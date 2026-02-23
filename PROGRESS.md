# FocusFlow Mobile — Progress Tracker

**Last Updated:** 2026-02-23
**Current Batch:** 2 ⏳ NEXT

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
- `lib/utils/date_utils.dart` — getAdjustedDate (3 AM cutoff), formatDateKey, formatDuration, formatCountdown, isToday, isPast, isFuture, getWeekDays, startOfDay, endOfDay, dateToMs, msToDate, minutesBetween

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

**MANDATORY first step:** Read `types.ts` from `unclip12/FocusFlow` (main branch) for exact field names and types before writing any model.

**Tool call plan:**
1. `get_file_contents` → `src/types.ts` from `unclip12/FocusFlow` (main)
2. `push_files` → push all 14 model Dart files to `lib/models/`
3. `create_or_update_file` → update this PROGRESS.md (Batch 2 ✅, Batch 3 ⏳ NEXT)

**Notes:**
- All models must have `toMap()` / `fromMap()` for SQLite serialisation
- All models must have `toJson()` / `fromJson()` for backup compatibility (matching web app Firebase export keys)
- Use `uuid` package for ID generation where needed
- DateTime stored as millisecondsSinceEpoch (int) in SQLite
- Enums stored as strings in SQLite

---

*Agent protocol: Read PROGRESS.md → implement current batch → update PROGRESS.md. One batch per turn. Max 3 GitHub tool calls.*
