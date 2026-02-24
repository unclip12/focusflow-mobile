// =============================================================
// FocusFlow Constants
// Mirrors enums + constants from the web app's types.ts
// =============================================================

// ── Menu Item IDs (15 screens) ────────────────────────────────
class MenuItemId {
  static const String dashboard     = 'DASHBOARD';
  static const String studyTracker  = 'STUDY_TRACKER';
  static const String todaysPlan    = 'TODAYS_PLAN';
  static const String focusTimer    = 'FOCUS_TIMER';
  static const String calendar      = 'CALENDAR';
  static const String timeLogger    = 'TIME_LOGGER';
  static const String fmge          = 'FMGE';
  static const String dailyTracker  = 'DAILY_TRACKER';
  static const String faLogger      = 'FA_LOGGER';
  static const String revision      = 'REVISION';
  static const String knowledgeBase = 'KNOWLEDGE_BASE';
  static const String data          = 'DATA';
  static const String chat          = 'CHAT';
  static const String aiMemory      = 'AI_MEMORY';
  static const String analytics     = 'ANALYTICS';
  static const String settings      = 'SETTINGS';
}

const List<String> kDefaultMenuOrder = [
  MenuItemId.dashboard,
  MenuItemId.todaysPlan,
  MenuItemId.faLogger,
  MenuItemId.revision,
  MenuItemId.knowledgeBase,
  MenuItemId.focusTimer,
  MenuItemId.studyTracker,
  MenuItemId.calendar,
  MenuItemId.timeLogger,
  MenuItemId.fmge,
  MenuItemId.dailyTracker,
  MenuItemId.analytics,
  MenuItemId.data,
  MenuItemId.chat,
  MenuItemId.aiMemory,
  MenuItemId.settings,
];

const Map<String, String> kMenuItemLabels = {
  MenuItemId.dashboard:     'Dashboard',
  MenuItemId.studyTracker:  'Study Tracker',
  MenuItemId.todaysPlan:    "Today's Plan",
  MenuItemId.focusTimer:    'Focus Timer',
  MenuItemId.calendar:      'Calendar',
  MenuItemId.timeLogger:    'Time Logger',
  MenuItemId.fmge:          'FMGE Prep',
  MenuItemId.dailyTracker:  'Daily Tracker',
  MenuItemId.faLogger:      'FA Logger',
  MenuItemId.revision:      'Revision Hub',
  MenuItemId.knowledgeBase: 'Knowledge Base',
  MenuItemId.data:          'Info Files',
  MenuItemId.chat:          'AI Mentor',
  MenuItemId.aiMemory:      'My AI Memory',
  MenuItemId.analytics:     'Analytics',
  MenuItemId.settings:      'Settings',
};

// ── FMGE Subjects (19) ───────────────────────────────────────
const List<String> kFmgeSubjects = [
  'Anatomy',
  'Physiology',
  'Biochemistry',
  'Pathology',
  'Pharmacology',
  'Microbiology',
  'Forensic Medicine',
  'Community Medicine',
  'General Medicine',
  'General Surgery',
  'Obstetrics & Gynecology',
  'Pediatrics',
  'Ophthalmology',
  'ENT',
  'Orthopedics',
  'Psychiatry',
  'Dermatology',
  'Radiology',
  'Anesthesia',
];

// ── Body Systems (Knowledge Base filter) ─────────────────────
const List<String> kBodySystems = [
  'General',
  'Cardiovascular',
  'Respiratory',
  'GIT',
  'Neurology',
  'Endocrine',
  'Renal',
  'Musculoskeletal',
  'Reproductive',
  'Hematology',
  'Immunology',
  'Dermatology',
  'Ophthalmology',
  'ENT',
  'Psychiatry',
];

// ── Block Types ───────────────────────────────────────────────
enum BlockType {
  video,
  revisionFa,
  anki,
  qbank,
  breakBlock,
  other,
  mixed,
  fmgeRevision;

  String get value {
    switch (this) {
      case BlockType.video:        return 'VIDEO';
      case BlockType.revisionFa:   return 'REVISION_FA';
      case BlockType.anki:         return 'ANKI';
      case BlockType.qbank:        return 'QBANK';
      case BlockType.breakBlock:   return 'BREAK';
      case BlockType.other:        return 'OTHER';
      case BlockType.mixed:        return 'MIXED';
      case BlockType.fmgeRevision: return 'FMGE_REVISION';
    }
  }

  static BlockType fromString(String s) {
    switch (s) {
      case 'VIDEO':         return BlockType.video;
      case 'REVISION_FA':   return BlockType.revisionFa;
      case 'ANKI':          return BlockType.anki;
      case 'QBANK':         return BlockType.qbank;
      case 'BREAK':         return BlockType.breakBlock;
      case 'OTHER':         return BlockType.other;
      case 'MIXED':         return BlockType.mixed;
      case 'FMGE_REVISION': return BlockType.fmgeRevision;
      default:              return BlockType.other;
    }
  }
}

// ── Block Status ──────────────────────────────────────────────
enum BlockStatus {
  notStarted,
  inProgress,
  paused,
  done,
  skipped;

