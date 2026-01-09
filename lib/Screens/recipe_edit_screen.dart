import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/Models/recipe_model.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/ingredient_selector.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class RecipeEditScreen extends StatefulWidget {
  final Recipe recipe;
  final Future<List<Map<String, dynamic>>> Function()? ingredientLoaderOverride;
  
  const RecipeEditScreen({super.key, required this.recipe, this.ingredientLoaderOverride});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final TextEditingController _nameController = TextEditingController();  
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  File? _selectedImage;
  bool _isPickingImage = false;
  final List<String> _selectedEmotions = [];
  String _selectedTime = '30 mins';
  
  List<int> _selectedIngredientIds = [];
  String _selectedCategory = 'Uncategorised';
  
  final List<String> _timeOptions = [
    '15 mins', '30 mins', '45 mins', '1 hour',
    '1 hour 15 mins', '1 hour 30 mins', '2+ hours'
  ];
  
  final List<String> _categoryOptions = [
    'Dessert', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Uncategorised'
  ];
  
  final List<String> _emotions = [
    'Happy', 'Sad', 'Energetic', 'Comfort', 'Healthy', 'Quick', 'Light'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final recipe = widget.recipe;
    
    _nameController.text = recipe.name;
    _caloriesController.text = recipe.calories;
    _stepsController.text = recipe.steps.join('\n');
    _selectedTime = recipe.cookingTime;
    _selectedCategory = recipe.category;
    _selectedEmotions.addAll(recipe.moods);
    
    // You'll need to load ingredient IDs from API
    // This is a placeholder - you'll need to implement based on your API
  }
  
  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.orange),
                title: Text('Take Photo', style: text.copyWith(color: Colors.orangeAccent)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: Text('Choose from Gallery', style: text.copyWith(color: Colors.orangeAccent)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    final source = await _chooseImageSource();
    if (source == null) return;

    _isPickingImage = true;
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      _isPickingImage = false;
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
  
  void _updateRecipe() async {
      debugPrint('🔄 UPDATE RECIPE DEBUG INFO:');
      debugPrint('   Recipe ID: ${widget.recipe.id}');
      debugPrint('   Recipe from widget: ${widget.recipe.name}');
      debugPrint('   Recipe userId from widget: ${widget.recipe.userId}');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_nameController.text.isEmpty) {
      debugPrint('🔄 Update button pressed');
      messenger.showSnackBar(
        SnackBar(content: Text('Please fill required fields'),
        backgroundColor: Colors.orange,),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    debugPrint('   Current user ID: ${userProvider.userId}');
    debugPrint('   Current user isAdmin: ${userProvider.user?.isAdmin}');
    debugPrint('   Current username: ${userProvider.username}');
    
    // Check if recipe exists in provider
  final recipeInProvider = recipeProvider.recipes.firstWhere(
    (r) => r.id == widget.recipe.id,
    orElse: () => Recipe.empty(),
  );
  
  debugPrint('   Recipe in provider: ${recipeInProvider.id != 0}');
  debugPrint('   Recipe userId in provider: ${recipeInProvider.userId}');

    // Check if user can still edit (in case permissions changed)
    final canEdit = recipeProvider.canEditRecipe(
      widget.recipe.id, 
      userProvider.userId, 
      userProvider.user?.isAdmin ?? false
    );
    
    debugPrint('   Final canEdit result: $canEdit');

    if (!canEdit) {

      messenger.showSnackBar(
        SnackBar(content: Text('You are no longer authorized to edit this recipe',style: text),
        backgroundColor: Colors.orange,),

      );
      return;
    }
       
    debugPrint('📊 Form data:');
    debugPrint('   Name: ${_nameController.text}');
    debugPrint('   Category: $_selectedCategory');
    debugPrint('   Time: $_selectedTime');
    debugPrint('   Calories: ${_caloriesController.text}');
    debugPrint('   Emotions: $_selectedEmotions');
    debugPrint('   Ingredient IDs: $_selectedIngredientIds');
    debugPrint('   Steps: ${_stepsController.text.split('\n').length} steps');
    debugPrint('   User ID: ${userProvider.userId}');
    debugPrint('   Recipe ID: ${widget.recipe.id}');
    debugPrint('   Image selected: ${_selectedImage != null}');

    final recipeData = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'time': _selectedTime,
      'calories': _caloriesController.text,
      'ingredients': _selectedIngredientIds,
      'instructions': _stepsController.text.split('\n'),
      'userId': userProvider.userId,
      'emotions': _selectedEmotions,
    };
    
    debugPrint('📤 Sending update request...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      debugPrint('🚀 Calling ApiService.updateRecipe...');
      bool success = await ApiService.updateRecipe(
        widget.recipe.id,
        recipeData,
        _selectedImage,
      );

      debugPrint('📡 API Response: $success');

      if (!mounted) return;

      navigator.pop();
      
      if (success) {
        debugPrint('✅ Recipe updated successfully!');
        messenger.showSnackBar(
          SnackBar(content: Text('Recipe updated successfully!'),
          backgroundColor: Colors.green,),
        );
        navigator.pop();
      } else {
        debugPrint('❌ Recipe update failed.');
        messenger.showSnackBar(
          SnackBar(content: Text('Update failed. Please try again.'),
          backgroundColor: Colors.red,),
        );
      }
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      debugPrint('🔥 Exception during update: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Update failed: $e'),
        backgroundColor: Colors.red,),
      );
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Edit Recipe', style: title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          iconSize: iconSize,
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
            
            // Category
            _buildDropdown(
              _selectedCategory, 
              _categoryOptions, 
              (newValue) => setState(() { _selectedCategory = newValue; }), 
              'Category'
            ),
            const SizedBox(height: 15),
            
            // Cooking Time & Calories
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    _selectedTime, 
                    _timeOptions, 
                    (newValue) => setState(() { _selectedTime = newValue; }), 
                    'Cooking Time'
                  ),
                ),
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
            
            // Update Button
            ElevatedButton(
              onPressed: _updateRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text('Update Recipe', style: title.copyWith(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Reuse the UI building methods from RecipeUploadScreen
  // Copy _buildImageSection, _buildTextField, etc. from recipe_upload_screen.dart
  // ... (copy the UI building methods from RecipeUploadScreen)
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
              color: Colors.white.withValues(alpha: 0.1),
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
              backgroundColor: const Color.fromARGB(255, 46, 32, 3).withValues(alpha: 0.3),
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
        ingredientLoader: widget.ingredientLoaderOverride,
      ),
    ],
  );
}

}