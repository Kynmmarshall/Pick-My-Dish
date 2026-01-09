import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:provider/provider.dart';

class _StubRecipeProvider extends RecipeProvider {
  _StubRecipeProvider({List<Recipe>? favorites}) {
    if (favorites != null) {
      this.favorites
        ..clear()
        ..addAll(favorites);
    }
  }

  int loadCalls = 0;
  int toggleCalls = 0;

  @override
  Future<void> loadUserFavorites() async {
    loadCalls++;
    safeNotify();
  }

  @override
  Future<void> toggleFavorite(int recipeId) async {
    toggleCalls++;
    favorites.removeWhere((recipe) => recipe.id == recipeId);
    safeNotify();
  }
}

Recipe _createRecipe({int id = 1, String name = 'Sample Favorite'}) {
  return Recipe(
    id: id,
    name: name,
    authorName: 'Test Author',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'assets/recipes/test.png',
    ingredients: const ['Salt'],
    steps: const ['Cook'],
    moods: const ['Happy'],
    userId: 1,
    isFavorite: true,
  );
}

User _createUser() {
  return User(
    id: '42',
    username: 'Fav Tester',
    email: 'fav@test.com',
    joinedDate: DateTime(2024, 1, 1),
    isAdmin: false,
    profileImage: 'assets/login/noPicture.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget pumpFavoritesScreen({
    required UserProvider userProvider,
    required RecipeProvider recipeProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
      ],
      child: const MaterialApp(home: FavoritesScreen()),
    );
  }

  testWidgets('shows login prompt when no user is logged in', (tester) async {
    final userProvider = UserProvider();
    final recipeProvider = _StubRecipeProvider();

    await tester.pumpWidget(
      pumpFavoritesScreen(
        userProvider: userProvider,
        recipeProvider: recipeProvider,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Login to save favorites'), findsOneWidget);
    expect(recipeProvider.loadCalls, equals(0));
  });

  testWidgets('renders existing favorites for logged-in user', (tester) async {
    final userProvider = UserProvider()
      ..setUser(_createUser())
      ..setUserId(42);

    final recipeProvider = _StubRecipeProvider(
      favorites: [_createRecipe()],
    );

    await tester.pumpWidget(
      pumpFavoritesScreen(
        userProvider: userProvider,
        recipeProvider: recipeProvider,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(recipeProvider.loadCalls, greaterThanOrEqualTo(1));
    expect(find.text('Favorite Recipes'), findsOneWidget);
    expect(find.text('Sample Favorite'), findsWidgets);
    expect(find.text('(1)'), findsOneWidget);
    expect(find.text('Fav Tester'), findsOneWidget);
  });

  testWidgets('confirming dismiss removes the favorite', (tester) async {
    final userProvider = UserProvider()
      ..setUser(_createUser())
      ..setUserId(100);
    final recipeProvider = _StubRecipeProvider(favorites: [_createRecipe()]);

    await tester.pumpWidget(
      pumpFavoritesScreen(
        userProvider: userProvider,
        recipeProvider: recipeProvider,
      ),
    );

    await tester.pumpAndSettle();

    final dismissible = find.byType(Dismissible).first;
    await tester.drag(dismissible, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(recipeProvider.toggleCalls, equals(1));
    expect(recipeProvider.favorites, isEmpty);
  });
}
