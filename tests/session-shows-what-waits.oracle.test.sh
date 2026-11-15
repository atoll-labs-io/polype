#!/usr/bin/env bash
# s184 — the oracle of the story: po-session lists the pending decisions under "Waiting for a human"
# and counts the answered ones not consumed yet (#315); the framing of this repository reads its
# stories review, and a project holding docs/reviews/stories.md reads as before (#244).

PO="${PO:-${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po}"
HOOK="$METHOD/hooks/po-session.sh"

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# A Polype project at $R with one story and an inbox; the hook finds the built po under $C.
project() {
  need_po
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  C="$R/.config"
  mkdir -p "$C/polype" "$R/docs" "$R/.polype/inbox"
  cp "$PO" "$C/polype/po"
  printf '%s\n' 'Target branch: main' 'Worktree root: .worktrees/' 'Entry mode: —' 'Parallel: 2' \
    'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)' \
    'Decision inbox: .polype/inbox/' 'Project CLAUDE file: absorbed' > "$R/AGENTS.local.md"
  printf '.worktrees/\n.config/\n.polype/inbox/\n' > "$R/.gitignore"
  printf '# Stories\n\n## M1 — One\n\n### s01-a — A\n- **Surface** : command\n' > "$R/docs/stories.md"
  git -C "$R" add -A && git -C "$R" commit -qm framing
}

# decision <id> <status> [sensitive] [consumed]: one decision file of the inbox. A sensitive one
# carries a witness string in its question and context, which nothing may print.
decision() {
  local sensitive=false text="Which runner runs the suite?" answer=null consumed=""
  [ "${3:-}" = sensitive ] && { sensitive=true; text="zq-witness-7f3c"; }
  [ "$2" = answered ] && answer='{"key": "a", "at": "2026-11-15T10:00:00+01:00"}'
  [ "${4:-}" = consumed ] && consumed=', "consumed": {"ref": "docs/plans/s01-a.md", "at": "2026-11-15T11:00:00+01:00"}'
  cat > "$R/.polype/inbox/$1.json" <<EOF
{"id": "$1", "asked": "2026-11-15T09:00:00+01:00", "motive": "strategic", "sensitive": $sensitive,
 "question": "$text", "context": "$text",
 "options": [{"key": "a", "label": "A", "consequence": "a"}, {"key": "b", "label": "B", "consequence": "b"}],
 "recommended": "a", "why": "w", "reversible": true, "blocks": ["s01-a"],
 "status": "$2", "answer": $answer$consumed}
EOF
}

session() {
  OUT="$(cd "$R" && CLAUDE_CONFIG_DIR="$C" CLAUDE_PROJECT_DIR="$R" bash "$HOOK" 2>&1)" \
    || fail "po-session exited non-zero: $OUT"
}

has_line() { grep -qxF -- "$1" <<< "$OUT" || fail "po-session did not print the line: $1"$'\n'"$OUT"; }
lacks_text() { if grep -qF -- "$1" <<< "$OUT"; then fail "po-session printed: $1"$'\n'"$OUT"; fi; }

# review_state: the state po state gives the stories-review framing item in $R.
review_state() {
  local out
  out="$(cd "$R" && "$PO" state 2>/dev/null)" || fail "po state failed in $R: $out"
  jq -r '.framing.items[] | select(.item == "stories-review") | .state' <<< "$out"
}

test_session_lists_pending_decisions() {
  project
  session
  has_line 'Waiting for a human: nothing'

  decision d-0001 pending
  decision d-0002 pending sensitive
  decision d-0003 answered
  session
  has_line 'Waiting for a human:'
  lacks_text 'Waiting for a human: nothing'
  has_line '- d-0001: decision pending → po inbox d-0001'
  has_line '- d-0002: decision pending → po inbox d-0002'
  if grep -q '^- d-0003' <<< "$OUT"; then fail "an answered decision is listed as waiting:"$'\n'"$OUT"; fi
  lacks_text 'zq-witness-7f3c'
}

test_session_counts_answered_not_consumed() {
  project
  decision d-0001 pending
  decision d-0002 answered
  decision d-0003 answered '' consumed
  decision d-0004 answered
  session
  has_line 'Decisions answered, not consumed: 2 → po inbox --answered'
  local state
  state="$(cd "$R" && "$PO" state 2>/dev/null)" || fail "po state failed: $state"
  jq -e '.answered == ["d-0002", "d-0004"]' <<< "$state" >/dev/null \
    || fail "po state does not list the answered decisions not consumed: $(jq -c '.answered' <<< "$state")"

  rm "$R/.polype/inbox/d-0002.json" "$R/.polype/inbox/d-0004.json"
  session
  has_line 'Decisions answered, not consumed: none'
  lacks_text 'po inbox --answered'
}

# Option B of ADR-0126: this repository holds docs/reviews/stories.md. Its settings, stories and
# stories reviews, as they stand in the working tree, are read by po state on a branch main.
test_this_repository_reads_reviewed() {
  need_po
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  mkdir -p "$R/docs/reviews"
  cp "$ROOT/AGENTS.local.md" "$R/AGENTS.local.md"
  cp "$ROOT/docs/stories.md" "$R/docs/stories.md"
  cp "$ROOT"/docs/reviews/stories*.md "$R/docs/reviews/"
  git -C "$R" add -A && git -C "$R" commit -qm framing
  [ "$(review_state)" = yes ] || fail "the stories review of this repository reads '$(review_state)', not yes"
}

test_single_file_projects_read_the_same() {
  project
  [ "$(review_state)" = none ] || fail "no review file reads '$(review_state)', not none"

  mkdir -p "$R/docs/reviews"
  printf '# Stories review\n\nReview status: complete\nMax severity: minor\nStories ready: yes\n' > "$R/docs/reviews/stories.md"
  printf 'Stories ready: no\n' > "$R/docs/reviews/stories-m1.md"
  printf 'Stories ready: no\n' > "$R/docs/reviews/stories-intake-2026-11-15-1000.md"
  git -C "$R" add -A && git -C "$R" commit -qm review
  local out
  out="$(cd "$R" && "$PO" state 2>/dev/null)" || fail "po state failed: $out"
  jq -e '.framing == {stage: "architecture", next: "/po-architect", items: [
      {item: "scope", state: "by hand"}, {item: "stories", state: "present"},
      {item: "stories-review", state: "yes"}, {item: "architecture", state: "missing"},
      {item: "design-system", state: "not needed"}]}' <<< "$out" >/dev/null \
    || fail "the framing of a single-file project moved: $(jq -c .framing <<< "$out")"

  printf 'Stories ready: no\n' > "$R/docs/reviews/stories.md"
  printf 'Stories ready: yes\n' > "$R/docs/reviews/stories-m1.md"
  git -C "$R" add -A && git -C "$R" commit -qm review
  [ "$(review_state)" = no ] || fail "docs/reviews/stories.md says no, yet the review reads '$(review_state)'"
}

test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$(printf '0.4.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.4.0 ] \
    || fail "po's version $toml is not a minor step above 0.3.2"
}
