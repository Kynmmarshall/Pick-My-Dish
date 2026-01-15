import 'package:flutter/material.dart';
import 'package:pick_my_dish/Screens/login_screen.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
enum PasswordStrength { weak, medium, strong }
class _RegisterScreenState extends State<RegisterScreen> {
   final TextEditingController _userNameController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();
   final TextEditingController _confirmPasswordController = TextEditingController();



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    final surfaceColor = theme.scaffoldBackgroundColor;
    final buttonTextColor = theme.floatingActionButtonTheme.foregroundColor ?? theme.textTheme.titleLarge?.color;
    return Scaffold(
      body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
            image: DecorationImage(
            image: AssetImage("assets/login/background.png"),
            fit: BoxFit.cover,
          ),
        ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                     surfaceColor.withValues(alpha: 0.0),
                     surfaceColor.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,

                  )
                  )
                ),

              Padding(padding: EdgeInsets.all(30),
              child: Center(
                child: SingleChildScrollView(
                child: Column(
                  children: [
                  SizedBox(height: 20,),
                      //logo
                  Image.asset('assets/login/logo.png'),
                
                  SizedBox(height: 10),

                  Text(
                    "PICK MY DISH",
                    style: title,
                    ),

                  Text(
                    "Cook in easy way",
                    style: text,
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Register",
                    style: title,
                  ),

                  SizedBox(height: 15),   
              
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: onSurfaceColor,
                        size: iconSize,
                      ),
                      SizedBox(width: 10,),
                      Expanded(child:
                      TextField(
                        style: text,
                        controller: _userNameController,
                        decoration: InputDecoration(
                          hintText: "User Name",
                          hintStyle: placeHolder,
                        ),
                      ),
                    )],
                  ) ,

                  SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: onSurfaceColor,
                        size: iconSize,
                      ),
                      SizedBox(width: 10,),
                      Expanded(child:
                      TextField(
                        style: text,
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: placeHolder,
                        ),
                      ),
                    )],
                  ),

                  SizedBox(height: 5),

                  Column(
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: 400), // or your desired max width
                      
                      child: TextField(
                        controller: _passwordController,
                        style: text,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          hintStyle: placeHolder,
                          labelStyle: placeHolder,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),

                    _buildPasswordStrengthIndicator(_passwordController.text),

                    Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: TextField(
                        controller: _confirmPasswordController,
                        style: text,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          hintStyle: placeHolder,
                          labelStyle: placeHolder,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      "Register",
                      style:  title.copyWith(color: buttonTextColor),
                    ),
                  ),
                  
                  SizedBox(height: 100),

                  Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already Registered? ",
                        style: footer,),
                     GestureDetector(
                      onTap: () {
                        // Navigate to login screen
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                      },
                      child: Text(
                        "Login Now",
                        style: footerClickable
                      ),
                    ),
                      
                    ],
                  ),
                ),
                ),
                ]
                ),
              ),
              ),
            ),
          ],
        ),
      ),
              );
  }
   
  // Add this widget to show password strength
  Widget _buildPasswordStrengthIndicator(String password) {
    final strength = _checkPasswordStrength(password);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    Color color;
    String text;
    double width;
    
    switch (strength) {
      case PasswordStrength.weak:
        color = theme.colorScheme.error;
        text = 'Weak';
        width = 0.3;
        break;
      case PasswordStrength.medium:
        color = primaryColor;
        text = 'Medium';
        width = 0.6;
        break;
      case PasswordStrength.strong:
        color = primaryColor;
        text = 'Strong';
        width = 1.0;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Password Strength: $text', style: TextStyle(
          color: color,
          fontSize: 12,
        )),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 4,
              width: MediaQuery.of(context).size.width * width,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

    void _register() async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // Get trimmed values
  final userName = _userNameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text;
  final confirmPassword = _confirmPasswordController.text;

  // Check for empty fields
  if (userName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Please fill in all fields', style: text),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    return;
  }

  // Validate email format
  if (!_isValidEmail(email)) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Please enter a valid email address (e.g., john.smith@gmail.com)', style: text),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    return;
  }

  // Validate password length
  if (password.length < 8) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Password must be at least 8 characters long', style: text),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    return;
  }

  // Check password strength
  final passwordStrength = _checkPasswordStrength(password);
  if (passwordStrength == PasswordStrength.weak) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Password is too weak. Include uppercase, lowercase, numbers, and special characters', style: text),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    return;
  }

  // Check if passwords match
  if (password != confirmPassword) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Passwords do not match', style: text),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).primaryColor,
      ),
    ),
  );

  try {
    var result = await ApiService.register(userName, email, password);
    if (!mounted) return;

    navigator.pop();

    if (result != null && result['error'] == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Registration successful! Please login.', style: text),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Registration failed', style: text),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Error: $e', style: text),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
  // Email validation function
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

// Password strength checker
  PasswordStrength _checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int strength = 0;
    
    // Check length
    if (password.length >= 8) strength++;
    
    // Check for uppercase letters
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    
    // Check for lowercase letters
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    
    // Check for numbers
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    
    // Check for special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

}
