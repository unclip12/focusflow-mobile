// =============================================================
// NotificationService — Comprehensive local notifications
// Channels: focus_timer | revision_due | streak_reminder | daily_summary
// =============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focusflow_mobile/app_router.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/reminder.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationIntentHandler = Future<bool> Function(
  NotificationIntent intent,
);

class NotificationIntentTarget {
  NotificationIntentTarget._();

  static const String route = 'route';
  static const String todayPlan = 'today_plan';
  static const String todayPlanBlock = 'today_plan_block';
  static const String daySession = 'day_session';
}

class NotificationIntentSource {
  NotificationIntentSource._();

  static const String plannedTaskReminder = 'planned_task_reminder';
  static const String reminder = 'reminder';
}

class NotificationIntent {
  final String targetType;
  final String? routeName;
  final String? dateKey;
  final String? blockId;
  final String? activityId;
  final String? routineId;
  final String? reminderId;
  final String? source;
  final bool openReminderTab;

  const NotificationIntent({
    required this.targetType,
    this.routeName,
    this.dateKey,
    this.blockId,
    this.activityId,
    this.routineId,
    this.reminderId,
    this.source,
    this.openReminderTab = false,
  });

  factory NotificationIntent.route(String routeName) {
    return NotificationIntent(
      targetType: NotificationIntentTarget.route,
      routeName: routeName,
    );
  }

  factory NotificationIntent.todayPlan({
    String? dateKey,
    String? activityId,
    String? routineId,
    String? reminderId,
    bool openReminderTab = false,
    String? source,
  }) {
    return NotificationIntent(
      targetType: NotificationIntentTarget.todayPlan,
      routeName: Routes.todaysPlan,
      dateKey: dateKey,
      activityId: activityId,
      routineId: routineId,
      reminderId: reminderId,
      source: source,
      openReminderTab: openReminderTab,
    );
  }

  factory NotificationIntent.todayPlanBlock({
    required String dateKey,
    required String blockId,
    String? source,
  }) {
    return NotificationIntent(
      targetType: NotificationIntentTarget.todayPlanBlock,
      routeName: Routes.todaysPlan,
      dateKey: dateKey,
      blockId: blockId,
      source: source,
    );
  }

  factory NotificationIntent.daySession({required String dateKey}) {
    return NotificationIntent(
      targetType: NotificationIntentTarget.daySession,
      routeName: Routes.todaysPlan,
      dateKey: dateKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      if (routeName != null) 'routeName': routeName,
      if (dateKey != null) 'dateKey': dateKey,
      if (blockId != null) 'blockId': blockId,
      if (activityId != null) 'activityId': activityId,
      if (routineId != null) 'routineId': routineId,
      if (reminderId != null) 'reminderId': reminderId,
      if (source != null) 'source': source,
      if (openReminderTab) 'openReminderTab': openReminderTab,
    };
  }

  String toPayload() => jsonEncode(toJson());

  factory NotificationIntent.fromJson(Map<String, dynamic> json) {
    return NotificationIntent(
      targetType:
          json['targetType'] as String? ?? NotificationIntentTarget.route,
      routeName: json['routeName'] as String?,
      dateKey: json['dateKey'] as String?,
      blockId: json['blockId'] as String?,
      activityId: json['activityId'] as String?,
      routineId: json['routineId'] as String?,
      reminderId: json['reminderId'] as String?,
      source: json['source'] as String?,
      openReminderTab: json['openReminderTab'] as bool? ?? false,
    );
  }

