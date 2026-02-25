# FocusFlow Mobile — Development Progress

> Last updated: 2026-02-25
> Session: Claude + Arsh — Antigravity workflow

---

## ✅ Completed Batches

---

### Batch A — Android Build Setup
**Status**: ✅ Complete
**Commits**: `fix: commit android folder with NDK 27`, `fix: align Java and Kotlin JVM targets to 17`, `ci: add Gradle and pub package caching`

**What was done:**
- Android folder committed with NDK 27
- Core library desugaring enabled
- Java + Kotlin JVM targets aligned to 17
- GitHub Actions CI workflow created with flutter analyze gate
- Gradle + pub package caching for faster builds

---

### Batch B — Data Persistence
**Status**: ✅ Complete
**Commits**: `fix: call AppProvider.loadAll() on startup so data persists across restarts`

**What was done:**
- `AppProvider.loadAll()` called on app startup in `main.dart`
- All data (tasks, KB, time logs) now persists across app restarts
- Previously: data was lost on every restart

---

### Batch C — Navigation Fixes
**Status**: ✅ Complete
**Commits**: `fix: data persistence, back navigation, date picker, remove generate plan`, `fix: task save without times, exit dialog on dashboard`

**What was done:**
- Task saves correctly without requiring start/end times
- Exit dialog appears on dashboard Android back button press
- Date picker works on Today Plan header
- Generate Plan button removed (was placeholder)
- Back navigation fixed app-wide

---

### Batch D — SRS + Knowledge Base + Task Planner
**Status**: ✅ Complete
**Commits**: `feat: strict SRS mode, AI Mentor JSON importer, KB pipeline`, `feat: exam-aware task planner, smart focus batch calculator, menu reorder`, `fix: replace initialValue with TextFormField in add_task_sheet`

**What was done:**

#### SRS Engine
- 12-step SRS revision schedule implemented
- Two modes: `strict` (default) and `relaxed`
- `SrsService.calculateNextRevisionDateString()` for scheduling
- `SrsService.isDueNow()` and `SrsService.isMastered()` helpers

#### Knowledge Base
- `KnowledgeBaseEntry` model: pageNumber, title, subject, system, topics, SRS fields
- `knowledge_base_screen.dart`: search, filter by subject/system/mastery
- `kb_entry_detail_screen.dart`: full page detail view with key points
- `kb_entry_card.dart`: compact card for list view

#### AI Mentor Importer
- JSON import via AI Mentor screen
- Paste Gemini JSON output → parsed → saved to KB
- Auto-populates: pageNumber, title, subject, system, keyPoints

#### Task Planner
- Step 1: Exam selector card (USMLE Step 1, FMGE)
- Step 2: Study type chips (FA Pages, Video Lecture, Qbank, Anki, Revision, Other)
- Step 3: Page/topic fields based on study type
- Smart focus batch calculator: given start/end times → auto-suggests 25/50min blocks
- Menu reordered for better flow

#### Bug Fix in Batch D
- `initialValue` on `TextFormField` was wrong in `add_task_sheet.dart` (Gemini hallucinated it) — fixed

---

### Batch E — Session Timer + FA Logger
**Status**: ✅ Complete
**Commits**: `feat: session timer with quotes, completion flow, FA Logger redesign`, `fix: wire session screen navigation from today plan block start`, `fix: wire session navigation, completion saves to KB and FA Logger`

**What was done:**

#### Session Screen
- Full countdown timer with start/pause/stop
- Rotating motivational quotes during session
- Completion screen with session summary
- Start Block button on Today Plan → opens SessionScreen correctly

#### Completion Flow
- Session complete → auto-creates `TimeLogEntry` in Time Log
- Session complete → updates `KnowledgeBaseEntry.lastStudiedAt`
- Session complete → logs to FA Logger

#### FA Logger Redesign
- Redesigned with cleaner layout
- Shows per-page stats: time spent, revision count, SRS step

#### Navigation
- Back from session → returns to Today Plan (no double-pop)
- Start Block → Session → Complete → Back to Today Plan ✔

---

