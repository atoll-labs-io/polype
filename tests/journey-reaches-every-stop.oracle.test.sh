#!/usr/bin/env bash
# s200 — the oracle of the story: the replayed journey of s199 also walks the short track, a story
# with a screen through design and QA, a refused review through its fix runs, a decision of the
# inbox, a human merge, and every `ask` reason po/src/next/ can give. Every journey runs inside the
# one folder journey_init makes, removed on any exit.

source "$ROOT/tests/journey/journey.sh"

ANSWERS="$ROOT/tests/journey/answers"

need_journey() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

log_has() { grep -qF -- "$1" "$JOURNEY_LOG" || fail "the journey log does not say: $1 — log: $(cat "$JOURNEY_LOG")"; }

# entries_of <id>: `<action> (<reason>) <track>` of each po next entry the last run met for <id>.
entries_of() { awk -F'\t' -v id="$1" '$1 == "entry" && $3 == id {print $4 " (" $5 ") " $6}' "$JOURNEY_LOG"; }

landed_on() { [ "$(git -C "$1" log -1 --format=%s main)" = "$2" ] || fail "main of $1 does not end with '$2': $(git -C "$1" log --format=%s -3 main)"; }

not_landed() { ! git -C "$R" log --format=%s main | grep -q "^$1:" || fail "$1 landed: $(git -C "$R" log --format=%s -3 main)"; }

# shipped <id>: po state --all gives <id> as shipped, stamped by po record, with no lane left.
shipped() {
  local state
  state="$(cd "$R" && "$PO" state --all)" || fail "po state failed: $state"
  jq -e --arg id "$1" '[.shipped[]? | select(.story == $id and .commit != null and .trust.method_version != null)] | length == 1' \
    <<< "$state" >/dev/null || fail "po state does not give $1 as shipped with a recorded review: $state"
  jq -e --arg id "$1" '[.lanes[]? | select(.story == $id)] | length == 0' <<< "$state" >/dev/null \
    || fail "po state still shows a lane for $1: $state"
}

test_short_track_lands() {
  need_journey
  journey_init
  journey_kind local
  journey_story s01-greeting 'Une salutation'
  journey_story_set s01-greeting Complexité 2
  journey_answers s01-greeting "$ANSWERS/flow" "$ANSWERS/plain"
  journey_run || fail "the journey stopped: $(cat "$JOURNEY_LOG")"
  local want
  want="$(printf '%s\n' 'plan (ready) flow' 'validate-plan (plan-validated refuses) -' \
    'execute (verif-current refuses) -' 'review (no review) -' 'ship (ship-allowed passes) -')"
  [ "$(entries_of s01-greeting)" = "$want" ] || fail "the short track did not cross the same gates: $(cat "$JOURNEY_LOG")"
  landed_on "$R" 's01-greeting: Une salutation'
  ! git -C "$R" cat-file -e main:docs/research/s01-greeting.md 2>/dev/null || fail "the short track landed a research file"
  git -C "$R" cat-file -e main:docs/plans/s01-greeting.md 2>/dev/null || fail "the landing commit lacks the plan"
  shipped s01-greeting
  jq -e '[.shipped[] | select(.story == "s01-greeting" and .trust.track == "flow")] | length == 1' \
    <<< "$(cd "$R" && "$PO" state --all)" >/dev/null || fail "po state does not read the landed plan as the short track"
}

