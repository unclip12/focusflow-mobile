class ReminderRecurrenceType {
  ReminderRecurrenceType._();

  static const String oneTime = 'oneTime';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String customWeekdays = 'customWeekdays';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  static const List<String> values = <String>[
    oneTime,
    daily,
    weekly,
    customWeekdays,
    monthly,
    yearly,
  ];
}

const Object _reminderFieldUnset = Object();

class Reminder {
  final String id;
  final String title;
  final String? notes;
  final String baseDate; // YYYY-MM-DD
  final String? time; // HH:mm
  final bool isAllDay;
  final String recurrenceType;
  final List<int> recurrenceWeekdays; // 1=Mon .. 7=Sun
  final bool useDefaultAlerts;
  final List<int> customAlertOffsets; // minutes before due time
  final String createdAt;
  final String updatedAt;
  final bool archived;

  const Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.baseDate,
    this.time,
    this.isAllDay = false,
    this.recurrenceType = ReminderRecurrenceType.oneTime,
    this.recurrenceWeekdays = const <int>[],
    this.useDefaultAlerts = true,
    this.customAlertOffsets = const <int>[],
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        notes: j['notes']?.toString(),
        baseDate: j['baseDate']?.toString() ?? '',
        time: j['time']?.toString(),
        isAllDay: j['isAllDay'] as bool? ?? false,
        recurrenceType:
            ReminderRecurrenceType.values.contains(j['recurrenceType'])
                ? j['recurrenceType'] as String
                : ReminderRecurrenceType.oneTime,
        recurrenceWeekdays: (j['recurrenceWeekdays'] as List?)
                ?.map((value) => value as int)
                .where((value) => value >= 1 && value <= 7)
                .toList() ??
            const <int>[],
        useDefaultAlerts: j['useDefaultAlerts'] as bool? ?? true,
        customAlertOffsets: (j['customAlertOffsets'] as List?)
                ?.map((value) => value as int)
                .toList() ??
            const <int>[],
        createdAt: j['createdAt']?.toString() ?? '',
        updatedAt: j['updatedAt']?.toString() ?? '',
        archived: j['archived'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (notes != null) 'notes': notes,
        'baseDate': baseDate,
        if (time != null) 'time': time,
        'isAllDay': isAllDay,
        'recurrenceType': recurrenceType,
        'recurrenceWeekdays': recurrenceWeekdays,
        'useDefaultAlerts': useDefaultAlerts,
        'customAlertOffsets': customAlertOffsets,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archived': archived,
      };

