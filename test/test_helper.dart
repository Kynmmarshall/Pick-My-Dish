import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';

class FakeFavoriteProvider extends ChangeNotifier {
  List<dynamic> favorites = [];
  List<int> favoriteIds = [];
  
  bool isFavorite(dynamic recipe) => false;
  
  Future<void> toggleFavorite(dynamic recipe) async {}
  
  Future<void> loadFavorites() async {}
}

// Helper to create test recipes
List<Map<String, dynamic>> createTestRecipes({int count = 5}) {
  return List.generate(count, (index) => {
    'category': index % 2 == 0 ? 'Breakfast' : 'Dinner',
    'name': 'Test Recipe ${index + 1}',
    'time': '${10 + index}:00',
    'isFavorite': false,
    'image': 'assets/recipes/test.png',
    'calories': '${1000 + index}'
  });
}

// Test wrapper for widgets
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
  
}

// test_helper.dart
Widget wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}