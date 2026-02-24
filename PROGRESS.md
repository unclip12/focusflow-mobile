# FocusFlow Mobile — Progress Tracker

**Last Updated:** 2026-02-24  
**Next Batch:** 15 — Calendar screen

---

## 📊 Batch Status

| Batch | Description | Status | Done |
|---|---|---|---|
| 0 | Repo setup, MASTER_PLAN.md | ✅ Done | 2026-02-23 |
| 1 | pubspec + main + app + constants + date_utils | ✅ Done | 2026-02-23 |
| 2 | All 14 model files in `lib/models/` | ✅ Done | 2026-02-24 |
| 3 | DB service + SRS service + haptics service | ✅ Done | 2026-02-24 |
| 4 | Providers + app_theme + app_router | ✅ Done | 2026-02-24 |
| 5 | app_scaffold + nav_overlay widgets | ✅ Done | 2026-02-24 |
| 6 | Dashboard screen + stats_card + activity_graphs | ✅ Done | 2026-02-24 |
| 7 | Today's Plan core (screen + block_card) | ✅ Done | 2026-02-24 |
| 8 | Today's Plan modals (5 modals) | ✅ Done | 2026-02-24 |
| 9 | Focus Timer screen | ✅ Done | 2026-02-24 |
| 10 | Knowledge Base screen + page_detail_modal | ✅ Done | 2026-02-24 |
| 11 | Revision Hub + log_revision_modal | ✅ Done | 2026-02-24 |
| 12 | FA Logger screen + fa_log_modal | ✅ Done | 2026-02-24 |
| 13 | Revision Hub + bottom sheets fix | ✅ Done | 2026-02-24 |
| 14 | Settings screen + theme_picker | ✅ Done | 2026-02-24 |
| 15 | Calendar screen | ⏳ **NEXT** | — |
| 16 | Time Logger screen | ⬜ Todo | — |
| 17 | Daily Tracker screen | ⬜ Todo | — |
| 18 | Info Files / Data screen | ⬜ Todo | — |
| 19 | AI Mentor chat UI | ⬜ Todo | — |
| 20 | AI Mentor import modal + session_modal widget | ⬜ Todo | — |
| 21 | My AI Memory screen | ⬜ Todo | — |
| 22 | Settings screen | ⬜ Todo | — |
| 23 | backup_service + notification_service + plan_service + fa_logger_service | ⬜ Todo | — |
| 24 | knowledge_base_provider + plan_provider | ⬜ Todo | — |
| 25 | Animations & polish pass | ⬜ Todo | — |
| 26 | Streak logic + Due Now + activity graph data | ⬜ Todo | — |
| 27 | Final integration + README update | ⬜ Todo | — |

---

## 📂 Batch 1 — Files Committed

| File | Notes |
|---|---|
| `pubspec.yaml` | All 16 deps from MASTER_PLAN (sqflite, provider, go_router, etc.) |
| `lib/main.dart` | Entry point — DB init, portrait lock, MultiProvider |
| `lib/app.dart` | MaterialApp.router — wires SettingsProvider → AppTheme → appRouter |
| `lib/utils/constants.dart` | All enums (BlockType, BlockStatus, TimeLogCategory, TimeLogSource, RevisionMode) + kFmgeSubjects, kBodySystems, kDefaultMenuOrder, kRevisionSchedules, kBlockDurations |
| `lib/utils/date_utils.dart` | AppDateUtils — getAdjustedDate (4 AM cutoff), formatters, parsers, daysBetween, daysInMonth |

---

## 📂 Batch 2 — Files Committed

| File | Notes |
|---|---|
| 14 model files in `lib/models/` | All field names match `types.ts`, fromJson/toJson/copyWith on every model |

✅ `flutter analyze lib/` → No issues found

---

## 📂 Batch 3 — Files Committed

| File | Notes |
|---|---|
| `lib/services/database_service.dart` | SQLite CRUD for all 15 data tables |
| `lib/services/srs_service.dart` | Spaced repetition scheduling |
| `lib/services/haptics_service.dart` | Thin wrapper around HapticFeedback (light/medium/heavy/selection) |

✅ `flutter analyze lib/` → No issues found

---

## 📂 Batch 4 — Files Committed

| File | Notes |
|---|---|
| `lib/utils/app_theme.dart` | 12 themes, 6 accent colors, google_fonts Inter, font size scaling |
| `lib/providers/settings_provider.dart` | ChangeNotifier for AppSettings, theme/darkMode/primaryColor/fontSize getters |
| `lib/providers/app_provider.dart` | Central state, loads all 15 tables, typed CRUD for each domain |
| `lib/app_router.dart` | GoRouter, 15 named routes (Routes class), placeholder screens |

✅ `flutter analyze lib/` → No issues found

---

## 📂 Batch 5 — Files Committed

| File | Key Notes |
|---|---|
| `lib/widgets/app_scaffold.dart` | Common scaffold, header bar (menu icon + screen name → nav overlay, streak 🔥 N right), accepts body/screenName/actions/streakCount |
| `lib/widgets/nav_overlay.dart` | SpringSimulation (stiffness 300, damping 30), left-anchored, scrim, filters by menuConfiguration.visible, active highlight, GoRouter named nav |

