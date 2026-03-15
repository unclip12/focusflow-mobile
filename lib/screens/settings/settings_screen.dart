// =============================================================
// SettingsScreen â€” grouped settings list via AppScaffold
// Sections: Appearance, Notifications, Menu, Data, About
// Android rules: resizeToAvoidBottomInset: true on Scaffolds,
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/services/backup_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/widgets/liquid_glass_card.dart';
import 'package:focusflow_mobile/screens/settings/theme_picker_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      screenName: 'Settings',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
        children: [
          // ═══════════════════════════════════════════════════════
          // EXAM DATES
          // ═══════════════════════════════════════════════════════
          _GlassSectionHeader(title: 'Exam Dates'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              children: [
                _GlassListTile(
                  title: 'FMGE',
                  subtitle: _formatDateLabel(sp.fmgeDate),
                  trailing: Icon(Icons.edit_calendar_rounded, color: DashboardColors.primaryLight, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(sp.fmgeDate) ?? DateTime(2026, 6, 28),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null) {
                      sp.setFmgeDate(DateFormat('yyyy-MM-dd').format(picked));
                    }
                  },
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                _GlassListTile(
                  title: 'USMLE Step 1',
                  subtitle: _formatDateLabel(sp.step1Date),
                  trailing: Icon(Icons.edit_calendar_rounded, color: DashboardColors.primaryLight, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(sp.step1Date) ?? DateTime(2026, 6, 15),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null) {
                      sp.setStep1Date(DateFormat('yyyy-MM-dd').format(picked));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════
          // DAILY GOALS
          // ═══════════════════════════════════════════════════════
          _GlassSectionHeader(title: 'Daily Goals'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              children: [
                _GlassListTile(
                  title: 'FA Pages / Day',
                  trailing: _GlassChip(label: '${sp.dailyFAGoal} pages'),
                  onTap: () => _showSliderDialog(
                    context: context,
                    title: 'FA Pages / Day',
                    currentValue: sp.dailyFAGoal.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    suffix: 'pages',
                    onConfirm: (val) => sp.setDailyFAGoal(val.round()),
                  ),
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                _GlassListTile(
                  title: 'Anki Cards / Day',
                  trailing: _GlassChip(label: '${sp.ankiBatchSize} cards'),
                  onTap: () => _showSliderDialog(
                    context: context,
                    title: 'Anki Cards / Day',
                    currentValue: sp.ankiBatchSize.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    suffix: 'cards',
                    onConfirm: (val) => sp.setAnkiBatchSize(val.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════
          // DAILY SCHEDULE
          // ═══════════════════════════════════════════════════════
          _GlassSectionHeader(title: 'Daily Schedule'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              children: [
                _GlassListTile(
                  title: 'Wake Time',
                  subtitle: _formatTimeLabel(sp.wakeTime),
                  trailing: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
                  onTap: () async {
                    final parts = sp.wakeTime.split(':');
                    final initial = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 6,
                      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                    );
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) {
                      sp.setWakeTime('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                _GlassListTile(
                  title: 'Sleep Time',
                  subtitle: _formatTimeLabel(sp.sleepTime),
                  trailing: const Icon(Icons.bedtime_rounded, color: Colors.indigo, size: 20),
                  onTap: () async {
                    final parts = sp.sleepTime.split(':');
                    final initial = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 23,
                      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                    );
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) {
                      sp.setSleepTime('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════
          // STREAK & DAY BOUNDARY
          // ═══════════════════════════════════════════════════════
          _GlassSectionHeader(title: 'Streak & Day Boundary'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              children: [
                _GlassListTile(
                  icon: Icons.schedule_rounded,
                  iconColor: DashboardColors.primary,
                  title: 'Day Start Time',
                  subtitle: '${sp.dayStartHour == 0 ? 12 : sp.dayStartHour > 12 ? sp.dayStartHour - 12 : sp.dayStartHour}:00 ${sp.dayStartHour < 12 ? 'AM' : 'PM'}',
                  trailing: Icon(Icons.chevron_right_rounded, color: DashboardColors.textSecondary, size: 20),
                  onTap: () => _showSliderDialog(
                    context: context,
                    title: 'Day Start Hour',
                    currentValue: sp.dayStartHour.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    suffix: 'AM',
                    onConfirm: (val) => sp.setDayStartHour(val.round()),
                  ),
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                _GlassListTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.amber,
                  title: 'Auto Use Credits',
                  subtitle: 'Auto-redeem credit points to save streak',
                  trailing: Switch.adaptive(
                    value: sp.streakAutoCredit,
                    onChanged: (v) => sp.setStreakAutoCredit(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // BOTTOM NAV PINS
          _GlassSectionHeader(title: 'Navigation'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Pinned Tabs',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary(Theme.of(context).brightness == Brightness.dark),
                        )),
                    const Spacer(),
                    Text('Max 4 tabs',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: DashboardColors.textSecondary,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sp.pinnedTabs.map((id) {
                    final label = kPinnableScreenLabels[id] ?? id;
                    return FilterChip(
                      label: Text(label),
                      selected: true,
                      onSelected: (_) {
                        if (sp.pinnedTabs.length > 1) {
                          final updated = sp.pinnedTabs.where((t) => t != id).toList();
                          sp.setPinnedTabs(updated);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add tab'),
                  onPressed: sp.pinnedTabs.length >= 4
                      ? null
                      : () {
                          final unpinned = kPinnableScreenLabels.entries
                              .where((e) => !sp.pinnedTabs.contains(e.key))
                              .toList();
                          showModalBottomSheet(
                            context: context,
                            enableDrag: false,
                            useSafeArea: true,
                            builder: (_) => ListView(
                              shrinkWrap: true,
                              children: unpinned.map((e) {
                                return ListTile(
                                  title: Text(e.value),
                                  onTap: () {
                                    sp.setPinnedTabs([...sp.pinnedTabs, e.key]);
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 8),
                Text('Tap a chip to unpin · Changes apply on restart',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: DashboardColors.textSecondary,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // =============================================================
          // APPEARANCE
          // =============================================================
          _GlassSectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),

          // â”€â”€ Theme picker (horizontal scroll) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kThemePresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final preset = kThemePresets[i];
                      return ThemePickerCard(
                        preset: preset,
                        selected: sp.currentTheme == preset.id,
                        onTap: () => sp.changeTheme(preset.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // â”€â”€ Dark mode toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: sp.isDarkMode,
              activeTrackColor: cs.primary,
              onChanged: (_) => sp.toggleDarkMode(),
            ),
          ),
          const SizedBox(height: 8),

          // â”€â”€ Font size slider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Font Size',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    Text(
                      sp.fontSize[0].toUpperCase() +
                          sp.fontSize.substring(1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: kFontSizes.map((size) {
                    final selected = sp.fontSize == size;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => sp.changeFontSize(size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.15)
                                : cs.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.4)
                                  : cs.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size[0].toUpperCase() + size.substring(1),
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
            ),
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // NOTIFICATIONS
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _GlassSectionHeader(title: 'Notifications'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.do_not_disturb_on_rounded,
            title: 'Quiet Hours',
            subtitle: sp.settings.quietHours.enabled
                ? '${sp.settings.quietHours.start} â€“ ${sp.settings.quietHours.end}'
                : 'Disabled',
            trailing: Switch.adaptive(
              value: sp.settings.quietHours.enabled,
              activeTrackColor: cs.primary,
              onChanged: (_) {
                sp.updateQuietHours(sp.settings.quietHours
                    .copyWith(enabled: !sp.settings.quietHours.enabled));
              },
            ),
          ),
          // â”€â”€ Time pickers (shown when quiet hours enabled) â”€â”€â”€â”€â”€â”€â”€
          if (sp.settings.quietHours.enabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Start',
                    time: sp.settings.quietHours.start,
                    onTap: () => _pickTime(
                      context,
                      sp.settings.quietHours.start,
                      (t) => sp.updateQuietHours(
                          sp.settings.quietHours.copyWith(start: t)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: 'End',
                    time: sp.settings.quietHours.end,
                    onTap: () => _pickTime(
                      context,
                      sp.settings.quietHours.end,
                      (t) => sp.updateQuietHours(
                          sp.settings.quietHours.copyWith(end: t)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // MENU CONFIGURATION
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _GlassSectionHeader(title: 'Menu'),
          const SizedBox(height: 8),
          _MenuReorderSection(sp: sp),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // BACKUP & RESTORE
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _GlassSectionHeader(title: 'Backup & Restore'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              children: [
                // Row 1 — Last Backup
                _GlassListTile(
                  icon: Icons.history_rounded,
                  iconColor: DashboardColors.primary,
                  title: 'Last Backup',
                  subtitleWidget: FutureBuilder<DateTime?>(
                    future: BackupService.lastBackupTime(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Text('Checking…', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary));
                      }
                      final dt = snap.data;
                      if (dt == null) return Text('No backup yet', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary));
                      final now = DateTime.now();
                      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
                      final formatted = isToday
                          ? 'Today at ${DateFormat.jm().format(dt)}'
                          : '${DateFormat('MMM d').format(dt)} at ${DateFormat.jm().format(dt)}';
                      return Text(formatted, style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary));
                    },
                  ),
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                // Row 2 — Backup Now
                _GlassListTile(
                  icon: Icons.backup_rounded,
                  iconColor: DashboardColors.success,
                  title: 'Backup Now',
                  trailing: Icon(Icons.chevron_right_rounded, color: DashboardColors.textSecondary, size: 20),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      final app = context.read<AppProvider>();
                      final savedPath = await BackupService.saveBackup(
                          BackupService.buildBackupData(app));
                      if (context.mounted) Navigator.pop(context); // close dialog
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Backup saved to ${savedPath.split('/').last}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // Refresh to update Last Backup row
                        (context as Element).markNeedsBuild();
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context); // close dialog
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Backup failed: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                Divider(height: 1, color: DashboardColors.glassBorder(Theme.of(context).brightness == Brightness.dark)),
                _GlassListTile(
                  icon: Icons.restore_rounded,
                  iconColor: DashboardColors.warning,
                  title: 'Restore from Backup',
                  trailing: Icon(Icons.chevron_right_rounded, color: DashboardColors.textSecondary, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('⚠️ Restore Backup?'),
                        content: const Text(
                          'This will overwrite all current data with the '
                          'last saved backup.\n\nThis cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(ctx); // close alert
                              
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              
                              try {
                                final data = await BackupService.loadBackup();
                                if (!context.mounted) return;
                                if (data == null) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No backup file found'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                final app = context.read<AppProvider>();
                                await app.restoreFromBackup(data);
                                if (context.mounted) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Data restored from backup'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) Navigator.pop(context); // close loader
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Restore failed: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // ABOUT
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // ── STUDY PLAN ─────────────────────────────────────────
          _GlassSectionHeader(title: 'Study Plan'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Plan Start Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final current = sp.studyPlanStartDate;
                        final initial = current != null
                            ? DateTime.tryParse(current) ?? DateTime.now()
                            : DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          sp.setStudyPlanStartDate(
                              picked.toIso8601String().substring(0, 10));
                        }
                      },
                      child: Text(
                        sp.studyPlanStartDate != null
                            ? _formatDateLabel(sp.studyPlanStartDate!)
                            : 'Not set (auto)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: sp.studyPlanStartDate != null
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-set on first study. SRS: Aggressive — 10 revisions / 30 days per page',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _GlassSectionHeader(title: 'About'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('App', 'FocusFlow'),
                _DetailRow('Version', 'v1.5.0'),
                _DetailRow('Build Date', '2026-02-28'),
                const Divider(height: 16),
                Text(
                  "What's New in v1.5.0",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                _ChangelogItem('Revision Hub connected to all resources'),
                _ChangelogItem('Sketchy/Pathoma/UWorld → revision tracking'),
                _ChangelogItem('UWorld wrong-question auto-revision'),
                _ChangelogItem('SRS scheduling (strict: 12 steps)'),
                _ChangelogItem('Source filter chips in Revision Hub'),
                _ChangelogItem('Version system in Settings'),
                const SizedBox(height: 8),
                Text(
                  'Previous: v1.4.0 — Streak credits & day boundary',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Built with ❤️ for FMGE prep',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // â”€â”€ Time picker helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickTime(
      BuildContext context, String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onPicked(formatted);
    }
  }

  // ── G10 helpers ─────────────────────────────────────────────────

  String _formatDateLabel(String yyyyMMdd) {
    final dt = DateTime.tryParse(yyyyMMdd);
    if (dt == null) return yyyyMMdd;
    return DateFormat('d MMM yyyy').format(dt);
  }

  String _formatTimeLabel(String hhMM) {
    final parts = hhMM.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    final suffix = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    return '$hour12:${m.toString().padLeft(2, '0')} $suffix';
  }

  void _showSliderDialog({
    required BuildContext context,
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onConfirm,
  }) {
    double val = currentValue;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${val.round()} $suffix',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              Slider(
                value: val,
                min: min,
                max: max,
                divisions: divisions,
                label: '${val.round()}',
                onChanged: (v) => setState(() => val = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onConfirm(val);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPER WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _GlassSectionHeader extends StatelessWidget {
  final String title;
  const _GlassSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 0),
      child: Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color: DashboardColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: DashboardColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const _GlassListTile({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (iconColor ?? DashboardColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor ?? DashboardColors.primary),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  if (subtitleWidget != null) subtitleWidget!,
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DashboardColors.primary.withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DashboardColors.primaryLight,
        ),
      ),
    );
  }
}



class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      )),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                )),
            const Spacer(),
            Text(time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}



class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MENU REORDER SECTION
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _MenuReorderSection extends StatefulWidget {
  final SettingsProvider sp;
  const _MenuReorderSection({required this.sp});

  @override
  State<_MenuReorderSection> createState() => _MenuReorderSectionState();
}

class _MenuReorderSectionState extends State<_MenuReorderSection> {
  late List<MenuItemConfig> _items;

  @override
  void initState() {
    super.initState();
    _syncItems();
  }

  @override
  void didUpdateWidget(_MenuReorderSection old) {
    super.didUpdateWidget(old);
    _syncItems();
  }

  void _syncItems() {
    final existing = widget.sp.menuConfiguration;
    if (existing.isNotEmpty) {
      _items = existing.toList();
    } else {
      _items = kDefaultMenuOrder
          .map((id) => MenuItemConfig(id: id, visible: true))
          .toList();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    widget.sp.updateMenuConfig(_items);
  }

  void _toggleVisibility(int index) {
    setState(() {
      _items[index] =
          _items[index].copyWith(visible: !_items[index].visible);
    });
    widget.sp.updateMenuConfig(_items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _items.length,
        onReorder: _onReorder,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          final label =
              kMenuItemLabels[item.id] ?? item.id;

          return Container(
            key: ValueKey(item.id),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: index < _items.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.04),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.25)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: item.visible
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Visibility toggle
                GestureDetector(
                  onTap: () => _toggleVisibility(index),
                  child: Icon(
                    item.visible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20,
                    color: item.visible
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Changelog bullet item ──────────────────────────────────────
class _ChangelogItem extends StatelessWidget {
  final String text;
  const _ChangelogItem(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 6),
            child: Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
