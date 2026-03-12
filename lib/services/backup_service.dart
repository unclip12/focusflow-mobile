// =============================================================
// BackupService - Save / load full app state as JSON
// Uses path_provider (already in pubspec) + dart:io + dart:convert
// NOTE: On Android, SAF URIs (content://) cannot be used with
//       dart:io File directly. We always write to the app's
//       Documents/FocusFlow directory which is always writable.
//       The user-selected folder URI is stored for display only.
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';

String _encodeBackupPayload(Map<String, dynamic> data) => jsonEncode(data);

Object? _decodeBackupPayload(String contents) => jsonDecode(contents);

class BackupService {
  static const _kBackupFolderUri = 'backup_folder_uri';

  /// Save the user-selected folder label to SharedPreferences (display only).
  static Future<void> setBackupFolderUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackupFolderUri, uri);
  }

  /// Read the saved backup folder label from SharedPreferences.
  static Future<String?> getBackupFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBackupFolderUri);
  }

  /// Always returns a writable path under Documents/FocusFlow.
  /// SAF URIs (content://) cannot be used with dart:io File on Android.
  static Future<String> getBackupFolder() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// Save full app state to Documents/FocusFlow with a timestamp filename.
  static Future<String> saveBackup(
    Map<String, dynamic> data, {
    String filePrefix = 'focusflow_backup',
  }) async {
    final folder = await getBackupFolder();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '$folder/${filePrefix}_$timestamp.json';
    final file = File(filePath);
    final payload = await compute(_encodeBackupPayload, data);
    await file.writeAsString(payload);
    return filePath;
  }

  /// Returns the newest JSON backup file in Documents/FocusFlow.
  static Future<File?> getLatestBackupFile() async {
    final folder = Directory(await getBackupFolder());
    final entities = await folder.list().toList();
    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'))
        .toList();

    if (files.isEmpty) return null;

    final fileStats = await Future.wait(
      files.map((file) async => MapEntry(file, await file.stat())),
    );
    fileStats.sort((a, b) => b.value.modified.compareTo(a.value.modified));
    return fileStats.first.key;
  }

  /// Returns the newest JSON backup path in Documents/FocusFlow.
  static Future<String?> getLatestBackupPath() async {
    final latestFile = await getLatestBackupFile();
    return latestFile?.path;
  }

  /// Reads and decodes a backup JSON file off the UI isolate.
  static Future<Map<String, dynamic>> restoreBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $filePath');
    }

    final contents = await file.readAsString();
    final decoded = await compute(_decodeBackupPayload, contents);
    if (decoded is! Map) {
      throw const FormatException(
          'Backup file does not contain a JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  /// Load the latest backup from Documents/FocusFlow.
  static Future<Map<String, dynamic>?> loadBackup() async {
    final path = await getLatestBackupPath();
    if (path == null) return null;
    return restoreBackup(path);
  }

  /// Delete the newest backup file.
  static Future<void> deleteBackup() async {
    final path = await getLatestBackupPath();
    if (path == null) return;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get last modified time of the newest backup file.
  static Future<DateTime?> lastBackupTime() async {
    final path = await getLatestBackupPath();
    if (path == null) return null;

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
