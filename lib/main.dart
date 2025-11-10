import 'package:flutter/material.dart';

void main() {
  runApp(const PickMyDishApp());
}

/// Main app widget that sets up the theme and initial screen
class PickMyDishApp extends StatelessWidget {
  const PickMyDishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PickMyDish',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// DATA MODELS
class Recipe {
  final int id;
  final String name;
  final List<String> ingredients;
  final String instructions;
  final int prepTime;
  final List<String> moods;
  final String difficulty;
  final String imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.moods,
    required this.difficulty,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients.join(','),
      'instructions': instructions,
      'prepTime': prepTime,
      'moods': moods.join(','),
      'difficulty': difficulty,
      'imageUrl': imageUrl,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      ingredients: (map['ingredients'] as String).split(','),
      instructions: map['instructions'],
      prepTime: map['prepTime'],
      moods: (map['moods'] as String).split(','),
      difficulty: map['difficulty'],
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class MoodTimeFilter {
  final List<String> selectedMoods;
  final int? maxPrepTime;
  final List<String> availableIngredients;

  MoodTimeFilter({
    this.selectedMoods = const [],
    this.maxPrepTime,
    this.availableIngredients = const [],
  });

  MoodTimeFilter copyWith({
    List<String>? selectedMoods,
    int? maxPrepTime,
    List<String>? availableIngredients,
  }) {
    return MoodTimeFilter(
      selectedMoods: selectedMoods ?? this.selectedMoods,
      maxPrepTime: maxPrepTime ?? this.maxPrepTime,
      availableIngredients: availableIngredients ?? this.availableIngredients,
    );
  }

  bool get hasFilters {
    return selectedMoods.isNotEmpty || 
           maxPrepTime != null || 
           availableIngredients.isNotEmpty;
  }
}

/// SIMPLE IN-MEMORY DATABASE (No SQLite dependency)
class RecipeDatabase {
  static final RecipeDatabase _instance = RecipeDatabase._internal();
  factory RecipeDatabase() => _instance;
  RecipeDatabase._internal() {
    _initializeSampleData();
  }

  final List<Recipe> _recipes = [];

  void _initializeSampleData() {
    _recipes.addAll([
      Recipe(
        id: 1,
        name: 'Quick Veggie Pasta',
        ingredients: ['pasta', 'tomato', 'garlic', 'olive oil', 'basil'],
        instructions: '1. Cook pasta according to package instructions.\n2. Sauté garlic in olive oil until fragrant.\n3. Add chopped tomatoes and cook for 5 minutes.\n4. Mix sauce with pasta and garnish with fresh basil.',
        prepTime: 15,
        moods: ['quick', 'comfort', 'easy'],
        difficulty: 'Easy',
      ),
      Recipe(
        id: 2,
        name: 'Hearty Vegetable Soup',
        ingredients: ['carrot', 'potato', 'onion', 'celery', 'vegetable broth'],
        instructions: '1. Chop all vegetables into bite-sized pieces.\n2. Sauté onions and celery until soft.\n3. Add carrots, potatoes, and broth.\n4. Simmer for 30 minutes until vegetables are tender.',
        prepTime: 40,
        moods: ['comfort', 'healthy', 'warm'],
        difficulty: 'Medium',
      ),
      Recipe(
        id: 3,
        name: '5-Minute Berry Smoothie',
        ingredients: ['banana', 'mixed berries', 'yogurt', 'honey', 'milk'],
        instructions: '1. Combine all ingredients in a blender.\n2. Blend until smooth and creamy.\n3. Adjust sweetness with honey if needed.',
        prepTime: 5,
        moods: ['quick', 'healthy', 'refreshing'],
        difficulty: 'Easy',
      ),
      Recipe(
        id: 4,
        name: 'Garlic Butter Shrimp',
        ingredients: ['shrimp', 'garlic', 'butter', 'lemon', 'parsley'],
        instructions: '1. Sauté garlic in butter until golden.\n2. Add shrimp and cook until pink.\n3. Squeeze lemon juice and garnish with parsley.',
        prepTime: 10,
        moods: ['quick', 'impressive', 'easy'],
        difficulty: 'Easy',
      ),
      Recipe(
        id: 5,
        name: 'Classic Beef Stew',
        ingredients: ['beef', 'potato', 'carrot', 'onion', 'beef broth'],
        instructions: '1. Brown beef cubes in a pot.\n2. Add chopped vegetables and broth.\n3. Simmer for 2 hours until meat is tender.',
        prepTime: 120,
        moods: ['comfort', 'hearty', 'warm'],
        difficulty: 'Medium',
      ),
    ]);
  }

