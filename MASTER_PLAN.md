# FocusFlow Mobile — Master Plan

> A medical study companion for USMLE Step 1 and FMGE students.
> Built with Flutter. AI-powered. Spaced-repetition at the core.

---

## 🎯 App Vision

FocusFlow Mobile is a **study OS** for medical students.
Not a flashcard app. Not a timer app. A full study operating system that:
- Plans your day around what's due for revision (SRS-driven)
- Tracks time at the FA-page level (not just subject level)
- Uses AI to generate study plans, debrief sessions, and detect weak areas
- Keeps a Knowledge Base of every FA page you've studied with SRS scheduling
- Runs beautifully on Android with a milky, iOS-inspired design

---

## 📁 Repository
`github.com/unclip12/focusflow-mobile`

## 🔧 Tech Stack
- **Framework**: Flutter (Dart) — stable channel 3.29.x
- **State**: Provider (`AppProvider` as central state)
- **Storage**: SharedPreferences (local, no Firebase yet)
- **Navigation**: go_router
- **AI**: Gemini API (planned — Batch H)
- **CI/CD**: GitHub Actions — flutter analyze gate on every push

---

## 🏗️ Architecture

```
lib/
  main.dart               — app entry, AppProvider init, loadAll()
  app_router.dart         — go_router route definitions
  providers/
    app_provider.dart     — central state: tasks, KB, time logs, settings
    settings_provider.dart — theme, dark mode, SRS mode
  models/
    task.dart             — TodayPlanTask with block support
    knowledge_base.dart   — KnowledgeBaseEntry with SRS fields
    time_log.dart         — TimeLogEntry (auto + manual)
    session.dart          — StudySession record
  services/
    srs_service.dart      — 12-step SRS intervals, strict/relaxed
    gemini_service.dart   — AI functions (Batch H)
  screens/
    dashboard/            — Home: streak, blocks done, due count
    today_plan/           — Task creation + block start → session
    session/              — Timer + quotes + completion
    knowledge_base/       — KB list + detail + manual add entry
    revision_hub/         — Due/Upcoming cards, Mark Revised
    fa_logger/            — FA page log + stats
    time_log/             — Auto + manual time entries
    analytics/            — Charts (Batch I)
    mentor/               — AI Mentor (Batch H)
    settings/             — Theme, dark mode, SRS mode
    study_plan/           — Study plan generator
    calendar/             — Calendar view
  utils/
    app_theme.dart        — 12 themes, light/dark, milky aesthetic
    constants.dart        — kFmgeSubjects, kBodySystems, etc.
    text_sanitizer.dart   — Fix garbled UTF-8/Windows-1252 chars
  widgets/
    app_scaffold.dart     — Common scaffold with nav
```

---

## 🔄 The Antigravity Workflow

```
[You] describe what you want
      ↓
[Claude] reads repo files → writes precise Gemini prompt
      ↓
[You] paste prompt to Gemini in Codespaces terminal
      ↓
[Gemini] writes + commits code (analyze + push baked in)
      ↓
[CI] flutter analyze runs on push → pass or fail
      ↓
  PASS → test on device → next batch
  FAIL → paste error to Claude → Claude pushes direct fix
```

### Why This Works
- **Claude** = architect, knows the repo, writes safe prompts
- **Gemini** = executor, fast at repetitive code changes
- **CI** = safety net, catches Gemini hallucinations before they ship
- **GitHub** = single source of truth, no context loss between sessions

### Hallucination Prevention Rules (in every prompt)
1. `STRICT RULE: Only use Flutter/Dart APIs you are 100% certain exist.`
2. `Read these files fully before writing a single line of code:`
3. Exact code blocks to paste (no guessing)
4. Explicit `DO NOT TOUCH` list
5. `flutter analyze --no-fatal-infos` as the last step before push

---

## 📊 Batch Execution Plan

| Batch | Name | Status | Model |
|---|---|---|---|
| A | Android build setup | ✅ Done | — |
| B | Data persistence | ✅ Done | — |
| C | Navigation fixes | ✅ Done | — |
| D | SRS + KB + Task Planner | ✅ Done | 3 Pro High |
| E | Session Timer + FA Logger | ✅ Done | 3 Pro High |
| F | Critical bug fixes | ✅ Done | 3 Pro High |
| Bug | TextSanitizer + revision card | ✅ Done | Direct push |
| G1 | Milky theme | 🔄 Running | 3 Flash |
| G2 | KB garbled chars + manual add | 🔄 Running | 3 Pro High |
| H | Gemini AI Service (14 fn) | 📋 Next | 3 Pro High |
| I | Analytics & charts | 📋 Planned | 3 Flash |
| J | Notifications | 📋 Planned | 3 Flash |
| K | Backup & export | 📋 Planned | 3 Pro High |
| L | Polish & release prep | 📋 Planned | 3 Flash |

