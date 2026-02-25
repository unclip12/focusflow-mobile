# FocusFlow Mobile — Development Progress

> Last updated: 2026-02-25 (Session 4 — G4 Complete)
> Session: Claude + Arsh — direct push workflow
> **App is a personal study OS for Arsh only. G4 bottom nav shell live.**

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
- AI Mentor JSON importer (replaced by Claude Import in G12)
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
**Commits**: `c200807`, `f1ddad2`, `715a7b5`, `612efe2`
- `app_router.dart`: 12 dead routes + 11 dead imports removed
- `constants.dart`: MenuItemId trimmed from 16 → 8 live screens
- `nav_overlay.dart`: dead map entries + `_extraNavItems` removed
- 5 CI errors fixed (Routes.focusTimer ref + 4× initialValue)
- All 10 orphaned dead screen directories deleted (G3b)

**Live screens after G3:**
| Route | Screen |
|---|---|
| `/dashboard` | Dashboard |
| `/todays-plan` | Today's Plan |
| `/time-logger` | Time Logger |
| `/fa-logger` | FA Logger (interim, replaced G5) |
| `/revision` | Revision Hub |
| `/knowledge-base` | Knowledge Base |
| `/analytics` | Analytics |
| `/settings` | Settings |
| `/session` | Session (outside shell) |

---

### Batch G4 — Bottom Nav Shell
**Status**: ✅ Complete — CI GREEN ✅
**Commits**: `2c7dd4b`, `c8a1910`

**What was built:**
- `lib/widgets/main_shell.dart` — NEW ShellRoute builder widget
  - `fullScreenMode = true` → returns child only (AppScaffold hamburger works as before)
  - `fullScreenMode = false` → wraps child in `Scaffold` with `NavigationBar`
  - 4 pinned tabs + permanent `More` (5th tab)
  - `More` → `showModalBottomSheet` 4-column icon grid of all non-pinned screens
  - Current route always highlighted. `/knowledge-base/:id` normalises to `knowledge-base` tab
- `lib/app_router.dart` — 8 screens wrapped in `ShellRoute`; `/session` stays outside
- `lib/models/app_settings.dart` — `pinnedTabs` + `fullScreenMode` fields added
- `lib/providers/settings_provider.dart` — `pinnedTabs`/`fullScreenMode` getters + setters
- `lib/utils/constants.dart` — `kPinnableScreenLabels`, `kDefaultPinnedTabs`, `kFaSubjects` added
- `add_time_log_sheet.dart` — fixed 3 broken `\$` string interpolations (functional bug)

**Default pinned tabs:** Dashboard · Revision · Today's Plan · FA Tracker

---

## 🔄 In Progress / Up Next

---

### Batch G5 — Tracker Screen (Unified)
**Status**: 📋 Next — Claude Opus 4.6 via Antigravity
**What it does:**
New screen `lib/screens/tracker/tracker_screen.dart` with scrollable top tab bar:
- **FA 2025 tab**: Full page list grouped by subject, status badges, bulk range marker
- **Sketchy tab**: Micro (organisms by type) + Pharma, per-item status, daily goal
- **Pathoma tab**: Chapters list, per-chapter status
- **UWorld tab**: Per-subject questions done/total/%, log session button

**Models to create:**
- `lib/models/fa_page.dart` — FAPage (pageNum, title, subject, system, status, srsFields)
- `lib/models/sketchy_item.dart` — SketchyItem (name, type, status, srsFields)
- `lib/models/pathoma_item.dart` — PathomaItem (chapter, subject, status)
- `lib/models/uworld_session.dart` — UWorldSession (subject, done, correct, date)

---

### Batch G6 — FA 2025 Pre-seed
**Status**: 📋 Planned — Direct Claude push
- Claude generates `assets/data/fa_2025_seed.json` with all ~672 FA pages
- Pages 33–49 pre-marked as `read`
- `lib/services/seed_service.dart` seeds on first launch

---

### Batch G7 — Bulk FA Page Range Marker
**Status**: 📋 Planned — Gemini Flash
- "Mark as Read" → dialog: From Page [__] To Page [__]
- Auto-schedules SRS revision for each marked page
- Celebration animation fires when 10+ pages marked in a day

