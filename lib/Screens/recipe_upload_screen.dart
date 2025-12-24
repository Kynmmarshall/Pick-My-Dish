import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/ingredient_Selector.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class RecipeUploadScreen extends StatefulWidget {
  const RecipeUploadScreen({super.key});

  @override
  State<RecipeUploadScreen> createState() => _RecipeUploadScreenState();
}

class _RecipeUploadScreenState extends State<RecipeUploadScreen> {
  final TextEditingController _nameController = TextEditingController();  
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  File? _selectedImage;
  final List<String> _selectedEmotions = [];
  String _selectedTime = '30 mins';

  final List<String> _timeOptions = [
    '15 mins',
    '30 mins', 
    '45 mins',
    '1 hour',
    '1 hour 15 mins',
    '1 hour 30 mins',
    '2+ hours'
  ];
  
  List<int> _selectedIngredientIds = [];
  String _selectedCategory = 'Uncategorised';
  final List<String> _categoryOptions = [
  'Dessert',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snack',
  'Uncategorised'
];

  final List<String> _emotions = [
    'Happy', 'Sad', 'Energetic', 'Comfort', 
    'Healthy', 'Quick', 'Light'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85, // Add compression
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _toggleEmotion(String emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else {
        _selectedEmotions.add(emotion);
      }
    });
  }

  void _uploadRecipe() async {
  // Validate
  if (_nameController.text.isEmpty || _selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill required fields')),
    );
    return;
  }
  
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  final recipeData = {
    'name': _nameController.text,
    'category': _selectedCategory, // Add category dropdown
    'time': _selectedTime,
    'calories': _caloriesController.text,
    'ingredients': _selectedIngredientIds,
    'instructions': _stepsController.text.split('\n'),
    'userId': userProvider.userId,
    'emotions': _selectedEmotions, 
  };
  
    // ADD THIS DEBUG LINE
  print('📤 Uploading recipe with moods: $_selectedEmotions');
  print('📤 Recipe data: $recipeData');
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );
  
  try {
    bool success = await ApiService.uploadRecipe(recipeData, _selectedImage);
    
    Navigator.pop(context); // Hide loading
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe uploaded successfully!')),
      );
      Navigator.pop(context); // Go back
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Upload Recipe', style: title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange), iconSize: iconSize,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            _buildImageSection(),
            const SizedBox(height: 20),
            
            // Recipe Name
            _buildTextField('Recipe Name', _nameController),
            const SizedBox(height: 15),
            
            // ADD CATEGORY DROPDOWN HERE
            _buildDropdown(_selectedCategory, _categoryOptions, (newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            }, 'Category'
            
            
            ),
            const SizedBox(height: 15),

            // Cooking Time & Calories
            Row(
              children: [
                Expanded(child: _buildDropdown(_selectedTime , _timeOptions, (newValue) {
                  setState(() {
                    _selectedTime = newValue;
                  });
                }, 'Cooking Time')),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildNumberField('KiloCalories', _caloriesController),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Emotions Selection
            _buildEmotionsSection(),
            const SizedBox(height: 15),
            
            // Ingredients
            _buildIngredientsSection(),
            const SizedBox(height: 15),
            
            // Cooking Steps
            _buildTextArea('Cooking Steps (one per line)', _stepsController),
            const SizedBox(height: 30),
            
            // Upload Button
            ElevatedButton(
              onPressed: _uploadRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text('Upload Recipe', style: title.copyWith(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipe Image', style: mediumtitle),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.orange, size: 50),
                      const SizedBox(height: 10),
                      Text('Tap to add image', style: text),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emotions (select one or more)', style: mediumtitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _emotions.map((emotion) {
            final isSelected = _selectedEmotions.contains(emotion);
            return FilterChip(
              label: Text(emotion, style: text),
              selected: isSelected,
              onSelected: (_) => _toggleEmotion(emotion),
              backgroundColor: const Color.fromARGB(255, 46, 32, 3).withOpacity(0.3),
              selectedColor: Colors.orange,
              checkmarkColor: Colors.white,
              labelStyle: text.copyWith(
                color: isSelected ? const Color.fromARGB(255, 31, 30, 30) : Colors.white,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: placeHolder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }

  Widget _buildTextArea(String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: mediumtitle),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: text,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Enter each item on a new line...',
              hintStyle: placeHolder,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String currentValue, 
    List<String> options, 
    Function(String) onChanged,
    String label
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: mediumtitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: text,
              icon: Icon(Icons.arrow_drop_down, color: Colors.orange),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: text.copyWith(color: Colors.orange)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue); // ← Call the callback
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String hint, TextEditingController controller) {
  return TextField(
    controller: controller,
    style: text,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: placeHolder,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    ),
  );
}

  Widget _buildIngredientsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ingredients', style: mediumtitle),
      const SizedBox(height: 10),
      IngredientSelector(
        selectedIds: _selectedIngredientIds,
        onSelectionChanged: (ids) {
          setState(() {
            _selectedIngredientIds = ids;
          });
        },
        hintText: "Search ingredients...",
      ),
    ],
  );
}

}