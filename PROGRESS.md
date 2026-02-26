# FocusFlow Mobile — Development Progress

> Last updated: 2026-02-26 (Session 5 — G10 Complete)
> Session: Claude + Arsh — direct push + Antigravity workflow
> **App is a personal study OS for Arsh only. Tracker live. Dashboard live. Settings expanded.**

---

## ✅ Completed Batches

---

### Batch A — Android Build Setup
**Status**: ✅ Complete
- Android folder committed with NDK 27, core library desugaring
- Java + Kotlin JVM targets aligned to 17
- GitHub Actions CI with flutter analyze gate
- Gradle + pub package caching

---

### Batch B — Data Persistence
**Status**: ✅ Complete
- `AppProvider.loadAll()` called on startup in `main.dart`
- All data persists across app restarts

---

### Batch C — Navigation Fixes
**Status**: ✅ Complete
- Task saves without requiring times
- Exit dialog on dashboard Android back button
- Date picker works on Today Plan
- Back navigation fixed app-wide

---

### Batch D — SRS + KB + Task Planner
**Status**: ✅ Complete
- 12-step SRS engine (strict/relaxed modes)
- KnowledgeBaseEntry model + screens
- Exam-aware task planner with smart focus batch calculator

---

### Batch E — Session Timer + FA Logger
**Status**: ✅ Complete
- Countdown timer with motivational quotes
- Completion flow: auto-creates TimeLogEntry, updates KB, logs FA
- FA Logger redesigned
- Session navigation fixed

---

### Batch F — Critical Bug Fixes
**Status**: ✅ Complete
- Duplicate AppScaffold removed from dashboard
- blocksDone counter fixed
- Session navigation double-pop fixed
- All deprecated APIs replaced
- Dark mode consistency pass
- DropdownButtonFormField `initialValue` → `value` fix

---

### Bug Fix — TextSanitizer + Revision Card
**Status**: ✅ Complete
- `lib/utils/text_sanitizer.dart` created
- Garbled chars fixed app-wide

---

### Batch G1 — Milky Theme
**Status**: ✅ Complete
- All 12 theme pairs replaced with milky soft backgrounds
- Light = white-lavender, Dark = charcoal
- Default: light mode

---

### Batch G2 — KB Garbled Chars + Manual Add Entry
**Status**: ✅ Complete
- `TextSanitizer.clean()` applied to `kb_entry_detail_screen.dart`
- FAB + `_AddKBEntrySheet` added to `knowledge_base_screen.dart`

---

### Batch G3 — Screen Cleanup
**Status**: ✅ Complete
- `app_router.dart`: 12 dead routes + 11 dead imports removed
- `constants.dart`: MenuItemId trimmed from 16 → 9 live screens
- `nav_overlay.dart`: dead map entries + `_extraNavItems` removed
- 5 CI errors fixed
- All 10 orphaned dead screen directories deleted (G3b)

---

### Batch G4 — Bottom Nav Shell
**Status**: ✅ Complete — CI GREEN ✅
- `lib/widgets/main_shell.dart` — ShellRoute builder, 4 pinned tabs + More sheet
- `lib/app_router.dart` — 8 screens in ShellRoute; `/session` outside
- `lib/models/app_settings.dart` — `pinnedTabs` + `fullScreenMode` fields
- `lib/providers/settings_provider.dart` — getters + setters
- `lib/utils/constants.dart` — `kPinnableScreenLabels`, `kDefaultPinnedTabs`, `kFaSubjects`
- `add_time_log_sheet.dart` — fixed 3 broken `\$` string interpolations

**Default pinned tabs:** Dashboard · Revision · Today's Plan · Tracker

---

### Batch G5 — Tracker Screen (Unified)
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `1a38f10`

- `lib/models/fa_page.dart` — FAPage model (unread → read → anki_done)
- `lib/models/sketchy_item.dart` — SketchyItem (micro/pharma, status cycling)
- `lib/models/pathoma_item.dart` — PathomaItem (chapters 1–19, status cycling)
- `lib/models/uworld_session.dart` — UWorldSession (per-subject Q bank log)
- `lib/screens/tracker/tracker_screen.dart` — 4-tab tracker
- `database_service.dart` — 4 new tables, DB version 1→2 with onUpgrade migration
- `app_provider.dart` — data stores, loadAll, full CRUD for all 4 new domains

---

### Batch G6 — FA 2025 Pre-seed
**Status**: ✅ Complete — CI GREEN ✅

- `assets/data/fa_2025_seed.json` — 676 FA pages (31–706) with hierarchical topics
- `scripts/generate_fa_seed.py` — Python parser
- `lib/services/seed_service.dart` — Seeds SQLite from bundled JSON on first launch
- `lib/main.dart` — `SeedService.seedIfNeeded()` called before `AppProvider.loadAll()`
- Pages 33–49 pre-marked as "read"

