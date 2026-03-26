// =============================================================
// VideoLecture — Video lecture with time tracking
// Subjects: PSM, Ophthalmology, ENT, etc.
// =============================================================

class VideoLecture {
  final int? id;
  final String subject;       // e.g. 'Preventive & Social Medicine'
  final String title;         // e.g. 'PSM Day-1 Mission 200+ (June 26) Lap 1'
  final int durationMinutes;  // total video length in minutes
  final int watchedMinutes;   // how many minutes user has watched
  final bool watched;         // true when fully watched / marked complete
  final int orderIndex;       // display order within subject
  final String? customTitle;
  final String? userDescription;

  const VideoLecture({
    this.id,
    required this.subject,
    required this.title,
    required this.durationMinutes,
    this.watchedMinutes = 0,
    this.watched = false,
    this.orderIndex = 0,
    this.customTitle,
    this.userDescription,
  });

  /// Progress as a fraction 0.0 → 1.0
  double get progressPercent =>
      durationMinutes > 0 ? (watchedMinutes / durationMinutes).clamp(0.0, 1.0) : 0.0;

  /// Remaining minutes
  int get remainingMinutes => (durationMinutes - watchedMinutes).clamp(0, durationMinutes);

  /// True if marked watched or slider reached the end
  bool get isComplete => watched || watchedMinutes >= durationMinutes;

  /// Human-readable duration string  e.g. "6h 26m" or "82 Mins"
  String get durationLabel {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '$durationMinutes Mins';
  }

  /// Human-readable watched string
  String get watchedLabel {
    if (watchedMinutes >= 60) {
      final h = watchedMinutes ~/ 60;
      final m = watchedMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '$watchedMinutes Mins';
  }

  /// Human-readable remaining string
  String get remainingLabel {
    final r = remainingMinutes;
    if (r >= 60) {
      final h = r ~/ 60;
      final m = r % 60;
      return m > 0 ? '${h}h ${m}m Left' : '${h}h Left';
    }
    return '$r Mins Left';
  }

  factory VideoLecture.fromMap(Map<String, dynamic> m) => VideoLecture(
        id: m['id'] as int?,
        subject: m['subject'] as String? ?? '',
        title: m['title'] as String? ?? '',
        durationMinutes: m['duration_minutes'] as int? ?? 0,
        watchedMinutes: m['watched_minutes'] as int? ?? 0,
        watched: (m['watched'] as int? ?? 0) == 1,
        orderIndex: m['order_index'] as int? ?? 0,
        customTitle: m['customTitle'] as String?,
        userDescription: m['userDescription'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject': subject,
        'title': title,
        'duration_minutes': durationMinutes,
        'watched_minutes': watchedMinutes,
        'watched': watched ? 1 : 0,
        'order_index': orderIndex,
        if (customTitle != null) 'customTitle': customTitle,
        if (userDescription != null) 'userDescription': userDescription,
      };

  VideoLecture copyWith({
    int? id,
    String? subject,
    String? title,
    int? durationMinutes,
    int? watchedMinutes,
    bool? watched,
    int? orderIndex,
    String? customTitle,
    String? userDescription,
  }) =>
      VideoLecture(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        title: title ?? this.title,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        watchedMinutes: watchedMinutes ?? this.watchedMinutes,
        watched: watched ?? this.watched,
        orderIndex: orderIndex ?? this.orderIndex,
        customTitle: customTitle ?? this.customTitle,
        userDescription: userDescription ?? this.userDescription,
      );
}
