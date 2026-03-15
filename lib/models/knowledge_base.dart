// =============================================================
// KnowledgeBaseEntry, RevisionLog, TrackableItem
// Matches types.ts — pageNumber (String) is the primary key.
// =============================================================

import 'attachment.dart';
import 'revision_item.dart';

class RevisionLog {
  final String id;
  final String timestamp; // ISO string
  final int? durationMinutes;
  final int revisionIndex; // 0 = initial study, 1 = first revision, etc.
  final String type; // 'STUDY' | 'REVISION'
  final List<String>? topics;
  final List<String>? subtopics;
  final String? notes;
  final String? source; // 'CHAT' | 'MODAL'
  final List<Attachment>? attachments;

  const RevisionLog({
    required this.id,
    required this.timestamp,
    this.durationMinutes,
    required this.revisionIndex,
    required this.type,
    this.topics,
    this.subtopics,
    this.notes,
    this.source,
    this.attachments,
  });

  factory RevisionLog.fromJson(Map<String, dynamic> j) => RevisionLog(
        id: j['id'] ?? '',
        timestamp: j['timestamp'] ?? '',
        durationMinutes: j['durationMinutes'],
        revisionIndex: j['revisionIndex'] ?? 0,
        type: j['type'] ?? 'STUDY',
        topics: j['topics'] != null ? List<String>.from(j['topics']) : null,
        subtopics:
            j['subtopics'] != null ? List<String>.from(j['subtopics']) : null,
        notes: j['notes'],
        source: j['source'],
        attachments: j['attachments'] != null
            ? (j['attachments'] as List)
                .map((a) => Attachment.fromJson(a))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'revisionIndex': revisionIndex,
        'type': type,
        if (topics != null) 'topics': topics,
        if (subtopics != null) 'subtopics': subtopics,
        if (notes != null) 'notes': notes,
        if (source != null) 'source': source,
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
      };

  RevisionLog copyWith({
    String? id,
    String? timestamp,
    int? durationMinutes,
    int? revisionIndex,
    String? type,
    List<String>? topics,
    List<String>? subtopics,
    String? notes,
    String? source,
    List<Attachment>? attachments,
  }) =>
      RevisionLog(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        revisionIndex: revisionIndex ?? this.revisionIndex,
        type: type ?? this.type,
        topics: topics ?? this.topics,
        subtopics: subtopics ?? this.subtopics,
        notes: notes ?? this.notes,
        source: source ?? this.source,
        attachments: attachments ?? this.attachments,
      );
}

class TrackableItem {
  final String id;
  final String name;
  final int revisionCount;
  final String? lastStudiedAt; // ISO string or null
  final String? nextRevisionAt; // ISO string or null
  final int currentRevisionIndex;
  final List<RevisionLog> logs;
  final String? notes;
  final List<Attachment>? attachments;
  final List<String>? content; // bullet points
  final List<TrackableItem>? subTopics;

  const TrackableItem({
    required this.id,
    required this.name,
    required this.revisionCount,
    this.lastStudiedAt,
    this.nextRevisionAt,
    required this.currentRevisionIndex,
    required this.logs,
    this.notes,
    this.attachments,
    this.content,
    this.subTopics,
  });

  factory TrackableItem.fromJson(Map<String, dynamic> j) => TrackableItem(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        revisionCount: j['revisionCount'] ?? 0,
        lastStudiedAt: j['lastStudiedAt'],
        nextRevisionAt: j['nextRevisionAt'],
        currentRevisionIndex: j['currentRevisionIndex'] ?? 0,
        logs: (j['logs'] as List?)
                ?.map((l) => RevisionLog.fromJson(l))
                .toList() ??
            [],
        notes: j['notes'],
        attachments: j['attachments'] != null
            ? (j['attachments'] as List)
                .map((a) => Attachment.fromJson(a))
                .toList()
            : null,
        content:
            j['content'] != null ? List<String>.from(j['content']) : null,
        subTopics: j['subTopics'] != null
            ? (j['subTopics'] as List)
                .map((s) => TrackableItem.fromJson(s))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'revisionCount': revisionCount,
        'lastStudiedAt': lastStudiedAt,
        'nextRevisionAt': nextRevisionAt,
        'currentRevisionIndex': currentRevisionIndex,
        'logs': logs.map((l) => l.toJson()).toList(),
        if (notes != null) 'notes': notes,
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
        if (content != null) 'content': content,
        if (subTopics != null)
          'subTopics': subTopics!.map((s) => s.toJson()).toList(),
      };

