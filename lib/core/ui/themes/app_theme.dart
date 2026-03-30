import 'package:flutter/material.dart';

class AppColors {
  // Base App Colors
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF1E1E24);
  static const surfaceHighlight = Color(0xFF2C2C35); // Replaces white.withOpacity(0.05)
  static const textMuted = Colors.white54;

  static const success = Colors.greenAccent;

  // Workout Specific Accents
  // You can tweak these to exactly match your Workout Choice page!
  static const repeaterAccent = Color(0xFFE8FF47);      // Neon Yellow/Lime
  static const peakLoadAccent = Color(0xFFFF6B6B);      // Red
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.peakLoadAccent, // Default primary
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
      ),
    );
  }
}
