// =============================================================
// LibraryNote — custom notes and attachments for any library item
// =============================================================

import 'dart:convert';

class LibraryNote {
  final String id;
  final String itemId; // ID of the referenced library item (e.g., FAPage id)
  final String itemType; // 'FA_PAGE', 'SKETCHY', 'PATHOMA', 'UWORLD', etc.
  final String noteText;
  final List<String> tags;
  final List<String> attachmentPaths;
  final String createdAt; // ISO8601 string

  const LibraryNote({
    required this.id,
    required this.itemId,
    required this.itemType,
    this.noteText = '',
    this.tags = const [],
    this.attachmentPaths = const [],
    required this.createdAt,
  });

  factory LibraryNote.fromJson(Map<String, dynamic> json) {
    return LibraryNote(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      noteText: json['noteText'] as String? ?? '',
      tags: json['tags'] != null
          ? List<String>.from(jsonDecode(json['tags'] as String? ?? '[]'))
          : [],
      attachmentPaths: json['attachmentPaths'] != null
          ? List<String>.from(
              jsonDecode(json['attachmentPaths'] as String? ?? '[]'))
          : [],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemType': itemType,
      'noteText': noteText,
      'tags': jsonEncode(tags),
      'attachmentPaths': jsonEncode(attachmentPaths),
      'createdAt': createdAt,
    };
  }

  LibraryNote copyWith({
    String? id,
    String? itemId,
    String? itemType,
    String? noteText,
    List<String>? tags,
    List<String>? attachmentPaths,
    String? createdAt,
  }) {
    return LibraryNote(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      noteText: noteText ?? this.noteText,
      tags: tags ?? this.tags,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
