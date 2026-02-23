// ─── FMGE Subjects (19 subjects — match web app fmge_subjects array) ────────
const List<String> FMGE_SUBJECTS = [
  'Anatomy',
  'Physiology',
  'Biochemistry',
  'Pathology',
  'Pharmacology',
  'Microbiology',
  'Forensic Medicine',
  'Community Medicine',
  'Medicine',
  'Surgery',
  'Obstetrics & Gynecology',
  'Pediatrics',
  'Orthopedics',
  'Ophthalmology',
  'ENT',
  'Dermatology',
  'Psychiatry',
  'Radiology',
  'Anesthesia',
];

// ─── Anatomy / Body Systems (for Knowledge Base filter) ─────────────────────
const List<String> SYSTEMS = [
  'All Systems',
  'General',
  'Musculoskeletal',
  'Cardiovascular',
  'Respiratory',
  'Gastrointestinal',
  'Genitourinary',
  'Nervous System',
  'Endocrine',
  'Lymphatic / Immune',
  'Skin / Integument',
  'Head & Neck',
  'Special Senses',
];

// ─── Time Log Categories (mirrors TimeLogCategory enum in web app) ───────────
const List<String> CATEGORIES = [
  'STUDY',
  'REVISION',
  'QBANK',
  'ANKI',
  'VIDEO',
  'NOTE_TAKING',
  'BREAK',
  'PERSONAL',
  'SLEEP',
  'ENTERTAINMENT',
  'OUTING',
  'LIFE',
  'OTHER',
];

/// Human-readable labels for each category (same order as CATEGORIES).
const List<String> CATEGORY_LABELS = [
  'Study',
  'Revision',
  'QBank',
  'Anki',
  'Video',
  'Note Taking',
  'Break',
  'Personal',
  'Sleep',
  'Entertainment',
  'Outing',
  'Life',
  'Other',
];

// ─── Navigation Menu Item IDs ─────────────────────────────────────────────────
const String kDashboard = 'DASHBOARD';
const String kStudyTracker = 'STUDY_TRACKER';
const String kTodaysPlan = 'TODAYS_PLAN';
const String kFocusTimer = 'FOCUS_TIMER';
const String kCalendar = 'CALENDAR';
const String kTimeLogger = 'TIME_LOGGER';
const String kFmge = 'FMGE';
const String kDailyTracker = 'DAILY_TRACKER';
const String kFaLogger = 'FA_LOGGER';
const String kRevision = 'REVISION';
const String kKnowledgeBase = 'KNOWLEDGE_BASE';
const String kData = 'DATA';
const String kChat = 'CHAT';
const String kAiMemory = 'AI_MEMORY';
const String kSettings = 'SETTINGS';

/// Default ordered list of all 15 navigation menu items.
const List<String> DEFAULT_MENU_ORDER = [
  kDashboard,
  kStudyTracker,
  kTodaysPlan,
  kFocusTimer,
  kCalendar,
  kTimeLogger,
  kFmge,
  kDailyTracker,
  kFaLogger,
  kRevision,
  kKnowledgeBase,
  kData,
  kChat,
  kAiMemory,
  kSettings,
];

/// Human-readable display names for each menu item ID.
const Map<String, String> MENU_LABELS = {
  kDashboard: 'Dashboard',
  kStudyTracker: 'Study Tracker',
  kTodaysPlan: "Today's Plan",
  kFocusTimer: 'Focus Timer',
  kCalendar: 'Calendar',
  kTimeLogger: 'Time Logger',
  kFmge: 'FMGE Prep',
  kDailyTracker: 'Daily Tracker',
  kFaLogger: 'FA Logger',
  kRevision: 'Revision Hub',
  kKnowledgeBase: 'Knowledge Base',
  kData: 'Info Files',
  kChat: 'AI Mentor',
  kAiMemory: 'My AI Memory',
  kSettings: 'Settings',
};

// ─── Block Durations (minutes) ───────────────────────────────────────────────
const List<int> BLOCK_DURATIONS = [30, 40, 45, 50];

// ─── Gemini API ───────────────────────────────────────────────────────────────
const String kGeminiModel = 'gemini-1.5-flash';
const String kGeminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// ─── SQLite table names ───────────────────────────────────────────────────────
const String kDbName = 'focusflow.db';
const int kDbVersion = 1;

const String tblKnowledgeBase = 'knowledge_base';
const String tblStudyPlan = 'study_plan';
const String tblDayPlans = 'day_plans';
const String tblFmgeEntries = 'fmge_entries';
const String tblTimeLogs = 'time_logs';
const String tblDailyTracker = 'daily_tracker';
const String tblStudyTracker = 'study_tracker';
const String tblMentorMessages = 'mentor_messages';
const String tblStudyMaterials = 'study_materials';
const String tblMentorMemory = 'mentor_memory';
const String tblAiSettings = 'ai_settings';
const String tblUserProfile = 'user_profile';
const String tblSettings = 'app_settings';
const String tblHistory = 'history';
const String tblRevisionItems = 'revision_items';
