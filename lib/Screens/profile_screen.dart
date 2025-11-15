import 'package:flutter/material.dart';
import 'package:pick_my_dish/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "kynmmarshall";
  TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usernameController.text = username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
        color: Colors.black
        ),
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 50,
              left: 30,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back, color: Colors.orange, size: iconSize),
              ),
            ),
            
            // Main Content
            Center(
              child: Container(
                width: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Image with Edit Icon
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage('assets/login/noPicture.png'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit, color: Colors.white, size: iconSize),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    
                    // Username Text Field
                    TextField(
                      controller: usernameController,
                      style: text,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Username",
                        hintStyle: placeHolder,
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Upload Button
                    ElevatedButton(
                      onPressed: () {
                        // Upload Profile Info logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text("Confirm", style: text.copyWith(fontSize: 30)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}