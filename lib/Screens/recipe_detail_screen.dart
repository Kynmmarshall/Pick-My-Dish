import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/recipe_edit_screen.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:provider/provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe initialRecipe;
  final bool showEditOptions; // Add this

  const RecipeDetailScreen({
    super.key, 
    required this.initialRecipe,
    this.showEditOptions = true,
  });
  
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe recipe;
  @override
  void initState() {
    super.initState();
    recipe = widget.initialRecipe;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    final surfaceColor = theme.cardColor;
    final surfaceVariantColor = theme.cardColor;
    final errorColor = theme.colorScheme.error;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.isAdmin ?? false;
    bool isFavorite = recipeProvider.isFavorite(recipe.id);
    
    // Check if user can edit/delete
    final canEdit = recipe.canUserEdit(userProvider.userId, isAdmin);
    final canDelete = recipe.canUserDelete(userProvider.userId, isAdmin);
    
    debugPrint('🔍 Recipe Detail Screen:');
    debugPrint('   Recipe ID: ${recipe.id}');
    debugPrint('   Recipe userId (creator): ${recipe.userId}');
    debugPrint('   Current user ID: ${userProvider.userId}');
    debugPrint('   Is admin: $isAdmin');
    debugPrint('   Can edit: $canEdit');
    debugPrint('   Can delete: $canDelete');

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Recipe Image Header
          SliverAppBar(
            expandedHeight: 300,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedProfileImage(
                imagePath: recipe.imagePath,
                radius: 0,
                isProfilePicture: false,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            backgroundColor: surfaceColor,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
              icon: Icon(
                Icons.arrow_back, 
                color: theme.iconTheme.color ?? onSurfaceColor, 
                size: 30,
                shadows: [
                  Shadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 6,
                    offset: Offset(0,3),
                  ),
                ],
              ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (canEdit || canDelete) // Show menu if user has permissions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.iconTheme.color ?? onSurfaceColor,
                    size: 50,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).shadowColor,
                        blurRadius: 6,
                        offset: Offset(0,3),
                      ),
                    ],
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditScreen(recipe);
                    } else if (value == 'delete') {
                      _deleteRecipe(recipe, userProvider.userId);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> items = [];
                    
                    if (canEdit) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: primaryColor),
                              SizedBox(width: 8),
                              Text('Edit Recipe'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    if (canDelete) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: errorColor),
                              SizedBox(width: 8),
                              Text('Delete Recipe'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return items;
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: primaryColor,
                    size: 30,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).shadowColor,
                        blurRadius: 6,
                        offset: Offset(0,3),
                      ),
                    ],
                  ),
                  onPressed: () {
                    recipeProvider.toggleFavorite(recipe.id);
                    
                    setState(() {
                      recipe = recipe.copyWith(isFavorite: !recipe.isFavorite);
                    });
                  },
                ),
              ),
            ],
          ),

          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: title.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By ${recipe.authorName}',
                              style: TextStyle(
                                color: onSurfaceColor?.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe.category,
                              style: categoryText.copyWith(
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cooking Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: onSurfaceColor, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              recipe.cookingTime,
                              style: TextStyle(
                                color: onSurfaceColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Calories
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: surfaceVariantColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${recipe.calories} KCAL',
                          style: mediumtitle.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Ingredients Section
                  Text("Ingredients", style: mediumtitle),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceVariantColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...recipe.ingredients.map(
                          (ingredient) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.circle, color: primaryColor, size: 8),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    style: text.copyWith(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Cooking Steps Section
                  Text("Cooking Steps", style: mediumtitle),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceVariantColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...recipe.steps.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style:  TextStyle(
                                        color: onSurfaceColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: text.copyWith(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Mood Tags
                  if (recipe.moods.isNotEmpty) ...[
                    Text("Perfect For", style: mediumtitle),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: recipe.moods.map(
                        (mood) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor),
                          ),
                          child: Text(
                            mood,
                            style: text.copyWith(
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Cook Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Happy cooking! 🍳', style: text),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Start Cooking",
                        style: title.copyWith(fontSize: 20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () async {
        await recipeProvider.loadSingleRecipe(recipe.id);
        setState(() {}); // Refresh UI if needed
      },
      backgroundColor: primaryColor,
      child: Icon(
        Icons.refresh,
        color: theme.floatingActionButtonTheme.foregroundColor ?? theme.iconTheme.color,
      ),
    ),
    );
  }

  void _navigateToEditScreen(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: recipe),
      ),
    );
  }

  void _deleteRecipe(Recipe recipe, int userId) async {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recipe', style: title),
        content: Text('Are you sure you want to delete "${recipe.name}"?', style: text),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: text.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: text.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    debugPrint('✅ Dialog result: $confirmed');

    if (!mounted) return;

    if (confirmed == true) {
      debugPrint('🚀 Calling deleteRecipe API...');
      final success = await recipeProvider.deleteRecipe(recipe.id);
      
      debugPrint('📡 API Response: $success');

      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Recipe deleted successfully', style: text),
            backgroundColor: theme.primaryColor,
          ),
        );
        navigator.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete recipe', style: text),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

}