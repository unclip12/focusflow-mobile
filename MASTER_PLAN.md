# FocusFlow Mobile — Master Plan

> **This app is a personal study OS built exclusively for Arsh.**
> Not a product. Not for general users. Built to help one person pass FMGE (June 28, 2026) and USMLE Step 1 (~June 2026).
> Claude (AI) is the brain. The app is the interface. Arsh is the user.

---

## 🚀 Continue In New Chat

Paste this at the start of every new Claude chat:

```
You are continuing development of FocusFlow Mobile.
Repo: github.com/unclip12/focusflow-mobile
Owner: unclip12

Before answering anything, read these files from the repo:
- MASTER_PLAN.md     (complete app vision, design, screen map, batch plan)
- PROGRESS.md        (what's done, what's next, current status)

Context:
- Flutter app, stable 3.29.x, Provider state, go_router, SharedPreferences
- Central state: AppProvider (lib/providers/app_provider.dart)
- CI: GitHub Actions with flutter analyze gate
- Workflow: Claude is the architect AND brain. Claude writes prompts for Gemini/Sonnet/Opus.
  Gemini runs in Codespaces. Errors fixed by Claude directly.
- You are Arsh's personal mentor for FMGE + Step 1 exam prep.
- You have full authority to make app decisions. Arsh trusts your judgment completely.
- Every session: read MASTER_PLAN + PROGRESS, understand full context, act accordingly.
- When Arsh describes his day/plan, generate a Claude Import JSON block at the end.
- Always update MASTER_PLAN.md and PROGRESS.md at end of major sessions.

Please read MASTER_PLAN.md and PROGRESS.md now, then ask what Arsh wants to work on.
```

---

## 🎯 Student Profile — Arsh

| Field | Detail |
|---|---|
| **Name** | Arsh |
| **Location** | Vijayawada, Andhra Pradesh, India |
| **Goal 1** | Pass FMGE — June 28, 2026 (123 days from Feb 25) |
| **Goal 2** | Pass USMLE Step 1 — approximately June 2026 |
| **FA Progress** | Pages 33–49 done (early Biochemistry) |
| **Daily FA Goal** | 10 pages/day |
| **Anki Batch** | Every 4 FA pages |
| **Daily Sketchy** | 2 Micro organisms/day minimum |
| **Sleep** | ~9–10 PM |
| **Wake** | ~4 AM (Fajr) |
| **Religion** | Muslim — 5 daily prayers, each = 30 min block |

---

## 📅 Exam Timeline (as of Feb 25, 2026)

| Milestone | Date | Days Left |
|---|---|---|
| FMGE | June 28, 2026 | ~123 days |
| USMLE Step 1 | ~June 2026 | ~118 days |
| FA pages remaining | Pages 50–706 | 657 pages |
| At 10 pages/day | Done in 66 days | ~May 1 |
| Buffer for UWorld+NBME | 57 days | Tight but doable |
| Book Step 1 exam | 2 months before | ~April 2026 |
| NBME practice test | After all FA done | ~May 2026 |

**Pace Target:** 10 FA pages/day is non-negotiable. App must make this visible every single day.

---

## 📖 Arsh's Exact Study Workflow

This is the ONLY workflow the app needs to support. Every screen must serve this flow.

```
1. MORNING — Open app → See revision due for today → Do those FIRST
2. READ FA PAGE — Upload to NotebookLM → Audio overview → Understand concept
3. CLARIFY — Doubts via Amboss (free trial rotating) / Google / YouTube
4. AFTER 4 PAGES — Do Anki flashcards for those 4 pages
5. MARK ANKI DONE — App records Anki complete for pages X-Y
6. REPEAT — Continue new FA pages
7. DAILY 1-2 HOURS — Sketchy (Micro/Pharma) + Pathoma revision
8. UWORLD — Start after completing each full subject in FA
   - Biochemistry done → start Biochem UWorld block
   - Immunology done → start Immuno UWorld block  
   - Continue adding subjects as completed
9. EVENING (before sleep) — Open app → check tomorrow's revision due
10. EXAM PREP (after all FA done) — Remaining UWorld + NBME practice
```

---

## 📚 Study Materials

