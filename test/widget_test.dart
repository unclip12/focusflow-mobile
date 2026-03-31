import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/today_plan/routine_runner_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/timeline_view.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(analysis.conflictingBlocks.map((block) => block.id), contains('morning'));
  });

  testWidgets('planned insertion allows exact boundary handoff', (tester) async {
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

  testWidgets('long insertion analysis recommends the next contiguous free slot',
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

  testWidgets('manual move validation rejects conflicts and accepts clear timings',
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

    expect(find.byKey(const ValueKey('selected_date_2026-03-30')),
        findsOneWidget);

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

    expect(find.byKey(const ValueKey('selected_date_2026-03-31')),
        findsOneWidget);
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
    expect(find.text('6:40 AM - 6:50 AM'), findsOneWidget);
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

    expect(find.byKey(const ValueKey('block_study_block_sameDay')), findsOneWidget);
    expect(find.text('Tasks are overlapping'), findsOneWidget);
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

  testWidgets('done block shows planned and actual time ranges when they differ',
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

    expect(find.text('Planned: 12:00 PM - 1:00 PM'), findsOneWidget);
    expect(find.text('Actual: 11:30 AM - 12:50 PM'), findsOneWidget);
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

    final activeRun = app.getActiveRoutineRunForRoutine(routine.id, '2026-03-31');
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

  testWidgets('cancelling a routine clears active state and restart begins fresh',
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
        estimatedMinutes: 2,
        sortOrder: 0,
      ),
      RoutineStep(
        id: 'step_2',
        title: 'Washroom',
        estimatedMinutes: 5,
        sortOrder: 1,
      ),
    ],
    createdAt: '2026-03-31T00:00:00.000',
  );
}

class _TimelineHarness extends StatefulWidget {
  final AppProvider app;
  final DateTime initialDate;

  const _TimelineHarness({
    required this.app,
    required this.initialDate,
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
    return ChangeNotifierProvider<AppProvider>.value(
      value: app,
      child: MaterialApp(
        home: RoutineRunnerScreen(
          routine: routine,
          dateKey: dateKey,
        ),
      ),
    );
  }
}
