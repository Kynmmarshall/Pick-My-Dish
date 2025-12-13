import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/services/database_service.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:pick_my_dish/widgets/ingredient_Selector.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedEmotion;
  List<String> selectedIngredients = [];
  List<int> selectedIngredientIds = [];
  List<Recipe> _todayRecipes = [];
  bool _loadingTodayRecipes = false;
  String? selectedTime;
  bool _recipesLoaded = false;

  List<String> emotions = [
    'Happy',
    'Sad',
    'Energetic',
    'Comfort',
    'Healthy',
    'Quick',
    'Light',
  ];
  List<String> timeOptions = ['<= 15mins', '<= 30mins', '<= 1hour', '<= 1hour 30mins', '2+ hours'];
  List<Map<String, dynamic>> allIngredients = [];

  final DatabaseService _databaseService = DatabaseService();
  List<Recipe> personalizedRecipes = [];
  bool showPersonalizedResults = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _generatePersonalisedRecipes() async {
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

   // Show loading
  setState(() {
    _loadingTodayRecipes = true;
  });

  try {
    // Get all recipes from API
    final recipeMaps = await ApiService.getRecipes();
    final allRecipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();
    
    // Apply filters
    final List<Recipe> filteredRecipes = allRecipes.where((recipe) {
      bool matches = true;
      
      // Filter by emotions/moods
      if (selectedEmotion != null) {
        matches = matches && 
            (recipe.moods.contains(selectedEmotion!) ||
             recipe.moods.any((mood) => mood.toLowerCase() == selectedEmotion!.toLowerCase()));
      }
      
      // Filter by ingredients
      if (selectedIngredients.isNotEmpty) {
        // Convert ingredient IDs to names for comparison
        final selectedIngredientNames = selectedIngredientIds
            .map((id) => _getIngredientName(id))
            .where((name) => name != 'Unknown')
            .toList();
        
        if (selectedIngredientNames.isNotEmpty) {
          matches = matches && recipe.ingredients.any((recipeIngredient) {
            return selectedIngredientNames.any((selectedIngredient) {
              return recipeIngredient.toLowerCase().contains(selectedIngredient.toLowerCase());
            });
          });
        }
      }
      
      // Filter by cooking time (simplified)
      if (selectedTime != null) {
        final selectedMinutes = _parseTimeToMinutes(selectedTime!);
        final recipeMinutes = _parseTimeToMinutes(recipe.cookingTime);
        
        // Show recipes with less or equal time
        if (selectedMinutes > 0 && recipeMinutes > 0) {
          matches = matches && recipeMinutes <= selectedMinutes;
        }
      }
      
      return matches;
    }).toList();

    setState(() {
      personalizedRecipes = filteredRecipes;
      showPersonalizedResults = true;
      _loadingTodayRecipes = false;
    });

    if (filteredRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No recipes found with your criteria', style: text),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      _showPersonalizedResults(filteredRecipes);
    }
  } catch (e) {
    setState(() {
      _loadingTodayRecipes = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating recipes: $e', style: text),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  
  // Helper method to parse time strings to minutes
  int _parseTimeToMinutes(String time) {
    // Remove any spaces and convert to lowercase for consistent parsing
    String cleanTime = time.toLowerCase().replaceAll(' ', '');
    
    // Handle "2+ hours" or similar cases
    if (cleanTime.contains('+')) {
      cleanTime = cleanTime.replaceAll('+', '');
    }
    
    // Case 1: Contains "hour" and "min" (e.g., "1hour15mins")
    if (cleanTime.contains('hour') && cleanTime.contains('min')) {
      // Extract hours
      final hourMatch = RegExp(r'(\d+)hour').firstMatch(cleanTime);
      int hours = hourMatch != null ? int.parse(hourMatch.group(1)!) : 0;
      
      // Extract minutes
      final minMatch = RegExp(r'(\d+)min').firstMatch(cleanTime);
      int minutes = minMatch != null ? int.parse(minMatch.group(1)!) : 0;
      
      return (hours * 60) + minutes;
    }
    
    // Case 2: Contains "hour" only (e.g., "1hour", "2hours")
    else if (cleanTime.contains('hour')) {
      final match = RegExp(r'(\d+)hour').firstMatch(cleanTime);
      if (match != null) {
        return int.parse(match.group(1)!) * 60;
      }
    }
    
    // Case 3: Contains "min" only (e.g., "15mins", "30mins")
    else if (cleanTime.contains('min')) {
      final match = RegExp(r'(\d+)min').firstMatch(cleanTime);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    
    // Return 0 if parsing fails
    return 0;
  }

  void _loadTodayRecipes() async {
    if (_loadingTodayRecipes) return;
    
    setState(() => _loadingTodayRecipes = true);
    
    try {
      final recipeMaps = await ApiService.getRecipes();
      final recipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();
      
      // Take only first 3 recipes
      setState(() {
        _todayRecipes = recipes.take(3).toList();
      });
    } catch (e) {
      print('❌ Error loading today recipes: $e');
    } finally {
      setState(() => _loadingTodayRecipes = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodayRecipes();
    _loadIngredients();

    //Load all recipes into RecipeProvider
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //   final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
  //   recipeProvider.loadRecipes();
  // });
  }

// update didChangeDependencies

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Load recipes only once
    if (!_recipesLoaded) {
      _recipesLoaded = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
            recipeProvider.loadRecipes();
          } catch (e) {
            debugPrint('⚠️ Could not load recipes: $e');
          }
        }
      });
    }
  }
  
  void _logout() async {
    // 1. Clear all user data from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    userProvider.logout();
    recipeProvider.logout();    
    // 2. Navigate to login (clear navigation stack)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  void _showPersonalizedResults(List<Recipe> recipes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Personalized Recipes (${recipes.length})',
          style: title.copyWith(fontSize: 24),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: recipes.isEmpty
              ? Text('No recipes found with your criteria', style: text)
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...recipes.map(
                        (recipe) => Column(
                          children: [
                            _buildPersonalizedRecipeCard(recipe),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
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
  
  // Update your _getIngredientName method to handle API data
  String _getIngredientName(int id) {
    if (allIngredients.isEmpty) {
      // Load ingredients if not loaded
      _loadIngredients();
      return 'Loading...';
    }
    
    final ingredient = allIngredients.firstWhere(
      (ing) => ing['id'] == id,
      orElse: () => {'name': 'Unknown'},
    );
    return ingredient['name'];
  }

  // Add a method to load ingredients
  Future<void> _loadIngredients() async {
    try {
      final ingredients = await ApiService.getIngredients();
      setState(() {
        allIngredients = ingredients;
      });
    } catch (e) {
      print('Error loading ingredients: $e');
    }
  }

  Widget _buildPersonalizedRecipeCard(Recipe recipe) {
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
          ),
          child: CachedProfileImage(
            imagePath: recipe.imagePath,
            radius: 8,
            isProfilePicture: false,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${recipe.cookingTime}',
              style: const TextStyle(color: Colors.orange),
            ),
            if (recipe.moods.isNotEmpty)
              Text(
                'Mood: ${recipe.moods.join(', ')}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            if (recipe.category.isNotEmpty)
              Text(
                'Category: ${recipe.category}',
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

  void _showRecipeDetails(Recipe recipe) {
    // Navigate to Recipe Detail Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(initialRecipe: recipe),
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
          padding: const EdgeInsets.only(left: 30, top: 20),
          child: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            
              child: const Icon(
                Icons.menu,
                color: Colors.orange,
                size: iconSize,
              ),
          ),
        ),
        // Add actions (right side buttons)
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 20),
            child: Row(
              children: [
                // Add Recipe Icon
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecipeUploadScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add_circle,
                    color: Colors.orange,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Favorites Icon
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.orange,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 10), // Adjust spacing
              ],
            ),
          ),
        ],
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

                    // Regular Recipe Cards
                    _buildRecipeList(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Ingredients",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              IngredientSelector(
                selectedIds: selectedIngredientIds, // Use the new variable
                onSelectionChanged: (List<int> ids) {
                  setState(() {
                    selectedIngredientIds = ids;
                    // Convert IDs to names for your existing filtering logic
                    selectedIngredients = ids.map((id) => _getIngredientName(id)).toList();
                  });
                },
                hintText: "Search ingredients...",
                allowAddingNew: false,
              ),
            ],
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
              onPressed: _generatePersonalisedRecipes,
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

  Widget buildRecipeCard(Recipe recipe) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    bool isFavorite = recipeProvider.isFavorite(recipe.id);
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
                ),
                child: CachedProfileImage(
                  imagePath: recipe.imagePath,
                  radius: 10,
                  isProfilePicture: false,
                  width: 66,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Recipe Name
            Positioned(
              left: 100,
              top: 13,
              child: Text(
                recipe.name,
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
                    recipe.cookingTime,
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
                  isFavorite ? Icons.favorite : Icons.favorite_border,
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
    
    // Load profile picture when menu opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? imagePath = await ApiService.getProfilePicture(userProvider.userId);
    
    // Check mounted BEFORE updating UI
    if (mounted && imagePath != null && imagePath.isNotEmpty) {
      userProvider.updateProfilePicture(imagePath);
      setState(() {});
    }
    });

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
                      return CachedProfileImage(imagePath: userProvider.profilePicture,radius: 60);
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
                  _logout();
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

  Widget _buildRecipeList() {
  if (_loadingTodayRecipes) {
    return Center(child: CircularProgressIndicator(color: Colors.orange));
  }
  
  if (_todayRecipes.isEmpty) {
    return Center(
      child: Text('No recipes available', style: text),
    );
  }
  
  return Column(
    children: _todayRecipes.map((recipe) {
      return Column(
        children: [
          buildRecipeCard(recipe),
          const SizedBox(height: 20),
        ],
      );
    }).toList(),
  );
}
}
