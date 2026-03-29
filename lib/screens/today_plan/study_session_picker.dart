import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:intl/intl.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import 'study_flow_screen.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';

class PlannedStudySessionData {
  final List<StudyTask> tasks;
  final int estimatedDurationMinutes;

  const PlannedStudySessionData({
    required this.tasks,
    required this.estimatedDurationMinutes,
  });

  int get itemCount => StudyTask.totalItemCount(tasks);
}

class PlannedStudySessionPayload {
  static const kind = 'planned_study_session';

  static PlannedStudySessionData? fromBlock(Block block) {
    final notes = block.reflectionNotes;
    if (notes == null || notes.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(notes);
      if (decoded is! Map<String, dynamic> || decoded['kind'] != kind) {
        return null;
      }

      final tasks = StudyTask.fromJsonList(decoded['tasks']);
      final estimatedMinutes = decoded['estimatedDurationMinutes'] as int?;
      return PlannedStudySessionData(
        tasks: tasks,
        estimatedDurationMinutes:
            estimatedMinutes != null && estimatedMinutes > 0
                ? estimatedMinutes
                : StudyTask.estimateQueueDurationMinutes(tasks),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> toJson(
    List<StudyTask> tasks,
    int estimatedMinutes,
  ) {
    return {
      'kind': kind,
      'estimatedDurationMinutes': estimatedMinutes,
      'tasks': StudyTask.toJsonList(tasks),
    };
  }

  static String encode(List<StudyTask> tasks, int estimatedMinutes) {
    return jsonEncode(toJson(tasks, estimatedMinutes));
  }

  static String buildTitle(List<StudyTask> tasks) {
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
    if (tasks.any((task) => task.type == 'VIDEO_LECTURE')) {
      parts.add('Library Videos');
    }
    if (parts.isEmpty && tasks.isNotEmpty) {
      parts.add(tasks.first.label);
    }

    if (parts.isEmpty) {
      return 'Study Session';
    }
    return 'Study Session • ${parts.join(' + ')}';
  }
}

class StudySessionPicker extends StatefulWidget {
  final String dateKey;
  final String? targetBlockId;
  final String? boundPlannedStartTime;
  final String? boundPlannedEndTime;

  const StudySessionPicker({
    super.key,
    required this.dateKey,
    this.targetBlockId,
    this.boundPlannedStartTime,
    this.boundPlannedEndTime,
  });

  @override
  State<StudySessionPicker> createState() => _StudySessionPickerState();
}

class _StudySessionPickerState extends State<StudySessionPicker> {
  final List<StudyTask> _queue = [];
  static const _plannedStudySessionKind = PlannedStudySessionPayload.kind;
  static const double _kQueuePickerBottomActionClearance = 104;
  static const double _kQueuePickerActionScrollPadding = 192;

  bool get _isBlockBound => widget.targetBlockId != null;

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
    return PlannedStudySessionPayload.fromBlock(block)?.tasks ??
        const <StudyTask>[];
  }

  int _plannedQueueMinutesFromBlock(Block block) {
    final plannedData = PlannedStudySessionPayload.fromBlock(block);
    if (plannedData != null && plannedData.estimatedDurationMinutes > 0) {
      return plannedData.estimatedDurationMinutes;
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

  String _videoLibrarySubtitle({
    required AppProvider app,
    required String subject,
    required String prefix,
  }) {
    final subjectVideos = app.videoLectures
        .where((video) => video.subject.toLowerCase() == subject.toLowerCase())
        .toList();
    if (subjectVideos.isEmpty) {
      return '$prefix — Videos available';
    }

    final unwatchedCount =
        subjectVideos.where((video) => !video.isComplete).length;
    return '$prefix — $unwatchedCount unwatched videos';
  }

  Future<void> _openLibrarySubject(
    BuildContext context, {
    required _LibrarySubjectOption option,
  }) async {
    final tasks = await Navigator.of(context).push<List<StudyTask>>(
      MaterialPageRoute(
        builder: (_) => _LibrarySubjectVideoScreen(
          title: option.title,
          subject: option.subject,
          color: option.color,
          icon: option.icon,
        ),
      ),
    );
    if (!mounted || tasks == null || tasks.isEmpty) {
      return;
    }
    setState(() {
      _queue.addAll(tasks);
    });
  }

  List<_LibrarySubjectOption> _librarySubjectOptions(AppProvider app) {
    final grouped = <String, List<VideoLecture>>{};
    for (final lecture in app.videoLectures) {
      grouped.putIfAbsent(lecture.subject, () => <VideoLecture>[]).add(lecture);
    }

    final options = grouped.entries.map((entry) {
      final preset = _librarySubjectPresets[entry.key];
      return _LibrarySubjectOption(
        subject: entry.key,
        title: preset?.title ?? entry.key,
        prefix: preset?.prefix ?? entry.key,
        icon: preset?.icon ?? Icons.ondemand_video_rounded,
        color: preset?.color ?? const Color(0xFF6366F1),
        orderIndex: entry.value.map((lecture) => lecture.orderIndex).fold<int>(
            1 << 20, (minOrder, order) => order < minOrder ? order : minOrder),
      );
    }).toList()
      ..sort((a, b) {
        final orderCompare = a.orderIndex.compareTo(b.orderIndex);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.subject.compareTo(b.subject);
      });

    return options;
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
    if (tasks.any((task) => task.type == 'VIDEO_LECTURE')) {
      parts.add('Library Videos');
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
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TaskDurationPickerSheet(initialMinutes: initialMinutes);
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
      case 'VIDEO_LECTURE':
        for (final id in task.topicIds) {
          final item = _findRevisionItem(app, 'video-lecture-$id');
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
    TimeOfDay selectedTime =
        _isBlockBound ? _boundStartTime() : TimeOfDay.now();

    await showAppBottomSheet(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final cs = Theme.of(sheetContext).colorScheme;
            final estimatedMinutes =
                StudyTask.estimateQueueDurationMinutes(plannedQueue);
            final sessionStart = _sessionStartDateTime(selectedTime);
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetContext).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
                      ),
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
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                        color:
                                            cs.onSurface.withValues(alpha: 0.6),
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
                    _isBlockBound ? 'Selected Task Time' : 'Scheduled Start',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isBlockBound)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_formatPlannedTime(widget.boundPlannedStartTime ?? '')} - ${_formatPlannedTime(widget.boundPlannedEndTime ?? '')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    )
                  else
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
                      onPressed: () => _isBlockBound
                          ? _persistBoundSession(
                              plannedQueue: plannedQueue,
                              scheduledTime: selectedTime,
                              startNow: false,
                              sheetContext: sheetContext,
                            )
                          : _savePlannedSession(
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
        dateKey: block.date,
        blockId: block.id,
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
    final librarySubjects = _librarySubjectOptions(app);
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🎥 Videos from Library',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    ...librarySubjects.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == librarySubjects.length - 1 ? 0 : 10,
                        ),
                        child: _OptionCard(
                          icon: option.icon,
                          color: option.color,
                          title: option.title,
                          subtitle: _videoLibrarySubtitle(
                            app: app,
                            subject: option.subject,
                            prefix: option.prefix,
                          ),
                          onTap: () => _openLibrarySubject(
                            context,
                            option: option,
                          ),
                        ),
                      );
                    }),
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
      case 'VIDEO_LECTURE':
        return const Icon(
          Icons.ondemand_video_rounded,
          color: Color(0xFFF59E0B),
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
    if (_isBlockBound) {
      unawaited(_bindQueuedTasksToBoundBlock(startNow: true));
      return;
    }

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

  TimeOfDay _boundStartTime() {
    final plannedStartTime = widget.boundPlannedStartTime;
    if (plannedStartTime == null || plannedStartTime.isEmpty) {
      return TimeOfDay.now();
    }
    return _timeOfDayFromString(plannedStartTime) ?? TimeOfDay.now();
  }

  int _boundSlotDurationMinutes() {
    final start = _timeOfDayFromString(widget.boundPlannedStartTime ?? '');
    final end = _timeOfDayFromString(widget.boundPlannedEndTime ?? '');
    if (start == null || end == null) {
      return 0;
    }

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final duration = endMinutes - startMinutes;
    return duration > 0 ? duration : 0;
  }

  Future<void> _bindQueuedTasksToBoundBlock({required bool startNow}) async {
    if (_queue.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one task to start this study session.'),
        ),
      );
      return;
    }

    await _persistBoundSession(
      plannedQueue: _queueWithPlanningDefaults(_queue),
      scheduledTime: _boundStartTime(),
      startNow: startNow,
    );
  }