| Material | Use | Tracker |
|---|---|---|
| **First Aid 2025 (35th Ed)** | Primary source | FA Tracker |
| **NotebookLM** | Audio overview per page | External |
| **Anki** | Flashcards every 4 pages | FA Tracker (Anki status per page) |
| **Sketchy Micro** | Microbiology memorization | Sketchy Tracker |
| **Sketchy Pharma** | Pharmacology memorization | Sketchy Tracker |
| **Pathoma** | Pathology video review | Pathoma Tracker |
| **UWorld** | Question bank per subject | UWorld Tracker |
| **Amboss** | Clarification / verify info | External (free trial rotating) |
| ~~Boards & Beyond~~ | ~~Removed~~ | — |
| ~~Camus~~ | ~~Removed~~ | — |

---

## 📖 FA 2025 Section Map (Full)

| Section | Subject | Pages | Total Pages |
|---|---|---|---|
| Section I | Exam Prep Guide | 1–30 | 30 |
| **Section II** | **Biochemistry** | **31–92** | **62** |
| Section II | Immunology | 93–120 | 28 |
| Section II | Microbiology | 121–200 | 80 |
| Section II | Pathology (General) | 201–226 | 26 |
| Section II | Pharmacology | 227–254 | 28 |
| Section II | Public Health Sciences | 255–278 | 24 |
| **Section III** | **Cardiovascular** | **283–328** | **46** |
| Section III | Endocrine | 329–362 | 34 |
| Section III | Gastrointestinal | 363–408 | 46 |
| Section III | Hematology & Oncology | 409–448 | 40 |
| Section III | Musculoskeletal & Skin | 449–498 | 50 |
| Section III | Neurology & Special Senses | 499–568 | 70 |
| Section III | Psychiatry | 569–594 | 26 |
| Section III | Renal | 595–628 | 34 |
| Section III | Reproductive | 629–676 | 48 |
| Section III | Respiratory | 677–706 | 30 |

**Arsh's status:** Pages 33–49 = Biochemistry in progress.

---

## 🏗️ Tech Stack

- **Framework**: Flutter (Dart) — stable channel 3.29.x
- **State**: Provider (`AppProvider` as central state)
- **Storage**: SharedPreferences (local, no Firebase)
- **Navigation**: go_router
- **Animations**: Lottie (celebration animations)
- **CI/CD**: GitHub Actions — flutter analyze gate on every push
- **AI**: NOT integrated in app — Claude (this conversation) IS the AI

---

## 🏗️ Architecture

```
lib/
  main.dart                   — app entry, AppProvider init, loadAll(), seed FA data on first launch
  app_router.dart             — go_router route definitions
  providers/
    app_provider.dart         — central state: FA pages, KB, time logs, settings, trackers
    settings_provider.dart    — theme, dark mode, SRS mode, prayer times, sleep/wake, exam dates
  models/
    fa_page.dart              — FAPage: pageNum, title, subject, system, status, srsFields
    sketchy_item.dart         — SketchyItem: name, type (micro/pharma), status, srsFields
    pathoma_item.dart         — PathomaItem: chapter, subject, status
    uworld_session.dart       — UWorldSession: subject, done, correct, date
    task.dart                 — TodayPlanTask with block support
    knowledge_base.dart       — KnowledgeBaseEntry with SRS fields
    time_log.dart             — TimeLogEntry (auto + manual)
    session.dart              — StudySession record
    prayer_time.dart          — PrayerTime: name, azanTime, departureTime, returnTime
  services/
    srs_service.dart          — 12-step SRS intervals, strict/relaxed
    seed_service.dart         — Seeds FA 2025 pages on first launch
    backup_service.dart       — Auto local backup to device storage
    claude_import_service.dart — Parse + execute Claude Import JSON
  screens/
    dashboard/                — Home: time budget, pace insight, dual countdown, motivation
    today_plan/               — Task planner with time calculator + prayer blocks
    tracker/                  — Unified tracker: FA | Sketchy | Pathoma | UWorld tabs
    revision_hub/             — Morning/Evening revision queue, Mark Revised
    time_log/                 — Auto + manual time entries
    analytics/                — Pace chart, subject progress, projection
    claude_import/            — Paste JSON → preview → execute
    settings/                 — Prayer times, exam dates, sleep/wake, nav customizer
  utils/
    app_theme.dart            — Premium milky theme, light/dark, vibrant accents
    constants.dart            — kFmgeSubjects, kBodySystems, FA subjects, etc.
    text_sanitizer.dart       — Fix garbled UTF-8/Windows-1252 chars
  widgets/
    app_scaffold.dart         — Common scaffold with bottom nav + drawer
    celebration_overlay.dart  — Lottie animation overlay for milestone celebrations
  assets/
    data/
      fa_2025_seed.json       — Full FA 2025 page index (pre-bundled, seeds on first launch)
    lottie/
      confetti.json           — 10 pages done celebration
      sparkle.json            — Anki done celebration
      trophy.json             — Subject complete celebration
      streak_fire.json        — 7-day streak celebration
```

