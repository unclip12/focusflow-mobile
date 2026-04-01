// =============================================================
// BackupScreen — Full backup & restore UI
// Creates .ffbackup files, platform-aware save/share,
// file picker restore with validation
// =============================================================

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/backup_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';

const _kAutoBackup = 'backup_auto';
const _kFrequency = 'backup_frequency';
const _kHistory = 'backup_history';

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
  bool _isLoading = false;
  String? _loadingMessage;


  final List<_BackupEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawHistory = prefs.getStringList(_kHistory) ?? [];
      final entries = rawHistory
          .map((s) {
            try {
              final m = _parseJson(s);
              return m == null
                  ? null
                  : _BackupEntry(
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
        _history
          ..clear()
          ..addAll(entries);
        _prefsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefsLoaded = true);
      _showSnack('Failed to load settings: ${_errorMessage(e)}', isError: true);
    }
  }

  Map<String, dynamic>? _parseJson(String s) {
    try {
      final decoded = _safeDecode(s);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  dynamic _safeDecode(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoBackup, _autoBackup);
      await prefs.setString(_kFrequency, _backupFrequency);
      final rawHistory = _history
          .map(
            (e) => '{"date":"${e.date}","size":"${e.size}","path":"${e.path ?? ''}"}',
          )
          .toList();
      await prefs.setStringList(_kHistory, rawHistory);
    } catch (_) {}
  }

  // ── Backup Now (native Save dialog via flutter_file_saver) ────
  Future<void> _backupNow() async {
    _beginLoading(message: 'Building backup…', backingUp: true);
    HapticFeedback.lightImpact();

    try {
      await _nextFrame();

      final data = await BackupService.buildBackupData();
      final bytes = await BackupService.buildBackupFileBytes(data);
      final fileName = BackupService.generateFileName();

      await FlutterFileSaver().writeFileAsBytes(
        fileName: fileName,
        bytes: bytes,
      );

      final sizeBytes = bytes.length;
      final entry = _buildHistoryEntryFromSize(
        sizeBytes: sizeBytes,
        fileName: fileName,
      );

      if (!mounted) return;
      setState(() {
        _history.insert(0, entry);
        if (_history.length > 10) _history.removeLast();
      });
      await _savePrefs();
      if (mounted) {
        _showSnack('Backup saved successfully', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        final msg = _errorMessage(e);
        // User cancelled the save dialog — not an error
        if (msg.toLowerCase().contains('cancel') ||
            msg.toLowerCase().contains('abort')) {
          _showSnack('Backup cancelled');
        } else {
          _showSnack('Backup failed: $msg', isError: true);
        }
      }
    } finally {
      _endLoading();
    }
  }



  // ── Export & Share ─────────────────────────────────────────────
  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    HapticFeedback.lightImpact();

    try {
      final data = await BackupService.buildBackupData();
      final filePath = await BackupService.saveBackupToTemp(data);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(filePath)],
        subject:
            'FocusFlow Backup ${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      );

      final entry = await _buildHistoryEntry(filePath, labelSuffix: 'exported');
      if (!mounted) return;

      setState(() {
        _history.insert(0, entry);
        if (_history.length > 10) _history.removeLast();
      });
      await _savePrefs();
    } catch (e) {
      if (mounted) {
        _showSnack('Export failed: ${_errorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  // ── Auto Backup ───────────────────────────────────────────────
  Future<void> _runAutoBackup() async {
    try {
      final data = await BackupService.buildBackupData();
      final filePath = await BackupService.saveBackup(
        data,
        filePrefix: 'focusflow_auto',
      );
      final entry = await _buildHistoryEntry(filePath, labelSuffix: 'auto');
      if (!mounted) return;

      setState(() {
        _history.insert(0, entry);
        if (_history.length > 10) _history.removeLast();
      });
      await _savePrefs();
    } catch (_) {}
  }

  // ── Restore: pick file ────────────────────────────────────────
  Future<void> _pickAndRestore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      // Validate extension manually since FileType.any allows all files
      final lower = path.toLowerCase();
      if (!lower.endsWith('.ffbackup') && !lower.endsWith('.json')) {
        if (mounted) {
          _showSnack(
            'Please select a .ffbackup or .json backup file.',
            isError: true,
          );
        }
        return;
      }

      if (!mounted) return;

      await _showRestoreConfirm(path);
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Could not pick file: ${_errorMessage(e)}',
          isError: true,
        );
      }
    }
  }

  // ── Restore: latest backup ────────────────────────────────────
  Future<void> _restoreLatestBackup() async {
    try {
      final path = await BackupService.getLastBackupPath();
      if (path == null || !await File(path).exists()) {
        throw Exception(
            'No backup file found. Create a backup first or pick a file.');
      }
      if (!mounted) return;
      await _showRestoreConfirm(path);
    } catch (e) {
      if (mounted) {
        _showSnack(_errorMessage(e), isError: true);
      }
    }
  }

  // ── Restore: confirmation dialog ──────────────────────────────
  Future<void> _showRestoreConfirm(String path) async {
    // Read and validate the backup first
    Map<String, dynamic> backupData;
    try {
      backupData = await BackupService.readBackupFile(path);
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to read backup: ${_errorMessage(e)}', isError: true);
      }
      return;
    }

    final validationError = BackupService.validateBackupData(backupData);
    if (validationError != null) {
      if (mounted) {
        _showSnack(validationError, isError: true);
      }
      return;
    }

    final exportedAt = BackupService.getExportedAtLabel(backupData);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: cs.error, size: 28),
              const SizedBox(width: 8),
              const Text('Restore Backup?'),
            ],
          ),
          content: Text(
            'This will permanently replace ALL current app data with '
            'the backup from $exportedAt.\n\n'
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _doRestore(backupData);
              },
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('RESTORE'),
            ),
          ],
        );
      },
    );
  }

  // ── Restore: actual execution ─────────────────────────────────
  Future<void> _doRestore(Map<String, dynamic> backupData) async {
    _beginLoading(message: 'Restoring backup…', restoring: true);
    HapticFeedback.mediumImpact();

    try {
      await _nextFrame();
      if (!mounted) return;

      final app = context.read<AppProvider>();
      await app.restoreFromBackup(backupData);

      if (mounted) {
        _showSnack('Restore successful! Reloading app…', isSuccess: true);
        // Navigate to splash for a full reload
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/splash');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Restore failed: ${_errorMessage(e)}', isError: true);
      }
    } finally {
      _endLoading();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  Future<_BackupEntry> _buildHistoryEntry(
    String filePath, {
    String? labelSuffix,
  }) async {
    int sizeBytes = 0;
    try {
      sizeBytes = await File(filePath).length();
    } catch (_) {}
    final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
    final sizeLabel =
        labelSuffix == null ? '$sizeKb KB' : '$sizeKb KB ($labelSuffix)';

    return _BackupEntry(
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      size: sizeLabel,
      path: filePath,
    );
  }

  /// Build history entry from known size (used when FlutterFileSaver
  /// doesn't return a file path).
  _BackupEntry _buildHistoryEntryFromSize({
    required int sizeBytes,
    required String fileName,
    String? labelSuffix,
  }) {
    final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
    final sizeLabel =
        labelSuffix == null ? '$sizeKb KB' : '$sizeKb KB ($labelSuffix)';
    return _BackupEntry(
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      size: sizeLabel,
      path: null,
    );
  }

  Future<void> _nextFrame() async {
    await Future<void>.delayed(Duration.zero);
  }

  void _beginLoading({
    required String message,
    bool backingUp = false,
    bool restoring = false,
  }) {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
      _backingUp = backingUp;
      _restoring = restoring;
    });
  }

  void _endLoading() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingMessage = null;
      _backingUp = false;
      _restoring = false;
    });
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    return message;
  }

  void _showSnack(
    String msg, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade600
                : null,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
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
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isLoading,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              children: [
                _sectionLabel('Quick Backup', theme, cs),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _backupNow,
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
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
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
                              : Icon(
                                  Icons.backup_rounded,
                                  size: 24,
                                  color: cs.primary,
                                ),
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
                                'Tap to save backup file to your chosen folder',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
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
                            child: Icon(
                              Icons.cloud_sync_rounded,
                              size: 20,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automatic Backup',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _autoBackup
                                      ? 'Saves to device storage — $_backupFrequency'
                                      : 'Disabled',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.45),
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
                                    'Auto backup enabled — first backup saved',
                                  );
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
                                  duration:
                                      const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? cs.primary
                                            .withValues(alpha: 0.15)
                                        : cs.onSurface
                                            .withValues(alpha: 0.05),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? cs.primary
                                              .withValues(alpha: 0.4)
                                          : cs.onSurface
                                              .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      f,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: selected
                                            ? cs.primary
                                            : cs.onSurface
                                                .withValues(alpha: 0.5),
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
                _sectionLabel('Restore', theme, cs),
                const SizedBox(height: 8),

                // Warning text
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: cs.error.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18,
                          color: cs.error.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Restoring will replace ALL current data. '
                          'This action cannot be undone.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Restore Latest Backup',
                        color: Colors.orange.shade600,
                        loading: _restoring,
                        onTap: _restoreLatestBackup,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.file_open_rounded,
                        label: 'Restore from File',
                        color: Colors.orange.shade400,
                        loading: _restoring,
                        onTap: _pickAndRestore,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel('Export', theme, cs),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Export & Share',
                  color: cs.primary,
                  loading: _exporting,
                  onTap: _exportBackup,
                ),
                const SizedBox(height: 20),
                _sectionLabel('Backup History', theme, cs),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: _cardDecor(cs),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.cloud_done_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.date,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.size,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.35),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: cs.error.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => _history.removeAt(idx));
                              _savePrefs();
                              _showSnack('Backup entry removed');
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          _loadingMessage ?? 'Working…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackupEntry {
  final String date;
  final String size;
  final String? path;

  const _BackupEntry({
    required this.date,
    required this.size,
    this.path,
  });
}

BoxDecoration _cardDecor(ColorScheme cs) {
  return BoxDecoration(
    color: Colors.transparent,
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
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
