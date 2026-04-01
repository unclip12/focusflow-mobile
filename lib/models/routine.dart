// =============================================================
// Routine, RoutineStep, RoutineLog, RoutineLogEntry
// User-created sequential routines with step-by-step execution
// =============================================================

const Object _routineFieldUnset = Object();

class RoutineStep {
  final String id;
  final String title;
  final String emoji;
  final int? estimatedMinutes;
  final List<RoutineChecklistItem> checklistItems;
  final int sortOrder;

  const RoutineStep({
    required this.id,
    required this.title,
    this.emoji = '✨',
    this.estimatedMinutes,
    this.checklistItems = const [],
    required this.sortOrder,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        emoji: j['emoji'] ?? '✨',
        estimatedMinutes: j['estimatedMinutes'],
        checklistItems: (j['checklistItems'] as List?)
                ?.map((item) => RoutineChecklistItem.fromJson(item))
                .toList() ??
            const [],
        sortOrder: j['sortOrder'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        if (checklistItems.isNotEmpty)
          'checklistItems': checklistItems.map((item) => item.toJson()).toList(),
        'sortOrder': sortOrder,
      };

  RoutineStep copyWith({
    String? id,
    String? title,
    String? emoji,
    int? estimatedMinutes,
    List<RoutineChecklistItem>? checklistItems,
    int? sortOrder,
  }) =>
      RoutineStep(
        id: id ?? this.id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        checklistItems: checklistItems ?? this.checklistItems,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class RoutineChecklistItem {
  final String id;
  final String title;

  const RoutineChecklistItem({
    required this.id,
    required this.title,
  });

  factory RoutineChecklistItem.fromJson(Map<String, dynamic> j) =>
      RoutineChecklistItem(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };

  RoutineChecklistItem copyWith({
    String? id,
    String? title,
  }) =>
      RoutineChecklistItem(
        id: id ?? this.id,
        title: title ?? this.title,
      );
}

class RoutineSubtask {
  final String id;
  final String name;
  final String emoji;
  final int durationMinutes;

  const RoutineSubtask({
    required this.id,
    required this.name,
    this.emoji = '📌',
    this.durationMinutes = 0,
  });

  factory RoutineSubtask.fromJson(Map<String, dynamic> j) => RoutineSubtask(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '📌',
        durationMinutes: j['durationMinutes'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'durationMinutes': durationMinutes,
      };

  RoutineSubtask copyWith({
    String? id,
    String? name,
    String? emoji,
    int? durationMinutes,
  }) =>
      RoutineSubtask(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        durationMinutes: durationMinutes ?? this.durationMinutes,
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
  final String recurrenceType; // 'none' | 'daily' | 'weekly' | 'monthly'
  final List<int> recurrenceDays; // for weekly: 1=Mon...7=Sun
  final List<RoutineSubtask> subtasks;
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
    this.recurrenceType = 'none',
    this.recurrenceDays = const [],
    this.subtasks = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        icon: j['icon'] ?? 'ðŸ”„',
        color: j['color'] ?? 0xFF6366F1,
        steps: (j['steps'] as List?)
                ?.map((s) => RoutineStep.fromJson(s))
                .toList() ??
            [],
        reminderTime: j['reminderTime'],
        recurrence: j['recurrence'],
        recurrenceEndDate: j['recurrenceEndDate'],
        reminderWeekday: j['reminderWeekday'],
        recurrenceType: j['recurrenceType'] ?? 'none',
        recurrenceDays: j['recurrenceDays'] != null
            ? List<int>.from(j['recurrenceDays'])
            : const [],
        subtasks: (j['subtasks'] as List?)
                ?.map((s) => RoutineSubtask.fromJson(s))
                .toList() ??
            const [],
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
        'recurrenceType': recurrenceType,
        if (recurrenceDays.isNotEmpty) 'recurrenceDays': recurrenceDays,
        if (subtasks.isNotEmpty)
          'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  int get totalEstimatedMinutes =>
      steps.fold(0, (sum, s) => sum + (s.estimatedMinutes ?? 0));

  int get totalSubtaskMinutes =>
      subtasks.fold(0, (s, t) => s + t.durationMinutes);

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
    String? recurrenceType,
    List<int>? recurrenceDays,
    List<RoutineSubtask>? subtasks,
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
        recurrenceType: recurrenceType ?? this.recurrenceType,
        recurrenceDays: recurrenceDays ?? this.recurrenceDays,
        subtasks: subtasks ?? this.subtasks,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ActiveRoutineRun {
  final String routineId;
  final String dateKey;
  final String? sourceBlockId;
  final DateTime startedAt;
  final DateTime currentStepStartedAt;
  final int currentStepIndex;
  final List<RoutineLogEntry> entries;
  final Map<String, bool> checklistState;
  final String status; // 'active' | 'cancelled' | 'completed'

  const ActiveRoutineRun({
    required this.routineId,
    required this.dateKey,
    this.sourceBlockId,
    required this.startedAt,
    required this.currentStepStartedAt,
    required this.currentStepIndex,
    this.entries = const [],
    this.checklistState = const {},
    this.status = 'active',
  });

  factory ActiveRoutineRun.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    return ActiveRoutineRun(
      routineId: j['routineId'] ?? '',
      dateKey: j['dateKey'] ?? '',
      sourceBlockId: j['sourceBlockId'],
      startedAt: DateTime.tryParse(j['startedAt'] ?? '') ?? now,
      currentStepStartedAt:
          DateTime.tryParse(j['currentStepStartedAt'] ?? '') ?? now,
      currentStepIndex: j['currentStepIndex'] ?? 0,
      entries: (j['entries'] as List?)
              ?.map((e) => RoutineLogEntry.fromJson(e))
              .toList() ??
          const [],
      checklistState: (j['checklistState'] as Map?)
              ?.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value == true,
                ),
              ) ??
          const {},
      status: j['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'routineId': routineId,
        'dateKey': dateKey,
        if (sourceBlockId != null) 'sourceBlockId': sourceBlockId,
        'startedAt': startedAt.toIso8601String(),
        'currentStepStartedAt': currentStepStartedAt.toIso8601String(),
        'currentStepIndex': currentStepIndex,
        'entries': entries.map((entry) => entry.toJson()).toList(),
        if (checklistState.isNotEmpty) 'checklistState': checklistState,
        'status': status,
      };

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  int totalElapsedSecondsAt([DateTime? now]) {
    final effectiveNow = now ?? DateTime.now();
    final elapsed = effectiveNow.difference(startedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  int currentStepElapsedSecondsAt([DateTime? now]) {
    final effectiveNow = now ?? DateTime.now();
    final elapsed = effectiveNow.difference(currentStepStartedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  bool isChecklistItemChecked(String stepId, String itemId) {
    return checklistState[_checklistKey(stepId, itemId)] ?? false;
  }

  static String checklistKey(String stepId, String itemId) {
    return _checklistKey(stepId, itemId);
  }

  static String _checklistKey(String stepId, String itemId) {
    return '$stepId::$itemId';
  }

  ActiveRoutineRun copyWith({
    String? routineId,
    String? dateKey,
    Object? sourceBlockId = _routineFieldUnset,
    DateTime? startedAt,
    DateTime? currentStepStartedAt,
    int? currentStepIndex,
    List<RoutineLogEntry>? entries,
    Map<String, bool>? checklistState,
    String? status,
  }) =>
      ActiveRoutineRun(
        routineId: routineId ?? this.routineId,
        dateKey: dateKey ?? this.dateKey,
        sourceBlockId: identical(sourceBlockId, _routineFieldUnset)
            ? this.sourceBlockId
            : sourceBlockId as String?,
        startedAt: startedAt ?? this.startedAt,
        currentStepStartedAt: currentStepStartedAt ?? this.currentStepStartedAt,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        entries: entries ?? this.entries,
        checklistState: checklistState ?? this.checklistState,
        status: status ?? this.status,
      );
}

// Routine log records actual execution timings.

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
