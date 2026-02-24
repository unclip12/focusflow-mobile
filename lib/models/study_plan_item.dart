// =============================================================
// StudyPlanItem, PlanLog, ToDoItem — matches types.ts
// =============================================================

import 'attachment.dart';

class ToDoItem {
  final String id;
  final String text;
  final bool done;

  const ToDoItem({required this.id, required this.text, required this.done});

  factory ToDoItem.fromJson(Map<String, dynamic> j) =>
      ToDoItem(id: j['id'] ?? '', text: j['text'] ?? '', done: j['done'] ?? false);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  ToDoItem copyWith({String? id, String? text, bool? done}) =>
      ToDoItem(id: id ?? this.id, text: text ?? this.text, done: done ?? this.done);
}

class PlanLog {
  final String id;
  final String date;
  final int durationMinutes;
  final String? notes;
  final String? startTime;
  final String? endTime;

  const PlanLog({
    required this.id, required this.date, required this.durationMinutes,
    this.notes, this.startTime, this.endTime,
  });

  factory PlanLog.fromJson(Map<String, dynamic> j) => PlanLog(
        id: j['id'] ?? '', date: j['date'] ?? '', durationMinutes: j['durationMinutes'] ?? 0,
        notes: j['notes'], startTime: j['startTime'], endTime: j['endTime'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'date': date, 'durationMinutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      };

  PlanLog copyWith({String? id, String? date, int? durationMinutes, String? notes, String? startTime, String? endTime}) =>
      PlanLog(
        id: id ?? this.id, date: date ?? this.date, durationMinutes: durationMinutes ?? this.durationMinutes,
        notes: notes ?? this.notes, startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
      );
}

class StudyPlanItem {
  final String id;
  final String date; // YYYY-MM-DD
  final String type; // 'PAGE' | 'VIDEO' | 'HYBRID'
  final String pageNumber; // Linker
  final String topic;
  final String? videoUrl;
  final int? ankiCount;
  final int estimatedMinutes;
  final bool isCompleted;
  final List<ToDoItem>? subTasks;
  final List<PlanLog>? logs;
  final int? totalMinutesSpent;
  final List<Attachment>? attachments;
  final String? createdAt;
  final String? completedAt;

  const StudyPlanItem({
    required this.id, required this.date, required this.type, required this.pageNumber,
    required this.topic, this.videoUrl, this.ankiCount, required this.estimatedMinutes,
    required this.isCompleted, this.subTasks, this.logs, this.totalMinutesSpent,
    this.attachments, this.createdAt, this.completedAt,
  });

  factory StudyPlanItem.fromJson(Map<String, dynamic> j) => StudyPlanItem(
        id: j['id'] ?? '', date: j['date'] ?? '', type: j['type'] ?? 'PAGE',
        pageNumber: j['pageNumber']?.toString() ?? '', topic: j['topic'] ?? '',
        videoUrl: j['videoUrl'], ankiCount: j['ankiCount'],
        estimatedMinutes: j['estimatedMinutes'] ?? 0, isCompleted: j['isCompleted'] ?? false,
        subTasks: j['subTasks'] != null ? (j['subTasks'] as List).map((t) => ToDoItem.fromJson(t)).toList() : null,
        logs: j['logs'] != null ? (j['logs'] as List).map((l) => PlanLog.fromJson(l)).toList() : null,
        totalMinutesSpent: j['totalMinutesSpent'],
        attachments: j['attachments'] != null ? (j['attachments'] as List).map((a) => Attachment.fromJson(a)).toList() : null,
        createdAt: j['createdAt'], completedAt: j['completedAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'date': date, 'type': type, 'pageNumber': pageNumber, 'topic': topic,
        if (videoUrl != null) 'videoUrl': videoUrl, if (ankiCount != null) 'ankiCount': ankiCount,
        'estimatedMinutes': estimatedMinutes, 'isCompleted': isCompleted,
        if (subTasks != null) 'subTasks': subTasks!.map((t) => t.toJson()).toList(),
        if (logs != null) 'logs': logs!.map((l) => l.toJson()).toList(),
        if (totalMinutesSpent != null) 'totalMinutesSpent': totalMinutesSpent,
        if (attachments != null) 'attachments': attachments!.map((a) => a.toJson()).toList(),
        if (createdAt != null) 'createdAt': createdAt, if (completedAt != null) 'completedAt': completedAt,
      };

  StudyPlanItem copyWith({
    String? id, String? date, String? type, String? pageNumber, String? topic,
    String? videoUrl, int? ankiCount, int? estimatedMinutes, bool? isCompleted,
    List<ToDoItem>? subTasks, List<PlanLog>? logs, int? totalMinutesSpent,
    List<Attachment>? attachments, String? createdAt, String? completedAt,
  }) => StudyPlanItem(
        id: id ?? this.id, date: date ?? this.date, type: type ?? this.type,
        pageNumber: pageNumber ?? this.pageNumber, topic: topic ?? this.topic,
        videoUrl: videoUrl ?? this.videoUrl, ankiCount: ankiCount ?? this.ankiCount,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        isCompleted: isCompleted ?? this.isCompleted, subTasks: subTasks ?? this.subTasks,
        logs: logs ?? this.logs, totalMinutesSpent: totalMinutesSpent ?? this.totalMinutesSpent,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt ?? this.createdAt, completedAt: completedAt ?? this.completedAt,
      );
}
