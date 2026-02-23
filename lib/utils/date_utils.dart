import 'package:intl/intl.dart';

// =============================================================
// AppDateUtils
// Mirrors the web app's getAdjustedDate helper and date
// formatting utilities used across all screens.
// =============================================================
class AppDateUtils {
  AppDateUtils._(); // static-only class

  static final DateFormat _isoDate     = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _shortDate   = DateFormat('d MMM');
  static final DateFormat _monthYear   = DateFormat('MMMM yyyy');
  static final DateFormat _time24      = DateFormat('HH:mm');
  static final DateFormat _time12      = DateFormat('h:mm a');
  static final DateFormat _isoDateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  // ── Core: adjusted date (4 AM boundary) ───────────────────────
  // If current time < 04:00, treat it as the previous calendar day.
  // This matches web app's getAdjustedDate() exactly.
  static DateTime getAdjustedDate([DateTime? now]) {
    final t = now ?? DateTime.now();
    final day = DateTime(t.year, t.month, t.day);
    return (t.hour < 4) ? day.subtract(const Duration(days: 1)) : day;
  }

  /// Returns ISO key for today (adjusted), e.g. '2026-02-23'
  static String todayKey([DateTime? now]) =>
      _isoDate.format(getAdjustedDate(now));

  // ── Formatters ────────────────────────────────────────────────
  static String formatDate(DateTime d) => _isoDate.format(d);
  static String formatDisplayDate(DateTime d) => _displayDate.format(d);
  static String formatShortDate(DateTime d) => _shortDate.format(d);
  static String formatMonthYear(DateTime d) => _monthYear.format(d);
  static String formatTime24(DateTime t) => _time24.format(t);
  static String formatTime12(DateTime t) => _time12.format(t);
  static String formatDateTime(DateTime dt) => _isoDateTime.format(dt);

  // ── Parsers ───────────────────────────────────────────────────
  static DateTime? parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return _isoDate.parseStrict(s); } catch (_) { return null; }
  }

  static DateTime? parseDateTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  // ── Comparators ───────────────────────────────────────────────
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) =>
      isSameDay(date, getAdjustedDate());

  static bool isPast(DateTime date) {
    final today = getAdjustedDate();
    return DateTime(date.year, date.month, date.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  static bool isFuture(DateTime date) {
    final today = getAdjustedDate();
    return DateTime(date.year, date.month, date.day)
        .isAfter(DateTime(today.year, today.month, today.day));
  }

  // ── Arithmetic helpers ────────────────────────────────────────
  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  // ── Duration display ─────────────────────────────────────────
  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String formatDurationFromSeconds(int seconds) =>
      formatDuration((seconds / 60).ceil());

  /// Returns a list of DateTime objects for every day in the given month.
  static List<DateTime> daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last  = DateTime(year, month + 1, 0); // last day trick
    return List.generate(
      last.day,
      (i) => DateTime(year, month, i + 1),
    );
  }
}