---

## 🚀 Continue In New Chat

Paste this at the start of a new Claude chat:

---

```
You are continuing development of FocusFlow Mobile.
Repo: github.com/unclip12/focusflow-mobile
Owner: unclip12

Before answering anything, read these files from the repo:
- MASTER_PLAN.md     (architecture, workflow, batch plan)
- PROGRESS.md        (what's done, what's in progress, what's next)

Context:
- Flutter app, stable 3.29.x, Provider state, go_router, SharedPreferences
- Central state: AppProvider (lib/providers/app_provider.dart)
- CI: GitHub Actions with flutter analyze gate
- Workflow: Claude writes Gemini prompts → Gemini runs in Codespaces → errors fixed by Claude directly
- Gemini hallucinates API params sometimes — CI catches it — paste errors here for direct fix

Current status from last session:
- Batches A–F fully complete and pushed
- G1 (milky theme) prompt given to Gemini 3 Flash — may or may not have run yet
- G2 (KB garbled chars + manual add entry) prompt given to Gemini Pro High — may or may not have run yet
- If G1/G2 failed with errors, paste the errors and I'll fix directly
- If G1/G2 passed, next up is Batch H: Gemini AI Service integration

Please read MASTER_PLAN.md and PROGRESS.md now, then ask what I want to work on next.
```

---

## 📝 Key Decisions Log

| Date | Decision | Reason |
|---|---|---|
| Feb 24 | Provider over Riverpod | Simpler, less boilerplate, team familiar |
| Feb 24 | SharedPreferences over Firebase | No auth needed yet, fully offline |
| Feb 24 | go_router over Navigator 2 | Named routes, deep linking ready |
| Feb 24 | 12-step SRS (not Anki) | Tuned for FA page review cadence |
| Feb 25 | Gemini 3 Flash for UI, Pro High for logic | Quality vs speed tradeoff |
| Feb 25 | STRICT RULE header in all prompts | Prevents Gemini API hallucinations |
| Feb 25 | TextSanitizer utility | AI JSON content had double-encoded UTF-8 |
| Feb 25 | Milky theme (not pure black/white) | iOS-inspired, easier on eyes for study |

---

## 🎨 Design Language

- **Light mode**: Soft white-lavender milk backgrounds, subtle drop shadows on cards
- **Dark mode**: Soft charcoal (not navy, not black) — iOS-style dark, readable
- **12 themes**: Flow White, Midnight Deep, Mystic Forest, Deep Ocean, Pastel Sunset,
  Soft Lilac, Cloudy Sky, Citrus Burst, Royal Violet, Fresh Mint, Warm Peach, Night Sky
- **Typography**: Clean, high-contrast, `w600`/`w700` for data, `w400` for descriptions
- **Radius**: 12–16px on cards, 8px on chips
- **No pure black backgrounds** — minimum dark bg is `#121212`-style charcoal

---

## 🧙 Batch H Detail — Gemini AI Service

This is the most complex batch. Use **3 Pro High with High thinking**.

### 14 Functions to Implement

1. `generateStudyPlan(examDate, weakSubjects, dailyHours)` → JSON plan
2. `debriefSession(sessionData, kbEntry)` → feedback string
3. `autoTagKBEntry(rawContent)` → subject, system, keyPoints
4. `generateMCQ(kbEntry)` → USMLE-style question with options + explanation
5. `detectWeakAreas(timeLogs, kbEntries)` → ranked weak area list
6. `getDailyMotivation(streak, examDate)` → motivational string
7. `getExamCoaching(daysLeft, coverage)` → strategy advice
8. `summarizeFAPage(pageContent)` → condensed summary
9. `analyzeMistakePatterns(wrongAnswers)` → pattern report
10. `rankRevisionPriority(kbEntries)` → sorted list by urgency
11. `predictStudyTime(topic, userHistory)` → estimated minutes
12. `detectKnowledgeGaps(kbEntries, qbankData)` → gap list
13. `analyzeQbankPerformance(results)` → subject performance map
14. `generateStudyTip(currentFocus, timeOfDay)` → tip string

### File to Create
`lib/services/gemini_service.dart`

### Files to Update
- `lib/screens/mentor/mentor_screen.dart` — wire all 14 functions
- `lib/providers/app_provider.dart` — expose AI results
- `pubspec.yaml` — add `google_generative_ai` package if not present
