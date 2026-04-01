// =============================================================
// SettingsScreen â€” grouped settings list via AppScaffold
// Sections: Appearance, Notifications, Menu, Data, About
// Android rules: resizeToAvoidBottomInset: true on Scaffolds,
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import '../../services/backup_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/widgets/liquid_glass_card.dart';
import 'package:focusflow_mobile/widgets/main_shell.dart';
import 'package:focusflow_mobile/screens/settings/theme_picker_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _taskReminderEditorReservedHeight = 360;

  bool _isTaskReminderEditorOpen = false;
  TaskReminderRule? _editingTaskReminderRule;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom +
        kNavBarHeight +
        24 +
        (_isTaskReminderEditorOpen ? _taskReminderEditorReservedHeight : 0);
    final reminderPanelBottom =
        MediaQuery.of(context).padding.bottom + kNavBarHeight + 12;

    return AppScaffold(
      screenName: 'Settings',
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
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
                      trailing: Icon(Icons.edit_calendar_rounded,
                          color: DashboardColors.primaryLight, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(sp.fmgeDate) ??
                              DateTime(2026, 6, 28),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          sp.setFmgeDate(
                              DateFormat('yyyy-MM-dd').format(picked));
                        }
                      },
                    ),
                    Divider(
                        height: 1,
                        color: DashboardColors.glassBorder(
                            Theme.of(context).brightness == Brightness.dark)),
                    _GlassListTile(
                      title: 'USMLE Step 1',
                      subtitle: _formatDateLabel(sp.step1Date),
                      trailing: Icon(Icons.edit_calendar_rounded,
                          color: DashboardColors.primaryLight, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(sp.step1Date) ??
                              DateTime(2026, 6, 15),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          sp.setStep1Date(
                              DateFormat('yyyy-MM-dd').format(picked));
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
                    Divider(
                        height: 1,
                        color: DashboardColors.glassBorder(
                            Theme.of(context).brightness == Brightness.dark)),
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
                      trailing: const Icon(Icons.wb_sunny_rounded,
                          color: Colors.amber, size: 20),
                      onTap: () async {
                        final parts = sp.wakeTime.split(':');
                        final initial = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 6,
                          minute:
                              int.tryParse(parts.length > 1 ? parts[1] : '0') ??
                                  0,
                        );
                        final picked = await showTimePicker(
                            context: context, initialTime: initial);
                        if (picked != null) {
                          sp.setWakeTime(
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                        }
                      },
                    ),
                    Divider(
                        height: 1,
                        color: DashboardColors.glassBorder(
                            Theme.of(context).brightness == Brightness.dark)),
                    _GlassListTile(
                      title: 'Sleep Time',
                      subtitle: _formatTimeLabel(sp.sleepTime),
                      trailing: const Icon(Icons.bedtime_rounded,
                          color: Colors.indigo, size: 20),
                      onTap: () async {
                        final parts = sp.sleepTime.split(':');
                        final initial = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 23,
                          minute:
                              int.tryParse(parts.length > 1 ? parts[1] : '0') ??
                                  0,
                        );
                        final picked = await showTimePicker(
                            context: context, initialTime: initial);
                        if (picked != null) {
                          sp.setSleepTime(
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
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
                      subtitle:
                          '${sp.dayStartHour == 0 ? 12 : sp.dayStartHour > 12 ? sp.dayStartHour - 12 : sp.dayStartHour}:00 ${sp.dayStartHour < 12 ? 'AM' : 'PM'}',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: DashboardColors.textSecondary, size: 20),
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
                    Divider(
                        height: 1,
                        color: DashboardColors.glassBorder(
                            Theme.of(context).brightness == Brightness.dark)),
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
                              color: DashboardColors.textPrimary(
                                  Theme.of(context).brightness ==
                                      Brightness.dark),
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
                              final updated =
                                  sp.pinnedTabs.where((t) => t != id).toList();
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
                                  padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            20,
                                  ),
                                  children: unpinned.map((e) {
                                    return ListTile(
                                      title: Text(e.value),
                                      onTap: () {
                                        sp.setPinnedTabs(
                                            [...sp.pinnedTabs, e.key]);
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

              // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
              // MENU CONFIGURATION
              // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
              _GlassSectionHeader(title: 'Reminder Notifications'),
              const SizedBox(height: 8),
              LiquidGlassCard(
                child: Column(
                  children: [
                    _GlassListTile(
                      title: 'Reminder Alerts',
                      subtitle: sp.reminderNotifications.enabled
                          ? 'Enabled for timed reminders'
                          : 'Disabled',
                      trailing: Switch.adaptive(
                        value: sp.reminderNotifications.enabled,
                        activeTrackColor: cs.primary,
                        onChanged: (value) async {
                          await sp.setReminderNotificationsEnabled(value);
                          if (!context.mounted) return;
                          await _syncReminderNotifications(context);
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: DashboardColors.glassBorder(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    _GlassListTile(
                      title: 'Default Alert Times',
                      subtitle: _formatReminderAlertOffsets(
                        sp.reminderNotifications.defaultAlertOffsets,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: DashboardColors.textSecondary,
                        size: 20,
                      ),
                      onTap: () => _editReminderDefaultAlerts(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'These defaults are used by reminders that keep global alert settings. All-day reminders stay in the list and only timed reminders schedule notifications.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _GlassSectionHeader(title: 'Timer Reminders'),
              const SizedBox(height: 8),
              LiquidGlassCard(
                child: Column(
                  children: [
                    _GlassListTile(
                      title: 'Cue Sounds',
                      subtitle:
                          'Play a sound for 20%, 5-minute, and 1-minute warnings',
                      trailing: Switch.adaptive(
                        value: sp.timerReminders.playCueSounds,
                        activeTrackColor: cs.primary,
                        onChanged: (value) {
                          sp.setPlayCueSounds(value);
                          unawaited(_syncPlannedTaskReminders(context));
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: DashboardColors.glassBorder(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    _GlassListTile(
                      title: 'Spoken Reminders',
                      subtitle:
                          'Speak timer warnings aloud after the cue sound',
                      trailing: Switch.adaptive(
                        value: sp.timerReminders.speakReminders,
                        activeTrackColor: cs.primary,
                        onChanged: (value) {
                          sp.setSpeakReminders(value);
                          unawaited(_syncPlannedTaskReminders(context));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Global Task Reminder Rules',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey<String>(
                              'task_reminder_add_button'),
                          onPressed: () => _openTaskReminderRuleEditor(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'These rules apply to timed tasks across Today\'s Plan. Fixed active timer warnings still run automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (sp.timerReminders.taskReminderRules.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          'No extra reminder rules yet. Add reminders for before start, at start, before end, or at end.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: sp.timerReminders.taskReminderRules
                            .map(
                              (rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TaskReminderRuleTile(
                                  rule: rule,
                                  summary: _taskReminderRuleSummary(rule),
                                  onTap: () => _openTaskReminderRuleEditor(
                                      existing: rule),
                                  onToggle: (value) async {
                                    await context
                                        .read<SettingsProvider>()
                                        .updateTaskReminderRule(
                                          rule.copyWith(enabled: value),
                                        );
                                    if (!context.mounted) return;
                                    await _syncPlannedTaskReminders(context);
                                  },
                                  onDelete: () async {
                                    await context
                                        .read<SettingsProvider>()
                                        .removeTaskReminderRule(rule.id);
                                    if (!context.mounted) return;
                                    await _syncPlannedTaskReminders(context);
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _GlassSectionHeader(title: 'Menu'),
              const SizedBox(height: 8),
              _MenuReorderSection(sp: sp),
              const SizedBox(height: 20),

              // ═════════════════════════════════════════════════════════════════════
              // BACKUP & RESTORE
              // ═════════════════════════════════════════════════════════════════════
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
                            return Text('Checking…',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: DashboardColors.textSecondary));
                          }
                          final dt = snap.data;
                          if (dt == null)
                            return Text('No backup yet',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: DashboardColors.textSecondary));
                          final now = DateTime.now();
                          final isToday = dt.year == now.year &&
                              dt.month == now.month &&
                              dt.day == now.day;
                          final formatted = isToday
                              ? 'Today at ${DateFormat.jm().format(dt)}'
                              : '${DateFormat('MMM d').format(dt)} at ${DateFormat.jm().format(dt)}';
                          return Text(formatted,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: DashboardColors.textSecondary));
                        },
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: DashboardColors.glassBorder(
                            Theme.of(context).brightness == Brightness.dark)),
                    // Row 2 — Open Backup & Restore Screen
                    _GlassListTile(
                      icon: Icons.backup_rounded,
                      iconColor: DashboardColors.success,
                      title: 'Backup & Restore',
                      subtitle: 'Create backups, restore, or export data',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: DashboardColors.textSecondary, size: 20),
                      onTap: () => GoRouter.of(context).push('/backup'),
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
                    _ChangelogItem(
                        'Sketchy/Pathoma/UWorld → revision tracking'),
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
          Positioned(
            left: 16,
            right: 16,
            bottom: reminderPanelBottom,
            child: IgnorePointer(
              ignoring: !_isTaskReminderEditorOpen,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _isTaskReminderEditorOpen
                    ? Offset.zero
                    : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _isTaskReminderEditorOpen ? 1 : 0,
                  child: _TaskReminderRuleEditorPanel(
                    key: ValueKey<String>(
                      'task-reminder-editor-${_editingTaskReminderRule?.id ?? 'new'}',
                    ),
                    existing: _editingTaskReminderRule,
                    bottomInset: MediaQuery.of(context).viewInsets.bottom,
                    onClose: _closeTaskReminderRuleEditor,
                    onSave: _saveTaskReminderRule,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Time picker helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickTime(BuildContext context, String current,
      ValueChanged<String> onPicked) async {
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

  void _openTaskReminderRuleEditor({TaskReminderRule? existing}) {
    setState(() {
      _editingTaskReminderRule = existing;
      _isTaskReminderEditorOpen = true;
    });
  }

  void _closeTaskReminderRuleEditor() {
    if (!_isTaskReminderEditorOpen && _editingTaskReminderRule == null) {
      return;
    }
    setState(() {
      _isTaskReminderEditorOpen = false;
      _editingTaskReminderRule = null;
    });
  }

  Future<void> _saveTaskReminderRule(TaskReminderRule rule) async {
    final existing = _editingTaskReminderRule;
    final settings = context.read<SettingsProvider>();
    if (existing == null) {
      await settings.addTaskReminderRule(rule);
    } else {
      await settings.updateTaskReminderRule(rule);
    }
    if (!mounted) return;
    _closeTaskReminderRuleEditor();
    await _syncPlannedTaskReminders(context);
  }

  String _taskReminderRuleSummary(TaskReminderRule rule) {
    final minuteLabel =
        rule.offsetMinutes == 1 ? '1 min' : '${rule.offsetMinutes} min';
    switch (rule.anchor) {
      case TaskReminderAnchor.beforeStart:
        return '$minuteLabel before task start';
      case TaskReminderAnchor.atStart:
        return 'At task start';
      case TaskReminderAnchor.beforeEnd:
        return '$minuteLabel before task end';
      case TaskReminderAnchor.atEnd:
        return 'At task end';
      default:
        return '$minuteLabel reminder';
    }
  }

  Future<void> _syncPlannedTaskReminders(BuildContext context) async {
    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    await NotificationService.instance.syncPlannedTaskReminders(
      plans: app.dayPlans,
      config: settings.timerReminders,
    );
  }

  Future<void> _syncReminderNotifications(BuildContext context) async {
    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    await NotificationService.instance.syncReminderNotifications(
      reminders: app.reminders,
      occurrenceStates: app.reminderOccurrenceStates,
      config: settings.reminderNotifications,
    );
  }

  String _formatReminderAlertOffsets(List<int> offsets) {
    if (offsets.isEmpty) return 'No alerts selected';
    final normalized = offsets.toSet().toList()..sort();
    return normalized
        .map((offset) => offset == 0 ? 'At time' : '$offset min before')
        .join(' • ');
  }

  Future<void> _editReminderDefaultAlerts(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final selected = settings.reminderNotifications.defaultAlertOffsets.toSet();
    final customController = TextEditingController();
    const presetOffsets = <int>[0, 5, 10, 15, 30, 45, 60];

    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Reminder Alert Times'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetOffsets.map((offset) {
                    final label =
                        offset == 0 ? 'At time' : '$offset min before';
                    return FilterChip(
                      label: Text(label),
                      selected: selected.contains(offset),
                      onSelected: (isSelected) {
                        setDialogState(() {
                          if (isSelected) {
                            selected.add(offset);
                          } else {
                            selected.remove(offset);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: customController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Custom minutes before',
                    helperText: 'Leave empty if presets are enough',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    final minutes = int.tryParse(customController.text.trim());
                    if (minutes == null || minutes < 0) return;
                    setDialogState(() {
                      selected.add(minutes);
                      customController.clear();
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add custom alert'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(selected.toList()..sort()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    customController.dispose();
    if (result == null || !context.mounted) return;

    await settings.setReminderDefaultAlertOffsets(result);
    if (!context.mounted) return;
    await _syncReminderNotifications(context);
  }

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
            width: 3,
            height: 16,
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
                  color: (iconColor ?? DashboardColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    size: 16, color: iconColor ?? DashboardColors.primary),
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
        color: Colors.transparent,
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

class _TaskReminderRuleTile extends StatelessWidget {
  final TaskReminderRule rule;
  final String summary;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _TaskReminderRuleTile({
    required this.rule,
    required this.summary,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      key: ValueKey<String>('task_reminder_rule_${rule.id}'),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rule.enabled ? 'Enabled' : 'Disabled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: rule.enabled,
                onChanged: onToggle,
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskReminderRuleEditorPanel extends StatefulWidget {
  final TaskReminderRule? existing;
  final double bottomInset;
  final VoidCallback onClose;
  final Future<void> Function(TaskReminderRule rule) onSave;

  const _TaskReminderRuleEditorPanel({
    super.key,
    this.existing,
    required this.bottomInset,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_TaskReminderRuleEditorPanel> createState() =>
      _TaskReminderRuleEditorPanelState();
}

class _TaskReminderRuleEditorPanelState
    extends State<_TaskReminderRuleEditorPanel> {
  static const List<int> _minuteOptions = <int>[
    1,
    2,
    5,
    10,
    15,
    20,
    30,
    45,
    60,
  ];
  static const String _customMinuteOption = 'custom';

  late String _anchor;
  late int _offsetMinutes;
  late bool _enabled;
  late bool _useCustomMinutes;
  late TextEditingController _customMinutesController;
  String? _customMinutesError;
  bool _isSaving = false;

  bool get _usesOffset =>
      _anchor == TaskReminderAnchor.beforeStart ||
      _anchor == TaskReminderAnchor.beforeEnd;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _anchor = existing?.anchor ?? TaskReminderAnchor.beforeStart;
    _offsetMinutes = existing?.offsetMinutes ?? 5;
    _enabled = existing?.enabled ?? true;
    _useCustomMinutes = _usesOffset && !_minuteOptions.contains(_offsetMinutes);
    _customMinutesController = TextEditingController(
      text: _useCustomMinutes ? _offsetMinutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  String _anchorLabel(String value) {
    switch (value) {
      case TaskReminderAnchor.beforeStart:
        return 'Before task start';
      case TaskReminderAnchor.atStart:
        return 'At task start';
      case TaskReminderAnchor.beforeEnd:
        return 'Before task end';
      case TaskReminderAnchor.atEnd:
        return 'At task end';
      default:
        return value;
    }
  }

  int? _validateCustomMinutes() {
    final rawValue = _customMinutesController.text.trim();
    final minutes = int.tryParse(rawValue);
    if (rawValue.isEmpty || minutes == null || minutes <= 0) {
      return null;
    }
    return minutes;
  }

  Future<void> _save() async {
    int reminderOffset = 0;
    if (_usesOffset) {
      if (_useCustomMinutes) {
        final validatedMinutes = _validateCustomMinutes();
        if (validatedMinutes == null) {
          setState(() {
            _customMinutesError = 'Enter a positive number of minutes';
          });
          return;
        }
        reminderOffset = validatedMinutes;
      } else {
        reminderOffset = _offsetMinutes;
      }
    }

    final existing = widget.existing;
    final rule = TaskReminderRule(
      id: existing?.id ?? 'timer-rule-${DateTime.now().microsecondsSinceEpoch}',
      anchor: _anchor,
      offsetMinutes: reminderOffset,
      enabled: _enabled,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(rule);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final minuteDropdownValue =
        _useCustomMinutes ? _customMinuteOption : _offsetMinutes.toString();

    return Material(
      key: const ValueKey<String>('task_reminder_editor_panel'),
      color: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? 'Add Reminder Rule'
                            : 'Edit Reminder Rule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>(
                        'task_reminder_editor_close_button',
                      ),
                      onPressed: _isSaving ? null : widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('task_reminder_anchor_$_anchor'),
                  initialValue: _anchor,
                  decoration: const InputDecoration(
                    labelText: 'When should this fire?',
                  ),
                  items: TaskReminderAnchor.values
                      .map(
                        (anchor) => DropdownMenuItem<String>(
                          value: anchor,
                          child: Text(_anchorLabel(anchor)),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _anchor = value;
                            _customMinutesError = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                if (_usesOffset) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'task_reminder_minutes_$minuteDropdownValue',
                    ),
                    initialValue: minuteDropdownValue,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                    ),
                    items: [
                      ..._minuteOptions.map(
                        (minutes) => DropdownMenuItem<String>(
                          value: minutes.toString(),
                          child: Text(
                            minutes == 1 ? '1 minute' : '$minutes minutes',
                          ),
                        ),
                      ),
                      const DropdownMenuItem<String>(
                        value: _customMinuteOption,
                        child: Text('Custom'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _useCustomMinutes = value == _customMinuteOption;
                              if (_useCustomMinutes) {
                                final currentText =
                                    _customMinutesController.text.trim();
                                if (currentText.isEmpty) {
                                  _customMinutesController.text =
                                      _offsetMinutes.toString();
                                }
                              } else {
                                _offsetMinutes = int.parse(value);
                              }
                              _customMinutesError = null;
                            });
                          },
                  ),
                  if (_useCustomMinutes) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey<String>(
                        'task_reminder_custom_minutes_field',
                      ),
                      controller: _customMinutesController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Custom minutes',
                        helperText: 'Enter any positive whole number',
                        errorText: _customMinutesError,
                      ),
                      onChanged: (_) {
                        if (_customMinutesError == null) return;
                        setState(() => _customMinutesError = null);
                      },
                    ),
                  ],
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'This reminder fires exactly at the task boundary.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: _enabled,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _enabled = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : widget.onClose,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey<String>(
                          'task_reminder_save_button',
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: Text(_isSaving ? 'Saving...' : 'Save Rule'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
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
          color: Colors.transparent,
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
      _items[index] = _items[index].copyWith(visible: !_items[index].visible);
    });
    widget.sp.updateMenuConfig(_items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
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
          final label = kMenuItemLabels[item.id] ?? item.id;

          return Container(
            key: ValueKey(item.id),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      size: 20, color: cs.onSurface.withValues(alpha: 0.25)),
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
              width: 4,
              height: 4,
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
