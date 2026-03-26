// =============================================================
// FocusFlow Constants
// =============================================================

// ── Menu Item IDs (live screens only — G3 cleaned up dead entries) ─
class MenuItemId {
  static const String dashboard     = 'dashboard';
  static const String todaysPlan    = 'todays-plan';
  static const String faLogger      = 'fa-logger';
  static const String tracker       = 'tracker';
  static const String revision      = 'revision';
  static const String knowledgeBase = 'knowledge-base';
  static const String timeLogger    = 'time-logger';
  static const String analytics     = 'analytics';
  static const String settings      = 'settings';
}

const List<String> kDefaultMenuOrder = [
  MenuItemId.dashboard,
  MenuItemId.todaysPlan,
  MenuItemId.tracker,
  MenuItemId.revision,
  MenuItemId.analytics,
  MenuItemId.settings,
];

const Map<String, String> kMenuItemLabels = {
  MenuItemId.dashboard:     'Dashboard',
  MenuItemId.todaysPlan:    "Today's Plan",
  MenuItemId.tracker:       'Library',
  MenuItemId.revision:      'Revision Hub',
  MenuItemId.analytics:     'Analytics',
  MenuItemId.settings:      'Settings',
};

// ── Pinnable screens for bottom nav ──────────────────────────────
const Map<String, String> kPinnableScreenLabels = {
  MenuItemId.dashboard:     'Dashboard',
  MenuItemId.todaysPlan:    "Today's Plan",
  'tracker':                'Library',
  MenuItemId.revision:      'Revision',
  MenuItemId.analytics:     'Analytics',
  'import':                 'Import',
};

// Default 4 pinned tabs shown in bottom nav
const List<String> kDefaultPinnedTabs = [
  'dashboard',
  'revision',
  'todays-plan',
  'tracker',
];

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

// ── FA 2025 Subjects (for Tracker) ────────────────────────────
const List<String> kFaSubjects = [
  'Biochemistry',
  'Immunology',
  'Microbiology',
  'Pathology',
  'Pharmacology',
  'Public Health Sciences',
  'Cardiovascular',
  'Endocrine',
  'Gastrointestinal',
  'Hematology & Oncology',
  'Musculoskeletal & Skin',
  'Neurology & Special Senses',
  'Psychiatry',
  'Renal',
  'Reproductive',
  'Respiratory',
];

// ── Block Types ───────────────────────────────────────────────
enum BlockType {
  video,
  revisionFa,
  anki,
  qbank,
  studySession,
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
      case BlockType.studySession: return 'STUDY_SESSION';
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
      case 'STUDY_SESSION': return BlockType.studySession;
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
  prayer,
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
      case TimeLogCategory.prayer:        return 'PRAYER';
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
      case 'PRAYER':        return TimeLogCategory.prayer;
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
  strict,
  aggressive;

  String get value {
    switch (this) {
      case RevisionMode.fast:       return 'fast';
      case RevisionMode.balanced:   return 'balanced';
      case RevisionMode.deep:       return 'deep';
      case RevisionMode.strict:     return 'strict';
      case RevisionMode.aggressive: return 'aggressive';
    }
  }

  static RevisionMode fromString(String s) {
    switch (s) {
      case 'fast':       return RevisionMode.fast;
      case 'balanced':   return RevisionMode.balanced;
      case 'deep':       return RevisionMode.deep;
      case 'strict':     return RevisionMode.strict;
      case 'aggressive': return RevisionMode.aggressive;
      default:           return RevisionMode.strict;
    }
  }
}

// ── SRS Schedules (hours) ─────────────────────────────────────
const Map<String, List<int>> kRevisionSchedules = {
  'fast':       [24, 72, 168, 360, 720],
  'balanced':   [4, 24, 48, 120, 240, 480, 960],
  'deep':       [4, 24, 72, 168, 336, 720, 1440],
  'strict':     [8, 24, 72, 168, 336, 504, 720, 1080, 1440, 2160, 2880, 4320],
  // 10 revisions in 30 days — fits 700 pages in 100 total days
  // R1: 1h, R2: 8h, R3: 1d, R4: 2d, R5: 4d, R6: 7d, R7: 12d, R8: 18d, R9: 24d, R10: 30d
  'aggressive': [1, 8, 24, 48, 96, 168, 288, 432, 576, 720],
};

// ── Daily FA page study target ────────────────────────────────
const int kDailyPageTarget = 10;

// ── Block Durations (minutes) ─────────────────────────────────
const List<int> kBlockDurations = [30, 40, 45, 50];

// ── AI Tone Options ───────────────────────────────────────────
const List<String> kAiTones = ['strict', 'encouraging', 'balanced'];

// ── Font Size Options ─────────────────────────────────────────
const List<String> kFontSizes = ['small', 'medium', 'large'];

