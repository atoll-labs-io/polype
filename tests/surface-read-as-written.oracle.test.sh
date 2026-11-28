#!/usr/bin/env bash
# s216 — the oracle of the story: `po` reads a `Surface` line as people write it, `—` in backticks
# included (#355), and a project with no screen is not asked for a design system (#348); po's
# version goes up (ADR-0122). Projects are built with the helpers of the driver oracle.

# in_driver_project <shell code>: runs the code in a subshell holding the driver oracle's helpers,
# after `project` built a fresh fixture at $F.
in_driver_project() {
  # Sourced inside a subshell, so this file does not take on the driver oracle's test_ functions.
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/driver-next-action.oracle.test.sh"
    project
    : > "$SCRATCH/expect"
    eval "$1"
  ) || exit 1
}

# track_is <id> <track>: the story's single action in OUT carries that track.
track_is() {
  jq -e --arg id "$1" --arg track "$2" '[.actions[] | select(.story == $id) | .track] == [$track]' \
    <<< "$OUT" >/dev/null || fail "$1 does not plan on the $2 track: $(jq -c '.actions' <<< "$OUT")"
}

test_backticked_dash_is_no_surface() {
  in_driver_project '
    setting Parallel 6
    setting "QA stage" surfaces
    story s01-alpha "\`—\`" -
    story s02-bravo "—" -
    story s03-charlie "\`—\`" -
    story s04-delta "\`—\`" -
    start
    recorded_lane s01-alpha
    recorded_lane s02-bravo
    lane s03-charlie
    research_in s03-charlie
    expect_lane s01-alpha review "no review"
    expect_lane s02-bravo review "no review"
    expect_lane s03-charlie plan "research, no plan"
    expect_ready s04-delta
    po_in "$F" next
    next_shape "QA stage surfaces"
    check_expectations
    [ -z "$BAD" ] || fail "QA stage surfaces: $BAD"
    track_is s03-charlie flow
    track_is s04-delta flow'

  in_driver_project '
    setting "QA stage" -
    story s01-alpha "\`—\`" -
    start
    recorded_lane s01-alpha
    expect_lane s01-alpha review "no review"
    po_in "$F" next
    next_shape "QA stage missing"
    check_expectations
    [ -z "$BAD" ] || fail "QA stage missing: $BAD"'
}

test_no_screen_needs_no_design_system() {
  in_driver_project '
    # design_system_is <state> <case>: what po state says of the design system, on committed stories.
    design_system_is() {
      git -C "$F" add -A && git -C "$F" commit -qm "$2"
      po_in "$F" state
      [ "$STATUS" -eq 0 ] || fail "$2: po state exited $STATUS: $OUT"
      local got
      got="$(jq -r ".framing.items[] | select(.item == \"design-system\") | .state" <<< "$OUT")"
      [ "$got" = "$1" ] || fail "$2: design-system is \"$got\" instead of \"$1\""
    }
    rm "$F/docs/design-system.md"
    sed -i "s|^Parallel:.*|&\nPlatform:          cli|" "$F/AGENTS.local.md"
    printf -- "### s01-alpha — s01-alpha\n- **Complexité** : 1\n\n" >> "$F/docs/stories.md"
    story s02-bravo command -
    design_system_is "not needed" "Platform cli, one story without a Surface line"
    sed -i "s|^Platform:.*|Platform:          web|" "$F/AGENTS.local.md"
    design_system_is missing "Platform web, one story without a Surface line"
    sed -i "s|^Platform:.*|Platform:          cli|" "$F/AGENTS.local.md"
    story s03-charlie screen -
    design_system_is missing "Platform cli, one story whose Surface says screen"'
}

# The three places that carry po's version agree, and it is above the 0.13.0 that s211 left.
test_version_raised() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$toml" != 0.13.0 ] && [ "$(printf '0.13.0\n%s\n' "$toml" | sort -V | tail -n 1)" = "$toml" ] \
    || fail "po's version $toml is not above 0.13.0"
}
