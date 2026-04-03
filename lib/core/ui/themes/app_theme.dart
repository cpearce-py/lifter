import 'package:flutter/material.dart';

class AppColors {
  // Base App Colors
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF1E1E24);
  static const surfaceHighlight = Color(0xFF2C2C35); // Replaces white.withOpacity(0.05)

  // State
  static const success = Colors.greenAccent;
  static const danger = Color(0xFFFF6B6B);
  
  // Cards and Inputs
  static const cardBackground = Color(0xFF111118); 
  static const cardBorder = Color(0xFF1E1E2A);     
  static const inputBackground = Color(0xFF1E1E2A);

  // Text Colors
  static const textPrimary = Color(0xFFF0F0F0);
  static const textMuted = Colors.white54;
  static const textSubtle = Colors.white30; // For placeholder text

  // Workout Specific Accents
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

class AppTextStyles {
  // Large Page Headers (e.g., "Your Data")
  static const h1 = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  // Card Titles (e.g., "Body Weight", "Measurement Unit")
  static const cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Small tracking labels (e.g., "PROFILE")
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: AppColors.textMuted,
  );

  // Standard Body Text
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
