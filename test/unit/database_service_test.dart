import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  sqflite.databaseFactory = databaseFactoryFfi;

  late DatabaseService databaseService;
  late sqflite.Database db;

  Future<void> insertRecipe({
    required int id,
    int isFavorite = 0,
    String name = 'Stored Recipe',
  }) async {
    await db.insert('recipes', {
      'id': id,
      'name': name,
      'category': 'Dinner',
      'time': '30 mins',
      'calories': '450',
      'image': 'assets/recipes/test.png',
      'ingredients': json.encode(['Salt', 'Pepper']),
      'mood': json.encode(['Happy']),
      'difficulty': 'Easy',
      'steps': json.encode(['Mix', 'Cook']),
      'isFavorite': isFavorite,
    });
  }

  setUpAll(() async {
    final dbPath = p.join(await sqflite.getDatabasesPath(), 'recipes.db');
    await sqflite.databaseFactory.deleteDatabase(dbPath);
    databaseService = DatabaseService();
    db = await databaseService.database;
  });

  tearDownAll(() async {
    await db.close();
  });

  setUp(() async {
    await db.delete('recipes');
  });

  test('getRecipes returns mapped Recipe objects from SQLite rows', () async {
    await insertRecipe(id: 1);

    final recipes = await databaseService.getRecipes();

    expect(recipes, hasLength(1));
    final recipe = recipes.first;
    expect(recipe.name, 'Stored Recipe');
    expect(recipe.ingredients, containsAll(['Salt', 'Pepper']));
    expect(recipe.cookingTime, '30 mins');
  });

  test('getFavoriteRecipes filters by isFavorite flag', () async {
    await insertRecipe(id: 1, isFavorite: 0);
    await insertRecipe(id: 2, isFavorite: 1, name: 'Favorite Dish');

    final favorites = await databaseService.getFavoriteRecipes();

    expect(favorites, hasLength(1));
    expect(favorites.first.name, 'Favorite Dish');
    expect(favorites.first.isFavorite, isTrue);
  });

  test('toggleFavorite updates record in place', () async {
    await insertRecipe(id: 1, isFavorite: 0);

    await databaseService.toggleFavorite(1, true);

    final updated = await databaseService.getFavoriteRecipes();
    expect(updated, hasLength(1));
    expect(updated.first.id, 1);

    await databaseService.toggleFavorite(1, false);
    final cleared = await databaseService.getFavoriteRecipes();
    expect(cleared, isEmpty);
  });

  test('getFilteredRecipes returns stored rows regardless of filters', () async {
    await insertRecipe(id: 1, name: 'Chili');
    await insertRecipe(id: 2, name: 'Soup');

    final filtered = await databaseService.getFilteredRecipes(
      ingredients: ['Salt'],
      mood: 'Happy',
      time: '<= 30mins',
    );

    expect(filtered, hasLength(2));
    expect(filtered.map((r) => r.name).toSet(), containsAll({'Chili', 'Soup'}));
  });
}
