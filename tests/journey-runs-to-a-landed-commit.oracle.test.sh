#!/usr/bin/env bash
# s199 — the oracle of the story: a replayed journey walks stories from the action `plan` to the
# commit landed on Target branch, with no model, through the real gates and `po ship`. The journey
# lives in tests/journey/ (journey.sh, its doubles, its throwaway project, its written answers);
# every journey runs inside the one folder journey_init makes, removed on any exit.

source "$ROOT/tests/journey/journey.sh"

PLAIN="$ROOT/tests/journey/answers/plain"

need_journey() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

log_has() { grep -qF -- "$1" "$JOURNEY_LOG" || fail "the journey log does not say: $1 — log: $(cat "$JOURNEY_LOG")"; }

# entries_of <id>: `<action> (<reason>) <track>` of each po next entry the journey met for <id>.
entries_of() { awk -F'\t' -v id="$1" '$1 == "entry" && $3 == id {print $4 " (" $5 ") " $6}' "$JOURNEY_LOG"; }

# recorded_at <rev> <id>: the newest `Recorded:` of the review <rev> holds, in seconds.
recorded_at() {
  local stamp
  stamp="$(git -C "$R" show "$1:docs/reviews/$2.md" | sed -n 's/^Recorded:[[:space:]]*//p' | tail -n 1)"
  [ -n "$stamp" ] || fail "the review of $2 at $1 has no Recorded: line"
  date -d "$stamp" +%s
}

# shipped <id>: po state --all gives <id> as shipped, with the stamp po record wrote, and no lane.
shipped() {
  local state
  state="$(cd "$R" && "$PO" state --all)" || fail "po state failed: $state"
  jq -e --arg id "$1" '[.shipped[]? | select(.story == $id and .commit != null and .trust.method_version != null)] | length == 1' \
    <<< "$state" >/dev/null || fail "po state does not give $1 as shipped with a recorded review: $state"
  jq -e --arg id "$1" '[.lanes[]? | select(.story == $id)] | length == 0' <<< "$state" >/dev/null \
    || fail "po state still shows a lane for $1: $state"
}

test_journey_follows_po_next() {
  need_journey
  journey_init
  journey_answers s01-greeting "$PLAIN"
  # po next names an action the written answers do not cover: the journey applies what po next
  # gives, never a route of its own, so it stops on that action and names it.
  if (
    journey_po_next() {
      printf '%s\n' '{"contract":1,"actions":[{"story":"s01-greeting","action":"design","reason":"no design"}],"ready":[],"held":[],"warnings":[]}'
    }
    journey_run
  ); then
    fail "the journey went past an action it has no answer for: $(cat "$JOURNEY_LOG")"
  fi
  log_has 'no written answer for design of s01-greeting'
  [ "$(entries_of s01-greeting)" = 'design (no design) -' ] \
    || fail "the journey did not apply the action po next gave: $(cat "$JOURNEY_LOG")"

  # A real project whose answers stop short of the review: each step before it is the one po next
  # named, with po next's own reason, and the missing answer stops the journey there.
  mkdir -p "$J/answers"
  cp -R "$PLAIN" "$J/answers/no-review"
  rm "$J/answers/no-review/review.md"
  journey_project local
  journey_story s01-greeting 'Une salutation' "$J/answers/no-review"
  if journey_run; then fail "the journey went on without a review answer: $(cat "$JOURNEY_LOG")"; fi
  log_has 'no written answer for review of s01-greeting'
  local want
  want="$(printf '%s\n' 'plan (ready) full' 'validate-plan (plan-validated refuses) -' \
    'execute (verif-current refuses) -' 'review (no review) -')"
  [ "$(entries_of s01-greeting)" = "$want" ] || fail "the journey did not follow po next step by step: $(cat "$JOURNEY_LOG")"
}

