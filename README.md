# FocusFlow Mobile

Premium Flutter study app for USMLE Step 1 & FMGE students. Offline-first, SQLite + Drift persistence, exam-aware planning, SRS revision system, Flow session engine, Daily Tracker.

---

## How This App Is Built — The Workflow

This app is built entirely using **AI-assisted development**. No manual code writing. The human (owner: Arsh) directs, the AI codes.

### Current Workflow (as of March 2026)

1. **Perplexity (planning layer)**
   - Arsh describes features, bugs, and design decisions to Perplexity.
   - Perplexity reads the GitHub repo live using GitHub MCP tools, understands current state, diagnoses bugs, writes precise prompts for coding agents.
   - Perplexity also directly commits small fixes (e.g. `backup_service.dart` SAF URI crash fix) to `main` via MCP.

2. **Codex (primary execution layer — current)**
   - Arsh pastes prompts into **Codex** (OpenAI), which runs against the local repo in a sandboxed environment.
   - Codex reads all relevant files, writes/edits code, runs `flutter analyze`, fixes errors, then shows a diff.
   - Arsh reviews the diff, clicks **Commit** to push to `main`.
   - Codex sometimes asks clarifying questions before planning — Arsh answers, Perplexity helps interpret.
   - Codex runs on **GPT-5.4, High** setting.

3. **Antigravity (previous execution layer)**
   - Used in earlier batches (A–C). Claude Opus and Gemini ran directly against the local repo.
   - Still available as fallback for complex multi-file logic if needed.

4. **Two AI models used:**
   - **GPT-5.4 via Codex** — Current primary. Complex logic, multi-file wiring, provider integration.
   - **Claude Opus / Gemini via Antigravity** — Used in earlier batches. Claude for logic, Gemini for UI polish.

5. **Testing** — Arsh tests on a real Android device via `flutter run`. Bugs reported back to Perplexity, which reads the repo again and writes a new targeted fix prompt.

6. **Loop:** Plan (Perplexity) → Prompt → Codex executes → Review diff → Commit → Test → Debug → Repeat.

### Why This Works
- Perplexity reads the live repo via GitHub MCP before every prompt — context always fresh
- Codex has full filesystem access in a sandboxed local clone
- Every change is committed with a descriptive message — history is traceable
- `flutter analyze` with 0 errors is mandatory before every commit
- Perplexity approves Codex's plan before execution ("Approved. Proceed.")

### Prompt Review Process
When Codex shows a plan before executing, Arsh shares it with Perplexity. Perplexity checks it and replies with either:
- `Approved. Proceed.` — paste this directly into Codex
- Corrections/additions — paste the corrected version into Codex

---

## Tech Stack

- **Flutter** (stable 3.29)
- **Drift (SQLite)** — all data persisted offline, type-safe ORM
- **Provider** — `AppProvider` (all data/state) + `SettingsProvider` (theme/config)
- **GoRouter** — navigation
- **SrsService** — strict 12-revision spaced repetition algorithm
- **path_provider** — internal file storage for backups
- **file_picker + share_plus** — backup export/restore
- **shared_preferences** — backup settings, UI prefs

---

## Architecture

```
lib/
├── main.dart                     # Entry point — init Drift DB, AppProvider.loadAll()
├── app.dart                      # MaterialApp.router + GoRouter + theme
├── providers/
│   ├── app_provider.dart         # Central state — all CRUD, Flow engine, Track Now, DayPlan sync
│   └── settings_provider.dart    # Theme, dark mode, menu visibility/order
├── services/
│   ├── database_service.dart     # Drift SQLite layer
│   ├── srs_service.dart          # 12-step SRS algorithm
│   └── backup_service.dart       # JSON backup/restore (writes to Documents/FocusFlow)
├── models/                       # DayPlan, Block, FlowActivity, DailyFlow, DailyTracker, etc.
├── screens/
│   ├── dashboard/                # Live data: streak, due revisions, today blocks
│   ├── today_plan/               # TodayPlanScreen, AddTaskSheet, TrackNowScreen,
│   │                             #   StudySessionPicker, StudyFlowScreen, FlowSessionScreen
│   ├── tracker/                  # TrackerScreen + _AddToTaskSheet
│   ├── session/                  # SessionScreen (single-block timer)
│   ├── revision_hub/             # RevisionCard, due/upcoming SRS queue
│   ├── knowledge_base/           # FA/Sketchy/Pathoma/UWorld content
│   ├── backup/                   # BackupScreen, restore_confirm_dialog
│   ├── mentor/                   # AI Mentor JSON importer
│   └── settings/                 # Settings screen with backup & study plan config
├── utils/
│   ├── constants.dart            # kDefaultMenuOrder, kBodySystems, kFocusQuotes, etc.
│   └── focus_batch_calculator.dart
└── widgets/
    └── app_scaffold.dart         # Shared scaffold with sidebar nav
```

---

## ✅ Completed (committed to main)

### Batch A — Core Foundation
- All screens wired, AppScaffold navigation, dashboard empty state
- Strict 12-revision SRS algorithm, AI Mentor JSON importer → Knowledge Base

### Batch B — Exam-Aware Task Planner
- USMLE + FMGE task planner, focus batch calculator, menu reorder

### Batch X — Critical Bug Fixes
- Data persistence fix, Android back navigation, date picker
- Task save without times, exit dialog on dashboard
- `AppProvider.loadAll()` on startup — data survives force close

