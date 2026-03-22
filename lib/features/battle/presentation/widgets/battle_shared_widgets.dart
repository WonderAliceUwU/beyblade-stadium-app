import 'package:flutter/material.dart';

class FinishButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final TextStyle textStyle;

  const FinishButton({
    super.key,
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

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startScrolling() async {
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 2));

    while (mounted && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) break;

      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 40).toInt()),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted || !_scrollController.hasClients) break;
      _scrollController.jumpTo(0);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minWidth: 150),
        child: Text(widget.text, style: widget.style, maxLines: 1),
      ),
    );
  }
}

class BattleMusicControls extends StatelessWidget {
  final bool showControls;
  final bool onRight;
  final bool isMusicMuted;
  final String currentTrackLabel;
  final TextStyle textStyle;
  final VoidCallback onToggleMusic;
  final VoidCallback onSkipTrack;
  final VoidCallback? onResetScores;

  const BattleMusicControls({
    super.key,
    required this.showControls,
    required this.onRight,
    required this.isMusicMuted,
    required this.currentTrackLabel,
    required this.textStyle,
    required this.onToggleMusic,
    required this.onSkipTrack,
    this.onResetScores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          onRight ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        if (showControls)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment:
                  onRight ? MainAxisAlignment.end : MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isMusicMuted ? Icons.music_off : Icons.music_note,
                    color: Colors.white54,
                    size: 28,
                  ),
                  onPressed: onToggleMusic,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  height: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: MarqueeText(
                      key: ValueKey<String>(currentTrackLabel),
                      text: currentTrackLabel,
                      style: textStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white54, size: 28),
                  onPressed: onSkipTrack,
                ),
              ],
            ),
          ),
        if (!onRight && onResetScores != null)
          TextButton(
            onPressed: onResetScores,
            child: Text(
              'RESET ALL SCORES',
              style: textStyle.copyWith(fontSize: 14, color: Colors.white54),
            ),
          ),
      ],
    );
  }
}