✅ `flutter analyze lib/` → No issues found

---

## 📂 Batch 6 — Files Committed

| File | Key Notes |
|---|---|
| `lib/widgets/stats_card.dart` | `TodayGlanceCard` (ring chart, blocks done/total, study hours), `StatsCard` (icon/label/value) |
| `lib/widgets/activity_graph.dart` | fl_chart `BarChart`, 14-day study hours, today highlighted, tooltips, clean grid |
| `lib/screens/dashboard/dashboard_screen.dart` | AppScaffold, welcome header (displayName), TodayGlance, KB/FMGE stats, activity chart, due revision list, streak counter, empty state |

✅ `flutter analyze lib/` → No issues found

---

## 📂 Batch 7 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/today_plan/today_plan_screen.dart` | AppScaffold, date nav (prev/next arrows), plan summary bar, sorted block list, start/skip with auto-pause, empty state with Generate Plan |
| `lib/screens/today_plan/block_card.dart` | Type icon, title + time range, progress bar, status chip, tap → detail modal, long-press → haptic + context menu |
| `lib/screens/today_plan/block_detail_modal.dart` | Draggable bottom sheet, task checkboxes, segment timeline, start/pause/resume/complete actions, haptics on task check and block complete |

✅ `flutter analyze lib/screens/today_plan/` → No issues found

---

## 📂 Batch 10 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/knowledge_base/knowledge_base_screen.dart` | Knowledge base listing screen |
| `lib/screens/knowledge_base/kb_entry_card.dart` | Card widget for KB entries |
| `lib/screens/knowledge_base/kb_entry_detail_screen.dart` | Detail view for a single KB entry |

---

## 📂 Batch 8 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/time_log/time_log_screen.dart` | AppScaffold, logs grouped by date, daily total hours, FAB → add sheet, streak counter |
| `lib/screens/time_log/time_log_entry_card.dart` | Category color dot, activity, time range, duration, category chip, swipe-to-delete |
| `lib/screens/time_log/add_time_log_sheet.dart` | Activity field, time pickers, category dropdown (13 values), notes, save via AppProvider |

✅ `flutter analyze lib/screens/time_log/` → No issues found

---

## 📂 Batch 11 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/study_plan/study_plan_screen.dart` | Study plan listing screen |
| `lib/screens/study_plan/study_plan_item_card.dart` | Card widget for study plan items |
| `lib/screens/study_plan/add_study_plan_sheet.dart` | Bottom sheet for adding study plan items |

---

## 📂 Batch 9 — Files Committed

| File | Key Notes |
|---|---|
| `pubspec.yaml` | Added `wakelock_plus: ^1.1.4` |
| `lib/screens/focus_timer/focus_timer_screen.dart` | Circular countdown AnimationController, presets (15-90m), WakelockPlus on/off, haptics on complete |
| `lib/screens/focus_timer/timer_controls.dart` | Start (green) / Pause (amber) / Stop (red) with AnimatedSwitcher |
| `lib/screens/focus_timer/session_complete_dialog.dart` | Duration/block/subject stats, Log Time via AppProvider, Start Break / Done |

✅ `flutter analyze lib/screens/focus_timer/` → No issues found

---

## 📂 Batch 12 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/fmge/fmge_screen.dart` | FMGE prep listing screen |
| `lib/screens/fmge/fmge_entry_card.dart` | Card widget for FMGE entries |
| `lib/screens/fmge/fmge_entry_detail_screen.dart` | Detail view for a single FMGE entry |

## 📂 Batch 13 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/revision_hub/revision_hub_screen.dart` | DUE/UPCOMING tabs with SrsService, due count banner, styled tab bar |
| `lib/screens/revision_hub/revision_card.dart` | Page/topic, subject chip, due status color, Revise button |
| `lib/screens/today_plan/block_card.dart` | Patched `showModalBottomSheet` with `enableDrag: false` and `useSafeArea: true` |
| `lib/screens/time_log/time_log_screen.dart` | Patched `showModalBottomSheet` with `enableDrag: false` and `useSafeArea: true` |
| `lib/screens/study_plan/add_study_plan_sheet.dart` | Patched `showModalBottomSheet` with `enableDrag: false` and `useSafeArea: true` |

---

## 📂 Batch 14 — Files Committed

| File | Key Notes |
|---|---|
| `lib/screens/settings/settings_screen.dart` | Settings screen implementation |
| `lib/screens/settings/theme_picker_card.dart` | Theme picker card component |

---

## 🤖 Instructions for Next AI Agent (Batch 15)

### What to do
1. Read `PROGRESS.md` → confirm Batch 15 is next
2. Create `lib/screens/calendar/calendar_screen.dart` — Calendar screen
3. Update `PROGRESS.md` — mark Batch 15 ✅ Done, set next batch as ⏳ NEXT

### Key rules
- Wrap screen in `AppScaffold(screenName: 'Calendar', body: ...)`
- Import `AppProvider` for data, `HapticsService` for feedback
- No Firebase, no cloud dependencies
