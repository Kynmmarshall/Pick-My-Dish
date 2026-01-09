import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:provider/provider.dart';

Recipe _makeRecipe(int id, String name, {int userId = 1}) {
  return Recipe(
    id: id,
    name: name,
    authorName: 'Chef Widget',
    category: 'Lunch',
    cookingTime: '20 mins',
    calories: '250',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Eggs'],
    steps: const ['Cook'],
    moods: const ['Happy'],
    userId: userId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecipesScreen', () {
    late UserProvider userProvider;
    late RecipeProvider recipeProvider;
    late List<Recipe> recipes;

    setUp(() {
      userProvider = UserProvider();
      userProvider.setUser(
        User(id: '5', username: 'Chef', email: 'chef@example.com'),
      );
      userProvider.setUserId(5);
      recipeProvider = RecipeProvider();
      recipes = [
        _makeRecipe(1, 'Spicy Pasta', userId: 5),
        _makeRecipe(2, 'Fresh Salad', userId: 8),
      ];
    });

    Future<void> pumpScreen(WidgetTester tester, {bool mineOnly = false}) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ],
          child: MaterialApp(
            home: RecipesScreen(
              showUserRecipesOnly: mineOnly,
              enableAutoLoad: false,
              initialRecipes: recipes,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('filters recipes by search query', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Spicy Pasta'), findsOneWidget);
      expect(find.text('Fresh Salad'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Spicy');
      await tester.pumpAndSettle();
      expect(find.text('Spicy Pasta'), findsOneWidget);
      expect(find.text('Fresh Salad'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Unknown');
      await tester.pumpAndSettle();
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('shows My Recipes header when filtering by owner', (tester) async {
      await pumpScreen(tester, mineOnly: true);
      expect(find.text('My Recipes'), findsOneWidget);
      expect(find.text('Spicy Pasta'), findsOneWidget);
      expect(find.text('Fresh Salad'), findsNothing);
    });

    testWidgets('renders error view when requested', (tester) async {
      await pumpScreen(tester);
      final dynamic state = tester.state(find.byType(RecipesScreen));
      state.setErrorStateForTest(true);
      await tester.pump();
      expect(find.text('Failed to load recipes'), findsOneWidget);
    });
  });
}
