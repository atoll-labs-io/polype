#!/usr/bin/env bash
# s183 — the oracle of the story: a lane whose dependency has not shipped waits, takes no Parallel
# slot and holds no Owns, then resumes once it ships (#306); po's version goes up. The routing states
# are the fixtures case_ready_set_16 to 19 of tests/fixtures/driver-cases/ready-set.cases.

# replay <case> [then]: builds the case's project with the helpers of the driver oracle, checks its
# expectations against `po next`, then runs the shell code <then> in the same project.
replay() {
  local name="$1" then="${2:-:}"
  # Sourced inside a subshell, so this file does not take on the driver oracle's test_ functions.
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/driver-next-action.oracle.test.sh"
    project
    : > "$SCRATCH/expect"
    # shellcheck source=/dev/null
    source "$CASES/ready-set.cases"
    declare -F "$name" >/dev/null || fail "$name is not a case of ready-set.cases"
    "$name"
    po_in "$F" next
    next_shape "$name"
    check_expectations
    [ -z "$BAD" ] || fail "$name: $BAD"
    eval "$then"
  ) || exit 1
}

test_lane_waits_on_an_unshipped_dependency() {
  replay case_ready_set_16_lane_waits_on_an_unshipped_dependency '
    po_in "$W" state
    [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
    jq -e "[.lanes[] | select(.story == \"s02-bravo\") | .next]
      == [{\"action\": \"wait\", \"reason\": \"dependency s01-alpha\"}]" <<< "$OUT" >/dev/null \
      || fail "po state does not give the lane the action po next gives: $(jq -c .lanes <<< "$OUT")"'
}

test_waiting_lane_takes_no_slot() {
  replay case_ready_set_17_waiting_lane_takes_no_slot
}

test_waiting_lane_holds_nothing() {
  replay case_ready_set_18_waiting_lane_holds_nothing
}

test_lane_resumes_once_shipped() {
  replay case_ready_set_19_lane_resumes_once_shipped
}

# The three places that carry po's version agree, and it is above the 0.3.1 that s182 left.
test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.3.1 ] && [ "$(printf '0.3.1\n%s\n' "$toml" | sort -V | tail -n 1)" = "$toml" ] \
    || fail "po's version $toml is not above 0.3.1"
}
