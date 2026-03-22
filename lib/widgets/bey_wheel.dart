import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum BeyType { attack, defense, stamina, balance }

enum SpinDirection { clockwise, counterClockwise }

class BeyInfo {
  final String name;
  final String motif;
  final BeyType type;
  final SpinDirection spin;
  final double imageScale;
  final String? selectVoiceOverride;
  final List<String>? winVoicesOverride;
  final String? winNameOverride;

  const BeyInfo({
    required this.name,
    required this.motif,
    required this.type,
    this.spin = SpinDirection.clockwise,
    this.imageScale = 1.0,
    this.selectVoiceOverride,
    this.winVoicesOverride,
    this.winNameOverride,
  });

  String get typeLogo {
    switch (type) {
      case BeyType.attack:
        return 'assets/metal/images/attack-logo.webp';
      case BeyType.defense:
        return 'assets/metal/images/defense-logo.webp';
      case BeyType.stamina:
        return 'assets/metal/images/stamina-logo.webp';
      case BeyType.balance:
        return 'assets/metal/images/balance-logo.webp';
    }
  }

  String get motifAsset => 'assets/metal/images/motifs/$motif.png';

  String get selectVoice {
    if (selectVoiceOverride != null) return selectVoiceOverride!;
    switch (motif) {
      case 'drago':
        return 'metal/sounds/bey-select/L-Drago Select.mp3';
      case 'aquario':
        return 'metal/sounds/bey-select/Aquario Select.mp3';
      case 'aquila':
        return 'metal/sounds/bey-select/Aquila Select.mp3';
      case 'leone':
        return 'metal/sounds/bey-select/Leone Select.mp3';
      case 'pegasis':
        return 'metal/sounds/bey-select/Pegasus Select.mp3';
      case 'phoenix':
        return 'metal/sounds/bey-select/Phoenix Select.mp3';
      case 'sagittario':
        return 'metal/sounds/bey-select/Sagittario Select.mp3';
      case 'wolf':
        return 'metal/sounds/bey-select/Wolf Select.mp3';
      case 'unicorn':
        return 'metal/sounds/bey-select/Unicorn Select.mp3';
      default:
        return 'metal/sounds/select.mp3';
    }
  }

  List<String> get winVoices {
    if (winVoicesOverride != null) return winVoicesOverride!;
    switch (motif) {
      case 'drago':
        return ['metal/sounds/bey-win/Drago Win.mp3'];
      case 'aquario':
        return ['metal/sounds/bey-win/Aquario Win.mp3'];
      case 'aquila':
        return ['metal/sounds/bey-win/Aquila Win.mp3'];
      case 'leone':
        return ['metal/sounds/bey-win/Leone Win.mp3'];
      case 'pegasis':
        return ['metal/sounds/bey-win/Pegasus Win.mp3', 'metal/sounds/bey-win/Pegasus Win 2.mp3'];
      case 'phoenix':
        return ['metal/sounds/bey-win/Phoenix Win.mp3'];
      case 'sagittario':
        return ['metal/sounds/bey-win/Sagittario Win.mp3', 'metal/sounds/bey-win/Sagittario Win 2.mp3'];
      case 'wolf':
        return ['metal/sounds/bey-win/Wolf Win.mp3', 'metal/sounds/bey-win/Wolf Win 2.mp3'];
      case 'unicorn':
        return ['metal/sounds/bey-win/Unicorn Win.mp3'];
      default:
        return ['metal/sounds/select.mp3'];
    }
  }

  String get winName {
    if (winNameOverride != null) return winNameOverride!;
    switch (motif) {
      case 'drago':
        return 'L-Drago';
      case 'aquario':
        return 'Aquario';
      case 'aquila':
        return 'Aquila';
      case 'leone':
        return 'Leone';
      case 'pegasis':
        return 'Pegasus';
      case 'phoenix':
        return 'Phoenix';
      case 'sagittario':
        return 'Sagittario';
      case 'wolf':
        return 'Wolf';
      case 'unicorn':
        return 'Unicorn';
      default:
        return name.split(' ')[1];
    }
  }
}

class BeyWheel extends StatefulWidget {
  final String label;
  final Color color;
  final bool locked;
  final VoidCallback onLock;
  final String fontFamily;
  final bool isLeft;
  final ValueChanged<BeyInfo>? onBeyChanged;
  final bool interactionEnabled;

