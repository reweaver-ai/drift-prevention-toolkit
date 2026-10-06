---
name: drift-toolkit-multi-agent
description: "Use when several AI agents or sub-agents work on one codebase at the same time, or before spawning parallel agents to edit code. One file, one writer."
---

# Skill: Multi-Agent Safety — One File, One Writer

## Core Principle

When an AI assistant spawns sub-agents to work in parallel, those agents must never edit the same file concurrently. Parallel reads are safe. Parallel writes to the same file cause silent data loss.

**Applies to**: Any AI coding assistant that edits files via text matching or diff application — Claude Code, Cursor, Cline, Windsurf, and similar tools. The specific mechanism varies (exact string match, diff apply, search/replace blocks) but the race condition is identical.

---

## The Problem

AI coding assistants use string-replacement to edit files: they match an exact block of old text and replace it with new text. When two agents edit the same file at the same time:

1. Agent A reads the file and plans an edit targeting lines 40-45
2. Agent B reads the same file and plans an edit targeting lines 42-50
3. Agent A writes its replacement — the file changes on disk
4. Agent B writes its replacement using the **old** text it read in step 2 — overwriting Agent A's changes

The result: Agent A's work is silently reverted. No error is thrown. No warning appears. The agent reports success.

---

## The Misdiagnosis Pattern

When this happens, the AI assistant will typically blame everything except itself:

| What the AI says | Why it's wrong |
|-----------------|----------------|
| "Your IDE is auto-fixing files" | IDE auto-fix requires explicit configuration — check your settings |
| "Auto-save is restoring files" | Auto-save writes the editor buffer to disk — it doesn't revert content |
| "The language server is modifying your code" | Language servers provide diagnostics and completions — they don't write to files |
| "Git fetch is causing conflicts" | `git fetch` updates remote refs — it never touches the working tree |
| "I don't know, here are five possible causes" | The AI is guessing instead of investigating |

**The fix is always the same**: don't let multiple agents write to the same file at the same time.

---

## Rules — Enforced

### 1. One Writer Per File

If a file needs editing, exactly one agent edits it. No exceptions.

```
❌ FORBIDDEN — Two agents editing the same file
Agent A → edits DashboardViews.swift (lines 10-30)
Agent B → edits DashboardViews.swift (lines 50-70)

✅ REQUIRED — One agent per file
Agent A → edits DashboardViews.swift (all changes)
Agent B → edits MainViews.swift (all changes)
```

### 2. Parent Doesn't Edit What It Delegates

If you spawn an agent to edit a file, do not edit that file yourself until the agent returns.

```
❌ FORBIDDEN
spawn Agent A to edit config.ts
[parent edits config.ts while Agent A is running]

✅ REQUIRED
spawn Agent A to edit config.ts
[wait for Agent A to return]
[then parent can edit config.ts]
```

### 3. Parallel Reads, Serial Writes

Parallel agents are excellent for research — reading files, searching codebases, fetching documentation. Only writes must be serialized per file.

```
✅ SAFE — Parallel reads
Agent A → reads and analyzes src/auth/
Agent B → reads and analyzes src/billing/

✅ SAFE — Parallel writes to different files
Agent A → edits auth.ts
Agent B → edits billing.ts

❌ UNSAFE — Parallel writes to the same file
Agent A → edits utils.ts
Agent B → edits utils.ts
```

### 4. Bulk Renames Are One-Agent Jobs

A find-and-replace across many files looks parallelizable but isn't. The gap between reading a file and writing the replacement creates a window for collisions.

```
❌ FORBIDDEN — Split rename across agents
Agent A → renames "quality" to "readiness" in files 1-5
Agent B → renames "quality" to "readiness" in files 6-10
Agent C → renames "quality" to "readiness" in files 11-15

✅ REQUIRED — One agent, one pass
Agent A → renames "quality" to "readiness" in all 15 files
```

### 5. Verify After Agent Returns

When an agent reports completion, spot-check the files it touched. Look for:
- Changes from earlier in the session that are now missing
- Code that has reverted to the version from before you started working
- Partial renames (some instances changed, others not)

### 6. Commit Before Delegating

Committing doesn't prevent the race condition, but it gives you a clean rollback point. If an agent makes a mess, you can `git diff` to see exactly what was lost and `git checkout -- <file>` to recover.

---

## How to Detect This Has Happened

Signs that agents silently overwrote each other:

1. **Partial completion** — The agent says "done" but only some files were changed
2. **Reverted changes** — Code you modified earlier in the session is back to its original state
3. **Mixed state** — Some parts of a file have new changes, other parts have regressed
4. **Edit tool failures** — "old_string not found" errors, meaning the file changed between read and write

---

## Investigation Protocol

If you suspect silent overwrites, don't guess. Investigate:

1. **Check your IDE settings** — Is anything configured to auto-modify files? (`formatOnSave`, `codeActionsOnSave`, auto-fix extensions)
2. **Check git diff** — Compare working tree to last commit. Are changes missing that you know were made?
3. **Check agent logs** — Did multiple agents report editing the same file?
4. **Don't accept "probably X"** — If the AI lists five possible causes without checking any of them, it's guessing. Make it investigate.