  Future<List<Recipe>> getAllRecipes() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    return List.from(_recipes);
  }

  Future<List<Recipe>> getRecipesByIngredients(List<String> ingredients) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) {
      return ingredients.any((ingredient) => 
        recipe.ingredients.any((recipeIngredient) => 
          recipeIngredient.toLowerCase().contains(ingredient.toLowerCase())
        )
      );
    }).toList();
  }
}

/// FILTERING LOGIC
class RecipeFilter {
  List<Recipe> filterRecipes({
    required List<Recipe> recipes,
    List<String> moods = const [],
    int? maxPrepTime,
    List<String> availableIngredients = const [],
  }) {
    List<Recipe> filtered = List.from(recipes);

    if (moods.isNotEmpty) {
      filtered = filterByMood(filtered, moods);
    }

    if (maxPrepTime != null) {
      filtered = filterByMaxTime(filtered, maxPrepTime);
    }

    if (availableIngredients.isNotEmpty) {
      filtered = filterByIngredients(filtered, availableIngredients);
    }

    return filtered;
  }

  List<Recipe> filterByMood(List<Recipe> recipes, List<String> moods) {
    return recipes.where((recipe) {
      return moods.any((mood) => recipe.moods.contains(mood));
    }).toList();
  }

  List<Recipe> filterByMaxTime(List<Recipe> recipes, int maxPrepTime) {
    return recipes.where((recipe) => recipe.prepTime <= maxPrepTime).toList();
  }

  List<Recipe> filterByIngredients(List<Recipe> recipes, List<String> ingredients) {
    return recipes.where((recipe) {
      return ingredients.any((ingredient) => 
        recipe.ingredients.any((recipeIngredient) => 
          recipeIngredient.toLowerCase().contains(ingredient.toLowerCase())
        )
      );
    }).toList();
  }
}

/// SERVICE LAYER
class RecipeService {
  final RecipeDatabase _repository = RecipeDatabase();
  final RecipeFilter _filter = RecipeFilter();

  Future<List<Recipe>> getFilteredRecipes({
    List<String> moods = const [],
    int? maxPrepTime,
    List<String> availableIngredients = const [],
  }) async {
    final allRecipes = await _repository.getAllRecipes();
    return _filter.filterRecipes(
      recipes: allRecipes,
      moods: moods,
      maxPrepTime: maxPrepTime,
      availableIngredients: availableIngredients,
    );
  }

  Future<List<Recipe>> getAllRecipes() async {
    return await _repository.getAllRecipes();
  }
}

/// UI WIDGETS

/// Splash Screen with entrance animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  void _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 70,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withAlpha(200),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'PickMyDish',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              AnimatedOpacity(
                opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  'Your Personal Recipe Companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withAlpha(200),
                ),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main Home Screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const ExploreScreen(), // Updated with recipe discovery
    const ProfileScreen(),
  ];

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Pick-My-Dish'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _navigateToSettings(context),
                ),
              ],
            )
          : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Home Content Screen
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  void _navigateToRecipeSearch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe Search - Coming Soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorites - Coming Soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withAlpha(25),
                  Theme.of(context).colorScheme.primary.withAlpha(12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Pick-My-Dish! 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Struggling to decide what to cook? Let us help you discover amazing recipes based on what you have and what you love.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context: context,
                icon: Icons.search_rounded,
                title: 'Find Recipes',
                subtitle: 'Search by ingredients',
                color: Colors.blue,
                onTap: () => _navigateToRecipeSearch(context),
              ),
              
              _buildActionCard(
                context: context,
                icon: Icons.favorite_rounded,
                title: 'My Favorites',
                subtitle: 'Saved recipes',
                color: Colors.red,
                onTap: () => _navigateToFavorites(context),
              ),
              
              _buildActionCard(
                context: context,
                icon: Icons.shuffle_rounded,
                title: 'Surprise Me',
                subtitle: 'Random recipe',
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Random Recipe - Coming Soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              _buildActionCard(
                context: context,
                icon: Icons.calendar_today_rounded,
                title: 'Meal Plan',
                subtitle: 'Weekly planning',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal Planner - Coming Soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your cooking journey starts here! Explore recipes and save your favorites to see them in this section.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explore Screen with Recipe Discovery
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _filteredRecipes = [];
  List<String> _availableIngredients = [];
  List<String> _selectedMoods = [];
  int? _maxPrepTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });
    
    final recipes = await _recipeService.getFilteredRecipes(
      moods: _selectedMoods,
      maxPrepTime: _maxPrepTime,
      availableIngredients: _availableIngredients,
    );
    
    setState(() {
      _filteredRecipes = recipes;
      _isLoading = false;
    });
  }

  void _onIngredientsUpdated(List<String> ingredients) {
    setState(() {
      _availableIngredients = ingredients;
    });
    _loadRecipes();
  }

  void _onFilterChanged(List<String> moods, int? maxTime) {
    setState(() {
      _selectedMoods = moods;
      _maxPrepTime = maxTime;
    });
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Recipes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket),
            onPressed: () async {
              final updatedIngredients = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IngredientInputScreen(
                    initialIngredients: _availableIngredients,
                    onIngredientsUpdated: _onIngredientsUpdated,
                  ),
                ),
              );
              if (updatedIngredients != null) {
                _onIngredientsUpdated(updatedIngredients);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MoodTimeDropdowns(
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RecipeList(recipes: _filteredRecipes),
          ),
        ],
      ),
    );
  }
}