---

### Batch G7 — Bulk FA Page Range Marker
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `919bf7d`

- FAB on FA 2025 tab → opens `_BulkMarkSheet` bottom sheet
- From/To page range fields (prefilled with next 10 unread pages)
- Status dropdown: Read | Anki Done
- `bulkMarkFAPages(from, to, status)` in AppProvider
- 🎉 Celebration SnackBar if ≥ 10 pages marked at once
- Full validation (31–706 range)

---

### Batch G8 — Dashboard Full Rebuild
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `0638e46`

- Dual exam countdown cards (FMGE · Step 1)
- Today's study stats: Today / This Week / Streak
- FA 2025 progress bar (X/676)
- Revision queue status
- 7-day activity heatmap
- Subject breakdown (top 4 by time)

---

### Batch G9 — Today's Plan Enhancements
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `d9684b2`

- Prayer blocks (Fajr/Zuhr/Asr/Maghrib/Isha) injected into timeline (today only, non-deletable)
- Available time banner (14h 30m after prayer deduction)
- Overflow warning if planned time > 870 min

---

### Batch G10 (Rogue) — Prayer Times + Notifications
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `371c58a`

- Real Vijayawada prayer times hardcoded
- `lib/services/notification_service.dart` added
- Local push notifications for prayer times
- Wired into `main.dart`

---

### Batch G10 — Settings Expansion
**Status**: ✅ Complete — CI GREEN ✅
**Commit**: `09c242d`

- `AppSettings` new fields: fmgeDate, step1Date, wakeTime, sleepTime, dailyFAGoal, ankiBatchSize
- `SettingsProvider` new getters + setters for all 6 fields
- Settings screen 4 new sections:
  - **Exam Dates**: FMGE + Step 1 date pickers
  - **Daily Goals**: FA pages/day slider + Anki cards/day slider
  - **Daily Schedule**: Wake time + Sleep time pickers
  - **Navigation**: Pinned tab chip manager (add/remove, max 4)

---

## 🔄 In Progress / Up Next

---

### Batch G11 — Claude Import Window
**Status**: 📋 Next — Antigravity
- JSON paste area → parse → action preview → confirm → execute
- Actions: mark_fa_pages_read, mark_fa_anki_done, add_today_task,
  log_uworld_session, set_daily_goals, set_exam_dates,
  mark_sketchy_watched, mark_pathoma_watched

---

### Batch G12 — Auto Local Backup
**Status**: 📋 Planned
- `lib/services/backup_service.dart`
- Saves full app state to device as JSON after every significant change
- Manual export/import in Settings

---

### Batch H — Analytics
**Status**: 📋 Planned
- FA pages/day 7-day bar chart, subject distribution pie, pace projection line

---

### Batch I — Final Polish
**Status**: 📋 Planned
- Wake alarm, math challenge, app icon, splash, onboarding, v1.0.0

---

## 🐛 Known Issues / Tech Debt

| Issue | Severity | Status |
|---|---|---|
| No Claude Import window yet | High | G11 ← Next |
| No auto backup | High | G12 |
| Dashboard hardcodes exam dates (not from Settings yet) | Medium | fix in G11 |
| Available time banner ignores Settings wake/sleep time | Medium | fix in G11 |
| Analytics screen is placeholder | Medium | Batch H |

---

## 📆 Session Log

| Date | Work Done |
|---|---|
| Feb 24, 2026 | Batches A–E completed |
| Feb 25, 2026 AM | Batch F, TextSanitizer fix, G1+G2 prompts written |
| Feb 25, 2026 AM | MASTER_PLAN.md + PROGRESS.md created |
| Feb 25, 2026 PM | G1 ✅ G2 ✅ confirmed |
| Feb 25, 2026 PM | Full app vision reset — personal study OS |
| Feb 25, 2026 PM | G3 ✅ G3b ✅ G4 ✅ G5 ✅ G6 ✅ G7 ✅ — CI GREEN all |
| Feb 25, 2026 PM | G8 ✅ — Dashboard full rebuild |
| Feb 25, 2026 PM | G9 ✅ — Prayer blocks + available time + overflow |
| Feb 25, 2026 PM | G10 Rogue ✅ — Prayer notifications |
| Feb 26, 2026 PM | **G10 ✅** — Settings expansion (exam dates, goals, schedule, nav pins) |

---

## 📌 Arsh's Current FA Progress

| Status | Pages | Subject |
|---|---|---|
| ✅ Read | 33–49 | Biochemistry (early sections) |
| ⬜ Not started | 50–706 | Everything else |

**Next pages:** 50 onwards
**Exams:** FMGE Jun 28 · Step 1 ~Jun 15 · ~122 days remaining
