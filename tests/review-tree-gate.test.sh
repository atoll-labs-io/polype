#!/usr/bin/env bash
# s92 — the gates pair each verdict with the tree of its own report, and read list-item lines.

GATE="$METHOD/hooks/po-gate.sh"

# Two commits: T1 is the old tree, T2 the tree of HEAD.
sandbox() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p docs/reviews docs/verif docs/qa/s01-a src
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
  echo 'y' > src/app.txt
  git add -A && git commit -qm second
  T1="$(git rev-parse 'HEAD~1^{tree}')"
  T2="$(git rev-parse 'HEAD^{tree}')"
}
passes() { bash "$GATE" "$@" 2>/dev/null; }
review() { printf '%b' "$1" > docs/reviews/s01-a.md; }

test_ship_gate_reads_the_last_review() {
  sandbox
  review "Reviewed tree: $T1\nShip allowed: no\nReviewed tree: $T2\nShip allowed: yes\n"
  passes ship-allowed s01-a || fail "the last review's own tree was not used"
  review "Reviewed tree: $T2\nShip allowed: no\nShip allowed: yes\n"
  ! passes ship-allowed s01-a || fail "a last review without a tree borrowed an earlier one"
  review "Reviewed tree: $T1\nShip allowed: yes\nReviewed tree: $T2\n"
  ! passes ship-allowed s01-a || fail "an unfinished appended review allowed the ship"
}

test_verdict_lines_may_be_list_items() {
  sandbox
  review "- Reviewed tree: $T2 (taken again just before answering: unchanged)\n* Ship allowed: yes\n"
  passes ship-allowed s01-a || fail "list-item lines refused"
  review "Reviewed tree: $T2\nShip allowed: yes\n- Ship allowed: no\n"
  ! passes ship-allowed s01-a || fail "a bulleted last verdict was ignored"
  review "  - Reviewed tree: $T2\nShip allowed: yes\n"
  ! passes ship-allowed s01-a || fail "indented line accepted"
  review "+ Reviewed tree: $T2\nShip allowed: yes\n"
  ! passes ship-allowed s01-a || fail "+ bullet accepted"
  review "Reviewed tree: ${T2:0:12} (short)\nShip allowed: yes\n"
  ! passes ship-allowed s01-a || fail "abbreviated hash accepted"
  review "- Reviewed tree: $T2. I took it again\nShip allowed: yes\n"
  ! passes ship-allowed s01-a || fail "punctuation stuck to the hash accepted"
}

test_other_tree_lines_read_the_same_way() {
  sandbox
  git add -A
  printf -- '- Tree: %s (after git add -A)\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | — | none here |\n\nVerification status: complete\n' \
    "$(git write-tree)" > docs/verif/s01-a.md
  git add -A && git commit -qm record
  passes verif-current s01-a || fail "list-item Tree: refused in the record"

  printf '* Tree: %s\nQA status: complete\n' "$T2" > docs/qa/s01-a/report.md
  git add -A && git commit -qm qa
  passes qa-current s01-a || fail "list-item Tree: refused in the QA report"
  printf 'Tree: %s\nQA status: blocked\nTree: %s\nQA status: complete\n' "$T2" "$T1" > docs/qa/s01-a/report.md
  git add -A && git commit -qm qa2
  ! passes qa-current s01-a || fail "a stacked QA report used the first tree"

  contains "$METHOD/commands/po-ship.md" 'between that verdict and the verdict line before it'
  source <(sed -n '/^grade() {/,/^}/p' "$ROOT/bin/po-eval")
  printf 'Max severity: critical\nShip allowed: yes\n- Ship allowed: no\n' > "$SCRATCH/r.md"
  [ "$(grade "$SCRATCH/r.md")" = "critical/no" ] || fail "po-eval ignored a bulleted last verdict"
}
