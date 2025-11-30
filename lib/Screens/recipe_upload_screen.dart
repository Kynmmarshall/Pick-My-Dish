import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/constants.dart';
import 'dart:io';

class RecipeUploadScreen extends StatefulWidget {
  const RecipeUploadScreen({super.key});

  @override
  State<RecipeUploadScreen> createState() => _RecipeUploadScreenState();
}

class _RecipeUploadScreenState extends State<RecipeUploadScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  File? _selectedImage;
  final List<String> _selectedEmotions = [];
  
  final List<String> _emotions = [
    'Happy', 'Sad', 'Energetic', 'Comfort', 
    'Healthy', 'Quick', 'Light'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
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

  void _uploadRecipe() {
    // Validate required fields
    if (_nameController.text.isEmpty || 
        _timeController.text.isEmpty ||
        _caloriesController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _stepsController.text.isEmpty ||
        _selectedImage == null ||
        _selectedEmotions.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields', style: text),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Upload to backend
    final recipeData = {
      'name': _nameController.text,
      'time': _timeController.text,
      'calories': _caloriesController.text,
      'ingredients': _ingredientsController.text,
      'steps': _stepsController.text,
      'emotions': _selectedEmotions,
      'image': _selectedImage!.path,
    };

    print('Recipe to upload: $recipeData');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recipe uploaded successfully!', style: text),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Upload Recipe', style: title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
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
            
            // Cooking Time & Calories
            Row(
              children: [
                Expanded(
                  child: _buildTextField('Cooking Time (e.g., 30 mins)', _timeController),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField('Calories', _caloriesController),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Emotions Selection
            _buildEmotionsSection(),
            const SizedBox(height: 15),
            
            // Ingredients
            _buildTextArea('Ingredients (one per line)', _ingredientsController),
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
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: Colors.orange,
              checkmarkColor: Colors.white,
              labelStyle: text.copyWith(
                color: isSelected ? Colors.white : Colors.white,
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
          height: 120,
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
}