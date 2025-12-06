import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Screens/splash_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/register_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/home_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/ingredient_input_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/recipe_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/favorite_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/profile_screen.dart'; // ADDED
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart'; // ADDED

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

class PickMyDish extends StatelessWidget {
  const PickMyDish({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/ingredients': (context) => const IngredientInputScreen(),
        '/recipes': (context) => const RecipesScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/upload': (context) => const RecipeUploadScreen(),
      },
    );
  }
}
