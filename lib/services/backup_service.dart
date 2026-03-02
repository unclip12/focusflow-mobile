// =============================================================
// BackupService — Save / load full app state as JSON
// Uses path_provider (already in pubspec) + dart:io + dart:convert
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';

class BackupService {
  static const _fileName = 'focusflow_backup.json';

  /// Returns the default or user-selected backup folder
  static Future<String> getBackupFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final folder = prefs.getString('backup_folder');
    if (folder != null && folder.isNotEmpty) {
      final dir = Directory(folder);
      if (await dir.exists()) return folder;
    }
    // Default: Documents/FocusFlow
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// Returns the static path for the old single-file backup logic.
  static Future<String> get _filePath async {
    final folder = await getBackupFolder();
    return '$folder/$_fileName';
  }

  /// Save full app state to JSON file with timestamp.
  /// Returns the exact file path where it was saved.
  static Future<String> saveBackup(Map<String, dynamic> data) async {
    final folder = await getBackupFolder();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '$folder/focusflow_backup_$timestamp.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
    return filePath;
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
