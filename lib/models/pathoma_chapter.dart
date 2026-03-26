class PathomaChapter {
  final int? id;
  final int chapter;
  final String title;
  final bool watched;
  final String? customTitle;
  final String? userDescription;

  const PathomaChapter({
    this.id,
    required this.chapter,
    required this.title,
    required this.watched,
    this.customTitle,
    this.userDescription,
  });

  PathomaChapter copyWith({
    bool? watched,
    String? customTitle,
    String? userDescription,
  }) =>
      PathomaChapter(
        id: id,
        chapter: chapter,
        title: title,
        watched: watched ?? this.watched,
        customTitle: customTitle ?? this.customTitle,
        userDescription: userDescription ?? this.userDescription,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chapter': chapter,
        'title': title,
        'watched': watched ? 1 : 0,
        if (customTitle != null) 'customTitle': customTitle,
        if (userDescription != null) 'userDescription': userDescription,
      };

  factory PathomaChapter.fromMap(Map<String, dynamic> m) => PathomaChapter(
        id: m['id'] as int?,
        chapter: m['chapter'] as int,
        title: m['title'] as String? ?? '',
        watched: (m['watched'] as int) == 1,
        customTitle: m['customTitle'] as String?,
        userDescription: m['userDescription'] as String?,
      );
}