---

### Batch G8 — Dashboard Full Rebuild
**Status**: 📋 Planned — Claude Opus 4.6
- Dual exam countdown (FMGE: X days, Step 1: ~Y days)
- Available time block + pace insight row
- Today's goals row: FA progress bar, Anki, Sketchy, Revision due
- Streak + motivation row

---

### Batch G9 — Today's Plan Rebuild
**Status**: 📋 Planned — Gemini Pro High
- Available time calculator
- Prayer blocks auto-populated from Settings
- Task types: FA Pages, Sketchy, Pathoma, Anki, UWorld, Personal, Break
- Overflow alert if plan exceeds available time

---

### Batch G10 — Settings Expansion
**Status**: 📋 Planned — Claude Sonnet 4.6
- Exam Dates: FMGE date, Step 1 date
- Sleep/Wake time, daily FA goal, Anki batch size
- Prayer times: 5 prayers with azan time
- Nav customizer: pick 4 pinned bottom tabs
- Full Screen Mode toggle

---

### Batch G11 — Motivation System (Lottie)
**Status**: 📋 Planned — Gemini Flash
- `lottie` package, `CelebrationOverlay` widget
- Triggers: 10 pages/day, Anki batch done, all revisions cleared, 7-day streak etc.

---

### Batch G12 — Claude Import Window
**Status**: 📋 Planned — Gemini Pro High
- JSON paste area → parse → action preview → confirm → execute
- `ClaudeImportService` handles: mark_fa_pages_read, mark_fa_anki_done,
  add_today_task, add_study_block, log_uworld_session, set_daily_goals,
  set_exam_dates, mark_sketchy_watched, mark_pathoma_watched

---

### Batch G13 — Auto Local Backup
**Status**: 📋 Planned — Gemini Pro High
- `lib/services/backup_service.dart`
- Saves full app state to device as JSON after every significant change
- Manual export/import in Settings

---

### Batch H — Analytics
**Status**: 📋 Planned — Gemini Flash
- FA pages/day 7-day bar chart, subject distribution pie, pace projection line

---

### Batch I — Final Polish
**Status**: 📋 Planned — Gemini Flash
- Wake alarm, math challenge, app icon, splash, onboarding, v1.0.0

---

## 🐛 Known Issues / Tech Debt

| Issue | Severity | Status |
|---|---|---|
| Analytics screen is placeholder | Medium | Batch H |
| No Claude Import window yet | High | G12 |
| No auto backup | High | G13 |
| No FA pre-seeded content | High | G6 |
| No Tracker screen (unified) | High | G5 |
| No prayer time settings | Medium | G10 |
| No exam date settings | Medium | G10 |
| No bulk page marker | High | G7 |
| Dashboard needs full rebuild | High | G8 |

---

## 📆 Session Log

| Date | Work Done |
|---|---|
| Feb 24, 2026 | Batches A–E completed |
| Feb 25, 2026 AM | Batch F, TextSanitizer fix, G1+G2 prompts written |
| Feb 25, 2026 AM | MASTER_PLAN.md + PROGRESS.md created |
| Feb 25, 2026 PM | G1 ✅ G2 ✅ confirmed |
| Feb 25, 2026 PM | Full app vision reset — personal study OS |
| Feb 25, 2026 PM | FA 2025 section map, design language, batch plan G3–I defined |
| Feb 25, 2026 PM | G3 ✅ — routes + constants + nav cleaned, 5 CI errors fixed |
| Feb 25, 2026 PM | G3b ✅ — 10 orphaned screen directories deleted |
| Feb 25, 2026 PM | **G4 ✅** — ShellRoute + bottom nav + More sheet + fullScreenMode — CI GREEN |

---

## 📌 Arsh's Current FA Progress

| Status | Pages | Subject |
|---|---|---|
| ✅ Read | 33–49 | Biochemistry (early sections) |
| ⬜ Not started | 50–92 | Biochemistry (remaining) |
| ⬜ Not started | 93–706 | Everything else |

**Next pages:** 50 onwards (Biochemistry continuing)
**Exams:** FMGE June 28 · Step 1 ~June 2026 · 123 days
