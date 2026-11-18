#!/usr/bin/env bash
# s190 — the oracle of the story: every `plan` action of `po next` carries the story's track, a track
# that cannot be read asks, a story with a screen gets its design before its plan, the stories file is
# read in French as in English, and po's version goes up a minor step.

# in_fixture: the driver oracle's helpers and a fresh project with room for every story. Called inside
# a subshell, so this file does not take on the driver oracle's test_ functions.
in_fixture() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  project
  setting Parallel 9
}

# track_settings <Story track|-> <Flow threshold|->: both lines rewritten, `-` leaving one out.
track_settings() {
  sed -i '/^Story track:/d; /^Flow threshold:/d' "$F/AGENTS.local.md"
  [ "$1" = - ] || printf 'Story track: %s\n' "$1" >> "$F/AGENTS.local.md"
  [ "$2" = - ] || printf 'Flow threshold: %s\n' "$2" >> "$F/AGENTS.local.md"
}

# card <fr|en> <id> <complexity|-> <surface> [fix]: one story of docs/stories.md, in that language;
# `-` writes no complexity line, `fix` adds the line of a story that fixes a defect.
card() {
  local lang="$1" id="$2" complexity="$3" surface="$4" fix="${5:-}"
  {
    printf '### %s — %s\n' "$id" "$id"
    if [ "$lang" = fr ]; then
      [ "$complexity" = - ] || printf -- '- **Complexité** : %s\n' "$complexity"
      printf -- '- **Surface** : %s\n' "$surface"
      [ -z "$fix" ] || printf -- '- **Corrige** : #1 (le défaut)\n'
    else
      [ "$complexity" = - ] || printf -- '- **Complexity**: %s\n' "$complexity"
      printf -- '- **Surface**: %s\n' "$surface"
      [ -z "$fix" ] || printf -- '- **Fixes**: #1 (the defect)\n'
    fi
    printf '\n'
  } >> "$F/docs/stories.md"
}

# run_next <label>: `po next` from the project root, in the contract's shape; resets BAD.
run_next() {
  po_in "$F" next
  next_shape "$1"
  BAD=""
  jq -e 'all(.actions[]; (.action == "plan") == has("track"))' <<< "$OUT" >/dev/null \
    || BAD+="a plan action without a track, or another action with one; "
}

# want <id> <action> <reason> <track|null>: the story's single entry of `actions`.
want() {
  local got expected
  got="$(jq -c --arg id "$1" '[.actions[]? | select(.story == $id) | [.action, .reason, (.track // null)]]' <<< "$OUT")"
  expected="$(jq -cn --arg a "$2" --arg r "$3" --arg t "$4" '[[$a, $r, (if $t == "null" then null else $t end)]]')"
  [ "$got" = "$expected" ] || BAD+="$1: $got instead of $expected; "
}

verdict() { [ -z "$BAD" ] || fail "$1: $BAD"; }

