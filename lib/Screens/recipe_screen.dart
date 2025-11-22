import 'package:flutter/material.dart';
import 'package:pick_my_dish/constants.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  static List<Map<String, dynamic>> allRecipes = [
    {
      'category': 'Breakfast',
      'name': 'Toast with Berries',
      'time': '10:03',
      'isFavorite': false,
      'image': 'assets/recipes/test.png',
      'calories': '1003',
    },
    {
      'category': 'Dinner',
      'name': 'Chicken Burger',
      'time': '25:30',
      'isFavorite': true,
      'image': 'assets/recipes/test.png',
      'calories': '2008',
    },
    {
      'category': 'Dinner',
      'name': 'Chicken Burger',
      'time': '25:30',
      'isFavorite': true,
      'image': 'assets/recipes/test.png',
      'calories': '2008',
    },
    {
      'category': 'Breakfast',
      'name': 'Toast with Berries',
      'time': '10:03',
      'isFavorite': false,
      'image': 'assets/recipes/test.png',
      'calories': '1003',
    },
    {
      'category': 'Dinner',
      'name': 'Chicken Burger',
      'time': '25:30',
      'isFavorite': true,
      'image': 'assets/recipes/test.png',
      'calories': '2008',
    },
    {
      'category': 'Dinner',
      'name': 'Chicken Burger',
      'time': '25:30',
      'isFavorite': true,
      'image': 'assets/recipes/test.png',
      'calories': '2008',
    },
    {
      'category': 'Dinner',
      'name': 'Chicken Burger',
      'time': '25:30',
      'isFavorite': true,
      'image': 'assets/recipes/test.png',
      'calories': '2008',
    },
    // Add more recipes here
  ];

  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> get filteredRecipes {
    if (searchQuery.isEmpty) return allRecipes;
    return allRecipes.where((recipe) {
      return recipe['name'].toLowerCase().contains(searchQuery) ||
          recipe['category'].toLowerCase().contains(searchQuery);
    }).toList();
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              SizedBox(height: 50),
              // Header with title and back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("All Recipes", style: title.copyWith(fontSize: 28)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.orange,
                      size: iconSize,
                    ),
                  ),
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
                        style: text,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
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

              // Recipes Grid
              Expanded(
                child: filteredRecipes.isEmpty
                    ? Center(child: Text("No recipes found", style: title))
                    : GridView.builder(
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
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Recipe Image
          Positioned(
            top: 20,
            right: 10,
            child: Container(
              width: 99,
              height: 87,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: AssetImage(recipe['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Favorite Icon
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  recipe['isFavorite'] = !recipe['isFavorite'];
                });
              },
              child: Icon(
                recipe['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                color: Colors.orange,
                size: iconSize,
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
                  recipe['category'],
                  style: categoryText.copyWith(
                    color: Color(0xFF2958FF),
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 5),

                // Recipe Name
                Text(recipe['name'], style: text.copyWith(fontSize: 17)),
                SizedBox(height: 10),

                // Time with Icon
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      recipe['time'],
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
    );
  }
}