test_screen_story_goes_through_design_and_qa() {
  need_journey
  journey_init
  journey_kind screen
  grep -qx 'QA stage: screens' "$R/AGENTS.local.md" || fail "the screen project does not run under QA stage: screens"
  journey_story s01-greeting 'Une salutation'
  journey_story_set s01-greeting Surface screen
  journey_answers s01-greeting "$ANSWERS/screen" "$ANSWERS/plain"
  # Stopped right after the QA stage, so the story branch can be read before the ship cleans it up.
  if JOURNEY_MAX_WAVES=6 journey_run; then fail "the journey ran past six waves: $(cat "$JOURNEY_LOG")"; fi
  log_has $'stopped\tmore than 6 waves'
  local want paths lane
  want="$(printf '%s\n' 'plan (ready) full' 'design (no design) -' 'plan (research, no plan) full' \
    'validate-plan (plan-validated refuses) -' 'execute (verif-current refuses) -' 'qa (qa-current refuses) -')"
  [ "$(entries_of s01-greeting)" = "$want" ] || fail "design did not come before the plan, or QA after the code: $(cat "$JOURNEY_LOG")"
  [ "$(git -C "$R" log --format=%s main..story/s01-greeting)" = "$(printf '%s\n' 's01-greeting: QA evidence' 's01-greeting: Une salutation')" ] \
    || fail "the QA evidence is not one commit on top of the story's: $(git -C "$R" log --format=%s main..story/s01-greeting)"
  paths="$(git -C "$R" show --name-only --format= story/s01-greeting)"
  grep -qx 'docs/qa/s01-greeting/report.md' <<< "$paths" || fail "the evidence commit lacks the report: $paths"
  [ -z "$(grep -v '^docs/qa/s01-greeting/' <<< "$paths")" ] || fail "the evidence commit holds more than docs/qa/s01-greeting/: $paths"
  git -C "$R" show story/s01-greeting:docs/qa/s01-greeting/report.md | grep -q '^Method version:' \
    || fail "the QA report was not written by po record qa"
  lane="$(journey_lane s01-greeting)"
  (cd "$lane" && bash .polype/hooks/po-gate.sh qa-current s01-greeting) >/dev/null 2>&1 || fail "po-gate qa-current refuses the recorded QA"
  journey_run || fail "the journey stopped after QA: $(cat "$JOURNEY_LOG")"
  [ "$(entries_of s01-greeting)" = "$(printf '%s\n' 'review (no review) -' 'ship (ship-allowed passes) -')" ] \
    || fail "the review did not follow the QA: $(cat "$JOURNEY_LOG")"
  landed_on "$R" 's01-greeting: Une salutation'
  local path
  for path in docs/designs/s01-greeting/design.md docs/qa/s01-greeting/report.md; do
    git -C "$R" cat-file -e "main:$path" 2>/dev/null || fail "the landing commit lacks $path"
  done
  shipped s01-greeting
}

test_blocked_review_loops_then_asks() {
  need_journey
  journey_init
  journey_kind local
  journey_story s01-greeting 'Une salutation'
  journey_answers s01-greeting "$ANSWERS/refused" "$ANSWERS/plain"
  if journey_run; then fail "a story whose every review refuses the ship went on: $(cat "$JOURNEY_LOG")"; fi
  log_has $'stopped\task for s01-greeting: Max attempts reached'
  local want lane
  want="$(printf '%s\n' 'plan (ready) full' 'validate-plan (plan-validated refuses) -' 'execute (verif-current refuses) -' \
    'review (no review) -' 'fix (Ship allowed: no) -' 'review (review judged earlier code) -' \
    'fix (Ship allowed: no) -' 'review (review judged earlier code) -' 'ask (Max attempts reached) -')"
  [ "$(entries_of s01-greeting)" = "$want" ] || fail "the refused reviews did not loop through fix runs: $(cat "$JOURNEY_LOG")"
  lane="$(journey_lane s01-greeting)"
  [ "$(sed -n 's/^Fix loop:[[:space:]]*//p' "$lane/docs/reviews/s01-greeting.md" | tr '\n' ' ')" = '0 1 2 ' ] \
    || fail "the reviews were not recorded at fix loops 0, 1 and 2: $(grep '^Fix loop:' "$lane/docs/reviews/s01-greeting.md")"
  [ "$(git -C "$R" log --format=%s main..story/s01-greeting | grep -cx 's01-greeting: address review findings')" = 2 ] \
    || fail "the story branch does not hold two fix runs: $(git -C "$R" log --format=%s main..story/s01-greeting)"
  not_landed s01-greeting
}

