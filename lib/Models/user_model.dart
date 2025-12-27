import 'dart:convert';
class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final DateTime joinedDate;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage, 
    this.isAdmin = false,
    DateTime? joinedDate,
  }): joinedDate = joinedDate ?? DateTime.now(); 


  // Fixed copyWith method - includes ALL fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    DateTime? joinedDate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      joinedDate: joinedDate ?? this.joinedDate
    );
  }

  // Convert from JSON (from API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image_path'] ?? json['profileImage'],
      joinedDate: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])  // ← Parse from database
        : null,
      isAdmin: (json['is_admin'] ?? 0) == 1, // Convert int to bool
    );
  }

  // Convert to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image_path': profileImage,
      'created_at': joinedDate.toIso8601String(),
    };
  }

  // For debugging
  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, profileImage: $profileImage, joinedDate: $joinedDate)';
  }

  // For equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.profileImage == profileImage &&
        other.joinedDate == joinedDate;

  }

  @override
  int get hashCode {
    return Object.hash(id, username, email, profileImage, joinedDate);
  }
}