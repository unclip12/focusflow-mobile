// Data models for AI Chat persistence.

class AiConversation {
  final String id;
  String title;
  final String createdAt;
  String updatedAt;
  String? lastMessage;

  AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'lastMessage': lastMessage,
  };

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'New Chat',
    createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    lastMessage: json['lastMessage'] as String?,
  );
}

class AiChatMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'ai'
  final String content;
  final String type; // 'text', 'attachment', 'voice'
  final String timestamp;

  AiChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.type = 'text',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'role': role,
    'content': content,
    'type': type,
    'timestamp': timestamp,
  };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    role: json['role'] as String,
    content: json['content'] as String,
    type: json['type'] as String? ?? 'text',
    timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
  );
}
