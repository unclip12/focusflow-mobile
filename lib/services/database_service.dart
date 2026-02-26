// =============================================================
// DatabaseService — SQLite CRUD for all FocusFlow data
// JSON blob storage: each table has a primary key + data TEXT
// KB table uses pageNumber TEXT PRIMARY KEY (not id)
// =============================================================

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _dbName = 'focusflow.db';
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Table names ──────────────────────────────────────────────
  static const tKnowledgeBase = 'knowledge_base';
  static const tDayPlans = 'day_plans';
  static const tStudyPlan = 'study_plan';
  static const tFmgeEntries = 'fmge_entries';
  static const tTimeLogs = 'time_logs';
  static const tDailyTracker = 'daily_tracker';
  static const tStudyEntries = 'study_entries';
  static const tStudyMaterials = 'study_materials';
  static const tMentorMessages = 'mentor_messages';
  static const tMentorMemory = 'mentor_memory';
  static const tAiSettings = 'ai_settings';
  static const tUserProfile = 'user_profile';
  static const tSettings = 'settings';
  static const tHistory = 'history';
  static const tRevisionSettings = 'revision_settings';
  static const tRevisionItems = 'revision_items';
  static const tFaPages = 'fa_pages';
  static const tSketchyItems = 'sketchy_items';
  static const tPathomaItems = 'pathoma_items';
  static const tUworldSessions = 'uworld_sessions';
  static const tSketchyMicroVideos = 'sketchy_micro_videos';
  static const tSketchyPharmVideos = 'sketchy_pharm_videos';
  static const tPathomaChapters = 'pathoma_chapters';

  Future<void> _onCreate(Database db, int version) async {
    // Knowledge Base — pageNumber is the primary key
    await db.execute('''
      CREATE TABLE $tKnowledgeBase (
        pageNumber TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        subject TEXT,
        system TEXT
      )
    ''');

    // Day Plans — indexed by date
    await db.execute('''
      CREATE TABLE $tDayPlans (
        date TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');

    // Study Plan items
    await db.execute('''
      CREATE TABLE $tStudyPlan (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        date TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_study_plan_date ON $tStudyPlan(date)');

    // FMGE Entries
    await db.execute('''
      CREATE TABLE $tFmgeEntries (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        subject TEXT
      )
    ''');

    // Time Logs — indexed by date
    await db.execute('''
      CREATE TABLE $tTimeLogs (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        date TEXT,
        category TEXT,
        source TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_time_logs_date ON $tTimeLogs(date)');

    // Daily Tracker — keyed by date
    await db.execute('''
      CREATE TABLE $tDailyTracker (
        date TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');

    // Study Entries — indexed by date
    await db.execute('''
      CREATE TABLE $tStudyEntries (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        date TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_study_entries_date ON $tStudyEntries(date)');

    // Study Materials
    await db.execute('''
      CREATE TABLE $tStudyMaterials (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        source TEXT
      )
    ''');

    // Mentor Messages
    await db.execute('''
      CREATE TABLE $tMentorMessages (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_mentor_msgs_ts ON $tMentorMessages(timestamp)');

    // Mentor Memory — singleton row
    await db.execute('''
      CREATE TABLE $tMentorMemory (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        data TEXT NOT NULL
      )
    ''');

    // AI Settings — singleton row
    await db.execute('''
      CREATE TABLE $tAiSettings (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        data TEXT NOT NULL
      )
    ''');

    // User Profile — singleton row
    await db.execute('''
      CREATE TABLE $tUserProfile (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        data TEXT NOT NULL
      )
    ''');

    // App Settings — singleton row
    await db.execute('''
      CREATE TABLE $tSettings (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        data TEXT NOT NULL
      )
    ''');

    // History records
    await db.execute('''
      CREATE TABLE $tHistory (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp TEXT,
        type TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_history_ts ON $tHistory(timestamp)');

    // Revision Settings — singleton row
    await db.execute('''
      CREATE TABLE $tRevisionSettings (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        data TEXT NOT NULL
      )
    ''');

    // Revision Items — scheduled revision entries
    await db.execute('''
      CREATE TABLE $tRevisionItems (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        pageNumber TEXT
      )
    ''');

    // ── G5 Tracker tables ──────────────────────────────────────
    await _createG5Tables(db);

    // ── G6 Tracker tables (Sketchy Micro/Pharm, Pathoma) ──────
    await _createG6Tables(db);
  }

  /// Create G5 tracker tables — called from both _onCreate and _onUpgrade.
  Future<void> _createG5Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tFaPages (
        pageNum INTEGER PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tSketchyItems (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tPathomaItems (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tUworldSessions (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
  }

  /// Create G6 tracker tables — Sketchy Micro/Pharm videos + Pathoma chapters.
  Future<void> _createG6Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tSketchyMicroVideos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        subcategory TEXT NOT NULL,
        title TEXT NOT NULL,
        watched INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tSketchyPharmVideos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        subcategory TEXT NOT NULL,
        title TEXT NOT NULL,
        watched INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tPathomaChapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter INTEGER NOT NULL,
        title TEXT NOT NULL,
        watched INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createG5Tables(db);
    }
    if (oldVersion < 3) {
      await _createG6Tables(db);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERIC CRUD HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Upsert a row by primary key.
  Future<void> upsert(
    String table,
    String primaryKey,
    String primaryKeyValue,
    Map<String, dynamic> json, {
    Map<String, dynamic>? indexColumns,
  }) async {
    final db = await database;
    final row = <String, dynamic>{
      primaryKey: primaryKeyValue,
      'data': jsonEncode(json),
    };
    if (indexColumns != null) row.addAll(indexColumns);
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a single row by primary key, decoded from JSON.
  Future<Map<String, dynamic>?> getById(
    String table,
    String primaryKey,
    String primaryKeyValue,
  ) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: '$primaryKey = ?',
      whereArgs: [primaryKeyValue],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  /// Get all rows from a table, decoded from JSON.
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    final rows = await db.query(table);
    return rows
        .map((r) =>
            jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Query rows where an index column matches a value.
  Future<List<Map<String, dynamic>>> getWhere(
    String table,
    String column,
    dynamic value,
  ) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: '$column = ?',
      whereArgs: [value],
    );
    return rows
        .map((r) =>
            jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Delete a row by primary key.
  Future<int> deleteById(
    String table,
    String primaryKey,
    String primaryKeyValue,
  ) async {
    final db = await database;
    return db.delete(table, where: '$primaryKey = ?', whereArgs: [primaryKeyValue]);
  }

  /// Delete all rows from a table.
  Future<int> deleteAll(String table) async {
    final db = await database;
    return db.delete(table);
  }

  /// Count rows in a table.
  Future<int> count(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // KNOWLEDGE BASE — pageNumber is primary key
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertKBEntry(Map<String, dynamic> json) => upsert(
        tKnowledgeBase,
        'pageNumber',
        json['pageNumber']?.toString() ?? '',
        json,
        indexColumns: {
          'subject': json['subject'],
          'system': json['system'],
        },
      );

  Future<Map<String, dynamic>?> getKBEntry(String pageNumber) =>
      getById(tKnowledgeBase, 'pageNumber', pageNumber);

  Future<List<Map<String, dynamic>>> getAllKBEntries() =>
      getAll(tKnowledgeBase);

  Future<int> deleteKBEntry(String pageNumber) =>
      deleteById(tKnowledgeBase, 'pageNumber', pageNumber);

  // ═══════════════════════════════════════════════════════════════
  // DAY PLANS — date is primary key
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertDayPlan(Map<String, dynamic> json) =>
      upsert(tDayPlans, 'date', json['date'] ?? '', json);

  Future<Map<String, dynamic>?> getDayPlan(String date) =>
      getById(tDayPlans, 'date', date);

  Future<List<Map<String, dynamic>>> getAllDayPlans() =>
      getAll(tDayPlans);

  Future<int> deleteDayPlan(String date) =>
      deleteById(tDayPlans, 'date', date);

  // ═══════════════════════════════════════════════════════════════
  // STUDY PLAN
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyPlanItem(Map<String, dynamic> json) => upsert(
        tStudyPlan, 'id', json['id'] ?? '', json,
        indexColumns: {'date': json['date']},
      );

  Future<List<Map<String, dynamic>>> getStudyPlanByDate(String date) =>
      getWhere(tStudyPlan, 'date', date);

  Future<List<Map<String, dynamic>>> getAllStudyPlanItems() =>
      getAll(tStudyPlan);

  Future<int> deleteStudyPlanItem(String id) =>
      deleteById(tStudyPlan, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // FMGE ENTRIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertFMGEEntry(Map<String, dynamic> json) => upsert(
        tFmgeEntries, 'id', json['id'] ?? '', json,
        indexColumns: {'subject': json['subject']},
      );

  Future<List<Map<String, dynamic>>> getFMGEBySubject(String subject) =>
      getWhere(tFmgeEntries, 'subject', subject);

  Future<List<Map<String, dynamic>>> getAllFMGEEntries() =>
      getAll(tFmgeEntries);

  Future<int> deleteFMGEEntry(String id) =>
      deleteById(tFmgeEntries, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // TIME LOGS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertTimeLog(Map<String, dynamic> json) => upsert(
        tTimeLogs, 'id', json['id'] ?? '', json,
        indexColumns: {
          'date': json['date'],
          'category': json['category'],
          'source': json['source'],
        },
      );

  Future<List<Map<String, dynamic>>> getTimeLogsByDate(String date) =>
      getWhere(tTimeLogs, 'date', date);

  Future<List<Map<String, dynamic>>> getAllTimeLogs() =>
      getAll(tTimeLogs);

  Future<int> deleteTimeLog(String id) =>
      deleteById(tTimeLogs, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // DAILY TRACKER — date is primary key
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertDailyTracker(Map<String, dynamic> json) =>
      upsert(tDailyTracker, 'date', json['date'] ?? '', json);

  Future<Map<String, dynamic>?> getDailyTracker(String date) =>
      getById(tDailyTracker, 'date', date);

  Future<List<Map<String, dynamic>>> getAllDailyTrackers() =>
      getAll(tDailyTracker);

  Future<int> deleteDailyTracker(String date) =>
      deleteById(tDailyTracker, 'date', date);

  // ═══════════════════════════════════════════════════════════════
  // STUDY ENTRIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyEntry(Map<String, dynamic> json) => upsert(
        tStudyEntries, 'id', json['id'] ?? '', json,
        indexColumns: {'date': json['date']},
      );

  Future<List<Map<String, dynamic>>> getStudyEntriesByDate(String date) =>
      getWhere(tStudyEntries, 'date', date);

  Future<List<Map<String, dynamic>>> getAllStudyEntries() =>
      getAll(tStudyEntries);

  Future<int> deleteStudyEntry(String id) =>
      deleteById(tStudyEntries, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // STUDY MATERIALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertStudyMaterial(Map<String, dynamic> json) => upsert(
        tStudyMaterials, 'id', json['id'] ?? '', json,
        indexColumns: {'source': json['source']},
      );

  Future<List<Map<String, dynamic>>> getAllStudyMaterials() =>
      getAll(tStudyMaterials);

  Future<int> deleteStudyMaterial(String id) =>
      deleteById(tStudyMaterials, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // MENTOR MESSAGES
  // ═══════════════════════════════════════════════════════════════

  Future<void> insertMentorMessage(Map<String, dynamic> json) => upsert(
        tMentorMessages, 'id', json['id'] ?? '', json,
        indexColumns: {'timestamp': json['timestamp']},
      );

  Future<List<Map<String, dynamic>>> getAllMentorMessages() async {
    final db = await database;
    final rows =
        await db.query(tMentorMessages, orderBy: 'timestamp ASC');
    return rows
        .map((r) =>
            jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<int> deleteMentorMessage(String id) =>
      deleteById(tMentorMessages, 'id', id);

  Future<int> deleteAllMentorMessages() => deleteAll(tMentorMessages);

  // ═══════════════════════════════════════════════════════════════
  // SINGLETONS: MentorMemory, AISettings, UserProfile, Settings
  // ═══════════════════════════════════════════════════════════════

  Future<void> _upsertSingleton(String table, Map<String, dynamic> json) =>
      upsert(table, 'id', 'singleton', json);

  Future<Map<String, dynamic>?> _getSingleton(String table) =>
      getById(table, 'id', 'singleton');

  // Mentor Memory
  Future<void> saveMentorMemory(Map<String, dynamic> json) =>
      _upsertSingleton(tMentorMemory, json);
  Future<Map<String, dynamic>?> getMentorMemory() =>
      _getSingleton(tMentorMemory);

  // AI Settings
  Future<void> saveAISettings(Map<String, dynamic> json) =>
      _upsertSingleton(tAiSettings, json);
  Future<Map<String, dynamic>?> getAISettings() =>
      _getSingleton(tAiSettings);

  // User Profile
  Future<void> saveUserProfile(Map<String, dynamic> json) =>
      _upsertSingleton(tUserProfile, json);
  Future<Map<String, dynamic>?> getUserProfile() =>
      _getSingleton(tUserProfile);

  // App Settings
  Future<void> saveSettings(Map<String, dynamic> json) =>
      _upsertSingleton(tSettings, json);
  Future<Map<String, dynamic>?> getSettings() =>
      _getSingleton(tSettings);

  // Revision Settings
  Future<void> saveRevisionSettings(Map<String, dynamic> json) =>
      _upsertSingleton(tRevisionSettings, json);
  Future<Map<String, dynamic>?> getRevisionSettings() =>
      _getSingleton(tRevisionSettings);

  // ═══════════════════════════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════════════════════════

  Future<void> insertHistoryRecord(Map<String, dynamic> json) => upsert(
        tHistory, 'id', json['id'] ?? '', json,
        indexColumns: {
          'timestamp': json['timestamp'],
          'type': json['type'],
        },
      );

  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await database;
    final rows = await db.query(tHistory, orderBy: 'timestamp DESC');
    return rows
        .map((r) =>
            jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<int> deleteHistoryRecord(String id) =>
      deleteById(tHistory, 'id', id);

  Future<int> deleteAllHistory() => deleteAll(tHistory);

  // ═══════════════════════════════════════════════════════════════
  // REVISION ITEMS
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertRevisionItem(Map<String, dynamic> json) => upsert(
        tRevisionItems, 'id', json['id'] ?? '', json,
        indexColumns: {'pageNumber': json['pageNumber']},
      );

  Future<List<Map<String, dynamic>>> getAllRevisionItems() =>
      getAll(tRevisionItems);

  Future<int> deleteRevisionItem(String id) =>
      deleteById(tRevisionItems, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // FA PAGES (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllFAPages() => getAll(tFaPages);

  Future<void> upsertFAPage(Map<String, dynamic> json) => upsert(
        tFaPages, 'pageNum', json['pageNum']?.toString() ?? '', json,
      );

  Future<int> deleteFAPage(int pageNum) =>
      deleteById(tFaPages, 'pageNum', pageNum.toString());

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY ITEMS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllSketchyItems() =>
      getAll(tSketchyItems);

  Future<void> upsertSketchyItem(Map<String, dynamic> json) => upsert(
        tSketchyItems, 'id', json['id'] ?? '', json,
      );

  Future<int> deleteSketchyItem(String id) =>
      deleteById(tSketchyItems, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // PATHOMA ITEMS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllPathomaItems() =>
      getAll(tPathomaItems);

  Future<void> upsertPathomaItem(Map<String, dynamic> json) => upsert(
        tPathomaItems, 'id', json['id'] ?? '', json,
      );

  Future<int> deletePathomaItem(String id) =>
      deleteById(tPathomaItems, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // UWORLD SESSIONS (G5)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllUWorldSessions() =>
      getAll(tUworldSessions);

  Future<void> insertUWorldSession(Map<String, dynamic> json) => upsert(
        tUworldSessions, 'id', json['id'] ?? '', json,
      );

  Future<int> deleteUWorldSession(String id) =>
      deleteById(tUworldSessions, 'id', id);

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY MICRO VIDEOS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> seedSketchyMicro(List<SketchyVideo> videos) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tSketchyMicroVideos'),
    );
    if (count != null && count > 0) return;
    final batch = db.batch();
    for (final v in videos) {
      batch.insert(tSketchyMicroVideos, v.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<List<SketchyVideo>> getSketchyMicroVideos() async {
    final db = await database;
    final rows = await db.query(tSketchyMicroVideos, orderBy: 'id ASC');
    return rows.map(SketchyVideo.fromMap).toList();
  }

  Future<void> toggleSketchyMicro(int id, bool watched) async {
    final db = await database;
    await db.update(tSketchyMicroVideos, {'watched': watched ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════
  // SKETCHY PHARM VIDEOS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> seedSketchyPharm(List<SketchyVideo> videos) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tSketchyPharmVideos'),
    );
    if (count != null && count > 0) return;
    final batch = db.batch();
    for (final v in videos) {
      batch.insert(tSketchyPharmVideos, v.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<List<SketchyVideo>> getSketchyPharmVideos() async {
    final db = await database;
    final rows = await db.query(tSketchyPharmVideos, orderBy: 'id ASC');
    return rows.map(SketchyVideo.fromMap).toList();
  }

  Future<void> toggleSketchyPharm(int id, bool watched) async {
    final db = await database;
    await db.update(tSketchyPharmVideos, {'watched': watched ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════
  // PATHOMA CHAPTERS (G6)
  // ═══════════════════════════════════════════════════════════════

  Future<void> seedPathoma(List<PathomaChapter> chapters) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tPathomaChapters'),
    );
    if (count != null && count > 0) return;
    final batch = db.batch();
    for (final c in chapters) {
      batch.insert(tPathomaChapters, c.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<List<PathomaChapter>> getPathomaChapters() async {
    final db = await database;
    final rows = await db.query(tPathomaChapters, orderBy: 'chapter ASC');
    return rows.map(PathomaChapter.fromMap).toList();
  }

  Future<void> togglePathoma(int id, bool watched) async {
    final db = await database;
    await db.update(tPathomaChapters, {'watched': watched ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════
  // BULK OPERATIONS (for backup restore)
  // ═══════════════════════════════════════════════════════════════

  /// Clear ALL tables — used before a full restore.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        tKnowledgeBase, tDayPlans, tStudyPlan, tFmgeEntries,
        tTimeLogs, tDailyTracker, tStudyEntries, tStudyMaterials,
        tMentorMessages, tMentorMemory, tAiSettings, tUserProfile,
        tSettings, tHistory, tRevisionSettings, tRevisionItems,
        tFaPages, tSketchyItems, tPathomaItems, tUworldSessions,
        tSketchyMicroVideos, tSketchyPharmVideos, tPathomaChapters,
      ]) {
        await txn.delete(table);
      }
    });
  }

  /// Close the database (e.g. on app dispose).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
