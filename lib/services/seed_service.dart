// =============================================================
// SeedService — Seeds FA 2025 pages from bundled JSON asset
// Runs ONCE on first app launch, populates SQLite database.
// =============================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/models/fa_page.dart';

class SeedService {
  static const String _seededKey = 'fa_2025_seeded_v1';

  /// Call once at app startup (before AppProvider.loadAll).
  /// Idempotent — safe to call every launch, only seeds if not already done.
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    // Load the bundled JSON asset
    final String raw = await rootBundle.loadString(
      'assets/data/fa_2025_seed.json',
    );

    final List<dynamic> jsonList = jsonDecode(raw);
    final db = DatabaseService.instance;

    // Parse and insert each FA page into SQLite
    for (final item in jsonList) {
      final json = item as Map<String, dynamic>;
      final page = FAPage(
        pageNum: json['pageNum'] as int,
        subject: json['subject'] as String? ?? '',
        system: json['system'] as String? ?? '',
        status: json['status'] as String? ?? 'unread',
        topics: json['topics'] as List<dynamic>? ?? [],
      );
      await db.upsertFAPage(page.toJson());
    }

    // Mark seeding complete
    await prefs.setBool(_seededKey, true);
  }

  /// Force re-seed (use when you push an updated JSON).
  /// Call this manually from debug tools if needed.
  static Future<void> forceReseed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seededKey);
    await seedIfNeeded();
  }
}
