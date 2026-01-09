import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Screens/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterScreen', () {
    Future<void> configureViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Future<void> pumpRegister(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('validates email format before submitting', (tester) async {
      await configureViewport(tester);
      await pumpRegister(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Chef User');
      await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(2), 'StrongPass1!');
      await tester.enterText(find.byType(TextField).at(3), 'StrongPass1!');
      final registerButton = find.widgetWithText(ElevatedButton, 'Register').first;
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('valid email address'), findsOneWidget);
    });

    testWidgets('ensures passwords match before calling API', (tester) async {
      await configureViewport(tester);
      await pumpRegister(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Chef User');
      await tester.enterText(find.byType(TextField).at(1), 'chef@test.com');
      await tester.enterText(find.byType(TextField).at(2), 'StrongPass1!');
      await tester.enterText(find.byType(TextField).at(3), 'Mismatch1!');
      final registerButton = find.widgetWithText(ElevatedButton, 'Register').first;
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('updates password strength indicator', (tester) async {
      await configureViewport(tester);
      await pumpRegister(tester);
      await tester.enterText(find.byType(TextField).at(2), 'weak');
      await tester.pump();
      expect(find.textContaining('Password Strength'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(2), 'StrongPass1!');
      await tester.pump();
      expect(find.textContaining('Strong'), findsWidgets);
    });
  });
}
