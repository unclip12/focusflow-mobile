// =============================================================
// FocusBatch Calculator — pure function, no Flutter dependency
// Given a start and end time, produces a list of focus/break
// segments following evidence-based study batch rules.
// =============================================================

class FocusBatch {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isBreak;
  final String label;

  const FocusBatch({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isBreak,
    required this.label,
  });

  @override
  String toString() => '$label ${durationMinutes}m';
}

/// Calculates focus batches between [start] and [end].
///
/// Rules:
///  ≤30 min  → 1 batch, no break
///  31–60    → 2 equal batches, 5 min break
///  61–90    → 2×40 min, 10 min break
///  91–150   → 3×~40 min, 10 min breaks
///  151–240  → 45 min batches, 10 min breaks
///  >240     → 50 min batches, 15 min breaks,
///             30 min long break after every 3rd batch
List<FocusBatch> calculateFocusBatches(DateTime start, DateTime end) {
  final totalMinutes = end.difference(start).inMinutes;
  if (totalMinutes <= 0) return [];

  final batches = <FocusBatch>[];

  if (totalMinutes <= 30) {
    // 1 batch, no break
    batches.add(FocusBatch(
      startTime: start,
      endTime: end,
      durationMinutes: totalMinutes,
      isBreak: false,
      label: 'Focus',
    ));
  } else if (totalMinutes <= 60) {
    // 2 equal batches, 5 min break
    final half = totalMinutes ~/ 2;
    _addFocusBreakFocus(batches, start, [half, half], 5);
  } else if (totalMinutes <= 90) {
    // 2×40 min, 10 min break
    _addFocusBreakFocus(batches, start, [40, 40], 10);
  } else if (totalMinutes <= 150) {
    // 3×~40 min, 10 min breaks
    final focusTime = totalMinutes - 20; // 2 breaks × 10 min
    final batch = focusTime ~/ 3;
    _addRepeatingBatches(batches, start, batch, 10, 3);
  } else if (totalMinutes <= 240) {
    // 45 min batches, 10 min breaks
    _addFittedBatches(batches, start, end, 45, 10);
  } else {
    // 50 min batches, 15 min breaks, 30 min long break after every 3rd
    _addLongSessionBatches(batches, start, end, 50, 15, 30);
  }

  return batches;
}

void _addFocusBreakFocus(
  List<FocusBatch> batches,
  DateTime start,
  List<int> focusDurations,
  int breakMinutes,
) {
  var cursor = start;
  for (int i = 0; i < focusDurations.length; i++) {
    final focusEnd = cursor.add(Duration(minutes: focusDurations[i]));
    batches.add(FocusBatch(
      startTime: cursor,
      endTime: focusEnd,
      durationMinutes: focusDurations[i],
      isBreak: false,
      label: 'Focus',
    ));
    cursor = focusEnd;

    if (i < focusDurations.length - 1) {
      final breakEnd = cursor.add(Duration(minutes: breakMinutes));
      batches.add(FocusBatch(
        startTime: cursor,
        endTime: breakEnd,
        durationMinutes: breakMinutes,
        isBreak: true,
        label: 'Break',
      ));
      cursor = breakEnd;
    }
  }
}

void _addRepeatingBatches(
  List<FocusBatch> batches,
  DateTime start,
  int focusMinutes,
  int breakMinutes,
  int count,
) {
  var cursor = start;
  for (int i = 0; i < count; i++) {
    final focusEnd = cursor.add(Duration(minutes: focusMinutes));
    batches.add(FocusBatch(
      startTime: cursor,
      endTime: focusEnd,
      durationMinutes: focusMinutes,
      isBreak: false,
      label: 'Focus',
    ));
    cursor = focusEnd;

    if (i < count - 1) {
      final breakEnd = cursor.add(Duration(minutes: breakMinutes));
      batches.add(FocusBatch(
        startTime: cursor,
        endTime: breakEnd,
        durationMinutes: breakMinutes,
        isBreak: true,
        label: 'Break',
      ));
      cursor = breakEnd;
    }
  }
}

void _addFittedBatches(
  List<FocusBatch> batches,
  DateTime start,
  DateTime end,
  int focusMinutes,
  int breakMinutes,
) {
  var cursor = start;
  while (cursor.isBefore(end)) {
    final remaining = end.difference(cursor).inMinutes;
    if (remaining <= 0) break;

    final thisFocus = remaining < focusMinutes ? remaining : focusMinutes;
    final focusEnd = cursor.add(Duration(minutes: thisFocus));
    batches.add(FocusBatch(
      startTime: cursor,
      endTime: focusEnd,
      durationMinutes: thisFocus,
      isBreak: false,
      label: 'Focus',
    ));
    cursor = focusEnd;

    final afterBreak = end.difference(cursor).inMinutes;
    if (afterBreak > breakMinutes) {
      final breakEnd = cursor.add(Duration(minutes: breakMinutes));
      batches.add(FocusBatch(
        startTime: cursor,
        endTime: breakEnd,
        durationMinutes: breakMinutes,
        isBreak: true,
        label: 'Break',
      ));
      cursor = breakEnd;
    } else {
      break;
    }
  }
}

void _addLongSessionBatches(
  List<FocusBatch> batches,
  DateTime start,
  DateTime end,
  int focusMinutes,
  int shortBreakMinutes,
  int longBreakMinutes,
) {
  var cursor = start;
  var focusCount = 0;

  while (cursor.isBefore(end)) {
    final remaining = end.difference(cursor).inMinutes;
    if (remaining <= 0) break;

    final thisFocus = remaining < focusMinutes ? remaining : focusMinutes;
    final focusEnd = cursor.add(Duration(minutes: thisFocus));
    batches.add(FocusBatch(
      startTime: cursor,
      endTime: focusEnd,
      durationMinutes: thisFocus,
      isBreak: false,
      label: 'Focus',
    ));
    cursor = focusEnd;
    focusCount++;

    final afterBreak = end.difference(cursor).inMinutes;
    if (afterBreak <= 0) break;

    // Long break after every 3rd focus batch
    if (focusCount % 3 == 0 && afterBreak > longBreakMinutes) {
      final breakEnd = cursor.add(Duration(minutes: longBreakMinutes));
      batches.add(FocusBatch(
        startTime: cursor,
        endTime: breakEnd,
        durationMinutes: longBreakMinutes,
        isBreak: true,
        label: 'Long Break',
      ));
      cursor = breakEnd;
    } else if (afterBreak > shortBreakMinutes) {
      final breakEnd = cursor.add(Duration(minutes: shortBreakMinutes));
      batches.add(FocusBatch(
        startTime: cursor,
        endTime: breakEnd,
        durationMinutes: shortBreakMinutes,
        isBreak: true,
        label: 'Break',
      ));
      cursor = breakEnd;
    } else {
      break;
    }
  }
}
