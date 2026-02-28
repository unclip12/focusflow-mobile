// =============================================================
// FASubtopic — individual subtopic within an FA page
// Tracks study status, revision history at subtopic level
// =============================================================

class FASubtopicRevision {
  final String date;     // ISO8601
  final String type;     // 'revision'
  final int revisionNum; // 1, 2, 3...

  const FASubtopicRevision({
    required this.date,
    required this.type,
    required this.revisionNum,
  });

  factory FASubtopicRevision.fromJson(Map<String, dynamic> j) =>
      FASubtopicRevision(
        date: j['date'] ?? '',
        type: j['type'] ?? 'revision',
        revisionNum: j['revisionNum'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'type': type,
        'revisionNum': revisionNum,
      };
}

class FASubtopic {
  final int? id;
  final int pageNum;
  final String name;
  final String status; // 'unread' | 'read' | 'anki_done'
  final String? firstReadAt;  // ISO8601
  final String? ankiDoneAt;   // ISO8601
  final int revisionCount;
  final String? lastRevisedAt;
  final List<FASubtopicRevision> revisionHistory;

  const FASubtopic({
    this.id,
    required this.pageNum,
    required this.name,
    this.status = 'unread',
    this.firstReadAt,
    this.ankiDoneAt,
    this.revisionCount = 0,
    this.lastRevisedAt,
    this.revisionHistory = const [],
  });

  factory FASubtopic.fromJson(Map<String, dynamic> j) => FASubtopic(
        id: j['id'] as int?,
        pageNum: j['pageNum'] as int,
        name: j['name'] as String? ?? '',
        status: j['status'] as String? ?? 'unread',
        firstReadAt: j['firstReadAt'] as String?,
        ankiDoneAt: j['ankiDoneAt'] as String?,
        revisionCount: j['revisionCount'] as int? ?? 0,
        lastRevisedAt: j['lastRevisedAt'] as String?,
        revisionHistory: (j['revisionHistory'] as List?)
                ?.map((r) =>
                    FASubtopicRevision.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'pageNum': pageNum,
        'name': name,
        'status': status,
        if (firstReadAt != null) 'firstReadAt': firstReadAt,
        if (ankiDoneAt != null) 'ankiDoneAt': ankiDoneAt,
        'revisionCount': revisionCount,
        if (lastRevisedAt != null) 'lastRevisedAt': lastRevisedAt,
        'revisionHistory': revisionHistory.map((r) => r.toJson()).toList(),
      };

  FASubtopic copyWith({
    int? id,
    int? pageNum,
    String? name,
    String? status,
    String? firstReadAt,
    String? ankiDoneAt,
    int? revisionCount,
    String? lastRevisedAt,
    List<FASubtopicRevision>? revisionHistory,
  }) =>
      FASubtopic(
        id: id ?? this.id,
        pageNum: pageNum ?? this.pageNum,
        name: name ?? this.name,
        status: status ?? this.status,
        firstReadAt: firstReadAt ?? this.firstReadAt,
        ankiDoneAt: ankiDoneAt ?? this.ankiDoneAt,
        revisionCount: revisionCount ?? this.revisionCount,
        lastRevisedAt: lastRevisedAt ?? this.lastRevisedAt,
        revisionHistory: revisionHistory ?? this.revisionHistory,
      );
}
