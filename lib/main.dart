import 'package:flutter/material.dart';
import 'screens/title_screen.dart';

void main() {
  runApp(const BeybladeStadiumApp());
}

class BeybladeStadiumApp extends StatelessWidget {
  const BeybladeStadiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TitleScreen(),
    );
  }
}