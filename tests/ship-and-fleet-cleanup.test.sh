#!/usr/bin/env bash
# s125 — the ship and the fleet say what they do, and their tests bite.

SHIP="$METHOD/commands/po-ship.md"
DRIVE="$METHOD/commands/po-drive.md"
RULES="$METHOD/AGENTS.md"
STATUS="$METHOD/commands/po-status.md"
MUTANTS="$(mktemp -d)"
trap 'rm -rf "$MUTANTS"' EXIT

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "${3:-text} lacks: $2"; }

mutant() {
  local dir
  dir="$(mktemp -d "$MUTANTS/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  echo "$dir/method"
}

run_against() {
  ( METHOD="$1"; CMDS="$1/commands"; source "$2"; "$3" ) >/dev/null 2>&1
}

test_ship_text_is_complete() {
  local step2 lines
  step2="$(awk '/^## Step 2/ {on=1} /^## Step 3/ {on=0} on' "$SHIP")"
  holds "$step2" 'When `origin/story/<id>` does not exist yet' 'po-ship Step 2'
  holds "$step2" 'the push creates it' 'po-ship Step 2'
  grep -F 'Skip the push' "$SHIP" | grep -qF '`<id>: <story title>` as its message' \
    || fail "the skip condition does not check the commit message"
  holds "$step2" 'Below, `Ship confirmation` is always the effective value that section settled.' 'po-ship Step 2'
  lines="$(grep -E '^- (`Ship confirmation: human`|`automatic`)' <<< "$step2")"
  [[ $(wc -l <<< "$lines") -ge 3 ]] || fail "fewer than three confirmation bullets in Step 2"
  ! grep -vF ', the effective value' <<< "$lines" | grep -q . || fail "a confirmation bullet lacks 'the effective value'"
  grep -qx 'test_push_targets_only_the_story_ref() {' "$ROOT/tests/ship-through-pr.test.sh" \
    || fail "ship-through-pr.test.sh lacks test_push_targets_only_the_story_ref"
}

test_fleet_rules_agree() {
  local whole='`Root cause: not found` as a whole line (`grep -x`'
  holds "$(section_of "$DRIVE" 'Resuming' | grep -F 'Root cause: not found')" "$whole" 'po-drive resuming row'
  holds "$(section_of "$DRIVE" 'A wave' | grep '^1\. `subagent_type: planner`')" "$whole" 'po-drive planner step'

  local shared='The order the reviews passed decides which ship starts first, not which story lands first.'
  holds "$(section_of "$RULES" 'Law 1 — Nothing reaches the code except through a story')" "$shared" 'AGENTS.md Law 1'
  holds "$(section_of "$DRIVE" 'Ships, one at a time')" "$shared" 'po-drive ships'
  holds "$(section_of "$DRIVE" 'Ships, one at a time')" 'Proving a ship means seeing it land' 'po-drive ships'
  ! grep -qF 'the next one lands after it, in the order the reviews passed' "$RULES" || fail "AGENTS.md keeps the old order clause"

  local step3 step4 step5
  step3="$(awk '/^3\. \*\*Per story/ {on=1} /^4\. \*\*Fleet/ {on=0} on' "$STATUS")"
  step4="$(awk '/^4\. \*\*Fleet/ {on=1} /^5\. \*\*Output/ {on=0} on' "$STATUS")"
  step5="$(awk '/^5\. \*\*Output/ {on=1} /^6\. \*\*Decisions/ {on=0} on' "$STATUS")"
  holds "$(grep -F -- '- plan:' <<< "$step3")" 'waiting for a technical choice' 'po-status plan bullet'
  holds "$(grep -F -- '- plan:' <<< "$step3")" 'Technical choice: waiting for a human' 'po-status plan bullet'
  holds "$step4" 'a plan waiting for a technical choice' 'po-status blocked stories'
  holds "$step5" 'a plan waiting for a technical choice' 'po-status Next chain'
  holds "$(grep -F -- '- research:' <<< "$step3")" 'Root cause: not found' 'po-status research bullet'
  holds "$(grep -F -- '- research:' <<< "$step3")" 'as a whole line (`grep -x`' 'po-status research bullet'
  holds "$step4" 'Root cause: not found' 'po-status blocked stories'
  holds "$step5" 'Root cause: not found' 'po-status Next chain'
}

# Applies a removal to a mutant file, checks the phrase is gone, the real tree passes and the mutant fails.
bites() {
  local file="$1" phrase="$2" t="$ROOT/tests/$3" name="$4" m
  run_against "$METHOD" "$t" "$name" || fail "$name fails on the real tree"
  m="$(mutant)"
  python3 -I - "$m/$file" "$phrase" <<'PY' || fail "mutation did not apply to $file"
import sys
p, a = sys.argv[1:]
s = open(p).read()
assert s.count(a) == 1
open(p, "w").write(s.replace(a, ""))
PY
  ! grep -qF -- "$phrase" "$m/$file" || fail "mutant keeps its phrase in $file"
  if run_against "$m" "$t" "$name"; then fail "$name still passes without the rule in $file"; fi
}

test_fleet_tests_bite() {
  bites commands/po-drive.md ' Meanwhile the other lanes carry on.' escalation-contract.test.sh test_human_stops_do_not_halt_the_fleet

  local m t="$ROOT/tests/short-subject-shipped.test.sh" name=test_short_subject_counts_as_shipped
  run_against "$METHOD" "$t" "$name" || fail "$name fails on the real tree"
  m="$(mutant)"
  python3 -I - "$m/hooks/po-session.sh" <<'PY' || fail "session mutation did not apply"
import sys
p = sys.argv[1]
s = open(p).read()
a = 'SHORT_SHIPPED["${id%:}"]=1'
assert s.count(a) == 1
open(p, "w").write(s.replace(a, ":"))
PY
  ! grep -qF 'SHORT_SHIPPED["${id%:}"]=1' "$m/hooks/po-session.sh" || fail "session mutant keeps its line"
  if run_against "$m" "$t" "$name"; then fail "$name still passes without the short-subject record"; fi

  t="$ROOT/tests/defect-and-routing-paths.test.sh"; name=test_no_root_cause_goes_to_a_human
  run_against "$METHOD" "$t" "$name" || fail "$name fails on the real tree"
  m="$(mutant)"
  python3 -I - "$m/commands/po-drive.md" <<'PY' || fail "dispatch mutation did not apply"
import sys
p = sys.argv[1]
s = open(p).read()
i = s.index(" A planner that answers with a research holding")
e = "no plan is approved or dispatched for it."
j = s.index(e, i) + len(e)
open(p, "w").write(s[:i] + s[j:])
PY
  ! grep -qF 'no plan is approved or dispatched for it' "$m/commands/po-drive.md" || fail "dispatch mutant keeps its stop"
  if run_against "$m" "$t" "$name"; then fail "$name still passes without the planner stop"; fi
}
