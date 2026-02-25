# FocusFlow Mobile — Development Progress

> Last updated: 2026-02-25 (Session 3 — G3 Execution)
> Session: Claude + Arsh — Antigravity workflow
> **App is now a personal study OS for Arsh only. Full vision reset completed.**

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
- `â€¢` → `•`, `â€“` → `—`, `â` → `✓` etc.
- revision_card.dart garbled chars fixed

---

### Batch G1 — Milky Theme
**Status**: ✅ Complete
**Commit**: `feat: milky theme light+dark, soft card shadows, light default`
- All 12 theme pairs replaced with milky soft backgrounds
- Light = white-lavender, Dark = charcoal (not navy)
- Default changed to light mode

---

### Batch G2 — KB Garbled Chars + Manual Add Entry
**Status**: ✅ Complete
**Commit**: `fix: sanitize KB content chars, add manual KB entry sheet`
- `TextSanitizer.clean()` applied to all text in `kb_entry_detail_screen.dart`
- FAB + `_AddKBEntrySheet` added to `knowledge_base_screen.dart`
- Manual KB entry creation now works

---

### Batch G3 — Screen Cleanup (Dead Screen Deletion)
**Status**: ✅ Complete
**Commits**: `c200807`, `f1ddad2`

**What was done:**
- `app_router.dart`: Removed 12 dead routes + 11 dead imports
  - Removed routes: `/study-tracker`, `/focus-timer`, `/calendar`, `/fmge`, `/fmge/:id`,
    `/daily-tracker`, `/data`, `/chat`, `/ai-memory`, `/mentor`, `/notifications`, `/profile`
  - Routes class trimmed from 19 → 10 constants
- `constants.dart`: MenuItemId trimmed from 16 → 8 live screens
  - Removed: `studyTracker`, `focusTimer`, `calendar`, `fmge`, `dailyTracker`, `data`, `chat`, `aiMemory`
  - `kDefaultMenuOrder` and `kMenuItemLabels` updated to 8 live items
  - `kAiTones` removed
- `nav_overlay.dart`: `_menuIdToRoute` and `_menuIcons` maps cleaned to 8 live entries
  - `_ExtraNavItem` class + `_extraNavItems` const removed entirely
  - Analytics promoted from “extra” section into main nav maps
  - Notifications + Profile (dead) removed from nav

**Dead screen directories (orphaned, CI passing, to be manually deleted):**
- `lib/screens/mentor/`
- `lib/screens/backup/`
- `lib/screens/calendar/`
- `lib/screens/daily_tracker/`
- `lib/screens/fmge/`
- `lib/screens/focus_timer/`
- `lib/screens/info_files/`
- `lib/screens/study_plan/`
- `lib/screens/notifications/`
- `lib/screens/profile/`

**Live screens after G3:**
| Route | Screen | File |
|---|---|---|
| `/dashboard` | Dashboard | `dashboard/dashboard_screen.dart` |
| `/todays-plan` | Today's Plan | `today_plan/today_plan_screen.dart` |
| `/time-logger` | Time Logger | `time_log/time_log_screen.dart` |
| `/fa-logger` | FA Logger | `fa_logger/fa_logger_screen.dart` |
| `/revision` | Revision Hub | `revision_hub/revision_hub_screen.dart` |
| `/knowledge-base` | Knowledge Base | `knowledge_base/knowledge_base_screen.dart` |
| `/analytics` | Analytics | `analytics/analytics_screen.dart` |
| `/settings` | Settings | `settings/settings_screen.dart` |
| `/session` | Session | `session/session_screen.dart` |

---

## 🔄 In Progress / Up Next

---

### Batch G3b — Dead Directory Deletion
**Status**: 📋 Next — Direct Claude push (file deletions)
**What it does:**
- Delete all 11 orphaned screen files from 10 dead directories
- Directories disappear once their files are removed (Git has no empty dirs)

