import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/widgets/ingredient_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.removeToken();
    ApiService.resetHttpClient();
  });

  tearDown(ApiService.resetHttpClient);

  group('IngredientSelector basics', () {
    testWidgets('filters ingredient list and toggles selections', (tester) async {
      List<int> lastSelection = const [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientSelector(
              selectedIds: lastSelection,
              onSelectionChanged: (ids) => lastSelection = ids,
              ingredientLoader: () async => [
                {'id': 1, 'name': 'Eggs'},
                {'id': 2, 'name': 'Flour'},
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Flo');
      await tester.pump();

      final flourTile = find.widgetWithText(CheckboxListTile, 'Flour');
      expect(flourTile, findsOneWidget);
      await tester.tap(flourTile);
      await tester.pump();

      expect(lastSelection.contains(2), isTrue);
    });

    testWidgets('adds new ingredient via API pathway', (tester) async {
      await ApiService.saveToken('token');
      var loaderCalls = 0;
      Future<List<Map<String, dynamic>>> loader() async {
        loaderCalls++;
        return [
          {'id': 1, 'name': 'Salt'},
        ];
      }

      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.method == 'POST' && request.url.path.contains('/api/ingredients')) {
            expect(json.decode(request.body)['name'], equals('Paprika'));
            return http.Response('{}', 201);
          }
          return http.Response('[]', 200);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IngredientSelector(
              selectedIds: const [],
              onSelectionChanged: (_) {},
              ingredientLoader: loader,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(loaderCalls, equals(1));

      await tester.enterText(find.byType(TextField).first, 'Paprika');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add "Paprika" as new ingredient'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Enter new ingredient'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(loaderCalls, greaterThan(1));
      expect(find.widgetWithText(TextField, 'Enter new ingredient'), findsNothing);
    });
  });
}
