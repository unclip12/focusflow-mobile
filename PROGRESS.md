# FocusFlow Mobile — Progress Tracker

**Last Updated:** 2026-02-23  
**Next Batch:** 2 — All 14 model files (`lib/models/`)

---

## 📊 Batch Status

| Batch | Description | Status | Done |
|---|---|---|---|
| 0 | Repo setup, MASTER_PLAN.md | ✅ Done | 2026-02-23 |
| 1 | pubspec + main + app + constants + date_utils | ✅ Done | 2026-02-23 |
| 2 | All 14 model files in `lib/models/` | ⏳ **NEXT** | — |
| 3 | DB service + SRS service + haptics service | ⬜ Todo | — |
| 4 | Providers + app_theme + app_router | ⬜ Todo | — |
| 5 | app_scaffold + nav_overlay widgets | ⬜ Todo | — |
| 6 | Dashboard screen + stats_card + activity_graphs | ⬜ Todo | — |
| 7 | Today’s Plan core (screen + block_card) | ⬜ Todo | — |
| 8 | Today’s Plan modals (5 modals) | ⬜ Todo | — |
| 9 | Focus Timer screen | ⬜ Todo | — |
| 10 | Knowledge Base screen + page_detail_modal | ⬜ Todo | — |
| 11 | Revision Hub + log_revision_modal | ⬜ Todo | — |
| 12 | FA Logger screen + fa_log_modal | ⬜ Todo | — |
| 13 | Study Tracker screen | ⬜ Todo | — |
| 14 | FMGE Prep + fmge_log_modal | ⬜ Todo | — |
| 15 | Calendar screen | ⬜ Todo | — |
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

## 🤖 Instructions for Next AI Agent (Batch 2)

### What to do
1. Read `PROGRESS.md` → confirm Batch 2 is next
2. **Read `types.ts`** from `unclip12/FocusFlow` (main branch) — this is the source of truth for ALL field names and types
3. Push all 14 model files to `lib/models/`
4. Update `PROGRESS.md` — mark Batch 2 ✅ Done, set Batch 3 as ⏳ NEXT

### Files to create in `lib/models/`
```
app_settings.dart       ← AppSettings, NotificationConfig, MenuItemConfig
knowledge_base.dart     ← KnowledgeBaseEntry, RevisionLog, TrackableItem
day_plan.dart           ← DayPlan, Block, BlockTask, DayPlanBreak
study_plan_item.dart    ← StudyPlanItem, PlanLog, ToDoItem
fmge_entry.dart         ← FMGEEntry, FMGELog
time_log_entry.dart     ← TimeLogEntry
daily_tracker.dart      ← DailyTracker, TimeSlot, TrackerTask
mentor_message.dart     ← MentorMessage, MentorMemory, BacklogItem, AISettings
study_entry.dart        ← StudyEntry
study_material.dart     ← StudyMaterial, MaterialChatMessage
revision_item.dart      ← RevisionItem, RevisionSettings
user_profile.dart       ← UserProfile
app_snapshot.dart       ← AppSnapshot, HistoryRecord
attachment.dart         ← Attachment, VideoResource, QuizQuestion
```

### 3-call budget for Batch 2
- Call 1: `get_file_contents` → `types.ts` from `unclip12/FocusFlow` (main)
- Call 2: `push_files` → all 14 model dart files
- Call 3: `create_or_update_file` → update `PROGRESS.md`

### Key rules
- Match ALL field names exactly to `types.ts` — never guess
- Use `fromJson` / `toJson` on every model (for SQLite + backup)
- Use `copyWith` on every model
- Enums already defined in `lib/utils/constants.dart` — import from there
- No Firebase, no cloud dependencies
