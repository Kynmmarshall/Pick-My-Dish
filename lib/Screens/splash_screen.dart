import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pick_my_dish/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/logo.png'),
            const SizedBox(height: 20),
            const Text(
              "PICK MY DISH",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'TimesNewRoman',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "What should I eat today?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'TimesNewRoman',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
