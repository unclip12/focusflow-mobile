// =============================================================
// AppTheme — 12 themes + 6 accent colors
// Called by app.dart: AppTheme.getTheme(themeId, isDarkMode, accentKey, fontSize)
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Accent Color Palette (6 options) ────────────────────────────
class AccentColors {
  AccentColors._();

  static const Map<String, Color> palette = {
    'indigo':  Color(0xFF4F46E5),
    'emerald': Color(0xFF10B981),
    'rose':    Color(0xFFF43F5E),
    'amber':   Color(0xFFF59E0B),
    'sky':     Color(0xFF0EA5E9),
    'violet':  Color(0xFF8B5CF6),
  };

  static Color get(String key) => palette[key] ?? palette['indigo']!;
}

// ── Per-theme color definition ──────────────────────────────────
class _ThemeDef {
  final String id;
  final String name;
  // Light mode
  final Color lightBg;
  final Color lightSurface;
  // Dark mode
  final Color darkBg;
  final Color darkSurface;

  const _ThemeDef({
    required this.id,
    required this.name,
    required this.lightBg,
    required this.lightSurface,
    required this.darkBg,
    required this.darkSurface,
  });
}

// ── 12 Theme Definitions ────────────────────────────────────────
const _themes = <_ThemeDef>[
  _ThemeDef(
    id: 'default', name: 'Flow White',
    lightBg: Color(0xFFF1F5F9), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF0F172A), darkSurface: Color(0xFF1E293B),
  ),
  _ThemeDef(
    id: 'midnight', name: 'Midnight Deep',
    lightBg: Color(0xFFCBD5E1), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF020617), darkSurface: Color(0xFF0F172A),
  ),
  _ThemeDef(
    id: 'forest', name: 'Mystic Forest',
    lightBg: Color(0xFFF0FFF5), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF022C22), darkSurface: Color(0xFF064E3B),
  ),
  _ThemeDef(
    id: 'ocean', name: 'Deep Ocean',
    lightBg: Color(0xFFF0F8FF), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF172554), darkSurface: Color(0xFF1E3A8A),
  ),
  _ThemeDef(
    id: 'sunset', name: 'Pastel Sunset',
    lightBg: Color(0xFFFAF0F5), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF1E1428), darkSurface: Color(0xFF2D1E3C),
  ),
  _ThemeDef(
    id: 'rose', name: 'Soft Lilac',
    lightBg: Color(0xFFFAF0FA), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF230F28), darkSurface: Color(0xFF321E3C),
  ),
  _ThemeDef(
    id: 'slate', name: 'Cloudy Sky',
    lightBg: Color(0xFFF8FAFC), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF1F2937), darkSurface: Color(0xFF374151),
  ),
  _ThemeDef(
    id: 'amber', name: 'Citrus Burst',
    lightBg: Color(0xFFFFFAF0), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF281900), darkSurface: Color(0xFF3C2814),
  ),
  _ThemeDef(
    id: 'violet', name: 'Royal Violet',
    lightBg: Color(0xFFFAF5FF), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF140A1E), darkSurface: Color(0xFF28143C),
  ),
  _ThemeDef(
    id: 'teal', name: 'Fresh Mint',
    lightBg: Color(0xFFEBFAFA), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF0A2323), darkSurface: Color(0xFF14322D),
  ),
  _ThemeDef(
    id: 'crimson', name: 'Warm Peach',
    lightBg: Color(0xFFFFF5F5), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF280F0F), darkSurface: Color(0xFF3C1E1E),
  ),
  _ThemeDef(
    id: 'mint', name: 'Night Sky',
    lightBg: Color(0xFFF0F8FF), lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF020024), darkSurface: Color(0xFF111827),
  ),
];

// ── Font Size Scale ─────────────────────────────────────────────
double _fontScale(String fontSize) {
  switch (fontSize) {
    case 'small':  return 0.9;
    case 'large':  return 1.1;
    default:       return 1.0;
  }
}

