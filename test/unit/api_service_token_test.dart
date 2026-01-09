import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.removeToken();
  });

  group('ApiService token & header helpers', () {
    test('saveToken persists value and updates headers', () async {
      await ApiService.saveToken('abc123');

      final headers = ApiService.getHeaders();
      expect(headers['Authorization'], equals('Bearer abc123'));
      expect(headers['Content-Type'], equals('application/json'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), equals('abc123'));
    });

    test('removeToken clears persisted state', () async {
      await ApiService.saveToken('will-be-removed');
      await ApiService.removeToken();

      final headers = ApiService.getHeaders();
      expect(headers.containsKey('Authorization'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });

    test('ensureToken reloads token from storage when missing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'restored-token');

      await ApiService.ensureToken();

      final headers = ApiService.getHeaders();
      expect(headers['Authorization'], equals('Bearer restored-token'));
    });

    test('getHeaders can opt-out of Authorization header', () async {
      await ApiService.saveToken('ignored-token');

      final headers = ApiService.getHeaders(includeAuth: false);
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Content-Type'], equals('application/json'));
    });
  });
}
