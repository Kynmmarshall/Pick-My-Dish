import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen', () {
    late UserProvider userProvider;
    late RecipeProvider recipeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      userProvider = UserProvider();
      recipeProvider = RecipeProvider();
    });

    tearDown(ApiService.resetHttpClient);

    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> settleFrames(WidgetTester tester, {int ticks = 10}) async {
      for (var i = 0; i < ticks; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    MockClient buildHttpClient({required bool loginSucceeds}) {
      return MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/api/auth/login')) {
          if (loginSucceeds) {
            return http.Response(
              jsonEncode({
                'token': 'abc',
                'userId': 7,
                'user': {
                  'id': '7',
                  'username': 'Widget Chef',
                  'email': 'chef@test.com',
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'error': 'Invalid email or password'}),
            401,
          );
        }

        if (path.contains('/api/users/profile-picture')) {
          return http.Response(
            jsonEncode({'imagePath': 'assets/login/noPicture.png'}),
            200,
          );
        }

        if (path.contains('/api/users/favorites')) {
          return http.Response(jsonEncode({'favorites': []}), 200);
        }

        if (path.contains('/api/ingredients')) {
          return http.Response(jsonEncode({'ingredients': []}), 200);
        }

        if (path.contains('/api/recipes')) {
          return http.Response(jsonEncode({'recipes': []}), 200);
        }

        return http.Response('{}', 200);
      });
    }

    testWidgets('shows validation message when fields are empty', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpLogin(tester);
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      expect(visibilityToggle, findsOneWidget);
      await tester.tap(visibilityToggle);
      await tester.pump();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('successful login stores user and navigates home', (tester) async {
      ApiService.setHttpClient(buildHttpClient(loginSucceeds: true));
      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'chef@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await settleFrames(tester, ticks: 15);

      expect(userProvider.isLoggedIn, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('invalid credentials show snackbar error', (tester) async {
      ApiService.setHttpClient(buildHttpClient(loginSucceeds: false));
      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'chef@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await settleFrames(tester);

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login As Guest opens HomeScreen without API call', (tester) async {
      ApiService.setHttpClient(buildHttpClient(loginSucceeds: true));
      await pumpLogin(tester);

      await tester.tap(find.text('Login As Guest'));
      await settleFrames(tester, ticks: 15);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(userProvider.isLoggedIn, isFalse);
    });

    testWidgets('shows loading dialog while waiting for login response', (tester) async {
      final responseCompleter = Completer<http.Response>();
      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/auth/login')) {
          return responseCompleter.future;
        }
        return http.Response('{}', 200);
      }));

      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'chef@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      responseCompleter.complete(
        http.Response(
          jsonEncode({
            'token': 'abc',
            'userId': 3,
            'user': {
              'id': '3',
              'username': 'Chef Slow',
              'email': 'slow@test.com',
            },
          }),
          200,
        ),
      );

      await settleFrames(tester, ticks: 15);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows connection error snackbar when login throws', (tester) async {
      ApiService.setHttpClient(MockClient((request) async {
        if (request.url.path.contains('/api/auth/login')) {
          throw Exception('network down');
        }
        return http.Response('{}', 200);
      }));

      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'chef@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await settleFrames(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(userProvider.isLoggedIn, isFalse);
    });
  });
}