// ── Main Theme Builder ──────────────────────────────────────────
class AppTheme {
  AppTheme._();

  /// Build a full ThemeData for the given settings.
  /// [themeId]   — one of the 12 theme IDs
  /// [isDark]    — dark mode toggle
  /// [accentKey] — one of 6 accent keys (indigo, emerald, rose, amber, sky, violet)
  /// [fontSize]  — 'small' | 'medium' | 'large'
  static ThemeData getTheme(
    String themeId,
    bool isDark,
    String accentKey,
    String fontSize,
  ) {
    final def = _themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => _themes.first,
    );

    final accent = AccentColors.get(accentKey);
    final scale = _fontScale(fontSize);
    final bg = isDark ? def.darkBg : def.lightBg;
    final surface = isDark ? def.darkSurface : def.lightSurface;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final primaryText = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryText =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93);
    final border =
        isDark ? const Color(0xFF2A2A38) : const Color(0xFFE5E5EA);

    final baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    const radius = 12.0;

    final textTheme = GoogleFonts.interTextTheme(baseText).copyWith(
      displayLarge:  GoogleFonts.inter(fontSize: 32 * scale, fontWeight: FontWeight.w800, color: primaryText),
      displayMedium: GoogleFonts.inter(fontSize: 28 * scale, fontWeight: FontWeight.w700, color: primaryText),
      displaySmall:  GoogleFonts.inter(fontSize: 24 * scale, fontWeight: FontWeight.w700, color: primaryText),
      headlineLarge: GoogleFonts.inter(fontSize: 22 * scale, fontWeight: FontWeight.w700, color: primaryText),
      headlineMedium:GoogleFonts.inter(fontSize: 20 * scale, fontWeight: FontWeight.w600, color: primaryText),
      headlineSmall: GoogleFonts.inter(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: primaryText),
      titleLarge:    GoogleFonts.inter(fontSize: 20 * scale, fontWeight: FontWeight.w600, color: primaryText),
      titleMedium:   GoogleFonts.inter(fontSize: 16 * scale, fontWeight: FontWeight.w600, color: primaryText),
      titleSmall:    GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w600, color: primaryText),
      bodyLarge:     GoogleFonts.inter(fontSize: 16 * scale, fontWeight: FontWeight.w400, color: primaryText),
      bodyMedium:    GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w400, color: secondaryText),
      bodySmall:     GoogleFonts.inter(fontSize: 12 * scale, fontWeight: FontWeight.w400, color: secondaryText),
      labelLarge:    GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w600, color: primaryText),
      labelMedium:   GoogleFonts.inter(fontSize: 12 * scale, fontWeight: FontWeight.w500, color: primaryText),
      labelSmall:    GoogleFonts.inter(fontSize: 11 * scale, fontWeight: FontWeight.w500, color: secondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent.withValues(alpha: 0.7),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: primaryText,
        error: const Color(0xFFF87171),
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20 * scale, fontWeight: FontWeight.w700, color: primaryText,
        ),
        iconTheme: IconThemeData(color: primaryText),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: GoogleFonts.inter(fontSize: 13 * scale, color: primaryText),
        side: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surface.withValues(alpha: 0.6) : const Color(0xFFF8F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 8)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 4)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18 * scale, fontWeight: FontWeight.w700, color: primaryText,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14 * scale, fontWeight: FontWeight.w400, color: secondaryText,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14 * scale, fontWeight: FontWeight.w500, color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        elevation: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
          textStyle: GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.inter(fontSize: 14 * scale, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent.withValues(alpha: 0.35) : null),
      ),
    );
  }

  /// List of all available theme IDs.
  static List<String> get themeIds => _themes.map((t) => t.id).toList();

  /// Get the display name for a theme.
  static String themeName(String themeId) =>
      _themes.firstWhere((t) => t.id == themeId, orElse: () => _themes.first).name;

  /// List of all accent color keys.
  static List<String> get accentKeys => AccentColors.palette.keys.toList();
}
