// =============================================================
// RevisionItem, RevisionSettings — matches types.ts
// =============================================================

class RevisionSettings {
  final String? mode; // 'fast' | 'balanced' | 'deep'
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

class RevisionItem {
  final String type; // 'PAGE' | 'TOPIC' | 'SUBTOPIC'
  final String pageNumber;
  final String title;
  final String parentTitle;
  final String nextRevisionAt;
  final int currentRevisionIndex;
  final String id;

  const RevisionItem({
    required this.type, required this.pageNumber, required this.title, required this.parentTitle,
    required this.nextRevisionAt, required this.currentRevisionIndex, required this.id,
  });

  factory RevisionItem.fromJson(Map<String, dynamic> j) => RevisionItem(
        type: j['type'] ?? 'PAGE', pageNumber: j['pageNumber']?.toString() ?? '',
        title: j['title'] ?? '', parentTitle: j['parentTitle'] ?? '',
        nextRevisionAt: j['nextRevisionAt'] ?? '', currentRevisionIndex: j['currentRevisionIndex'] ?? 0,
        id: j['id'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'type': type, 'pageNumber': pageNumber, 'title': title, 'parentTitle': parentTitle,
        'nextRevisionAt': nextRevisionAt, 'currentRevisionIndex': currentRevisionIndex, 'id': id,
      };

  RevisionItem copyWith({
    String? type, String? pageNumber, String? title, String? parentTitle,
    String? nextRevisionAt, int? currentRevisionIndex, String? id,
  }) => RevisionItem(
        type: type ?? this.type, pageNumber: pageNumber ?? this.pageNumber,
        title: title ?? this.title, parentTitle: parentTitle ?? this.parentTitle,
        nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
        currentRevisionIndex: currentRevisionIndex ?? this.currentRevisionIndex,
        id: id ?? this.id,
      );
}
