import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class StudyTask {
  final String id;
  final String type;
  final String label;
  final String detail;
  final List<int> pageNumbers;
  final List<int> topicIds;
  final int questionCount;
  final int? plannedDurationMinutes;

  const StudyTask({
    required this.id,
    required this.type,
    required this.label,
    required this.detail,
    this.pageNumbers = const [],
    this.topicIds = const [],
    this.questionCount = 0,
    this.plannedDurationMinutes,
  });

  bool get isPlannable => true;

  int get itemCount {
    switch (type) {
      case 'FA':
        return pageNumbers.length;
      case 'UWORLD':
        return topicIds.length;
      default:
        if (pageNumbers.isNotEmpty) {
          return pageNumbers.length;
        }
        if (topicIds.isNotEmpty) {
          return topicIds.length;
        }
        return questionCount > 0 ? questionCount : 1;
    }
  }

  int get estimatedDurationMinutes {
    if (plannedDurationMinutes != null && plannedDurationMinutes! > 0) {
      return plannedDurationMinutes!;
    }

    final count = itemCount > 0 ? itemCount : 1;
    switch (type) {
      case 'FA':
        return count * 15;
      case 'UWORLD':
        return count * 20;
      case 'SKETCHY_MICRO':
      case 'SKETCHY_PHARM':
        return count * 25;
      case 'PATHOMA':
        return count * 30;
      case 'VIDEO_LECTURE':
        return count * 20;
      default:
        return count * 20;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'detail': detail,
        'pageNumbers': pageNumbers,
        'topicIds': topicIds,
        'questionCount': questionCount,
        if (plannedDurationMinutes != null)
          'plannedDurationMinutes': plannedDurationMinutes,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final label = json['label']?.toString() ?? '';
    final detail = json['detail']?.toString() ?? '';
    final pageNumbers = _parseIntList(json['pageNumbers']);
    final topicIds = _parseIntList(json['topicIds']);
    final questionCount = json['questionCount'] as int? ?? 0;

    return StudyTask(
      id: json['id']?.toString() ??
          _legacyId(
            type: type,
            label: label,
            detail: detail,
            pageNumbers: pageNumbers,
            topicIds: topicIds,
          ),
      type: type,
      label: label,
      detail: detail,
      pageNumbers: pageNumbers,
      topicIds: topicIds,
      questionCount: questionCount,
      plannedDurationMinutes: json['plannedDurationMinutes'] as int?,
    );
  }

  StudyTask copyWith({
    String? id,
    String? type,
    String? label,
    String? detail,
    List<int>? pageNumbers,
    List<int>? topicIds,
    int? questionCount,
    int? plannedDurationMinutes,
  }) =>
      StudyTask(
        id: id ?? this.id,
        type: type ?? this.type,
        label: label ?? this.label,
        detail: detail ?? this.detail,
        pageNumbers: pageNumbers ?? this.pageNumbers,
        topicIds: topicIds ?? this.topicIds,
        questionCount: questionCount ?? this.questionCount,
        plannedDurationMinutes:
            plannedDurationMinutes ?? this.plannedDurationMinutes,
      );

  static List<StudyTask> explodeForExecution({
    required Iterable<StudyTask> tasks,
    required List<UWorldTopic> uworldTopics,
    required List<SketchyVideo> sketchyMicroVideos,
    required List<SketchyVideo> sketchyPharmVideos,
    required List<PathomaChapter> pathomaChapters,
    required List<VideoLecture> videoLectures,
  }) {
    final uworldById = <int, UWorldTopic>{
      for (final topic in uworldTopics)
        if (topic.id != null) topic.id!: topic,
    };
    final sketchyMicroById = <int, SketchyVideo>{
      for (final video in sketchyMicroVideos)
        if (video.id != null) video.id!: video,
    };
    final sketchyPharmById = <int, SketchyVideo>{
      for (final video in sketchyPharmVideos)
        if (video.id != null) video.id!: video,
    };
    final pathomaById = <int, PathomaChapter>{
      for (final chapter in pathomaChapters)
        if (chapter.id != null) chapter.id!: chapter,
    };
    final videoLectureById = <int, VideoLecture>{
      for (final lecture in videoLectures)
        if (lecture.id != null) lecture.id!: lecture,
    };

    return tasks.expand((task) {
      switch (task.type) {
        case 'FA':
          if (task.pageNumbers.isEmpty) {
            return <StudyTask>[task];
          }
          return task.pageNumbers.map(
            (page) => task.copyWith(
              id: '${task.id}#fa:$page',
              detail: 'Page $page',
              pageNumbers: <int>[page],
              topicIds: const <int>[],
              questionCount: 0,
              plannedDurationMinutes: _atomicPlannedDurationMinutes(task),
            ),
          );
        case 'UWORLD':
          if (task.topicIds.isEmpty) {
            return <StudyTask>[task];
          }
          return task.topicIds.map((topicId) {
            final topic = uworldById[topicId];
            final remainingQuestions = topic == null
                ? 0
                : (topic.totalQuestions - topic.doneQuestions)
                    .clamp(0, topic.totalQuestions);
            return task.copyWith(
              id: '${task.id}#uw:$topicId',
              detail: topic == null
                  ? task.detail
                  : '${topic.subtopic} - ${topic.system}',
              pageNumbers: const <int>[],
              topicIds: <int>[topicId],
              questionCount: remainingQuestions > 0
                  ? remainingQuestions
                  : (task.questionCount > 0 ? task.questionCount : 1),
              plannedDurationMinutes: _atomicPlannedDurationMinutes(task),
            );
          });
        case 'SKETCHY_MICRO':
          return _explodeSketchyTask(
            task,
            sketchyMicroById,
            runtimeTypeKey: 'sketchy-micro',
          );
        case 'SKETCHY_PHARM':
          return _explodeSketchyTask(
            task,
            sketchyPharmById,
            runtimeTypeKey: 'sketchy-pharm',
          );
        case 'PATHOMA':
          if (task.topicIds.isEmpty) {
            return <StudyTask>[task];
          }
          return task.topicIds.map((chapterId) {
            final chapter = pathomaById[chapterId];
            return task.copyWith(
              id: '${task.id}#pathoma:$chapterId',
              detail: chapter == null
                  ? task.detail
                  : 'Chapter ${chapter.chapter} - ${chapter.title}',
              pageNumbers: const <int>[],
              topicIds: <int>[chapterId],
              questionCount: 0,
              plannedDurationMinutes: _atomicPlannedDurationMinutes(task),
            );
          });
        case 'VIDEO_LECTURE':
          if (task.topicIds.isEmpty) {
            return <StudyTask>[task];
          }
          return task.topicIds.map((lectureId) {
            final lecture = videoLectureById[lectureId];
            return task.copyWith(
              id: '${task.id}#video-lecture:$lectureId',
              detail: lecture == null
                  ? task.detail
                  : (lecture.customTitle ?? lecture.title),
              pageNumbers: const <int>[],
              topicIds: <int>[lectureId],
              questionCount: 0,
              plannedDurationMinutes:
                  lecture?.remainingMinutes ?? _atomicPlannedDurationMinutes(task),
            );
          });
        default:
          return <StudyTask>[task];
      }
    }).toList();
  }

  static List<StudyTask> plannableOnly(Iterable<StudyTask> tasks) {
    return List<StudyTask>.from(tasks);
  }

  static int totalItemCount(Iterable<StudyTask> tasks) {
    return tasks.fold<int>(0, (sum, task) => sum + task.itemCount);
  }

  static int estimateQueueDurationMinutes(Iterable<StudyTask> tasks) {
    final total = tasks.fold<int>(
      0,
      (sum, task) => sum + task.estimatedDurationMinutes,
    );
    return total > 0 ? total : 15;
  }

  static List<Map<String, dynamic>> toJsonList(Iterable<StudyTask> tasks) {
    return tasks.map((task) => task.toJson()).toList();
  }

  static List<StudyTask> fromJsonList(dynamic json) {
    if (json is! List) {
      return const <StudyTask>[];
    }
    return json
        .whereType<Map>()
        .map((task) => StudyTask.fromJson(Map<String, dynamic>.from(task)))
        .toList();
  }

  static List<int> _parseIntList(dynamic values) {
    if (values is! List) {
      return const <int>[];
    }
    return values
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .toList();
  }

  static String _legacyId({
    required String type,
    required String label,
    required String detail,
    required List<int> pageNumbers,
    required List<int> topicIds,
  }) {
    final parts = <String>[
      type,
      label,
      detail,
      pageNumbers.join('-'),
      topicIds.join('-'),
    ];
    return parts.join('|');
  }

  static Iterable<StudyTask> _explodeSketchyTask(
    StudyTask task,
    Map<int, SketchyVideo> videosById, {
    required String runtimeTypeKey,
  }) {
    if (task.topicIds.isEmpty) {
      return <StudyTask>[task];
    }
    return task.topicIds.map((videoId) {
      final video = videosById[videoId];
      return task.copyWith(
        id: '${task.id}#$runtimeTypeKey:$videoId',
        detail: video == null ? task.detail : video.title,
        pageNumbers: const <int>[],
        topicIds: <int>[videoId],
        questionCount: 0,
        plannedDurationMinutes: _atomicPlannedDurationMinutes(task),
      );
    });
  }

  static int? _atomicPlannedDurationMinutes(StudyTask task) {
    final plannedDurationMinutes = task.plannedDurationMinutes;
    if (plannedDurationMinutes == null) {
      return null;
    }

    final itemCount = task.itemCount > 0 ? task.itemCount : 1;
    return (plannedDurationMinutes / itemCount).ceil().clamp(5, 120);
  }
}

class StudyFlowScreen extends StatefulWidget {
  final String dateKey;
  final VoidCallback? onComplete;
  final List<StudyTask>? queuedTasks;

  const StudyFlowScreen({
    super.key,
    required this.dateKey,
    this.onComplete,
    this.queuedTasks,
  });

  @override
  State<StudyFlowScreen> createState() => _StudyFlowScreenState();
}

class _StudyFlowScreenState extends State<StudyFlowScreen> {
  int _currentPage = 0;
  int _pagesCompletedInSession = 0;
  int _targetPages = 10;
  bool _isStudying = false;
  bool _isRevisionPage = false;
  bool _timersPaused = false;
  bool _isResolvingQueuedRevision = false;
  bool _showAnkiPrompt = false;
  final List<int> _ankiPendingPages = [];
  Timer? _timer;
  int _totalElapsed = 0;
  int _pageElapsed = 0;
  final List<_PageTiming> _pageTimings = [];
  final Map<String, DateTime> _taskStartedAt = {};

  late final List<StudyTask> _queue;
  int _currentTaskIndex = 0;

  static const _motivations = [
    'Come on, you got this!',
    'One page closer to your goal!',
    'Future doctor in the making!',
    'Keep the momentum going!',
    'You are doing amazing!',
    'Every page counts!',
    'Stay focused, stay strong!',
    'Almost there, keep pushing!',
    'Your hard work will pay off!',
    'Page by page, you will conquer this!',
  ];

  bool get _hasQueuedTasks => _queue.isNotEmpty;

  StudyTask? get _currentTask {
    if (_currentTaskIndex < 0 || _currentTaskIndex >= _queue.length) {
      return null;
    }
    return _queue[_currentTaskIndex];
  }

  bool get _isQueueFaTask => _currentTask?.type == 'FA';
  bool get _isQueueUWorldTask => _currentTask?.type == 'UWORLD';
  bool get _isQueueStructuredTask => _isQueueFaTask || _isQueueUWorldTask;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _queue = StudyTask.explodeForExecution(
      tasks: widget.queuedTasks ?? const <StudyTask>[],
      uworldTopics: app.uworldTopics,
      sketchyMicroVideos: app.sketchyMicroVideos,
      sketchyPharmVideos: app.sketchyPharmVideos,
      pathomaChapters: app.pathomaChapters,
      videoLectures: app.videoLectures,
    );
    final settingsProvider = context.read<SettingsProvider>();

    settingsProvider.ensureStudyPlanStartDate();

    if (_hasQueuedTasks) {
      _targetPages = _queue
          .where((task) => task.type == 'FA')
          .fold<int>(0, (sum, task) => sum + task.pageNumbers.length);
      _prepareQueuedTask();
    } else {
      _currentPage = app.getNextContinuePage();
      _targetPages = settingsProvider.dailyFAGoal;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareQueuedTask() {
    final task = _currentTask;
    if (task == null) {
      return;
    }

    if (task.type == 'FA' && task.pageNumbers.isNotEmpty) {
      _currentPage = task.pageNumbers.first;
    }

    _pageElapsed = 0;
    _isRevisionPage = false;
    _showAnkiPrompt = false;
    _ankiPendingPages.clear();
    if (_isStudying) {
      _startCurrentQueuedTaskIfNeeded();
    }
  }

  void _startStudying() {
    _setStateIfMounted(() {
      _isStudying = true;
      _pageElapsed = 0;
    });

    _startCurrentQueuedTaskIfNeeded();
    _ensureTimerRunning();
    _triggerQueuedFaRevisionGateIfNeeded();
  }

  void _startCurrentQueuedTaskIfNeeded() {
    final task = _currentTask;
    if (task == null) {
      return;
    }
    _taskStartedAt.putIfAbsent(task.id, DateTime.now);
  }

  void _ensureTimerRunning() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isStudying || _timersPaused) {
        return;
      }
      _setStateIfMounted(() {
        _totalElapsed++;
        _pageElapsed++;
      });
    });
  }

  void _triggerQueuedFaRevisionGateIfNeeded() {
    if (!_isStudying || !_hasQueuedTasks || !_isQueueFaTask) {
      return;
    }
    unawaited(_handleQueuedFaRevisionGateIfNeeded());
  }

  Future<void> _handleQueuedFaRevisionGateIfNeeded() async {
    if (!mounted ||
        !_isStudying ||
        !_hasQueuedTasks ||
        !_isQueueFaTask ||
        _isResolvingQueuedRevision) {
      return;
    }

    final app = context.read<AppProvider>();
    final page = app.getFAPage(_currentPage);
    final revisionItem = app.getFAPageRevisionItem(_currentPage);
    final scheduledAt =
        SrsService.parseRevisionDate(revisionItem?.nextRevisionAt);
    final isRevisionTask = page != null &&
        page.status != 'unread' &&
        revisionItem != null &&
        scheduledAt != null;

    if (!isRevisionTask) {
      if (_timersPaused || _isRevisionPage || _isResolvingQueuedRevision) {
        _setStateIfMounted(() {
          _timersPaused = false;
          _isRevisionPage = false;
          _isResolvingQueuedRevision = false;
        });
      }
      return;
    }

    _setStateIfMounted(() {
      _timersPaused = true;
      _isRevisionPage = true;
      _isResolvingQueuedRevision = true;
    });

    final reviseNow = await _showRevisionDueSheet(
      page: page,
      scheduledAt: scheduledAt,
    );

    if (!mounted || !_isStudying) {
      return;
    }

    if (reviseNow) {
      _setStateIfMounted(() {
        _timersPaused = false;
        _isRevisionPage = true;
        _isResolvingQueuedRevision = false;
      });
      return;
    }

    _setStateIfMounted(() {
      _isRevisionPage = false;
      _isResolvingQueuedRevision = false;
    });
    await _advanceQueue(
      triggerRevisionGate: false,
      completeCurrentTask: false,
    );

    if (!mounted || !_isStudying) {
      return;
    }

    if (!_isQueueFaTask) {
      _setStateIfMounted(() {
        _timersPaused = false;
      });
      return;
    }

    _triggerQueuedFaRevisionGateIfNeeded();
  }

  Future<bool> _showRevisionDueSheet({
    required FAPage page,
    required DateTime scheduledAt,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final scheduledLabel =
            DateFormat('EEE, d MMM yyyy').format(scheduledAt.toLocal());
        final isDueNow = SrsService.isScheduledTodayOrPast(
          nextRevisionAt: scheduledAt.toIso8601String(),
        );
        final daysUntil = SrsService.daysUntilScheduledDate(
              nextRevisionAt: scheduledAt.toIso8601String(),
            ) ??
            0;
        final statusText = isDueNow
            ? 'Due now'
            : 'Scheduled in $daysUntil day${daysUntil == 1 ? '' : 's'}';

        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${page.pageNum} - Revision Due',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${page.subject} - ${page.title}',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scheduled for $scheduledLabel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDueNow
                            ? cs.errorContainer.withValues(alpha: 0.65)
                            : cs.primaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDueNow
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_rounded,
                            color: isDueNow ? cs.error : cs.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isDueNow ? 'Due now' : statusText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDueNow ? cs.onErrorContainer : cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Revise Now',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Keep for Scheduled Time',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _markPageDone() async {
    if (_hasQueuedTasks && !_isQueueFaTask) {
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();

    _pageTimings.add(
      _PageTiming(
        pageNum: _currentPage,
        seconds: _pageElapsed,
      ),
    );

    if (_isRevisionPage) {
      app.advanceFAPageRevision(_currentPage);
    } else {
      final subs = app.getSubtopicsForPage(_currentPage);
      if (subs.isNotEmpty) {
        final unreadIds =
            subs.where((s) => s.status == 'unread').map((s) => s.id!).toList();
        if (unreadIds.isNotEmpty) {
          app.markSubtopicsRead(unreadIds);
        }
      }

      app.updateFAPageStatus(_currentPage, 'read');
    }
    _pagesCompletedInSession++;

    if (!_hasQueuedTasks) {
      _ankiPendingPages.add(_currentPage);
      if (_ankiPendingPages.length >= 4) {
        _setStateIfMounted(() {
          _showAnkiPrompt = true;
        });
        return;
      }
    }

    await _moveToNextPage();
  }

  Future<void> _moveToNextPage({bool triggerRevisionGate = true}) async {
    if (_hasQueuedTasks && _isQueueFaTask) {
      await _advanceQueue(triggerRevisionGate: triggerRevisionGate);
      return;
    }

    final app = context.read<AppProvider>();
    int next = _currentPage + 1;
    while (true) {
      final match = app.faPages.where((p) => p.pageNum == next).toList();
      if (match.isEmpty || match.first.status == 'unread') {
        break;
      }
      next++;
    }
    _setStateIfMounted(() {
      _currentPage = next;
      _pageElapsed = 0;
      _isRevisionPage = false;
    });
  }

  Future<void> _advanceQueue({
    bool triggerRevisionGate = true,
    bool completeCurrentTask = true,
  }) async {
    if (completeCurrentTask) {
      await _completeCurrentQueuedTask();
    } else {
      final currentTask = _currentTask;
      if (currentTask != null) {
        _taskStartedAt.remove(currentTask.id);
      }
    }
    final nextTaskIndex = _currentTaskIndex + 1;
    if (nextTaskIndex >= _queue.length) {
      _endSession();
      return;
    }

    _setStateIfMounted(() {
      _currentTaskIndex = nextTaskIndex;
      _prepareQueuedTask();
    });
    if (triggerRevisionGate) {
      _triggerQueuedFaRevisionGateIfNeeded();
    }
  }

  Future<void> _completeQueuedUWorldTask() async {
    if (!_hasQueuedTasks || !_isQueueUWorldTask) {
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final task = _currentTask;
    if (task == null) {
      return;
    }

    for (final topicId in task.topicIds.toSet()) {
      await app.markUWorldTopicDone(topicId);
    }

    if (!mounted) {
      return;
    }

    _setStateIfMounted(() {
      _pageElapsed = 0;
    });
    await _advanceQueue();
  }

  Future<void> _completeQueuedSupplementalTask() async {
    if (!_hasQueuedTasks || _isQueueStructuredTask) {
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final task = _currentTask;
    if (task == null) {
      return;
    }

    final itemIds = task.topicIds.toSet();
    for (final itemId in itemIds) {
      switch (task.type) {
        case 'SKETCHY_MICRO':
          await app.advanceSketchyMicroRevision(itemId);
          break;
        case 'SKETCHY_PHARM':
          await app.advanceSketchyPharmRevision(itemId);
          break;
        case 'PATHOMA':
          await app.advancePathomaRevision(itemId);
          break;
        case 'VIDEO_LECTURE':
          await app.toggleVideoLectureWatched(itemId, true);
          break;
      }
    }

    if (!mounted) {
      return;
    }

    _setStateIfMounted(() {
      _pageElapsed = 0;
    });
    await _advanceQueue();
  }

  void _doAnki() {
    final app = context.read<AppProvider>();
    for (final page in _ankiPendingPages) {
      app.updateFAPageStatus(page, 'anki_done');
    }
    _setStateIfMounted(() {
      _showAnkiPrompt = false;
      _ankiPendingPages.clear();
    });
    unawaited(_moveToNextPage());
  }

  void _skipAnki() {
    _setStateIfMounted(() {
      _showAnkiPrompt = false;
      _ankiPendingPages.clear();
    });
    unawaited(_moveToNextPage());
  }

  void _endSession() {
    _timer?.cancel();
    _timer = null;
    _isStudying = false;
    _timersPaused = false;
    _isRevisionPage = false;
    _isResolvingQueuedRevision = false;
    _setStateIfMounted(() {});
    widget.onComplete?.call();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _completeCurrentQueuedTask() async {
    final task = _currentTask;
    if (task == null) {
      return;
    }

    final completedAt = DateTime.now();
    final startedAt = _taskStartedAt.remove(task.id) ?? completedAt;
    final actualDurationSeconds =
        completedAt.difference(startedAt).inSeconds.clamp(0, 24 * 60 * 60);
    final durationMinutes =
        (actualDurationSeconds / 60).ceil().clamp(1, 24 * 60);
    final dateLabel = DateFormat('yyyy-MM-dd').format(completedAt.toLocal());

    final entry = TimeLogEntry(
      id: 'study-task-${task.id}-${completedAt.microsecondsSinceEpoch}',
      date: dateLabel,
      startTime: startedAt.toIso8601String(),
      endTime: completedAt.toIso8601String(),
      durationMinutes: durationMinutes,
      category: _timeLogCategoryForTask(task),
      source: TimeLogSource.todaysPlan,
      activity: task.label,
      linkedEntityId: task.id,
      taskType: task.type,
      taskId: task.id,
      taskLabel: task.label,
      actualDurationSeconds: actualDurationSeconds,
      pageNumber: _timeLogPageNumber(task),
      topics: _timeLogTopics(task),
    );

    await context.read<AppProvider>().upsertTimeLog(entry);
  }

  TimeLogCategory _timeLogCategoryForTask(StudyTask task) {
    switch (task.type) {
      case 'UWORLD':
        return TimeLogCategory.qbank;
      case 'SKETCHY_MICRO':
      case 'SKETCHY_PHARM':
      case 'PATHOMA':
      case 'VIDEO_LECTURE':
        return TimeLogCategory.video;
      default:
        return TimeLogCategory.study;
    }
  }

  String? _timeLogPageNumber(StudyTask task) {
    if (task.type != 'FA' || task.pageNumbers.isEmpty) {
      return null;
    }
    if (task.pageNumbers.length == 1) {
      return task.pageNumbers.first.toString();
    }
    return '${task.pageNumbers.first}-${task.pageNumbers.last}';
  }

  List<String>? _timeLogTopics(StudyTask task) {
    if (task.type == 'FA' || task.topicIds.isEmpty) {
      return null;
    }
    return task.topicIds.map((id) => id.toString()).toList();
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  List<UWorldTopic> _selectedUWorldTopics(AppProvider app) {
    final selectedIds = _currentTask?.topicIds.toSet() ?? const <int>{};
    if (selectedIds.isEmpty) {
      return const <UWorldTopic>[];
    }

    final topics = app.uworldTopics
        .where((topic) => topic.id != null && selectedIds.contains(topic.id))
        .toList()
      ..sort((a, b) {
        final systemCompare = a.system.compareTo(b.system);
        if (systemCompare != 0) {
          return systemCompare;
        }
        return a.subtopic.compareTo(b.subtopic);
      });
    return topics;
  }

  List<SketchyVideo> _selectedSketchyVideos(AppProvider app, String type) {
    final selectedIds = _currentTask?.topicIds.toSet() ?? const <int>{};
    if (selectedIds.isEmpty) {
      return const <SketchyVideo>[];
    }

    final source = type == 'SKETCHY_PHARM'
        ? app.sketchyPharmVideos
        : app.sketchyMicroVideos;
    final videos = source
        .where((video) => video.id != null && selectedIds.contains(video.id))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return videos;
  }

  List<PathomaChapter> _selectedPathomaChapters(AppProvider app) {
    final selectedIds = _currentTask?.topicIds.toSet() ?? const <int>{};
    if (selectedIds.isEmpty) {
      return const <PathomaChapter>[];
    }

    final chapters = app.pathomaChapters
        .where(
            (chapter) => chapter.id != null && selectedIds.contains(chapter.id))
        .toList()
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return chapters;
  }

  List<VideoLecture> _selectedLibraryVideos(AppProvider app) {
    final selectedIds = _currentTask?.topicIds.toSet() ?? const <int>{};
    if (selectedIds.isEmpty) {
      return const <VideoLecture>[];
    }

    final lectures = app.videoLectures
        .where((lecture) => lecture.id != null && selectedIds.contains(lecture.id))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lectures;
  }

  List<_QueuedTaskListItem> _selectedSupplementalItems(AppProvider app) {
    final task = _currentTask;
    if (task == null) {
      return const <_QueuedTaskListItem>[];
    }

    switch (task.type) {
      case 'SKETCHY_MICRO':
      case 'SKETCHY_PHARM':
        return _selectedSketchyVideos(app, task.type)
            .map(
              (video) => _QueuedTaskListItem(
                title: video.title,
                subtitle: '${video.category} • ${video.subcategory}',
              ),
            )
            .toList();
      case 'PATHOMA':
        return _selectedPathomaChapters(app)
            .map(
              (chapter) => _QueuedTaskListItem(
                title: 'Chapter ${chapter.chapter}',
                subtitle: chapter.title,
              ),
            )
            .toList();
      case 'VIDEO_LECTURE':
        return _selectedLibraryVideos(app)
            .map(
              (lecture) => _QueuedTaskListItem(
                title: lecture.customTitle ?? lecture.title,
                subtitle: '${lecture.subject} • ${lecture.remainingLabel}',
              ),
            )
            .toList();
      default:
        if (task.topicIds.isEmpty) {
          return const <_QueuedTaskListItem>[];
        }
        return task.topicIds
            .map(
              (id) => _QueuedTaskListItem(
                title: task.label,
                subtitle: 'Item ID $id',
              ),
            )
            .toList();
    }
  }

  IconData _iconForTaskType(String type) {
    switch (type) {
      case 'UWORLD':
        return Icons.quiz_rounded;
      case 'SKETCHY_MICRO':
      case 'SKETCHY_PHARM':
        return Icons.play_circle_fill_rounded;
      case 'PATHOMA':
      case 'VIDEO_LECTURE':
        return Icons.ondemand_video_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _accentForTaskType(String type) {
    switch (type) {
      case 'UWORLD':
        return const Color(0xFFF59E0B);
      case 'SKETCHY_MICRO':
        return const Color(0xFF0EA5E9);
      case 'SKETCHY_PHARM':
        return const Color(0xFF14B8A6);
      case 'PATHOMA':
        return const Color(0xFFEF4444);
      case 'VIDEO_LECTURE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _welcomeDescription() {
    final task = _currentTask;
    if (!_hasQueuedTasks || task == null) {
      return _currentPage > 1
          ? 'You have completed up to page ${_currentPage - 1}.\nContinue from page $_currentPage?'
          : 'Start studying from page $_currentPage';
    }

    if (task.type == 'FA') {
      if (task.pageNumbers.isEmpty) {
        return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.';
      }
      final first = task.pageNumbers.first;
      final last = task.pageNumbers.last;
      final range = first == last ? 'page $first' : 'pages $first-$last';
      return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.\nStart FA $range?';
    }

    if (task.type == 'UWORLD') {
      return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.\nStart ${task.detail}?';
    }

    return 'Queued task ${_currentTaskIndex + 1} of ${_queue.length}.\nStart ${task.label}?';
  }

  String _welcomeBadgeText() {
    final task = _currentTask;
    if (!_hasQueuedTasks || task == null) {
      return 'Today\'s target: $_targetPages pages';
    }

    if (task.type == 'FA') {
      final count = task.pageNumbers.length;
      return '$count selected page${count == 1 ? '' : 's'}';
    }

    if (task.type == 'UWORLD') {
      return '${task.questionCount} queued question${task.questionCount == 1 ? '' : 's'}';
    }

    return '${task.estimatedDurationMinutes} min planned';
  }

  String _faBannerText() {
    if (_hasQueuedTasks && _isQueueFaTask) {
      final task = _currentTask!;
      final pageNumber =
          task.pageNumbers.isNotEmpty ? task.pageNumbers.first : _currentPage;
      return 'Task ${_currentTaskIndex + 1}/${_queue.length}: page $pageNumber.';
    }

    final remaining = _targetPages - _pagesCompletedInSession;
    final motivation =
        _motivations[_pagesCompletedInSession % _motivations.length];
    return remaining > 0
        ? 'Today\'s target: $remaining pages remaining. $motivation'
        : 'You have hit your target! Amazing!';
  }

  String _faHeaderTitle() {
    if (_hasQueuedTasks && _isQueueFaTask) {
      return '${_currentTask!.label} - Page $_currentPage';
    }
    return 'Page $_currentPage';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();

    if (!_isStudying) {
      return _WelcomeView(
        description: _welcomeDescription(),
        badgeText: _welcomeBadgeText(),
        onStart: _startStudying,
        onBack: () => Navigator.pop(context),
      );
    }

    if (!_hasQueuedTasks && _showAnkiPrompt) {
      return _AnkiPromptView(
        pages: _ankiPendingPages,
        onDoAnki: _doAnki,
        onSkip: _skipAnki,
      );
    }

    if (_hasQueuedTasks && _isQueueUWorldTask) {
      final task = _currentTask!;
      final topics = _selectedUWorldTopics(app);
      return _QueuedUWorldView(
        task: task,
        topics: topics,
        taskIndex: _currentTaskIndex,
        totalTasks: _queue.length,
        totalElapsedLabel: _fmtTime(_totalElapsed),
        taskElapsedLabel: _fmtTime(_pageElapsed),
        onComplete: _completeQueuedUWorldTask,
        onEndSession: _endSession,
      );
    }

    if (_hasQueuedTasks && !_isQueueFaTask) {
      final task = _currentTask!;
      return _QueuedGenericTaskView(
        task: task,
        items: _selectedSupplementalItems(app),
        taskIndex: _currentTaskIndex,
        totalTasks: _queue.length,
        totalElapsedLabel: _fmtTime(_totalElapsed),
        taskElapsedLabel: _fmtTime(_pageElapsed),
        accentColor: _accentForTaskType(task.type),
        icon: _iconForTaskType(task.type),
        onComplete: _completeQueuedSupplementalTask,
        onEndSession: _endSession,
      );
    }

    final subtopics = app.getSubtopicsForPage(_currentPage);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _faHeaderTitle(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _endSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _faBannerText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: subtopics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 48,
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Study Page $_currentPage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No subtopics available for this page',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Subtopics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  final unreadIds = subtopics
                                      .where((s) => s.status == 'unread')
                                      .map((s) => s.id!)
                                      .toList();
                                  if (unreadIds.isNotEmpty) {
                                    app.markSubtopicsRead(unreadIds);
                                  }
                                },
                                icon: const Icon(
                                  Icons.select_all_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Select All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: subtopics.length,
                            itemBuilder: (context, i) {
                              final sub = subtopics[i];
                              final isDone = sub.status != 'unread';
                              return CheckboxListTile(
                                value: isDone,
                                onChanged: (val) {
                                  if (val == true && sub.id != null) {
                                    app.markSubtopicRead(sub.id!);
                                  }
                                },
                                title: Text(
                                  sub.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDone
                                        ? cs.onSurface.withValues(alpha: 0.4)
                                        : cs.onSurface,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This page',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_pageElapsed),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_totalElapsed),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _markPageDone,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Done with this page',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final String description;
  final String badgeText;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _WelcomeView({
    required this.description,
    required this.badgeText,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Study?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Let\'s Go!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueuedUWorldView extends StatelessWidget {
  final StudyTask task;
  final List<UWorldTopic> topics;
  final int taskIndex;
  final int totalTasks;
  final String totalElapsedLabel;
  final String taskElapsedLabel;
  final Future<void> Function() onComplete;
  final VoidCallback onEndSession;

  const _QueuedUWorldView({
    required this.task,
    required this.topics,
    required this.taskIndex,
    required this.totalTasks,
    required this.totalElapsedLabel,
    required this.taskElapsedLabel,
    required this.onComplete,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    size: 22,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEndSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    const Color(0xFFF97316).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.playlist_add_check_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Task ${taskIndex + 1}/$totalTasks - ${task.questionCount} queued questions',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  task.detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: topics.isEmpty
                  ? Center(
                      child: Text(
                        'No UWorld topics were selected.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        final remaining =
                            topic.totalQuestions - topic.doneQuestions;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.quiz_rounded,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.subtopic,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${topic.system} - $remaining remaining',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This task',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            taskElapsedLabel,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalElapsedLabel,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Complete UWorld task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuedTaskListItem {
  final String title;
  final String subtitle;

  const _QueuedTaskListItem({
    required this.title,
    required this.subtitle,
  });
}

class _QueuedGenericTaskView extends StatelessWidget {
  final StudyTask task;
  final List<_QueuedTaskListItem> items;
  final int taskIndex;
  final int totalTasks;
  final String totalElapsedLabel;
  final String taskElapsedLabel;
  final Color accentColor;
  final IconData icon;
  final Future<void> Function() onComplete;
  final VoidCallback onEndSession;

  const _QueuedGenericTaskView({
    required this.task,
    required this.items,
    required this.taskIndex,
    required this.totalTasks,
    required this.totalElapsedLabel,
    required this.taskElapsedLabel,
    required this.accentColor,
    required this.icon,
    required this.onComplete,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final detailText = task.detail.trim().isEmpty ? task.label : task.detail;
    final itemLabel = task.itemCount == 1 ? 'item' : 'items';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEndSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.14),
                    accentColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_add_check_rounded, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Task ${taskIndex + 1}/$totalTasks - ${task.itemCount} queued $itemLabel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Review the task details, then mark it done when finished.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: accentColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This task',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            taskElapsedLabel,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalElapsedLabel,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Mark Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnkiPromptView extends StatelessWidget {
  final List<int> pages;
  final VoidCallback onDoAnki;
  final VoidCallback onSkip;

  const _AnkiPromptView({
    required this.pages,
    required this.onDoAnki,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pageRange = pages.isNotEmpty
        ? 'pages ${pages.first}-${pages.last}'
        : 'recent pages';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('Anki', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time for Anki!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please complete Anki for $pageRange\nbefore continuing to the next page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDoAnki,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Done with Anki',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip Anki for now',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTiming {
  final int pageNum;
  final int seconds;
  const _PageTiming({required this.pageNum, required this.seconds});
}
