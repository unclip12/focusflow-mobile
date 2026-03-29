// =============================================================
// AppTheme - shared theme presets for the full app
// Theme preset now drives both accent colors and light/dark surfaces.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/utils/app_colors.dart';

class AccentColors {
  AccentColors._();

  static const Map<String, Color> palette = {
    'indigo': Color(0xFF4F46E5),
    'emerald': Color(0xFF10B981),
    'rose': Color(0xFFF43F5E),
    'amber': Color(0xFFF59E0B),
    'sky': Color(0xFF0EA5E9),
    'violet': Color(0xFF8B5CF6),
  };

  static Color get(String key) => palette[key] ?? palette['indigo']!;
}

class ThemePreset {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color lightBg;
  final Color lightSurface;
  final Color darkBg;
  final Color darkSurface;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.lightBg,
    required this.lightSurface,
    required this.darkBg,
    required this.darkSurface,
  });

  Color previewBackground(bool isDark) => isDark ? darkBg : lightBg;
}

const List<ThemePreset> _themePresets = <ThemePreset>[
  ThemePreset(
    id: 'default',
    name: 'Indigo',
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF818CF8),
    lightBg: Color(0xFFF4F6FB),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF16171F),
    darkSurface: Color(0xFF21222D),
  ),
  ThemePreset(
    id: 'violet',
    name: 'Violet',
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFFA78BFA),
    lightBg: Color(0xFFF8F4FF),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF18142A),
    darkSurface: Color(0xFF231E36),
  ),
  ThemePreset(
    id: 'rose',
    name: 'Rose',
    primary: Color(0xFFF43F5E),
    secondary: Color(0xFFFB7185),
    lightBg: Color(0xFFFFF1F4),
    lightSurface: Color(0xFFFFFBFC),
    darkBg: Color(0xFF241216),
    darkSurface: Color(0xFF301B21),
  ),
  ThemePreset(
    id: 'emerald',
    name: 'Emerald',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    lightBg: Color(0xFFF0FAF4),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF141C18),
    darkSurface: Color(0xFF1E2B22),
  ),
  ThemePreset(
    id: 'amber',
    name: 'Amber',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFFBBF24),
    lightBg: Color(0xFFFDF8F0),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF1E1910),
    darkSurface: Color(0xFF2A2318),
  ),
  ThemePreset(
    id: 'cyan',
    name: 'Cyan',
    primary: Color(0xFF06B6D4),
    secondary: Color(0xFF22D3EE),
    lightBg: Color(0xFFF0F6FF),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF141820),
    darkSurface: Color(0xFF1E2430),
  ),
  ThemePreset(
    id: 'pink',
    name: 'Pink',
    primary: Color(0xFFEC4899),
    secondary: Color(0xFFF472B6),
    lightBg: Color(0xFFFAF2F6),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF1E161C),
    darkSurface: Color(0xFF2A1F26),
  ),
  ThemePreset(
    id: 'orange',
    name: 'Orange',
    primary: Color(0xFFF97316),
    secondary: Color(0xFFFB923C),
    lightBg: Color(0xFFFFF4F2),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF1E1414),
    darkSurface: Color(0xFF2C1E1E),
  ),
  ThemePreset(
    id: 'teal',
    name: 'Teal',
    primary: Color(0xFF14B8A6),
    secondary: Color(0xFF2DD4BF),
    lightBg: Color(0xFFEEFAF8),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF121D1C),
    darkSurface: Color(0xFF1A2A28),
  ),
  ThemePreset(
    id: 'blue',
    name: 'Blue',
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF60A5FA),
    lightBg: Color(0xFFF0F4FF),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF12131E),
    darkSurface: Color(0xFF1C1E2C),
  ),
  ThemePreset(
    id: 'lime',
    name: 'Lime',
    primary: Color(0xFF84CC16),
    secondary: Color(0xFFA3E635),
    lightBg: Color(0xFFF7FBEE),
    lightSurface: Color(0xFFFFFEFA),
    darkBg: Color(0xFF171D11),
    darkSurface: Color(0xFF222B18),
  ),
  ThemePreset(
    id: 'slate',
    name: 'Slate',
    primary: Color(0xFF64748B),
    secondary: Color(0xFF94A3B8),
    lightBg: Color(0xFFF6F8FC),
    lightSurface: Color(0xFFFFFFFF),
    darkBg: Color(0xFF171A20),
    darkSurface: Color(0xFF20242C),
  ),
];

double _fontScale(String fontSize) {
  switch (fontSize) {
    case 'small':
      return 0.9;
    case 'large':
      return 1.1;
    default:
      return 1.0;
  }
}

class AppTheme {
  AppTheme._();

  static const Color _lightInputFillColor = Color(0xFFE8E8ED);
  static const Map<String, String> _themeAliases = {
    'midnight': 'slate',
    'forest': 'emerald',
    'ocean': 'cyan',
    'sunset': 'pink',
    'crimson': 'orange',
    'mint': 'blue',
    'milky': 'lime',
  };

