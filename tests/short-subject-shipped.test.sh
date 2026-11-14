#!/usr/bin/env bash
# s112 — a story shipped under a bare "sNN:" subject counts as shipped.

HOOK="$METHOD/hooks/po-session.sh"

session_in() { (cd "$1" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }

project_with_stories() {
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\nParallel: 3\n' > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
  mkdir -p "$R/docs"
  : > "$R/docs/stories.md"
  local spec id dep
  for spec in "$@"; do
    id="${spec%%:*}"; dep="${spec#*:}"
    printf '## %s\n\n- **Depends on**: %s\n\n' "$id" "$dep" >> "$R/docs/stories.md"
  done
  git -C "$R" add -A && git -C "$R" commit -qm framing
}

test_short_subject_counts_as_shipped() {
  project_with_stories s01-x:none s02-y:none
  git -C "$R" commit -q --allow-empty -m 's01: x'
  session_in "$R" | grep -qxF 'Ready stories: s02-y' \
    || fail "a bare s01: subject does not count as shipped in the session output"
}

test_short_subject_is_exact() {
  project_with_stories s1-a:none s10-x:none s100-y:none
  git -C "$R" commit -q --allow-empty -m 's1: a'
  git -C "$R" commit -q --allow-empty -m 's10-autre: b'
  local out; out="$(session_in "$R")"
  grep -qxF 'Ready stories: s10-x, s100-y' <<< "$out" \
    || fail "unexpected session output:"$'\n'"$out"
}

test_session_lists_no_short_shipped_story() {
  project_with_stories s01-x:none s02-y:s01-x
  git -C "$R" commit -q --allow-empty -m 's01: x'
  local out; out="$(session_in "$R")"
  grep -qxF 'Ready stories: s02-y' <<< "$out" \
    || fail "unexpected session output:"$'\n'"$out"
}
