import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../screens/title_screen.dart';
import '../../../../widgets/bey_wheel.dart';
import '../../domain/battle_session_state.dart';
import 'battle_shared_widgets.dart';

class WinScreenView extends StatelessWidget {
  final BattleSessionState state;
  final BeySeries series;
  final TextStyle textStyle;
  final AnimationController motifController;
  final bool isMusicMuted;
  final String currentTrackLabel;
  final VoidCallback onResetBattle;
  final VoidCallback onToggleMusic;
  final VoidCallback onSkipTrack;

  const WinScreenView({
    super.key,
    required this.state,
    required this.series,
    required this.textStyle,
    required this.motifController,
    required this.isMusicMuted,
    required this.currentTrackLabel,
    required this.onResetBattle,
    required this.onToggleMusic,
    required this.onSkipTrack,
  });

  @override
  Widget build(BuildContext context) {
    final winBey = state.winningBey;
    if (winBey == null) return const SizedBox.shrink();

    final winColor = state.winnerIsLeft ? Colors.redAccent : Colors.blueAccent;
    final rotationSign =
        winBey.spin == SpinDirection.clockwise ? 1.0 : -1.0;

    return KeyedSubtree(
      key: const ValueKey('win'),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: motifController,
                builder: (context, child) {
                  return Center(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Transform.scale(
                        scale: 1.4 + (motifController.value * 0.4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 0.2 + (motifController.value * 0.1),
                              child: ImageFiltered(
                                imageFilter:
                                    ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: Image.asset(
                                  winBey.motifAsset,
                                  color: winColor,
                                  colorBlendMode: BlendMode.srcIn,
                                  height: 800,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: 0.4 + (motifController.value * 0.2),
                              child: Image.asset(
                                winBey.motifAsset,
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
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: motifController,
                  builder: (context, child) {
                    return SparksOverlay(
                      spawnFactor: 0.5 + (motifController.value * 0.5),
                      color: winColor,
                    );
                  },
                ),
              ),
            ),
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
                        scale: (0.8 + (value * 0.2)) * winBey.imageScale,
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
                        winBey.imageAsset,
                        height: 400,
                        width: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: motifController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: (motifController.value * 4).clamp(0.0, 1.0),
                        child: child,
                      );
                    },
                    child: Text(
                      state.finishText,
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
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: onResetBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
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
            Positioned(
              bottom: 10,
              right: 10,
              child: BattleMusicControls(
                showControls: series == BeySeries.metal,
                onRight: true,
                isMusicMuted: isMusicMuted,
                currentTrackLabel: currentTrackLabel,
                textStyle: textStyle,
                onToggleMusic: onToggleMusic,
                onSkipTrack: onSkipTrack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
