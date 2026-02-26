// =============================================================
// BackupService — Save / load full app state as JSON
// Uses path_provider (already in pubspec) + dart:io + dart:convert
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';

class BackupService {
  static const _fileName = 'focusflow_backup.json';

  /// Returns the backup file path (app documents directory).
  static Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  /// Save full app state to JSON file.
  static Future<void> saveBackup(Map<String, dynamic> data) async {
    final path = await _filePath;
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }

  /// Load backup from JSON file — returns null if not found.
  static Future<Map<String, dynamic>?> loadBackup() async {
    final path = await _filePath;
    final file = File(path);
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  }

  /// Delete backup file.
  static Future<void> deleteBackup() async {
    final path = await _filePath;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Get last modified time of backup file.
  static Future<DateTime?> lastBackupTime() async {
    final path = await _filePath;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.lastModified();
  }

  /// Build the full backup map from AppProvider.
  static Map<String, dynamic> buildBackupData(AppProvider app) {
    return {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'faPages': app.faPages.map((e) => e.toJson()).toList(),
      'sketchyItems': app.sketchyItems.map((e) => e.toJson()).toList(),
      'pathomaItems': app.pathomaItems.map((e) => e.toJson()).toList(),
      'uWorldSessions': app.uWorldSessions.map((e) => e.toJson()).toList(),
      'timeLogs': app.timeLogs.map((e) => e.toJson()).toList(),
      'revisionItems': app.revisionItems.map((e) => e.toJson()).toList(),
      'dayPlans': app.dayPlans.map((e) => e.toJson()).toList(),
    };
  }
}
