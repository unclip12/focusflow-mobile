# 🧠 FocusFlow Flutter — MASTER PLAN
**Source of Truth for All AI Agents Working on This Project**
*Web App Reference: https://github.com/unclip12/FocusFlow (main branch)*

---

## 🤖 AI AGENT INSTRUCTIONS — READ THIS FIRST

### Critical: 3 GitHub Tool Call Limit Per Turn
This project is built by AI assistants (Perplexity, Claude, etc.) that have a **maximum of 3 GitHub API tool calls per conversation turn**. Violating this causes incomplete commits and broken states.

### Mandatory Working Protocol:
1. **START every turn** by reading `PROGRESS.md` to know the current batch state
2. **Plan your 3 calls before executing**:
   - Call 1: Read source/reference files from FocusFlow web app (if needed for logic)
   - Call 2: Push the main Dart file(s) for the current batch (use `push_files` for multi-file)
   - Call 3: Update `PROGRESS.md` with new ✅ status and next batch pointer
3. **One batch per turn** — never start a new batch mid-turn
4. **Batch sizes**: Max 3–5 Dart files pushed per turn via `push_files`
5. **Never skip PROGRESS.md update** — this is how the next AI knows where to resume
6. **All logic must match web app exactly** — read the web app source files, don't guess

### Standard Turn Template:
```
Step 1: mcp_tool_github_mcp_direct_get_file_contents → PROGRESS.md (know current batch)
Step 2: mcp_tool_github_mcp_direct_push_files → implement current batch Dart files
Step 3: mcp_tool_github_mcp_direct_create_or_update_file → update PROGRESS.md
```

### How to Read Web App Source:
- **Always read from**: `unclip12/FocusFlow` repo, `main` branch
- Use `get_file_contents` with `ref: 'main'` to fetch any component
- Key files by priority: `types.ts`, `App.tsx`, then specific screen `.tsx` files

---

## 🏗️ Architecture Overview

### Tech Stack
| Layer | Web App (Source) | Flutter App (Target) |
|---|---|---|
| Storage | IndexedDB + Firebase | SQLite via `sqflite` |
| State | React useState | Provider + ChangeNotifier |
| Navigation | State machine | GoRouter named routes |
| AI | Gemini API (HTTP) | Same Gemini API (http package) |
| Notifications | Web Push API | flutter_local_notifications |
| Haptics | Capacitor Haptics | HapticFeedback (Flutter built-in) |
| Backup | Firebase + JSON | JSON file export/import (file_picker + share_plus) |
| Themes | CSS Variables (12 themes) | ThemeData (same 12 themes) |

### Required pubspec.yaml Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  provider: ^6.1.2
  go_router: ^14.0.0
  flutter_local_notifications: ^17.0.0
  http: ^1.2.0
  shared_preferences: ^2.2.3
  path_provider: ^2.1.3
  file_picker: ^8.0.0
  share_plus: ^9.0.0
  google_fonts: ^6.2.1
  intl: ^0.19.0
  fl_chart: ^0.69.0
  flutter_slidable: ^3.1.0
  image_picker: ^1.0.7
  permission_handler: ^11.3.1
  uuid: ^4.4.0
  collection: ^1.18.0
