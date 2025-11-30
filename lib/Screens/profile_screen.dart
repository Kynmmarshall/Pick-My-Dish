import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  TextEditingController usernameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
  super.initState();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  usernameController.text = userProvider.username;
  _loadProfilePicture();
}

  void _loadProfilePicture() async {
  if (!mounted) return;
  
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  String? imagePath = await ApiService.getProfilePicture(userProvider.userId);
  debugPrint('🖼️ Image path from server: $imagePath');
  if (imagePath != null && mounted) {
    userProvider.updateProfilePicture(imagePath);
    setState(() {}); // Refresh UI
  }
}

  void _saveProfile() async {
  // Add this check first
  if (!mounted) return;
  
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  bool success = await ApiService.updateUsername(
    usernameController.text,
    userProvider.userId  
  );

  
  // Check mounted again after async operation
  if (!mounted) return;
  
  if (success) {
    userProvider.updateUsername(usernameController.text, userProvider.userId);
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Username updated!'), backgroundColor: Colors.green),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update failed!'), backgroundColor: Colors.red),
    );
  }
}

  void _cancelEdit() {
    setState(() {
     // usernameController.text = ;
      _isEditing = false;
    });
  }

  void _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    // Check mounted BEFORE using context
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Convert XFile to File and use UPLOAD method (not update)
    bool success = await ApiService.uploadProfilePicture(
      File(pickedFile.path), // Convert to File object
      userProvider.userId
    );
    
    // Check mounted again after async operation
    if (!mounted) return;
    
    if (success) {
      // Reload from server to get the actual stored path
      _loadProfilePicture();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture updated!', style: text),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update picture', style: text),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  ImageProvider _getProfileImage(String imagePath) {
  print('🖼️ Loading image: $imagePath');
  
  // ALWAYS use NetworkImage for server paths
  if (imagePath.startsWith('uploads/') || imagePath.contains('profile-')) {
    return NetworkImage('http://38.242.246.126:3000/$imagePath');
  } else {
    // Only use AssetImage for actual local assets
    return AssetImage(imagePath);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black),
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.orange,
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
                            return CircleAvatar(
                            radius: 60,
                            backgroundImage: _getProfileImage(userProvider.profilePicture),
                          );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
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
                   return Text("${userProvider.username}", style: title.copyWith(fontSize: 24));
                }
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
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                "Save Changes",
                                style: text.copyWith(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('cancel_button'), // FIX: Add key
                              onPressed: _cancelEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                "Cancel",
                                style: text.copyWith(fontSize: 18),
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
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          "Edit Profile",
                          style: text.copyWith(fontSize: 20),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Additional Profile Info
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
                            "12 recipes",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30), // FIX: Replace Spacer with SizedBox

                    // Logout Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('logout_button'), // FIX: Add key
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text("Logout", style: text.copyWith(fontSize: 20)),
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
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 10),
        Text("$title: ", style: text.copyWith(fontWeight: FontWeight.bold)),
        Text(value, style: text),
      ],
    );
  }
}