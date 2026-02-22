import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/storage/backup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _apiKeyObscure = true;
  bool _autoSync = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() { _apiKeyCtrl.dispose(); super.dispose(); }

  Future<void> _loadPrefs() async {
    final svc = ref.read(backupServiceProvider);
    final key  = await svc.getApiKey();
    final auto = await svc.isAutoSyncEnabled();
    setState(() { _apiKeyCtrl.text = key; _autoSync = auto; });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode  = ref.watch(themeModeProvider);
    final snapshots  = ref.watch(backupSnapshotsProvider);
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 24),

                  // ── Theme ──────────────────────────────────────────────────
                  _SectionHeader(title: 'Appearance'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(children: [
                          for (final mode in ThemeMode.values)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: mode != ThemeMode.system ? 8 : 0),
                                child: GestureDetector(
                                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(mode),
                                  child: AnimatedContainer(
                                    duration: 200.ms,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: themeMode == mode
                                          ? AppColors.accent
                                          : AppColors.accentGlow,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: themeMode == mode
                                            ? AppColors.accent
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          [Icons.dark_mode_rounded, Icons.light_mode_rounded, Icons.contrast_rounded][mode.index],
                                          color: themeMode == mode ? Colors.white : AppColors.accent,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ['Dark', 'Light', 'Auto'][mode.index],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: themeMode == mode ? Colors.white : AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn(delay: 50.ms),

                  const SizedBox(height: 24),

                  // ── AI ─────────────────────────────────────────────────────
                  _SectionHeader(title: 'AI Mentor (Gemini)'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API Key', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Get yours free at aistudio.google.com',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _apiKeyCtrl,
                          obscureText: _apiKeyObscure,
                          decoration: InputDecoration(
                            hintText: 'Paste Gemini API key...',
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_apiKeyObscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                  onPressed: () => setState(() => _apiKeyObscure = !_apiKeyObscure),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save_rounded, color: AppColors.accent),
                                  onPressed: () async {
                                    await ref.read(backupServiceProvider).setApiKey(_apiKeyCtrl.text.trim());
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✅ API key saved')));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // ── Backup & Sync ──────────────────────────────────────────
                  _SectionHeader(title: 'Backup & Sync'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          const Icon(Icons.cloud_sync_rounded, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto Backup', style: Theme.of(context).textTheme.titleMedium),
                                Text('Saves on app close',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoSync,
                            activeColor: AppColors.accent,
                            onChanged: (v) async {
                              setState(() => _autoSync = v);
                              await ref.read(backupServiceProvider).setAutoSync(v);
                            },
                          ),
                        ]),
                        const Divider(height: 24),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _createManualBackup,
                              icon: _loading
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.backup_rounded),
                              label: const Text('Backup Now'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Import'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accentLight,
                                side: const BorderSide(color: AppColors.accentLight),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // ── Snapshot list ─────────────────────────────────────────
                  if (snapshots.isNotEmpty) ...
                    [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Snapshots (${snapshots.length}/30)',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('Swipe to delete',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...snapshots.asMap().entries.map((e) =>
                          _SnapshotTile(
                            snapshot: e.value,
                            onRestore: () => _restoreSnapshot(e.value),
                            onExport: () => ref.read(backupServiceProvider).exportToFile(e.value),
                            onDelete: () => ref.read(backupSnapshotsProvider.notifier).delete(e.value.id),
                          ).animate(delay: (e.key * 30).ms).fadeIn().slideX(begin: 0.06),
                      ),
                    ],

                  const SizedBox(height: 24),

                  // ── About ─────────────────────────────────────────────────
                  _SectionHeader(title: 'About'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _AboutRow(icon: Icons.info_rounded, label: 'Version', value: '1.0.0'),
                        const Divider(height: 20),
                        _AboutRow(icon: Icons.code_rounded, label: 'Built with', value: 'Flutter + Riverpod'),
                        const Divider(height: 20),
                        _AboutRow(icon: Icons.storage_rounded, label: 'Storage', value: 'Offline • Hive'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createManualBackup() async {
    setState(() => _loading = true);
    try {
      final snap = ref.read(backupServiceProvider).createSnapshot(isAuto: false);
      ref.read(backupSnapshotsProvider.notifier).add(snap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Backup created!')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreSnapshot(BackupSnapshot snap) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: Text('This will replace ALL current data with\n"${snap.label}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(backupServiceProvider).restoreSnapshot(snap);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data restored! Restart the app.')));
    }
  }

  Future<void> _importBackup() async {
    final snap = await ref.read(backupServiceProvider).importFromFile();
    if (snap == null || !mounted) return;
    ref.read(backupSnapshotsProvider.notifier).add(snap);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Backup imported!')));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.accent, letterSpacing: 0.5)),
      );
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _AboutRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ]);
}

class _SnapshotTile extends StatelessWidget {
  final BackupSnapshot snapshot;
  final VoidCallback onRestore, onExport, onDelete;
  const _SnapshotTile({
    required this.snapshot,
    required this.onRestore,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(snapshot.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(
            snapshot.isAuto ? Icons.cloud_done_rounded : Icons.save_rounded,
            color: snapshot.isAuto ? AppColors.info : AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(snapshot.label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
              Text(
                snapshot.createdAt.toString().substring(0, 16),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.accentLight),
            onPressed: onExport,
            tooltip: 'Export',
          ),
          TextButton(
            onPressed: onRestore,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
