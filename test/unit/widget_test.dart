import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/main.dart';
import 'package:pick_my_dish/Screens/splash_screen.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Screens/register_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/constants.dart';
import '../test_helper.dart'; 

void main() {
  // Test the screens in isolation with proper setup
  group('Screen Rendering Tests - Basic', () {
    testWidgets('App builds without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const PickMyDish());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('SplashScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('HomeScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('LoginScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('RegisterScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('RecipeScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(RecipesScreen), findsOneWidget);
    });

    testWidgets('FavoriteScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const FavoritesScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('ProfileScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen()));
      await tester.pump(); // Allow frame to render
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('Key UI Elements Tests', () {
    testWidgets('HomeScreen shows welcome text', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle(); // Wait for all animations
      
      // Use findsAtLeast to be more flexible
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('LoginScreen shows app title', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('PICK MY DISH'), findsAtLeast(1));
    });

    testWidgets('RegisterScreen shows register title', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('Register'), findsAtLeast(1));
    });

    testWidgets('RecipeScreen shows all recipes title', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('All Recipes'), findsAtLeast(1));
    });

    testWidgets('FavoriteScreen shows favorite recipes title', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const FavoritesScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('Favorite Recipes'), findsAtLeast(1));
    });
  });

  group('Form Elements Tests', () {
    testWidgets('LoginScreen has email field', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      
      // Look for TextField with hint text containing "Email"
      final emailFields = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                    widget.decoration?.hintText?.toLowerCase().contains('email') == true
      );
      expect(emailFields, findsAtLeast(1));
    });

    testWidgets('LoginScreen has password field', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      
      // Look for TextField with obscure text (password field)
      final passwordFields = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.obscureText == true
      );
      expect(passwordFields, findsAtLeast(1));
    });

    testWidgets('RegisterScreen has multiple text fields', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pumpAndSettle();
      
      // Should have multiple text fields for registration
      expect(find.byType(TextField), findsAtLeast(3));
    });

    testWidgets('ProfileScreen shows username field when editing', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen()));
      await tester.pumpAndSettle();
      
      // Initially, the TextField should not be visible (since _isEditing is false)
      final usernameField = find.byKey(const Key('username_field'));
      expect(usernameField, findsNothing);
      
      // Find and tap the edit button
      final editButton = find.byKey(const Key('edit_button'));
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      
      // Now the TextField should be visible
      expect(usernameField, findsOneWidget);
      
      // Verify the TextField has the correct hint text
      final textField = tester.widget<TextField>(usernameField);
      expect(textField.decoration?.hintText, 'Enter username');
    });
  });

  group('Button Tests', () {
    testWidgets('LoginScreen has login button', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      
      // Look for elevated buttons
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('RegisterScreen has register button', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pumpAndSettle();
      
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('ProfileScreen has save button', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen()));
      await tester.pumpAndSettle();
      
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });
  });

  group('Icon Tests', () {
    testWidgets('RecipeScreen has favorite icons', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pumpAndSettle();
      
      // Should have favorite icons
      expect(find.byIcon(Icons.favorite), findsAtLeast(1));
      expect(find.byIcon(Icons.favorite_border), findsAtLeast(1));
    });

    testWidgets('Screens have back buttons', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pumpAndSettle();
      
      // Many screens have back arrow icons
      expect(find.byIcon(Icons.arrow_back), findsAtLeast(1));
    });
  });

  group('Layout Tests', () {
    testWidgets('HomeScreen has personalization section', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      
      // Look for elements that should be in the personalization section
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('What would you like to cook today?'), findsOneWidget);
    });

    testWidgets('RecipeScreen has search field', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pumpAndSettle();
      
      // Look for search icon or search-related text
      expect(find.byIcon(Icons.search), findsAtLeast(1));
    });

    testWidgets('HomeScreen shows recipe section', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('Today\'s Fresh Recipe'), findsAtLeast(1));
    });
  });

  group('Input Tests', () {
    testWidgets('Can type in login email field', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      
      // Find first text field and enter text
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    testWidgets('Can type in recipe search', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const RecipesScreen()));
      await tester.pumpAndSettle();
      
      // Find text fields and try to enter text in the first one (likely search)
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'chicken');
        expect(find.text('chicken'), findsOneWidget);
      }
    });
  });

  group('Constants Test', () {
    test('Text styles are defined', () {
      expect(title, isA<TextStyle>());
      expect(text, isA<TextStyle>());
      expect(mediumtitle, isA<TextStyle>());
    });

    test('Global variables exist', () {
      expect(isPasswordVisible, isA<bool>());
    });
  });
}