// =============================================================
// SeedService — Seeds FA 2025 pages + subtopics + Sketchy + Pathoma
// Runs ONCE on first app launch, populates SQLite database.
// =============================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/services/sketchy_micro_seed.dart';
import 'package:focusflow_mobile/services/sketchy_pharm_seed.dart';
import 'package:focusflow_mobile/services/pathoma_seed.dart';

class SeedService {
  static const String _seededKey = 'fa_2025_seeded_v2'; // bumped for subtopics

  /// Call once at app startup (before AppProvider.loadAll).
  /// Idempotent — safe to call every launch, only seeds if not already done.
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseService.instance;

    // ── FA 2025 seed (pages + subtopics) ──────────────────────────
    if (prefs.getBool(_seededKey) != true) {
      final String raw = await rootBundle.loadString(
        'assets/data/fa_2025_seed.json',
      );

      final List<dynamic> jsonList = jsonDecode(raw);

      for (int orderIdx = 0; orderIdx < jsonList.length; orderIdx++) {
        final json = jsonList[orderIdx] as Map<String, dynamic>;
        final pageNum = json['pageNum'] as int;
        final topics = json['topics'] as List<dynamic>? ?? [];

        // Build title from first topic name
        String title = json['subject'] as String? ?? 'Untitled';
        if (topics.isNotEmpty) {
          final firstTopic = topics[0] as Map<String, dynamic>?;
          if (firstTopic != null && firstTopic['t'] != null) {
            title = firstTopic['t'] as String;
          }
        }

        // Seed the FA page with orderIndex
        final page = FAPage(
          pageNum: pageNum,
          subject: json['subject'] as String? ?? '',
          system: json['system'] as String? ?? '',
          title: title,
          status: json['status'] as String? ?? 'unread',
          orderIndex: orderIdx,
        );
        await db.upsertFAPage(page.toJson());

        // Extract and seed subtopics
        final subtopics = <FASubtopic>[];
        for (final topic in topics) {
          final topicMap = topic as Map<String, dynamic>;
          final topicName = topicMap['t'] as String? ?? '';

          // Check if the topic has nested subtopics ('s' array)
          final nested = topicMap['s'] as List<dynamic>?;
          if (nested != null && nested.isNotEmpty) {
            for (final sub in nested) {
              final subMap = sub as Map<String, dynamic>;
              final subName = subMap['t'] as String? ?? '';
              if (subName.isNotEmpty) {
                subtopics.add(FASubtopic(
                  pageNum: pageNum,
                  name: subName,
                ));
              }
            }
          } else {
            // Top-level topic is itself a subtopic
            if (topicName.isNotEmpty) {
              subtopics.add(FASubtopic(
                pageNum: pageNum,
                name: topicName,
              ));
            }
          }
        }

        // Seed subtopics for this page (idempotent)
        if (subtopics.isNotEmpty) {
          await db.seedFASubtopics(pageNum, subtopics);
        }
      }

      await prefs.setBool(_seededKey, true);
    }

    // ── Sketchy & Pathoma seeds (idempotent via count > 0 guard) ──
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
