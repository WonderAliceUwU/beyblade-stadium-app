import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'player_select_screen.dart';

enum BeySeries { x, metal }

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _leftSlide;
  late Animation<Offset> _rightSlide;
  final AudioPlayer _audioPlayer = AudioPlayer();

  BeySeries? selectedSeries;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _leftSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _rightSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  void selectSeries(BeySeries series) async {
    if (selectedSeries != null) return;

    setState(() => selectedSeries = series);

    // Play sound effect
    try {
      await _audioPlayer.play(AssetSource('metal/sounds/select.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    await _controller.forward();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerSelectScreen(series: series),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: SlideTransition(
                  position: _leftSlide,
                  child: _SidePanel(
                    logo: SvgPicture.asset(
                      'assets/metal/images/X-logo.svg',
                      width: 600,
                      fit: BoxFit.contain,
                    ),
                    color: Colors.white,
                    onTap: () => selectSeries(BeySeries.x),
                  ),
                ),
              ),
              Expanded(
                child: SlideTransition(
                  position: _rightSlide,
                  child: _SidePanel(
                    logo: Image.asset(
                      'assets/metal/images/metal-logo.png',
                      width: 600,
                      fit: BoxFit.contain,
                    ),
                    color: Colors.black,
                    onTap: () => selectSeries(BeySeries.metal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final Widget logo;
  final Color color;
  final VoidCallback onTap;

  const _SidePanel({
    required this.logo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: color,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: logo,
          ),
        ),
      ),
    );
  }
}
