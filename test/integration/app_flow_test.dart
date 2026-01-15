import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/theme_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';

class MockUserProvider extends UserProvider {
  @override
  Future<bool> autoLogin() async {
    // Return immediately for test
    return false;
  }
}

void main() {
  testWidgets('App builds without crashing with providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const PickMyDish(), // Wrap in MaterialApp
      ),
    );
    
    expect(find.byType(MaterialApp), findsOneWidget);
  });

testWidgets('PickMyDish shows loading then MaterialApp', (WidgetTester tester) async {
  // Create mock that completes immediately
  final mockUserProvider = MockUserProvider();
  
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PickMyDish(),
    ),
  );
  
  // Initial loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  // Fast-forward past loading
  await tester.pump(Duration(milliseconds: 100));
  
  // Should show main MaterialApp
  expect(find.byType(MaterialApp), findsOneWidget);
});


  testWidgets('App structure test', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const PickMyDish(),
    ),
  );
  
  // Should contain MaterialApp (created by PickMyDish)
  expect(find.byType(MaterialApp), findsOneWidget);
  // MultiProvider is at root, not inside PickMyDish
  expect(find.byType(MultiProvider), findsOneWidget);
});
}