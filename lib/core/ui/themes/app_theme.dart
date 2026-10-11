import 'package:flutter/material.dart';

extension AppColorsExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ─── Base Colors ───
  Color get background => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F2F7);
  Color get success => isDark ? const Color(0xFF5EE38A) : const Color(0xFF15803D); // Mint / Forest Green
  Color get danger => isDark ? const Color(0xFFFF7F7F) : const Color(0xFFD32F2F); // Deep Red
  
  // ─── Cards and Inputs ───
  Color get cardBackground => isDark ? const Color(0xFF111118) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE5E5EA);
  Color get inputBackground => isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7);

  // ─── Text Colors ───
  Color get textPrimary => isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1E);
  Color get textMuted => isDark ? Colors.white54 : Colors.black54;
  Color get textSubtle => isDark ? Colors.white30 : Colors.black38;
  Color get textPrimaryInv => isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0);
  Color get textMutedInv => isDark ? Colors.black54 : Colors.white54;

  // ─── Accents ───
  // Each pairs a bright dark-mode tone with a deeper light-mode tone of the
  // same hue, picked to stay readable (~4.5:1 or better) on white cards.
  Color get repeaterAccent => isDark ? const Color(0xFFE8FF47) : const Color(0xFF5A7F00); // Lime / Olive
  Color get peakLoadAccent => isDark ? Color(0xFFFF6B6B) : Color(0xFFE04343);
  Color get streakAccent => isDark ? const Color(0xFF47C8FF) : const Color(0xFF0077AB); // Deep Blue
  Color get setRestAccent => isDark ? const Color(0xFFB47FFF) : const Color(0xFF6B24D6); // Deep Purple
  Color get swapHandAccent => isDark ? const Color(0xFFEA80FC) : const Color(0xFFA21CAF); // Orchid / Fuchsia
  Color get customAccent => isDark ? const Color(0xFF4FE3C1) : const Color(0xFF0D7F66); // Teal
  Color get warmupAccent => isDark ? const Color(0xFFFFB347) : const Color(0xFFB45309); // Amber

  // Hands 
  Color get rightHandAccent => isDark ? Color(0xFF4FACFE) : Color(0xFF0077B6);
  Color get leftHandAccent => isDark ? Color(0xFFFF7E67) : Color(0xFFE85D04);

  // Cards
  Color get buttonSecondary => isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE5E5EA);
}

class AppTheme {
  
  // ─── Dark Theme Configuration ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // Tell the native Scaffold what to do
      scaffoldBackgroundColor: const Color(0xFF0A0A0F), 
      
      // Tell standard Material widgets what colors to use
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE8FF47), // repeaterAccent
        secondary: Color(0xFFFF6B6B), // peakLoadAccent
        surface: Color(0xFF0A0A0F), // cardBackground
        error: Color(0xFFFF6B6B),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFFF0F0F0), // Matches your Dark textPrimary
        selectionColor: const Color(0xFFF0F0F0).withOpacity(0.3), // Highlighted text color
        selectionHandleColor: const Color(0xFFF0F0F0), // The little teardrop selection handles
      ),
      
      // Globally style native widgets here!
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // ─── Light Theme Configuration ───
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5A7F00), // repeaterAccent
        secondary: Color(0xFFE04343), // peakLoadAccent
        surface: Colors.white, 
        error: Color(0xFFD32F2F),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFF1C1C1E), // Matches your Light textPrimary
        selectionColor: const Color(0xFF1C1C1E).withOpacity(0.2), 
        selectionHandleColor: const Color(0xFF1C1C1E),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}

extension AppTextStylesExt on BuildContext {
  
  TextStyle get h1 => TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    height: 1.1,
    color: textPrimary,
  );

  TextStyle get cardTitle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  TextStyle get overline => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: textMuted,
  );

  TextStyle get body => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  TextStyle get hero => TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.5,
    height: 1.0,
    color: textPrimary,
  );
}