```

### Offline Storage Strategy
- **Main DB**: SQLite (sqflite) with one table per data type
- **Backup**: Full JSON export to device Downloads/Documents folder
- **Restore**: Import JSON file → parse → write to SQLite
- **Format**: Must match web app's Firebase JSON backup format for cross-app restore
- **No Firebase, no cloud, no Vercel** — 100% local/offline

### Folder Structure
```
lib/
├── main.dart
├── app.dart                         # App root, MaterialApp, theme, router
├── models/                          # All data models (from types.ts)
│   ├── app_settings.dart            # AppSettings, NotificationConfig, MenuItemConfig
│   ├── knowledge_base.dart          # KnowledgeBaseEntry, RevisionLog, TrackableItem
│   ├── day_plan.dart                # DayPlan, Block, BlockTask, BlockType, DayPlanBreak
│   ├── study_plan_item.dart         # StudyPlanItem, PlanLog, ToDoItem
│   ├── fmge_entry.dart              # FMGEEntry, FMGELog, FMGE_SUBJECTS
│   ├── time_log_entry.dart          # TimeLogEntry, TimeLogCategory, TimeLogSource
│   ├── daily_tracker.dart           # DailyTracker, TimeSlot, TrackerTask
│   ├── mentor_message.dart          # MentorMessage, MentorMemory, BacklogItem, AISettings
│   ├── study_entry.dart             # StudyEntry
│   ├── study_material.dart          # StudyMaterial, MaterialChatMessage
│   ├── revision_item.dart           # RevisionItem, RevisionSettings, REVISION_SCHEDULES
│   ├── user_profile.dart            # UserProfile
│   ├── app_snapshot.dart            # AppSnapshot, HistoryRecord
│   └── attachment.dart              # Attachment, VideoResource, QuizQuestion
├── services/
│   ├── database_service.dart        # SQLite CRUD for all tables
│   ├── backup_service.dart          # JSON export/import (web-compatible format)
│   ├── srs_service.dart             # Spaced repetition (from srsService.ts)
│   ├── plan_service.dart            # Plan migration (from planService.ts)
│   ├── fa_logger_service.dart       # KB integrity check (from faLoggerService.ts)
│   ├── notification_service.dart    # Local push notifications
│   └── haptics_service.dart         # Haptic feedback wrapper
├── providers/
│   ├── app_provider.dart            # Central state (from App.tsx)
│   ├── knowledge_base_provider.dart
│   ├── plan_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── dashboard/dashboard_screen.dart
│   ├── study_tracker/study_tracker_screen.dart
│   ├── todays_plan/
│   │   ├── todays_plan_screen.dart
│   │   ├── block_card.dart
│   │   ├── add_block_modal.dart
│   │   ├── add_break_modal.dart
│   │   ├── pause_reason_modal.dart
│   │   ├── manual_plan_modal.dart
│   │   └── reflection_modal.dart
│   ├── focus_timer/focus_timer_screen.dart
│   ├── fmge/
│   │   ├── fmge_screen.dart
│   │   └── fmge_log_modal.dart
│   ├── calendar/calendar_screen.dart
│   ├── time_logger/time_logger_screen.dart
│   ├── daily_tracker/daily_tracker_screen.dart
│   ├── fa_logger/
│   │   ├── fa_logger_screen.dart
│   │   └── fa_log_modal.dart
│   ├── revision/
│   │   ├── revision_screen.dart
│   │   └── log_revision_modal.dart
│   ├── knowledge_base/
│   │   ├── knowledge_base_screen.dart
│   │   └── page_detail_modal.dart
│   ├── data/data_screen.dart
│   ├── ai_mentor/
│   │   ├── ai_mentor_screen.dart
│   │   └── import_confirm_modal.dart
│   ├── ai_memory/ai_memory_screen.dart
│   └── settings/settings_screen.dart
├── widgets/
│   ├── app_scaffold.dart            # Common scaffold with nav
│   ├── nav_overlay.dart             # Bouncy top-left nav menu
│   ├── stats_card.dart              # TodayGlance (from StatsCard.tsx)
│   ├── activity_graphs.dart         # Charts (from ActivityGraphs.tsx)
│   ├── animated_button.dart
│   ├── delete_confirm_dialog.dart
│   └── session_modal.dart           # Study session logging modal
└── utils/
    ├── constants.dart               # CATEGORIES, SYSTEMS, FMGE_SUBJECTS, DEFAULT_MENU_ORDER
    ├── date_utils.dart              # getAdjustedDate equivalent
    └── app_theme.dart               # 12 APP_THEMES + 6 THEME_COLORS
```

---

## 📦 Complete Data Models Summary
*(Full definitions in types.ts of web app — always read that file for exact field names)*

### Key SRS Logic (from srsService.ts)
```
REVISION_SCHEDULES (hours from last review):
  fast:     [24, 72, 168, 360, 720]           → 1d, 3d, 7d, 15d, 30d
  balanced: [4, 24, 48, 120, 240, 480, 960]   → 4h, 1d, 2d, 5d, 10d, 20d, 40d
  deep:     [4, 24, 72, 168, 336, 720, 1440]  → 4h, 1d, 3d, 7d, 14d, 30d, 60d

