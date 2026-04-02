import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/active_study_session.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/reminder.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/session/session_screen.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/widgets/liquid_glass_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'buying_tab.dart';
import 'block_editor_sheet.dart';
import 'day_session_screen.dart';
import 'reminder_tab.dart';
import 'routine_editor_sheet.dart';
import 'routine_runner_screen.dart';
import 'routines_tab.dart';
import 'study_flow_screen.dart';
import 'study_session_picker.dart';
import 'todo_tab.dart';
import 'track_now_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/timeline_view.dart';
import 'planned_insert_conflict_sheet.dart';

Color _todayPlanAccent(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

Color _todayPlanAccentSoft(BuildContext context) =>
    Theme.of(context).colorScheme.secondary;

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen>
    with SingleTickerProviderStateMixin {
  static const int _timelineTabIndex = 0;
  static const int _routinesTabIndex = 1;
  static const int _moreTabIndex = 2;
  static const int _moreReminderSubTabIndex = 0;

  late DateTime _selectedDate;
  late DateTime _lastCalendarDate;
  String? _completedBlockId;
  String? _highlightedReminderId;
  late TabController _tabCtrl;
  bool _didProcessExpiredRoutineQueue = false;
  bool _didAutoOpenActiveStudySession = false;
  TodayPlanLaunchRequest? _processingNotificationLaunch;
  int _selectedMoreSubTabIndex = _moreReminderSubTabIndex;

  late final StreamSubscription<DateTime> _clockTimer;

  static const _prayers = [
    ('Fajr', 5, 35, 6, 5, 5, 45),
    ('Zuhr', 13, 20, 13, 50, 13, 30),
    ('Asr', 16, 50, 17, 20, 17, 0),
    ('Maghrib', 18, 20, 18, 50, 18, 30),
    ('Isha', 20, 5, 20, 35, 20, 15),
  ];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ignore: unused_element
  List<Block> _buildPrayerBlocks() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _prayers.map((p) {
      final startH = p.$2;
      final startM = p.$3;
      final endH = p.$4;
      final endM = p.$5;
      final duration = (endH * 60 + endM) - (startH * 60 + startM);

      return Block(
        id: 'prayer_${p.$1.toLowerCase()}',
        index: 0,
        date: dateStr,
        plannedStartTime:
            '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}',
        plannedEndTime:
            '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
        type: BlockType.other,
        title: '${p.$1} 🕌',
        plannedDurationMinutes: duration,
        isEvent: true,
        status: BlockStatus.done,
        isVirtual: true,
      );
    }).toList();
  }

  DateTime _calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isAutoPrayerRoutineBlock(Block block) =>
      block.id.startsWith('routine-prayer_');

  void _handleClockTick(DateTime now) {
    final currentCalendarDate = _calendarDate(now);
    if (AppDateUtils.isSameDay(currentCalendarDate, _lastCalendarDate)) {
      return;
    }

    final wasShowingCurrentDay =
        AppDateUtils.isSameDay(_selectedDate, _lastCalendarDate);
    _lastCalendarDate = currentCalendarDate;

    if (wasShowingCurrentDay) {
      _setStateIfMounted(() => _selectedDate = currentCalendarDate);
      unawaited(_refreshSelectedDateBlocks());
    }

    _schedulePrayerNotifications();
  }

  void _schedulePrayerNotifications() {
    if (!_isToday) return;

    for (int i = 0; i < _prayers.length; i++) {
      NotificationService.instance.cancel(1000 + i);
    }

    final now = DateTime.now();
    for (int i = 0; i < _prayers.length; i++) {
      final p = _prayers[i];
      final notifTime = DateTime(now.year, now.month, now.day, p.$2, p.$3);
      if (notifTime.isAfter(now)) {
        NotificationService.instance.scheduleAt(
          id: 1000 + i,
          title: '${p.$1} 🕌',
          body: 'Time to head to the mosque — ${p.$1} prayer in 10 minutes.',
          when: notifTime,
          intent: NotificationIntent.todayPlan(dateKey: _dateKey),
        );
      }
    }
  }

  Future<void> _showRoutineEditorSheet(Routine routine) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoutineEditorSheet(existing: routine),
    );
  }

  Future<void> _showExpiredRoutineDialogs() async {
    if (_didProcessExpiredRoutineQueue || !mounted) return;
    _didProcessExpiredRoutineQueue = true;
    await _processNextExpiredRoutineDialog(context.read<AppProvider>());
  }

  Future<void> _processNextExpiredRoutineDialog(AppProvider app) async {
    if (!mounted || !app.hasPendingExpiredRoutinePrompts) return;

    final routine = app.takeNextExpiredRoutinePrompt();
    if (routine == null) return;

    final endDate = DateTime.tryParse(routine.recurrenceEndDate ?? '');
    final formattedDate = endDate == null
        ? (routine.recurrenceEndDate ?? 'the selected date')
        : DateFormat('dd MMM yyyy').format(endDate);

    final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Routine schedule expired'),
            content: Text(
              '${routine.name} was scheduled until $formattedDate. Update it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Dismiss'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Update'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (shouldUpdate) {
      _tabCtrl.animateTo(_routinesTabIndex);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _showRoutineEditorSheet(routine);
      if (!mounted) return;
    }

    await _processNextExpiredRoutineDialog(app);
  }

  void _onTodayPlanLaunchChanged() {
    final request = NotificationService.instance.todayPlanLaunchNotifier.value;
    if (request == null) return;
    unawaited(_handleTodayPlanLaunchRequest(request));
  }

  Future<void> _handleTodayPlanLaunchRequest(
    TodayPlanLaunchRequest request,
  ) async {
    if (!mounted) return;
    if (!identical(
      NotificationService.instance.todayPlanLaunchNotifier.value,
      request,
    )) {
      return;
    }
    if (identical(_processingNotificationLaunch, request)) return;

    _processingNotificationLaunch = request;
    try {
      final requestedDate =
          request.dateKey != null ? DateTime.tryParse(request.dateKey!) : null;
      if (requestedDate != null) {
        _setStateIfMounted(() {
          _selectedDate = DateTime(
            requestedDate.year,
            requestedDate.month,
            requestedDate.day,
          );
        });
      }

      final opensReminderTab =
          request.openReminderTab || request.reminderId != null;
      if (opensReminderTab) {
        _setStateIfMounted(() {
          _selectedMoreSubTabIndex = _moreReminderSubTabIndex;
          _highlightedReminderId = request.reminderId;
        });
      } else if (_highlightedReminderId != null) {
        _setStateIfMounted(() => _highlightedReminderId = null);
      }

      _tabCtrl.animateTo(
        opensReminderTab
            ? _moreTabIndex
            : (request.opensRoutinesTab
                ? _routinesTabIndex
                : _timelineTabIndex),
      );
      await _refreshSelectedDateBlocks();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;

      final app = context.read<AppProvider>();
      if (request.openDaySession) {
        final session = app.getActiveDaySession(_dateKey);
        if (session != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DaySessionScreen(
                dateKey: _dateKey,
                session: session,
              ),
            ),
          );
        }
        return;
      }

      if (opensReminderTab) {
        return;
      }

      if (request.blockId == null) {
        await _openRoutineLaunchIfNeeded(app, request);
        return;
      }

      final plan = app.getDayPlan(_dateKey);
      Block? block;
      for (final candidate in plan?.blocks ?? const <Block>[]) {
        if (candidate.id == request.blockId) {
          block = candidate;
          break;
        }
      }
      if (block == null) return;

      await _openBlockLaunch(app, plan, block);
    } finally {
      NotificationService.instance.clearTodayPlanLaunchRequest(request);
      if (identical(_processingNotificationLaunch, request)) {
        _processingNotificationLaunch = null;
      }
    }
  }

  bool _opensStudyLaunch(Block block) {
    final title = block.title.toLowerCase();
    return title.contains('study') ||
        title.contains('revision') ||
        title.contains('anki') ||
        title.contains('qbank') ||
        title.contains('lecture');
  }

  Future<void> _openRoutineLaunchIfNeeded(
    AppProvider app,
    TodayPlanLaunchRequest request,
  ) async {
    final routineId = request.routineId;
    if (routineId == null) return;

    final activeRun = app.getActiveRoutineRunForRoutine(routineId, _dateKey);
    if (activeRun == null) return;

    final routine = app.getRoutineById(routineId);
    if (routine == null) return;

    await RoutineRunnerScreen.open(
      context,
      routine: routine,
      dateKey: _dateKey,
      sourceBlockId: activeRun.sourceBlockId,
    );
  }

  Future<void> _openBlockLaunch(
    AppProvider app,
    DayPlan? plan,
    Block block,
  ) async {
    final sourceDateKey = block.date.isNotEmpty ? block.date : _dateKey;

    if (app.isRoutineBlock(block)) {
      final routine = app.getRoutineForBlock(block);
      if (routine != null) {
        await RoutineRunnerScreen.open(
          context,
          routine: routine,
          dateKey: sourceDateKey,
          sourceBlockId: block.id,
        );
      }
      return;
    }

    if (_opensStudyLaunch(block)) {
      final activeSession = app.getActiveStudySession();
      if (activeSession != null &&
          activeSession.kind == ActiveStudySessionKind.studyFlow &&
          activeSession.dateKey == sourceDateKey &&
          activeSession.blockId == block.id) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudyFlowScreen(
              dateKey: sourceDateKey,
              blockId: block.id,
              sessionTitle: block.title,
              autoAdvanceFlow: true,
            ),
          ),
        );
        return;
      }

      final plannedSession = PlannedStudySessionPayload.fromBlock(block);
      if (plannedSession != null && plannedSession.tasks.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudyFlowScreen(
              dateKey: sourceDateKey,
              queuedTasks: plannedSession.tasks,
              blockId: block.id,
              sessionTitle: block.title,
              autoAdvanceFlow: true,
            ),
          ),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StudySessionPicker(
          dateKey: sourceDateKey,
          targetBlockId: block.id,
          boundPlannedStartTime: block.plannedStartTime,
          boundPlannedEndTime: block.plannedEndTime,
        ),
      );
      return;
    }

    if (plan != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(block: block, plan: plan),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _lastCalendarDate = _calendarDate(DateTime.now());
    _selectedDate = _lastCalendarDate;
    _tabCtrl = TabController(length: 3, vsync: this);
    NotificationService.instance.todayPlanLaunchNotifier
        .addListener(_onTodayPlanLaunchChanged);
    _clockTimer =
        Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now())
            .listen(_handleClockTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePrayerNotifications();
      _showExpiredRoutineDialogs();
      unawaited(_refreshSelectedDateBlocks());
      final request =
          NotificationService.instance.todayPlanLaunchNotifier.value;
      if (request != null) {
        unawaited(_handleTodayPlanLaunchRequest(request));
      } else {
        unawaited(_tryOpenActiveStudySession());
      }
    });
  }

  @override
  void dispose() {
    NotificationService.instance.todayPlanLaunchNotifier
        .removeListener(_onTodayPlanLaunchChanged);
    _clockTimer.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _dateKey => AppDateUtils.formatDate(_selectedDate);
  bool get _isToday =>
      AppDateUtils.isSameDay(_selectedDate, _calendarDate(DateTime.now()));
  bool get _isPastDate =>
      _calendarDate(_selectedDate).isBefore(_calendarDate(DateTime.now()));

  Future<void> _refreshSelectedDateBlocks() async {
    final app = context.read<AppProvider>();
    if (_dateKey == app.todayDateKey) {
      await app.injectRoutinesIntoDayPlan(_dateKey);
    }
    await app.ensureRecurringBlocksForDate(_dateKey);
  }

  void _prevDay() {
    _setStateIfMounted(
      () {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _highlightedReminderId = null;
      },
    );
    unawaited(_refreshSelectedDateBlocks());
  }

  void _nextDay() {
    _setStateIfMounted(
      () {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _highlightedReminderId = null;
      },
    );
    unawaited(_refreshSelectedDateBlocks());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      _setStateIfMounted(() {
        _selectedDate = picked;
        _highlightedReminderId = null;
      });
      await _refreshSelectedDateBlocks();
    }
  }

  Future<void> _openTimelineDate(DateTime date) async {
    _setStateIfMounted(
      () {
        _selectedDate = DateTime(date.year, date.month, date.day);
        _highlightedReminderId = null;
      },
    );
    await _refreshSelectedDateBlocks();
  }

  Future<void> _openReminderFromTimeline(ReminderOccurrence occurrence) async {
    _setStateIfMounted(() {
      _selectedMoreSubTabIndex = _moreReminderSubTabIndex;
      _highlightedReminderId = occurrence.reminderId;
    });
    await showReminderEditorSheet(
      context,
      dateKey: _dateKey,
      existing: occurrence.reminder,
    );
  }

  Future<void> _toggleReminderFromTimeline(
    ReminderOccurrence occurrence,
    bool completed,
  ) {
    return context.read<AppProvider>().setReminderOccurrenceCompleted(
          reminderId: occurrence.reminderId,
          occurrenceKey: occurrence.occurrenceKey,
          completed: completed,
        );
  }

  void _handleMoreSubTabChanged(int index) {
    if (_selectedMoreSubTabIndex == index) return;
    _setStateIfMounted(() {
      _selectedMoreSubTabIndex = index;
      if (index != _moreReminderSubTabIndex) {
        _highlightedReminderId = null;
      }
    });
  }

  Future<void> _tryOpenActiveStudySession() async {
    if (_didAutoOpenActiveStudySession || !mounted) {
      return;
    }

    final app = context.read<AppProvider>();
    final session = app.getActiveStudySession();
    if (session == null || session.kind != ActiveStudySessionKind.studyFlow) {
      return;
    }

    _didAutoOpenActiveStudySession = true;
    final sessionDate = AppDateUtils.parseDate(session.dateKey);
    if (sessionDate != null) {
      _setStateIfMounted(
        () => _selectedDate =
            DateTime(sessionDate.year, sessionDate.month, sessionDate.day),
      );
    }

    _tabCtrl.animateTo(0);
    await _refreshSelectedDateBlocks();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyFlowScreen(
          dateKey: session.dateKey,
          blockId: session.blockId,
          sessionTitle: session.title,
          autoAdvanceFlow: true,
        ),
      ),
    );
  }

  void _openTrackNow() {
    final app = context.read<AppProvider>();
    final activeTrackNow = app.getActiveTrackNow(_dateKey);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackNowScreen(
          dateKey: _dateKey,
          existingActivityId: activeTrackNow?.id,
        ),
      ),
    );
  }

  Future<void> _openDaySession() async {
    final app = context.read<AppProvider>();
    var session = app.getActiveDaySession(_dateKey);

    if (session == null) {
      app.startDaySession(_dateKey);
      await app.rescheduleFromNow(_dateKey);
    }

    final firstBlockId = app.getFirstActionableBlockId(_dateKey);
    if (firstBlockId != null) {
      app.setCurrentBlock(_dateKey, firstBlockId);
    }

    session = app.getActiveDaySession(_dateKey);

    if (!mounted || session == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DaySessionScreen(
          dateKey: _dateKey,
          session: session!,
        ),
      ),
    );
  }

  void _openStudySession() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudySessionPicker(dateKey: _dateKey),
    );
  }

  int _defaultStartMinutes() {
    final now = DateTime.now();
    final roundedMinutes = ((now.minute + 14) ~/ 15) * 15;
    final rolledHour = now.hour + (roundedMinutes ~/ 60);
    final normalizedHour = rolledHour.clamp(0, 23);
    final normalizedMinute = roundedMinutes % 60;
    final requestedStart = (normalizedHour * 60) + normalizedMinute;
    return context.read<AppProvider>().recommendedStartMinutesForInsertion(
          _dateKey,
          requestedStartMinutes: requestedStart,
          durationMinutes: 60,
        );
  }

  String _formatMinutesOfDay(int totalMinutes) {
    final normalized = totalMinutes.clamp(0, 23 * 60 + 59);
    final hours = normalized ~/ 60;
    final minutes = normalized % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Block _buildDraftBlock({
    int? startMinutes,
    int? endMinutes,
    bool isEvent = false,
    BlockType type = BlockType.other,
    String? title,
    String? description,
  }) {
    final initialStart = startMinutes ?? _defaultStartMinutes();
    const defaultDurationMinutes = 60;
    final initialEnd = endMinutes ?? (initialStart + defaultDurationMinutes);
    return Block(
      id: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      index: 0,
      date: _dateKey,
      plannedStartTime: _formatMinutesOfDay(initialStart),
      plannedEndTime: _formatMinutesOfDay(initialEnd),
      type: type,
      title: title ?? (isEvent ? 'New Event' : 'New Task'),
      description: description,
      plannedDurationMinutes: initialEnd - initialStart,
      isEvent: isEvent,
      status: BlockStatus.notStarted,
    );
  }

  Future<void> _saveNewBlock(BlockEditorUpdate update, String blockId) async {
    final app = context.read<AppProvider>();
    if (update.saveAsLog) {
      await app.saveManualLogBlock(
        date: update.dateKey,
        title: update.title,
        startTime: update.plannedStartTime,
        endTime: update.plannedEndTime,
        notes: update.description,
        blockId: blockId,
      );
      return;
    }
    final newBlock = Block(
      id: blockId,
      index: 0,
      date: update.dateKey,
      plannedStartTime: update.plannedStartTime,
      plannedEndTime: update.plannedEndTime,
      type: update.type,
      title: update.title,
      description: update.description,
      plannedDurationMinutes: update.plannedDurationMinutes,
      alertOffsetMinutes: update.alertOffsetMinutes,
      alertType: update.alertType,
      recurrenceType: update.recurrenceType,
      recurrenceDays: update.recurrenceDays,
      isEvent: update.isEvent,
      status: BlockStatus.notStarted,
    );
    final inserted = await insertPlannedBlocksWithConflictHandling(
      context: context,
      dateKey: update.dateKey,
      requestedBlocks: [newBlock],
    );
    if (!inserted) return;
    await app.ensureRecurringBlocksForDate(update.dateKey);
  }

  Future<void> _showNewBlockEditor({
    int? startMinutes,
    int? endMinutes,
    bool isEvent = false,
    BlockEditorMode mode = BlockEditorMode.planned,
  }) async {
    final draftBlock = _buildDraftBlock(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      isEvent: isEvent,
      title: mode == BlockEditorMode.log ? 'New Log' : null,
      description: mode == BlockEditorMode.log ? '' : null,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockEditorSheet(
        block: draftBlock,
        mode: mode,
        onSave: (update) => _saveNewBlock(update, draftBlock.id),
        onDelete: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _openAddTaskSheet({
    int? startMinutes,
    bool isEvent = false,
  }) {
    return _showNewBlockEditor(
      startMinutes: startMinutes,
      isEvent: isEvent,
    );
  }

  Future<void> _openAddLogSheet({
    int? startMinutes,
    int? endMinutes,
  }) {
    return _showNewBlockEditor(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      mode: BlockEditorMode.log,
    );
  }

  // ignore: unused_element
  void _completeBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.heavy();
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(
        status: BlockStatus.done,
        actualEndTime: DateTime.now().toIso8601String(),
      );
    }
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
    final tasks = block.tasks ?? [];
    for (final task in tasks) {
      app.completeStudyTask(task);
    }
    if (tasks.isEmpty && block.type == BlockType.revisionFa) {
      for (final page in block.relatedFaPages ?? []) {
        app.updateFAPageStatus(page, 'read');
      }
    }
    _setStateIfMounted(() => _completedBlockId = block.id);
  }

  // ignore: unused_element
  void _startBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final now = DateTime.now().toIso8601String();
    final blocks = List<Block>.from(plan.blocks ?? []);
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].status == BlockStatus.inProgress &&
          blocks[i].id != block.id) {
        blocks[i] = blocks[i].copyWith(status: BlockStatus.paused);
      }
    }
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(
        status: BlockStatus.inProgress,
        actualStartTime: blocks[idx].actualStartTime ?? now,
      );
    }
    final updatedPlan = plan.copyWith(blocks: blocks);
    app.upsertDayPlan(updatedPlan);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(block: block, plan: updatedPlan),
        ),
      );
    }
  }

  // ignore: unused_element
  void _skipBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    }
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final plan = app.getDayPlan(DateFormat('yyyy-MM-dd').format(_selectedDate));
    final realBlocks = List<Block>.from(plan?.blocks ?? []);
    final visibleBlocks = realBlocks
        .where((block) => !_isAutoPrayerRoutineBlock(block))
        .toList(growable: false);
    final totalBlocks = visibleBlocks.length;
    final completedBlocks =
        visibleBlocks.where((block) => block.status == BlockStatus.done).length;

    final displayBlocks = List<Block>.from(visibleBlocks);
    displayBlocks
        .sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));
    final timelineReminders =
        app.getTimelineReminderOccurrencesForDate(_dateKey);

    return AppScaffold(
      screenName: "Today's Plan",
      showHeader: false,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Compact Header ─────────────────────────
              // ── Tab Bar ────────────────────────────────
              const SizedBox(height: 8),
              _ThreeTabBar(controller: _tabCtrl),
              // ── Tab Views ──────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _TodayTimelineTab(
                      date: _selectedDate,
                      isToday: _isToday,
                      totalBlocks: totalBlocks,
                      completedBlocks: completedBlocks,
                      onPrev: _prevDay,
                      onNext: _nextDay,
                      onDateTap: _pickDate,
                      onStartDay: _openDaySession,
                      onStudySession: _openStudySession,
                      onTrackNow: _openTrackNow,
                      onQuickAdd: _isPastDate
                          ? ({int? startMinutes, bool isEvent = false}) =>
                              _openAddLogSheet(startMinutes: startMinutes)
                          : _openAddTaskSheet,
                      quickAddLabel: _isPastDate ? 'Add Log' : 'Add Task',
                      onSelectDate: (selected) {
                        unawaited(_openTimelineDate(selected));
                      },
                      dateKey: _dateKey,
                      blocks: displayBlocks,
                      reminders: timelineReminders,
                      onReminderTap: _openReminderFromTimeline,
                      onReminderToggle: _toggleReminderFromTimeline,
                    ),
                    RoutinesTab(dateKey: _dateKey),
                    _MoreTabView(
                      dateKey: _dateKey,
                      selectedTabIndex: _selectedMoreSubTabIndex,
                      highlightedReminderId: _highlightedReminderId,
                      onTabChanged: _handleMoreSubTabChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_completedBlockId != null)
            _CelebrationOverlay(
              onComplete: () =>
                  _setStateIfMounted(() => _completedBlockId = null),
            ),
        ],
      ),
    );
  }
}

