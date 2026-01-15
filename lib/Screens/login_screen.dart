import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/user_model.dart';
import 'package:pick_my_dish/Providers/user_provider.dart';
import 'package:pick_my_dish/Services/api_service.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/Screens/register_screen.dart';
import 'package:pick_my_dish/Screens/home_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  void _login() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields', style: text),
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
      final Map<String, dynamic>? response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      navigator.pop();

      // if (response != null && response['user'] != null) {
      //   final userProvider = Provider.of<UserProvider>(context, listen: false);
        
      //   // Use the actual user data from API
      //   userProvider.setUser(User.fromJson(response['user']));
      //   userProvider.setUserId(response['userId'] ?? 0);
      //   if (context.mounted) {
      //     Navigator.pushReplacement(
      //       context, 
      //       MaterialPageRoute(builder: (context) => HomeScreen())
      //     );
      //   }
      // } else {
      //   // Handle error
      //   final errorMessage = response?['error'] ?? 'Login failed';
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text(errorMessage, style: text),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //   }

      if (response != null && response['user'] != null) {
        userProvider.setUser(User.fromJson(response['user']));
        userProvider.setUserId(response['userId'] ?? 0);

        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Invalid email or password', style: text),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Connection error: $e', style: text),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final surfaceColor = theme.scaffoldBackgroundColor;
    final onSurfaceColor = theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodyLarge?.color;
    final buttonTextColor = theme.floatingActionButtonTheme.foregroundColor ?? theme.textTheme.titleLarge?.color;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      //logo
                      Image.asset(
                        'assets/login/logo.png',
                        width: 100,
                        height: 100,
                      ),

                      const SizedBox(height: 10),

                      Text("PICK MY DISH", style: title),

                      Text("Cook in easy way", style: text),

                      const SizedBox(height: 5),

                      Text("Login", style: title),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: onSurfaceColor,
                            size: iconSize,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: text,
                              decoration: InputDecoration(
                                hintText: "Email Address",
                                hintStyle: placeHolder,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Icon(
                            Icons.key,
                            color: onSurfaceColor,
                            size: iconSize,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              style: text,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Password",
                                hintStyle: placeHolder,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: onSurfaceColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (context) => HomeScreen())
                            );
                            },
                            child: Text(
                              "Login As Guest",
                              style: footerClickable,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Login Button
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Login",
                          style: title.copyWith(fontSize: 20,
                          color: buttonTextColor,),
                          
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Not Registered Yet? ", style: footer),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text("Register Now", style: footerClickable),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
