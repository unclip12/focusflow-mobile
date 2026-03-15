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
   - Codex runs on **GPT-5.4, Medium** reasoning setting.

3. **Antigravity (UI overhaul layer — March 2026)**
   - Claude Opus 4.6 running via Antigravity used for the full Ultra-Premium iOS design system overhaul.
   - Handles large-scale multi-file visual redesigns (12+ screens, ~10,000+ lines).
   - Perplexity writes the phased redesign prompts, Arsh submits to Antigravity, reviews diffs, commits.

4. **Two AI models used:**
   - **GPT-5.4 via Codex** — Current primary. Complex logic, multi-file wiring, provider integration.
   - **Claude Opus 4.6 via Antigravity** — UI overhaul, design system application, large visual refactors.

5. **Testing** — Arsh tests on a real Android device via signed release APK (GitHub Actions CI). Bugs reported back to Perplexity, which reads the repo again and writes a new targeted fix prompt.

6. **Loop:** Plan (Perplexity) → Prompt → Codex/Antigravity executes → Review diff → Commit → CI builds signed APK → Test on device → Debug → Repeat.

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

## AI Agent Suite (.github/agents/)

Inspired by [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents), this repo includes a set of plain `.md` agent prompt files in `.github/agents/`. Paste them as system prompts in Claude/Gemini/GPT before a coding session to get project-specific expert responses.

| Agent File | Purpose |
|---|---|
| `MOBILE_APP_BUILDER.md` | Flutter expert knowing FocusFlow's exact stack (Drift, Provider, GoRouter, offline-first) |
| `UI_DESIGNER.md` | Liquid glass morphism design agent with FocusFlow color constants |
| `DEVOPS_AUTOMATOR.md` | GitHub Actions / Firebase deployment agent |
| `RAPID_PROTOTYPER.md` | Fast POC agent for new feature validation |
| `SECURITY_ENGINEER.md` | Firebase rules + auth security agent |
| `README.md` | Explains the agent workflow: Rapid Prototype → Build → UI Polish → Security Review → Deploy |

See [`.github/DEVELOPMENT.md`](.github/DEVELOPMENT.md) for full dev guide (stack, folder structure, batch workflow, color constants).

---

## Security

See [`.github/SECURITY.md`](.github/SECURITY.md) for the full security policy.

**Files that must NEVER be committed:**
- `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`
- `*.jks`, `*.keystore`, `key.properties`
- `.env`, `.env.*`
- `.cognetivy/`, `.antigravity/`, `.cursor/mcp.json`, `.claude/`
- `git_log.txt`

The `.gitignore` is fully hardened to block all of the above. Both repos were scanned for leaked secrets — **zero found, both repos are clean**.

---

## Tech Stack

- **Flutter** (stable 3.29)
- **Drift (SQLite)** — all data persisted offline, type-safe ORM
- **Provider** — `AppProvider` (all data/state) + `SettingsProvider` (theme/config)
- **GoRouter** — navigation
- **SrsService** — strict 12-revision spaced repetition algorithm
- **flutter_local_notifications + timezone** — routine reminders, prayer reminders, session alerts
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
│   ├── app_provider.dart         # Central state — all CRUD, Flow engine, Track Now, DayPlan sync,
│   │                             #   routine injection into DayPlan
│   └── settings_provider.dart    # Theme, dark mode, menu visibility/order
├── services/
│   ├── database_service.dart     # Drift SQLite layer
│   ├── srs_service.dart          # 12-step SRS algorithm
│   ├── backup_service.dart       # JSON backup/restore (writes to Documents/FocusFlow)
│   └── notification_service.dart # Local notifications: focus timer, revision, streak,
│                                 #   routine reminders (Asia/Kolkata timezone)
├── models/                       # DayPlan, Block, FlowActivity, DailyFlow, DailyTracker,
│                                 #   Routine, RoutineStep, RoutineLog, FAPage, UWorldTopic, etc.
├── screens/
│   ├── dashboard/                # Live data: streak, due revisions, today blocks, analytics
│   ├── today_plan/               # TodayPlanScreen, AddTaskSheet, TrackNowScreen,
│   │                             #   StudySessionPicker, StudyFlowScreen, FlowSessionScreen,
│   │                             #   RoutinesTab, RoutineEditorSheet
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
    ├── app_scaffold.dart         # Shared scaffold with aurora background + sidebar nav
    └── liquid_glass_card.dart    # Shared frosted glass card widget (Android-safe, no BackdropFilter)

