import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(PickMyDishApp());
}

class PickMyDishApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PickMyDish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF00B478),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
      ),
      home: PickMyDishHome(),
    );
  }
}

class PickMyDishHome extends StatefulWidget {
  @override
  _PickMyDishHomeState createState() => _PickMyDishHomeState();
}

class _PickMyDishHomeState extends State<PickMyDishHome> {
  final TextEditingController ingredientCtrl = TextEditingController();

  String selectedMood = "Healthy";
  String selectedTime = "<=15";
  List<Map<String, dynamic>> recipes = [];
  Map<String, dynamic>? suggestion;

  final List<String> moods = ["Healthy", "Lazy", "Hungry", "Energetic"];
  final List<String> times = ["<=15", "15-30", "30-60"];

  final List<Map<String, dynamic>> allRecipes = [
    {
      "name": "Tomato Pasta",
      "ingredients": ["pasta", "tomato", "onion", "garlic", "olive oil"],
      "moods": ["hungry", "energetic", "healthy"],
      "time": 20,
      "instructions": "Boil pasta, add tomato sauce, mix and serve."
    },
    {
      "name": "Veggie Omelette",
      "ingredients": ["eggs", "onion", "tomato", "cheese"],
      "moods": ["lazy", "healthy"],
      "time": 10,
      "instructions": "Mix eggs with veggies, fry, and fold with cheese."
    },
    {
      "name": "Avocado Toast",
      "ingredients": ["bread", "avocado", "salt"],
      "moods": ["lazy", "healthy"],
      "time": 5,
      "instructions": "Mash avocado, spread on toast, add salt."
    },
    {
      "name": "Chicken Stir-fry",
      "ingredients": ["chicken", "soy sauce", "broccoli"],
      "moods": ["energetic", "hungry"],
      "time": 25,
      "instructions": "Fry chicken and veggies, add soy sauce."
    },
    {
      "name": "Greek Salad",
      "ingredients": ["tomato", "cucumber", "feta"],
      "moods": ["healthy"],
      "time": 10,
      "instructions": "Mix veggies with feta and olive oil."
    }
  ];

  // --- Core logic ---
  List<String> parseIngredients(String text) =>
      text.split(",").map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();

  double score(Map<String, dynamic> recipe, List<String> have, String mood, int tmax) {
    final ing = List<String>.from(recipe["ingredients"]);
    final ingMatch = ing.where((i) => have.contains(i)).length;
    final moodScore = recipe["moods"].contains(mood.toLowerCase()) ? 1 : 0;
    final timeScore = recipe["time"] <= tmax ? 1 : 0;
    return ingMatch * 0.6 + moodScore * 0.3 + timeScore * 0.1;
  }

  void suggestDish() {
    final have = parseIngredients(ingredientCtrl.text);
    final tmax = {"<=15": 15, "15-30": 30, "30-60": 60}[selectedTime] ?? 100;

    final sorted = List<Map<String, dynamic>>.from(allRecipes)
      ..sort((a, b) =>
          score(b, have, selectedMood, tmax).compareTo(score(a, have, selectedMood, tmax)));

    setState(() {
      suggestion = sorted.isNotEmpty ? sorted.first : null;
    });
  }

  Future<void> saveFavorite() async {
    if (suggestion == null) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList("favorites") ?? [];
    existing.add(jsonEncode(suggestion));
    await prefs.setStringList("favorites", existing);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Recipe saved to favorites!")));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PickMyDish 🍽", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF00B478),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: ingredientCtrl,
            decoration: InputDecoration(
              labelText: "Enter ingredients (comma separated)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 20),
          Text("Select Mood:", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: moods
                .map((m) => ChoiceChip(
                      label: Text(m),
                      selected: selectedMood == m,
                      onSelected: (_) => setState(() => selectedMood = m),
                      selectedColor: Color(0xFF00B478),
                      labelStyle: TextStyle(color: selectedMood == m ? Colors.white : Colors.black),
                    ))
                .toList(),
          ),
          SizedBox(height: 20),
          Text("Select Cooking Time:", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: times
                .map((t) => ChoiceChip(
                      label: Text(t),
                      selected: selectedTime == t,
                      onSelected: (_) => setState(() => selectedTime = t),
                      selectedColor: Color(0xFF00B478),
                      labelStyle: TextStyle(color: selectedTime == t ? Colors.white : Colors.black),
                    ))
                .toList(),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00B478),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: suggestDish,
            icon: Icon(Icons.restaurant_menu, color: Colors.white),
            label: Text("Suggest Dish", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00805A),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: saveFavorite,
            icon: Icon(Icons.favorite, color: Colors.white),
            label: Text("Save Favorite", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 30),
          if (suggestion != null) _buildRecipeCard(suggestion!)
          else
            Center(
                child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text("No suggestion yet. Try entering ingredients!",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ))
        ]),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r["name"],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00B478))),
          SizedBox(height: 10),
          Text("Time: ${r["time"]} min", style: TextStyle(color: Colors.grey[700])),
          SizedBox(height: 6),
          Text("Ingredients: ${r["ingredients"].join(", ")}"),
          SizedBox(height: 10),
          Text("Instructions:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
          Text(r["instructions"]),
        ]),
      ),
    );
  }
}
