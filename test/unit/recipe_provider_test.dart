import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';

Recipe _recipe({
  required int id,
  required String name,
  List<String> moods = const ['Happy'],
  String time = '30 mins',
  int userId = 1,
}) {
  return Recipe(
    id: id,
    name: name,
    authorName: 'Chef',
    category: 'Dinner',
    cookingTime: time,
    calories: '100',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Eggs'],
    steps: const ['Cook'],
    moods: moods,
    userId: userId,
  );
}

Map<String, dynamic> _recipeJson({
  required int id,
  required String name,
  int userId = 1,
}) {
  return {
    'id': id,
    'name': name,
    'author_name': 'Chef',
    'category_name': 'Dinner',
    'cooking_time': '20 mins',
    'calories': '120',
    'image_path': 'assets/login/noPicture.png',
    'ingredient_names': 'Eggs',
    'steps': ['Cook'],
    'emotions': ['Joy'],
    'user_id': userId,
  };
}

void main() {
  group('RecipeProvider', () {
    late RecipeProvider provider;

    setUp(() {
      provider = RecipeProvider();
      provider.setRecipesForTest([
        _recipe(id: 1, name: 'Happy Salad', moods: const ['Happy'], userId: 1),
        _recipe(id: 2, name: 'Sad Soup', moods: const ['Comfort'], userId: 2),
      ]);
    });

    test('filters recipes with text query', () {
      final results = provider.filterRecipes('salad');
      expect(results.length, 1);
      expect(results.first.name, 'Happy Salad');
    });

    test('personalizes recipes by mood and time', () {
      final matches = provider.personalizeRecipes(mood: 'Comfort', time: '30 mins');
      expect(matches.length, 1);
      expect(matches.first.name, 'Sad Soup');
    });

    test('determines edit rights for admins and owners', () {
      expect(provider.canEditRecipe(1, 99, true), isTrue); // admin
      expect(provider.canEditRecipe(1, 1, false), isTrue); // owner
      expect(provider.canEditRecipe(2, 1, false), isFalse);
    });

    test('syncs favorites into recipe list', () {
      provider.setFavoritesForTest([
        _recipe(id: 2, name: 'Sad Soup'),
      ]);
      provider.syncFavoritesForTest();
      final updated = provider.recipes.firstWhere((r) => r.id == 2);
      expect(updated.isFavorite, isTrue);
    });

    test('loadRecipes populates recipes from API data', () async {
      provider.setRecipesForTest([]);
      provider.overrideApiForTest(
        fetchRecipes: () async => [_recipeJson(id: 3, name: 'API Soup')],
      );

      await provider.loadRecipes();

      expect(provider.recipes, hasLength(1));
      expect(provider.recipes.first.name, 'API Soup');
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadUserFavorites hydrates favorites list', () async {
      provider.overrideApiForTest(
        fetchFavorites: () async => [_recipeJson(id: 4, name: 'Fav Dish')],
      );

      await provider.loadUserFavorites();

      expect(provider.favorites, hasLength(1));
      expect(provider.isFavorite(4), isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('loadUserFavorites captures API errors', () async {
      provider.overrideApiForTest(
        fetchFavorites: () => throw Exception('offline'),
      );

      await provider.loadUserFavorites();

      expect(provider.error, contains('Failed to load favorites'));
      expect(provider.isLoading, isFalse);
    });

    test('toggleFavorite adds and removes favorites via API hooks', () async {
      var addCalls = 0;
      var removeCalls = 0;
      provider.overrideApiForTest(
        addFavorite: (recipeId) async {
          addCalls++;
          return true;
        },
        removeFavorite: (recipeId) async {
          removeCalls++;
          return true;
        },
        fetchRecipes: () async => [_recipeJson(id: 1, name: 'Happy Salad')],
      );

      await provider.toggleFavorite(1);
      expect(addCalls, 1);
      expect(provider.favorites.map((r) => r.id), contains(1));
      expect(provider.recipes.firstWhere((r) => r.id == 1).isFavorite, isTrue);

      await provider.toggleFavorite(1);
      expect(removeCalls, 1);
      expect(provider.favorites.any((r) => r.id == 1), isFalse);
      expect(provider.recipes.firstWhere((r) => r.id == 1).isFavorite, isFalse);
    });

    test('deleteRecipe removes from local caches when API succeeds', () async {
      provider.overrideApiForTest(
        deleteRecipe: (recipeId) async => true,
      );

      provider.setFavoritesForTest([
        _recipe(id: 2, name: 'Sad Soup'),
      ]);

      final result = await provider.deleteRecipe(2);

      expect(result, isTrue);
      expect(provider.recipes.any((r) => r.id == 2), isFalse);
      expect(provider.favorites.any((r) => r.id == 2), isFalse);
    });
  });
}
