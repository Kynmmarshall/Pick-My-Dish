import 'dart:convert';  // Add this
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://pickmydish.duckdns.org';
  
  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/test-db'));
      print('Backend status: ${response.statusCode}');
      print('Response: ${response.body}');
    } catch (e) {
      print('Connection error: $e');
    }
  }

  static Future<List<dynamic>> getRecipes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recipes'));
    return json.decode(response.body);  // Now json will work
  }

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      body: json.encode({'email': email, 'password': password}),  // And here
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}