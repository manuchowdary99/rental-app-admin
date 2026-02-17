import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF781C2E); // Burgundy
  static const Color primaryDeep = Color(0xFF8B2635);
  static const Color primaryBold = Color(0xFF9E2F3C);
  static const Color primaryAccent = Color(0xFFB13843);
  static const Color creamBackground = Color(0xFFF9F6EE);
  static const Color darkSurface = Color(0xFF1E1417);
  static const Color darkBackground = Color(0xFF140A0D);

  // =========================
  // LIGHT THEME
  // =========================
  static ColorScheme get _lightColorScheme {
    final base = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return base.copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: primaryDeep,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF3B1E24),
      surfaceContainerHighest: const Color(0xFFFAEFE8),
      onSurfaceVariant: const Color(0xFF4A2026),
      tertiary: primaryBold,
      onTertiary: Colors.white,
      error: primaryAccent,
      onError: Colors.white,
      outline: const Color(0xFFDFC8C8),
      inversePrimary: primaryBold,
    );
  }

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: creamBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: primaryColor.withOpacity(0.12),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: creamBackground,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shadowColor: primaryColor.withOpacity(0.25),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5D7D7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
    ),
  );

  // =========================
  // DARK THEME
  // =========================
  static ColorScheme get _darkColorScheme {
    final base = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      primary: primaryAccent,
      onPrimary: Colors.white,
      secondary: primaryDeep,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF231217),
      onSurfaceVariant: const Color(0xFFEBD4D6),
      tertiary: const Color(0xFFCF5B64),
      onTertiary: Colors.white,
      error: const Color(0xFFFF6B6B),
      onError: Colors.black,
      outline: const Color(0xFF4A2026),
      inversePrimary: primaryColor,
    );
  }

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: _darkColorScheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.black.withOpacity(0.4),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: darkSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF24151A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3C1D22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryAccent, width: 1.4),
      ),
    ),
  );
}
