// =============================================================
// MentorMessage, MentorMemory, BacklogItem, AISettings — types.ts
// =============================================================

class MentorMessage {
  final String id;
  final String role; // 'user' | 'model'
  final String text;
  final String timestamp; // ISO
  final bool? isSystemAction;
  final String? actionType; // 'VIEW_PLAN' | 'BLOCK_CONTROL' | 'CONFIRM_IMPORT'
  final dynamic actionPayload;

  const MentorMessage({
    required this.id, required this.role, required this.text, required this.timestamp,
    this.isSystemAction, this.actionType, this.actionPayload,
  });

  factory MentorMessage.fromJson(Map<String, dynamic> j) => MentorMessage(
        id: j['id'] ?? '', role: j['role'] ?? 'user', text: j['text'] ?? '',
        timestamp: j['timestamp'] ?? '', isSystemAction: j['isSystemAction'],
        actionType: j['actionType'], actionPayload: j['actionPayload'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'role': role, 'text': text, 'timestamp': timestamp,
        if (isSystemAction != null) 'isSystemAction': isSystemAction,
        if (actionType != null) 'actionType': actionType,
        if (actionPayload != null) 'actionPayload': actionPayload,
      };

  MentorMessage copyWith({
    String? id, String? role, String? text, String? timestamp,
    bool? isSystemAction, String? actionType, dynamic actionPayload,
  }) => MentorMessage(
        id: id ?? this.id, role: role ?? this.role, text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp, isSystemAction: isSystemAction ?? this.isSystemAction,
        actionType: actionType ?? this.actionType, actionPayload: actionPayload ?? this.actionPayload,
      );
}

class BacklogItem {
  final String id;
  final String dateOriginal;
  final String task;
  final int estimatedMinutes;
  final String? reason;
  final String? status; // 'PENDING' | 'SKIPPED_PERMANENTLY' | 'DONE'

  const BacklogItem({
    required this.id, required this.dateOriginal, required this.task,
    required this.estimatedMinutes, this.reason, this.status,
  });

  factory BacklogItem.fromJson(Map<String, dynamic> j) => BacklogItem(
        id: j['id'] ?? '', dateOriginal: j['dateOriginal'] ?? '', task: j['task'] ?? '',
        estimatedMinutes: j['estimatedMinutes'] ?? 0, reason: j['reason'], status: j['status'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'dateOriginal': dateOriginal, 'task': task, 'estimatedMinutes': estimatedMinutes,
        if (reason != null) 'reason': reason, if (status != null) 'status': status,
      };

  BacklogItem copyWith({
    String? id, String? dateOriginal, String? task, int? estimatedMinutes, String? reason, String? status,
  }) => BacklogItem(
        id: id ?? this.id, dateOriginal: dateOriginal ?? this.dateOriginal, task: task ?? this.task,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        reason: reason ?? this.reason, status: status ?? this.status,
      );
}

class MentorMemory {
  final String? examTarget;
  final String? examDate;
  final int? averageOverrunMinutes;
  final String? learningStyle;
  final List<String>? typicalDelaysIn;
  final String? preferredTone; // 'strict' | 'encouraging' | 'balanced'
  final List<BacklogItem>? backlog;
  final String? notes;
  final String? lastUpdated;

  const MentorMemory({
    this.examTarget, this.examDate, this.averageOverrunMinutes, this.learningStyle,
    this.typicalDelaysIn, this.preferredTone, this.backlog, this.notes, this.lastUpdated,
  });

  factory MentorMemory.fromJson(Map<String, dynamic> j) => MentorMemory(
        examTarget: j['examTarget'], examDate: j['examDate'],
        averageOverrunMinutes: j['averageOverrunMinutes'], learningStyle: j['learningStyle'],
        typicalDelaysIn: j['typicalDelaysIn'] != null ? List<String>.from(j['typicalDelaysIn']) : null,
        preferredTone: j['preferredTone'],
        backlog: j['backlog'] != null ? (j['backlog'] as List).map((b) => BacklogItem.fromJson(b)).toList() : null,
        notes: j['notes'], lastUpdated: j['lastUpdated'],
      );

  Map<String, dynamic> toJson() => {
        if (examTarget != null) 'examTarget': examTarget,
        if (examDate != null) 'examDate': examDate,
        if (averageOverrunMinutes != null) 'averageOverrunMinutes': averageOverrunMinutes,
        if (learningStyle != null) 'learningStyle': learningStyle,
        if (typicalDelaysIn != null) 'typicalDelaysIn': typicalDelaysIn,
        if (preferredTone != null) 'preferredTone': preferredTone,
        if (backlog != null) 'backlog': backlog!.map((b) => b.toJson()).toList(),
        if (notes != null) 'notes': notes,
        if (lastUpdated != null) 'lastUpdated': lastUpdated,
      };

  MentorMemory copyWith({
    String? examTarget, String? examDate, int? averageOverrunMinutes, String? learningStyle,
    List<String>? typicalDelaysIn, String? preferredTone, List<BacklogItem>? backlog,
    String? notes, String? lastUpdated,
  }) => MentorMemory(
        examTarget: examTarget ?? this.examTarget, examDate: examDate ?? this.examDate,
        averageOverrunMinutes: averageOverrunMinutes ?? this.averageOverrunMinutes,
        learningStyle: learningStyle ?? this.learningStyle,
        typicalDelaysIn: typicalDelaysIn ?? this.typicalDelaysIn,
        preferredTone: preferredTone ?? this.preferredTone,
        backlog: backlog ?? this.backlog, notes: notes ?? this.notes,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class AISettings {
  final String? personalityMode; // 'calm' | 'balanced' | 'strict'
  final String? talkStyle; // 'short' | 'teaching' | 'motivational'
  final int? disciplineLevel; // 1-5
  final Map<String, bool>? memoryPermissions;

  const AISettings({this.personalityMode, this.talkStyle, this.disciplineLevel, this.memoryPermissions});

  factory AISettings.fromJson(Map<String, dynamic> j) => AISettings(
        personalityMode: j['personalityMode'], talkStyle: j['talkStyle'],
        disciplineLevel: j['disciplineLevel'],
        memoryPermissions: j['memoryPermissions'] != null ? Map<String, bool>.from(j['memoryPermissions']) : null,
      );

  Map<String, dynamic> toJson() => {
        if (personalityMode != null) 'personalityMode': personalityMode,
        if (talkStyle != null) 'talkStyle': talkStyle,
        if (disciplineLevel != null) 'disciplineLevel': disciplineLevel,
        if (memoryPermissions != null) 'memoryPermissions': memoryPermissions,
      };

  AISettings copyWith({String? personalityMode, String? talkStyle, int? disciplineLevel, Map<String, bool>? memoryPermissions}) =>
      AISettings(
        personalityMode: personalityMode ?? this.personalityMode, talkStyle: talkStyle ?? this.talkStyle,
        disciplineLevel: disciplineLevel ?? this.disciplineLevel,
        memoryPermissions: memoryPermissions ?? this.memoryPermissions,
      );
}
