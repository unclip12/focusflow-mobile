// =============================================================
// BackupService — Complete backup & restore for all 34 tables
//                 + SharedPreferences
// File format: .ffbackup (JSON internally)
// Manual backup: temp file → share_plus ShareXFiles (all platforms)
// Auto backup:   Documents/FocusFlow (always writable)
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/activity_log.dart';

// ── Isolate helpers ─────────────────────────────────────────────
String _encodeBackupPayload(Map<String, dynamic> data) => jsonEncode(data);

Object? _decodeBackupPayload(String contents) => jsonDecode(contents);

class BackupService {
  static const _kLastBackupPath = 'last_backup_path';
  static const _kLastBackupTime = 'last_backup_time';

  static const int backupSchemaVersion = 1;
  static const String appVersion = '2.0.0';

  // ── Standard tables (use getRawTableRows → insertRawRow) ──────
  static const List<String> standardTables = [
    DatabaseService.tDayPlans,
    DatabaseService.tStudyPlan,
    DatabaseService.tFmgeEntries,
    DatabaseService.tTimeLogs,
    DatabaseService.tDailyTracker,
    DatabaseService.tStudyEntries,
    DatabaseService.tStudyMaterials,
    DatabaseService.tMentorMessages,
    DatabaseService.tMentorMemory,
    DatabaseService.tAiSettings,
    DatabaseService.tUserProfile,
    DatabaseService.tSettings,
    DatabaseService.tHistory,
    DatabaseService.tRevisionSettings,
    DatabaseService.tRevisionItems,
    DatabaseService.tFaPages,
    DatabaseService.tSketchyItems,
    DatabaseService.tPathomaItems,
    DatabaseService.tUworldSessions,
    DatabaseService.tRoutines,
    DatabaseService.tRoutineLogs,
    DatabaseService.tBuyingItems,
    DatabaseService.tTodoItems,
    DatabaseService.tDefaultRoutineOrder,
    DatabaseService.tDailyFlows,
    DatabaseService.tLibraryNotes,
    DatabaseService.tKnowledgeBase,
    DatabaseService.tStreakData,
  ];

  // ── Special-structure tables (use model toMap/fromMap) ─────────
  static const List<String> specialTables = [
    DatabaseService.tSketchyMicroVideos,
    DatabaseService.tSketchyPharmVideos,
    DatabaseService.tPathomaChapters,
    DatabaseService.tUworldTopics,
    DatabaseService.tFaSubtopics,
    DatabaseService.tActivityLogs,
  ];

  // ═════════════════════════════════════════════════════════════════
  // SHARED PREFERENCES HELPERS
  // ═════════════════════════════════════════════════════════════════


