# FocusFlow Mobile — Session Handoff & Test Checklist

> **For new AI chat sessions (Perplexity):**
> Read this file first. It tells you exactly what was built, what to test, and what prompt to send Codex when something is broken.

---

## How to Use This File

Arsh will start a new chat and say something like:
> “Continuing FocusFlow. Here are my test results: 1✔, 2✔, 3✘, 4✔...”

You (Perplexity) should:
1. Cross-reference his numbers against the checklist below
2. For every ✘ item, read the relevant repo files via GitHub MCP
3. Write a targeted Codex fix prompt using the format at the bottom
4. When Codex shows a plan, approve it or correct it before Arsh pastes it back

---

## Workflow Reminder
- **Perplexity** = planning, reading repo, writing/approving prompts
- **Codex (GPT-5.4 High)** = execution, edits files, runs `flutter analyze`, shows diff
- **Arsh** = reviews diff → clicks Commit → tests on Android device
- Before every Codex session: run `git pull origin main` in Codex terminal
- Perplexity can also directly commit small fixes via GitHub MCP (like the backup SAF fix)

---

## ✅ Test Checklist — Report results as numbered list

### Backup (Prompt 1)
1. Settings → Backup Now — does NOT go black screen, shows success snackbar
2. Settings → Backup Now — backup file appears in Documents/FocusFlow on device
3. Settings → Restore from Backup — file picker opens and restores correctly

### Today Plan — Task Edit + Swipe (Prompt 3)
4. Resume tab: tap a FlowActivity card — edit bottom sheet opens (Date / Start Time / End Time / Delete)
5. Resume tab: swipe a FlowActivity card — deletes it, list rebuilds
6. Upcoming tab: tap a FlowActivity card — edit bottom sheet opens
7. Upcoming tab: swipe a FlowActivity card — deletes it
8. Full Day Plan tab: tap a FlowActivity card — edit bottom sheet opens
9. Full Day Plan tab: swipe a FlowActivity card — deletes it
10. Full Day Plan tab: tap a Block (tracker-created) card — edit bottom sheet opens
11. Full Day Plan tab: swipe a Block card — deletes from DayPlan only, NOT from DailyTracker
12. Edit date on any card — item moves to target date, disappears from current date

### Sync DayPlan Blocks Into Flow (Prompt 4)
13. Add a task via AddTaskSheet — immediately visible in Full Day Plan AND as FlowActivity
14. Add tracker items via Tracker → Add to Task Sheet — blocks appear in Full Day Plan
15. After tracker add — matching FlowActivity rows exist without hot reload
16. Tap Start Flow on a day with existing blocks but no flow entries — blocks are synced before session starts
17. Break blocks and virtual prayer blocks do NOT appear as FlowActivity items
18. A pre-completed block syncs as a DONE FlowActivity (not NOT_STARTED)
19. No duplicate FlowActivity items created if sync runs twice

### Track Now (Prompt 6)
20. Tap Track Now with no active session — fresh screen opens
21. Tap Track Now with active session already running — resumes existing session (no second TRACK_NOW created)
22. In tracking mode: top-right `+` opens AddTaskSheet
23. In tracking mode: lower secondary action shows today’s existing tasks picker
24. Tracked task name visible prominently above timer
25. Cancel button — discards session, saves nothing, pops screen
26. Stop & Save — completes TrackNow activity AND marks linked DayPlan block as DONE
27. Stop & Save on task with NO library metadata — saves fine, no crash, no revision mutation

### Study Queue / Study Flow (Prompt 10)
28. Start Study Session — FA page list shows ALL pages (not capped at 20 or 50)
29. Start Study Session — UWorld topics list shows ALL topics from DB
30. Select FA pages — queue card shows exact selected page range
31. Select UWorld topics — queue card shows exact selected topics + question total
32. Start with FA-only queue — session opens and advances through selected pages
33. Start with UWorld-only queue — session opens and advances through selected topics
34. Start with mixed FA + UWorld queue — session advances through both in order
35. Completing FA task marks those pages as read in DB
36. Completing UWorld task updates topic progress in DB

---

## Fix Prompt Template (for Codex)

When something is broken, Perplexity will:
1. Read the relevant file(s) from the repo via GitHub MCP
2. Identify the exact bug
3. Write a prompt in this format:

```
[FILE: lib/path/to/file.dart]

Context: [what this screen/feature does]

Bug: [exact description of what’s wrong]

Fix:
1. [Exact step]
2. [Exact step]
3. [Exact step]

Do NOT change any other files.
Run flutter analyze — must pass with 0 errors before committing.
```

