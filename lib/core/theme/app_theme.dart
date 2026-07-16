import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF8C2C4E); // Elegant burgundy
  static const Color secondaryColor = Color(0xFFD48194); // Blush pink
  static const Color accentColor = Color(0xFFEAA0A2); // Light pastel rose
  static const Color backgroundColor = Color(
    0xFFFAF7F2,
  ); // Warm cream background
  static const Color cardColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF2B2526); // Soft charcoal
  static const Color textSecondaryColor = Color(0xFF756869); // Muted gray-brown

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
        labelLarge: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
