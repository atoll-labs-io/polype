#!/usr/bin/env bash
# s120 — the ship gate needs a complete review status; po-session flags a technical choice and skips a useless design system.

GATE="$METHOD/hooks/po-gate.sh"
HOOK="$METHOD/hooks/po-session.sh"

session_in() { (cd "$1" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }

test_ship_gate_needs_review_status() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p docs/reviews src
  echo x > src/app.txt
  git add -A && git commit -qm init
  local T; T="$(git rev-parse 'HEAD^{tree}')"
  review() { printf '%b' "$1" > docs/reviews/s01-a.md; }
  ok() { bash "$GATE" ship-allowed s01-a 2>/dev/null; }

  review "Review status: complete\nReviewed tree: $T\nShip allowed: yes\n"
  ok || fail "a complete review was refused"
  review "- Review status: complete\nReviewed tree: $T\nShip allowed: yes\n"
  ok || fail "a list-item status was refused"

  review "Reviewed tree: $T\nShip allowed: yes\n"
  ! ok || fail "a review with no status line shipped"
  local err; err="$(bash "$GATE" ship-allowed s01-a 2>&1 || true)"
  grep -qF 'Review status:' <<< "$err" || fail "the refusal does not name Review status: $err"

  review "Review status: blocked\nReviewed tree: $T\nShip allowed: yes\n"
  ! ok || fail "a blocked status shipped"
  review "Review status: complete\nReviewed tree: $T\nShip allowed: no\nReviewed tree: $T\nShip allowed: yes\n"
  ! ok || fail "an appended review borrowed the status of an earlier block"
  review "Review status: complete\nReviewed tree: $T\nShip allowed: yes\nReview status: blocked\n"
  ! ok || fail "a blocked status written after the verdict was ignored"

  contains "$METHOD/AGENTS.md" 'without `Review status: complete`'
  contains "$METHOD/commands/po-ship.md" 'must both read `Review status: complete`'
}

test_session_flags_a_technical_choice() {
  scratch_repo
  local R; R="$(cd "$SCRATCH" && pwd -P)"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\n' > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
  mkdir -p "$R/docs"; printf -- '---\nstatus: approved\n---\n# Brief\n' > "$R/docs/brief.md"
  git -C "$R" add -A && git -C "$R" commit -qm framing
  local id
  for id in s05-x s06-y; do
    git -C "$R" worktree add -q -b "story/$id" "$R/.worktrees/$id" main
    mkdir -p "$R/.worktrees/$id/docs/plans"
  done
  printf -- '---\nvalidated: no\n---\nTechnical choice: waiting for a human\n' > "$R/.worktrees/s05-x/docs/plans/s05-x.md"
  printf -- '---\nvalidated: yes\n---\nTechnical choice: waiting for a human\n' > "$R/.worktrees/s06-y/docs/plans/s06-y.md"
  local out; out="$(session_in "$R")"
  grep -qxF -- '- s05-x: technical choice waiting for a human (docs/plans/s05-x.md) → /po-plan s05-x' <<< "$out" \
    || fail "marker not listed: $out"
  ! grep -q 's06-y: technical' <<< "$out" || fail "a validated plan was listed: $out"
}

test_design_system_only_with_a_screen() {
  scratch_repo
  local R; R="$(cd "$SCRATCH" && pwd -P)"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\n' > "$R/AGENTS.local.md"
  mkdir -p "$R/docs/reviews"
  printf -- '---\nstatus: approved\n---\n# Brief\n' > "$R/docs/brief.md"
  printf 'Stories ready: yes\n' > "$R/docs/reviews/stories.md"
  echo '# Architecture' > "$R/docs/architecture.md"
  stories() { printf '## s01-a Alpha\n\n- **Surface**: `command`\n\n## s02-b Beta\n\n%s\n' "$1" > "$R/docs/stories.md"
    git -C "$R" add -A && git -C "$R" commit -qm "stories" --allow-empty; }
  local out

  stories '- **Surface** : —'
  out="$(session_in "$R")"
  grep -qF 'design system not needed' <<< "$out" || fail "screenless project still needs a design system: $out"
  grep -qxF 'Framing next: none — framing done' <<< "$out" || fail "framing not done: $out"

  stories '- **Surface**: `screen`'
  out="$(session_in "$R")"
  grep -qF 'design system missing' <<< "$out" || fail "screen story: $out"
  grep -qxF 'Framing next: /po-design-system' <<< "$out" || fail "screen story: no design-system step: $out"

  stories 'Some text, no surface line.'
  out="$(session_in "$R")"
  grep -qF 'design system missing' <<< "$out" || fail "story without Surface treated as screenless: $out"
}
