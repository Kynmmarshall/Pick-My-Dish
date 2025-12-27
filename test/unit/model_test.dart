import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Models/user_model.dart';

void main() {
group('Recipe Model Tests', () {
test('Recipe constructor works correctly', () {
final recipe = Recipe(
id: 1,
name: 'Test Recipe',
authorName: 'Test Author',
category: 'Dinner',
cookingTime: '30 mins',
calories: '300',
imagePath: 'test.jpg',
ingredients: ['ing1', 'ing2'],
steps: ['step1', 'step2'],
moods: ['Happy', 'Energetic'],
userId: 123,
isFavorite: true,
canEdit: true,
canDelete: false,
);

  expect(recipe.id, 1);
  expect(recipe.name, 'Test Recipe');
  expect(recipe.authorName, 'Test Author');
  expect(recipe.category, 'Dinner');
  expect(recipe.cookingTime, '30 mins');
  expect(recipe.calories, '300');
  expect(recipe.imagePath, 'test.jpg');
  expect(recipe.ingredients, ['ing1', 'ing2']);
  expect(recipe.steps, ['step1', 'step2']);
  expect(recipe.moods, ['Happy', 'Energetic']);
  expect(recipe.userId, 123);
  expect(recipe.isFavorite, true);
  expect(recipe.canEdit, true);
  expect(recipe.canDelete, false);
});

test('Recipe.fromJson parses all fields correctly', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    'author_name': 'Test Author',
    'category_name': 'Dinner',
    'cooking_time': '30 mins',
    'calories': '300',
    'image_path': 'test.jpg',
    'ingredient_names': 'ing1,ing2,ing3',
    'steps': ['step1', 'step2', 'step3'],
    'emotions': ['Happy', 'Comfort'],
    'user_id': 123,
    'isFavorite': true,
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.id, 1);
  expect(recipe.name, 'Test Recipe');
  expect(recipe.authorName, 'Test Author');
  expect(recipe.category, 'Dinner');
  expect(recipe.cookingTime, '30 mins');
  expect(recipe.calories, '300');
  expect(recipe.imagePath, 'test.jpg');
  expect(recipe.ingredients, ['ing1', 'ing2', 'ing3']);
  expect(recipe.steps, ['step1', 'step2', 'step3']);
  expect(recipe.moods, ['Happy', 'Comfort']);
  expect(recipe.userId, 123);
  expect(recipe.isFavorite, true);
});

test('Recipe.fromJson handles missing fields', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    // Missing other fields
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.id, 1);
  expect(recipe.name, 'Test Recipe');
  expect(recipe.authorName, '');
  expect(recipe.category, 'Main Course'); // Default value
  expect(recipe.cookingTime, '30 mins'); // Default value
  expect(recipe.calories, '0');
  expect(recipe.imagePath, 'assets/recipes/test.png'); // Default value
  expect(recipe.ingredients, isEmpty);
  expect(recipe.steps, isEmpty);
  expect(recipe.moods, isEmpty);
  expect(recipe.userId, 0);
  expect(recipe.isFavorite, false);
});

test('Recipe.fromJson handles null ingredient_names', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    'ingredient_names': null,
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.ingredients, isEmpty);
});

test('Recipe.fromJson handles empty ingredient_names string', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    'ingredient_names': '',
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.ingredients, isEmpty);
});

test('Recipe.fromJson handles string steps and moods', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    'steps': '["step1", "step2"]', // JSON string
    'emotions': '["Happy", "Sad"]', // JSON string
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.steps, ['step1', 'step2']);
  expect(recipe.moods, ['Happy', 'Sad']);
});

test('Recipe.fromJson handles invalid JSON strings', () {
  final json = {
    'id': 1,
    'name': 'Test Recipe',
    'steps': 'invalid json',
    'emotions': 'also invalid',
  };

  final recipe = Recipe.fromJson(json);

  expect(recipe.steps, isEmpty);
  expect(recipe.moods, isEmpty);
});

test('canUserEdit returns correct values', () {
  final recipe = Recipe(
    id: 1,
    name: 'Test Recipe',
    authorName: 'Author',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'test.jpg',
    ingredients: ['ing1'],
    steps: ['step1'],
    moods: ['Happy'],
    userId: 123, // Recipe owner ID
    isFavorite: false,
  );

  // Owner can edit
  expect(recipe.canUserEdit(123, false), true);
  
  // Non-owner cannot edit unless admin
  expect(recipe.canUserEdit(456, false), false);
  
  // Admin can edit any recipe
  expect(recipe.canUserEdit(456, true), true);
});

