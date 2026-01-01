// Import Flutter material design package
import 'package:flutter/material.dart';

// Import Provider classes for state management
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';

// Import Provider package
import 'package:provider/provider.dart';

// Import application screens
import 'package:pick_my_dish/Screens/splash_screen.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';

/// Application entry point
void main() {
  // Wrap the app with MultiProvider to provide global state objects
  runApp(
    MultiProvider(
      providers: [
        // Provides UserProvider across the entire app
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // Provides RecipeProvider across the entire app
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],

      // Root widget of the application
      child: const PickMyDish(),
    ),
  );
}

/// Root widget of the application
class PickMyDish extends StatefulWidget {
  const PickMyDish({super.key});

  @override
  State<PickMyDish> createState() => _PickMyDishState();
}

/// State class for PickMyDish
class _PickMyDishState extends State<PickMyDish> {
  // Controls whether the app is still initializing
  bool _isInitializing = true;

  // Determines which screen to show after initialization
  Widget _initialScreen = const SplashScreen();

  @override
  void initState() {
    super.initState();

    // Start app initialization logic
    _initializeApp();
  }

  /// Initializes the application
  /// - Loads user session
  /// - Determines initial screen
  Future<void> _initializeApp() async {
    debugPrint('🚀 Initializing application...');

    // Access UserProvider without listening for UI changes
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );

    // Initialize user session (e.g., check stored login)
    await userProvider.initialize();

    // Keep splash screen visible for a short duration
    await Future.delayed(const Duration(milliseconds: 1500));

    // Ensure widget is still mounted before updating state
    if (mounted) {
      setState(() {
        // Initialization is complete
        _isInitializing = false;

        // Decide which screen to show
        if (userProvider.isLoggedIn) {
          // User is authenticated
          debugPrint('✅ User is logged in, going to HomeScreen');
          _initialScreen = const HomeScreen();
        } else {
          // User is not authenticated
          debugPrint('🔒 User is not logged in, going to LoginScreen');
          _initialScreen = const LoginScreen();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove debug banner
      debugShowCheckedModeBanner: false,

      // Application title
      title: 'Pick My Dish',

      // Global application theme
      theme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // Show splash screen while initializing,
      // otherwise show the selected initial screen
      home: _isInitializing ? const SplashScreen() : _initialScreen,

      // Named routes for navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },

      // Route guard logic
      onGenerateRoute: (settings) {
        // Prevent logged-in users from going back to login screen
        if (settings.name == '/login') {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);

          if (userProvider.isLoggedIn) {
            // Redirect logged-in users to home screen
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
          }
        }
        return null;
      },
    );
  }
}