/// Ingredient Input Screen
class IngredientInputScreen extends StatefulWidget {
  final List<String> initialIngredients;
  final Function(List<String>) onIngredientsUpdated;

  const IngredientInputScreen({
    super.key,
    required this.initialIngredients,
    required this.onIngredientsUpdated,
  });

  @override
  State<IngredientInputScreen> createState() => _IngredientInputScreenState();
}

class _IngredientInputScreenState extends State<IngredientInputScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.initialIngredients);
  }

  void _addIngredient() {
    final ingredient = _controller.text.trim();
    if (ingredient.isNotEmpty && !_ingredients.contains(ingredient)) {
      setState(() {
        _ingredients.add(ingredient);
        _controller.clear();
      });
      widget.onIngredientsUpdated(_ingredients);
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
    widget.onIngredientsUpdated(_ingredients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ingredients'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter ingredient',
                      hintText: 'e.g., tomato, chicken, rice',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addIngredient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Available Ingredients (${_ingredients.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _ingredients.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No ingredients added yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Add ingredients to find matching recipes',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.kitchen_rounded),
                            title: Text(ingredient),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeIngredient(ingredient),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mood and Time Filter Dropdowns
class MoodTimeDropdowns extends StatefulWidget {
  final Function(List<String>, int?) onFilterChanged;

  const MoodTimeDropdowns({super.key, required this.onFilterChanged});

  @override
  State<MoodTimeDropdowns> createState() => _MoodTimeDropdownsState();
}

class _MoodTimeDropdownsState extends State<MoodTimeDropdowns> {
  List<String> _selectedMoods = [];
  int? _selectedMaxTime;

  final List<String> _availableMoods = [
    'quick',
    'comfort',
    'healthy',
    'refreshing',
    'warm',
    'easy',
    'impressive',
    'hearty'
  ];

  final List<int> _availableTimes = [15, 30, 45, 60, 120];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Recipes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableMoods.map((mood) {
                final isSelected = _selectedMoods.contains(mood);
                return FilterChip(
                  label: Text(mood),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMoods.add(mood);
                      } else {
                        _selectedMoods.remove(mood);
                      }
                    });
                    _notifyParent();
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            const Text('Maximum Prep Time', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedMaxTime,
              hint: const Text('Select max time'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No time limit'),
                ),
                ..._availableTimes.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text('$time minutes'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMaxTime = value;
                });
                _notifyParent();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _notifyParent() {
    widget.onFilterChanged(_selectedMoods, _selectedMaxTime);
  }
}

/// Recipe List Widget
class RecipeList extends StatelessWidget {
  final List<Recipe> recipes;

  const RecipeList({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recipes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Try adjusting your filters or ingredients',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildRecipeCard(context, recipe);
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recipe.prepTime} min',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingredients: ${recipe.ingredients.join(', ')}',
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: recipe.moods.map((mood) {
                return Chip(
                  label: Text(mood),
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  recipe.difficulty,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder Screens
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Profile Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Content coming soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_rounded,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Settings Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Content coming soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