  Future<void> _persistBoundSession({
    required List<StudyTask> plannedQueue,
    required TimeOfDay scheduledTime,
    required bool startNow,
    BuildContext? sheetContext,
  }) async {
    final targetBlockId = widget.targetBlockId;
    if (targetBlockId == null || targetBlockId.isEmpty) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppProvider>();
    final existingPlan = app.getDayPlan(widget.dateKey);
    final existingBlocks = existingPlan?.blocks ?? const <Block>[];
    final targetIndex =
        existingBlocks.indexWhere((block) => block.id == targetBlockId);
    if (targetIndex < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to update the selected study task')),
      );
      return;
    }

    final estimatedMinutes =
        StudyTask.estimateQueueDurationMinutes(plannedQueue);
    final scheduledAt = _sessionStartDateTime(scheduledTime);
    final targetBlock = existingBlocks[targetIndex];
    final slotDuration = _boundSlotDurationMinutes();
    final updatedBlock = targetBlock.copyWith(
      type: BlockType.studySession,
      title: _buildStudySessionTitle(plannedQueue),
      plannedDurationMinutes:
          slotDuration > 0 ? slotDuration : targetBlock.plannedDurationMinutes,
      status: BlockStatus.notStarted,
      reflectionNotes: jsonEncode(
        _plannedStudySessionPayload(plannedQueue, estimatedMinutes),
      ),
    );

