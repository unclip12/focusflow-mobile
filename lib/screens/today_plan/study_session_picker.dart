import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:intl/intl.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import 'study_flow_screen.dart';

class StudySessionPicker extends StatefulWidget {
  final String dateKey;
  const StudySessionPicker({super.key, required this.dateKey});

  @override
  State<StudySessionPicker> createState() => _StudySessionPickerState();
}

class _StudySessionPickerState extends State<StudySessionPicker> {
  final List<StudyTask> _queue = [];
  static const _plannedStudySessionKind = 'planned_study_session';

  List<Block> _plannedSessionBlocks(AppProvider app) {
    final plan = app.getDayPlan(widget.dateKey);
    final blocks = (plan?.blocks ?? const <Block>[])
        .where(
          (block) =>
              block.type == BlockType.studySession &&
              block.status == BlockStatus.notStarted,
        )
        .toList()
      ..sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));
    return blocks;
  }

  List<StudyTask> _plannedQueueFromBlock(Block block) {
    final notes = block.reflectionNotes;
    if (notes == null || notes.isEmpty) {
      return const <StudyTask>[];
    }
    try {
      final decoded = jsonDecode(notes);
      if (decoded is! Map<String, dynamic>) {
        return const <StudyTask>[];
      }
      if (decoded['kind'] != _plannedStudySessionKind) {
        return const <StudyTask>[];
      }
      return StudyTask.fromJsonList(decoded['tasks']);
    } catch (_) {
      return const <StudyTask>[];
    }
  }

  int _plannedQueueMinutesFromBlock(Block block) {
    final notes = block.reflectionNotes;
    if (notes != null && notes.isNotEmpty) {
      try {
        final decoded = jsonDecode(notes);
        if (decoded is Map<String, dynamic>) {
          final minutes = decoded['estimatedDurationMinutes'] as int?;
          if (minutes != null && minutes > 0) {
            return minutes;
          }
        }
      } catch (_) {
        // Fall back to queue-derived estimate.
      }
    }
    if (block.plannedDurationMinutes > 0) {
      return block.plannedDurationMinutes;
    }
    return StudyTask.estimateQueueDurationMinutes(
        _plannedQueueFromBlock(block));
  }

  int _plannedQueueItemCount(Block block) {
    return StudyTask.totalItemCount(_plannedQueueFromBlock(block));
  }

  List<StudyTask> _queueWithPlanningDefaults(Iterable<StudyTask> tasks) {
    return tasks
        .map(
          (task) => task.copyWith(
            plannedDurationMinutes:
                task.plannedDurationMinutes ?? task.estimatedDurationMinutes,
          ),
        )
        .toList();
  }

  String _buildTaskId({
    required String type,
    List<int> pageNumbers = const [],
    List<int> topicIds = const [],
  }) {
    final parts = <String>[
      type,
      pageNumbers.join('-'),
      topicIds.join('-'),
      DateTime.now().microsecondsSinceEpoch.toString(),
    ];
    return parts.join('|');
  }

  String _buildStudySessionTitle(List<StudyTask> tasks) {
    final parts = <String>[];
    final faPages = tasks
        .where((task) => task.type == 'FA')
        .expand((task) => task.pageNumbers)
        .toList()
      ..sort();
    if (faPages.isNotEmpty) {
      if (faPages.length == 1) {
        parts.add('FA p.${faPages.first}');
      } else {
        parts.add('FA pp.${faPages.first}-${faPages.last}');
      }
    }
    if (tasks.any((task) => task.type == 'UWORLD')) {
      parts.add('UWorld');
    }
    if (tasks.any(
      (task) => task.type == 'SKETCHY_MICRO' || task.type == 'SKETCHY_PHARM',
    )) {
      parts.add('Sketchy');
    }
    if (tasks.any((task) => task.type == 'PATHOMA')) {
      parts.add('Pathoma');
    }
    if (parts.isEmpty && tasks.isNotEmpty) {
      parts.add(tasks.first.label);
    }

    if (parts.isEmpty) {
      return 'Study Session';
    }
    return 'Study Session • ${parts.join(' + ')}';
  }

  Map<String, dynamic> _plannedStudySessionPayload(
    List<StudyTask> tasks,
    int estimatedMinutes,
  ) {
    return {
      'kind': _plannedStudySessionKind,
      'estimatedDurationMinutes': estimatedMinutes,
      'tasks': StudyTask.toJsonList(tasks),
    };
  }

  String _formatPlannedTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return hhmm;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return hhmm;
    }
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _timeOfDayFromString(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _sessionStartDateTime(TimeOfDay time) {
    final date = DateTime.tryParse(widget.dateKey) ?? DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  DateTime _blockStartDateTime(Block block) {
    final date = DateTime.tryParse(block.date) ??
        DateTime.tryParse(widget.dateKey) ??
        DateTime.now();
    final time = _timeOfDayFromString(block.plannedStartTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _plannedTaskWindowLabel(
    DateTime sessionStart,
    List<StudyTask> tasks,
    int index,
  ) {
    var taskStart = sessionStart;
    for (var i = 0; i < index; i++) {
      taskStart = taskStart.add(
        Duration(minutes: tasks[i].estimatedDurationMinutes),
      );
    }
    final task = tasks[index];
    final taskEnd = taskStart.add(
      Duration(minutes: task.estimatedDurationMinutes),
    );
    return '${DateFormat('h:mm a').format(taskStart)} -> ${DateFormat('h:mm a').format(taskEnd)} • ${task.estimatedDurationMinutes} min';
  }

  String _formatDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) {
      return '${mins}min';
    }
    return '${hours}h ${mins.toString().padLeft(2, '0')}min';
  }

  int _notificationIdForBlock(String blockId) {
    return blockId.codeUnits.fold<int>(
      0,
      (value, code) => ((value * 31) + code) & 0x7fffffff,
    );
  }

  Future<int?> _pickTaskDurationMinutes(int initialMinutes) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _TaskDurationDialog(initialMinutes: initialMinutes);
      },
    );
  }

  RevisionItem? _findRevisionItem(AppProvider app, String revisionId) {
    final index = app.revisionItems.indexWhere((item) => item.id == revisionId);
    if (index < 0) {
      return null;
    }
    return app.revisionItems[index];
  }

  List<_RevisionStatusSummary> _revisionStatusesForTask(
    AppProvider app,
    StudyTask task,
  ) {
    final revisions = <RevisionItem>[];
    switch (task.type) {
      case 'FA':
        for (final page in task.pageNumbers) {
          final item = _findRevisionItem(app, 'fa-page-$page');
          if (item != null) {
            revisions.add(item);
          }
        }
        break;
      case 'SKETCHY_MICRO':
        for (final id in task.topicIds) {
          final item = _findRevisionItem(app, 'sketchy-micro-$id');
          if (item != null) {
            revisions.add(item);
          }
        }
        break;
      case 'SKETCHY_PHARM':
        for (final id in task.topicIds) {
          final item = _findRevisionItem(app, 'sketchy-pharm-$id');
          if (item != null) {
            revisions.add(item);
          }
        }
        break;
      case 'PATHOMA':
        for (final id in task.topicIds) {
          final item = _findRevisionItem(app, 'pathoma-ch-$id');
          if (item != null) {
            revisions.add(item);
          }
        }
        break;
    }

    return revisions
        .map(_buildRevisionStatusSummary)
        .whereType<_RevisionStatusSummary>()
        .toList();
  }

  _RevisionStatusSummary? _buildRevisionStatusSummary(RevisionItem item) {
    final scheduledAt = DateTime.tryParse(item.nextRevisionAt)?.toLocal();
    if (scheduledAt == null) {
      return null;
    }

    final now = DateTime.now();
    final difference = scheduledAt.difference(now);
    final dateLabel = DateFormat('d MMM yyyy').format(scheduledAt);
    final timeLabel = DateFormat('h:mm a').format(scheduledAt);
    if (difference.isNegative) {
      return _RevisionStatusSummary(
        text:
            'Scheduled for $dateLabel at $timeLabel • Overdue by ${_formatRelativeTime(difference.abs())}',
        overdue: true,
      );
    }

    return _RevisionStatusSummary(
      text:
          'Scheduled for $dateLabel at $timeLabel • in ${_formatRelativeTime(difference)}',
      overdue: false,
    );
  }

  String _formatRelativeTime(Duration duration) {
    if (duration.inHours >= 24) {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      if (hours == 0) {
        return '$days day${days == 1 ? '' : 's'}';
      }
      return '$days day${days == 1 ? '' : 's'} $hours hour${hours == 1 ? '' : 's'}';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    return '$hours hour${hours == 1 ? '' : 's'} $minutes min';
  }

  List<_PlannedSessionQueueRowData> _plannedRowsForBlock(
    AppProvider app,
    Block block,
  ) {
    final queue = _plannedQueueFromBlock(block);
    final sessionStart = _blockStartDateTime(block);
    return queue.asMap().entries.map((entry) {
      final index = entry.key;
      final task = entry.value;
      return _PlannedSessionQueueRowData(
        icon: _iconForType(task.type),
        title: task.label,
        detail: task.detail,
        timeLabel: _plannedTaskWindowLabel(sessionStart, queue, index),
        revisionStatuses: _revisionStatusesForTask(app, task),
      );
    }).toList();
  }

  Future<void> _startPlannedSession(Block block) async {
    final queue = _plannedQueueFromBlock(block);
    if (queue.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start planned study session'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final app = context.read<AppProvider>();
    final dateKey = widget.dateKey;
    final startedAt = DateTime.now();
    navigator.pop();
    Future.microtask(() {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => StudyFlowScreen(
            dateKey: dateKey,
            queuedTasks: queue,
            onComplete: () {
              final completedAt = DateTime.now();
              unawaited(
                app.completeDayPlanBlock(
                  dateKey,
                  block.id,
                  startedAt: startedAt,
                  completedAt: completedAt,
                  durationSeconds: completedAt.difference(startedAt).inSeconds,
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Future<void> _showPlanForLaterSheet() async {
    if (_queue.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one task to plan this study session.'),
        ),
      );
      return;
    }

    var plannedQueue = _queueWithPlanningDefaults(_queue);
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final estimatedMinutes =
                StudyTask.estimateQueueDurationMinutes(plannedQueue);
            final sessionStart = _sessionStartDateTime(selectedTime);
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Plan for Later',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated duration: ${_formatDurationLabel(estimatedMinutes)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Planned Queue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drag to reorder - top item starts first',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          buildDefaultDragHandles: false,
                          itemCount: plannedQueue.length,
                          onReorder: (oldIndex, newIndex) {
                            setSheetState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final task = plannedQueue.removeAt(oldIndex);
                              plannedQueue.insert(newIndex, task);
                            });
                          },
                          itemBuilder: (_, index) {
                            final task = plannedQueue[index];
                            return Container(
                              key: ValueKey(task.id),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.drag_handle,
                                        size: 20,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _iconForType(task.type),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          task.detail,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.55),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _plannedTaskWindowLabel(
                                            sessionStart,
                                            plannedQueue,
                                            index,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: Text(
                                      '${task.estimatedDurationMinutes} min',
                                    ),
                                    onPressed: () async {
                                      final minutes =
                                          await _pickTaskDurationMinutes(
                                        task.estimatedDurationMinutes,
                                      );
                                      if (minutes == null) {
                                        return;
                                      }
                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }
                                      setSheetState(() {
                                        plannedQueue[index] = task.copyWith(
                                          plannedDurationMinutes: minutes,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scheduled Start',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: sheetContext,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: Text(selectedTime.format(sheetContext)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _savePlannedSession(
                            sheetContext,
                            plannedQueue,
                            selectedTime,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save to Day Plan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePlannedSession(
    BuildContext sheetContext,
    List<StudyTask> plannedQueue,
    TimeOfDay selectedTime,
  ) async {
    final app = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final sheetNavigator = Navigator.of(sheetContext);
    final rootNavigator = Navigator.of(context);
    final date = DateTime.tryParse(widget.dateKey) ?? DateTime.now();
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final estimatedMinutes =
        StudyTask.estimateQueueDurationMinutes(plannedQueue);
    final endAt = scheduledAt.add(Duration(minutes: estimatedMinutes));
    final title = _buildStudySessionTitle(plannedQueue);
    final block = Block(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      index: 0,
      date: widget.dateKey,
      plannedStartTime: _formatTimeOfDay(selectedTime),
      plannedEndTime:
          '${endAt.hour.toString().padLeft(2, '0')}:${endAt.minute.toString().padLeft(2, '0')}',
      type: BlockType.studySession,
      title: title,
      plannedDurationMinutes: estimatedMinutes,
      status: BlockStatus.notStarted,
      reflectionNotes: jsonEncode(
        _plannedStudySessionPayload(plannedQueue, estimatedMinutes),
      ),
    );

    final existingPlan = app.getDayPlan(widget.dateKey);
    final allBlocks = [...(existingPlan?.blocks ?? const <Block>[]), block]
      ..sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));
    final reindexedBlocks = List<Block>.generate(
      allBlocks.length,
      (index) => allBlocks[index].copyWith(index: index),
    );
    final totalStudyMinutes = reindexedBlocks
        .where((entry) => entry.type != BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);
    final totalBreakMinutes = reindexedBlocks
        .where((entry) => entry.type == BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);

    final plan = existingPlan?.copyWith(
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: totalStudyMinutes,
          totalBreakMinutes: totalBreakMinutes,
        ) ??
        DayPlan(
          date: widget.dateKey,
          faPages: const [],
          faPagesCount: 0,
          videos: const [],
          notesFromUser: '',
          notesFromAI: '',
          attachments: const [],
          breaks: const [],
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: totalStudyMinutes,
          totalBreakMinutes: totalBreakMinutes,
        );

    await app.upsertDayPlan(plan);
    await app.syncFlowActivitiesFromDayPlan(widget.dateKey);

    if (scheduledAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleStudySessionReminder(
        id: _notificationIdForBlock(block.id),
        blockTitle: title,
        when: scheduledAt,
      );
    }

    if (!mounted) return;
    sheetNavigator.pop();
    rootNavigator.pop();
    Future.microtask(() {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Study session planned for ${DateFormat('h:mm a').format(scheduledAt)}',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final plannedBlocks = _plannedSessionBlocks(app);
    final nextPage = app.getNextContinuePage();
    final targetPages = app.getTodayTargetPages(
      count: settingsProvider.dailyFAGoal,
    );
    final totalRead = app.faPages.where((p) => p.status != 'unread').length;
    final totalPages = app.faPages.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school_rounded, color: cs.primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Start Study Session',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_queue.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _startSession,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Start (${_queue.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showPlanForLaterSheet,
                              icon: const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Plan for Later',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (plannedBlocks.isNotEmpty) ...[
                      Text(
                        'Planned Sessions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...plannedBlocks.map((block) {
                        final itemCount = _plannedQueueItemCount(block);
                        final durationMinutes =
                            _plannedQueueMinutesFromBlock(block);
                        return _PlannedSessionDetailsCard(
                          title: block.title,
                          scheduledTime: _formatPlannedTime(
                            block.plannedStartTime,
                          ),
                          itemCount: itemCount,
                          durationLabel: _formatDurationLabel(durationMinutes),
                          queueRows: _plannedRowsForBlock(app, block),
                          onStartNow: () => _startPlannedSession(block),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            const Color(0xFF6366F1).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('FA', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FA Progress: $totalRead / $totalPages pages',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalPages > 0
                                        ? totalRead / totalPages
                                        : 0,
                                    backgroundColor:
                                        cs.onSurface.withValues(alpha: 0.08),
                                    color: const Color(0xFF8B5CF6),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'Continue Essay Reading',
                      subtitle:
                          'Continue from page $nextPage - Today\'s target: ${targetPages.length} pages',
                      onTap: () {
                        final navigator = Navigator.of(context);
                        settingsProvider.ensureStudyPlanStartDate();
                        navigator.pop();
                        Future.microtask(() {
                          navigator.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudyFlowScreen(dateKey: widget.dateKey),
                            ),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF10B981),
                      title: 'FA Pages',
                      subtitle: 'Select specific pages to study',
                      onTap: () => _showFAPagePicker(context, app),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'UWorld Questions',
                      subtitle:
                          '${app.uworldTopics.fold<int>(0, (s, t) => s + t.totalQuestions - t.doneQuestions)} questions remaining',
                      onTap: () => _showUWorldPicker(context, app),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      icon: Icons.play_circle_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'Sketchy Micro',
                      subtitle:
                          '${app.sketchyMicroVideos.where((v) => !v.watched).length} unwatched videos',
                      onTap: () => _showSketchyPicker(context, app, 'micro'),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      icon: Icons.play_circle_rounded,
                      color: const Color(0xFFEC4899),
                      title: 'Sketchy Pharm',
                      subtitle:
                          '${app.sketchyPharmVideos.where((v) => !v.watched).length} unwatched videos',
                      onTap: () => _showSketchyPicker(context, app, 'pharm'),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      icon: Icons.ondemand_video_rounded,
                      color: const Color(0xFFEF4444),
                      title: 'Pathoma',
                      subtitle:
                          '${app.pathomaChapters.where((c) => !c.watched).length} unwatched chapters',
                      onTap: () => _showPathomaPicker(context, app),
                    ),
                    const SizedBox(height: 20),
                    if (_queue.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Queued Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      ..._queue.asMap().entries.map((e) {
                        final i = e.key;
                        final task = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              _iconForType(task.type),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      task.detail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: cs.error,
                                ),
                                onPressed: () =>
                                    setState(() => _queue.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'FA':
        return const Icon(
          Icons.menu_book_rounded,
          color: Color(0xFF8B5CF6),
          size: 20,
        );
      case 'UWORLD':
        return const Icon(
          Icons.quiz_rounded,
          color: Color(0xFFF59E0B),
          size: 20,
        );
      case 'SKETCHY_MICRO':
        return const Icon(
          Icons.play_circle_rounded,
          color: Color(0xFF3B82F6),
          size: 20,
        );
      case 'SKETCHY_PHARM':
        return const Icon(
          Icons.play_circle_rounded,
          color: Color(0xFFEC4899),
          size: 20,
        );
      case 'PATHOMA':
        return const Icon(
          Icons.ondemand_video_rounded,
          color: Color(0xFFEF4444),
          size: 20,
        );
      default:
        return const Icon(
          Icons.school_rounded,
          color: Color(0xFF6366F1),
          size: 20,
        );
    }
  }

  String _faTaskDetail(List<int> pageNumbers) {
    final sortedPages = List<int>.from(pageNumbers)..sort();
    if (sortedPages.length == 1) {
      return 'Page ${sortedPages.first}';
    }
    return 'Pages ${sortedPages.first}-${sortedPages.last} (${sortedPages.length} pages)';
  }

  String _uWorldTaskDetail(List<UWorldTopic> topics, int questionCount) {
    return '${topics.length} topics - $questionCount questions';
  }

  String _pathomaTaskDetail(List<PathomaChapter> chapters) {
    if (chapters.length == 1) {
      return 'Chapter ${chapters.first.chapter}';
    }
    return '${chapters.length} chapters';
  }

  void _startSession() {
    final navigator = Navigator.of(context);
    final queueSnapshot = List<StudyTask>.from(_queue);
    navigator.pop();
    Future.microtask(() {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => StudyFlowScreen(
            dateKey: widget.dateKey,
            queuedTasks: queueSnapshot,
          ),
        ),
      );
    });
  }

  void _showFAPagePicker(BuildContext context, AppProvider app) {
    final cs = Theme.of(context).colorScheme;
    final pages = List<FAPage>.from(app.faPages)
      ..sort((a, b) {
        final orderCompare = a.orderIndex.compareTo(b.orderIndex);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.pageNum.compareTo(b.pageNum);
      });
    final selectedPageNumbers = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Select FA Pages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Selected: ${selectedPageNumbers.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pages.length,
                    itemBuilder: (ctx, i) {
                      final page = pages[i];
                      final isRead = page.status != 'unread';
                      final isSelected =
                          selectedPageNumbers.contains(page.pageNum);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              selectedPageNumbers.add(page.pageNum);
                            } else {
                              selectedPageNumbers.remove(page.pageNum);
                            }
                          });
                        },
                        secondary: Icon(
                          isRead
                              ? Icons.check_circle_rounded
                              : Icons.menu_book_rounded,
                          color:
                              isRead ? Colors.green : const Color(0xFF8B5CF6),
                        ),
                        title: Text(
                          'Page ${page.pageNum}',
                          style: TextStyle(
                            color: isRead
                                ? cs.onSurface.withValues(alpha: 0.65)
                                : cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${page.subject} - ${page.title}',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedPageNumbers.isEmpty
                          ? null
                          : () {
                              final selectedPages = selectedPageNumbers.toList()
                                ..sort();
                              setState(() {
                                _queue.add(StudyTask(
                                  id: _buildTaskId(
                                    type: 'FA',
                                    pageNumbers: selectedPages,
                                  ),
                                  type: 'FA',
                                  label: 'FA Pages',
                                  detail: _faTaskDetail(selectedPages),
                                  pageNumbers: selectedPages,
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        selectedPageNumbers.isEmpty
                            ? 'Select pages to add'
                            : 'Add ${selectedPageNumbers.length} pages to queue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showUWorldPicker(BuildContext context, AppProvider app) {
    final cs = Theme.of(context).colorScheme;
    final systems = <String, List<UWorldTopic>>{};
    for (final topic in app.uworldTopics) {
      systems.putIfAbsent(topic.system, () => []).add(topic);
    }

    String? selectedSystem;
    final selectedTopicIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final topics = List<UWorldTopic>.from(
            selectedSystem == null
                ? app.uworldTopics
                : (systems[selectedSystem] ?? const <UWorldTopic>[]),
          )..sort((a, b) => a.subtopic.compareTo(b.subtopic));
          final selectedTopics = app.uworldTopics
              .where((topic) =>
                  topic.id != null && selectedTopicIds.contains(topic.id))
              .toList()
            ..sort((a, b) => a.subtopic.compareTo(b.subtopic));
          final selectedQuestionTotal = selectedTopics.fold<int>(
            0,
            (sum, topic) => sum + (topic.totalQuestions - topic.doneQuestions),
          );

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'UWorld Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedSystem == null,
                          selectedColor: const Color(0xFFF59E0B),
                          labelStyle: TextStyle(
                            color: selectedSystem == null
                                ? Colors.white
                                : cs.onSurface,
                          ),
                          onSelected: (_) => setSheetState(() {
                            selectedSystem = null;
                          }),
                        ),
                      ),
                      ...systems.keys.map((system) {
                        final isSelected = selectedSystem == system;
                        final remaining = systems[system]!.fold<int>(
                          0,
                          (sum, topic) =>
                              sum + topic.totalQuestions - topic.doneQuestions,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$system ($remaining)'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF59E0B),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : cs.onSurface,
                            ),
                            onSelected: (_) => setSheetState(() {
                              selectedSystem = system;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selected: ${selectedTopics.length} topics - $selectedQuestionTotal questions',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topics.length,
                    itemBuilder: (ctx, i) {
                      final topic = topics[i];
                      final remaining =
                          topic.totalQuestions - topic.doneQuestions;
                      final isSelectable = topic.id != null && remaining > 0;
                      final isSelected = topic.id != null &&
                          selectedTopicIds.contains(topic.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: !isSelectable
                            ? null
                            : (value) {
                                setSheetState(() {
                                  if (value == true) {
                                    selectedTopicIds.add(topic.id!);
                                  } else {
                                    selectedTopicIds.remove(topic.id);
                                  }
                                });
                              },
                        title: Text(
                          topic.subtopic,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${topic.system} - ${topic.doneQuestions} / ${topic.totalQuestions} done',
                          style: TextStyle(
                            fontSize: 12,
                            color: remaining == 0
                                ? Colors.green
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedQuestionTotal <= 0
                          ? null
                          : () {
                              setState(() {
                                _queue.add(StudyTask(
                                  id: _buildTaskId(
                                    type: 'UWORLD',
                                    topicIds: selectedTopics
                                        .map((topic) => topic.id!)
                                        .toList(),
                                  ),
                                  type: 'UWORLD',
                                  label: selectedSystem == null
                                      ? 'UWorld Questions'
                                      : 'UWorld - $selectedSystem',
                                  detail: _uWorldTaskDetail(
                                    selectedTopics,
                                    selectedQuestionTotal,
                                  ),
                                  topicIds: selectedTopics
                                      .map((topic) => topic.id!)
                                      .toList(),
                                  questionCount: selectedQuestionTotal,
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        selectedQuestionTotal <= 0
                            ? 'Select questions to add'
                            : 'Add $selectedQuestionTotal UWorld questions to queue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSketchyPicker(BuildContext context, AppProvider app, String type) {
    final cs = Theme.of(context).colorScheme;
    final videos =
        type == 'micro' ? app.sketchyMicroVideos : app.sketchyPharmVideos;
    final label = type == 'micro' ? 'Sketchy Micro' : 'Sketchy Pharm';
    final color =
        type == 'micro' ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);

    final categories = <String, List<SketchyVideo>>{};
    for (final video in videos) {
      categories.putIfAbsent(video.category, () => []).add(video);
    }

    String? selectedCategory;
    final selectedVideos = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final categoryVideos = selectedCategory != null
              ? (categories[selectedCategory] ?? const <SketchyVideo>[])
              : const <SketchyVideo>[];

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: categories.keys.map((category) {
                      final isSelected = category == selectedCategory;
                      final unwatchedCount = categories[category]!
                          .where((video) => !video.watched)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$category ($unwatchedCount)'),
                          selected: isSelected,
                          selectedColor: color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : cs.onSurface,
                          ),
                          onSelected: (_) => setSheetState(() {
                            selectedCategory = category;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedCategory != null)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryVideos.length,
                      itemBuilder: (ctx, i) {
                        final video = categoryVideos[i];
                        final isSelected = selectedVideos.contains(video.id);
                        return CheckboxListTile(
                          value: video.watched ? true : isSelected,
                          onChanged: video.watched
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      selectedVideos.add(video.id!);
                                    } else {
                                      selectedVideos.remove(video.id);
                                    }
                                  });
                                },
                          title: Text(
                            video.title,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: video.watched
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: video.watched
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            video.subcategory,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Select a category above',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedVideos.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _queue.add(StudyTask(
                                  id: _buildTaskId(
                                    type: type == 'micro'
                                        ? 'SKETCHY_MICRO'
                                        : 'SKETCHY_PHARM',
                                    topicIds: selectedVideos.toList(),
                                  ),
                                  type: type == 'micro'
                                      ? 'SKETCHY_MICRO'
                                      : 'SKETCHY_PHARM',
                                  label: '$label - $selectedCategory',
                                  detail: '${selectedVideos.length} videos',
                                  topicIds: selectedVideos.toList(),
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        selectedVideos.isEmpty
                            ? 'Select videos'
                            : 'Add ${selectedVideos.length} videos to queue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showPathomaPicker(BuildContext context, AppProvider app) {
    final cs = Theme.of(context).colorScheme;
    final chapters = List<PathomaChapter>.from(app.pathomaChapters)
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    final selectedChapterIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final selectedChapters = chapters
                .where(
                  (chapter) =>
                      chapter.id != null &&
                      selectedChapterIds.contains(chapter.id),
                )
                .toList()
              ..sort((a, b) => a.chapter.compareTo(b.chapter));

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Pathoma',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Selected: ${selectedChapters.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chapters.length,
                      itemBuilder: (ctx, i) {
                        final chapter = chapters[i];
                        final isSelected = chapter.id != null &&
                            selectedChapterIds.contains(chapter.id);
                        return CheckboxListTile(
                          value: chapter.watched ? true : isSelected,
                          onChanged: chapter.watched || chapter.id == null
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      selectedChapterIds.add(chapter.id!);
                                    } else {
                                      selectedChapterIds.remove(chapter.id);
                                    }
                                  });
                                },
                          title: Text(
                            'Chapter ${chapter.chapter}',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: chapter.watched
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: chapter.watched
                                  ? cs.onSurface.withValues(alpha: 0.45)
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selectedChapters.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _queue.add(
                                    StudyTask(
                                      id: _buildTaskId(
                                        type: 'PATHOMA',
                                        topicIds: selectedChapters
                                            .map((chapter) => chapter.id!)
                                            .toList(),
                                      ),
                                      type: 'PATHOMA',
                                      label: 'Pathoma',
                                      detail:
                                          _pathomaTaskDetail(selectedChapters),
                                      topicIds: selectedChapters
                                          .map((chapter) => chapter.id!)
                                          .toList(),
                                    ),
                                  );
                                });
                                Navigator.pop(ctx);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedChapters.isEmpty
                              ? 'Select chapters'
                              : 'Add ${selectedChapters.length} chapters to queue',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ignore: unused_element
class _PlannedSessionCard extends StatelessWidget {
  final String title;
  final String scheduledTime;
  final int itemCount;
  final String durationLabel;
  final VoidCallback onStartNow;

  const _PlannedSessionCard({
    required this.title,
    required this.scheduledTime,
    required this.itemCount,
    required this.durationLabel,
    required this.onStartNow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$scheduledTime • $itemCount item${itemCount == 1 ? '' : 's'} • $durationLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onStartNow,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Start Now',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDurationDialog extends StatefulWidget {
  final int initialMinutes;

  const _TaskDurationDialog({
    required this.initialMinutes,
  });

  @override
  State<_TaskDurationDialog> createState() => _TaskDurationDialogState();
}

class _TaskDurationDialogState extends State<_TaskDurationDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialMinutes.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final minutes = int.tryParse(_controller.text.trim());
    if (minutes == null || minutes < 5 || minutes > 120) {
      setState(() {
        _errorText = 'Enter a value from 5 to 120.';
      });
      return;
    }

    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Task duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5 - 120 min'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Minutes',
              suffixText: 'min',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText == null) {
                return;
              }
              setState(() {
                _errorText = null;
              });
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RevisionStatusSummary {
  final String text;
  final bool overdue;

  const _RevisionStatusSummary({
    required this.text,
    required this.overdue,
  });
}

class _PlannedSessionQueueRowData {
  final Widget icon;
  final String title;
  final String detail;
  final String timeLabel;
  final List<_RevisionStatusSummary> revisionStatuses;

  const _PlannedSessionQueueRowData({
    required this.icon,
    required this.title,
    required this.detail,
    required this.timeLabel,
    required this.revisionStatuses,
  });
}

class _PlannedSessionDetailsCard extends StatelessWidget {
  final String title;
  final String scheduledTime;
  final int itemCount;
  final String durationLabel;
  final List<_PlannedSessionQueueRowData> queueRows;
  final VoidCallback onStartNow;

  const _PlannedSessionDetailsCard({
    required this.title,
    required this.scheduledTime,
    required this.itemCount,
    required this.durationLabel,
    required this.queueRows,
    required this.onStartNow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$scheduledTime • $itemCount item${itemCount == 1 ? '' : 's'} • $durationLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onStartNow,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Start Now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (queueRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...queueRows.map(
              (row) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        row.icon,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.detail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                row.timeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (row.revisionStatuses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...row.revisionStatuses.map(
                        (revision) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            revision.text,
                            style: TextStyle(
                              fontSize: 11,
                              color: revision.overdue
                                  ? cs.error
                                  : cs.onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
