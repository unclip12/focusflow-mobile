// =============================================================
// AppProvider — Central state, loads ALL data from SQLite
// One ChangeNotifier holding lists for every data domain.
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
import 'package:focusflow_mobile/models/sketchy_item.dart';
import 'package:focusflow_mobile/models/pathoma_item.dart';
import 'package:focusflow_mobile/models/uworld_session.dart';
import 'package:focusflow_mobile/utils/constants.dart';

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

  MentorMemory? mentorMemory;
  AISettings? aiSettings;
  UserProfile? userProfile;
  RevisionSettings? revisionSettings;

  // ── Initial load ──────────────────────────────────────────────
  Future<void> loadAll() async {
    knowledgeBase = (await _db.getAllKBEntries())
        .map((j) => KnowledgeBaseEntry.fromJson(j))
        .toList();

    dayPlans = (await _db.getAllDayPlans())
        .map((j) => DayPlan.fromJson(j))
        .toList();

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

    faPages = (await _db.getAllFAPages())
        .map((j) => FAPage.fromJson(j))
        .toList();
    sketchyItems = (await _db.getAllSketchyItems())
        .map((j) => SketchyItem.fromJson(j))
        .toList();
    pathomaItems = (await _db.getAllPathomaItems())
        .map((j) => PathomaItem.fromJson(j))
        .toList();
    uWorldSessions = (await _db.getAllUWorldSessions())
        .map((j) => UWorldSession.fromJson(j))
        .toList();

    // Singletons
    final memJson = await _db.getMentorMemory();
    mentorMemory = memJson != null ? MentorMemory.fromJson(memJson) : null;

    final aiJson = await _db.getAISettings();
    aiSettings = aiJson != null ? AISettings.fromJson(aiJson) : null;

    final upJson = await _db.getUserProfile();
    userProfile = upJson != null ? UserProfile.fromJson(upJson) : null;

    final rsJson = await _db.getRevisionSettings();
    revisionSettings = rsJson != null ? RevisionSettings.fromJson(rsJson) : null;

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
      Habit(id: 'h1', name: 'Morning Revision', frequency: HabitFrequency.daily, color: const Color(0xFF6366F1)),
      Habit(id: 'h2', name: 'Read First Aid', frequency: HabitFrequency.daily, color: const Color(0xFF10B981)),
      Habit(id: 'h3', name: 'QBank Practice', frequency: HabitFrequency.weekdays, color: const Color(0xFFEC4899)),
      Habit(id: 'h4', name: 'Anki Review', frequency: HabitFrequency.daily, color: const Color(0xFFF59E0B)),
    ];

    _loaded = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // KNOWLEDGE BASE
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertKBEntry(KnowledgeBaseEntry entry) async {
    await _db.upsertKBEntry(entry.toJson());
    final idx = knowledgeBase.indexWhere((e) => e.pageNumber == entry.pageNumber);
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
    try { return dayPlans.firstWhere((p) => p.date == date); }
    catch (_) { return null; }
  }

  Future<void> upsertDayPlan(DayPlan plan) async {
    await _db.upsertDayPlan(plan.toJson());
    final idx = dayPlans.indexWhere((p) => p.date == plan.date);
    if (idx >= 0) { dayPlans[idx] = plan; } else { dayPlans.add(plan); }
    notifyListeners();
  }

  Future<void> deleteDayPlan(String date) async {
    await _db.deleteDayPlan(date);
    dayPlans.removeWhere((p) => p.date == date);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY PLAN
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyPlanItem(StudyPlanItem item) async {
    await _db.upsertStudyPlanItem(item.toJson());
    final idx = studyPlan.indexWhere((i) => i.id == item.id);
    if (idx >= 0) { studyPlan[idx] = item; } else { studyPlan.add(item); }
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
    if (idx >= 0) { fmgeEntries[idx] = entry; } else { fmgeEntries.add(entry); }
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
    if (idx >= 0) { timeLogs[idx] = entry; } else { timeLogs.add(entry); }
    notifyListeners();
  }

  Future<void> deleteTimeLog(String id) async {
    await _db.deleteTimeLog(id);
    timeLogs.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY TRACKER
  // ═══════════════════════════════════════════════════════════════

  DailyTracker? getDailyTracker(String date) {
    try { return dailyTrackers.firstWhere((t) => t.date == date); }
    catch (_) { return null; }
  }

  Future<void> upsertDailyTracker(DailyTracker tracker) async {
    await _db.upsertDailyTracker(tracker.toJson());
    final idx = dailyTrackers.indexWhere((t) => t.date == tracker.date);
    if (idx >= 0) { dailyTrackers[idx] = tracker; } else { dailyTrackers.add(tracker); }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY ENTRIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyEntry(StudyEntry entry) async {
    await _db.upsertStudyEntry(entry.toJson());
    final idx = studyEntries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) { studyEntries[idx] = entry; } else { studyEntries.add(entry); }
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
    if (idx >= 0) { studyMaterials[idx] = material; } else { studyMaterials.add(material); }
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
      id:        _uuid.v4(),
      role:      'user',
      text:      text,
      timestamp: DateTime.now().toIso8601String(),
    );
    await addMentorMessage(userMsg);

    // 2. Mock mentor reply after delay
    await Future.delayed(const Duration(milliseconds: 800));
    final reply = _kMentorAutoReplies[_mentorReplyIdx % _kMentorAutoReplies.length];
    _mentorReplyIdx++;

    final mentorMsg = MentorMessage(
      id:        _uuid.v4(),
      role:      'model',
      text:      reply,
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
  Future<void> updateUserProfile(UserProfile profile) => saveUserProfile(profile);

  Future<void> saveRevisionSettings(RevisionSettings s) async {
    revisionSettings = s;
    await _db.saveRevisionSettings(s.toJson());
    notifyListeners();
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
    if (idx >= 0) { revisionItems[idx] = item; } else { revisionItems.add(item); }
    notifyListeners();
  }

  Future<void> deleteRevisionItem(String id) async {
    await _db.deleteRevisionItem(id);
    revisionItems.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FA PAGES (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertFAPage(FAPage page) async {
    await _db.upsertFAPage(page.toJson());
    final idx = faPages.indexWhere((p) => p.pageNum == page.pageNum);
    if (idx >= 0) { faPages[idx] = page; } else { faPages.add(page); }
    notifyListeners();
  }

  Future<void> updateFAPageStatus(int pageNum, String status) async {
    final idx = faPages.indexWhere((p) => p.pageNum == pageNum);
    if (idx < 0) return;
    final updated = faPages[idx].copyWith(
      status: status,
      lastReviewed: DateTime.now().toIso8601String(),
    );
    await upsertFAPage(updated);
  }

  /// Bulk-update FA pages in range [from..to] to the given status.
  /// Returns the count of pages actually updated.
  Future<int> bulkMarkFAPages(int from, int to, String status) async {
    int count = 0;
    final now = DateTime.now().toIso8601String();
    for (int i = 0; i < faPages.length; i++) {
      final p = faPages[i];
      if (p.pageNum >= from && p.pageNum <= to && p.status != status) {
        final updated = p.copyWith(status: status, lastReviewed: now);
        await _db.upsertFAPage(updated.toJson());
        faPages[i] = updated;
        count++;
      }
    }
    if (count > 0) notifyListeners();
    return count;
  }

  Future<void> deleteFAPage(int pageNum) async {
    await _db.deleteFAPage(pageNum);
    faPages.removeWhere((p) => p.pageNum == pageNum);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY ITEMS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertSketchyItem(SketchyItem item) async {
    await _db.upsertSketchyItem(item.toJson());
    final idx = sketchyItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) { sketchyItems[idx] = item; } else { sketchyItems.add(item); }
    notifyListeners();
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
    if (idx >= 0) { pathomaItems[idx] = item; } else { pathomaItems.add(item); }
    notifyListeners();
  }

  Future<void> updatePathomaStatus(String id, String status) async {
    final idx = pathomaItems.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    await upsertPathomaItem(pathomaItems[idx].copyWith(status: status));
  }

  // ═══════════════════════════════════════════════════════════════
  // UWORLD SESSIONS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<void> addUWorldSession(UWorldSession session) async {
    await _db.insertUWorldSession(session.toJson());
    uWorldSessions.add(session);
    notifyListeners();
  }

  Future<void> deleteUWorldSession(String id) async {
    await _db.deleteUWorldSession(id);
    uWorldSessions.removeWhere((s) => s.id == id);
    notifyListeners();
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
      if (!n.isRead) { n.isRead = true; changed = true; }
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
          type:            'block',
          title:           block.title,
          subtitle:        '${block.plannedStartTime} – ${block.plannedEndTime}',
          durationMinutes: block.plannedDurationMinutes,
        ));
      }
    }

    // Time logs
    for (final log in timeLogs) {
      if (log.date == dateStr) {
        result.add(DateActivity(
          type:            'timeLog',
          title:           log.activity,
          subtitle:        log.category.value,
          durationMinutes: log.durationMinutes,
        ));
      }
    }

    // Study plan items for that date
    for (final item in studyPlan) {
      if (item.date == dateStr) {
        result.add(DateActivity(
          type:     'studyPlan',
          title:    item.topic,
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
    mentorMemory = null;
    aiSettings = null;
    userProfile = null;
    revisionSettings = null;
    _loaded = false;
    notifyListeners();
  }
}

