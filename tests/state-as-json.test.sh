#!/usr/bin/env bash
# s164 — task tests of `po state`: framing parity with po-session, the milestone, the per-lane stops
# and orphan worktrees, and po as a state file of the payload.

POLYPE="$ROOT/bin/polype"

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# A Polype project at $F: project_at <Entry mode> [<Merge mode> <Ship confirmation>].
project_at() {
  scratch_repo
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH"
  mkdir -p "$F/.polype/hooks" "$F/docs/reviews"
  cp "$METHOD/hooks/po-gate.sh" "$F/.polype/hooks/po-gate.sh"
  sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$POLYPE" > "$F/.polype/version"
  cat > "$F/AGENTS.local.md" <<EOF
\`\`\`
Merge mode:        ${2:-local}
Target branch:     main
Ship confirmation: ${3:-automatic}
QA stage:          —
Worktree root:     .worktrees/
Entry mode:        $1
Max attempts:      2
Decision inbox:    .polype/inbox/
\`\`\`
EOF
  printf '.worktrees/\n' > "$F/.gitignore"
  commit_all init
}

commit_all() { git -C "$F" add -A; git -C "$F" commit -qm "$1"; }

# stories <surface>...: one story per surface given, s01-a, s02-b, … under one milestone.
stories() {
  local n=0 surface
  { printf '# Stories\n\n## M1 — One\n\n'
    for surface in "$@"; do n=$((n + 1)); printf '### s%02d-x — X\n- **Surface** : %s\n\n' "$n" "$surface"; done
  } > "$F/docs/stories.md"
}

po_state() { OUT="$(cd "$F" && "$PO" state 2>/dev/null)" || fail "po state failed in $F: $OUT"; }

# What po-session says the next framing command is; `null` when it says the framing is done.
session_next() {
  local out line
  out="$(CLAUDE_PROJECT_DIR="$F" bash "$METHOD/hooks/po-session.sh")"
  line="$(grep -m1 -E '^Framing next: |^Framing: setup missing → ' <<< "$out")" || fail "po-session gave no framing next: $out"
  line="${line#Framing next: }"; line="${line#Framing: setup missing → }"
  [ "$line" = "none — framing done" ] && line=null
  printf '%s' "$line"
}

# expect <stage>: po state's framing stage is <stage>, and its next is po-session's.
expect() {
  local want got
  po_state
  got="$(jq -r '.framing.stage' <<< "$OUT")"
  [ "$got" = "$1" ] || fail "framing stage $got instead of $1: $OUT"
  want="$(session_next)"
  got="$(jq -r '.framing.next // "null"' <<< "$OUT")"
  [ "$got" = "$want" ] || fail "at $1, po state says next $got, po-session says $want"
}

test_framing_next_matches_po_session() {
  need_po
  project_at new
  expect scope
  printf -- '---\nstatus: approved\n---\n# Brief\n' > "$F/docs/brief.md"; commit_all brief
  expect stories
  stories screen command; commit_all stories
  expect stories-review
  printf 'Stories ready: yes\n' > "$F/docs/reviews/stories.md"; commit_all review
  expect architecture
  printf '# Architecture\n' > "$F/docs/architecture.md"; commit_all architecture
  expect design-system
  stories command command; commit_all no-screen
  expect done
  stories screen; printf '# Design system\n' > "$F/docs/design-system.md"; commit_all ds
  expect done

  project_at —
  expect stories
  rm "$F/AGENTS.local.md"
  expect setup
}

test_milestone_is_the_first_with_a_story_not_shipped() {
  need_po
  project_at —
  printf '%s\n' '# Stories' '' '## M1 — First' '### s01-a — A' '### s02-b — B' '' \
    '## Reportées' '### s05-later — Later' '' '## M2 bis — Second' '### s03-c — C' '' \
    '## M3 — Third (à cadrer)' > "$F/docs/stories.md"
  commit_all stories
  git -C "$F" commit -q --allow-empty -m 's01-a: A'
  git -C "$F" commit -q --allow-empty -m 's02: B'
  po_state
  jq -e '.milestone == {"id": "M2 bis", "stories": 1, "shipped": 0}' <<< "$OUT" >/dev/null \
    || fail "the milestone is not the first section holding a story not shipped: $OUT"
  git -C "$F" commit -q --allow-empty -m 's03-c: C'
  po_state
  jq -e 'has("milestone") and .milestone == null' <<< "$OUT" >/dev/null || fail "every story shipped, yet a milestone: $OUT"
}

test_blocked_by_names_each_stop_and_orphans_warn() {
  need_po
  project_at — pr 'human (forge)'
  local id W
  lane() { id="$1"; W="$F/.worktrees/$1"; git -C "$F" worktree add -q -b "story/$1" "$W" main; mkdir -p "$W/docs/plans" "$W/docs/research" "$W/docs/reviews"; }

  lane s01-root; printf 'Root cause: not found\n' > "$W/docs/research/$id.md"
  lane s02-choice; printf -- '---\nvalidated: no\n---\nTechnical choice: waiting for a human\n' > "$W/docs/plans/$id.md"
  lane s03-qa; mkdir -p "$W/docs/qa/$id"; printf 'QA status: blocked\n' > "$W/docs/qa/$id/report.md"
  lane s04-attempts; printf 'Review status: complete\nFix loop: 2\nShip allowed: no\n' > "$W/docs/reviews/$id.md"
  lane s05-merge; printf 'Review status: complete\nFix loop: 0\nShip allowed: yes\n' > "$W/docs/reviews/$id.md"
  git -C "$F" update-ref "refs/remotes/origin/story/$id" main
  lane s06-plain
  git -C "$F" worktree add -q -b other "$F/.worktrees/stray" main
  git -C "$F" worktree add -q --detach "$F/.worktrees/loose" main

  po_state
  local want got bad=""
  while read -r id want; do
    got="$(jq -r --arg id "$id" '[.lanes[] | select(.story == $id) | .blocked_by // "null"] | if length == 1 then .[0] else "missing" end' <<< "$OUT")"
    [ "$got" = "$want" ] || bad+="$id: $got instead of $want; "
  done <<'EOF'
s01-root root-cause-not-found
s02-choice technical-choice
s03-qa qa-blocked
s04-attempts max-attempts
s05-merge merge-waiting
s06-plain null
EOF
  [ -z "$bad" ] || fail "blocked_by does not name the stops: $bad"
  jq -e '[.lanes[].story] | length == 6' <<< "$OUT" >/dev/null || fail "an orphan worktree counted as a lane: $OUT"
  jq -e '[.warnings[] | select(.code == "orphan-worktree")] | sort_by(.path)
         == [{"code": "orphan-worktree", "path": ".worktrees/loose", "branch": null},
             {"code": "orphan-worktree", "path": ".worktrees/stray", "branch": "other"}]' <<< "$OUT" >/dev/null \
    || fail "the orphan worktrees are not warned with their path and branch: $OUT"
}

test_po_is_a_state_file_of_the_payload() {
  command -v cargo >/dev/null 2>&1 || fail "cargo is required by this test"
  scratch_repo
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude"
  local H="$CLAUDE_CONFIG_DIR" out sum
  mkdir -p "$H"
  out="$(bash "$POLYPE" install --global 2>&1)" || fail "install --global failed: $out"
  [ -x "$H/polype/po" ] || fail "install --global did not lay po: $out"
  sum="$(cksum < "$H/polype/po")"

  out="$(bash "$H/polype/bin/polype" update --global 2>&1)" || fail "update --global from the payload stopped on po: $out"
  out="$(bash "$H/polype/bin/polype" install --global 2>&1)" || fail "install --global from the payload stopped on po: $out"
  grep -qF 'no po sources' <<< "$out" || fail "a run from the payload did not say po was not built: $out"
  [ "$(cksum < "$H/polype/po")" = "$sum" ] || fail "a run from the payload did not keep po as it was"
  out="$(bash "$H/polype/bin/polype" check --global 2>&1)" || fail "check --global is not clean with po in the payload: $out"
  if grep -qF 'po missing' <<< "$out"; then fail "check --global says po is missing: $out"; fi

  out="$(bash "$POLYPE" remove --global 2>&1)" || fail "remove --global failed: $out"
  [ ! -e "$H/polype" ] || fail "remove --global left the payload (and po) behind: $(find "$H/polype")"
}
