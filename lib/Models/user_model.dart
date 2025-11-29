class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.profileImage,
  });

  // Get first name from full name
  String get firstName {
    if (fullName.isEmpty) return username;
    return fullName.split(' ').first;
  }

  // Fixed copyWith method - includes ALL fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // Convert from JSON (from API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      profileImage: json['profile_image_path'] ?? json['profileImage'],
    );
  }

  // Convert to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'profile_image_path': profileImage,
    };
  }

  // For debugging
  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fullName: $fullName, profileImage: $profileImage)';
  }

  // For equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.fullName == fullName &&
        other.profileImage == profileImage;
  }

  @override
  int get hashCode {
    return Object.hash(id, username, email, fullName, profileImage);
  }
}