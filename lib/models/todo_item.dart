// =============================================================
// TodoItem — to-do with time scheduling and category
// Categories: Studies, Daily Life, Other
// =============================================================

class TodoItem {
  final String id;
  final String title;
  final String category; // 'Studies' | 'Daily Life' | 'Other'
  final String? scheduledTime; // HH:mm
  final int? estimatedMinutes;
  final String? notes;
  final String date; // YYYY-MM-DD
  final bool completed;
  final String? completedAt;
  final int sortOrder;
  final String createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    required this.category,
    this.scheduledTime,
    this.estimatedMinutes,
    this.notes,
    required this.date,
    this.completed = false,
    this.completedAt,
    required this.sortOrder,
    required this.createdAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        category: j['category'] ?? 'Other',
        scheduledTime: j['scheduledTime'],
        estimatedMinutes: j['estimatedMinutes'],
        notes: j['notes'],
        date: j['date'] ?? '',
        completed: j['completed'] ?? false,
        completedAt: j['completedAt'],
        sortOrder: j['sortOrder'] ?? 0,
        createdAt: j['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        if (scheduledTime != null) 'scheduledTime': scheduledTime,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        if (notes != null) 'notes': notes,
        'date': date,
        'completed': completed,
        if (completedAt != null) 'completedAt': completedAt,
        'sortOrder': sortOrder,
        'createdAt': createdAt,
      };

  TodoItem copyWith({
    String? id,
    String? title,
    String? category,
    String? scheduledTime,
    int? estimatedMinutes,
    String? notes,
    String? date,
    bool? completed,
    String? completedAt,
    int? sortOrder,
    String? createdAt,
  }) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        completed: completed ?? this.completed,
        completedAt: completedAt ?? this.completedAt,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
}