test('canUserDelete returns correct values', () {
  final recipe = Recipe(
    id: 1,
    name: 'Test Recipe',
    authorName: 'Author',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'test.jpg',
    ingredients: ['ing1'],
    steps: ['step1'],
    moods: ['Happy'],
    userId: 123, // Recipe owner ID
    isFavorite: false,
  );

  // Owner can delete
  expect(recipe.canUserDelete(123, false), true);
  
  // Non-owner cannot delete unless admin
  expect(recipe.canUserDelete(456, false), false);
  
  // Admin can delete any recipe
  expect(recipe.canUserDelete(456, true), true);
});

test('copyWith creates modified copy', () {
  final original = Recipe(
    id: 1,
    name: 'Original',
    authorName: 'Author',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'original.jpg',
    ingredients: ['ing1'],
    steps: ['step1'],
    moods: ['Happy'],
    userId: 123,
    isFavorite: false,
    canEdit: true,
    canDelete: true,
  );

  final copied = original.copyWith(
    name: 'Modified',
    isFavorite: true,
    canEdit: false,
  );

  // Modified fields
  expect(copied.name, 'Modified');
  expect(copied.isFavorite, true);
  expect(copied.canEdit, false);
  
  // Unmodified fields should stay the same
  expect(copied.id, 1);
  expect(copied.authorName, 'Author');
  expect(copied.category, 'Dinner');
  expect(copied.cookingTime, '30 mins');
  expect(copied.calories, '300');
  expect(copied.imagePath, 'original.jpg');
  expect(copied.ingredients, ['ing1']);
  expect(copied.steps, ['step1']);
  expect(copied.moods, ['Happy']);
  expect(copied.userId, 123);
  expect(copied.canDelete, true);
});

test('toJson creates correct JSON', () {
  final recipe = Recipe(
    id: 1,
    name: 'Test Recipe',
    authorName: 'Test Author',
    category: 'Dinner',
    cookingTime: '30 mins',
    calories: '300',
    imagePath: 'test.jpg',
    ingredients: ['ing1', 'ing2'],
    steps: ['step1', 'step2'],
    moods: ['Happy', 'Energetic'],
    userId: 123,
    isFavorite: true,
  );

  final json = recipe.toJson();

  expect(json['id'], 1);
  expect(json['name'], 'Test Recipe');
  expect(json['authorName'], 'Test Author');
  expect(json['category'], 'Dinner');
  expect(json['time'], '30 mins');
  expect(json['calories'], '300');
  expect(json['image_path'], 'test.jpg');
  expect(json['ingredients'], ['ing1', 'ing2']);
  expect(json['instructions'], ['step1', 'step2']);
  expect(json['mood'], ['Happy', 'Energetic']);
  expect(json['userId'], 123);
  expect(json['isFavorite'], true);
});
});

