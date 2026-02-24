// =============================================================
// HapticsService — thin wrapper around Flutter HapticFeedback
// =============================================================

import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();

  /// Light tap — e.g. toggling a checkbox, selecting an item.
  static void light() => HapticFeedback.lightImpact();

  /// Medium tap — e.g. completing a block, starting a timer.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy tap — e.g. deleting an item, resetting data.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection click — e.g. scrolling through a picker.
  static void selection() => HapticFeedback.selectionClick();
}
