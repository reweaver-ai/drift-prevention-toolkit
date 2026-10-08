#!/usr/bin/env bash
# Claude Code Stop hook from the Drift Prevention Toolkit.
#
# A session that edited files may not finish until it has invoked the
# drift-toolkit-verification-checklist skill. Skills are opened at the model's
# discretion; this makes the run-before-done check a rule instead of a hope.
# A session that changed nothing is never held up.
set -uo pipefail

input="$(cat)"

# Claude Code sets stop_hook_active when this hook already sent the session back once.
# Let it stop then, so a model that cannot comply is not held in a loop.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;;
esac

transcript="$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  echo "drift-toolkit: Stop hook could not read the session transcript (\"$transcript\"), so it could not check for the verification checklist." >&2
  exit 0
fi

# Match tool CALLS, not the tool definitions every transcript also carries
# ({"name":"Edit","description":…}): a call is recorded as "type":"tool_use".
grep -qE '"type":"tool_use","id":"[^"]+","name":"(Edit|Write|MultiEdit|NotebookEdit)"' "$transcript" || exit 0
grep -qE '"type":"tool_use","id":"[^"]+","name":"Skill","input":\{"skill":"drift-toolkit-verification-checklist"' "$transcript" && exit 0

printf '%s\n' '{"decision":"block","reason":"You changed code in this session. Before finishing, invoke the drift-toolkit-verification-checklist skill, check your changes against it, and fix anything it finds."}'
