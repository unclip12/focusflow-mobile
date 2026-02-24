// =============================================================
// FMGEEntry, FMGELog — matches types.ts
// FMGELog extends RevisionLog fields + FMGE-specific fields.
// =============================================================

import 'attachment.dart';

class FMGELog {
  final String id;
  final String timestamp; // ISO
  final int? durationMinutes;
  final int revisionIndex;
  final String type; // 'STUDY' | 'REVISION'
  final List<String>? topics;
  final List<String>? subtopics;
  final String? notes;
  final String? source;
  final List<Attachment>? attachments;
  // FMGE-specific
  final int slideStart;
  final int slideEnd;
  final int? qBankCount;

  const FMGELog({
    required this.id, required this.timestamp, this.durationMinutes, required this.revisionIndex,
    required this.type, this.topics, this.subtopics, this.notes, this.source, this.attachments,
    required this.slideStart, required this.slideEnd, this.qBankCount,
  });

  factory FMGELog.fromJson(Map<String, dynamic> j) => FMGELog(
        id: j['id'] ?? '', timestamp: j['timestamp'] ?? '', durationMinutes: j['durationMinutes'],
        revisionIndex: j['revisionIndex'] ?? 0, type: j['type'] ?? 'STUDY',
        topics: j['topics'] != null ? List<String>.from(j['topics']) : null,
        subtopics: j['subtopics'] != null ? List<String>.from(j['subtopics']) : null,
        notes: j['notes'], source: j['source'],
        attachments: j['attachments'] != null
            ? (j['attachments'] as List).map((a) => Attachment.fromJson(a)).toList() : null,
        slideStart: j['slideStart'] ?? 0, slideEnd: j['slideEnd'] ?? 0, qBankCount: j['qBankCount'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'timestamp': timestamp, if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'revisionIndex': revisionIndex, 'type': type,
        if (topics != null) 'topics': topics, if (subtopics != null) 'subtopics': subtopics,
        if (notes != null) 'notes': notes, if (source != null) 'source': source,
        if (attachments != null) 'attachments': attachments!.map((a) => a.toJson()).toList(),
        'slideStart': slideStart, 'slideEnd': slideEnd, if (qBankCount != null) 'qBankCount': qBankCount,
      };

  FMGELog copyWith({
    String? id, String? timestamp, int? durationMinutes, int? revisionIndex, String? type,
    List<String>? topics, List<String>? subtopics, String? notes, String? source,
    List<Attachment>? attachments, int? slideStart, int? slideEnd, int? qBankCount,
  }) => FMGELog(
        id: id ?? this.id, timestamp: timestamp ?? this.timestamp,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        revisionIndex: revisionIndex ?? this.revisionIndex, type: type ?? this.type,
        topics: topics ?? this.topics, subtopics: subtopics ?? this.subtopics,
        notes: notes ?? this.notes, source: source ?? this.source, attachments: attachments ?? this.attachments,
        slideStart: slideStart ?? this.slideStart, slideEnd: slideEnd ?? this.slideEnd,
        qBankCount: qBankCount ?? this.qBankCount,
      );
}

class FMGEEntry {
  final String id;
  final String subject;
  final int slideStart;
  final int slideEnd;
  final int revisionCount;
  final String? lastStudiedAt;
  final String? nextRevisionAt;
  final int currentRevisionIndex;
  final List<FMGELog> logs;
  final String? notes;

  const FMGEEntry({
    required this.id, required this.subject, required this.slideStart, required this.slideEnd,
    required this.revisionCount, this.lastStudiedAt, this.nextRevisionAt,
    required this.currentRevisionIndex, required this.logs, this.notes,
  });

  factory FMGEEntry.fromJson(Map<String, dynamic> j) => FMGEEntry(
        id: j['id'] ?? '', subject: j['subject'] ?? '', slideStart: j['slideStart'] ?? 0,
        slideEnd: j['slideEnd'] ?? 0, revisionCount: j['revisionCount'] ?? 0,
        lastStudiedAt: j['lastStudiedAt'], nextRevisionAt: j['nextRevisionAt'],
        currentRevisionIndex: j['currentRevisionIndex'] ?? 0,
        logs: (j['logs'] as List?)?.map((l) => FMGELog.fromJson(l)).toList() ?? [],
        notes: j['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'subject': subject, 'slideStart': slideStart, 'slideEnd': slideEnd,
        'revisionCount': revisionCount, 'lastStudiedAt': lastStudiedAt,
        'nextRevisionAt': nextRevisionAt, 'currentRevisionIndex': currentRevisionIndex,
        'logs': logs.map((l) => l.toJson()).toList(), if (notes != null) 'notes': notes,
      };

  FMGEEntry copyWith({
    String? id, String? subject, int? slideStart, int? slideEnd, int? revisionCount,
    String? lastStudiedAt, String? nextRevisionAt, int? currentRevisionIndex,
    List<FMGELog>? logs, String? notes,
  }) => FMGEEntry(
        id: id ?? this.id, subject: subject ?? this.subject,
        slideStart: slideStart ?? this.slideStart, slideEnd: slideEnd ?? this.slideEnd,
        revisionCount: revisionCount ?? this.revisionCount,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
        nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
        currentRevisionIndex: currentRevisionIndex ?? this.currentRevisionIndex,
        logs: logs ?? this.logs, notes: notes ?? this.notes,
      );
}
