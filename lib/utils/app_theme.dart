import 'package:flutter/material.dart';

/// Centralized palette for the app. Use these instead of raw Color(0x...).
abstract final class AppColors {
  AppColors._();

  /// Primary warm brown (buttons, accents, selected states).
  static const Color primary = Color(0xFF8B7355);

  /// Scaffold and main background (warm off-white).
  static const Color scaffoldBackground = Color(0xFFFAF8F5);

  /// Dark text (headings, titles).
  static const Color textDark = Color(0xFF2C2416);

  /// Body text.
  static const Color bodyText = Color(0xFF3D3426);

  /// Default border (chips, inputs, panels).
  static const Color border = Color(0xFFD4C4B0);

  /// Landing screen background (light yellow).
  static const Color landingBackground = Color(0xFFEADCC4);

  /// Card/panel background (beige).
  static const Color cardBeige = Color(0xFFF4ECDD);

  /// Light border (landing cards, subtle dividers).
  static const Color borderLight = Color(0xFFE8E4DC);

  /// Wrong answer / error accent (quiz).
  static const Color wrong = Color(0xFFB57373);

  /// Muted brown (secondary text in panels).
  static const Color mutedBrown = Color(0xFF5C4A3A);

  /// Dark brown (e.g. snackbar background).
  static const Color darkBrown = Color(0xFF6B4A4A);

  /// Commentary panel background.
  static const Color commentaryBg = Color(0xFFEDF0E8);

  /// Commentary panel border.
  static const Color commentaryBorder = Color(0xFFA3B09A);

  /// Commentary panel header.
  static const Color commentaryHeader = Color(0xFF7A8B72);
}

abstract final class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Lora',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Lora',
          fontSize: 16,
          height: 1.8,
          color: AppColors.bodyText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Lora',
          fontSize: 14,
          height: 1.7,
          color: AppColors.bodyText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

abstract final class AppSurfaceColors {
  AppSurfaceColors._();

  static Color landingBackground(BuildContext context) =>
      AppColors.landingBackground;

  static Color cardBackground(BuildContext context) =>
      AppColors.cardBeige;

  static Color borderLight(BuildContext context) =>
      AppColors.borderLight;

  static Color textDark(BuildContext context) => AppColors.textDark;
}
