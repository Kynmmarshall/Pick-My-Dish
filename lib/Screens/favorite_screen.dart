import 'package:flutter/material.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:pick_my_dish/constants.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteRecipes = RecipesScreenState.allRecipes.where((recipe) => recipe['isFavorite'] == true).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Favorite Recipes", style: title.copyWith(fontSize: 28)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  ),
                ],
              ),
              SizedBox(height: 30),
              
              // Favorites List
              Expanded(
                child: favoriteRecipes.isEmpty
                    ? Center(
                        child: Text(
                          "No favorite recipes yet",
                          style: text,
                        ),
                      )
                    : ListView.builder(
                        itemCount: favoriteRecipes.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 15),
                            child: HomeScreenState.buildRecipeCard(favoriteRecipes[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}