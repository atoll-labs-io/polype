#!/usr/bin/env bash
# s199 — the journey's own guards: what stops a run, the wave cap, and the one folder removed on a
# failure and on an interrupt.

source "$ROOT/tests/journey/journey.sh"

stops_with() {
  if journey_run; then fail "the journey went on: $(cat "$JOURNEY_LOG")"; fi
  grep -qF -- "$1" "$JOURNEY_LOG" || fail "the journey did not stop with: $1 — log: $(cat "$JOURNEY_LOG")"
}

test_canned_po_next_stops() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  # canned <json> [<exit>]: po next answers <json>, then exits <exit>; no project is ever built.
  canned() { CANNED="$1" CANNED_EXIT="${2:-0}"; }
  journey_po_next() { printf '%s\n' "$CANNED"; return "$CANNED_EXIT"; }
  journey_init
  journey_answers s01-greeting "$ROOT/tests/journey/answers/plain"
  canned '{"contract":1,"actions":[{"story":"s01-greeting","action":"ask","reason":"Max attempts reached"}],"ready":[],"held":[],"warnings":[]}'
  stops_with $'stopped\task for s01-greeting: Max attempts reached'
  canned '{"contract":1,"actions":[],"ready":[],"held":[],"warnings":[{"kind":"orphan-worktree","path":".worktrees/x"}]}'
  stops_with $'stopped\tpo next warns: [{"kind":"orphan-worktree"'
  canned '{"contract":1,"error":"not-a-project","message":"no project"}' 2
  stops_with $'stopped\tpo next failed: {"contract":1,"error":"not-a-project"'
  canned '{"contract":1,"actions":[{"story":"s01-greeting","action":"wait","reason":"dependency s00-base"}],"ready":[],"held":[],"warnings":[]}'
  stops_with $'stopped\tnothing moves'
  # The audit inside a run: a call made while the journey ran fails it, even with nothing left to do.
  canned '{"contract":1,"actions":[],"ready":[],"held":[],"warnings":[]}'
  journey_run || fail "a po next with no action and no unexpected call did not end the journey: $(cat "$JOURNEY_LOG")"
  journey_po_next() { gh repo view acme/project >/dev/null 2>&1 || true; printf '%s\n' "$CANNED"; }
  stops_with $'stopped\tunexpected call to gh: repo view acme/project'
  ! grep -q '^done' "$JOURNEY_LOG" || fail "the journey logged done despite the unexpected call"
  # No installer ran here, so a call to cargo is one the journey does not expect.
  cargo build --release >/dev/null 2>&1 || true
  grep -qF 'unexpected call to cargo: build --release' <<< "$(journey_audit)" \
    || fail "the audit does not name a call to cargo made outside the installer: $(journey_audit)"
}

test_wave_cap_stops_the_journey() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  journey_init
  journey_project local
  journey_story s01-greeting 'Une salutation'
  JOURNEY_MAX_WAVES=2 stops_with $'stopped\tmore than 2 waves'
  [ "$(grep -c '^entry' "$JOURNEY_LOG")" = 2 ] || fail "the journey did not run exactly two waves: $(cat "$JOURNEY_LOG")"
  ! git -C "$R" log --format=%s main | grep -q '^s01-greeting:' || fail "s01-greeting landed past the wave cap"
}

# child <folder> <po next body>: a journey in its own session, with TMPDIR at <folder>; it writes
# its pid (its process group) and its journey folder into <folder>.
child() {
  TMPDIR="$1" setsid -w bash -c '
    set -u
    source "$1/tests/lib.sh"; source "$1/tests/journey/journey.sh"
    echo $$ > "$2/pid"
    journey_init
    echo "$J" > "$2/journey"
    eval "journey_po_next() { $3; }"
    journey_run' child "$ROOT" "$1" "$2" > /dev/null 2>&1
}

test_folders_go_on_failure_and_interrupt() {
  local made status=0 pid i own
  own="$(cd "$(mktemp -d)" && pwd -P)"
  OWN="$own"; trap 'rm -rf "$OWN"' EXIT
  child "$own" "printf '%s\n' '{\"contract\":1,\"actions\":[{\"story\":\"s01-greeting\",\"action\":\"ask\",\"reason\":\"no complexity\"}],\"ready\":[],\"held\":[],\"warnings\":[]}'" \
    || status=$?
  [ "$status" -ne 0 ] || fail "a journey stopped on an ask exited 0"
  made="$(cat "$own/journey" 2>/dev/null)" || fail "the child journey never made its folder"
  case "$made" in "$own"/polype-journey.*) ;; *) fail "the journey folder is not made under TMPDIR: $made" ;; esac
  [ ! -e "$made" ] || fail "a journey stopped on an ask left its folder: $made"

  rm -f "$own/journey" "$own/pid"
  child "$own" ": > \"$own/started\"; sleep 30" &
  pid=$!
  for i in $(seq 50); do [ -e "$own/started" ] && break; sleep 0.1; done
  [ -e "$own/started" ] || { kill -KILL "$pid" 2>/dev/null; fail "the child journey never reached po next"; }
  made="$(cat "$own/journey")"
  [ -d "$made" ] || fail "the journey folder is missing while the journey runs: $made"
  kill -TERM -- "-$(cat "$own/pid")" || fail "cannot signal the child's process group"
  for i in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL -- "-$(cat "$own/pid")" 2>/dev/null
    fail "the journey did not exit within 5 s of a TERM"
  fi
  status=0; wait "$pid" || status=$?
  [ "$status" = 143 ] || fail "the interrupted journey exited $status, not 143"
  [ ! -e "$made" ] || fail "an interrupted journey left its folder: $made"
  [ -z "$(find "$own" -maxdepth 1 -name 'polype-journey.*')" ] || fail "a journey folder is left under $own"
}