.github/
├── agents/                       # AI agent system prompts (paste into Claude/Gemini/GPT)
│   ├── MOBILE_APP_BUILDER.md
│   ├── UI_DESIGNER.md
│   ├── DEVOPS_AUTOMATOR.md
│   ├── RAPID_PROTOTYPER.md
│   ├── SECURITY_ENGINEER.md
│   └── README.md
├── DEVELOPMENT.md                # Full dev guide: stack, folder structure, batch workflow
├── SECURITY.md                   # Security policy: files never to commit
└── ISSUE_TEMPLATE/
    ├── bug_report.md
    └── feature_request.md
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
- Commit: `f3f3726`

### Prompt 3 — Today Plan Task Edit + Swipe (Codex)
- Every FlowActivity and Block card opens an edit bottom sheet (Date, Start Time, End Time, Delete)
- Swipe-to-delete (Dismissible) on all eligible cards including tracker-created Blocks
- Edits/deletes on tracker Blocks affect DayPlan only, not DailyTracker
- Cross-date moves for both FlowActivity and Block

### Prompt 4 — Sync DayPlan Blocks Into Flow Activities (Codex)
- `AppProvider.syncFlowActivitiesFromDayPlan(date)` — single source of truth for Block → FlowActivity mapping
- Dedupes by block id, excludes break/virtual blocks, mirrors block status
- Called from: `startFlow()`, `AddTaskSheet`, tracker `_AddToTaskSheet`
- Ends with `notifyListeners()` for immediate UI rebuild

### Prompt 5 — Show Today's Tracker Tasks (Codex)
- Today's tracker tasks visible in Today Plan UI

### Prompt 6 — Fix Track Now Session Flow (Codex)
- Resume existing active session instead of pushing a fresh one
- Cancel (discard) + Stop & Save (complete) 2-button row
- On Stop & Save: marks linked DayPlan block or FlowActivity as DONE
- RevisionHub sync only when linked task has structured metadata (strict mode)

### Prompt 10 — Fix Study Queue Flow (Codex)
- FA picker: full DB-backed page list, no caps, queues exact selected pages
- UWorld picker: real topic selection, no truncation
- StudyFlowScreen queue mode: advances through items, marks each done

### Prompts 12A–12F — Bug Fixes + UWorld/FA Session Overhaul (Codex)
- Swipe-to-delete on tracker Blocks only removes from DayPlan (not DailyTracker)
- Pre-completed blocks sync as DONE into FlowActivity (not NOT_STARTED)
- Duplicate FlowActivity prevention on double sync (upsert pattern)
- UWorld subtopic partial completion — only marks explicitly completed topics as done
- Drag-to-reorder queue in StudySessionPicker (ReorderableListView)
- FA revision gate logic

### Prompt 13 — Full Day Plan Duplicate Fix (Codex)
- Removed second list builder rendering blocks twice in Full Day Plan tab
- Start/end time + duration now shown as subtitle on top cards only
- "Add Activity" button moved into Start Flow box area

### Prompt 14 — Start Study Session Box (Codex)
- "Start Study Session" box added next to "Start Flow" in Today Plan
- Both boxes equal size, same card style, side by side in a Row

