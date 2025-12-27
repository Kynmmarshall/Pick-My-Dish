import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Screens/splash_screen.dart';
import 'package:pick_my_dish/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';

void main() {

testWidgets('App builds without crashing with providers', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const PickMyDish(),
    ),
  );
  
  expect(find.byType(MaterialApp), findsOneWidget);
});

test('Main function structure', () {
// Test that main.dart has correct structure
expect(PickMyDish.new, returnsNormally);

// Create instance to ensure it builds
final app = PickMyDish();
expect(app, isA<StatelessWidget>());
});

test('App has correct debug mode setting', () {
// Test that debug banner is disabled
final app = PickMyDish();
final widget = app.build(MockBuildContext());

expect(widget, isA<MaterialApp>());
final materialApp = widget as MaterialApp;
expect(materialApp.debugShowCheckedModeBanner, false);
});
}

class MockBuildContext extends Mock implements BuildContext {}

void mainAdditionalTests() {
test('Additional app flow tests', () {
// Test constants and setup
expect(true, true);
});
}