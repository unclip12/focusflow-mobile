# FocusFlow Mobile — Progress Tracker

**Last Updated:** 2026-02-23
**Current Batch:** 2 ⏳ NEXT

---

## ⚠️ Repo Cleanup Note (2026-02-23)

The repo contained pre-existing files from a previous AI attempt that used the **wrong tech stack**:
- `flutter_riverpod` (MASTER_PLAN requires `provider`)
- `hive_flutter` (MASTER_PLAN requires `sqflite`)
- `flutter_animate` (not in MASTER_PLAN)
- `lib/features/` folder structure (MASTER_PLAN uses `lib/screens/`)
- `lib/core/` folder structure (MASTER_PLAN uses `lib/services/`, `lib/widgets/`)

**Fix commit:** 1da7f8910f2858126cd567552de17687b782ff16

All 14 conflicting files have been replaced with comment-only stubs that:
- Import nothing (no compile errors)
- Document which batch contains the correct implementation
- Preserve file paths to prevent any lingering references

**Files stubbed out:**
- `lib/app_lifecycle.dart` → logic goes in providers/app_provider.dart (Batch 4)
- `lib/core/navigation/app_router.dart` → see lib/app_router.dart (Batch 4)
- `lib/core/providers/theme_provider.dart` → see lib/providers/settings_provider.dart (Batch 4)
- `lib/core/storage/backup_service.dart` → see lib/services/backup_service.dart (Batch 23)
- `lib/core/widgets/navigation_shell.dart` → see lib/widgets/app_scaffold.dart (Batch 5)
- `lib/features/dashboard/dashboard_screen.dart` → see lib/screens/dashboard/ (Batch 6)
- `lib/features/fa_logger/fa_logger_provider.dart` → see lib/providers/app_provider.dart (Batch 4)
- `lib/features/fa_logger/fa_logger_screen.dart` → see lib/screens/fa_logger/ (Batch 12)
- `lib/features/knowledge_base/kb_provider.dart` → see lib/providers/knowledge_base_provider.dart (Batch 24)
- `lib/features/knowledge_base/knowledge_base_screen.dart` → see lib/screens/knowledge_base/ (Batch 10)
- `lib/features/settings/settings_screen.dart` → see lib/screens/settings/ (Batch 22)
- `lib/features/todays_plan/todays_plan_provider.dart` → see lib/providers/plan_provider.dart (Batch 24)
- `lib/features/todays_plan/todays_plan_screen.dart` → see lib/screens/todays_plan/ (Batch 7)
- `test/widget_test.dart` → full tests in Batch 27

---

## Batch Status

| Batch | Description | Status |
|---|---|---|
| 0 | Repo setup, MASTER_PLAN.md | ✅ Done |
| 1 | pubspec + main + app + constants | ✅ Done |
| 2 | All model files (14 files) | ⏳ **NEXT** |
| 3 | DB service + SRS + haptics | ⬜ Todo |
| 4 | Providers + theme + router | ⬜ Todo |
| 5 | Nav overlay + base scaffold | ⬜ Todo |
| 6 | Dashboard screen | ⬜ Todo |
| 7 | Today's Plan core | ⬜ Todo |
| 8 | Today's Plan modals | ⬜ Todo |
| 9 | Focus Timer | ⬜ Todo |
| 10 | Knowledge Base | ⬜ Todo |
| 11 | Revision Hub | ⬜ Todo |
| 12 | FA Logger | ⬜ Todo |
| 13 | Study Tracker | ⬜ Todo |
| 14 | FMGE Prep | ⬜ Todo |
| 15 | Calendar | ⬜ Todo |
| 16 | Time Logger | ⬜ Todo |
| 17 | Daily Tracker | ⬜ Todo |
| 18 | Info Files | ⬜ Todo |
| 19 | AI Mentor (chat UI) | ⬜ Todo |
| 20 | AI Mentor (KB import) + Session modal | ⬜ Todo |
| 21 | My AI Memory | ⬜ Todo |
| 22 | Settings | ⬜ Todo |
| 23 | Backup/Restore + Notifications | ⬜ Todo |
| 24 | Remaining providers | ⬜ Todo |
| 25 | Animations & polish | ⬜ Todo |
| 26 | Streak + Due Now + Graphs | ⬜ Todo |
| 27 | Final testing + README | ⬜ Todo |

---

## Batch 1 — Completed ✅

**Commit:** b8d1b1a030b3eee54dca077b067149af0e07a172
**Files pushed:**
- `pubspec.yaml` — all 20 dependencies per MASTER_PLAN
- `lib/main.dart` — MultiProvider entry point (portrait lock, 4 providers)
- `lib/app.dart` — FocusFlowApp with MaterialApp.router, Consumer<SettingsProvider>
- `lib/utils/constants.dart` — FMGE_SUBJECTS (19), SYSTEMS (13), CATEGORIES, MENU IDs (15), SQLite table names, Gemini endpoint
- `lib/utils/date_utils.dart` — getAdjustedDate (3 AM cutoff), formatDateKey, formatDuration, formatCountdown, isToday/isPast/isFuture, getWeekDays, startOfDay/endOfDay, dateToMs/msToDate, minutesBetween

---

## Batch 2 — Instructions for Next Agent

**Files to push (all in `lib/models/`):**
```
app_settings.dart
knowledge_base.dart
day_plan.dart
study_plan_item.dart
fmge_entry.dart
time_log_entry.dart
daily_tracker.dart
mentor_message.dart
study_entry.dart
study_material.dart
revision_item.dart
user_profile.dart
app_snapshot.dart
attachment.dart
```

**MANDATORY first step:** Read `src/types.ts` from `unclip12/FocusFlow` (main branch) for exact field names and types before writing any model.

**Tool call plan for Batch 2:**
1. `get_file_contents` → `src/types.ts` from `unclip12/FocusFlow` (ref: main)
2. `push_files` → push all 14 model Dart files to `lib/models/`
3. `create_or_update_file` → update this PROGRESS.md (Batch 2 ✅, Batch 3 ⏳ NEXT)

**Model requirements:**
- All models must have `toMap()` / `fromMap(Map<String, dynamic>)` for SQLite serialisation
- All models must have `toJson()` / `fromJson(Map<String, dynamic>)` for backup (matching web app Firebase export keys exactly)
- Use `uuid` package for ID generation: `const Uuid().v4()`
- DateTime stored as millisecondsSinceEpoch (int) in SQLite, ISO string in JSON backup
- Enums stored as `.name` string in SQLite and JSON
- Null safety: use `?` for optional fields
- No `flutter_riverpod`, no `hive`, no `flutter_animate` — those are BANNED

---

*Agent protocol: Read PROGRESS.md → implement current batch → push files → update PROGRESS.md. One batch per turn. Max 3 GitHub tool calls.*
