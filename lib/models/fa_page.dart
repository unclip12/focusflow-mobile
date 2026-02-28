// =============================================================
// FAPage — First Aid 2025 page with expanded tracking
// =============================================================

class FAPageRevision {
  final String date;
  final int revisionNum;

  const FAPageRevision({required this.date, required this.revisionNum});

  factory FAPageRevision.fromJson(Map<String, dynamic> j) => FAPageRevision(
        date: j['date'] ?? '',
        revisionNum: j['revisionNum'] ?? 0,
      );

  Map<String, dynamic> toJson() => {'date': date, 'revisionNum': revisionNum};
}

class FAPage {
  final int pageNum; // 33 to 706
  final String subject; // e.g. 'Biochemistry'
  final String system; // e.g. 'General'
  final String title; // e.g. 'Molecular Biology'
  final String status; // 'unread' | 'read' | 'anki_done'
  final String? ankiDueDate; // ISO8601 or null
  final String? lastReviewed; // ISO8601 or null
  final String? firstReadAt; // ISO8601 — when page was first fully read
  final String? ankiDoneAt; // ISO8601 — when anki was marked done
  final int revisionCount; // number of completed revisions
  final String? lastRevisedAt; // ISO8601
  final int orderIndex; // FA book order (from seed position)
  final List<FAPageRevision> revisionHistory;

  const FAPage({
    required this.pageNum,
    required this.subject,
    required this.system,
    required this.title,
    required this.status,
    this.ankiDueDate,
    this.lastReviewed,
    this.firstReadAt,
    this.ankiDoneAt,
    this.revisionCount = 0,
    this.lastRevisedAt,
    this.orderIndex = 0,
    this.revisionHistory = const [],
  });

  factory FAPage.fromJson(Map<String, dynamic> j) => FAPage(
        pageNum: j['pageNum'] as int,
        subject: j['subject'] as String,
        system: j['system'] as String? ?? 'General',
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'unread',
        ankiDueDate: j['ankiDueDate'] as String?,
        lastReviewed: j['lastReviewed'] as String?,
        firstReadAt: j['firstReadAt'] as String?,
        ankiDoneAt: j['ankiDoneAt'] as String?,
        revisionCount: j['revisionCount'] as int? ?? 0,
        lastRevisedAt: j['lastRevisedAt'] as String?,
        orderIndex: j['orderIndex'] as int? ?? 0,
        revisionHistory: (j['revisionHistory'] as List?)
                ?.map((r) =>
                    FAPageRevision.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'pageNum': pageNum,
        'subject': subject,
        'system': system,
        'title': title,
        'status': status,
        if (ankiDueDate != null) 'ankiDueDate': ankiDueDate,
        if (lastReviewed != null) 'lastReviewed': lastReviewed,
        if (firstReadAt != null) 'firstReadAt': firstReadAt,
        if (ankiDoneAt != null) 'ankiDoneAt': ankiDoneAt,
        'revisionCount': revisionCount,
        if (lastRevisedAt != null) 'lastRevisedAt': lastRevisedAt,
        'orderIndex': orderIndex,
        'revisionHistory': revisionHistory.map((r) => r.toJson()).toList(),
      };

  FAPage copyWith({
    int? pageNum,
    String? subject,
    String? system,
    String? title,
    String? status,
    String? ankiDueDate,
    String? lastReviewed,
    String? firstReadAt,
    String? ankiDoneAt,
    int? revisionCount,
    String? lastRevisedAt,
    int? orderIndex,
    List<FAPageRevision>? revisionHistory,
  }) =>
      FAPage(
        pageNum: pageNum ?? this.pageNum,
        subject: subject ?? this.subject,
        system: system ?? this.system,
        title: title ?? this.title,
        status: status ?? this.status,
        ankiDueDate: ankiDueDate ?? this.ankiDueDate,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        firstReadAt: firstReadAt ?? this.firstReadAt,
        ankiDoneAt: ankiDoneAt ?? this.ankiDoneAt,
        revisionCount: revisionCount ?? this.revisionCount,
        lastRevisedAt: lastRevisedAt ?? this.lastRevisedAt,
        orderIndex: orderIndex ?? this.orderIndex,
        revisionHistory: revisionHistory ?? this.revisionHistory,
      );
}
