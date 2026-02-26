// =============================================================
// SeedService — Seeds FA 2025 pages + Sketchy + Pathoma
// Runs ONCE on first app launch, populates SQLite database.
// =============================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/services/sketchy_micro_seed.dart';
import 'package:focusflow_mobile/services/sketchy_pharm_seed.dart';
import 'package:focusflow_mobile/services/pathoma_seed.dart';

class SeedService {
  static const String _seededKey = 'fa_2025_seeded_v1';

  /// Call once at app startup (before AppProvider.loadAll).
  /// Idempotent — safe to call every launch, only seeds if not already done.
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // ── FA 2025 seed ─────────────────────────────────────────────
    if (prefs.getBool(_seededKey) != true) {
      final String raw = await rootBundle.loadString(
        'assets/data/fa_2025_seed.json',
      );

      final List<dynamic> jsonList = jsonDecode(raw);
      final db = DatabaseService.instance;

      for (final item in jsonList) {
        final json = item as Map<String, dynamic>;

        String title = json['subject'] as String? ?? 'Untitled';
        final topics = json['topics'] as List<dynamic>?;
        if (topics != null && topics.isNotEmpty) {
          final firstTopic = topics[0] as Map<String, dynamic>?;
          if (firstTopic != null && firstTopic['t'] != null) {
            title = firstTopic['t'] as String;
          }
        }

        final page = FAPage(
          pageNum: json['pageNum'] as int,
          subject: json['subject'] as String? ?? '',
          system: json['system'] as String? ?? '',
          title: title,
          status: json['status'] as String? ?? 'unread',
        );
        await db.upsertFAPage(page.toJson());
      }

      await prefs.setBool(_seededKey, true);
    }

    // ── Sketchy & Pathoma seeds (idempotent via count > 0 guard) ──
    final db = DatabaseService.instance;
    await db.seedSketchyMicro(sketchyMicroSeed);
    await db.seedSketchyPharm(sketchyPharmSeed);
    await db.seedPathoma(pathomaSeed);
  }

  /// Force re-seed (use when you push an updated JSON).
  /// Call this manually from debug tools if needed.
  static Future<void> forceReseed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seededKey);
    await seedIfNeeded();
  }
}

