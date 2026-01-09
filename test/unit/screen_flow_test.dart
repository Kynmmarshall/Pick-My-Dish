import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/Screens/recipe_edit_screen.dart';
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart';
import 'package:pick_my_dish/Screens/register_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestUserProvider extends UserProvider {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

RecipeProvider _stubRecipeProvider() {
  final provider = RecipeProvider();
  final recipeMap = {
    'id': 1,
    'name': 'Seed Recipe',
    'author_name': 'Chef',
    'category': 'Dinner',
    'time': '30 mins',
    'calories': 200,
    'ingredient_names': 'Salt,Pepper',
    'steps': ['Prep'],
    'emotions': ['Happy'],
    'user_id': 1,
  };

  provider.setRecipesForTest([Recipe.fromJson(recipeMap)]);
  provider.overrideApiForTest(
    fetchRecipes: () async => [recipeMap],
    fetchRecipesWithPermissions: () async => [recipeMap],
    fetchFavorites: () async => [],
    addFavorite: (_) async => true,
    removeFavorite: (_) async => true,
    deleteRecipe: (_) async => true,
  );
  return provider;
}

Recipe _buildRecipe({int id = 1, int ownerId = 1}) {
  return Recipe(
    id: id,
    name: 'Mock Recipe',
    authorName: 'Chef',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'assets/recipes/test.png',
    ingredients: const ['Salt', 'Pepper'],
    steps: const ['Prep', 'Cook'],
    moods: const ['Happy'],
    userId: ownerId,
    isFavorite: false,
  );
}

Future<List<Map<String, dynamic>>> _fakeIngredientsLoader() async => [
      {'id': 1, 'name': 'Salt'},
      {'id': 2, 'name': 'Pepper'},
    ];