// ── More Tab: inline Todo + Buying sub-tabs ────────────────────
class _TodayTimelineTab extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int totalBlocks;
  final int completedBlocks;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final VoidCallback onStartDay;
  final VoidCallback onStudySession;
  final VoidCallback onTrackNow;
  final TimelineAddTaskCallback onQuickAdd;
  final String quickAddLabel;
  final ValueChanged<DateTime> onSelectDate;
  final String dateKey;
  final List<Block> blocks;
  final List<ReminderOccurrence> reminders;
  final Future<void> Function(ReminderOccurrence occurrence) onReminderTap;
  final Future<void> Function(ReminderOccurrence occurrence, bool completed)
      onReminderToggle;

  const _TodayTimelineTab({
    required this.date,
    required this.isToday,
    required this.totalBlocks,
    required this.completedBlocks,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.onStartDay,
    required this.onStudySession,
    required this.onTrackNow,
    required this.onQuickAdd,
    required this.quickAddLabel,
    required this.onSelectDate,
    required this.dateKey,
    required this.blocks,
    required this.reminders,
    required this.onReminderTap,
    required this.onReminderToggle,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: _CompactHeader(
              date: date,
              isToday: isToday,
              totalBlocks: totalBlocks,
              completedBlocks: completedBlocks,
              onPrev: onPrev,
              onNext: onNext,
              onDateTap: onDateTap,
              onStartDay: onStartDay,
              onStudySession: onStudySession,
              onTrackNow: onTrackNow,
              onQuickAdd: () => onQuickAdd(),
              quickAddLabel: quickAddLabel,
              onSelectDate: onSelectDate,
            ),
          ),
        ];
      },
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: TimelineView(
          dateKey: dateKey,
          blocks: blocks,
          reminders: reminders,
          onAddTask: onQuickAdd,
          onOpenDate: onSelectDate,
          onReminderTap: onReminderTap,
          onReminderToggle: onReminderToggle,
        ),
      ),
    );
  }
}

