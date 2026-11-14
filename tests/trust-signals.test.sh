#!/usr/bin/env bash
# s170 — the task tests of `po state`'s options and forge reading, beside the story's oracle.

# The oracle's fixture (and through it s164's), loaded inside a test only, so its tests are not listed here.
s170_fixtures() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/trust-signals.oracle.test.sh"
  s164_fixtures
}

# forge_double <answer>: a PO_GH double printing <answer> and noting each call in $SCRATCH/gh-calls.
forge_double() {
  : > "$SCRATCH/gh-calls"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\necho %q\n' "$SCRATCH/gh-calls" "$1" > "$SCRATCH/forge"
  chmod +x "$SCRATCH/forge"
}

test_state_refuses_an_unknown_option() {
  s170_fixtures
  trust_project

  po_in "$F" state --bogus
  [ "$STATUS" -eq 2 ] || fail "po state --bogus exited $STATUS instead of 2: $OUT"
  one_object "po state --bogus"
  jq -e '.error == "unknown-option"' <<< "$OUT" >/dev/null || fail "po state --bogus is not unknown-option: $OUT"

  po_in "$F" state --remote --all --remote
  [ "$STATUS" -eq 0 ] || fail "po state --remote --all --remote exited $STATUS: $OUT"
  jq -e '(.shipped | length) == 4' <<< "$OUT" >/dev/null || fail "--all was not taken after --remote: $OUT"
}

test_remote_reads_only_github() {
  s170_fixtures
  trust_project
  git -C "$F" remote add origin https://gitlab.com/acme/project.git
  forge_double '{"total_count": 0, "check_runs": []}'

  STATUS=0
  OUT="$(cd "$F" && PO_GH="$SCRATCH/forge" "$PO" state --all --remote 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po state --all --remote exited $STATUS: $OUT"
  jq -e 'all(.shipped[]; .trust.checks == null)' <<< "$OUT" >/dev/null \
    || fail "checks is not null on a forge other than GitHub: $(jq -c '[.shipped[].trust.checks]' <<< "$OUT")"
  [ ! -s "$SCRATCH/gh-calls" ] || fail "po state asked gh about a remote that is not on github.com: $(cat "$SCRATCH/gh-calls")"
}

test_unfinished_checks_are_null() {
  s170_fixtures
  trust_project
  git -C "$F" remote add origin git@github.com:acme/project.git
  forge_double '{"total_count": 2, "check_runs": [{"status": "completed", "conclusion": "success"}, {"status": "in_progress", "conclusion": null}]}'

  STATUS=0
  OUT="$(cd "$F" && PO_GH="$SCRATCH/forge" "$PO" state --remote 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po state --remote exited $STATUS: $OUT"
  grep -qF 'repos/acme/project/commits/' "$SCRATCH/gh-calls" || fail "the forge was not asked: $(cat "$SCRATCH/gh-calls")"
  jq -e '(.shipped | length) == 2 and all(.shipped[]; .trust.checks == null)' <<< "$OUT" >/dev/null \
    || fail "checks is not null while a check runs: $(jq -c '[.shipped[].trust.checks]' <<< "$OUT")"
}
