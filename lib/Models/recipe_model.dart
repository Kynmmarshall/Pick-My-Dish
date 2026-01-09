import 'dart:convert';
class Recipe {
  final int id;
  final String name;
  final String authorName;
  final String category;
  final String cookingTime;
  final String calories;
  final String imagePath;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> moods;
  final int userId;
  final bool isFavorite;
  final bool canEdit; // Added: computed property
  final bool canDelete; // Added: computed property

  Recipe({
    required this.id,
    required this.name,
    required this.authorName,
    required this.category,
    required this.cookingTime,
    required this.calories,
    required this.imagePath,
    required this.ingredients,
    required this.steps,
    required this.moods,
    required this.userId,
    this.isFavorite = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    
    // Helper function
    List<String> parseBackendData(dynamic data) {
      if (data == null) return [];
      if (data is List) return List<String>.from(data);
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) return List<String>.from(parsed);
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    }
    List<String> parseIngredients() {
    final ingredientNames = json['ingredient_names'];
    if (ingredientNames == null || ingredientNames == 'null') return [];
    
    final names = ingredientNames.toString();
    if (names.isEmpty) return [];
    
    // Split by comma and trim whitespace
    return names.split(',').map((name) => name.trim()).toList();
  }
    
    return Recipe(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      authorName: json['author_name'] ?? '',
      category: json['category_name'] ?? json['category'] ?? 'Main Course',
      cookingTime: json['cooking_time'] ?? json['time'] ?? '30 mins',
      calories: json['calories']?.toString() ?? '0',
      imagePath: json['image_path'] ?? json['image'] ?? 'assets/recipes/test.png',
      ingredients: parseIngredients(),
      steps: parseBackendData(json['steps'] ?? json['instructions']),
      moods: parseBackendData(json['emotions'] ?? json['mood']),
      userId: json['user_id'] ?? json['userId'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Check if current user can edit this recipe
  bool canUserEdit(int currentUserId, bool isAdmin) {
    return isAdmin || userId == currentUserId;
  }

  // Check if current user can delete this recipe
  bool canUserDelete(int currentUserId, bool isAdmin) {
    return isAdmin || userId == currentUserId;
  }

  Recipe copyWith({
    int? id,
    String? name,
    String? authorName,
    String? category,
    String? cookingTime,
    String? calories,
    String? imagePath,
    List<String>? ingredients,
    List<String>? steps,
    List<String>? moods,
    int? userId,
    bool? isFavorite,
    bool? canEdit,
    bool? canDelete,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      cookingTime: cookingTime ?? this.cookingTime,
      calories: calories ?? this.calories,
      imagePath: imagePath ?? this.imagePath,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      moods: moods ?? this.moods,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  // check if Recipe is empty
  factory Recipe.empty() => Recipe(
    id: 0,
    name: '',
    userId: 0,
    // Add all other required fields with default values
    category: '',
    cookingTime: '',
    calories: '',
    imagePath: '',
    ingredients: [],
    steps: [],
    moods: [],
    authorName: '',
    isFavorite: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'authorName': authorName,
      'category': category,
      'time': cookingTime,
      'calories': calories,
      'image_path': imagePath,
      'ingredients': ingredients,
      'instructions': steps,
      'mood': moods,
      'userId': userId,
      'isFavorite': isFavorite,
    };
  }

}