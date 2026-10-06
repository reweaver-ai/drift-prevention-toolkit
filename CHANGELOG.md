# Changelog

## 1.3 — Claude Code skills that trigger (October 2026)

The skills were written as reference documents. Claude Code decides whether to open a skill from its one-line description, and these had none, so in practice they were never invoked: an AI agent asked to review a codebase for production loaded the toolkit's instructions but none of its 14 skills.

- **Every skill file now starts with Claude Code frontmatter**: a name (`drift-toolkit-<topic>`) and a description that says when to use it. The `SKILL-*.md` files and `VERIFICATION_CHECKLIST.md` stay the single source; other tools ignore the frontmatter.
- **`install-claude-skills.sh`** installs all 14 skills into a project (`--project <dir>`) or for every project (`--user`), with each expansion-pack patch already applied where `expansion-pack/UPDATES.md` says, and installs `CLAUDE.md` with its rule additions in place. It never overwrites an existing file.
- **`CLAUDE.md` gains a "Skills: Use Them" section** that lists the skills and when to invoke them, starting with `drift-toolkit-production-readiness` for any review.
- The content of every skill and rule is unchanged.

## 1.2 and earlier

See [`expansion-pack/UPDATES.md`](expansion-pack/UPDATES.md).