### Batch C — Session Timer + FA Logger
- SessionScreen (countdown timer, 100+ quotes, pause/end), SessionCompleteSheet
- FA Logger redesign, session completion saves to DB

### Batch D — Dashboard Live Data
- Dashboard wired to real AppProvider data (streak, due revisions, subject breakdown)

### Batch E — Revision Hub
- Due/upcoming SRS queue, Mark Revised, overdue highlighting

### Migration: Sqflite → Drift
- Full DB migration to Drift ORM, type-safe queries, no schema renames

### Today Plan — Full Feature Build (Codex, March 2026)
- Full Day Plan tab, Resume tab, Upcoming tab
- FlowActivityCard, BlockCard, Today Plan UI overhaul
- DailyTracker integration, TrackerScreen `_AddToTaskSheet`
- Flow session engine (`FlowSessionScreen`)
- Track Now screen (`TrackNowScreen`)
- StudySessionPicker + StudyFlowScreen (FA/UWorld queue)

### Prompt 1 — Backup Black Screen Fix (Perplexity direct commit)
- `backup_service.dart`: removed SAF URI path usage — `dart:io File()` cannot write to `content://` URIs on Android
- Always writes to `Documents/FocusFlow` (internal, always writable)
- User-selected folder URI stored for display only
- Commit: `f3f3726`

### Prompt 3 — Today Plan Task Edit + Swipe (Codex)
- Every FlowActivity and Block card opens an edit bottom sheet (Date, Start Time, End Time, Delete)
- Swipe-to-delete (Dismissible) on all eligible cards including tracker-created Blocks
- Edits/deletes on tracker Blocks affect DayPlan only, not DailyTracker
- Cross-date moves for both FlowActivity and Block

### Prompt 4 — Sync DayPlan Blocks Into Flow Activities (Codex)
- `AppProvider.syncFlowActivitiesFromDayPlan(date)` — single source of truth for Block → FlowActivity mapping
- Dedupes by block id, excludes break/virtual blocks, mirrors block status
- Called from: `startFlow()`, `AddTaskSheet` after upsertDayPlan, tracker `_AddToTaskSheet` after upsertDayPlan
- Ends with `notifyListeners()` for immediate UI rebuild
- 3 files: `app_provider.dart` (+95 -12), `add_task_sheet.dart` (+11 -26), `tracker_screen.dart` (+6 -5)

### Prompt 5 — Show Today's Tracker Tasks (Codex)
- Today's tracker tasks visible in Today Plan UI

### Prompt 6 — Fix Track Now Session Flow (Codex)
- Resume existing active session instead of pushing a fresh one
- Top-right `+` always opens AddTaskSheet; lower action opens today-only existing task picker
- Tracked task name shown prominently above timer
- Cancel button (discard) + Stop & Save (complete) in 2-button row
- On Stop & Save: marks linked DayPlan block or FlowActivity as DONE
- RevisionHub/library sync only when linked task has structured metadata (strict mode)

### Prompt 10 — Fix Study Queue Flow (Codex)
- FA picker: full DB-backed page list, no 20/50 cap, queues exact selected pages
- UWorld picker: real topic selection from full `app.uworldTopics`, no system-only cap
- Start button always navigates to StudyFlowScreen with queue snapshot
- StudyFlowScreen queue mode: advances through selected items, marks each done on completion

---

## 🔴 Known Issues / Next Up

- **Prompt 3 (Task Edit + Swipe)** — Codex plan approved, may still be in progress or pending test
- Run `flutter analyze` and test on device after each Codex commit before starting next prompt
- Always `git pull origin main` in Codex terminal before starting a new prompt (to get latest committed changes)

---

## Rules for AI Agents Working on This Repo

- **Always `git pull origin main` first** — especially if Perplexity made a direct commit
- **Always read the relevant files before writing anything**
- **Always** run `flutter analyze` before committing — 0 errors required
- **Always** commit with a descriptive message and push to `main`
- **Do NOT** rewrite `database_service.dart` or model files unless explicitly instructed
- **Do NOT** use SAF URIs (`content://`) with `dart:io File()` — use `getApplicationDocumentsDirectory()` instead
- Use `context.watch<AppProvider>()` in `build()` methods
- Use `context.read<AppProvider>()` in event handlers
- `AppProvider.loadAll()` is called once in `main.dart` — do not call it elsewhere
- No storage permissions needed — Drift/SQLite uses app-internal storage automatically
- GoRouter is already configured — add new routes there, do not use `Navigator.pushNamed`
- Backup files always saved to `Documents/FocusFlow` — never use user-picked SAF folder as a `dart:io` path

---

## Data Models (key ones)

| Model | Primary Key | Notes |
|---|---|---|
| `DayPlan` | `date` (YYYY-MM-DD) | Contains list of `Block` objects |
| `Block` | `id` (UUID) | Task block with status, times, type, actualDuration |
| `DailyFlow` | `date` | Contains list of `FlowActivity` objects |
| `FlowActivity` | `id` | Linked to Block via `linkedTaskIds`, has status/times |
| `DailyTracker` | `date` | Tracker session for the day |
| `FAPage` | `pageNumber` | First Aid page data, SRS fields |
| `RevisionItem` | `id` | SRS revision record per content item |
| `TimeLogEntry` | `id` | Study session logs for streak/analytics |
| `UWorldSession` | `id` | UWorld topic progress |
