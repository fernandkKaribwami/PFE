import 'package:flutter/material.dart';

/// Palette de couleurs centralisée pour USMBA Social
/// Inspirée par le design moderne avec accent bleu universitaire
class AppColors {
  // Couleurs primaires
  static const Color primaryBlue = Color(0xFF003366); // Bleu USMBA
  static const Color primaryBlueDark = Color(0xFF001F47);
  static const Color primaryBlueLight = Color(0xFF0052A3);

  // Couleurs d'accent
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);

  // Couleurs grises (Light Mode)
  static const Color greyLight50 = Color(0xFFFAFAFA);
  static const Color greyLight100 = Color(0xFFF5F5F5);
  static const Color greyLight200 = Color(0xFFEEEEEE);
  static const Color greyLight300 = Color(0xFFE0E0E0);
  static const Color greyLight400 = Color(0xFFBDBDBD);
  static const Color greyLight500 = Color(0xFF9E9E9E);
  static const Color greyLight600 = Color(0xFF757575);
  static const Color greyLight700 = Color(0xFF616161);
  static const Color greyLight800 = Color(0xFF424242);
  static const Color greyLight900 = Color(0xFF212121);

  // Couleurs grises (Dark Mode)
  static const Color greyDark50 = Color(0xFF121212);
  static const Color greyDark100 = Color(0xFF1E1E1E);
  static const Color greyDark200 = Color(0xFF2C2C2C);
  static const Color greyDark300 = Color(0xFF3D3D3D);
  static const Color greyDark400 = Color(0xFF4F4F4F);
  static const Color greyDark500 = Color(0xFF616161);
  static const Color greyDark600 = Color(0xFF757575);
  static const Color greyDark700 = Color(0xFF9E9E9E);
  static const Color greyDark800 = Color(0xFFBDBDBD);
  static const Color greyDark900 = Color(0xFFEEEEEE);

  // Couleurs sémantiques
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Light Theme specific
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF212121);

  // Dark Theme specific
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFEEEEEE);

  // Primary color (used in theme)
  static const Color primary = primaryBlue;