    final updatedBlocks = List<Block>.from(existingBlocks);
    updatedBlocks[targetIndex] = updatedBlock;
    final totalStudyMinutes = updatedBlocks
        .where((entry) => entry.type != BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);
    final totalBreakMinutes = updatedBlocks
        .where((entry) => entry.type == BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);
    final updatedPlan = existingPlan?.copyWith(
          blocks: updatedBlocks,
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
          blocks: updatedBlocks,
          totalStudyMinutesPlanned: totalStudyMinutes,
          totalBreakMinutes: totalBreakMinutes,
        );

    await app.upsertDayPlan(updatedPlan);
    await app.syncFlowActivitiesFromDayPlan(widget.dateKey);

    if (scheduledAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleStudySessionReminder(
        id: _notificationIdForBlock(updatedBlock.id),
        blockTitle: updatedBlock.title,
        when: scheduledAt,
        dateKey: updatedBlock.date,
        blockId: updatedBlock.id,
      );
    }

    if (!mounted) return;
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    } else {
      navigator.pop();
    }

    if (!startNow) {
      Future.microtask(() {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Study session saved to ${DateFormat('h:mm a').format(scheduledAt)}',
            ),
          ),
        );
      });
      return;
    }

    final startedAt = DateTime.now();
    await Future<void>.microtask(() async {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => StudyFlowScreen(
            dateKey: widget.dateKey,
            queuedTasks: plannedQueue,
            onComplete: () {
              final completedAt = DateTime.now();
              unawaited(
                app.completeDayPlanBlock(
                  widget.dateKey,
                  updatedBlock.id,
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

  void _showFAPagePicker(BuildContext context, AppProvider app) {
    final pages = List<FAPage>.from(app.faPages)
      ..sort((a, b) {
        final orderCompare = a.orderIndex.compareTo(b.orderIndex);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.pageNum.compareTo(b.pageNum);
      });
    final selectedPageNumbers = <int>{};

    showAppBottomSheet(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final cs = Theme.of(ctx).colorScheme;
          return Column(
            children: [
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
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(ctx).padding.bottom +
                        _kQueuePickerActionScrollPadding,
                  ),
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
                        color: isRead ? Colors.green : const Color(0xFF8B5CF6),
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
                padding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: MediaQuery.of(ctx).padding.bottom +
                      _kQueuePickerBottomActionClearance,
                ),
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
          );
        });
      },
    );
  }

  void _showUWorldPicker(BuildContext context, AppProvider app) {
    final systems = <String, List<UWorldTopic>>{};
    for (final topic in app.uworldTopics) {
      systems.putIfAbsent(topic.system, () => []).add(topic);
    }

    String? selectedSystem;
    final selectedTopicIds = <int>{};

    showAppBottomSheet(
      context: context,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final cs = Theme.of(ctx).colorScheme;
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

          return Column(
            children: [
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
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(ctx).padding.bottom +
                        _kQueuePickerActionScrollPadding,
                  ),
                  itemCount: topics.length,
                  itemBuilder: (ctx, i) {
                    final topic = topics[i];
                    final remaining =
                        topic.totalQuestions - topic.doneQuestions;
                    final isSelectable = topic.id != null && remaining > 0;
                    final isSelected =
                        topic.id != null && selectedTopicIds.contains(topic.id);
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(ctx).padding.bottom +
                      _kQueuePickerBottomActionClearance,
                ),
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
          );
        });
      },
    );
  }

  void _showSketchyPicker(BuildContext context, AppProvider app, String type) {
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

    showAppBottomSheet(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final cs = Theme.of(ctx).colorScheme;
          final categoryVideos = selectedCategory != null
              ? (categories[selectedCategory] ?? const <SketchyVideo>[])
              : const <SketchyVideo>[];

          return Column(
            children: [
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
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(ctx).padding.bottom +
                          _kQueuePickerActionScrollPadding,
                    ),
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(ctx).padding.bottom +
                      _kQueuePickerBottomActionClearance,
                ),
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
          );
        });
      },
    );
  }

  void _showPathomaPicker(BuildContext context, AppProvider app) {
    final chapters = List<PathomaChapter>.from(app.pathomaChapters)
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    final selectedChapterIds = <int>{};

    showAppBottomSheet(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cs = Theme.of(ctx).colorScheme;
            final selectedChapters = chapters
                .where(
                  (chapter) =>
                      chapter.id != null &&
                      selectedChapterIds.contains(chapter.id),
                )
                .toList()
              ..sort((a, b) => a.chapter.compareTo(b.chapter));

            return Column(
              children: [
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
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(ctx).padding.bottom +
                          _kQueuePickerActionScrollPadding,
                    ),
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(ctx).padding.bottom +
                        _kQueuePickerBottomActionClearance,
                  ),
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

class _TaskDurationPickerSheet extends StatefulWidget {
  final int initialMinutes;

  const _TaskDurationPickerSheet({
    required this.initialMinutes,
  });

  @override
  State<_TaskDurationPickerSheet> createState() =>
      _TaskDurationPickerSheetState();
}

class _TaskDurationPickerSheetState extends State<_TaskDurationPickerSheet> {
  static const _bodyColor = Color(0xFF1C1C1E);
  static const _cardColor = Color(0xFF252528);
  static const _accentColor = Color(0xFF8B5CF6);
  static const _wheelItemExtent = 40.0;
  static const _wheelHeight = _wheelItemExtent * 5;
  static const _maxHours = 99;

  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final safeMinutes = widget.initialMinutes < 1 ? 1 : widget.initialMinutes;
    _hours = safeMinutes ~/ 60;
    _minutes = safeMinutes % 60;
    _hoursController = FixedExtentScrollController(
      initialItem: _hours.clamp(0, _maxHours),
    );
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int get _totalMinutes {
    final total = (_hours * 60) + _minutes;
    return total < 1 ? 1 : total;
  }

  String _durationLabel(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Material(
      color: Colors.transparent,
      child: FractionallySizedBox(
        heightFactor: 0.6,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: _bodyColor,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Task duration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _durationLabel(_totalMinutes),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: _wheelItemExtent + 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _DurationWheelColumn(
                                    controller: _hoursController,
                                    itemCount: _maxHours + 1,
                                    selectedItem: _hours.clamp(0, _maxHours),
                                    onSelectedItemChanged: (value) {
                                      setState(() {
                                        _hours = value;
                                      });
                                    },
                                    labelBuilder: (value, isSelected) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          value.toString().padLeft(2, '0'),
                                          style: _wheelTextStyle(isSelected),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'hr',
                                          style: _wheelUnitStyle(isSelected),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _DurationWheelColumn(
                                    controller: _minutesController,
                                    itemCount: 60,
                                    selectedItem: _minutes,
                                    onSelectedItemChanged: (value) {
                                      setState(() {
                                        _minutes = value;
                                      });
                                    },
                                    labelBuilder: (value, isSelected) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          value.toString().padLeft(2, '0'),
                                          style: _wheelTextStyle(isSelected),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'min',
                                          style: _wheelUnitStyle(isSelected),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(_totalMinutes),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _wheelTextStyle(bool isSelected) {
    return TextStyle(
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.34),
      fontSize: isSelected ? 24 : 19,
      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
    );
  }

  TextStyle _wheelUnitStyle(bool isSelected) {
    return TextStyle(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.26),
      fontSize: isSelected ? 14 : 12,
      fontWeight: FontWeight.w700,
    );
  }
}

class _DurationWheelColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedItem;
  final ValueChanged<int> onSelectedItemChanged;
  final Widget Function(int value, bool isSelected) labelBuilder;

  const _DurationWheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedItem,
    required this.onSelectedItemChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TaskDurationPickerSheetState._wheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _TaskDurationPickerSheetState._wheelItemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.45,
        perspective: 0.004,
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            return Center(
              child: labelBuilder(index, index == selectedItem),
            );
          },
        ),
      ),
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

class _LibrarySubjectVideoScreen extends StatefulWidget {
  final String title;
  final String subject;
  final Color color;
  final IconData icon;

  const _LibrarySubjectVideoScreen({
    required this.title,
    required this.subject,
    required this.color,
    required this.icon,
  });

  @override
  State<_LibrarySubjectVideoScreen> createState() =>
      _LibrarySubjectVideoScreenState();
}

class _LibrarySubjectVideoScreenState
    extends State<_LibrarySubjectVideoScreen> {
  static const double _kBottomActionClearance = 104;
  final Set<int> _selectedLectureIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final lectures = app.videoLectures
        .where(
          (lecture) =>
              lecture.subject.toLowerCase() == widget.subject.toLowerCase(),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final selectedLectures = lectures
        .where(
          (lecture) =>
              lecture.id != null && _selectedLectureIds.contains(lecture.id),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: lectures.isEmpty
          ? Center(
              child: Text(
                'No videos available for ${widget.title}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                _kBottomActionClearance + 120,
              ),
              itemCount: lectures.length,
              itemBuilder: (context, index) {
                final lecture = lectures[index];
                final lectureId = lecture.id;
                final isDisabled = lecture.isComplete || lectureId == null;
                final isSelected = lectureId != null &&
                    _selectedLectureIds.contains(lectureId);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? widget.color.withValues(alpha: 0.4)
                          : cs.outline.withValues(alpha: 0.08),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: lecture.isComplete ? true : isSelected,
                    onChanged: isDisabled
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedLectureIds.add(lectureId);
                              } else {
                                _selectedLectureIds.remove(lectureId);
                              }
                            });
                          },
                    activeColor: widget.color,
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: Icon(widget.icon, color: widget.color),
                    title: Text(
                      lecture.customTitle ?? lecture.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: lecture.isComplete
                            ? TextDecoration.lineThrough
                            : null,
                        color: lecture.isComplete
                            ? cs.onSurface.withValues(alpha: 0.45)
                            : cs.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: lecture.progressPercent,
                              minHeight: 4,
                              backgroundColor:
                                  cs.onSurface.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                lecture.isComplete
                                    ? Colors.green
                                    : widget.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lecture.isComplete
                                ? 'Watched • ${lecture.durationLabel}'
                                : '${lecture.remainingLabel} • ${lecture.subject}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, _kBottomActionClearance),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: selectedLectures.isEmpty
                ? null
                : () {
                    final tasks = selectedLectures
                        .where((lecture) => lecture.id != null)
                        .map(
                          (lecture) => StudyTask(
                            id: [
                              'VIDEO_LECTURE',
                              lecture.id.toString(),
                              DateTime.now().microsecondsSinceEpoch.toString(),
                            ].join('|'),
                            type: 'VIDEO_LECTURE',
                            label: lecture.customTitle ?? lecture.title,
                            detail:
                                '${lecture.subject} • ${lecture.remainingLabel}',
                            topicIds: <int>[lecture.id!],
                            plannedDurationMinutes: lecture.remainingMinutes > 0
                                ? lecture.remainingMinutes
                                : lecture.durationMinutes,
                          ),
                        )
                        .toList();
                    Navigator.of(context).pop(tasks);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              selectedLectures.isEmpty
                  ? 'Select videos'
                  : 'Add ${selectedLectures.length} videos to queue',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibrarySubjectOption {
  final String subject;
  final String title;
  final String prefix;
  final IconData icon;
  final Color color;
  final int orderIndex;

  const _LibrarySubjectOption({
    required this.subject,
    required this.title,
    required this.prefix,
    required this.icon,
    required this.color,
    required this.orderIndex,
  });
}

class _LibrarySubjectPreset {
  final String title;
  final String prefix;
  final IconData icon;
  final Color color;

  const _LibrarySubjectPreset({
    required this.title,
    required this.prefix,
    required this.icon,
    required this.color,
  });
}

const Map<String, _LibrarySubjectPreset> _librarySubjectPresets =
    <String, _LibrarySubjectPreset>{
  'ENT': _LibrarySubjectPreset(
    title: 'ENT',
    prefix: 'Ear, Nose & Throat',
    icon: Icons.headphones_rounded,
    color: Color(0xFFF59E0B),
  ),
  'Preventive & Social Medicine': _LibrarySubjectPreset(
    title: 'PSM',
    prefix: 'Preventive & Social Medicine',
    icon: Icons.public_rounded,
    color: Color(0xFF10B981),
  ),
  'Ophthalmology': _LibrarySubjectPreset(
    title: 'Ophthalmology',
    prefix: 'Ophtha',
    icon: Icons.visibility_rounded,
    color: Color(0xFF3B82F6),
  ),
};
