import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';

/// FakeFavoriteProvider
/// ------------------------------------------------------------
/// A mock provider used ONLY for testing purposes.
/// It simulates a favorite system without real logic or API calls.
/// Useful for widget tests where the real backend is not required.
class FakeFavoriteProvider extends ChangeNotifier {

  /// List holding fake favorite recipe objects
  List<dynamic> favorites = [];

  /// List holding IDs of favorite recipes
  List<int> favoriteIds = [];
  
  /// Checks whether a recipe is marked as favorite
  /// Always returns false because this is a fake implementation
  bool isFavorite(dynamic recipe) => false;
  
  /// Toggles favorite state (mock implementation)
  /// Does nothing but keeps async signature for compatibility
  Future<void> toggleFavorite(dynamic recipe) async {}
  
  /// Loads favorites (mock implementation)
  /// Does nothing but mimics async behavior
  Future<void> loadFavorites() async {}
}

/// Helper Function: createTestRecipes
/// ------------------------------------------------------------
/// Generates a list of fake recipe maps for testing UI components.
/// This avoids dependency on real API data.
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

/// Helper Function: createTestableWidget
/// ------------------------------------------------------------
/// Wraps a widget inside MaterialApp and Scaffold.
/// Required for widgets that depend on Material context
/// such as Theme, Navigator, SnackBar, etc.
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Helper Function: wrapWithProviders
/// ------------------------------------------------------------
/// Wraps a widget with required providers for testing.
/// This allows widgets to access RecipeProvider and UserProvider
/// without launching the full application.
///
/// Commonly used in widget tests.
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

