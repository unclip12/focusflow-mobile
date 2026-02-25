class UWorldSession {
  final String id;
  final String subject; // from kFmgeSubjects
  final int done; // questions attempted this session
  final int correct; // questions correct
  final String date; // 'yyyy-MM-dd'
  final String? notes;

  const UWorldSession({
    required this.id,
    required this.subject,
    required this.done,
    required this.correct,
    required this.date,
    this.notes,
  });

  factory UWorldSession.fromJson(Map<String, dynamic> j) => UWorldSession(
        id: j['id'] as String,
        subject: j['subject'] as String,
        done: j['done'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        date: j['date'] as String,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'done': done,
        'correct': correct,
        'date': date,
        if (notes != null) 'notes': notes,
      };
}