group('User Model Tests', () {
test('User constructor works correctly', () {
final joinedDate = DateTime(2023, 1, 1);
final user = User(
id: '123',
username: 'testuser',
email: 'test@example.com',
profileImage: 'profile.jpg',
joinedDate: joinedDate,
isAdmin: true,
);

  expect(user.id, '123');
  expect(user.username, 'testuser');
  expect(user.email, 'test@example.com');
  expect(user.profileImage, 'profile.jpg');
  expect(user.joinedDate, joinedDate);
  expect(user.isAdmin, true);
});

test('User constructor uses default joinedDate', () {
  final beforeCreation = DateTime.now();
  final user = User(
    id: '123',
    username: 'testuser',
    email: 'test@example.com',
  );
  final afterCreation = DateTime.now();

  expect(user.joinedDate.isAfter(beforeCreation) || 
         user.joinedDate.isAtSameMomentAs(beforeCreation), true);
  expect(user.joinedDate.isBefore(afterCreation) || 
         user.joinedDate.isAtSameMomentAs(afterCreation), true);
});

test('User.fromJson parses all fields correctly', () {
  final json = {
    'id': '123',
    'username': 'testuser',
    'email': 'test@example.com',
    'profile_image_path': 'profile.jpg',
    'created_at': '2023-01-01T12:00:00.000Z',
    'is_admin': 1,
  };

  final user = User.fromJson(json);

  expect(user.id, '123');
  expect(user.username, 'testuser');
  expect(user.email, 'test@example.com');
  expect(user.profileImage, 'profile.jpg');
  expect(user.joinedDate, DateTime.parse('2023-01-01T12:00:00.000Z'));
  expect(user.isAdmin, true);
});

test('User.fromJson handles missing fields', () {
  final json = {
    'id': '123',
    'username': 'testuser',
    // Missing other fields
  };

  final user = User.fromJson(json);

  expect(user.id, '123');
  expect(user.username, 'testuser');
  expect(user.email, '');
  expect(user.profileImage, isNull);
  expect(user.isAdmin, false);
});

test('User.fromJson handles null created_at', () {
  final json = {
    'id': '123',
    'username': 'testuser',
    'email': 'test@example.com',
    'created_at': null,
  };

  final user = User.fromJson(json);

  expect(user.joinedDate, isNotNull);
});

test('User.fromJson handles is_admin as 0', () {
  final json = {
    'id': '123',
    'username': 'testuser',
    'email': 'test@example.com',
    'is_admin': 0,
  };

  final user = User.fromJson(json);

  expect(user.isAdmin, false);
});

test('copyWith creates modified copy', () {
  final originalDate = DateTime(2023, 1, 1);
  final original = User(
    id: '123',
    username: 'original',
    email: 'original@example.com',
    profileImage: 'original.jpg',
    joinedDate: originalDate,
    isAdmin: false,
  );

  final newDate = DateTime(2024, 1, 1);
  final copied = original.copyWith(
    username: 'modified',
    email: 'modified@example.com',
    profileImage: 'modified.jpg',
    joinedDate: newDate,
  );

  // Modified fields
  expect(copied.username, 'modified');
  expect(copied.email, 'modified@example.com');
  expect(copied.profileImage, 'modified.jpg');
  expect(copied.joinedDate, newDate);
  
  // Unmodified fields should stay the same
  expect(copied.id, '123');
  expect(copied.isAdmin, false);
});

test('copyWith handles partial updates', () {
  final original = User(
    id: '123',
    username: 'original',
    email: 'original@example.com',
    profileImage: 'original.jpg',
    joinedDate: DateTime(2023, 1, 1),
    isAdmin: false,
  );

  final copied = original.copyWith(
    username: 'modified',
  );

  expect(copied.username, 'modified');
  expect(copied.email, 'original@example.com'); // Unchanged
  expect(copied.profileImage, 'original.jpg'); // Unchanged
});

test('toJson creates correct JSON', () {
  final date = DateTime(2023, 1, 1, 12, 0, 0);
  final user = User(
    id: '123',
    username: 'testuser',
    email: 'test@example.com',
    profileImage: 'profile.jpg',
    joinedDate: date,
    isAdmin: true,
  );

  final json = user.toJson();

  expect(json['id'], '123');
  expect(json['username'], 'testuser');
  expect(json['email'], 'test@example.com');
  expect(json['profile_image_path'], 'profile.jpg');
  expect(json['created_at'], '2023-01-01T12:00:00.000');
});

test('toString returns formatted string', () {
  final user = User(
    id: '123',
    username: 'testuser',
    email: 'test@example.com',
    profileImage: 'profile.jpg',
    joinedDate: DateTime(2023, 1, 1),
    isAdmin: true,
  );

  final str = user.toString();
  
  expect(str.contains('id: 123'), true);
  expect(str.contains('username: testuser'), true);
  expect(str.contains('email: test@example.com'), true);
  expect(str.contains('profileImage: profile.jpg'), true);
});

test('equality operator works correctly', () {
  final date = DateTime(2023, 1, 1);
  final user1 = User(
    id: '123',
    username: 'testuser',
    email: 'test@example.com',
    profileImage: 'profile.jpg',
    joinedDate: date,
    isAdmin: true,
  );

  final user2 = User(
    id: '123',
    username: 'testuser',
    email: 'test@example.com',
    profileImage: 'profile.jpg',
    joinedDate: date,
    isAdmin: true,
  );

  final user3 = User(
    id: '456', // Different ID
    username: 'testuser',
    email: 'test@example.com',
    profileImage: 'profile.jpg',
    joinedDate: date,
    isAdmin: true,
  );

  expect(user1 == user2, true);
  expect(user1 == user3, false);
  expect(user1.hashCode == user2.hashCode, true);
});
});
}