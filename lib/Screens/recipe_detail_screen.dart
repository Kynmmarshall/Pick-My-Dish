import 'package:flutter/material.dart';
import 'package:pick_my_dish/constants.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Recipe Image Header
          SliverAppBar(
            expandedHeight: 300,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                recipe['image'] ?? 'assets/recipes/test.png',
                fit: BoxFit.cover,
              ),
            ),
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: IconButton(
                  icon: Icon(
                    recipe['isFavorite'] == true ? Icons.favorite : Icons.favorite_border,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () {
                    // Toggle favorite logic
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
                              recipe['name'] ?? 'Recipe Name',
                              style: title.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe['category'] ?? 'Category',
                              style: categoryText.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      // Cooking Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              recipe['time'] ?? '30 mins',
                              style: const TextStyle(
                                color: Colors.white,
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${recipe['calories'] ?? '0'} Calories',
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipe['ingredients'] != null)
                          ...List<String>.from(recipe['ingredients']).map(
                            (ingredient) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.orange, size: 8),
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
                          ).toList(),
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipe['steps'] != null)
                          ...List<String>.from(recipe['steps']).asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
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
                          ).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Mood Tags
                  if (recipe['mood'] != null) ...[
                    Text("Perfect For", style: mediumtitle),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List<String>.from(recipe['mood']).map(
                        (mood) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            mood,
                            style: text.copyWith(
                              fontSize: 14,
                              color: Colors.orange,
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
                        // Start cooking logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Happy cooking! 🍳', style: text),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
    );
  }
}
