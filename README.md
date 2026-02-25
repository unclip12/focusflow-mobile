# FocusFlow Mobile

Premium Flutter study app for USMLE Step 1 & FMGE students. Offline-first, SQLite persistence, exam-aware planning, SRS revision system.

---

## Tech Stack

- **Flutter** (stable 3.29)
- **SQLite** via `sqflite` — all data persisted offline
- **Provider** — `AppProvider` (all data) + `SettingsProvider` (theme/config)
- **GoRouter** — navigation
- **SrsService** — strict 12-revision spaced repetition algorithm

---

## Architecture

```
lib/
├── main.dart                  # Entry point — initialises SQLite, calls AppProvider.loadAll()
├── app.dart                   # MaterialApp.router with GoRouter + theme
├── providers/
│   ├── app_provider.dart      # Central state — all CRUD via DatabaseService
│   └── settings_provider.dart # Theme, dark mode, menu config
├── services/
│   ├── database_service.dart  # SQLite CRUD — JSON blob storage
│   └── srs_service.dart       # 12-step SRS algorithm
├── models/                    # DayPlan, Block, KnowledgeBaseEntry, RevisionItem, etc.
├── screens/
│   ├── dashboard/
│   ├── today_plan/            # AddTaskSheet (exam-aware), BlockCard, TodayPlanScreen
│   ├── session/               # SessionScreen (timer + quotes), SessionCompleteSheet
│   ├── fa_logger/             # FA Logger — First Aid pages only
│   ├── revision_hub/
│   ├── knowledge_base/
│   ├── mentor/                # AI Mentor — JSON importer
│   └── settings/
├── utils/
│   ├── constants.dart         # kDefaultMenuOrder, kBodySystems, kFocusQuotes (100+), etc.
│   └── focus_batch_calculator.dart  # Pomodoro-style batch splitter
└── widgets/
    └── app_scaffold.dart      # Shared scaffold with sidebar nav
```

---

## ✅ Completed (committed to main)

### Batch A — Core Foundation
- `1864df2` — All screens wired, AppScaffold navigation, dashboard empty state
- `939110b` — Strict 12-revision SRS algorithm, AI Mentor JSON importer → Knowledge Base

### Batch B — Exam-Aware Task Planner
- `58b313a` — USMLE + FMGE task planner, focus batch calculator, menu reorder
- `cea1551` — TextFormField fix (CI green)

### Batch X — Critical Bug Fixes
- `063ccde` — Data persistence fix, Android back navigation, date picker on Today's Plan, removed Generate Plan button
- `b88a40f` — Task save without times, exit dialog on dashboard back press
- `19b1f65` — **AppProvider.loadAll() called on startup** (data now survives force close)

### Batch C — Session Timer + FA Logger
- `3f2da99` — SessionScreen (countdown timer, 100+ motivational quotes, pause/end), SessionCompleteSheet, FA Logger redesign
- `203c7d4` — Wired SessionScreen navigation from Today's Plan block start

---

## 🔴 Current Bug (fix this first)

**Session flow not fully wired:**

1. `SessionScreen` navigation from `_startBlock()` in `today_plan_screen.dart` — needs to confirm it actually opens the timer screen when Start is tapped on a block
2. `session_complete_sheet.dart` — on Save & Complete must:
   - Call `app.upsertDayPlan()` to mark block as `done`
   - For FA Pages: call `app.upsertKBEntry()` with updated `lastStudiedAt`, `completionPercent`, `nextRevisionAt`
   - Create/update `RevisionItem` for each page studied
   - Navigate back to Today's Plan after save
3. FA Logger FAB quick-add must also trigger `upsertKBEntry()` + revision item creation

**Fix command for Antigravity (Claude Opus):**
```
The SessionScreen and SessionCompleteSheet exist but completion data 
is not being saved anywhere. When Save & Complete is tapped:
1. Mark the block as done in DayPlan via app.upsertDayPlan()
2. For FA Pages blocks, update each KnowledgeBaseEntry with 
   lastStudiedAt, completionPercent, nextRevisionAt via app.upsertKBEntry()
3. Create RevisionItem for each page via app.upsertRevisionItem()
4. Navigate back to Today's Plan after saving
5. FA Logger FAB save must do the same KB + revision updates
flutter analyze --no-fatal-infos → commit → push
```

---

## ⏳ Remaining Batches

### Batch D — Dashboard Live Data (Gemini)
Replace all empty/mock data on the dashboard with real data from AppProvider:
- Today's blocks list with completion status
- Due revisions count from KnowledgeBase entries where `nextRevisionAt <= now`
- Current streak (consecutive days with timeLogs)
- Subject breakdown chart from timeLogs
- Recent activity heatmap

### Batch E — Revision Hub (Claude Opus)
- List all KB entries where `nextRevisionAt <= now` (due for revision)
- Show SRS countdown for future entries (e.g. "Due in 3 days")
- "Mark Revised" button per entry that calls `SrsService.calculateNextRevision()` and increments `revisionIndex`
- Overdue entries highlighted in red

### Batch F — Polish & Cleanup (Gemini)
- Fix deprecated `activeColor` warnings in `notification_settings_sheet.dart`
- Fix deprecated `value` warning in `add_time_log_sheet.dart` and `add_task_sheet.dart`
- Dark mode consistency check
- Spacing and typography pass
- Empty states for all screens

---

## Data Models (key ones)

| Model | Primary Key | Notes |
|---|---|---|
| `DayPlan` | `date` (YYYY-MM-DD) | Contains list of `Block` objects |
| `Block` | `id` (UUID) | Task block with status, times, type |
| `KnowledgeBaseEntry` | `pageNumber` | FA page data, SRS fields |
| `RevisionItem` | `id` | Links to KB entry, tracks revision index |
| `TimeLogEntry` | `id` | Study session logs for streak/analytics |
| `FMGEEntry` | `id` | FMGE-specific study entries |

---

## Rules for AI Agents

- **Always** run `flutter analyze --no-fatal-infos` before committing
- **Always** commit with a descriptive message and push to `main`
- **Do NOT** rewrite `database_service.dart`, `app_provider.dart`, or any model files — they are stable
- Use `context.watch<AppProvider>()` in `build()` methods
- Use `context.read<AppProvider>()` in event handlers
- `AppProvider.loadAll()` is called once in `main()` — do not call it again
- No storage permissions needed — SQLite uses app-internal storage automatically
