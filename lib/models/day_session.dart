// =============================================================
// DaySession — tracks active day execution state
// =============================================================

class DaySession {
  final String sessionId;
  final String dateKey;
  final DateTime startedAt;
  final String? currentBlockId;
  final String status; // 'running' | 'paused' | 'completed'

  const DaySession({
    required this.sessionId,
    required this.dateKey,
    required this.startedAt,
    this.currentBlockId,
    required this.status,
  });

  factory DaySession.fromJson(Map<String, dynamic> j) => DaySession(
        sessionId: j['sessionId'] ?? '',
        dateKey: j['dateKey'] ?? '',
        startedAt: DateTime.tryParse(j['startedAt'] ?? '') ?? DateTime.now(),
        currentBlockId: j['currentBlockId'],
        status: j['status'] ?? 'running',
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'dateKey': dateKey,
        'startedAt': startedAt.toIso8601String(),
        if (currentBlockId != null) 'currentBlockId': currentBlockId,
        'status': status,
      };

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  DaySession copyWith({
    String? sessionId,
    String? dateKey,
    DateTime? startedAt,
    String? currentBlockId,
    String? status,
  }) =>
      DaySession(
        sessionId: sessionId ?? this.sessionId,
        dateKey: dateKey ?? this.dateKey,
        startedAt: startedAt ?? this.startedAt,
        currentBlockId: currentBlockId ?? this.currentBlockId,
        status: status ?? this.status,
      );
}
