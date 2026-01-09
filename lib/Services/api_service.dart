import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Backend server base URL
    
    // For physical device testing:
   //static const String baseUrl = "http://192.168.1.110:3000";
  
  // For production (VPS):
  static const String baseUrl = "http://38.242.246.126:3000";
  static String? _token;
  static http.Client _client = http.Client();

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _client = client;
  }

  @visibleForTesting
  static void resetHttpClient() {
    try {
      _client.close();
    } catch (_) {
      // Ignore client close errors during tests
    }
    _client = http.Client();
  }

  // Initialize token from shared preferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }
  
    static Future<void> ensureToken() async {
    if (_token == null) await init();
  }

  // Save token to shared preferences
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  // Remove token (logout)
  static Future<void> removeToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Test if backend is reachable and database is connected
  static Future<void> testConnection() async {
    try {
      // Send GET request to test endpoint
      final response = await _client.get(Uri.parse('$baseUrl/api/pick_my_dish'));
      debugPrint('Backend status: ${response.statusCode}');  // Should be 200 if successful
      debugPrint('Response: ${response.body}');  // Response data from backend
    } catch (e) {
      debugPrint('Connection error: $e');  // Handle network/database errors
    }
  }


   // Get headers with authentication
  static Map<String, String> getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }


  //login user
  static Future<Map<String, dynamic>?>  login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        body: json.encode({'email': email, 'password': password}),
        headers: getHeaders(includeAuth: false),
      );
      final errorData = json.decode(response.body);
      // ADD THIS DEBUG LINE:
      debugPrint('Login Response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Save the token
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
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
static Future<Map<String, dynamic>?> register(String userName, String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        body: json.encode({
          'userName': userName,
          'email': email,
          'password': password
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      debugPrint('Register Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save the token
        if (data['token'] != null) {
          await saveToken(data['token']);
        }

        debugPrint('✅ Registration successful: ${data['message']}');
        return data;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Registration failed: ${response.statusCode} - ${response.body}');
        return {'error': errorData['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return {'error': 'Registration error: $e'};
    }
  }


// Add this test
static Future<void> testBaseUrl() async {
  try {
    final response = await _client.get(Uri.parse('$baseUrl/'));
    debugPrint('Base URL status: ${response.statusCode}');
    debugPrint('Base URL response: ${response.body}');
  } catch (e) {
    debugPrint('Base URL error: $e');
  }
}

// Verify token
static Future<Map<String, dynamic>?> verifyToken() async {
  try {
    await init(); // Make sure token is loaded
    
    if (_token == null) {
      return {'valid': false, 'error': 'No token found'};
    }
    
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/verify'),
      headers: getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      // Token is invalid, remove it
      await removeToken();
      final errorData = json.decode(response.body);
      return {'valid': false, 'error': errorData['error']};
    }
  } catch (e) {
    debugPrint('❌ Token verification error: $e');
    return {'valid': false, 'error': 'Verification failed'};
  }
}

//update user name
static Future<bool> updateUsername(String newUsername) async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.put(
      Uri.parse('$baseUrl/api/users/username'),
      body: json.encode({
        'username': newUsername,
      }),
      headers: getHeaders(),
    );

    debugPrint('📡 Status: ${response.statusCode}');
    debugPrint('📡 Body: ${response.body}');
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ Error: $e');
    return false;
  }
}

//update profile picture
static Future<bool> uploadProfilePicture(File imageFile) async {
  try {
    await ensureToken(); // Ensure token is loaded
    var request = http.MultipartRequest(
      'PUT', 
      Uri.parse('$baseUrl/api/users/profile-picture')
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path)
    );
    
    // Add authorization header
    request.headers['Authorization'] = 'Bearer $_token';
    
    var response = await _client.send(request);
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

//Get profile picture
static Future<String?> getProfilePicture() async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/users/profile-picture'),
      headers: getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['imagePath']; // Returns the image path from database
    } else {
      debugPrint('❌ Failed to get profile picture: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('❌ Error getting profile picture: $e');
    return null;
  }
}

// Get all recipes
static Future<List<Map<String, dynamic>>> getRecipes() async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/recipes'),
      headers: getHeaders(),
    );
    
    debugPrint('📡 Recipes endpoint: ${response.statusCode}'); 
    debugPrint('📡 Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
    } else if (response.statusCode == 401) {
        // Token expired or invalid
        debugPrint('❌ Authentication required');
        return [];
      }else {
      debugPrint('❌ Failed to fetch recipes: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('❌ Error fetching recipes: $e');
    return [];
  }
}
  
// Upload recipe with image
static Future<bool> uploadRecipe(Map<String, dynamic> recipeData, File? imageFile) async {
    try {
      await init();
      await ensureToken(); // Ensure token is loaded
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/recipes'));
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_token';

      // Add recipe data
      request.fields['name'] = recipeData['name'];
      request.fields['category'] = recipeData['category'];
      request.fields['time'] = recipeData['time'];
      request.fields['calories'] = recipeData['calories'];
      request.fields['ingredients'] = json.encode(recipeData['ingredients']);
      request.fields['instructions'] = json.encode(recipeData['instructions']);
    
      final emotions = recipeData['emotions'] ?? [];
      request.fields['emotions'] = json.encode(emotions);
      
      debugPrint('📤 Sending emotions: $emotions');
      debugPrint('📤 Encoded emotions: ${json.encode(emotions)}');

      // Add image if exists
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path)
        );
      }
      
      var response = await _client.send(request);
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error uploading recipe: $e');
      return false;
    }
  }

