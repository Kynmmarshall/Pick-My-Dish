import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Services/api_service.dart';

/// Provider that holds and manages the current authenticated user.
/// 
/// Uses [ChangeNotifier] so widgets can listen to changes and rebuild
/// when the user data is updated or cleared.
class UserProvider with ChangeNotifier {
  // Backing field for the current user. Null when no user is logged in.
  User? _user;
  int _userId = 0;
  /// Returns the current user, or null if not signed in.
  User? get user => _user;
  String _profilePicture = 'assets/login/noPicture.png';
  String get profilePicture => _profilePicture;
  /// Returns the username of the current user, or a default 'User' string
  /// when no user is available.
  String get username => _user?.username ?? 'Guest';  
  int get userId => _userId;  

  Future<Map<String, dynamic>?> Function()? _verifyTokenOverride;
  Future<Map<String, dynamic>?> Function(String email, String password)?
      _loginOverride;
  Future<void> Function()? _removeTokenOverride;
  Future<void> Function()? _clearImageCacheOverride;

  /// Returns the email of the current user, or empty string if not available.
  String get email => _user?.email ?? '';

  /// Returns the profile image URL of the current user, or null if not available.
  String? get profileImage => _user?.profileImage;

  /// Indicates whether a user is currently logged in.
  bool get isLoggedIn => _user != null;

  bool _isDisposed = false;

   // Add this method:
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  // Safe notify method:
  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @visibleForTesting
  void overrideApiForTest({
    Future<Map<String, dynamic>?> Function()? verifyToken,
    Future<Map<String, dynamic>?> Function(String email, String password)? login,
    Future<void> Function()? removeToken,
    Future<void> Function()? clearImageCache,
  }) {
    _verifyTokenOverride = verifyToken ?? _verifyTokenOverride;
    _loginOverride = login ?? _loginOverride;
    _removeTokenOverride = removeToken ?? _removeTokenOverride;
    _clearImageCacheOverride = clearImageCache ?? _clearImageCacheOverride;
  }

  @visibleForTesting
  void resetApiOverrides() {
    _verifyTokenOverride = null;
    _loginOverride = null;
    _removeTokenOverride = null;
    _clearImageCacheOverride = null;
  }
  
  // Update ALL notifyListeners() calls to safeNotify():
  void setUser(User user) {
    _user = user;
    safeNotify(); // <-- Change this
  }

  Future<bool> autoLogin() async {
    try {
      debugPrint('🔐 Attempting auto-login...');
      
      final verifyFn = _verifyTokenOverride ?? ApiService.verifyToken;
      final result = await verifyFn();
      
      if (result?['valid'] == true && result?['user'] != null) {
        debugPrint('✅ Token valid, setting user...');
        
        _user = User.fromJson(result!['user']);
        _userId = _user!.id.isNotEmpty ? int.parse(_user!.id) : 0;
        
        debugPrint('👤 User loaded: ${_user!.username}');
        
        // IMPORTANT: Notify listeners on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          safeNotify(); // <-- Change this
        });
        
        return true;
      } else {
        debugPrint('❌ Token invalid or expired');
        final removeTokenFn = _removeTokenOverride ?? ApiService.removeToken;
        await removeTokenFn(); // Clear invalid token
        return false;
      }
    } catch (e) {
      debugPrint('❌ Auto-login error: $e');
      return false;
    }
  }
  
  Future<void> login(String email, String password) async {
    final loginFn = _loginOverride ?? ApiService.login;
    final result = await loginFn(email, password);
    
    if (result != null && result['error'] == null) {
      _user = User.fromJson(result['user']);
      _userId = _user!.id.isNotEmpty ? int.parse(_user!.id) : 0;
      safeNotify();
    } else {
      throw Exception(result?['error'] ?? 'Login failed');
    }
  }


  /// Create and set user from JSON data (typically from API response).
  /// Convenience method that uses [User.fromJson] constructor.
  void setUserFromJson(Map<String, dynamic> userData) {
    _user = User.fromJson(userData);
    safeNotify();
  }

  /// Update only the username for the current user and notify listeners.
  ///
  /// If there is no current user, this method does nothing.
  void updateUsername(String newUsername) {
    if (_user != null) {
      // Use the model's copyWith to preserve other fields.
      _user = _user!.copyWith(username: newUsername);
      safeNotify();
    }
  }


  /// Update the user's profile image and notify listeners.
  ///
  /// If there is no current user, this method does nothing.
  void updateProfilePicture(String imagePath) {
    _profilePicture = imagePath;
    safeNotify();
  }


  /// Clear the current user (log out) and notify listeners.
  void clearUser() {
    _user = null;
    safeNotify();
  }

  void setUserId(int userId) {
    _userId = userId;
    safeNotify();
  }
  /// Debug method to print current user state
  void printUserState() {
    if (_user == null) {
      debugPrint('UserProvider: No user logged in');
    } else {
      debugPrint('UserProvider: Current user - ${_user!.toString()}');
      debugPrint('UserProvider: First name - $username');
    }
  }
  
  
  /// Clear ALL user data
  void clearAllUserData() {
    _user = null;
    _userId = 0;
    _profilePicture = 'assets/login/noPicture.png';
    
    // Clear image cache
    _clearImageCache();
    
    safeNotify();
  }

  Future<void> _clearImageCache() async {
  if (_clearImageCacheOverride != null) {
    await _clearImageCacheOverride!.call();
    return;
  }
  try {
    // 1. Clear specific cached profile image URL if it exists
    if (_user?.profileImage != null && !_user!.profileImage!.startsWith('assets/')) {
      final profileImageUrl = 'http://38.242.246.126:3000/${_user!.profileImage}';
      
      // Method 1: Use evictFromCache (most reliable for CachedNetworkImage)
      await CachedNetworkImage.evictFromCache(profileImageUrl);
      
      // Method 2: Use DefaultCacheManager
      await DefaultCacheManager().removeFile(profileImageUrl);
      
      debugPrint('🗑️ Cleared cached profile image: $profileImageUrl');
    }
    
    // 2. Clear Flutter's built-in image cache
    imageCache.clear();
    imageCache.clearLiveImages();
    
    // 3. Optional: Clear entire DefaultCacheManager
    await DefaultCacheManager().emptyCache();
    
    debugPrint('✅ Image cache cleared successfully');
  } catch (e) {
    debugPrint('⚠️ Error clearing image cache: $e');
  }
}

  
  Future<void> logout() async {
  try {
    // 1. Clear API token
    final removeTokenFn = _removeTokenOverride ?? ApiService.removeToken;
    await removeTokenFn();
    
    // 2. Clear cached profile image URL specifically
    if (_user?.profileImage != null && !_user!.profileImage!.startsWith('assets/')) {
      final profileImageUrl = 'http://38.242.246.126:3000/${_user!.profileImage}';
      
      // Clear from CachedNetworkImage cache
      await CachedNetworkImage.evictFromCache(profileImageUrl);
      
      // Clear from DefaultCacheManager
      await DefaultCacheManager().removeFile(profileImageUrl);
      
      debugPrint('🗑️ Cleared cached profile image: $profileImageUrl');
    }
    
    // 3. Clear user data
    _user = null;
    
    // 4. Reset profile picture to default
    _profilePicture = 'assets/login/noPicture.png';
    
    // 5. Force a complete image cache clear
    await _clearImageCache();
    
    // 6. Notify listeners
    safeNotify();
    
    debugPrint('✅ Logout complete - all data cleared');
  } catch (e) {
    debugPrint('❌ Logout error: $e');
  }
}


}