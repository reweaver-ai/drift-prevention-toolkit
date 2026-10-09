# Changelog

## 1.4.2 — The checklist is enforced where the edits are made (October 2026)

- **Fixed:** the checklist was enforced only on the main session. Claude Code's `Stop` hook does not fire for subagents, and a review that hands its work to subagents makes most of its edits there, out of the hook's reach. `--with-hook` now also registers the hook on `SubagentStop`, so a subagent that changed code cannot finish until it has run the checklist.
- **Fixed:** each session and subagent is judged by its own transcript. A subagent's edits are read from its own transcript (`agent_transcript_path`), so a read-only subagent is never held for edits the main session made, and the reverse.
- **Added:** subagent cases to `hooks/tests/test-require-checklist.sh`.
- If you installed 1.4 or 1.4.1 with `--with-hook` into an existing `settings.json`, add the `SubagentStop` entry the installer now prints.

## 1.4.1 — The checklist hook sees what a session did, not what it could do (October 2026)

- **Fixed:** the Stop hook treated every session as one that edited code. A session transcript lists the tools available (`{"name":"Edit",…}`), and the hook matched those definitions instead of tool calls, so a read-only session was sent back to run the checklist. It now matches only tool calls (`"type":"tool_use"`).
- **Fixed:** a mention of `drift-toolkit-verification-checklist` (for example in a skill listing) counted as having run it. Only an actual invocation of the skill counts now.
- **Added:** `hooks/tests/test-require-checklist.sh`, run against transcripts in Claude Code's format, tool definitions included.

## 1.4 — The review opens every skill it needs, and the checklist is enforced (October 2026)

In 1.3 the skills triggered, but a review opened only `drift-toolkit-production-readiness`: its checklist covers every area, and nothing told the model to go deeper.

- **`drift-toolkit-production-readiness` now routes the review.** A "How to Run This Review" section names the skill to invoke for each area (security, error handling, types, data, concurrency, architecture, maintainability, performance, testing) and ends with the verification checklist; each area's heading repeats its skill.
- **Optional Stop hook (`--with-hook`)**: a Claude Code session that edited code is sent back until it has invoked `drift-toolkit-verification-checklist`. Read-only sessions are never held, and a session the hook already sent back once may stop.
- Skill and rule content is otherwise unchanged.

## 1.3 — Claude Code skills that trigger (October 2026)

The skills were written as reference documents. Claude Code decides whether to open a skill from its one-line description, and these had none, so in practice they were never invoked: an AI agent asked to review a codebase for production loaded the toolkit's instructions but none of its 14 skills.

- **Every skill file now starts with Claude Code frontmatter**: a name (`drift-toolkit-<topic>`) and a description that says when to use it. The `SKILL-*.md` files and `VERIFICATION_CHECKLIST.md` stay the single source; other tools ignore the frontmatter.
- **`install-claude-skills.sh`** installs all 14 skills into a project (`--project <dir>`) or for every project (`--user`), with each expansion-pack patch already applied where `expansion-pack/UPDATES.md` says, and installs `CLAUDE.md` with its rule additions in place. It never overwrites an existing file.
- **`CLAUDE.md` gains a "Skills: Use Them" section** that lists the skills and when to invoke them, starting with `drift-toolkit-production-readiness` for any review.
- The content of every skill and rule is unchanged.

## 1.2 and earlier

See [`expansion-pack/UPDATES.md`](expansion-pack/UPDATES.md).
