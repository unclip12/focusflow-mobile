class PathomaChapter {
  final int? id;
  final int chapter;
  final String title;
  final bool watched;

  const PathomaChapter({
    this.id,
    required this.chapter,
    required this.title,
    required this.watched,
  });

  PathomaChapter copyWith({bool? watched}) => PathomaChapter(
        id: id,
        chapter: chapter,
        title: title,
        watched: watched ?? this.watched,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chapter': chapter,
        'title': title,
        'watched': watched ? 1 : 0,
      };

  factory PathomaChapter.fromMap(Map<String, dynamic> m) => PathomaChapter(
        id: m['id'] as int?,
        chapter: m['chapter'] as int,
        title: m['title'] as String? ?? '',
        watched: (m['watched'] as int) == 1,
      );
}
