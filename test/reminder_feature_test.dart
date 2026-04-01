import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow_mobile/models/reminder.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:intl/intl.dart';

Reminder _buildReminder({
  required String id,
  required String baseDate,
  String? time = '17:00',
  bool isAllDay = false,
  String recurrenceType = ReminderRecurrenceType.oneTime,
  List<int> recurrenceWeekdays = const <int>[],
}) {
  return Reminder(
    id: id,
    title: 'Check website',
    notes: 'Important',
    baseDate: baseDate,
    time: isAllDay ? null : time,
    isAllDay: isAllDay,
    recurrenceType: recurrenceType,
    recurrenceWeekdays: recurrenceWeekdays,
    useDefaultAlerts: false,
    customAlertOffsets: const <int>[0, 10],
    createdAt: '2026-01-01T00:00:00.000',
    updatedAt: '2026-01-01T00:00:00.000',
  );
}

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

void main() {
  group('Reminder model', () {
    test('serializes and restores reminder fields', () {
      final reminder = _buildReminder(
        id: 'r1',
        baseDate: '2026-04-01',
        recurrenceType: ReminderRecurrenceType.customWeekdays,
        recurrenceWeekdays: const <int>[1, 3, 5],
      );

      final restored = Reminder.fromJson(reminder.toJson());

      expect(restored.id, reminder.id);
      expect(restored.title, reminder.title);
      expect(restored.notes, reminder.notes);
      expect(restored.baseDate, reminder.baseDate);
      expect(restored.time, reminder.time);
      expect(restored.recurrenceType, reminder.recurrenceType);
      expect(restored.recurrenceWeekdays, reminder.recurrenceWeekdays);
      expect(restored.customAlertOffsets, reminder.customAlertOffsets);
    });

    test('monthly recurrence clamps to last day of shorter months', () {
      final reminder = _buildReminder(
        id: 'r2',
        baseDate: '2026-01-31',
        recurrenceType: ReminderRecurrenceType.monthly,
      );

      expect(reminder.occursOn(DateTime(2026, 2, 28)), isTrue);
      expect(reminder.occursOn(DateTime(2026, 2, 27)), isFalse);
      expect(
        reminder.latestOccurrenceOnOrBefore(DateTime(2026, 2, 28)),
        DateTime(2026, 2, 28),
      );
    });

    test('custom weekday recurrence resolves latest eligible occurrence', () {
      final reminder = _buildReminder(
        id: 'r3',
        baseDate: '2026-03-30',
        recurrenceType: ReminderRecurrenceType.customWeekdays,
        recurrenceWeekdays: const <int>[1, 3, 5],
      );

      expect(reminder.occursOn(DateTime(2026, 4, 1)), isTrue);
      expect(reminder.occursOn(DateTime(2026, 4, 2)), isFalse);
      expect(
        reminder.latestOccurrenceOnOrBefore(DateTime(2026, 4, 2)),
        DateTime(2026, 4, 1),
      );
    });
  });

  group('Reminder provider views', () {
    test('carries incomplete past reminder into today as overdue', () {
      final app = AppProvider();
      final today = reminderDateOnly(DateTime.now());
      final past = today.subtract(const Duration(days: 2));

      app.reminders = <Reminder>[
        _buildReminder(id: 'overdue', baseDate: _dateKey(past)),
      ];

      final occurrences = app.getReminderOccurrencesForDate(_dateKey(today));

      expect(occurrences, hasLength(1));
      expect(occurrences.single.reminderId, 'overdue');
      expect(occurrences.single.occurrenceKey, _dateKey(past));
      expect(occurrences.single.effectiveDate, _dateKey(today));
      expect(occurrences.single.isOverdue, isTrue);
      expect(app.getTimelineReminderOccurrencesForDate(_dateKey(today)),
          hasLength(1));
    });

    test('completed overdue one-time reminder no longer appears today', () {
      final app = AppProvider();
      final today = reminderDateOnly(DateTime.now());
      final past = today.subtract(const Duration(days: 1));
      final occurrenceKey = _dateKey(past);

      app.reminders = <Reminder>[
        _buildReminder(id: 'done', baseDate: occurrenceKey),
      ];
      app.reminderOccurrenceStates = <ReminderOccurrenceState>[
        ReminderOccurrenceState(
          id: 'done_$occurrenceKey',
          reminderId: 'done',
          occurrenceKey: occurrenceKey,
          completed: true,
          completedAt: '2026-01-01T12:00:00.000',
        ),
      ];

      expect(app.getReminderOccurrencesForDate(_dateKey(today)), isEmpty);
    });

    test('timeline reminders exclude all-day reminders', () {
      final app = AppProvider();
      final todayKey = _dateKey(DateTime.now());

      app.reminders = <Reminder>[
        _buildReminder(id: 'timed', baseDate: todayKey, time: '08:00'),
        _buildReminder(
          id: 'all-day',
          baseDate: todayKey,
          isAllDay: true,
          time: null,
        ),
      ];

      final timelineItems = app.getTimelineReminderOccurrencesForDate(todayKey);

      expect(timelineItems, hasLength(1));
      expect(timelineItems.single.reminderId, 'timed');
    });
  });
}
