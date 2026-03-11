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
  static const _kBackupFolderUri = 'backup_folder_uri';

  /// Save the user-selected SAF folder URI to SharedPreferences.
  static Future<void> setBackupFolderUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackupFolderUri, uri);
  }

  /// Read the saved backup folder URI from SharedPreferences.
  static Future<String?> getBackupFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBackupFolderUri);
  }

  /// Returns the user-selected backup folder, or a default under Documents.
  static Future<String> getBackupFolder() async {
    final uri = await getBackupFolderUri();
    if (uri != null && uri.isNotEmpty) {
      final dir = Directory(uri);
      if (await dir.exists()) return uri;
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

  /// Save full app state to the configured backup folder with a timestamp.
  static Future<String> saveBackup(
    Map<String, dynamic> data, {
    String filePrefix = 'focusflow_backup',
  }) async {
    final folder = await getBackupFolder();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '$folder/${filePrefix}_$timestamp.json';
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
