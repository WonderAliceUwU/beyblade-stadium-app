import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../features/battle/domain/battle_session_state.dart';
import '../features/battle/domain/battle_series_config.dart';
import '../features/battle/presentation/battle_series_presenter.dart';
import '../features/battle/services/battle_audio_controller.dart';
import 'title_screen.dart';

class PlayerSelectScreen extends StatefulWidget {
  final BeySeries series;

  const PlayerSelectScreen({super.key, required this.series});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen>
    with TickerProviderStateMixin {
  late final BattleSeriesConfig _config;
  late final BattleAudioController _audio;
  late BattleSessionState _state;

  late final AnimationController _countdownController;
  late final Animation<Offset> _countdownSlide;
  late final AnimationController _finishOverlayController;
  late final Animation<double> _finishOpacity;
  late final Animation<Offset> _finishSlide;
  late final AnimationController _winMotifController;
  late final FocusNode _keyboardFocusNode;

  VideoPlayerController? _videoController;
  bool _showVideo = false;
  bool _isVideoReady = false;
  bool _isClosingVideo = false;

  String get font => _config.fontFamily;

  TextStyle get textStyle {
    if (_config.embossedText) {
      return TextStyle(
        fontFamily: font,
        color: Colors.white,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
          ),
          const Shadow(
            offset: Offset(-1, -1),
            color: Colors.grey,
            blurRadius: 1,
          ),
        ],
      );
    }
    return TextStyle(fontFamily: font, color: Colors.white);
  }

  @override
  void initState() {
    super.initState();
    _config = BattleSeriesConfig.forSeries(widget.series);
    _state = BattleSessionState.initial();
    _audio = BattleAudioController(
      config: _config.audio,
      isMounted: () => mounted,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _keyboardFocusNode = FocusNode(debugLabel: 'battle-keyboard-focus');
    _countdownSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.easeOutBack),
    );

    _finishOverlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _finishOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_finishOverlayController);
    _finishSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(1.0, 0.0))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 15,
      ),
    ]).animate(_finishOverlayController);

    _winMotifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (_config.hasOpeningVideo) {
      _showVideo = true;
      _initVideoAndMusic();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerRoundAnimation(autoClose: false);
      });
    }
  }

  void _updateState(BattleSessionState Function(BattleSessionState state) update) {
    setState(() {
      _state = update(_state);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _showVideo) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final shortcuts = _config.shortcuts;

    if (key == shortcuts.primaryAction) {
      _handlePrimaryActionShortcut();
      return KeyEventResult.handled;
    }

    if (_state.isGameOver) {
      return KeyEventResult.ignored;
    }

    if (_state.phase == ArenaPhase.countdown && !_state.isAnimatingFinish) {
      if (key == shortcuts.warning) {
        _triggerFinishAnimation('WARNING');
        return KeyEventResult.handled;
      }
      if (key == shortcuts.leftSpinFinish) {
        _triggerFinishAnimation('SPIN FINISH', isLeft: true, points: 1);
        return KeyEventResult.handled;
      }
      if (key == shortcuts.leftOverFinish) {
        _triggerFinishAnimation('OVER FINISH', isLeft: true, points: 2);
        return KeyEventResult.handled;
      }
      if (key == shortcuts.rightSpinFinish) {
        _triggerFinishAnimation('SPIN FINISH', isLeft: false, points: 1);
        return KeyEventResult.handled;
      }
      if (key == shortcuts.rightOverFinish) {
        _triggerFinishAnimation('OVER FINISH', isLeft: false, points: 2);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _handlePrimaryActionShortcut() {
    if (_state.isGameOver || _state.phase != ArenaPhase.selecting) {
      return;
    }

    if (!_state.leftLocked) {
      _updateState((state) => state.copyWith(leftLocked: true));
      return;
    }

    if (!_state.rightLocked) {
      _updateState((state) => state.copyWith(rightLocked: true));
      return;
    }

    if (_state.bothLocked) {
      _startCountdown();
    }
  }

  Future<void> _initVideoAndMusic() async {
    final openingVideoAsset = _config.openingVideoAsset;
    if (openingVideoAsset == null) return;

    _videoController = VideoPlayerController.asset(openingVideoAsset);

    try {
      await _videoController!.initialize();
      if (!mounted) return;

      setState(() {
        _isVideoReady = true;
      });

      await _videoController!.setVolume(0.15);
      await _videoController!.play();
      _videoController!.addListener(() {
        if (_videoController != null &&
            _videoController!.value.position >= _videoController!.value.duration &&
            !_isClosingVideo) {
          _closeVideo();
        }
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
      _closeVideo();
    }
  }

  Future<void> _closeVideo() async {
    if (!_showVideo || !mounted || _isClosingVideo) return;

    setState(() {
      _isClosingVideo = true;
    });

    await _audio.startBgMusic();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _showVideo = false;
      _isVideoReady = false;
      _isClosingVideo = false;
    });

    await _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _triggerRoundAnimation(autoClose: false);
      }
    });
  }

  Future<void> _triggerRoundAnimation({bool autoClose = true}) async {
    if (_state.finishText == 'ROUND ${_state.currentRound}' &&
        _state.isAnimatingFinish &&
        !autoClose) {
      return;
    }

    _updateState(
      (state) => state.copyWith(
        isAnimatingFinish: true,
        finishText: 'ROUND ${state.currentRound}',
      ),
    );

    if (_config.audio.bgPlaylist.isNotEmpty && !_audio.isMusicMuted) {
      _audio.fadeBgMusic(
        _audio.duckMusicVol,
        const Duration(milliseconds: 500),
      );
    }

    final soundFile = _config.audio.roundSoundFor(_state.currentRound);

    try {
      await _audio.playSoundWithEcho(soundFile, baseVolume: 0.3);
    } catch (e) {
      debugPrint('Error playing round sound: $e');
    }

    if (autoClose) {
      await _finishOverlayController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      _finishOverlayController.reset();
      if (!mounted) return;
      _updateState(
        (state) => state.copyWith(isAnimatingFinish: false, finishText: ''),
      );
    } else {
      await _finishOverlayController.animateTo(0.5);
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      if (_state.phase == ArenaPhase.selecting && !_audio.isMusicMuted) {
        _audio.fadeBgMusic(
          _audio.maxMusicVol,
          const Duration(milliseconds: 800),
        );
      }
    });
  }

  Future<void> _startCountdown() async {
    if (_config.audio.bgPlaylist.isNotEmpty && !_audio.isMusicMuted) {
      _audio.fadeBgMusic(
        _audio.maxMusicVol * 0.1,
        const Duration(milliseconds: 400),
      );
    }

    if (_state.finishText.startsWith('ROUND')) {
      _finishOverlayController.value = 0.85;
      await _finishOverlayController.forward();
      _finishOverlayController.reset();
      if (!mounted) return;
      _updateState(
        (state) => state.copyWith(isAnimatingFinish: false, finishText: ''),
      );
    }

    if (!mounted) return;

    _updateState(
      (state) => state.copyWith(phase: ArenaPhase.countdown, countdownIndex: 0),
    );

    try {
      await _audio.playCountdown();
    } catch (e) {
      debugPrint('Error playing countdown sound: $e');
    }

    const stepDurations = [1100, 1100, 1100, 1000, 1200];
    for (int i = 0; i < _config.countdownSequence.length; i++) {
      if (!mounted ||
          _state.phase != ArenaPhase.countdown ||
          _state.isAnimatingFinish) {
        break;
      }

      _updateState((state) => state.copyWith(countdownIndex: i));
      _countdownController.forward(from: 0);

      if (i == _config.countdownSequence.length - 1) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && _state.phase == ArenaPhase.countdown) {
            _audio.fadeOutEffect(const Duration(milliseconds: 500));
          }
        });
      }

      await Future.delayed(Duration(milliseconds: stepDurations[i]));
    }

    if (_config.audio.bgPlaylist.isNotEmpty && !_audio.isMusicMuted) {
      _audio.fadeBgMusic(
        _audio.maxMusicVol,
        const Duration(milliseconds: 1000),
      );
    }

    if (mounted &&
        _state.phase == ArenaPhase.countdown &&
        !_state.isAnimatingFinish) {
      _updateState(
        (state) => state.copyWith(countdownIndex: _config.countdownSequence.length),
      );
      _countdownController.forward(from: 0);
    }
  }

  Future<void> _triggerFinishAnimation(
    String text, {
    bool? isLeft,
    int? points,
  }) async {
    if (_state.isAnimatingFinish && !_state.finishText.startsWith('ROUND')) {
      return;
    }
    final shouldAdvanceRound = isLeft != null && points != null && points > 0;

    _finishOverlayController.reset();
    _updateState(
      (state) => state.copyWith(isAnimatingFinish: true, finishText: text),
    );

    final random = Random();
    final soundFile = _config.audio.finishSoundFor(
      text.contains('WARNING')
          ? BattleFinishType.warning
          : text.contains('OVER')
              ? BattleFinishType.over
              : BattleFinishType.spin,
      random,
    );

    try {
      await _audio.playSoundWithEcho(soundFile, baseVolume: 0.4);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    await _finishOverlayController.forward(from: 0);
    _finishOverlayController.reset();
    if (!mounted) return;

    final nextLeftScore = _state.leftScore + ((isLeft == true && points != null) ? points : 0);
    final nextRightScore = _state.rightScore + ((isLeft == false && points != null) ? points : 0);

    final leftWon = nextLeftScore >= 4;
    final rightWon = nextRightScore >= 4;

    if (leftWon || rightWon) {
      final winningBey = leftWon ? _state.leftBey : _state.rightBey;
      final winnerMessage =
          '${(winningBey?.winName ?? (leftWon ? 'PLAYER 1' : 'PLAYER 2')).toUpperCase()} WINS';

      _updateState(
        (state) => state.copyWith(
          leftScore: nextLeftScore,
          rightScore: nextRightScore,
          finishText: winnerMessage,
          winningBey: winningBey,
          winnerIsLeft: leftWon,
          isGameOver: true,
        ),
      );

      try {
        if (winningBey != null) {
          final voices = winningBey.winVoices;
          final randomVoice = voices[random.nextInt(voices.length)];
          await _audio.playSoundWithEcho(randomVoice, baseVolume: 0.6);
        } else {
          await _audio.playSoundWithEcho(_config.audio.clickSound, baseVolume: 0.4);
        }
      } catch (e) {
        debugPrint('Error playing win sound: $e');
      }

      _winMotifController.forward(from: 0);
      return;
    }

    _updateState(
      (state) => state.copyWith(
        leftScore: nextLeftScore,
        rightScore: nextRightScore,
        phase: ArenaPhase.selecting,
        leftLocked: false,
        rightLocked: false,
        isAnimatingFinish: false,
        finishText: '',
        currentRound: shouldAdvanceRound
            ? state.currentRound + 1
            : state.currentRound,
      ),
    );

    _audio.handleCrossfade(random: true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _triggerRoundAnimation(autoClose: false);
      }
    });
  }

  void _toggleMusic() {
    setState(_audio.toggleMusic);
  }

  void _resetScores() {
    _updateState(
      (state) => state.copyWith(
        leftScore: 0,
        rightScore: 0,
        currentRound: 1,
        leftLocked: false,
        rightLocked: false,
        phase: ArenaPhase.selecting,
        isAnimatingFinish: false,
        finishText: '',
      ),
    );
    _audio.handleCrossfade(forceIndex: 0);
    _triggerRoundAnimation(autoClose: false);
  }

  void _resetBattle() {
    _updateState(
      (state) => state.copyWith(
        leftScore: 0,
        rightScore: 0,
        currentRound: 1,
        phase: ArenaPhase.selecting,
        leftLocked: false,
        rightLocked: false,
        isAnimatingFinish: false,
        finishText: '',
        isGameOver: false,
        winningBey: null,
      ),
    );
    _winMotifController.reset();
    _audio.handleCrossfade(forceIndex: 0);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _triggerRoundAnimation(autoClose: false);
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _finishOverlayController.dispose();
    _winMotifController.dispose();
    _keyboardFocusNode.dispose();
    _audio.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              children: <Widget>[
                ...previousChildren,
                ...?currentChild == null ? null : [currentChild],
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: Container(color: Colors.black, child: child),
            );
          },
          child: _state.isGameOver
              ? _config.presenter.buildWinView(
                  _presentationData(),
                  _winMotifController,
                  WinPresentationCallbacks(
                    onResetBattle: _resetBattle,
                    onToggleMusic: _toggleMusic,
                    onSkipTrack: () => _audio.handleCrossfade(random: true),
                  ),
                )
              : _config.presenter.buildBattleView(
                  _presentationData(),
                  BattlePresentationCallbacks(
                    onPointerDown: () => _audio.playClickSfx(
                      enabled: _config.audio.clickSound.isNotEmpty,
                    ),
                    onLeftLockToggle: () => _updateState(
                      (state) => state.copyWith(leftLocked: !state.leftLocked),
                    ),
                    onRightLockToggle: () => _updateState(
                      (state) => state.copyWith(rightLocked: !state.rightLocked),
                    ),
                    onLeftBeyChanged: (bey) =>
                        _updateState((state) => state.copyWith(leftBey: bey)),
                    onRightBeyChanged: (bey) =>
                        _updateState((state) => state.copyWith(rightBey: bey)),
                    onPlay: _startCountdown,
                    onWarning: () => _triggerFinishAnimation('WARNING'),
                    onLeftSpinFinish: () => _triggerFinishAnimation(
                      'SPIN FINISH',
                      isLeft: true,
                      points: 1,
                    ),
                    onLeftOverFinish: () => _triggerFinishAnimation(
                      'OVER FINISH',
                      isLeft: true,
                      points: 2,
                    ),
                    onRightSpinFinish: () => _triggerFinishAnimation(
                      'SPIN FINISH',
                      isLeft: false,
                      points: 1,
                    ),
                    onRightOverFinish: () => _triggerFinishAnimation(
                      'OVER FINISH',
                      isLeft: false,
                      points: 2,
                    ),
                    onToggleMusic: _toggleMusic,
                    onSkipTrack: () => _audio.handleCrossfade(random: true),
                    onResetScores: _resetScores,
                    onCloseVideo: _closeVideo,
                  ),
                ),
        ),
      ),
    );
  }

  BattlePresentationData _presentationData() {
    return BattlePresentationData(
      state: _state,
      series: widget.series,
      font: font,
      textStyle: textStyle,
      countdownSequence: _config.countdownSequence,
      beys: _config.beys,
      countdownSlide: _countdownSlide,
      finishOpacity: _finishOpacity,
      finishSlide: _finishSlide,
      videoController: _videoController,
      showVideo: _showVideo,
      isVideoReady: _isVideoReady,
      isClosingVideo: _isClosingVideo,
      isMusicMuted: _audio.isMusicMuted,
      currentTrackLabel: _audio.currentTrackLabel,
    );
  }
}