### Prompt 17 — Routine Reminders + Recurrence + Expiry (Codex)
- `Routine` model extended with: `reminderTime`, `recurrence`, `recurrenceEndDate`, `reminderWeekday`
- All fields nullable — backward compatible with existing saved routines
- `RoutineEditorSheet`: reminder time picker, Daily/Weekly/Until Date segmented control
  - Weekly: single-select Mon–Sun chips (v1, single `reminderWeekday` stored)
  - Until Date: date picker stored as `YYYY-MM-DD`
  - Reminder "Off" clears all reminder fields
- `NotificationService`: `scheduleRoutineReminder()`, `cancelRoutineReminder()`, `rescheduleAllRoutineReminders()`
  - Daily: repeats with `DateTimeComponents.time`
  - Weekly: repeats with `DateTimeComponents.dayOfWeekAndTime`
  - Until Date: daily repeating, auto-cancelled on next app open after expiry
  - Prayer notification IDs (1000–1004) protected — not wiped by routine reschedule
- Expiry dialog shown from `TodayPlanScreen` post-frame for `until_date` routines past end date
  - "Update" opens editor prefilled, "Dismiss" skips
- Routine card shows reminder time (🔔 6:00 AM) + recurrence badge (Daily/Weekly/Until dd MMM)

### Prompt 17B — Auto-inject Routines into DayPlan + Timezone Fix (Codex)
- `AppProvider.injectRoutinesIntoDayPlan(date)` — reconciles routine-derived blocks in today's DayPlan
  - Eligible routines (with `reminderTime`) inject a `routine-{id}` Block automatically
  - Daily: injects every day; Weekly: only on matching weekday; Until Date: only while active
  - Existing block updated in place on routine edit (preserves runtime status/actual times)
  - Ineligible routine blocks (reminder removed, wrong weekday, expired) are removed from plan
  - No-op if date is not today; no-op if nothing changed (skips `upsertDayPlan`)
  - Block uses `actualNotes = 'source:routine'` as source marker (no new model field needed)
- Called from `loadAll()` and `upsertRoutine()` automatically
- `NotificationService.init()`: added `tz.setLocalLocation(tz.getLocation('Asia/Kolkata'))` — fixes notifications firing at UTC instead of IST

### Prompt 18 — Add FA Pages + UWorld Topics to Library (Codex)
- FA Pages add sheet: page number, subject, system, title, notes → `app.upsertFAPage()`
- UWorld Topics add sheet: topic name, system, total questions → `app.addUWorldTopic()`
- Validation: required fields, no duplicate FA page numbers, green/red SnackBar feedback
- Existing KB Entry sheet unchanged

### Prompt 19 — Dashboard Analytics (Codex)
- 4 analytics cards added to Dashboard: Today's Time Breakdown, Planned vs Actual this week, Top 5 Activities, Daily Avg Study Time (30d)
- All client-side from existing `timeLogs` + `dayPlans` — no new dependencies, no schema changes
- All cards use app theme colors (dark mode safe), graceful empty states

### .github Infrastructure (March 12, 2026)
- Added `.github/agents/` AI agent suite (5 agents + README)
- Added `.github/DEVELOPMENT.md`, `.github/SECURITY.md`, issue templates
- `.gitignore` fully hardened, repo scanned — zero secrets found

### Android Glass Card Fix + Dashboard Restore (Codex, March 14, 2026)
- `liquid_glass_card.dart`: replaced `BackdropFilter` with Android-safe painted frosted glass
  - `BackdropFilter` commented out (preserved for future iOS use)
  - Dark fill opacity increased to `0.92`, light fill to `0.88`
  - Stronger inner gradient overlay simulates frost/depth without GPU blur dependency
  - All shimmer, ripple, tap-scale, border, glow shadow behavior preserved
- `dashboard_screen.dart`: restored all 11 dashboard sections in correct order
  - Greeting, Exam Countdown, Your Pace, Time Budget, Goals, Streak
  - Analytics, FA Tracker, Revision Queue, Last 7 Days, Time by Subject
  - Time Budget shows only Sleep / Study / Free segments
  - Goals shows exactly FA Pages / Anki / Sketchy Micro / Revision
  - All 5 restored sections use private helpers, no public API changes

