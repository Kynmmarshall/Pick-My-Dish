import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:provider/provider.dart';

Recipe _favoriteRecipe(int id, String name) {
  return Recipe(
    id: id,
    name: name,
    authorName: 'Chef',
    category: 'Dinner',
    cookingTime: '25 mins',
    calories: '300',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Eggs'],
    steps: const ['Cook'],
    moods: const ['Happy'],
    userId: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen', () {
    late UserProvider userProvider;
    late RecipeProvider recipeProvider;

    setUp(() {
      userProvider = UserProvider();
      userProvider.setUser(
        User(id: '1', username: 'Chef Tester', email: 'chef@test.com'),
      );
      userProvider.setUserId(1);
      recipeProvider = RecipeProvider();
      recipeProvider.setFavoritesForTest([
        _favoriteRecipe(1, 'Favorite Dish'),
      ]);
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(enableProfilePictureFetch: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('allows editing username and canceling changes', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('edit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('username_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('username_field')), 'New Name');

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chef Tester'), findsOneWidget);
    });

    testWidgets('shows profile info and logout button', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('Email'), findsOneWidget);
      expect(find.textContaining('Favorite Recipes'), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    });
  });
}