  Reminder copyWith({
    String? id,
    String? title,
    Object? notes = _reminderFieldUnset,
    String? baseDate,
    Object? time = _reminderFieldUnset,
    bool? isAllDay,
    String? recurrenceType,
    List<int>? recurrenceWeekdays,
    bool? useDefaultAlerts,
    List<int>? customAlertOffsets,
    String? createdAt,
    String? updatedAt,
    bool? archived,
  }) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: identical(notes, _reminderFieldUnset)
            ? this.notes
            : notes as String?,
        baseDate: baseDate ?? this.baseDate,
        time:
            identical(time, _reminderFieldUnset) ? this.time : time as String?,
        isAllDay: isAllDay ?? this.isAllDay,
        recurrenceType: recurrenceType ?? this.recurrenceType,
        recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
        useDefaultAlerts: useDefaultAlerts ?? this.useDefaultAlerts,
        customAlertOffsets: customAlertOffsets ?? this.customAlertOffsets,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archived: archived ?? this.archived,
      );

  DateTime? get baseDateValue => parseReminderDate(baseDate);

  bool occursOn(DateTime date) {
    final normalizedDate = reminderDateOnly(date);
    final base = baseDateValue;
    if (base == null) return false;
    if (normalizedDate.isBefore(base)) return false;

    switch (recurrenceType) {
      case ReminderRecurrenceType.oneTime:
        return isSameReminderDate(normalizedDate, base);
      case ReminderRecurrenceType.daily:
        return true;
      case ReminderRecurrenceType.weekly:
      case ReminderRecurrenceType.customWeekdays:
        final weekdays = recurrenceWeekdays.isNotEmpty
            ? recurrenceWeekdays
            : <int>[base.weekday];
        return weekdays.contains(normalizedDate.weekday);
      case ReminderRecurrenceType.monthly:
        final scheduledDay = _clampedDayForMonth(
          normalizedDate.year,
          normalizedDate.month,
          base.day,
        );
        return normalizedDate.day == scheduledDay;
      case ReminderRecurrenceType.yearly:
        if (normalizedDate.month != base.month) return false;
        final scheduledDay = _clampedDayForMonth(
          normalizedDate.year,
          base.month,
          base.day,
        );
        return normalizedDate.day == scheduledDay;
      default:
        return isSameReminderDate(normalizedDate, base);
    }
  }

  DateTime? latestOccurrenceOnOrBefore(DateTime date) {
    final target = reminderDateOnly(date);
    final base = baseDateValue;
    if (base == null || target.isBefore(base)) return null;

    switch (recurrenceType) {
      case ReminderRecurrenceType.oneTime:
        return base;
      case ReminderRecurrenceType.daily:
        return target;
      case ReminderRecurrenceType.weekly:
      case ReminderRecurrenceType.customWeekdays:
        final weekdays = recurrenceWeekdays.isNotEmpty
            ? recurrenceWeekdays
            : <int>[base.weekday];
        for (int offset = 0; offset < 7; offset++) {
          final candidate = target.subtract(Duration(days: offset));
          if (candidate.isBefore(base)) break;
          if (weekdays.contains(candidate.weekday)) return candidate;
        }
        return null;
      case ReminderRecurrenceType.monthly:
        final thisMonth = DateTime(
          target.year,
          target.month,
          _clampedDayForMonth(target.year, target.month, base.day),
        );
        if (!thisMonth.isAfter(target) && !thisMonth.isBefore(base)) {
          return thisMonth;
        }
        final previousMonth = DateTime(target.year, target.month - 1, 1);
        final candidate = DateTime(
          previousMonth.year,
          previousMonth.month,
          _clampedDayForMonth(
              previousMonth.year, previousMonth.month, base.day),
        );
        return candidate.isBefore(base) ? null : candidate;
      case ReminderRecurrenceType.yearly:
        final thisYear = DateTime(
          target.year,
          base.month,
          _clampedDayForMonth(target.year, base.month, base.day),
        );
        if (!thisYear.isAfter(target) && !thisYear.isBefore(base)) {
          return thisYear;
        }
        final candidate = DateTime(
          target.year - 1,
          base.month,
          _clampedDayForMonth(target.year - 1, base.month, base.day),
        );
        return candidate.isBefore(base) ? null : candidate;
      default:
        return base;
    }
  }
}

class ReminderOccurrenceState {
  final String id;
  final String reminderId;
  final String occurrenceKey; // YYYY-MM-DD of scheduled occurrence
  final bool completed;
  final String? completedAt;

  const ReminderOccurrenceState({
    required this.id,
    required this.reminderId,
    required this.occurrenceKey,
    this.completed = false,
    this.completedAt,
  });

  factory ReminderOccurrenceState.fromJson(Map<String, dynamic> j) =>
      ReminderOccurrenceState(
        id: j['id']?.toString() ?? '',
        reminderId: j['reminderId']?.toString() ?? '',
        occurrenceKey: j['occurrenceKey']?.toString() ?? '',
        completed: j['completed'] as bool? ?? false,
        completedAt: j['completedAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminderId': reminderId,
        'occurrenceKey': occurrenceKey,
        'completed': completed,
        if (completedAt != null) 'completedAt': completedAt,
      };

  ReminderOccurrenceState copyWith({
    String? id,
    String? reminderId,
    String? occurrenceKey,
    bool? completed,
    Object? completedAt = _reminderFieldUnset,
  }) =>
      ReminderOccurrenceState(
        id: id ?? this.id,
        reminderId: reminderId ?? this.reminderId,
        occurrenceKey: occurrenceKey ?? this.occurrenceKey,
        completed: completed ?? this.completed,
        completedAt: identical(completedAt, _reminderFieldUnset)
            ? this.completedAt
            : completedAt as String?,
      );
}

class ReminderOccurrence {
  final Reminder reminder;
  final String occurrenceKey;
  final String effectiveDate;
  final bool completed;
  final String? completedAt;
  final bool isOverdue;

  const ReminderOccurrence({
    required this.reminder,
    required this.occurrenceKey,
    required this.effectiveDate,
    required this.completed,
    this.completedAt,
    this.isOverdue = false,
  });

  String get reminderId => reminder.id;
  String get title => reminder.title;
  String? get notes => reminder.notes;
  String? get time => reminder.time;
  bool get isAllDay => reminder.isAllDay;
  bool get isTimed => !isAllDay && time != null && time!.isNotEmpty;
}

DateTime? parseReminderDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return reminderDateOnly(parsed);
}

String reminderOccurrenceKey(DateTime date) {
  final normalized = reminderDateOnly(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime reminderDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool isSameReminderDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _clampedDayForMonth(int year, int month, int desiredDay) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return desiredDay > lastDay ? lastDay : desiredDay;
}
