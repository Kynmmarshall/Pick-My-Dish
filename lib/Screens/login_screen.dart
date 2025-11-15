import 'package:flutter/material.dart';
import 'package:pick_my_dish/Screens/register_screen.dart';
import 'package:pick_my_dish/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(body: Container(
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
                     Colors.transparent,
                     Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,

                  )
                  )
                ),

              Padding(padding: const EdgeInsets.all(30),
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
                    "Login",
                    style: title,
                  ),

                  SizedBox(height: 15),   

                  Row(
                    children: [
                      Icon(Icons.email,
                      color: Colors.white,
                      size: iconSize,),
                      SizedBox(width: 10,),
                      Expanded(child:
                      TextField(
                        style: text,
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: placeHolder,
                        ),
                      ),
                    )],
                  ),

                  SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(Icons.key,
                      color: Colors.white,
                      size: iconSize,),
                      SizedBox(width: 10,),
                      Expanded(child:
                      TextField(
                        style: text,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: placeHolder,
                          suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        ),
                      ),
                    )],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                     GestureDetector(
                      onTap: () {
                        // Navigate to login screen
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                      },
                      child: Text(
                        "Forgot Password? ",
                        style: footerClickable
                      ),
                    ),
                      
                    ],
                  ),

                  SizedBox(height: 20),

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.g_mobiledata, color: Colors.red, size: iconSize),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      // Registration logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Your color
                      side: BorderSide(color: Colors.white, width: 2),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      "Login",
                      style:  title,
                    ),
                  ),
                  
                  SizedBox(height: 100),

                  Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child:

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not Registered Yet? ",
                        style: footer,),
                     GestureDetector(
                      onTap: () {
                        // Navigate to login screen
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                      },
                      child: Text(
                        "Register Now",
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
}