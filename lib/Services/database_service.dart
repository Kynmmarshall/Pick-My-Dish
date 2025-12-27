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

  // UPDATED: Returns List<Recipe>
  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final maps = await db.query('recipes');
    return maps.map((map) => _mapToRecipe(map)).toList();
  }

  // UPDATED: Returns List<Recipe>
  Future<List<Recipe>> getFilteredRecipes({
  List<String>? ingredients,
  String? mood,
  String? time,
}) async {
  final db = await database;
  List<Map<String, dynamic>> allRecipes = await db.query('recipes');

  final filtered = allRecipes.where((recipeMap) {
    // Your existing filter logic...
    return true; // Your condition
  }).toList();

  // Convert each Map to Recipe
  return filtered.map((map) => Recipe.fromJson({
    'id': map['id'] ?? 0,
    'name': map['name'] ?? '',
    'category': map['category'] ?? '',
    'time': map['time'] ?? '',
    'calories': map['calories']?.toString() ?? '0',
    'image_path': map['image'] ?? 'assets/recipes/test.png',
    'ingredients': json.decode(map['ingredients'] ?? '[]'),
    'mood': json.decode(map['mood'] ?? '[]'),
    'steps': json.decode(map['steps'] ?? '[]'),
    'isFavorite': (map['isFavorite'] ?? 0) == 1,
  })).toList();
}

  // UPDATED: Returns List<Recipe>
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
      authorName: map['authornName'] ?? '',
      category: map['category'] ?? '',
      cookingTime: map['time'] ?? 'cooking_time' ?? '',
      calories: map['calories']?.toString() ?? '0',
      imagePath: map['image'] ?? 'assets/recipes/test.png',
      ingredients: List<String>.from(json.decode(map['ingredients'] ?? '[]')),
      steps: List<String>.from(json.decode(map['instructions'] ?? map['steps'] ??  '[]')),
      moods: List<String>.from(json.decode(map['mood'] ?? '[]')),
      userId: 1, // Default for local DB
      isFavorite: (map['isFavorite'] ?? 0) == 1,
    );
  }

  int _convertTimeToMinutes(String time) {
    switch (time) {
      case '15 mins':
        return 15;
      case '30 mins':
        return 30;
      case '1 hour':
        return 60;
      case '2+ hours':
        return 120;
      default:
        return 120;
    }
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
}