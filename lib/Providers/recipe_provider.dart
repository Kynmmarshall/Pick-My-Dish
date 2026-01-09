import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Services/api_service.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _userFavorites = [];
  bool _isLoading = false;
  String? _error;
  Future<List<Map<String, dynamic>>> Function()? _fetchRecipesOverride;
  Future<List<Map<String, dynamic>>> Function()? _fetchRecipesWithPermissionsOverride;
  Future<List<Map<String, dynamic>>> Function()? _fetchFavoritesOverride;
  Future<bool> Function(int recipeId)? _addFavoriteOverride;
  Future<bool> Function(int recipeId)? _removeFavoriteOverride;
  Future<bool> Function(int recipeId)? _deleteRecipeOverride;

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _userFavorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get mounted => true; 
   bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @visibleForTesting
  void overrideApiForTest({
    Future<List<Map<String, dynamic>>> Function()? fetchRecipes,
    Future<List<Map<String, dynamic>>> Function()? fetchRecipesWithPermissions,
    Future<List<Map<String, dynamic>>> Function()? fetchFavorites,
    Future<bool> Function(int recipeId)? addFavorite,
    Future<bool> Function(int recipeId)? removeFavorite,
    Future<bool> Function(int recipeId)? deleteRecipe,
  }) {
    _fetchRecipesOverride = fetchRecipes ?? _fetchRecipesOverride;
    _fetchRecipesWithPermissionsOverride =
        fetchRecipesWithPermissions ?? _fetchRecipesWithPermissionsOverride;
    _fetchFavoritesOverride = fetchFavorites ?? _fetchFavoritesOverride;
    _addFavoriteOverride = addFavorite ?? _addFavoriteOverride;
    _removeFavoriteOverride = removeFavorite ?? _removeFavoriteOverride;
    _deleteRecipeOverride = deleteRecipe ?? _deleteRecipeOverride;
  }

  @visibleForTesting
  void resetApiOverrides() {
    _fetchRecipesOverride = null;
    _fetchRecipesWithPermissionsOverride = null;
    _fetchFavoritesOverride = null;
    _addFavoriteOverride = null;
    _removeFavoriteOverride = null;
    _deleteRecipeOverride = null;
  }

  @visibleForTesting
  void setRecipesForTest(List<Recipe> recipes) {
    _recipes = List<Recipe>.from(recipes);
    safeNotify();
  }

  @visibleForTesting
  void setFavoritesForTest(List<Recipe> favorites) {
    _userFavorites = List<Recipe>.from(favorites);
    safeNotify();
  }

  @visibleForTesting
  void syncFavoritesForTest() {
    _syncFavoriteStatus();
    safeNotify();
  }
  // Check if recipe is favorite
  bool isFavorite(int recipeId) => _userFavorites.any((recipe) => recipe.id == recipeId);

  Recipe? _favoriteById(int recipeId) {
    try {
      return _userFavorites.firstWhere((recipe) => recipe.id == recipeId);
    } catch (_) {
      return null;
    }
  }

  void _updateFavoriteFlag(int recipeId, bool isFavorite) {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(isFavorite: isFavorite);
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite( int recipeId) async {
    debugPrint('🔄 RecipeProvider.toggleFavorite called');
    debugPrint('   📝 Recipe ID: $recipeId');

    final recipe = getRecipeById(recipeId) ?? _favoriteById(recipeId);
    if (recipe == null) {
      debugPrint('❌ Cannot toggle favorite: Recipe $recipeId not found');
      return;
    }

    debugPrint('🔍 Checking if recipe is already favorite...');
    bool wasFavorite = isFavorite(recipeId);
    debugPrint('   📊 Currently favorite? $wasFavorite');
    
    bool success = false;
    final addFavorite = _addFavoriteOverride ?? ApiService.addToFavorites;
    final removeFavorite = _removeFavoriteOverride ?? ApiService.removeFromFavorites;
    if (wasFavorite) {
      debugPrint('🗑️ Removing from favorites...');
      final removedFavorite = _favoriteById(recipeId);
      _userFavorites.removeWhere((r) => r.id == recipeId);
      _updateFavoriteFlag(recipeId, false);
      safeNotify(); // Optimistic removal keeps Dismissible from throwing
      success = await removeFavorite(recipeId);
      if (!success && removedFavorite != null) {
        debugPrint('↩️ Remove failed, restoring favorite locally');
        _userFavorites.add(removedFavorite);
        _updateFavoriteFlag(recipeId, true);
        safeNotify();
      }
    } else {
      debugPrint('💖 Adding to favorites...');
      final favoriteEntry = recipe.copyWith(isFavorite: true);
      _userFavorites.add(favoriteEntry);
      _updateFavoriteFlag(recipeId, true);
      safeNotify(); // Update listeners immediately so UI reflects new favorite
      success = await addFavorite(recipeId);
      if (!success) {
        debugPrint('↩️ Add failed, rolling back local favorite');
        _userFavorites.removeWhere((r) => r.id == recipeId);
        _updateFavoriteFlag(recipeId, false);
        safeNotify();
      }
    }

    debugPrint('📊 API call result: $success');
    
    if (success) {
      // Update main recipes list
      _updateFavoriteFlag(recipeId, !wasFavorite);
      debugPrint('🔄 Updated recipe in main list');
      
      // Sync all recipes
      _syncFavoriteStatus();
      await loadRecipes();
      // Schedule UI update
      Future.microtask(() {
        debugPrint('📢 Notifying listeners...');
        safeNotify();
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
  Future<void> loadUserFavorites() async {
  _isLoading = true;
  
  try {
    final loader = _fetchFavoritesOverride ?? ApiService.getUserFavorites;
    final favoriteMaps = await loader();
    _userFavorites = favoriteMaps.map((map) => Recipe.fromJson(map)).toList();
  } catch (e) {
    _error = 'Failed to load favorites: $e';
    debugPrint('❌ Error loading user favorites: $e');
  } finally {
    _isLoading = false;
    // Schedule for next frame
    Future.microtask(() {
      safeNotify();
    });
  }
}
  
  // Clear on logout
  void logout() {
    _recipes.clear();
    _userFavorites.clear();
    safeNotify();
  }

  // Load all recipes from API
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    safeNotify();

    try {
      final fetcher = _fetchRecipesOverride ?? ApiService.getRecipes;
      final List<Map<String, dynamic>> recipeMaps = await fetcher();
      _recipes = recipeMaps.map((json) => Recipe.fromJson(json)).toList();
      
      // CRITICAL: Sync favorite status with _userFavorites list
      _syncFavoriteStatus();
      
    } catch (e) {
      _error = 'Failed to load recipes: $e';
      debugPrint('❌ RecipeProvider load error: $e');
    } finally {
      _isLoading = false;
      safeNotify();
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
  // In RecipeProvider class
  bool canEditRecipe(int recipeId, int currentUserId, bool isAdmin) {
    debugPrint('🔍 Checking edit permission:');
    debugPrint('   Recipe ID: $recipeId');
    debugPrint('   Is Admin: $isAdmin');
    debugPrint('   Available recipes count: ${_recipes.length}');
    
    // Check admin first
    if (isAdmin) {
      debugPrint('   ✅ User is admin - allowing edit');
      return true;
    }
    
    // Find the recipe
    final recipe = _recipes.firstWhere(
      (recipe) => recipe.id == recipeId,
      orElse: () => Recipe.empty(),
    );
    
    
    debugPrint('   Recipe found: ${recipe.id != 0}');
    debugPrint('   Recipe creator ID: ${recipe.userId}');
    final canEdit = recipe.id != 0;
    debugPrint('   Can edit (non-admin): $canEdit');
    
    // Check if current user owns this recipe
    return recipe.id != 0 && recipe.userId == currentUserId;

  }

  bool canDeleteRecipe(int recipeId, int currentUserId, bool isAdmin) {
    return canEditRecipe(recipeId, currentUserId, isAdmin);
  }

  // Load recipes with permissions
  Future<void> loadRecipesWithPermissions() async {
    _isLoading = true;
    _error = null;
    safeNotify();

    try {
        final fetcher =
          _fetchRecipesWithPermissionsOverride ?? ApiService.getRecipesWithPermissions;
        final recipeMaps = await fetcher();
      _recipes = recipeMaps.map((json) => Recipe.fromJson(json)).toList();
      
      _syncFavoriteStatus();
      
    } catch (e) {
      _error = 'Failed to load recipes: $e';
      debugPrint('❌ RecipeProvider load error: $e');
    } finally {
      _isLoading = false;
      safeNotify();
    }
  }

  // Delete recipe
  Future<bool> deleteRecipe(int recipeId) async {
    debugPrint('📤 RecipeProvider.deleteRecipe called: recipeId=$recipeId');
    try {
      final deleter = _deleteRecipeOverride ?? ApiService.deleteRecipe;
      final success = await deleter(recipeId);
      debugPrint('📡 ApiService.deleteRecipe response: $success');
      if (success) {
        _recipes.removeWhere((recipe) => recipe.id == recipeId);
        _userFavorites.removeWhere((recipe) => recipe.id == recipeId);
        debugPrint('✅ Recipe removed from local lists');
        safeNotify();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return false;
    }
  }

  // Load single recipe by ID
  Future<void> loadSingleRecipe(int recipeId) async {
    try {
      final recipeMaps = await ApiService.getRecipes();
      final allRecipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();
      final currentRecipe = allRecipes.firstWhere(
        (r) => r.id == recipeId,
        orElse: () => Recipe.empty(),
      );
      
      // Replace in list or store separately
      final index = _recipes.indexWhere((r) => r.id == recipeId);
      if (index != -1) {
        _recipes[index] = currentRecipe;
      } else {
        _recipes.add(currentRecipe);
      }
      safeNotify();
    } catch (e) {
      debugPrint('Error loading single recipe: $e');
    }
  }
}