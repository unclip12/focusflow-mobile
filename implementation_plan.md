# FocusFlow Mobile — Implementation Plan

---

## ✅ Completed Batches (1–12)

| Batch | File(s) | Status |
|---|---|---|
| 1 | `models/day_plan.dart` | ✅ Done |
| 2 | `models/routine.dart` (initial) | ✅ Done |
| 3 | `services/notification_service.dart` | ✅ Done |
| 4 | `providers/app_provider.dart` | ✅ Done |
| 5 | `screens/today_plan/timeline_view.dart` (initial) | ✅ Done |
| 6 | `screens/today_plan/block_editor_sheet.dart` | ✅ Done |
| 7 | `screens/today_plan/today_plan_screen.dart` (initial) | ✅ Done |
| 8 | `models/routine.dart` — RoutineSubtask defaults + totalEstimatedMinutes getter | ✅ Done |
| 9 | `screens/today_plan/routines_tab.dart` — recurrence pills, subtask preview, Add to Today's Plan | ✅ Done |
| 10 | `screens/today_plan/routine_editor_sheet.dart` — subtask reorder, emoji, duration steppers, recurrence | ✅ Done |
| 11 | `screens/today_plan/today_plan_screen.dart` — pre-existing error fixes | ✅ Done |
| 12 | `screens/today_plan/wakeup_snooze_overlay.dart` — full-screen overlay, countdown ring, snooze notifications | ✅ Done |

---

## 🔄 In Progress — Timeline & Task Creation Redesign (Batches 13–17)

> **Goal**: Redesign the timeline visual, task creation sheet, time picker sheet,
> and fix scroll/layout issues to match the reference screenshots.
> Do NOT replace full files — surgical changes only.

---

### Batch 13 — Timeline Block Visual Redesign
**File**: `lib/screens/today_plan/timeline_view.dart`  
**Status**: 🔲 Not started

**Changes**:
- Replace current block rendering with tall rounded pill/capsule icon container on LEFT
- Pill height stretches proportionally to block duration
- Block emoji/icon centered inside pill
- Time labels on far LEFT (e.g. `8:00`, `9:35`)
- Block title + time range text to RIGHT of pill
- Status circle (hollow ring) on far RIGHT
- Dashed vertical connector line between blocks with a time gap
- Free gap row: clock icon + `"Use Xh Xm wisely. Create away!"` with free time in salmon/pink + `Add Task` pill button
- Keep all existing tap/swipe/long-press behaviors

---

### Batch 14 — Layout & Scroll Fixes
**File**: `lib/screens/today_plan/today_plan_screen.dart`  
**Status**: 🔲 Not started

**Changes**:
- Add `extendBody: true` to the Scaffold so content renders behind nav bar
- Add `MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight` as bottom padding to scrollable content
- Make the weekly calendar strip + date header scroll away with content (NOT sticky/pinned)
- Full page scrolls up so only timeline is visible when user scrolls down

---

### Batch 15 — Task Creation Sheet Redesign (Step 1 — Basic Info)
**File**: `lib/screens/today_plan/block_editor_sheet.dart`  
**Status**: 🔲 Not started

**Changes**:
- Color header at top (salmon/block color background)
- X close button top-left
- Large circle icon (tappable → emoji picker) top-center
- Color palette icon below icon circle (tappable → color picker)
- Title text field (white underline style, large)
- Status circle top-right
- Below header on dark background:
  - Date row: calendar icon + date + relative label ("Tomorrow") + chevron
  - Time row: clock icon + time range + duration + chevron → opens Batch 16 sheet
  - Alert row: bell-off icon + "1 Alert" + "Nudge" + chevron
- Repeat row: refresh icon + "Repeat" + PRO badge pill
- Subtask/notes card: checkbox + "Add Subtask" + gear icon + divider + notes placeholder
- "Create Task" full-width salmon CTA button
- Keep all existing fields: `isEvent`, `BlockType`, `BlockStatus`, `date`, `plannedStartTime`, `plannedEndTime`, `plannedDurationMinutes`

---

### Batch 16 — Time Picker Sheet (Step 2)
**File**: `lib/screens/today_plan/time_picker_sheet.dart` *(new file)*  
**Status**: 🔲 Not started

**Changes**:
- Same color header as Batch 15 (block color background, title, icon)
- "Time" section: scrollable list of 15-min interval time slots
  - Selected slot shown as salmon rounded pill (e.g. `8:05 – 9:35 AM`)
- "Duration" section: horizontal segmented selector
  - Options: `1`, `15`, `30`, `45`, `1h`, `1.5h` (minutes, except last two)
  - Selected option shown as salmon pill
- "Continue" full-width salmon button → returns picked time + duration to Batch 15 sheet
- 12-hour AM/PM format throughout

---

### Batch 17 — Alert & Repeat Sheet
**File**: `lib/screens/today_plan/alert_repeat_sheet.dart` *(new file)*  
**Status**: 🔲 Not started

**Changes**:
- Alert options: None, At time, 5 min before, 10 min before, 15 min before, 30 min before
- Alert type selector: Nudge | Notification | Alarm
- Repeat options: None | Daily | Weekly (with weekday chips M T W T F S S) | Monthly
- Returns `alertOffset`, `alertType`, `recurrenceType`, `recurrenceDays` back to block editor
- Wire into existing `NotificationService.scheduleAt(...)` call

---

## 📋 Batch Order & Dependencies

```
Batch 13 (timeline visuals)  ← independent, start first
Batch 14 (scroll/layout)     ← independent, run in parallel with 13
Batch 15 (task sheet UI)     ← depends on 13 + 14 being done
Batch 16 (time picker)       ← depends on 15
Batch 17 (alert/repeat)      ← depends on 15
```

---

## 🗒️ Notes
- Reference screenshots: `docs/screenshots/timeline_reference_*.png`
- Flutter SDK on build machine may differ from local — always use `value:` not `initialValue:` for `DropdownButtonFormField`
- Run `flutter analyze <file>` after every batch before marking done
- Full `flutter analyze --no-fatal-infos` after every 2 batches
