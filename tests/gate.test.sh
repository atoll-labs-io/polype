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

# A review bound to the tree HEAD has now, followed by the given verdict lines.
review() { { echo "Review status: complete"; echo "Reviewed tree: $(git rev-parse 'HEAD^{tree}')"; printf '%b' "$1"; } > docs/reviews/s01-a.md; }

test_ship_allowed_passes_only_on_exact_line() {
  sandbox
  review 'Max severity: minor\nShip allowed: yes\n'
  passes ship-allowed s01-a || fail "positive verdict refused"
  review 'Ship allowed: yes, once fixed\n'
  ! passes ship-allowed s01-a || fail "qualified verdict accepted"
}

test_ship_allowed_fails_on_no() {
  sandbox
  review 'Ship allowed: no\n'
  ! passes ship-allowed s01-a || fail "negative verdict accepted"
  rm docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "missing review accepted"
}

test_ship_allowed_reads_the_last_verdict() {
  sandbox
  review 'Earlier run said:\nShip allowed: yes\n\nMax severity: critical\nShip allowed: no\n'
  ! passes ship-allowed s01-a || fail "an earlier quoted verdict overrode the final one"
}

test_ship_allowed_fails_when_code_changed_after_review() {
  sandbox
  review 'Ship allowed: yes\n'
  passes ship-allowed s01-a || fail "review of the current code refused"
  echo 'z' > src/app.txt && git commit -qam 'late change'
  local err
  if err=$(bash "$GATE" ship-allowed s01-a 2>&1); then fail "code committed after the review shipped"; fi
  grep -qF '/po-review s01-a' <<< "$err" || fail "the refusal does not name /po-review s01-a: $err"
}

test_ship_allowed_ignores_docs_changes_after_review() {
  sandbox
  review 'Ship allowed: yes\n'
  echo '- [x] task' > docs/plans/s01-a.md && git add -A && git commit -qm 'record the review'
  passes ship-allowed s01-a || fail "a docs-only change reopened the review"
}

test_ship_allowed_fails_without_reviewed_tree() {
  sandbox
  local tree; tree=$(git rev-parse 'HEAD^{tree}')
  printf 'Review status: complete\nMax severity: minor\nShip allowed: yes\n' > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "a review without 'Reviewed tree:' allowed the ship"
  printf 'Review status: complete\nReviewed tree: %s\nShip allowed: yes\n' "${tree:0:12}" > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "an abbreviated tree hash was accepted"
  printf 'Review status: complete\nReviewed tree: %s\nShip allowed: yes\n' "$(printf 'f%.0s' {1..40})" > docs/reviews/s01-a.md
  ! passes ship-allowed s01-a || fail "a tree naming no object was accepted"
}

record() {
  git add -A
  printf 'Tree: %s\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | — | none here |\n\nVerification status: %s\n' \
    "$(git write-tree)" "${1:-complete}" > docs/verif/s01-a.md
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

# s49 — secret scan. Every key is assembled at run time so no literal secret ever sits in this file.
refused_naming() {
  local err
  if err=$(bash "$GATE" pre-commit 2>&1); then fail "$2 slipped past the gate"; fi
  grep -qF -- "$1" <<< "$err" || fail "refusal of $2 does not name $1: $err"
  [ -z "${3:-}" ] || ! grep -qF -- "$3" <<< "$err" || fail "refusal of $2 shows the value"
}

# Moves HEAD to another branch while keeping the index, as a developer switching branches with staged work would.
on_branch() { git branch -f "$1" HEAD 2>/dev/null || true; git symbolic-ref HEAD "refs/heads/$1"; }

test_pre_commit_refuses_a_staged_env_file() {
  sandbox
  echo 'K=v' > .env && git add .env
  refused_naming '.env: environment file staged' '.env'
  git reset -q && rm .env
  mkdir -p config && echo 'K=v' > config/.env.local && git add config
  refused_naming 'config/.env.local' 'config/.env.local'
  git reset -q && rm -r config
  echo 'K=' > .env.example && git add .env.example
  passes pre-commit || fail ".env.example refused"
  git commit -qm example
  echo 'K=v' > .env && git add .env && git commit -qm leak
  git rm -q --cached .env
  passes pre-commit || fail "unstaging a tracked .env refused"
}

test_pre_commit_refuses_obvious_keys() {
  sandbox
  local q16 a36 value
  q16="$(printf 'Q%.0s' {1..16})"; a36="$(printf 'a%.0s' {1..36})"
  for value in "-----BEGIN RSA PRIV""ATE KEY-----" "AKI""A$q16" "gh""p_$a36" "sk_""live_$a36" "sk-""ant-api03-$a36"; do
    echo "token = $value" > src/leak.txt && git add src/leak.txt
    refused_naming 'src/leak.txt:1:' "$value" "$value"
    git reset -q
  done
  printf 'pk_live_%s\ndesk_live_%s\n' "${a36:0:24}" "${a36:0:24}" > src/leak.txt && git add src/leak.txt
  passes pre-commit || fail "a publishable key or a near-miss identifier was refused"
}

# s60 — in a one-line JSON string the PEM header follows the `n` of a literal `\n`; it must still count.
test_secret_scan_finds_a_pem_key_after_an_escaped_newline() {
  sandbox
  local d='-----' header
  header="${d}BEGIN PRIV""ATE KEY${d}"
  printf '"tls": "%sEND CERTIFICATE%s\\n%s\\nMIIE"\n' "$d" "$d" "$header" > src/tls.json && git add src/tls.json
  refused_naming 'src/tls.json:1: private-key' 'a PEM key after \n'
}

test_secret_scan_runs_on_every_branch() {
  sandbox
  echo 'K=v' > .env && git add .env
  refused_naming '.env' 'a .env on main'
  on_branch feature/x
  refused_naming '.env' 'a .env on feature/x'
  on_branch story/s01-a
  plan yes && git add docs
  refused_naming '.env' 'a .env on a story with an approved plan'
  on_branch main && git reset -q && rm -f .env docs/plans/s01-a.md
  mkdir -p .polype/hooks && cp "$METHOD"/hooks/* .polype/hooks/ && chmod +x .polype/hooks/*
  git add -A && git commit -qm 'install polype'
  git config core.hooksPath .polype/hooks
  echo 'K=v' > .env && git add .env
  local err
  if err=$(git commit -qm leak 2>&1); then fail "the hook let a .env through on main"; fi
  grep -qF 'po-gate:' <<< "$err" || fail "commit failed for another reason: $err"
}

test_rules_point_at_the_secret_gate() {
  contains "$METHOD/AGENTS.md" '**Secrets never enter git.**'
  contains "$METHOD/AGENTS.md" 'the pre-commit refuses'
  contains "$METHOD/AGENTS.md" 'git status --porcelain'
  contains "$METHOD/AGENTS.md" '.env.example'
}
