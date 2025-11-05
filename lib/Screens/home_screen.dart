import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
              gradient: LinearGradient(
              colors: [
                Colors.black,
                const Color.fromARGB(255, 97, 96, 96),
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

                  Image.asset(
                  'assets/icons/hamburger.png',
                  width: 24,
                  height: 24,
                )
                  ]
                ),
               ),
              ),
          )
          ],
        ),
      )
      );
  }
}