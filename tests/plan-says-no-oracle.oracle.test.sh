#!/usr/bin/env bash
# s217 — a plan says "no oracle" in the one form `po-gate oracle-intact` accepts: a `—` line with its reason in
# place of the oracle table, a criterion without a test explained in its row of the criterion table (#484).

GATE="$METHOD/hooks/po-gate.sh"
ID=s01-a
A=tests/a.oracle.test.sh
FORM='write a — line with its reason in place of the oracle table'

# A story branch holding one oracle file; the gate is always run from main, so only story/<id> can answer.
story_repo() {
  scratch_repo
  cd "$SCRATCH"
  echo base > README.md
  git add -A && git commit -qm base
  git checkout -qb "story/$ID"
  mkdir -p tests docs/plans
  printf 'test_one() { true; }\n' > "$A"
  SUM="$(cksum < "$A")"
}

# The plan's ## Acceptance tests holds exactly the lines given, then the criterion table: one criterion with a
# test, one that speaks to the model and says why in its row.
plan_section() {
  {
    printf -- '---\nvalidated: yes\n---\n# Plan — %s\n\n## Acceptance tests\n' "$ID"
    printf '%s\n' "$@"
    printf '\n| Criterion | Test |\n| --- | --- |\n| `one` | `test_one` |\n'
    printf '| `speaks_to_the_model` | — case 3: the rule speaks to a model; the reviewer reads it. |\n'
    printf '\n## Tasks\n1. [ ] something\n'
  } > "docs/plans/$ID.md"
}

gate_on() {
  git checkout -q "story/$ID"
  plan_section "$@"
  git add -A && git commit -qm plan
  git checkout -q main
  code=0
  out=$(bash "$GATE" oracle-intact "$ID" 2>"$SCRATCH/.git/gate.err") || code=$?
  err=$(cat "$SCRATCH/.git/gate.err")
}

test_no_oracle_row_passes_the_gate() {
  story_repo
  gate_on '— no oracle: the story'\''s `Owns` admits no test file.'
  [ "$code" -eq 0 ] && grep -qF 'has no oracle' <<< "$out" \
    || fail "dash line, criterion row says why: exit $code, stdout '$out', stderr '$err'"

  gate_on '| Oracle file | cksum |' '| --- | --- |' "| \`$A\` | \`$SUM\` |"
  [ "$code" -eq 0 ] || fail "oracle table, one criterion without a test in its row: exit $code, stdout '$out', stderr '$err'"
}

test_missing_oracle_still_refused() {
  story_repo
  gate_on '| Oracle file | cksum |' '| --- | --- |' '| — (the story'\''s `Owns` admits no test file) | — |'
  [ "$code" -eq 2 ] || fail "placeholder row: exit $code, stdout '$out', stderr '$err'"
  grep -qF -- "$FORM" <<< "$err" || fail "placeholder row: the message does not name the form: '$err'"

  gate_on '—'
  [ "$code" -eq 2 ] || fail "bare — with no reason: exit $code, stdout '$out', stderr '$err'"
  grep -qF -- "$FORM" <<< "$err" || fail "bare —: the message does not name the form: '$err'"

  gate_on '| Oracle file | cksum |' '| --- | --- |'
  [ "$code" -eq 2 ] || fail "empty oracle table, no — line: exit $code, stdout '$out', stderr '$err'"
}