test_plan_action_names_its_track() {
  ( in_fixture
    track_settings auto 2
    card fr s01-alpha 2 —
    card fr s02-bravo 3 —
    card fr s03-charlie 1 — fix
    card fr s04-delta 1 screen
    card fr s05-echo 1 command
    card fr s06-foxtrot 2 —
    card fr s07-golf 1 —
    start
    lane s06-foxtrot; research_in s06-foxtrot
    lane s07-golf; research_in s07-golf; plan_in s07-golf no

    setting 'QA stage' surfaces
    run_next "auto, threshold 2, QA stage surfaces"
    want s01-alpha plan ready flow
    want s02-bravo plan ready full
    want s03-charlie plan ready full
    want s04-delta plan ready full
    want s05-echo plan ready full
    want s06-foxtrot plan 'research, no plan' flow
    want s07-golf plan 'plan-validated refuses' flow
    verdict "Story track auto, Flow threshold 2, QA stage surfaces"

    po_in "$F" state
    [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
    jq -e '[.lanes[] | select(.story == "s06-foxtrot") | .next]
      == [{"action": "plan", "reason": "research, no plan", "track": "flow"}]' <<< "$OUT" >/dev/null \
      || fail "po state does not carry the track po next gives: $(jq -c .lanes <<< "$OUT")"

    setting 'QA stage' —
    run_next "auto, threshold 2, no QA"
    want s04-delta plan ready full
    want s05-echo plan ready flow
    verdict "Story track auto, QA stage —"

    track_settings full 2
    run_next "full"
    want s01-alpha plan ready full
    want s06-foxtrot plan 'research, no plan' full
    verdict "Story track full"

    track_settings flow 2
    run_next "flow"
    want s01-alpha plan ready flow
    want s02-bravo plan ready flow
    want s03-charlie plan ready full
    want s04-delta plan ready full
    verdict "Story track flow"
  ) || exit 1
}

test_unreadable_track_settings_ask() {
  ( in_fixture
    card fr s01-alpha 2 —
    card fr s02-bravo - —
    card fr s03-charlie 2 —
    start
    lane s03-charlie; research_in s03-charlie

    local value
    for value in - — sometimes; do
      track_settings "$value" 2
      run_next "Story track $value"
      want s01-alpha ask 'setting unreadable: Story track' null
      want s03-charlie ask 'setting unreadable: Story track' null
      verdict "Story track '$value'"
    done
    for value in - — two; do
      track_settings auto "$value"
      run_next "Flow threshold $value"
      want s01-alpha ask 'setting unreadable: Flow threshold' null
      want s03-charlie ask 'setting unreadable: Flow threshold' null
      verdict "Story track auto, Flow threshold '$value'"
    done

    track_settings auto 2
    run_next "auto, a story without complexity"
    want s01-alpha plan ready flow
    want s02-bravo ask 'no complexity' null
    want s03-charlie plan 'research, no plan' flow
    verdict "a story without complexity under auto"

    track_settings full -
    run_next "full, no threshold"
    want s02-bravo plan ready full
    verdict "Story track full needs neither a threshold nor a complexity"
  ) || exit 1
}

test_design_comes_before_plan() {
  ( in_fixture
    track_settings auto 2
    card fr s01-alpha 1 screen
    card fr s02-bravo 1 screen
    card fr s03-charlie 1 screen
    start
    lane s01-alpha; research_in s01-alpha
    lane s02-bravo
    lane s03-charlie; research_in s03-charlie; design_in s03-charlie

    run_next "screens"
    want s01-alpha design 'no design' null
    want s02-bravo plan 'no research' full
    want s03-charlie plan 'research, no plan' full
    verdict "a story with a screen, research on disk and no design"

    po_in "$F" state
    [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
    jq -e '[.lanes[] | select(.story == "s01-alpha") | [.stage, .next.action]] == [["design", "design"]]' \
      <<< "$OUT" >/dev/null || fail "the lane's stage and its next action disagree: $(jq -c .lanes <<< "$OUT")"

    W="$F/.worktrees/s01-alpha"
    design_in s01-alpha
    run_next "the design on disk"
    want s01-alpha plan 'research, no plan' full
    verdict "once the design is on disk"
  ) || exit 1
}

test_stories_file_reads_both_languages() {
  ( in_fixture
    track_settings auto 3
    local lang
    for lang in fr en; do
      printf '# Stories\n\n## M1 — Fixture\n\n' > "$F/docs/stories.md"
      card "$lang" s01-alpha 3 —
      card "$lang" s02-bravo 4 —
      card "$lang" s03-charlie 1 — fix
      card "$lang" s04-delta '2 — risk: the forge' —
      git -C "$F" add -A
      git -C "$F" commit -qm "stories in $lang"
      run_next "stories in $lang"
      want s01-alpha plan ready flow
      want s02-bravo plan ready full
      want s03-charlie plan ready full
      want s04-delta plan ready flow
      verdict "a stories file in $lang"
    done
  ) || exit 1
}

# The three places that carry po's version agree, at least one minor step above the 0.6.1 of s189.
test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$(printf '0.7.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.7.0 ] \
    || fail "po's version $toml is not a minor step above 0.6.1"
}
