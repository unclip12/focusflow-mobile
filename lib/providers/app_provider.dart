// =============================================================
// AppProvider — Central state, loads ALL data from SQLite
// One ChangeNotifier holding lists for every data domain.
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/services/database_service.dart';

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

class AppProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  bool _loaded = false;
  bool get loaded => _loaded;

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

    // Singletons
    final memJson = await _db.getMentorMemory();
    mentorMemory = memJson != null ? MentorMemory.fromJson(memJson) : null;

    final aiJson = await _db.getAISettings();
    aiSettings = aiJson != null ? AISettings.fromJson(aiJson) : null;

    final upJson = await _db.getUserProfile();
    userProfile = upJson != null ? UserProfile.fromJson(upJson) : null;

    final rsJson = await _db.getRevisionSettings();
    revisionSettings = rsJson != null ? RevisionSettings.fromJson(rsJson) : null;

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

  Future<void> clearHistory() async {
    await _db.deleteAllHistory();
    history.clear();
    notifyListeners();
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
    mentorMemory = null;
    aiSettings = null;
    userProfile = null;
    revisionSettings = null;
    _loaded = false;
    notifyListeners();
  }
}
