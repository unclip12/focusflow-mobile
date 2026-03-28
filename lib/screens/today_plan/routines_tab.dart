import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'routine_editor_sheet.dart';
import 'routine_runner_screen.dart';
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
                      Icon(
                        Icons.repeat_rounded,
                        size: 48,
                        color: cs.primary.withValues(alpha: 0.25),
                      ),
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.of(context).padding.bottom + 72 + 24,
                  ),
                  children: [
                    _StudySessionCard(dateKey: dateKey),
                    const SizedBox(height: 12),
                    if (prayerRoutines.isNotEmpty) ...[
                      _SectionHeader(
                        emoji: '\u{1F54C}',
                        label: 'Prayer Routines',
                        count: prayerRoutines.length,
                      ),
                      ...prayerRoutines.map((routine) {
                        final wasRun = todayLogs.any(
                          (log) => log.routineId == routine.id && log.completed,
                        );
                        return _RoutineCard(
                          routine: routine,
                          wasRunToday: wasRun,
                          onTap: () => _showEditor(context, routine),
                          onStart: () => _startRoutine(context, routine),
                          onDelete: () => _deleteRoutine(context, routine),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                    if (customRoutines.isNotEmpty) ...[
                      _SectionHeader(
                        emoji: '\u{1F504}',
                        label: 'Custom Routines',
                        count: customRoutines.length,
                      ),
                      ...customRoutines.map((routine) {
                        final wasRun = todayLogs.any(
                          (log) => log.routineId == routine.id && log.completed,
                        );
                        return _RoutineCard(
                          routine: routine,
                          wasRunToday: wasRun,
                          onTap: () => _showEditor(context, routine),
                          onStart: () => _startRoutine(context, routine),
                          onDelete: () => _deleteRoutine(context, routine),
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _startRoutine(BuildContext context, Routine routine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineRunnerScreen(routine: routine, dateKey: dateKey),
      ),
    );
  }

  void _showEditor(BuildContext context, Routine? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoutineEditorSheet(existing: existing),
    );
  }

  void _deleteRoutine(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text('Delete "${routine.name}" and all its steps?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteRoutine(routine.id);
              Navigator.pop(dialogContext);
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

  const _SectionHeader({
    required this.emoji,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
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
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool wasRunToday;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.wasRunToday,
    required this.onTap,
    required this.onStart,
    required this.onDelete,
  });

  String? _formatReminderTime() {
    final reminderTime = routine.reminderTime;
    if (reminderTime == null || reminderTime.isEmpty) return null;

    try {
      final parsed = DateFormat('HH:mm').parseStrict(reminderTime);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return reminderTime;
    }
  }

  ({String label, Color color})? _recurrenceBadge() {
    switch (routine.recurrenceType) {
      case 'daily':
        return (label: 'Daily', color: const Color(0xFF2563EB));
      case 'weekly':
        return (label: 'Weekly', color: const Color(0xFF16A34A));
      case 'monthly':
        return (label: 'Monthly', color: const Color(0xFFEA580C));
      case 'none':
        return null;
    }

    switch (routine.recurrence ?? '') {
      case 'daily':
        return (label: 'Daily', color: const Color(0xFF2563EB));
      case 'weekly':
        return (label: 'Weekly', color: const Color(0xFF16A34A));
      default:
        return null;
    }
  }

  String _formatDuration(int minutes) {
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final hours = safeMinutes ~/ 60;
    final remainder = safeMinutes % 60;

    if (hours > 0) {
      if (remainder == 0) return '${hours}h';
      return '${hours}h ${remainder}min';
    }

    return '$safeMinutes min';
  }

  Future<void> _addToTodayPlan(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (pickerContext, child) => MediaQuery(
        data:
            MediaQuery.of(pickerContext).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (pickedTime == null || !context.mounted) return;

    final now = DateTime.now();
    final todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final plannedDurationMinutes = routine.totalSubtaskMinutes > 0
        ? routine.totalSubtaskMinutes
        : routine.totalEstimatedMinutes;
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final endDateTime =
        startDateTime.add(Duration(minutes: plannedDurationMinutes));
    final timeFormat = DateFormat('HH:mm');

    final block = Block(
      id: Uuid().v4(),
      index: 0,
      date: todayDateKey,
      plannedStartTime: timeFormat.format(startDateTime),
      plannedDurationMinutes: plannedDurationMinutes,
      plannedEndTime: timeFormat.format(endDateTime),
      type: BlockType.other,
      title: routine.name,
      isEvent: false,
      status: BlockStatus.notStarted,
    );

    final app = context.read<AppProvider>();
    final existingPlan = app.getDayPlan(todayDateKey);
    final existingBlocks = List<Block>.from(existingPlan?.blocks ?? const []);
    final allBlocks = [
      ...existingBlocks,
      block.copyWith(index: existingBlocks.length),
    ];

    final updatedPlan = existingPlan?.copyWith(
          blocks: allBlocks,
          totalStudyMinutesPlanned: allBlocks
              .where((item) => item.type != BlockType.breakBlock)
              .fold<int>(0, (sum, item) => sum + item.plannedDurationMinutes),
          totalBreakMinutes: allBlocks
              .where((item) => item.type == BlockType.breakBlock)
              .fold<int>(0, (sum, item) => sum + item.plannedDurationMinutes),
        ) ??
        DayPlan(
          date: todayDateKey,
          faPages: const [],
          faPagesCount: 0,
          videos: const [],
          notesFromUser: '',
          notesFromAI: '',
          attachments: const [],
          breaks: const [],
          blocks: allBlocks,
          totalStudyMinutesPlanned: allBlocks
              .where((item) => item.type != BlockType.breakBlock)
              .fold<int>(0, (sum, item) => sum + item.plannedDurationMinutes),
          totalBreakMinutes: allBlocks
              .where((item) => item.type == BlockType.breakBlock)
              .fold<int>(0, (sum, item) => sum + item.plannedDurationMinutes),
        );

    await app.upsertDayPlan(updatedPlan);
    await app.syncFlowActivitiesFromDayPlan(todayDateKey);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${routine.name}" added to timeline'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSubtaskPreview(
    BuildContext context,
    List<RoutineSubtask> subtasks,
  ) {
    final cs = Theme.of(context).colorScheme;
    final previewSubtasks = subtasks.take(3).toList();
    final remainingCount = subtasks.length - previewSubtasks.length;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final subtask in previewSubtasks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              '${subtask.emoji} ${subtask.name}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        if (remainingCount > 0)
          Text(
            '+$remainingCount more',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final routineColor = Color(routine.color);
    final reminderLabel = _formatReminderTime();
    final recurrenceBadge = _recurrenceBadge();
    final durationMinutes = routine.subtasks.isNotEmpty
        ? routine.totalSubtaskMinutes
        : routine.totalEstimatedMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: routineColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        routine.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                routine.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (wasRunToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (recurrenceBadge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: recurrenceBadge.color
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  recurrenceBadge.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: recurrenceBadge.color,
                                  ),
                                ),
                              ),
                            if (reminderLabel != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reminderLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (routine.subtasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSubtaskPreview(context, routine.subtasks),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDuration(durationMinutes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Text(
                    'Tap to edit settings',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addToTodayPlan(context),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text("Add to Today's Plan"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: cs.outlineVariant),
                        foregroundColor: cs.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: routineColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: routineColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: routineColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit / Settings'),
                      ),
                      const PopupMenuItem(value: 'start', child: Text('Start')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onTap();
                          break;
                        case 'start':
                          onStart();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
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

class _StudySessionCard extends StatelessWidget {
  final String dateKey;

  const _StudySessionCard({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final nextPage = app.getNextContinuePage();
    final totalRead =
        app.faPages.where((page) => page.status != 'unread').length;
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
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Study Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Next: Page $nextPage - $totalRead/$totalPages done',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
