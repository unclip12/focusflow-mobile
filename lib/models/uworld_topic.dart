class UWorldTopic {
  final int? id;
  final String system;
  final String subtopic;
  final String? customTitle;
  final String? userDescription;
  final int totalQuestions;
  final int doneQuestions;
  final int correctQuestions;

  const UWorldTopic({
    this.id,
    required this.system,
    required this.subtopic,
    this.customTitle,
    this.userDescription,
    required this.totalQuestions,
    this.doneQuestions = 0,
    this.correctQuestions = 0,
  });

  UWorldTopic copyWith({
    String? customTitle,
    String? userDescription,
    int? doneQuestions,
    int? correctQuestions,
  }) =>
      UWorldTopic(
        id: id,
        system: system,
        subtopic: subtopic,
        customTitle: customTitle ?? this.customTitle,
        userDescription: userDescription ?? this.userDescription,
        totalQuestions: totalQuestions,
        doneQuestions: doneQuestions ?? this.doneQuestions,
        correctQuestions: correctQuestions ?? this.correctQuestions,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'system': system,
        'subtopic': subtopic,
        if (customTitle != null) 'customTitle': customTitle,
        if (userDescription != null) 'userDescription': userDescription,
        'total_questions': totalQuestions,
        'done_questions': doneQuestions,
        'correct_questions': correctQuestions,
      };

  factory UWorldTopic.fromMap(Map<String, dynamic> m) => UWorldTopic(
        id: m['id'] as int?,
        system: m['system'] as String? ?? '',
        subtopic: m['subtopic'] as String? ?? '',
        customTitle: m['customTitle'] as String?,
        userDescription: m['userDescription'] as String?,
        totalQuestions: m['total_questions'] as int,
        doneQuestions: m['done_questions'] as int,
        correctQuestions: m['correct_questions'] as int,
      );
}
