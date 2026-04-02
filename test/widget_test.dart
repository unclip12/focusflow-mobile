import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:focusflow_mobile/models/active_study_session.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/screens/settings/settings_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/routine_editor_sheet.dart';
import 'package:focusflow_mobile/screens/today_plan/routine_runner_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/study_flow_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/timeline_view.dart';
import 'package:focusflow_mobile/services/attachment_storage_service.dart';
import 'package:focusflow_mobile/services/backup_service.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');
const MethodChannel _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
const MethodChannel _backgroundServiceChannel = MethodChannel(
  'id.flutter/background_service/android/method',
  JSONMethodCodec(),
);

late Directory _testSandboxDirectory;
final List<String> _notificationMethodCalls = <String>[];
bool _backgroundServiceRunning = false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterBackgroundServiceAndroid.registerWith();
    GoogleFonts.config.allowRuntimeFetching = false;

    _testSandboxDirectory =
        await Directory.systemTemp.createTemp('focusflow_backup_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _pathProviderChannel,
      (call) async {
        switch (call.method) {
          case 'getTemporaryDirectory':
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getLibraryDirectory':
          case 'getDownloadsDirectory':
          case 'getExternalStorageDirectory':
            return _testSandboxDirectory.path;
          case 'getExternalCacheDirectories':
          case 'getExternalStorageDirectories':
            return <String>[_testSandboxDirectory.path];
          default:
            return _testSandboxDirectory.path;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _notificationsChannel,
      (call) async {
        _notificationMethodCalls.add(call.method);
        switch (call.method) {
          case 'initialize':
          case 'cancel':
          case 'cancelAll':
          case 'zonedSchedule':
          case 'show':
          case 'createNotificationChannel':
          case 'createNotificationChannelGroup':
            return true;
          case 'getNotificationAppLaunchDetails':
            return <String, dynamic>{'notificationLaunchedApp': false};
          case 'pendingNotificationRequests':
          case 'getActiveNotifications':
            return <Map<String, dynamic>>[];
          case 'requestNotificationsPermission':
            return true;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _backgroundServiceChannel,
      (call) async {
        switch (call.method) {
          case 'configure':
            _backgroundServiceRunning = false;
            return true;
          case 'start':
            _backgroundServiceRunning = true;
            return true;
          case 'isServiceRunning':
            return _backgroundServiceRunning;
          case 'sendData':
            final args =
                (call.arguments as Map?)?.cast<dynamic, dynamic>() ?? {};
            final method = args['method'];
            if (method == 'stopService') {
              _backgroundServiceRunning = false;
            }
            return true;
          default:
            return true;
        }
      },
    );

    await NotificationService.instance.init();
    await OfflineSuggestionCatalog.ensureInitialized();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_backgroundServiceChannel, null);
    if (await _testSandboxDirectory.exists()) {
      await _testSandboxDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _notificationMethodCalls.clear();
    _backgroundServiceRunning = false;
    await _resetDatabase();
    final focusFlowDir =
        Directory(p.join(_testSandboxDirectory.path, 'FocusFlow'));
    if (await focusFlowDir.exists()) {
      await focusFlowDir.delete(recursive: true);
    }
  });

  test('backup roundtrip preserves video lectures and dynamic tables',
      () async {
    final db = DatabaseService.instance;
    final sqlDb = await db.database;

    await db.insertRawRow(DatabaseService.tVideoLectures, {
      'id': 7,
      'subject': 'ENT',
      'title': 'ENT Day-1 Mission 200+',
      'duration_minutes': 312,
      'watched_minutes': 312,
      'watched': 1,
      'order_index': 1,
    });

    await sqlDb.execute('''
      CREATE TABLE IF NOT EXISTS custom_backup_probe (
        id TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await sqlDb.insert(
      'custom_backup_probe',
      {'id': 'probe-1', 'value': 'ok'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final backupData = await BackupService.buildBackupData();
    final tables = Map<String, dynamic>.from(backupData['tables'] as Map);

    expect(tables.containsKey(DatabaseService.tVideoLectures), isTrue);
    expect(tables.containsKey('custom_backup_probe'), isTrue);

    await db.clearAllData();
    expect(await db.getRawTableRows(DatabaseService.tVideoLectures), isEmpty);
    expect(await sqlDb.query('custom_backup_probe'), isEmpty);

    await BackupService.restoreFromBackupData(backupData);

    final restoredVideoRows =
        await db.getRawTableRows(DatabaseService.tVideoLectures);
    expect(restoredVideoRows, hasLength(1));
    expect(restoredVideoRows.single['watched'], 1);
    expect(restoredVideoRows.single['watched_minutes'], 312);

    final restoredProbeRows = await sqlDb.query('custom_backup_probe');
    expect(restoredProbeRows, hasLength(1));
    expect(restoredProbeRows.single['value'], 'ok');
  });

  test('restore clears transient prefs and skips malformed stable prefs',
      () async {
    SharedPreferences.setMockInitialValues({
      'general_task_names': <String>['stale'],
      'active_routine_run': '{"stale":true}',
      'lastActiveTab': 'revision',
      'backup_history': <String>['old-entry'],
    });

    final app = AppProvider();
    final backupData = <String, dynamic>{
      'backup_schema_version': BackupService.backupSchemaVersion,
      'app_version': BackupService.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'db_version': DatabaseService.dbVersion,
      'tables': <String, dynamic>{},
      'shared_preferences': <String, dynamic>{
        'faViewMode': 'timeline',
        'general_task_names': {
          '_type': 'StringList',
          '_value': <dynamic>['Task A', 7],
        },
        'fa_2025_seeded_v3': true,
        'backup_auto': true,
        'backup_frequency': 'Weekly',
        'active_routine_run': '{"should":"be-cleared"}',
        'lastActiveTab': 'todays-plan',
        'backup_history': <String>['should-not-restore'],
      },
    };

    await app.restoreFromBackup(backupData);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('faViewMode'), 'timeline');
    expect(prefs.getBool('fa_2025_seeded_v3'), isTrue);
    expect(prefs.getBool('backup_auto'), isTrue);
    expect(prefs.getString('backup_frequency'), 'Weekly');
    expect(prefs.getStringList('general_task_names'), isNull);
    expect(prefs.get('active_routine_run'), isNull);
    expect(prefs.get('lastActiveTab'), isNull);
    expect(prefs.get('backup_history'), isNull);
  });

  test('legacy note json upgrades attachment paths into structured attachments',
      () {
    final note = LibraryNote.fromJson({
      'id': 'legacy-note',
      'itemId': 'video-9',
      'itemType': 'VIDEO',
      'noteText': 'Legacy attachment payload',
      'tags': jsonEncode(['legacy']),
      'attachmentPaths': jsonEncode([
        r'C:\attachments\IMG_1001.png',
        'https://example.com/reference-video',
      ]),
      'createdAt': '2026-04-01T00:00:00.000',
    });

    expect(note.attachments, hasLength(2));
    expect(note.attachments.first.displayName, 'IMG_1001.png');
    expect(note.attachments.first.kind, LibraryNoteAttachmentKind.image);
    expect(note.attachments.last.displayName, 'reference-video');
    expect(note.attachments.last.kind, LibraryNoteAttachmentKind.link);
    expect(
      note.attachmentPaths,
      [
        r'C:\attachments\IMG_1001.png',
        'https://example.com/reference-video',
      ],
    );
  });

  test('structured note json preserves display names through serialization',
      () {
    final note = LibraryNote(
      id: 'note-structured',
      itemId: 'video-10',
      itemType: 'VIDEO',
      noteText: 'Structured attachment payload',
      attachments: [
        LibraryNoteAttachment(
          source: r'C:\attachments\scan.pdf',
          displayName: 'Pathoma handout',
          kind: LibraryNoteAttachmentKind.pdf,
        ),
        LibraryNoteAttachment(
          source: 'https://youtube.com/watch?v=abc123',
          displayName: 'YouTube explanation',
          kind: LibraryNoteAttachmentKind.link,
        ),
      ],
      createdAt: '2026-04-01T00:00:00.000',
    );

    final serialized = note.toJson();
    final decoded = LibraryNote.fromJson(serialized);

    expect(decoded.attachments, hasLength(2));
    expect(decoded.attachments.first.displayName, 'Pathoma handout');
    expect(decoded.attachments.first.kind, LibraryNoteAttachmentKind.pdf);
    expect(decoded.attachments.last.displayName, 'YouTube explanation');
    expect(decoded.attachments.last.kind, LibraryNoteAttachmentKind.link);
    expect(
      decoded.attachmentPaths,
      [
        r'C:\attachments\scan.pdf',
        'https://youtube.com/watch?v=abc123',
      ],
    );
  });

  test('restore preserves bundled note attachments and resyncs notifications',
      () async {
    final sourceAttachment =
        File(p.join(_testSandboxDirectory.path, 'source_attachment.txt'));
    await sourceAttachment.writeAsString('focusflow attachment');

    final note = LibraryNote(
      id: 'note-1',
      itemId: 'video-7',
      itemType: 'VIDEO',
      noteText: 'ENT note',
      attachments: [
        LibraryNoteAttachment(
          source: sourceAttachment.path,
          displayName: 'ENT source file',
          kind: LibraryNoteAttachmentKind.unknown,
        ),
        LibraryNoteAttachment(
          source: 'https://example.com/ent',
          displayName: 'ENT reference link',
          kind: LibraryNoteAttachmentKind.link,
        ),
      ],
      createdAt: DateTime.now().toIso8601String(),
    );
    final normalizedAttachments =
        await AttachmentStorageService.normalizeAttachments(note.attachments);
    await DatabaseService.instance.upsertLibraryNote(
      note.copyWith(attachments: normalizedAttachments).toJson(),
    );

    final savedNoteRows =
        await DatabaseService.instance.getLibraryNotes('video-7');
    final savedNote = LibraryNote.fromJson(savedNoteRows.single);
    final managedAttachment = savedNote.attachments.firstWhere(
      (attachment) => !AttachmentStorageService.isWebLink(attachment.source),
    );
    final managedAttachmentPath = managedAttachment.source;
    expect(managedAttachmentPath, isNot(sourceAttachment.path));
    expect(File(managedAttachmentPath).existsSync(), isTrue);
    expect(managedAttachment.displayName, 'ENT source file');

    await DatabaseService.instance
        .insertRawRow(DatabaseService.tVideoLectures, {
      'id': 7,
      'subject': 'ENT',
      'title': 'ENT Day-1 Mission 200+',
      'duration_minutes': 312,
      'watched_minutes': 312,
      'watched': 1,
      'order_index': 1,
    });
    await DatabaseService.instance.upsertRoutine(
      _buildRoutineFixture()
          .copyWith(reminderTime: '09:15', recurrence: 'daily')
          .toJson(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'active_routine_run',
      jsonEncode(
        ActiveRoutineRun(
          routineId: 'morning_routine',
          dateKey: '2026-04-01',
          startedAt: DateTime.parse('2026-04-01T07:00:00.000'),
          currentStepStartedAt: DateTime.parse('2026-04-01T07:05:00.000'),
          currentStepIndex: 0,
          checklistState: const <String, bool>{
            'step_1::take_toothbrush': true,
          },
        ).toJson(),
      ),
    );
    await DatabaseService.instance.upsertRevisionItem(
      RevisionItem(
        id: 'rev-1',
        type: 'VIDEO',
        source: 'VIDEO',
        pageNumber: '7',
        title: 'ENT Day-1 Mission 200+',
        parentTitle: 'ENT',
        nextRevisionAt:
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        currentRevisionIndex: 0,
      ).toJson(),
    );

    final backupData = await BackupService.buildBackupData();
    final backupFile = File(
        p.join(_testSandboxDirectory.path, 'focusflow_roundtrip.ffbackup'));
    await backupFile
        .writeAsBytes(await BackupService.buildBackupFileBytes(backupData));
    final decodedBackup = await BackupService.readBackupFile(backupFile.path);

    final attachmentsDir =
        await AttachmentStorageService.getAttachmentsDirectory();
    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }

    final restoringApp = AppProvider();
    await restoringApp.restoreFromBackup(decodedBackup);

    final restoredVideoRows = await DatabaseService.instance
        .getRawTableRows(DatabaseService.tVideoLectures);
    expect(restoredVideoRows, hasLength(1));
    expect(restoredVideoRows.single['watched'], 1);
    expect(restoredVideoRows.single['watched_minutes'], 312);

    final restoredRoutineRows = await DatabaseService.instance.getAllRoutines();
    expect(restoredRoutineRows, hasLength(1));
    final restoredRoutine = Routine.fromJson(restoredRoutineRows.single);
    expect(restoredRoutine.steps.first.emoji, '🪥');
    expect(restoredRoutine.steps.first.checklistItems.first.title,
        'Take toothbrush');

    final restoredNoteRows =
        await DatabaseService.instance.getLibraryNotes('video-7');
    final restoredNote = LibraryNote.fromJson(restoredNoteRows.single);
    final restoredAttachment = restoredNote.attachments.firstWhere(
      (attachment) => !AttachmentStorageService.isWebLink(attachment.source),
    );
    final restoredAttachmentPath = restoredAttachment.source;
    expect(restoredAttachmentPath, isNot(managedAttachmentPath));
    expect(File(restoredAttachmentPath).existsSync(), isTrue);
    expect(restoredAttachment.displayName, 'ENT source file');
    expect(
      restoredNote.attachments.any(
        (attachment) =>
            attachment.source == 'https://example.com/ent' &&
            attachment.displayName == 'ENT reference link',
      ),
      isTrue,
    );

    expect(_notificationMethodCalls, contains('cancelAll'));
    expect(
      _notificationMethodCalls
          .where((method) => method == 'zonedSchedule')
          .length,
      greaterThanOrEqualTo(2),
    );
    expect(
      prefs.getString('active_routine_run'),
      contains('take_toothbrush'),
    );
  });

  test('legacy json backups remain readable', () async {
    final legacyBackup = <String, dynamic>{
      'backup_schema_version': 1,
      'app_version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'db_version': DatabaseService.dbVersion,
      'tables': {
        DatabaseService.tVideoLectures: [
          {
            'id': 7,
            'subject': 'ENT',
            'title': 'ENT Day-1 Mission 200+',
            'duration_minutes': 312,
            'watched_minutes': 120,
            'watched': 0,
            'order_index': 1,
          },
        ],
      },
      'shared_preferences': {
        'backup_auto': true,
      },
    };

    final legacyFile =
        File(p.join(_testSandboxDirectory.path, 'legacy_backup.json'));
    await legacyFile.writeAsString(jsonEncode(legacyBackup));

    final decodedBackup = await BackupService.readBackupFile(legacyFile.path);
    expect(BackupService.validateBackupData(decodedBackup), isNull);
    final tables = Map<String, dynamic>.from(decodedBackup['tables'] as Map);
    expect(tables[DatabaseService.tVideoLectures], isA<List>());
  });

  test('startup guards recover from corrupted startup preferences', () async {
    SharedPreferences.setMockInitialValues({
      'general_task_names': Uint8List.fromList(<int>[1, 2, 3]),
      'faViewMode': Uint8List.fromList(<int>[4, 5, 6]),
      'active_routine_run': Uint8List.fromList(<int>[7, 8, 9]),
      'active_study_session': Uint8List.fromList(<int>[10, 11, 12]),
      'lastActiveTab': Uint8List.fromList(<int>[13, 14, 15]),
    });

    final app = AppProvider();
    await app.loadAll();

    expect(app.faViewMode, 'cards');
    expect(app.hasActiveStudySession, isFalse);

    final prefs = await SharedPreferences.getInstance();
    final lastTab =
        await BackupService.readStringPreferenceSafely(prefs, 'lastActiveTab') ??
            'dashboard';
    expect(prefs.get('general_task_names'), isNull);
    expect(prefs.get('faViewMode'), isNull);
    expect(prefs.get('active_routine_run'), isNull);
    expect(prefs.get('active_study_session'), isNull);
    expect(prefs.get('lastActiveTab'), isNull);
    expect(lastTab, 'dashboard');
  });

  testWidgets('settings reminder editor saves preset minute rules',
      (tester) async {
    final app = AppProvider();
    final settings = SettingsProvider();

    await tester.pumpWidget(
      _SettingsScreenHarness(
        app: app,
        settings: settings,
      ),
    );
    await _settleTestUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('task_reminder_add_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey<String>('task_reminder_add_button')));
    await _settleTestUi(tester);

    expect(find.byKey(const ValueKey<String>('task_reminder_editor_panel')),
        findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_minutes_field')),
    );
    await _settleTestUi(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_minutes_option_10')),
    );
    await _settleTestUi(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_save_button')),
    );
    await _settleTestUi(tester);

    expect(settings.timerReminders.taskReminderRules, hasLength(1));
    expect(settings.timerReminders.taskReminderRules.single.offsetMinutes, 10);
  });

  testWidgets('settings reminder editor accepts custom minute rules',
      (tester) async {
    final app = AppProvider();
    final settings = SettingsProvider();

    await tester.pumpWidget(
      _SettingsScreenHarness(
        app: app,
        settings: settings,
      ),
    );
    await _settleTestUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('task_reminder_add_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey<String>('task_reminder_add_button')));
    await _settleTestUi(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_minutes_field')),
    );
    await _settleTestUi(tester);

    await tester.enterText(
      find.byKey(const ValueKey<String>('task_reminder_custom_minutes_field')),
      '17',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey<String>('task_reminder_minutes_custom_button'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('task_reminder_minutes_custom_button'),
      ),
    );
    await _settleTestUi(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('task_reminder_save_button')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_save_button')),
    );
    await _settleTestUi(tester);

    expect(settings.timerReminders.taskReminderRules, hasLength(1));
    expect(settings.timerReminders.taskReminderRules.single.offsetMinutes, 17);
  });

  testWidgets('settings reminder editor shows existing custom-minute rules',
      (tester) async {
    final app = AppProvider();
    final settings = SettingsProvider();
    await settings.addTaskReminderRule(
      const TaskReminderRule(
        id: 'custom-rule',
        anchor: TaskReminderAnchor.beforeStart,
        offsetMinutes: 17,
        enabled: true,
      ),
    );

    await tester.pumpWidget(
      _SettingsScreenHarness(
        app: app,
        settings: settings,
      ),
    );
    await _settleTestUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('task_reminder_add_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey<String>('task_reminder_rule_custom-rule')),
      findsOneWidget,
    );
    expect(find.text('17 min before task start'), findsOneWidget);
  });

  testWidgets('settings reminder editor saves at-start rules with zero offset',
      (tester) async {
    final app = AppProvider();
    final settings = SettingsProvider();

    await tester.pumpWidget(
      _SettingsScreenHarness(
        app: app,
        settings: settings,
      ),
    );
    await _settleTestUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('task_reminder_add_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey<String>('task_reminder_add_button')));
    await _settleTestUi(tester);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('task_reminder_anchor_field'),
      ),
    );
    await _settleTestUi(tester);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('task_reminder_anchor_option_atStart'),
      ),
    );
    await _settleTestUi(tester);

    expect(find.byKey(const ValueKey<String>('task_reminder_minutes_field')),
        findsNothing);
    expect(
      find.byKey(const ValueKey<String>('task_reminder_custom_minutes_field')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('task_reminder_save_button')),
    );
    await _settleTestUi(tester);

    expect(settings.timerReminders.taskReminderRules, hasLength(1));
    expect(
      settings.timerReminders.taskReminderRules.single.anchor,
      TaskReminderAnchor.atStart,
    );
    expect(settings.timerReminders.taskReminderRules.single.offsetMinutes, 0);
  });

  testWidgets('planned insertion recommends the next free start time',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: '2026-03-31',
        blocks: [
          _block(
            id: 'morning',
            date: '2026-03-31',
            start: '01:00',
            end: '01:10',
            duration: 10,
            title: 'Morning Routine',
          ),
        ],
      ),
    ];

    final analysis = app.analyzePlannedInsertions(
      '2026-03-31',
      [
        _block(
          id: 'workout',
          date: '2026-03-31',
          start: '01:00',
          end: '01:30',
          duration: 30,
          title: 'Workout',
        ),
      ],
    );

    expect(analysis.recommendedStartMinutes, 70);
    expect(analysis.conflictingBlocks.map((block) => block.id),
        contains('morning'));
  });

  testWidgets('planned insertion allows exact boundary handoff',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: '2026-03-31',
        blocks: [
          _block(
            id: 'morning',
            date: '2026-03-31',
            start: '01:00',
            end: '01:10',
            duration: 10,
            title: 'Morning Routine',
          ),
        ],
      ),
    ];

    final analysis = app.analyzePlannedInsertions(
      '2026-03-31',
      [
        _block(
          id: 'workout',
          date: '2026-03-31',
          start: '01:10',
          end: '01:40',
          duration: 30,
          title: 'Workout',
        ),
      ],
    );

    expect(analysis.hasConflicts, isFalse);
    expect(analysis.recommendedStartMinutes, 70);
  });

  testWidgets(
      'long insertion analysis recommends the next contiguous free slot',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: '2026-04-01',
        blocks: [
          _block(
            id: 'eat',
            date: '2026-04-01',
            start: '02:00',
            end: '02:30',
            duration: 30,
            title: 'Eating',
          ),
        ],
      ),
    ];

    final analysis = app.analyzePlannedInsertions(
      '2026-04-01',
      [
        _block(
          id: 'study',
          date: '2026-04-01',
          start: '01:00',
          end: '04:00',
          duration: 180,
          title: 'Study Session',
        ),
      ],
    );

    expect(analysis.conflictingBlocks.map((block) => block.id), ['eat']);
    expect(analysis.recommendedStartMinutes, 150);
  });

  testWidgets('long insertion analysis accounts for multiple blockers',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: '2026-04-02',
        blocks: [
          _block(
            id: 'eat',
            date: '2026-04-02',
            start: '02:00',
            end: '02:30',
            duration: 30,
            title: 'Eating',
          ),
          _block(
            id: 'call',
            date: '2026-04-02',
            start: '03:00',
            end: '03:15',
            duration: 15,
            title: 'Call',
          ),
        ],
      ),
    ];

    final analysis = app.analyzePlannedInsertions(
      '2026-04-02',
      [
        _block(
          id: 'study',
          date: '2026-04-02',
          start: '01:00',
          end: '04:00',
          duration: 180,
          title: 'Study Session',
        ),
      ],
    );

    expect(
      analysis.conflictingBlocks.map((block) => block.id),
      ['eat', 'call'],
    );
    expect(analysis.recommendedStartMinutes, 195);
  });

  testWidgets(
      'manual move validation rejects conflicts and accepts clear timings',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: '2026-04-03',
        blocks: [
          _block(
            id: 'morning',
            date: '2026-04-03',
            start: '01:00',
            end: '01:10',
            duration: 10,
            title: 'Morning Routine',
          ),
        ],
      ),
    ];

    final newWorkout = _block(
      id: 'workout',
      date: '2026-04-03',
      start: '01:00',
      end: '01:30',
      duration: 30,
      title: 'Workout',
    );

    final invalidMove = app.validatePlannedBlockPlacements(
      '2026-04-03',
      [
        newWorkout,
        _block(
          id: 'morning',
          date: '2026-04-03',
          start: '01:15',
          end: '01:25',
          duration: 10,
          title: 'Morning Routine',
        ),
      ],
      excludedBlockIds: const {'morning'},
    );
    expect(invalidMove.isValid, isFalse);

    final validMove = app.validatePlannedBlockPlacements(
      '2026-04-03',
      [
        newWorkout,
        _block(
          id: 'morning',
          date: '2026-04-03',
          start: '01:30',
          end: '01:40',
          duration: 10,
          title: 'Morning Routine',
        ),
      ],
      excludedBlockIds: const {'morning'},
    );
    expect(validMove.isValid, isTrue);
  });

  test('video lecture toggle watched derives full completion state', () {
    const lecture = VideoLecture(
      id: 1,
      subject: 'Ophthalmology',
      title: 'Day-1 Mission 200+',
      durationMinutes: 120,
      watchedMinutes: 18,
      watched: false,
    );

    final nextState = AppProvider.deriveVideoLectureToggleState(lecture, true);

    expect(nextState.watched, isTrue);
    expect(nextState.watchedMinutes, lecture.durationMinutes);
    expect(nextState.shouldHaveRevision, isTrue);
  });

  test('video lecture toggle unwatched derives zero-progress reset state', () {
    const lecture = VideoLecture(
      id: 1,
      subject: 'Ophthalmology',
      title: 'Day-1 Mission 200+',
      durationMinutes: 120,
      watchedMinutes: 120,
      watched: true,
    );

    final nextState = AppProvider.deriveVideoLectureToggleState(lecture, false);

    expect(nextState.watched, isFalse);
    expect(nextState.watchedMinutes, 0);
    expect(nextState.shouldHaveRevision, isFalse);
  });

  test('video lecture progress auto-complete derives watched revision state',
      () {
    const lecture = VideoLecture(
      id: 1,
      subject: 'Ophthalmology',
      title: 'Day-1 Mission 200+',
      durationMinutes: 120,
      watchedMinutes: 60,
      watched: false,
    );

    final nextState = AppProvider.deriveVideoLectureProgressState(lecture, 120);

    expect(nextState.watched, isTrue);
    expect(nextState.watchedMinutes, lecture.durationMinutes);
    expect(nextState.shouldHaveRevision, isTrue);
  });

  test(
      'video lecture progress drop from complete to zero derives unwatch reset',
      () {
    const lecture = VideoLecture(
      id: 1,
      subject: 'Ophthalmology',
      title: 'Day-1 Mission 200+',
      durationMinutes: 120,
      watchedMinutes: 120,
      watched: true,
    );

    final nextState = AppProvider.deriveVideoLectureProgressState(lecture, 0);

    expect(nextState.watched, isFalse);
    expect(nextState.watchedMinutes, 0);
    expect(nextState.shouldHaveRevision, isFalse);
  });

  testWidgets('current day overnight block renders only the visible slice',
      (tester) async {
    final app = _buildAppProviderWithPlans();

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 30),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_sleep_carryOut')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('10:00 PM - 4:00 AM (next day)'), findsOneWidget);
    expect(find.text('Next day'), findsOneWidget);
    expect(find.text('Previous day'), findsNothing);

    final sleepSize = tester.getSize(
      find.byKey(const ValueKey('block_sleep_carryOut')),
    );

    expect(sleepSize.height, greaterThan(145));
    expect(sleepSize.height, lessThan(220));
  });

  testWidgets('next day shows carry-in slice from the previous day',
      (tester) async {
    final app = _buildAppProviderWithPlans();

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_sleep_carryIn')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('10:00 PM - 4:00 AM (previous day)'), findsOneWidget);
    expect(find.text('Previous day'), findsOneWidget);
    expect(find.text('Next day'), findsNothing);

    final carryInSize = tester.getSize(
      find.byKey(const ValueKey('block_sleep_carryIn')),
    );

    expect(carryInSize.height, greaterThan(290));
    expect(carryInSize.height, lessThan(340));
  });

  testWidgets('next day chip opens the continuation on the following day',
      (tester) async {
    final app = _buildAppProviderWithPlans();

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 30),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('selected_date_2026-03-30')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_sleep_carryOut')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next day'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('selected_date_2026-03-31')), findsOneWidget);
    expect(find.byKey(const ValueKey('block_sleep_carryIn')), findsOneWidget);
    expect(find.text('10:00 PM - 4:00 AM (previous day)'), findsOneWidget);
  });

  testWidgets('tracked ad-hoc block shows tracked badge and time range',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      DayPlan(
        date: '2026-03-31',
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: [
          Block(
            id: 'tracked_dev',
            index: 0,
            date: '2026-03-31',
            plannedStartTime: '06:40',
            plannedEndTime: '06:50',
            type: BlockType.other,
            title: 'Developing App',
            plannedDurationMinutes: 10,
            actualStartTime: '2026-03-31T06:40:00.000',
            actualEndTime: '2026-03-31T06:50:00.000',
            actualDurationMinutes: 10,
            status: BlockStatus.done,
            completionStatus: 'COMPLETED',
            isAdHocTrack: true,
          ),
        ],
        totalStudyMinutesPlanned: 0,
        totalBreakMinutes: 0,
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_tracked_dev_sameDay')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Developing App'), findsOneWidget);
    expect(find.text('Tracked'), findsOneWidget);
    expect(find.textContaining('6:40 AM - 6:50 AM'), findsOneWidget);
    expect(find.textContaining('Planned:'), findsNothing);
    expect(find.textContaining('Actual:'), findsNothing);
  });

  testWidgets('overlapping planned and tracked blocks both render',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      DayPlan(
        date: '2026-03-31',
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: [
          Block(
            id: 'study_block',
            index: 0,
            date: '2026-03-31',
            plannedStartTime: '12:00',
            plannedEndTime: '13:00',
            type: BlockType.studySession,
            title: 'Study Session',
            plannedDurationMinutes: 60,
            status: BlockStatus.notStarted,
          ),
          Block(
            id: 'tracked_overlap',
            index: 1,
            date: '2026-03-31',
            plannedStartTime: '12:15',
            plannedEndTime: '12:45',
            type: BlockType.other,
            title: 'Developing App',
            plannedDurationMinutes: 30,
            actualStartTime: '2026-03-31T12:15:00.000',
            actualEndTime: '2026-03-31T12:45:00.000',
            actualDurationMinutes: 30,
            status: BlockStatus.done,
            completionStatus: 'COMPLETED',
            isAdHocTrack: true,
          ),
        ],
        totalStudyMinutesPlanned: 60,
        totalBreakMinutes: 0,
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_study_block_sameDay')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('block_study_block_sameDay')),
        findsOneWidget);
    expect(find.text('Tasks are overlapping'), findsOneWidget);
  });

  testWidgets('full-day gap caps past log range at the current time',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = AppDateUtils.formatDate(today);
    final nowMinutes = now.hour * 60 + now.minute;
    final expectedGapLabel =
        '12:00 AM - ${_formatFullTimeForTest(nowMinutes)} • ${_formatCompactDurationForTest(nowMinutes)}';
    final futureStartMinutes = _roundUpToNextFiveMinutesForTest(nowMinutes);
    final expectedFutureText =
        'Use ${_formatCompactDurationForTest(math.max(0, (24 * 60) - futureStartMinutes))} from here onward';

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: const [],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: today,
        onAddTask: ({int? startMinutes, bool isEvent = false}) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What did you do here?'), findsOneWidget);
    expect(find.text(expectedGapLabel), findsOneWidget);
    expect(find.text('Add Log'), findsOneWidget);
    expect(_findRichTextContaining(expectedFutureText), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
  });

  testWidgets('past full-day gap shows log prompt without task CTA',
      (tester) async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final dateKey = AppDateUtils.formatDate(yesterday);

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: const [],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: yesterday,
        onAddTask: ({int? startMinutes, bool isEvent = false}) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What did you do here?'), findsOneWidget);
    expect(find.text('Add Log'), findsOneWidget);
    expect(find.text('Add Task'), findsNothing);
    expect(_findRichTextContaining('wisely...'), findsNothing);
  });

  testWidgets('future full-day gap shows planning CTA without log prompt',
      (tester) async {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dateKey = AppDateUtils.formatDate(tomorrow);

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: const [],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: tomorrow,
        onAddTask: ({int? startMinutes, bool isEvent = false}) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What did you do here?'), findsNothing);
    expect(find.text('Add Log'), findsNothing);
    expect(find.text('Add Task'), findsOneWidget);
    expect(_findRichTextContaining('wisely...'), findsOneWidget);
  });

  testWidgets('gap crossing now splits past log label from future task CTA',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = AppDateUtils.formatDate(today);
    final nowMinutes = now.hour * 60 + now.minute;
    final earlierEndMinutes = math.max(30, nowMinutes - 30);
    final earlierStartMinutes = math.max(0, earlierEndMinutes - 30);
    final laterStartMinutes = math.min((24 * 60) - 1, nowMinutes + 60);
    final laterEndMinutes = math.min(24 * 60, laterStartMinutes + 30);
    final expectedGapLabel =
        '${_formatFullTimeForTest(earlierEndMinutes)} - ${_formatFullTimeForTest(nowMinutes)} • ${_formatCompactDurationForTest(nowMinutes - earlierEndMinutes)}';
    final futureStartMinutes = _roundUpToNextFiveMinutesForTest(nowMinutes);
    final expectedFutureText =
        'Use ${_formatCompactDurationForTest(math.max(0, laterStartMinutes - futureStartMinutes))} from here onward';

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: [
          _block(
            id: 'earlier_block',
            date: dateKey,
            start: _formatMinutesForTest(earlierStartMinutes),
            end: _formatMinutesForTest(earlierEndMinutes),
            duration: earlierEndMinutes - earlierStartMinutes,
            title: 'Earlier Block',
          ),
          _block(
            id: 'later_block',
            date: dateKey,
            start: _formatMinutesForTest(laterStartMinutes),
            end: _formatMinutesForTest(laterEndMinutes),
            duration: laterEndMinutes - laterStartMinutes,
            title: 'Later Block',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: today,
        onAddTask: ({int? startMinutes, bool isEvent = false}) async {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(expectedGapLabel),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(expectedGapLabel), findsOneWidget);
    expect(_findRichTextContaining(expectedFutureText), findsOneWidget);
  });

  testWidgets('gap after extended actual end starts at the actual end time',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = AppDateUtils.formatDate(today);
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < 40) {
      expect(nowMinutes, lessThan(40));
      return;
    }

    final plannedStartMinutes = nowMinutes - 40;
    final plannedEndMinutes = nowMinutes - 30;
    final actualEndMinutes = nowMinutes - 10;
    final expectedGapLabel =
        '${_formatFullTimeForTest(actualEndMinutes)} - ${_formatFullTimeForTest(nowMinutes)} • ${_formatCompactDurationForTest(nowMinutes - actualEndMinutes)}';
    final unexpectedGapLabel =
        '${_formatFullTimeForTest(plannedEndMinutes)} - ${_formatFullTimeForTest(nowMinutes)} • ${_formatCompactDurationForTest(nowMinutes - plannedEndMinutes)}';

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: [
          Block(
            id: 'actual_end_extension',
            index: 0,
            date: dateKey,
            plannedStartTime: _formatMinutesForTest(plannedStartMinutes),
            plannedEndTime: _formatMinutesForTest(plannedEndMinutes),
            type: BlockType.studySession,
            title: 'Extended Actual End',
            plannedDurationMinutes: plannedEndMinutes - plannedStartMinutes,
            actualStartTime: DateTime(
              today.year,
              today.month,
              today.day,
              plannedStartMinutes ~/ 60,
              plannedStartMinutes % 60,
            ).toIso8601String(),
            actualEndTime: DateTime(
              today.year,
              today.month,
              today.day,
              actualEndMinutes ~/ 60,
              actualEndMinutes % 60,
            ).toIso8601String(),
            actualDurationMinutes: actualEndMinutes - plannedStartMinutes,
            status: BlockStatus.done,
            completionStatus: 'COMPLETED',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: today,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(expectedGapLabel),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(expectedGapLabel), findsOneWidget);
    expect(find.text(unexpectedGapLabel), findsNothing);
  });

  testWidgets('gap before early actual start ends at the actual start time',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = AppDateUtils.formatDate(today);
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < 50) {
      expect(nowMinutes, lessThan(50));
      return;
    }

    final previousStartMinutes = nowMinutes - 50;
    final previousEndMinutes = nowMinutes - 40;
    final actualStartMinutes = nowMinutes - 30;
    final plannedStartMinutes = nowMinutes - 20;
    final plannedEndMinutes = nowMinutes - 10;
    final expectedGapLabel =
        '${_formatFullTimeForTest(previousEndMinutes)} - ${_formatFullTimeForTest(actualStartMinutes)} • ${_formatCompactDurationForTest(actualStartMinutes - previousEndMinutes)}';
    final unexpectedGapLabel =
        '${_formatFullTimeForTest(previousEndMinutes)} - ${_formatFullTimeForTest(plannedStartMinutes)} • ${_formatCompactDurationForTest(plannedStartMinutes - previousEndMinutes)}';

    final app = AppProvider();
    app.dayPlans = [
      _buildDayPlan(
        date: dateKey,
        blocks: [
          _block(
            id: 'preceding_block',
            date: dateKey,
            start: _formatMinutesForTest(previousStartMinutes),
            end: _formatMinutesForTest(previousEndMinutes),
            duration: previousEndMinutes - previousStartMinutes,
            title: 'Preceding Block',
          ),
          Block(
            id: 'early_actual_start',
            index: 1,
            date: dateKey,
            plannedStartTime: _formatMinutesForTest(plannedStartMinutes),
            plannedEndTime: _formatMinutesForTest(plannedEndMinutes),
            type: BlockType.studySession,
            title: 'Early Actual Start',
            plannedDurationMinutes: plannedEndMinutes - plannedStartMinutes,
            actualStartTime: DateTime(
              today.year,
              today.month,
              today.day,
              actualStartMinutes ~/ 60,
              actualStartMinutes % 60,
            ).toIso8601String(),
            actualEndTime: DateTime(
              today.year,
              today.month,
              today.day,
              plannedEndMinutes ~/ 60,
              plannedEndMinutes % 60,
            ).toIso8601String(),
            actualDurationMinutes: plannedEndMinutes - actualStartMinutes,
            status: BlockStatus.done,
            completionStatus: 'COMPLETED',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: today,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(expectedGapLabel),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(expectedGapLabel), findsOneWidget);
    expect(find.text(unexpectedGapLabel), findsNothing);
  });

  testWidgets('planned block shows play control before starting',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      DayPlan(
        date: '2026-03-31',
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: [
          Block(
            id: 'startable_block',
            index: 0,
            date: '2026-03-31',
            plannedStartTime: '09:00',
            plannedEndTime: '10:00',
            type: BlockType.studySession,
            title: 'Morning Study',
            plannedDurationMinutes: 60,
            status: BlockStatus.notStarted,
          ),
        ],
        totalStudyMinutesPlanned: 60,
        totalBreakMinutes: 0,
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_startable_block_sameDay')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('in-progress and paused planned blocks show execution controls',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      DayPlan(
        date: '2026-03-31',
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: [
          Block(
            id: 'running_block',
            index: 0,
            date: '2026-03-31',
            plannedStartTime: '10:00',
            plannedEndTime: '11:00',
            type: BlockType.studySession,
            title: 'Running Study',
            plannedDurationMinutes: 60,
            actualStartTime: '2026-03-31T09:50:00.000',
            status: BlockStatus.inProgress,
          ),
          Block(
            id: 'paused_block',
            index: 1,
            date: '2026-03-31',
            plannedStartTime: '11:00',
            plannedEndTime: '12:00',
            type: BlockType.studySession,
            title: 'Paused Study',
            plannedDurationMinutes: 60,
            actualStartTime: '2026-03-31T10:40:00.000',
            status: BlockStatus.paused,
          ),
        ],
        totalStudyMinutesPlanned: 120,
        totalBreakMinutes: 0,
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_running_block_sameDay')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Stop'), findsNWidgets(2));
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets(
      'done block shows planned and actual time ranges when they differ',
      (tester) async {
    final app = AppProvider();
    app.dayPlans = [
      DayPlan(
        date: '2026-03-31',
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: [
          Block(
            id: 'actual_diff',
            index: 0,
            date: '2026-03-31',
            plannedStartTime: '12:00',
            plannedEndTime: '13:00',
            type: BlockType.studySession,
            title: 'Study Session',
            plannedDurationMinutes: 60,
            actualStartTime: '2026-03-31T11:30:00.000',
            actualEndTime: '2026-03-31T12:50:00.000',
            actualDurationMinutes: 80,
            status: BlockStatus.done,
            completionStatus: 'COMPLETED',
          ),
        ],
        totalStudyMinutesPlanned: 60,
        totalBreakMinutes: 0,
      ),
    ];

    await tester.pumpWidget(
      _TimelineHarness(
        app: app,
        initialDate: DateTime(2026, 3, 31),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('block_actual_diff_sameDay')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Planned: 12:00 PM - 1:00 PM'), findsOneWidget);
    expect(find.textContaining('Actual: 11:30 AM - 12:50 PM'), findsOneWidget);
  });

  testWidgets('routine run progress is persisted to shared preferences',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final routine = _buildRoutineFixture();
    final startedAt = DateTime.now().subtract(const Duration(seconds: 70));

    await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: '2026-03-31',
      now: startedAt,
    );
    await app.advanceActiveRoutineStep(
      routine: routine,
      skipped: false,
      now: startedAt.add(const Duration(seconds: 30)),
    );
    await app.setActiveRoutineChecklistItemChecked(
      stepId: 'step_1',
      itemId: 'take_toothbrush',
      checked: true,
    );

    final activeRun =
        app.getActiveRoutineRunForRoutine(routine.id, '2026-03-31');
    expect(activeRun, isNotNull);
    expect(activeRun!.currentStepIndex, 1);
    expect(activeRun.entries.length, 1);
    expect(activeRun.entries.first.durationSeconds, 30);

    final prefs = await SharedPreferences.getInstance();
    final rawRun = prefs.getString('active_routine_run');
    expect(rawRun, isNotNull);
    final decoded = ActiveRoutineRun.fromJson(
      Map<String, dynamic>.from(jsonDecode(rawRun!) as Map),
    );
    expect(decoded.currentStepIndex, 1);
    expect(decoded.entries.length, 1);
    expect(
      decoded.checklistState,
      containsPair('step_1::take_toothbrush', true),
    );
  });

  testWidgets(
      'routine editor auto-fills step emoji, duration, suggestions, and preserves manual overrides',
      (tester) async {
    final app = AppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: app,
        child: const MaterialApp(
          home: Scaffold(
            body: RoutineEditorSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Step'));
    await tester.pumpAndSettle();

    final stepTitleFinder = _findTextFieldWithLabel('Step title');
    final emojiFinder = _findTextFieldWithLabel('Emoji');
    final minutesFinder = _findTextFieldWithLabel('Estimated minutes');

    await tester.enterText(stepTitleFinder, 'Taking bath');
    await tester.pumpAndSettle();

    expect(_readTextFieldValue(tester, emojiFinder), '🛁');
    expect(_readTextFieldValue(tester, minutesFinder), '15');
    expect(find.text('Take clothes'), findsOneWidget);
    expect(find.text('Heat water'), findsOneWidget);

    await tester.enterText(emojiFinder, '🚿');
    await tester.pumpAndSettle();
    await tester.enterText(minutesFinder, '12');
    await tester.pumpAndSettle();

    await tester.enterText(stepTitleFinder, 'Taking bath slowly');
    await tester.pumpAndSettle();

    expect(_readTextFieldValue(tester, emojiFinder), '🚿');
    expect(_readTextFieldValue(tester, minutesFinder), '12');
  });

  testWidgets('routine runner reopens without resetting elapsed time',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final routine = _buildRoutineFixture();
    final startedAt = DateTime.now().subtract(const Duration(seconds: 70));

    await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: '2026-03-31',
      now: startedAt,
    );
    await app.setActiveRoutineChecklistItemChecked(
      stepId: 'step_1',
      itemId: 'take_toothbrush',
      checked: true,
    );

    await tester.pumpWidget(
      _RoutineRunnerHarness(
        app: app,
        routine: routine,
        dateKey: '2026-03-31',
      ),
    );
    await tester.pump();

    expect(find.text('Brush Teeth'), findsOneWidget);
    expect(find.text('01:10'), findsWidgets);
    expect(find.text('00:50'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      _RoutineRunnerHarness(
        app: app,
        routine: routine,
        dateKey: '2026-03-31',
      ),
    );
    await tester.pump();

    expect(find.text('Brush Teeth'), findsOneWidget);
    expect(find.text('01:10'), findsWidgets);
    expect(find.text('00:50'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isTrue,
    );
  });

  testWidgets('routine runner resumes the current step instead of restarting',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final routine = _buildRoutineFixture();
    final startedAt = DateTime.now().subtract(const Duration(seconds: 70));
    final secondStepStartedAt =
        DateTime.now().subtract(const Duration(seconds: 40));

    await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: '2026-03-31',
      now: startedAt,
    );
    await app.advanceActiveRoutineStep(
      routine: routine,
      skipped: false,
      now: secondStepStartedAt,
    );

    await tester.pumpWidget(
      _RoutineRunnerHarness(
        app: app,
        routine: routine,
        dateKey: '2026-03-31',
      ),
    );
    await tester.pump();

    expect(find.text('Washroom'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('00:40'), findsWidgets);
  });

  testWidgets(
      'cancelling a routine clears active state and restart begins fresh',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final routine = _buildRoutineFixture();
    final startedAt = DateTime.now().subtract(const Duration(seconds: 70));

    await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: '2026-03-31',
      now: startedAt,
    );
    await app.setActiveRoutineChecklistItemChecked(
      stepId: 'step_1',
      itemId: 'take_toothbrush',
      checked: true,
    );
    await app.cancelActiveRoutineRun();

    expect(app.getActiveRoutineRun(), isNull);

    await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: '2026-03-31',
      now: DateTime.now(),
    );

    await tester.pumpWidget(
      _RoutineRunnerHarness(
        app: app,
        routine: routine,
        dateKey: '2026-03-31',
      ),
    );
    await tester.pump();

    expect(find.text('Brush Teeth'), findsOneWidget);
    expect(find.text('00:00'), findsWidgets);
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isFalse,
    );
  });

  testWidgets(
      'study flow shows planned summary, studied total, and remaining time',
      (tester) async {
    final app = _buildStudyFlowAppProvider();

    await tester.pumpWidget(
      _StudyFlowHarness(
        app: app,
        dateKey: '2026-04-01',
        blockId: 'study_block',
        sessionTitle: 'ENT Day-2 Mission 200+',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session Summary'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('10:00'), findsWidgets);
    expect(find.text('10:00 AM - 10:10 AM'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('session_footer_remaining')),
        matching: find.text('50:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('study flow pause and resume updates log rows', (tester) async {
    final app = _buildStudyFlowAppProvider();

    await tester.pumpWidget(
      _StudyFlowHarness(
        app: app,
        dateKey: '2026-04-01',
        blockId: 'study_block',
        sessionTitle: 'ENT Day-2 Mission 200+',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pause'), findsOneWidget);
    expect(app.getActiveStudySession()!.interruptions, isEmpty);

    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
    expect(app.getActiveStudySession()!.interruptions.length, 1);
    expect(app.getActiveStudySession()!.interruptions.single.reason, 'Paused');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('session_footer_studied')),
        matching: find.text('10:00'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Pause'), findsOneWidget);
    expect(app.getActiveStudySession()!.segments.length, 2);
    expect(app.getActiveStudySession()!.interruptions.single.end, isNotNull);
  });

  testWidgets('study flow subtopics section expands and collapses',
      (tester) async {
    final app = _buildStudyFlowAppProvider(
      subtopics: const [
        FASubtopic(id: 1, pageNum: 42, name: 'Nasal cavity'),
        FASubtopic(id: 2, pageNum: 42, name: 'Paranasal sinus'),
      ],
    );

    await tester.pumpWidget(
      _StudyFlowHarness(
        app: app,
        dateKey: '2026-04-01',
        blockId: 'study_block',
        sessionTitle: 'ENT Day-2 Mission 200+',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('study_flow_subtopics_section')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('study_flow_subtopics_section')),
        findsOneWidget);
    expect(find.text('Nasal cavity'), findsNothing);

    await tester.tap(find.text('Subtopics'));
    await tester.pumpAndSettle();

    expect(find.text('Nasal cavity'), findsOneWidget);
    expect(find.text('Paranasal sinus'), findsOneWidget);

    await tester.tap(find.text('Subtopics'));
    await tester.pumpAndSettle();

    expect(find.text('Nasal cavity'), findsNothing);
  });
}

AppProvider _buildAppProviderWithPlans() {
  final app = AppProvider();
  app.dayPlans = [
    DayPlan(
      date: '2026-03-30',
      faPages: const [],
      faPagesCount: 0,
      videos: const [],
      notesFromUser: '',
      notesFromAI: '',
      attachments: const [],
      breaks: const [],
      blocks: [
        Block(
          id: 'sleep',
          index: 0,
          date: '2026-03-30',
          plannedStartTime: '22:00',
          plannedEndTime: '04:00',
          type: BlockType.other,
          title: 'Sleep',
          plannedDurationMinutes: 360,
          isEvent: false,
          status: BlockStatus.notStarted,
        ),
      ],
      totalStudyMinutesPlanned: 360,
      totalBreakMinutes: 0,
    ),
    DayPlan(
      date: '2026-03-31',
      faPages: const [],
      faPagesCount: 0,
      videos: const [],
      notesFromUser: '',
      notesFromAI: '',
      attachments: const [],
      breaks: const [],
      blocks: const [],
      totalStudyMinutesPlanned: 0,
      totalBreakMinutes: 0,
    ),
  ];
  return app;
}

DayPlan _buildDayPlan({
  required String date,
  required List<Block> blocks,
}) {
  final normalizedBlocks = List<Block>.generate(
    blocks.length,
    (index) => blocks[index].copyWith(index: index),
  );
  return DayPlan(
    date: date,
    faPages: const [],
    faPagesCount: 0,
    videos: const [],
    notesFromUser: '',
    notesFromAI: '',
    attachments: const [],
    breaks: const [],
    blocks: normalizedBlocks,
    totalStudyMinutesPlanned: normalizedBlocks
        .where((block) => block.type != BlockType.breakBlock)
        .fold<int>(0, (sum, block) => sum + block.plannedDurationMinutes),
    totalBreakMinutes: normalizedBlocks
        .where((block) => block.type == BlockType.breakBlock)
        .fold<int>(0, (sum, block) => sum + block.plannedDurationMinutes),
  );
}

Block _block({
  required String id,
  required String date,
  required String start,
  required String end,
  required int duration,
  required String title,
  BlockType type = BlockType.other,
}) {
  return Block(
    id: id,
    index: 0,
    date: date,
    plannedStartTime: start,
    plannedEndTime: end,
    type: type,
    title: title,
    plannedDurationMinutes: duration,
    status: BlockStatus.notStarted,
  );
}

String _formatMinutesForTest(int minutes) {
  final safeMinutes = minutes.clamp(0, (24 * 60) - 1);
  final hour = safeMinutes ~/ 60;
  final minute = safeMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _formatFullTimeForTest(int minutes) {
  final safeMinutes = minutes.clamp(0, (24 * 60) - 1);
  final hour24 = safeMinutes ~/ 60;
  final minute = safeMinutes % 60;
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
}

String _formatCompactDurationForTest(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours > 0 && remainingMinutes > 0) {
    return '${hours}h ${remainingMinutes}m';
  }
  if (hours > 0) return '${hours}h';
  return '${remainingMinutes}m';
}

int _roundUpToNextFiveMinutesForTest(int minutes) {
  final remainder = minutes % 5;
  if (remainder == 0) return minutes;
  return math.min(24 * 60, minutes + (5 - remainder));
}

Finder _findRichTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
  );
}

Finder _findTextFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

String _readTextFieldValue(WidgetTester tester, Finder finder) {
  return tester.widget<TextField>(finder).controller?.text ?? '';
}

Routine _buildRoutineFixture() {
  return Routine(
    id: 'morning_routine',
    name: 'Morning Routine',
    icon: 'R',
    color: 0xFF2563EB,
    steps: const [
      RoutineStep(
        id: 'step_1',
        title: 'Brush Teeth',
        emoji: '🪥',
        estimatedMinutes: 2,
        checklistItems: [
          RoutineChecklistItem(
            id: 'take_toothbrush',
            title: 'Take toothbrush',
          ),
        ],
        sortOrder: 0,
      ),
      RoutineStep(
        id: 'step_2',
        title: 'Washroom',
        emoji: '🚿',
        estimatedMinutes: 5,
        sortOrder: 1,
      ),
    ],
    createdAt: '2026-03-31T00:00:00.000',
  );
}

Future<void> _resetDatabase() async {
  await DatabaseService.instance.close();
  final dbPath = await getDatabasesPath();
  final dbFilePath = p.join(dbPath, 'focusflow.db');
  await deleteDatabase(dbFilePath);

  for (final suffix in ['-wal', '-shm']) {
    final sidecar = File('$dbFilePath$suffix');
    if (await sidecar.exists()) {
      await sidecar.delete();
    }
  }
}

_TestStudyFlowAppProvider _buildStudyFlowAppProvider({
  List<FASubtopic> subtopics = const [],
}) {
  final dayPlan = _buildDayPlan(
    date: '2026-04-01',
    blocks: [
      Block(
        id: 'study_block',
        index: 0,
        date: '2026-04-01',
        plannedStartTime: '10:00',
        plannedEndTime: '11:00',
        type: BlockType.studySession,
        title: 'ENT Day-2 Mission 200+',
        plannedDurationMinutes: 60,
        actualStartTime: '2026-04-01T10:00:00.000',
        status: BlockStatus.inProgress,
        segments: const [
          BlockSegment(
            start: '2026-04-01T10:00:00.000',
            end: '2026-04-01T10:10:00.000',
          ),
        ],
      ),
    ],
  );

  final activeSession = ActiveStudySession(
    sessionId: 'study-session-1',
    kind: ActiveStudySessionKind.studyFlow,
    dateKey: '2026-04-01',
    title: 'ENT Day-2 Mission 200+',
    blockId: 'study_block',
    startedAt: '2026-04-01T10:00:00.000',
    currentPage: 42,
    targetPages: 1,
    currentTaskElapsedSeconds: 600,
    segments: const [
      BlockSegment(
        start: '2026-04-01T10:00:00.000',
        end: '2026-04-01T10:10:00.000',
      ),
    ],
    interruptions: const [],
  );

  return _TestStudyFlowAppProvider(
    activeSession: activeSession,
    dayPlan: dayPlan,
    subtopics: subtopics,
    totalElapsedSeconds: 600,
    taskElapsedSeconds: 600,
  );
}

Future<void> _settleTestUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

class _TimelineHarness extends StatefulWidget {
  final AppProvider app;
  final DateTime initialDate;
  final TimelineAddTaskCallback? onAddTask;

  const _TimelineHarness({
    required this.app,
    required this.initialDate,
    this.onAddTask,
  });

  @override
  State<_TimelineHarness> createState() => _TimelineHarnessState();
}

class _TimelineHarnessState extends State<_TimelineHarness> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = AppDateUtils.formatDate(_selectedDate);
    final blocks = widget.app.getDayPlan(dateKey)?.blocks ?? const <Block>[];

    return ChangeNotifierProvider<AppProvider>.value(
      value: widget.app,
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text(
                dateKey,
                key: ValueKey('selected_date_$dateKey'),
              ),
              Expanded(
                child: TimelineView(
                  dateKey: dateKey,
                  blocks: blocks,
                  reminders: const [],
                  onAddTask: widget.onAddTask,
                  onOpenDate: (date) {
                    setState(
                      () => _selectedDate =
                          DateTime(date.year, date.month, date.day),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineRunnerHarness extends StatelessWidget {
  final AppProvider app;
  final Routine routine;
  final String dateKey;

  const _RoutineRunnerHarness({
    required this.app,
    required this.routine,
    required this.dateKey,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: _TestSettingsProvider(),
        ),
      ],
      child: MaterialApp(
        home: RoutineRunnerScreen(
          routine: routine,
          dateKey: dateKey,
        ),
      ),
    );
  }
}

class _StudyFlowHarness extends StatelessWidget {
  final AppProvider app;
  final String dateKey;
  final String? blockId;
  final String? sessionTitle;

  const _StudyFlowHarness({
    required this.app,
    required this.dateKey,
    this.blockId,
    this.sessionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: _TestSettingsProvider(),
        ),
      ],
      child: MaterialApp(
        home: StudyFlowScreen(
          dateKey: dateKey,
          blockId: blockId,
          sessionTitle: sessionTitle,
        ),
      ),
    );
  }
}

class _SettingsScreenHarness extends StatelessWidget {
  final AppProvider app;
  final SettingsProvider settings;

  const _SettingsScreenHarness({
    required this.app,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }
}

class _TestSettingsProvider extends SettingsProvider {
  @override
  int get dailyFAGoal => 10;

  @override
  Future<void> ensureStudyPlanStartDate() async {}
}

class _TestStudyFlowAppProvider extends AppProvider {
  ActiveStudySession? _session;
  final int totalElapsedSeconds;
  final int taskElapsedSeconds;

  _TestStudyFlowAppProvider({
    required ActiveStudySession activeSession,
    required DayPlan dayPlan,
    required List<FASubtopic> subtopics,
    required this.totalElapsedSeconds,
    required this.taskElapsedSeconds,
  }) : _session = activeSession {
    dayPlans = [dayPlan];
    faSubtopics = List<FASubtopic>.from(subtopics);
  }

  @override
  ActiveStudySession? getActiveStudySession() => _session;

  @override
  int get activeStudySessionElapsedSeconds => totalElapsedSeconds;

  @override
  int activeStudySessionTaskElapsedSeconds([DateTime? now]) =>
      taskElapsedSeconds;

  @override
  Future<void> pauseActiveStudySession() async {
    final session = _session;
    if (session == null || session.isPaused) {
      return;
    }

    final pausedAt = DateTime.parse('2026-04-01T10:10:00.000');
    _session = session.copyWith(
      isPaused: true,
      currentTaskRunStartedAt: null,
      segments: _closeSegments(session.segments, pausedAt),
      interruptions: [
        ...session.interruptions,
        BlockInterruption(
          start: pausedAt.toIso8601String(),
          reason: 'Paused',
        ),
      ],
    );
    notifyListeners();
  }

  @override
  Future<void> resumeActiveStudySession() async {
    final session = _session;
    if (session == null || !session.isPaused) {
      return;
    }

    final resumedAt = DateTime.parse('2026-04-01T10:15:00.000');
    _session = session.copyWith(
      isPaused: false,
      currentTaskRunStartedAt: resumedAt.toIso8601String(),
      segments: [
        ...session.segments,
        BlockSegment(start: resumedAt.toIso8601String()),
      ],
      interruptions: _closeInterruptions(session.interruptions, resumedAt),
    );
    notifyListeners();
  }

  @override
  Future<void> markSubtopicRead(int subtopicId) async {
    final index =
        faSubtopics.indexWhere((subtopic) => subtopic.id == subtopicId);
    if (index < 0) {
      return;
    }
    faSubtopics[index] = faSubtopics[index].copyWith(status: 'read');
    notifyListeners();
  }

  @override
  Future<void> markSubtopicsRead(List<int> subtopicIds) async {
    for (final subtopicId in subtopicIds) {
      final index =
          faSubtopics.indexWhere((subtopic) => subtopic.id == subtopicId);
      if (index >= 0) {
        faSubtopics[index] = faSubtopics[index].copyWith(status: 'read');
      }
    }
    notifyListeners();
  }

  List<BlockSegment> _closeSegments(
    List<BlockSegment> segments,
    DateTime endedAt,
  ) {
    if (segments.isEmpty) {
      return segments;
    }
    final updated = List<BlockSegment>.from(segments);
    final last = updated.last;
    if (last.end != null && last.end!.isNotEmpty) {
      return updated;
    }
    updated[updated.length - 1] = BlockSegment(
      start: last.start,
      end: endedAt.toIso8601String(),
    );
    return updated;
  }

  List<BlockInterruption> _closeInterruptions(
    List<BlockInterruption> interruptions,
    DateTime endedAt,
  ) {
    if (interruptions.isEmpty) {
      return interruptions;
    }
    final updated = List<BlockInterruption>.from(interruptions);
    final last = updated.last;
    if (last.end != null && last.end!.isNotEmpty) {
      return updated;
    }
    updated[updated.length - 1] = BlockInterruption(
      start: last.start,
      end: endedAt.toIso8601String(),
      reason: last.reason,
    );
    return updated;
  }
}
