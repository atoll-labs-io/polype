#!/usr/bin/env bash
# s07 — ship.

CMD="$METHOD/commands/po-ship.md"

test_ship_gate_is_mechanical() {
  require_file "$CMD"
  local gate_line first_step
  gate_line=$(grep -n 'po-gate ship-allowed <id>' "$CMD" | head -n 1 | cut -d: -f1)
  first_step=$(grep -n '^## Step 1' "$CMD" | cut -d: -f1)
  [ -n "$gate_line" ] && [ -n "$first_step" ] && [ "$gate_line" -lt "$first_step" ] \
    || fail "the ship-allowed gate must come before any other step"
  contains "$CMD" 'the **last** line starting with `Ship allowed:`'
}

test_ship_always_squashes_with_the_story_subject() {
  contains "$CMD" 'Merge, always as a squash'
  contains "$CMD" 'git merge --squash story/<id>'
  contains "$CMD" 'gh pr merge <url> --squash --subject "<id>: <story title>"'
  contains "$CMD" 'titled `<id>: <story title>`'
}

test_ship_cleans_up_only_on_proven_merge() {
  contains "$CMD" 'Cleanup, only after proof'
  contains "$CMD" 'prints exactly `MERGED`'
  contains "$CMD" '`--force` is not an option'
  contains "$CMD" "Do not test the story branch's own commits"
}

test_ship_can_ask_before_merging() {
  needs_tool "$CMD" AskUserQuestion
}

test_ship_runs_expensive_checks_once() {
  contains "$CMD" 'the single end-to-end run of the whole cycle'
  contains "$CMD" '**One failure and the ship stops**'
}

test_ship_goes_straight_to_cleanup_after_a_human_merge() {
  contains "$CMD" 'already prints `MERGED`, go straight to cleanup'
}

# s47 — the verdict is bound to the tree it judged.

test_rules_and_ship_describe_the_bound_verdict() {
  local row step0 status
  row=$(grep -F '| Ship allowed |' "$METHOD/AGENTS.md")
  grep -qF 'Reviewed tree:' <<< "$row" || fail "the Law 3 Ship allowed row does not mention 'Reviewed tree:'"
  step0=$(awk '/^## Step 0/ {on=1; next} /^## Step 1/ {on=0} on' "$CMD")
  grep -qF 'Reviewed tree:' <<< "$step0" || fail "po-ship.md Step 0 does not check 'Reviewed tree:'"
  grep -qF "':(exclude)docs'" <<< "$step0" || fail "po-ship.md Step 0 does not leave docs/ out of the comparison"
  status=$(grep -F -- '- review:' "$METHOD/commands/po-status.md")
  grep -qF 'Reviewed tree:' <<< "$status" || fail "the review bullet of po-status.md does not mention 'Reviewed tree:'"
}