### CI/CD — Signed Release APK (March 14, 2026)
- Generated Android release keystore (`focusflow.jks`) stored securely outside repo
- Added 4 GitHub Actions secrets: `KEYSTORE_BASE64`, `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
- Updated `flutter_check.yml` to build and upload a signed release APK on every push to `main`
- Updated `android/app/build.gradle` with `signingConfigs.release` block reading from env vars
- Artifact: `focusflow-signed-release-apk` available for 7 days after each CI run

### Ultra-Premium iOS Design System Overhaul (Antigravity / Claude Opus 4.6, March 14–15, 2026)
- Full app visual redesign based on Figma Ultra-Premium iOS reference
- Design tokens applied globally:
  - Background: `#0E0E1A` (dark) / `#F8F7FF` (light)
  - Accent: `#6366F1 → #818CF8 → #8B5CF6 → #A78BFA`
  - Glass card: `rgba(255,255,255,0.08)` + indigo border
  - Font: Inter, weights 400–800
  - Animations: spring physics, shimmer sweeps, tap ripples
- Phases completed:
  - **Phase 1**: `app_scaffold.dart`, `main_shell.dart`, `app_theme.dart` — aurora background on all screens, frosted glass bottom nav, dark theme tokens
  - **Phase 2**: `settings_screen.dart` — LiquidGlassCard sections, glass toggles, glass +/- steppers, appearance picker
  - **Phase 3**: `today_plan_screen.dart` + related cards — glass prayer/study blocks, indigo accents
  - **Phase 4**: `analytics_screen.dart` — glass charts, indigo palette, subject radial donuts, heatmap
  - **Phase 5**: `revision_hub_screen.dart`, `time_log_screen.dart`, `import_screen.dart`, `fa_logger_screen.dart`, tracker screens, `knowledge_base_screen.dart`, `backup_screen.dart`, `splash_screen.dart`
- All functionality, data models, providers, and navigation routes unchanged
- Both dark and light mode supported throughout

---

## 🔴 Pending / Next Up

### Phase 6 — Dashboard Visual Audit (Antigravity)
**Status: Pending**
Audit and fix dashboard visual inconsistencies after the full app redesign.
Verify glass card opacity, border colors, aurora rendering in both light/dark modes.

### Prompt 11 — Backup Screen UX Fix
**Status: Deferred — will do later | Reasoning: High | Files: backup_service.dart, backup_screen.dart**

Add `_isLoading` state + `CircularProgressIndicator`, wrap all calls in `try/catch`,
show SnackBar on success/error, call `AppProvider.loadAll()` after restore.

---

## 📱 Device Test Checklists

> Run these on a real Android device after each commit. Download signed release APK from GitHub Actions artifacts. Mark ✅ pass or ❌ fail and report fails to Perplexity.

---

### After Glass Card Fix + Dashboard Restore (March 14, 2026)

- [ ] Dashboard loads without crash (no `basic.dart` assertion error)
- [ ] All 11 dashboard sections visible and scrollable
- [ ] Time Budget shows Sleep / Study / Free only (no Prayer segment)
- [ ] Goals shows FA Pages / Anki / Sketchy Micro / Revision only
- [ ] Glass cards look frosted/opaque in dark mode (not flat/transparent)
- [ ] Glass cards look frosted in light mode
- [ ] Shimmer animation visible sweeping across cards
- [ ] Tap ripple effect works on cards
- [ ] FA Tracker card taps → navigates to tracker screen
- [ ] Revision Queue card shows due count and top items

### After Ultra-Premium Redesign (March 14–15, 2026)

