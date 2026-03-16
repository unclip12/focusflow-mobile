// =============================================================
// ActivityLogEntry — tracks every action in the Library
// Used for history, analytics, and synchronization
// =============================================================

class ActivityLogEntry {
  final int? id;
  final String itemId;      // e.g. 'fa:42', 'sketchy:5', 'uworld:3'
  final String itemType;    // 'fa' | 'sketchy' | 'pathoma' | 'uworld'
  final String action;      // 'read' | 'revision' | 'watched' | 'question_done' | 'anki_done' | 'reset'
  final String timestamp;   // ISO8601
  final String title;       // Human-readable item title
  final String details;     // JSON string for extra data (revision num, correct count, etc.)

  const ActivityLogEntry({
    this.id,
    required this.itemId,
    required this.itemType,
    required this.action,
    required this.timestamp,
    this.title = '',
    this.details = '{}',
  });

  factory ActivityLogEntry.fromMap(Map<String, dynamic> m) => ActivityLogEntry(
        id: m['id'] as int?,
        itemId: m['item_id'] as String? ?? '',
        itemType: m['item_type'] as String? ?? '',
        action: m['action'] as String? ?? '',
        timestamp: m['timestamp'] as String? ?? '',
        title: m['title'] as String? ?? '',
        details: m['details'] as String? ?? '{}',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'item_id': itemId,
        'item_type': itemType,
        'action': action,
        'timestamp': timestamp,
        'title': title,
        'details': details,
      };

  ActivityLogEntry copyWith({
    int? id,
    String? itemId,
    String? itemType,
    String? action,
    String? timestamp,
    String? title,
    String? details,
  }) =>
      ActivityLogEntry(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        itemType: itemType ?? this.itemType,
        action: action ?? this.action,
        timestamp: timestamp ?? this.timestamp,
        title: title ?? this.title,
        details: details ?? this.details,
      );

  /// Human-readable action label
  String get actionLabel {
    switch (action) {
      case 'read':
        return 'Marked as Read';
      case 'revision':
        return 'Revision Completed';
      case 'watched':
        return 'Marked as Watched';
      case 'question_done':
        return 'Questions Completed';
      case 'anki_done':
        return 'Anki Marked Done';
      case 'reset':
        return 'Reset';
      case 'unwatched':
        return 'Marked as Unwatched';
      default:
        return action;
    }
  }
}

/// UWorld per-session tracking entry
class UWorldSessionEntry {
  final String timestamp;       // ISO8601
  final int questionsDone;
  final int questionsCorrect;

  const UWorldSessionEntry({
    required this.timestamp,
    required this.questionsDone,
    required this.questionsCorrect,
  });

  double get accuracy =>
      questionsDone > 0 ? (questionsCorrect / questionsDone) * 100 : 0;

  factory UWorldSessionEntry.fromJson(Map<String, dynamic> j) =>
      UWorldSessionEntry(
        timestamp: j['timestamp'] as String? ?? '',
        questionsDone: j['questionsDone'] as int? ?? 0,
        questionsCorrect: j['questionsCorrect'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'questionsDone': questionsDone,
        'questionsCorrect': questionsCorrect,
      };
}
