#!/usr/bin/env bash
# s190 — a ready story whose track cannot be read gets an `ask` entry and stays in `ready`, the driver
# ending its wave on the entries; `po state` gives the same `ready` as `po next`.

test_ready_story_that_asks_stays_ready() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/next-names-the-track.oracle.test.sh"
    in_fixture
    card fr s01-alpha 2 —
    card fr s02-bravo - —
    start

    local value ready
    for value in auto -; do
      track_settings "$value" 2
      run_next "Story track $value"
      if [ "$value" = auto ]; then
        want s01-alpha plan ready flow
        want s02-bravo ask 'no complexity' null
      else
        want s01-alpha ask 'setting unreadable: Story track' null
        want s02-bravo ask 'setting unreadable: Story track' null
      fi
      jq -e '.ready == ["s01-alpha", "s02-bravo"]' <<< "$OUT" >/dev/null \
        || BAD+="ready is not both stories: $(jq -c .ready <<< "$OUT"); "
      verdict "a ready story that asks, Story track '$value'"

      ready="$(jq -c .ready <<< "$OUT")"
      po_in "$F" state
      [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
      [ "$(jq -c .ready <<< "$OUT")" = "$ready" ] \
        || fail "po state's ready $(jq -c .ready <<< "$OUT") is not po next's $ready"
    done
  ) || exit 1
}
