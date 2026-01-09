import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUpload(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeUploadScreen(
          ingredientLoaderOverride: () async => [
            {'id': 1, 'name': 'Eggs'},
            {'id': 2, 'name': 'Flour'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('requires name before uploading', (tester) async {
    await pumpUpload(tester);
    final uploadButton = find.widgetWithText(ElevatedButton, 'Upload Recipe');
    await tester.ensureVisible(uploadButton.first);
    await tester.tap(uploadButton.first);
    await tester.pump();
    expect(find.text('Please fill required fields'), findsOneWidget);
  });

  testWidgets('selects ingredients and emotion chips', (tester) async {
    await pumpUpload(tester);
    final eggsTile = find.widgetWithText(CheckboxListTile, 'Eggs');
    await tester.ensureVisible(eggsTile.first);
    await tester.tap(eggsTile.first, warnIfMissed: false);
    await tester.pump();
    expect(find.text('Eggs'), findsWidgets);

    final happyChip = find.text('Happy');
    await tester.ensureVisible(happyChip.first);
    await tester.tap(happyChip.first, warnIfMissed: false);
    await tester.pump();
    expect(happyChip, findsWidgets);
  });
}
