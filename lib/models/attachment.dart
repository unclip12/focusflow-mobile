// =============================================================
// Attachment, VideoResource, QuizQuestion
// Matches types.ts — used by KnowledgeBaseEntry, RevisionLog, etc.
// =============================================================

class Attachment {
  final String id;
  final String name;
  final String type; // 'IMAGE' | 'PDF' | 'OTHER'
  final String data; // Base64 string or URL

  const Attachment({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
  });

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'OTHER',
        data: j['data'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'data': data,
      };

  Attachment copyWith({
    String? id,
    String? name,
    String? type,
    String? data,
  }) =>
      Attachment(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        data: data ?? this.data,
      );
}

class VideoResource {
  final String id;
  final String title;
  final String url;

  const VideoResource({
    required this.id,
    required this.title,
    required this.url,
  });

  factory VideoResource.fromJson(Map<String, dynamic> j) => VideoResource(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        url: j['url'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
      };

  VideoResource copyWith({
    String? id,
    String? title,
    String? url,
  }) =>
      VideoResource(
        id: id ?? this.id,
        title: title ?? this.title,
        url: url ?? this.url,
      );
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer; // index
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] ?? '',
        options: List<String>.from(j['options'] ?? []),
        correctAnswer: j['correctAnswer'] ?? 0,
        explanation: j['explanation'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
      };

  QuizQuestion copyWith({
    String? question,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
  }) =>
      QuizQuestion(
        question: question ?? this.question,
        options: options ?? this.options,
        correctAnswer: correctAnswer ?? this.correctAnswer,
        explanation: explanation ?? this.explanation,
      );
}
