import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/theme_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/about_us_screen.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:pick_my_dish/widgets/ingredient_selector.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final bool enableAutoFetch;
  final bool fetchProfilePictureInDrawer;
  final Future<List<Map<String, dynamic>>> Function()? ingredientLoaderOverride;

  const HomeScreen({
    super.key,
    this.enableAutoFetch = true,
    this.fetchProfilePictureInDrawer = true,
    this.ingredientLoaderOverride,
  });

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
    'Energetic',
    'Comfort',
    'Healthy',
    'Quick',
    'Light',
    'None',
  ];
  List<String> timeOptions = ['<= 15mins', '<= 30mins', '<= 1hour', '<= 1hour 30mins', '<=3 hours'];
  List<Map<String, dynamic>> allIngredients = [];

  List<Recipe> personalizedRecipes = [];
  bool showPersonalizedResults = false;
  bool _isLoading = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _generatePersonalisedRecipes() async {
    final messenger = ScaffoldMessenger.of(context);

    if (selectedIngredients.isEmpty &&
        selectedEmotion == null &&
        selectedTime == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Please select at least one filter', style: text),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      return;
    }

    setState(() {
      _loadingTodayRecipes = true;
    });

  try {
    // Get all recipes from API
    final recipeMaps = await ApiService.getRecipes();
    final allRecipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();

    if (!mounted) return;
    
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
      messenger.showSnackBar(
        SnackBar(
          content: Text('No recipes found with your criteria', style: text),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    } else {
      _showPersonalizedResults(filteredRecipes);
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _loadingTodayRecipes = false;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text('Error generating recipes: $e', style: text),
        backgroundColor: Theme.of(context).colorScheme.error,
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

    if (!mounted) return;
    setState(() => _loadingTodayRecipes = true);
    
    try {
      final recipeMaps = await ApiService.getRecipes();
      final recipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();
      
      // Take only first 5 recipes
      if (!mounted) return;
      setState(() {
        _todayRecipes = recipes.take(5).toList();
      });
    } catch (e) {
        debugPrint('❌ Error loading today recipes: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingTodayRecipes = false);
      }
    }
  }

  Future<void> _loadFavorites() async {
    if (_isLoading || !mounted) return;
    
    setState(() => _isLoading = true);
    
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.userId == 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Add delay to avoid build conflicts
      await Future.delayed(const Duration(milliseconds: 10));
      await recipeProvider.loadUserFavorites();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @visibleForTesting
  void setTodayRecipesForTest(List<Recipe> recipes) {
    setState(() {
      _todayRecipes = List<Recipe>.from(recipes);
    });
  }

  @visibleForTesting
  void setLoadingStateForTest(bool value) {
    setState(() {
      _loadingTodayRecipes = value;
    });
  }

  @visibleForTesting
  void showPersonalizedDialogForTest(List<Recipe> recipes) {
    _showPersonalizedResults(recipes);
  }

  @visibleForTesting
  void setAllIngredientsForTest(List<Map<String, dynamic>> ingredients) {
    setState(() {
      allIngredients = List<Map<String, dynamic>>.from(ingredients);
    });
  }

  @visibleForTesting
  void setFiltersForTest({
    String? emotion,
    List<int>? ingredientIds,
    String? time,
  }) {
    setState(() {
      if (emotion != null) {
        selectedEmotion = emotion;
      }
      if (ingredientIds != null) {
        selectedIngredientIds = List<int>.from(ingredientIds);
        selectedIngredients = ingredientIds.map(_getIngredientName).toList();
      }
      if (time != null) {
        selectedTime = time;
      }
    });
  }
  
  @override
  void initState() {
    super.initState();
    _loadIngredients();
    if (widget.enableAutoFetch) {
      _loadTodayRecipes();
      _loadFavorites();
    }
    
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
    if (!_recipesLoaded && widget.enableAutoFetch) {
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      final loader = widget.ingredientLoaderOverride ?? ApiService.getIngredients;
      final ingredients = await loader();
      if (!mounted) return;
      setState(() {
        allIngredients = ingredients;
      });
    } catch (e) {
      debugPrint('Error loading ingredients: $e');
    }
  }

  Widget _buildPersonalizedRecipeCard(Recipe recipe) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyLarge?.color ?? theme.textTheme.bodyMedium?.color;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          style: TextStyle(
            color: onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${recipe.cookingTime}',
              style: TextStyle(color: primaryColor),
            ),
            if (recipe.moods.isNotEmpty)
              Text(
                'Mood: ${recipe.moods.join(', ')}',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            if (recipe.category.isNotEmpty)
              Text(
                'Category: ${recipe.category}',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: primaryColor,
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyLarge?.color ?? theme.textTheme.bodyMedium?.color;
    final titleColor = theme.textTheme.titleLarge?.color ?? onSurfaceColor;
    final surfaceColor = theme.scaffoldBackgroundColor;
    final surfaceVariantColor = theme.cardColor;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSideMenu(),
       appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 30, top: 20),
          child: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            
              child: Icon(
                Icons.menu,
                color: primaryColor,
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
                  child: Icon(
                    Icons.add_circle,
                    color: primaryColor,
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
                  child: Icon(
                    Icons.favorite,
                    color: primaryColor,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [surfaceColor, surfaceVariantColor],
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
                            style: title.copyWith(color: primaryColor),
                          );
                        },
                      ),
                    ),
                  ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      "What would you like to cook today?",
                      style: title.copyWith(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 30),

                    // Personalization Section
                    _buildPersonalizationSection(),
                    const SizedBox(height: 30),

                    // Today's Fresh Recipe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Fresh Recipe",
                          style: TextStyle(
                            color: titleColor,
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
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: primaryColor,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _loadingTodayRecipes ? null : (){
        _loadTodayRecipes();
        _loadIngredients();
      _loadFavorites();
        },
        backgroundColor: primaryColor,
        child: Icon(
          Icons.refresh,
          color: theme.floatingActionButtonTheme.foregroundColor ?? theme.iconTheme.color,
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
              labelStyle: placeHolder,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
            ),
            dropdownColor: theme.cardColor,
            items: emotions.map((emotion) {
              return DropdownMenuItem(
                value: emotion,
                child: Text(
                  emotion,
                  style: TextStyle(color: primaryColor),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value == 'None') {
                  selectedEmotion = null;
                } else {
                selectedEmotion = value;}
              });
            },
          ),
          const SizedBox(height: 15),

          // Ingredients Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Ingredients",
                style: text
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
                hintText: 'Search ingredients...',
                hintStyle: placeHolder,
                textStyle: text.copyWith(
                  color: theme.textTheme.bodyLarge?.color ??
                      theme.textTheme.bodyMedium?.color,
                ),
                allowAddingNew: false,
                ingredientLoader: widget.ingredientLoaderOverride,
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Time Selection
          DropdownButtonFormField<String>(
            initialValue: selectedTime,
            decoration: InputDecoration(
              labelText: "Cooking Time",
              labelStyle: placeHolder,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
            ),
            dropdownColor: theme.cardColor,
            items: timeOptions.map((time) {
              return DropdownMenuItem(
                value: time,
                child: Text(
                  time,
                  style: TextStyle(
                    color: primaryColor,
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
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text("Generate Personalized Recipes", style: text2),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecipeCard(Recipe recipe) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.textTheme.bodyLarge?.color ?? theme.textTheme.bodyMedium?.color;
    final recipeProvider = Provider.of<RecipeProvider>(context);
    bool isFavorite = recipeProvider.isFavorite(recipe.id);
    return GestureDetector(
      onTap: () {
        _showRecipeDetails(recipe);
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.25),
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
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
              ),
            ),

            // Time with Icon
            Positioned(
              right: 15,
              bottom: 10,
              child: Row(
                children: [
                  Icon(Icons.access_time, color: onSurfaceColor, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    recipe.cookingTime,
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
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
                  color: theme.primaryColor,
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
    final theme = Theme.of(context);
    
    // Load profile picture when menu opens
    if (widget.fetchProfilePictureInDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        String? imagePath = await ApiService.getProfilePicture();
        
        // Check mounted BEFORE updating UI
        if (mounted && imagePath != null && imagePath.isNotEmpty) {
          userProvider.updateProfilePicture(imagePath);
          setState(() {});
        }
      });
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
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
          Container(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6)),

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
                      child: Icon(
                        Icons.arrow_back,
                        color: theme.primaryColor,
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
                   return Text(userProvider.username, style: title.copyWith(fontSize: 22));
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
              _buildMenuItem(Icons.restaurant_menu, "My Recipes", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipesScreen(showUserRecipesOnly: true),
                  ),
                );
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
                _buildMenuItem(Icons.help, "About Us", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                // Theme Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: theme.primaryColor,
                        size: 32,
                      ),
                      title: Text(
                        'Theme',
                        style: text.copyWith(fontSize: 22),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeThumbColor: theme.primaryColor,
                        inactiveThumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
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
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color ?? theme.primaryColor, size: 32),
      title: Text(title, style: text.copyWith(fontSize: 22)),
      onTap: () => onTap(),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRecipeList() {
  if (_loadingTodayRecipes) {
    return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
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
