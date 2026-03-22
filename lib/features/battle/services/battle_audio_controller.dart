import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import '../domain/battle_series_config.dart';

class BattleAudioController {
  BattleAudioController({
    required BattleAudioConfig config,
    required bool Function() isMounted,
    required void Function() onChanged,
  })  : _config = config,
        _isMounted = isMounted,
        _onChanged = onChanged {
    _setupMusicListeners(_bgMusicPlayer1);
    _setupMusicListeners(_bgMusicPlayer2);
  }

  final BattleAudioConfig _config;
  final bool Function() _isMounted;
  final void Function() _onChanged;

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _echoPlayer1 = AudioPlayer();
  final AudioPlayer _echoPlayer2 = AudioPlayer();
  final AudioPlayer _bgMusicPlayer1 = AudioPlayer();
  final AudioPlayer _bgMusicPlayer2 = AudioPlayer();
  final AudioPlayer _clickSfxPlayer = AudioPlayer();

  int currentBgIndex = 0;
  int _activePlayerIndex = 1;
  bool _isCrossfading = false;
  Duration? _currentSongDuration;
  int _bgMusicFadeId = 0;
  bool isMusicMuted = false;

  AudioPlayer get _activeBgPlayer =>
      _activePlayerIndex == 1 ? _bgMusicPlayer1 : _bgMusicPlayer2;

  List<String> get bgPlaylist => _config.bgPlaylist;
  double get maxMusicVol => _config.maxMusicVolume;
  double get duckMusicVol => _config.duckMusicVolume;

  String get currentTrackLabel =>
      bgPlaylist[currentBgIndex].split('/').last.split('.').first.toUpperCase();

  void _setupMusicListeners(AudioPlayer player) {
    player.onPositionChanged.listen((position) {
      if (isMusicMuted || _isCrossfading || player != _activeBgPlayer) return;

      final duration = _currentSongDuration;
      if (duration != null &&
          duration.inMilliseconds > 5000 &&
          duration.inMilliseconds - position.inMilliseconds < 4000) {
        unawaited(handleCrossfade());
      }
    });

    player.onPlayerComplete.listen((_) {
      if (player == _activeBgPlayer && !_isCrossfading) {
        unawaited(handleCrossfade());
      }
    });
  }

  Future<void> playClickSfx({required bool enabled}) async {
    if (!enabled) return;

    try {
      if (_clickSfxPlayer.state == PlayerState.playing) {
        await _clickSfxPlayer.stop();
      }
      await _clickSfxPlayer.setVolume(0.15);
      await _clickSfxPlayer.play(AssetSource(_config.clickSound));
    } catch (e) {
      // Ignore transient audio errors.
    }
  }

  Future<void> startBgMusic() async {
    if (_bgMusicPlayer1.state == PlayerState.playing ||
        _bgMusicPlayer2.state == PlayerState.playing) {
      return;
    }

    try {
      _activePlayerIndex = 1;
      currentBgIndex = 0;
      _onChanged();

      await _bgMusicPlayer1.setVolume(0.0);
      await _bgMusicPlayer1.play(AssetSource(bgPlaylist[currentBgIndex]));
      _currentSongDuration = await _bgMusicPlayer1.getDuration();

      if (!isMusicMuted) {
        await fadeBgMusic(maxMusicVol, const Duration(seconds: 1));
      }
    } catch (_) {}
  }

  Future<void> handleCrossfade({bool random = false, int? forceIndex}) async {
    if (_isCrossfading) return;
    _isCrossfading = true;

    final oldPlayer = _activeBgPlayer;
    final newIndex = _resolveNextTrack(random: random, forceIndex: forceIndex);

    currentBgIndex = newIndex;
    _activePlayerIndex = _activePlayerIndex == 1 ? 2 : 1;
    _onChanged();

    final newPlayer = _activeBgPlayer;

    try {
      await newPlayer.setVolume(0.0);
      await newPlayer.play(AssetSource(bgPlaylist[currentBgIndex]));
      _currentSongDuration = await newPlayer.getDuration();

      const fadeDuration = Duration(seconds: 4);
      unawaited(_fadeSpecificPlayer(oldPlayer, 0.0, fadeDuration));
      unawaited(_fadeSpecificPlayer(
        newPlayer,
        isMusicMuted ? 0.0 : maxMusicVol,
        fadeDuration,
      ));

      await Future.delayed(fadeDuration);
      if (oldPlayer.state == PlayerState.playing) {
        await oldPlayer.stop();
      }
    } catch (_) {
    } finally {
      _isCrossfading = false;
    }
  }

  int _resolveNextTrack({required bool random, int? forceIndex}) {
    if (forceIndex != null) return forceIndex;
    if (random && bgPlaylist.length > 1) {
      int nextIndex;
      do {
        nextIndex = Random().nextInt(bgPlaylist.length);
      } while (nextIndex == currentBgIndex);
      return nextIndex;
    }
    return (currentBgIndex + 1) % bgPlaylist.length;
  }

  Future<void> fadeBgMusic(double targetVolume, Duration duration) async {
    final fadeId = ++_bgMusicFadeId;
    await _fadeSpecificPlayer(
      _activeBgPlayer,
      targetVolume,
      duration,
      fadeId: fadeId,
    );
  }

  Future<void> _fadeSpecificPlayer(
    AudioPlayer player,
    double targetVolume,
    Duration duration, {
    int? fadeId,
  }) async {
    const steps = 20;
    final interval = duration.inMilliseconds ~/ steps;
    final startVolume = player.volume;
    final volumeDelta = targetVolume - startVolume;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      if (!_isMounted()) break;
      if (fadeId != null && _bgMusicFadeId != fadeId) break;

      await player.setVolume(startVolume + (volumeDelta * (i / steps)));
    }
  }

  Future<void> fadeOutEffect(Duration duration) async {
    const steps = 20;
    final interval = duration.inMilliseconds ~/ steps;
    final startVolume = _effectPlayer.volume;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      if (!_isMounted()) return;
      await _effectPlayer.setVolume(startVolume * (1 - (i / steps)));
    }
  }

  Future<void> playCountdown() async {
    await _effectPlayer.setVolume(1.0);
    await _effectPlayer.play(AssetSource(_config.countdownSound));
  }

  Future<void> playSoundWithEcho(
    String soundPath, {
    double baseVolume = 1.0,
  }) async {
    final source = AssetSource(soundPath);

    await _effectPlayer.setVolume(baseVolume);
    await _effectPlayer.play(source);

    Future.delayed(const Duration(milliseconds: 150), () async {
      if (_isMounted()) {
        await _echoPlayer1.setVolume(baseVolume * 0.4);
        await _echoPlayer1.play(source);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (_isMounted()) {
        await _echoPlayer2.setVolume(baseVolume * 0.3);
        await _echoPlayer2.play(source);
      }
    });
  }

  void toggleMusic() {
    isMusicMuted = !isMusicMuted;
    if (isMusicMuted) {
      _bgMusicPlayer1.setVolume(0.0);
      _bgMusicPlayer2.setVolume(0.0);
    } else {
      _activeBgPlayer.setVolume(maxMusicVol);
    }
    _onChanged();
  }

  Future<void> dispose() async {
    await _effectPlayer.dispose();
    await _echoPlayer1.dispose();
    await _echoPlayer2.dispose();
    await _bgMusicPlayer1.dispose();
    await _bgMusicPlayer2.dispose();
    await _clickSfxPlayer.dispose();
  }
}
