# FocusFlow Mobile

Premium Flutter study app for USMLE Step 1 & FMGE students. Offline-first, SQLite persistence, exam-aware planning, SRS revision system.

---

## How This App Is Built — The Workflow

This app is built entirely using **AI-assisted development via Antigravity** — a tool that lets you run AI models (Claude Opus, Gemini) directly inside a cloned local repository. No manual code writing. The human (owner) directs, the AI codes.

### The Exact Process

1. **Perplexity (planning layer)** — The owner discusses features, bugs, and design decisions with Perplexity. Perplexity reads the GitHub repo using MCP tools, understands the current state, diagnoses bugs, and writes precise prompts for the AI coding agents.

2. **Antigravity (execution layer)** — The owner pastes those prompts into Antigravity, which runs the AI model against the actual local repo files. The AI reads every relevant file, writes/edits code, runs `flutter analyze`, fixes any errors, then commits and pushes to `main`.

3. **Two AI models are used depending on task type:**
   - **Claude Opus (via Antigravity)** — Used for complex logic: SRS algorithm, session flow, data wiring, provider integration, navigation fixes. Claude is better at reading large codebases and getting multi-file logic right.
   - **Gemini (via Antigravity)** — Used for UI work, polish, theme fixes, deprecation warnings, empty states. Gemini is faster for visual/styling tasks.

4. **Testing** — Owner tests the app on a real Android device (via `flutter run`). Bugs are reported back to Perplexity, which reads the repo again and writes a new targeted fix prompt.

5. **This loop repeats** — Plan → Prompt → Antigravity executes → Test → Debug → Repeat.

### Why This Works
- Perplexity reads the live repo via GitHub MCP before every prompt, so context is always fresh
- Antigravity gives the AI model full filesystem access to read/edit files
- Every change is committed with a descriptive message so history is traceable
- `flutter analyze --no-fatal-infos` is mandatory before every commit — no broken code ever reaches main

### Prompt Format Used
Every prompt sent to Antigravity follows this structure:
```
[Context: what screen/file this is about]
[What currently exists and what is broken]
[Exact steps the AI must do — numbered]
[flutter analyze --no-fatal-infos → git commit -m "..." → git push origin main]
```

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

### Batch A — Core Foundation (Claude Opus via Antigravity)
- `1864df2` — All screens wired, AppScaffold navigation, dashboard empty state
- `939110b` — Strict 12-revision SRS algorithm, AI Mentor JSON importer → Knowledge Base

### Batch B — Exam-Aware Task Planner (Claude Opus via Antigravity)
- `58b313a` — USMLE + FMGE task planner, focus batch calculator, menu reorder
- `cea1551` — TextFormField fix (flutter analyze clean)

### Batch X — Critical Bug Fixes (Claude Opus via Antigravity)
- `063ccde` — Data persistence fix, Android back navigation, date picker on Today's Plan, removed Generate Plan button
- `b88a40f` — Task save without times, exit dialog on dashboard back press
- `19b1f65` — **AppProvider.loadAll() called on startup** (data now survives force close)

### Batch C — Session Timer + FA Logger (Claude Opus via Antigravity)
- `3f2da99` — SessionScreen (countdown timer, 100+ motivational quotes, pause/end), SessionCompleteSheet, FA Logger redesign
- `203c7d4` — Wired SessionScreen navigation from Today's Plan block start

---

## 🔴 Current Bug (fix this first in new session)

**Session completion does not save data anywhere.**

The `SessionScreen` and `SessionCompleteSheet` exist and the timer works. But when Save & Complete is tapped, nothing is written to the database. Also the Today's Plan page does not update block status to done.

**How this bug was found:** Owner tested on device — tapped Start on a block, session screen opened with timer running correctly. Tapped End Session → completion sheet appeared. Tapped Save & Complete → nothing happened, block still showed as not started.

**Root cause (diagnosed by Perplexity reading repo):** `SessionCompleteSheet` has no calls to `app.upsertDayPlan()` or `app.upsertKBEntry()`. The UI exists but the save logic was never wired.

**Fix prompt for Antigravity (Claude Opus):**
```
Read session_complete_sheet.dart fully.
The Save & Complete button currently does nothing useful.
Fix it so that when Save & Complete is tapped:
1. Mark the block as done in DayPlan via context.read<AppProvider>().upsertDayPlan()
2. For FA Pages blocks (block.type == BlockType.revisionFa):
   - For each page studied, call upsertKBEntry() with updated
     lastStudiedAt = DateTime.now().toIso8601String()
     completionPercent = value from slider
     nextRevisionAt = SrsService.calculateNextRevision(entry.revisionIndex)
   - Create a RevisionItem via upsertRevisionItem() for each page
3. After saving, pop back to Today's Plan:
   Navigator.of(context).pop(); // pop sheet
   Navigator.of(context).pop(); // pop session screen
4. Also fix FA Logger FAB save to call upsertKBEntry() + create RevisionItem
flutter analyze --no-fatal-infos → commit → push
```

---

## ⏳ Remaining Batches

### Batch D — Dashboard Live Data (Gemini via Antigravity)
Replace all empty/mock data on the dashboard with real AppProvider data:
- Today's blocks list with completion status rings
- Due revisions count: KB entries where `nextRevisionAt <= DateTime.now()`
- Current streak: count consecutive days with at least one TimeLogEntry
- Subject breakdown: pie/bar from timeLogs grouped by subject
- Recent activity heatmap (last 30 days)

### Batch E — Revision Hub (Claude Opus via Antigravity)
- List all KB entries where `nextRevisionAt <= now` (due)
- Show SRS countdown for future entries ("Due in 3 days")
- "Mark Revised" button → calls `SrsService.calculateNextRevision()`, increments `revisionIndex`, saves via `upsertKBEntry()`
- Overdue entries highlighted in red
- Sort: overdue first, then soonest due

### Batch F — Polish & Cleanup (Gemini via Antigravity)
- Fix all deprecated `activeColor`, `value`, `background` warnings
- Dark mode consistency check across all screens
- Spacing and typography pass
- Empty states with illustration + CTA for all screens
- `flutter analyze --no-fatal-infos` must exit 0 with zero warnings

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

## Rules for AI Agents Working on This Repo

- **Always read the relevant files before writing anything**
- **Always** run `flutter analyze --no-fatal-infos` before committing — fix ALL warnings, not just errors
- **Always** commit with a descriptive message and push to `main`
- **Do NOT** rewrite `database_service.dart`, `app_provider.dart`, or any model files — they are stable and correct
- Use `context.watch<AppProvider>()` in `build()` methods
- Use `context.read<AppProvider>()` in event handlers and callbacks
- `AppProvider.loadAll()` is called once in `main.dart` — do not call it anywhere else
- No storage permissions needed — SQLite uses app-internal storage automatically (no AndroidManifest changes needed)
- GoRouter is already configured — add new routes there if needed, do not use `Navigator.pushNamed`
