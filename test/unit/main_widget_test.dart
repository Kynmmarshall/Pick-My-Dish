import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestRecipeProvider extends RecipeProvider {
  bool favoritesLoaded = false;

  @override
  Future<void> loadUserFavorites() async {
    favoritesLoaded = true;
  }
}

class _ThrowingUserProvider extends UserProvider {
  bool attempted = false;

  @override
  Future<bool> autoLogin() async {
    attempted = true;
    throw Exception('auto-login failed');
  }
}

MockClient _buildHomeClient() {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.contains('/api/recipes')) {
      return http.Response(jsonEncode({'recipes': []}), 200);
    }

    if (path.contains('/api/ingredients')) {
      return http.Response(jsonEncode({'ingredients': []}), 200);
    }

    if (path.contains('/api/users/favorites')) {
      return http.Response(jsonEncode({'favorites': []}), 200);
    }

    if (path.contains('/api/users/profile-picture')) {
      return http.Response(jsonEncode({'imagePath': 'assets/login/noPicture.png'}), 200);
    }

    return http.Response('{}', 200);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PickMyDish auto-login', () {
    late UserProvider userProvider;
    late _TestRecipeProvider recipeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      userProvider = UserProvider();
      recipeProvider = _TestRecipeProvider();
      userProvider.overrideApiForTest(removeToken: () async {});
      ApiService.setHttpClient(_buildHomeClient());
    });

    tearDown(() {
      userProvider.resetApiOverrides();
      recipeProvider.resetApiOverrides();
      ApiService.resetHttpClient();
    });

    Future<void> pumpPickMyDish(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ],
          child: const PickMyDish(),
        ),
      );
    }

    Future<void> settleFrames(WidgetTester tester, {int ticks = 10}) async {
      for (var i = 0; i < ticks; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('shows loading indicator while auto-login is pending', (tester) async {
      final completer = Completer<Map<String, dynamic>?>();
      userProvider.overrideApiForTest(verifyToken: () => completer.future);
      await pumpPickMyDish(tester);
      await tester.pump();
      expect(find.text('Loading...'), findsOneWidget);
      completer.complete({'valid': false});
    });

    testWidgets('falls back to LoginScreen when token is invalid', (tester) async {
      userProvider.overrideApiForTest(verifyToken: () async => {'valid': false});
      await pumpPickMyDish(tester);
      await tester.pump();
      await settleFrames(tester);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('successful auto-login renders HomeScreen and loads favorites', (tester) async {
      userProvider.overrideApiForTest(
        verifyToken: () async => {
          'valid': true,
          'user': {
            'id': '7',
            'username': 'Auto User',
            'email': 'auto@test.com',
            'created_at': DateTime.now().toIso8601String(),
          },
        },
      );
      await pumpPickMyDish(tester);
      await tester.pump();
      await settleFrames(tester, ticks: 15);

      expect(recipeProvider.favoritesLoaded, isTrue);
      expect(userProvider.isLoggedIn, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('auto-login exceptions still show LoginScreen', (tester) async {
      userProvider = _ThrowingUserProvider();
      userProvider.overrideApiForTest(removeToken: () async {});
      await pumpPickMyDish(tester);
      await tester.pump();
      await settleFrames(tester, ticks: 12);

      final throwingProvider = userProvider as _ThrowingUserProvider;
      expect(throwingProvider.attempted, isTrue);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });
  });
}
