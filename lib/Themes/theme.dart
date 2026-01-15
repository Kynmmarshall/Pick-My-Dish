import 'package:flutter/material.dart';

// Light Theme
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
primaryColor: Colors.orange,
cardColor: const Color.fromARGB(255, 255, 255, 255),
scaffoldBackgroundColor: const Color.fromARGB(255, 254, 249, 231),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 254, 249, 231),
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'TimesNewRoman',
    ),
  ),
  
  cardTheme: CardThemeData(
    color: const Color.fromARGB(255, 112, 111, 111),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Colors.black,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w600,
      fontSize: 22,
    ),
    bodyLarge: TextStyle(
      color: Colors.black87,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Colors.black54,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
  ),
  
  iconTheme: const IconThemeData(
    color: Colors.orange,
    size: 24,
  ),
  
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.orange, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.black54),
  ),
);

// Dark Theme
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Colors.orange,
  scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 0, 0, 0),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'TimesNewRoman',
    ),
  ),
  
  cardTheme: CardThemeData(
    color: const Color(0xFF2A2A2A),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Colors.white,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w600,
      fontSize: 22,
    ),
    bodyLarge: TextStyle(
      color: Colors.white,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Colors.white,
      fontFamily: 'TimesNewRoman',
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
  ),
  
  iconTheme: const IconThemeData(
    color: Colors.orange,
    size: 24,
  ),
  
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.orange, width: 2),
    ),
    labelStyle: const TextStyle(color: Color.fromARGB(136, 232, 224, 224)),
  ),
);
