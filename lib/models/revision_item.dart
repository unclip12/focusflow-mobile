// =============================================================
// RevisionItem, RevisionSettings, RevisionLogEntry
// Smart SRS with confidence-based scheduling
// =============================================================

class RevisionSettings {
  final String? mode; // 'fast' | 'balanced' | 'deep' | 'strict'
  final int? targetCount; // 5-15
  final String? carryForwardRule; // 'next_block' | 'end_of_day' | 'next_day'

  const RevisionSettings({this.mode, this.targetCount, this.carryForwardRule});

  factory RevisionSettings.fromJson(Map<String, dynamic> j) => RevisionSettings(
        mode: j['mode'], targetCount: j['targetCount'], carryForwardRule: j['carryForwardRule'],
      );

  Map<String, dynamic> toJson() => {
        if (mode != null) 'mode': mode,
        if (targetCount != null) 'targetCount': targetCount,
        if (carryForwardRule != null) 'carryForwardRule': carryForwardRule,
      };

  RevisionSettings copyWith({String? mode, int? targetCount, String? carryForwardRule}) =>
      RevisionSettings(
        mode: mode ?? this.mode, targetCount: targetCount ?? this.targetCount,
        carryForwardRule: carryForwardRule ?? this.carryForwardRule,
      );
}

// ── Revision Log Entry ──────────────────────────────────────────
class RevisionLogEntry {
  final int revisionNumber;    // which revision step (0, 1, 2, ...)
  final String scheduledAt;    // ISO8601 — when it was scheduled
  final String actualAt;       // ISO8601 — when the user actually responded
  final String response;       // 'hard' | 'good' | 'easy'
  final int hardAttempt;       // if hard: which attempt (1, 2, 3...), else 0
  final int nextScheduledHours;// how many hours until next review
  final String note;           // human-readable description

  const RevisionLogEntry({
    required this.revisionNumber,
    required this.scheduledAt,
    required this.actualAt,
    required this.response,
    this.hardAttempt = 0,
    required this.nextScheduledHours,
    this.note = '',
  });

  factory RevisionLogEntry.fromJson(Map<String, dynamic> j) => RevisionLogEntry(
    revisionNumber: j['revisionNumber'] ?? 0,
    scheduledAt: j['scheduledAt'] ?? '',
    actualAt: j['actualAt'] ?? '',
    response: j['response'] ?? 'good',
    hardAttempt: j['hardAttempt'] ?? 0,
    nextScheduledHours: j['nextScheduledHours'] ?? 0,
    note: j['note'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'revisionNumber': revisionNumber,
    'scheduledAt': scheduledAt,
    'actualAt': actualAt,
    'response': response,
    'hardAttempt': hardAttempt,
    'nextScheduledHours': nextScheduledHours,
    'note': note,
  };
}

// ── Revision Item ───────────────────────────────────────────────
class RevisionItem {
  final String type; // 'PAGE' | 'TOPIC' | 'SUBTOPIC' | 'VIDEO' | 'CHAPTER' | 'UWORLD_Q'
  final String source; // 'FA' | 'SKETCHY_MICRO' | 'SKETCHY_PHARM' | 'PATHOMA' | 'UWORLD' | 'KB'
  final String pageNumber;
  final String title;
  final String parentTitle;
  final String nextRevisionAt;
  final int currentRevisionIndex;
  final String id;
  final String? lastStudiedAt; // ISO8601
  final int totalSteps; // total SRS steps for the current mode

  // ── Smart SRS fields ──────────────────────────────────────────
  final int hardCount;           // times Hard clicked for current pending revision
  final int effectiveSrsStep;    // actual position in SRS interval table
  final bool easyFlag;           // true if never marked hard (green indicator)
  final int retentionScore;      // +10 Good, +15 Easy, -5 Hard
  final List<RevisionLogEntry> revisionLog; // full history

  const RevisionItem({
    required this.type, required this.pageNumber, required this.title, required this.parentTitle,
    required this.nextRevisionAt, required this.currentRevisionIndex, required this.id,
    this.source = 'KB', this.lastStudiedAt, this.totalSteps = 12,
    this.hardCount = 0, this.effectiveSrsStep = 0, this.easyFlag = true,
    this.retentionScore = 0, this.revisionLog = const [],
  });

  factory RevisionItem.fromJson(Map<String, dynamic> j) => RevisionItem(
        type: j['type'] ?? 'PAGE', pageNumber: j['pageNumber']?.toString() ?? '',
        title: j['title'] ?? '', parentTitle: j['parentTitle'] ?? '',
        nextRevisionAt: j['nextRevisionAt'] ?? '', currentRevisionIndex: j['currentRevisionIndex'] ?? 0,
        id: j['id'] ?? '', source: j['source'] ?? 'KB',
        lastStudiedAt: j['lastStudiedAt'], totalSteps: j['totalSteps'] ?? 12,
        hardCount: j['hardCount'] ?? 0,
        effectiveSrsStep: j['effectiveSrsStep'] ?? j['currentRevisionIndex'] ?? 0,
        easyFlag: j['easyFlag'] ?? true,
        retentionScore: j['retentionScore'] ?? 0,
        revisionLog: (j['revisionLog'] as List<dynamic>?)
            ?.map((e) => RevisionLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'type': type, 'pageNumber': pageNumber, 'title': title, 'parentTitle': parentTitle,
        'nextRevisionAt': nextRevisionAt, 'currentRevisionIndex': currentRevisionIndex, 'id': id,
        'source': source, if (lastStudiedAt != null) 'lastStudiedAt': lastStudiedAt,
        'totalSteps': totalSteps,
        'hardCount': hardCount, 'effectiveSrsStep': effectiveSrsStep,
        'easyFlag': easyFlag, 'retentionScore': retentionScore,
        'revisionLog': revisionLog.map((e) => e.toJson()).toList(),
      };

  RevisionItem copyWith({
    String? type, String? pageNumber, String? title, String? parentTitle,
    String? nextRevisionAt, int? currentRevisionIndex, String? id,
    String? source, String? lastStudiedAt, int? totalSteps,
    int? hardCount, int? effectiveSrsStep, bool? easyFlag,
    int? retentionScore, List<RevisionLogEntry>? revisionLog,
  }) => RevisionItem(
        type: type ?? this.type, pageNumber: pageNumber ?? this.pageNumber,
        title: title ?? this.title, parentTitle: parentTitle ?? this.parentTitle,
        nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
        currentRevisionIndex: currentRevisionIndex ?? this.currentRevisionIndex,
        id: id ?? this.id, source: source ?? this.source,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
        totalSteps: totalSteps ?? this.totalSteps,
        hardCount: hardCount ?? this.hardCount,
        effectiveSrsStep: effectiveSrsStep ?? this.effectiveSrsStep,
        easyFlag: easyFlag ?? this.easyFlag,
        retentionScore: retentionScore ?? this.retentionScore,
        revisionLog: revisionLog ?? this.revisionLog,
      );
}
