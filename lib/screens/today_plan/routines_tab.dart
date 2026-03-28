// =============================================================
// RoutinesTab — Tapping a routine opens settings, not runner
// Start button separate. Subtask previews. Recurrence badge.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'routine_runner_screen.dart';
import 'routine_editor_sheet.dart';
import 'study_session_picker.dart';

class RoutinesTab extends StatelessWidget {
  final String dateKey;
  const RoutinesTab({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final routines = app.routines;
    final todayLogs = app.getRoutineLogsForDate(dateKey);

    final prayerRoutines =
        routines.where((r) => r.id.startsWith('prayer_')).toList();
    final customRoutines =
        routines.where((r) => !r.id.startsWith('prayer_')).toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '${routines.length} routine${routines.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showEditor(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: routines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 48, color: cs.primary.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text('No routines yet',
                          style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text('Create a morning or evening routine',
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.35))),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showEditor(context, null),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Routine'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 4, 16,
                      MediaQuery.of(context).padding.bottom + 72 + 24),
                  children: [
                    _StudySessionCard(dateKey: dateKey),
                    const SizedBox(height: 12),

                    if (prayerRoutines.isNotEmpty) ...[
                      _SectionHeader(emoji: '🕌', label: 'Prayer Routines', count: prayerRoutines.length),
                      ...prayerRoutines.map((r) {
                        final wasRun = todayLogs.any((l) => l.routineId == r.id && l.completed);
                        return _RoutineCard(
                          routine: r,
                          wasRunToday: wasRun,
                          // Tap = open editor/settings
                          onTap: () => _showEditor(context, r),
                          onStart: () => _startRoutine(context, r),
                          onDelete: () => _deleteRoutine(context, r),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    if (customRoutines.isNotEmpty) ...[
                      _SectionHeader(emoji: '🔄', label: 'Custom Routines', count: customRoutines.length),
                      ...customRoutines.map((r) {
                        final wasRun = todayLogs.any((l) => l.routineId == r.id && l.completed);
                        return _RoutineCard(
                          routine: r,
                          wasRunToday: wasRun,
                          onTap: () => _showEditor(context, r),
                          onStart: () => _startRoutine(context, r),
                          onDelete: () => _deleteRoutine(context, r),
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _startRoutine(BuildContext context, Routine r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineRunnerScreen(routine: r, dateKey: dateKey),
      ),
    );
  }

  void _showEditor(BuildContext context, Routine? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => RoutineEditorSheet(existing: existing),
    );
  }

  void _deleteRoutine(BuildContext context, Routine r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text('Delete "${r.name}" and all its steps?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteRoutine(r.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  const _SectionHeader({required this.emoji, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Routine Card ────────────────────────────────────────────────
class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool wasRunToday;
  final VoidCallback onTap;    // opens settings/editor
  final VoidCallback onStart;  // launches runner
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.wasRunToday,
    required this.onTap,
    required this.onStart,
    required this.onDelete,
  });

  String? _formatReminderTime() {
    final t = routine.reminderTime;
    if (t == null || t.isEmpty) return null;
    try {
      final parsed = DateFormat('HH:mm').parseStrict(t);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return t;
    }
  }

  String _recurrenceBadge() {
    switch (routine.recurrenceType) {
      case 'daily': return 'Daily';
      case 'weekly':
        if (routine.recurrenceDays.isEmpty) return 'Weekly';
        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        return routine.recurrenceDays
            .map((d) => days[(d - 1).clamp(0, 6)])
            .join(', ');
      case 'monthly': return 'Monthly';
      default:
        switch (routine.recurrence ?? '') {
          case 'daily': return 'Daily';
          case 'weekly': return 'Weekly';
          case 'until_date':
            final ed = routine.recurrenceEndDate;
            if (ed == null) return 'Until date';
            try {
              return 'Until ${DateFormat('dd MMM').format(DateTime.parse(ed))}';
            } catch (_) { return 'Until $ed'; }
          default: return '';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final routineColor = Color(routine.color);
    final reminderLabel = _formatReminderTime();
    final recLabel = _recurrenceBadge();
    final durationMin = routine.subtasks.isNotEmpty
        ? routine.totalSubtaskMinutes
        : routine.totalEstimatedMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap, // TAP = settings/editor
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: routineColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(routine.icon,
                          style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(routine.name,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface))),
                            if (wasRunToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('✓ Done',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (reminderLabel != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 13,
                                      color: cs.onSurface.withValues(alpha: 0.55)),
                                  const SizedBox(width: 3),
                                  Text(reminderLabel,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface.withValues(alpha: 0.7))),
                                ],
                              ),
                            if (recLabel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: routineColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(recLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: routineColor)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Subtask preview chips
              if (routine.subtasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: routine.subtasks.take(4).map((s) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${s.emoji} ${s.name} (${s.durationMinutes}m)',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.6))),
                    )
                  ).toList()
                    ..addAll(routine.subtasks.length > 4
                      ? [Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${routine.subtasks.length - 4} more',
                              style: TextStyle(fontSize: 11, color: cs.primary)),
                        )]
                      : []),
                ),
              ],

              const SizedBox(height: 10),

              // Bottom row: duration + buttons
              Row(
                children: [
                  Text(
                    '${routine.steps.length} step${routine.steps.length == 1 ? '' : 's'}'
                    ' · ~${durationMin > 0 ? durationMin : routine.totalEstimatedMinutes} min',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                  const Spacer(),
                  // Settings tap hint
                  Text('Tap to edit settings',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.3))),
                  const SizedBox(width: 10),
                  // Explicit Start button
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: routineColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              size: 14, color: routineColor),
                          const SizedBox(width: 4),
                          Text('Start',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: routineColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit / Settings')),
                      const PopupMenuItem(value: 'start', child: Text('Start')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 'edit': onTap();
                        case 'start': onStart();
                        case 'delete': onDelete();
                      }
                    },
                    icon: Icon(Icons.more_vert_rounded,
                        size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Study Session Card ──────────────────────────────────────────
class _StudySessionCard extends StatelessWidget {
  final String dateKey;
  const _StudySessionCard({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final nextPage = app.getNextContinuePage();
    final totalRead = app.faPages.where((p) => p.status != 'unread').length;
    final totalPages = app.faPages.length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => StudySessionPicker(dateKey: dateKey),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                const Color(0xFF6366F1).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Color(0xFF8B5CF6), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Study Session',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 3),
                    Text(
                      'Next: Page $nextPage · $totalRead/$totalPages done',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF8B5CF6), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
