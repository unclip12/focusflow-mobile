class FAPage {
  final int pageNum; // 33 to 706
  final String subject; // e.g. 'Biochemistry'
  final String system; // e.g. 'General'
  final String title; // e.g. 'Molecular Biology'
  final String status; // 'unread' | 'read' | 'anki_done'
  final String? ankiDueDate; // ISO8601 or null
  final String? lastReviewed; // ISO8601 or null

  const FAPage({
    required this.pageNum,
    required this.subject,
    required this.system,
    required this.title,
    required this.status,
    this.ankiDueDate,
    this.lastReviewed,
  });

  factory FAPage.fromJson(Map<String, dynamic> j) => FAPage(
        pageNum: j['pageNum'] as int,
        subject: j['subject'] as String,
        system: j['system'] as String? ?? 'General',
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'unread',
        ankiDueDate: j['ankiDueDate'] as String?,
        lastReviewed: j['lastReviewed'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'pageNum': pageNum,
        'subject': subject,
        'system': system,
        'title': title,
        'status': status,
        if (ankiDueDate != null) 'ankiDueDate': ankiDueDate,
        if (lastReviewed != null) 'lastReviewed': lastReviewed,
      };

  FAPage copyWith({
    int? pageNum,
    String? subject,
    String? system,
    String? title,
    String? status,
    String? ankiDueDate,
    String? lastReviewed,
  }) =>
      FAPage(
        pageNum: pageNum ?? this.pageNum,
        subject: subject ?? this.subject,
        system: system ?? this.system,
        title: title ?? this.title,
        status: status ?? this.status,
        ankiDueDate: ankiDueDate ?? this.ankiDueDate,
        lastReviewed: lastReviewed ?? this.lastReviewed,
      );
}
