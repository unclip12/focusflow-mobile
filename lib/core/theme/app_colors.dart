import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark (visionOS deep dark)
  static const darkBg         = Color(0xFF0A0A0F);
  static const darkSurface    = Color(0xFF13131A);
  static const darkSurface2   = Color(0xFF1C1C26);
  static const darkBorder     = Color(0xFF2A2A38);
  static const darkGlass      = Color(0x1AFFFFFF);
  static const darkGlassBorder= Color(0x26FFFFFF);

  // Light (airy frosted)
  static const lightBg        = Color(0xFFF2F2F7);
  static const lightSurface   = Color(0xFFFFFFFF);
  static const lightSurface2  = Color(0xFFF8F8FC);
  static const lightBorder    = Color(0xFFE5E5EA);
  static const lightGlass     = Color(0xB3FFFFFF);
  static const lightGlassBorder = Color(0x4DFFFFFF);

  // Accent
  static const accent         = Color(0xFF6366F1);
  static const accentGlow     = Color(0x336366F1);
  static const accentLight    = Color(0xFF818CF8);
  static const success        = Color(0xFF34D399);
  static const warning        = Color(0xFFFBBF24);
  static const error          = Color(0xFFF87171);
  static const info           = Color(0xFF60A5FA);

  static const List<Color> subjectColors = [
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF06B6D4), Color(0xFF3B82F6),
    Color(0xFF14B8A6),
  ];
}
