// =============================================================
// SrsService — Spaced Repetition Scheduling
// Uses kRevisionSchedules from constants.dart (string keys, hours)
// Now includes confidence-based adaptive scheduling
// =============================================================

import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/models/revision_item.dart';

class SrsService {
  SrsService._();

  static DateTime? parseRevisionDate(String? nextRevisionAt) {
    if (nextRevisionAt == null || nextRevisionAt.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(nextRevisionAt);
  }

  static bool isScheduledTodayOrPast({
    required String? nextRevisionAt,
    DateTime? now,
  }) {
    final scheduled = parseRevisionDate(nextRevisionAt);
    if (scheduled == null) return false;
    final current = now ?? DateTime.now();
    final scheduledDate = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
    );
    final currentDate = DateTime(current.year, current.month, current.day);
    return !scheduledDate.isAfter(currentDate);
  }

  static int? daysUntilScheduledDate({
    required String? nextRevisionAt,
    DateTime? now,
  }) {
    final scheduled = parseRevisionDate(nextRevisionAt);
    if (scheduled == null) return null;
    final current = now ?? DateTime.now();
    final scheduledDate = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
    );
    final currentDate = DateTime(current.year, current.month, current.day);
    return scheduledDate.difference(currentDate).inDays;
  }

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

  // ═══════════════════════════════════════════════════════════════
  // CONFIDENCE-BASED ADAPTIVE SCHEDULING
  // ═══════════════════════════════════════════════════════════════

  /// Hard interval: starts at 7h, decreases by ~1-2h each successive hard.
  /// Sequence: 7h, 5h, 4h, 3h, 2h, 2h, 2h...
  static const List<int> _hardIntervals = [7, 5, 4, 3, 2];

  /// Returns the review interval in hours for Hard clicks.
  /// [hardCount] is the number of prior Hard clicks for this revision (0-based).
  static int calculateHardInterval(int hardCount) {
    if (hardCount < _hardIntervals.length) {
      return _hardIntervals[hardCount];
    }
    return 2; // minimum floor
  }

  /// Process a confidence response and return an updated RevisionItem.
  ///
  /// [quality] — 'hard', 'good', or 'easy'
  /// [mode] — SRS mode key (e.g. 'strict')
  ///
  /// Returns a new RevisionItem with updated scheduling, logs, and scores.
  static RevisionItem processConfidenceResponse({
    required RevisionItem item,
    required String quality,
    required String mode,
  }) {
    final now = DateTime.now();
    final schedule = kRevisionSchedules[mode] ?? kRevisionSchedules['strict']!;
    final scheduledAt = item.nextRevisionAt;
    final logs = List<RevisionLogEntry>.from(item.revisionLog);

    switch (quality) {
      case 'hard':
        return _processHard(item, now, schedule, scheduledAt, logs, mode);
      case 'easy':
        return _processEasy(item, now, schedule, scheduledAt, logs, mode);
      default: // 'good'
        return _processGood(item, now, schedule, scheduledAt, logs, mode);
    }
  }

  /// HARD: Don't advance revision. Reschedule in diminishing intervals.
  /// Reset effectiveSrsStep to 0 (will take effect when good is clicked).
  static RevisionItem _processHard(
    RevisionItem item,
    DateTime now,
    List<int> schedule,
    String scheduledAt,
    List<RevisionLogEntry> logs,
    String mode,
  ) {
    final hardCount = item.hardCount;
    final intervalHours = calculateHardInterval(hardCount);
    final nextDate = now.add(Duration(hours: intervalHours));

    logs.add(RevisionLogEntry(
      revisionNumber: item.currentRevisionIndex,
      scheduledAt: scheduledAt,
      actualAt: now.toIso8601String(),
      response: 'hard',
      hardAttempt: hardCount + 1,
      nextScheduledHours: intervalHours,
      note: 'Hard #${hardCount + 1} → rescheduled in ${intervalHours}h',
    ));

    return item.copyWith(
      nextRevisionAt: nextDate.toIso8601String(),
      lastStudiedAt: now.toIso8601String(),
      hardCount: hardCount + 1,
      // Reset effectiveSrsStep to 0 — SRS timing will restart when Good is clicked
      effectiveSrsStep: 0,
      easyFlag: false,
      retentionScore: item.retentionScore - 5,
      revisionLog: logs,
    );
  }

  /// GOOD: Advance revision index. Use effectiveSrsStep for interval.
  /// If hard was clicked before, effectiveSrsStep is already 0 (reset).
  static RevisionItem _processGood(
    RevisionItem item,
    DateTime now,
    List<int> schedule,
    String scheduledAt,
    List<RevisionLogEntry> logs,
    String mode,
  ) {
    final newRevisionIndex = item.currentRevisionIndex + 1;
    final newEffectiveSrsStep = item.effectiveSrsStep;

    // Use effectiveSrsStep for the interval
    final intervalHours = newEffectiveSrsStep < schedule.length
        ? schedule[newEffectiveSrsStep]
        : null;

    final nextDate = intervalHours != null
        ? now.add(Duration(hours: intervalHours))
        : null; // mastered

    logs.add(RevisionLogEntry(
      revisionNumber: item.currentRevisionIndex,
      scheduledAt: scheduledAt,
      actualAt: now.toIso8601String(),
      response: 'good',
      nextScheduledHours: intervalHours ?? 0,
      note: intervalHours != null
          ? 'Good → R$newRevisionIndex, next in ${_formatHours(intervalHours)}'
          : 'Good → Mastered!',
    ));

    return item.copyWith(
      nextRevisionAt: nextDate?.toIso8601String() ?? '',
      lastStudiedAt: now.toIso8601String(),
      currentRevisionIndex: newRevisionIndex,
      hardCount: 0,
      effectiveSrsStep: newEffectiveSrsStep + 1,
      retentionScore: item.retentionScore + 10,
      revisionLog: logs,
    );
  }

  /// EASY: Advance revision index.
  /// - If lagging (effectiveSrsStep < currentRevisionIndex): skip 1 SRS step
  /// - If on track or ahead: treat as good (no skip)
  static RevisionItem _processEasy(
    RevisionItem item,
    DateTime now,
    List<int> schedule,
    String scheduledAt,
    List<RevisionLogEntry> logs,
    String mode,
  ) {
    final newRevisionIndex = item.currentRevisionIndex + 1;
    final isLagging = item.effectiveSrsStep < item.currentRevisionIndex;

    // If lagging, skip one step ahead; otherwise act like good
    int newEffectiveSrsStep;
    if (isLagging) {
      newEffectiveSrsStep = item.effectiveSrsStep + 2; // skip one
      // But don't overshoot past the natural position
      if (newEffectiveSrsStep > newRevisionIndex) {
        newEffectiveSrsStep = newRevisionIndex;
      }
    } else {
      newEffectiveSrsStep = item.effectiveSrsStep + 1;
    }


    // Calculate final interval based on effective step
    final finalIntervalHours = isLagging
        ? (newEffectiveSrsStep > 0 && newEffectiveSrsStep - 1 < schedule.length
            ? schedule[newEffectiveSrsStep - 1]
            : null)
        : (item.effectiveSrsStep < schedule.length
            ? schedule[item.effectiveSrsStep]
            : null);

    final nextDate = finalIntervalHours != null
        ? now.add(Duration(hours: finalIntervalHours))
        : null;

    logs.add(RevisionLogEntry(
      revisionNumber: item.currentRevisionIndex,
      scheduledAt: scheduledAt,
      actualAt: now.toIso8601String(),
      response: 'easy',
      nextScheduledHours: finalIntervalHours ?? 0,
      note: isLagging
          ? 'Easy (lagging) → R$newRevisionIndex, skipped ahead, next in ${_formatHours(finalIntervalHours ?? 0)}'
          : 'Easy → R$newRevisionIndex, next in ${_formatHours(finalIntervalHours ?? 0)}',
    ));

    return item.copyWith(
      nextRevisionAt: nextDate?.toIso8601String() ?? '',
      lastStudiedAt: now.toIso8601String(),
      currentRevisionIndex: newRevisionIndex,
      hardCount: 0,
      effectiveSrsStep: newEffectiveSrsStep,
      easyFlag: item.easyFlag, // keep existing flag (only hard sets to false)
      retentionScore: item.retentionScore + 15,
      revisionLog: logs,
    );
  }

  /// Format hours into human-readable string
  static String _formatHours(int hours) {
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (remainingHours == 0) return '${days}d';
    return '${days}d ${remainingHours}h';
  }

  /// Get the SRS interval in hours for a given step.
  static int? getIntervalHours(int step, String mode) {
    final schedule = kRevisionSchedules[mode];
    if (schedule == null || step >= schedule.length || step < 0) return null;
    return schedule[step];
  }
}