  static NotificationIntent? tryParse(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      return NotificationIntent.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

class TodayPlanLaunchRequest {
  final String? dateKey;
  final String? blockId;
  final String? activityId;
  final String? routineId;
  final String? reminderId;
  final bool openDaySession;
  final bool openReminderTab;

  const TodayPlanLaunchRequest({
    this.dateKey,
    this.blockId,
    this.activityId,
    this.routineId,
    this.reminderId,
    this.openDaySession = false,
    this.openReminderTab = false,
  });

  bool get opensRoutinesTab => routineId != null;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<TodayPlanLaunchRequest?> todayPlanLaunchNotifier =
      ValueNotifier<TodayPlanLaunchRequest?>(null);

  bool _initialised = false;
  NotificationIntent? _pendingIntent;
  NotificationIntentHandler? _intentHandler;

  // ── Notification IDs ──────────────────────────────────────────
  static const int _timerDoneId = 1001;
  static const int _dailyRevisionId = 2001;
  static const int _streakRiskId = 3001;
  static const int _morningSummaryId = 4001;

  // ── Channel IDs ───────────────────────────────────────────────
  static const String _chFocusTimer = 'focus_timer';
  static const String _chRevisionDue = 'revision_due';
  static const String _chStreakReminder = 'streak_reminder';
  static const String _chDailySummary = 'daily_summary';
  static const String _chStudySession = 'study_session';
  static const String _chRoutineReminder = 'routine_reminder';
  static const String _chTaskReminder = 'task_reminder';
  static const String _chReminder = 'reminder';

  // ── Android channels ──────────────────────────────────────────
  static const _timerChannel = AndroidNotificationChannel(
    _chFocusTimer,
    'Focus Timer',
    description: 'Alerts when a focus timer or session completes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _revisionChannel = AndroidNotificationChannel(
    _chRevisionDue,
    'Revision Reminders',
    description: 'Daily reminders for overdue and upcoming revisions',
    importance: Importance.high,
    playSound: true,
  );

  static const _streakChannel = AndroidNotificationChannel(
    _chStreakReminder,
    'Streak Alerts',
    description: 'Alerts when your study streak is at risk',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const _summaryChannel = AndroidNotificationChannel(
    _chDailySummary,
    'Daily Summary',
    description: 'Morning briefing on today\'s study plan',
    importance: Importance.defaultImportance,
  );

  static const _studySessionChannel = AndroidNotificationChannel(
    _chStudySession,
    'Study Sessions',
    description: 'Alerts when a planned study session is due',
    importance: Importance.high,
    playSound: true,
  );

  static const _routineReminderChannel = AndroidNotificationChannel(
    _chRoutineReminder,
    'Routine Reminders',
    description: 'Alerts when a routine reminder is due',
    importance: Importance.high,
    playSound: true,
  );

  static const _taskReminderChannel = AndroidNotificationChannel(
    _chTaskReminder,
    'Task Reminders',
    description: 'Alerts for scheduled task reminder rules',
    importance: Importance.high,
    playSound: true,
  );

  static const _reminderChannel = AndroidNotificationChannel(
    _chReminder,
    'Reminders',
    description: 'Alerts for standalone reminders',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialise the plugin and create all Android channels.
  Future<void> init() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _queueIntent(NotificationIntent.tryParse(
        launchDetails?.notificationResponse?.payload,
      ));
    }

    // Create Android channels
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_timerChannel);
    await androidPlugin?.createNotificationChannel(_revisionChannel);
    await androidPlugin?.createNotificationChannel(_streakChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);
    await androidPlugin?.createNotificationChannel(_studySessionChannel);
    await androidPlugin?.createNotificationChannel(_routineReminderChannel);
    await androidPlugin?.createNotificationChannel(_taskReminderChannel);
    await androidPlugin?.createNotificationChannel(_reminderChannel);

    _initialised = true;
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  void registerIntentHandler(NotificationIntentHandler handler) {
    _intentHandler = handler;
    unawaited(tryDispatchPendingIntent());
  }

  Future<bool> tryDispatchPendingIntent() async {
    final handler = _intentHandler;
    final intent = _pendingIntent;
    if (handler == null || intent == null) return false;

    final handled = await handler(intent);
    if (handled && identical(_pendingIntent, intent)) {
      _pendingIntent = null;
    }
    return handled;
  }

  void publishTodayPlanLaunchRequest(TodayPlanLaunchRequest request) {
    todayPlanLaunchNotifier.value = null;
    todayPlanLaunchNotifier.value = request;
  }

  void clearTodayPlanLaunchRequest(TodayPlanLaunchRequest request) {
    if (identical(todayPlanLaunchNotifier.value, request)) {
      todayPlanLaunchNotifier.value = null;
    }
  }

  void _queueIntent(NotificationIntent? intent) {
    if (intent == null) return;
    _pendingIntent = intent;
    unawaited(tryDispatchPendingIntent());
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _queueIntent(NotificationIntent.tryParse(response.payload));
  }

  int _routineNotificationId(String routineId) => routineId.hashCode;

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay? _parseRoutineTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _parseRoutineDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  tz.TZDateTime _nextDailyOccurrence(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeeklyOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    var daysAhead = (weekday - scheduled.weekday) % DateTime.daysPerWeek;
    if (daysAhead < 0) {
      daysAhead += DateTime.daysPerWeek;
    }
    scheduled = scheduled.add(Duration(days: daysAhead));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: DateTime.daysPerWeek));
    }
    return scheduled;
  }

  NotificationDetails _routineReminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _chRoutineReminder,
        'Routine Reminders',
        channelDescription: 'Alerts when a routine reminder is due',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails _taskReminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _chTaskReminder,
        'Task Reminders',
        channelDescription: 'Alerts for scheduled task reminder rules',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails _reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _chReminder,
        'Reminders',
        channelDescription: 'Alerts for standalone reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // FOCUS TIMER — show immediately when timer ends
  // ──────────────────────────────────────────────────────────────
  Future<void> showFocusTimerDone({
    required String activityName,
    String? dateKey,
  }) async {
    await _plugin.show(
      _timerDoneId,
      '🎉 Session Complete!',
      'Great job finishing: $activityName',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chFocusTimer,
          'Focus Timer',
          channelDescription: 'Alerts when a focus timer or session completes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            'You completed "$activityName". Keep the momentum going! 🚀',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: NotificationIntent.todayPlan(
        dateKey: dateKey ?? _dateKey(DateTime.now()),
      ).toPayload(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // REVISION DUE — scheduled daily at chosen time
  // ──────────────────────────────────────────────────────────────
  Future<void> scheduleDailyRevisionReminder({
    required int revisionCount,
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0),
  }) async {
    await _plugin.cancel(_dailyRevisionId);
    if (revisionCount == 0) return;

    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyRevisionId,
      '📚 Revisions Due',
      '$revisionCount revision${revisionCount == 1 ? '' : 's'} waiting for you today',
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chRevisionDue,
          'Revision Reminders',
          channelDescription:
              'Daily reminders for overdue and upcoming revisions',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: NotificationIntent.route(Routes.revision).toPayload(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // STREAK AT RISK — show immediately if streak is at risk
  // ──────────────────────────────────────────────────────────────
  Future<void> showStreakRisk({required int streakDays}) async {
    await _plugin.show(
      _streakRiskId,
      '🔥 Don\'t break your streak!',
      'You have a $streakDays-day streak — log some study time before midnight!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chStreakReminder,
          'Streak Alerts',
          channelDescription: 'Alerts when your study streak is at risk',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: NotificationIntent.todayPlan().toPayload(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // MORNING SUMMARY — scheduled daily at 8 AM
  // ──────────────────────────────────────────────────────────────
  Future<void> scheduleMorningSummary({
    int dueCount = 0,
    int pagesPlanned = 0,
  }) async {
    await _plugin.cancel(_morningSummaryId);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 8, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = dueCount > 0
        ? 'Good morning! $dueCount revisions due today. Stay consistent! 💪'
        : 'Good morning! No revisions due today. Great job staying on track!';

    await _plugin.zonedSchedule(
      _morningSummaryId,
      '🌅 FocusFlow Daily Briefing',
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chDailySummary,
          'Daily Summary',
          channelDescription: 'Morning briefing on today\'s study plan',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: NotificationIntent.todayPlan().toPayload(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHOW IMMEDIATE — generic helper for quick one-off toasts
  // ──────────────────────────────────────────────────────────────
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String channelId = _chDailySummary,
    String channelName = 'Daily Summary',
    NotificationIntent? intent,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: intent?.toPayload(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SCHEDULE AT — compatibility helper used by existing screens
  // (prayer reminders, pause/stop flow reminders)
  // ──────────────────────────────────────────────────────────────
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String channelId = _chDailySummary,
    String channelName = 'Daily Summary',
    NotificationIntent? intent,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: intent?.toPayload(),
    );
  }

  Future<void> scheduleStudySessionReminder({
    required int id,
    required String blockTitle,
    required DateTime when,
    required String dateKey,
    required String blockId,
  }) async {
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      'Study Session Starting',
      '$blockTitle is scheduled now',
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chStudySession,
          'Study Sessions',
          channelDescription: 'Alerts when a planned study session is due',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: NotificationIntent.todayPlanBlock(
        dateKey: dateKey,
        blockId: blockId,
        source: NotificationIntentSource.plannedTaskReminder,
      ).toPayload(),
    );
  }

  Future<void> syncPlannedTaskReminders({
    required Iterable<DayPlan> plans,
    required TimerReminderConfig config,
  }) async {
    await _cancelPendingBySource(NotificationIntentSource.plannedTaskReminder);

    final rules =
        config.taskReminderRules.where((rule) => rule.enabled).toList();
    if (rules.isEmpty) return;

    final now = DateTime.now();
    for (final plan in plans) {
      for (final block in plan.blocks ?? const <Block>[]) {
        if (!_isTimedBlock(block)) continue;

        final start = _dateTimeForBlockStart(block);
        if (start == null) continue;
        final end = _dateTimeForBlockEnd(block, start);

        for (final rule in rules) {
          if (block.type == BlockType.studySession &&
              rule.anchor == TaskReminderAnchor.atStart) {
            // Existing study-session scheduling already handles the exact start alert.
            continue;
          }

          final when = _dateTimeForReminderRule(
            rule: rule,
            start: start,
            end: end,
          );
          if (when == null || !when.isAfter(now)) continue;

          await _plugin.zonedSchedule(
            _plannedTaskReminderId(block, rule),
            _plannedTaskReminderTitle(block, rule),
            _plannedTaskReminderBody(block, rule),
            tz.TZDateTime.from(when, tz.local),
            _taskReminderDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: NotificationIntent.todayPlanBlock(
              dateKey: block.date,
              blockId: block.id,
              source: NotificationIntentSource.plannedTaskReminder,
            ).toPayload(),
          );
        }
      }
    }
  }

  Future<void> syncReminderNotifications({
    required Iterable<Reminder> reminders,
    required Iterable<ReminderOccurrenceState> occurrenceStates,
    required ReminderNotificationConfig config,
  }) async {
    await _cancelPendingBySource(NotificationIntentSource.reminder);

    if (!config.enabled) return;

    final now = DateTime.now();
    final horizonEnd = _today().add(const Duration(days: 365));
    final stateMap = <String, ReminderOccurrenceState>{
      for (final state in occurrenceStates) state.id: state,
    };

    for (final reminder in reminders) {
      if (reminder.archived || reminder.isAllDay) continue;
      final reminderTime = _parseRoutineTime(reminder.time);
      if (reminderTime == null) continue;

      final offsets = (reminder.useDefaultAlerts
              ? config.defaultAlertOffsets
              : reminder.customAlertOffsets)
          .where((offset) => offset >= 0)
          .toSet()
          .toList()
        ..sort();
      if (offsets.isEmpty) continue;

      for (DateTime cursor = _today();
          !cursor.isAfter(horizonEnd);
          cursor = cursor.add(const Duration(days: 1))) {
        if (!reminder.occursOn(cursor)) continue;

        final occurrenceKey = reminderOccurrenceKey(cursor);
        final state = stateMap['${reminder.id}_$occurrenceKey'];
        if (state?.completed == true) continue;

        final dueTime = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        for (final offset in offsets) {
          final scheduled = dueTime.subtract(Duration(minutes: offset));
          if (!scheduled.isAfter(now)) continue;

          await _plugin.zonedSchedule(
            _reminderNotificationId(reminder.id, occurrenceKey, offset),
            _reminderNotificationTitle(reminder, offset),
            _reminderNotificationBody(reminder, offset),
            tz.TZDateTime.from(scheduled, tz.local),
            _reminderDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: NotificationIntent.todayPlan(
              dateKey: occurrenceKey,
              reminderId: reminder.id,
              openReminderTab: true,
              source: NotificationIntentSource.reminder,
            ).toPayload(),
          );
        }
      }
    }
  }

  Future<void> scheduleRoutineReminder(Routine routine) async {
    final reminderTime = _parseRoutineTime(routine.reminderTime);
    if (reminderTime == null) {
      await cancelRoutineReminder(routine.id);
      return;
    }

    final recurrence = routine.recurrence ?? 'daily';
    final id = _routineNotificationId(routine.id);
    final details = _routineReminderDetails();
    final title = routine.name;
    final body = 'Time for your ${routine.name} routine';
    final payload = NotificationIntent.todayPlan(
      routineId: routine.id,
    ).toPayload();

    if (recurrence == 'weekly') {
      final weekday = routine.reminderWeekday;
      if (weekday == null || weekday < 1 || weekday > 7) {
        await cancelRoutineReminder(routine.id);
        return;
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextWeeklyOccurrence(reminderTime, weekday),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
      return;
    }

    final scheduled = _nextDailyOccurrence(reminderTime);
    if (recurrence == 'until_date') {
      final endDate = _parseRoutineDate(routine.recurrenceEndDate);
      final scheduledDate = DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day,
      );
      if (endDate == null ||
          _today().isAfter(endDate) ||
          scheduledDate.isAfter(endDate)) {
        await cancelRoutineReminder(routine.id);
        return;
      }
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelRoutineReminder(String routineId) async {
    await _plugin.cancel(_routineNotificationId(routineId));
  }

  Future<void> rescheduleAllRoutineReminders(List<Routine> routines) async {
    for (final routine in routines) {
      await cancelRoutineReminder(routine.id);
    }
    for (final routine in routines) {
      await scheduleRoutineReminder(routine);
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async => _plugin.cancelAll();

  /// Cancel by id.
  Future<void> cancel(int id) async => _plugin.cancel(id);

  bool _isTimedBlock(Block block) => block.plannedDurationMinutes > 0;

  DateTime? _dateTimeForBlockStart(Block block) {
    final date = DateTime.tryParse(block.date);
    final time = _parseRoutineTime(block.plannedStartTime);
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime? _dateTimeForBlockEnd(Block block, DateTime start) {
    if (block.plannedDurationMinutes <= 0) return null;

    final parsedEnd = _parseRoutineTime(block.plannedEndTime);
    if (parsedEnd != null) {
      var end = DateTime(
        start.year,
        start.month,
        start.day,
        parsedEnd.hour,
        parsedEnd.minute,
      );
      if (!end.isAfter(start)) {
        end = end.add(const Duration(days: 1));
      }
      final diff = end.difference(start).inMinutes;
      if (diff == block.plannedDurationMinutes) {
        return end;
      }
    }

    return start.add(Duration(minutes: block.plannedDurationMinutes));
  }

  DateTime? _dateTimeForReminderRule({
    required TaskReminderRule rule,
    required DateTime start,
    required DateTime? end,
  }) {
    switch (rule.anchor) {
      case TaskReminderAnchor.beforeStart:
        return start.subtract(Duration(minutes: rule.offsetMinutes));
      case TaskReminderAnchor.atStart:
        return start;
      case TaskReminderAnchor.beforeEnd:
        if (end == null) return null;
        return end.subtract(Duration(minutes: rule.offsetMinutes));
      case TaskReminderAnchor.atEnd:
        return end;
      default:
        return null;
    }
  }

  Future<void> _cancelPendingBySource(String source) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final intent = NotificationIntent.tryParse(request.payload);
      if (intent?.source == source) {
        await _plugin.cancel(request.id);
      }
    }
  }

  int _plannedTaskReminderId(Block block, TaskReminderRule rule) {
    final seed =
        '${block.date}|${block.id}|${rule.anchor}|${rule.offsetMinutes}';
    return seed.hashCode & 0x7fffffff;
  }

  int _reminderNotificationId(
    String reminderId,
    String occurrenceKey,
    int offsetMinutes,
  ) {
    final seed = '$reminderId|$occurrenceKey|$offsetMinutes';
    return seed.hashCode & 0x7fffffff;
  }

  String _plannedTaskReminderTitle(Block block, TaskReminderRule rule) {
    switch (rule.anchor) {
      case TaskReminderAnchor.beforeStart:
        return '${block.title} starts soon';
      case TaskReminderAnchor.atStart:
        return '${block.title} starts now';
      case TaskReminderAnchor.beforeEnd:
        return '${block.title} ends soon';
      case TaskReminderAnchor.atEnd:
        return '${block.title} just ended';
      default:
        return block.title;
    }
  }

  String _reminderNotificationTitle(Reminder reminder, int offsetMinutes) {
    if (offsetMinutes <= 0) {
      return reminder.title;
    }
    final minuteLabel =
        offsetMinutes == 1 ? '1 minute' : '$offsetMinutes minutes';
    return '${reminder.title} in $minuteLabel';
  }

  String _reminderNotificationBody(Reminder reminder, int offsetMinutes) {
    if (offsetMinutes <= 0) {
      return reminder.notes?.trim().isNotEmpty == true
          ? reminder.notes!.trim()
          : 'Reminder due now';
    }
    final minuteLabel =
        offsetMinutes == 1 ? '1 minute' : '$offsetMinutes minutes';
    return '${reminder.title} is due in $minuteLabel';
  }

  String _plannedTaskReminderBody(Block block, TaskReminderRule rule) {
    switch (rule.anchor) {
      case TaskReminderAnchor.beforeStart:
        return rule.offsetMinutes == 1
            ? 'Starts in 1 minute.'
            : 'Starts in ${rule.offsetMinutes} minutes.';
      case TaskReminderAnchor.atStart:
        return 'Open FocusFlow to start this task.';
      case TaskReminderAnchor.beforeEnd:
        return rule.offsetMinutes == 1
            ? 'Ends in 1 minute.'
            : 'Ends in ${rule.offsetMinutes} minutes.';
      case TaskReminderAnchor.atEnd:
        return 'This scheduled task has reached its end time.';
      default:
        return block.title;
    }
  }
}
