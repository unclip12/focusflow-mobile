// =============================================================
// AppProvider — Central state, loads ALL data from SQLite
// One ChangeNotifier holding lists for every data domain.
// =============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/services/backup_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/services/background_timer_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/study_plan_item.dart';
import 'package:focusflow_mobile/models/fmge_entry.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/models/daily_tracker.dart';
import 'package:focusflow_mobile/models/study_entry.dart';
import 'package:focusflow_mobile/models/study_material.dart';
import 'package:focusflow_mobile/models/mentor_message.dart';
import 'package:focusflow_mobile/models/user_profile.dart';
import 'package:focusflow_mobile/models/app_snapshot.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/models/sketchy_item.dart';
import 'package:focusflow_mobile/models/pathoma_item.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/models/uworld_session.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/streak_data.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/models/buying_item.dart';
import 'package:focusflow_mobile/models/todo_item.dart';
import 'package:focusflow_mobile/models/default_routine_order.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/models/activity_log.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart' as du;

// ── AppNotification ───────────────────────────────────────────────
enum AppNotificationType { reminder, achievement, revisionDue, streak }

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  /// Optional route name payload — used by NotificationCard to navigate.
  final String? routeName;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.routeName,
  });
}

// ── Habit ─────────────────────────────────────────────────────────
enum HabitFrequency { daily, weekdays, custom }

class Habit {
  final String id;
  final String name;
  final HabitFrequency frequency;
  final List<int>? customDays; // 1=Mon .. 7=Sun — for custom frequency
  final Color color;
  bool isCompleted;

  Habit({
    required this.id,
    required this.name,
    this.frequency = HabitFrequency.daily,
    this.customDays,
    this.color = const Color(0xFF6366F1),
    this.isCompleted = false,
  });
}

// ── DateActivity (combined activity item) ─────────────────────────
class DateActivity {
  final String type; // 'block' | 'timeLog' | 'studyPlan'
  final String title;
  final String? subtitle;
  final int? durationMinutes;

  const DateActivity({
    required this.type,
    required this.title,
    this.subtitle,
    this.durationMinutes,
  });
}

// ── Canned mentor replies ─────────────────────────────────────────
const _kMentorAutoReplies = [
  "Great question! Based on your recent study logs, I'd recommend focusing on Anatomy — you haven't reviewed it in 5 days.",
  "You're doing amazing! Your streak is strong 🔥. Keep the momentum going with a quick revision session today.",
  "Looking at your analytics, your weakest area is Pharmacology. Want me to create a focused study plan for it?",
  "Here's a tip: try the Pomodoro technique — 25 min study, 5 min break. It works wonders for retention!",
  "Your block completion rate has been improving! You've gone from 65% to 82% this week. Great progress!",
  "I notice you study best in the morning. Consider scheduling your hardest subjects before noon.",
  "Don't forget — spaced repetition is key to long-term memory! Review those overdue KB pages today.",
];

class AppProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();
  bool _loaded = false;
  bool get loaded => _loaded;
  int _mentorReplyIdx = 0;

  // ── Data stores ───────────────────────────────────────────────
  List<KnowledgeBaseEntry> knowledgeBase = [];
  List<DayPlan> dayPlans = [];
  List<StudyPlanItem> studyPlan = [];
  List<FMGEEntry> fmgeEntries = [];
  List<TimeLogEntry> timeLogs = [];
  List<DailyTracker> dailyTrackers = [];
  List<StudyEntry> studyEntries = [];
  List<StudyMaterial> studyMaterials = [];
  List<MentorMessage> mentorMessages = [];
  List<HistoryRecord> history = [];
  List<AppNotification> notifications = [];
  List<Habit> habits = [];
  List<RevisionItem> revisionItems = [];
  List<FAPage> faPages = [];
  List<SketchyItem> sketchyItems = [];
  List<PathomaItem> pathomaItems = [];
  List<UWorldSession> uWorldSessions = [];
  List<SketchyVideo> sketchyMicroVideos = [];
  List<SketchyVideo> sketchyPharmVideos = [];
  List<PathomaChapter> pathomaChapters = [];
  List<UWorldTopic> uworldTopics = [];
  List<FASubtopic> faSubtopics = [];
  List<Routine> routines = [];
  final List<Routine> _pendingExpiredRoutinePrompts = [];
  List<RoutineLog> routineLogs = [];
  List<BuyingItem> buyingItems = [];
  List<TodoItem> todoItems = [];
  List<DefaultActivity> defaultActivities = [];
  List<DailyFlow> dailyFlows = [];

  String faViewMode = 'cards';

  MentorMemory? mentorMemory;
  AISettings? aiSettings;
  UserProfile? userProfile;
  RevisionSettings? revisionSettings;
  StreakData streakData = StreakData();

  // ── Initial load ──────────────────────────────────────────────
  Future<void> loadAll() async {
    knowledgeBase = (await _db.getAllKBEntries())
        .map((j) => KnowledgeBaseEntry.fromJson(j))
        .toList();

    dayPlans =
        (await _db.getAllDayPlans()).map((j) => DayPlan.fromJson(j)).toList();

    studyPlan = (await _db.getAllStudyPlanItems())
        .map((j) => StudyPlanItem.fromJson(j))
        .toList();

    fmgeEntries = (await _db.getAllFMGEEntries())
        .map((j) => FMGEEntry.fromJson(j))
        .toList();

    timeLogs = (await _db.getAllTimeLogs())
        .map((j) => TimeLogEntry.fromJson(j))
        .toList();

    dailyTrackers = (await _db.getAllDailyTrackers())
        .map((j) => DailyTracker.fromJson(j))
        .toList();

    studyEntries = (await _db.getAllStudyEntries())
        .map((j) => StudyEntry.fromJson(j))
        .toList();

    studyMaterials = (await _db.getAllStudyMaterials())
        .map((j) => StudyMaterial.fromJson(j))
        .toList();

    mentorMessages = (await _db.getAllMentorMessages())
        .map((j) => MentorMessage.fromJson(j))
        .toList();

    history = (await _db.getAllHistory())
        .map((j) => HistoryRecord.fromJson(j))
        .toList();

    revisionItems = (await _db.getAllRevisionItems())
        .map((j) => RevisionItem.fromJson(j))
        .toList();

    faPages =
        (await _db.getAllFAPages()).map((j) => FAPage.fromJson(j)).toList();
    sketchyItems = (await _db.getAllSketchyItems())
        .map((j) => SketchyItem.fromJson(j))
        .toList();
    pathomaItems = (await _db.getAllPathomaItems())
        .map((j) => PathomaItem.fromJson(j))
        .toList();
    uWorldSessions = (await _db.getAllUWorldSessions())
        .map((j) => UWorldSession.fromJson(j))
        .toList();

    // G6 tracker data
    sketchyMicroVideos = await _db.getSketchyMicroVideos();
    sketchyPharmVideos = await _db.getSketchyPharmVideos();
    pathomaChapters = await _db.getPathomaChapters();
    uworldTopics = await _db.getUWorldTopics();

    // V5 subtopics
    faSubtopics = await _db.getAllFASubtopics();

    // V6: Routines, Buying, To-Do, Default Order
    routines =
        (await _db.getAllRoutines()).map((j) => Routine.fromJson(j)).toList();
    routineLogs = (await _db.getAllRoutineLogs())
        .map((j) => RoutineLog.fromJson(j))
        .toList();
    buyingItems = (await _db.getAllBuyingItems())
        .map((j) => BuyingItem.fromJson(j))
        .toList();
    todoItems =
        (await _db.getAllTodoItems()).map((j) => TodoItem.fromJson(j)).toList();
    defaultActivities = (await _db.getAllDefaultActivities())
        .map((j) => DefaultActivity.fromJson(j))
        .toList();
    defaultActivities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // V7: Daily Flows
    dailyFlows = (await _db.getAllDailyFlows())
        .map((j) => DailyFlow.fromJson(j))
        .toList();

    // Singletons
    final memJson = await _db.getMentorMemory();
    mentorMemory = memJson != null ? MentorMemory.fromJson(memJson) : null;

    final aiJson = await _db.getAISettings();
    aiSettings = aiJson != null ? AISettings.fromJson(aiJson) : null;

    final upJson = await _db.getUserProfile();
    userProfile = upJson != null ? UserProfile.fromJson(upJson) : null;

    final rsJson = await _db.getRevisionSettings();
    revisionSettings =
        rsJson != null ? RevisionSettings.fromJson(rsJson) : null;

    final sdJson = await _db.getStreakData();
    streakData = sdJson != null ? StreakData.fromJson(sdJson) : StreakData();

    final prefs = await SharedPreferences.getInstance();
    faViewMode = prefs.getString('faViewMode') ?? 'cards';
    await _refreshRoutineReminderState();

    // ── Seed sample notifications (in-memory only) ────────────────
    final now = DateTime.now();
    notifications = [
      AppNotification(
        id: 'n1',
        type: AppNotificationType.streak,
        title: '7-Day Streak! 🔥',
        message: "You've studied 7 days in a row. Keep it up!",
        createdAt: now.subtract(const Duration(hours: 1)),
        routeName: 'dashboard',
      ),
      AppNotification(
        id: 'n2',
        type: AppNotificationType.revisionDue,
        title: 'Revision Due',
        message: '3 KB pages are overdue for revision.',
        createdAt: now.subtract(const Duration(hours: 3)),
        routeName: 'knowledge-base',
      ),
      AppNotification(
        id: 'n3',
        type: AppNotificationType.reminder,
        title: 'Study Session Reminder',
        message: "It's time for your 2 PM focus block.",
        createdAt: now.subtract(const Duration(hours: 5)),
        routeName: 'focus-timer',
      ),
      AppNotification(
        id: 'n4',
        type: AppNotificationType.achievement,
        title: 'Achievement Unlocked',
        message: "You've completed 50 study sessions!",
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        routeName: 'dashboard',
      ),
      AppNotification(
        id: 'n5',
        type: AppNotificationType.revisionDue,
        title: 'FMGE Revision Due',
        message: 'Anatomy slides 12–24 are due for review.',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        isRead: true,
        routeName: 'fmge',
      ),
      AppNotification(
        id: 'n6',
        type: AppNotificationType.reminder,
        title: 'Daily Summary',
        message: 'You studied 4h 30m yesterday. Great job!',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        routeName: 'dashboard',
      ),
    ];

    // ── Seed sample habits (in-memory only) ───────────────────────
    habits = [
      Habit(
          id: 'h1',
          name: 'Morning Revision',
          frequency: HabitFrequency.daily,
          color: const Color(0xFF6366F1)),
      Habit(
          id: 'h2',
          name: 'Read First Aid',
          frequency: HabitFrequency.daily,
          color: const Color(0xFF10B981)),
      Habit(
          id: 'h3',
          name: 'QBank Practice',
          frequency: HabitFrequency.weekdays,
          color: const Color(0xFFEC4899)),
      Habit(
          id: 'h4',
          name: 'Anki Review',
          frequency: HabitFrequency.daily,
          color: const Color(0xFFF59E0B)),
    ];

    _loaded = true;
    notifyListeners();
    await injectRoutinesIntoDayPlan(todayDateKey);
  }

  // ═══════════════════════════════════════════════════════════════
  // KNOWLEDGE BASE
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertKBEntry(KnowledgeBaseEntry entry) async {
    await _db.upsertKBEntry(entry.toJson());
    final idx =
        knowledgeBase.indexWhere((e) => e.pageNumber == entry.pageNumber);
    if (idx >= 0) {
      knowledgeBase[idx] = entry;
    } else {
      knowledgeBase.add(entry);
    }
    notifyListeners();
  }

  Future<void> deleteKBEntry(String pageNumber) async {
    await _db.deleteKBEntry(pageNumber);
    knowledgeBase.removeWhere((e) => e.pageNumber == pageNumber);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // DAY PLANS
  // ═══════════════════════════════════════════════════════════════

  DayPlan? getDayPlan(String date) {
    try {
      return dayPlans.firstWhere((p) => p.date == date);
    } catch (_) {
      return null;
    }
  }

  String get todayDateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Block> getTodayBlocksForLibraryVideo({
    required int videoId,
    required Iterable<String> candidateTitles,
  }) {
    final normalizedTitles = candidateTitles
        .map((title) => title.trim().toLowerCase())
        .where((title) => title.isNotEmpty)
        .toSet();
    final blocks = getDayPlan(todayDateKey)?.blocks ?? const <Block>[];

    return blocks.where((block) {
      if (block.type != BlockType.video) return false;
      if (block.relatedVideoId == '$videoId') return true;
      return normalizedTitles.contains(block.title.trim().toLowerCase());
    }).toList();
  }

  Future<void> removeTodayBlocksById(Iterable<String> blockIds) async {
    final ids = blockIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return;

    final plan = getDayPlan(todayDateKey);
    final blocks = plan?.blocks;
    if (plan == null || blocks == null) return;

    final remaining = <Block>[];
    for (final block in blocks) {
      if (!ids.contains(block.id)) {
        remaining.add(block.copyWith(index: remaining.length));
      }
    }
    if (remaining.length == blocks.length) return;

    await upsertDayPlan(plan.copyWith(blocks: remaining));
    await syncFlowActivitiesFromDayPlan(todayDateKey);
  }

  Future<void> removeBlockFromDayPlan(String blockId, String date) async {
    if (blockId.isEmpty) return;

    final plan = getDayPlan(date);
    final blocks = plan?.blocks;
    if (plan == null || blocks == null) return;

    final remaining = <Block>[];
    for (final block in blocks) {
      if (block.id != blockId) {
        remaining.add(block.copyWith(index: remaining.length));
      }
    }
    if (remaining.length == blocks.length) return;

    await upsertDayPlan(plan.copyWith(blocks: remaining));
    await syncFlowActivitiesFromDayPlan(date);
  }

  Future<void> _saveDayPlan(DayPlan plan, {bool notify = true}) async {
    await _db.upsertDayPlan(plan.toJson());
    final idx = dayPlans.indexWhere((p) => p.date == plan.date);
    if (idx >= 0) {
      dayPlans[idx] = plan;
    } else {
      dayPlans.add(plan);
    }
    if (notify) {
      notifyListeners();
    }
    unawaited(_triggerBackup());
  }

  Future<void> upsertDayPlan(DayPlan plan) async {
    await _saveDayPlan(plan);
  }

  Future<void> deleteDayPlan(String date) async {
    await _db.deleteDayPlan(date);
    dayPlans.removeWhere((p) => p.date == date);
    notifyListeners();
  }

  Future<void> completeDayPlanBlock(
    String date,
    String blockId, {
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    bool autoAdvanceFlow = false,
  }) async {
    final plan = getDayPlan(date);
    final blocks = plan?.blocks;
    if (plan == null || blocks == null) return;

    final blockIdx = blocks.indexWhere((block) => block.id == blockId);
    if (blockIdx < 0) return;

    final end = completedAt ?? DateTime.now();
    final block = blocks[blockIdx];
    final existingStart = DateTime.tryParse(block.actualStartTime ?? '');
    final start = startedAt ?? existingStart ?? end;
    final resolvedDurationSeconds =
        durationSeconds ?? end.difference(start).inSeconds;

    final updatedBlocks = List<Block>.from(blocks);
    updatedBlocks[blockIdx] = block.copyWith(
      status: BlockStatus.done,
      actualStartTime: block.actualStartTime ?? start.toIso8601String(),
      actualEndTime: end.toIso8601String(),
      actualDurationMinutes: (resolvedDurationSeconds / 60).ceil(),
      completionStatus: 'COMPLETED',
    );
    final updatedPlan = plan.copyWith(blocks: updatedBlocks);
    await _saveDayPlan(updatedPlan, notify: !autoAdvanceFlow);

    final flow = getDailyFlow(date);
    if (flow == null) {
      if (autoAdvanceFlow) {
        notifyListeners();
      }
      return;
    }

    final activities = List<FlowActivity>.from(flow.activities);
    final activityIdx = activities.indexWhere(
      (activity) =>
          activity.id == 'task-$blockId' ||
          activity.linkedTaskIds.contains(blockId),
    );
    if (activityIdx < 0) {
      if (autoAdvanceFlow) {
        notifyListeners();
      }
      return;
    }

    if (autoAdvanceFlow) {
      if (startedAt != null) {
        activities[activityIdx] = activities[activityIdx].copyWith(
          startedAt: startedAt.toIso8601String(),
        );
        await upsertDailyFlow(
          flow.copyWith(activities: activities),
          notify: false,
        );
      }
      await completeFlowActivity(
        date,
        activities[activityIdx].id,
        notify: false,
      );
      notifyListeners();
      return;
    }

    final activity = activities[activityIdx];
    activities[activityIdx] = activity.copyWith(
      status: 'DONE',
      startedAt: activity.startedAt ?? start.toIso8601String(),
      completedAt: end.toIso8601String(),
      durationSeconds: resolvedDurationSeconds,
    );
    final allDone = activities.every((a) => a.isDone || a.isSkipped);
    await upsertDailyFlow(
      flow.copyWith(
        activities: activities,
        status: allDone ? 'COMPLETED' : flow.status,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY PLAN
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyPlanItem(StudyPlanItem item) async {
    await _db.upsertStudyPlanItem(item.toJson());
    final idx = studyPlan.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      studyPlan[idx] = item;
    } else {
      studyPlan.add(item);
    }
    notifyListeners();
  }

  Future<void> deleteStudyPlanItem(String id) async {
    await _db.deleteStudyPlanItem(id);
    studyPlan.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FMGE ENTRIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertFMGEEntry(FMGEEntry entry) async {
    await _db.upsertFMGEEntry(entry.toJson());
    final idx = fmgeEntries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      fmgeEntries[idx] = entry;
    } else {
      fmgeEntries.add(entry);
    }
    notifyListeners();
  }

  Future<void> deleteFMGEEntry(String id) async {
    await _db.deleteFMGEEntry(id);
    fmgeEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME LOGS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertTimeLog(TimeLogEntry entry) async {
    await _db.upsertTimeLog(entry.toJson());
    final idx = timeLogs.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      timeLogs[idx] = entry;
    } else {
      timeLogs.add(entry);
    }
    notifyListeners();
    unawaited(_triggerBackup());
  }

  Future<void> deleteTimeLog(String id) async {
    await _db.deleteTimeLog(id);
    timeLogs.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> _deleteTimeLogsForActivities(
    Iterable<String> activities, {
    TimeLogCategory? category,
  }) async {
    final targets = activities
        .map((activity) => activity.trim())
        .where((activity) => activity.isNotEmpty)
        .toSet();
    if (targets.isEmpty) return;

    final matching = timeLogs
        .where((log) =>
            targets.contains(log.activity.trim()) &&
            (category == null || log.category == category))
        .map((log) => log.id)
        .toList();

    if (matching.isEmpty) return;

    for (final id in matching) {
      await _db.deleteTimeLog(id);
    }
    timeLogs.removeWhere((log) => matching.contains(log.id));
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY TRACKER
  // ═══════════════════════════════════════════════════════════════

  DailyTracker? getDailyTracker(String date) {
    try {
      return dailyTrackers.firstWhere((t) => t.date == date);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertDailyTracker(DailyTracker tracker) async {
    await _db.upsertDailyTracker(tracker.toJson());
    final idx = dailyTrackers.indexWhere((t) => t.date == tracker.date);
    if (idx >= 0) {
      dailyTrackers[idx] = tracker;
    } else {
      dailyTrackers.add(tracker);
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY ENTRIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyEntry(StudyEntry entry) async {
    await _db.upsertStudyEntry(entry.toJson());
    final idx = studyEntries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      studyEntries[idx] = entry;
    } else {
      studyEntries.add(entry);
    }
    notifyListeners();
  }

  Future<void> deleteStudyEntry(String id) async {
    await _db.deleteStudyEntry(id);
    studyEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY MATERIALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyMaterial(StudyMaterial material) async {
    await _db.upsertStudyMaterial(material.toJson());
    final idx = studyMaterials.indexWhere((m) => m.id == material.id);
    if (idx >= 0) {
      studyMaterials[idx] = material;
    } else {
      studyMaterials.add(material);
    }
    notifyListeners();
  }

  Future<void> deleteStudyMaterial(String id) async {
    await _db.deleteStudyMaterial(id);
    studyMaterials.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // MENTOR MESSAGES
  // ═══════════════════════════════════════════════════════════════

  Future<void> addMentorMessage(MentorMessage msg) async {
    await _db.insertMentorMessage(msg.toJson());
    mentorMessages.add(msg);
    notifyListeners();
  }

  Future<void> clearMentorMessages() async {
    await _db.deleteAllMentorMessages();
    mentorMessages.clear();
    notifyListeners();
  }

  /// High-level helper: adds a user message and triggers a mock
  /// mentor reply after ~800ms.
  Future<void> sendMentorMessage(String text) async {
    // 1. Add user message
    final userMsg = MentorMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text,
      timestamp: DateTime.now().toIso8601String(),
    );
    await addMentorMessage(userMsg);

    // 2. Mock mentor reply after delay
    await Future.delayed(const Duration(milliseconds: 800));
    final reply =
        _kMentorAutoReplies[_mentorReplyIdx % _kMentorAutoReplies.length];
    _mentorReplyIdx++;

    final mentorMsg = MentorMessage(
      id: _uuid.v4(),
      role: 'model',
      text: reply,
      timestamp: DateTime.now().toIso8601String(),
    );
    await addMentorMessage(mentorMsg);
  }

  // ═══════════════════════════════════════════════════════════════
  // SINGLETONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveMentorMemory(MentorMemory mem) async {
    mentorMemory = mem;
    await _db.saveMentorMemory(mem.toJson());
    notifyListeners();
  }

  Future<void> saveAISettings(AISettings s) async {
    aiSettings = s;
    await _db.saveAISettings(s.toJson());
    notifyListeners();
  }

  Future<void> saveUserProfile(UserProfile p) async {
    userProfile = p;
    await _db.saveUserProfile(p.toJson());
    notifyListeners();
  }

  /// Alias for saveUserProfile — screens may call either name.
  Future<void> updateUserProfile(UserProfile profile) =>
      saveUserProfile(profile);

  Future<void> saveRevisionSettings(RevisionSettings s) async {
    revisionSettings = s;
    await _db.saveRevisionSettings(s.toJson());
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // ROUTINES (V6)
  // ═══════════════════════════════════════════════════════════════

  DateTime _routineDateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _parseRoutineEndDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return null;
    return _routineDateOnly(parsed);
  }

  bool _isExpiredUntilDateRoutine(Routine routine) {
    if (routine.recurrence != 'until_date') return false;
    final endDate = _parseRoutineEndDate(routine.recurrenceEndDate);
    if (endDate == null) return false;
    return _routineDateOnly(DateTime.now()).isAfter(endDate);
  }

  bool _shouldInjectRoutineForDate(Routine routine, DateTime today) {
    final reminderTime = routine.reminderTime;
    if (reminderTime == null || reminderTime.isEmpty) return false;

    final recurrence = routine.recurrence?.toLowerCase().trim();
    if (recurrence == null || recurrence == 'daily' || recurrence.isEmpty) {
      return true;
    }
    if (recurrence == 'weekly') {
      return routine.reminderWeekday == today.weekday;
    }
    if (recurrence == 'until_date') {
      final endDate = _parseRoutineEndDate(routine.recurrenceEndDate);
      if (endDate == null) return false;
      return !today.isAfter(endDate);
    }
    return true;
  }

  int? _minutesSinceMidnight(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }

  String _formatMinutesSinceMidnight(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final safeMinutes = normalized < 0 ? normalized + (24 * 60) : normalized;
    final hour = safeMinutes ~/ 60;
    final minute = safeMinutes % 60;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  String _calculateRoutineEndTime(String startTime, int durationMinutes) {
    final startMinutes = _minutesSinceMidnight(startTime);
    if (startMinutes == null) return startTime;
    return _formatMinutesSinceMidnight(startMinutes + durationMinutes);
  }

  bool _isRoutineInjectedBlock(Block block) => block.id.startsWith('routine-');

  Block _buildRoutineInjectedBlock(
    Routine routine, {
    required String date,
    required int index,
    Block? existing,
  }) {
    final plannedDurationMinutes =
        routine.totalEstimatedMinutes > 0 ? routine.totalEstimatedMinutes : 30;
    final plannedStartTime = routine.reminderTime!;
    final plannedEndTime = _calculateRoutineEndTime(
      plannedStartTime,
      plannedDurationMinutes,
    );
    final title = '${routine.icon} ${routine.name}';

    if (existing != null) {
      return existing.copyWith(
        index: index,
        date: date,
        plannedStartTime: plannedStartTime,
        plannedEndTime: plannedEndTime,
        type: BlockType.other,
        title: title,
        plannedDurationMinutes: plannedDurationMinutes,
        actualNotes: 'source:routine',
      );
    }

    return Block(
      id: 'routine-${routine.id}',
      index: index,
      date: date,
      plannedStartTime: plannedStartTime,
      plannedEndTime: plannedEndTime,
      type: BlockType.other,
      title: title,
      plannedDurationMinutes: plannedDurationMinutes,
      status: BlockStatus.notStarted,
      actualNotes: 'source:routine',
    );
  }

  List<Block> _reindexBlocks(List<Block> blocks) {
    return List<Block>.generate(
      blocks.length,
      (index) => blocks[index].copyWith(index: index),
    );
  }

  DayPlan _buildMinimalDayPlan(String date, List<Block> blocks) {
    return DayPlan(
      date: date,
      faPages: const [],
      faPagesCount: 0,
      videos: const [],
      notesFromUser: '',
      notesFromAI: '',
      attachments: const [],
      breaks: const [],
      blocks: blocks,
      totalStudyMinutesPlanned: 0,
      totalBreakMinutes: 0,
    );
  }

  bool _sameBlockLists(List<Block> left, List<Block> right) {
    if (left.length != right.length) return false;
    final leftJson = left.map((block) => block.toJson()).toList();
    final rightJson = right.map((block) => block.toJson()).toList();
    return jsonEncode(leftJson) == jsonEncode(rightJson);
  }

  Future<void> injectRoutinesIntoDayPlan(String date) async {
    if (date != todayDateKey) return;

    final today = _routineDateOnly(DateTime.now());
    final eligibleRoutines = routines
        .where((routine) => _shouldInjectRoutineForDate(routine, today))
        .toList();
    final eligibleById = <String, Routine>{
      for (final routine in eligibleRoutines) routine.id: routine,
    };

    final existingPlan = getDayPlan(date);
    final existingBlocks = List<Block>.from(existingPlan?.blocks ?? const []);
    final reconciledBlocks = <Block>[];
    final seenRoutineIds = <String>{};

    for (final block in existingBlocks) {
      if (!_isRoutineInjectedBlock(block)) {
        reconciledBlocks.add(block);
        continue;
      }

      final routineId = block.id.substring('routine-'.length);
      final routine = eligibleById[routineId];
      if (routine == null) {
        continue;
      }

      seenRoutineIds.add(routineId);
      reconciledBlocks.add(
        _buildRoutineInjectedBlock(
          routine,
          date: date,
          index: reconciledBlocks.length,
          existing: block,
        ),
      );
    }

    for (final routine in eligibleRoutines) {
      if (seenRoutineIds.contains(routine.id)) continue;
      reconciledBlocks.add(
        _buildRoutineInjectedBlock(
          routine,
          date: date,
          index: reconciledBlocks.length,
        ),
      );
    }

    final normalizedExistingBlocks = _reindexBlocks(existingBlocks);
    final normalizedReconciledBlocks = _reindexBlocks(reconciledBlocks);
    if (_sameBlockLists(normalizedExistingBlocks, normalizedReconciledBlocks)) {
      return;
    }

    if (existingPlan == null && normalizedReconciledBlocks.isEmpty) {
      return;
    }

    final updatedPlan =
        existingPlan?.copyWith(blocks: normalizedReconciledBlocks) ??
            _buildMinimalDayPlan(date, normalizedReconciledBlocks);
    await upsertDayPlan(updatedPlan);
  }

  Future<void> _refreshRoutineReminderState() async {
    _pendingExpiredRoutinePrompts
      ..clear()
      ..addAll(routines.where(_isExpiredUntilDateRoutine));
    await NotificationService.instance.rescheduleAllRoutineReminders(routines);
  }

  bool get hasPendingExpiredRoutinePrompts =>
      _pendingExpiredRoutinePrompts.isNotEmpty;

  Routine? takeNextExpiredRoutinePrompt() {
    if (_pendingExpiredRoutinePrompts.isEmpty) return null;
    return _pendingExpiredRoutinePrompts.removeAt(0);
  }

  Future<void> upsertRoutine(Routine routine) async {
    await _db.upsertRoutine(routine.toJson());
    final idx = routines.indexWhere((r) => r.id == routine.id);
    if (idx >= 0) {
      routines[idx] = routine;
    } else {
      routines.add(routine);
    }
    await _refreshRoutineReminderState();
    await injectRoutinesIntoDayPlan(todayDateKey);
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _db.deleteRoutine(id);
    routines.removeWhere((r) => r.id == id);
    await NotificationService.instance.cancelRoutineReminder(id);
    await _refreshRoutineReminderState();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // ROUTINE LOGS (V6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertRoutineLog(RoutineLog log) async {
    await _db.upsertRoutineLog(log.toJson());
    final idx = routineLogs.indexWhere((l) => l.id == log.id);
    if (idx >= 0) {
      routineLogs[idx] = log;
    } else {
      routineLogs.add(log);
    }
    notifyListeners();
  }

  Future<void> deleteRoutineLog(String id) async {
    await _db.deleteRoutineLog(id);
    routineLogs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  List<RoutineLog> getRoutineLogsForDate(String date) =>
      routineLogs.where((l) => l.date == date).toList();

  // ═══════════════════════════════════════════════════════════════
  // BUYING ITEMS (V6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertBuyingItem(BuyingItem item) async {
    await _db.upsertBuyingItem(item.toJson());
    final idx = buyingItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      buyingItems[idx] = item;
    } else {
      buyingItems.add(item);
    }
    notifyListeners();
  }

  Future<void> deleteBuyingItem(String id) async {
    await _db.deleteBuyingItem(id);
    buyingItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  List<BuyingItem> getBuyingItemsForDate(String date) =>
      buyingItems.where((i) => i.date == date).toList();

  // ═══════════════════════════════════════════════════════════════
  // TODO ITEMS (V6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertTodoItem(TodoItem item) async {
    await _db.upsertTodoItem(item.toJson());
    final idx = todoItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      todoItems[idx] = item;
    } else {
      todoItems.add(item);
    }
    notifyListeners();
  }

  Future<void> deleteTodoItem(String id) async {
    await _db.deleteTodoItem(id);
    todoItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  List<TodoItem> getTodoItemsForDate(String date) =>
      todoItems.where((i) => i.date == date).toList();

  List<TodoItem> getTodosByCategory(String date, String category) =>
      todoItems.where((i) => i.date == date && i.category == category).toList();

  // ═══════════════════════════════════════════════════════════════
  // DEFAULT ROUTINE ORDER (V6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertDefaultActivity(DefaultActivity activity) async {
    await _db.upsertDefaultActivity(activity.toJson());
    final idx = defaultActivities.indexWhere((a) => a.id == activity.id);
    if (idx >= 0) {
      defaultActivities[idx] = activity;
    } else {
      defaultActivities.add(activity);
    }
    defaultActivities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
  }

  Future<void> deleteDefaultActivity(String id) async {
    await _db.deleteDefaultActivity(id);
    defaultActivities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> saveDefaultActivities(List<DefaultActivity> activities) async {
    await _db.deleteAllDefaultActivities();
    for (final a in activities) {
      await _db.upsertDefaultActivity(a.toJson());
    }
    defaultActivities = List.from(activities);
    defaultActivities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════
  // DAILY FLOWS (V7)
  // ═════════════════════════════════════════════════════════════════

  DailyFlow? getDailyFlow(String date) {
    try {
      return dailyFlows.firstWhere((f) => f.date == date);
    } catch (_) {
      return null;
    }
  }

  List<FlowActivity> getFlowActivitiesForDate(String dateKey) {
    final flow = getDailyFlow(dateKey);
    if (flow == null || flow.activities.isEmpty) return const [];

    final deduped = <FlowActivity>[];
    final seenIds = <String>{};
    final firstSeenOrder = <String, int>{};

    for (int i = 0; i < flow.activities.length; i++) {
      final activity = flow.activities[i];
      firstSeenOrder.putIfAbsent(activity.id, () => i);
      if (seenIds.add(activity.id)) {
        deduped.add(activity);
      }
    }

    deduped.sort((a, b) {
      final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderCompare != 0) return sortOrderCompare;
      return (firstSeenOrder[a.id] ?? 0).compareTo(firstSeenOrder[b.id] ?? 0);
    });

    return deduped;
  }

  Future<void> _saveDailyFlow(DailyFlow flow, {bool notify = true}) async {
    await _db.upsertDailyFlow(flow.toJson());
    final idx = dailyFlows.indexWhere((f) => f.date == flow.date);
    if (idx >= 0) {
      dailyFlows[idx] = flow;
    } else {
      dailyFlows.add(flow);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> upsertDailyFlow(DailyFlow flow, {bool notify = true}) async {
    await _saveDailyFlow(flow, notify: notify);
  }

  Future<void> deleteDailyFlow(String date) async {
    await _db.deleteDailyFlow(date);
    dailyFlows.removeWhere((f) => f.date == date);
    notifyListeners();
  }

  /// Initialize a daily flow for a date by cloning the default activity chain.
  /// If a flow already exists for the date, it is returned as-is.
  Future<DailyFlow> initializeDailyFlow(String date,
      {bool notify = true}) async {
    final existing = getDailyFlow(date);
    if (existing != null) return existing;

    final activities = defaultActivities.map((da) {
      return FlowActivity(
        id: _uuid.v4(),
        label: da.displayLabel,
        icon: da.displayIcon,
        activityType: da.type.value,
        routineId: da.routineId,
        linkedTaskIds: da.linkedTaskIds,
        sortOrder: da.sortOrder,
      );
    }).toList();

    final flow = DailyFlow(date: date, activities: activities);
    await _saveDailyFlow(flow, notify: notify);
    return flow;
  }

  String _flowIconForBlockType(BlockType type) {
    switch (type) {
      case BlockType.revisionFa:
        return '📚';
      case BlockType.video:
        return '🎬';
      case BlockType.qbank:
        return '📝';
      case BlockType.anki:
        return '🃏';
      case BlockType.studySession:
        return '🎓';
      case BlockType.fmgeRevision:
        return '📖';
      case BlockType.breakBlock:
        return '☕';
      case BlockType.mixed:
        return '🔄';
      case BlockType.other:
        return '⚡';
    }
  }

  String _flowStatusFromBlockStatus(BlockStatus status) {
    switch (status) {
      case BlockStatus.done:
        return 'DONE';
      case BlockStatus.inProgress:
        return 'IN_PROGRESS';
      default:
        return 'NOT_STARTED';
    }
  }

  FlowActivity _flowActivityFromBlock(
    Block block,
    int sortOrder, {
    FlowActivity? existing,
  }) {
    final blockStatus = _flowStatusFromBlockStatus(block.status);
    final preserveExistingState = existing != null &&
        block.status == BlockStatus.notStarted &&
        existing.status != 'NOT_STARTED';
    final status = preserveExistingState ? existing.status : blockStatus;
    final isCompleted = status == 'DONE';
    final startedAt = preserveExistingState
        ? (existing.startedAt ?? block.actualStartTime)
        : block.actualStartTime;
    final completedAt = preserveExistingState
        ? (existing.completedAt ?? block.actualEndTime)
        : block.actualEndTime;
    final durationSeconds = preserveExistingState
        ? (existing.durationSeconds ??
            (block.actualDurationMinutes != null
                ? block.actualDurationMinutes! * 60
                : null))
        : (block.actualDurationMinutes != null
            ? block.actualDurationMinutes! * 60
            : null);

    return FlowActivity(
      id: 'task-${block.id}',
      label: block.title,
      icon: _flowIconForBlockType(block.type),
      activityType: block.type.value,
      linkedTaskIds: [block.id],
      sortOrder: sortOrder,
      status: status,
      startedAt: startedAt,
      completedAt: isCompleted ? completedAt : null,
      durationSeconds: durationSeconds,
      pausedUntil: preserveExistingState ? existing.pausedUntil : null,
      notes: preserveExistingState ? existing.notes : null,
      category: preserveExistingState ? existing.category : null,
    );
  }

  Future<void> syncFlowActivitiesFromDayPlan(
    String date, {
    bool notify = true,
  }) async {
    final plan = getDayPlan(date);
    var flow = getDailyFlow(date);
    flow ??= await initializeDailyFlow(date, notify: false);

    final blocks = (plan?.blocks ?? [])
        .where((block) =>
            block.type != BlockType.breakBlock && block.isVirtual != true)
        .toList();
    final blockActivityIds = blocks.map((block) => 'task-${block.id}').toSet();
    final existingActivities = List<FlowActivity>.from(flow.activities);
    final normalizedActivities = <FlowActivity>[];
    final seenActivityIds = <String>{};
    for (final activity in existingActivities) {
      if (seenActivityIds.add(activity.id)) {
        if (!activity.id.startsWith('task-') ||
            blockActivityIds.contains(activity.id)) {
          normalizedActivities.add(activity);
        }
      }
    }

    for (final block in blocks) {
      final activityId = 'task-${block.id}';
      final existingIdx = normalizedActivities.indexWhere(
        (activity) => activity.id == activityId,
      );
      if (existingIdx >= 0) {
        final existing = normalizedActivities[existingIdx];
        normalizedActivities[existingIdx] = _flowActivityFromBlock(
          block,
          existing.sortOrder,
          existing: existing,
        );
      } else {
        normalizedActivities
            .add(_flowActivityFromBlock(block, normalizedActivities.length));
      }
    }

    final reindexedActivities = <FlowActivity>[];
    for (int i = 0; i < normalizedActivities.length; i++) {
      reindexedActivities.add(
        normalizedActivities[i].copyWith(sortOrder: i),
      );
    }

    await _saveDailyFlow(
      flow.copyWith(activities: reindexedActivities),
      notify: notify,
    );
  }

  /// Start the daily flow.
  Future<void> startFlow(String date) async {
    await syncFlowActivitiesFromDayPlan(date, notify: false);

    var flow = getDailyFlow(date);
    flow ??= await initializeDailyFlow(date, notify: false);

    final now = DateTime.now().toIso8601String();
    final activities = List<FlowActivity>.from(flow.activities);

    // Find the first pending activity and mark it as IN_PROGRESS
    for (int i = 0; i < activities.length; i++) {
      if (activities[i].isNotStarted) {
        activities[i] = activities[i].copyWith(
          status: 'IN_PROGRESS',
          startedAt: now,
        );
        break;
      }
    }

    final updated = flow.copyWith(
      status: 'ACTIVE',
      activities: activities,
      startedAt: flow.startedAt ?? now,
    );
    await _saveDailyFlow(updated);
  }

  /// Pause the flow with an optional duration.
  Future<void> pauseFlow(String date, {Duration? pauseDuration}) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    String? pausedUntil;
    if (pauseDuration != null) {
      pausedUntil = DateTime.now().add(pauseDuration).toIso8601String();
    }

    // Pause the currently active activity
    final activities = List<FlowActivity>.from(flow.activities);
    for (int i = 0; i < activities.length; i++) {
      if (activities[i].isActive) {
        activities[i] = activities[i].copyWith(
          status: 'PAUSED',
          pausedUntil: pausedUntil,
        );
        break;
      }
    }

    await upsertDailyFlow(flow.copyWith(
      status: 'PAUSED',
      activities: activities,
    ));
    BackgroundTimerService.stop();
  }

  /// Stop the flow with an optional reminder time.
  Future<void> stopFlow(String date, {DateTime? remindAt}) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    // Pause any active activity
    final activities = List<FlowActivity>.from(flow.activities);
    for (int i = 0; i < activities.length; i++) {
      if (activities[i].isActive) {
        activities[i] = activities[i].copyWith(status: 'PAUSED');
        break;
      }
    }

    await upsertDailyFlow(flow.copyWith(
      status: 'STOPPED',
      activities: activities,
      stoppedAt: DateTime.now().toIso8601String(),
      resumeReminderAt: remindAt?.toIso8601String(),
    ));
    BackgroundTimerService.stop();
  }

  /// Resume the flow from the next pending activity.
  Future<void> resumeFlow(String date) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final now = DateTime.now().toIso8601String();
    final activities = List<FlowActivity>.from(flow.activities);

    // Find the first paused or not-started activity and start it
    for (int i = 0; i < activities.length; i++) {
      if (activities[i].isPaused || activities[i].isNotStarted) {
        activities[i] = activities[i].copyWith(
          status: 'IN_PROGRESS',
          startedAt: activities[i].startedAt ?? now,
        );
        break;
      }
    }

    await upsertDailyFlow(flow.copyWith(
      status: 'ACTIVE',
      activities: activities,
    ));
  }

  /// Mark a flow activity as completed.
  Future<void> completeFlowActivity(
    String date,
    String activityId, {
    bool notify = true,
  }) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final now = DateTime.now();
    final activities = List<FlowActivity>.from(flow.activities);
    final idx = activities.indexWhere((a) => a.id == activityId);
    if (idx < 0) return;

    final activity = activities[idx];
    final startTime = activity.startedAt != null
        ? DateTime.tryParse(activity.startedAt!)
        : null;
    final duration =
        startTime != null ? now.difference(startTime).inSeconds : null;

    activities[idx] = activity.copyWith(
      status: 'DONE',
      completedAt: now.toIso8601String(),
      durationSeconds: duration,
    );

    // Auto-start the next pending activity
    bool foundNext = false;
    for (int i = 0; i < activities.length; i++) {
      if (activities[i].isNotStarted) {
        activities[i] = activities[i].copyWith(
          status: 'IN_PROGRESS',
          startedAt: now.toIso8601String(),
        );
        foundNext = true;
        break;
      }
    }

    // Check if all completed
    final allDone = activities.every((a) => a.isDone || a.isSkipped);
    await _saveDailyFlow(
      flow.copyWith(
        activities: activities,
        status: allDone ? 'COMPLETED' : (foundNext ? 'ACTIVE' : 'COMPLETED'),
      ),
      notify: notify,
    );
  }

  /// Undo a completed activity — moves it back to NOT_STARTED.
  Future<void> undoFlowActivity(String date, String activityId) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final activities = List<FlowActivity>.from(flow.activities);
    final idx = activities.indexWhere((a) => a.id == activityId);
    if (idx < 0) return;

    activities[idx] = FlowActivity(
      id: activities[idx].id,
      label: activities[idx].label,
      icon: activities[idx].icon,
      activityType: activities[idx].activityType,
      routineId: activities[idx].routineId,
      linkedTaskIds: activities[idx].linkedTaskIds,
      sortOrder: activities[idx].sortOrder,
      status: 'NOT_STARTED',
    );

    await upsertDailyFlow(flow.copyWith(
      activities: activities,
      status: 'ACTIVE',
    ));
  }

  /// Reorder flow activities.
  Future<void> reorderFlowActivities(
      String date, int oldIdx, int newIdx) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final activities = List<FlowActivity>.from(flow.activities);
    if (newIdx > oldIdx) newIdx--;
    final item = activities.removeAt(oldIdx);
    activities.insert(newIdx, item);

    // Re-index sortOrder
    for (int i = 0; i < activities.length; i++) {
      activities[i] = activities[i].copyWith(sortOrder: i);
    }

    await upsertDailyFlow(flow.copyWith(activities: activities));
  }

  /// Add a new activity to a daily flow.
  Future<void> addFlowActivity(String date, FlowActivity activity) async {
    var flow = getDailyFlow(date);
    flow ??= await initializeDailyFlow(date);

    final activities = List<FlowActivity>.from(flow.activities);
    activities.add(activity.copyWith(sortOrder: activities.length));
    await upsertDailyFlow(flow.copyWith(activities: activities));
  }

  /// Remove an activity from a daily flow.
  Future<void> removeFlowActivity(String date, String activityId) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final activities = List<FlowActivity>.from(flow.activities)
      ..removeWhere((a) => a.id == activityId);
    await upsertDailyFlow(flow.copyWith(activities: activities));
  }

  /// Plan a flow for a specific date by cloning the current template.
  /// Unlike [initializeDailyFlow], this always replaces any existing flow.
  Future<DailyFlow> planFlowFromTemplate(String date) async {
    final activities = defaultActivities.map((da) {
      return FlowActivity(
        id: _uuid.v4(),
        label: da.displayLabel,
        icon: da.displayIcon,
        activityType: da.type.value,
        routineId: da.routineId,
        linkedTaskIds: da.linkedTaskIds,
        sortOrder: da.sortOrder,
      );
    }).toList();

    final flow = DailyFlow(date: date, activities: activities);
    await upsertDailyFlow(flow);
    return flow;
  }

  /// Update an existing flow activity (e.g. rename it).
  Future<void> updateFlowActivity(String date, FlowActivity updated) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final activities = List<FlowActivity>.from(flow.activities);
    final idx = activities.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      activities[idx] = updated;
      await upsertDailyFlow(flow.copyWith(activities: activities));
    }
  }

  // ── TRACK NOW (ad-hoc activity tracking) ──────────────────────

  /// Start tracking a spontaneous activity (e.g. "Cooking").
  /// Creates a new FlowActivity with IN_PROGRESS status.
  Future<FlowActivity> startTrackNow(
    String date, {
    required String label,
    String? category,
  }) async {
    final now = DateTime.now().toIso8601String();
    final activity = FlowActivity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      icon: _categoryIcon(category),
      activityType: 'TRACK_NOW',
      sortOrder: 999,
      status: 'IN_PROGRESS',
      startedAt: now,
      category: category,
    );
    await addFlowActivity(
        date, activity.copyWith(status: 'IN_PROGRESS', startedAt: now));
    return activity;
  }

  /// Discard an active Track Now activity without saving it.
  Future<void> discardTrackNow(String date, String activityId) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final activities = List<FlowActivity>.from(flow.activities);
    activities.removeWhere(
      (a) => a.id == activityId && a.activityType == 'TRACK_NOW',
    );
    if (activities.length == flow.activities.length) return;

    await upsertDailyFlow(flow.copyWith(activities: activities));
    BackgroundTimerService.stop();
  }

  /// Stop the Track Now timer and mark activity as DONE.
  Future<void> stopTrackNow(
    String date,
    String activityId, {
    String? notes,
    List<String>? linkedTaskIds,
  }) async {
    final flow = getDailyFlow(date);
    if (flow == null) return;

    final now = DateTime.now();
    final activities = List<FlowActivity>.from(flow.activities);
    final idx = activities.indexWhere((a) => a.id == activityId);
    if (idx < 0) return;

    final activity = activities[idx];
    final startTime = activity.startedAt != null
        ? DateTime.tryParse(activity.startedAt!)
        : null;
    final duration =
        startTime != null ? now.difference(startTime).inSeconds : null;

    activities[idx] = activity.copyWith(
      status: 'DONE',
      completedAt: now.toIso8601String(),
      durationSeconds: duration,
      notes: notes,
      linkedTaskIds: linkedTaskIds ?? activity.linkedTaskIds,
    );

    await upsertDailyFlow(flow.copyWith(activities: activities));
    final linkedId = activities[idx].linkedTaskIds.isNotEmpty
        ? activities[idx].linkedTaskIds.first
        : null;
    if (linkedId != null) {
      await _completeTrackNowLinkedItem(
        date,
        linkedId,
        completedAt: now,
        durationSeconds: duration,
        startedAtIso: activities[idx].startedAt,
      );
      await _syncTrackNowLinkedLibraryItem(date, linkedId);
    }
    BackgroundTimerService.stop();
  }

  /// Get the currently active Track Now activity (if any).
  FlowActivity? getActiveTrackNow(String date) {
    final flow = getDailyFlow(date);
    if (flow == null) return null;
    try {
      return flow.activities.firstWhere(
        (a) => a.activityType == 'TRACK_NOW' && a.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _completeTrackNowLinkedItem(
    String date,
    String linkedId, {
    required DateTime completedAt,
    required int? durationSeconds,
    required String? startedAtIso,
  }) async {
    final startIso = startedAtIso ??
        (durationSeconds != null
            ? completedAt
                .subtract(Duration(seconds: durationSeconds))
                .toIso8601String()
            : null);

    final flow = getDailyFlow(date);
    if (flow != null) {
      final activities = List<FlowActivity>.from(flow.activities);
      final idx = activities.indexWhere((a) => a.id == linkedId);
      if (idx >= 0) {
        final linkedActivity = activities[idx];
        activities[idx] = linkedActivity.copyWith(
          status: 'DONE',
          startedAt: linkedActivity.startedAt ?? startIso,
          completedAt: completedAt.toIso8601String(),
          durationSeconds: durationSeconds ?? linkedActivity.durationSeconds,
        );
        await upsertDailyFlow(flow.copyWith(activities: activities));
        return;
      }
    }

    final plan = getDayPlan(date);
    final planBlocks = plan?.blocks;
    if (plan == null || planBlocks == null) return;

    final blocks = List<Block>.from(planBlocks);
    final idx = blocks.indexWhere((b) => b.id == linkedId);
    if (idx < 0) return;

    final block = blocks[idx];
    blocks[idx] = block.copyWith(
      status: BlockStatus.done,
      actualStartTime: block.actualStartTime ?? startIso,
      actualEndTime: completedAt.toIso8601String(),
      actualDurationMinutes: durationSeconds != null
          ? (durationSeconds / 60).ceil()
          : block.actualDurationMinutes,
      completionStatus: 'COMPLETED',
    );
    await upsertDayPlan(plan.copyWith(blocks: blocks));
  }

  Map<String, dynamic>? _resolveTrackNowStructuredTarget(
    String date,
    String linkedId, {
    Set<String>? visited,
  }) {
    final seen = visited ?? <String>{};
    if (!seen.add(linkedId)) return null;

    final planBlocks = getDayPlan(date)?.blocks ?? const <Block>[];
    for (final block in planBlocks) {
      if (block.id == linkedId) {
        final tasks = block.tasks ?? const <BlockTask>[];
        if (tasks.length == 1 && tasks.first.meta != null) {
          return {'task': tasks.first};
        }
        final hasStructuredBlockData =
            (block.relatedFaPages?.isNotEmpty ?? false) ||
                block.relatedVideoId != null ||
                block.relatedQbankInfo != null;
        if (hasStructuredBlockData) {
          return {'block': block};
        }
        return null;
      }

      for (final task in block.tasks ?? const <BlockTask>[]) {
        if (task.id == linkedId && task.meta != null) {
          return {'task': task};
        }
      }
    }

    final flow = getDailyFlow(date);
    if (flow == null) return null;

    final idx = flow.activities.indexWhere((a) => a.id == linkedId);
    if (idx < 0) return null;

    for (final nestedId in flow.activities[idx].linkedTaskIds) {
      final resolved = _resolveTrackNowStructuredTarget(
        date,
        nestedId,
        visited: seen,
      );
      if (resolved != null) return resolved;
    }
    return null;
  }

  Future<void> _syncTrackNowLinkedLibraryItem(
    String date,
    String linkedId,
  ) async {
    final resolved = _resolveTrackNowStructuredTarget(date, linkedId);
    if (resolved == null) return;

    final task = resolved['task'] as BlockTask?;
    if (task != null) {
      await completeStudyTask(task.copyWith(completed: true));
      return;
    }

    final block = resolved['block'] as Block?;
    if (block == null) return;

    final relatedPages = block.relatedFaPages ?? const <int>[];
    if (relatedPages.isNotEmpty) {
      for (final pageNum in relatedPages) {
        final pageIdx = faPages.indexWhere((p) => p.pageNum == pageNum);
        if (pageIdx < 0) continue;
        final page = faPages[pageIdx];
        if (page.status == 'unread') {
          await updateFAPageStatus(pageNum, 'read');
        } else {
          await advanceFAPageRevision(pageNum);
        }
      }
      return;
    }

    final videoId = int.tryParse(block.relatedVideoId ?? '');
    if (videoId != null) {
      if (sketchyMicroVideos.any((v) => v.id == videoId)) {
        await advanceSketchyMicroRevision(videoId);
        return;
      }
      if (sketchyPharmVideos.any((v) => v.id == videoId)) {
        await advanceSketchyPharmRevision(videoId);
        return;
      }
      if (pathomaChapters.any((c) => c.id == videoId)) {
        await advancePathomaRevision(videoId);
        return;
      }
    }

    final qbankInfo = block.relatedQbankInfo;
    if (qbankInfo == null) return;

    final topicIdRaw = qbankInfo['topicId'];
    final countRaw = qbankInfo['count'] ??
        qbankInfo['doneQuestions'] ??
        qbankInfo['questions'];
    final correctRaw = qbankInfo['correctQuestions'] ?? 0;

    final topicId =
        topicIdRaw is int ? topicIdRaw : int.tryParse('$topicIdRaw');
    final count = countRaw is int ? countRaw : int.tryParse('$countRaw');
    final correct =
        correctRaw is int ? correctRaw : int.tryParse('$correctRaw') ?? 0;
    if (topicId == null || count == null) return;

    final topicIdx = uworldTopics.indexWhere((t) => t.id == topicId);
    if (topicIdx < 0) return;

    final topic = uworldTopics[topicIdx];
    await updateUWorldProgress(
      topicId,
      topic.doneQuestions + count,
      topic.correctQuestions + correct,
    );
    await addUWorldSession(
      UWorldSession(
        id: _uuid.v4(),
        subject: topic.system,
        done: count,
        correct: correct,
        date: date,
      ),
    );
  }

  /// Icon helper for Track Now categories.
  static String _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'cooking':
        return '🍳';
      case 'cleaning':
        return '🧹';
      case 'exercise':
        return '💪';
      case 'study':
        return '📚';
      case 'prayer':
        return '🕌';
      case 'shopping':
        return '🛒';
      case 'eating':
        return '🍽️';
      case 'rest':
        return '😴';
      case 'travel':
        return '🚗';
      case 'work':
        return '💼';
      default:
        return '⏱️';
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // PRAYER ROUTINE SEEDING
  // ═════════════════════════════════════════════════════════════════

  /// Seed default prayer routines if they don't already exist.
  Future<void> seedPrayerRoutines() async {
    const prayerNames = ['Fajr', 'Zuhr', 'Asr', 'Maghrib', 'Isha'];
    final existingNames = routines.map((r) => r.name).toSet();

    for (final name in prayerNames) {
      if (existingNames.contains(name)) continue;

      final routine = Routine(
        id: 'prayer_${name.toLowerCase()}',
        name: name,
        icon: '🕌',
        color: 0xFF059669,
        steps: [
          RoutineStep(
              id: '${name.toLowerCase()}_wudu',
              title: 'Wudu (Ablution)',
              estimatedMinutes: 5,
              sortOrder: 0),
          RoutineStep(
              id: '${name.toLowerCase()}_walk',
              title: 'Walk to Mosque',
              estimatedMinutes: 5,
              sortOrder: 1),
          RoutineStep(
              id: '${name.toLowerCase()}_pray',
              title: '$name Prayer',
              estimatedMinutes: 10,
              sortOrder: 2),
          RoutineStep(
              id: '${name.toLowerCase()}_tasbeeh',
              title: 'Tasbeeh & Dhikr',
              estimatedMinutes: 5,
              sortOrder: 3),
          RoutineStep(
              id: '${name.toLowerCase()}_dua',
              title: 'Dua & Quran Reading',
              estimatedMinutes: 5,
              sortOrder: 4),
        ],
        createdAt: DateTime.now().toIso8601String(),
      );
      await upsertRoutine(routine);
    }
  }

  /// Get the highest completed FA page number
  int getLastCompletedFAPage() {
    int maxPage = 0;
    for (final p in faPages) {
      if ((p.status == 'read' || p.status == 'anki_done') &&
          p.pageNum > maxPage) {
        maxPage = p.pageNum;
      }
    }
    return maxPage;
  }

  FAPage? getFAPage(int pageNum) {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return null;
    return faPages[idx];
  }

  RevisionItem? getFAPageRevisionItem(int pageNum) {
    final revId = 'fa-page-$pageNum';
    final idx = revisionItems.indexWhere((item) => item.id == revId);
    if (idx < 0) return null;
    return revisionItems[idx];
  }

  /// Gap-aware: find the first unread FA page in book order.
  /// Respects gaps — e.g. if 33-34 read, 35 unread, 36-37 read → returns 35.
  /// After 35, returns 38 (since 36-37 already read).
  int getNextContinuePage() {
    if (faPages.isEmpty) return 33; // FA 2025 starts at page 33
    final sorted = List<FAPage>.from(faPages)
      ..sort((a, b) => a.pageNum.compareTo(b.pageNum));
    for (final p in sorted) {
      if (p.status == 'unread') return p.pageNum;
    }
    // All pages read — return the page after the last one
    return sorted.last.pageNum + 1;
  }

  /// Get ordered list of unread pages for today's study target.
  /// Returns up to [count] unread pages in book order, gap-aware.
  List<int> getTodayTargetPages({int count = 10}) {
    if (faPages.isEmpty) return [];
    final sorted = List<FAPage>.from(faPages)
      ..sort((a, b) => a.pageNum.compareTo(b.pageNum));
    final result = <int>[];
    for (final p in sorted) {
      if (p.status == 'unread') {
        result.add(p.pageNum);
        if (result.length >= count) break;
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════════════════════════

  Future<void> addHistoryRecord(HistoryRecord record) async {
    await _db.insertHistoryRecord(record.toJson());
    history.insert(0, record); // newest first
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // REVISION ITEMS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertRevisionItem(RevisionItem item) async {
    await _db.upsertRevisionItem(item.toJson());
    final idx = revisionItems.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      revisionItems[idx] = item;
    } else {
      revisionItems.add(item);
    }
    notifyListeners();
    unawaited(_triggerBackup());
  }

  Future<void> deleteRevisionItem(String id) async {
    await _db.deleteRevisionItem(id);
    revisionItems.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Advance a RevisionItem to the next SRS step.
  /// If mastered (all steps done), the item is deleted.
  Future<void> markRevisionItemDone(String revId) async {
    final idx = revisionItems.indexWhere((r) => r.id == revId);
    if (idx < 0) return;
    final item = revisionItems[idx];
    final mode = revisionSettings?.mode ?? 'strict';
    final newIndex = item.currentRevisionIndex + 1;
    if (SrsService.isMastered(revisionIndex: newIndex, mode: mode)) {
      await deleteRevisionItem(revId);
      return;
    }
    final now = DateTime.now();
    final nextDate = SrsService.calculateNextRevisionDateString(
      lastStudiedAt: now.toIso8601String(),
      revisionIndex: newIndex,
      mode: mode,
    );
    final updated = item.copyWith(
      currentRevisionIndex: newIndex,
      nextRevisionAt:
          nextDate ?? now.add(const Duration(days: 1)).toIso8601String(),
      lastStudiedAt: now.toIso8601String(),
    );
    await upsertRevisionItem(updated);
  }

  /// Smart confidence-based revision: 'hard', 'good', or 'easy'.
  /// Updates scheduling, logs, and retention score via SrsService.
  Future<void> markRevisionItemWithConfidence(String revId, String quality) async {
    final idx = revisionItems.indexWhere((r) => r.id == revId);
    if (idx < 0) return;
    final item = revisionItems[idx];
    final mode = revisionSettings?.mode ?? 'strict';

    final updated = SrsService.processConfidenceResponse(
      item: item,
      quality: quality,
      mode: mode,
    );

    // Check if mastered (empty nextRevisionAt)
    if (updated.nextRevisionAt.isEmpty) {
      await deleteRevisionItem(revId);
      return;
    }

    await upsertRevisionItem(updated);
  }

  /// Smart confidence-based revision for KB entries.
  Future<void> markKBEntryWithConfidence(String kbPageNumber, String quality) async {
    final kbIdx = knowledgeBase.indexWhere((e) => e.pageNumber == kbPageNumber);
    if (kbIdx < 0) return;
    final kb = knowledgeBase[kbIdx];
    final mode = revisionSettings?.mode ?? 'strict';

    // Convert KB entry to a temporary RevisionItem for processing
    final tempItem = RevisionItem(
      id: 'kb-$kbPageNumber',
      type: 'PAGE',
      source: 'KB',
      title: kb.title,
      parentTitle: kb.subject,
      pageNumber: kbPageNumber,
      nextRevisionAt: kb.nextRevisionAt ?? '',
      currentRevisionIndex: kb.currentRevisionIndex,
      totalSteps: 12,
      lastStudiedAt: kb.lastStudiedAt,
      hardCount: kb.hardCount,
      effectiveSrsStep: kb.effectiveSrsStep,
      easyFlag: kb.easyFlag,
      retentionScore: kb.retentionScore,
      revisionLog: kb.revisionLog,
    );

    final updated = SrsService.processConfidenceResponse(
      item: tempItem,
      quality: quality,
      mode: mode,
    );

    // Write back to KB entry
    final updatedKb = kb.copyWith(
      currentRevisionIndex: updated.currentRevisionIndex,
      lastStudiedAt: updated.lastStudiedAt,
      nextRevisionAt: updated.nextRevisionAt,
      revisionCount: kb.revisionCount + (quality != 'hard' ? 1 : 0),
      hardCount: updated.hardCount,
      effectiveSrsStep: updated.effectiveSrsStep,
      easyFlag: updated.easyFlag,
      retentionScore: updated.retentionScore,
      revisionLog: updated.revisionLog,
    );
    await upsertKBEntry(updatedKb);
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY TASK COMPLETION → TRACKER + REVISION HUB
  // ═══════════════════════════════════════════════════════════════

  /// Called when a block task is completed from Today's Plan.
  /// Updates the relevant tracker and creates/advances revision items.
  Future<void> completeStudyTask(BlockTask task) async {
    final meta = task.meta;
    if (meta == null) return;

    final isRev = meta.isRevision ?? false;

    switch (task.type) {
      case 'FA':
      case 'REVISION':
        // FA page task — mark page as read or advance revision
        if (meta.pageNumber != null) {
          final pageNum = meta.pageNumber!;
          final pageIdx = faPages.indexWhere((p) => p.pageNum == pageNum);
          if (pageIdx >= 0) {
            if (isRev) {
              // Advance existing revision item
              final revId = 'fa-page-$pageNum';
              final revIdx = revisionItems.indexWhere((r) => r.id == revId);
              if (revIdx >= 0) {
                await markRevisionItemDone(revId);
              }
              // Also bump the page revision count
              final page = faPages[pageIdx];
              final newRevCount = page.revisionCount + 1;
              final now = DateTime.now().toIso8601String();
              final updated = page.copyWith(
                revisionCount: newRevCount,
                lastRevisedAt: now,
                lastReviewed: now,
                revisionHistory: [
                  ...page.revisionHistory,
                  FAPageRevision(date: now, revisionNum: newRevCount),
                ],
              );
              await upsertFAPage(updated);
            } else {
              // First study — mark as read (creates revision item via existing logic)
              await updateFAPageStatus(pageNum, 'read');
            }
          }
        }
        break;

      case 'VIDEO':
        // Check if it's a Sketchy video
        if (meta.topic != null) {
          // Try Sketchy Micro
          final microIdx = sketchyMicroVideos.indexWhere(
            (v) => v.title.toLowerCase() == meta.topic!.toLowerCase(),
          );
          if (microIdx >= 0 && !sketchyMicroVideos[microIdx].watched) {
            await toggleSketchyMicroWatched(
                sketchyMicroVideos[microIdx].id!, true);
            break;
          }
          // Try Sketchy Pharm
          final pharmIdx = sketchyPharmVideos.indexWhere(
            (v) => v.title.toLowerCase() == meta.topic!.toLowerCase(),
          );
          if (pharmIdx >= 0 && !sketchyPharmVideos[pharmIdx].watched) {
            await toggleSketchyPharmWatched(
                sketchyPharmVideos[pharmIdx].id!, true);
            break;
          }
          // Try Pathoma
          final pathomaIdx = pathomaChapters.indexWhere(
            (v) => v.title.toLowerCase() == meta.topic!.toLowerCase(),
          );
          if (pathomaIdx >= 0 && !pathomaChapters[pathomaIdx].watched) {
            await togglePathomaChapterWatched(
                pathomaChapters[pathomaIdx].id!, true);
            break;
          }
        }
        break;

      case 'QBANK':
        // UWorld progress update
        if (meta.system != null && meta.count != null) {
          final topicIdx = uworldTopics.indexWhere(
            (t) => t.system.toLowerCase() == meta.system!.toLowerCase(),
          );
          if (topicIdx >= 0) {
            final topic = uworldTopics[topicIdx];
            await updateUWorldProgress(
              topic.id!,
              topic.doneQuestions + meta.count!,
              topic.correctQuestions,
            );
          }
        }
        break;

      default:
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FA PAGES (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertFAPage(FAPage page) async {
    await _db.upsertFAPage(page.toJson());
    final idx = faPages.indexWhere((p) => p.pageNum == page.pageNum);
    if (idx >= 0) {
      faPages[idx] = page;
    } else {
      faPages.add(page);
    }
    notifyListeners();
  }

  Future<void> updateFAPageStatus(int pageNum, String status) async {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return;
    final now = DateTime.now().toIso8601String();
    final page = faPages[idx];
    final updated = page.copyWith(
      status: status,
      lastReviewed: now,
      firstReadAt: (status == 'read' || status == 'anki_done')
          ? (page.firstReadAt ?? now)
          : page.firstReadAt,
      ankiDoneAt:
          status == 'anki_done' ? (page.ankiDoneAt ?? now) : page.ankiDoneAt,
    );
    await upsertFAPage(updated);

    // Create revision item for direct page reads (not from subtopic flow)
    if (status == 'read' || status == 'anki_done') {
      final revId = 'fa-page-$pageNum';
      final exists = revisionItems.any((r) => r.id == revId);
      if (!exists) {
        final mode = revisionSettings?.mode ?? 'strict';
        final nextDate = SrsService.calculateNextRevisionDateString(
          lastStudiedAt: now,
          revisionIndex: 0,
          mode: mode,
        );
        final revItem = RevisionItem(
          id: revId,
          type: 'PAGE',
          source: 'FA',
          pageNumber: pageNum.toString(),
          title: updated.title,
          parentTitle: updated.subject,
          nextRevisionAt: nextDate ??
              DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
          currentRevisionIndex: 0,
          lastStudiedAt: now,
          totalSteps: SrsService.totalSteps(mode),
        );
        await upsertRevisionItem(revItem);
      }
    } else if (status == 'unread') {
      final revId = 'fa-page-$pageNum';
      if (revisionItems.any((r) => r.id == revId)) {
        await deleteRevisionItem(revId);
      }
    }

    // Log activity
    await _logActivity(
      itemId: 'fa:$pageNum',
      itemType: 'fa',
      action: status == 'unread' ? 'reset' : status == 'read' ? 'read' : 'anki_done',
      title: updated.title.isNotEmpty ? 'FA p.$pageNum — ${updated.title}' : 'FA Page $pageNum',
    );
  }

  /// Bulk-update FA pages in range [from..to] to the given status.
  /// Returns the count of pages actually updated.
  /// PERFORMANCE: All DB writes are batched. notifyListeners() fires only once at the end.
  /// REVISION FIX: Creates one PAGE-level revision item per page — not per-subtopic.
  Future<int> bulkMarkFAPages(int from, int to, String status) async {
    int count = 0;
    final now = DateTime.now().toIso8601String();
    final mode = revisionSettings?.mode ?? 'strict';

    // ── Step 1: Update FA pages in range ──────────────────────────
    for (int i = 0; i < faPages.length; i++) {
      final p = faPages[i];
      if (p.pageNum >= from && p.pageNum <= to && p.status != status) {
        final updated = p.copyWith(
          status: status,
          lastReviewed: now,
          firstReadAt: (status == 'read' || status == 'anki_done')
              ? (p.firstReadAt ?? now)
              : p.firstReadAt,
          ankiDoneAt:
              status == 'anki_done' ? (p.ankiDoneAt ?? now) : p.ankiDoneAt,
        );
        // DB write — no notifyListeners here
        await _db.upsertFAPage(updated.toJson());
        faPages[i] = updated;
        count++;

        // ── Create ONE page-level revision item ───────────────────
        if (status == 'read' || status == 'anki_done') {
          final revId = 'fa-page-${p.pageNum}';
          // Remove any stale subtopic revisions for this page
          final staleIds = revisionItems
              .where((r) =>
                  r.type == 'SUBTOPIC' &&
                  r.source == 'FA' &&
                  r.pageNumber == p.pageNum.toString())
              .map((r) => r.id)
              .toList();
          for (final sid in staleIds) {
            await _db.deleteRevisionItem(sid);
            revisionItems.removeWhere((r) => r.id == sid);
          }

          // Create page revision if not already there
          if (!revisionItems.any((r) => r.id == revId)) {
            final nextDate = SrsService.calculateNextRevisionDateString(
              lastStudiedAt: now,
              revisionIndex: 0,
              mode: mode,
            );
            final revItem = RevisionItem(
              id: revId,
              type: 'PAGE',
              source: 'FA',
              pageNumber: p.pageNum.toString(),
              title: updated.title,
              parentTitle: updated.subject,
              nextRevisionAt: nextDate ??
                  DateTime.now()
                      .add(const Duration(hours: 8))
                      .toIso8601String(),
              currentRevisionIndex: 0,
              lastStudiedAt: now,
              totalSteps: SrsService.totalSteps(mode),
            );
            await _db.upsertRevisionItem(revItem.toJson());
            revisionItems.add(revItem);
          }
        } else if (status == 'unread') {
          // Remove page revision
          final revId = 'fa-page-${p.pageNum}';
          if (revisionItems.any((r) => r.id == revId)) {
            await _db.deleteRevisionItem(revId);
            revisionItems.removeWhere((r) => r.id == revId);
          }
        }
      }
    }

    // ── Step 2: Update subtopics silently (no per-subtopic revisions) ─
    for (int i = 0; i < faSubtopics.length; i++) {
      final sub = faSubtopics[i];
      if (sub.pageNum >= from && sub.pageNum <= to && sub.status != status) {
        if (status == 'read') {
          final updated = sub.copyWith(
            status: 'read',
            firstReadAt: sub.firstReadAt ?? now,
          );
          await _db.updateFASubtopicStatus(
            sub.id!,
            status: 'read',
            firstReadAt: updated.firstReadAt,
          );
          faSubtopics[i] = updated;
        } else if (status == 'anki_done') {
          final updated = sub.copyWith(status: 'anki_done', ankiDoneAt: now);
          await _db.updateFASubtopicStatus(
            sub.id!,
            status: 'anki_done',
            ankiDoneAt: now,
          );
          faSubtopics[i] = updated;
        } else if (status == 'unread') {
          await _db.resetFASubtopic(sub.id!);
          faSubtopics[i] = FASubtopic(
            id: sub.id,
            pageNum: sub.pageNum,
            name: sub.name,
          );
        }
      }
    }

    // ── Step 3: One single rebuild ────────────────────────────────
    notifyListeners();
    unawaited(_triggerBackup());
    return count;
  }

  Future<void> deleteFAPage(int pageNum) async {
    await _db.deleteFAPage(pageNum);
    faPages.removeWhere((p) => p.pageNum == pageNum);
    notifyListeners();
  }

  Future<void> advanceFAPageRevision(int pageNum) async {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return;
    final page = faPages[idx];

    String nextStatus;
    if (page.status == 'unread') {
      nextStatus = 'read';
    } else if (page.status == 'read') {
      nextStatus = 'anki_done';
    } else {
      nextStatus = 'anki_done';
    }

    final now = DateTime.now().toIso8601String();
    final updated = page.copyWith(
      status: nextStatus,
      revisionCount: (page.status == 'anki_done')
          ? page.revisionCount + 1
          : page.revisionCount,
      lastReviewed: now,
      firstReadAt: (nextStatus == 'read' && page.status == 'unread')
          ? now
          : page.firstReadAt,
      ankiDoneAt: (nextStatus == 'anki_done' && page.status != 'anki_done')
          ? now
          : page.ankiDoneAt,
    );

    await upsertFAPage(updated);

    if (nextStatus == 'read' || nextStatus == 'anki_done') {
      final revId = 'fa-page-$pageNum';
      final mode = revisionSettings?.mode ?? 'strict';
      final nextDate = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: now,
        revisionIndex: updated.revisionCount,
        mode: mode,
      );

      final existingRevIdx = revisionItems.indexWhere((r) => r.id == revId);
      if (existingRevIdx >= 0) {
        final existing = revisionItems[existingRevIdx];
        final newRev = existing.copyWith(
          currentRevisionIndex: updated.revisionCount,
          lastStudiedAt: now,
          nextRevisionAt: nextDate,
        );
        await _db.upsertRevisionItem(newRev.toJson());
        revisionItems[existingRevIdx] = newRev;
      } else {
        final revItem = RevisionItem(
          id: revId,
          type: 'PAGE',
          source: 'FA',
          pageNumber: pageNum.toString(),
          title: updated.title,
          parentTitle: updated.subject,
          nextRevisionAt: nextDate ??
              DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
          currentRevisionIndex: updated.revisionCount,
          lastStudiedAt: now,
          totalSteps: SrsService.totalSteps(mode),
        );
        await _db.upsertRevisionItem(revItem.toJson());
        revisionItems.add(revItem);
      }
    }
    notifyListeners();
  }

  Future<void> undoFAPage(int pageNum) async {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return;
    final page = faPages[idx];

    String nextStatus = page.status;
    int nextRevCount = page.revisionCount;

    if (page.revisionCount > 0) {
      nextRevCount--;
    } else if (page.status == 'anki_done') {
      nextStatus = 'read';
    } else if (page.status == 'read') {
      nextStatus = 'unread';
    }

    final updated = page.copyWith(
      status: nextStatus,
      revisionCount: nextRevCount,
    );

    await upsertFAPage(updated);

    if (nextStatus == 'unread') {
      final revId = 'fa-page-$pageNum';
      if (revisionItems.any((r) => r.id == revId)) {
        await deleteRevisionItem(revId);
      }
    }
    notifyListeners();
  }

  Future<void> resetFAPage(int pageNum) async {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return;
    final page = faPages[idx];

    final updated = page.copyWith(
      status: 'unread',
      revisionCount: 0,
      firstReadAt: null,
      ankiDoneAt: null,
      lastReviewed: null,
    );

    // We update DB directly to nullify the fields properly since copyWith might ignore nulls depending on implementation
    await _db.updateFAPage(updated.toJson()
      ..addAll({
        'first_read_at': null,
        'anki_done_at': null,
        'last_reviewed': null,
      }));
    faPages[idx] = updated;

    final subtopicIdsToDelete = <String>[];
    for (var i = 0; i < faSubtopics.length; i++) {
      final sub = faSubtopics[i];
      if (sub.pageNum != pageNum || sub.id == null) continue;

      await _db.resetFASubtopic(sub.id!);
      faSubtopics[i] = FASubtopic(
        id: sub.id,
        pageNum: sub.pageNum,
        name: sub.name,
      );
      subtopicIdsToDelete.add('fa-sub-${sub.pageNum}-${sub.id}');
    }

    final revId = 'fa-page-$pageNum';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
    for (final subRevId in subtopicIdsToDelete) {
      if (revisionItems.any((r) => r.id == subRevId)) {
        await deleteRevisionItem(subRevId);
      }
    }
    notifyListeners();
    unawaited(_triggerBackup());
  }

  // ═══════════════════════════════════════════════════════════════
  // FA SUBTOPICS (v5)
  // ═══════════════════════════════════════════════════════════════

  /// Get subtopics for a specific page
  List<FASubtopic> getSubtopicsForPage(int pageNum) =>
      faSubtopics.where((s) => s.pageNum == pageNum).toList();

  /// Calculate subtopic completion percentage for a page
  double getPageCompletionPercent(int pageNum) {
    final subs = getSubtopicsForPage(pageNum);
    if (subs.isEmpty) return 0;
    final done = subs.where((s) => s.status != 'unread').length;
    return done / subs.length;
  }

  /// Mark a subtopic as read
  Future<void> markSubtopicRead(int subtopicId) async {
    final idx = faSubtopics.indexWhere((s) => s.id == subtopicId);
    if (idx < 0) return;
    final now = DateTime.now().toIso8601String();
    final sub = faSubtopics[idx];
    final updated = sub.copyWith(
      status: 'read',
      firstReadAt: sub.firstReadAt ?? now,
    );
    await _db.updateFASubtopicStatus(
      subtopicId,
      status: 'read',
      firstReadAt: updated.firstReadAt,
    );
    faSubtopics[idx] = updated;

    // Create a revision item for this subtopic
    await _createSubtopicRevision(updated);

    notifyListeners();
    await _checkPageCompletion(updated.pageNum);
    unawaited(_triggerBackup());
  }

  /// Mark multiple subtopics as read at once
  Future<void> markSubtopicsRead(List<int> subtopicIds) async {
    final now = DateTime.now().toIso8601String();
    int? pageNum;
    for (final id in subtopicIds) {
      final idx = faSubtopics.indexWhere((s) => s.id == id);
      if (idx < 0) continue;
      pageNum = faSubtopics[idx].pageNum;
      final sub = faSubtopics[idx];
      final updated = sub.copyWith(
        status: 'read',
        firstReadAt: sub.firstReadAt ?? now,
      );
      await _db.updateFASubtopicStatus(
        id,
        status: 'read',
        firstReadAt: updated.firstReadAt,
      );
      faSubtopics[idx] = updated;

      // Create a revision item for each newly read subtopic
      await _createSubtopicRevision(updated);
    }
    notifyListeners();
    if (pageNum != null) {
      await _checkPageCompletion(pageNum);
    }
    unawaited(_triggerBackup());
  }

  /// Mark a subtopic as anki_done
  Future<void> markSubtopicAnkiDone(int subtopicId) async {
    final idx = faSubtopics.indexWhere((s) => s.id == subtopicId);
    if (idx < 0) return;
    final now = DateTime.now().toIso8601String();
    final updated = faSubtopics[idx].copyWith(
      status: 'anki_done',
      ankiDoneAt: now,
    );
    await _db.updateFASubtopicStatus(
      subtopicId,
      status: 'anki_done',
      ankiDoneAt: now,
    );
    faSubtopics[idx] = updated;
    notifyListeners();
    unawaited(_triggerBackup());
  }

  /// Reset a subtopic to unread
  Future<void> resetFASubtopic(int subtopicId) async {
    final idx = faSubtopics.indexWhere((s) => s.id == subtopicId);
    if (idx < 0) return;
    await _db.resetFASubtopic(subtopicId);
    faSubtopics[idx] = FASubtopic(
      id: faSubtopics[idx].id,
      pageNum: faSubtopics[idx].pageNum,
      name: faSubtopics[idx].name,
    );
    notifyListeners();
  }

  Future<void> advanceFASubtopicRevision(int subtopicId) async {
    final idx = faSubtopics.indexWhere((s) => s.id == subtopicId);
    if (idx < 0) return;
    final sub = faSubtopics[idx];

    if (sub.status == 'unread') {
      await markSubtopicRead(subtopicId);
    } else if (sub.status == 'read') {
      await markSubtopicAnkiDone(subtopicId);
    }
  }

  Future<void> undoFASubtopic(int subtopicId) async {
    final idx = faSubtopics.indexWhere((s) => s.id == subtopicId);
    if (idx < 0) return;
    final sub = faSubtopics[idx];

    if (sub.status == 'anki_done') {
      final updated = sub.copyWith(status: 'read');
      await _db.updateFASubtopicStatus(subtopicId,
          status: 'read', firstReadAt: sub.firstReadAt);
      faSubtopics[idx] = updated;
      notifyListeners();
    } else if (sub.status == 'read') {
      await resetFASubtopic(subtopicId);
    }
  }

  /// Create a revision item for a subtopic that was just read
  Future<void> _createSubtopicRevision(FASubtopic sub) async {
    // Find parent page for context
    final page = faPages.firstWhere(
      (p) => p.pageNum == sub.pageNum,
      orElse: () => FAPage(
        pageNum: sub.pageNum,
        subject: '',
        system: '',
        title: '',
        status: 'unread',
      ),
    );
    final revId = 'fa-sub-${sub.pageNum}-${sub.id}';
    // Only create if doesn't exist yet
    final exists = revisionItems.any((r) => r.id == revId);
    if (exists) return;

    final mode = revisionSettings?.mode ?? 'strict';
    final now = DateTime.now().toIso8601String();
    final nextDate = SrsService.calculateNextRevisionDateString(
      lastStudiedAt: now,
      revisionIndex: 0,
      mode: mode,
    );
    final revItem = RevisionItem(
      id: revId,
      type: 'SUBTOPIC',
      source: 'FA',
      pageNumber: sub.pageNum.toString(),
      title: sub.name,
      parentTitle: '${page.subject} p.${sub.pageNum}',
      nextRevisionAt: nextDate ??
          DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
      currentRevisionIndex: 0,
      lastStudiedAt: now,
      totalSteps: SrsService.totalSteps(mode),
    );
    await upsertRevisionItem(revItem);
  }

  /// Auto-promote page when all subtopics are read/done
  Future<void> _checkPageCompletion(int pageNum) async {
    final subs = getSubtopicsForPage(pageNum);
    if (subs.isEmpty) return;
    final allRead =
        subs.every((s) => s.status == 'read' || s.status == 'anki_done');
    if (allRead) {
      final pageIdx = faPages.indexWhere((p) => p.pageNum == pageNum);
      if (pageIdx >= 0 && faPages[pageIdx].status == 'unread') {
        final now = DateTime.now().toIso8601String();
        final updated = faPages[pageIdx].copyWith(
          status: 'read',
          firstReadAt: faPages[pageIdx].firstReadAt ?? now,
          lastReviewed: now,
        );
        await _db.upsertFAPage(updated.toJson());
        faPages[pageIdx] = updated;

        // Cancel all subtopic-level revisions for this page
        final subRevIds = revisionItems
            .where((r) =>
                r.type == 'SUBTOPIC' && r.pageNumber == pageNum.toString())
            .map((r) => r.id)
            .toList();
        for (final rid in subRevIds) {
          await deleteRevisionItem(rid);
        }

        // Create page-level R0 revision
        final pageRevId = 'fa-page-$pageNum';
        final mode = revisionSettings?.mode ?? 'strict';
        final nowStr = DateTime.now().toIso8601String();
        final nextDate = SrsService.calculateNextRevisionDateString(
          lastStudiedAt: nowStr,
          revisionIndex: 0,
          mode: mode,
        );
        final pageRev = RevisionItem(
          id: pageRevId,
          type: 'PAGE',
          source: 'FA',
          pageNumber: pageNum.toString(),
          title: updated.title,
          parentTitle: updated.subject,
          nextRevisionAt: nextDate ??
              DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
          currentRevisionIndex: 0,
          lastStudiedAt: nowStr,
          totalSteps: SrsService.totalSteps(mode),
        );
        await upsertRevisionItem(pageRev);

        notifyListeners();
      }
    }
  }

  /// Save FA View Mode to SharedPreferences
  Future<void> saveFAViewMode(String mode) async {
    faViewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('faViewMode', mode);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY ITEMS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertSketchyItem(SketchyItem item) async {
    await _db.upsertSketchyItem(item.toJson());
    final idx = sketchyItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      sketchyItems[idx] = item;
    } else {
      sketchyItems.add(item);
    }
    notifyListeners();
    unawaited(_triggerBackup());
  }

  Future<void> updateSketchyStatus(String id, String status) async {
    final idx = sketchyItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    await upsertSketchyItem(sketchyItems[idx].copyWith(status: status));
  }

  // ═══════════════════════════════════════════════════════════════
  // PATHOMA ITEMS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertPathomaItem(PathomaItem item) async {
    await _db.upsertPathomaItem(item.toJson());
    final idx = pathomaItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      pathomaItems[idx] = item;
    } else {
      pathomaItems.add(item);
    }
    notifyListeners();
    unawaited(_triggerBackup());
  }

  Future<void> updatePathomaStatus(String id, String status) async {
    final idx = pathomaItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    await upsertPathomaItem(pathomaItems[idx].copyWith(status: status));
  }

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY MICRO VIDEOS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleSketchyMicroWatched(int id, bool watched) async {
    await _db.toggleSketchyMicro(id, watched);
    final idx = sketchyMicroVideos.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      sketchyMicroVideos[idx] =
          sketchyMicroVideos[idx].copyWith(watched: watched);
      // Create revision item when watched
      if (watched) {
        final video = sketchyMicroVideos[idx];
        final revId = 'sketchy-micro-$id';
        final exists = revisionItems.any((r) => r.id == revId);
        if (!exists) {
          final mode = revisionSettings?.mode ?? 'strict';
          final now = DateTime.now().toIso8601String();
          final nextDate = SrsService.calculateNextRevisionDateString(
            lastStudiedAt: now,
            revisionIndex: 0,
            mode: mode,
          );
          final revItem = RevisionItem(
            id: revId,
            type: 'VIDEO',
            source: 'SKETCHY_MICRO',
            pageNumber: '',
            title: video.title,
            parentTitle: '${video.category} › ${video.subcategory}',
            nextRevisionAt: nextDate ??
                DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
            currentRevisionIndex: 0,
            lastStudiedAt: now,
            totalSteps: SrsService.totalSteps(mode),
          );
          await upsertRevisionItem(revItem);
        }
      }
    }
    notifyListeners();
    unawaited(_triggerBackup());

    // Log activity
    final logVideo = idx >= 0 ? sketchyMicroVideos[idx] : null;
    await _logActivity(
      itemId: 'sketchy-micro:$id',
      itemType: 'sketchy',
      action: watched ? 'watched' : 'unwatched',
      title: logVideo != null ? 'Sketchy Micro — ${logVideo.title}' : 'Sketchy Micro #$id',
    );
  }

  Future<void> undoSketchyMicro(int id) async {
    await toggleSketchyMicroWatched(id, false);
    // Also remove revision tracking
    final revId = 'sketchy-micro-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
  }

  Future<void> resetSketchyMicro(int id) async {
    final idx = sketchyMicroVideos.indexWhere((v) => v.id == id);
    final video = idx >= 0 ? sketchyMicroVideos[idx] : null;
    await toggleSketchyMicroWatched(id, false);
    final revId = 'sketchy-micro-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
    if (video != null) {
      await _deleteTimeLogsForActivities(
        {'Sketchy: ${video.title}'},
        category: TimeLogCategory.video,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY PHARM VIDEOS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleSketchyPharmWatched(int id, bool watched) async {
    await _db.toggleSketchyPharm(id, watched);
    final idx = sketchyPharmVideos.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      sketchyPharmVideos[idx] =
          sketchyPharmVideos[idx].copyWith(watched: watched);
      // Create revision item when watched
      if (watched) {
        final video = sketchyPharmVideos[idx];
        final revId = 'sketchy-pharm-$id';
        final exists = revisionItems.any((r) => r.id == revId);
        if (!exists) {
          final mode = revisionSettings?.mode ?? 'strict';
          final now = DateTime.now().toIso8601String();
          final nextDate = SrsService.calculateNextRevisionDateString(
            lastStudiedAt: now,
            revisionIndex: 0,
            mode: mode,
          );
          final revItem = RevisionItem(
            id: revId,
            type: 'VIDEO',
            source: 'SKETCHY_PHARM',
            pageNumber: '',
            title: video.title,
            parentTitle: '${video.category} › ${video.subcategory}',
            nextRevisionAt: nextDate ??
                DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
            currentRevisionIndex: 0,
            lastStudiedAt: now,
            totalSteps: SrsService.totalSteps(mode),
          );
          await upsertRevisionItem(revItem);
        }
      }
    }
    notifyListeners();
    unawaited(_triggerBackup());

    // Log activity
    final logVideo = idx >= 0 ? sketchyPharmVideos[idx] : null;
    await _logActivity(
      itemId: 'sketchy-pharm:$id',
      itemType: 'sketchy',
      action: watched ? 'watched' : 'unwatched',
      title: logVideo != null ? 'Sketchy Pharm — ${logVideo.title}' : 'Sketchy Pharm #$id',
    );
  }

  Future<void> undoSketchyPharm(int id) async {
    await toggleSketchyPharmWatched(id, false);
    final revId = 'sketchy-pharm-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
  }

  Future<void> resetSketchyPharm(int id) async {
    final idx = sketchyPharmVideos.indexWhere((v) => v.id == id);
    final video = idx >= 0 ? sketchyPharmVideos[idx] : null;
    await toggleSketchyPharmWatched(id, false);
    final revId = 'sketchy-pharm-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
    if (video != null) {
      await _deleteTimeLogsForActivities(
        {'Sketchy: ${video.title}'},
        category: TimeLogCategory.video,
      );
    }
  }

  bool isSketchyMicroVideo(int id) {
    return sketchyMicroVideos.any((v) => v.id == id);
  }

  bool isSketchyPharmVideo(int id) {
    return sketchyPharmVideos.any((v) => v.id == id);
  }

  Future<void> toggleSketchyWatched(int id, bool watched) async {
    if (isSketchyMicroVideo(id)) {
      await toggleSketchyMicroWatched(id, watched);
      return;
    }
    if (isSketchyPharmVideo(id)) {
      await toggleSketchyPharmWatched(id, watched);
    }
  }

  Future<void> undoSketchy(int id) async {
    if (isSketchyMicroVideo(id)) {
      await undoSketchyMicro(id);
      return;
    }
    if (isSketchyPharmVideo(id)) {
      await undoSketchyPharm(id);
    }
  }

  Future<void> resetSketchy(int id) async {
    if (isSketchyMicroVideo(id)) {
      await resetSketchyMicro(id);
      return;
    }
    if (isSketchyPharmVideo(id)) {
      await resetSketchyPharm(id);
    }
  }

  Future<void> advanceSketchyRevision(int id) async {
    if (isSketchyMicroVideo(id)) {
      await advanceSketchyMicroRevision(id);
      return;
    }
    if (isSketchyPharmVideo(id)) {
      await advanceSketchyPharmRevision(id);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PATHOMA CHAPTERS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> togglePathomaChapterWatched(int id, bool watched) async {
    await _db.togglePathoma(id, watched);
    final idx = pathomaChapters.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      pathomaChapters[idx] = pathomaChapters[idx].copyWith(watched: watched);
      // Create revision item when watched
      if (watched) {
        final ch = pathomaChapters[idx];
        final revId = 'pathoma-ch-$id';
        final exists = revisionItems.any((r) => r.id == revId);
        if (!exists) {
          final mode = revisionSettings?.mode ?? 'strict';
          final now = DateTime.now().toIso8601String();
          final nextDate = SrsService.calculateNextRevisionDateString(
            lastStudiedAt: now,
            revisionIndex: 0,
            mode: mode,
          );
          final revItem = RevisionItem(
            id: revId,
            type: 'CHAPTER',
            source: 'PATHOMA',
            pageNumber: 'Ch ${ch.chapter}',
            title: ch.title,
            parentTitle: 'Pathoma Ch ${ch.chapter}',
            nextRevisionAt: nextDate ??
                DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
            currentRevisionIndex: 0,
            lastStudiedAt: now,
            totalSteps: SrsService.totalSteps(mode),
          );
          await upsertRevisionItem(revItem);
        }
      }
    }
    notifyListeners();
    unawaited(_triggerBackup());

    // Log activity
    final logChapter = idx >= 0 ? pathomaChapters[idx] : null;
    await _logActivity(
      itemId: 'pathoma:$id',
      itemType: 'pathoma',
      action: watched ? 'watched' : 'unwatched',
      title: logChapter != null ? 'Pathoma Ch${logChapter.chapter} — ${logChapter.title}' : 'Pathoma #$id',
    );
  }

  Future<void> undoPathomaChapter(int id) async {
    await togglePathomaChapterWatched(id, false);
    final revId = 'pathoma-ch-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
  }

  Future<void> resetPathomaChapter(int id) async {
    final idx = pathomaChapters.indexWhere((c) => c.id == id);
    final chapter = idx >= 0 ? pathomaChapters[idx] : null;
    await togglePathomaChapterWatched(id, false);
    final revId = 'pathoma-ch-$id';
    if (revisionItems.any((r) => r.id == revId)) {
      await deleteRevisionItem(revId);
    }
    if (chapter != null) {
      await _deleteTimeLogsForActivities(
        {'Pathoma Ch${chapter.chapter}: ${chapter.title}'},
        category: TimeLogCategory.video,
      );
    }
  }

  // ── Sketchy / Pathoma revision advance (mirrors FA page cycle) ─
  Future<void> advanceSketchyMicroRevision(int id) async {
    final idx = sketchyMicroVideos.indexWhere((v) => v.id == id);
    if (idx < 0) return;
    final video = sketchyMicroVideos[idx];
    if (!video.watched) {
      await toggleSketchyMicroWatched(id, true);
      return;
    }
    // Already watched → advance revision
    final revId = 'sketchy-micro-$id';
    final revIdx = revisionItems.indexWhere((r) => r.id == revId);
    if (revIdx >= 0) {
      final rev = revisionItems[revIdx];
      final now = DateTime.now().toIso8601String();
      final mode = revisionSettings?.mode ?? 'strict';
      final newIndex = rev.currentRevisionIndex + 1;
      if (SrsService.isMastered(revisionIndex: newIndex, mode: mode)) {
        await deleteRevisionItem(revId);
        return;
      }
      final nextDate = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: now,
        revisionIndex: newIndex,
        mode: mode,
      );
      final updated = rev.copyWith(
        currentRevisionIndex: newIndex,
        lastStudiedAt: now,
        nextRevisionAt: nextDate,
      );
      await _db.upsertRevisionItem(updated.toJson());
      revisionItems[revIdx] = updated;
      notifyListeners();
    }
  }

  Future<void> advanceSketchyPharmRevision(int id) async {
    final idx = sketchyPharmVideos.indexWhere((v) => v.id == id);
    if (idx < 0) return;
    final video = sketchyPharmVideos[idx];
    if (!video.watched) {
      await toggleSketchyPharmWatched(id, true);
      return;
    }
    final revId = 'sketchy-pharm-$id';
    final revIdx = revisionItems.indexWhere((r) => r.id == revId);
    if (revIdx >= 0) {
      final rev = revisionItems[revIdx];
      final now = DateTime.now().toIso8601String();
      final mode = revisionSettings?.mode ?? 'strict';
      final newIndex = rev.currentRevisionIndex + 1;
      final nextDate = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: now,
        revisionIndex: newIndex,
        mode: mode,
      );
      final updated = rev.copyWith(
        currentRevisionIndex: newIndex,
        lastStudiedAt: now,
        nextRevisionAt: nextDate,
      );
      await _db.upsertRevisionItem(updated.toJson());
      revisionItems[revIdx] = updated;
      notifyListeners();
    }
  }

  Future<void> advancePathomaRevision(int id) async {
    final idx = pathomaChapters.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final ch = pathomaChapters[idx];
    if (!ch.watched) {
      await togglePathomaChapterWatched(id, true);
      return;
    }
    final revId = 'pathoma-ch-$id';
    final revIdx = revisionItems.indexWhere((r) => r.id == revId);
    if (revIdx >= 0) {
      final rev = revisionItems[revIdx];
      final now = DateTime.now().toIso8601String();
      final mode = revisionSettings?.mode ?? 'strict';
      final newIndex = rev.currentRevisionIndex + 1;
      final nextDate = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: now,
        revisionIndex: newIndex,
        mode: mode,
      );
      final updated = rev.copyWith(
        currentRevisionIndex: newIndex,
        lastStudiedAt: now,
        nextRevisionAt: nextDate,
      );
      await _db.upsertRevisionItem(updated.toJson());
      revisionItems[revIdx] = updated;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UWORLD SESSIONS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> addUWorldSession(UWorldSession session) async {
    await _db.insertUWorldSession(session.toJson());
    uWorldSessions.add(session);

    // Create revision item for wrong questions
    final wrong = session.done - session.correct;
    if (wrong > 0) {
      final revId = 'uw-${session.id}';
      final exists = revisionItems.any((r) => r.id == revId);
      if (!exists) {
        final mode = revisionSettings?.mode ?? 'strict';
        final now = DateTime.now().toIso8601String();
        final nextDate = SrsService.calculateNextRevisionDateString(
          lastStudiedAt: now,
          revisionIndex: 0,
          mode: mode,
        );
        final revItem = RevisionItem(
          id: revId,
          type: 'UWORLD_Q',
          source: 'UWORLD',
          pageNumber: '',
          title: '$wrong wrong Q${wrong > 1 ? 's' : ''} — ${session.subject}',
          parentTitle: 'UWorld ${session.date}',
          nextRevisionAt: nextDate ??
              DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
          currentRevisionIndex: 0,
          lastStudiedAt: now,
          totalSteps: SrsService.totalSteps(mode),
        );
        await upsertRevisionItem(revItem);
      }
    }

    notifyListeners();
    unawaited(_triggerBackup());
  }

  Future<void> deleteUWorldSession(String id) async {
    await _db.deleteUWorldSession(id);
    uWorldSessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // UWORLD PROGRESS (G6/V4)
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadUWorldTopics() async {
    uworldTopics = await _db.getUWorldTopics();
    notifyListeners();
  }

  Future<void> addUWorldTopic(UWorldTopic topic) async {
    final insertedTopic = await _db.insertUWorldTopic(topic);
    uworldTopics.add(insertedTopic);
    notifyListeners();
  }

  Future<void> updateUWorldProgress(int id, int done, int correct) async {
    // Get topic info before update for logging
    final topicIdx = uworldTopics.indexWhere((t) => t.id == id);
    final prevDone = topicIdx >= 0 ? uworldTopics[topicIdx].doneQuestions : 0;
    final prevCorrect = topicIdx >= 0 ? uworldTopics[topicIdx].correctQuestions : 0;

    await _db.updateUWorldProgress(id, done, correct);
    await loadUWorldTopics();
    unawaited(_triggerBackup());

    // Log activity if questions were added
    final deltaDone = done - prevDone;
    final deltaCorrect = correct - prevCorrect;
    if (deltaDone > 0) {
      final topic = topicIdx >= 0 ? uworldTopics.firstWhere((t) => t.id == id, orElse: () => uworldTopics[0]) : null;
      await _logActivity(
        itemId: 'uworld:$id',
        itemType: 'uworld',
        action: 'question_done',
        title: topic != null ? 'UWorld — ${topic.subtopic}' : 'UWorld Topic #$id',
        details: '{"done":$deltaDone,"correct":$deltaCorrect,"totalDone":$done,"totalCorrect":$correct}',
      );
    }
  }

  Future<void> markUWorldTopicDone(int topicId) async {
    final topicIdx = uworldTopics.indexWhere((topic) => topic.id == topicId);
    if (topicIdx < 0) return;

    final topic = uworldTopics[topicIdx];
    await updateUWorldProgress(
      topicId,
      topic.totalQuestions,
      topic.correctQuestions > topic.totalQuestions
          ? topic.totalQuestions
          : topic.correctQuestions,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Mark a single notification as read by id.
  void markNotificationRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  /// Mark all notifications as read.
  void markAllNotificationsRead() {
    bool changed = false;
    for (final n in notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> clearHistory() async {
    await _db.deleteAllHistory();
    history.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // HABITS
  // ═══════════════════════════════════════════════════════════════

  /// Add a new habit (in-memory only for now).
  void addHabit(Habit habit) {
    habits.add(habit);
    notifyListeners();
  }

  /// Remove a habit by id.
  void removeHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  /// Toggle a habit's completion status.
  void toggleHabit(String id) {
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx >= 0) {
      habits[idx].isCompleted = !habits[idx].isCompleted;
      notifyListeners();
    }
  }

  /// Returns habits applicable to today's day of week.
  List<Habit> get todayHabits {
    final weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    return habits.where((h) {
      switch (h.frequency) {
        case HabitFrequency.daily:
          return true;
        case HabitFrequency.weekdays:
          return weekday <= 5;
        case HabitFrequency.custom:
          return h.customDays?.contains(weekday) ?? false;
      }
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // COMBINED QUERIES / GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// Returns combined activities for a specific date from
  /// dayPlans (blocks), timeLogs, and studyPlan.
  List<DateActivity> getActivitiesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final result = <DateActivity>[];

    // Blocks from day plan
    final plan = getDayPlan(dateStr);
    if (plan?.blocks != null) {
      for (final block in plan!.blocks!) {
        result.add(DateActivity(
          type: 'block',
          title: block.title,
          subtitle: '${block.plannedStartTime} – ${block.plannedEndTime}',
          durationMinutes: block.plannedDurationMinutes,
        ));
      }
    }

    // Time logs
    for (final log in timeLogs) {
      if (log.date == dateStr) {
        result.add(DateActivity(
          type: 'timeLog',
          title: log.activity,
          subtitle: log.category.value,
          durationMinutes: log.durationMinutes,
        ));
      }
    }

    // Study plan items for that date
    for (final item in studyPlan) {
      if (item.date == dateStr) {
        result.add(DateActivity(
          type: 'studyPlan',
          title: item.topic,
          subtitle: item.type,
        ));
      }
    }

    return result;
  }

  /// Returns map of subject → total hours from timeLogs.
  /// Includes only study-related categories.
  Map<String, double> getSubjectBreakdown() {
    const studyCats = {
      TimeLogCategory.study,
      TimeLogCategory.revision,
      TimeLogCategory.video,
      TimeLogCategory.qbank,
      TimeLogCategory.anki,
    };

    final map = <String, double>{};
    for (final log in timeLogs) {
      if (!studyCats.contains(log.category)) continue;
      final subject = log.activity.isNotEmpty ? log.activity : 'Other';
      map[subject] = (map[subject] ?? 0) + log.durationMinutes / 60.0;
    }
    return map;
  }

  /// Returns booleans for the last 7 days (index 0 = 6 days ago, 6 = today).
  /// `true` means the user had any time-log activity that day.
  List<bool> get recentActivity {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      return timeLogs.any((l) => l.date == dateStr);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKUP
  // ═══════════════════════════════════════════════════════════════

  /// Fire-and-forget backup after every write.
  Future<void> _triggerBackup() async {
    try {
      final data = await BackupService.buildBackupData();
      await BackupService.saveBackup(data);
    } catch (_) {
      // Backup failure should never crash the app
    }
  }

  /// Restore all backed-up domains from a decoded backup map.
  /// Clears DB, writes all data, then reloads in-memory state.
  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    // 1. Clear everything
    await _db.clearAllData();

    // 2. Let BackupService handle the actual restore of all 34 tables + prefs
    await BackupService.restoreFromBackupData(data);

    // 3. Reload all in-memory state from the freshly-restored DB
    _loaded = false;
    await loadAll();
  }

  // ═══════════════════════════════════════════════════════════════
  // FULL DATA CLEAR (for backup restore)
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearAllAndReload() async {
    await _db.clearAllData();
    knowledgeBase.clear();
    dayPlans.clear();
    studyPlan.clear();
    fmgeEntries.clear();
    timeLogs.clear();
    dailyTrackers.clear();
    studyEntries.clear();
    studyMaterials.clear();
    mentorMessages.clear();
    history.clear();
    notifications.clear();
    habits.clear();
    revisionItems.clear();
    faPages.clear();
    sketchyItems.clear();
    pathomaItems.clear();
    uWorldSessions.clear();
    sketchyMicroVideos.clear();
    sketchyPharmVideos.clear();
    pathomaChapters.clear();
    mentorMemory = null;
    aiSettings = null;
    userProfile = null;
    revisionSettings = null;
    _loaded = false;
    notifyListeners();
  }
  // ═══════════════════════════════════════════════════════════════
  // STREAK SYSTEM
  // ═══════════════════════════════════════════════════════════════

  /// Count FA pages whose firstReadAt falls on the given effective date.
  int getPagesReadOnDate(String dateKey, int dayStartHour) {
    int count = 0;
    for (final p in faPages) {
      if (p.firstReadAt == null) continue;
      final dt = DateTime.tryParse(p.firstReadAt!);
      if (dt == null) continue;
      final effKey = du.AppDateUtils.effectiveDateKey(dt, dayStartHour);
      if (effKey == dateKey) count++;
    }
    // Also count subtopics whose firstReadAt falls on this date
    for (final s in faSubtopics) {
      if (s.firstReadAt == null) continue;
      final dt = DateTime.tryParse(s.firstReadAt!);
      if (dt == null) continue;
      final effKey = du.AppDateUtils.effectiveDateKey(dt, dayStartHour);
      if (effKey == dateKey) count++;
    }
    return count;
  }

  /// Count pages read today (effective date).
  int getTodayPagesRead(int dayStartHour) {
    final todayKey =
        du.AppDateUtils.effectiveDateKey(DateTime.now(), dayStartHour);
    return getPagesReadOnDate(todayKey, dayStartHour);
  }

  /// Get the deadline DateTime for current streak (dayStart + 30h).
  /// Returns null if streak is already validated for today.
  DateTime? getStreakDeadline(int dayStartHour) {
    final now = DateTime.now();
    final todayKey = du.AppDateUtils.effectiveDateKey(now, dayStartHour);
    if (streakData.lastStreakDate == todayKey) return null; // already validated
    final todayDate = du.AppDateUtils.effectiveDate(now, dayStartHour);
    // Deadline: day start + 30 hours
    return DateTime(
            todayDate.year, todayDate.month, todayDate.day, dayStartHour)
        .add(const Duration(hours: 30));
  }

  /// Compute and update streak based on FA pages read vs daily target.
  /// Returns a status string: 'earned', 'at_risk', 'grace', 'broken', 'redeemed'.
  Future<String> computeStreak(int dayStartHour, int dailyGoal) async {
    final now = DateTime.now();
    final todayKey = du.AppDateUtils.effectiveDateKey(now, dayStartHour);

    // If already validated today, skip
    if (streakData.lastStreakDate == todayKey) return 'earned';

    final todayRead = getTodayPagesRead(dayStartHour);

    if (todayRead >= dailyGoal) {
      // Target met! Check if credits were used today
      final usedCreditsToday = streakData.creditUsedDates.contains(todayKey);
      final earnedCredits = usedCreditsToday ? 0 : todayRead;

      streakData.currentStreak++;
      streakData.creditBalance += earnedCredits;
      streakData.lastStreakDate = todayKey;
      if (streakData.currentStreak > streakData.longestStreak) {
        streakData.longestStreak = streakData.currentStreak;
      }
      await _persistStreak();
      return 'earned';
    }

    // Not yet met — check if within 30h window
    final deadline = getStreakDeadline(dayStartHour);
    if (deadline != null && now.isBefore(deadline)) {
      // Still within window
      final todayDate = du.AppDateUtils.effectiveDate(now, dayStartHour);
      final dayEnd =
          DateTime(todayDate.year, todayDate.month, todayDate.day, dayStartHour)
              .add(const Duration(hours: 24));
      if (now.isBefore(dayEnd)) {
        return 'at_risk'; // Within 24h
      }
      return 'grace'; // In 6h grace period
    }

    // Past 30h window — streak is broken unless credits cover it
    return 'broken';
  }

  /// Redeem credits to save the streak for a missed day.
  /// Returns true if successful, false if insufficient credits.
  Future<bool> redeemCreditsForStreak(int dayStartHour, int dailyGoal) async {
    final todayKey =
        du.AppDateUtils.effectiveDateKey(DateTime.now(), dayStartHour);
    final todayRead = getTodayPagesRead(dayStartHour);
    final missedPages = dailyGoal - todayRead;
    if (missedPages <= 0) return true; // Target already met

    final cost = missedPages * 5;
    if (streakData.creditBalance < cost) return false; // Not enough credits

    streakData.creditBalance -= cost;
    streakData.currentStreak++;
    streakData.lastStreakDate = todayKey;
    streakData.creditUsedDates = [...streakData.creditUsedDates, todayKey];
    if (streakData.currentStreak > streakData.longestStreak) {
      streakData.longestStreak = streakData.currentStreak;
    }
    await _persistStreak();
    return true;
  }

  /// Break the streak (user chose not to redeem or insufficient credits).
  Future<void> breakStreak() async {
    streakData.currentStreak = 0;
    await _persistStreak();
  }

  Future<void> _persistStreak() async {
    await _db.saveStreakData(streakData.toJson());
    notifyListeners();
    unawaited(_triggerBackup());
  }

  // ═════════════════════════════════════════════════════════════════
  // LIBRARY NOTES
  // ═════════════════════════════════════════════════════════════════

  Future<List<LibraryNote>> getLibraryNotes(String itemId) async {
    final docs = await DatabaseService.instance.getLibraryNotes(itemId);
    return docs.map((doc) => LibraryNote.fromJson(doc)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveLibraryNote(LibraryNote note) async {
    await DatabaseService.instance.upsertLibraryNote(note.toJson());
    notifyListeners();
  }

  Future<void> deleteLibraryNote(String id) async {
    await DatabaseService.instance.deleteLibraryNote(id);
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════
  // LIBRARY ITEM METADATA
  // ═════════════════════════════════════════════════════════════════

  Future<void> updateFAPageMetadata(FAPage updatedPage) async {
    final i = faPages.indexWhere((p) => p.pageNum == updatedPage.pageNum);
    if (i == -1) return;
    faPages[i] = updatedPage;
    await _db.updateFAPage(updatedPage.toJson());
    notifyListeners();
  }

  Future<void> updateSketchyMetadata(SketchyItem updatedItem) async {
    final microIndex = sketchyMicroVideos
        .indexWhere((v) => v.id?.toString() == updatedItem.id);
    if (microIndex != -1) {
      sketchyMicroVideos[microIndex] = updatedItem as SketchyVideo;
      await _db.updateSketchyMicroVideo(updatedItem.toJson());
    } else {
      final pharmIndex = sketchyPharmVideos
          .indexWhere((v) => v.id?.toString() == updatedItem.id);
      if (pharmIndex != -1) {
        sketchyPharmVideos[pharmIndex] = updatedItem as SketchyVideo;
        await _db.updateSketchyPharmVideo(updatedItem.toJson());
      }
    }
    notifyListeners();
  }

  Future<void> updatePathomaMetadata(PathomaItem updatedItem) async {
    final i =
        pathomaChapters.indexWhere((c) => c.id?.toString() == updatedItem.id);
    if (i == -1) return;
    pathomaChapters[i] = updatedItem as PathomaChapter;
    await _db.updatePathomaChapter(updatedItem.toJson());
    notifyListeners();
  }

  Future<void> updateUWorldMetadata(UWorldTopic updatedTopic) async {
    final i = uworldTopics.indexWhere((t) => t.id == updatedTopic.id);
    if (i == -1) return;
    uworldTopics[i] = updatedTopic;
    if (updatedTopic.id != null) {
      await _db.updateUWorldTopic(updatedTopic.toMap());
    }
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════
  // ACTIVITY LOGS
  // ═════════════════════════════════════════════════════════════════

  /// Internal helper to log an activity.
  Future<void> _logActivity({
    required String itemId,
    required String itemType,
    required String action,
    String title = '',
    String details = '{}',
  }) async {
    final entry = ActivityLogEntry(
      itemId: itemId,
      itemType: itemType,
      action: action,
      timestamp: DateTime.now().toIso8601String(),
      title: title,
      details: details,
    );
    await _db.insertActivityLog(entry);
  }

  /// Get activity logs for a specific item.
  Future<List<ActivityLogEntry>> getActivityLogs(String itemId) async {
    return _db.getActivityLogsByItem(itemId);
  }

  /// Get all activity logs, optionally limited.
  Future<List<ActivityLogEntry>> getAllActivityLogs({int? limit}) async {
    return _db.getAllActivityLogs(limit: limit);
  }

  /// Get activity logs by item type.
  Future<List<ActivityLogEntry>> getActivityLogsByType(String itemType) async {
    return _db.getActivityLogsByType(itemType);
  }

  /// Get activity logs since a specific date.
  Future<List<ActivityLogEntry>> getActivityLogsSince(DateTime since) async {
    return _db.getActivityLogsSince(since.toIso8601String());
  }
}