calculateNextRevisionDate(lastStudied, revisionIndex, revisionSettings) → DateTime?
  - Get schedule for mode (fast/balanced/deep)
  - If revisionIndex >= schedule.length → return null (mastered)
  - Else → lastStudied.add(Duration(hours: schedule[revisionIndex]))
```

### BlockType Enum
`VIDEO | REVISION_FA | ANKI | QBANK | BREAK | OTHER | MIXED | FMGE_REVISION`

### BlockStatus Enum
`NOT_STARTED | IN_PROGRESS | PAUSED | DONE | SKIPPED`

### TimeLogCategory Enum
`STUDY | REVISION | QBANK | ANKI | VIDEO | NOTE_TAKING | BREAK | PERSONAL | SLEEP | ENTERTAINMENT | OUTING | LIFE | OTHER`

### 15 Menu Item IDs (in DEFAULT_MENU_ORDER)
`DASHBOARD, STUDY_TRACKER, TODAYS_PLAN, FOCUS_TIMER, CALENDAR, TIME_LOGGER, FMGE, DAILY_TRACKER, FA_LOGGER, REVISION, KNOWLEDGE_BASE, DATA, CHAT, AI_MEMORY, SETTINGS`

---

## 📱 15 Screens — Feature Inventory

### 1. Dashboard
- Welcome + name
- TodayGlance card (today's plan summary, sessions done)
- Activity graphs (bar chart of study hours per day)
- Due Now list (KB entries + FMGE entries overdue)
- Streak counter
- Quick nav to Today's Plan

### 2. Study Tracker
- Date picker
- Search bar
- StudyEntry: taskName, progress 0-100%, revision flag, durationMinutes
- List/table view by date

### 3. Today's Plan ← Most Complex (124KB source)
- Date navigation (prev/next day)
- Block list view (ordered by index)
- Block card showing: title, type, planned time, status, tasks checklist
- Add/Edit/Delete blocks (type, time, title, tasks, FA pages, anki, qbank)
- Break blocks (AddBreakModal)
- Block execution: Start → In Progress → Pause (with reason) → Done/Skipped
- Segment tracking (actual start/end within block)
- Interruption tracking with reasons
- Reflection notes when completing block
- Carry-forward pages for incomplete blocks
- Reflection at day end (ReflectionModal)
- FA pages planned count + actual covered
- Video blocks with URL, duration, playback speed
- Anki blocks with card count
- QBank blocks with question count
- Auto time-log generation when block completed
- Auto KB log generation when block completed
- Daily stats: total planned vs actual minutes, blocks done/total
- Manual plan modal (simple non-block view)
- AI Mentor integration for plan suggestions
- Block duration setting (30/40/45/50 min)

### 4. Focus Timer
- Countdown timer
- Topic/block linking
- Start/Pause/Stop
- Session auto-logged to KB on completion
- Integrates with Today's Plan blocks

### 5. FMGE Prep
- 19-subject list
- Log entry: subject, slideStart, slideEnd, qBankCount, notes
- SRS revision scheduling per entry
- Log history per entry
- Due for revision indicator

### 6. Calendar
- Month view grid
- Day detail tap → show study plan items for that day
- Color coding by completion
- Add plan item from calendar

### 7. Time Logger
- Manual time entry: activity name, category, date, start time, end time
- Computed duration
- History list (grouped by date)
- Filter by category
- Link to KB page number
- Source tracking

### 8. Daily Tracker
- Time slot grid (custom start/end)
- Add tasks to time slots
- Mark tasks complete/incomplete
- Reason for incomplete
- Time invested input

### 9. FA Logger
- Log FA reading: pageNumber, date, startTime, endTime, topics covered, notes
- NO subject/category selector
- List of all FA logs chronologically
- Study mode vs Revision mode
- Edit/delete logs
- Tap to view linked KB entry

### 10. Revision Hub
- Tabs: DUE / UPCOMING / HISTORY
- Each revision item shows: title, page, system, due date/time
- Sort options: TIME / PAGE / TOPIC / SYSTEM
- Tap to log revision → opens session modal
- Delete revision (remove scheduled date)
- Grouped topics under same page

### 11. Knowledge Base ← READ-ONLY
- No add button — populated only by AI Mentor
- Search bar
- Filter by system dropdown
- Sort: PAGE/TOPIC/SYSTEM/SUBJECT/REVISIONS/STUDIED/LAST_STUDIED/RECENTLY_ADDED
- View mode toggle: PAGE_WISE / SUBTOPIC_WISE
- Tap entry → PageDetail modal:
  - Title, subject, system, page number
  - Anki total/covered, Anki tag
  - Video links (tap to open)
  - Tags, Notes, Key points (high-yield bullets)
  - Attachments
  - Topics list with their own SRS data
  - Subtopics nested under topics
  - Full revision log history
  - Page Analysis (AI-generated)
  - Quiz questions

### 12. Info Files / Data
- List of uploaded study materials
- Filter: ALL / UPLOAD / MENTOR
- Tap → Material detail (full text view)
- Toggle active/inactive (for Study Buddy context)

### 13. AI Mentor (Chat)
- Chat interface with message history
- Two modes: MENTOR / BUDDY (uses Info Files as context)
- Paste structured FAQ output → AI detects → asks: "Add to Knowledge Base" or "Add to Today's Plan"?
- Confirm action → data written to store
- Persistent conversation history
- AI Settings accessible from here

### 14. My AI Memory
- Display name edit
- Exam target + date picker
- Learning style freetext
- Preferred AI tone (strict/encouraging/balanced)
- Backlog items list
- Notes field
- Memory permission toggles

### 15. Settings
- 12 themes (visual preview chips)
- 6 primary accent colors
- Dark mode toggle
- Font size (small/medium/large)
- Menu configuration: toggle visibility + reorder (drag handles)
- Notification settings
- Quiet hours
- Anki integration (host URL, tag prefix)
- Backup & Restore: Export JSON / Import JSON
- Profile: display name

### Navigation Design (All Screens)
- Top header bar: Left = current screen name (TAPPABLE), Right = streak
- Tap screen name → bouncy spring nav overlay (anchored top-left)
- Select any screen → navigates + closes overlay
- Active screen highlighted
- Respects `menuConfiguration` visibility

---

## 🔧 Services Logic Summary

### srs_service.dart
```dart
// calculateNextRevisionDate(lastStudied, revisionIndex, revisionSettings) → DateTime?
// Get schedule list for mode → if index >= length return null (mastered)
// Else return lastStudied.add(Duration(hours: schedule[revisionIndex]))
```

### backup_service.dart
```dart
// exportFullBackup() → JSON with keys:
// { knowledgeBase, studyPlan, dayPlans, fmgeEntries, timeLogs,
//   dailyTracker, studyTracker, mentorMessages, studyMaterials,
//   mentorMemory, aiSettings, userProfile, settings, history }
// Must match web app Firebase export format for cross-app restore
// importBackup(jsonString) → parse all keys → write to SQLite
```

---

## 🗓️ 27-Batch Implementation Plan

### PHASE 0 — Foundation
| Batch | Files | Description |
|---|---|---|
| 1 | pubspec.yaml, main.dart, app.dart, utils/constants.dart, utils/date_utils.dart | Project setup + constants |
| 2 | All 14 model files in models/ | Data models from types.ts |
| 3 | services/database_service.dart, services/srs_service.dart, services/haptics_service.dart | Core services |

### PHASE 1 — State & Navigation
| Batch | Files | Description |
|---|---|---|
| 4 | providers/app_provider.dart, providers/settings_provider.dart, utils/app_theme.dart, app_router.dart | State + routing |
| 5 | widgets/app_scaffold.dart, widgets/nav_overlay.dart | Base scaffold + bouncy nav |

### PHASE 2 — Core Screens
| Batch | Files | Description |
|---|---|---|
| 6 | screens/dashboard/dashboard_screen.dart, widgets/stats_card.dart, widgets/activity_graphs.dart | Dashboard |
| 7 | screens/todays_plan/todays_plan_screen.dart, screens/todays_plan/block_card.dart | Today's Plan core |
| 8 | screens/todays_plan/add_block_modal.dart + add_break_modal + pause_reason_modal + manual_plan_modal + reflection_modal | Today's Plan modals |
| 9 | screens/focus_timer/focus_timer_screen.dart | Focus Timer |
| 10 | screens/knowledge_base/knowledge_base_screen.dart, screens/knowledge_base/page_detail_modal.dart | Knowledge Base |
| 11 | screens/revision/revision_screen.dart, screens/revision/log_revision_modal.dart | Revision Hub |
| 12 | screens/fa_logger/fa_logger_screen.dart, screens/fa_logger/fa_log_modal.dart | FA Logger |

### PHASE 3 — Secondary Screens
| Batch | Files | Description |
|---|---|---|
| 13 | screens/study_tracker/study_tracker_screen.dart | Study Tracker |
| 14 | screens/fmge/fmge_screen.dart, screens/fmge/fmge_log_modal.dart | FMGE Prep |
| 15 | screens/calendar/calendar_screen.dart | Calendar |
| 16 | screens/time_logger/time_logger_screen.dart | Time Logger |
| 17 | screens/daily_tracker/daily_tracker_screen.dart | Daily Tracker |
| 18 | screens/data/data_screen.dart | Info Files |

### PHASE 4 — AI & Intelligence
| Batch | Files | Description |
|---|---|---|
| 19 | screens/ai_mentor/ai_mentor_screen.dart | AI Mentor chat UI |
| 20 | screens/ai_mentor/import_confirm_modal.dart, widgets/session_modal.dart | KB import flow + session modal |
| 21 | screens/ai_memory/ai_memory_screen.dart | My AI Memory |

### PHASE 5 — Settings & Backup
| Batch | Files | Description |
|---|---|---|
| 22 | screens/settings/settings_screen.dart | Full settings screen |
| 23 | services/backup_service.dart, services/notification_service.dart, services/plan_service.dart, services/fa_logger_service.dart | Remaining services |
| 24 | providers/knowledge_base_provider.dart, providers/plan_provider.dart | Remaining providers |

### PHASE 6 — Polish & Integration
| Batch | Files | Description |
|---|---|---|
| 25 | Animations, transitions across all screens | Polish pass |
| 26 | Streak logic, Due Now, activity graph data | Final features |
| 27 | Final integration test, README update | Done |

---

## ✅ PROGRESS TRACKER

| Batch | Description | Status |
|---|---|---|
| 0 | Repo setup, MASTER_PLAN.md | ✅ Done |
| 1 | pubspec + main + app + constants | ⏳ **NEXT** |
| 2 | All model files | ⬜ Todo |
| 3 | DB service + SRS + haptics | ⬜ Todo |
| 4 | Providers + theme + router | ⬜ Todo |
| 5 | Nav overlay + base scaffold | ⬜ Todo |
| 6 | Dashboard screen | ⬜ Todo |
| 7 | Today's Plan core | ⬜ Todo |
| 8 | Today's Plan modals | ⬜ Todo |
| 9 | Focus Timer | ⬜ Todo |
| 10 | Knowledge Base | ⬜ Todo |
| 11 | Revision Hub | ⬜ Todo |
| 12 | FA Logger | ⬜ Todo |
| 13 | Study Tracker | ⬜ Todo |
| 14 | FMGE Prep | ⬜ Todo |
| 15 | Calendar | ⬜ Todo |
| 16 | Time Logger | ⬜ Todo |
| 17 | Daily Tracker | ⬜ Todo |
| 18 | Info Files | ⬜ Todo |
| 19 | AI Mentor (chat UI) | ⬜ Todo |
| 20 | AI Mentor (KB import) + Session modal | ⬜ Todo |
| 21 | My AI Memory | ⬜ Todo |
| 22 | Settings | ⬜ Todo |
| 23 | Backup/Restore + Notifications | ⬜ Todo |
| 24 | Remaining providers | ⬜ Todo |
| 25 | Animations & polish | ⬜ Todo |
| 26 | Streak + Due Now + Graphs | ⬜ Todo |
| 27 | Final testing + README | ⬜ Todo |

---

*Last updated: 2026-02-23 | Next: Batch 1*
