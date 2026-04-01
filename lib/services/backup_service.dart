import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/services/attachment_storage_service.dart';
import 'package:focusflow_mobile/services/database_service.dart';

String _encodeBackupPayload(Map<String, dynamic> data) => jsonEncode(data);

Object? _decodeBackupPayload(String contents) => jsonDecode(contents);

class _BackupAttachmentAsset {
  final String originalPath;
  final String archivePath;
  final String fileName;

  const _BackupAttachmentAsset({
    required this.originalPath,
    required this.archivePath,
    required this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'original_path': originalPath,
        'archive_path': archivePath,
        'file_name': fileName,
      };

  factory _BackupAttachmentAsset.fromJson(Map<String, dynamic> json) {
    return _BackupAttachmentAsset(
      originalPath: json['original_path'] as String? ?? '',
      archivePath: json['archive_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
    );
  }
}

class BackupService {
  static const _kLastBackupPath = 'last_backup_path';
  static const _kLastBackupTime = 'last_backup_time';
  static const _manifestFileName = 'manifest.json';
  static const _attachmentsRoot = 'attachments';

  static const int backupSchemaVersion = 2;
  static const String appVersion = '2.0.0';

  static Future<void> _recordBackupInfo(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupPath, path);
    await prefs.setString(_kLastBackupTime, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> lastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_kLastBackupTime);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  static Future<String?> getLastBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastBackupPath);
  }

  static Future<Map<String, dynamic>> buildBackupData() async {
    final db = DatabaseService.instance;
    final tables = <String, dynamic>{};

    for (final table in await db.getUserTableNames()) {
      tables[table] = await db.getRawTableRows(table);
    }

    final sharedPreferences = await _collectSharedPreferences();
    final attachments = await _collectAttachmentAssets(tables);

    return {
      'backup_schema_version': backupSchemaVersion,
      'app_version': appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'db_version': DatabaseService.dbVersion,
      'tables': tables,
      'shared_preferences': sharedPreferences,
      'attachments': attachments.map((asset) => asset.toJson()).toList(),
    };
  }

