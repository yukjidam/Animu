// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

// ── Available themes ──────────────────────────────────────────────────────────

enum AppThemeMode { cosmicDark, sakuraDawn, midnightForest }

extension AppThemeModeX on AppThemeMode {
  String get id {
    switch (this) {
      case AppThemeMode.cosmicDark:
        return 'cosmicDark';
      case AppThemeMode.sakuraDawn:
        return 'sakuraDawn';
      case AppThemeMode.midnightForest:
        return 'midnightForest';
    }
  }

  String get label {
    switch (this) {
      case AppThemeMode.cosmicDark:
        return 'Cosmic Dark';
      case AppThemeMode.sakuraDawn:
        return 'Sakura Dawn';
      case AppThemeMode.midnightForest:
        return 'Midnight Forest';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.cosmicDark:
        return 'Deep navy & electric violet — the default';
      case AppThemeMode.sakuraDawn:
        return 'Warm rose & soft gold on dark plum';
      case AppThemeMode.midnightForest:
        return 'Deep emerald & teal on charcoal';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemeMode.cosmicDark:
        return '🌌';
      case AppThemeMode.sakuraDawn:
        return '🌸';
      case AppThemeMode.midnightForest:
        return '🌿';
    }
  }

  List<Color> get previewGradient {
    switch (this) {
      case AppThemeMode.cosmicDark:
        return [const Color(0xFF7C5CFC), const Color(0xFFFF6B9D)];
      case AppThemeMode.sakuraDawn:
        return [const Color(0xFFE8629A), const Color(0xFFFFB347)];
      case AppThemeMode.midnightForest:
        return [const Color(0xFF2ECC71), const Color(0xFF1ABC9C)];
    }
  }

  static AppThemeMode fromId(String? id) {
    return AppThemeMode.values.firstWhere(
      (t) => t.id == id,
      orElse: () => AppThemeMode.cosmicDark,
    );
  }
}

// ── AppThemeTokens ────────────────────────────────────────────────────────────

class AppThemeTokens {
  final Color backgroundDark;
  final Color surfaceDark;
  final Color cardDark;
  final Color cardElevated;
  final Color divider;
  final Color primaryViolet;
  final Color primaryVioletLight;
  final Color accentSakura;
  final Color accentCyan;

  const AppThemeTokens({
    required this.backgroundDark,
    required this.surfaceDark,
    required this.cardDark,
    required this.cardElevated,
    required this.divider,
    required this.primaryViolet,
    required this.primaryVioletLight,
    required this.accentSakura,
    required this.accentCyan,
  });
}

// ── AppTheme ──────────────────────────────────────────────────────────────────

class AppTheme {
  // ── Theme-independent constants (never change) ────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9BA3C7);
  static const Color textMuted = Color(0xFF5A6080);
  static const Color accentGold = Color(0xFFFFD166);
  static const Color shimmer = Color(0xFF252943);
  static const Color statusOngoing = Color(0xFF4ECDC4);
  static const Color statusFinished = Color(0xFF7C5CFC);
  static const Color statusPlanToWatch = Color(0xFFFFD166);
  static const Color statusDropped = Color(0xFFFF6B6B);

  // ── Token bundles per theme ───────────────────────────────────────────────
  static AppThemeTokens tokensFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.cosmicDark:
        return const AppThemeTokens(
          backgroundDark: Color(0xFF0B0D17),
          surfaceDark: Color(0xFF131625),
          cardDark: Color(0xFF1C1F35),
          cardElevated: Color(0xFF252943),
          divider: Color(0xFF1E2240),
          primaryViolet: Color(0xFF7C5CFC),
          primaryVioletLight: Color(0xFF9D82FF),
          accentSakura: Color(0xFFFF6B9D),
          accentCyan: Color(0xFF4ECDC4),
        );
      case AppThemeMode.sakuraDawn:
        return const AppThemeTokens(
          backgroundDark: Color(0xFF16090F),
          surfaceDark: Color(0xFF221018),
          cardDark: Color(0xFF2E1520),
          cardElevated: Color(0xFF3A1D2A),
          divider: Color(0xFF3D1E2C),
          primaryViolet: Color(0xFFE8629A),
          primaryVioletLight: Color(0xFFF28CB8),
          accentSakura: Color(0xFFFFB347),
          accentCyan: Color(0xFFFF8C69),
        );
      case AppThemeMode.midnightForest:
        return const AppThemeTokens(
          backgroundDark: Color(0xFF080F0C),
          surfaceDark: Color(0xFF0D1A14),
          cardDark: Color(0xFF132419),
          cardElevated: Color(0xFF1A3024),
          divider: Color(0xFF1C3022),
          primaryViolet: Color(0xFF2ECC71),
          primaryVioletLight: Color(0xFF58D68D),
          accentSakura: Color(0xFF1ABC9C),
          accentCyan: Color(0xFF48C9B0),
        );
    }
  }

  // ── Context-aware accessor ────────────────────────────────────────────────
  // Use this in build() methods: final t = AppTheme.of(context);
  // Then: t.cardDark, t.primaryViolet, etc.
  static AppThemeTokens of(BuildContext context) =>
      context.watch<ThemeNotifier>().tokens;

  // ── ThemeData factory ─────────────────────────────────────────────────────
  static ThemeData themeDataFor(AppThemeMode mode) {
    final t = tokensFor(mode);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: t.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: t.primaryViolet,
        secondary: t.accentSakura,
        tertiary: t.accentCyan,
        surface: t.surfaceDark,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      fontFamily: 'Nunito',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surfaceDark,
        selectedItemColor: t.primaryViolet,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primaryViolet, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontFamily: 'Nunito'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.cardDark,
        selectedColor: t.primaryViolet.withOpacity(0.3),
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
        displayLarge: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 22,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 16,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Nunito',
          color: textSecondary,
          fontSize: 15,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Nunito',
          color: textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Backwards-compatible const statics (Cosmic Dark) ─────────────────────
  // These exist so existing widget code compiles without changes.
  // To make a widget theme-aware, replace AppTheme.cardDark with
  // AppTheme.of(context).cardDark inside its build() method.
  static const Color backgroundDark = Color(0xFF0B0D17);
  static const Color surfaceDark = Color(0xFF131625);
  static const Color cardDark = Color(0xFF1C1F35);
  static const Color cardElevated = Color(0xFF252943);
  static const Color divider = Color(0xFF1E2240);
  static const Color primaryViolet = Color(0xFF7C5CFC);
  static const Color primaryVioletLight = Color(0xFF9D82FF);
  static const Color accentSakura = Color(0xFFFF6B9D);
  static const Color accentCyan = Color(0xFF4ECDC4);

  static ThemeData get darkTheme => themeDataFor(AppThemeMode.cosmicDark);
}

// ── Themed wrapper widget ─────────────────────────────────────────────────────
// Wrap any widget that needs live theme colors with T (short for Themed).
// Inside builder you get the current AppThemeTokens as `t`.
//
// Usage:
//   T(builder: (context, t) => Container(color: t.cardDark, ...))
//
class T extends StatelessWidget {
  final Widget Function(BuildContext context, AppThemeTokens t) builder;
  const T({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return builder(context, t);
  }
}