test_pending_decision_holds_the_lane() {
  need_journey
  journey_init
  journey_kind local
  journey_story s01-greeting 'Une salutation'
  journey_answers s01-greeting "$ANSWERS/choice" "$ANSWERS/plain"
  if journey_run; then fail "a plan waiting for a technical choice went on: $(cat "$JOURNEY_LOG")"; fi
  log_has $'stopped\task for s01-greeting: Technical choice: waiting for a human'
  local decision shown key plan
  decision="$(awk -F'\t' '$1 == "asked" && $2 == "s01-greeting" {print $3}' "$JOURNEY_LOG")"
  [ -n "$decision" ] || fail "the ask was not put in the inbox: $(cat "$JOURNEY_LOG")"
  shown="$(cd "$R" && "$PO" inbox "$decision")" || fail "po inbox cannot show $decision: $shown"
  jq -e '.status == "pending" and .blocks == ["s01-greeting"]' <<< "$shown" >/dev/null \
    || fail "the decision is not a pending one blocking s01-greeting: $shown"
  if journey_run; then fail "the lane went on under a pending decision: $(cat "$JOURNEY_LOG")"; fi
  log_has $'stopped\tnothing moves'
  [ "$(entries_of s01-greeting)" = "wait (decision $decision) -" ] || fail "the pending decision did not hold the lane: $(cat "$JOURNEY_LOG")"
  key="$(jq -r '.options[0].key' <<< "$shown")"
  (cd "$R" && "$PO" answer "$decision" "$key") >/dev/null || fail "po answer refused $decision $key"
  if journey_run; then fail "the lane went on before the answer was consumed: $(cat "$JOURNEY_LOG")"; fi
  [ "$(entries_of s01-greeting)" = "wait (decision $decision) -" ] || fail "an answered decision stopped holding the lane: $(cat "$JOURNEY_LOG")"
  # What the answer produces lands where it lives, as /po-plan records it; then the lead consumes it.
  plan="$(journey_lane s01-greeting)/docs/plans/s01-greeting.md"
  grep -vx 'Technical choice: waiting for a human' "$plan" > "$plan.new" && mv "$plan.new" "$plan"
  (cd "$R" && "$PO" inbox consume "$decision" docs/plans/s01-greeting.md) >/dev/null || fail "po inbox consume refused $decision"
  journey_run || fail "the lane did not resume once the decision was consumed: $(cat "$JOURNEY_LOG")"
  [ "$(entries_of s01-greeting | head -n 1)" = 'validate-plan (plan-validated refuses) -' ] \
    || fail "the lane did not resume at its plan: $(cat "$JOURNEY_LOG")"
  landed_on "$R" 's01-greeting: Une salutation'
  shipped s01-greeting
}

test_human_confirmation_waits_for_the_merge() {
  need_journey
  journey_init
  journey_kind pr-human
  journey_story s01-greeting 'Une salutation'
  if journey_run; then fail "the journey ended before a person merged: $(cat "$JOURNEY_LOG")"; fi
  log_has $'stopped\tnothing moves'
  [ "$(entries_of s01-greeting | tail -n 2)" = "$(printf '%s\n' 'ship (ship-allowed passes) -' 'wait (merge waiting) -')" ] \
    || fail "the lane does not wait for the merge after its ship: $(cat "$JOURNEY_LOG")"
  local url sha calls
  url="$(awk -F'\t' '$1 == "pr-waiting" && $2 == "s01-greeting" {print $3}' "$JOURNEY_LOG")"
  [ -n "$url" ] || fail "no pull request was left for a person: $(cat "$JOURNEY_LOG")"
  calls="$(journey_calls gh)"
  [ "$(grep -c '^pr create ' <<< "$calls")" = 1 ] || fail "not exactly one pull request was opened: $calls"
  ! grep -q '^pr merge ' <<< "$calls" || fail "po merged under a human confirmation: $calls"
  [ "$(git -C "$ORIGIN" log -1 --format=%s main)" != 's01-greeting: Une salutation' ] || fail "the story landed before a person merged"
  sha="$(git -C "$ORIGIN" rev-parse -q --verify refs/heads/story/s01-greeting)" || fail "the story branch is not on origin"
  # The person merges on the forge, then runs /po-ship again for the cleanup (po-ship.md, Step 2).
  gh pr merge "$url" --repo github.com/acme/project --rebase --match-head-commit "$sha" >/dev/null || fail "the forge double refused the merge"
  journey_by_hand s01-greeting ship || fail "the ship run again after the merge stopped: $(cat "$JOURNEY_LOG")"
  journey_run || fail "the journey did not end once the lane was cleaned up: $(cat "$JOURNEY_LOG")"
  landed_on "$ORIGIN" 's01-greeting: Une salutation'
  [ -z "$(git -C "$ORIGIN" for-each-ref refs/heads/story)" ] || fail "origin keeps a story branch"
  [ "$(git -C "$R" worktree list --porcelain | grep -c '^worktree ')" = 1 ] || fail "a worktree is left: $(git -C "$R" worktree list)"
  shipped s01-greeting
}

test_every_ask_reason_is_reached() {
  need_journey
  source "$ROOT/tests/journey/stops.sh"
  journey_init
  local stop stops reasons missing
  stops="$(declare -F | awk '$3 ~ /^stop_/ {print $3}')"
  [ -n "$stops" ] || fail "tests/journey/stops.sh defines no stop_ journey"
  for stop in $stops; do
    ( "$stop" ) || fail "$stop did not end on an ask: $(cat "$JOURNEY_LOG")"
  done
  reasons="$(journey_ask_reasons "$ROOT/po/src/next")" || fail "the ask reasons of po/src/next/ cannot all be read: $reasons"
  [ -n "$reasons" ] || fail "no ask reason was read in po/src/next/"
  missing="$(journey_unreached "$ROOT/po/src/next")" \
    || fail "po next can answer ask with a reason no journey reaches: $missing"
}
