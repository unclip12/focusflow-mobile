// =============================================================
// NotificationSettingsSheet — modal bottom sheet
// Toggles: study reminders, achievements, revision alerts,
//          daily summary.  Quiet hours start/end time pickers.
// Android rules: enableDrag: false, useSafeArea: true.
// Save via SettingsProvider.updateNotifications() /
//          SettingsProvider.updateQuietHours().
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/app_settings.dart';

// ── Public helper to open the sheet ───────────────────────────────
Future<void> showNotificationSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    enableDrag: false,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NotificationSettingsSheet(),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────
class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  // Local copies — applied on change
  late Map<String, bool> _types;
  late bool _quietEnabled;
  late String _quietStart;
  late String _quietEnd;

  @override
  void initState() {
    super.initState();
    final sp = context.read<SettingsProvider>();
    final nc = sp.settings.notifications;
    final qh = sp.settings.quietHours;

    _types = {
      'studyReminders': nc.types['blockTimers'] ?? true,
      'achievements':   nc.types['mentorNudges'] ?? true,
      'revisionAlerts': nc.types['breaks'] ?? true,
      'dailySummary':   nc.types['dailySummary'] ?? true,
    };
    _quietEnabled = qh.enabled;
    _quietStart   = qh.start;
    _quietEnd     = qh.end;
  }

  // ── Helpers ───────────────────────────────────────────────────
  void _setType(String key, bool value) {
    setState(() => _types[key] = value);
    _saveNotifications();
  }

  void _saveNotifications() {
    final sp = context.read<SettingsProvider>();
    final nc = sp.settings.notifications;
    sp.updateNotifications(nc.copyWith(types: {
      'blockTimers':  _types['studyReminders'] ?? true,
      'mentorNudges': _types['achievements']   ?? true,
      'breaks':       _types['revisionAlerts'] ?? true,
      'dailySummary': _types['dailySummary']   ?? true,
    }));
  }

  void _saveQuietHours() {
    final sp = context.read<SettingsProvider>();
    sp.updateQuietHours(QuietHoursConfig(
      enabled: _quietEnabled,
      start:   _quietStart,
      end:     _quietEnd,
    ));
  }

  Future<void> _pickTime(String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    if (!mounted) return;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag pill ─────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Notification type toggles ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Notification Types',
              style: theme.textTheme.labelSmall?.copyWith(
                color:       cs.onSurface.withValues(alpha: 0.5),
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          _ToggleTile(
            icon:    Icons.alarm_rounded,
            color:   const Color(0xFF6366F1),
            label:   'Study Reminders',
            value:   _types['studyReminders'] ?? true,
            onChanged: (v) => _setType('studyReminders', v),
          ),
          _ToggleTile(
            icon:    Icons.emoji_events_rounded,
            color:   const Color(0xFFF59E0B),
            label:   'Achievements',
            value:   _types['achievements'] ?? true,
            onChanged: (v) => _setType('achievements', v),
          ),
          _ToggleTile(
            icon:    Icons.replay_rounded,
            color:   const Color(0xFFF43F5E),
            label:   'Revision Alerts',
            value:   _types['revisionAlerts'] ?? true,
            onChanged: (v) => _setType('revisionAlerts', v),
          ),
          _ToggleTile(
            icon:    Icons.summarize_rounded,
            color:   const Color(0xFF10B981),
            label:   'Daily Summary',
            value:   _types['dailySummary'] ?? true,
            onChanged: (v) => _setType('dailySummary', v),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 12),

          // ── Quiet hours ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Quiet Hours',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:       cs.onSurface.withValues(alpha: 0.5),
                    fontWeight:  FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value:            _quietEnabled,
                  activeColor: cs.primary,
                  onChanged: (v) {
                    setState(() => _quietEnabled = v);
                    _saveQuietHours();
                  },
                ),
              ],
            ),
          ),

          if (_quietEnabled) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Start',
                      time:  _quietStart,
                      onTap: () => _pickTime(_quietStart, (t) {
                        setState(() => _quietStart = t);
                        _saveQuietHours();
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeTile(
                      label: 'End',
                      time:  _quietEnd,
                      onTap: () => _pickTime(_quietEnd, (t) {
                        setState(() => _quietEnd = t);
                        _saveQuietHours();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bottom padding (keyboard / home bar)
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Container(
            padding:    const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(
            value:            value,
            activeColor: cs.primary,
            onChanged:        onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Time tile ─────────────────────────────────────────────────────
class _TimeTile extends StatelessWidget {
  final String       label;
  final String       time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:        cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 15, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
