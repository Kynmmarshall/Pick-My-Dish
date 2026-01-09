import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/Screens/recipe_edit_screen.dart';
import 'package:provider/provider.dart';

Recipe _buildRecipe({int id = 1, int userId = 1}) {
  return Recipe(
    id: id,
    name: 'Detail Dish',
    authorName: 'Chef Detail',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '320',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Salt', 'Pepper'],
    steps: const ['Prep', 'Cook'],
    moods: const ['Happy'],
    userId: userId,
  );
}

UserProvider _buildUserProvider({required String id, bool isAdmin = false}) {
  final provider = UserProvider();
  provider.setUser(
    User(
      id: id,
      username: 'User$id',
      email: 'user$id@test.com',
      isAdmin: isAdmin,
    ),
  );
  provider.setUserId(int.tryParse(id) ?? 0);
  return provider;
}

Widget _wrapWithProviders({
  required Recipe recipe,
  required UserProvider userProvider,
  required RecipeProvider recipeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
    ],
    child: MaterialApp(
      home: RecipeDetailScreen(initialRecipe: recipe),
    ),
  );
}

class _TrackingRecipeProvider extends RecipeProvider {
  bool loadSingleCalled = false;

  @override
  Future<void> loadSingleRecipe(int recipeId) async {
    loadSingleCalled = true;
  }
}

Future<void> _selectMenuOption(WidgetTester tester, String value) async {
  final popupFinder = find.byType(PopupMenuButton<String>);
  final popup = tester.widget<PopupMenuButton<String>>(popupFinder);
  popup.onSelected?.call(value);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecipeDetailScreen', () {
    testWidgets('owner sees edit option and navigates to edit screen', (tester) async {
      final recipe = _buildRecipe(userId: 1);
      final recipeProvider = RecipeProvider();
      final userProvider = _buildUserProvider(id: '1');

      await tester.pumpWidget(
        _wrapWithProviders(
          recipe: recipe,
          userProvider: userProvider,
          recipeProvider: recipeProvider,
        ),
      );

      await _selectMenuOption(tester, 'edit');
      await tester.pump();

      expect(find.byType(RecipeEditScreen), findsOneWidget);
    });

    testWidgets('delete recipe failure shows snackbar', (tester) async {
      final recipe = _buildRecipe(userId: 1);
      final recipeProvider = RecipeProvider();
      final userProvider = _buildUserProvider(id: '1');
      recipeProvider.overrideApiForTest(deleteRecipe: (id) async => false);

      await tester.pumpWidget(
        _wrapWithProviders(
          recipe: recipe,
          userProvider: userProvider,
          recipeProvider: recipeProvider,
        ),
      );

      await _selectMenuOption(tester, 'delete');
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.text('Failed to delete recipe'), findsOneWidget);
    });

    testWidgets('floating action button requests single recipe reload', (tester) async {
      final recipe = _buildRecipe(userId: 1);
      final recipeProvider = _TrackingRecipeProvider();
      final userProvider = _buildUserProvider(id: '1');

      await tester.pumpWidget(
        _wrapWithProviders(
          recipe: recipe,
          userProvider: userProvider,
          recipeProvider: recipeProvider,
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(recipeProvider.loadSingleCalled, isTrue);
    });

    testWidgets('start cooking button shows celebratory snackbar', (tester) async {
      final recipe = _buildRecipe(userId: 1);
      final recipeProvider = RecipeProvider();
      final userProvider = _buildUserProvider(id: '99');

      await tester.pumpWidget(
        _wrapWithProviders(
          recipe: recipe,
          userProvider: userProvider,
          recipeProvider: recipeProvider,
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.ensureVisible(find.text('Start Cooking'));
      await tester.tap(find.text('Start Cooking'));
      await tester.pump();

      expect(find.textContaining('Happy cooking!'), findsOneWidget);
    });

    testWidgets('non-owner without admin rights does not see edit menu', (tester) async {
      final recipe = _buildRecipe(userId: 1);
      final recipeProvider = RecipeProvider();
      final userProvider = _buildUserProvider(id: '42');

      await tester.pumpWidget(
        _wrapWithProviders(
          recipe: recipe,
          userProvider: userProvider,
          recipeProvider: recipeProvider,
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
