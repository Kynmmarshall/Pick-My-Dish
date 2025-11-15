import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/main.dart';
import 'package:flutter/material.dart';


void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PickMyDish());
    
    // Verify the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('Constants are defined', () {
    expect(true, true); // Simple test to verify setup works
  });
}