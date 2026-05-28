import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette — deep navy + electric violet + sakura pink accents
  static const Color backgroundDark = Color(0xFF0B0D17);
  static const Color surfaceDark = Color(0xFF131625);
  static const Color cardDark = Color(0xFF1C1F35);
  static const Color cardElevated = Color(0xFF252943);

  static const Color primaryViolet = Color(0xFF7C5CFC);
  static const Color primaryVioletLight = Color(0xFF9D82FF);
  static const Color accentSakura = Color(0xFFFF6B9D);
  static const Color accentCyan = Color(0xFF4ECDC4);
  static const Color accentGold = Color(0xFFFFD166);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9BA3C7);
  static const Color textMuted = Color(0xFF5A6080);

  static const Color divider = Color(0xFF1E2240);
  static const Color shimmer = Color(0xFF252943);

  // Status Colors
  static const Color statusOngoing = Color(0xFF4ECDC4);
  static const Color statusFinished = Color(0xFF7C5CFC);
  static const Color statusPlanToWatch = Color(0xFFFFD166);
  static const Color statusDropped = Color(0xFFFF6B6B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryViolet,
        secondary: accentSakura,
        tertiary: accentCyan,
        surface: surfaceDark,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryViolet,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryViolet, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontFamily: 'Nunito'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: primaryViolet.withOpacity(0.3),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: textPrimary),
        displayMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: textPrimary, fontSize: 28),
        headlineMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: textPrimary, fontSize: 22),
        headlineSmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: textPrimary, fontSize: 18),
        titleLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: textPrimary, fontSize: 16),
        titleMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: 'Nunito', color: textSecondary, fontSize: 15, height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Nunito', color: textSecondary, fontSize: 13, height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: textPrimary, fontSize: 14, letterSpacing: 0.5),
      ),
    );
  }
}
