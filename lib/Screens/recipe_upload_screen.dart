import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/ingredient_selector.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class RecipeUploadScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? ingredientLoaderOverride;

  const RecipeUploadScreen({super.key, this.ingredientLoaderOverride});

  @override
  State<RecipeUploadScreen> createState() => _RecipeUploadScreenState();
}

class _RecipeUploadScreenState extends State<RecipeUploadScreen> {
  final TextEditingController _nameController = TextEditingController();  
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  File? _selectedImage;
  bool _isPickingImage = false;
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
    'Happy', 'Energetic', 'Comfort', 
    'Healthy', 'Quick', 'Light'
  ];

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.primaryColor;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera, color: primaryColor),
                title: Text('Take Photo', style: text.copyWith(color: primaryColor)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: Text('Choose from Gallery', style: text.copyWith(color: primaryColor)),
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
    try {
      final picker = ImagePicker();
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

  void _uploadRecipe() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_nameController.text.isEmpty || _selectedImage == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Please fill required fields'),
        backgroundColor: Theme.of(context).primaryColor,),
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
  debugPrint('📤 Uploading recipe with moods: $_selectedEmotions');
  debugPrint('📤 Recipe data: $recipeData');
  
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      final success = await ApiService.uploadRecipe(recipeData, _selectedImage);

      if (!mounted) return;

      navigator.pop();
      
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text('Recipe uploaded successfully!'),
          backgroundColor: Theme.of(context).primaryColor,),
        );
        navigator.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Upload failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,),
        );
      }
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Upload failed: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        title: Text('Upload Recipe', style: title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor), iconSize: iconSize,
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
                backgroundColor: primaryColor,
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
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
              color: theme.cardColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryColor, width: 2),
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: primaryColor, size: 50),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
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
              backgroundColor: theme.cardColor.withValues(alpha: 0.6),
              selectedColor: primaryColor,
              checkmarkColor: theme.floatingActionButtonTheme.foregroundColor ?? onSurfaceColor,
              labelStyle: text.copyWith(
                color: isSelected ? theme.scaffoldBackgroundColor : onSurfaceColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return TextField(
      controller: controller,
      style: text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: placeHolder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildTextArea(String hint, TextEditingController controller) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: mediumtitle),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: mediumtitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              style: text,
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: text.copyWith(color: primaryColor)),
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
  final theme = Theme.of(context);
  final primaryColor = theme.primaryColor;
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
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
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