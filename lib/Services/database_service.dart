import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'recipes.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY,
        name TEXT,
        category TEXT,
        time TEXT,
        calories TEXT,
        image TEXT,
        ingredients TEXT,
        mood TEXT,
        difficulty TEXT,
        steps TEXT,
        isFavorite INTEGER
      )
    ''');
    // Load initial data from JSON
    await _loadInitialData(db);
  }

  Future<void> _loadInitialData(Database db) async {
    try {
      String data = await rootBundle.loadString('data/recipes.json');
      final jsonData = json.decode(data);
      for (var recipe in jsonData['recipes']) {
        await db.insert('recipes', {
          'id': recipe['id'],
          'name': recipe['name'],
          'category': recipe['category'],
          'time': recipe['time'],
          'calories': recipe['calories'],
          'image': recipe['image'],
          'ingredients': json.encode(recipe['ingredients']),
          'mood': json.encode(recipe['mood']),
          'difficulty': recipe['difficulty'],
          'steps': json.encode(recipe['steps']),
          'isFavorite': recipe['isFavorite'] ? 1 : 0,
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  // Returns List<Recipe>
  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final maps = await db.query('recipes');
    return maps.map((map) => _mapToRecipe(map)).toList();
  }

  // Returns List<Recipe> with filters
  Future<List<Recipe>> getFilteredRecipes({
    List<String>? ingredients,
    String? mood,
    String? time,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> allRecipes = await db.query('recipes');
    
    final filtered = allRecipes.where((recipeMap) {
      bool matches = true;
      
      // Enhanced ingredient matching for "What's in your fridge?" feature
      if (ingredients != null && ingredients.isNotEmpty) {
        final List<String> recipeIngredients = List<String>.from(
          json.decode(recipeMap['ingredients'] ?? '[]')
        );
        
        // Check if ANY user ingredient matches ANY recipe ingredient
        bool hasMatchingIngredient = false;
        for (final userIngredient in ingredients) {
          for (final recipeIngredient in recipeIngredients) {
            // Check for substring match (e.g., "chicken" matches "chicken breast")
            // Convert to lowercase for case-insensitive comparison
            if (recipeIngredient.toLowerCase().contains(userIngredient.toLowerCase()) ||
                userIngredient.toLowerCase().contains(recipeIngredient.toLowerCase())) {
              hasMatchingIngredient = true;
              break;
            }
          }
          if (hasMatchingIngredient) break;
        }
        
        matches = matches && hasMatchingIngredient;
      }
      
      if (mood != null && mood.isNotEmpty) {
        final List<String> recipeMoods = List<String>.from(
          json.decode(recipeMap['mood'] ?? '[]')
        );
        matches = matches && recipeMoods.contains(mood);
      }
      
      if (time != null && time.isNotEmpty) {
        // Convert time to minutes for comparison
        final recipeTime = _convertTimeToMinutes(recipeMap['time'] ?? '');
        final userTime = _convertTimeToMinutes(time);
        matches = matches && recipeTime <= userTime;
      }
      
      return matches;
    }).toList();

    return filtered.map((map) => _mapToRecipe(map)).toList();
  }

  // Returns List<Recipe> for favorites
  Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', where: 'isFavorite = 1');
    return maps.map((map) => _mapToRecipe(map)).toList();
  }

  // Helper: Convert database map to Recipe object
  Recipe _mapToRecipe(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      cookingTime: map['time'] ?? '',
      calories: map['calories']?.toString() ?? '0',
      imagePath: map['image'] ?? 'assets/recipes/test.png',
      ingredients: List<String>.from(json.decode(map['ingredients'] ?? '[]')),
      steps: List<String>.from(json.decode(map['steps'] ?? '[]')),
      moods: List<String>.from(json.decode(map['mood'] ?? '[]')),
      userId: 1, // Default for local DB
      isFavorite: (map['isFavorite'] ?? 0) == 1,
    );
  }

  // Enhanced time converter for better filtering
  int _convertTimeToMinutes(String time) {
    time = time.toLowerCase();
    
    // Extract numbers from time string
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(time);
    
    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      
      if (time.contains('hour')) {
        return minutes * 60;
      } else if (time.contains('min')) {
        return minutes;
      }
    }
    
    // Default values for common time strings
    if (time.contains('quick') || time.contains('15')) return 15;
    if (time.contains('30')) return 30;
    if (time.contains('1 hour')) return 60;
    if (time.contains('2+')) return 120;
    if (time.contains('long')) return 180;
    
    return 120; // Default for unknown times
  }

  Future<void> toggleFavorite(int recipeId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'recipes',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  // New method: Get recipes by specific ingredient
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    final db = await database;
    List<Map<String, dynamic>> allRecipes = await db.query('recipes');
    
    final filtered = allRecipes.where((recipeMap) {
      final List<String> recipeIngredients = List<String>.from(
        json.decode(recipeMap['ingredients'] ?? '[]')
      );
      
      return recipeIngredients.any((recipeIngredient) =>
          recipeIngredient.toLowerCase().contains(ingredient.toLowerCase()));
    }).toList();

    return filtered.map((map) => _mapToRecipe(map)).toList();
  }

  // New method: Get ingredient suggestions based on what's in database
  Future<List<String>> getIngredientSuggestions(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> allRecipes = await db.query('recipes');
    
    final Set<String> suggestions = {};
    
    for (final recipe in allRecipes) {
      final List<String> ingredients = List<String>.from(
        json.decode(recipe['ingredients'] ?? '[]')
      );
      
      for (final ingredient in ingredients) {
        if (ingredient.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(ingredient);
        }
      }
    }
    
    return suggestions.toList();
  }
}
