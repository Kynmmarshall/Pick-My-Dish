import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final db = await database;
    return await db.query('recipes');
  }

  Future<List<Map<String, dynamic>>> getFilteredRecipes({
    List<String>? ingredients,
    String? mood,
    String? time,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> allRecipes = await db.query('recipes');

    return allRecipes.where((recipe) {
      // Filter by ingredients
      if (ingredients != null && ingredients.isNotEmpty) {
        List<String> recipeIngredients = List<String>.from(
          json.decode(recipe['ingredients']),
        );
        bool hasIngredient = ingredients.any(
          (ingredient) => recipeIngredients.any(
            (recipeIngredient) => recipeIngredient.toLowerCase().contains(
              ingredient.toLowerCase(),
            ),
          ),
        );
        if (!hasIngredient) return false;
      }

      // Filter by mood
      if (mood != null && mood.isNotEmpty) {
        List<String> recipeMoods = List<String>.from(
          json.decode(recipe['mood']),
        );
        if (!recipeMoods.any(
          (recipeMood) => recipeMood.toLowerCase().contains(mood.toLowerCase()),
        )) {
          return false;
        }
      }

      // Filter by time
      if (time != null && time.isNotEmpty) {
        int recipeTime = int.parse(
          recipe['time'].toString().replaceAll(' mins', ''),
        );
        int selectedTime = _convertTimeToMinutes(time);
        if (recipeTime > selectedTime) return false;
      }

      return true;
    }).toList();
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

  Future<List<Map<String, dynamic>>> getFavoriteRecipes() async {
    final db = await database;
    return await db.query('recipes', where: 'isFavorite = 1');
  }
}