Files to delete:
- `lib/screens/mentor/mentor_screen.dart`
- `lib/screens/backup/backup_screen.dart`
- `lib/screens/calendar/calendar_screen.dart`
- `lib/screens/daily_tracker/daily_tracker_screen.dart`
- `lib/screens/fmge/fmge_screen.dart`
- `lib/screens/fmge/fmge_entry_detail_screen.dart`
- `lib/screens/focus_timer/focus_timer_screen.dart`
- `lib/screens/info_files/info_files_screen.dart`
- `lib/screens/study_plan/study_plan_screen.dart`
- `lib/screens/notifications/notifications_screen.dart`
- `lib/screens/profile/profile_screen.dart`

---

### Batch G4 — Bottom Nav Redesign
**Status**: 📋 Planned — Claude Sonnet 4.6
**What it does:**
- 4 customizable pinned tabs (default: Dashboard, Revision Hub, Today’s Plan, Tracker)
- Permanent 5th tab: “More ▲”
- Tapping More → beautiful slide-up bottom sheet grid with remaining screens
- Full Screen Mode option in Settings: hides bottom nav, shows hamburger drawer instead
- Settings screen: user picks which 4 screens to pin

---

### Batch G5 — Tracker Screen (Unified)
**Status**: 📋 Planned — Claude Opus 4.6
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
**What it does:**
- Claude generates `assets/data/fa_2025_seed.json` with all ~672 FA pages
- Each page: `{ "page": 31, "title": "Molecular Biology", "subject": "Biochemistry", "system": "General", "status": "unread" }`
- `lib/services/seed_service.dart` detects first launch, seeds all pages into AppProvider
- Pages 33–49 marked as `read` (Arsh’s current progress)
- Bundled in `pubspec.yaml` as asset

---

### Batch G7 — Bulk FA Page Range Marker
**Status**: 📋 Planned — Gemini Flash
**What it does:**
- “Mark as Read” button in FA Tracker → opens dialog: From Page [__] To Page [__]
- Marks all pages in range as `read`, auto-schedules SRS revision for each
- Separate “Mark Anki Done” range action
- Celebration animation fires when 10+ pages marked in a day

---

### Batch G8 — Dashboard Full Rebuild
**Status**: 📋 Planned — Claude Opus 4.6
**What it does:**
- Dual exam countdown cards (FMGE: X days, Step 1: ~Y days)
- Today’s available time block (wake → sleep − prayer blocks − tasks)
- Pace insight row: avg pages/day, projected FA completion date, on-track indicator
- Today’s goals row: FA progress bar, Anki status, Sketchy progress, Revision due
- Streak + motivation row
- All values pulled live from AppProvider

---

### Batch G9 — Today’s Plan Rebuild
**Status**: 📋 Planned — Gemini Pro High
**What it does:**
- Available time calculator at top
- Prayer blocks auto-populated from Settings
- Add task types: FA Pages, Sketchy, Pathoma, Anki, UWorld, Personal, Break
- Running time total — shows overflow alert if plan exceeds available time
- “Doesn’t fit — reduce by X min” warning

---

### Batch G10 — Settings Expansion
**Status**: 📋 Planned — Claude Sonnet 4.6
**New settings fields:**
- Exam Dates: FMGE date, Step 1 date
- Sleep time + Wake time
- Daily FA page goal (default: 10)
- Anki batch size (default: 4 pages)
- Prayer times: 5 prayers, each with azan time (departure auto-calculated)
- Nav customizer: pick 4 pinned bottom tabs
- Full Screen Mode toggle

---

### Batch G11 — Motivation System (Lottie Animations)
**Status**: 📋 Planned — Gemini Flash
**What it does:**
- Add `lottie` package to pubspec.yaml
- Bundle Lottie JSON files in `assets/lottie/`
- `CelebrationOverlay` widget wrapping the app
- Triggers: 10 pages/day, Anki batch done, all revisions cleared, 7-day streak,
  subject complete, daily goal before 6 PM, 30-day streak

