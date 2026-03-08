import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB58863),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFBF8),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF4B2E2B),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