class _MoreTabView extends StatefulWidget {
  final String dateKey;
  final int selectedTabIndex;
  final String? highlightedReminderId;
  final ValueChanged<int>? onTabChanged;

  const _MoreTabView({
    required this.dateKey,
    required this.selectedTabIndex,
    this.highlightedReminderId,
    this.onTabChanged,
  });

  @override
  State<_MoreTabView> createState() => _MoreTabViewState();
}

class _MoreTabViewState extends State<_MoreTabView>
    with SingleTickerProviderStateMixin {
  late TabController _subTabCtrl;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.selectedTabIndex,
    );
    _subTabCtrl.addListener(_handleSubTabChanged);
  }

  @override
  void didUpdateWidget(covariant _MoreTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_subTabCtrl.index != widget.selectedTabIndex) {
      _subTabCtrl.animateTo(widget.selectedTabIndex);
    }
  }

  void _handleSubTabChanged() {
    if (_subTabCtrl.indexIsChanging) return;
    widget.onTabChanged?.call(_subTabCtrl.index);
  }

  @override
  void dispose() {
    _subTabCtrl.removeListener(_handleSubTabChanged);
    _subTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _todayPlanAccent(context);
    final accentSoft = _todayPlanAccentSoft(context);
    return Column(
      children: [
        // Sub-tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: LiquidGlassCard(
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(18),
            child: TabBar(
              controller: _subTabCtrl,
              dividerColor: Colors.transparent,
              labelColor: accent,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.62),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              indicator: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentSoft.withValues(alpha: 0.22)),
              ),
              tabs: const [
                Tab(text: 'Reminder'),
                Tab(text: 'To-Do'),
                Tab(text: 'Buying'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              ReminderTab(
                dateKey: widget.dateKey,
                highlightedReminderId: widget.highlightedReminderId,
              ),
              TodoTab(dateKey: widget.dateKey),
              BuyingTab(dateKey: widget.dateKey),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Celebration Overlay ────────────────────────────────────────
class _CelebrationOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  const _CelebrationOverlay({this.onComplete});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    });
    _ctrl.forward();
    _particles = List.generate(
        24,
        (_) => _Particle(
              x: _rng.nextDouble(),
              y: _rng.nextDouble() * 0.3,
              vx: (_rng.nextDouble() - 0.5) * 0.6,
              vy: -0.5 - _rng.nextDouble() * 0.5,
              size: 4 + _rng.nextDouble() * 6,
            ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _todayPlanAccent(context);
    final accentSoft = _todayPlanAccentSoft(context);
    final particleColors = <Color>[
      accent,
      accentSoft,
      DashboardColors.primaryViolet,
      cs.onSurfaceVariant,
      theme.disabledColor,
      cs.primary.withValues(alpha: 0.7),
    ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return IgnorePointer(
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  opacity: t < 0.7 ? 1.0 : 1.0 - ((t - 0.7) / 0.3),
                  duration: Duration.zero,
                  child: AnimatedScale(
                    scale: t < 0.2 ? t / 0.2 : 1.0,
                    duration: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: cs.onPrimary, size: 24),
                          const SizedBox(width: 8),
                          Text('Block Complete! 🎉',
                              style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ..._particles.map((p) {
                final px = p.x + p.vx * t;
                final py = p.y + p.vy * t + 0.5 * t * t;
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final particleColor = particleColors[
                    ((p.size.round() + (p.x * 10).round()) %
                            particleColors.length)
                        .abs()];
                return Positioned(
                  left: px * MediaQuery.of(context).size.width,
                  top: py * MediaQuery.of(context).size.height + 200,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: particleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, vx, vy, size;
  const _Particle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size});
}

// ── Compact Header ─────────────────────────────────────────────
class _CompactHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int totalBlocks;
  final int completedBlocks;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final VoidCallback onStartDay;
  final VoidCallback onStudySession;
  final VoidCallback onTrackNow;
  final VoidCallback onQuickAdd;
  final String quickAddLabel;
  final ValueChanged<DateTime> onSelectDate;

  const _CompactHeader({
    required this.date,
    required this.isToday,
    required this.totalBlocks,
    required this.completedBlocks,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.onStartDay,
    required this.onStudySession,
    required this.onTrackNow,
    required this.onQuickAdd,
    required this.quickAddLabel,
    required this.onSelectDate,
  });

  List<DateTime> _buildWeekDates() {
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return List<DateTime>.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

  bool _isNightRoutine(Block block) {
    final title = block.title.toLowerCase();
    return title.contains('night') ||
        title.contains('sleep') ||
        title.contains('wind down') ||
        title.contains('bed');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final weekDates = _buildWeekDates();
    final theme = Theme.of(context);
    final accent = _todayPlanAccent(context);
    final onSurface = theme.colorScheme.onSurface;
    final progress = totalBlocks == 0 ? 0.0 : completedBlocks / totalBlocks;
    final dateLabel = isToday
        ? 'Today, ${DateFormat('d MMM').format(date)}'
        : DateFormat('EEE, d MMM').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: LiquidGlassCard(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _DateArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: onPrev,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onDateTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          dateLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _DateArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: onNext,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$completedBlocks / $totalBlocks done',
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    emoji: '🌅',
                    label: 'Start Day',
                    onTap: onStartDay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    emoji: '📚',
                    label: 'Study Session',
                    onTap: onStudySession,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    emoji: '📊',
                    label: 'Track Now',
                    onTap: onTrackNow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    emoji: '➕',
                    label: quickAddLabel,
                    onTap: onQuickAdd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final weekDate in weekDates)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final weekBlocks = (app
                                    .getDayPlan(
                                      DateFormat('yyyy-MM-dd').format(weekDate),
                                    )
                                    ?.blocks ??
                                const <Block>[])
                            .where(
                              (block) =>
                                  !block.id.startsWith('routine-prayer_'),
                            )
                            .toList(growable: false);

                        return _WeekDayColumn(
                          date: weekDate,
                          isSelected: AppDateUtils.isSameDay(weekDate, date),
                          hasBlocks: weekBlocks.isNotEmpty,
                          hasNightRoutine: weekBlocks.any(_isNightRoutine),
                          onTap: () => onSelectDate(weekDate),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasBlocks;
  final bool hasNightRoutine;
  final VoidCallback onTap;

  const _WeekDayColumn({
    required this.date,
    required this.isSelected,
    required this.hasBlocks,
    required this.hasNightRoutine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _todayPlanAccent(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? accent : onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                DateFormat('d').format(date),
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBlocks) _WeekIndicatorDot(color: accent),
                  if (hasBlocks && hasNightRoutine) const SizedBox(width: 3),
                  if (hasNightRoutine)
                    _WeekIndicatorDot(
                        color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekIndicatorDot extends StatelessWidget {
  final Color color;

  const _WeekIndicatorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _ThreeTabBar extends StatelessWidget {
  final TabController controller;
  const _ThreeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _todayPlanAccent(context);
    final accentSoft = _todayPlanAccentSoft(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(20),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: accent,
          unselectedLabelColor: onSurface.withValues(alpha: 0.58),
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          indicator: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentSoft.withValues(alpha: 0.24),
            ),
          ),
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Routines'),
            Tab(text: 'More'),
          ],
        ),
      ),
    );
  }
}

class _DateArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DateArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _todayPlanAccent(context);
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return LiquidGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
