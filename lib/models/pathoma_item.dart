class PathomaItem {
  final String id; // e.g. 'patho_ch1'
  final int chapter; // 1 to 19
  final String title; // e.g. 'Cell Injury'
  final String subject; // e.g. 'General Pathology'
  final String status; // 'unwatched' | 'watched' | 'reviewed'

  const PathomaItem({
    required this.id,
    required this.chapter,
    required this.title,
    required this.subject,
    required this.status,
  });

  factory PathomaItem.fromJson(Map<String, dynamic> j) => PathomaItem(
        id: j['id'] as String,
        chapter: j['chapter'] as int,
        title: j['title'] as String,
        subject: j['subject'] as String? ?? 'General',
        status: j['status'] as String? ?? 'unwatched',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter': chapter,
        'title': title,
        'subject': subject,
        'status': status,
      };

  PathomaItem copyWith({
    String? id,
    int? chapter,
    String? title,
    String? subject,
    String? status,
  }) =>
      PathomaItem(
        id: id ?? this.id,
        chapter: chapter ?? this.chapter,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        status: status ?? this.status,
      );
}
