// main.dart - SIMPLER VERSION
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/theme_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/Themes/theme.dart';
import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service (load token from storage)
  await ApiService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    
    try {
      // Try to auto-login with stored token
      final success = await userProvider.autoLogin();

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Auto-login successful');
        
        await recipeProvider.loadUserFavorites();
      } else {
        debugPrint('❌ No valid token found');
      }
    } catch (e) {
      debugPrint('❌ Auto-login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 20),
                Text('Loading...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              // Show login screen if not logged in, home screen if logged in
              return userProvider.isLoggedIn ? HomeScreen() : LoginScreen();
            },
          ),
        );
      },
    );
  }
}