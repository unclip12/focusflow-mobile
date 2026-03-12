# 🛠️ FocusFlow Mobile — Development Guide

## 📦 Tech Stack
| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart) |
| State Management | Riverpod / Provider |
| Backend | Firebase (Auth + Firestore + Storage) |
| Local DB | Hive / Isar |
| ML / OCR | Google ML Kit |
| CI/CD | GitHub Actions |
| Distribution | Firebase App Distribution |

---

## 🏗️ Project Structure
```
lib/
├── core/           # App-wide utilities, constants, theme
│   ├── theme/      # Liquid glass design system
│   ├── utils/      # Helpers, extensions
│   └── widgets/    # Shared GlassCard, PrimaryButton, etc.
├── features/
│   ├── auth/       # Login, signup, auth wrapper
│   ├── timer/      # Focus timer, Pomodoro
│   ├── qbank/      # Flashcard decks, spaced repetition
│   ├── tasks/      # Task manager, subtasks
│   ├── analytics/  # Study streaks, heatmaps
│   └── settings/   # User preferences, profile
├── services/
│   ├── firebase/   # Firestore, Auth, Storage wrappers
│   └── local/      # Hive boxes, offline cache
test/
├── unit/
├── widget/
└── integration/
```

---

## 🚀 Getting Started

```bash
# Clone
git clone https://github.com/unclip12/focusflow-mobile.git
cd focusflow-mobile

# Install dependencies
flutter pub get

# Set up environment
cp .env.example .env
# Fill in your Firebase config

# Run on device
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## 🤖 AI Development Workflow

This project uses [Agency Agents](https://github.com/msitarzewski/agency-agents) — specialized AI prompts for each role.
See `.github/agents/README.md` for the full agent suite.

### Recommended Session Flow
1. **New feature?** → Start with ⚡ `RAPID_PROTOTYPER.md`
2. **Building production code?** → Use 📲 `MOBILE_APP_BUILDER.md`
3. **UI work?** → Switch to 🎨 `UI_DESIGNER.md`
4. **Pre-release review?** → Run through 🔒 `SECURITY_ENGINEER.md`
5. **Deploying?** → Use 🚀 `DEVOPS_AUTOMATOR.md`

---

## 📋 Batch Development Process

Arsh's preferred workflow — implement in batches:

**Batch 1** — Core scaffold (navigation, theme, auth)
**Batch 2** — Focus Timer feature (complete)
**Batch 3** — Q-Bank / Flashcards (complete)
**Batch 4** — Task Manager (complete)
**Batch 5** — Analytics + Firebase sync
**Batch 6** — Polish, animations, 120fps optimization
**Batch 7** — Security review + production prep
**Batch 8** — CI/CD setup + store deployment

---

## 🎨 Design System

### Colors
```dart
const primaryBg = Color(0xFF0A0E1A);      // Deep navy
const accent = Color(0xFF4F8EF7);          // Electric blue  
const surfaceGlass = Color(0x0FFFFFFF);   // Glass surface
const textPrimary = Color(0xFFFFFFFF);    // White
const textSecondary = Color(0xFF8892A4); // Muted
```

### Spacing (8px grid)
```dart
const s4 = 4.0;   // Micro
const s8 = 8.0;   // Small
const s16 = 16.0; // Default
const s24 = 24.0; // Medium
const s32 = 32.0; // Large
```

---

## 🔒 Security Checklist (Pre-Release)
- [ ] `google-services.json` in `.gitignore`
- [ ] `GoogleService-Info.plist` in `.gitignore`  
- [ ] `.env` in `.gitignore`
- [ ] Firestore rules require `request.auth.uid`
- [ ] Firebase App Check enabled
- [ ] Release build uses `--obfuscate --split-debug-info`
- [ ] All API keys in GitHub Secrets (not hardcoded)

---

*See `.github/agents/` for AI development agent prompts.*