test_story_lands_on_the_full_track() {
  need_journey
  journey_init
  journey_project local
  journey_story s01-greeting 'Une salutation'
  journey_run || fail "the journey stopped: $(cat "$JOURNEY_LOG")"
  [ "$(entries_of s01-greeting | head -n 1)" = 'plan (ready) full' ] \
    || fail "po next did not open s01-greeting on the full track: $(cat "$JOURNEY_LOG")"
  [ "$(git -C "$R" log -1 --format=%s main)" = 's01-greeting: Une salutation' ] \
    || fail "main does not end with the landing commit: $(git -C "$R" log --format=%s -3 main)"
  [ "$(git -C "$R" rev-list --parents -n 1 main | wc -w)" = 2 ] || fail "the landing commit is a merge commit"
  local path
  for path in src/s01-greeting.txt docs/research/s01-greeting.md docs/plans/s01-greeting.md \
    docs/verif/s01-greeting.md docs/reviews/s01-greeting.md; do
    git -C "$R" cat-file -e "main:$path" 2>/dev/null || fail "the landing commit lacks $path"
  done
  shipped s01-greeting
  [ "$(git -C "$R" worktree list --porcelain | grep -c '^worktree ')" = 1 ] \
    || fail "a worktree is left: $(git -C "$R" worktree list)"
  ! git -C "$R" rev-parse -q --verify refs/heads/story/s01-greeting >/dev/null || fail "story/s01-greeting is left"
  [ -z "$(journey_calls gh)" ] || fail "a forge call was made under Merge mode: local: $(journey_calls gh)"
}

test_story_lands_through_a_pull_request() {
  need_journey
  journey_init
  journey_project pr
  journey_story s01-greeting 'Une salutation'
  journey_run || fail "the journey stopped: $(cat "$JOURNEY_LOG")"
  [ "$(git -C "$ORIGIN" log -1 --format=%s main)" = 's01-greeting: Une salutation' ] \
    || fail "origin's main does not end with the landing commit: $(git -C "$ORIGIN" log --format=%s -3 main)"
  # Every ref a push sent is the story branch, never Target branch; the hook logged at least one.
  local pushed calls
  pushed="$(journey_pushed)"
  grep -qx 'refs/heads/story/s01-greeting' <<< "$pushed" || fail "no push of story/s01-greeting reached origin: $pushed"
  [ -z "$(grep -vx 'refs/heads/story/s01-greeting' <<< "$pushed")" ] || fail "a push sent another ref than the story branch: $pushed"
  calls="$(journey_calls gh)"
  [ "$(grep -c '^pr create ' <<< "$calls")" = 1 ] || fail "not exactly one pull request was opened: $calls"
  grep '^pr create ' <<< "$calls" | grep -qF -- '--base main --head story/s01-greeting' \
    || fail "the pull request does not go from story/s01-greeting to main: $calls"
  [ "$(grep -c '^pr merge ' <<< "$calls")" = 1 ] || fail "the forge was not asked one merge: $calls"
  ! grep -qE -- '--head main( |$)' <<< "$calls" || fail "a forge call names main as a head: $calls"
  [ "$(grep -c 'repos/acme/project/issues' <<< "$calls")" = 1 ] || fail "the review's finding was not filed once: $calls"
  [ -z "$(git -C "$ORIGIN" for-each-ref refs/heads/story)" ] || fail "origin keeps a story branch"
  shipped s01-greeting
}

test_two_lanes_ship_in_order() {
  need_journey
  journey_init
  journey_project local
  # s02 is written first in docs/stories.md, so it ranks first; lanes are applied in id order, so
  # s01's review is recorded first. The ships must follow the reviews, not the rank.
  journey_story s02-farewell 'Un au revoir'
  journey_story s01-greeting 'Une salutation'
  journey_run || fail "the journey stopped: $(cat "$JOURNEY_LOG")"
  [ "$(awk -F'\t' '$1 == "entry" && $2 == 1 && $4 == "plan" && $5 == "ready" {print $3}' "$JOURNEY_LOG" | sort)" \
    = "$(printf '%s\n' s01-greeting s02-farewell)" ] || fail "the two stories did not open in the same wave: $(cat "$JOURNEY_LOG")"
  awk -F'\t' '$1 == "entry" && $3 == "s02-farewell" && $4 == "wait" && $5 == "ships serial: s01-greeting" {f = 1} END {exit !f}' \
    "$JOURNEY_LOG" || fail "s02-farewell never waited behind s01-greeting's ship: $(cat "$JOURNEY_LOG")"
  [ "$(git -C "$R" log -2 --format=%s main)" = "$(printf '%s\n' 's02-farewell: Un au revoir' 's01-greeting: Une salutation')" ] \
    || fail "the stories did not land one after the other, s01 first: $(git -C "$R" log --format=%s -3 main)"
  [ "$(recorded_at main~1 s01-greeting)" -lt "$(recorded_at main s02-farewell)" ] \
    || fail "s01-greeting's review was not recorded before s02-farewell's"
  shipped s01-greeting
  shipped s02-farewell
}

