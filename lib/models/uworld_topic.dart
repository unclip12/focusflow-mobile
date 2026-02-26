class UWorldTopic {
  final int? id;
  final String system;
  final String subtopic;
  final int totalQuestions;
  final int doneQuestions;
  final int correctQuestions;

  const UWorldTopic({
    this.id,
    required this.system,
    required this.subtopic,
    required this.totalQuestions,
    this.doneQuestions = 0,
    this.correctQuestions = 0,
  });

  UWorldTopic copyWith({int? doneQuestions, int? correctQuestions}) =>
      UWorldTopic(
        id: id,
        system: system,
        subtopic: subtopic,
        totalQuestions: totalQuestions,
        doneQuestions: doneQuestions ?? this.doneQuestions,
        correctQuestions: correctQuestions ?? this.correctQuestions,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'system': system,
        'subtopic': subtopic,
        'total_questions': totalQuestions,
        'done_questions': doneQuestions,
        'correct_questions': correctQuestions,
      };

  factory UWorldTopic.fromMap(Map<String, dynamic> m) => UWorldTopic(
        id: m['id'] as int?,
        system: m['system'] as String,
        subtopic: m['subtopic'] as String,
        totalQuestions: m['total_questions'] as int,
        doneQuestions: m['done_questions'] as int,
        correctQuestions: m['correct_questions'] as int,
      );
}
