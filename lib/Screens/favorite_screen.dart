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
      await recipeProvider.loadUserFavorites();
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
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      return;
    }
    
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from favorites?', style: title),
        content: Text('Remove "${recipe.name}" from your favorites?', style: text),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: text.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: text.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    
    if (shouldRemove == true && mounted) {
      await recipeProvider.toggleFavorite(recipe.id);
      // Refresh the list
      await _loadFavorites();
    }
  }

  Widget _buildEmptyState() {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    
    if (userProvider.userId == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: primaryColor, size: 60),
            SizedBox(height: 20),
            Text('Login to save favorites', style: title.copyWith(fontSize: 20)),
            SizedBox(height: 10),
            Text(
              'Your favorite recipes will appear here',
              style: text.copyWith(color: onSurfaceColor?.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
          Icon(Icons.favorite_border, color: primaryColor, size: 60),
          SizedBox(height: 20),
          Text('No favorite recipes yet', style: title.copyWith(fontSize: 20)),
          SizedBox(height: 10),
          Text(
            'Tap the heart icon on any recipe to add it here',
            style: text.copyWith(color: onSurfaceColor?.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    final surfaceColor = theme.cardColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
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
                            color: primaryColor,
                          ),
                        ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: onSurfaceColor,
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
                    Icon(Icons.person, color: primaryColor, size: 25),
                    const SizedBox(width: 8),
                    Text(
                      userProvider.username,
                      style: text.copyWith(
                        fontSize: 17,
                        color: onSurfaceColor?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 20),

              // Loading indicator
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              else if (favoriteRecipes.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadFavorites,
                    color: primaryColor,
                    backgroundColor: surfaceColor,
                    child: ListView.builder(
                      itemCount: favoriteRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = favoriteRecipes[index];
                        return Dismissible(
                          key: Key('fav_${recipe.id}_$index'),
                          background: Container(
                            color: theme.colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(
                              Icons.delete,
                              color: theme.floatingActionButtonTheme.foregroundColor ?? theme.iconTheme.color,
                              size: 30,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Remove from favorites?', style: title),
                                content: Text('Remove "${recipe.name}" from your favorites?', style: text),
                                backgroundColor: surfaceColor,
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancel', style: text.copyWith(color: onSurfaceColor)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Remove', style: text.copyWith(color: theme.colorScheme.error)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
                            await recipeProvider.toggleFavorite(recipe.id);
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    final surfaceVariantColor = theme.cardColor;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: surfaceVariantColor,
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
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
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
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: primaryColor,
                ),
              ),
            ),

          // Time with Icon
          Positioned(
            left: 105,
            bottom: 15,
            child: Row(
              children: [
                Icon(Icons.access_time, color: primaryColor, size: 12),
                const SizedBox(width: 5),
                Text(
                  recipe.cookingTime,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
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
              icon: Icon(Icons.favorite, color: primaryColor, size: 24),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: onSurfaceColor?.withValues(alpha: 0.7),
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