  /// Record last backup path + time in SharedPreferences.
  static Future<void> _recordBackupInfo(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupPath, path);
    await prefs.setString(_kLastBackupTime, DateTime.now().toIso8601String());
  }

  /// Get last backup timestamp.
  static Future<DateTime?> lastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_kLastBackupTime);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Get last backup path.
  static Future<String?> getLastBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastBackupPath);
  }

  // ═════════════════════════════════════════════════════════════════
  // BUILD BACKUP DATA — reads from DB directly, covers all 34 tables
  // ═════════════════════════════════════════════════════════════════

  /// Build the complete backup payload asynchronously from the database.
  static Future<Map<String, dynamic>> buildBackupData() async {
    final db = DatabaseService.instance;
    final tables = <String, dynamic>{};

    // ── 28 standard tables ──────────────────────────────────────
    for (final table in standardTables) {
      tables[table] = await db.getRawTableRows(table);
    }

    // ── 6 special-structure tables ──────────────────────────────
    final microVideos = await db.getSketchyMicroVideos();
    tables[DatabaseService.tSketchyMicroVideos] =
        microVideos.map((v) => v.toMap()).toList();

    final pharmVideos = await db.getSketchyPharmVideos();
    tables[DatabaseService.tSketchyPharmVideos] =
        pharmVideos.map((v) => v.toMap()).toList();

    final chapters = await db.getPathomaChapters();
    tables[DatabaseService.tPathomaChapters] =
        chapters.map((c) => c.toMap()).toList();

    final topics = await db.getUWorldTopics();
    tables[DatabaseService.tUworldTopics] =
        topics.map((t) => t.toMap()).toList();

    final subtopics = await db.getAllFASubtopics();
    tables[DatabaseService.tFaSubtopics] =
        subtopics.map((s) => s.toJson()).toList();

    final logs = await db.getAllActivityLogs();
    tables[DatabaseService.tActivityLogs] =
        logs.map((l) => l.toMap()).toList();

    // ── SharedPreferences ───────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final spMap = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is List<String>) {
        spMap[key] = {'_type': 'StringList', '_value': value};
      } else {
        spMap[key] = value;
      }
    }

    return {
      'backup_schema_version': backupSchemaVersion,
      'app_version': appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'db_version': DatabaseService.dbVersion,
      'tables': tables,
      'shared_preferences': spMap,
    };
  }

  // ═════════════════════════════════════════════════════════════════
  // SAVE BACKUP TO FILE
  // ═════════════════════════════════════════════════════════════════

  /// Generate a timestamped backup filename.
  static String generateFileName() {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'focusflow_backup_$timestamp.ffbackup';
  }

  /// Write backup data to a temp directory for sharing.
  /// Returns the full path of the temp file.
  static Future<String> saveBackupToTemp(Map<String, dynamic> data) async {
    final dir = await getTemporaryDirectory();
    final fileName = generateFileName();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    final payload = await compute(_encodeBackupPayload, data);
    await file.writeAsString(payload);

    await _recordBackupInfo(filePath);
    return filePath;
  }

  /// Fallback: write to Documents/FocusFlow (used by auto-backup).
  static Future<String> saveBackupToDocuments(
      Map<String, dynamic> data) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final fileName = generateFileName();
    final filePath = '${backupDir.path}/$fileName';
    final file = File(filePath);

    final payload = await compute(_encodeBackupPayload, data);
    await file.writeAsString(payload);

    await _recordBackupInfo(filePath);
    return filePath;
  }

  // ═════════════════════════════════════════════════════════════════
  // READ & DECODE BACKUP FILE
  // ═════════════════════════════════════════════════════════════════

  /// Reads and decodes a backup file off the UI isolate.
  static Future<Map<String, dynamic>> readBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $filePath');
    }

    final contents = await file.readAsString();
    final decoded = await compute(_decodeBackupPayload, contents);
    if (decoded is! Map) {
      throw const FormatException(
          'Backup file does not contain a valid JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  /// Validate backup data structure. Returns null if valid, error message if not.
  static String? validateBackupData(Map<String, dynamic> data) {
    final version = data['backup_schema_version'];
    if (version == null) {
      return 'This file is not a valid FocusFlow backup (missing schema version).';
    }
    if (version is! int || version > backupSchemaVersion) {
      return 'This backup was created with a newer version of FocusFlow '
          '(schema v$version). Please update the app to restore it.';
    }
    if (data['tables'] is! Map) {
      return 'This backup file is corrupted (missing tables data).';
    }
    return null; // valid
  }

  /// Extract the exported_at timestamp from backup data, formatted for display.
  static String getExportedAtLabel(Map<String, dynamic> data) {
    final isoString = data['exported_at'] as String?;
    if (isoString == null) return 'Unknown date';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;
    return DateFormat('MMM d, yyyy – h:mm a').format(dt.toLocal());
  }

  // ═════════════════════════════════════════════════════════════════
  // RESTORE BACKUP DATA INTO DATABASE
  // ═════════════════════════════════════════════════════════════════

  /// Restore all data from a decoded backup map.
  /// Call this AFTER clearing the database.
  static Future<void> restoreFromBackupData(Map<String, dynamic> data) async {
    final db = DatabaseService.instance;
    final tables = data['tables'] as Map<String, dynamic>? ?? {};

    // ── 28 standard tables ──────────────────────────────────────
    for (final table in standardTables) {
      final rows = tables[table];
      if (rows is! List) continue;
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          await db.insertRawRow(table, Map<String, dynamic>.from(row));
        }
      }
    }

    // ── 6 special-structure tables ──────────────────────────────
    // Sketchy Micro Videos
    final microRows = tables[DatabaseService.tSketchyMicroVideos];
    if (microRows is List) {
      for (final row in microRows) {
        if (row is Map<String, dynamic>) {
          final video = SketchyVideo.fromMap(Map<String, dynamic>.from(row));
          await db.insertRawRow(
            DatabaseService.tSketchyMicroVideos,
            video.toMap()..remove('id'),
          );
        }
      }
    }

    // Sketchy Pharm Videos
    final pharmRows = tables[DatabaseService.tSketchyPharmVideos];
    if (pharmRows is List) {
      for (final row in pharmRows) {
        if (row is Map<String, dynamic>) {
          final video = SketchyVideo.fromMap(Map<String, dynamic>.from(row));
          await db.insertRawRow(
            DatabaseService.tSketchyPharmVideos,
            video.toMap()..remove('id'),
          );
        }
      }
    }

    // Pathoma Chapters
    final pathomaRows = tables[DatabaseService.tPathomaChapters];
    if (pathomaRows is List) {
      for (final row in pathomaRows) {
        if (row is Map<String, dynamic>) {
          final chapter =
              PathomaChapter.fromMap(Map<String, dynamic>.from(row));
          await db.insertRawRow(
            DatabaseService.tPathomaChapters,
            chapter.toMap()..remove('id'),
          );
        }
      }
    }

    // UWorld Topics
    final uworldRows = tables[DatabaseService.tUworldTopics];
    if (uworldRows is List) {
      for (final row in uworldRows) {
        if (row is Map<String, dynamic>) {
          final topic = UWorldTopic.fromMap(Map<String, dynamic>.from(row));
          final map = topic.toMap();
          map.remove('id');
          await db.insertRawRow(DatabaseService.tUworldTopics, map);
        }
      }
    }

    // FA Subtopics
    final faSubRows = tables[DatabaseService.tFaSubtopics];
    if (faSubRows is List) {
      for (final row in faSubRows) {
        if (row is Map<String, dynamic>) {
          final sub = FASubtopic.fromJson(Map<String, dynamic>.from(row));
          await db.insertRawRow(DatabaseService.tFaSubtopics, {
            'pageNum': sub.pageNum,
            'name': sub.name,
            'status': sub.status,
            'firstReadAt': sub.firstReadAt,
            'ankiDoneAt': sub.ankiDoneAt,
            'revisionCount': sub.revisionCount,
            'lastRevisedAt': sub.lastRevisedAt,
            'revisionHistory':
                jsonEncode(sub.revisionHistory.map((r) => r.toJson()).toList()),
          });
        }
      }
    }

    // Activity Logs
    final activityRows = tables[DatabaseService.tActivityLogs];
    if (activityRows is List) {
      for (final row in activityRows) {
        if (row is Map<String, dynamic>) {
          final entry =
              ActivityLogEntry.fromMap(Map<String, dynamic>.from(row));
          await db.insertActivityLog(entry);
        }
      }
    }

    // ── Restore SharedPreferences ───────────────────────────────
    final spMap = data['shared_preferences'] as Map<String, dynamic>?;
    if (spMap != null) {
      final prefs = await SharedPreferences.getInstance();


      for (final entry in spMap.entries) {
        final key = entry.key;
        final value = entry.value;



        try {
          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is Map &&
              value['_type'] == 'StringList' &&
              value['_value'] is List) {
            await prefs.setStringList(
              key,
              (value['_value'] as List).cast<String>(),
            );
          } else if (value is List) {
            // Legacy format: plain list
            await prefs.setStringList(key, value.cast<String>());
          }
        } catch (_) {
          // Skip keys that can't be restored
        }
      }


    }
  }

  // ═════════════════════════════════════════════════════════════════
  // LEGACY COMPAT — keep old callers working during transition
  // ═════════════════════════════════════════════════════════════════

  /// Returns the Documents/FocusFlow folder (always writable).
  static Future<String> getBackupFolder() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// Quick save to Documents/FocusFlow (used by auto-backup trigger).
  static Future<String> saveBackup(Map<String, dynamic> data, {
    String filePrefix = 'focusflow_backup',
  }) async {
    final folder = await getBackupFolder();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '$folder/${filePrefix}_$timestamp.ffbackup';
    final file = File(filePath);
    final payload = await compute(_encodeBackupPayload, data);
    await file.writeAsString(payload);
    await _recordBackupInfo(filePath);
    return filePath;
  }
}
