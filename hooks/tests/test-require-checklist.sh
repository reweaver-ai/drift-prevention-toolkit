#!/usr/bin/env bash
# Tests for drift-toolkit-require-checklist.sh. Run: ./hooks/tests/test-require-checklist.sh
# Transcripts here follow Claude Code's real format, including the tool definitions every
# transcript carries ({"name":"Edit","description":…}), which a call must not be confused with.
set -uo pipefail
hook="$(cd "$(dirname "$0")/.." && pwd)/drift-toolkit-require-checklist.sh"
dir="$(mktemp -d)"; trap 'rm -rf "$dir"' EXIT
fail=0

defs='{"type":"system","tools":[{"name":"Edit","description":"Performs exact string replacements in files."},{"name":"Write","description":"Writes a file."}]}'
edit='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_01","name":"Edit","input":{"file_path":"a.ts"}}]}}'
read='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_02","name":"Read","input":{"file_path":"a.ts"}}]}}'
checklist='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_03","name":"Skill","input":{"skill":"drift-toolkit-verification-checklist"}}]}}'
mention='{"type":"attachment","skills":{"toolu_09":{"skill":"drift-toolkit-verification-checklist"}}}'

run() { # name, expected (block|allow), stop_hook_active, transcript lines...
  local name="$1" want="$2" active="$3"; shift 3
  printf '%s\n' "$@" > "$dir/$name.jsonl"
  local out; out="$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$dir/$name.jsonl" "$active" | "$hook" 2>/dev/null)"
  local got=allow; case "$out" in *'"decision":"block"'*) got=block ;; esac
  if [ "$got" = "$want" ]; then echo "ok   $name"; else echo "FAIL $name: wanted $want, got $got"; fail=1; fi
}

run "tool definitions alone are not an edit"          allow false "$defs" "$read"
run "an edit without the checklist is sent back"      block false "$defs" "$edit"
run "an edit with the checklist may stop"             allow false "$defs" "$edit" "$checklist"
run "a mention of the checklist is not invoking it"   block false "$defs" "$edit" "$mention"
run "a session already sent back once may stop"       allow true  "$defs" "$edit"

exit $fail