// ── Focus Session Motivational Quotes ─────────────────────────
const List<String> kFocusQuotes = [
  'Close Instagram. Open First Aid.',
  'Future doctor. Present student.',
  'Your phone can wait. Your patients can\'t.',
  'One page at a time. You\'ve got this.',
  'Step 1 is a marathon. Today is one mile.',
  'The work you do now is the doctor you become.',
  'Distraction is the enemy of distinction.',
  'Every page studied is a life saved someday.',
  'You didn\'t come this far to only come this far.',
  'Discipline today. White coat tomorrow.',
  'Be the doctor your future patients deserve.',
  'First Aid won\'t read itself. Let\'s go.',
  'Your stethoscope is waiting. Earn it.',
  'Small steps. Big board scores.',
  'The grind is temporary. The title is forever.',
  'Another hour closer to MD.',
  'Neurons fire when you study. So fire them up.',
  'You\'re not behind. You\'re building.',
  'That last page you read? Someone in clinic needed it.',
  'Consistency beats intensity. Show up daily.',
  'Your brain is a muscle. Train it.',
  'Pathoma today. Pathologist\'s respect tomorrow.',
  'Ten more minutes. You can do ten minutes.',
  'Rest is earned. Focus is chosen.',
  'Think of the patient who needs you to know this.',
  'Every Anki card is a future diagnosis caught.',
  'Coffee is optional. Commitment is not.',
  'Hard chapters build strong doctors.',
  'Don\'t count the pages. Make the pages count.',
  'You\'re investing in lives, including your own.',
  'The best time to study was yesterday. The next best is now.',
  'One more question. One more concept. One more win.',
  'Your future self will thank you for this hour.',
  'No one said it was easy. They said it was worth it.',
  'Embrace the struggle. It\'s shaping you.',
  'Board prep is a privilege. Not everyone gets this far.',
  'Focus is a superpower. Activate it.',
  'Netflix will be there after boards. This window won\'t.',
  'Less scrolling. More scoring.',
  'Imagine the pride on match day. Feed that fire.',
  'You are one study session away from a breakthrough.',
  'Micro-progress is still progress.',
  'Sketchy today. Sketchy recall on test day.',
  'Your classmates are studying. Join the wave.',
  'Pain of discipline or pain of regret. Choose wisely.',
  'The material is hard. You are harder.',
  'Read. Recall. Repeat. Results.',
  'Build the knowledge. The confidence follows.',
  'Pharmacology won\'t memorize itself. You will.',
  'Stop overthinking the plan. Start executing it.',
  'Every wrong answer is a future right answer.',
  'Your rotation self needs today\'s study self.',
  'Make Goljan proud.',
  'Trade one hour of phone time for one hour of First Aid.',
  'This page could be the difference on test day.',
  'You\'re not just reading. You\'re becoming.',
  'The wards will test you. Prepare now.',
  'Knowledge compounds. Keep depositing.',
  'Do the hard thing. Then do it again.',
  'One chapter. One system. One victory.',
  'Your white coat doesn\'t come with an asterisk. Earn it fully.',
  'Boredom is the gateway to mastery.',
  'Master the basics. The zebras will follow.',
  'Nobody regrets studying too much for boards.',
  'Turn off notifications. Turn on your brain.',
  'Study like lives depend on it. They will.',
  'Today\'s effort. Tomorrow\'s expertise.',
  'The library doesn\'t judge. It just helps.',
  'Attention is currency. Spend it on First Aid.',
  'Be relentless. Be focused. Be a doctor.',
  'Skip the shortcut. Take the deep path.',
  'Your dreams are bigger than your distractions.',
  'One flashcard at a time changes everything.',
  'The discomfort you feel is growth happening.',
  'Amboss it. Anki it. Own it.',
  'The attending who inspires you once sat where you sit.',
  'Don\'t wish for it. Work for it.',
  'Grit > talent when talent doesn\'t grind.',
  'Step away from YouTube. Open UWorld.',
  'Every question you practice is armor for test day.',
  'You\'re building a foundation of saving lives.',
  'Trust the process. Repeat the process.',
  'Revision today means retention tomorrow.',
  'Champions study when they don\'t feel like it.',
  'That tricky concept? It\'s on the exam. Learn it now.',
  'Your EHR future starts with today\'s textbook.',
  'Craving a break? Earn it with 30 more minutes.',
  'Less comparing. More preparing.',
  'The scoreboard changes with every session.',
  'Motivation fades. Habits don\'t.',
  'Biochem is brutal. You are more brutal.',
  'Imagine explaining this topic to a patient. Can you?',
  'Brain fog lifts when you start. Just start.',
  'Five more questions. That\'s all.',
  'Your USMLE score is written in hours, not wishes.',
  'Be the reason your study group levels up.',
  'Clarity comes from action, not from planning.',
  'First Aid page 1 was hard too. Look how far you\'ve come.',
  'Don\'t break the chain. Study every day.',
  'The exam doesn\'t care about excuses. Neither should you.',
  'One topic mastered today is one less worry on test day.',
  'Treat your study time like a patient appointment. Non-negotiable.',
  'Your future colleagues are counting on you.',
  'The sacrifice is real. The reward is realer.',
  'This moment right now? It matters.',
  'Forget perfect. Pursue persistent.',
  'Stay hungry for knowledge. Stay humble in practice.',
  'The finish line is closer than it feels.',
  'Keep going. You\'re doing better than you think.',
];