  TrackableItem copyWith({
    String? id,
    String? name,
    int? revisionCount,
    String? lastStudiedAt,
    String? nextRevisionAt,
    int? currentRevisionIndex,
    List<RevisionLog>? logs,
    String? notes,
    List<Attachment>? attachments,
    List<String>? content,
    List<TrackableItem>? subTopics,
  }) =>
      TrackableItem(
        id: id ?? this.id,
        name: name ?? this.name,
        revisionCount: revisionCount ?? this.revisionCount,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
        nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
        currentRevisionIndex:
            currentRevisionIndex ?? this.currentRevisionIndex,
        logs: logs ?? this.logs,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        content: content ?? this.content,
        subTopics: subTopics ?? this.subTopics,
      );
}

class KnowledgeBaseEntry {
  final String pageNumber; // Primary key (String, matches web app)
  final String title;
  final String subject;
  final String system;

  // Page-level SRS
  final int revisionCount;
  final String? firstStudiedAt; // ISO string or null
  final String? lastStudiedAt;
  final String? nextRevisionAt;
  final int currentRevisionIndex;

  // Page-level content
  final int ankiTotal;
  final int ankiCovered;
  final String? ankiTag;
  final List<VideoResource> videoLinks;
  final List<String> tags;
  final String notes;
  final List<String>? keyPoints;
  final List<Attachment>? attachments;
  final List<RevisionLog> logs;

  // Nested topics & subtopics
  final List<TrackableItem> topics;

  // Smart SRS fields
  final int hardCount;
  final int effectiveSrsStep;
  final bool easyFlag;
  final int retentionScore;
  final List<RevisionLogEntry> revisionLog;

  const KnowledgeBaseEntry({
    required this.pageNumber,
    required this.title,
    required this.subject,
    required this.system,
    required this.revisionCount,
    this.firstStudiedAt,
    this.lastStudiedAt,
    this.nextRevisionAt,
    required this.currentRevisionIndex,
    required this.ankiTotal,
    required this.ankiCovered,
    this.ankiTag,
    required this.videoLinks,
    required this.tags,
    required this.notes,
    this.keyPoints,
    this.attachments,
    required this.logs,
    required this.topics,
    this.hardCount = 0,
    this.effectiveSrsStep = 0,
    this.easyFlag = true,
    this.retentionScore = 0,
    this.revisionLog = const [],
  });

