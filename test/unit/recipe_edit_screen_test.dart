import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_edit_screen.dart';
import 'package:provider/provider.dart';

Recipe _editableRecipe() {
  return Recipe(
    id: 10,
    name: 'Editable Dish',
    authorName: 'Chef',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '400',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Eggs'],
    steps: const ['Mix', 'Bake'],
    moods: const ['Happy'],
    userId: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecipeEditScreen', () {
    late UserProvider userProvider;
    late RecipeProvider recipeProvider;
    late Recipe recipe;

    setUp(() {
      recipe = _editableRecipe();
      userProvider = UserProvider();
      userProvider.setUser(User(id: '1', username: 'Chef', email: 'chef@test.com'));
      userProvider.setUserId(1);
      recipeProvider = RecipeProvider();
      recipeProvider.setRecipesForTest([recipe]);
    });

    Future<void> pumpEditor(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ],
          child: MaterialApp(
            home: RecipeEditScreen(
              recipe: recipe,
              ingredientLoaderOverride: () async => [
                {'id': 1, 'name': 'Eggs'},
                {'id': 2, 'name': 'Butter'},
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pre-fills existing data and allows changes', (tester) async {
      await pumpEditor(tester);
      expect(find.text('Editable Dish'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Updated Dish');
      await tester.pump();
      expect(find.text('Updated Dish'), findsOneWidget);

      final eggsTile = find.widgetWithText(CheckboxListTile, 'Eggs');
      await tester.ensureVisible(eggsTile.first);
      await tester.tap(eggsTile.first, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Eggs'), findsWidgets);

      final timeFinder = find.text('30 mins').first;
      await tester.ensureVisible(timeFinder);
      await tester.tap(timeFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 mins').last);
      await tester.pumpAndSettle();

      final happyChip = find.text('Happy').first;
      await tester.ensureVisible(happyChip);
      await tester.tap(happyChip, warnIfMissed: false);
      await tester.pump();
    });
  });
}
