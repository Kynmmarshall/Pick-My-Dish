import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/theme_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Recipe _buildRecipe(int id, String name) {
  return Recipe(
    id: id,
    name: name,
    authorName: 'Chef Test',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '200',
    imagePath: 'assets/login/noPicture.png',
    ingredients: const ['Eggs', 'Flour'],
    steps: const ['Mix', 'Bake'],
    moods: const ['Happy'],
    userId: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    late UserProvider userProvider;
    late RecipeProvider recipeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userProvider = UserProvider();
      userProvider.setUser(
        User(
          id: '1',
          username: 'TestUser',
          email: 'test@example.com',
        ),
      );
      userProvider.setUserId(1);
      recipeProvider = RecipeProvider();
    });

    tearDown(ApiService.resetHttpClient);

    Future<void> configureViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Future<void> pumpHomeScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(
              enableAutoFetch: false,
              fetchProfilePictureInDrawer: false,
              ingredientLoaderOverride: () async => [
                {'id': 1, 'name': 'Eggs'},
                {'id': 2, 'name': 'Flour'},
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> settleFrames(WidgetTester tester, {int ticks = 10}) async {
      for (var i = 0; i < ticks; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('shows snackbar when no filters are selected', (tester) async {
      await configureViewport(tester);
      await pumpHomeScreen(tester);
      final generateButton = find.text('Generate Personalized Recipes');
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Please select at least one filter'), findsOneWidget);
    });

    testWidgets('renders recipes, drawer content, and personalized dialog', (tester) async {
      await configureViewport(tester);
      await pumpHomeScreen(tester);
      final recipes = [
        _buildRecipe(1, 'Spicy Pasta'),
        _buildRecipe(2, 'Fresh Salad'),
      ];

      final dynamic state = tester.state(find.byType(HomeScreen));
      state.setTodayRecipesForTest(recipes);
      await tester.pumpAndSettle();

      expect(find.text('Spicy Pasta'), findsOneWidget);
      expect(find.text('Fresh Salad'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('View Profile'), findsOneWidget);

      state.showPersonalizedDialogForTest(recipes);
      await tester.pumpAndSettle();
      expect(find.text('Personalized Recipes (2)'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('displays loading indicator and empty state', (tester) async {
      await configureViewport(tester);
      await pumpHomeScreen(tester);
      final dynamic state = tester.state(find.byType(HomeScreen));

      state.setLoadingStateForTest(true);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      state.setLoadingStateForTest(false);
      state.setTodayRecipesForTest(const <Recipe>[]);
      await tester.pump();
      expect(find.text('No recipes available'), findsOneWidget);
    });

    testWidgets('drawer My Recipes option navigates to RecipesScreen', (tester) async {
      await ApiService.saveToken('token-123');
      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/recipes')) {
          return http.Response(
            jsonEncode({
              'recipes': [
                {
                  'id': 42,
                  'name': 'Spaghetti Supreme',
                  'author_name': 'Chef Widget',
                  'category_name': 'Dinner',
                  'cooking_time': '25 mins',
                  'calories': '320',
                  'image_path': 'assets/login/noPicture.png',
                  'ingredient_names': 'Tomato',
                  'steps': ['Cook'],
                  'emotions': ['Happy'],
                  'user_id': 1,
                }
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }));

      await configureViewport(tester);
      await pumpHomeScreen(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Recipes'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipesScreen), findsOneWidget);
      expect(find.text('Spaghetti Supreme'), findsWidgets);
    });

    testWidgets('drawer Favorites option shows saved dishes', (tester) async {
      recipeProvider.overrideApiForTest(
        fetchFavorites: () async => [
          {
            'id': 7,
            'name': 'Pinned Curry',
            'author_name': 'Chef Widget',
            'category_name': 'Dinner',
            'cooking_time': '20 mins',
            'calories': '280',
            'image_path': 'assets/login/noPicture.png',
            'ingredient_names': 'Spice',
            'steps': ['Cook'],
            'emotions': ['Happy'],
            'user_id': 1,
          },
        ],
      );

      await configureViewport(tester);
      await pumpHomeScreen(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Pinned Curry'), findsWidgets);
    });

    testWidgets('personalized dialog lists recipe metadata', (tester) async {
      await configureViewport(tester);
      await pumpHomeScreen(tester);
      final dynamic state = tester.state(find.byType(HomeScreen));

      state.showPersonalizedDialogForTest([
        Recipe(
          id: 99,
          name: 'Mood Booster',
          authorName: 'Chef Detail',
          category: 'Lunch',
          cookingTime: '12 mins',
          calories: '150',
          imagePath: 'assets/login/noPicture.png',
          ingredients: const ['Spinach'],
          steps: const ['Blend'],
          moods: const ['Energized'],
          userId: 1,
        ),
      ]);

      await tester.pumpAndSettle();
      expect(find.text('Personalized Recipes (1)'), findsOneWidget);
      expect(find.text('Mood Booster'), findsOneWidget);
      expect(find.text('Time: 12 mins'), findsOneWidget);
      expect(find.text('Mood: Energized'), findsOneWidget);
      expect(find.text('Category: Lunch'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Personalized Recipes (1)'), findsNothing);
    });

    testWidgets('ingredient selector toggles chips when ingredients are picked', (tester) async {
      await configureViewport(tester);
      await pumpHomeScreen(tester);

      final Finder searchField = find.widgetWithText(TextField, 'Search ingredients...');
      await tester.enterText(searchField, 'Eggs');
      await tester.pumpAndSettle();

      final eggsTile = find.widgetWithText(CheckboxListTile, 'Eggs');
      await tester.ensureVisible(eggsTile.first);
      await tester.tap(eggsTile.first);
      await tester.pump();

      expect(find.widgetWithText(Chip, 'Eggs'), findsOneWidget);

      await tester.tap(eggsTile.first);
      await tester.pump();

      expect(find.widgetWithText(Chip, 'Eggs'), findsNothing);
    });

    testWidgets('generate personalized recipes fetches filtered matches', (tester) async {
      await ApiService.saveToken('token-personalized');
      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/recipes')) {
          return http.Response(
            jsonEncode({
              'recipes': [
                {
                  'id': 77,
                  'name': 'Happy Fuel',
                  'author_name': 'Chef Joy',
                  'category_name': 'Lunch',
                  'cooking_time': '20 mins',
                  'calories': '220',
                  'image_path': 'assets/login/noPicture.png',
                  'ingredient_names': 'Eggs',
                  'steps': ['Cook'],
                  'emotions': ['Happy'],
                  'user_id': 1,
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }));

      await configureViewport(tester);
      await pumpHomeScreen(tester);

      final dynamic state = tester.state(find.byType(HomeScreen));
      state.setAllIngredientsForTest([
        {'id': 1, 'name': 'Eggs'},
      ]);
      state.setFiltersForTest(
        emotion: 'Happy',
        ingredientIds: [1],
        time: '<= 30mins',
      );

      await tester.tap(find.text('Generate Personalized Recipes'));
      await tester.pump();
      await settleFrames(tester, ticks: 12);

      expect(find.text('Personalized Recipes (1)'), findsOneWidget);
      expect(find.text('Happy Fuel'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
    });

    testWidgets('generate personalized recipes shows error snackbar on failure', (tester) async {
      await ApiService.saveToken('token-error');
      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/recipes')) {
          throw Exception('offline');
        }
        return http.Response('{}', 200);
      }));

      await configureViewport(tester);
      await pumpHomeScreen(tester);

      final dynamic state = tester.state(find.byType(HomeScreen));
      state.setFiltersForTest(emotion: 'Happy');

      await tester.tap(find.text('Generate Personalized Recipes'));
      await tester.pump();
      await settleFrames(tester, ticks: 10);

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('refresh action reloads today recipes and favorites', (tester) async {
      await ApiService.saveToken('token-refresh');
      bool favoritesLoaded = false;
      recipeProvider.overrideApiForTest(
        fetchFavorites: () async {
          favoritesLoaded = true;
          return [];
        },
      );

      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/recipes')) {
          return http.Response(
            jsonEncode({
              'recipes': [
                {
                  'id': 91,
                  'name': 'Refresh Paella',
                  'author_name': 'Chef Reset',
                  'category_name': 'Dinner',
                  'cooking_time': '35 mins',
                  'calories': '310',
                  'image_path': 'assets/login/noPicture.png',
                  'ingredient_names': 'Rice',
                  'steps': ['Cook'],
                  'emotions': ['Calm'],
                  'user_id': 1,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.contains('/api/ingredients')) {
          return http.Response(jsonEncode({
            'ingredients': [
              {'id': 1, 'name': 'Rice'},
            ],
          }), 200);
        }
        return http.Response('{}', 200);
      }));

      await configureViewport(tester);
      await pumpHomeScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await settleFrames(tester, ticks: 15);

      expect(favoritesLoaded, isTrue);
      expect(find.text('Refresh Paella'), findsOneWidget);
    });
  });
}
