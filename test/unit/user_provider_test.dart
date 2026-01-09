import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('UserProvider', () {
    late UserProvider provider;

    setUp(() {
      provider = UserProvider();
    });

    test('sets user from json and updates username', () {
      provider.setUserFromJson({
        'id': 7,
        'username': 'Original',
        'email': 'user@example.com',
      });
      expect(provider.username, 'Original');

      provider.updateUsername('Updated');
      expect(provider.username, 'Updated');
    });

    test('updates profile picture and clears data', () {
      provider.overrideApiForTest(clearImageCache: () async {});
      provider.updateProfilePicture('custom/path.png');
      expect(provider.profilePicture, 'custom/path.png');

      provider.clearAllUserData();
      expect(provider.username, 'Guest');
      expect(provider.profilePicture, 'assets/login/noPicture.png');
      expect(provider.userId, 0);
    });

    test('autoLogin sets user when verifyToken succeeds', () async {
      provider.overrideApiForTest(
        verifyToken: () async => {
          'valid': true,
          'user': {
            'id': '42',
            'username': 'Chef',
            'email': 'chef@test.com',
          },
        },
      );

      final result = await provider.autoLogin();

      expect(result, isTrue);
      expect(provider.userId, 42);
      expect(provider.username, 'Chef');
    });

    test('autoLogin removes token when backend reports invalid', () async {
      var removeCalled = false;
      provider.overrideApiForTest(
        verifyToken: () async => {'valid': false},
        removeToken: () async {
          removeCalled = true;
        },
      );

      final result = await provider.autoLogin();

      expect(result, isFalse);
      expect(removeCalled, isTrue);
    });

    test('login stores user data via override', () async {
      provider.overrideApiForTest(
        login: (email, password) async {
          expect(email, 'chef@test.com');
          expect(password, 'Secret123!');
          return {
            'user': {
              'id': '7',
              'username': 'Chef',
              'email': email,
            }
          };
        },
      );

      await provider.login('chef@test.com', 'Secret123!');

      expect(provider.userId, 7);
      expect(provider.username, 'Chef');
    });

    test('logout clears user session and caches', () async {
      var removeCalled = false;
      var cacheCleared = false;
      provider.setUserFromJson({
        'id': 9,
        'username': 'SessionUser',
        'email': 'session@test.com',
      });
      provider.overrideApiForTest(
        removeToken: () async {
          removeCalled = true;
        },
        clearImageCache: () async {
          cacheCleared = true;
        },
      );

      await provider.logout();

      expect(removeCalled, isTrue);
      expect(cacheCleared, isTrue);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.profilePicture, 'assets/login/noPicture.png');
    });
  });
}
