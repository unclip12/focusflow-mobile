import 'package:flutter/material.dart';

class DashboardColors {
  DashboardColors._();

  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color darkBackground = Color(0xFF0E0E1A);

  static const Color lightTextPrimary = Color(0xFF1E1E2E);
  static const Color darkTextPrimary = Color(0xFFF4F4FF);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color primaryLavender = Color(0xFFA78BFA);
  static const Color primaryDeep = Color(0xFF4F46E5);
  static const Color primaryDeeper = Color(0xFF4338CA);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color glassLight = Color.fromRGBO(255, 255, 255, 0.72);
  static const Color glassDark = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassBorderLight = Color.fromRGBO(255, 255, 255, 0.45);
  static const Color glassBorderDark = Color.fromRGBO(99, 102, 241, 0.30);

  static const Color navGlassDark = Color.fromRGBO(14, 14, 26, 0.75);
  static const Color countdownTrackDark = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color countdownTrackLight = Color.fromRGBO(99, 102, 241, 0.10);

  static const Color budgetSleep = Color(0xFF1E1E2E);
  static const Color quoteCardFill = Color.fromRGBO(99, 102, 241, 0.10);
  static const Color quoteCardBorder = Color.fromRGBO(99, 102, 241, 0.15);

  static const Color shimmerBright = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color shimmerSoft = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color shimmerTransparent = Color.fromRGBO(255, 255, 255, 0.0);

  static const List<Color> darkAuroraBlobs = <Color>[
    Color(0xFF6366F1),
    Color(0xFF818CF8),
    Color(0xFF4338CA),
    Color(0xFF8B5CF6),
    Color(0xFF4F46E5),
  ];

  static const List<Color> lightAuroraBlobs = <Color>[
    Color(0xFFCDD5FF),
    Color(0xFFD8D4FE),
    Color(0xFFDBE3FF),
    Color(0xFFE9D5FF),
    Color(0xFFC7D2FE),
  ];

  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color glassFill(bool isDark) => isDark ? glassDark : glassLight;

  static Color glassBorder(bool isDark) =>
      isDark ? glassBorderDark : glassBorderLight;

  static Color countdownTrack(bool isDark) =>
      isDark ? countdownTrackDark : countdownTrackLight;

  static Color navGlass(bool isDark) =>
      isDark ? navGlassDark : const Color.fromRGBO(255, 255, 255, 0.82);

  static List<Color> auroraBlobs(bool isDark) =>
      isDark ? darkAuroraBlobs : lightAuroraBlobs;

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
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        primary,
        primaryViolet,
      ],
    );
  }
}
