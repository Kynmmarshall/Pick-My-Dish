import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:provider/provider.dart';

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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    
    await Future.delayed(const Duration(seconds: 2));
    
    final success = await userProvider.autoLogin();

    if (!mounted) return;
    
    if (success) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
  
  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/logo.png'),
            const SizedBox(height: 20),
            Text(
              "What should I eat today?",
              style: TextStyle(
                color: onSurfaceColor,
                fontSize: 18,
                fontFamily: 'TimesNewRoman',
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: primaryColor),
          ],
        ),
      ),
    );
  }
}