  static const Map<String, String> _accentFallbackTheme = {
    'indigo': 'default',
    'emerald': 'emerald',
    'rose': 'rose',
    'amber': 'amber',
    'sky': 'cyan',
    'violet': 'violet',
  };

  static List<ThemePreset> get themePresets => List<ThemePreset>.unmodifiable(
        _themePresets,
      );

  static String _resolveThemeId(String themeId, String accentKey) {
    if (_themeAliases.containsKey(themeId)) {
      return _themeAliases[themeId]!;
    }

    final matchesPreset = _themePresets.any((preset) => preset.id == themeId);
    if (matchesPreset) {
      return themeId;
    }

    return _accentFallbackTheme[accentKey] ?? _themePresets.first.id;
  }

  static ThemePreset resolveThemePreset(String themeId, [String accentKey = 'indigo']) {
    final resolvedId = _resolveThemeId(themeId, accentKey);
    return _themePresets.firstWhere(
      (preset) => preset.id == resolvedId,
      orElse: () => _themePresets.first,
    );
  }

  static ThemeData lightTheme(
    String themeId,
    String accentKey,
    String fontSize,
  ) {
    return _buildTheme(themeId, false, accentKey, fontSize);
  }

  static ThemeData darkTheme(
    String themeId,
    String accentKey,
    String fontSize,
  ) {
    return _buildTheme(themeId, true, accentKey, fontSize);
  }

  static ThemeData getTheme(
    String themeId,
    bool isDark,
    String accentKey,
    String fontSize,
  ) {
    return _buildTheme(themeId, isDark, accentKey, fontSize);
  }

  static ThemeData _buildTheme(
    String themeId,
    bool isDark,
    String accentKey,
    String fontSize,
  ) {
    final preset = resolveThemePreset(themeId, accentKey);
    final scale = _fontScale(fontSize);
    final bg = isDark ? preset.darkBg : preset.lightBg;
    final surface = isDark ? preset.darkSurface : preset.lightSurface;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    DashboardColors.applyThemeValues(
      primary: preset.primary,
      secondary: preset.secondary,
      lightBackground: preset.lightBg,
      lightSurface: preset.lightSurface,
      darkBackground: preset.darkBg,
      darkSurface: preset.darkSurface,
    );

    final primaryText = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryText =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93);
    final border = isDark ? const Color(0xFF2E2F3D) : const Color(0xFFE8EAF0);

    final baseText =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    const radius = 12.0;

    final textTheme = baseText
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 32 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: primaryText,
          ),
          displayMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 28 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: primaryText,
          ),
          displaySmall: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: primaryText,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 22 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: primaryText,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: primaryText,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: primaryText,
          ),
          titleLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: primaryText,
          ),
          titleMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: primaryText,
          ),
          titleSmall: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: primaryText,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            color: primaryText,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 13 * scale,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            color: secondaryText,
          ),
          bodySmall: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12 * scale,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: secondaryText,
          ),
          labelLarge: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 13 * scale,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: primaryText,
          ),
          labelMedium: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: primaryText,
          ),
          labelSmall: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 11 * scale,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: secondaryText,
          ),
        )
        .apply(fontFamily: 'SF Pro Display');

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: preset.primary,
            secondary: preset.secondary,
            surface: surface,
            surfaceContainerHighest: surface.withValues(alpha: 0.92),
            onSurface: primaryText,
            onSurfaceVariant: secondaryText,
            error: const Color(0xFFF87171),
          )
        : ColorScheme.light(
            primary: preset.primary,
            secondary: preset.secondary,
            surface: surface,
            surfaceContainerHighest: surface.withValues(alpha: 0.92),
            onSurface: primaryText,
            onSurfaceVariant: secondaryText,
            error: const Color(0xFFF87171),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: border,
      disabledColor: secondaryText.withValues(alpha: 0.55),
      fontFamily: 'SF Pro Display',
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.3,
          fontSize: 20 * scale,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
        iconTheme: IconThemeData(color: primaryText),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor:
            isDark ? Colors.transparent : preset.primary.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
          side:
              isDark ? BorderSide(color: border, width: 0.5) : BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: GoogleFonts.inter(fontSize: 13 * scale, color: primaryText),
        side: BorderSide(color: border, width: 0.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? surface.withValues(alpha: 0.6) : _lightInputFillColor,
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
          borderSide: BorderSide(color: preset.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 8)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w400,
          color: secondaryText,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF374151) : const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        elevation: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: preset.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: preset.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          side: BorderSide(color: preset.primary.withValues(alpha: 0.5)),
          textStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: preset.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? preset.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? preset.primary.withValues(alpha: 0.35)
              : null,
        ),
      ),
    );
  }

  static List<String> get themeIds => {
        ..._themePresets.map((preset) => preset.id),
        ..._themeAliases.keys,
      }.toList();

  static String themeName(String themeId) => resolveThemePreset(themeId).name;

  static List<String> get accentKeys => AccentColors.palette.keys.toList();
}
