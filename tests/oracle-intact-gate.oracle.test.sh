#!/usr/bin/env bash
# s150 — the oracle of the story: `po-gate oracle-intact <id>` compares the oracle files of the plan, on story/<id>,
# with their sums, and the review runs it before reading any test (ADR-0098).

GATE="$METHOD/hooks/po-gate.sh"
SKILL="$METHOD/skills/review-antihallu/SKILL.md"
ID=s01-a
A=tests/a.oracle.test.sh
B=tests/b.oracle.test.sh

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# A story branch holding two oracle files; the gate is always run from main, so only story/<id> can answer.
oracle_repo() {
  scratch_repo
  cd "$SCRATCH"
  echo base > README.md
  git add -A && git commit -qm base
  git checkout -qb "story/$ID"
  mkdir -p tests docs/plans docs/verif
  printf 'test_one() { true; }\n' > "$A"
  printf 'test_two() { true; }\n' > "$B"
}

commit() { git add -A && git commit -qm "$1"; }
on_story() { git checkout -q "story/$ID"; }
on_main() { git checkout -q main; }

# The plan lists each given file with the sum it has now, then the criteria table the gate must not read as files.
plan_with_oracle() {
  local f
  {
    printf -- '---\nvalidated: yes\n---\n# Plan — %s\n\n## Acceptance tests\n\n' "$ID"
    printf '| Oracle file | cksum |\n| --- | --- |\n'
    for f in "$@"; do printf '| `%s` | `%s` |\n' "$f" "$(cksum < "$f")"; done
    printf '\n| Criterion | Test |\n| --- | --- |\n| `one` | `test_one` |\n\n## Tasks\n1. [ ] something\n'
  } > "docs/plans/$ID.md"
}

plan_without_section() {
  printf -- '---\nvalidated: yes\n---\n# Plan — %s\n\n## Tasks\n1. [ ] something\n' "$ID" > "docs/plans/$ID.md"
}

plan_with_dash() {
  printf -- '---\nvalidated: yes\n---\n# Plan — %s\n\n## Acceptance tests\n— no criterion can be checked by a test: the story is purely visual.\n\n## Tasks\n1. [ ] something\n' \
    "$ID" > "docs/plans/$ID.md"
}

# Each argument is one row of ## Oracle changes: `<file>|<what changes>|<why>`.
record_with_changes() {
  local row file what why
  {
    printf '# Verification — %s\n\nTree: %s\n\n## Oracle changes\n| Oracle file | What changes | Why |\n| --- | --- | --- |\n' \
      "$ID" 0000000000000000000000000000000000000000
    for row in "$@"; do
      IFS='|' read -r file what why <<< "$row"
      printf '| `%s` | %s | %s |\n' "$file" "$what" "$why"
    done
    printf '\nVerification status: complete\n'
  } > "docs/verif/$ID.md"
}

gate() {
  code=0
  out=$(bash "$GATE" oracle-intact "$@" 2>"$SCRATCH/.git/gate.err") || code=$?
  err=$(cat "$SCRATCH/.git/gate.err")
}

line_naming() { grep -F -- "$1" <<< "$out" || true; }

test_gate_compares_oracle_sums() {
  oracle_repo
  plan_with_oracle "$A" "$B"
  record_with_changes
  commit planned
  on_main
  gate "$ID"
  [ "$code" -eq 0 ] || fail "intact oracle: exit $code, stdout '$out', stderr '$err'"

  on_story
  printf 'test_one() { false; }\n' > "$A"
  commit 'oracle edited, nothing logged'
  on_main
  gate "$ID"
  [ "$code" -eq 1 ] || fail "unlogged change: exit $code, stdout '$out', stderr '$err'"
  grep -qF 'without a row' <<< "$(line_naming "$A")" || fail "the changed file is not named as unlogged: '$out'"
  [ -z "$(line_naming "$B")" ] || fail "an intact file is reported: '$out'"

  on_story
  git rm -q "$B"
  record_with_changes "$A|asserts false now|criterion reworded"
  commit 'one change logged, one file gone'
  on_main
  gate "$ID"
  [ "$code" -eq 1 ] || fail "missing file not logged: exit $code, stdout '$out', stderr '$err'"
  grep -qF 'without a row' <<< "$(line_naming "$B")" || fail "the missing file is not named as unlogged: '$out'"

  on_story
  record_with_changes "$A|asserts false now|criterion reworded" "$B|file dropped|criterion merged into test_one"
  commit 'both changes logged'
  on_main
  gate "$ID"
  [ "$code" -eq 0 ] || fail "every change logged: exit $code, stdout '$out', stderr '$err'"
  grep -qF 'criterion reworded' <<< "$(line_naming "$A")" || fail "no line to judge for $A: '$out'"
  grep -qF 'criterion merged into test_one' <<< "$(line_naming "$B")" || fail "no line to judge for $B: '$out'"
  ! grep -qF 'without a row' <<< "$out" || fail "a logged change is reported as unlogged: '$out'"
}

