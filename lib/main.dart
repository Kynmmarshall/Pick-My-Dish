import 'package:flutter/material.dart';
import 'package:pick_my_dish/Screens/splash_screen.dart';

void main() {
  runApp(const PickMyDish());
}

class PickMyDish extends StatelessWidget {
  const PickMyDish({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
    home: SplashScreen(),
    );
  }
}
