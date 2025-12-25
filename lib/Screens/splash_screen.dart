import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/logo/logo.png',
              width: 150,
              height: 150,
            ),
            
            const SizedBox(height: 30),
            
            // App Title
            const Text(
              "PICK MY DISH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'TimesNewRoman',
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Tagline
            const Text(
              "What should I eat today?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'TimesNewRoman',
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 20),
            
            // Loading text
            const Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
