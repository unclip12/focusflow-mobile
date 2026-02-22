import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge:  GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      titleLarge:    GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
    );
  }

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: AppColors.darkSurface,
      error: AppColors.error,
    ),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      Colors.white,
      const Color(0xFFAEAEB2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      const Color(0xFF1C1C1E),
      const Color(0xFF8E8E93),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}
