// =============================================================
// StudyEntry — matches types.ts
// =============================================================

class StudyEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm
  final String taskName;
  final double progress; // 0–100
  final bool revision;
  final int? durationMinutes;

  const StudyEntry({
    required this.id, required this.date, required this.time, required this.taskName,
    required this.progress, required this.revision, this.durationMinutes,
  });

  factory StudyEntry.fromJson(Map<String, dynamic> j) => StudyEntry(
        id: j['id'] ?? '', date: j['date'] ?? '', time: j['time'] ?? '',
        taskName: j['taskName'] ?? '', progress: (j['progress'] ?? 0).toDouble(),
        revision: j['revision'] ?? false, durationMinutes: j['durationMinutes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'date': date, 'time': time, 'taskName': taskName,
        'progress': progress, 'revision': revision,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      };

  StudyEntry copyWith({
    String? id, String? date, String? time, String? taskName,
    double? progress, bool? revision, int? durationMinutes,
  }) => StudyEntry(
        id: id ?? this.id, date: date ?? this.date, time: time ?? this.time,
        taskName: taskName ?? this.taskName, progress: progress ?? this.progress,
        revision: revision ?? this.revision, durationMinutes: durationMinutes ?? this.durationMinutes,
      );
}
