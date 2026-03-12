# 🔒 Security Policy — FocusFlow Mobile

## What Is Protected

This repository follows strict security practices to protect:
- Firebase API keys and project configuration
- Android release signing keystores
- User study data and personal information
- AI agent session data (`.cognetivy/`, `.claude/`)

---

## ❌ Files That Must NEVER Be Committed

| File | Why It's Dangerous |
|------|--------------------|
| `android/app/google-services.json` | Contains Firebase API keys — gives full backend access |
| `ios/Runner/GoogleService-Info.plist` | Same as above for iOS |
| `lib/firebase_options.dart` | Firebase config with project ID and keys |
| `*.jks` / `*.keystore` | Android signing key — can be used to impersonate your app |
| `key.properties` | Contains keystore password in plaintext |
| `.env` | API keys, secrets, environment variables |
| `.cognetivy/` | AI session history — contains full code context |
| `.cursor/mcp.json` | MCP server config — can expose tool access |

All of the above are covered in `.gitignore`.

---

## ✅ How Secrets Are Managed

- Firebase config files are generated **during CI/CD** from GitHub Secrets
- Android keystore is stored as `ANDROID_KEYSTORE_BASE64` in GitHub Secrets
- No secrets are ever hardcoded in source code

---

## 🤖 AI Agent Safety (Codex / Antigravity)

When using AI coding agents (OpenAI Codex, Antigravity, Cursor, Claude Code):

1. **Never paste your Firebase config** into an AI chat — use placeholder values in prompts
2. **Never share your keystore password** with an AI agent
3. **Add `.cognetivy/` to `.gitignore`** before using Cognetivy on this project
4. Agents like Codex can **read all files in your repo** — ensure no secrets exist before granting access
5. Review every file an agent creates before committing

---

## 🚨 Agency Agents Safety Note

The `.github/agents/` folder contains **AI system prompt files only** — plain Markdown.
They contain:
- ✅ Project architecture descriptions
- ✅ Code style guidelines  
- ✅ Flutter/Firebase patterns
- ❌ NO actual API keys
- ❌ NO passwords or secrets
- ❌ NO user data

These files are **safe to be public**. They are instructions for AI, not credentials.

---

## 📣 Reporting a Vulnerability

If you find a security issue, **do not open a public GitHub issue**.
Contact the repo owner privately via GitHub Security Advisories.