Widget _pumpWithProviders({
  required Widget child,
  RecipeProvider? recipeProvider,
  UserProvider? userProvider,
}) {
  final recipe = recipeProvider ?? RecipeProvider();
  final user = userProvider ?? UserProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RecipeProvider>.value(value: recipe),
      ChangeNotifierProvider<UserProvider>.value(value: user),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.resetHttpClient();
  });

  tearDown(ApiService.resetHttpClient);

  group('HomeScreen flows', () {
    testWidgets('Add icon navigates to RecipeUploadScreen', (tester) async {
      await tester.pumpWidget(
        _pumpWithProviders(
          child: HomeScreen(
            enableAutoFetch: false,
            fetchProfilePictureInDrawer: false,
            ingredientLoaderOverride: _fakeIngredientsLoader,
          ),
          recipeProvider: _stubRecipeProvider(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeUploadScreen), findsOneWidget);
    });

    testWidgets('Generate button warns when no filters selected', (tester) async {
      await tester.pumpWidget(
        _pumpWithProviders(
          child: HomeScreen(
            enableAutoFetch: false,
            fetchProfilePictureInDrawer: false,
            ingredientLoaderOverride: _fakeIngredientsLoader,
          ),
          recipeProvider: _stubRecipeProvider(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Generate Personalized Recipes'));
      await tester.tap(find.text('Generate Personalized Recipes'));
      await tester.pump();

      expect(find.text('Please select at least one filter'), findsOneWidget);
    });
  });

  group('RecipeDetailScreen actions', () {
    testWidgets('Hides edit menu when user lacks permissions', (tester) async {
      final recipe = _buildRecipe(ownerId: 99);
      final userProvider = UserProvider();
      userProvider.setUser(User(id: '1', username: 'Guest', email: 'guest@test.com'));
      userProvider.setUserId(1);

      await tester.pumpWidget(
        _pumpWithProviders(
          child: RecipeDetailScreen(initialRecipe: recipe),
          recipeProvider: RecipeProvider()..setRecipesForTest([recipe]),
          userProvider: userProvider,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('Admin sees menu and toggle favorite updates provider', (tester) async {
      final recipe = _buildRecipe(ownerId: 1);
      final recipeProvider = RecipeProvider()
        ..setRecipesForTest([recipe])
        ..overrideApiForTest(
          fetchRecipes: () async => [recipe.toJson()],
          fetchRecipesWithPermissions: () async => [recipe.toJson()],
          fetchFavorites: () async => [],
          addFavorite: (_) async => true,
          removeFavorite: (_) async => true,
        );

      final userProvider = UserProvider();
      userProvider.setUser(
        User(id: '7', username: 'Admin', email: 'admin@test.com', isAdmin: true),
      );
      userProvider.setUserId(7);

      await tester.pumpWidget(
        _pumpWithProviders(
          child: RecipeDetailScreen(initialRecipe: recipe),
          recipeProvider: recipeProvider,
          userProvider: userProvider,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(recipeProvider.favorites.length, 1);
    });
  });

  group('Recipe form screens', () {
    testWidgets('RecipeUploadScreen shows validation snackbar when fields missing', (tester) async {
      await tester.pumpWidget(
        _pumpWithProviders(child: const RecipeUploadScreen()),
      );

      await tester.pumpAndSettle();
      final uploadButton = find.widgetWithText(ElevatedButton, 'Upload Recipe');
      await tester.ensureVisible(uploadButton);
      await tester.tap(uploadButton);
      await tester.pump();

      expect(find.text('Please fill required fields'), findsOneWidget);
    });

    testWidgets('RecipeEditScreen blocks unauthorized updates', (tester) async {
      final recipe = _buildRecipe(ownerId: 1);
      final userProvider = UserProvider();
      userProvider.setUser(User(id: '2', username: 'Viewer', email: 'viewer@test.com'));
      userProvider.setUserId(2);

      await tester.pumpWidget(
        _pumpWithProviders(
          child: RecipeEditScreen(recipe: recipe),
          recipeProvider: RecipeProvider(),
          userProvider: userProvider,
        ),
      );

      await tester.pumpAndSettle();
      final updateButton = find.text('Update Recipe');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pump();

      expect(
        find.text('You are no longer authorized to edit this recipe'),
        findsOneWidget,
      );
    });
  });

  group('ProfileScreen interactions', () {
    testWidgets('Edit and cancel toggles username field visibility', (tester) async {
      final userProvider = UserProvider();
      userProvider.setUser(User(id: '5', username: 'Chef', email: 'chef@test.com'));
      userProvider.setUserId(5);

      await tester.pumpWidget(
        _pumpWithProviders(
          child: const ProfileScreen(enableProfilePictureFetch: false),
          userProvider: userProvider,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('username_field')), findsNothing);

      await tester.tap(find.byKey(const Key('edit_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('username_field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('username_field')), findsNothing);
    });

    testWidgets('Logout navigates back to LoginScreen', (tester) async {
      final userProvider = _TestUserProvider();
      userProvider.setUser(User(id: '9', username: 'Chef', email: 'chef@test.com'));
      userProvider.setUserId(9);

      await tester.pumpWidget(
        _pumpWithProviders(
          child: const ProfileScreen(enableProfilePictureFetch: false),
          userProvider: userProvider,
        ),
      );

      await tester.pumpAndSettle();
      final logoutButton = find.byKey(const Key('logout_button'));
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(userProvider.logoutCalled, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Auth screens', () {
    testWidgets('Login button warns when fields empty', (tester) async {
      await tester.pumpWidget(
        _pumpWithProviders(child: const LoginScreen()),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('Login as guest navigates to HomeScreen', (tester) async {
      ApiService.setHttpClient(
        MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/api/recipes')) {
            return http.Response(
              jsonEncode({
                'recipes': [
                  {
                    'id': 1,
                    'name': 'Mock',
                    'author_name': 'Chef',
                    'category': 'Dinner',
                    'time': '30 mins',
                    'calories': 200,
                    'ingredient_names': 'Salt,Pepper',
                    'steps': ['Prep'],
                  }
                ],
              }),
              200,
            );
          }
          if (path.contains('/api/ingredients')) {
            return http.Response(
              jsonEncode({
                'ingredients': [
                  {'id': 1, 'name': 'Salt'},
                ],
              }),
              200,
            );
          }
          if (path.contains('/api/users/favorites')) {
            return http.Response(jsonEncode({'favorites': []}), 200);
          }
          return http.Response('{}', 200);
        }),
      );

      await tester.pumpWidget(
        _pumpWithProviders(child: const LoginScreen()),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Login As Guest'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Register button validates email format', (tester) async {
      await tester.pumpWidget(
        _pumpWithProviders(child: const RegisterScreen()),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'User Name'), 'Chef');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'invalid');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'StrongPass1!');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'StrongPass1!');

      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pump();

      expect(
        find.text('Please enter a valid email address (e.g., john.smith@gmail.com)'),
        findsOneWidget,
      );
    });
  });
}
