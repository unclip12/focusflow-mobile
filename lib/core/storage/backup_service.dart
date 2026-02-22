import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class BackupSnapshot {
  final String id;
  final String label;
  final DateTime createdAt;
  final bool isAuto;
  final Map<String, dynamic> data;

  const BackupSnapshot({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.isAuto,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'isAuto': isAuto,
        'data': data,
      };

  factory BackupSnapshot.fromJson(Map m) => BackupSnapshot(
        id: m['id'],
        label: m['label'],
        createdAt: DateTime.parse(m['createdAt']),
        isAuto: m['isAuto'] ?? false,
        data: Map<String, dynamic>.from(m['data'] ?? {}),
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final backupSnapshotsProvider =
    StateNotifierProvider<BackupNotifier, List<BackupSnapshot>>(
        (ref) => BackupNotifier());

class BackupNotifier extends StateNotifier<List<BackupSnapshot>> {
  BackupNotifier() : super([]) { _load(); }

  static const _maxSnapshots = 30;
  Box get _box => Hive.box('backups');

  void _load() {
    final raw = _box.get('snapshots');
    if (raw == null) return;
    state = (raw as List)
        .map((e) => BackupSnapshot.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _save() =>
      _box.put('snapshots', state.map((s) => s.toJson()).toList());

  void add(BackupSnapshot snap) {
    var list = [snap, ...state];
    if (list.length > _maxSnapshots) {
      // Remove oldest auto-snapshot first, then oldest overall
      final lastAutoIdx = list.lastIndexWhere((s) => s.isAuto);
      if (lastAutoIdx != -1) {
        list.removeAt(lastAutoIdx);
      } else {
        list = list.take(_maxSnapshots).toList();
      }
    }
    state = list;
    _save();
  }

  void delete(String id) {
    state = state.where((s) => s.id != id).toList();
    _save();
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

final backupServiceProvider = Provider((_) => BackupService());

class BackupService {
  static const _autoSyncKey = 'auto_sync_enabled';
  static const _apiKeyKey   = 'gemini_api_key';
  static const _boxNames    = [
    'todays_plan', 'knowledge_base', 'fa_logger',
    'focus_timer', 'time_logger',    'fmge',
    'revision',    'analytics',
  ];

  final _uuid = const Uuid();

  // ── Settings prefs ────────────────────────────────────────────────────────

  Future<bool>   isAutoSyncEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_autoSyncKey) ?? true;

  Future<void>   setAutoSync(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_autoSyncKey, v);

  Future<String> getApiKey() async =>
      (await SharedPreferences.getInstance()).getString(_apiKeyKey) ?? '';

  Future<void>   setApiKey(String key) async =>
      (await SharedPreferences.getInstance()).setString(_apiKeyKey, key);

  // ── Data capture / restore ────────────────────────────────────────────────

  Map<String, dynamic> _captureAll() {
    final out = <String, dynamic>{};
    for (final name in _boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      final box = Hive.box(name);
      final boxData = <String, dynamic>{};
      for (final key in box.keys) {
        try {
          // Normalize through JSON round-trip to strip Hive internals
          boxData[key.toString()] =
              jsonDecode(jsonEncode(box.get(key)));
        } catch (_) {
          boxData[key.toString()] = box.get(key)?.toString();
        }
      }
      out[name] = boxData;
    }
    return out;
  }

  Future<void> _restoreAll(Map<String, dynamic> data) async {
    for (final name in data.keys) {
      if (!Hive.isBoxOpen(name)) continue;
      final box = Hive.box(name);
      await box.clear();
      final boxData = Map<String, dynamic>.from(data[name] ?? {});
      for (final e in boxData.entries) {
        await box.put(e.key, e.value);
      }
    }
  }

  // ── Snapshot actions ──────────────────────────────────────────────────────

  BackupSnapshot createSnapshot({bool isAuto = false}) {
    final now = DateTime.now();
    final tag = isAuto ? 'Auto' : 'Manual';
    final label =
        '$tag \u2022 ${now.day}/${now.month}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    return BackupSnapshot(
      id: _uuid.v4(),
      label: label,
      createdAt: now,
      isAuto: isAuto,
      data: _captureAll(),
    );
  }

  Future<void> restoreSnapshot(BackupSnapshot snap) =>
      _restoreAll(snap.data);

  Future<void> exportToFile(BackupSnapshot snap) async {
    final json = const JsonEncoder.withIndent('  ').convert(snap.toJson());
    final dir  = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/focusflow_backup_${snap.createdAt.millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
        [XFile(file.path)], text: 'FocusFlow Backup \u2022 ${snap.label}');
  }

  Future<BackupSnapshot?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;
    final content = await File(path).readAsString();
    return BackupSnapshot.fromJson(
        jsonDecode(content) as Map<String, dynamic>);
  }
}
