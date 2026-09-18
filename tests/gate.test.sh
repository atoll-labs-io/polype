#!/usr/bin/env bash
# s02 — gates, exercised on throwaway git repositories.

GATE="$METHOD/hooks/po-gate.sh"

sandbox() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p docs/plans docs/reviews docs/verif src
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
}

plan() { printf -- '---\nvalidated: %s\n---\n# Plan\n%s\n' "$1" "${2:-}" > docs/plans/s01-a.md; }
passes() { bash "$GATE" "$@" 2>/dev/null; }

test_plan_validated_passes_only_on_exact_line() {
  sandbox
  plan yes;                 passes plan-validated s01-a || fail "approved plan refused"
  plan no;                  ! passes plan-validated s01-a || fail "unapproved plan accepted"
  plan no 'validated: yes'; ! passes plan-validated s01-a || fail "validated: yes outside the frontmatter accepted"
}

test_plan_validated_fails_without_file() {
  sandbox
  ! passes plan-validated s01-a || fail "missing plan accepted"
}

test_ship_allowed_passes_only_on_exact_line() {
  sandbox
  printf 'Max severity: minor\nShip allowed: yes\n' > docs/reviews/s01-a.md
  passes ship-allowed s01-a || fail "positive verdict refused"
  printf 'Ship allowed: yes, once fixed\n' > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "qualified verdict accepted"
}

test_ship_allowed_fails_on_no() {
  sandbox
  printf 'Ship allowed: no\n' > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "negative verdict accepted"
  rm docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "missing review accepted"
}

test_ship_allowed_reads_the_last_verdict() {
  sandbox
  printf 'Earlier run said:\nShip allowed: yes\n\nMax severity: critical\nShip allowed: no\n' > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "an earlier quoted verdict overrode the final one"
}

record() {
  git add -A
  printf 'Tree: %s\n\nVerification status: %s\n' "$(git write-tree)" "${1:-complete}" > docs/verif/s01-a.md
  git add -A && git commit -qm story
}

test_verif_current_passes_when_tree_matches() {
  sandbox
  echo 'y' > src/app.txt
  record
  passes verif-current s01-a || fail "current record refused"
}

test_verif_current_fails_when_code_changed() {
  sandbox
  record
  echo 'z' > src/app.txt && git commit -qam change
  ! passes verif-current s01-a || fail "stale record accepted"
}

test_verif_current_fails_from_a_subdirectory_too() {
  sandbox
  mkdir lib && echo 'unchanged' > lib/util.txt
  record
  echo 'z' > src/app.txt && git commit -qam change
  # From lib/, a pathspec relative to the current directory would only see lib/, which did not change.
  cd lib
  ! passes verif-current s01-a || fail "stale record accepted when run from a subdirectory"
}

test_verif_current_ignores_docs_changes() {
  sandbox
  record
  echo '- [x] task' > docs/plans/s01-a.md && git add -A && git commit -qm tick
  passes verif-current s01-a || fail "a docs-only change invalidated the record"
}

test_verif_current_fails_when_incomplete() {
  sandbox
  record incomplete
  ! passes verif-current s01-a || fail "incomplete record accepted"
}

test_pre_commit_blocks_code_without_validated_plan() {
  sandbox
  git checkout -qb story/s01-a
  plan no && echo 'w' > src/app.txt && git add -A
  ! passes pre-commit || fail "code commit allowed without an approved plan"
  plan yes && git add -A
  passes pre-commit || fail "code commit refused with an approved plan"
}

test_pre_commit_allows_docs_only() {
  sandbox
  git checkout -qb story/s01-a
  plan no && git add -A
  passes pre-commit || fail "docs-only commit refused"
}

test_pre_commit_counts_a_move_into_docs_as_code() {
  sandbox
  git checkout -qb story/s01-a
  plan no && git add -A && git commit -qm plan
  git mv src/app.txt docs/app.txt
  ! passes pre-commit || fail "moving code into docs/ slipped past the gate"
}

test_pre_commit_ignores_non_story_branch() {
  sandbox
  echo 'w' > src/app.txt && git add -A
  passes pre-commit || fail "commit on main refused"
}

test_hook_blocks_code_inside_a_story_worktree() {
  sandbox
  mkdir -p .polype/hooks && cp "$METHOD"/hooks/* .polype/hooks/ && chmod +x .polype/hooks/*
  printf '.worktrees/\n' > .gitignore
  git add -A && git commit -qm 'install polype'
  git config core.hooksPath .polype/hooks
  git worktree add -q -b story/s01-a .worktrees/s01-a main
  cd .worktrees/s01-a
  mkdir -p docs/plans && plan no && echo 'w' > src/app.txt && git add -A
  local err
  if err=$(git commit -qm code 2>&1); then fail "the hook let a code commit through inside the worktree"; fi
  grep -qF 'po-gate: no code commit on story/s01-a' <<< "$err" || fail "commit failed for another reason: $err"
}
