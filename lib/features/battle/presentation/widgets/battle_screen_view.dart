import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../screens/title_screen.dart';
import '../../../../widgets/bey_wheel.dart';
import '../../domain/battle_session_state.dart';
import 'battle_shared_widgets.dart';

class BattleScreenView extends StatelessWidget {
  final BattleSessionState state;
  final BeySeries series;
  final String font;
  final TextStyle textStyle;
  final List<String> countdownSequence;
  final List<BeyInfo> beys;
  final Animation<Offset> countdownSlide;
  final Animation<double> finishOpacity;
  final Animation<Offset> finishSlide;
  final VideoPlayerController? videoController;
  final bool showVideo;
  final bool isVideoReady;
  final bool isClosingVideo;
  final bool isMusicMuted;
  final String currentTrackLabel;
  final VoidCallback onPointerDown;
  final VoidCallback onLeftLockToggle;
  final VoidCallback onRightLockToggle;
  final ValueChanged<BeyInfo> onLeftBeyChanged;
  final ValueChanged<BeyInfo> onRightBeyChanged;
  final VoidCallback onPlay;
  final VoidCallback onWarning;
  final VoidCallback onLeftSpinFinish;
  final VoidCallback onLeftOverFinish;
  final VoidCallback onRightSpinFinish;
  final VoidCallback onRightOverFinish;
  final VoidCallback onToggleMusic;
  final VoidCallback onSkipTrack;
  final VoidCallback onResetScores;
  final VoidCallback onCloseVideo;

  const BattleScreenView({
    super.key,
    required this.state,
    required this.series,
    required this.font,
    required this.textStyle,
    required this.countdownSequence,
    required this.beys,
    required this.countdownSlide,
    required this.finishOpacity,
    required this.finishSlide,
    required this.videoController,
    required this.showVideo,
    required this.isVideoReady,
    required this.isClosingVideo,
    required this.isMusicMuted,
    required this.currentTrackLabel,
    required this.onPointerDown,
    required this.onLeftLockToggle,
    required this.onRightLockToggle,
    required this.onLeftBeyChanged,
    required this.onRightBeyChanged,
    required this.onPlay,
    required this.onWarning,
    required this.onLeftSpinFinish,
    required this.onLeftOverFinish,
    required this.onRightSpinFinish,
    required this.onRightOverFinish,
    required this.onToggleMusic,
    required this.onSkipTrack,
    required this.onResetScores,
    required this.onCloseVideo,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('battle'),
      child: Listener(
        onPointerDown: (_) => onPointerDown(),
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
                      locked: state.leftLocked,
                      onLock: onLeftLockToggle,
                      fontFamily: font,
                      beys: beys,
                      onBeyChanged: onLeftBeyChanged,
                      interactionEnabled: state.interactionEnabled,
                    ),
                  ),
                  Expanded(
                    child: BeyWheel(
                      key: const ValueKey('p2'),
                      label: 'PLAYER 2',
                      isLeft: false,
                      color: Colors.blueAccent,
                      locked: state.rightLocked,
                      onLock: onRightLockToggle,
                      fontFamily: font,
                      beys: beys,
                      onBeyChanged: onRightBeyChanged,
                      interactionEnabled: state.interactionEnabled,
                    ),
                  ),
                ],
              ),
              if (state.phase == ArenaPhase.selecting)
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
              _ScoreDisplay(
                score: state.leftScore,
                color: Colors.redAccent,
                textStyle: textStyle,
                alignment: Alignment.bottomLeft,
                offset: const Offset(-10, -120),
              ),
              _ScoreDisplay(
                score: state.rightScore,
                color: Colors.blueAccent,
                textStyle: textStyle,
                alignment: Alignment.bottomRight,
                offset: const Offset(50, -120),
              ),
              if (state.bothLocked && state.phase == ArenaPhase.selecting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 200.0),
                    child: ElevatedButton(
                      onPressed: onPlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        'PLAY',
                        style: textStyle.copyWith(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              if (state.phase == ArenaPhase.countdown) ...[
                if (!state.isAnimatingFinish)
                  Center(
                    child: IgnorePointer(
                      child: SlideTransition(
                        position: countdownSlide,
                        child: Text(
                          state.countdownIndex < countdownSequence.length
                              ? countdownSequence[state.countdownIndex]
                              : 'VS',
                          style: textStyle.copyWith(
                            fontSize: state.countdownIndex == 4
                                ? 72
                                : (state.countdownIndex == 5 ? 60 : 56),
                            fontWeight: FontWeight.bold,
                            fontStyle: state.countdownIndex == 5
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: state.countdownIndex == 5
                                ? Colors.white.withOpacity(0.6)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!state.isAnimatingFinish)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: onWarning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.8),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                if (!state.isAnimatingFinish)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Column(
                      children: [
                        FinishButton(
                          label: '1 pt. SPIN FINISH',
                          onPressed: onLeftSpinFinish,
                          color: Colors.redAccent,
                          textStyle: textStyle,
                        ),
                        const SizedBox(height: 15),
                        FinishButton(
                          label: '2 pt. OVER FINISH',
                          onPressed: onLeftOverFinish,
                          color: Colors.redAccent,
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),
                if (!state.isAnimatingFinish)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Column(
                      children: [
                        FinishButton(
                          label: '1 pt. SPIN FINISH',
                          onPressed: onRightSpinFinish,
                          color: Colors.blueAccent,
                          textStyle: textStyle,
                        ),
                        const SizedBox(height: 15),
                        FinishButton(
                          label: '2 pt. OVER FINISH',
                          onPressed: onRightOverFinish,
                          color: Colors.blueAccent,
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),
              ],
              if (state.finishText.isNotEmpty)
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: finishOpacity,
                      child: SlideTransition(
                        position: finishSlide,
                        child: Center(
                          child: Text(
                            state.finishText,
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 4,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.orange, blurRadius: 40),
                                Shadow(color: Colors.white, blurRadius: 10),
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
                child: BattleMusicControls(
                  showControls: series == BeySeries.metal,
                  onRight: false,
                  isMusicMuted: isMusicMuted,
                  currentTrackLabel: currentTrackLabel,
                  textStyle: textStyle,
                  onToggleMusic: onToggleMusic,
                  onSkipTrack: onSkipTrack,
                  onResetScores: onResetScores,
                ),
              ),
              if (showVideo)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: onCloseVideo,
                    child: AnimatedOpacity(
                      opacity: isClosingVideo ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: (isVideoReady && videoController != null)
                              ? AspectRatio(
                                  aspectRatio: videoController!.value.aspectRatio,
                                  child: VideoPlayer(videoController!),
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
}

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final Color color;
  final TextStyle textStyle;
  final Alignment alignment;
  final Offset offset;

  const _ScoreDisplay({
    required this.score,
    required this.color,
    required this.textStyle,
    required this.alignment,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: offset.dy,
      left: alignment == Alignment.bottomLeft ? offset.dx : null,
      right: alignment == Alignment.bottomRight ? offset.dx : null,
      child: IgnorePointer(
        child: Text(
          '$score',
          style: textStyle.copyWith(
            fontSize: 320,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: color.withOpacity(0.8), blurRadius: 25),
              Shadow(color: color.withOpacity(0.5), blurRadius: 50),
            ],
          ),
        ),
      ),
    );
  }
}
