import 'package:flutter/material.dart';

final ThemeData blueGoldTheme = ThemeData(
  brightness: Brightness.light,

  // =========================
  // FONT
  // =========================
  fontFamily: 'Inter',

  primaryColor: const Color(0xFF1E3A8A),

  scaffoldBackgroundColor: const Color(0xFFFDFCF9),

  // =========================
  // APP BAR
  // =========================
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E3A8A),
    foregroundColor: Colors.white,
    elevation: 2,

    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  // =========================
  // COLOR SCHEME
  // =========================
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: const Color(0xFF1E3A8A),
    secondary: const Color(0xFF1E3A8A),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    surface: const Color(0xFFEDEDED),
  ),

  // =========================
  // FAB
  // =========================
  floatingActionButtonTheme:
      const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF1E3A8A),
    foregroundColor: Colors.white,
  ),

  // =========================
  // ELEVATED BUTTON
  // =========================
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,

      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
    ),
  ),

  // =========================
  // TEXT BUTTON
  // =========================
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF1E3A8A),

      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // =========================
  // INPUT
  // =========================
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF6F6F6),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFF1E3A8A),
      ),
    ),

    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFF1E3A8A),
        width: 2,
      ),
    ),

    labelStyle: const TextStyle(
      fontFamily: 'Inter',
      color: Color(0xFF1E3A8A),
    ),
  ),

  // =========================
  // ICON
  // =========================
  iconTheme: const IconThemeData(
    color: Color(0xFF1E3A8A),
  ),

  dividerColor: Colors.grey.shade300,

  // =========================
  // DROPDOWN
  // =========================
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      padding: WidgetStateProperty.all(
        EdgeInsets.zero,
      ),
    ),
  ),
);