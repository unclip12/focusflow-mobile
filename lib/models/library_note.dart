// =============================================================
// LibraryNote — custom notes and attachments for any library item
// =============================================================

import 'dart:convert';

class LibraryNoteAttachmentKind {
  static const String link = 'link';
  static const String image = 'image';
  static const String pdf = 'pdf';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String unknown = 'unknown';
}

class LibraryNoteAttachment {
  final String source;
  final String displayName;
  final String kind;

  LibraryNoteAttachment({
    required this.source,
    required this.displayName,
    required this.kind,
  });

  factory LibraryNoteAttachment.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] as String? ?? '').trim();
    final fallbackDisplayName = deriveDisplayName(source);
    return LibraryNoteAttachment(
      source: source,
      displayName:
          (json['displayName'] as String? ?? fallbackDisplayName).trim().isEmpty
              ? fallbackDisplayName
              : (json['displayName'] as String? ?? fallbackDisplayName).trim(),
      kind: normalizeKind(
        json['kind'] as String?,
        fallbackSource: source,
      ),
    );
  }

  factory LibraryNoteAttachment.fromLegacySource(String source) {
    final trimmedSource = source.trim();
    return LibraryNoteAttachment(
      source: trimmedSource,
      displayName: deriveDisplayName(trimmedSource),
      kind: detectKind(trimmedSource),
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'displayName': displayName,
        'kind': kind,
      };

  LibraryNoteAttachment copyWith({
    String? source,
    String? displayName,
    String? kind,
  }) {
    final nextSource = (source ?? this.source).trim();
    final fallbackDisplayName = deriveDisplayName(nextSource);
    final nextDisplayName = (displayName ?? this.displayName).trim();
    return LibraryNoteAttachment(
      source: nextSource,
      displayName:
          nextDisplayName.isEmpty ? fallbackDisplayName : nextDisplayName,
      kind: normalizeKind(
        kind ?? this.kind,
        fallbackSource: nextSource,
      ),
    );
  }

  bool get isWebLink => _isWebLink(source);

  static String deriveDisplayName(String source) {
    final trimmedSource = source.trim();
    if (trimmedSource.isEmpty) {
      return 'Attachment';
    }
    if (_isWebLink(trimmedSource)) {
      final uri = Uri.tryParse(trimmedSource);
      final host = uri?.host.trim() ?? '';
      final pathSegment = uri != null && uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last.trim()
          : '';
      if (pathSegment.isNotEmpty) {
        return Uri.decodeComponent(pathSegment);
      }
      if (host.isNotEmpty) {
        return host;
      }
      return trimmedSource;
    }

    final normalized = trimmedSource.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final filename = parts.isNotEmpty ? parts.last.trim() : trimmedSource;
    return filename.isEmpty ? 'Attachment' : filename;
  }

  static String detectKind(String source) {
    final trimmedSource = source.trim();
    if (_isWebLink(trimmedSource)) return LibraryNoteAttachmentKind.link;
    final ext = _fileExtension(trimmedSource);
    if (_imageExtensions.contains(ext)) return LibraryNoteAttachmentKind.image;
    if (ext == 'pdf') return LibraryNoteAttachmentKind.pdf;
    if (_videoExtensions.contains(ext)) return LibraryNoteAttachmentKind.video;
    if (_audioExtensions.contains(ext)) return LibraryNoteAttachmentKind.audio;
    return LibraryNoteAttachmentKind.unknown;
  }

  static String normalizeKind(
    String? rawKind, {
    required String fallbackSource,
  }) {
    switch ((rawKind ?? '').trim().toLowerCase()) {
      case LibraryNoteAttachmentKind.link:
        return LibraryNoteAttachmentKind.link;
      case LibraryNoteAttachmentKind.image:
        return LibraryNoteAttachmentKind.image;
      case LibraryNoteAttachmentKind.pdf:
        return LibraryNoteAttachmentKind.pdf;
      case LibraryNoteAttachmentKind.video:
        return LibraryNoteAttachmentKind.video;
      case LibraryNoteAttachmentKind.audio:
        return LibraryNoteAttachmentKind.audio;
      case LibraryNoteAttachmentKind.unknown:
        return LibraryNoteAttachmentKind.unknown;
      default:
        return detectKind(fallbackSource);
    }
  }

  static List<LibraryNoteAttachment> decodeAttachmentList(dynamic rawValue) {
    final rawList = _decodeDynamicList(rawValue);
    return rawList
        .whereType<Map>()
        .map((entry) => LibraryNoteAttachment.fromJson(
              Map<String, dynamic>.from(entry),
            ))
        .where((attachment) => attachment.source.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> decodeLegacyAttachmentPaths(dynamic rawValue) {
    final rawList = _decodeDynamicList(rawValue);
    return rawList
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<dynamic> _decodeDynamicList(dynamic rawValue) {
    if (rawValue == null) return const [];
    if (rawValue is List) return rawValue;
    if (rawValue is String && rawValue.isNotEmpty) {
      final decoded = jsonDecode(rawValue);
      if (decoded is List) {
        return decoded;
      }
    }
    return const [];
  }

  static String _fileExtension(String source) {
    final normalized = source.replaceAll('\\', '/');
    final filename = normalized.split('/').last;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) {
      return '';
    }
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  static bool _isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tiff',
    'tif',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
  };

  static const Set<String> _audioExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'oga',
    'flac',
    'wma',
    'amr',
  };
}

class LibraryNote {
  final String id;
  final String itemId; // ID of the referenced library item (e.g., FAPage id)
  final String itemType; // 'FA_PAGE', 'SKETCHY', 'PATHOMA', 'UWORLD', etc.
  final String noteText;
  final List<String> tags;
  final List<String> attachmentPaths;
  final List<LibraryNoteAttachment> attachments;
  final String createdAt; // ISO8601 string

  LibraryNote({
    required this.id,
    required this.itemId,
    required this.itemType,
    this.noteText = '',
    List<String> tags = const [],
    List<LibraryNoteAttachment> attachments = const [],
    List<String> attachmentPaths = const [],
    required this.createdAt,
  })  : tags = List.unmodifiable(tags),
        attachments = List.unmodifiable(
          attachments.isNotEmpty
              ? attachments
              : attachmentPaths
                  .map(LibraryNoteAttachment.fromLegacySource)
                  .toList(),
        ),
        attachmentPaths = List.unmodifiable(
          (attachments.isNotEmpty
                  ? attachments.map((attachment) => attachment.source)
                  : attachmentPaths)
              .where((path) => path.trim().isNotEmpty)
              .map((path) => path.trim())
              .toList(),
        );

  factory LibraryNote.fromJson(Map<String, dynamic> json) {
    final attachments =
        LibraryNoteAttachment.decodeAttachmentList(json['attachments']);
    final legacyPaths = LibraryNoteAttachment.decodeLegacyAttachmentPaths(
        json['attachmentPaths']);
    return LibraryNote(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      noteText: json['noteText'] as String? ?? '',
      tags: _decodeStringList(json['tags']),
      attachments: attachments,
      attachmentPaths: attachments.isNotEmpty ? const [] : legacyPaths,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final attachmentJson = attachments.map((attachment) => attachment.toJson());
    return {
      'id': id,
      'itemId': itemId,
      'itemType': itemType,
      'noteText': noteText,
      'tags': jsonEncode(tags),
      'attachments': jsonEncode(attachmentJson.toList()),
      'attachmentPaths': jsonEncode(
          attachments.map((attachment) => attachment.source).toList()),
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
    List<LibraryNoteAttachment>? attachments,
    String? createdAt,
  }) {
    return LibraryNote(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      noteText: noteText ?? this.noteText,
      tags: tags ?? this.tags,
      attachments: attachments ??
          (attachmentPaths == null ? this.attachments : const []),
      attachmentPaths: attachmentPaths ?? const [],
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _decodeStringList(dynamic rawValue) {
    if (rawValue == null) return const [];
    if (rawValue is List) {
      return rawValue
          .map((entry) => entry?.toString() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (rawValue is String && rawValue.isNotEmpty) {
      final decoded = jsonDecode(rawValue);
      if (decoded is List) {
        return decoded
            .map((entry) => entry?.toString() ?? '')
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }
}
