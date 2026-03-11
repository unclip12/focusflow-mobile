// =============================================================
// BackupScreen — Backup Now, Auto Backup, Export, Restore
// Saves to user-selected folder (Documents/FocusFlow default)
// Auto-backup & history persisted in SharedPreferences
// Restore wired to AppProvider.restoreFromBackup()
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/backup_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';

// ── SharedPrefs keys ────────────────────────────────────────────
const _kAutoBackup = 'backup_auto';
const _kFrequency = 'backup_frequency';
const _kHistory = 'backup_history'; // JSON list of {date,size,path}
const _kBackupFolder = 'backup_folder_uri';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _autoBackup = false;
  String _backupFrequency = 'Daily';
  bool _exporting = false;
  bool _restoring = false;
  bool _backingUp = false;
  bool _prefsLoaded = false;
  String? _backupFolder; // user-selected folder path

  final List<_BackupEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ── Load persisted settings & history ──────────────────────────
  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawHistory = prefs.getStringList(_kHistory) ?? [];
      final entries = rawHistory
          .map((s) {
            try {
              final m = jsonDecode(s) as Map<String, dynamic>;
              return _BackupEntry(
                date: m['date'] as String? ?? '',
                size: m['size'] as String? ?? '',
                path: m['path'] as String?,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<_BackupEntry>()
          .toList();

      if (!mounted) return;
      setState(() {
        _autoBackup = prefs.getBool(_kAutoBackup) ?? false;
        _backupFrequency = prefs.getString(_kFrequency) ?? 'Daily';
        _backupFolder = prefs.getString(_kBackupFolder);
        _history.addAll(entries);
        _prefsLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _prefsLoaded = true);
        _showSnack('Failed to load settings: $e');
      }
    }
  }

  // ── Persist settings & history ─────────────────────────────────
  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoBackup, _autoBackup);
      await prefs.setString(_kFrequency, _backupFrequency);
      if (_backupFolder != null) {
        await prefs.setString(_kBackupFolder, _backupFolder!);
      }
      final rawHistory = _history
          .map((e) =>
              jsonEncode({'date': e.date, 'size': e.size, 'path': e.path}))
          .toList();
      await prefs.setStringList(_kHistory, rawHistory);
    } catch (_) {}
  }

  // ── Select backup folder (SAF folder picker on Android) ────────
  Future<void> _pickBackupFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Folder',
      );
      if (result != null && result.isNotEmpty) {
        setState(() => _backupFolder = result);
        await BackupService.setBackupFolderUri(result);
        await _savePrefs();
        if (mounted) {
          _showSnack('Backup folder set: $result');
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Could not select folder: $e');
    }
  }

  // ── Backup Now — saves to the backup folder ────────────────────
  Future<void> _handleBackupNowPressed() async {
    try {
      await _backupNow();
    } catch (e) {
      if (mounted) {
        _showSnack('Backup failed: $e');
      }
    }
  }

  Future<void> _backupNow() async {
    setState(() => _backingUp = true);
    HapticFeedback.lightImpact();

    try {
      final ap = context.read<AppProvider>();
      final data = BackupService.buildBackupData(ap);
      final filePath = await BackupService.saveBackup(data);
      final sizeKb = (jsonEncode(data).length / 1024).toStringAsFixed(1);
      final entry = _BackupEntry(
        date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        size: '$sizeKb KB',
        path: filePath,
      );

      if (!mounted) return;
      setState(() {
        _history.insert(0, entry);
        if (_history.length > 10) _history.removeLast();
      });
      await _savePrefs();
      if (mounted) {
        _showSnack('Backup saved to $filePath');
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  // ── Export backup via share sheet ───────────────────────────────
  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    HapticFeedback.lightImpact();

    try {
      final ap = context.read<AppProvider>();
      final data = BackupService.buildBackupData(ap);
      final json = jsonEncode(data);

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/focusflow_backup_$timestamp.json');
      await file.writeAsString(json);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'FocusFlow Backup $timestamp',
        );

        final sizeKb = (json.length / 1024).toStringAsFixed(1);
        final entry = _BackupEntry(
          date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          size: '$sizeKb KB (exported)',
          path: file.path,
        );
        setState(() {
          _history.insert(0, entry);
          if (_history.length > 10) _history.removeLast();
        });
        await _savePrefs();
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Auto-backup internal save ──────────────────────────────────
  Future<void> _runAutoBackup() async {
    try {
      final ap = context.read<AppProvider>();
      final data = BackupService.buildBackupData(ap);
      final filePath = await BackupService.saveBackup(
        data,
        filePrefix: 'focusflow_auto',
      );
      final sizeKb = (jsonEncode(data).length / 1024).toStringAsFixed(1);
      final entry = _BackupEntry(
        date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        size: '$sizeKb KB (auto)',
        path: filePath,
      );
      setState(() {
        _history.insert(0, entry);
        if (_history.length > 10) _history.removeLast();
      });
      await _savePrefs();
    } catch (_) {}
  }

  // ── Restore from JSON file ─────────────────────────────────────
  Future<void> _pickAndRestore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      if (!mounted) return;
      _showRestoreConfirm(path);
    } catch (e) {
      if (mounted) _showSnack('Could not pick file: $e');
    }
  }

  void _showRestoreConfirm(String path) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Restore Backup?'),
          content: const Text(
            'This will replace all current data with the backup. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _doRestore(path);
              },
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _doRestore(String path) async {
    setState(() => _restoring = true);
    HapticFeedback.mediumImpact();

    try {
      final file = File(path);
      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      if (!mounted) return;
      final app = context.read<AppProvider>();
      await app.restoreFromBackup(data);

      if (mounted) _showSnack('✅ Data restored successfully');
    } catch (e) {
      if (mounted) _showSnack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final frequencies = ['Daily', 'Weekly', 'Manual'];

    if (!_prefsLoaded) {
      return AppScaffold(
        screenName: 'Backup & Restore',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      screenName: 'Backup & Restore',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ════════════════════════════════════════════════════════
          // BACKUP NOW — primary action
          // ════════════════════════════════════════════════════════
          _sectionLabel('Quick Backup', theme, cs),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _backingUp ? null : _handleBackupNowPressed,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.12),
                    cs.primary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _backingUp
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Icon(Icons.backup_rounded,
                            size: 24, color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup Now',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _backupFolder != null
                              ? 'Saves to: ${_backupFolder!.split('/').last}'
                              : 'Saves to Documents/FocusFlow',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: cs.primary.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Change folder button
          TextButton.icon(
            onPressed: _pickBackupFolder,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Change Backup Folder'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 20),

          // ════════════════════════════════════════════════════════
          // AUTO BACKUP
          // ════════════════════════════════════════════════════════
          _sectionLabel('Auto Backup', theme, cs),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor(cs),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_sync_rounded,
                          size: 20, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Automatic Backup',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                          Text(
                            _autoBackup
                                ? 'Saves to device storage — $_backupFrequency'
                                : 'Disabled',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _autoBackup,
                      onChanged: (v) async {
                        HapticFeedback.selectionClick();
                        setState(() => _autoBackup = v);
                        await _savePrefs();
                        if (v) {
                          await _runAutoBackup();
                          if (mounted) {
                            _showSnack(
                                'Auto backup enabled — first backup saved');
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (_autoBackup) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: frequencies.map((f) {
                      final selected = _backupFrequency == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() => _backupFrequency = f);
                            await _savePrefs();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : cs.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? cs.primary.withValues(alpha: 0.4)
                                    : cs.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                f,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.5),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ════════════════════════════════════════════════════════
          // MANUAL EXPORT / RESTORE
          // ════════════════════════════════════════════════════════
          _sectionLabel('Manual', theme, cs),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Export & Share',
                  color: cs.primary,
                  loading: _exporting,
                  onTap: _exportBackup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Restore',
                  color: Colors.orange.shade600,
                  loading: _restoring,
                  onTap: _pickAndRestore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ════════════════════════════════════════════════════════
          // BACKUP HISTORY
          // ════════════════════════════════════════════════════════
          _sectionLabel('Backup History', theme, cs),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: _cardDecor(cs),
              child: Center(
                child: Text(
                  'No backups yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            )
          else
            ..._history.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: _cardDecor(cs),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_done_rounded,
                          size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.date,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.size,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: cs.error.withValues(alpha: 0.6)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _history.removeAt(idx));
                        _savePrefs();
                        _showSnack('Backup entry removed');
                      },
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LOCAL MODELS + HELPERS
// ─────────────────────────────────────────────────────────────────

class _BackupEntry {
  final String date;
  final String size;
  final String? path;
  const _BackupEntry({required this.date, required this.size, this.path});
}

BoxDecoration _cardDecor(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
  );
}

Widget _sectionLabel(String label, ThemeData theme, ColorScheme cs) {
  return Text(
    label,
    style: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface.withValues(alpha: 0.5),
    ),
  );
}

// ── Action button with loading state ──────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