---

## Prompt History & What Each One Did

### Prompt 1 — Backup Black Screen Fix
**File:** `lib/services/backup_service.dart`
**Bug:** `saveBackup()` passed SAF URI (`content://...`) to `dart:io File()` — crashes on Android silently, causes black screen
**Fix:** `getBackupFolder()` now always returns `Documents/FocusFlow` path. SAF URI stored for display only.
**Status:** ✅ Committed by Perplexity directly (commit `f3f3726`)

### Prompt 3 — Today Plan Task Edit + Swipe
**Files:** `lib/screens/today_plan/today_plan_screen.dart`
**What it does:**
- Every FlowActivity + Block card in Resume/Upcoming/Full Day Plan opens edit bottom sheet on tap
- Swipe-to-delete (Dismissible) on all eligible cards
- Edit actions: Date, Start Time, End Time, Delete
- Tracker-created block edits affect DayPlan only, NOT DailyTracker
- Cross-date moves for both FlowActivity and Block
**Status:** ✅ Committed via Codex

### Prompt 4 — Sync DayPlan Blocks Into Flow
**Files:** `lib/providers/app_provider.dart`, `lib/screens/today_plan/add_task_sheet.dart`, `lib/screens/tracker/tracker_screen.dart`
**What it does:**
- New method: `AppProvider.syncFlowActivitiesFromDayPlan(date)`
- Converts eligible DayPlan blocks → FlowActivity (deduped, excludes break/virtual)
- Maps: id=`task-{block.id}`, label=block.title, status mirrors block status
- Called from: `startFlow()`, AddTaskSheet after upsertDayPlan, tracker after upsertDayPlan
- Ends with `notifyListeners()` for immediate rebuild
**Status:** ✅ Committed via Codex (+112/-43 total)

### Prompt 5 — Show Today’s Tracker Tasks
**What it does:** Today’s tracker tasks visible in Today Plan UI
**Status:** ✅ Committed via Codex (+41/-23)

### Prompt 6 — Fix Track Now Session Flow
**Files:** `lib/screens/today_plan/track_now_screen.dart`, `lib/screens/today_plan/today_plan_screen.dart`, `lib/providers/app_provider.dart`
**What it does:**
- Resume existing active TRACK_NOW session instead of creating duplicate
- Cancel (discard, no save) + Stop & Save (complete) 2-button row
- Tracked task name shown prominently above timer
- Top-right `+` = AddTaskSheet always; lower action = today-only existing task picker
- Stop & Save marks linked DayPlan block OR FlowActivity as DONE
- RevisionHub sync only when linked task has structured metadata (strict mode — no title guessing)
- New provider helper: discard Track Now by id without marking done
**Status:** ✅ Committed via Codex (+607/-167)

### Prompt 10 — Fix Study Queue Flow
**Files:** `lib/screens/today_plan/study_session_picker.dart`, `lib/screens/today_plan/study_flow_screen.dart`
**What it does:**
- FA picker: full `app.faPages` list sorted by page number, no 20/50 cap
- Queues exact user-selected page numbers (not `unread.take(n)`)
- UWorld picker: real topic selection from full `app.uworldTopics`, system chips as filters only
- Queue exact `topicIds`, compute questionCount from selected topics
- `_startSession()` captures navigator before dismissing, always pushes StudyFlowScreen
- `StudyFlowScreen` gains optional `queuedTasks` param — queue mode iterates selected items exactly
- FA completion: marks selected pages read; UWorld completion: updates topic doneQuestions
**Status:** ✅ Committed via Codex

---

## Key Files Quick Reference

| File | What it does |
|---|---|
| `lib/providers/app_provider.dart` | ALL state, CRUD, Flow engine, Track Now, DayPlan sync |
| `lib/screens/today_plan/today_plan_screen.dart` | Resume/Upcoming/Full Day Plan tabs |
| `lib/screens/today_plan/add_task_sheet.dart` | New task creation sheet |
| `lib/screens/today_plan/track_now_screen.dart` | Track Now timer screen |
| `lib/screens/today_plan/study_session_picker.dart` | FA/UWorld study session picker |
| `lib/screens/today_plan/study_flow_screen.dart` | Queue-based study session execution |
| `lib/screens/tracker/tracker_screen.dart` | Daily tracker + add to task sheet |
| `lib/services/backup_service.dart` | JSON backup/restore (always writes to Documents/FocusFlow) |
| `lib/screens/backup/backup_screen.dart` | Backup UI screen |