- [ ] Every screen has aurora background (`#0E0E1A` dark / `#F8F7FF` light)
- [ ] Bottom nav: frosted glass background, indigo glow dot on active tab, smooth icon scale animation
- [ ] Settings: glass card sections, glass toggles, glass +/- steppers
- [ ] Today's Plan: glass prayer blocks with dashed indigo border, gradient study blocks
- [ ] Analytics: indigo charts, subject radial donuts, study heatmap
- [ ] Revision Hub: glass cards, progress bar, mode toggle pill
- [ ] All existing functionality works (no broken taps, no missing data)
- [ ] No overflow errors on any screen
- [ ] Light mode: frosted-light design on all screens
- [ ] Splash screen: aurora background, animated indigo glow logo

### After Prompt 17 — Routine Reminders

- [ ] Open a routine → Editor sheet shows Reminder toggle, time picker, recurrence options
- [ ] Set Daily reminder at 8:00 AM → card shows "🔔 8:00 AM" + "Daily" badge
- [ ] Set Weekly reminder (Friday) → card shows "🔔 8:00 AM" + "Weekly" badge
- [ ] Set Until Date reminder (pick a date 3 days ahead) → card shows date badge
- [ ] Turn Reminder Off → no bell icon or badge shown on card
- [ ] Force-close app and reopen → reminder settings still saved correctly
- [ ] Set a reminder for 1 min from now → notification fires at correct IST time (not UTC)
- [ ] `until_date` routine past its end date → expiry dialog shown on Today Plan open
  - Tap "Update" → editor opens prefilled
  - Tap "Dismiss" → dialog gone, no crash
- [ ] Prayer routines still fire at correct times (not broken by routine notification reschedule)

### After Prompt 17B — Auto-inject into DayPlan

- [ ] Routine with Daily reminder → block `routine-{id}` appears in today's Full Day Plan at correct time
- [ ] Block shows correct title (icon + name), planned start time, and duration
- [ ] Force-close and reopen → block is NOT duplicated in the plan
- [ ] Edit routine's reminder time → existing block in plan updates time immediately (no duplicate)
- [ ] Edit routine's name → block title updates immediately
- [ ] Weekly routine → block only appears on matching weekday, not other days
- [ ] `until_date` routine on valid day → block injects; on expired date → block removed from plan
- [ ] Remove reminder from routine → `routine-{id}` block removed from today's plan
- [ ] Manually complete the routine block in plan → status stays DONE after re-inject (not reset)
- [ ] Open tomorrow's plan → routine block NOT injected there (today only)
- [ ] Notification at set time fires at correct IST time (timezone fix verified)

### After Prompt 18 — Add FA Pages + UWorld Topics

- [ ] Open FA tracker screen → "+" button visible
- [ ] Tap "+" → bottom sheet opens with page number, subject, system, title, notes fields
- [ ] Save with empty page number → sheet does NOT close, shows validation error
- [ ] Save with valid page number → sheet closes, green SnackBar, page appears in list
- [ ] Try saving same page number again → red SnackBar "Page already exists", no duplicate added
- [ ] Force-close and reopen → newly added FA page still in list (persisted to DB)
- [ ] Open UWorld tracker screen → "+" button visible
- [ ] Tap "+" → bottom sheet opens with topic name, system, total questions fields
- [ ] Save with empty topic name → validation error shown
- [ ] Save valid topic → sheet closes, green SnackBar, topic appears in UWorld list
- [ ] Force-close and reopen → newly added UWorld topic still in list
- [ ] KnowledgeBaseScreen existing "Add KB Entry" sheet → unchanged and still works

### After Prompt 19 — Dashboard Analytics

