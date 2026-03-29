# FocusFlow Mobile — Implementation Plan

---

## ✅ Completed Batches (1–33)

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
| 13 | `timeline_view.dart` — tall rounded pill, emoji icon, time labels, status circle, dashed connector, free gap row | ✅ Done |
| 14 | `today_plan_screen.dart` — extendBody, bottom padding, scroll-away header + weekly strip | ✅ Done |
| 15 | `block_editor_sheet.dart` — color header, emoji/color pickers, white underline title, date/time/alert rows | ✅ Done |
| 16 | `time_picker_sheet.dart` — drum-roll pickers, Standard/Detailed toggle, duration sync | ✅ Done |
| 17 | `alert_repeat_sheet.dart` — alert offsets, alert types, repeat options, weekday chips | ✅ Done |
| 18 | `today_plan_screen.dart` + `timeline_view.dart` — dark theme, salmon pills, weekly strip, scroll-away date header | ✅ Done |
| 19 | `time_picker_sheet.dart` — paired drum-roll pickers, looping ListWheelScrollView, duration chip row | ✅ Done |
| 20 | `timeline_view.dart` + `app_provider.dart` — removed auto-complete, keyboard white screen fix across all sheets | ✅ Done |
| 21 | `study_session_screen.dart` + `timeline_view.dart` — study session full screen, tap routing for study blocks | ✅ Done |
| 22 | `day_session_screen.dart` — real progress from BlockStatus.done, 12hr times, dark palette | ✅ Done |
| 23 | `today_plan_screen.dart` + `timeline_view.dart` — all entry points wire to BlockEditorSheet | ✅ Done |
| 24 | `task_suggestions_service.dart` + `block_editor_sheet.dart` — 500+ keyword smart emoji/category auto-suggest | ✅ Done |
| 25 | `today_plan_screen.dart` + `timeline_view.dart` — theme fix, top quick-action grid restored, compact pills, overlap warning | ✅ Done |
| 26 | `today_plan_screen.dart` — Study Session button routes to existing study_session_picker.dart | ✅ Done |
| 27 | `timeline_view.dart` — live now-line, smart Add Task (future only), Add Log (past gaps) | ✅ Done |
| 28 | `app.dart` + `app_theme.dart` + all sheets — root-cause keyboard white screen fix | ✅ Done |
| 29 | `study_session_picker.dart` — Videos from Library section (ENT, PSM, Ophtha) | ✅ Done |
| 30 | `AndroidManifest.xml` + `app_theme.dart` + `block_editor_sheet.dart` + `routine_editor_sheet.dart` — keyboard inset padding, bottom sheet theme | ✅ Done |
| 31 | `study_session_picker.dart` — ENT/PSM/Ophtha navigate to real VideoLecturesTab | ✅ Done |
| 32 | `day_session_screen.dart` — exclude retroactive logs, Done Early persists, theme uses app theme | ✅ Done |
| 33 | `timeline_view.dart` + `day_plan.dart` — dual-track planned vs actual, status circle marks done | ✅ Done |

---

## 🗒️ Known Minor Items (non-blocking)

- 5 `deprecated_member_use` info warnings for `value:` in:
  - `add_task_sheet.dart:1452`
  - `tracker_sheets.dart:394, 409, 588, 839`
  - These are `DropdownButtonFormField` — replace `value:` with the current API when upgrading Flutter SDK
- 57 pub dependency update notices (not errors)

---

## 🗒️ Notes
- Reference screenshots: `docs/screenshots/timeline_reference_*.png`
- Flutter SDK on build machine may differ from local — always use `value:` not `initialValue:` for `DropdownButtonFormField`
- Run `flutter analyze <file>` after every batch before marking done
- Full `flutter analyze --no-fatal-infos` after every 2 batches
- `actualStartTime` and `actualEndTime` already existed in `Block` model at `day_plan.dart:377-378`
- `BlockType` is defined in `lib/utils/constants.dart` (not `day_plan.dart`)
- `BlockStatus` done terminal state uses `BlockStatus.done` (not `.completed`)
- `Block.description` is used for retroactive log detection (no `notes` field on Block)
