import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import '../widgets/bey_wheel.dart';
import 'title_screen.dart';

enum ArenaPhase { selecting, countdown }

class PlayerSelectScreen extends StatefulWidget {
  final BeySeries series;
  const PlayerSelectScreen({super.key, required this.series});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen>
    with TickerProviderStateMixin {
  bool leftLocked = false;
  bool rightLocked = false;

  int leftScore = 0;
  int rightScore = 0;
  int currentRound = 1;

  BeyInfo? leftBey;
  BeyInfo? rightBey;

  ArenaPhase phase = ArenaPhase.selecting;

  late AnimationController _countdownController;
  late Animation<Offset> _slide;

  late AnimationController _finishOverlayController;
  late Animation<double> _finishOpacity;
  late Animation<Offset> _finishSlide;
  String _finishText = '';
  bool _isAnimatingFinish = false;

  // Win Screen State
  bool _isGameOver = false;
  BeyInfo? _winningBey;
  bool _winnerIsLeft = true;
  late AnimationController _winMotifController;

  final List<String> sequence = ['3', '2', '1', 'GOOO', 'SHOOT!!'];
  int currentIndex = 0;

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _echoPlayer1 = AudioPlayer();
  final AudioPlayer _echoPlayer2 = AudioPlayer();
  
  final AudioPlayer _bgMusicPlayer1 = AudioPlayer();
  final AudioPlayer _bgMusicPlayer2 = AudioPlayer();
  final AudioPlayer _clickSfxPlayer = AudioPlayer();

  VideoPlayerController? _videoController;
  bool _showVideo = false;
  bool _isVideoReady = false;
  bool _isClosingVideo = false;

  bool _isMusicMuted = false;

  static const double _maxMusicVol = 0.10;
  static const double _duckMusicVol = 0.02;

  int _bgMusicFadeId = 0;

  final List<String> _bgPlaylist = [
    'metal/sounds/bg-music/Metal Fight Theme.m4a',
    'metal/sounds/bg-music/Fatal Damage.opus',
    'metal/sounds/bg-music/Fly.m4a',
    'metal/sounds/bg-music/Wild Scent.opus',
    'metal/sounds/bg-music/Ryu-Kyu Humming.mp3',
  ];
  int _currentBgIndex = 0;
  int _activePlayerIndex = 1;
  bool _isCrossfading = false;
  Duration? _currentSongDuration;

  AudioPlayer get _activeBgPlayer => _activePlayerIndex == 1 ? _bgMusicPlayer1 : _bgMusicPlayer2;
  AudioPlayer get _inactiveBgPlayer => _activePlayerIndex == 1 ? _bgMusicPlayer2 : _bgMusicPlayer1;

  String get font {
    return widget.series == BeySeries.x ? 'BeybladeX' : 'MetalFight';
  }

  TextStyle get textStyle {
    if (widget.series == BeySeries.metal) {
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

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _countdownController,
        curve: Curves.easeOutBack,
      ),
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

    _setupMusicListeners(_bgMusicPlayer1);
    _setupMusicListeners(_bgMusicPlayer2);

    if (widget.series == BeySeries.metal) {
      _showVideo = true;
      _initVideoAndMusic();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerRoundAnimation(autoClose: false);
      });
    }
  }

  void _setupMusicListeners(AudioPlayer player) {
    player.onPositionChanged.listen((position) {
      if (_isMusicMuted || _isCrossfading || player != _activeBgPlayer) return;
      
      if (_currentSongDuration != null && _currentSongDuration!.inMilliseconds > 5000) {
        if (_currentSongDuration!.inMilliseconds - position.inMilliseconds < 4000) {
          _handleCrossfade();
        }
      }
    });

    player.onPlayerComplete.listen((_) {
      if (player == _activeBgPlayer && !_isCrossfading) {
        _handleCrossfade();
      }
    });
  }

  Future<void> _handleCrossfade({bool random = false, int? forceIndex}) async {
    if (_isCrossfading) return;
    _isCrossfading = true;

    final oldPlayer = _activeBgPlayer;
    
    int newIndex;
    if (forceIndex != null) {
      newIndex = forceIndex;
    } else if (random && _bgPlaylist.length > 1) {
      do {
        newIndex = Random().nextInt(_bgPlaylist.length);
      } while (newIndex == _currentBgIndex);
    } else {
      newIndex = (_currentBgIndex + 1) % _bgPlaylist.length;
    }

    setState(() {
      _currentBgIndex = newIndex;
    });
    
    _activePlayerIndex = _activePlayerIndex == 1 ? 2 : 1;
    final newPlayer = _activeBgPlayer;

    try {
      await newPlayer.setVolume(0);
      await newPlayer.play(AssetSource(_bgPlaylist[_currentBgIndex]));
      _currentSongDuration = await newPlayer.getDuration();
      
      const fadeDuration = Duration(seconds: 4);
      _fadeSpecificPlayer(oldPlayer, 0.0, fadeDuration);
      _fadeSpecificPlayer(newPlayer, _isMusicMuted ? 0.0 : _maxMusicVol, fadeDuration);

      await Future.delayed(fadeDuration);
      if (oldPlayer.state == PlayerState.playing) await oldPlayer.stop();
    } catch (e) {
      debugPrint('Error during music crossfade: $e');
    } finally {
      _isCrossfading = false;
    }
  }

  Future<void> _playClickSfx() async {
    if (widget.series != BeySeries.metal) return;
    try {
      if (_clickSfxPlayer.state == PlayerState.playing) {
        await _clickSfxPlayer.stop();
      }
      await _clickSfxPlayer.setVolume(0.15);
      await _clickSfxPlayer.play(AssetSource('metal/sounds/select.mp3'));
    } catch (e) {
      debugPrint('Error playing click sound: $e');
    }
  }

  Future<void> _initVideoAndMusic() async {
    _videoController = VideoPlayerController.asset('assets/metal/video/opening-mf.mp4');
    
    try {
      await _videoController!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isVideoReady = true;
      });
      
      await _videoController!.setVolume(0.15);
      _videoController!.play();
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

  void _closeVideo() async {
    if (!_showVideo || !mounted || _isClosingVideo) return;
    
    setState(() {
      _isClosingVideo = true;
    });

    _startBgMusic();

    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    setState(() {
      _showVideo = false;
      _isVideoReady = false;
      _isClosingVideo = false;
    });
    
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _triggerRoundAnimation(autoClose: false);
    });
  }

  Future<void> _startBgMusic() async {
    if (_bgMusicPlayer1.state == PlayerState.playing || _bgMusicPlayer2.state == PlayerState.playing) return;
    
    try {
      _activePlayerIndex = 1;
      setState(() {
        _currentBgIndex = 0;
      });
      await _bgMusicPlayer1.setVolume(0.0);
      await _bgMusicPlayer1.play(AssetSource(_bgPlaylist[_currentBgIndex]));
      _currentSongDuration = await _bgMusicPlayer1.getDuration();

      if (!_isMusicMuted) {
        _fadeBgMusic(_maxMusicVol, const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> _fadeBgMusic(double targetVolume, Duration duration) async {
    final fadeId = ++_bgMusicFadeId;
    _fadeSpecificPlayer(_activeBgPlayer, targetVolume, duration, fadeId: fadeId);
  }

  Future<void> _fadeSpecificPlayer(AudioPlayer player, double targetVolume, Duration duration, {int? fadeId}) async {
    const steps = 20;
    final interval = duration.inMilliseconds ~/ steps;
    final startVolume = player.volume;
    final volumeDelta = targetVolume - startVolume;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      if (!mounted) break;
      if (fadeId != null && _bgMusicFadeId != fadeId) break;
      
      await player.setVolume(startVolume + (volumeDelta * (i / steps)));
    }
  }

  Future<void> _fadeOutPlayer(AudioPlayer player, Duration duration) async {
    const steps = 20;
    final interval = duration.inMilliseconds ~/ steps;
    final startVolume = player.volume;
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));
      if (!mounted) return;
      await player.setVolume(startVolume * (1 - (i / steps)));
    }
  }

  Future<void> _triggerRoundAnimation({bool autoClose = true}) async {
    if (_finishText == 'ROUND $currentRound' && _isAnimatingFinish && !autoClose) return;

    setState(() {
      _isAnimatingFinish = true;
      _finishText = 'ROUND $currentRound';
    });

    if (widget.series == BeySeries.metal && !_isMusicMuted) {
      _fadeBgMusic(_duckMusicVol, const Duration(milliseconds: 500));
    }

    String soundFile = 'metal/sounds/round/round-$currentRound.mp3';
    if (currentRound > 7) soundFile = 'metal/sounds/round/round-7.mp3';

    try {
      await _playSoundWithEcho(soundFile, baseVolume: 0.3);
    } catch (e) {
      debugPrint('Error playing round sound: $e');
    }

    if (autoClose) {
      await _finishOverlayController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      _finishOverlayController.reset();
      setState(() {
        _isAnimatingFinish = false;
        _finishText = '';
      });
    } else {
      await _finishOverlayController.animateTo(0.5);
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && phase == ArenaPhase.selecting && !_isMusicMuted) {
        _fadeBgMusic(_maxMusicVol, const Duration(milliseconds: 800));
      }
    });
  }

  Future<void> startCountdown() async {
    if (widget.series == BeySeries.metal && !_isMusicMuted) {
      _fadeBgMusic(_maxMusicVol * 0.1, const Duration(milliseconds: 400));
    }

    if (_finishText.startsWith('ROUND')) {
      _finishOverlayController.value = 0.85;
      await _finishOverlayController.forward();
      _finishOverlayController.reset();
      setState(() {
        _isAnimatingFinish = false;
        _finishText = '';
      });
    }

    if (!mounted) return;

    setState(() {
      phase = ArenaPhase.countdown;
      currentIndex = 0;
    });

    try {
      await _effectPlayer.setVolume(1.0);
      await _effectPlayer.play(AssetSource('metal/sounds/countdown.m4a'));
    } catch (e) {
      debugPrint('Error playing countdown sound: $e');
    }

    final List<int> stepDurations = [1100, 1100, 1100, 1000, 1200];

    for (int i = 0; i < sequence.length; i++) {
      if (!mounted || phase != ArenaPhase.countdown || _isAnimatingFinish) break;
      setState(() => currentIndex = i);
      _countdownController.forward(from: 0);
      
      if (i == sequence.length - 1) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && phase == ArenaPhase.countdown) {
            _fadeOutPlayer(_effectPlayer, const Duration(milliseconds: 500));
          }
        });
      }
      
      await Future.delayed(Duration(milliseconds: stepDurations[i]));
    }

    if (widget.series == BeySeries.metal && !_isMusicMuted) {
      _fadeBgMusic(_maxMusicVol, const Duration(milliseconds: 1000));
    }

    if (mounted && phase == ArenaPhase.countdown && !_isAnimatingFinish) {
      setState(() {
        currentIndex = sequence.length;
      });
      _countdownController.forward(from: 0);
    }
  }

  Future<void> _playSoundWithEcho(String soundPath, {double baseVolume = 1.0}) async {
    final source = AssetSource(soundPath);
    
    await _effectPlayer.setVolume(baseVolume);
    await _effectPlayer.play(source);

    Future.delayed(const Duration(milliseconds: 150), () async {
      if (mounted) {
        await _echoPlayer1.setVolume(baseVolume * 0.4);
        await _echoPlayer1.play(source);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        await _echoPlayer2.setVolume(baseVolume * 0.3);
        await _echoPlayer2.play(source);
      }
    });
  }

  Future<void> _triggerFinishAnimation(String text, {bool? isLeft, int? points}) async {
    if (_isAnimatingFinish && !_finishText.startsWith('ROUND')) return;
    
    _finishOverlayController.reset();

    setState(() {
      _isAnimatingFinish = true;
      _finishText = text;
    });

    String soundFile = 'metal/sounds/select.mp3';
    final random = Random();
    
    if (text.contains('SPIN')) {
      int version = random.nextInt(2) + 1;
      soundFile = version == 1 
          ? 'metal/sounds/finish/Spin finish 1.mp3' 
          : 'metal/sounds/finish/Spin Finish 2.mp3';
    } else if (text.contains('OVER')) {
      int version = random.nextInt(3) + 1;
      soundFile = 'metal/sounds/finish/Over finish $version.mp3';
    } else if (text.contains('WARNING')) {
      soundFile = 'metal/sounds/finish/Warning 1.mp3';
    }
    
    try {
      await _playSoundWithEcho(soundFile, baseVolume: 0.4);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    await _finishOverlayController.forward(from: 0);
    _finishOverlayController.reset();

    bool hasWinner = false;
    String winnerMessage = '';
    BeyInfo? winningBey;
    bool winnerIsLeft = true;

    setState(() {
      if (isLeft != null && points != null) {
        if (isLeft) {
          leftScore += points;
        } else {
          rightScore += points;
        }
      }

      if (leftScore >= 4) {
        hasWinner = true;
        winningBey = leftBey;
        winnerIsLeft = true;
        winnerMessage = '${leftBey?.winName.toUpperCase() ?? 'PLAYER 1'} WINS';
      } else if (rightScore >= 4) {
        hasWinner = true;
        winningBey = rightBey;
        winnerIsLeft = false;
        winnerMessage = '${rightBey?.winName.toUpperCase() ?? 'PLAYER 2'} WINS';
      }

      if (!hasWinner) {
        phase = ArenaPhase.selecting;
        leftLocked = false;
        rightLocked = false;
        _isAnimatingFinish = false;
        _finishText = '';
        currentRound++;
        
        _handleCrossfade(random: true);

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _triggerRoundAnimation(autoClose: false);
        });
      } else {
        _finishText = winnerMessage;
      }
    });

    if (hasWinner) {
      try {
        if (winningBey != null) {
          final voices = winningBey!.winVoices;
          final randomVoice = voices[random.nextInt(voices.length)];
          await _playSoundWithEcho(randomVoice, baseVolume: 0.6);
        } else {
          await _playSoundWithEcho('metal/sounds/select.mp3', baseVolume: 0.4);
        }
      } catch (e) {
        debugPrint('Error playing win sound: $e');
      }
      
      setState(() {
        _isGameOver = true;
        _winningBey = winningBey;
        _winnerIsLeft = winnerIsLeft;
      });
      
      _winMotifController.forward(from: 0);
    }
  }

  void _resetBattle() {
    setState(() {
      leftScore = 0;
      rightScore = 0;
      currentRound = 1;
      phase = ArenaPhase.selecting;
      leftLocked = false;
      rightLocked = false;
      _isAnimatingFinish = false;
      _finishText = '';
      _isGameOver = false;
      _winningBey = null;
    });

    _winMotifController.reset();
    _handleCrossfade(forceIndex: 0);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _triggerRoundAnimation(autoClose: false);
    });
  }

  void toggleMusic() {
    setState(() {
      _isMusicMuted = !_isMusicMuted;
      if (_isMusicMuted) {
        _bgMusicPlayer1.setVolume(0.0);
        _bgMusicPlayer2.setVolume(0.0);
      } else {
        _activeBgPlayer.setVolume(_maxMusicVol);
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _finishOverlayController.dispose();
    _winMotifController.dispose();
    _effectPlayer.dispose();
    _echoPlayer1.dispose();
    _echoPlayer2.dispose();
    _bgMusicPlayer1.dispose();
    _bgMusicPlayer2.dispose();
    _clickSfxPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              color: Colors.black,
              child: child,
            ),
          );
        },
        child: _isGameOver ? _buildWinScreen() : _buildBattleScreen(),
      ),
    );
  }

  Widget _buildBattleScreen() {
    final bothLocked = leftLocked && rightLocked;
    final interactionEnabled = phase == ArenaPhase.selecting && 
        (!_isAnimatingFinish || (_finishText.startsWith('ROUND')));

    return KeyedSubtree(
      key: const ValueKey('battle'),
      child: Listener(
        onPointerDown: (_) => _playClickSfx(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: BeyWheel(
                      key: const ValueKey('p1'),
                      label: 'PLAYER 1',
                      isLeft: true,
                      color: Colors.redAccent,
                      locked: leftLocked,
                      onLock: () {
                        setState(() => leftLocked = !leftLocked);
                      },
                      fontFamily: font,
                      onBeyChanged: (bey) => leftBey = bey,
                      interactionEnabled: interactionEnabled,
                    ),
                  ),
                  Expanded(
                    child: BeyWheel(
                      key: const ValueKey('p2'),
                      label: 'PLAYER 2',
                      isLeft: false,
                      color: Colors.blueAccent,
                      locked: rightLocked,
                      onLock: () {
                        setState(() => rightLocked = !rightLocked);
                      },
                      fontFamily: font,
                      onBeyChanged: (bey) => rightBey = bey,
                      interactionEnabled: interactionEnabled,
                    ),
                  ),
                ],
              ),

              if (phase == ArenaPhase.selecting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: -120,
                left: -10,
                child: IgnorePointer(
                  child: Text(
                    '$leftScore',
                    style: textStyle.copyWith(
                      fontSize: 320,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 25),
                        Shadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 50),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                right: 50,
                child: IgnorePointer(
                  child: Text(
                    '$rightScore',
                    style: textStyle.copyWith(
                      fontSize: 320,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.blueAccent.withOpacity(0.8), blurRadius: 25),
                        Shadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 50),
                      ],
                    ),
                  ),
                ),
              ),

              if (bothLocked && phase == ArenaPhase.selecting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 200.0),
                    child: ElevatedButton(
                      onPressed: startCountdown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        'PLAY',
                        style: textStyle.copyWith(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  ),
                ),

              if (phase == ArenaPhase.countdown) ...[
                if (!_isAnimatingFinish)
                  Center(
                    child: IgnorePointer(
                      child: SlideTransition(
                        position: _slide,
                        child: Text(
                          currentIndex < sequence.length ? sequence[currentIndex] : 'VS',
                          style: textStyle.copyWith(
                            fontSize: currentIndex == 4 ? 72 : (currentIndex == 5 ? 60 : 56),
                            fontWeight: FontWeight.bold,
                            fontStyle: currentIndex == 5 ? FontStyle.italic : FontStyle.normal,
                            color: currentIndex == 5 ? Colors.white.withOpacity(0.6) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!_isAnimatingFinish)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => _triggerFinishAnimation('WARNING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.8),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(Icons.priority_high, color: Colors.white, size: 32),
                      ),
                    ),
                  ),

                if (!_isAnimatingFinish)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Column(
                      children: [
                        _FinishButton(
                          label: '1 pt. SPIN FINISH',
                          onPressed: () => _triggerFinishAnimation('SPIN FINISH', isLeft: true, points: 1),
                          color: Colors.redAccent,
                          textStyle: textStyle,
                        ),
                        const SizedBox(height: 15),
                        _FinishButton(
                          label: '2 pt. OVER FINISH',
                          onPressed: () => _triggerFinishAnimation('OVER FINISH', isLeft: true, points: 2),
                          color: Colors.redAccent,
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),

                if (!_isAnimatingFinish)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Column(
                      children: [
                        _FinishButton(
                          label: '1 pt. SPIN FINISH',
                          onPressed: () => _triggerFinishAnimation('SPIN FINISH', isLeft: false, points: 1),
                          color: Colors.blueAccent,
                          textStyle: textStyle,
                        ),
                        const SizedBox(height: 15),
                        _FinishButton(
                          label: '2 pt. OVER FINISH',
                          onPressed: () => _triggerFinishAnimation('OVER FINISH', isLeft: false, points: 2),
                          color: Colors.blueAccent,
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),
              ],

              if (_finishText.isNotEmpty)
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _finishOpacity,
                      child: SlideTransition(
                        position: _finishSlide,
                        child: Center(
                          child: Text(
                            _finishText,
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 4,
                              color: Colors.white,
                              shadows: [
                                const Shadow(color: Colors.orange, blurRadius: 40),
                                const Shadow(color: Colors.white, blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: _buildMusicControls(onRight: false),
              ),

              if (_showVideo)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeVideo,
                    child: AnimatedOpacity(
                      opacity: _isClosingVideo ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: (_isVideoReady && _videoController != null)
                              ? AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinScreen() {
    // Capture winner info locally to prevent null crashes during AnimatedSwitcher transitions
    final BeyInfo? winBey = _winningBey;
    if (winBey == null) return const SizedBox.shrink();
    
    final Color winColor = _winnerIsLeft ? Colors.redAccent : Colors.blueAccent;
    final double rotationSign = winBey.spin == SpinDirection.clockwise ? 1.0 : -1.0;
    final String finishMsg = _finishText;
    
    return KeyedSubtree(
      key: const ValueKey('win'),
      child: SafeArea(
        child: Stack(
          children: [
            // CENTER MOTIF (ENLARGED)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _winMotifController,
                builder: (context, child) {
                  return Center(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Transform.scale(
                        scale: 1.4 + (_winMotifController.value * 0.4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // GLOW LAYER (PLAYER COLOR)
                            Opacity(
                              opacity: 0.2 + (_winMotifController.value * 0.1),
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: Image.asset(
                                  'assets/metal/images/motifs/${winBey.motif}.png',
                                  color: winColor,
                                  colorBlendMode: BlendMode.srcIn,
                                  height: 800,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // DETAIL LAYER (ORIGINAL PNG COLORS REVEALED)
                            Opacity(
                              opacity: 0.4 + (_winMotifController.value * 0.2),
                              child: Image.asset(
                                'assets/metal/images/motifs/${winBey.motif}.png',
                                // Using modulate at lower intensity keeps details and original colors
                                color: winColor.withOpacity(0.3),
                                colorBlendMode: BlendMode.modulate,
                                height: 800,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // SPARKS
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _winMotifController,
                  builder: (context, child) {
                    return SparksOverlay(
                      spawnFactor: 0.5 + (_winMotifController.value * 0.5),
                      color: winColor,
                    );
                  },
                ),
              ),
            ),

            // WINNER BEY CENTERED
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Transform.rotate(
                          angle: value * 4 * pi * rotationSign,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: winColor.withOpacity(0.4),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/metal/images/beys/${winBey.name}.png',
                        height: 400,
                        width: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // TEXT STAYS PERMANENTLY IN WIN SCREEN
                  AnimatedBuilder(
                    animation: _winMotifController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: (_winMotifController.value * 4).clamp(0.0, 1.0),
                        child: child,
                      );
                    },
                    child: Text(
                      finishMsg,
                      textAlign: TextAlign.center,
                      style: textStyle.copyWith(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 4,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: winColor, blurRadius: 40),
                          const Shadow(color: Colors.white, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // START NEW BATTLE BUTTON
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _resetBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    'START NEW BATTLE',
                    style: textStyle.copyWith(
                      fontSize: 28,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            // MUSIC CONTROLS ON BOTTOM RIGHT
            Positioned(
              bottom: 10,
              right: 10,
              child: _buildMusicControls(onRight: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicControls({required bool onRight}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: onRight ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        if (widget.series == BeySeries.metal)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: onRight ? MainAxisAlignment.end : MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isMusicMuted ? Icons.music_off : Icons.music_note,
                    color: Colors.white54,
                    size: 28,
                  ),
                  onPressed: toggleMusic,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  height: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Center(
                      key: ValueKey<int>(_currentBgIndex),
                      child: Text(
                        _bgPlaylist[_currentBgIndex].split('/').last.split('.').first.toUpperCase(),
                        style: textStyle.copyWith(
                          fontSize: 12,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white54,
                    size: 28,
                  ),
                  onPressed: () => _handleCrossfade(random: true),
                ),
              ],
            ),
          ),
        if (!onRight)
          TextButton(
            onPressed: () {
              setState(() {
                leftScore = 0;
                rightScore = 0;
                currentRound = 1;
                leftLocked = false;
                rightLocked = false;
                phase = ArenaPhase.selecting;
              });
              _handleCrossfade(forceIndex: 0);
              _triggerRoundAnimation(autoClose: false);
            },
            child: Text('RESET ALL SCORES', 
              style: textStyle.copyWith(fontSize: 14, color: Colors.white54)),
          ),
      ],
    );
  }
}

class _FinishButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final TextStyle textStyle;

  const _FinishButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
