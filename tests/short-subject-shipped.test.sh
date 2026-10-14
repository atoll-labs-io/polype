#!/usr/bin/env bash
# s112 — a story shipped under a bare "sNN:" subject counts as shipped.

HOOK="$METHOD/hooks/po-session.sh"
SENTENCE='a story `s<n>-<slug>` is shipped when a commit on `Target branch` or `origin/<Target branch>` has a subject starting with `<id>:`, or, when no commit does, with `s<n>:` exactly, its number written as the id writes it'

session_in() { (cd "$1" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }

project_with_stories() {
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\n' > "$R/AGENTS.local.md"
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
  local f
  for f in po-status po-drive; do
    grep -qF -- "$SENTENCE" "$METHOD/commands/$f.md" || fail "$f.md lacks the shared sentence"
  done
  project_with_stories s01-x:none s02-y:none
  git -C "$R" commit -q --allow-empty -m 's01: x'
  session_in "$R" | grep -qxF 'Ready stories: s02-y (Owns not checked: /po-drive decides)' \
    || fail "a bare s01: subject does not count as shipped in the session output"
}

test_short_subject_is_exact() {
  project_with_stories s1-a:none s10-x:none s100-y:none
  git -C "$R" commit -q --allow-empty -m 's1: a'
  git -C "$R" commit -q --allow-empty -m 's10-autre: b'
  local out; out="$(session_in "$R")"
  grep -qxF 'Ready stories: s10-x, s100-y (Owns not checked: /po-drive decides)' <<< "$out" \
    || fail "unexpected session output:"$'\n'"$out"
}

test_session_lists_no_short_shipped_story() {
  project_with_stories s01-x:none s02-y:s01-x
  git -C "$R" commit -q --allow-empty -m 's01: x'
  local out; out="$(session_in "$R")"
  grep -qxF 'Ready stories: s02-y (Owns not checked: /po-drive decides)' <<< "$out" \
    || fail "unexpected session output:"$'\n'"$out"
}
