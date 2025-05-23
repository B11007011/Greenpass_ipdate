import 'package:flutter/material.dart';

// Custom color constants
const _primaryGreen = Color(0xFF4CAF50); // Material Design Green 500
const _lightGreen = Color(0xFF81C784); // Material Design Green 300
const _darkGreen = Color(0xFF388E3C); // Material Design Green 700
const _accentGreen = Color(0xFF66BB6A); // Material Design Green 400
const _surfaceLight = Color(0xFFFFFFFF);
const _backgroundLight = Color(0xFFFAFAFA); // Lighter background
const _surfaceDark = Color(0xFF424242); // Lighter dark surface
const _backgroundDark = Color(0xFFF5F5F5); // Light gray for dark theme

final lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _backgroundLight,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: _primaryGreen,
    onPrimary: Colors.white,
    secondary: _accentGreen,
    onSecondary: Colors.white,
    tertiary: _lightGreen,
    onTertiary: Colors.black87,
    error: Colors.red.shade700,
    onError: Colors.white,
    background: _backgroundLight,
    onBackground: Colors.black87,
    surface: _surfaceLight,
    onSurface: Colors.black87,
    outline: _darkGreen.withOpacity(0.2), // More subtle outline
    surfaceVariant: _lightGreen.withOpacity(
      0.05,
    ), // More subtle surface variant
    onSurfaceVariant: _darkGreen,
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: _primaryGreen,
    foregroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 1, // Reduced elevation
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: _surfaceLight,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1, // Reduced elevation
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  iconTheme: IconThemeData(color: _darkGreen),
  chipTheme: ChipThemeData(
    backgroundColor: _lightGreen.withOpacity(0.05), // More subtle background
    labelStyle: TextStyle(color: _darkGreen),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _backgroundDark,
  colorScheme: ColorScheme(
    brightness: Brightness.light, // Keep light brightness for lighter theme
    primary: _primaryGreen,
    onPrimary: Colors.white,
    secondary: _accentGreen,
    onSecondary: Colors.white,
    tertiary: _lightGreen,
    onTertiary: Colors.black87,
    error: Colors.red.shade700,
    onError: Colors.white,
    background: _backgroundDark,
    onBackground: Colors.black87,
    surface: _surfaceLight,
    onSurface: Colors.black87,
    outline: _darkGreen.withOpacity(0.2),
    surfaceVariant: _lightGreen.withOpacity(0.05),
    onSurfaceVariant: _darkGreen,
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: _primaryGreen,
    foregroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: _surfaceLight,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  iconTheme: IconThemeData(color: _darkGreen),
  chipTheme: ChipThemeData(
    backgroundColor: _lightGreen.withOpacity(0.05),
    labelStyle: TextStyle(color: _darkGreen),
  ),
);
