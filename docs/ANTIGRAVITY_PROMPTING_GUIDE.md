# Antigravity IDE Prompting Guide — FocusFlow Mobile

> Based on a leaked Chain-of-Thought log from r/google_antigravity (March 2026).
> A UI bug in Antigravity exposed the agent's raw `<rrthought>` inner monologue,
> revealing exactly how tokens are burned before any code is written.

---

## What Happens Under the Hood

Every prompt you send to Antigravity triggers this hidden loop **before** the agent writes a single line:

1. **Re-reads system rules** (CRITICAL INSTRUCTION blocks repeat every single tool call)
2. **Searches for relevant files** using `grep_search`, `find_by_name`, `list_dir`
3. **Plans the approach** and self-checks against its tool rules
4. **Debates edge cases** (e.g., "should I use task_boundary or not?")
5. **Only then** writes code via `write_to_file` or `multi_replace_file_content`

This means vague prompts = massive hidden token cost. Every extra planning step burns your quota.

### Antigravity's Internal Tool List (from the leak)
```
grep_search, find_by_name, view_file, list_dir,
task_boundary, write_to_file, multi_replace_file_content
```

---

## The Golden Rule: Be a GPS, Not a Tour Guide

Give the agent exact coordinates, not a destination. The more specific your prompt, the less the agent has to search/plan.

---

## Prompting Rules for FocusFlow

### ✅ DO: Reference Exact File Paths
```
❌ Bad:  "Update the timer widget styling"
✅ Good: "In lib/features/timer/widgets/timer_display.dart, change the 
          container color from Colors.grey to AppColors.surface"
```

### ✅ DO: One Atomic Task Per Prompt
```
❌ Bad:  "Fix the session screen UI and also update the Hive storage logic"
✅ Good: Prompt 1 → "Fix session screen UI in lib/features/session/..."
         Prompt 2 → "Update Hive logic in lib/data/repositories/..."
```

### ✅ DO: Name Exact Classes, Functions, and Selectors
```
❌ Bad:  "Fix the flashcard flip animation"
✅ Good: "In FlashcardWidget._buildFlipAnimation(), change the duration 
          from 300ms to 200ms"
```

### ✅ DO: Specify the Change Type Explicitly
Tell it which tool intent to use:
- **"Replace"** → triggers `multi_replace_file_content` (fast)
- **"Add after line X"** → triggers `write_to_file` at position (fast)
- **"Find all usages of X"** → triggers `grep_search` (scoped)

### ❌ AVOID: Open-Ended Prompts
```
❌ "Improve the focus session screen"
❌ "Make the app feel smoother"
❌ "Refactor the timer logic"
```
These force a full-codebase planning loop — the most expensive operation possible.

### ❌ AVOID: Compound Requests
Every additional task in a single prompt = another full planning loop stacked on top.

---

## Token Cost Reference

| Prompt Style | Agent Behavior | Token Cost |
|---|---|---|
| `"Improve the app"` | Full codebase scan + broad planning | 🔴 Very High |
| `"Fix the timer on session screen"` | Feature-scoped search + planning | 🟡 Medium |
| `"In file.dart, change X to Y"` | Direct write, minimal planning | 🟢 Low |
| `"Replace className in lib/x/y.dart"` | Single tool call, near-zero overhead | 🟢 Minimal |

---

## FocusFlow-Specific File Map (Quick Reference)

Use these paths in prompts to skip the agent's file-finding step entirely:

```
lib/
├── features/
│   ├── timer/          → Timer/Pomodoro logic & widgets
│   ├── flashcards/     → Flashcard deck, flip animations
│   ├── session/        → Study session screens
│   └── dashboard/      → Home/dashboard UI
├── data/
│   ├── repositories/   → Hive/local storage logic
│   └── models/         → Data models
├── core/
│   ├── theme/          → AppColors, AppTheme, typography
│   └── widgets/        → Shared/reusable widgets
└── main.dart
```

---

## If the Agent Starts Looping

Signs of an agent panic spiral (token drain):
- It re-reads the same rules 3+ times
- It calls `grep_search` for something already found
- It debates `task_boundary` errors repeatedly

**Action**: Halt the session immediately and re-prompt with a more specific, file-referenced instruction. Letting it spiral can consume 15–20% of your session quota on a single task.

---

## Prompt Templates for Common FocusFlow Tasks

### Styling Change
```
In [exact/path/to/widget.dart], update [WidgetName]'s [property] 
from [old value] to [new value].
```

### Logic Fix
```
In [exact/path/to/file.dart], inside [MethodName()], 
fix [describe the specific bug]. The current behavior is [X], expected is [Y].
```

### New Feature (scoped)
```
Add a [feature name] to [exact/path/to/screen.dart]. 
It should [single specific behavior]. 
Place it after [existing element/method name].
```

### Dependency / State Update
```
In [provider/bloc file path], update [StateClass] to include 
a new field [fieldName] of type [Type]. 
Wire it to [specific widget path].
```

---

*Last updated: March 2026 | Source: r/google_antigravity leak analysis*
