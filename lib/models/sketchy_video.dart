class SketchyVideo {
  final int? id;
  final String category;
  final String subcategory;
  final String title;
  final bool watched;

  const SketchyVideo({
    this.id,
    required this.category,
    required this.subcategory,
    required this.title,
    required this.watched,
  });

  SketchyVideo copyWith({bool? watched}) => SketchyVideo(
        id: id,
        category: category,
        subcategory: subcategory,
        title: title,
        watched: watched ?? this.watched,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'subcategory': subcategory,
        'title': title,
        'watched': watched ? 1 : 0,
      };

  factory SketchyVideo.fromMap(Map<String, dynamic> m) => SketchyVideo(
        id: m['id'] as int?,
        category: m['category'] as String? ?? '',
        subcategory: m['subcategory'] as String? ?? '',
        title: m['title'] as String? ?? '',
        watched: (m['watched'] as int) == 1,
      );
}
