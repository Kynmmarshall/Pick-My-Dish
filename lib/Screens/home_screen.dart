import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Screens/favorite_screen.dart';
import 'package:pick_my_dish/Screens/profile_screen.dart';
import 'package:pick_my_dish/Screens/recipe_screen.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedEmotion;
  List<String> selectedIngredients = [];
  String? selectedTime;
  
  List<String> emotions = ['Happy', 'Sad', 'Energetic', 'Comfort', 'Healthy'];
  List<String> ingredients = ['Eggs', 'Flour', 'Chicken', 'Vegetables', 'Rice', 'Pasta', 'Cheese', 'Milk'];
  List<String> timeOptions = ['15 mins', '30 mins', '1 hour', '2+ hours'];
  String ingredientSearch = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSideMenu(),
      appBar: AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: Padding(
      padding: EdgeInsets.only(left: 30, top: 30),
      child:GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: Image.asset(
          'assets/icons/hamburger.png',
          width: 24,
          height: 24,
        ),
      ),
      ),
      ),
    
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF6B6B6B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.7, 1.0],
          )
        ),
        child: Stack(
          children: [

            Padding(
              padding: EdgeInsets.all(30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    
                    // Welcome Section
                    Row(
                      children: [
                        Text(
                          "Welcome",
                           style: title,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "What would you like to cook today?",
                      style: title.copyWith(color: Colors.orange)
                    ),
                    SizedBox(height: 30),

                    // Personalization Section
                    _buildPersonalizationSection(),
                    SizedBox(height: 30),

                    // Today's Fresh Recipe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Fresh Recipe",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipesScreen()));
                        },
                        child: Text(
                          "See All",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // Recipe Cards
                    // Recipe Cards - Responsive layout
                    // Replace the Recipe Cards section with:
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: 5, // Since you have 2 cards
                      itemBuilder: (context, index) {
                        final  recipe = RecipesScreenState.allRecipes[index];
                        return Column(
                        children: [
                          buildRecipeCard(recipe),
                          SizedBox(height: 20), // Adds space after each item except last
                        ],
                      );
                      },
                    ),
                    SizedBox(height: 30),

                    
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
          Text(
            "Personalize Your Recipes",
            style:mediumtitle,
          ),
          SizedBox(height: 15),
          
          // Emotion Dropdown
          DropdownButtonFormField<String>(
            value: selectedEmotion,
            decoration: InputDecoration(
              labelText: "How are you feeling?",
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
            items: emotions.map((emotion) {
              return DropdownMenuItem(
                value: emotion,
                child: Text(emotion, style: TextStyle(color: Colors.orange)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedEmotion = value;
              });
            },
          ),
          SizedBox(height: 15),

          // Ingredients Selection
          DropdownSearch<String>.multiSelection(
          items: ingredients,
          popupProps: PopupPropsMultiSelection.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(hintText: "Search ingredients..."),
            ),
          ),
          onChanged: (List<String> selectedItems) {
            setState(() {
              selectedIngredients = selectedItems;
            });
          },
          selectedItems: selectedIngredients,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: "Select ingredients",
              border: OutlineInputBorder(),
            ),
          ),
        ),







          SizedBox(height: 15),

          // Time Selection
          DropdownButtonFormField<String>(
            value: selectedTime,
            decoration: InputDecoration(
              labelText: "Cooking Time",
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
            items: timeOptions.map((time) {
              return DropdownMenuItem(
                value: time,
                child: Text(time, style: TextStyle(color: Colors.orange)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTime = value;
              });
            },
          ),
          SizedBox(height: 15),

          // Generate Recipes Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Generate personalized recipes
                _generateRecipes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                "Generate Personalized Recipes",
                style: text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Color(0xFF373737),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 5,
            offset: Offset(0, 5),
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
                //color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                image: AssetImage(recipe['image']),
                fit: BoxFit.cover,
              ),
              ),
            ),
          ),
          
          // Recipe Name
          Positioned(
            left: 100,
            top: 13,
            child: Text(
              recipe['name'],
              style: TextStyle(
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
                Icon(Icons.access_time, color: Colors.white, size: 16),
                SizedBox(width: 5),
                Text(
                  recipe['time'],
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          // Like Icon - Clickable
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  recipe['isFavorite'] = !recipe['isFavorite'];
                });
              },
              child: Icon(
                recipe['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                color: Colors.orange,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSideMenu() {
  return Container(
    width: MediaQuery.of(context).size.width * 0.9,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.8),
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Stack(
      children: [

        // Background Image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/sideMenu/background.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
        color: Colors.black.withOpacity(0.5), 
       ),
        
        Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              Row(
                children: [
                  Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: Colors.orange, size: iconSize),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
               children: [
              // Profile Section
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/login/noPicture.png'), // Replace with profile image
              ),
              SizedBox(width: 25),
              Text("kynmmarshall", style: title.copyWith(fontSize: 22)),
              ]
              ),
              SizedBox(height: 5),
              GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
              child: Text("View Profile", style: footerClickable),
            ),

              SizedBox(height: 50),
              
              // Menu Items
              _buildMenuItem(Icons.home, "Home", () {Navigator.pop(context);}),
              SizedBox(height: 20),
              _buildMenuItem(Icons.favorite, "Favorites", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));}),
              SizedBox(height: 20),
              _buildMenuItem(Icons.help, "Help", () {Navigator.pop(context);}),
              Spacer(),
              _buildMenuItem(Icons.logout, "Logout", () {Navigator.pop(context);}),
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

  void _generateRecipes() {
    // Logic to generate recipes based on selections
    print("Emotion: $selectedEmotion");
    print("Ingredients: $selectedIngredients");
    print("Time: $selectedTime");
    
    // Navigate to results screen or show dialog with personalized recipes
  }

}