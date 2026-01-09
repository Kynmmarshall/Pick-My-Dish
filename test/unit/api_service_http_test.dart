import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  _RecordingClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

http.StreamedResponse _streamedResponse(String body, int status) {
  final stream = Stream<List<int>>.fromIterable([utf8.encode(body)]);
  return http.StreamedResponse(stream, status);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.removeToken();
  });

  tearDown(ApiService.resetHttpClient);

  group('ApiService HTTP workflows', () {
    test('login saves token and returns payload on success', () async {
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.url.toString(), contains('/api/auth/login'));
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['email'], equals('chef@test.com'));
        expect(body['password'], equals('secret'));
        return http.Response(
          jsonEncode({
            'token': 'abc123',
            'message': 'ok',
            'user': {'id': 1}
          }),
          200,
        );
      }));

      final result = await ApiService.login('chef@test.com', 'secret');
      expect(result?['message'], equals('ok'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), equals('abc123'));
    });

    test('login returns error map on failure', () async {
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Invalid credentials'}), 401);
      }));

      final result = await ApiService.login('bad@test.com', 'nope');
      expect(result?['error'], equals('Invalid credentials'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });

    test('register saves token when backend responds with 201', () async {
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.url.toString(), contains('/api/auth/register'));
        return http.Response(
          jsonEncode({
            'token': 'new-user-token',
            'message': 'created'
          }),
          201,
        );
      }));

      final result = await ApiService.register('Chef', 'chef@test.com', 'Passw0rd!');
      expect(result?['message'], equals('created'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), equals('new-user-token'));
    });

    test('verifyToken returns payload and keeps token on success', () async {
      await ApiService.saveToken('valid-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer valid-token'));
        return http.Response(jsonEncode({'valid': true}), 200);
      }));

      final result = await ApiService.verifyToken();
      expect(result?['valid'], isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), equals('valid-token'));
    });

    test('verifyToken removes token when backend rejects it', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'stale-token');

      ApiService.setHttpClient(MockClient((request) async {
        return http.Response(jsonEncode({'error': 'expired'}), 401);
      }));

      final result = await ApiService.verifyToken();
      expect(result?['valid'], isFalse);
      expect(result?['error'], equals('expired'));
      expect(prefs.getString('token'), isNull);
    });

    test('getRecipes returns decoded list on success', () async {
      await ApiService.saveToken('recipes-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer recipes-token'));
        return http.Response(
          jsonEncode({
            'recipes': [
              {'id': 1, 'name': 'Soup'}
            ]
          }),
          200,
        );
      }));

      final recipes = await ApiService.getRecipes();
      expect(recipes, hasLength(1));
      expect(recipes.first['name'], equals('Soup'));
    });

    test('getRecipes returns empty list when unauthorized', () async {
      await ApiService.saveToken('recipes-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
      }));

      final recipes = await ApiService.getRecipes();
      expect(recipes, isEmpty);
    });

    test('getIngredients returns decoded payload', () async {
      await ApiService.saveToken('ingredients-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.method, equals('GET'));
        return http.Response(
          jsonEncode({
            'ingredients': [
              {'id': 10, 'name': 'Salt'}
            ]
          }),
          200,
        );
      }));

      final ingredients = await ApiService.getIngredients();
      expect(ingredients, hasLength(1));
      expect(ingredients.first['name'], 'Salt');
    });

    test('addIngredient posts payload and returns true on 201', () async {
      await ApiService.saveToken('ingredients-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.method, equals('POST'));
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Paprika');
        return http.Response('{}', 201);
      }));

      final success = await ApiService.addIngredient('Paprika');
      expect(success, isTrue);
    });

    test('getUserFavorites hydrates list with Authorization header', () async {
      await ApiService.saveToken('favorite-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer favorite-token');
        return http.Response(
          jsonEncode({
            'favorites': [
              {'id': 99, 'name': 'Favorite Dish'}
            ]
          }),
          200,
        );
      }));

      final favorites = await ApiService.getUserFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.first['id'], 99);
    });

    test('addToFavorites and removeFromFavorites honor status codes', () async {
      await ApiService.saveToken('favorite-token');
      var addHits = 0;
      var removeHits = 0;
      ApiService.setHttpClient(MockClient((request) async {
        if (request.method == 'POST') {
          addHits++;
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['recipeId'], 5);
          return http.Response('{}', 201);
        }
        if (request.method == 'DELETE') {
          removeHits++;
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['recipeId'], 5);
          return http.Response('{}', 200);
        }
        return http.Response('not handled', 400);
      }));

      expect(await ApiService.addToFavorites(5), isTrue);
      expect(await ApiService.removeFromFavorites(5), isTrue);
      expect(addHits, 1);
      expect(removeHits, 1);
    });

    test('isUserAdmin parses boolean from response', () async {
      await ApiService.saveToken('admin-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response(jsonEncode({'isAdmin': true}), 200);
      }));

      expect(await ApiService.isUserAdmin(), isTrue);
    });

    test('isUserAdmin returns false on non-200', () async {
      await ApiService.saveToken('admin-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response('oops', 500);
      }));

      expect(await ApiService.isUserAdmin(), isFalse);
    });

    test('getUserRecipes returns list of maps', () async {
      await ApiService.saveToken('recipes-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response(
          jsonEncode({
            'recipes': [
              {'id': 11, 'name': 'Owned Dish'}
            ]
          }),
          200,
        );
      }));

      final recipes = await ApiService.getUserRecipes();
      expect(recipes, hasLength(1));
      expect(recipes.first['id'], 11);
    });

    test('uploadRecipe sends multipart payload with encoded arrays', () async {
      await ApiService.saveToken('upload-token');
      late http.MultipartRequest captured;
      ApiService.setHttpClient(_RecordingClient((request) async {
        captured = request as http.MultipartRequest;
        expect(request.headers['Authorization'], 'Bearer upload-token');
        expect(request.url.path, contains('/api/recipes'));
        return _streamedResponse('{}', 201);
      }));

      final recipeData = {
        'name': 'Veggie Soup',
        'category': 'Dinner',
        'time': '30',
        'calories': '220',
        'ingredients': ['Tomato', 'Onion'],
        'instructions': ['Chop', 'Boil'],
        'emotions': ['Cozy']
      };

      final success = await ApiService.uploadRecipe(recipeData, null);

      expect(success, isTrue);
      expect(captured.fields['name'], 'Veggie Soup');
      expect(json.decode(captured.fields['ingredients'] ?? '[]'), contains('Tomato'));
      expect(json.decode(captured.fields['instructions'] ?? '[]'), contains('Boil'));
      expect(json.decode(captured.fields['emotions'] ?? '[]'), contains('Cozy'));
    });

    test('uploadRecipe returns false when client throws', () async {
      await ApiService.saveToken('upload-token');
      ApiService.setHttpClient(_RecordingClient((request) async {
        throw Exception('network down');
      }));

      final recipeData = {
        'name': 'Fail Soup',
        'category': 'Dinner',
        'time': '30',
        'calories': '220',
        'ingredients': [],
        'instructions': [],
        'emotions': []
      };

      final success = await ApiService.uploadRecipe(recipeData, null);
      expect(success, isFalse);
    });

    test('updateRecipe hits recipe endpoint and encodes arrays', () async {
      await ApiService.saveToken('update-token');
      ApiService.setHttpClient(_RecordingClient((request) async {
        final multipart = request as http.MultipartRequest;
        expect(request.url.path, contains('/api/recipes/7'));
        expect(multipart.headers['Authorization'], 'Bearer update-token');
        expect(json.decode(multipart.fields['emotions'] ?? '[]'), contains('Proud'));
        return _streamedResponse('{}', 200);
      }));

      final recipeData = {
        'name': 'Updated Dish',
        'category': 'Lunch',
        'time': '15',
        'calories': '180',
        'ingredients': ['Rice'],
        'instructions': ['Serve'],
        'emotions': ['Proud']
      };

      final success = await ApiService.updateRecipe(7, recipeData, null);
      expect(success, isTrue);
    });

    test('deleteRecipe sends DELETE to recipe endpoint', () async {
      await ApiService.saveToken('delete-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, contains('/api/recipes/42'));
        return http.Response('{}', 200);
      }));

      expect(await ApiService.deleteRecipe(42), isTrue);
    });

    test('deleteRecipe returns false on error response', () async {
      await ApiService.saveToken('delete-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response('nope', 500);
      }));

      expect(await ApiService.deleteRecipe(42), isFalse);
    });

    test('getRecipesWithPermissions returns recipes list', () async {
      await ApiService.saveToken('perm-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.url.path, contains('/api/recipes/with-permissions'));
        return http.Response(
          jsonEncode({
            'recipes': [
              {'id': 1, 'canEdit': true}
            ]
          }),
          200,
        );
      }));

      final recipes = await ApiService.getRecipesWithPermissions();
      expect(recipes, hasLength(1));
      expect(recipes.first['canEdit'], isTrue);
    });

    test('getRecipesWithPermissions returns empty list on failure', () async {
      await ApiService.saveToken('perm-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response('server error', 500);
      }));

      final recipes = await ApiService.getRecipesWithPermissions();
      expect(recipes, isEmpty);
    });

    test('getRecipeOwner returns map on 200', () async {
      await ApiService.saveToken('owner-token');
      ApiService.setHttpClient(MockClient((request) async {
        expect(request.url.path, contains('/api/recipes/77/owner'));
        return http.Response(jsonEncode({'ownerId': 8}), 200);
      }));

      final owner = await ApiService.getRecipeOwner(77);
      expect(owner?['ownerId'], 8);
    });

    test('getRecipeOwner returns null on non-200', () async {
      await ApiService.saveToken('owner-token');
      ApiService.setHttpClient(MockClient((request) async {
        return http.Response('not found', 404);
      }));

      final owner = await ApiService.getRecipeOwner(77);
      expect(owner, isNull);
    });
  });
}
