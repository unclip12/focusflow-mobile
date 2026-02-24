// =============================================================
// StudyMaterial, MaterialChatMessage — matches types.ts
// =============================================================

class MaterialChatMessage {
  final String id;
  final String role; // 'user' | 'model'
  final String text;
  final String timestamp; // ISO

  const MaterialChatMessage({
    required this.id, required this.role, required this.text, required this.timestamp,
  });

  factory MaterialChatMessage.fromJson(Map<String, dynamic> j) => MaterialChatMessage(
        id: j['id'] ?? '', role: j['role'] ?? 'user', text: j['text'] ?? '', timestamp: j['timestamp'] ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'role': role, 'text': text, 'timestamp': timestamp};

  MaterialChatMessage copyWith({String? id, String? role, String? text, String? timestamp}) =>
      MaterialChatMessage(
        id: id ?? this.id, role: role ?? this.role, text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
      );
}

class StudyMaterial {
  final String id;
  final String title;
  final String text;
  final String sourceType; // 'PDF' | 'IMAGE' | 'TEXT'
  final String createdAt; // ISO
  final bool isActive;
  final int? tokenEstimate;
  final String? source; // 'UPLOAD' | 'MENTOR' | 'PASTE'
  final String? relatedSessionId;

  const StudyMaterial({
    required this.id, required this.title, required this.text, required this.sourceType,
    required this.createdAt, required this.isActive, this.tokenEstimate, this.source,
    this.relatedSessionId,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> j) => StudyMaterial(
        id: j['id'] ?? '', title: j['title'] ?? '', text: j['text'] ?? '',
        sourceType: j['sourceType'] ?? 'TEXT', createdAt: j['createdAt'] ?? '',
        isActive: j['isActive'] ?? true, tokenEstimate: j['tokenEstimate'],
        source: j['source'], relatedSessionId: j['relatedSessionId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'text': text, 'sourceType': sourceType,
        'createdAt': createdAt, 'isActive': isActive,
        if (tokenEstimate != null) 'tokenEstimate': tokenEstimate,
        if (source != null) 'source': source,
        if (relatedSessionId != null) 'relatedSessionId': relatedSessionId,
      };

  StudyMaterial copyWith({
    String? id, String? title, String? text, String? sourceType, String? createdAt,
    bool? isActive, int? tokenEstimate, String? source, String? relatedSessionId,
  }) => StudyMaterial(
        id: id ?? this.id, title: title ?? this.title, text: text ?? this.text,
        sourceType: sourceType ?? this.sourceType, createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive, tokenEstimate: tokenEstimate ?? this.tokenEstimate,
        source: source ?? this.source, relatedSessionId: relatedSessionId ?? this.relatedSessionId,
      );
}