  String get value {
    switch (this) {
      case BlockStatus.notStarted: return 'NOT_STARTED';
      case BlockStatus.inProgress: return 'IN_PROGRESS';
      case BlockStatus.paused:     return 'PAUSED';
      case BlockStatus.done:       return 'DONE';
      case BlockStatus.skipped:    return 'SKIPPED';
    }
  }

  static BlockStatus fromString(String s) {
    switch (s) {
      case 'IN_PROGRESS': return BlockStatus.inProgress;
      case 'PAUSED':      return BlockStatus.paused;
      case 'DONE':        return BlockStatus.done;
      case 'SKIPPED':     return BlockStatus.skipped;
      default:            return BlockStatus.notStarted;
    }
  }
}

// ── Time Log Categories ───────────────────────────────────────
enum TimeLogCategory {
  study,
  revision,
  qbank,
  anki,
  video,
  noteTaking,
  breakTime,
  personal,
  sleep,
  entertainment,
  outing,
  life,
  other;

  String get value {
    switch (this) {
      case TimeLogCategory.study:         return 'STUDY';
      case TimeLogCategory.revision:      return 'REVISION';
      case TimeLogCategory.qbank:         return 'QBANK';
      case TimeLogCategory.anki:          return 'ANKI';
      case TimeLogCategory.video:         return 'VIDEO';
      case TimeLogCategory.noteTaking:    return 'NOTE_TAKING';
      case TimeLogCategory.breakTime:     return 'BREAK';
      case TimeLogCategory.personal:      return 'PERSONAL';
      case TimeLogCategory.sleep:         return 'SLEEP';
      case TimeLogCategory.entertainment: return 'ENTERTAINMENT';
      case TimeLogCategory.outing:        return 'OUTING';
      case TimeLogCategory.life:          return 'LIFE';
      case TimeLogCategory.other:         return 'OTHER';
    }
  }

  static TimeLogCategory fromString(String s) {
    switch (s) {
      case 'STUDY':         return TimeLogCategory.study;
      case 'REVISION':      return TimeLogCategory.revision;
      case 'QBANK':         return TimeLogCategory.qbank;
      case 'ANKI':          return TimeLogCategory.anki;
      case 'VIDEO':         return TimeLogCategory.video;
      case 'NOTE_TAKING':   return TimeLogCategory.noteTaking;
      case 'BREAK':         return TimeLogCategory.breakTime;
      case 'PERSONAL':      return TimeLogCategory.personal;
      case 'SLEEP':         return TimeLogCategory.sleep;
      case 'ENTERTAINMENT': return TimeLogCategory.entertainment;
      case 'OUTING':        return TimeLogCategory.outing;
      case 'LIFE':          return TimeLogCategory.life;
      default:              return TimeLogCategory.other;
    }
  }
}

// ── Time Log Source ───────────────────────────────────────────
enum TimeLogSource {
  manual,
  focusTimer,
  todaysPlan;

  String get value {
    switch (this) {
      case TimeLogSource.manual:     return 'MANUAL';
      case TimeLogSource.focusTimer: return 'FOCUS_TIMER';
      case TimeLogSource.todaysPlan: return 'TODAYS_PLAN';
    }
  }

  static TimeLogSource fromString(String s) {
    switch (s) {
      case 'FOCUS_TIMER':  return TimeLogSource.focusTimer;
      case 'TODAYS_PLAN':  return TimeLogSource.todaysPlan;
      default:             return TimeLogSource.manual;
    }
  }
}

// ── Revision Mode ─────────────────────────────────────────────
enum RevisionMode {
  fast,
  balanced,
  deep,
  strict;

  String get value {
    switch (this) {
      case RevisionMode.fast:     return 'fast';
      case RevisionMode.balanced: return 'balanced';
      case RevisionMode.deep:     return 'deep';
      case RevisionMode.strict:   return 'strict';
    }
  }

  static RevisionMode fromString(String s) {
    switch (s) {
      case 'fast':     return RevisionMode.fast;
      case 'balanced': return RevisionMode.balanced;
      case 'deep':     return RevisionMode.deep;
      case 'strict':   return RevisionMode.strict;
      default:         return RevisionMode.strict;
    }
  }
}

// ── SRS Schedules (hours) — mirrors srsService.ts ─────────────
// fast:     1d 3d 7d 15d 30d
// balanced: 4h 1d 2d 5d 10d 20d 40d
// deep:     4h 1d 3d 7d 14d 30d 60d
// strict:   8h 1d 3d 7d 14d 21d 30d 45d 60d 90d 120d 180d
const Map<String, List<int>> kRevisionSchedules = {
  'fast':     [24, 72, 168, 360, 720],
  'balanced': [4, 24, 48, 120, 240, 480, 960],
  'deep':     [4, 24, 72, 168, 336, 720, 1440],
  'strict':   [8, 24, 72, 168, 336, 504, 720, 1080, 1440, 2160, 2880, 4320],
};

// ── Block Durations (minutes) ─────────────────────────────────
const List<int> kBlockDurations = [30, 40, 45, 50];

// ── AI Tone Options ───────────────────────────────────────────
const List<String> kAiTones = ['strict', 'encouraging', 'balanced'];

// ── Font Size Options ─────────────────────────────────────────
const List<String> kFontSizes = ['small', 'medium', 'large'];
