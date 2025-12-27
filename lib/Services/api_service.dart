import 'dart:convert';  // For JSON encoding/decoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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


  //login user
  static Future<Map<String, dynamic>?>  login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      final errorData = json.decode(response.body);
      // ADD THIS DEBUG LINE:
      debugPrint('Login Response: ${response.body}');
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
static Future<bool> register(String userName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        body: json.encode({
          'userName': userName,
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
static Future<bool> updateUsername(String newUsername, int userId) async {
  try {
     debugPrint('🔄 Updating username: $newUsername for user: $userId');
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/username'),
      body: json.encode({
        'username': newUsername,
        'userId': userId  // ← Send user ID
      }),
      headers: {'Content-Type': 'application/json'},
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
static Future<bool> uploadProfilePicture(File imageFile, int userId) async {
  try {
    var request = http.MultipartRequest(
      'PUT', 
      Uri.parse('$baseUrl/api/users/profile-picture')
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path)
    );
    
    // Add user ID to request
    request.fields['userId'] = userId.toString();
    
    var response = await request.send();
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

//Get profile picture
static Future<String?> getProfilePicture(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile-picture?userId=$userId')
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['imagePath']; // Returns the image path from database
    } else {
      print('❌ Failed to get profile picture: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ Error getting profile picture: $e');
    return null;
  }
}

// Get all recipes
static Future<List<Map<String, dynamic>>> getRecipes() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/recipes'),
      headers: {'Content-Type': 'application/json'},
    );
    
    debugPrint('📡 Recipes endpoint: ${response.statusCode}'); 
    debugPrint('📡 Response body: ${response.body}');
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
  
// Upload recipe with image
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
      print('📤 Encoded emotions: ${json.encode(emotions)}');

      // Add image if exists
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path)
        );
      }
      
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error uploading recipe: $e');
      return false;
    }
  }

//method to get ingredients
static Future<List<Map<String, dynamic>>> getIngredients() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ingredients'),
      headers: {'Content-Type': 'application/json'},
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

//method to create new ingredient
static Future<bool> addIngredient(String name) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ingredients'),
      body: json.encode({'name': name}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 201;
  } catch (e) {
    print('❌ Error adding ingredient: $e');
    return false;
  }
}

// Get user's favorite recipes
static Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/favorites'),
      headers: {'Content-Type': 'application/json'},
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
static Future<bool> addToFavorites(int userId, int recipeId) async {
  debugPrint('📤 API: Adding favorite - User: $userId, Recipe: $recipeId');
  debugPrint('📤 URL: $baseUrl/api/users/favorites');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/favorites'),
      body: json.encode({
        'userId': userId,
        'recipeId': recipeId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    
    return response.statusCode == 201;
  } catch (e) {
    debugPrint('❌ Error adding to favorites: $e');
    return false;
  }
}

// Remove recipe from favorites
static Future<bool> removeFromFavorites(int userId, int recipeId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/favorites'),
      body: json.encode({
        'userId': userId,
        'recipeId': recipeId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ Error removing from favorites: $e');
    return false;
  }
}

// Check if recipe is favorited by user
static Future<bool> isRecipeFavorited(int userId, int recipeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/favorites/check?userId=$userId&recipeId=$recipeId'),
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
static Future<bool> isUserAdmin(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/is-admin'),
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
static Future<List<Map<String, dynamic>>> getUserRecipes(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/recipes'),
        headers: {'Content-Type': 'application/json'},
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
  int userId
) async {
  debugPrint('📤 API: updateRecipe called');
  debugPrint('   Recipe ID: $recipeId');
  debugPrint('   User ID: $userId');
  debugPrint('   Data: $recipeData');
  debugPrint('   Has image: ${imageFile != null}');
  
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

// Delete recipe with ownership check
static Future<bool> deleteRecipe(int recipeId, int userId) async {
    debugPrint('📤 API: deleteRecipe called - recipeId: $recipeId, userId: $userId');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/recipes/$recipeId'),
        body: json.encode({
          'userId': userId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return false;
    }
  }

// Get all recipes with edit permissions
static Future<List<Map<String, dynamic>>> getRecipesWithPermissions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes/with-permissions?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
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

// Get recipe ownership info (check if user created the recipe)
static Future<Map<String, dynamic>?> getRecipeOwner(int recipeId) async {
  try {
    final response = await http.get(
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
    final response = await http.get(Uri.parse('$baseUrl/api/recipes'));
    debugPrint('Recipes endpoint: ${response.statusCode}');
  } catch (e) {
    debugPrint('Recipes endpoint error: $e');
  }
}

}