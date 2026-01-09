import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Screens/about_us_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders about us content and developer cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutUsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Meet Our Team'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('About PickMyDish'), 300);
    expect(find.text('About PickMyDish'), findsOneWidget);
  });
}
