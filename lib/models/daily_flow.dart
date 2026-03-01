// =============================================================
// DailyFlow — per-day independent activity flow
// Each day has its own flow that can be customized independently.
// =============================================================

class FlowActivity {
  final String id;
  final String label;
  final String icon;
  final String activityType; // ActivityType.value
  final String? routineId;
  final List<String> linkedTaskIds;
  final int sortOrder;
  final String status; // NOT_STARTED | IN_PROGRESS | PAUSED | DONE | SKIPPED
  final String? startedAt;
  final String? completedAt;
  final int? durationSeconds;
  final String? pausedUntil; // ISO 8601 — pause timer target

  const FlowActivity({
    required this.id,
    required this.label,
    required this.icon,
    required this.activityType,
    this.routineId,
    this.linkedTaskIds = const [],
    required this.sortOrder,
    this.status = 'NOT_STARTED',
    this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.pausedUntil,
  });

  factory FlowActivity.fromJson(Map<String, dynamic> j) => FlowActivity(
        id: j['id'] ?? '',
        label: j['label'] ?? '',
        icon: j['icon'] ?? '⚡',
        activityType: j['activityType'] ?? 'CUSTOM',
        routineId: j['routineId'],
        linkedTaskIds: j['linkedTaskIds'] != null
            ? List<String>.from(j['linkedTaskIds'])
            : [],
        sortOrder: j['sortOrder'] ?? 0,
        status: j['status'] ?? 'NOT_STARTED',
        startedAt: j['startedAt'],
        completedAt: j['completedAt'],
        durationSeconds: j['durationSeconds'],
        pausedUntil: j['pausedUntil'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': icon,
        'activityType': activityType,
        if (routineId != null) 'routineId': routineId,
        'linkedTaskIds': linkedTaskIds,
        'sortOrder': sortOrder,
        'status': status,
        if (startedAt != null) 'startedAt': startedAt,
        if (completedAt != null) 'completedAt': completedAt,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (pausedUntil != null) 'pausedUntil': pausedUntil,
      };

  FlowActivity copyWith({
    String? id,
    String? label,
    String? icon,
    String? activityType,
    String? routineId,
    List<String>? linkedTaskIds,
    int? sortOrder,
    String? status,
    String? startedAt,
    String? completedAt,
    int? durationSeconds,
    String? pausedUntil,
  }) =>
      FlowActivity(
        id: id ?? this.id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        activityType: activityType ?? this.activityType,
        routineId: routineId ?? this.routineId,
        linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
        sortOrder: sortOrder ?? this.sortOrder,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        pausedUntil: pausedUntil ?? this.pausedUntil,
      );

  bool get isDone => status == 'DONE';
  bool get isActive => status == 'IN_PROGRESS';
  bool get isPaused => status == 'PAUSED';
  bool get isNotStarted => status == 'NOT_STARTED';
  bool get isSkipped => status == 'SKIPPED';
}

class DailyFlow {
  final String date; // YYYY-MM-DD
  final List<FlowActivity> activities;
  final String status; // NOT_STARTED | ACTIVE | PAUSED | STOPPED | COMPLETED
  final int currentIndex;
  final String? startedAt;
  final String? stoppedAt;
  final String? resumeReminderAt;

  const DailyFlow({
    required this.date,
    this.activities = const [],
    this.status = 'NOT_STARTED',
    this.currentIndex = 0,
    this.startedAt,
    this.stoppedAt,
    this.resumeReminderAt,
  });

  factory DailyFlow.fromJson(Map<String, dynamic> j) => DailyFlow(
        date: j['date'] ?? '',
        activities: (j['activities'] as List?)
                ?.map((a) => FlowActivity.fromJson(a))
                .toList() ??
            [],
        status: j['status'] ?? 'NOT_STARTED',
        currentIndex: j['currentIndex'] ?? 0,
        startedAt: j['startedAt'],
        stoppedAt: j['stoppedAt'],
        resumeReminderAt: j['resumeReminderAt'],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'activities': activities.map((a) => a.toJson()).toList(),
        'status': status,
        'currentIndex': currentIndex,
        if (startedAt != null) 'startedAt': startedAt,
        if (stoppedAt != null) 'stoppedAt': stoppedAt,
        if (resumeReminderAt != null) 'resumeReminderAt': resumeReminderAt,
      };

  DailyFlow copyWith({
    String? date,
    List<FlowActivity>? activities,
    String? status,
    int? currentIndex,
    String? startedAt,
    String? stoppedAt,
    String? resumeReminderAt,
  }) =>
      DailyFlow(
        date: date ?? this.date,
        activities: activities ?? this.activities,
        status: status ?? this.status,
        currentIndex: currentIndex ?? this.currentIndex,
        startedAt: startedAt ?? this.startedAt,
        stoppedAt: stoppedAt ?? this.stoppedAt,
        resumeReminderAt: resumeReminderAt ?? this.resumeReminderAt,
      );

  int get completedCount => activities.where((a) => a.isDone).length;
  int get totalCount => activities.length;
  int get totalElapsedSeconds =>
      activities.fold(0, (s, a) => s + (a.durationSeconds ?? 0));

  bool get isActive => status == 'ACTIVE';
  bool get isPaused => status == 'PAUSED';
  bool get isStopped => status == 'STOPPED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isNotStarted => status == 'NOT_STARTED';

  /// Next activity that hasn't been completed or skipped
  FlowActivity? get nextPendingActivity {
    for (final a in activities) {
      if (a.isNotStarted || a.isActive || a.isPaused) return a;
    }
    return null;
  }
}
