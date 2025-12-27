import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Services/api_service.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _userFavorites = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _userFavorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get mounted => true; 

  // Check if recipe is favorite
  bool isFavorite(int recipeId) => _userFavorites.any((recipe) => recipe.id == recipeId);

  // Toggle favorite
  Future<void> toggleFavorite(int userId, int recipeId) async {
    debugPrint('🔄 RecipeProvider.toggleFavorite called');
    debugPrint('   👤 User ID: $userId');
    debugPrint('   📝 Recipe ID: $recipeId');
    
    if (userId == 0) {
      debugPrint('❌ Cannot toggle favorite: User ID is 0 (not logged in)');
      return;
    }

    final recipe = getRecipeById(recipeId);
    if (recipe == null) {
      debugPrint('❌ Cannot toggle favorite: Recipe $recipeId not found');
      return;
    }

    debugPrint('🔍 Checking if recipe is already favorite...');
    bool wasFavorite = isFavorite(recipeId);
    debugPrint('   📊 Currently favorite? $wasFavorite');
    
    bool success;
    if (wasFavorite) {
      debugPrint('🗑️ Removing from favorites...');
      success = await ApiService.removeFromFavorites(userId, recipeId);
      if (success) {
        _userFavorites.removeWhere((r) => r.id == recipeId);
        debugPrint('✅ Removed from local list');
      }
    } else {
      debugPrint('💖 Adding to favorites...');
      success = await ApiService.addToFavorites(userId, recipeId);
      if (success) {
        _userFavorites.add(recipe);
        debugPrint('✅ Added to local list');
      }
    }

    debugPrint('📊 API call result: $success');
    
    if (success) {
      // Update main recipes list
      final index = _recipes.indexWhere((r) => r.id == recipeId);
      if (index != -1) {
        _recipes[index] = _recipes[index].copyWith(isFavorite: !wasFavorite);
        debugPrint('🔄 Updated recipe in main list');
      }
      
      // Sync all recipes
      _syncFavoriteStatus();
      await loadRecipes();
      // Schedule UI update
      Future.microtask(() {
        debugPrint('📢 Notifying listeners...');
        notifyListeners();
        debugPrint('📊 Current favorites count: ${_userFavorites.length}');
      });
    } else {
      debugPrint('❌ API call failed - favorite not saved to database');
    }
  }
  
  // Get recipe by ID
  Recipe? getRecipeById(int id) {
    try {
      return _recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }
  
 // Load user's favorite recipes
  Future<void> loadUserFavorites(int userId) async {
  if (userId == 0) {
    _userFavorites = [];
    // Schedule for next frame
    Future.microtask(() {
      notifyListeners();
    });
    return;
  }
  
  _isLoading = true;
  
  try {
    final favoriteMaps = await ApiService.getUserFavorites(userId);
    _userFavorites = favoriteMaps.map((map) => Recipe.fromJson(map)).toList();
  } catch (e) {
    _error = 'Failed to load favorites: $e';
    debugPrint('❌ Error loading user favorites: $e');
  } finally {
    _isLoading = false;
    // Schedule for next frame
    Future.microtask(() {
      notifyListeners();
    });
  }
}
  
  // Clear on logout
  void logout() {
    _recipes.clear();
    _userFavorites.clear();
    notifyListeners();
  }

  // Load all recipes from API
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> recipeMaps = await ApiService.getRecipes();
      _recipes = recipeMaps.map((json) => Recipe.fromJson(json)).toList();
      
      // CRITICAL: Sync favorite status with _userFavorites list
      _syncFavoriteStatus();
      
    } catch (e) {
      _error = 'Failed to load recipes: $e';
      debugPrint('❌ RecipeProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  //sync favorite status of recipes
  void _syncFavoriteStatus() {
    // Update each recipe's isFavorite based on _userFavorites
    for (int i = 0; i < _recipes.length; i++) {
      final recipe = _recipes[i];
      final isFav = _userFavorites.any((fav) => fav.id == recipe.id);
      if (recipe.isFavorite != isFav) {
        _recipes[i] = recipe.copyWith(isFavorite: isFav);
      }
    }
    
    debugPrint('🔄 Synced favorite status for ${_recipes.length} recipes');
    debugPrint('   Total favorites: ${_userFavorites.length}');
  }

  // Filter recipes (for search)
  List<Recipe> filterRecipes(String query) {
    if (query.isEmpty) return _recipes;
    
    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(query.toLowerCase()) ||
             recipe.category.toLowerCase().contains(query.toLowerCase()) ||
             recipe.moods.any((mood) => mood.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // Personalize recipes (from your home screen)
  List<Recipe> personalizeRecipes({
    List<String>? ingredients,
    String? mood,
    String? time,
  }) {
    return _recipes.where((recipe) {
      bool matches = true;
      
      if (ingredients != null && ingredients.isNotEmpty) {
        matches = ingredients.any((ing) => 
          recipe.ingredients.any((recipeIng) => 
            recipeIng.toLowerCase().contains(ing.toLowerCase())
          )
        );
      }
      
      if (mood != null && mood.isNotEmpty) {
        matches = matches && recipe.moods.contains(mood);
      }
      
      if (time != null && time.isNotEmpty) {
        // Simple time matching - you can improve this
        matches = matches && recipe.cookingTime.contains(time);
      }
      
      return matches;
    }).toList();
  }

  // Check if recipe can be edited/deleted by current user
  bool canEditRecipe(int recipeId, int userId, bool isAdmin) {
    final recipe = getRecipeById(recipeId);
    if (recipe == null) return false;
    return isAdmin || recipe.userId == userId;
  }

  bool canDeleteRecipe(int recipeId, int userId, bool isAdmin) {
    return canEditRecipe(recipeId, userId, isAdmin);
  }

  // Load recipes with permissions
  Future<void> loadRecipesWithPermissions(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recipeMaps = await ApiService.getRecipesWithPermissions(userId);
      _recipes = recipeMaps.map((json) => Recipe.fromJson(json)).toList();
      
      _syncFavoriteStatus();
      
    } catch (e) {
      _error = 'Failed to load recipes: $e';
      debugPrint('❌ RecipeProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete recipe
  Future<bool> deleteRecipe(int recipeId, int userId) async {
    debugPrint('📤 RecipeProvider.deleteRecipe called: recipeId=$recipeId, userId=$userId');
    try {
      final success = await ApiService.deleteRecipe(recipeId, userId);
      debugPrint('📡 ApiService.deleteRecipe response: $success');
      if (success) {
        _recipes.removeWhere((recipe) => recipe.id == recipeId);
        _userFavorites.removeWhere((recipe) => recipe.id == recipeId);
        debugPrint('✅ Recipe removed from local lists');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return false;
    }
  }

}