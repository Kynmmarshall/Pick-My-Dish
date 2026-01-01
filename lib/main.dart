
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Screens/splash_screen.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const PickMyDish(),
    ),
  );
}

class PickMyDish extends StatefulWidget {
  const PickMyDish({super.key});

  @override
  State<PickMyDish> createState() => _PickMyDishState();
}

class _PickMyDishState extends State<PickMyDish> {
  bool _isInitializing = true;
  Widget _initialScreen = const SplashScreen();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('🚀 Initializing application...');
    
    
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    
    await userProvider.initialize();
    
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
        
        
        if (userProvider.isLoggedIn) {
          debugPrint('✅ User is logged in, going to HomeScreen');
          _initialScreen = const HomeScreen();
        } else {
          debugPrint('🔒 User is not logged in, going to LoginScreen');
          _initialScreen = const LoginScreen();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pick My Dish',
      theme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: _isInitializing ? const SplashScreen() : _initialScreen,
      
      
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      
      
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.isLoggedIn) {
            // If user is logged in, redirect to home
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          }
        }
        return null;
      },
    );
  }

}

















