// =============================================================
// SessionCompleteDialog — shown when focus timer session ends
// Shows duration, block name, subject. Log Time / Start Break / Done
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class SessionCompleteDialog extends StatelessWidget {
  final int durationMinutes;
  final String blockName;
  final String subject;
  final DateTime startedAt;

  const SessionCompleteDialog({
    super.key,
    required this.durationMinutes,
    required this.blockName,
    required this.subject,
    required this.startedAt,
  });

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Celebration icon ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),

            Text('Session Complete! 🎉',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // ── Stats ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _StatRow(
                      icon: Icons.timer_rounded,
                      label: 'Duration',
                      value: _formatDuration(durationMinutes)),
                  const SizedBox(height: 8),
                  if (blockName.isNotEmpty)
                    _StatRow(
                        icon: Icons.view_agenda_rounded,
                        label: 'Block',
                        value: blockName),
                  if (subject.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _StatRow(
                        icon: Icons.subject_rounded,
                        label: 'Subject',
                        value: subject),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Log Time button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _logTime(context),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Log Time'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Secondary actions ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('break'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Start Break'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('done'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _logTime(BuildContext context) {
    HapticsService.medium();
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final id = 'tl_${now.millisecondsSinceEpoch}';
    final dateStr = AppDateUtils.todayKey();

    final entry = TimeLogEntry(
      id: id,
      date: dateStr,
      startTime: startedAt.toIso8601String(),
      endTime: now.toIso8601String(),
      durationMinutes: durationMinutes,
      category: TimeLogCategory.study,
      source: TimeLogSource.focusTimer,
      activity: blockName.isNotEmpty ? blockName : 'Focus Session',
    );

    app.upsertTimeLog(entry);
    Navigator.of(context).pop('logged');
  }
}

// ── Stat row ────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            )),
        const Spacer(),
        Text(value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
