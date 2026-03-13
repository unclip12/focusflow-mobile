// =============================================================
// Routine, RoutineStep, RoutineLog, RoutineLogEntry
// User-created sequential routines with step-by-step execution
// =============================================================

const Object _routineFieldUnset = Object();

class RoutineStep {
  final String id;
  final String title;
  final int? estimatedMinutes;
  final int sortOrder;

  const RoutineStep({
    required this.id,
    required this.title,
    this.estimatedMinutes,
    required this.sortOrder,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        estimatedMinutes: j['estimatedMinutes'],
        sortOrder: j['sortOrder'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        'sortOrder': sortOrder,
      };

  RoutineStep copyWith({
    String? id,
    String? title,
    int? estimatedMinutes,
    int? sortOrder,
  }) =>
      RoutineStep(
        id: id ?? this.id,
        title: title ?? this.title,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class Routine {
  final String id;
  final String name;
  final String icon; // emoji or icon name
  final int color; // 0xAARRGGBB
  final List<RoutineStep> steps;
  final String? reminderTime; // HH:mm
  final String? recurrence; // daily | weekly | until_date
  final String? recurrenceEndDate; // YYYY-MM-DD
  final int? reminderWeekday; // 1=Mon .. 7=Sun
  final String createdAt;
  final String? updatedAt;

  const Routine({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.steps,
    this.reminderTime,
    this.recurrence,
    this.recurrenceEndDate,
    this.reminderWeekday,
    required this.createdAt,
    this.updatedAt,
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        icon: j['icon'] ?? '🔄',
        color: j['color'] ?? 0xFF6366F1,
        steps: (j['steps'] as List?)
                ?.map((s) => RoutineStep.fromJson(s))
                .toList() ??
            [],
        reminderTime: j['reminderTime'],
        recurrence: j['recurrence'],
        recurrenceEndDate: j['recurrenceEndDate'],
        reminderWeekday: j['reminderWeekday'],
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'steps': steps.map((s) => s.toJson()).toList(),
        if (reminderTime != null) 'reminderTime': reminderTime,
        if (recurrence != null) 'recurrence': recurrence,
        if (recurrenceEndDate != null) 'recurrenceEndDate': recurrenceEndDate,
        if (reminderWeekday != null) 'reminderWeekday': reminderWeekday,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  int get totalEstimatedMinutes =>
      steps.fold(0, (sum, s) => sum + (s.estimatedMinutes ?? 0));

  Routine copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    List<RoutineStep>? steps,
    Object? reminderTime = _routineFieldUnset,
    Object? recurrence = _routineFieldUnset,
    Object? recurrenceEndDate = _routineFieldUnset,
    Object? reminderWeekday = _routineFieldUnset,
    String? createdAt,
    String? updatedAt,
  }) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        steps: steps ?? this.steps,
        reminderTime: identical(reminderTime, _routineFieldUnset)
            ? this.reminderTime
            : reminderTime as String?,
        recurrence: identical(recurrence, _routineFieldUnset)
            ? this.recurrence
            : recurrence as String?,
        recurrenceEndDate: identical(recurrenceEndDate, _routineFieldUnset)
            ? this.recurrenceEndDate
            : recurrenceEndDate as String?,
        reminderWeekday: identical(reminderWeekday, _routineFieldUnset)
            ? this.reminderWeekday
            : reminderWeekday as int?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── Routine Log — records actual execution timings ──────────────

class RoutineLogEntry {
  final String stepId;
  final String stepTitle;
  final String startTime; // ISO 8601
  final String? endTime;
  final int? durationSeconds;
  final bool skipped;

  const RoutineLogEntry({
    required this.stepId,
    required this.stepTitle,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.skipped = false,
  });

  factory RoutineLogEntry.fromJson(Map<String, dynamic> j) => RoutineLogEntry(
        stepId: j['stepId'] ?? '',
        stepTitle: j['stepTitle'] ?? '',
        startTime: j['startTime'] ?? '',
        endTime: j['endTime'],
        durationSeconds: j['durationSeconds'],
        skipped: j['skipped'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'stepTitle': stepTitle,
        'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        'skipped': skipped,
      };

  RoutineLogEntry copyWith({
    String? stepId,
    String? stepTitle,
    String? startTime,
    String? endTime,
    int? durationSeconds,
    bool? skipped,
  }) =>
      RoutineLogEntry(
        stepId: stepId ?? this.stepId,
        stepTitle: stepTitle ?? this.stepTitle,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        skipped: skipped ?? this.skipped,
      );
}

class RoutineLog {
  final String id;
  final String routineId;
  final String routineName;
  final String date; // YYYY-MM-DD
  final String startTime; // ISO 8601
  final String? endTime;
  final int? totalDurationSeconds;
  final List<RoutineLogEntry> entries;
  final bool completed;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.startTime,
    this.endTime,
    this.totalDurationSeconds,
    required this.entries,
    required this.completed,
  });

  factory RoutineLog.fromJson(Map<String, dynamic> j) => RoutineLog(
        id: j['id'] ?? '',
        routineId: j['routineId'] ?? '',
        routineName: j['routineName'] ?? '',
        date: j['date'] ?? '',
        startTime: j['startTime'] ?? '',
        endTime: j['endTime'],
        totalDurationSeconds: j['totalDurationSeconds'],
        entries: (j['entries'] as List?)
                ?.map((e) => RoutineLogEntry.fromJson(e))
                .toList() ??
            [],
        completed: j['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'routineName': routineName,
        'date': date,
        'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (totalDurationSeconds != null)
          'totalDurationSeconds': totalDurationSeconds,
        'entries': entries.map((e) => e.toJson()).toList(),
        'completed': completed,
      };

  RoutineLog copyWith({
    String? id,
    String? routineId,
    String? routineName,
    String? date,
    String? startTime,
    String? endTime,
    int? totalDurationSeconds,
    List<RoutineLogEntry>? entries,
    bool? completed,
  }) =>
      RoutineLog(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        routineName: routineName ?? this.routineName,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
        entries: entries ?? this.entries,
        completed: completed ?? this.completed,
      );
}
