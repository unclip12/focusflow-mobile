// =============================================================
// TimeLogEntry — matches types.ts
// =============================================================

import 'package:focusflow_mobile/utils/constants.dart';

class TimeLogEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String startTime; // ISO string
  final String endTime; // ISO string
  final int durationMinutes;
  final TimeLogCategory category;
  final TimeLogSource source;
  final String activity; // Label/Title
  final String? pageNumber; // can be String or number in types.ts — use String
  final List<String>? topics;
  final String? notes;
  final String? linkedEntityId; // blockId or pageNumber reference

  const TimeLogEntry({
    required this.id, required this.date, required this.startTime, required this.endTime,
    required this.durationMinutes, required this.category, required this.source,
    required this.activity, this.pageNumber, this.topics, this.notes, this.linkedEntityId,
  });

  factory TimeLogEntry.fromJson(Map<String, dynamic> j) => TimeLogEntry(
        id: j['id'] ?? '', date: j['date'] ?? '', startTime: j['startTime'] ?? '',
        endTime: j['endTime'] ?? '', durationMinutes: j['durationMinutes'] ?? 0,
        category: TimeLogCategory.fromString(j['category'] ?? 'OTHER'),
        source: TimeLogSource.fromString(j['source'] ?? 'MANUAL'),
        activity: j['activity'] ?? '',
        pageNumber: j['pageNumber']?.toString(),
        topics: j['topics'] != null ? List<String>.from(j['topics']) : null,
        notes: j['notes'], linkedEntityId: j['linkedEntityId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'date': date, 'startTime': startTime, 'endTime': endTime,
        'durationMinutes': durationMinutes, 'category': category.value, 'source': source.value,
        'activity': activity,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (topics != null) 'topics': topics,
        if (notes != null) 'notes': notes,
        if (linkedEntityId != null) 'linkedEntityId': linkedEntityId,
      };

  TimeLogEntry copyWith({
    String? id, String? date, String? startTime, String? endTime, int? durationMinutes,
    TimeLogCategory? category, TimeLogSource? source, String? activity,
    String? pageNumber, List<String>? topics, String? notes, String? linkedEntityId,
  }) => TimeLogEntry(
        id: id ?? this.id, date: date ?? this.date,
        startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        category: category ?? this.category, source: source ?? this.source,
        activity: activity ?? this.activity, pageNumber: pageNumber ?? this.pageNumber,
        topics: topics ?? this.topics, notes: notes ?? this.notes,
        linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      );
}
