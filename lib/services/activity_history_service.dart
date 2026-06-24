import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists custom activity labels and how many times each was used.
/// Used to power autocomplete suggestions in TrackNowScreen.
class ActivityHistoryService {
  static const _key = 'track_now_activity_history';

  /// Returns a map of { label -> useCount }.
  static Future<Map<String, int>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Increments count for [label], or sets it to 1 if new.
  static Future<void> record(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    all[trimmed] = (all[trimmed] ?? 0) + 1;
    await prefs.setString(_key, jsonEncode(all));
  }

  /// Returns entries whose label starts with [prefix] (case-insensitive),
  /// sorted by use count descending. Returns at most [limit] results.
  static Future<List<MapEntry<String, int>>> suggest(
    String prefix, {
    int limit = 5,
  }) async {
    final trimmed = prefix.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await getAll();
    final matches = all.entries
        .where((e) => e.key.toLowerCase().startsWith(trimmed))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return matches.take(limit).toList();
  }
}
