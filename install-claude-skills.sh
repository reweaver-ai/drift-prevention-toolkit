#!/usr/bin/env bash
# Install the Drift Prevention Toolkit into Claude Code as 14 skills, plus CLAUDE.md.
#
#   ./install-claude-skills.sh --user            # ~/.claude/skills and ~/.claude/CLAUDE.md
#   ./install-claude-skills.sh --project <dir>   # <dir>/.claude/skills and <dir>/CLAUDE.md
#   add --with-hook to either                    # plus Stop and SubagentStop hooks: a session or subagent that edited code
#                                                # must invoke the verification checklist first
#
# Each skill is its SKILL-*.md with the matching PATCH-*.md applied, and the checklist,
# production-readiness skill and CLAUDE.md get their blocks from PATCH-rules-additions.md:
# the same content the manual steps in expansion-pack/UPDATES.md produce.
# Existing files are never overwritten: the script stops and names them.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "Usage: $0 --user | --project <dir>   [--with-hook]" >&2; exit 1; }
with_hook=0
case "${1:-}" in
  --user)
    dot="$HOME/.claude"; claude_md="$dot/CLAUDE.md"; hook_ref='$HOME/.claude/hooks'; shift ;;
  --project)
    [ -n "${2:-}" ] && [ -d "$2" ] || { echo "❌ --project needs an existing directory" >&2; exit 1; }
    dot="$2/.claude"; claude_md="$2/CLAUDE.md"; hook_ref='$CLAUDE_PROJECT_DIR/.claude/hooks'; shift 2 ;;
  *) usage ;;
esac
case "${1:-}" in
  --with-hook) with_hook=1 ;;
  "") ;;
  *) usage ;;
esac
skills="$dot/skills"
hook_file="$dot/hooks/drift-toolkit-require-checklist.sh"
settings="$dot/settings.json"

rules="$here/expansion-pack/PATCH-rules-additions.md"

# The content to add for <target>: the fenced ```markdown blocks under the heading
# "## For <target>" in PATCH-rules-additions.md, without the instructions around them.
rules_block() {
  awk -v want="## For $1" '
    index($0, "## For ") == 1 { on = ($0 == want); fence = 0; next }
    on && /^```markdown/ { fence = 1; if (n++) print ""; next }
    on && fence && /^```/ { fence = 0; next }
    on && fence { print }
  ' "$rules"
}

# The <n>th fenced ```markdown block under "## For <target>" (1-based).
rules_fence() {
  awk -v want="## For $1" -v nth="$2" '
    index($0, "## For ") == 1 { on = ($0 == want); fence = 0; next }
    on && /^```markdown/ { fence = 1; k++; next }
    on && fence && /^```/ { fence = 0; next }
    on && fence && k == nth { print }
  ' "$rules"
}

# The toolkit's CLAUDE.md with its two rule additions where PATCH-rules-additions.md puts them:
# the sections after "## Performance & Resources", the checklist items after "### Modern Patterns".
compose_claude_md() {
  awk -v sections="$1" -v checks="$2" '
    function emit(f,   line) { while ((getline line < f) > 0) print line; close(f); print "" }
    /^#{2,3} / {
      if (after_perf && /^## /) { emit(sections); after_perf = 0; placed_sections = 1 }
      if (after_modern) { emit(checks); after_modern = 0; placed_checks = 1 }
      if ($0 == "## Performance & Resources") after_perf = 1
      if ($0 == "### Modern Patterns") after_modern = 1
    }
    { print }
    END { if (!placed_sections || !placed_checks) { print "❌ CLAUDE.md is missing the Performance & Resources or Modern Patterns heading" > "/dev/stderr"; exit 1 } }
  ' "$here/CLAUDE.md"
}

skill_dir() { echo "$skills/drift-toolkit-$1"; }

targets=()
for s in architecture error-handling multi-agent performance production-readiness security type-safety workarounds \
         concurrency data-truth maintainability migration testing verification-checklist; do
  targets+=("$(skill_dir "$s")/SKILL.md")
done
[ -e "$claude_md" ] && existing_claude_md=1 || existing_claude_md=0
if [ "$with_hook" = 1 ]; then targets+=("$hook_file"); fi
for t in "${targets[@]}"; do
  if [ -e "$t" ]; then echo "❌ $t already exists; remove it or install elsewhere." >&2; exit 1; fi
done

write_skill() { # name, source, extra...
  local name="$1" src="$2"; shift 2
  mkdir -p "$(skill_dir "$name")"
  {
    cat "$src"
    for extra in "$@"; do printf '\n---\n\n'; cat "$extra"; done
  } > "$(skill_dir "$name")/SKILL.md"
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
rules_block "VERIFICATION_CHECKLIST.md" > "$tmp/checklist-additions.md"
rules_block "SKILL-production-readiness.md" > "$tmp/readiness-additions.md"
rules_fence "CLAUDE.md" 1 > "$tmp/claude-sections.md"
rules_fence "CLAUDE.md" 2 > "$tmp/claude-checks.md"
for f in checklist-additions readiness-additions claude-sections claude-checks; do
  [ -s "$tmp/$f.md" ] || { echo "❌ PATCH-rules-additions.md has no block for $f" >&2; exit 1; }
done

write_skill architecture         "$here/SKILL-architecture.md"         "$here/expansion-pack/PATCH-architecture.md"
write_skill error-handling       "$here/SKILL-error-handling.md"       "$here/expansion-pack/PATCH-error-handling.md"
write_skill security             "$here/SKILL-security.md"             "$here/expansion-pack/PATCH-security.md"
write_skill production-readiness "$here/SKILL-production-readiness.md" "$tmp/readiness-additions.md"
write_skill verification-checklist "$here/VERIFICATION_CHECKLIST.md"   "$tmp/checklist-additions.md"
for s in multi-agent performance type-safety workarounds; do write_skill "$s" "$here/SKILL-$s.md"; done
for s in concurrency data-truth maintainability migration testing; do write_skill "$s" "$here/expansion-pack/SKILL-$s.md"; done
echo "✔ 14 skills installed in $skills"

if [ "$existing_claude_md" = 1 ]; then
  echo "ℹ️  $claude_md already exists, so it was left alone. Add the toolkit's CLAUDE.md (its \"Skills: Use Them\" section first) to it by hand."
else
  mkdir -p "$(dirname "$claude_md")"
  compose_claude_md "$tmp/claude-sections.md" "$tmp/claude-checks.md" > "$claude_md"
  echo "✔ CLAUDE.md installed at $claude_md"
fi

if [ "$with_hook" = 1 ]; then
  mkdir -p "$(dirname "$hook_file")"
  cp "$here/hooks/drift-toolkit-require-checklist.sh" "$hook_file"
  chmod +x "$hook_file"
  hook_cmd='{ "hooks": [ { "type": "command", "command": "\"'"$hook_ref"'/drift-toolkit-require-checklist.sh\"" } ] }'
  hook_json='{
  "hooks": {
    "Stop": [ '"$hook_cmd"' ],
    "SubagentStop": [ '"$hook_cmd"' ]
  }
}'
  if [ -e "$settings" ]; then
    echo "ℹ️  $settings already exists, so it was left alone. Add these Stop and SubagentStop hooks to it by hand:"
    echo "$hook_json"
  else
    printf '%s\n' "$hook_json" > "$settings"
    echo "✔ Stop and SubagentStop hooks installed: $hook_file, registered in $settings"
  fi
fi