### Batch F — Critical Bug Fixes
**Status**: ✅ Complete
**Commits**: `fix: Start Block opens SessionScreen, fix navigator double-pop on save`, `fix: remove duplicate AppScaffold on dashboard, fix blocksDone count`, `fix: correct SRS index field, add TimeLogEntry on session save`, `chore: fix all deprecations, dark mode consistency, spacing pass`, `fix: replace initialValue with value in DropdownButtonFormField (2 files)`

**What was done:**

#### Dashboard
- Removed duplicate `AppScaffold` wrapper (was showing double bottom nav)
- Fixed `blocksDone` counter (was always showing 0)

#### Session Navigation
- Start Block → SessionScreen (was crashing or going to wrong screen)
- Double-pop bug fixed (was jumping past Today Plan)

#### SRS
- Correct field used for SRS index (was referencing wrong field name)
- `TimeLogEntry` now auto-created when session saves

#### Code Quality
- All deprecated APIs replaced (`withOpacity` → `withValues(alpha:)`)
- Dark mode consistency pass across all screens
- Spacing standardized
- `initialValue` on `DropdownButtonFormField` → `value` (2 files: `add_time_log_sheet.dart`, `add_task_sheet.dart`)

---

### Bug Fix — TextSanitizer + Revision Card
**Status**: ✅ Complete
**Commits**: `fix: add TextSanitizer utility + fix garbled chars in revision_card`

**What was done:**

#### Root Cause
AI-generated content (from JSON imports) had UTF-8 bytes read as Windows-1252,
creating garbled sequences: `â€¢` (for •), `â€”` (for —), `â` (for ✓)

#### Fix 1: New Utility
`lib/utils/text_sanitizer.dart` — `TextSanitizer.clean(String)` method
Maps all common Windows-1252-over-UTF-8 garbled sequences to correct Unicode.

#### Fix 2: revision_card.dart
- Source code had garbled chars in string literals
- `â€”` → `\u2014` (em dash) in page title string
- `â` → `\u2713` (check mark) in 'Mark Revised' button
- `TextSanitizer.clean()` now applied to `entry.title` and `entry.pageNumber` before display

---

## 🔄 In Progress

---

### Batch G1 — Milky Theme Update
**Status**: 🔄 Prompt given to Gemini 3 Flash — may or may not be committed yet
**Model**: Gemini 3 Flash (UI-only, no logic)

**What it does:**
- Replaces all 12 theme color pairs (lightBg, lightSurface, darkBg, darkSurface)
- Milky soft backgrounds: light = white-lavender, dark = charcoal (not navy)
- Softer card shadows in light mode, subtle border in dark mode
- Default theme changed to light mode (`isDarkMode = false` default)
- Softer border colors

**Files to change:**
- `lib/utils/app_theme.dart`
- `lib/providers/settings_provider.dart`

**Check after running:**
- App opens in LIGHT mode by default
- Backgrounds have soft milky tint (not stark white)
- Dark mode is charcoal not navy
- All 12 themes cycle correctly

---

### Batch G2 — KB Garbled Chars + Manual Add Entry
**Status**: 🔄 Prompt given to Gemini Pro High — currently running
**Model**: Gemini 3 Pro High

**What it does:**
1. Apply `TextSanitizer.clean()` to all text display in `kb_entry_detail_screen.dart`
   (fixes bullet points showing as `â€¢` in the Page view)
2. Add FAB + `_AddKBEntrySheet` to `knowledge_base_screen.dart`
   (allows manual creation of KB entries without AI import)

**Files to change:**
- `lib/screens/knowledge_base/kb_entry_detail_screen.dart`
- `lib/screens/knowledge_base/knowledge_base_screen.dart`

**Check after running:**
- Page detail view shows clean bullet points • not `â€¢`
- `+` FAB visible on Knowledge Base screen
- Tapping `+` opens sheet with: Page #, Topic, Subject dropdown, System dropdown
- Save creates entry that appears in KB list

---

## 📋 Upcoming Batches

---

### Batch H — Gemini AI Service
**Status**: 📋 Planned — most complex batch
**Model**: Gemini 3 Pro High, High thinking budget

