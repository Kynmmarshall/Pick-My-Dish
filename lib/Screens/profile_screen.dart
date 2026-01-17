import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/Providers/recipe_provider.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final bool enableProfilePictureFetch;

  const ProfileScreen({super.key, this.enableProfilePictureFetch = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  TextEditingController usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isPickingImage = false;

  @override
  void initState() {
  super.initState();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  usernameController.text = userProvider.username;
  if (widget.enableProfilePictureFetch) {
    _loadProfilePicture();
  }
}

  void _loadProfilePicture() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? imagePath = await ApiService.getProfilePicture();
    
    // Check mounted BEFORE updating UI
    if (mounted && imagePath != null && imagePath.isNotEmpty) {
      userProvider.updateProfilePicture(imagePath);
      setState(() {});
    }
  }

  void _saveProfile() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await ApiService.updateUsername(usernameController.text);

    if (!mounted) return;

    if (success) {
      userProvider.updateUsername(usernameController.text);
      setState(() {
        _isEditing = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Username updated!'), backgroundColor: Theme.of(context).primaryColor),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Update failed!'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _logout() async {
    // 1. Clear all user data from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    userProvider.logout();
    recipeProvider.logout();   
    
    // 2. Navigate to login (clear navigation stack)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      usernameController.text = Provider.of<UserProvider>(context, listen: false).username;
      _isEditing = false;
    });
  }

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

  void _pickImage() async {
    if (_isPickingImage) return;

    _isPickingImage = true;
    try {
      final source = await _chooseImageSource();
      if (source == null || !mounted) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null || !mounted) return;

      final success = await ApiService.uploadProfilePicture(File(pickedFile.path));

      if (!mounted) return;

      if (success) {
        final actualImagePath = await ApiService.getProfilePicture();

        if (!mounted) return;

        if (actualImagePath != null) {
          final cacheManager = DefaultCacheManager();
          await cacheManager.removeFile('http://38.242.246.126:3000/${userProvider.profilePicture}');
          userProvider.updateProfilePicture(actualImagePath);
          setState(() {});

          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          final theme = Theme.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Profile picture updated!', style: text),
              backgroundColor: theme.primaryColor,
            ),
          );
        }
      } else {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final theme = Theme.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update picture', style: text),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: SingleChildScrollView( // FIX: Add scrollable container
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 50,
                left: 30,
                child: GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: primaryColor,
                    size: iconSize,
                  ),
                ),
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // Profile Image with Edit Icon
                    Stack(
                      children: [
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return CachedProfileImage(imagePath: userProvider.profilePicture,radius: 60,);
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: theme.floatingActionButtonTheme.foregroundColor ?? onSurfaceColor,
                                  size: 20,
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // FIX: Always render TextField but control visibility
                    _isEditing
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('username_field'), // FIX: Add key for testing
                                  controller: usernameController,
                                  style: text.copyWith(fontSize: 20),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: "Enter username",
                                    hintStyle: placeHolder,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : 
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return Text(userProvider.username, style: title.copyWith(fontSize: 24));
                          },
                        ),        

                    const SizedBox(height: 20),

                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('save_button'), // FIX: Add key
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                "Save Changes",
                                style: text2.copyWith(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('cancel_button'), // FIX: Add key
                              onPressed: _cancelEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                "Cancel",
                                style: text2.copyWith(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      ElevatedButton(
                        key: const Key('edit_button'), // FIX: Add key
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          "Edit Profile",
                          style: text2.copyWith(fontSize: 20),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Additional Profile Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 1), 
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Profile Information", style: mediumtitle),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.email,
                            "Email",
                            Provider.of<UserProvider>(context).email,
                          ),
                          const SizedBox(height: 10),
                          Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return _buildInfoRow(
                            Icons.cake,
                            "Member since",
                            DateFormat('d MMMM yyyy').format(userProvider.user?.joinedDate ?? DateTime.now()),
                          );
                          },
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.favorite,
                            "Favorite Recipes",
                            "${Provider.of<RecipeProvider>(context).favorites.length} recipes",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30), // FIX: Replace Spacer with SizedBox

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('logout_button'), // FIX: Add key
                        onPressed: () {
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text("Logout", style: text2.copyWith(fontSize: 20)),
                      ),
                    ),
                    
                    const SizedBox(height: 20), // FIX: Add bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 10),
        Text("$title: ", style: text.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: text,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}