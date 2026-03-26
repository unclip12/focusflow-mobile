class SketchyVideo {
  final int? id;
  final String category;
  final String subcategory;
  final String title;
  final bool watched;
  final String? customTitle;
  final String? userDescription;

  const SketchyVideo({
    this.id,
    required this.category,
    required this.subcategory,
    required this.title,
    required this.watched,
    this.customTitle,
    this.userDescription,
  });

  SketchyVideo copyWith({
    bool? watched,
    String? customTitle,
    String? userDescription,
  }) =>
      SketchyVideo(
        id: id,
        category: category,
        subcategory: subcategory,
        title: title,
        watched: watched ?? this.watched,
        customTitle: customTitle ?? this.customTitle,
        userDescription: userDescription ?? this.userDescription,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'subcategory': subcategory,
        'title': title,
        'watched': watched ? 1 : 0,
        if (customTitle != null) 'customTitle': customTitle,
        if (userDescription != null) 'userDescription': userDescription,
      };

  factory SketchyVideo.fromMap(Map<String, dynamic> m) => SketchyVideo(
        id: m['id'] as int?,
        category: m['category'] as String? ?? '',
        subcategory: m['subcategory'] as String? ?? '',
        title: m['title'] as String? ?? '',
        watched: (m['watched'] as int) == 1,
        customTitle: m['customTitle'] as String?,
        userDescription: m['userDescription'] as String?,
      );
}