  const BeyWheel({
    super.key,
    required this.label,
    required this.color,
    required this.locked,
    required this.onLock,
    required this.fontFamily,
    required this.isLeft,
    this.onBeyChanged,
    this.interactionEnabled = true,
  });

  @override
  State<BeyWheel> createState() => _BeyWheelState();
}

class _BeyWheelState extends State<BeyWheel> with TickerProviderStateMixin {
  final List<BeyInfo> beys = [
    const BeyInfo(
        name: "Storm Pegasus 105RF", motif: "pegasis", type: BeyType.attack),
    const BeyInfo(
        name: "Lightning L-Drago 100HF",
        motif: "drago",
        type: BeyType.attack,
        spin: SpinDirection.counterClockwise),
    const BeyInfo(
        name: "Storm Aquario 100HF:S", motif: "aquario", type: BeyType.attack),
    const BeyInfo(
        name: "Earth Aquila 145WD", motif: "aquila", type: BeyType.defense),
    const BeyInfo(
        name: "Rock Leone 145WB", motif: "leone", type: BeyType.defense),
    const BeyInfo(
        name: "Burn Phoenix 135MS", motif: "phoenix", type: BeyType.stamina),
    const BeyInfo(
        name: "Flame Sagittario C-145S",
        motif: "sagittario",
        type: BeyType.stamina),
    const BeyInfo(
        name: "Dark Wolf DF-145FS", motif: "wolf", type: BeyType.balance),
    const BeyInfo(
      name: "Ray Unicorn D-125CS",
      motif: "unicorn",
      type: BeyType.balance,
      imageScale: 1.22,
    ),
    const BeyInfo(
      name: "Samurai Pegasus W-125R2F",
      motif: "samurai-pegasus",
      type: BeyType.attack,
      imageScale: 1.22,
      selectVoiceOverride: 'metal/sounds/bey-select/samurai-pegasus.mp3',
      winVoicesOverride: ['metal/sounds/bey-win/Samurai-Pegasus Win.mp3'],
      winNameOverride: 'Samurai Pegasus',
    ),
  ];

  late FixedExtentScrollController _scrollController;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  late AnimationController _motifController;
  late Animation<double> _motifScale;
  late Animation<double> _motifOpacity;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _echoPlayer1 = AudioPlayer();
  final AudioPlayer _echoPlayer2 = AudioPlayer();

