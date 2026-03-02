class SketchyItem {
  final String id; // unique e.g. 'sk_staph_aureus'
  final String name; // e.g. 'Staph aureus'
  final String type; // 'micro' | 'pharma'
  final String category; // e.g. 'Gram Positive' for micro, 'Antibiotics' for pharma
  final String? customTitle;
  final String? userDescription;
  final String status; // 'unwatched' | 'watched' | 'mastered'

  const SketchyItem({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    this.customTitle,
    this.userDescription,
    required this.status,
  });

  factory SketchyItem.fromJson(Map<String, dynamic> j) => SketchyItem(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        category: j['category'] as String? ?? 'General',
        customTitle: j['customTitle'] as String?,
        userDescription: j['userDescription'] as String?,
        status: j['status'] as String? ?? 'unwatched',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        if (customTitle != null) 'customTitle': customTitle,
        if (userDescription != null) 'userDescription': userDescription,
        'status': status,
      };

  SketchyItem copyWith({
    String? id,
    String? name,
    String? type,
    String? category,
    String? customTitle,
    String? userDescription,
    String? status,
  }) =>
      SketchyItem(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        category: category ?? this.category,
        customTitle: customTitle ?? this.customTitle,
        userDescription: userDescription ?? this.userDescription,
        status: status ?? this.status,
      );
}
