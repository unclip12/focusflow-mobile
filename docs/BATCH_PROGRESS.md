# FocusFlow Mobile — Batch Implementation Progress

This file tracks all Codex batch implementations, their status, and context for future sessions.

## Workflow Rules
- I (Perplexity/AI) give prompts batch by batch
- User pastes prompts into Codex (High mode)
- Codex codes locally, user pushes to GitHub
- AI never pushes code directly to GitHub
- Plan mode ON for complex logic, OFF for UI/additive changes

## Completed Batches

### ✅ Batch 1 — `app_provider.dart` General Task Persistence
- Added `_savedGeneralTaskNames` field
- Added `savedGeneralTaskNames` getter
- Added `saveGeneralTaskName()` method
- Added `_persistGeneralTaskNames()` method
- Loads from SharedPreferences in `loadAll()`

### ✅ Batch 2 — `add_task_sheet.dart` General/Life Task Path
- Added Step 0 path selector (Study vs General)
- Added 8 general categories: Meal, Exercise, Chores, Personal, Errands, Social, Rest, Other
- Added autocomplete from category suggestions + savedGeneralTaskNames
- AM/PM 12-hour time pickers
- Duration preview text
- Event toggle with red highlight
- `prefillCategory` constructor param (pass 'Revision' to jump to study>revision)
- Back arrow returns to path selector
- Study flow completely untouched

### ✅ Batch 3 — `timeline_view.dart` Tap Fix + Drag Reorder
- Locked blocks (prayer/event) now show read-only detail sheet on tap
- Non-locked blocks still open edit sheet on tap
- ReorderableListView.builder replaces ListView.builder
- Drag handles on non-locked blocks only
- onReorder cascades start times from earliest free slot
- Locked blocks stay pinned during reorder
- HapticsService.light() fires on reorder

### ✅ Batch 4 — `today_plan_screen.dart` Header + FAB Polish
- FAB opens AddTaskSheet with no prefillCategory (shows path selector)
- isScrollControlled: true, useSafeArea: true, backgroundColor: transparent
- Date header shows "Today", "Tomorrow", or "EEEE, d MMM"
- Block count summary row: completed/total + 3px LinearProgressIndicator

### ✅ Batch 5 — `flow_session_screen.dart` Timer UI Polish
- "Ends at X:XX PM" shown under block title using _to12h helper
- Pause/Resume button shows correct icon + label per state
- Paused state: pulsing AnimatedOpacity on Resume button (800ms)
- "Up next" card at bottom showing next block title, time, duration

### ✅ Batch 6 — `app_provider.dart` Anchor-Based Reschedule
- rescheduleFrom() replaced with local anchor-based collision resolver
- TimelineScheduler import kept (other methods still use it)
- Locked blocks (isEvent or prayer_ prefix) never moved
- Done/skipped blocks stay in place but are non-blocking
- Blocks before anchor untouched
- Per-block collision resolution (not cursor-based)
- No new split parts generated
- Single notifyListeners() at end
- Helper methods: isLockedBlock, toMinutes, fromMinutes, overlap helpers

### ✅ Batch 7 — `tracker_sheets.dart` Deprecation Fixes
- Fixed 4 pre-existing deprecation warnings
- withOpacity() → withValues(alpha:)
- 0 warnings after fix

---

## Pending Batches

### ⏳ Batch 8 — `routine.dart` Model Changes
**Plan mode: ON**
Add to Routine model:
- `recurrenceType` (String, default 'none') — 'none' | 'daily' | 'weekly' | 'monthly'
- `recurrenceDays` (List<int>, default []) — for weekly: 1=Mon…7=Sun

New model `RoutineSubtask`:
- id, name, emoji, durationMinutes
- toJson, fromJson, copyWith

Add `subtasks` (List<RoutineSubtask>, default []) to Routine.
Add `totalSubtaskMinutes` getter (sum from subtasks).
Keep existing `totalEstimatedMinutes` getter unchanged.

### ⏳ Batch 9 — `routines_tab.dart` Redesign
**Plan mode: OFF**
- Subtask previews on routine cards
- Total duration from subtasks
- Recurrence badge
- "Add to Today's Plan" button with time picker → scheduler re-run

### ⏳ Batch 10 — `routine_editor_sheet.dart` Redesign
**Plan mode: OFF**
- Emoji picker per subtask
- Subtask list with ReorderableListView
- Duration stepper
- Live total duration
- Recurrence selector (None/Daily/Weekly with weekday checkboxes/Monthly)

### ⏳ Batch 11 — `free_gap_panel.dart` Fixes
**Plan mode: OFF**
- Fix broken buildRoutineBlock / addBlockToDayPlan calls
- Check AppProvider for actual equivalent method names
- Wire correctly

### ⏳ Batch 12 — `wakeup_snooze_overlay.dart`
**Plan mode: OFF**
- Full-screen overlay with "Start the Day Now" button
- Snooze buttons: 5/10/15/20 min
- Countdown ring
- Alarm sound via NotificationService

---

## Key Architecture Notes
- `rescheduleFrom(String dateKey, DateTime from)` — anchor-based, from = anchor
- Locked blocks = isEvent == true OR id.startsWith('prayer_')
- BlockStatus.done / BlockStatus.skipped = non-blocking in scheduler
- `savedGeneralTaskNames` persisted in SharedPreferences key: 'general_task_names'
- `prefillCategory == 'Revision'` skips path selector → study > USMLE > revision
- All time pickers use 12-hour AM/PM format
- Timeline drag reorder cascades from earliest non-locked start time

## File Locations
- Provider: `lib/providers/app_provider.dart`
- Models: `lib/models/day_plan.dart`, `lib/models/routine.dart`
- Scheduler: `lib/services/timeline_scheduler.dart`
- Today Plan screens: `lib/screens/today_plan/`
- Tracker: `lib/screens/tracker/tracker_sheets.dart`
