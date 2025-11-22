import 'package:flutter/material.dart';
import 'package:pick_my_dish/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "FAHDIL";
  TextEditingController usernameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    usernameController.text = username;
  }

  void _saveProfile() {
    setState(() {
      username = usernameController.text;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!', style: text),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      usernameController.text = username;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 50,
              left: 30,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage(
                          'assets/login/noPicture.png',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Change profile picture logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Profile picture change feature coming soon!',
                                  style: text,
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
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

                  // Username Section
                  Text("Username", style: mediumtitle),
                  const SizedBox(height: 10),

                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                  else
                    Text(username, style: title.copyWith(fontSize: 24)),

                  const SizedBox(height: 20),

                  // Action Buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
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
                          "kynmmarshall@example.com",
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.cake,
                          "Member since",
                          "January 2024",
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

                  const Spacer(),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Logout logic
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text("Logout", style: text.copyWith(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