//method to get ingredients
static Future<List<Map<String, dynamic>>> getIngredients() async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/ingredients'),
      headers: getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error getting ingredients: $e');
    return [];
  }
}

//method to create new ingredient
static Future<bool> addIngredient(String name) async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.post(
      Uri.parse('$baseUrl/api/ingredients'),
      body: json.encode({'name': name}),
      headers: getHeaders(),
    );
    return response.statusCode == 201;
  } catch (e) {
    debugPrint('❌ Error adding ingredient: $e');
    return false;
  }
}

// Get user's favorite recipes
static Future<List<Map<String, dynamic>>> getUserFavorites() async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/users/favorites'),
      headers: getHeaders(),
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

// Add recipe to favorites
static Future<bool> addToFavorites( int recipeId) async {
  debugPrint('📤 URL: $baseUrl/api/users/favorites');
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.post(
      Uri.parse('$baseUrl/api/users/favorites'),
      body: json.encode({
        'recipeId': recipeId,
      }),
      headers: getHeaders(),
    );
    
    return response.statusCode == 201;
  } catch (e) {
    debugPrint('❌ Error adding to favorites: $e');
    return false;
  }
}

// Remove recipe from favorites
static Future<bool> removeFromFavorites( int recipeId) async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/users/favorites'),
      body: json.encode({
        'recipeId': recipeId,
      }),
      headers: getHeaders(),
    );
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ Error removing from favorites: $e');
    return false;
  }
}

// Check if recipe is favorited by user
static Future<bool> isRecipeFavorited( int recipeId) async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/users/favorites/check?recipeId=$recipeId'),
      headers: getHeaders(),
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

// Check if user is admin
static Future<bool> isUserAdmin() async {
    try {
      await ensureToken(); // Ensure token is loaded
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/is-admin'),
        headers: getHeaders(),
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

// Get user's own recipes
static Future<List<Map<String, dynamic>>> getUserRecipes() async {
    try {
      await ensureToken(); // Ensure token is loaded
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/recipes'),
        headers: getHeaders(),
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

// Update recipe with ownership check
static Future<bool> updateRecipe(
  int recipeId,
  Map<String, dynamic> recipeData,
  File? imageFile,
) async {
  debugPrint('📤 API: updateRecipe called');
  debugPrint('   Recipe ID: $recipeId');
  debugPrint('   Data: $recipeData');
  debugPrint('   Has image: ${imageFile != null}');
  
  try {
    await ensureToken(); // Ensure token is loaded
    var request = http.MultipartRequest(
      'PUT', 
      Uri.parse('$baseUrl/api/recipes/$recipeId')
    );
    
    // Add authorization header
    request.headers['Authorization'] = 'Bearer $_token';

    // Add recipe data
    request.fields['name'] = recipeData['name'];
    request.fields['category'] = recipeData['category'];
    request.fields['time'] = recipeData['time'];
    request.fields['calories'] = recipeData['calories'];
    request.fields['ingredients'] = json.encode(recipeData['ingredients']);
    request.fields['instructions'] = json.encode(recipeData['instructions']);
    
    final emotions = recipeData['emotions'] ?? [];
    request.fields['emotions'] = json.encode(emotions);
    
    debugPrint('📤 Fields:');
    request.fields.forEach((key, value) {
      debugPrint('   $key: $value');
    });
    
    // Add image if exists
    if (imageFile != null) {
      debugPrint('📸 Adding image file: ${imageFile.path}');
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path)
      );
    }

    debugPrint('🚀 Sending request to: $baseUrl/api/recipes/$recipeId');
    var response = await _client.send(request);
    var responseBody = await response.stream.bytesToString();
    
    debugPrint('📡 Update response status: ${response.statusCode}');
    debugPrint('📡 Update response body: $responseBody');
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ Error updating recipe: $e');
    return false;
  }
}

// Delete recipe with ownership check
static Future<bool> deleteRecipe(int recipeId) async {
    try {
      await ensureToken(); // Ensure token is loaded
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/recipes/$recipeId'),
        headers: getHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return false;
    }
  }

// Get all recipes with edit permissions
static Future<List<Map<String, dynamic>>> getRecipesWithPermissions() async {
    try {
      await ensureToken(); // Ensure token is loaded
      final response = await _client.get(
        Uri.parse('$baseUrl/api/recipes/with-permissions'),
        headers: getHeaders(),
      );
      
      debugPrint('📡 Recipes with permissions: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching recipes with permissions: $e');
      return [];
    }
  }

// Get recipe ownership info (check if user created the recipe)
static Future<Map<String, dynamic>?> getRecipeOwner(int recipeId) async {
  try {
    await ensureToken(); // Ensure token is loaded
    final response = await _client.get(
      Uri.parse('$baseUrl/api/recipes/$recipeId/owner'),
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
    final response = await _client.get(Uri.parse('$baseUrl/api/recipes'));
    debugPrint('Recipes endpoint: ${response.statusCode}');
  } catch (e) {
    debugPrint('Recipes endpoint error: $e');
  }
}

}