  factory KnowledgeBaseEntry.fromJson(Map<String, dynamic> j) =>
      KnowledgeBaseEntry(
        pageNumber: j['pageNumber']?.toString() ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        system: j['system'] ?? '',
        revisionCount: j['revisionCount'] ?? 0,
        firstStudiedAt: j['firstStudiedAt'],
        lastStudiedAt: j['lastStudiedAt'],
        nextRevisionAt: j['nextRevisionAt'],
        currentRevisionIndex: j['currentRevisionIndex'] ?? 0,
        ankiTotal: j['ankiTotal'] ?? 0,
        ankiCovered: j['ankiCovered'] ?? 0,
        ankiTag: j['ankiTag'],
        videoLinks: (j['videoLinks'] as List?)
                ?.map((v) => VideoResource.fromJson(v is Map<String, dynamic>
                    ? v
                    : {'id': '', 'title': '', 'url': v.toString()}))
                .toList() ??
            [],
        tags: List<String>.from(j['tags'] ?? []),
        notes: j['notes'] ?? '',
        keyPoints: j['keyPoints'] != null
            ? List<String>.from(j['keyPoints'])
            : null,
        attachments: j['attachments'] != null
            ? (j['attachments'] as List)
                .map((a) => Attachment.fromJson(a))
                .toList()
            : null,
        logs: (j['logs'] as List?)
                ?.map((l) => RevisionLog.fromJson(l))
                .toList() ??
            [],
        topics: (j['topics'] as List?)
                ?.map((t) => TrackableItem.fromJson(t))
                .toList() ??
            [],
        hardCount: j['hardCount'] ?? 0,
        effectiveSrsStep: j['effectiveSrsStep'] ?? j['currentRevisionIndex'] ?? 0,
        easyFlag: j['easyFlag'] ?? true,
        retentionScore: j['retentionScore'] ?? 0,
        revisionLog: (j['revisionLog'] as List<dynamic>?)
            ?.map((e) => RevisionLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'title': title,
        'subject': subject,
        'system': system,
        'revisionCount': revisionCount,
        'firstStudiedAt': firstStudiedAt,
        'lastStudiedAt': lastStudiedAt,
        'nextRevisionAt': nextRevisionAt,
        'currentRevisionIndex': currentRevisionIndex,
        'ankiTotal': ankiTotal,
        'ankiCovered': ankiCovered,
        if (ankiTag != null) 'ankiTag': ankiTag,
        'videoLinks': videoLinks.map((v) => v.toJson()).toList(),
        'tags': tags,
        'notes': notes,
        if (keyPoints != null) 'keyPoints': keyPoints,
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'topics': topics.map((t) => t.toJson()).toList(),
        'hardCount': hardCount,
        'effectiveSrsStep': effectiveSrsStep,
        'easyFlag': easyFlag,
        'retentionScore': retentionScore,
        'revisionLog': revisionLog.map((e) => e.toJson()).toList(),
      };

  KnowledgeBaseEntry copyWith({
    String? pageNumber,
    String? title,
    String? subject,
    String? system,
    int? revisionCount,
    String? firstStudiedAt,
    String? lastStudiedAt,
    String? nextRevisionAt,
    int? currentRevisionIndex,
    int? ankiTotal,
    int? ankiCovered,
    String? ankiTag,
    List<VideoResource>? videoLinks,
    List<String>? tags,
    String? notes,
    List<String>? keyPoints,
    List<Attachment>? attachments,
    List<RevisionLog>? logs,
    List<TrackableItem>? topics,
    int? hardCount,
    int? effectiveSrsStep,
    bool? easyFlag,
    int? retentionScore,
    List<RevisionLogEntry>? revisionLog,
  }) =>
      KnowledgeBaseEntry(
        pageNumber: pageNumber ?? this.pageNumber,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        system: system ?? this.system,
        revisionCount: revisionCount ?? this.revisionCount,
        firstStudiedAt: firstStudiedAt ?? this.firstStudiedAt,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
        nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
        currentRevisionIndex:
            currentRevisionIndex ?? this.currentRevisionIndex,
        ankiTotal: ankiTotal ?? this.ankiTotal,
        ankiCovered: ankiCovered ?? this.ankiCovered,
        ankiTag: ankiTag ?? this.ankiTag,
        videoLinks: videoLinks ?? this.videoLinks,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
        keyPoints: keyPoints ?? this.keyPoints,
        attachments: attachments ?? this.attachments,
        logs: logs ?? this.logs,
        topics: topics ?? this.topics,
        hardCount: hardCount ?? this.hardCount,
        effectiveSrsStep: effectiveSrsStep ?? this.effectiveSrsStep,
        easyFlag: easyFlag ?? this.easyFlag,
        retentionScore: retentionScore ?? this.retentionScore,
        revisionLog: revisionLog ?? this.revisionLog,
      );
}
