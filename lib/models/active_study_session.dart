import 'package:focusflow_mobile/models/day_plan.dart';

class ActiveStudySessionKind {
  ActiveStudySessionKind._();

  static const String studyFlow = 'study_flow';
  static const String studySession = 'study_session';
  static const String focusSession = 'focus_session';
}

class ActiveStudySession {
  final String sessionId;
  final String kind;
  final String dateKey;
  final String title;
  final String? blockId;
  final String startedAt;
  final bool isPaused;
  final int currentTaskIndex;
  final int currentTaskElapsedSeconds;
  final String? currentTaskRunStartedAt;
  final int currentPage;
  final int targetPages;
  final int pagesCompletedInSession;
  final List<int> ankiPendingPages;
  final bool showAnkiPrompt;
  final List<Map<String, dynamic>> queuedTasks;
  final List<BlockSegment> segments;
  final List<BlockInterruption> interruptions;

  const ActiveStudySession({
    required this.sessionId,
    required this.kind,
    required this.dateKey,
    required this.title,
    required this.startedAt,
    this.blockId,
    this.isPaused = false,
    this.currentTaskIndex = 0,
    this.currentTaskElapsedSeconds = 0,
    this.currentTaskRunStartedAt,
    this.currentPage = 0,
    this.targetPages = 0,
    this.pagesCompletedInSession = 0,
    this.ankiPendingPages = const <int>[],
    this.showAnkiPrompt = false,
    this.queuedTasks = const <Map<String, dynamic>>[],
    this.segments = const <BlockSegment>[],
    this.interruptions = const <BlockInterruption>[],
  });

  factory ActiveStudySession.fromJson(Map<String, dynamic> json) {
    return ActiveStudySession(
      sessionId: json['sessionId']?.toString() ?? '',
      kind: json['kind']?.toString() ?? ActiveStudySessionKind.studyFlow,
      dateKey: json['dateKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      blockId: json['blockId']?.toString(),
      startedAt: json['startedAt']?.toString() ?? '',
      isPaused: json['isPaused'] as bool? ?? false,
      currentTaskIndex: json['currentTaskIndex'] as int? ?? 0,
      currentTaskElapsedSeconds: json['currentTaskElapsedSeconds'] as int? ?? 0,
      currentTaskRunStartedAt: json['currentTaskRunStartedAt']?.toString(),
      currentPage: json['currentPage'] as int? ?? 0,
      targetPages: json['targetPages'] as int? ?? 0,
      pagesCompletedInSession: json['pagesCompletedInSession'] as int? ?? 0,
      ankiPendingPages: (json['ankiPendingPages'] as List?)
              ?.map((value) => int.tryParse(value.toString()))
              .whereType<int>()
              .toList() ??
          const <int>[],
      showAnkiPrompt: json['showAnkiPrompt'] as bool? ?? false,
      queuedTasks: (json['queuedTasks'] as List?)
              ?.whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList() ??
          const <Map<String, dynamic>>[],
      segments: (json['segments'] as List?)
              ?.whereType<Map>()
              .map((entry) => BlockSegment.fromJson(Map<String, dynamic>.from(entry)))
              .toList() ??
          const <BlockSegment>[],
      interruptions: (json['interruptions'] as List?)
              ?.whereType<Map>()
              .map((entry) => BlockInterruption.fromJson(Map<String, dynamic>.from(entry)))
              .toList() ??
          const <BlockInterruption>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'kind': kind,
      'dateKey': dateKey,
      'title': title,
      if (blockId != null) 'blockId': blockId,
      'startedAt': startedAt,
      'isPaused': isPaused,
      'currentTaskIndex': currentTaskIndex,
      'currentTaskElapsedSeconds': currentTaskElapsedSeconds,
      if (currentTaskRunStartedAt != null)
        'currentTaskRunStartedAt': currentTaskRunStartedAt,
      'currentPage': currentPage,
      'targetPages': targetPages,
      'pagesCompletedInSession': pagesCompletedInSession,
      'ankiPendingPages': ankiPendingPages,
      'showAnkiPrompt': showAnkiPrompt,
      'queuedTasks': queuedTasks,
      'segments': segments.map((entry) => entry.toJson()).toList(),
      'interruptions': interruptions.map((entry) => entry.toJson()).toList(),
    };
  }

  ActiveStudySession copyWith({
    String? sessionId,
    String? kind,
    String? dateKey,
    String? title,
    Object? blockId = _copySentinel,
    String? startedAt,
    bool? isPaused,
    int? currentTaskIndex,
    int? currentTaskElapsedSeconds,
    Object? currentTaskRunStartedAt = _copySentinel,
    int? currentPage,
    int? targetPages,
    int? pagesCompletedInSession,
    List<int>? ankiPendingPages,
    bool? showAnkiPrompt,
    List<Map<String, dynamic>>? queuedTasks,
    List<BlockSegment>? segments,
    List<BlockInterruption>? interruptions,
  }) {
    return ActiveStudySession(
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      blockId: identical(blockId, _copySentinel)
          ? this.blockId
          : blockId as String?,
      startedAt: startedAt ?? this.startedAt,
      isPaused: isPaused ?? this.isPaused,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      currentTaskElapsedSeconds:
          currentTaskElapsedSeconds ?? this.currentTaskElapsedSeconds,
      currentTaskRunStartedAt:
          identical(currentTaskRunStartedAt, _copySentinel)
              ? this.currentTaskRunStartedAt
              : currentTaskRunStartedAt as String?,
      currentPage: currentPage ?? this.currentPage,
      targetPages: targetPages ?? this.targetPages,
      pagesCompletedInSession:
          pagesCompletedInSession ?? this.pagesCompletedInSession,
      ankiPendingPages: ankiPendingPages ?? this.ankiPendingPages,
      showAnkiPrompt: showAnkiPrompt ?? this.showAnkiPrompt,
      queuedTasks: queuedTasks ?? this.queuedTasks,
      segments: segments ?? this.segments,
      interruptions: interruptions ?? this.interruptions,
    );
  }

  static const Object _copySentinel = Object();
}