  static Future<Map<String, dynamic>> _collectSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is List<String>) {
        values[key] = {'_type': 'StringList', '_value': value};
      } else {
        values[key] = value;
      }
    }
    return values;
  }

  static Future<List<_BackupAttachmentAsset>> _collectAttachmentAssets(
    Map<String, dynamic> tables,
  ) async {
    final rows = tables[DatabaseService.tLibraryNotes];
    if (rows is! List) return const [];

    final assets = <_BackupAttachmentAsset>[];
    final seenPaths = <String>{};
    var index = 0;

    for (final row in rows) {
      if (row is! Map) continue;
      final data = row['data'];
      if (data is! String || data.isEmpty) continue;

      try {
        final decoded = jsonDecode(data);
        if (decoded is! Map) continue;
        final note = LibraryNote.fromJson(Map<String, dynamic>.from(decoded));
        for (final attachmentPath in note.attachmentPaths) {
          final trimmedPath = attachmentPath.trim();
          if (trimmedPath.isEmpty ||
              AttachmentStorageService.isWebLink(trimmedPath) ||
              !seenPaths.add(trimmedPath)) {
            continue;
          }
          final file = File(trimmedPath);
          if (!await file.exists()) continue;

          index++;
          assets.add(
            _BackupAttachmentAsset(
              originalPath: trimmedPath,
              archivePath:
                  '$_attachmentsRoot/${AttachmentStorageService.buildArchiveFileName(index, trimmedPath)}',
              fileName: file.uri.pathSegments.isNotEmpty
                  ? file.uri.pathSegments.last
                  : 'attachment_$index',
            ),
          );
        }
      } catch (_) {
        // Keep backup resilient even if one note row is malformed.
      }
    }

    return assets;
  }

  static List<_BackupAttachmentAsset> _attachmentAssetsFromData(
    Map<String, dynamic> data,
  ) {
    final rawAssets = data['attachments'];
    if (rawAssets is! List) return const [];

    final assets = <_BackupAttachmentAsset>[];
    for (final rawAsset in rawAssets) {
      if (rawAsset is! Map) continue;
      assets.add(
        _BackupAttachmentAsset.fromJson(Map<String, dynamic>.from(rawAsset)),
      );
    }
    return assets;
  }

  static String generateFileName() {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'focusflow_backup_$timestamp.ffbackup';
  }

  static Future<Uint8List> buildBackupFileBytes(
    Map<String, dynamic> data,
  ) async {
    final archive = Archive();
    final manifestJson = await compute(_encodeBackupPayload, data);
    archive.addFile(ArchiveFile.string(_manifestFileName, manifestJson));

    for (final asset in _attachmentAssetsFromData(data)) {
      final file = File(asset.originalPath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile.bytes(asset.archivePath, bytes));
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<String> saveBackupToTemp(Map<String, dynamic> data) async {
    final dir = await getTemporaryDirectory();
    final fileName = generateFileName();
    final filePath = '${dir.path}/$fileName';
    await _writeBackupFile(data, filePath);
    return filePath;
  }

  static Future<String> saveBackupToDocuments(
    Map<String, dynamic> data,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final fileName = generateFileName();
    final filePath = '${backupDir.path}/$fileName';
    await _writeBackupFile(data, filePath);
    return filePath;
  }

  static Future<void> _writeBackupFile(
    Map<String, dynamic> data,
    String filePath,
  ) async {
    final file = File(filePath);
    final payload = await buildBackupFileBytes(data);
    await file.writeAsBytes(payload, flush: true);
    await _recordBackupInfo(filePath);
  }

  static Future<Map<String, dynamic>> readBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    if (_looksLikeZip(bytes)) {
      return _readZipBackup(bytes);
    }

    final contents = utf8.decode(bytes);
    final decoded = await compute(_decodeBackupPayload, contents);
    if (decoded is! Map) {
      throw const FormatException(
        'Backup file does not contain a valid JSON object.',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  static bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
        (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
  }

  static Future<Map<String, dynamic>> _readZipBackup(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile(_manifestFileName);
    if (manifestFile == null || !manifestFile.isFile) {
      throw const FormatException('Backup archive is missing manifest.json.');
    }

    final manifestString = utf8.decode(manifestFile.content);
    final decodedManifest = await compute(_decodeBackupPayload, manifestString);
    if (decodedManifest is! Map) {
      throw const FormatException('Backup manifest is corrupted.');
    }

    final data = Map<String, dynamic>.from(decodedManifest);
    final attachmentBytes = <String, List<int>>{};
    for (final file in archive) {
      if (!file.isFile || !file.name.startsWith('$_attachmentsRoot/')) {
        continue;
      }
      attachmentBytes[file.name] = List<int>.from(file.content);
    }
    data['_attachment_bytes'] = attachmentBytes;
    return data;
  }

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
    return null;
  }

  static String getExportedAtLabel(Map<String, dynamic> data) {
    final isoString = data['exported_at'] as String?;
    if (isoString == null) return 'Unknown date';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;
    return DateFormat('MMM d, yyyy – h:mm a').format(dt.toLocal());
  }

  static Future<void> restoreFromBackupData(Map<String, dynamic> data) async {
    final db = DatabaseService.instance;
    final tables = data['tables'] as Map<String, dynamic>? ?? {};
    final attachmentPathMap = await _restoreAttachmentFiles(data);

    for (final entry in tables.entries) {
      final rows = entry.value;
      if (rows is! List) continue;

      for (final row in rows) {
        if (row is! Map) continue;
        final restoredRow = await _prepareRowForRestore(
          table: entry.key,
          row: Map<String, dynamic>.from(row),
          attachmentPathMap: attachmentPathMap,
        );
        await db.insertRawRow(entry.key, restoredRow);
      }
    }

    await _restoreSharedPreferences(data);
  }

  static Future<Map<String, String>> _restoreAttachmentFiles(
    Map<String, dynamic> data,
  ) async {
    final restoredPaths = <String, String>{};
    final attachmentBytesRaw = data['_attachment_bytes'];
    if (attachmentBytesRaw is! Map) return restoredPaths;

    final attachmentBytes = <String, List<int>>{};
    for (final entry in attachmentBytesRaw.entries) {
      if (entry.key is! String) continue;
      final value = entry.value;
      if (value is Uint8List) {
        attachmentBytes[entry.key as String] = value;
      } else if (value is List<int>) {
        attachmentBytes[entry.key as String] = value;
      } else if (value is List) {
        attachmentBytes[entry.key as String] = value.cast<int>();
      }
    }

    for (final asset in _attachmentAssetsFromData(data)) {
      final bytes = attachmentBytes[asset.archivePath];
      if (bytes == null) continue;
      final restoredPath = await AttachmentStorageService.writeRestoredAttachment(
        originalPath: asset.originalPath,
        suggestedFileName: asset.fileName,
        bytes: bytes,
      );
      restoredPaths[asset.originalPath] = restoredPath;
    }

    return restoredPaths;
  }

  static Future<Map<String, dynamic>> _prepareRowForRestore({
    required String table,
    required Map<String, dynamic> row,
    required Map<String, String> attachmentPathMap,
  }) async {
    if (table != DatabaseService.tLibraryNotes || attachmentPathMap.isEmpty) {
      return row;
    }

    final encodedData = row['data'];
    if (encodedData is! String || encodedData.isEmpty) {
      return row;
    }

    try {
      final decodedData = jsonDecode(encodedData);
      if (decodedData is! Map) return row;
      final note = LibraryNote.fromJson(Map<String, dynamic>.from(decodedData));
      final restoredPaths = note.attachmentPaths
          .map((path) => attachmentPathMap[path] ?? path)
          .toList();
      final restoredNote = note.copyWith(attachmentPaths: restoredPaths);
      row['data'] = jsonEncode(restoredNote.toJson());
    } catch (_) {
      // Preserve the row as-is if it cannot be rewritten.
    }

    return row;
  }

  static Future<void> _restoreSharedPreferences(
    Map<String, dynamic> data,
  ) async {
    final spMap = data['shared_preferences'] as Map<String, dynamic>?;
    if (spMap == null) return;

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
          await prefs.setStringList(key, value.cast<String>());
        }
      } catch (_) {
        // Skip keys that cannot be restored.
      }
    }
  }

  static Future<String> getBackupFolder() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/FocusFlow');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  static Future<String> saveBackup(
    Map<String, dynamic> data, {
    String filePrefix = 'focusflow_backup',
  }) async {
    final folder = await getBackupFolder();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '$folder/${filePrefix}_$timestamp.ffbackup';
    await _writeBackupFile(data, filePath);
    return filePath;
  }
}
