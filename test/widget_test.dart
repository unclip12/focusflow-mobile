import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/today_plan/timeline_view.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';

void main() {
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
