// =============================================================
// BackupScreen — Auto Backup, Export, Restore, History
// Auto-backup setting & history persisted in SharedPreferences
// Restore is wired to AppProvider.restoreFromBackup()
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
import 'package:focusflow_mobile/screens/backup/backup_history_card.dart';
import 'package:focusflow_mobile/screens/backup/restore_confirm_dialog.dart';

// ── SharedPrefs keys ────────────────────────────────────────────
const _kAutoBackup = 'backup_auto';
const _kFrequency  = 'backup_frequency';
const _kHistory    = 'backup_history'; // JSON list of {date,size}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _autoBackup      = false;
  String _backupFrequency = 'Daily';
  bool _exporting       = false;
  bool _restoring       = false;
  bool _prefsLoaded     = false;

  final List<_BackupEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ── Load persisted settings & history ──────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHistory = prefs.getStringList(_kHistory) ?? [];
    final entries = rawHistory.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return _BackupEntry(date: m['date'] as String, size: m['size'] as String);
    }).toList();

    if (!mounted) return;
    setState(() {
      _autoBackup       = prefs.getBool(_kAutoBackup) ?? false;
      _backupFrequency  = prefs.getString(_kFrequency) ?? 'Daily';
      _history.addAll(entries);
      _prefsLoaded      = true;
    });
  }

  // ── Persist settings & history ─────────────────────────────────
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackup, _autoBackup);
    await prefs.setString(_kFrequency, _backupFrequency);
    final rawHistory = _history
        .map((e) => jsonEncode({'date': e.date, 'size': e.size}))
        .toList();
    await prefs.setStringList(_kHistory, rawHistory);
  }

  // ── Export backup as JSON ──────────────────────────────────────
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
          size: '$sizeKb KB',
        );
        setState(() {
          _history.insert(0, entry);
          if (_history.length > 5) _history.removeLast();
        });
        await _savePrefs();
        _showSnack('Backup exported successfully');
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Quick internal save (auto-backup) ─────────────────────────
  Future<void> _runAutoBackup() async {
    try {
      final ap = context.read<AppProvider>();
      final data = BackupService.buildBackupData(ap);
      await BackupService.saveBackup(data);

      final sizeKb = (jsonEncode(data).length / 1024).toStringAsFixed(1);
      final entry = _BackupEntry(
        date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        size: '$sizeKb KB (auto)',
      );
      setState(() {
        _history.insert(0, entry);
        if (_history.length > 5) _history.removeLast();
      });
      await _savePrefs();
    } catch (_) {}
  }

  // ── Restore from JSON file ─────────────────────────────────────
  Future<void> _pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    if (!mounted) return;
    RestoreConfirmDialog.show(context, () => _doRestore(path));
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
                            style: theme.textTheme.labelSmall?.copyWith(
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
                          // Run a backup immediately when enabled
                          await _runAutoBackup();
                          if (mounted) {
                            _showSnack('Auto backup enabled — first backup saved');
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
          // MANUAL BACKUP / RESTORE
          // ════════════════════════════════════════════════════════
          _sectionLabel('Manual', theme, cs),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.upload_file_rounded,
                  label: 'Export Backup',
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
              return BackupHistoryCard(
                date: item.date,
                size: item.size,
                onRestore: () {
                  RestoreConfirmDialog.show(context, () {
                    _showSnack('Use "Restore" button to load a saved backup file');
                  });
                },
                onDelete: () {
                  HapticFeedback.lightImpact();
                  setState(() => _history.removeAt(idx));
                  _savePrefs();
                  _showSnack('Backup entry removed');
                },
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
  const _BackupEntry({required this.date, required this.size});
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
