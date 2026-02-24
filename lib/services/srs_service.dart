// =============================================================
// SrsService — Spaced Repetition Scheduling
// Uses kRevisionSchedules from constants.dart (string keys, hours)
// =============================================================

import 'package:focusflow_mobile/utils/constants.dart';

class SrsService {
  SrsService._();

  /// Returns the next revision DateTime based on the SRS schedule.
  ///
  /// [lastStudied] — when the item was last studied/revised
  /// [revisionIndex] — current revision index (0 = just studied, 1 = first review done, etc.)
  /// [mode] — 'fast', 'balanced', or 'deep' (keys of kRevisionSchedules)
  ///
  /// Returns `null` if the item has completed all scheduled revisions (mastered).
  static DateTime? calculateNextRevisionDate({
    required DateTime lastStudied,
    required int revisionIndex,
    required String mode,
  }) {
    final schedule = kRevisionSchedules[mode];
    if (schedule == null) return null;
    if (revisionIndex >= schedule.length) return null; // mastered
    final hoursUntilNext = schedule[revisionIndex];
    return lastStudied.add(Duration(hours: hoursUntilNext));
  }

  /// Returns the next revision date as an ISO 8601 string, or null if mastered.
  static String? calculateNextRevisionDateString({
    required String lastStudiedAt,
    required int revisionIndex,
    required String mode,
  }) {
    final lastStudied = DateTime.tryParse(lastStudiedAt);
    if (lastStudied == null) return null;
    final next = calculateNextRevisionDate(
      lastStudied: lastStudied,
      revisionIndex: revisionIndex,
      mode: mode,
    );
    return next?.toIso8601String();
  }

  /// Check if an item is due for revision now.
  static bool isDueNow({
    required String? nextRevisionAt,
    DateTime? now,
  }) {
    if (nextRevisionAt == null) return false;
    final nextDate = DateTime.tryParse(nextRevisionAt);
    if (nextDate == null) return false;
    return (now ?? DateTime.now()).isAfter(nextDate);
  }

  /// Check if an item is due within the next N days.
  static bool isDueWithinDays({
    required String? nextRevisionAt,
    required int days,
    DateTime? now,
  }) {
    if (nextRevisionAt == null) return false;
    final nextDate = DateTime.tryParse(nextRevisionAt);
    if (nextDate == null) return false;
    final current = now ?? DateTime.now();
    final cutoff = current.add(Duration(days: days));
    return nextDate.isBefore(cutoff) || nextDate.isAtSameMomentAs(cutoff);
  }

  /// Check if an item is mastered (completed all revision intervals).
  static bool isMastered({
    required int revisionIndex,
    required String mode,
  }) {
    final schedule = kRevisionSchedules[mode];
    if (schedule == null) return false;
    return revisionIndex >= schedule.length;
  }

  /// Get total number of revision steps for a given mode.
  static int totalSteps(String mode) {
    return kRevisionSchedules[mode]?.length ?? 0;
  }
}
