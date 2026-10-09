#!/usr/bin/env bash
# Claude Code Stop and SubagentStop hook from the Drift Prevention Toolkit.
#
# A session or subagent that edited files may not finish until it has invoked the
# drift-toolkit-verification-checklist skill. Skills are opened at the model's
# discretion; this makes the run-before-done check a rule instead of a hope.
# A session or subagent that changed nothing is never held up.
#
# Each is judged by its own transcript: on SubagentStop, the subagent's
# (agent_transcript_path); on Stop, the main session's (transcript_path). A review
# that hands its edits to subagents is therefore checked where the edits were made.
set -uo pipefail

input="$(cat)"

# Claude Code sets stop_hook_active when this hook already sent the session back once.
# Let it stop then, so a model that cannot comply is not held in a loop.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;;
esac

field() { printf '%s' "$input" | sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'; }
case "$input" in
  *'"hook_event_name":"SubagentStop"'* | *'"hook_event_name": "SubagentStop"'*) event=SubagentStop; transcript="$(field agent_transcript_path)"; who="subagent" ;;
  *) event=Stop; transcript="$(field transcript_path)"; who="session" ;;
esac
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  echo "drift-toolkit: $event hook could not read the $who transcript (\"$transcript\"), so it could not check for the verification checklist." >&2
  exit 0
fi

# Match tool CALLS, not the tool definitions every transcript also carries
# ({"name":"Edit","description":…}): a call is recorded as "type":"tool_use".
grep -qE '"type":"tool_use","id":"[^"]+","name":"(Edit|Write|MultiEdit|NotebookEdit)"' "$transcript" || exit 0
grep -qE '"type":"tool_use","id":"[^"]+","name":"Skill","input":\{"skill":"drift-toolkit-verification-checklist"' "$transcript" && exit 0

printf '{"decision":"block","reason":"You changed code in this %s. Before finishing, invoke the drift-toolkit-verification-checklist skill, check your changes against it, and fix anything it finds."}\n' "$who"
