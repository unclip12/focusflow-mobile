import 'package:flutter/material.dart';

class DashboardColors {
  DashboardColors._();

  static Color _lightBackground = const Color(0xFFF4F6FB);
  static Color _darkBackground = const Color(0xFF16171F);
  static Color _lightSurface = const Color(0xFFFFFFFF);
  static Color _darkSurface = const Color(0xFF21222D);
  static Color _primary = const Color(0xFF6366F1);
  static Color _secondary = const Color(0xFF818CF8);

  static const Color lightTextPrimary = Color(0xFF1E1E2E);
  static const Color darkTextPrimary = Color(0xFFF4F4FF);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color budgetSleep = Color(0xFF1E1E2E);
  static const Color shimmerBright = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color shimmerSoft = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color shimmerTransparent = Color.fromRGBO(255, 255, 255, 0.0);

  static Color get primary => _primary;
  static Color get primaryLight => _secondary;
  static Color get primaryViolet => _blend(_primary, _secondary, 0.45);
  static Color get primaryLavender => _shiftLightness(_secondary, 0.10);
  static Color get primaryDeep => _shiftLightness(_primary, -0.10);
  static Color get primaryDeeper => _shiftLightness(_primary, -0.18);

  static Color get glassLight => Colors.white.withValues(alpha: 0.40);
  static Color get glassDark => Colors.white.withValues(alpha: 0.12);
  static Color get glassBorderLight => Colors.white.withValues(alpha: 0.45);
  static Color get glassBorderDark => _primary.withValues(alpha: 0.30);

  static Color get navGlassDark => _darkBackground.withValues(alpha: 0.75);
  static Color get countdownTrackDark =>
      Colors.white.withValues(alpha: 0.06);
  static Color get countdownTrackLight => _primary.withValues(alpha: 0.10);

  static Color get quoteCardFill => _primary.withValues(alpha: 0.10);
  static Color get quoteCardBorder => _primary.withValues(alpha: 0.15);

  static void applyThemeValues({
    required Color primary,
    required Color secondary,
    required Color lightBackground,
    required Color lightSurface,
    required Color darkBackground,
    required Color darkSurface,
  }) {
    _primary = primary;
    _secondary = secondary;
    _lightBackground = lightBackground;
    _darkBackground = darkBackground;
    _lightSurface = lightSurface;
    _darkSurface = darkSurface;
  }

  static Color background(bool isDark) =>
      isDark ? _darkBackground : _lightBackground;

  static Color surface(bool isDark) => isDark ? _darkSurface : _lightSurface;

  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color glassFill(bool isDark) => isDark ? glassDark : glassLight;

  static Color glassBorder(bool isDark) =>
      isDark ? glassBorderDark : glassBorderLight;

  static Color countdownTrack(bool isDark) =>
      isDark ? countdownTrackDark : countdownTrackLight;

  static Color navGlass(bool isDark) =>
      isDark ? navGlassDark : Colors.white.withValues(alpha: 0.82);

  static List<Color> auroraBlobs(bool isDark) {
    if (isDark) {
      return <Color>[
        _primary,
        _secondary,
        primaryDeep,
        primaryViolet,
        primaryDeeper,
      ];
    }

    return <Color>[
      _shiftLightness(_primary, 0.30),
      _shiftLightness(_secondary, 0.22),
      _shiftLightness(primaryViolet, 0.26),
      _shiftLightness(primaryDeep, 0.34),
      _shiftLightness(primaryLight, 0.28),
    ];
  }

  static LinearGradient progressGradient(Color color) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        color,
        color.withValues(alpha: 0.80),
      ],
    );
  }

  static LinearGradient verticalAccentGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        _primary,
        primaryViolet,
      ],
    );
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  static Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
