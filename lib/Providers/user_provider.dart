// Import Flutter material library
import 'package:flutter/material.dart';

// Import cache manager to clear cached images on logout
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Import User model
import 'package:pick_my_dish/Models/user_model.dart';

/// UserProvider
/// Manages authentication state, user profile data,
/// persistent storage, and cleanup on logout
class UserProvider with ChangeNotifier {

  // -------------------- User State --------------------

  // Currently authenticated user (null if not logged in)
  User? _user;

  // Logged-in user's ID
  int _userId = 0;

  // Date the user joined
  DateTime _joined = DateTime.now();

  /// Returns the current user or null if not logged in
  User? get user => _user;

  // Path or URL of the user's profile picture
  String _profilePicture = 'assets/login/noPicture.png';

  /// Returns the profile picture path
  String get profilePicture => _profilePicture;

  /// Returns the username or a default value when not logged in
  String get username => _user?.username ?? 'Guest';

  /// Returns the current user ID
  int get userId => _userId;

  // -------------------- Additional User Data --------------------

  // List of recipes created by the user
  List<Map<String, dynamic>> _userRecipes = [];

  // List of recipe IDs marked as favorites by the user
  List<int> _userFavorites = [];

  // Map of user-specific settings
  Map<String, dynamic> _userSettings = {};

  // -------------------- Authentication Persistence --------------------
  // (This method is usually called during app initialization)

  /// Loads saved authentication data from persistent storage
  /// and restores user session if available
  Future<void> loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve saved authentication data
      final savedToken = prefs.getString('auth_token');
      final savedUserId = prefs.getInt('user_id');
      final savedUsername = prefs.getString('username');
      final savedEmail = prefs.getString('email');
      final savedProfileImage = prefs.getString('profile_image');

      // Check if a valid session exists
      if (savedToken != null && savedUserId != null) {
        _authToken = savedToken;
        _userId = savedUserId;

        // Restore user object
        if (savedUsername != null && savedEmail != null) {
          _user = User(
            id: savedUserId.toString(),
            username: savedUsername,
            email: savedEmail,
            profileImage: savedProfileImage,
          );
        }

        // Restore profile picture
        if (savedProfileImage != null && savedProfileImage.isNotEmpty) {
          _profilePicture = savedProfileImage;
        }

        debugPrint('✅ Restored saved session for user: $savedUsername');
      } else {
        debugPrint('ℹ️ No saved session found');
      }
    } catch (e) {
      debugPrint('❌ Error restoring authentication: $e');
    } finally {
      notifyListeners();
    }
  }

  // -------------------- Persistent Storage Helpers --------------------

  /// Saves authentication-related data to local storage
  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (authData['token'] != null) {
        await prefs.setString('auth_token', authData['token']);
        _authToken = authData['token'];
      }

      if (authData['userId'] != null) {
        await prefs.setInt('user_id', authData['userId']);
        _userId = authData['userId'];
      }

      if (_user != null) {
        await prefs.setString('username', _user!.username);
        await prefs.setString('email', _user!.email);

        if (_user!.profileImage != null) {
          await prefs.setString('profile_image', _user!.profileImage!);
        }
      }

      debugPrint('💾 Authentication data saved');
    } catch (e) {
      debugPrint('❌ Error saving authentication data: $e');
    }
  }

  /// Clears authentication data from persistent storage
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('profile_image');
      debugPrint('🗑️ Authentication data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing authentication data: $e');
    }
  }

  // -------------------- User Management --------------------

  /// Sets the current user and optionally saves auth data
  void setUser(User user, {Map<String, dynamic>? authData}) {
    _user = user;

    if (authData != null) {
      _saveAuthData(authData);
    }

    notifyListeners();
  }

  /// Creates and sets a user from JSON data
  void setUserFromJson(
    Map<String, dynamic> userData, {
    Map<String, dynamic>? authData,
  }) {
    _user = User.fromJson(userData);

    if (authData != null) {
      _saveAuthData(authData);
    }

    notifyListeners();
  }

  /// Updates the username of the current user
  void updateUsername(String newUsername) {
    if (_user != null) {
      _user = _user!.copyWith(username: newUsername);
      notifyListeners();
    }
  }

  /// Updates the profile picture path and persists it
  void updateProfilePicture(String imagePath) {
    _profilePicture = imagePath;
    _saveProfilePicture(imagePath);
    notifyListeners();
  }

  /// Saves profile picture path to persistent storage
  Future<void> _saveProfilePicture(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', imagePath);
    } catch (e) {
      debugPrint('❌ Error saving profile picture: $e');
    }
  }

  // -------------------- Logout & Cleanup --------------------

  /// Clears current user session and all associated data
  void clearUser() {
    _user = null;
    _authToken = null;
    _userId = 0;
    _profilePicture = 'assets/login/noPicture.png';
    _userRecipes.clear();
    _userFavorites.clear();
    _userSettings.clear();

    _clearAuthData();
    _clearImageCache();

    notifyListeners();
  }

  /// Sets user ID manually (used after login)
  void setUserId(int userId) {
    _userId = userId;
    notifyListeners();
  }

  /// Clears ALL user-related data (hard reset)
  void clearAllUserData() {
    _user = null;
    _userId = 0;
    _profilePicture = 'assets/login/noPicture.png';
    _userRecipes.clear();
    _userFavorites.clear();
    _userSettings.clear();

    _clearImageCache();
    _clearLocalStorage();

    notifyListeners();
  }

  /// Clears cached images (profile pictures, recipe images)
  Future<void> _clearImageCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();

      if (_profilePicture.startsWith('http')) {
        await cacheManager.removeFile(_profilePicture);
      }

      debugPrint('🗑️ Image cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing image cache: $e');
    }
  }

  /// Clears local storage (optional extension point)
  Future<void> _clearLocalStorage() async {
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
  }

  /// Logs out the user and clears everything
  void logout() {
    clearAllUserData();
    debugPrint('✅ User logged out successfully');
  }

  // -------------------- Debugging --------------------

  /// Prints current user state for debugging
  void printUserState() {
    if (_user == null) {
      debugPrint('UserProvider: No user logged in');
    } else {
      debugPrint('UserProvider: $_user');
    }
  }
}

