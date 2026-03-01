// =============================================================
// RoutinesTab — List of user-created routines with management
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'routine_runner_screen.dart';
import 'routine_editor_sheet.dart';

class RoutinesTab extends StatelessWidget {
  final String dateKey;
  const RoutinesTab({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final routines = app.routines;
    final todayLogs = app.getRoutineLogsForDate(dateKey);

    // Split into prayer & custom
    final prayerRoutines = routines.where((r) => r.id.startsWith('prayer_')).toList();
    final customRoutines = routines.where((r) => !r.id.startsWith('prayer_')).toList();

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────
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

        // ── Routines list ─────────────────────────────────────
        Expanded(
          child: routines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded, size: 48,
                          color: cs.primary.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text(
                        'No routines yet',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a morning or evening routine',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showEditor(context, null),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Routine'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    // ── Prayer Routines Section ──
                    if (prayerRoutines.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(
                          children: [
                            const Text('🕌', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              'Prayer Routines',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${prayerRoutines.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...prayerRoutines.map((r) {
                        final wasRun = todayLogs.any((l) => l.routineId == r.id && l.completed);
                        return _RoutineCard(
                          routine: r,
                          wasRunToday: wasRun,
                          onStart: () => _startRoutine(context, r),
                          onEdit: () => _showEditor(context, r),
                          onDelete: () => _deleteRoutine(context, r),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // ── Custom Routines Section ──
                    if (customRoutines.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Text('🔄', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              'Custom Routines',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${customRoutines.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...customRoutines.map((r) {
                        final wasRun = todayLogs.any((l) => l.routineId == r.id && l.completed);
                        return _RoutineCard(
                          routine: r,
                          wasRunToday: wasRun,
                          onStart: () => _startRoutine(context, r),
                          onEdit: () => _showEditor(context, r),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            child: const Text('Cancel'),
          ),
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

// ── Routine Card ────────────────────────────────────────────────
class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool wasRunToday;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.wasRunToday,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final routineColor = Color(routine.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: routineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(routine.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            routine.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (wasRunToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✓ Done',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routine.steps.length} steps • ~${routine.totalEstimatedMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'start', child: Text('Start')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) {
                  switch (v) {
                    case 'start': onStart();
                    case 'edit': onEdit();
                    case 'delete': onDelete();
                  }
                },
                icon: Icon(Icons.more_vert_rounded, size: 20,
                    color: cs.onSurface.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
