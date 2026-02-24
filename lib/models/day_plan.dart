// =============================================================
// DayPlan, Block, BlockTask, BlockSegment, etc.
// Matches types.ts — the richest model in the app.
// =============================================================

import 'package:focusflow_mobile/utils/constants.dart';
import 'attachment.dart';

class DayPlanVideo {
  final String? subject;
  final String? topic;
  final double totalContentHours;
  final double playbackRate;
  final double effectiveStudyMinutes;

  const DayPlanVideo({
    this.subject,
    this.topic,
    required this.totalContentHours,
    required this.playbackRate,
    required this.effectiveStudyMinutes,
  });

  factory DayPlanVideo.fromJson(Map<String, dynamic> j) => DayPlanVideo(
        subject: j['subject'],
        topic: j['topic'],
        totalContentHours: (j['totalContentHours'] ?? 0).toDouble(),
        playbackRate: (j['playbackRate'] ?? 1.0).toDouble(),
        effectiveStudyMinutes: (j['effectiveStudyMinutes'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (subject != null) 'subject': subject,
        if (topic != null) 'topic': topic,
        'totalContentHours': totalContentHours,
        'playbackRate': playbackRate,
        'effectiveStudyMinutes': effectiveStudyMinutes,
      };

  DayPlanVideo copyWith({
    String? subject,
    String? topic,
    double? totalContentHours,
    double? playbackRate,
    double? effectiveStudyMinutes,
  }) =>
      DayPlanVideo(
        subject: subject ?? this.subject,
        topic: topic ?? this.topic,
        totalContentHours: totalContentHours ?? this.totalContentHours,
        playbackRate: playbackRate ?? this.playbackRate,
        effectiveStudyMinutes:
            effectiveStudyMinutes ?? this.effectiveStudyMinutes,
      );
}

class DayPlanBreak {
  final String label;
  final String? startTime;
  final String? endTime;
  final int durationMinutes;

  const DayPlanBreak({
    required this.label,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
  });

  factory DayPlanBreak.fromJson(Map<String, dynamic> j) => DayPlanBreak(
        label: j['label'] ?? '',
        startTime: j['startTime'],
        endTime: j['endTime'],
        durationMinutes: j['durationMinutes'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        'durationMinutes': durationMinutes,
      };

  DayPlanBreak copyWith({
    String? label,
    String? startTime,
    String? endTime,
    int? durationMinutes,
  }) =>
      DayPlanBreak(
        label: label ?? this.label,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );
}

class BlockSegment {
  final String start; // HH:mm or ISO
  final String? end;

  const BlockSegment({required this.start, this.end});

  factory BlockSegment.fromJson(Map<String, dynamic> j) => BlockSegment(
        start: j['start'] ?? '',
        end: j['end'],
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        if (end != null) 'end': end,
      };

  BlockSegment copyWith({String? start, String? end}) => BlockSegment(
        start: start ?? this.start,
        end: end ?? this.end,
      );
}

class BlockInterruption {
  final String start;
  final String? end;
  final String reason;

  const BlockInterruption({
    required this.start,
    this.end,
    required this.reason,
  });

  factory BlockInterruption.fromJson(Map<String, dynamic> j) =>
      BlockInterruption(
        start: j['start'] ?? '',
        end: j['end'],
        reason: j['reason'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        if (end != null) 'end': end,
        'reason': reason,
      };

  BlockInterruption copyWith({String? start, String? end, String? reason}) =>
      BlockInterruption(
        start: start ?? this.start,
        end: end ?? this.end,
        reason: reason ?? this.reason,
      );
}

class TaskExecution {
  final bool completed;
  final String? note;

  const TaskExecution({required this.completed, this.note});

  factory TaskExecution.fromJson(Map<String, dynamic> j) => TaskExecution(
        completed: j['completed'] ?? false,
        note: j['note'],
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        if (note != null) 'note': note,
      };

  TaskExecution copyWith({bool? completed, String? note}) => TaskExecution(
        completed: completed ?? this.completed,
        note: note ?? this.note,
      );
}

class BlockTaskMeta {
  final int? pageNumber;
  final int? count;
  final String? topic;
  final String? system;
  final String? subject;
  final List<String>? subtopics;
  final String? url;
  final int? videoDuration;
  final int? videoStartTime;
  final int? videoEndTime;
  final double? playbackSpeed;
  final int? slideStart;
  final int? slideEnd;
  final String? logStart; // HH:mm
  final String? logEnd;

  const BlockTaskMeta({
    this.pageNumber,
    this.count,
    this.topic,
    this.system,
    this.subject,
    this.subtopics,
    this.url,
    this.videoDuration,
    this.videoStartTime,
    this.videoEndTime,
    this.playbackSpeed,
    this.slideStart,
    this.slideEnd,
    this.logStart,
    this.logEnd,
  });

  factory BlockTaskMeta.fromJson(Map<String, dynamic> j) => BlockTaskMeta(
        pageNumber: j['pageNumber'],
        count: j['count'],
        topic: j['topic'],
        system: j['system'],
        subject: j['subject'],
        subtopics: j['subtopics'] != null
            ? List<String>.from(j['subtopics'])
            : null,
        url: j['url'],
        videoDuration: j['videoDuration'],
        videoStartTime: j['videoStartTime'],
        videoEndTime: j['videoEndTime'],
        playbackSpeed: (j['playbackSpeed'] as num?)?.toDouble(),
        slideStart: j['slideStart'],
        slideEnd: j['slideEnd'],
        logStart: j['logStart'],
        logEnd: j['logEnd'],
      );

  Map<String, dynamic> toJson() => {
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (count != null) 'count': count,
        if (topic != null) 'topic': topic,
        if (system != null) 'system': system,
        if (subject != null) 'subject': subject,
        if (subtopics != null) 'subtopics': subtopics,
        if (url != null) 'url': url,
        if (videoDuration != null) 'videoDuration': videoDuration,
        if (videoStartTime != null) 'videoStartTime': videoStartTime,
        if (videoEndTime != null) 'videoEndTime': videoEndTime,
        if (playbackSpeed != null) 'playbackSpeed': playbackSpeed,
        if (slideStart != null) 'slideStart': slideStart,
        if (slideEnd != null) 'slideEnd': slideEnd,
        if (logStart != null) 'logStart': logStart,
        if (logEnd != null) 'logEnd': logEnd,
      };

  BlockTaskMeta copyWith({
    int? pageNumber,
    int? count,
    String? topic,
    String? system,
    String? subject,
    List<String>? subtopics,
    String? url,
    int? videoDuration,
    int? videoStartTime,
    int? videoEndTime,
    double? playbackSpeed,
    int? slideStart,
    int? slideEnd,
    String? logStart,
    String? logEnd,
  }) =>
      BlockTaskMeta(
        pageNumber: pageNumber ?? this.pageNumber,
        count: count ?? this.count,
        topic: topic ?? this.topic,
        system: system ?? this.system,
        subject: subject ?? this.subject,
        subtopics: subtopics ?? this.subtopics,
        url: url ?? this.url,
        videoDuration: videoDuration ?? this.videoDuration,
        videoStartTime: videoStartTime ?? this.videoStartTime,
        videoEndTime: videoEndTime ?? this.videoEndTime,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        slideStart: slideStart ?? this.slideStart,
        slideEnd: slideEnd ?? this.slideEnd,
        logStart: logStart ?? this.logStart,
        logEnd: logEnd ?? this.logEnd,
      );
}

class BlockTask {
  final String id;
  final String type; // 'FA' | 'VIDEO' | 'ANKI' | 'QBANK' | 'OTHER' | 'FMGE' | 'REVISION'
  final String detail;
  final bool completed;
  final BlockTaskMeta? meta;
  final TaskExecution? execution;

  const BlockTask({
    required this.id,
    required this.type,
    required this.detail,
    required this.completed,
    this.meta,
    this.execution,
  });

  factory BlockTask.fromJson(Map<String, dynamic> j) => BlockTask(
        id: j['id'] ?? '',
        type: j['type'] ?? 'OTHER',
        detail: j['detail'] ?? '',
        completed: j['completed'] ?? false,
        meta: j['meta'] != null ? BlockTaskMeta.fromJson(j['meta']) : null,
        execution: j['execution'] != null
            ? TaskExecution.fromJson(j['execution'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'detail': detail,
        'completed': completed,
        if (meta != null) 'meta': meta!.toJson(),
        if (execution != null) 'execution': execution!.toJson(),
      };

  BlockTask copyWith({
    String? id,
    String? type,
    String? detail,
    bool? completed,
    BlockTaskMeta? meta,
    TaskExecution? execution,
  }) =>
      BlockTask(
        id: id ?? this.id,
        type: type ?? this.type,
        detail: detail ?? this.detail,
        completed: completed ?? this.completed,
        meta: meta ?? this.meta,
        execution: execution ?? this.execution,
      );
}

class Block {
  final String id;
  final int index;
  final String date; // same as dayPlan.date
  final String plannedStartTime; // "HH:mm"
  final String plannedEndTime;
  final BlockType type;
  final String title;
  final String? description;
  final List<BlockTask>? tasks;

  final String? relatedVideoId;
  final List<int>? relatedFaPages;
  final Map<String, dynamic>? relatedAnkiInfo;
  final Map<String, dynamic>? relatedQbankInfo;

  final int plannedDurationMinutes;

  // Actual execution
  final String? actualStartTime;
  final String? actualEndTime;
  final int? actualDurationMinutes;
  final BlockStatus status;

  // Granular timeline
  final List<BlockSegment>? segments;
  final List<BlockInterruption>? interruptions;
  final String? actualNotes;

  // Reflection & carry forward
  final String? completionStatus; // 'COMPLETED' | 'PARTIAL' | 'NOT_DONE'
  final List<int>? actualPagesCovered;
  final List<int>? carryForwardPages;
  final String? reflectionNotes;
  final String? rescheduledTo;

  // Sync tracking
  final List<String>? generatedLogIds;
  final List<String>? generatedTimeLogIds;

  // UI
  final bool? isVirtual;

  const Block({
    required this.id,
    required this.index,
    required this.date,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.type,
    required this.title,
    this.description,
    this.tasks,
    this.relatedVideoId,
    this.relatedFaPages,
    this.relatedAnkiInfo,
    this.relatedQbankInfo,
    required this.plannedDurationMinutes,
    this.actualStartTime,
    this.actualEndTime,
    this.actualDurationMinutes,
    required this.status,
    this.segments,
    this.interruptions,
    this.actualNotes,
    this.completionStatus,
    this.actualPagesCovered,
    this.carryForwardPages,
    this.reflectionNotes,
    this.rescheduledTo,
    this.generatedLogIds,
    this.generatedTimeLogIds,
    this.isVirtual,
  });

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        id: j['id'] ?? '',
        index: j['index'] ?? 0,
        date: j['date'] ?? '',
        plannedStartTime: j['plannedStartTime'] ?? '',
        plannedEndTime: j['plannedEndTime'] ?? '',
        type: BlockType.fromString(j['type'] ?? 'OTHER'),
        title: j['title'] ?? '',
        description: j['description'],
        tasks: j['tasks'] != null
            ? (j['tasks'] as List)
                .map((t) => BlockTask.fromJson(t))
                .toList()
            : null,
        relatedVideoId: j['relatedVideoId'],
        relatedFaPages: j['relatedFaPages'] != null
            ? List<int>.from(j['relatedFaPages'])
            : null,
        relatedAnkiInfo: j['relatedAnkiInfo'] != null
            ? Map<String, dynamic>.from(j['relatedAnkiInfo'])
            : null,
        relatedQbankInfo: j['relatedQbankInfo'] != null
            ? Map<String, dynamic>.from(j['relatedQbankInfo'])
            : null,
        plannedDurationMinutes: j['plannedDurationMinutes'] ?? 0,
        actualStartTime: j['actualStartTime'],
        actualEndTime: j['actualEndTime'],
        actualDurationMinutes: j['actualDurationMinutes'],
        status: BlockStatus.fromString(j['status'] ?? 'NOT_STARTED'),
        segments: j['segments'] != null
            ? (j['segments'] as List)
                .map((s) => BlockSegment.fromJson(s))
                .toList()
            : null,
        interruptions: j['interruptions'] != null
            ? (j['interruptions'] as List)
                .map((i) => BlockInterruption.fromJson(i))
                .toList()
            : null,
        actualNotes: j['actualNotes'],
        completionStatus: j['completionStatus'],
        actualPagesCovered: j['actualPagesCovered'] != null
            ? List<int>.from(j['actualPagesCovered'])
            : null,
        carryForwardPages: j['carryForwardPages'] != null
            ? List<int>.from(j['carryForwardPages'])
            : null,
        reflectionNotes: j['reflectionNotes'],
        rescheduledTo: j['rescheduledTo'],
        generatedLogIds: j['generatedLogIds'] != null
            ? List<String>.from(j['generatedLogIds'])
            : null,
        generatedTimeLogIds: j['generatedTimeLogIds'] != null
            ? List<String>.from(j['generatedTimeLogIds'])
            : null,
        isVirtual: j['isVirtual'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'index': index,
        'date': date,
        'plannedStartTime': plannedStartTime,
        'plannedEndTime': plannedEndTime,
        'type': type.value,
        'title': title,
        if (description != null) 'description': description,
        if (tasks != null) 'tasks': tasks!.map((t) => t.toJson()).toList(),
        if (relatedVideoId != null) 'relatedVideoId': relatedVideoId,
        if (relatedFaPages != null) 'relatedFaPages': relatedFaPages,
        if (relatedAnkiInfo != null) 'relatedAnkiInfo': relatedAnkiInfo,
        if (relatedQbankInfo != null) 'relatedQbankInfo': relatedQbankInfo,
        'plannedDurationMinutes': plannedDurationMinutes,
        if (actualStartTime != null) 'actualStartTime': actualStartTime,
        if (actualEndTime != null) 'actualEndTime': actualEndTime,
        if (actualDurationMinutes != null)
          'actualDurationMinutes': actualDurationMinutes,
        'status': status.value,
        if (segments != null)
          'segments': segments!.map((s) => s.toJson()).toList(),
        if (interruptions != null)
          'interruptions': interruptions!.map((i) => i.toJson()).toList(),
        if (actualNotes != null) 'actualNotes': actualNotes,
        if (completionStatus != null) 'completionStatus': completionStatus,
        if (actualPagesCovered != null)
          'actualPagesCovered': actualPagesCovered,
        if (carryForwardPages != null) 'carryForwardPages': carryForwardPages,
        if (reflectionNotes != null) 'reflectionNotes': reflectionNotes,
        if (rescheduledTo != null) 'rescheduledTo': rescheduledTo,
        if (generatedLogIds != null) 'generatedLogIds': generatedLogIds,
        if (generatedTimeLogIds != null)
          'generatedTimeLogIds': generatedTimeLogIds,
        if (isVirtual != null) 'isVirtual': isVirtual,
      };

  Block copyWith({
    String? id,
    int? index,
    String? date,
    String? plannedStartTime,
    String? plannedEndTime,
    BlockType? type,
    String? title,
    String? description,
    List<BlockTask>? tasks,
    String? relatedVideoId,
    List<int>? relatedFaPages,
    Map<String, dynamic>? relatedAnkiInfo,
    Map<String, dynamic>? relatedQbankInfo,
    int? plannedDurationMinutes,
    String? actualStartTime,
    String? actualEndTime,
    int? actualDurationMinutes,
    BlockStatus? status,
    List<BlockSegment>? segments,
    List<BlockInterruption>? interruptions,
    String? actualNotes,
    String? completionStatus,
    List<int>? actualPagesCovered,
    List<int>? carryForwardPages,
    String? reflectionNotes,
    String? rescheduledTo,
    List<String>? generatedLogIds,
    List<String>? generatedTimeLogIds,
    bool? isVirtual,
  }) =>
      Block(
        id: id ?? this.id,
        index: index ?? this.index,
        date: date ?? this.date,
        plannedStartTime: plannedStartTime ?? this.plannedStartTime,
        plannedEndTime: plannedEndTime ?? this.plannedEndTime,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        tasks: tasks ?? this.tasks,
        relatedVideoId: relatedVideoId ?? this.relatedVideoId,
        relatedFaPages: relatedFaPages ?? this.relatedFaPages,
        relatedAnkiInfo: relatedAnkiInfo ?? this.relatedAnkiInfo,
        relatedQbankInfo: relatedQbankInfo ?? this.relatedQbankInfo,
        plannedDurationMinutes:
            plannedDurationMinutes ?? this.plannedDurationMinutes,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime: actualEndTime ?? this.actualEndTime,
        actualDurationMinutes:
            actualDurationMinutes ?? this.actualDurationMinutes,
        status: status ?? this.status,
        segments: segments ?? this.segments,
        interruptions: interruptions ?? this.interruptions,
        actualNotes: actualNotes ?? this.actualNotes,
        completionStatus: completionStatus ?? this.completionStatus,
        actualPagesCovered: actualPagesCovered ?? this.actualPagesCovered,
        carryForwardPages: carryForwardPages ?? this.carryForwardPages,
        reflectionNotes: reflectionNotes ?? this.reflectionNotes,
        rescheduledTo: rescheduledTo ?? this.rescheduledTo,
        generatedLogIds: generatedLogIds ?? this.generatedLogIds,
        generatedTimeLogIds: generatedTimeLogIds ?? this.generatedTimeLogIds,
        isVirtual: isVirtual ?? this.isVirtual,
      );
}

class DayPlan {
  final String date; // YYYY-MM-DD
  final List<int> faPages;
  final int faPagesCount;
  final int? faStudyMinutesPlanned;
  final List<DayPlanVideo> videos;
  final Map<String, dynamic>? anki; // { totalCards, plannedMinutes, ... }
  final Map<String, dynamic>? qbank;
  final String notesFromUser;
  final String notesFromAI;
  final List<Attachment> attachments;
  final List<DayPlanBreak> breaks;
  final List<Block>? blocks;
  final int? blockDurationSetting;
  final String? startTimePlanned; // HH:mm
  final String? startTimeActual;
  final String? estimatedEndTime;
  final int totalStudyMinutesPlanned;
  final int totalBreakMinutes;

  const DayPlan({
    required this.date,
    required this.faPages,
    required this.faPagesCount,
    this.faStudyMinutesPlanned,
    required this.videos,
    this.anki,
    this.qbank,
    required this.notesFromUser,
    required this.notesFromAI,
    required this.attachments,
    required this.breaks,
    this.blocks,
    this.blockDurationSetting,
    this.startTimePlanned,
    this.startTimeActual,
    this.estimatedEndTime,
    required this.totalStudyMinutesPlanned,
    required this.totalBreakMinutes,
  });

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        date: j['date'] ?? '',
        faPages: List<int>.from(j['faPages'] ?? []),
        faPagesCount: j['faPagesCount'] ?? 0,
        faStudyMinutesPlanned: j['faStudyMinutesPlanned'],
        videos: (j['videos'] as List?)
                ?.map((v) => DayPlanVideo.fromJson(v))
                .toList() ??
            [],
        anki: j['anki'] != null
            ? Map<String, dynamic>.from(j['anki'])
            : null,
        qbank: j['qbank'] != null
            ? Map<String, dynamic>.from(j['qbank'])
            : null,
        notesFromUser: j['notesFromUser'] ?? '',
        notesFromAI: j['notesFromAI'] ?? '',
        attachments: (j['attachments'] as List?)
                ?.map((a) => Attachment.fromJson(a))
                .toList() ??
            [],
        breaks: (j['breaks'] as List?)
                ?.map((b) => DayPlanBreak.fromJson(b))
                .toList() ??
            [],
        blocks: j['blocks'] != null
            ? (j['blocks'] as List)
                .map((b) => Block.fromJson(b))
                .toList()
            : null,
        blockDurationSetting: j['blockDurationSetting'],
        startTimePlanned: j['startTimePlanned'],
        startTimeActual: j['startTimeActual'],
        estimatedEndTime: j['estimatedEndTime'],
        totalStudyMinutesPlanned: j['totalStudyMinutesPlanned'] ?? 0,
        totalBreakMinutes: j['totalBreakMinutes'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'faPages': faPages,
        'faPagesCount': faPagesCount,
        if (faStudyMinutesPlanned != null)
          'faStudyMinutesPlanned': faStudyMinutesPlanned,
        'videos': videos.map((v) => v.toJson()).toList(),
        if (anki != null) 'anki': anki,
        if (qbank != null) 'qbank': qbank,
        'notesFromUser': notesFromUser,
        'notesFromAI': notesFromAI,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'breaks': breaks.map((b) => b.toJson()).toList(),
        if (blocks != null) 'blocks': blocks!.map((b) => b.toJson()).toList(),
        if (blockDurationSetting != null)
          'blockDurationSetting': blockDurationSetting,
        if (startTimePlanned != null) 'startTimePlanned': startTimePlanned,
        if (startTimeActual != null) 'startTimeActual': startTimeActual,
        if (estimatedEndTime != null) 'estimatedEndTime': estimatedEndTime,
        'totalStudyMinutesPlanned': totalStudyMinutesPlanned,
        'totalBreakMinutes': totalBreakMinutes,
      };

  DayPlan copyWith({
    String? date,
    List<int>? faPages,
    int? faPagesCount,
    int? faStudyMinutesPlanned,
    List<DayPlanVideo>? videos,
    Map<String, dynamic>? anki,
    Map<String, dynamic>? qbank,
    String? notesFromUser,
    String? notesFromAI,
    List<Attachment>? attachments,
    List<DayPlanBreak>? breaks,
    List<Block>? blocks,
    int? blockDurationSetting,
    String? startTimePlanned,
    String? startTimeActual,
    String? estimatedEndTime,
    int? totalStudyMinutesPlanned,
    int? totalBreakMinutes,
  }) =>
      DayPlan(
        date: date ?? this.date,
        faPages: faPages ?? this.faPages,
        faPagesCount: faPagesCount ?? this.faPagesCount,
        faStudyMinutesPlanned:
            faStudyMinutesPlanned ?? this.faStudyMinutesPlanned,
        videos: videos ?? this.videos,
        anki: anki ?? this.anki,
        qbank: qbank ?? this.qbank,
        notesFromUser: notesFromUser ?? this.notesFromUser,
        notesFromAI: notesFromAI ?? this.notesFromAI,
        attachments: attachments ?? this.attachments,
        breaks: breaks ?? this.breaks,
        blocks: blocks ?? this.blocks,
        blockDurationSetting:
            blockDurationSetting ?? this.blockDurationSetting,
        startTimePlanned: startTimePlanned ?? this.startTimePlanned,
        startTimeActual: startTimeActual ?? this.startTimeActual,
        estimatedEndTime: estimatedEndTime ?? this.estimatedEndTime,
        totalStudyMinutesPlanned:
            totalStudyMinutesPlanned ?? this.totalStudyMinutesPlanned,
        totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      );
}