---

## 🎨 Design Language — PREMIUM

This app must feel like a ₹10,000 productivity app. Every interaction should feel satisfying.

| Element | Spec |
|---|---|
| **Light background** | `#F8F7FF` — warm white with barely-there lavender tint |
| **Dark background** | `#0E0E1A` — deep rich charcoal. NOT navy. NOT pure black. |
| **Primary accent** | `#6366F1` — vibrant indigo/violet |
| **Secondary accent** | `#818CF8` — lighter indigo for tags/chips |
| **Success** | `#22C55E` — clean green |
| **Warning** | `#F59E0B` — warm amber |
| **Cards light** | Pure white `#FFFFFF`, radius 16px, soft drop shadow |
| **Cards dark** | `#1A1A2E`, radius 16px, subtle glowing indigo border |
| **Typography** | `w700` for numbers/stats/titles, `w400` for body text |
| **Transitions** | Curved spring animations, slide-up sheets, hero transitions |
| **NO** | Pure black, flat UI, harsh borders, stock Material blue |

### Celebration Animations (Lottie)

| Trigger | Animation | Message |
|---|---|---|
| 10 FA pages done today | 🎉 Confetti burst | "10 pages crushed! FA is falling." |
| Anki batch (4 pages) complete | ✨ Sparkle | "Memory locked in. 🧠" |
| All daily revisions cleared | 🌟 Star burst | "Zero backlog. Clean slate." |
| 7-day streak | 🔥 Fire animation | "7 days straight. You're dangerous." |
| Subject fully completed | 🏆 Trophy drop | "Biochemistry: DONE. Next victim?" |
| Daily goal hit before 6 PM | ⚡ Lightning | "Done early! Extra time is yours." |
| 30-day streak | 👑 Crown | "One month. Unbreakable." |

---

## 📱 Screen Map — Final

### ❌ DELETED (removed from app)