- [ ] Open Dashboard → new "Analytics" section visible below existing stats
- [ ] Card 1 (Today's Time Breakdown): shows categories with time if logs exist; shows "No activity logged today" if none
- [ ] Card 2 (Planned vs Actual): shows rows for each day Mon–today with planned and actual minutes
- [ ] Card 2: days with no blocks show 0 or are skipped gracefully (no crash)
- [ ] Card 3 (Top 5 Activities): shows ranked list with duration; shows empty state if no logs this week
- [ ] Card 4 (Daily Average): shows formatted "Avg X h Y m / study day"; no divide-by-zero crash if 0 study days
- [ ] All cards use app theme colors (no hardcoded white/black that breaks dark mode)
- [ ] Scroll Dashboard to bottom without layout overflow or jank

### After Prompt 11 — Backup Screen Fix

- [ ] Tap "Backup Now" → loading spinner shown immediately (no black screen)
- [ ] Backup completes → spinner dismissed, green SnackBar with file path
- [ ] Backup with no write access (simulate) → red SnackBar with error message, no freeze
- [ ] Tap "Restore" → file picker opens, pick a valid backup file
- [ ] Restore completes → spinner dismissed, green SnackBar, app data reloaded
- [ ] Restore with corrupted file → red SnackBar with error, no crash, app still usable
- [ ] Navigate away during backup → no memory leak / setState after dispose error in console

---

## Rules for AI Agents Working on This Repo

- **Always `git pull origin main` first** — especially if Perplexity made a direct commit
- **Always read the relevant files before writing anything**
- **Always** run `flutter analyze` before committing — 0 errors required
- **Always** commit with a descriptive message and push to `main`
- **Do NOT** rewrite `database_service.dart` or model files unless explicitly instructed
- **Do NOT** use SAF URIs (`content://`) with `dart:io File()` — use `getApplicationDocumentsDirectory()` instead
- **Do NOT** commit `google-services.json`, `firebase_options.dart`, `*.jks`, `.env`, or any secrets
- **Do NOT** use `BackdropFilter` for glass effects — Android does not blur `CustomPaint` backgrounds reliably. Use high-opacity fill + gradient overlay instead (see `liquid_glass_card.dart`)
- Use `context.watch<AppProvider>()` in `build()` methods
- Use `context.read<AppProvider>()` in event handlers
- `AppProvider.loadAll()` is called once in `main.dart` — do not call it elsewhere
- No storage permissions needed — Drift/SQLite uses app-internal storage automatically
- GoRouter is already configured — add new routes there, do not use `Navigator.pushNamed`
- Backup files always saved to `Documents/FocusFlow` — never use user-picked SAF folder as a `dart:io` path
- Notifications always use `Asia/Kolkata` timezone — `tz.setLocalLocation(tz.getLocation('Asia/Kolkata'))` is set in `NotificationService.init()`
- Routine-derived DayPlan blocks use id prefix `routine-{routineId}` and `actualNotes = 'source:routine'`
- Signed release APK is built automatically by CI on every push to `main` — download from GitHub Actions artifacts (`focusflow-signed-release-apk`)

---

## Data Models (key ones)

| Model | Primary Key | Notes |
|---|---|---|
| `DayPlan` | `date` (YYYY-MM-DD) | Contains list of `Block` objects |
| `Block` | `id` (UUID) | Task block with status, times, type, actualDuration. Routine-injected blocks use id `routine-{routineId}` |
| `DailyFlow` | `date` | Contains list of `FlowActivity` objects |
| `FlowActivity` | `id` | Linked to Block via `linkedTaskIds`, has status/times |
| `DailyTracker` | `date` | Tracker session for the day |
| `Routine` | `id` | User routine with steps, optional reminder time, recurrence, end date |
| `RoutineLog` | `id` | Execution log for a completed routine run |
| `FAPage` | `pageNum` (int) | First Aid page data, SRS fields, subject/system |
| `RevisionItem` | `id` | SRS revision record per content item |
| `TimeLogEntry` | `id` | Study session logs for streak/analytics |
| `UWorldSession` | `id` | Log of a completed UWorld session (done/correct counts) |
| `UWorldTopic` | `id` (int) | UWorld topic with total/done/correct question counts |
