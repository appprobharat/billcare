import 'package:flutter/material.dart';

final ThemeData blueGoldTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF1E3A8A), 

  scaffoldBackgroundColor: const Color(0xFFFDFCF9),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E3A8A),
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),

  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: const Color(0xFF1E3A8A), 
    secondary: const Color(0xFF1E3A8A),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    surface: const Color(0xFFEDEDED),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF1E3A8A),
    foregroundColor: Colors.white,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E3A8A), 
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A)),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF6F6F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1E3A8A)), 
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
  ),

  iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),

  dividerColor: Colors.grey.shade300,
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
  ),
);
