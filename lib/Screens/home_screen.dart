import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/services/database_service.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedEmotion;
  List<String> selectedIngredients = [];
  String? selectedTime;

  List<String> emotions = [
    'Happy',
    'Sad',
    'Energetic',
    'Comfort',
    'Healthy',
    'Quick',
    'Light',
  ];
  List<String> ingredients = [
    'Eggs',
    'Flour',
    'Chicken',
    'Vegetables',
    'Rice',
    'Pasta',
    'Cheese',
    'Milk',
    'Bread',
    'Avocado',
    'Berries',
    'Yogurt',
    'Bacon',
    'Lettuce',
    'Tomato',
  ];
  List<String> timeOptions = ['15 mins', '30 mins', '1 hour', '2+ hours'];

  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> personalizedRecipes = [];
  bool showPersonalizedResults = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _generateRecipes() async {
    if (selectedIngredients.isEmpty &&
        selectedEmotion == null &&
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one filter', style: text),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final recipes = await _databaseService.getFilteredRecipes(
        ingredients: selectedIngredients,
        mood: selectedEmotion,
        time: selectedTime,
      );

      setState(() {
        personalizedRecipes = recipes;
        showPersonalizedResults = true;
      });

      _showPersonalizedResults(recipes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating recipes: $e', style: text),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPersonalizedResults(List<Map<String, dynamic>> recipes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Personalized Recipes',
          style: title.copyWith(fontSize: 24),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: recipes.isEmpty
              ? Text('No recipes found with your criteria', style: text)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return _buildPersonalizedRecipeCard(recipe);
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: footerClickable),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage(String imagePath) {
  print('🖼️ Loading image: $imagePath');
  
  // ALWAYS use NetworkImage for server paths
  if (imagePath.startsWith('uploads/') || imagePath.contains('profile-')) {
    return NetworkImage('http://38.242.246.126:3000/$imagePath');
  } else {
    // Only use AssetImage for actual local assets
    return AssetImage(imagePath);
  }
}


  Widget _buildPersonalizedRecipeCard(Map<String, dynamic> recipe) {
    List<String> ingredients = List<String>.from(
      json.decode(recipe['ingredients']),
    );
    List<String> moods = List<String>.from(json.decode(recipe['mood']));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(recipe['image']),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          recipe['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${recipe['time']}',
              style: const TextStyle(color: Colors.orange),
            ),
            Text(
              'Mood: ${moods.join(', ')}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.orange,
          size: 16,
        ),
        onTap: () {
          Navigator.pop(context);
          _showRecipeDetails(recipe);
        },
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    // Navigate to Recipe Detail Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 30, top: 30),
          child: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Image.asset(
              'assets/icons/hamburger.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF6B6B6B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Welcome Section
                    Row(children: [Text("Welcome", style: title),
                    SizedBox(width: 10),
                    Expanded(
                    child: FittedBox( // Scales text to fit
                      fit: BoxFit.scaleDown,
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return Text(
                            '${userProvider.username}!', 
                            style: title.copyWith(color: Colors.orange),
                          );
                        },
                      ),
                    ),
                  ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      "What would you like to cook today?",
                      style: title.copyWith(color: Colors.orange),
                    ),
                    const SizedBox(height: 30),

                    // Personalization Section
                    _buildPersonalizationSection(),
                    const SizedBox(height: 30),

                    // Today's Fresh Recipe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Fresh Recipe",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecipesScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Personalized Results (if any)
                    if (showPersonalizedResults &&
                        personalizedRecipes.isNotEmpty) ...[
                      Text("Personalized For You", style: mediumtitle),
                      const SizedBox(height: 10),
                      ...personalizedRecipes
                          .take(3)
                          .map(
                            (recipe) => Column(
                              children: [
                                _buildPersonalizedRecipeCard(recipe),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                      const SizedBox(height: 20),
                    ],

                    // Regular Recipe Cards
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final recipe = {
                          'name': 'Sample Recipe ${index + 1}',
                          'time': '${15 + index * 10} mins',
                          'image': 'assets/recipes/test.png',
                          'isFavorite': false,
                          'category': 'Main Course',
                          'calories': '${300 + index * 100}',
                          'ingredients': [
                            'Ingredient 1',
                            'Ingredient 2',
                            'Ingredient 3'
                          ],
                          'steps': [
                            'Step 1: Prepare ingredients',
                            'Step 2: Cook according to instructions',
                            'Step 3: Serve hot'
                          ],
                          'mood': ['Comfort', 'Healthy']
                        };
                        return Column(
                          children: [
                            buildRecipeCard(recipe),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personalize Your Recipes", style: mediumtitle),
          const SizedBox(height: 15),

          // Emotion Dropdown
          DropdownButtonFormField<String>(
            initialValue: selectedEmotion,
            decoration: InputDecoration(
              labelText: "How are you feeling?",
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
            ),
            dropdownColor: Colors.grey[900],
            items: emotions.map((emotion) {
              return DropdownMenuItem(
                value: emotion,
                child: Text(
                  emotion,
                  style: const TextStyle(color: Colors.orange),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedEmotion = value;
              });
            },
          ),
          const SizedBox(height: 15),

          // Ingredients Selection
          DropdownSearch<String>.multiSelection(
            items: ingredients,
            popupProps: PopupPropsMultiSelection.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search ingredients...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
              ),
              menuProps: MenuProps(
                backgroundColor: const Color.fromARGB(255, 237, 229, 229),
              ),
            ),
            onChanged: (List<String>? selectedItems) {
              setState(() {
                selectedIngredients = selectedItems ?? [];
              });
            },
            selectedItems: selectedIngredients,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Select ingredients",
                hintStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Time Selection
          DropdownButtonFormField<String>(
            initialValue: selectedTime,
            decoration: InputDecoration(
              labelText: "Cooking Time",
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
            ),
            dropdownColor: Colors.grey[900],
            items: timeOptions.map((time) {
              return DropdownMenuItem(
                value: time,
                child: Text(
                  time,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 123, 0),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTime = value;
              });
            },
          ),
          const SizedBox(height: 15),

          // Generate Recipes Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text("Generate Personalized Recipes", style: text),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        _showRecipeDetails(recipe);
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF373737),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Recipe Image
            Positioned(
              left: 20,
              top: 5,
              child: Container(
                width: 66,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(recipe['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Recipe Name
            Positioned(
              left: 100,
              top: 13,
              child: Text(
                recipe['name'],
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Time with Icon
            Positioned(
              right: 15,
              bottom: 10,
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    recipe['time'],
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Favorite Icon - Clickable
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: () {
                  // Toggle favorite logic
                },
                child: Icon(
                  recipe['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                  color: Colors.orange,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/sideMenu/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.orange,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return CircleAvatar(
                            radius: 60,
                            backgroundImage: _getProfileImage(userProvider.profilePicture),
                          );
                          },
                        );
                          },
                        ),
                    const SizedBox(width: 25),
                     Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                   return Text("${userProvider.username}", style: title.copyWith(fontSize: 22));
                }
                )
                ],
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Text("View Profile", style: footerClickable),
                ),

                const SizedBox(height: 50),

                // Menu Items
                _buildMenuItem(Icons.home, "Home", () {
                  Navigator.pop(context);
                }),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.favorite, "Favorites", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.help, "Help", () {
                  Navigator.pop(context);
                }),
                const Spacer(),
                _buildMenuItem(Icons.logout, "Logout", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange, size: 32),
      title: Text(title, style: text.copyWith(fontSize: 22)),
      onTap: () => onTap(),
      contentPadding: EdgeInsets.zero,
    );
  }
}
