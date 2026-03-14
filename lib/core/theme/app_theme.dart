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
    scaffoldBackgroundColor: const Color(0xFF0E0E1A),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: Color(0xFF0E0E1A),
      surfaceContainerHighest: Color(0xFF1C1C26),
      onSurface: Color(0xFFF4F4FF),
      onSurfaceVariant: Color(0xFF6B7280),
      error: AppColors.error,
    ),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      const Color(0xFFF4F4FF),
      const Color(0xFF6B7280),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF4F4FF),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF6B7280),
        fontSize: 14,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      thickness: 0.5,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFF0E0E1A).withValues(alpha: 0.92),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF13131A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.20),
      side: BorderSide(
        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
        width: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF4F4FF),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return const Color(0xFF6B7280);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF6366F1);
        }
        return Colors.white.withValues(alpha: 0.10);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1C26),
      contentTextStyle: GoogleFonts.inter(
        color: const Color(0xFFF4F4FF),
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F7FF),
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: Color(0xFFF8F7FF),
      surfaceContainerHighest: Color(0xFFF0EFFF),
      onSurface: Color(0xFF1E1E2E),
      onSurfaceVariant: Color(0xFF6B7280),
      error: AppColors.error,
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      const Color(0xFF1E1E2E),
      const Color(0xFF6B7280),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E2E),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.75),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF6B7280),
        fontSize: 14,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withValues(alpha: 0.06),
      thickness: 0.5,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFF8F7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.60),
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
      side: BorderSide(
        color: const Color(0xFF6366F1).withValues(alpha: 0.10),
        width: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E1E2E),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return const Color(0xFF6B7280);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF6366F1);
        }
        return Colors.black.withValues(alpha: 0.10);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      contentTextStyle: GoogleFonts.inter(
        color: const Color(0xFF1E1E2E),
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
