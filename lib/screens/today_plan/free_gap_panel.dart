// =============================================================
// FreeGapPanel — Bottom sheet for free gap slots
// Wires: New Task, Study Session, Revision, Add Routine
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:provider/provider.dart';
import 'add_task_sheet.dart';
import 'study_flow_screen.dart';
import 'routine_editor_sheet.dart';

class FreeGapPanel extends StatelessWidget {
  final TimeOfDay gapStart;
  final TimeOfDay gapEnd;
  final String dateKey;

  const FreeGapPanel({
    super.key,
    required this.gapStart,
    required this.gapEnd,
    required this.dateKey,
  });

  int get _gapMinutes =>
      (gapEnd.hour * 60 + gapEnd.minute) -
      (gapStart.hour * 60 + gapStart.minute);

  String get _durationLabel {
    final m = _gapMinutes;
    if (m >= 60) {
      final h = m ~/ 60;
      final rem = m % 60;
      return rem > 0 ? '${h}h ${rem}min free' : '${h}h free';
    }
    return '$m min free';
  }

  String _fmt12(TimeOfDay t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final suffix = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FREE GAP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_fmt12(gapStart)} – ${_fmt12(gapEnd)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                _durationLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── New Task ────────────────────────────────────────
          _ActionButton(
            icon: Icons.add_task_rounded,
            label: 'New Task',
            subtitle: 'Add any task to this time slot',
            color: const Color(0xFF6366F1),
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskSheet(
                  dateKey: dateKey,
                  prefillStartTime: gapStart,
                  prefillEndTime: gapEnd,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Study Session ───────────────────────────────────
          _ActionButton(
            icon: Icons.school_rounded,
            label: 'Study Session',
            subtitle: 'Start a focused study block here',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudyFlowScreen(dateKey: dateKey),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Revision ───────────────────────────────────────
          _ActionButton(
            icon: Icons.replay_rounded,
            label: 'Revision',
            subtitle: 'Schedule a revision block in this gap',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              // Open Add Task sheet pre-filled as revision type
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskSheet(
                  dateKey: dateKey,
                  prefillStartTime: gapStart,
                  prefillEndTime: gapEnd,
                  prefillCategory: 'Revision',
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Add Routine ────────────────────────────────────
          _ActionButton(
            icon: Icons.repeat_rounded,
            label: 'Add Routine',
            subtitle: 'Insert a routine into this slot',
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              _showRoutinePicker(context);
            },
          ),
        ],
      ),
    );
  }

  void _showRoutinePicker(BuildContext context) {
    final app = context.read<AppProvider>();
    final routines = app.routines
        .where((r) => !r.id.startsWith('prayer_'))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Select Routine',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const RoutineEditorSheet(existing: null),
                      );
                    },
                    child: const Text('Create New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (routines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No routines yet. Create one first.',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                )
              else
                ...routines.map((r) => ListTile(
                      leading: Text(r.icon,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(r.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '~${r.subtasks.isNotEmpty ? r.totalSubtaskMinutes : r.totalEstimatedMinutes} min'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        // Add routine as block into the gap
                        _insertRoutineAsBlock(context, r);
                      },
                    )),
            ],
          ),
        );
      },
    );
  }

  void _insertRoutineAsBlock(BuildContext context, Routine routine) {
    final app = context.read<AppProvider>();
    final durationMin = routine.subtasks.isNotEmpty
        ? routine.totalSubtaskMinutes
        : routine.totalEstimatedMinutes;
    final startMin = gapStart.hour * 60 + gapStart.minute;
    final endMin = startMin + durationMin;
    final endH = (endMin ~/ 60).clamp(0, 23);
    final endM = endMin % 60;

    final block = app.buildRoutineBlock(
      routine: routine,
      dateKey: dateKey,
      startTime:
          '${gapStart.hour.toString().padLeft(2, '0')}:${gapStart.minute.toString().padLeft(2, '0')}',
      endTime:
          '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
    );
    if (block != null) {
      app.addBlockToDayPlan(block, dateKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${routine.name} added to timeline'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                cs.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
