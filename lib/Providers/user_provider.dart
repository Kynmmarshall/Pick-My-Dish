import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/user_model.dart';

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

  /// Returns the username of the current user, or a default 'User' string
  /// when no user is available.
  String get username => _user?.username ?? 'User';  
  int get userId => _userId;  


  /// Returns the first name of the current user extracted from fullName,
  /// or falls back to username, or 'User' if no user is available.
  String get firstName => _user?.firstName ?? username;

  /// Returns the full name of the current user, or empty string if not available.
  String get fullName => _user?.fullName ?? '';

  /// Returns the email of the current user, or empty string if not available.
  String get email => _user?.email ?? '';

  /// Returns the profile image URL of the current user, or null if not available.
  String? get profileImage => _user?.profileImage;

  /// Indicates whether a user is currently logged in.
  bool get isLoggedIn => _user != null;

  /// Set (or replace) the current user and notify listeners.
  ///
  /// Call this after a successful login or when user data is fetched.
  void setUser(User user) {
    _user = user;
    notifyListeners(); // Notify widgets that depend on user data.
  }

  /// Create and set user from JSON data (typically from API response).
  ///
  /// Convenience method that uses [User.fromJson] constructor.
  void setUserFromJson(Map<String, dynamic> userData) {
    _user = User.fromJson(userData);
    notifyListeners();
  }

  /// Update only the username for the current user and notify listeners.
  ///
  /// If there is no current user, this method does nothing.
  void updateUsername(String newUsername, int userId) {
    if (_user != null) {
      // Use the model's copyWith to preserve other fields.
      _user = _user!.copyWith(username: newUsername);
      notifyListeners();
    }
  }

  /// Update the user's full name and notify listeners.
  ///
  /// If there is no current user, this method does nothing.
  void updateFullName(String newFullName) {
    if (_user != null) {
      _user = _user!.copyWith(fullName: newFullName);
      notifyListeners();
    }
  }

  /// Update the user's profile image and notify listeners.
  ///
  /// If there is no current user, this method does nothing.
  void updateProfilePicture(String ImagePath) {
    if (_user != null) {
      _user = _user!.copyWith(profileImage: ImagePath);
      notifyListeners();
    }
  }


  /// Clear the current user (log out) and notify listeners.
  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void setUserId(int userId) {
    _userId = userId;
    notifyListeners();
  }
  /// Debug method to print current user state
  void printUserState() {
    if (_user == null) {
      debugPrint('UserProvider: No user logged in');
    } else {
      debugPrint('UserProvider: Current user - ${_user!.toString()}');
      debugPrint('UserProvider: First name - $firstName');
    }
  }
}