test_real_gates_are_crossed() {
  need_journey
  journey_init
  journey_project local
  journey_story s01-greeting 'Une salutation'
  [ "$(git -C "$R" config core.hooksPath)" = .polype/hooks ] || fail "the method's pre-commit is not active in the throwaway project"
  journey_snapshot
  # Each run takes one step out; the journey must stop at the gate that step opens, landing nothing.
  stops_at() {
    log_has "$1"
    ! git -C "$R" log --format=%s main | grep -q '^s01-greeting:' || fail "s01-greeting landed with a step removed: $1"
  }
  if (git -C "$R" config --unset core.hooksPath && journey_run); then fail "the journey landed without the pre-commit"; fi
  stops_at 'the pre-commit accepted a code commit on story/s01-greeting before its plan was approved'
  journey_restore
  if (journey_validate_line() { :; } && journey_run); then fail "the journey landed without validating the plan"; fi
  stops_at 's01-greeting: po next answers validate-plan (plan-validated refuses) again after its answer: stopped at that gate'
  journey_restore
  if (journey_po_run() { :; } && journey_run); then fail "the journey landed without po-run"; fi
  stops_at 's01-greeting: po next answers execute (verif-current refuses) again after its answer: stopped at that gate'
  journey_restore
  if (journey_record_review() { :; } && journey_run); then fail "the journey landed without po record review"; fi
  stops_at 's01-greeting: po next answers review (no review) again after its answer: stopped at that gate'
}

test_journey_runs_in_the_suite() {
  need_journey
  export GH_TOKEN=s199-not-a-token GITHUB_TOKEN=s199-not-a-token
  journey_init
  [ -z "${GH_TOKEN+set}" ] && [ -z "${GITHUB_TOKEN+set}" ] || fail "a forge token reaches the journey"
  local tool out
  for tool in gh curl glab tea task claude cargo; do
    [ "$(command -v "$tool")" = "$J/bin/$tool" ] || fail "$tool does not resolve to the journey's double: $(command -v "$tool")"
  done
  [ "$PO_GH" = "$J/bin/gh" ] && [ "$PO_CURL" = "$J/bin/curl" ] && [ "$PO_GLAB" = "$J/bin/glab" ] && [ "$PO_TEA" = "$J/bin/tea" ] \
    || fail "po is not pointed at the forge doubles"
  # No network: git refuses any transport but a local one, before it connects anywhere.
  if out="$(git ls-remote https://127.0.0.1:9/s199.git 2>&1)"; then fail "git reached an https remote"; fi
  grep -qF "transport 'https' not allowed" <<< "$out" || fail "git was not stopped by its protocol rule: $out"
  # The remote of a pr project is a local bare repository inside the journey's folder.
  journey_project pr
  [ "$(git -C "$R" config remote.origin.url)" = https://github.com/acme/project.git ] || fail "origin is not named as a github.com repository"
  [ "$(git -C "$R" ls-remote --get-url origin)" = "$ORIGIN" ] || fail "origin does not lead to the local bare repository"
  case "$ORIGIN" in "$J"/*) ;; *) fail "the bare repository lies outside the journey's folder: $ORIGIN" ;; esac
  [ "$(git -C "$ORIGIN" rev-parse --is-bare-repository)" = true ] || fail "origin is not a bare repository"
  # A call the journey expects passes the audit; any other call fails it, and is named.
  gh pr list --repo github.com/acme/project --head story/s01-greeting --state all --json number >/dev/null \
    || fail "the gh double refused a call the journey makes"
  journey_audit >/dev/null || fail "expected calls failed the audit: $(journey_audit)"
  gh repo delete acme/project --yes >/dev/null 2>&1 || true
  claude -p hello >/dev/null 2>&1 || true
  if out="$(journey_audit)"; then fail "unexpected calls passed the audit"; fi
  grep -qF 'unexpected call to gh: repo delete acme/project --yes' <<< "$out" || fail "the audit does not name the gh call: $out"
  grep -qF 'unexpected call to claude: -p hello' <<< "$out" || fail "the audit does not name the model call: $out"
}
