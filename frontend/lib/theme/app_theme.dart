import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Theme Manager pour Light & Dark Mode
class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBlueLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentPink,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentPink,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.accentPurple,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error,
      onErrorContainer: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.greyLight900,
      surfaceContainerHighest: AppColors.greyLight100,
      onSurfaceVariant: AppColors.greyLight700,
      outline: AppColors.greyLight400,
      shadow: Colors.black12,
      scrim: Colors.black87,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    canvasColor: AppColors.lightBackground,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.headlineSmall.copyWith(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.greyLight500,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.greyLight100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyLight300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyLight300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.greyLight700,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.greyLight200,
      thickness: 1,
      space: 1,
    ),

    // Text Styles
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.greyLight900,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.greyLight900,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(
        color: AppColors.greyLight900,
      ),
      headlineLarge: AppTypography.headlineLarge.copyWith(
        color: AppColors.greyLight900,
      ),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: AppColors.greyLight900,
      ),
      headlineSmall: AppTypography.headlineSmall.copyWith(
        color: AppColors.greyLight900,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(
        color: AppColors.greyLight900,
      ),
      titleMedium: AppTypography.titleMedium.copyWith(
        color: AppColors.greyLight900,
      ),
      titleSmall: AppTypography.titleSmall.copyWith(
        color: AppColors.greyLight900,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: AppColors.greyLight800,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.greyLight700,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(
        color: AppColors.greyLight600,
      ),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: AppColors.greyLight900,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: AppColors.greyLight700,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: AppColors.greyLight600,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryBlueLight,
      onPrimary: AppColors.darkSurface,
      primaryContainer: AppColors.primaryBlue,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentPink,
      onSecondary: AppColors.darkSurface,
      secondaryContainer: AppColors.accentPink.withAlpha(80),
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.accentPurple,
      onTertiary: AppColors.darkSurface,
      error: AppColors.error,
      onError: AppColors.darkSurface,
      errorContainer: AppColors.error,
      onErrorContainer: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.greyDark900,
      surfaceContainerHighest: AppColors.greyDark200,
      onSurfaceVariant: AppColors.greyDark800,
      outline: AppColors.greyDark600,
      shadow: Colors.black54,
      scrim: Colors.black87,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    canvasColor: AppColors.darkBackground,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBlueDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.headlineSmall.copyWith(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.greyDark200, width: 1),
      ),
    ),

    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryBlueLight,
      unselectedItemColor: AppColors.greyDark600,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlueLight,
        foregroundColor: AppColors.darkSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlueLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.greyDark200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyDark300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyDark300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primaryBlueLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.greyDark700,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.greyDark200,
      thickness: 1,
      space: 1,
    ),

    // Text Styles
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.greyDark900,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.greyDark900,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(
        color: AppColors.greyDark900,
      ),
      headlineLarge: AppTypography.headlineLarge.copyWith(
        color: AppColors.greyDark900,
      ),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: AppColors.greyDark900,
      ),
      headlineSmall: AppTypography.headlineSmall.copyWith(
        color: AppColors.greyDark900,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(
        color: AppColors.greyDark900,
      ),
      titleMedium: AppTypography.titleMedium.copyWith(
        color: AppColors.greyDark900,
      ),
      titleSmall: AppTypography.titleSmall.copyWith(
        color: AppColors.greyDark900,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.greyDark800),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.greyDark700,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.greyDark600),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: AppColors.greyDark900,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: AppColors.greyDark700,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: AppColors.greyDark600,
      ),
    ),
  );
}
