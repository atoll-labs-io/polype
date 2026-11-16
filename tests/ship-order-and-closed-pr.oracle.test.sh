#!/usr/bin/env bash
# s185 — the oracle of the story: `po record review` dates each block it writes, `po next` orders
# the ships by that date and falls back to the file's modification time without it (#278); with
# `--remote`, a lane whose pull request was closed without a merge goes to a person (#286, d-0009);
# po's version goes up. The ship states are the fixtures case_ships_05 and 06 of ships.cases.

# A `Recorded:` line as `po record review` writes it: a date, a time and its offset.
DATED='^Recorded: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$'

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
    source "$CASES/ships.cases"
    declare -F "$name" >/dev/null || fail "$name is not a case of ships.cases"
    "$name"
    po_in "$F" next
    next_shape "$name"
    check_expectations
    [ -z "$BAD" ] || fail "$name: $BAD"
    eval "$then"
  ) || exit 1
}

# again <lane> <action> <reason>...: `po next` once more, each triple expected of it.
again() {
  : > "$SCRATCH/expect"
  while [ $# -ge 3 ]; do expect_lane "$1" "$2" "$3"; shift 3; done
  po_in "$F" next
  next_shape "po next again"
  check_expectations
  [ -z "$BAD" ] || fail "$BAD"
}

# blocks <file>: exit 0 when every block opened by a `Method version:` line holds exactly one
# `Recorded:` line and no `Recorded:` line stands outside a block.
blocks() {
  awk '/^Method version:/ { if (open && n != 1) bad = 1; open = 1; n = 0; next }
       /^Recorded:/ { if (!open) bad = 1; n++ }
       END { if (!open || n != 1) bad = 1; exit bad }' "$1"
}

test_record_dates_each_verdict() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/record-writes-reports.oracle.test.sh"
    need_po; fixture
    local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md" again="$SCRATCH/again.txt"
    review_answer "$answer"
    rec "$W" "$answer" record review "$ID"
    [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
    [ "$(grep -c '^Recorded:' "$file")" -eq 1 ] || fail "the review holds $(grep -c '^Recorded:' "$file") Recorded lines, not 1"
    grep -qE "$DATED" "$file" || fail "the Recorded line is not a date with its offset: $(grep '^Recorded:' "$file")"

    review_answer "$answer" 1
    rec "$W" "$answer" record review "$ID"
    [ "$STATUS" -eq 0 ] || fail "po record review of the next loop exited $STATUS: $OUT"
    [ "$(grep -cE "$DATED" "$file")" -eq 2 ] || fail "two recorded blocks do not hold two dated lines: $(grep '^Recorded:' "$file")"
    blocks "$file" || fail "a block does not hold exactly one Recorded line: $(grep -nE '^(Method version|Recorded):' "$file")"

    # Re-recorded onto itself, the report gets one block more, each with its own single date.
    cp "$file" "$again"
    rec "$W" "$again" record review "$ID"
    [ "$STATUS" -eq 0 ] || fail "po record review on its own report exited $STATUS: $OUT"
    blocks "$file" || fail "re-recording the report doubled a Recorded line: $(grep -nE '^(Method version|Recorded):' "$file")"
  ) || exit 1
}

test_ships_follow_the_written_date() {
  # Touching the files the other way round, then copying one onto itself, leaves the order alone.
  replay case_ships_05_written_date_orders_the_ships '
    reviewed_at s01-alpha "@1794553200"
    reviewed_at s02-bravo "@1794571200"
    again s01-alpha ship "ship-allowed passes" s02-bravo wait "ships serial: s01-alpha"
    f="$F/.worktrees/s01-alpha/docs/reviews/s01-alpha.md"
    cp "$f" "$SCRATCH/copy.md" && cp "$SCRATCH/copy.md" "$f"
    again s01-alpha ship "ship-allowed passes" s02-bravo wait "ships serial: s01-alpha"'
}

test_older_reviews_fall_back() {
  # The undated review touched after the dated one was written now ships second.
  replay case_ships_06_undated_review_falls_back '
    reviewed_at s02-bravo "@1794567600"
    again s01-alpha ship "ship-allowed passes" s02-bravo wait "ships serial: s01-alpha"'
}