---

### Batch G12 — Claude Import Window
**Status**: 📋 Planned — Gemini Pro High
**What it does:**
- New screen `lib/screens/claude_import/claude_import_screen.dart`
- Large paste area for JSON
- Parse button → validates + shows action preview list
- Confirm → executes all actions via `ClaudeImportService`
- Supported actions: mark_fa_pages_read, mark_fa_anki_done, add_today_task,
  add_study_block, log_uworld_session, set_daily_goals, set_exam_dates,
  mark_sketchy_watched, mark_pathoma_watched
- Error handling: shows which actions failed and why

---

### Batch G13 — Auto Local Backup
**Status**: 📋 Planned — Gemini Pro High
**What it does:**
- `lib/services/backup_service.dart`
- Saves complete app state to device storage as JSON after every significant change
- Backup file: `[device_documents]/focusflow_backup.json`
- On app start: detect if backup exists → offer restore if data is empty
- Manual export/import option in Settings
- Uses `path_provider` package

---

### Batch H — Analytics
**Status**: 📋 Planned — Gemini Flash
- FA pages per day (7-day bar chart)
- Subject distribution (pie chart)
- Pace projection line (actual vs needed)
- Exam readiness score (pages done / total needed)

---

### Batch I — Final Polish
**Status**: 📋 Planned — Gemini Flash
- Wake alarm (flutter_local_notifications)
- Math challenge to confirm wake-up
- App icon + splash screen
- Onboarding flow (exam type, dates, prayer times setup)
- Version bump to 1.0.0

---

## 🐛 Known Issues / Tech Debt

| Issue | Severity | Status |
|---|---|---|
| Analytics screen is placeholder | Medium | Batch H |
| No Claude Import window yet | High | G12 |
| No auto backup | High | G13 |
| No FA pre-seeded content | High | G6 |
| No Tracker screen (unified) | High | G5 |
| ~~Dead screens still in codebase~~ | ~~Medium~~ | ✅ G3 (routes+nav clean; files pending deletion) |
| No prayer time settings | Medium | G10 |
| No exam date settings | Medium | G10 |
| No bulk page marker | High | G7 |
| Dashboard needs full rebuild | High | G8 |

---

## 📆 Session Log

| Date | Work Done |
|---|---|
| Feb 24, 2026 | Batches A, B, C, D, E completed in one session |
| Feb 25, 2026 AM | Batch F (critical fixes), TextSanitizer bug fix, G1+G2 prompts written |
| Feb 25, 2026 AM | MASTER_PLAN.md + PROGRESS.md first version created |
| Feb 25, 2026 PM | G1 ✅ + G2 ✅ both confirmed complete |
| Feb 25, 2026 PM | **FULL APP VISION RESET** — app is now personal study OS for Arsh only |
| Feb 25, 2026 PM | FA 2025 (35th Ed) uploaded — full section map extracted |
| Feb 25, 2026 PM | New design language defined (premium vibrant milky) |
| Feb 25, 2026 PM | New screen map finalised (8 dead screens removed, Tracker + Claude Import added) |
| Feb 25, 2026 PM | New batch plan G3–I defined |
| Feb 25, 2026 PM | Claude Import JSON schema designed |
| Feb 25, 2026 PM | MASTER_PLAN + PROGRESS fully rewritten with all new context |
| Feb 25, 2026 PM | **G3 ✅** — app_router + constants + nav_overlay all cleaned (routes, MenuItemIds, nav maps) |

---

## 📌 Arsh’s Current FA Progress

| Status | Pages | Subject |
|---|---|---|
| ✅ Read | 33–49 | Biochemistry (early sections) |
| ⬜ Not started | 50–92 | Biochemistry (remaining) |
| ⬜ Not started | 93–706 | Everything else |

**Next pages to read:** 50 onwards (Biochemistry continuing)
**Next Anki batch due:** Pages 46–49 (if not done yet — confirm with Arsh)
