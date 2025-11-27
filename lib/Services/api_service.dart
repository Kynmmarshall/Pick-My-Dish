import 'dart:convert';  // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // For HTTP requests


class ApiService {
  // Backend server base URL
    
    // For physical device testing:
   //static const String baseUrl = "http://192.168.1.110:3000";
  
  // For production (VPS):
  static const String baseUrl = "http://38.242.246.126:3000";
  
  // Test if backend is reachable and database is connected
  static Future<void> testConnection() async {
    try {
      // Send GET request to test endpoint
      final response = await http.get(Uri.parse('$baseUrl/api/pick_my_dish'));
      debugPrint('Backend status: ${response.statusCode}');  // Should be 200 if successful
      debugPrint('Response: ${response.body}');  // Response data from backend
    } catch (e) {
      debugPrint('Connection error: $e');  // Handle network/database errors
    }
  }

  // Fetch all recipes from the backend
  static Future<List<dynamic>> getRecipes() async {
    // Send GET request to recipes endpoint
    final response = await http.get(Uri.parse('$baseUrl/api/recipes'));
    // Convert JSON response to Dart List
    return json.decode(response.body);
  }

  
  //login user
  static Future<Map<String, dynamic>?>  login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      final errorData = json.decode(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Login successful: ${data['message']}');
        debugPrint('👤 User: ${data['user']}');
        return data;
      } else {
        debugPrint('❌ Login failed: ${response.statusCode} - ${response.body}');
        return {'error': errorData['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {'error': 'Login error: $e'};
    }
  }

// Register a new user with name, email, and password
static Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Registration successful: ${data['message']}');
        return true;
      } else {
        debugPrint('❌ Registration failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return false;
    }
  }

  static Future<void> testAuth() async {
  debugPrint('🔐 Testing authentication...');
  
  // Test Registration
  bool registered = await register('Test User', 'test@example.com', 'password123');
  debugPrint(registered ? '✅ Registration successful' : '❌ Registration failed');
  

}

// Add this test
static Future<void> testBaseUrl() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/'));
    debugPrint('Base URL status: ${response.statusCode}');
    debugPrint('Base URL response: ${response.body}');
  } catch (e) {
    debugPrint('Base URL error: $e');
  }
}

//update user name
static Future<bool> updateUsername(String newUsername) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/username'),
      body: json.encode({'username': newUsername}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

}