test_gate_without_oracle_says_so() {
  oracle_repo
  plan_without_section
  commit 'plan written before M17'
  on_main
  gate "$ID"
  [ "$code" -eq 0 ] && grep -qF 'has no oracle' <<< "$out" || fail "no section: exit $code, stdout '$out', stderr '$err'"

  on_story
  plan_with_dash
  commit 'plan with a dash'
  on_main
  gate "$ID"
  [ "$code" -eq 0 ] && grep -qF 'has no oracle' <<< "$out" || fail "dash: exit $code, stdout '$out', stderr '$err'"

  gate s02-b
  [ "$code" -eq 2 ] && [ -z "$out" ] || fail "no branch: exit $code, stdout '$out'"
  grep -qF 'cannot check the oracle of' <<< "$err" || fail "no branch: no exit-2 message: '$err'"

  on_story
  plan_with_oracle "$A"
  sed -i.bak 's/| `[0-9][0-9]* [0-9][0-9]*` |/| `not a sum` |/' "docs/plans/$ID.md" && rm "docs/plans/$ID.md.bak"
  commit 'plan with an unreadable sum'
  on_main
  gate "$ID"
  [ "$code" -eq 2 ] && [ -z "$out" ] || fail "unreadable sum: exit $code, stdout '$out', stderr '$err'"
  grep -qF 'cannot check the oracle of' <<< "$err" || fail "unreadable sum: no exit-2 message: '$err'"

  on_story
  plan_with_oracle "$A"
  printf 'test_one() { false; }\n' > "$A"
  commit 'oracle changed, no record at all'
  on_main
  gate "$ID"
  [ "$code" -eq 2 ] && [ -z "$out" ] || fail "no record: exit $code, stdout '$out', stderr '$err'"

  on_story
  git rm -q "docs/plans/$ID.md"
  commit 'plan gone'
  on_main
  gate "$ID"
  [ "$code" -eq 2 ] && [ -z "$out" ] || fail "no plan: exit $code, stdout '$out', stderr '$err'"

  local usage
  usage="$(awk '/^set -euo/ {exit} {sub(/^#[[:space:]]*/, ""); printf "%s ", $0}' "$GATE")"
  holds "$usage" 'po-gate oracle-intact <id>' "the usage of po-gate.sh"
  holds "$usage" 'guards against mistakes, not against an implementer who also rewrites the sum' "the usage of po-gate.sh"
  holds "$usage" 'ADR-0052' "the usage of po-gate.sh"
  holds "$usage" 'ADR-0098' "the usage of po-gate.sh"
}

step_four() { awk '/^\*\*4\. / {on=1} /^\*\*5\. / {on=0} on' "$SKILL"; }

test_review_runs_the_oracle_gate() {
  require_file "$SKILL"
  local step oracle at_oracle at_floor
  step="$(step_four)"
  oracle="$(grep -F -- '- *Oracle.* ' <<< "$step" || true)"
  [ -n "$oracle" ] || fail "step 4 of review-antihallu has no *Oracle.* item"
  holds "$oracle" 'Run `po-gate oracle-intact <id>` from the worktree before reading any test' "the *Oracle.* item"
  holds "$oracle" 'Exit 1: an oracle changed without saying so counts as a test file deleted without a reason → **critical**' "the *Oracle.* item"
  holds "$oracle" 'each change it lists from `## Oracle changes` is judged' "the *Oracle.* item"
  holds "$oracle" 'one that weakens the criterion its test holds is **major** at least' "the *Oracle.* item"
  holds "$oracle" "the review is blocked, with the check's message as \`Failure cause:\`" "the *Oracle.* item"
  at_oracle="$(grep -nF -- '- *Oracle.* ' <<< "$step" | head -n1 | cut -d: -f1)"
  at_floor="$(grep -nF -- '- *Floor.* ' <<< "$step" | head -n1 | cut -d: -f1)"
  [ -n "$at_floor" ] && [ "$at_oracle" -lt "$at_floor" ] || fail "the *Oracle.* item must come before *Floor.* in step 4"
}

test_bite_starts_with_the_oracle() {
  require_file "$SKILL"
  local bite
  bite="$(step_four | grep -F -- '- *Bite.* ' || true)"
  [ -n "$bite" ] || fail "step 4 of review-antihallu has no *Bite.* item"
  holds "$bite" 'When the plan names oracle files, choose first among the rules their tests hold.' "the *Bite.* item"
}
