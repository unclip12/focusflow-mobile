import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/utils/emoji_helper.dart';

/// Shared task registry — records every task name entered from:
///   • Track Now (live tracking)
///   • Add Log (past activity logging)
///   • Add Task / New Task (scheduling)
///   • Study Session (records under label "Studies")
///
/// Per-label data stored:
///   count        — total number of times this label was used
///   totalSeconds — cumulative time in seconds
///   lastUsedAt   — ISO-8601 timestamp of most recent use
class ActivityHistoryService {
  static const _key = 'track_now_activity_history_v2';

  // ── Raw storage ───────────────────────────────────────────────

  /// Returns raw map: { label -> { count, totalSeconds, lastUsedAt } }
  static Future<Map<String, Map<String, dynamic>>> getAllFull() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return _migrateV1(prefs);
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _migrateV1(
    SharedPreferences prefs,
  ) async {
    final oldRaw = prefs.getString('track_now_activity_history');
    if (oldRaw == null) return {};
    try {
      final old = jsonDecode(oldRaw) as Map<String, dynamic>;
      final migrated = old.map(
        (k, v) => MapEntry(k, {
          'count': (v as num).toInt(),
          'totalSeconds': 0,
          'lastUsedAt': DateTime.now().toIso8601String(),
        }),
      );
      await prefs.setString(_key, jsonEncode(migrated));
      return migrated;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(
    SharedPreferences prefs,
    Map<String, Map<String, dynamic>> data,
  ) async {
    await prefs.setString(_key, jsonEncode(data));
  }

  // ── Write ─────────────────────────────────────────────────────

  /// Cleans task labels by removing leading emojis and symbols.
  static String cleanLabel(String label) {
    var clean = label.trim();
    if (clean.isEmpty) return clean;
    final regex = RegExp(r'^[^\p{L}\p{N}\(\)]+\s*', unicode: true);
    clean = clean.replaceFirst(regex, '');
    return clean.trim();
  }

  /// Determines if a label or block type represents study tasks.
  static bool isStudyLabel(String label, {String? blockTypeValue}) {
    final lower = label.toLowerCase();
    if (lower.startsWith('studies') ||
        lower.startsWith('study') ||
        lower.contains('fa page') ||
        lower.contains('first aid') ||
        lower.contains('qbank') ||
        lower.contains('anki') ||
        lower.contains('cerebellum') ||
        lower.contains('subject reading') ||
        lower.contains('usmle') ||
        lower.contains('fmge')) {
      return true;
    }
    if (blockTypeValue != null) {
      final val = blockTypeValue.toUpperCase();
      return val == 'VIDEO' ||
          val == 'REVISION_FA' ||
          val == 'ANKI' ||
          val == 'QBANK' ||
          val == 'STUDY_SESSION' ||
          val == 'FMGE_REVISION';
    }
    return false;
  }

  /// Record a task usage. Call this whenever a task name is saved/confirmed
  /// from any input area (Track Now, Add Log, New Task, Study Session).
  ///
  /// [label]        — task name (e.g. "Cooking", "Bathe", "Studies")
  /// [durationSecs] — seconds spent on this task (0 if unknown / scheduling)
  static Future<void> record(
    String label, {
    int durationSecs = 0,
    String? blockTypeValue,
    bool incrementCount = true,
  }) async {
    final cleaned = cleanLabel(label);
    if (cleaned.isEmpty) return;

    final isStudy = isStudyLabel(cleaned, blockTypeValue: blockTypeValue);
    final targetLabel = isStudy ? 'Studies' : cleaned;

    final prefs = await SharedPreferences.getInstance();
    final all = await getAllFull();
    final existing = all[targetLabel] ?? {'count': 0, 'totalSeconds': 0};
    all[targetLabel] = {
      'count': ((existing['count'] as num?) ?? 0).toInt() + (incrementCount ? 1 : 0),
      'totalSeconds':
          ((existing['totalSeconds'] as num?) ?? 0).toInt() + durationSecs,
      'lastUsedAt': DateTime.now().toIso8601String(),
    };
    await _saveAll(prefs, all);
  }

  /// Decrement completed count and duration for a task when deleted or status changed.
  static Future<void> decrementRecord(
    String label, {
    int durationSecs = 0,
    String? blockTypeValue,
  }) async {
    final cleaned = cleanLabel(label);
    if (cleaned.isEmpty) return;

    final isStudy = isStudyLabel(cleaned, blockTypeValue: blockTypeValue);
    final targetLabel = isStudy ? 'Studies' : cleaned;

    final prefs = await SharedPreferences.getInstance();
    final all = await getAllFull();
    if (!all.containsKey(targetLabel)) return;

    final existing = all[targetLabel]!;
    final currentCount = ((existing['count'] as num?) ?? 0).toInt();
    final currentSeconds = ((existing['totalSeconds'] as num?) ?? 0).toInt();

    final newCount = currentCount - 1;
    final newSeconds = currentSeconds - durationSecs;

    all[targetLabel] = {
      'count': newCount < 0 ? 0 : newCount,
      'totalSeconds': newSeconds < 0 ? 0 : newSeconds,
      'lastUsedAt': existing['lastUsedAt'] ?? DateTime.now().toIso8601String(),
    };
    await _saveAll(prefs, all);
  }

  // ── Read helpers ──────────────────────────────────────────────

  /// Returns all entries sorted by lastUsedAt descending (recently tracked first).
  /// Excludes entries with count <= 0.
  static Future<List<MapEntry<String, Map<String, dynamic>>>> getRecent() async {
    final all = await getAllFull();
    final filtered = all.entries.where((e) => ((e.value['count'] as num?) ?? 0) > 0).toList();
    final sorted = filtered
      ..sort((a, b) {
        final aT = a.value['lastUsedAt'] as String? ?? '';
        final bT = b.value['lastUsedAt'] as String? ?? '';
        return bT.compareTo(aT);
      });
    return sorted;
  }

  /// Returns all entries sorted by totalSeconds descending (top by time spent).
  /// Excludes entries with count <= 0.
  static Future<List<MapEntry<String, Map<String, dynamic>>>> getTopByTime()
      async {
    final all = await getAllFull();
    final filtered = all.entries.where((e) => ((e.value['count'] as num?) ?? 0) > 0).toList();
    final sorted = filtered
      ..sort((a, b) {
        final aS = (a.value['totalSeconds'] as num?)?.toInt() ?? 0;
        final bS = (b.value['totalSeconds'] as num?)?.toInt() ?? 0;
        return bS.compareTo(aS);
      });
    return sorted;
  }

  /// Returns all entries sorted by count descending (top by times done).
  /// Excludes entries with count <= 0.
  static Future<List<MapEntry<String, Map<String, dynamic>>>> getTopByCount()
      async {
    final all = await getAllFull();
    final filtered = all.entries.where((e) => ((e.value['count'] as num?) ?? 0) > 0).toList();
    final sorted = filtered
      ..sort((a, b) {
        final aC = (a.value['count'] as num?)?.toInt() ?? 0;
        final bC = (b.value['count'] as num?)?.toInt() ?? 0;
        return bC.compareTo(aC);
      });
    return sorted;
  }

  /// Prefix-based autocomplete — returns up to [limit] entries whose label
  /// starts with [prefix] (case-insensitive), sorted by count descending.
  static Future<List<MapEntry<String, int>>> suggest(
    String prefix, {
    int limit = 5,
  }) async {
    final trimmed = prefix.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    // 1. History matches
    final all = await getAllFull();
    final historyMatches = all.entries
        .where((e) => e.key.toLowerCase().contains(trimmed))
        .map((e) => MapEntry(e.key, ((e.value['count'] as num?) ?? 0).toInt()))
        .toList();

    // 2. Dictionary matches
    final dictionaryMatches = EmojiHelper.suggestCommonTasks(trimmed, limit: limit)
        .map((task) => MapEntry(task, 0))
        .toList();

    // 3. Merge and deduplicate
    final merged = <String, int>{};
    for (final e in historyMatches) {
      merged[e.key] = e.value;
    }
    for (final e in dictionaryMatches) {
      final matchingKey = merged.keys.firstWhere(
        (k) => k.toLowerCase() == e.key.toLowerCase(),
        orElse: () => '',
      );
      if (matchingKey.isEmpty) {
        merged[e.key] = 0;
      }
    }

    // 4. Sort: startsWith first, then higher count, then shorter length
    final sorted = merged.entries.toList()
      ..sort((a, b) {
        final aLower = a.key.toLowerCase();
        final bLower = b.key.toLowerCase();
        final aStarts = aLower.startsWith(trimmed);
        final bStarts = bLower.startsWith(trimmed);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        if (b.value != a.value) {
          return b.value.compareTo(a.value);
        }
        return a.key.length.compareTo(b.key.length);
      });

    return sorted.take(limit).toList();
  }

  /// Legacy compat — returns a simple { label -> count } map.
  static Future<Map<String, int>> getAll() async {
    final full = await getAllFull();
    return full.map(
      (k, v) => MapEntry(k, ((v['count'] as num?) ?? 0).toInt()),
    );
  }
}
