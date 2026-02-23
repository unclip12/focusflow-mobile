import 'package:intl/intl.dart';

/// Returns the "adjusted" date for FocusFlow.
/// If the current time is before 03:00, treat it as the previous calendar day.
/// This matches the web app's getAdjustedDate() behaviour in utils/dateUtils.ts.
DateTime getAdjustedDate([DateTime? now]) {
  final dt = now ?? DateTime.now();
  if (dt.hour < 3) {
    return DateTime(dt.year, dt.month, dt.day - 1);
  }
  return DateTime(dt.year, dt.month, dt.day);
}

// ─── Key / serialisation helpers ─────────────────────────────────────────────

/// Converts a DateTime to the ISO date string used as DB row keys: "YYYY-MM-DD".
String formatDateKey(DateTime date) =>
    DateFormat('yyyy-MM-dd').format(date);

/// Parses a "YYYY-MM-DD" key back to a DateTime (time set to midnight).
DateTime parseDateKey(String key) =>
    DateFormat('yyyy-MM-dd').parse(key);

// ─── Display helpers ──────────────────────────────────────────────────────────

/// Short weekday + date, e.g. "Mon, 23 Feb".
String formatDisplayDate(DateTime date) =>
    DateFormat('EEE, d MMM').format(date);

/// Full date, e.g. "23 Feb 2026".
String formatFullDate(DateTime date) =>
    DateFormat('d MMM yyyy').format(date);

/// Month + year, e.g. "February 2026".
String formatMonthYear(DateTime date) =>
    DateFormat('MMMM yyyy').format(date);

/// 24-hour time string, e.g. "14:30".
String formatTime(DateTime dt) =>
    DateFormat('HH:mm').format(dt);

/// 12-hour time string, e.g. "2:30 PM".
String formatTime12(DateTime dt) =>
    DateFormat('h:mm a').format(dt);

/// Converts total minutes to human-readable string: "1h 30m" or "45m".
String formatDuration(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// Converts total seconds to "HH:MM:SS" — used by the Focus Timer.
String formatCountdown(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

// ─── Comparison helpers ───────────────────────────────────────────────────────

/// Returns true if [date] is today (using adjusted date logic).
bool isToday(DateTime date) {
  final today = getAdjustedDate();
  return date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
}

/// Returns true if [date] is strictly before today (adjusted).
bool isPast(DateTime date) {
  final today = getAdjustedDate();
  return date.isBefore(DateTime(today.year, today.month, today.day));
}

/// Returns true if [date] is strictly after today (adjusted).
bool isFuture(DateTime date) {
  final today = getAdjustedDate();
  return date.isAfter(DateTime(today.year, today.month, today.day));
}

// ─── Week helpers ─────────────────────────────────────────────────────────────

/// Returns all 7 days of the week containing [date] (Monday-first).
List<DateTime> getWeekDays([DateTime? date]) {
  final d = date ?? getAdjustedDate();
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return List.generate(
    7,
    (i) => DateTime(monday.year, monday.month, monday.day + i),
  );
}

// ─── Range helpers (for DB queries) ──────────────────────────────────────────

/// Midnight start of [date].
DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// 23:59:59.999 end of [date].
DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

/// DateTime → millisecondsSinceEpoch for SQLite INTEGER storage.
int dateToMs(DateTime dt) => dt.millisecondsSinceEpoch;

/// SQLite INTEGER (ms) → DateTime.
DateTime msToDate(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

/// Difference between two DateTimes in whole minutes.
int minutesBetween(DateTime from, DateTime to) =>
    to.difference(from).inMinutes;
