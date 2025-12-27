import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_detail_screen.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  bool _hasLoaded = false;

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
      await recipeProvider.loadUserFavorites(userProvider.userId);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Load favorites after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load once, not on every dependency change
    if (!_hasLoaded) {
      _hasLoaded = true;
      // Load on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavorites();
      });
    }
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(initialRecipe: recipe),
      ),
    );
  }

  Future<void> _removeFavorite(Recipe recipe) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to manage favorites', style: text),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from favorites?', style: title),
        content: Text('Remove "${recipe.name}" from your favorites?', style: text),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: text.copyWith(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: text.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldRemove == true && mounted) {
      await recipeProvider.toggleFavorite(userProvider.userId,recipe.id);
      // Refresh the list
      await _loadFavorites();
    }
  }

  Widget _buildEmptyState() {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (userProvider.userId == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: Colors.orange, size: 60),
            SizedBox(height: 20),
            Text('Login to save favorites', style: title.copyWith(fontSize: 20)),
            SizedBox(height: 10),
            Text(
              'Your favorite recipes will appear here',
              style: text.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('Go Home', style: text),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, color: Colors.orange, size: 60),
          SizedBox(height: 20),
          Text('No favorite recipes yet', style: title.copyWith(fontSize: 20)),
          SizedBox(height: 10),
          Text(
            'Tap the heart icon on any recipe to add it here',
            style: text.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Browse Recipes', style: text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final favoriteRecipes = recipeProvider.favorites;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Favorite Recipes", style: title.copyWith(fontSize: 28)),
                  Row(
                    children: [
                      if (favoriteRecipes.isNotEmpty)
                        Text(
                          '(${favoriteRecipes.length})',
                          style: title.copyWith(
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // User info
              if (userProvider.userId != 0)
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.orange, size: 25),
                    const SizedBox(width: 8),
                    Text(
                      userProvider.username,
                      style: text.copyWith(
                        fontSize: 17,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 20),

              // Loading indicator
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                )
              else if (favoriteRecipes.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadFavorites,
                    color: Colors.orange,
                    backgroundColor: Colors.black,
                    child: ListView.builder(
                      itemCount: favoriteRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = favoriteRecipes[index];
                        return Dismissible(
                          key: Key('fav_${recipe.id}_${index}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Remove from favorites?', style: title),
                                content: Text('Remove "${recipe.name}" from your favorites?', style: text),
                                backgroundColor: Colors.black,
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancel', style: text.copyWith(color: Colors.white)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Remove', style: text.copyWith(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
                            await recipeProvider.toggleFavorite(userProvider.userId,recipe.id);
                          },
                          child: GestureDetector(
                            onTap: () => _showRecipeDetails(recipe),
                            onLongPress: () => _removeFavorite(recipe),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: _buildRecipeCard(recipe),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      height: 100,
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
            left: 8,
            top: 8,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: CachedProfileImage(
                imagePath: recipe.imagePath,
                radius: 8,
                isProfilePicture: false,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Recipe Name
          Positioned(
            left: 105,
            top: 15,
            right: 50,
            child: Text(
              recipe.name,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Category
          if (recipe.category.isNotEmpty)
            Positioned(
              left: 105,
              top: 40,
              child: Text(
                recipe.category,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),

          // Time with Icon
          Positioned(
            left: 105,
            bottom: 15,
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange, size: 12),
                const SizedBox(width: 5),
                Text(
                  recipe.cookingTime,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Favorite Icon with remove option
          Positioned(
            right: 15,
            top: 15,
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.orange, size: 24),
              onPressed: () {
                _removeFavorite(recipe);
              },
              tooltip: 'Remove from favorites',
            ),
          ),

          // Moods if available
          if (recipe.moods.isNotEmpty)
            Positioned(
              left: 105,
              bottom: 35,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 180,
                child: Text(
                  recipe.moods.join(', '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}