- AI Mentor / Chat screen
- AI Memory screen
- Info Files / Data screen
- FMGE Prep (standalone screen)
- Daily Tracker (merged into Today's Plan)
- Study Tracker (merged into Dashboard)
- Calendar (standalone — just show countdown on Dashboard)
- Focus Timer (standalone — integrate into session blocks)

### ✅ SCREENS IN APP

| # | Screen | Description |
|---|---|---|
| 1 | **Dashboard** | Time budget, pace insight, dual countdown, revision due, today goals, motivation |
| 2 | **Today's Plan** | Time calculator, prayer blocks auto-filled, task types, overflow alert |
| 3 | **Tracker** | Unified: FA 2025 \| Sketchy \| Pathoma \| UWorld tabs |
| 4 | **Revision Hub** | SRS due queue, morning/evening mode, Mark Revised |
| 5 | **Claude Import** | Paste JSON from Claude → preview actions → execute |
| 6 | **Analytics** | Pace chart, subject distribution, exam projection |
| 7 | **Time Logger** | Manual + auto time entries |
| 8 | **Settings** | Prayer times, exam dates, sleep/wake, daily goals, nav customizer |

---

## 📲 Bottom Navigation Structure

```
[ Dashboard ]  [ Revision ]  [ Today's Plan ]  [ Tracker ]  [ More ▲ ]
```

- **4 pinned tabs** — customizable in Settings (user picks which 4 to pin)
- **"More" is PERMANENT** — always 5th tab, never removable
- Tapping **More** → slides up bottom sheet grid showing all remaining screens
- **Full Screen Mode** (toggle in Settings): hides bottom nav entirely → hamburger top-left → opens side drawer with all screens listed

---

## 🖥️ Dashboard — Widget Layout

```
┌─────────────────────────────────────────┐
│  FMGE: 123 days    Step 1: ~118 days    │  ← Dual countdown cards
├─────────────────────────────────────────┤
│  ⏰ 7h 20min available today            │  ← Time budget
│  Sleep 9PM · Prayers 1h30m · Tasks 45m │
├─────────────────────────────────────────┤
│  📈 8.3 pages/day avg                   │  ← Pace insight
│  FA done: May 1 · ✅ On track FMGE     │
│  ⚠️ Push to 10/day for Step 1 buffer   │
├─────────────────────────────────────────┤
│  TODAY'S GOALS                          │
│  FA Pages  ████░░  6/10                 │
│  Anki      ██████  Done ✅              │
│  Sketchy   ██░░░░  1/2                  │
│  Revision  3 due  →                     │
├─────────────────────────────────────────┤
│  🔥 Day 4 streak · 17 FA pages total    │  ← Streak + motivation
└─────────────────────────────────────────┘
```

---

## 📥 Claude Import — JSON Schema

This is how Claude fills the app. At the end of every planning conversation, Claude generates this block. Arsh pastes it into the Claude Import screen.

```json
{
  "import_version": "1.0",
  "date": "2026-02-25",
  "actions": [
    {
      "type": "mark_fa_pages_read",
      "from_page": 50,
      "to_page": 59,
      "subject": "Biochemistry",
      "anki_done": false
    },
    {
      "type": "mark_fa_anki_done",
      "from_page": 46,
      "to_page": 49
    },
    {
      "type": "add_today_task",
      "title": "Cook lunch",
      "category": "PERSONAL",
      "time_start": "13:00",
      "time_end": "15:00"
    },
    {
      "type": "add_study_block",
      "block_type": "SKETCHY_MICRO",
      "items": ["S. aureus", "S. epidermidis"],
      "time_start": "16:00",
      "time_end": "17:00"
    },
    {
      "type": "log_uworld_session",
      "subject": "Biochemistry",
      "questions_done": 10,
      "correct": 7
    },
    {
      "type": "set_daily_goals",
      "fa_pages_per_day": 10,
      "sketchy_micro_per_day": 2
    },
    {
      "type": "set_exam_dates",
      "fmge": "2026-06-28",
      "step1_approx_days": 118
    }
  ]
}
```

---

## 🙏 Prayer Time Settings (Vijayawada Defaults)

Arsh will update exact times. Until then, app uses these February 2026 defaults:

| Prayer | Azan | App Departure | Return |
|---|---|---|---|
| Fajr | 05:35 | 05:25 | 06:05 |
| Dhuhr | 12:48 | 12:38 | 13:18 |
| Asr | 16:18 | 16:08 | 16:48 |
| Maghrib | 18:22 | 18:12 | 18:52 |
| Isha | 19:48 | 19:38 | 20:18 |

**Buffer logic**: Departure = Azan − 10 min. Return = Azan + 20 min. Total = 30 min per prayer.

---

## 🔄 The Antigravity Workflow (Updated)

```
[Arsh] describes what he wants / his day / what he studied
      ↓
[Claude] reads MASTER_PLAN + PROGRESS → understands full context
      ↓
[Claude] makes decisions: direct push OR Gemini/Sonnet/Opus prompt
      ↓
  DIRECT PUSH (minor changes, bug fixes, file updates, data seeds)
      ↓
  OR: Claude writes spoon-fed prompt → Arsh pastes to model in Codespaces
      ↓
  Model writes + commits code (analyze + push baked in)
      ↓
[CI] flutter analyze runs on push → pass or fail
      ↓
  PASS → Arsh tests on device → Claude updates PROGRESS.md
  FAIL → Arsh pastes error to Claude → Claude pushes direct fix
      ↓
[Claude] generates Claude Import JSON block for Arsh's daily plan
```

### Model Assignment Guide

| Task | Model | Why |
|---|---|---|
| Color/theme/UI tweaks | Gemini 3 Flash | Fast, good at UI |
| Single widget/screen | Gemini 3 Flash | Adequate quality |
| New screen with state logic | Gemini 3 Pro High | Needs accuracy |
| Claude Import parser/executor | Claude Sonnet 4.6 | Complex parsing logic |
| Dashboard rebuild (complex UI + logic) | Claude Opus 4.6 | Highest quality |
| Multi-file architecture changes | Claude Opus 4.6 | Needs full context |
| FA seed generation | Direct Claude push | I generate the JSON |
| Bug fixes | Direct Claude push | Fastest path |

### Hallucination Prevention Rules (every Gemini prompt)
```
STRICT RULE: Only use Flutter/Dart APIs you are 100% certain exist.
Do NOT invent parameter names. If unsure, use the simplest known alternative.

Read these files fully before writing anything:
- [list relevant files]

[Exact code blocks to insert]

DO NOT TOUCH:
- [list files to leave alone]

flutter analyze --no-fatal-infos
Fix any errors found, then:
git add [files changed]
git commit -m "[message]"
git push origin main
```

---

## 📊 Full Batch Execution Plan

| Batch | Name | Status | Model |
|---|---|---|---|
| A | Android build setup | ✅ Done | — |
| B | Data persistence | ✅ Done | — |
| C | Navigation fixes | ✅ Done | — |
| D | SRS + KB + Task Planner | ✅ Done | 3 Pro High |
| E | Session Timer + FA Logger | ✅ Done | 3 Pro High |
| F | Critical bug fixes | ✅ Done | 3 Pro High |
| Bug | TextSanitizer + revision card | ✅ Done | Direct push |
| G1 | Milky theme | ✅ Done | 3 Flash |
| G2 | KB garbled chars + manual add | ✅ Done | 3 Pro High |
| **G3** | **Screen cleanup** (delete 8 dead screens) | 📋 Next | Direct push |
| **G4** | **Bottom nav redesign** (4 tabs + More + customizable + drawer mode) | 📋 Next | Sonnet 4.6 |
| **G5** | **Tracker screen** (unified FA/Sketchy/Pathoma/UWorld tabs) | 📋 Planned | Opus 4.6 |
| **G6** | **FA 2025 pre-seed** (bundle asset, seed on first launch) | 📋 Planned | Direct push |
| **G7** | **Bulk FA page range marker** | 📋 Planned | Flash |
| **G8** | **Dashboard rebuild** (time budget, pace insight, dual countdown) | 📋 Planned | Opus 4.6 |
| **G9** | **Today's Plan rebuild** (time calculator, prayer blocks, overflow) | 📋 Planned | Pro High |
| **G10** | **Settings expansion** (prayer times, exam dates, sleep/wake, nav) | 📋 Planned | Sonnet 4.6 |
| **G11** | **Motivation system** (Lottie celebrations, milestone triggers) | 📋 Planned | Flash |
| **G12** | **Claude Import window** (JSON parser, preview, executor) | 📋 Planned | Pro High |
| **G13** | **Auto local backup** (device storage, restore on reinstall) | 📋 Planned | Pro High |
| H | Analytics (pace chart, projection, subject distribution) | 📋 Planned | Flash |
| I | Final polish (alarm, math challenge wake, icons, onboarding) | 📋 Planned | Flash |

---

## 📝 Key Decisions Log

| Date | Decision | Reason |
|---|---|---|
| Feb 24 | Provider over Riverpod | Simpler, less boilerplate |
| Feb 24 | SharedPreferences over Firebase | No auth needed, fully offline |
| Feb 24 | go_router over Navigator 2 | Named routes, deep linking ready |
| Feb 24 | 12-step SRS | Tuned for FA page review cadence |
| Feb 25 | Gemini 3 Flash for UI, Pro High for logic | Quality vs speed |
| Feb 25 | STRICT RULE header in all prompts | Prevents Gemini API hallucinations |
| Feb 25 | TextSanitizer utility | AI JSON had double-encoded UTF-8 |
| Feb 25 | Milky theme (not pure black/white) | iOS-inspired, easy on eyes |
| Feb 25 | **App is personal only — Arsh, not public** | Focus on passing exams, not product |
| Feb 25 | **Gemini AI removed from app** | Claude is the AI brain via Claude Import |
| Feb 25 | **Claude Import replaces AI Mentor** | More reliable, no API key, better context |
| Feb 25 | **FA 2025 content pre-bundled as asset** | Zero manual entry, seeds on first launch |
| Feb 25 | **Lottie for celebrations** | Smooth 60fps, lightweight JSON animations |
| Feb 25 | **Bottom nav: 4 custom + permanent More** | Clean, not cluttered, user-customizable |
| Feb 25 | **Tracker = unified screen** | FA + Sketchy + Pathoma + UWorld in one place |
| Feb 25 | **Premium vibrant design** | App must feel ₹10,000 quality, smooth, joyful |
