// =============================================================
// NotificationService — Comprehensive local notifications
// Channels: focus_timer | revision_due | streak_reminder | daily_summary
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Notification IDs ──────────────────────────────────────────
  static const int _timerDoneId        = 1001;
  static const int _dailyRevisionId    = 2001;
  static const int _streakRiskId       = 3001;
  static const int _morningSummaryId   = 4001;

  // ── Channel IDs ───────────────────────────────────────────────
  static const String _chFocusTimer    = 'focus_timer';
  static const String _chRevisionDue   = 'revision_due';
  static const String _chStreakReminder = 'streak_reminder';
  static const String _chDailySummary  = 'daily_summary';
  static const String _chStudySession  = 'study_session';

  // ── Android channels ─────────────────────────────────────────
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

  /// Initialise the plugin and create all Android channels.
  Future<void> init() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Create Android channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_timerChannel);
    await androidPlugin?.createNotificationChannel(_revisionChannel);
    await androidPlugin?.createNotificationChannel(_streakChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);
    await androidPlugin?.createNotificationChannel(_studySessionChannel);

    _initialised = true;
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  // ─────────────────────────────────────────────────────────────
  // FOCUS TIMER — show immediately when timer ends
  // ─────────────────────────────────────────────────────────────
  Future<void> showFocusTimerDone({required String activityName}) async {
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REVISION DUE — scheduled daily at chosen time
  // ─────────────────────────────────────────────────────────────
  Future<void> scheduleDailyRevisionReminder({
    required int revisionCount,
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0),
  }) async {
    await _plugin.cancel(_dailyRevisionId);
    if (revisionCount == 0) return;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
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
          channelDescription: 'Daily reminders for overdue and upcoming revisions',
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
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STREAK AT RISK — show immediately if streak is at risk
  // ─────────────────────────────────────────────────────────────
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MORNING SUMMARY — scheduled daily at 8 AM
  // ─────────────────────────────────────────────────────────────
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
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW IMMEDIATE — generic helper for quick one-off toasts
  // ─────────────────────────────────────────────────────────────
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String channelId = _chDailySummary,
    String channelName = 'Daily Summary',
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SCHEDULE AT — compatibility helper used by existing screens
  // (prayer reminders, pause/stop flow reminders)
  // ─────────────────────────────────────────────────────────────
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String channelId = _chDailySummary,
    String channelName = 'Daily Summary',
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
    );
  }

  Future<void> scheduleStudySessionReminder({
    required int id,
    required String blockTitle,
    required DateTime when,
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
    );
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async => _plugin.cancelAll();

  /// Cancel by id.
  Future<void> cancel(int id) async => _plugin.cancel(id);
}
