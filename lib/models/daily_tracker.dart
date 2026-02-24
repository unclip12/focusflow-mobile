// =============================================================
// DailyTracker, TimeSlot, TrackerTask — matches types.ts
// =============================================================

class TrackerTask {
  final String id;
  final String text;
  final bool isCompleted;
  final String? reason;
  final int? timeInvestedMinutes;

  const TrackerTask({
    required this.id, required this.text, required this.isCompleted,
    this.reason, this.timeInvestedMinutes,
  });

  factory TrackerTask.fromJson(Map<String, dynamic> j) => TrackerTask(
        id: j['id'] ?? '', text: j['text'] ?? '', isCompleted: j['isCompleted'] ?? false,
        reason: j['reason'], timeInvestedMinutes: j['timeInvestedMinutes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'text': text, 'isCompleted': isCompleted,
        if (reason != null) 'reason': reason,
        if (timeInvestedMinutes != null) 'timeInvestedMinutes': timeInvestedMinutes,
      };

  TrackerTask copyWith({String? id, String? text, bool? isCompleted, String? reason, int? timeInvestedMinutes}) =>
      TrackerTask(
        id: id ?? this.id, text: text ?? this.text, isCompleted: isCompleted ?? this.isCompleted,
        reason: reason ?? this.reason, timeInvestedMinutes: timeInvestedMinutes ?? this.timeInvestedMinutes,
      );
}

class TimeSlot {
  final String startTime; // "HH:mm"
  final String endTime;
  final List<TrackerTask> tasks;

  const TimeSlot({required this.startTime, required this.endTime, required this.tasks});

  factory TimeSlot.fromJson(Map<String, dynamic> j) => TimeSlot(
        startTime: j['startTime'] ?? '', endTime: j['endTime'] ?? '',
        tasks: (j['tasks'] as List?)?.map((t) => TrackerTask.fromJson(t)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime, 'endTime': endTime,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  TimeSlot copyWith({String? startTime, String? endTime, List<TrackerTask>? tasks}) =>
      TimeSlot(
        startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
        tasks: tasks ?? this.tasks,
      );
}

class DailyTracker {
  final String date; // YYYY-MM-DD
  final List<TimeSlot> timeSlots;

  const DailyTracker({required this.date, required this.timeSlots});

  factory DailyTracker.fromJson(Map<String, dynamic> j) => DailyTracker(
        date: j['date'] ?? '',
        timeSlots: (j['timeSlots'] as List?)?.map((s) => TimeSlot.fromJson(s)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'timeSlots': timeSlots.map((s) => s.toJson()).toList(),
      };

  DailyTracker copyWith({String? date, List<TimeSlot>? timeSlots}) =>
      DailyTracker(date: date ?? this.date, timeSlots: timeSlots ?? this.timeSlots);
}