**14 functions to implement in `lib/services/gemini_service.dart`:**
1. `generateStudyPlan(examDate, weakSubjects, dailyHours)` → JSON plan
2. `debriefSession(sessionData, kbEntry)` → feedback string
3. `autoTagKBEntry(rawContent)` → subject, system, keyPoints
4. `generateMCQ(kbEntry)` → USMLE-style question + answer + explanation
5. `detectWeakAreas(timeLogs, kbEntries)` → ranked weak area list
6. `getDailyMotivation(streak, examDate)` → motivational string
7. `getExamCoaching(daysLeft, coverage)` → strategy advice
8. `summarizeFAPage(pageContent)` → condensed summary
9. `analyzeMistakePatterns(wrongAnswers)` → pattern report
10. `rankRevisionPriority(kbEntries)` → sorted by urgency
11. `predictStudyTime(topic, userHistory)` → estimated minutes
12. `detectKnowledgeGaps(kbEntries, qbankData)` → gap list
13. `analyzeQbankPerformance(results)` → subject performance map
14. `generateStudyTip(currentFocus, timeOfDay)` → tip string

**Files to create/update:**
- `lib/services/gemini_service.dart` (new)
- `lib/screens/mentor/mentor_screen.dart` (wire all 14)
- `lib/providers/app_provider.dart` (expose AI results)
- `pubspec.yaml` (add `google_generative_ai` if not present)

---

### Batch I — Analytics & Charts
**Status**: 📋 Planned
**Model**: Gemini 3 Flash

- Study hours by day (7-day bar chart)
- Time per subject (pie chart)
- SRS due vs mastered over time (line chart)
- Streak visualization
- Screen: `lib/screens/analytics/analytics_screen.dart`

---

### Batch J — Notifications
**Status**: 📋 Planned
**Model**: Gemini 3 Flash

- Daily revision reminder (8 AM)
- SRS due alert when items are overdue
- Streak protection reminder if no session by 9 PM
- Package: `flutter_local_notifications`

---

### Batch K — Backup & Export
**Status**: 📋 Planned
**Model**: Gemini 3 Pro High

- Export KB + time logs to JSON file
- Import backup JSON
- Share as file (share_plus)
- Screen: `lib/screens/backup/backup_screen.dart`

---

### Batch L — Polish & Release Prep
**Status**: 📋 Planned
**Model**: Gemini 3 Flash

- App icon finalization
- Splash screen
- Onboarding flow (exam type selection)
- Play Store metadata
- Version bump to 1.0.0

---

## 🐛 Known Issues / Tech Debt

| Issue | Severity | Status |
|---|---|---|
| KB content from AI JSON has garbled chars | High | G2 fixing |
| Manual KB entry not possible | High | G2 fixing |
| Analytics screen is placeholder | Medium | Batch I |
| No notifications yet | Medium | Batch J |
| Mentor screen wired but AI not connected | High | Batch H |
| No backup/restore | Medium | Batch K |
| Study plan generator is placeholder | Low | Future |

---

## 🛠️ Model Selection Guide

| Task Type | Use | Thinking |
|---|---|---|
| Color / theme / UI tweaks | 3 Flash | Off |
| Single widget refactor | 3 Flash | Off |
| New screen with state logic | 3 Pro High | Low |
| AI service / complex provider | 3 Pro High | High |
| Multi-file architecture | 3 Pro High | High |
| Anything touching Firebase | 3 Pro High | High |
| Build errors / quick fixes | Direct Claude push | — |

---

## 🔒 Prompt Quality Rules

Every Gemini prompt must have:
```
STRICT RULE: Only use Flutter/Dart APIs you are 100% certain exist.
Do NOT invent parameter names. If unsure, use the simplest known alternative.

Read these files fully before writing anything:
- [list relevant files]

[Exact code blocks to insert]

DO NOT TOUCH:
- [list files to leave alone]

flutter analyze --no-fatal-infos
Fix any errors found, then:
git add [files changed]
git commit -m "[message]"
git push origin main
```

---

## 📆 Session Log

| Date | Work Done |
|---|---|
| Feb 24, 2026 | Batches A, B, C, D, E all completed in one session |
| Feb 25, 2026 | Batch F (critical fixes), TextSanitizer bug fix, G1/G2 prompts written |
| Feb 25, 2026 | MASTER_PLAN.md + PROGRESS.md updated with full state |
