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
