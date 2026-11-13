#!/usr/bin/env bash
# s159 — bin/po-ci never guesses a command the project does not declare.

test_ci_entry_refuses_a_missing_test_command() {
  require_file "$ROOT/bin/po-ci"
  scratch_repo
  local s st=0 out
  s="$(cd "$SCRATCH" && pwd -P)"
  mkdir -p "$s/bin"
  cp -p "$ROOT/bin/po-ci" "$s/bin/po-ci"
  printf '```\nTest budget:       25\n```\n\n```\nTest:              —\n```\n' > "$s/AGENTS.local.md"
  out="$(cd "$s" && "$s/bin/po-ci" 2>&1)" || st=$?
  [ "$st" -eq 2 ] || fail "po-ci exited $st on Test: —, 2 expected: $out"
  grep -qF 'Test' <<< "$out" || fail "po-ci did not name the Test setting: $out"
  rm "$s/AGENTS.local.md"
  st=0; out="$(cd "$s" && "$s/bin/po-ci" 2>&1)" || st=$?
  [ "$st" -eq 2 ] || fail "po-ci exited $st without AGENTS.local.md, 2 expected: $out"
}