test_gates_read_the_block_as_before() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/record-writes-reports.oracle.test.sh"
    need_po; fixture
    local answer="$SCRATCH/review.txt" file="$W/docs/reviews/$ID.md" rc
    review_answer "$answer"
    rec "$W" "$answer" record review "$ID"
    [ "$STATUS" -eq 0 ] || fail "po record review exited $STATUS: $OUT"
    grep -qE "$DATED" "$file" || fail "the fixture is wrong: the review carries no dated line"
    for gate in ship-allowed findings-shape; do
      rc=0; (cd "$W" && bash .polype/hooks/po-gate.sh "$gate" "$ID" >/dev/null 2>&1) || rc=$?
      [ "$rc" -eq 0 ] || fail "po-gate $gate exits $rc on a review that carries the dated line"
    done

    # Landed with that review, the story's trust signals read the block as they did.
    mkdir -p "$F/docs/reviews"
    cp "$file" "$F/docs/reviews/$ID.md"
    git -C "$F" add -A && git -C "$F" commit -q -m "$ID: landed"
    STATUS=0
    OUT="$(cd "$F" && "$PO" state --all 2>/dev/null)" || STATUS=$?
    [ "$STATUS" -eq 0 ] || fail "po state --all exited $STATUS: $OUT"
    jq -e --arg id "$ID" '[.shipped[] | select(.story == $id) | .trust
        | {method_version, fix_loops, max_severity, not_verified, oracle}]
      == [{"method_version": "9.9.9-oracle", "fix_loops": 0, "max_severity": "minor",
           "not_verified": 0, "oracle": "intact"}]' <<< "$OUT" >/dev/null \
      || fail "the trust signals changed on a dated review: $(jq -c '.shipped' <<< "$OUT")"
  ) || exit 1
}

test_closed_pr_goes_to_a_human() {
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
    reviewed_at s01-alpha '@1794553200'
    reviewed_at s02-bravo '@1794560400'

    # A gh double: s01's pull request in the state $SCRATCH/s01-pr holds, none for any other branch.
    local calls="$SCRATCH/gh-calls" gh="$SCRATCH/gh"
    : > "$calls"
    cat > "$gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$calls"
case "\$*" in
  *s01-alpha*) cat "$SCRATCH/s01-pr" ;;
  *) echo '[]' ;;
esac
EOF
    chmod +x "$gh"
    echo '[{"number": 7, "state": "closed", "merged_at": null}]' > "$SCRATCH/s01-pr"
    export PO_GH="$gh"

    # Without the option, no forge is asked and the lanes read as they did.
    again s01-alpha wait "merge waiting" s02-bravo ship "ship-allowed passes"
    [ ! -s "$calls" ] || fail "po next asked the forge without --remote: $(cat "$calls")"

    po_in "$F" next --remote
    next_shape "po next --remote"
    : > "$SCRATCH/expect"
    expect_lane s01-alpha ask "pull request closed"
    expect_lane s02-bravo ship "ship-allowed passes"
    check_expectations
    [ -z "$BAD" ] || fail "a pull request closed without a merge does not go to a person: $BAD"
    grep -q 'github.com' "$calls" || fail "the forge was not asked on github.com: $(cat "$calls")"

    # An open pull request is still a merge waiting for a person.
    echo '[{"number": 7, "state": "open", "merged_at": null}]' > "$SCRATCH/s01-pr"
    po_in "$F" next --remote
    : > "$SCRATCH/expect"
    expect_lane s01-alpha wait "merge waiting"
    check_expectations
    [ -z "$BAD" ] || fail "an open pull request was read as closed: $BAD"

    # Under automatic, the closed lane passed first, yet the next lane ships instead of waiting on it.
    echo '[{"number": 7, "state": "closed", "merged_at": null}]' > "$SCRATCH/s01-pr"
    setting 'Ship confirmation' automatic
    again s01-alpha ship "ship-allowed passes" s02-bravo wait "ships serial: s01-alpha"
    po_in "$F" next --remote
    : > "$SCRATCH/expect"
    expect_lane s01-alpha ask "pull request closed"
    expect_lane s02-bravo ship "ship-allowed passes"
    check_expectations
    [ -z "$BAD" ] || fail "under automatic, a closed pull request holds the ships or is not seen: $BAD"
  ) || exit 1
}

# The three places that carry po's version agree, a minor step above the 0.4.0 that s184 left.
test_version_goes_up() {
  local toml lock polype
  toml="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/po/Cargo.toml" | head -n 1)"
  lock="$(awk '$0 == "name = \"po\"" {getline; print; exit}' "$ROOT/po/Cargo.lock" | sed -n 's/^version = "\(.*\)"$/\1/p')"
  polype="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype")"
  [ -n "$toml" ] && [ "$toml" = "$lock" ] && [ "$toml" = "$polype" ] \
    || fail "po's version differs: po/Cargo.toml $toml, po/Cargo.lock $lock, bin/polype $polype"
  [ "$(printf '0.5.0\n%s\n' "$toml" | sort -V | head -n 1)" = 0.5.0 ] \
    || fail "po's version $toml is not a minor step above 0.4.0"
}
