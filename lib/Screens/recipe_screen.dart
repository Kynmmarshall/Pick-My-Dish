import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart'; // Add this
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/recipe_edit_screen.dart';
import 'package:pick_my_dish/Screens/recipe_upload_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:provider/provider.dart'; // Add this

class RecipesScreen extends StatefulWidget {
  final bool showUserRecipesOnly; // Add this parameter
  
  const RecipesScreen({
    super.key,
    this.showUserRecipesOnly = false,
  });

  @override
  State<RecipesScreen> createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> allRecipes = [];
  bool isLoading = true;
  bool hasError = false;
  String header = "All Recipes";

  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipeMaps = await ApiService.getRecipes(); // This returns List<Map>
      var recipes = recipeMaps.map((map) => Recipe.fromJson(map)).toList();
      
      // Filter user's recipes if needed
      if (widget.showUserRecipesOnly) {
        header = "My Recipes";
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        recipes = recipes.where((recipe) => recipe.userId == userProvider.userId).toList();
      }

      setState(() {
        allRecipes = recipes;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      print('❌ Error loading recipes: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
  }

  List<Recipe> get filteredRecipes {
    if (searchQuery.isEmpty) return allRecipes;
    return allRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(searchQuery) ||
          recipe.category.toLowerCase().contains(searchQuery);
    }).toList();
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(initialRecipe: recipe),
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange), iconSize: iconSize,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 20),
            child: Row(
              children: [
                // Add Recipe Button
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
                    Icons.favorite_outlined,
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
        decoration: BoxDecoration(color: Colors.black),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // Header with title and back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(header, style: title.copyWith(fontSize: 28)),
                ],
              ),
              SizedBox(height: 20),

              // Search Bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 15),
                    Icon(Icons.search, color: Colors.white70),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: text,
                        decoration: InputDecoration(
                          hintText: "Search recipes...",
                          hintStyle: placeHolder,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Loading/Error/Recipes
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRecipes,
        backgroundColor: Colors.orange,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.orange));
    }
    
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 20),
            Text('Failed to load recipes', style: text),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadRecipes,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (filteredRecipes.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty ? 'No recipes available' : 'No recipes found',
          style: title,
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredRecipes.length,
      itemBuilder: (context, index) {
        return buildRecipeCard(filteredRecipes[index]);
      },
    );
  }

  Widget buildRecipeCard(Recipe recipe) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    bool isFavorite = recipeProvider.isFavorite(recipe.id);
    final isAdmin = userProvider.user?.isAdmin ?? false;
    final canEdit = recipe.canUserEdit(userProvider.userId, isAdmin);
    
    return GestureDetector(
      onTap: () => _showRecipeDetails(recipe),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Recipe Image from VPS database
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 99,
                height: 87,
                child: CachedProfileImage(
                  imagePath: recipe.imagePath, // Use Recipe property
                  radius: 0,
                  isProfilePicture: false,
                  width: 99,
                  height: 87,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Favorite Icon
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  _toggleFavorite(recipe);
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border, // Use Recipe property
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Category
                  Text(
                    recipe.category, // Use Recipe property
                    style: categoryText.copyWith(
                      color: Color(0xFF2958FF),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 5),

                  // Recipe Name
                  Text(
                    recipe.name, // Use Recipe property
                    style: text.copyWith(fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),

                  // Time with Icon
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        recipe.cookingTime, // Use Recipe property
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(Recipe recipe) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    recipeProvider.toggleFavorite(userProvider.userId, recipe.id);
    
    // Update local state if needed
    setState(() {
      final index = allRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        allRecipes[index] = allRecipes[index].copyWith(
          isFavorite: !allRecipes[index].isFavorite
        );
      }
    });
  }
  
  void _editRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: recipe),
      ),
    );
  }

}