  int _localIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: 0);
    
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOutCubic),
    );

    _motifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _motifScale = Tween<double>(begin: 0.1, end: 1.2).animate(
      CurvedAnimation(parent: _motifController, curve: Curves.easeOutExpo),
    );
    
    _motifOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.25), weight: 70),
    ]).animate(_motifController);

    // Initial notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onBeyChanged != null) {
        widget.onBeyChanged!(beys[_getRealIndex(_localIndex)]);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var bey in beys) {
      precacheImage(AssetImage('assets/metal/images/beys/${bey.name}.png'), context);
      precacheImage(AssetImage(bey.motifAsset), context);
      precacheImage(AssetImage(bey.typeLogo), context);
    }
  }

  @override
  void didUpdateWidget(BeyWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked != widget.locked) {
      if (widget.locked) {
        _spinController.forward();
        _motifController.forward();
        _playSelectVoice();
      } else {
        // Reverse motifs and sparks, but reset/stop rotation
        _spinController.reset();
        _motifController.reverse();
      }
    }
  }

  Future<void> _playSelectVoice() async {
    final currentBey = beys[_getRealIndex(_localIndex)];
    final source = AssetSource(currentBey.selectVoice);
    
    // Main voice - LOWERED VOLUME
    await _audioPlayer.setVolume(0.4);
    await _audioPlayer.play(source);

    // Echo 1
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (mounted && widget.locked) {
        await _echoPlayer1.setVolume(0.12); // Reduced accordingly
        await _echoPlayer1.play(source);
      }
    });

    // Echo 2
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted && widget.locked) {
        await _echoPlayer2.setVolume(0.08); // Reduced accordingly
        await _echoPlayer2.play(source);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _spinController.dispose();
    _motifController.dispose();
    _audioPlayer.dispose();
    _echoPlayer1.dispose();
    _echoPlayer2.dispose();
    super.dispose();
  }

  int _getRealIndex(int index) {
    if (beys.isEmpty) return 0;
    return (index % beys.length + beys.length) % beys.length;
  }

  void _nextBey() {
    if (widget.locked || !widget.interactionEnabled) return;
    _scrollController.animateToItem(
      _scrollController.selectedItem + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _prevBey() {
    if (widget.locked || !widget.interactionEnabled) return;
    _scrollController.animateToItem(
      _scrollController.selectedItem - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBey = beys[_getRealIndex(_localIndex)];

    return Stack(
      children: [
        // BACKGROUND MOTIF SPLASH
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _motifController,
            builder: (context, child) {
              if (_motifController.isDismissed && !widget.locked) {
                return const SizedBox.shrink();
              }
              return OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: _motifScale.value,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    // Narrowed gap by shifting motifs closer (200 pixels)
                    offset: Offset(widget.isLeft ? -200 : 200, 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // GLOW LAYER (Energy silhouette)
                        Opacity(
                          opacity: _motifOpacity.value * 0.7,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                            child: Image.asset(
                              currentBey.motifAsset,
                              color: widget.color,
                              colorBlendMode: BlendMode.srcIn,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
                          ),
                        ),
                        // SHARP LOGO LAYER (Detailed appearance restored)
                        Opacity(
                          opacity: _motifOpacity.value * 0.9,
                          child: Image.asset(
                            currentBey.motifAsset,
                            color: widget.color.withOpacity(0.6),
                            colorBlendMode: BlendMode.modulate, // Shows details instead of silhouette
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
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

        Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: widget.fontFamily,
                letterSpacing: 4,
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLeft) Flexible(child: _buildNamePanel(currentBey)),
                      if (widget.isLeft) const SizedBox(width: 40),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: widget.locked ? 0 : 1,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up,
                                  color: Colors.white, size: 60),
                              onPressed: widget.interactionEnabled ? _prevBey : null,
                            ),
                          ),

                          SizedBox(
                            height: 480,
                            width: 480,
                            child: ListWheelScrollView.useDelegate(
                              controller: _scrollController,
                              itemExtent: 480,
                              clipBehavior: Clip.none,
                              physics: (widget.locked || !widget.interactionEnabled)
                                  ? const NeverScrollableScrollPhysics()
                                  : const FixedExtentScrollPhysics(),
                              overAndUnderCenterOpacity: 0.0,
                              perspective: 0.001,
                              onSelectedItemChanged: (index) {
                                final bey = beys[_getRealIndex(index)];
                                setState(() {
                                  _localIndex = index;
                                });
                                if (widget.onBeyChanged != null) {
                                  widget.onBeyChanged!(bey);
                                }
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  final bey = beys[_getRealIndex(index)];
                                  final isCurrent = _getRealIndex(index) ==
                                      _getRealIndex(_localIndex);

                                  return Center(
                                    child: RotationTransition(
                                      turns: isCurrent
                                          ? _spinAnimation.drive(
                                              Tween(
                                                  begin: 0.0,
                                                  end: bey.spin ==
                                                          SpinDirection.clockwise
                                                      ? 1.0
                                                      : -1.0),
                                            )
                                          : const AlwaysStoppedAnimation(0),
                                      child: AbsorbPointer(
                                        absorbing: !widget.interactionEnabled,
                                        child: GestureDetector(
                                          onTap: widget.interactionEnabled ? (isCurrent ? widget.onLock : _nextBey) : null,
                                          child: MouseRegion(
                                            cursor: widget.interactionEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                                            child: Container(
                                              decoration: isCurrent ? BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: widget.color.withOpacity(0.3),
                                                    blurRadius: 40,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ) : null,
                                              child: Transform.scale(
                                                scale: bey.imageScale,
                                                child: Image.asset(
                                                  'assets/metal/images/beys/${bey.name}.png',
                                                  height: 350,
                                                  width: 350,
                                                  fit: BoxFit.contain,
                                                  gaplessPlayback: true,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(Icons.error_outline, color: Colors.red, size: 80);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          Opacity(
                            opacity: widget.locked ? 0 : 1,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white, size: 60),
                              onPressed: widget.interactionEnabled ? _nextBey : null,
                            ),
                          ),
                        ],
                      ),

                      if (!widget.isLeft) const SizedBox(width: 40),
                      if (!widget.isLeft) Flexible(child: _buildNamePanel(currentBey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // CHISPAS / SPARKS OVERLAY (Optimized Performance)
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _motifController,
              builder: (context, child) {
                return SparksOverlay(
                  spawnFactor: _motifController.value,
                  color: widget.color,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNamePanel(BeyInfo bey) {
    String displayName = bey.name.replaceAll(':', '/').toUpperCase();
    List<String> words = displayName.split(' ');

    String line1 = words.take(2).join(' ');
    String line2 = words.length > 2 ? words.skip(2).join(' ') : '';

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            widget.isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                widget.isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              line1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.w900,
                fontFamily: widget.fontFamily,
                fontStyle: FontStyle.italic,
                height: 0.9,
                shadows: [
                  Shadow(color: widget.color, blurRadius: 25),
                  Shadow(color: widget.color, blurRadius: 10),
                ],
              ),
            ),
          ),
          if (line2.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: widget.isLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  line2,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: widget.fontFamily,
                    fontStyle: FontStyle.italic,
                    height: 1.0,
                    shadows: [
                      Shadow(
                          color: widget.color.withOpacity(0.7), blurRadius: 15),
                    ],
                  ),
                ),
              ),
            ),
          // BEY TYPE DISPLAY (Icon inside the rectangle)
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    bey.typeLogo,
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${bey.type.name.toUpperCase()} TYPE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: widget.fontFamily,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle system for sparks
class SparkParticle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  Color color;

  SparkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  }) : maxLife = life;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 800 * dt;
    life -= dt;
  }
}

class SparksOverlay extends StatefulWidget {
  final double spawnFactor;
  final Color color;
  const SparksOverlay({super.key, required this.spawnFactor, required this.color});

  @override
  State<SparksOverlay> createState() => _SparksOverlayState();
}

class _SparksOverlayState extends State<SparksOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SparkParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..repeat();
    _controller.addListener(_tick);
  }

  void _tick() {
    if (!mounted) return;
    double dt = 0.016;
    
    // We update logic inside tick but only trigger rebuild of the CustomPaint
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(dt);
      if (_particles[i].life <= 0) _particles.removeAt(i);
    }

    double spawnChance = 0.15 + 0.65 * widget.spawnFactor;
    if (_random.nextDouble() < spawnChance) {
      _spawnParticle();
    }
    
    // Trigger paint update
    setState(() {});
  }

  void _spawnParticle() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    double width = renderBox.size.width;
    double height = renderBox.size.height;

    double startX = _random.nextDouble() * width;
    double startY = height;
    
    _particles.add(SparkParticle(
      x: startX,
      y: startY,
      vx: (_random.nextDouble() - 0.5) * 400,
      vy: -_random.nextDouble() * 1200 - 600,
      life: _random.nextDouble() * 0.7 + 0.4,
      color: widget.color,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: SparksPainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class SparksPainter extends CustomPainter {
  final List<SparkParticle> particles;
  SparksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Shared paint objects to avoid allocation in the loop
    final glowPaint = Paint()..strokeCap = StrokeCap.round;
    final corePaint = Paint()..strokeCap = StrokeCap.round;

    for (var p in particles) {
      double ratio = p.life / p.maxLife;
      final color = p.color.withOpacity(ratio);
      
      // 1. Optimized Glow
      glowPaint.color = color.withOpacity(ratio * 0.25);
      glowPaint.strokeWidth = (2.0 + ratio * 4.0) * 6;
      glowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, ratio * 10 + 2);
      
      Offset start = Offset(p.x, p.y);
      Offset end = Offset(p.x - p.vx * 0.02, p.y - p.vy * 0.02);
      
      canvas.drawLine(start, end, glowPaint);

      // 2. High intensity core (More color, less white for performance)
      corePaint.color = Color.lerp(p.color, Colors.white, 0.4)!.withOpacity(ratio);
      corePaint.strokeWidth = 2.0 + ratio * 2.0;
      corePaint.maskFilter = null; // Core doesn't need blur
      
      canvas.drawLine(start, end, corePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
