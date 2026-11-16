#!/usr/bin/env bash
# s185 — `po next --remote` when the forge cannot be read: the action is the one computed without
# the option, and a project whose origin is not on github.com asks no forge at all.

test_unreadable_forge_changes_nothing() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/driver-next-action.oracle.test.sh"
    project
    setting 'Merge mode' pr
    setting 'Ship confirmation' human
    story s01-alpha command - 'src/a/'
    story s02-bravo command - 'src/b/'
    start
    git -C "$F" remote add origin https://github.com/acme/app.git
    recorded_lane s01-alpha
    review_in s01-alpha complete 0 yes
    pushed s01-alpha
    recorded_lane s02-bravo
    review_in s02-bravo complete 0 yes

    local calls="$SCRATCH/gh-calls" gh="$SCRATCH/gh"
    : > "$calls"
    cat > "$gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$calls"
exit 1
EOF
    chmod +x "$gh"
    export PO_GH="$gh"

    po_in "$F" next --remote
    next_shape "po next --remote, forge failing"
    : > "$SCRATCH/expect"
    expect_lane s01-alpha wait "merge waiting"
    expect_lane s02-bravo ship "ship-allowed passes"
    check_expectations
    [ -z "$BAD" ] || fail "a forge that cannot be read changed the actions: $BAD"
    [ -s "$calls" ] || fail "the failing forge was never asked, so this test proves nothing"

    : > "$calls"
    git -C "$F" remote set-url origin https://gitlab.com/acme/app.git
    po_in "$F" next --remote
    next_shape "po next --remote, gitlab origin"
    : > "$SCRATCH/expect"
    expect_lane s01-alpha wait "merge waiting"
    check_expectations
    [ -z "$BAD" ] || fail "a gitlab.com origin changed the actions: $BAD"
    [ ! -s "$calls" ] || fail "po next --remote asked gh for a gitlab.com origin: $(cat "$calls")"
  ) || exit 1
}

# A two-block review recorded onto itself at 11:00 keeps its 08:00 block, stamp included, after the
# new stamp, as po record review writes it: the ship is ordered by 11:00, so s02 at 10:00 goes first.
test_rerecorded_review_ships_by_its_newest_date() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/driver-next-action.oracle.test.sh"
    project
    story s01-alpha command - 'src/a/'
    story s02-bravo command - 'src/b/'
    start
    recorded_lane s01-alpha
    review_in s01-alpha complete 1 yes
    recorded_lane s02-bravo
    review_in s02-bravo complete 0 yes

    local file="$F/.worktrees/s01-alpha/docs/reviews/s01-alpha.md" body
    body="$(cat "$file")"
    printf 'Method version: 0\nRecorded: %s\n\n%s\n' 2026-11-13T07:00:00+00:00 "$body" \
      2026-11-13T08:00:00+00:00 "$body" 2026-11-13T11:00:00+00:00 "$body" > "$file"
    printf '\nMethod version: 0\nRecorded: 2026-11-13T08:00:00+00:00\n\n%s\n' "$body" >> "$file"
    printf 'Method version: 0\nRecorded: 2026-11-13T10:00:00+00:00\n\n%s\n' \
      "$(cat "$F/.worktrees/s02-bravo/docs/reviews/s02-bravo.md")" > "$F/.worktrees/s02-bravo/docs/reviews/s02-bravo.md"

    : > "$SCRATCH/expect"
    expect_lane s01-alpha wait "ships serial: s02-bravo"
    expect_lane s02-bravo ship "ship-allowed passes"
    po_in "$F" next
    next_shape "po next, a review recorded onto itself"
    check_expectations
    [ -z "$BAD" ] || fail "the ship is ordered by a stamp copied from an older block: $BAD"
  ) || exit 1
}
