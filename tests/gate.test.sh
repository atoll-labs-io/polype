#!/usr/bin/env bash
# s02 — gates, exercised on throwaway git repositories.

GATE="$METHOD/hooks/po-gate.sh"

sandbox() {
  local dir; dir="$(mktemp -d)"
  cd "$dir" || return 1
  git init -q -b main
  git config user.email t@example.com
  git config user.name test
  mkdir -p docs/plans docs/reviews docs/verif src
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
}

plan() { printf -- '---\nvalidated: %s\n---\n# Plan\n%s\n' "$1" "${2:-}" > docs/plans/s01-a.md; }

test_plan_validated_passes_only_on_exact_line() {
  sandbox
  plan yes && bash "$GATE" plan-validated s01-a 2>/dev/null || fail "validated plan refused"
  plan no && ! bash "$GATE" plan-validated s01-a 2>/dev/null || fail "unvalidated plan accepted"
  plan no 'validated: yes' && ! bash "$GATE" plan-validated s01-a 2>/dev/null \
    || fail "validated: yes outside the frontmatter was accepted"
}

test_plan_validated_fails_without_file() {
  sandbox
  ! bash "$GATE" plan-validated s01-a 2>/dev/null || fail "missing plan accepted"
}

test_ship_allowed_passes_only_on_exact_line() {
  sandbox
  printf 'Max severity: minor\nShip allowed: yes\n' > docs/reviews/s01-a.md
  bash "$GATE" ship-allowed s01-a 2>/dev/null || fail "positive verdict refused"
  printf 'Ship allowed: yes, once fixed\n' > docs/reviews/s01-a.md
  ! bash "$GATE" ship-allowed s01-a 2>/dev/null || fail "qualified verdict accepted"
}

test_ship_allowed_fails_on_no() {
  sandbox
  printf 'Ship allowed: no\n' > docs/reviews/s01-a.md
  ! bash "$GATE" ship-allowed s01-a 2>/dev/null || fail "negative verdict accepted"
  rm docs/reviews/s01-a.md
  ! bash "$GATE" ship-allowed s01-a 2>/dev/null || fail "missing review accepted"
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
  bash "$GATE" verif-current s01-a 2>/dev/null || fail "current record refused"
}

test_verif_current_fails_when_code_changed() {
  sandbox
  record
  echo 'z' > src/app.txt && git commit -qam change
  ! bash "$GATE" verif-current s01-a 2>/dev/null || fail "stale record accepted"
}

test_verif_current_ignores_docs_changes() {
  sandbox
  record
  echo '- [x] task' > docs/plans/s01-a.md && git add -A && git commit -qm tick
  bash "$GATE" verif-current s01-a 2>/dev/null || fail "a docs-only change invalidated the record"
}

test_verif_current_fails_when_incomplete() {
  sandbox
  record partial
  ! bash "$GATE" verif-current s01-a 2>/dev/null || fail "incomplete record accepted"
}

test_pre_commit_blocks_code_without_validated_plan() {
  sandbox
  git checkout -qb story/s01-a
  plan no && echo 'w' > src/app.txt && git add -A
  ! bash "$GATE" pre-commit 2>/dev/null || fail "code commit allowed without a validated plan"
  plan yes && git add -A
  bash "$GATE" pre-commit 2>/dev/null || fail "code commit refused with a validated plan"
}

test_pre_commit_allows_docs_only() {
  sandbox
  git checkout -qb story/s01-a
  plan no && git add -A
  bash "$GATE" pre-commit 2>/dev/null || fail "docs-only commit refused"
}

test_pre_commit_ignores_non_story_branch() {
  sandbox
  echo 'w' > src/app.txt && git add -A
  bash "$GATE" pre-commit 2>/dev/null || fail "commit on main refused"
}

test_hook_delegates_to_gate() {
  sandbox
  git config core.hooksPath "$METHOD/hooks"
  git checkout -qb story/s01-a
  echo 'w' > src/app.txt && git add -A
  ! git commit -qm code 2>/dev/null || fail "installed hook let a code commit through"
}
