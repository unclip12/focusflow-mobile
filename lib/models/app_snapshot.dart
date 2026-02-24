// =============================================================
// AppSnapshot, HistoryRecord — matches types.ts
// =============================================================

class AppSnapshot {
  final List<Map<String, dynamic>> kb;
  final Map<String, dynamic>? dayPlan;
  final List<Map<String, dynamic>> fmge;

  const AppSnapshot({required this.kb, this.dayPlan, required this.fmge});

  factory AppSnapshot.fromJson(Map<String, dynamic> j) => AppSnapshot(
        kb: (j['kb'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
        dayPlan: j['dayPlan'] != null ? Map<String, dynamic>.from(j['dayPlan']) : null,
        fmge: (j['fmge'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'kb': kb,
        if (dayPlan != null) 'dayPlan': dayPlan,
        'fmge': fmge,
      };

  AppSnapshot copyWith({
    List<Map<String, dynamic>>? kb, Map<String, dynamic>? dayPlan, List<Map<String, dynamic>>? fmge,
  }) => AppSnapshot(kb: kb ?? this.kb, dayPlan: dayPlan ?? this.dayPlan, fmge: fmge ?? this.fmge);
}

class HistoryRecord {
  final String id;
  final String timestamp; // ISO
  final String type; // 'KB_UPDATE' | 'PLAN_UPDATE' | 'FMGE_UPDATE' | 'FULL_RESTORE' | 'SNAPSHOT' | 'AUTO_DAILY'
  final String description;
  final dynamic snapshot; // AppSnapshot | KnowledgeBaseEntry | DayPlan | any
  final bool? isFullSnapshot;

  const HistoryRecord({
    required this.id, required this.timestamp, required this.type,
    required this.description, this.snapshot, this.isFullSnapshot,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        id: j['id'] ?? '', timestamp: j['timestamp'] ?? '', type: j['type'] ?? '',
        description: j['description'] ?? '', snapshot: j['snapshot'],
        isFullSnapshot: j['isFullSnapshot'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'timestamp': timestamp, 'type': type, 'description': description,
        if (snapshot != null) 'snapshot': snapshot,
        if (isFullSnapshot != null) 'isFullSnapshot': isFullSnapshot,
      };

  HistoryRecord copyWith({
    String? id, String? timestamp, String? type, String? description,
    dynamic snapshot, bool? isFullSnapshot,
  }) => HistoryRecord(
        id: id ?? this.id, timestamp: timestamp ?? this.timestamp, type: type ?? this.type,
        description: description ?? this.description, snapshot: snapshot ?? this.snapshot,
        isFullSnapshot: isFullSnapshot ?? this.isFullSnapshot,
      );
}
