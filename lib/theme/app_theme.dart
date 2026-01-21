import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryBlue = Color(0xFF0f3460);
  static const Color accentBlue = Color(0xFF4A90D9);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF1a1a2e);
  static const Color darkSurface = Color(0xFF16213e);
  static const Color darkCard = Color(0xFF16213e);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      surface: darkSurface,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: darkCard,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.green;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.green.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    dividerColor: Colors.grey.shade700,
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Colors.grey,
      collapsedIconColor: Colors.grey,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      surface: lightSurface,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.green;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.green.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    dividerColor: Colors.grey.shade300,
    listTileTheme: const ListTileThemeData(
      textColor: Colors.black87,
      iconColor: Colors.black87,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Colors.grey,
      collapsedIconColor: Colors.grey,
      textColor: Colors.black87,
      collapsedTextColor: Colors.black87,
    ),
  );
}
