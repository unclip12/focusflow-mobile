# 🤖 FocusFlow AI Agent Suite

This folder contains specialized AI agent system prompts for the FocusFlow Mobile development workflow. Each agent is a `.md` file you paste as a **system prompt** into your AI tool of choice (Claude, Gemini, ChatGPT) to get expert-level, project-specific assistance.

Inspired by [Agency Agents](https://github.com/msitarzewski/agency-agents) — an open-source collection of AI agent prompts.

---

## 📋 Available Agents

| Agent | File | When to Use |
|-------|------|-------------|
| 📲 Mobile App Builder | `MOBILE_APP_BUILDER.md` | Writing Flutter code, fixing bugs, implementing features |
| 🎨 UI Designer | `UI_DESIGNER.md` | Designing screens, building components, animation work |
| 🚀 DevOps Automator | `DEVOPS_AUTOMATOR.md` | GitHub Actions, CI/CD, Firebase deployment |
| ⚡ Rapid Prototyper | `RAPID_PROTOTYPER.md` | Validating new feature ideas fast |
| 🔒 Security Engineer | `SECURITY_ENGINEER.md` | Firebase rules, auth security, data protection |

---

## 🛠️ How to Use

### Method 1 — Paste in Chat (Claude/ChatGPT/Gemini)
1. Open the agent `.md` file
2. Copy the full contents
3. Paste it as the **first message** or **system prompt** in your AI chat
4. Start asking FocusFlow-specific questions

### Method 2 — GitHub Codespaces + Copilot
1. Open Codespaces on this repo
2. Open the relevant agent file
3. Reference it in your Copilot Chat: `@workspace Use the agent in .github/agents/MOBILE_APP_BUILDER.md`

### Method 3 — Cursor/Windsurf IDE
1. Add the agent file to your project context
2. The AI will automatically adopt the persona for FocusFlow-specific answers

---

## 🔄 Recommended Workflow

```
New Feature Request
       ↓
⚡ Rapid Prototyper → Validate idea fast
       ↓
📲 Mobile App Builder → Build production code
       ↓
🎨 UI Designer → Polish the UI
       ↓
🔒 Security Engineer → Review before release
       ↓
🚀 DevOps Automator → Deploy to Firebase App Distribution
```

---

## 🤝 Contributing

If you create a new agent prompt that's useful for FocusFlow development, add it here with:
- A clear `name` and `description` in the frontmatter
- Project-specific context (don't make it generic)
- A "How to Use" section with example prompts

---
*Based on [Agency Agents](https://github.com/msitarzewski/agency-agents) by msitarzewski — MIT License*
