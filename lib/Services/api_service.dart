import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:provider/provider.dart';

class ApiService {
  // Backend server base URL
  static const String baseUrl = "http://38.242.246.126:3000";
  static String? _authToken;

  // Set auth token from provider
  static void setAuthToken(String token) {
    _authToken = token;
    debugPrint('🔑 API Token set: ${token.substring(0, 20)}...');
  }

  // Clear auth token
  static void clearAuthToken() {
    _authToken = null;
    debugPrint('🔑 API Token cleared');
  }

  // Get headers with authorization if token exists
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Initialize API service with context (call this after login)
  static void initializeWithContext(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.authToken != null) {
      setAuthToken(userProvider.authToken!);
    }
  }

  // Test if backend is reachable and database is connected
  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pick_my_dish'));
      debugPrint('Backend status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
    } catch (e) {
      debugPrint('Connection error: $e');
    }
  }

  // Login user - MODIFIED to return token
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      debugPrint('🔐 Attempting login for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Login Response Status: ${response.statusCode}');
      debugPrint('📡 Login Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Login successful: ${data['message']}');
        debugPrint('👤 User data received');
        
        // Extract token from response
        final token = data['token'] ?? data['access_token'] ?? data['auth_token'];
        final userId = data['user']?['id'] ?? data['userId'] ?? 0;
        
        if (token != null) {
          // Store the token
          setAuthToken(token);
          
          return {
            'user': data['user'] ?? {},
            'token': token,
            'userId': userId,
          };
        } else {
          debugPrint('⚠️ No token received in login response');
          return {'user': data['user'] ?? {}, 'userId': userId};
        }
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Login failed: ${response.statusCode} - ${response.body}');
        return {'error': errorData['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {'error': 'Login error: $e'};
    }
  }

  // Register a new user with name, email, and password
  static Future<bool> register(String userName, String email, String password) async {
    try {
      debugPrint('📝 Attempting registration for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        body: json.encode({
          'userName': userName,
          'email': email,
          'password': password
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      debugPrint('📡 Registration Response: ${response.statusCode}');
      
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
    bool registered = await register('Test User', 'test@example.com', 'password123');
    debugPrint(registered ? '✅ Registration successful' : '❌ Registration failed');
  }

  static Future<void> testBaseUrl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      debugPrint('Base URL status: ${response.statusCode}');
      debugPrint('Base URL response: ${response.body}');
    } catch (e) {
      debugPrint('Base URL error: $e');
    }
  }

  // Update user name - MODIFIED to use token
  static Future<bool> updateUsername(String newUsername, int userId) async {
    try {
      debugPrint('🔄 Updating username: $newUsername for user: $userId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/username'),
        body: json.encode({
          'username': newUsername,
          'userId': userId
        }),
        headers: _getHeaders(), // Use token headers
      );
      
      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return false;
    }
  }

  // Update profile picture - MODIFIED to use token
  static Future<bool> uploadProfilePicture(File imageFile, int userId) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/users/profile-picture')
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path)
      );
      
      request.fields['userId'] = userId.toString();
      
      // Add authorization header if token exists
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Upload profile picture error: $e');
      return false;
    }
  }

  // Get profile picture - MODIFIED to use token
  static Future<String?> getProfilePicture(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile-picture?userId=$userId'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imagePath'];
      } else {
        print('❌ Failed to get profile picture: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting profile picture: $e');
      return null;
    }
  }

  // Get all recipes - MODIFIED to use token
  static Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes'),
        headers: _getHeaders(), // Use token headers
      );
      
      debugPrint('📡 Recipes endpoint: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      } else {
        print('❌ Failed to fetch recipes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      return [];
    }
  }

  // Upload recipe with image - MODIFIED to use token
  static Future<bool> uploadRecipe(Map<String, dynamic> recipeData, File? imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/recipes'));
      
      // Add recipe data
      request.fields['name'] = recipeData['name'];
      request.fields['category'] = recipeData['category'];
      request.fields['time'] = recipeData['time'];
      request.fields['calories'] = recipeData['calories'];
      request.fields['ingredients'] = json.encode(recipeData['ingredients']);
      request.fields['instructions'] = json.encode(recipeData['instructions']);
      request.fields['userId'] = recipeData['userId'].toString();
      
      final emotions = recipeData['emotions'] ?? [];
      request.fields['emotions'] = json.encode(emotions);
      
      print('📤 Sending emotions: $emotions');
      
      // Add image if exists
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path)
        );
      }
      
      // Add authorization header if token exists
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error uploading recipe: $e');
      return false;
    }
  }

  // Method to get ingredients - MODIFIED to use token
  static Future<List<Map<String, dynamic>>> getIngredients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ingredients'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error getting ingredients: $e');
      return [];
    }
  }

  // Method to create new ingredient - MODIFIED to use token
  static Future<bool> addIngredient(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ingredients'),
        body: json.encode({'name': name}),
        headers: _getHeaders(), // Use token headers
      );
      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error adding ingredient: $e');
      return false;
    }
  }

  // Get user's favorite recipes - MODIFIED to use token
  static Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/favorites'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching favorites: $e');
      return [];
    }
  }

  // Add recipe to favorites - MODIFIED to use token
  static Future<bool> addToFavorites(int userId, int recipeId) async {
    debugPrint('📤 API: Adding favorite - User: $userId, Recipe: $recipeId');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/favorites'),
        body: json.encode({
          'userId': userId,
          'recipeId': recipeId,
        }),
        headers: _getHeaders(), // Use token headers
      );
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error adding to favorites: $e');
      return false;
    }
  }

  // Remove recipe from favorites - MODIFIED to use token
  static Future<bool> removeFromFavorites(int userId, int recipeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/favorites'),
        body: json.encode({
          'userId': userId,
          'recipeId': recipeId,
        }),
        headers: _getHeaders(), // Use token headers
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error removing from favorites: $e');
      return false;
    }
  }

  // Check if recipe is favorited by user - MODIFIED to use token
  static Future<bool> isRecipeFavorited(int userId, int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/favorites/check?userId=$userId&recipeId=$recipeId'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorited'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Check if user is admin - MODIFIED to use token
  static Future<bool> isUserAdmin(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/is-admin'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Get user's own recipes - MODIFIED to use token
  static Future<List<Map<String, dynamic>>> getUserRecipes(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/recipes'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user recipes: $e');
      return [];
    }
  }

  // Update recipe with ownership check - MODIFIED to use token
  static Future<bool> updateRecipe(
    int recipeId,
    Map<String, dynamic> recipeData,
    File? imageFile,
    int userId
  ) async {
    debugPrint('📤 API: updateRecipe called');
    
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/recipes/$recipeId')
      );
      
      // Add recipe data
      request.fields['userId'] = userId.toString();
      request.fields['name'] = recipeData['name'];
      request.fields['category'] = recipeData['category'];
      request.fields['time'] = recipeData['time'];
      request.fields['calories'] = recipeData['calories'];
      request.fields['ingredients'] = json.encode(recipeData['ingredients']);
      request.fields['instructions'] = json.encode(recipeData['instructions']);
      
      final emotions = recipeData['emotions'] ?? [];
      request.fields['emotions'] = json.encode(emotions);
      
      // Add image if exists
      if (imageFile != null) {
        debugPrint('📸 Adding image file: ${imageFile.path}');
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path)
        );
      }
      
      // Add authorization header if token exists
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      debugPrint('🚀 Sending request to: $baseUrl/api/recipes/$recipeId');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      debugPrint('📡 Update response status: ${response.statusCode}');
      debugPrint('📡 Update response body: $responseBody');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating recipe: $e');
      return false;
    }
  }

  // Delete recipe with ownership check - MODIFIED to use token
  static Future<bool> deleteRecipe(int recipeId, int userId) async {
    debugPrint('📤 API: deleteRecipe called - recipeId: $recipeId, userId: $userId');
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/recipes/$recipeId'),
        body: json.encode({
          'userId': userId,
        }),
        headers: _getHeaders(), // Use token headers
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return false;
    }
  }

  // Get all recipes with permissions - MODIFIED to use token
  static Future<List<Map<String, dynamic>>> getRecipesWithPermissions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes/with-permissions?userId=$userId'),
        headers: _getHeaders(), // Use token headers
      );
      
      debugPrint('📡 Recipes with permissions: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching recipes with permissions: $e');
      return [];
    }
  }

  // Get recipe ownership info - MODIFIED to use token
  static Future<Map<String, dynamic>?> getRecipeOwner(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes/$recipeId/owner'),
        headers: _getHeaders(), // Use token headers
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting recipe owner: $e');
      return null;
    }
  }

  static Future<void> testRecipeUpload() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/recipes'));
      debugPrint('Recipes endpoint: ${response.statusCode}');
    } catch (e) {
      debugPrint('Recipes endpoint error: $e');
    }
  }
}
