#!/usr/bin/env bash
# s102 — the ship follows the forge's review rule; a solo person's choice stays put.

SHIP="$METHOD/commands/po-ship.md"
SETUP="$METHOD/commands/po-setup.md"
DRIVE="$METHOD/commands/po-drive.md"
RULES="$METHOD/AGENTS.md"
TEMPLATE="$METHOD/templates/agents-local.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

forge_section() { section_of "$SHIP" "The forge's review rule"; }

test_setup_reads_review_rules_from_the_forge() {
  require_file "$SETUP"
  local step1 step2 forge
  step1=$(awk '/^## Step 1/ {on=1; next} /^## / {on=0} on' "$SETUP")
  step2=$(awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$SETUP")
  holds "$step1" "## The forge's review rule" 'Step 1 of po-setup.md'
  grep -F 'AskUserQuestion call for `Ship confirmation`' <<< "$step2" | grep -qvE '^[0-9]+\. ' \
    || fail "po-setup.md Step 2 has no unnumbered Ship confirmation follow-up"
  holds "$step2" '`automatic (chosen)` (suggested) and `human (chosen)`' 'Step 2 of po-setup.md'
  ! grep -qF 'Propose the same value for' "$SETUP" || fail "po-setup.md still copies Plan validation onto Ship confirmation"

  forge=$(forge_section)
  [ -n "$forge" ] || fail "po-ship.md has no '## The forge's review rule' section"
  local s
  for s in 'host `github.com` → GitHub' 'a host containing `gitlab` → GitLab' '/api/v1/version' \
           '`gh api`' '`glab api`' '`tea api`' 'No CLI and no token → the forge is unreadable'; do
    holds "$forge" "$s" 'the forge section'
  done
}

test_collaborative_repo_forbids_agent_merge() {
  local forge; forge=$(forge_section)
  holds "$forge" 'permissions.push' 'the forge section'
  holds "$forge" '*A `CODEOWNERS` naming someone else*' 'the forge section'
  holds "$forge" 'required_approving_review_count' 'the forge section'
  holds "$forge" '`human` on a collaborative repository, whatever the line says, a `(chosen)` line included' 'the forge section'
  holds "$forge" 'a value reading `(forge)` on a solo repository is `automatic`' 'the forge section'
  holds "$forge" '"Upgrade to GitHub Pro"' 'the forge section'
  holds "$forge" 'all count as "no protection"' 'the forge section'
}

test_setting_records_its_origin() {
  local reading row
  reading=$(section_of "$RULES" 'Reading settings')
  holds "$reading" '`human (forge)` reads `human` wherever a command compares the value' 'Reading settings'
  holds "$reading" 'A value with no suffix reads as `(forge)`' 'Reading settings'
  row=$(grep -F '| Ship confirmation |' "$TEMPLATE")
  holds "$row" '`(forge)`' 'the Ship confirmation row of the template'
  holds "$row" '`(chosen)`' 'the Ship confirmation row of the template'
}

test_template_defaults_trust_the_gates() {
  local fenced
  fenced=$(awk '/^```/ {fence=!fence; next} fence' "$TEMPLATE")
  grep -qE '^Plan validation:[[:space:]]+autonomous$' <<< "$fenced" || fail "the template does not default Plan validation to autonomous"
  grep -qE '^Ship confirmation:[[:space:]]+automatic$' <<< "$fenced" || fail "the template does not default Ship confirmation to automatic"
}

test_forge_tightening_switches_to_human() {
  local forge; forge=$(forge_section)
  holds "$forge" 'collaborative and not `human` → `human (forge)`' 'the forge section'
  holds "$forge" 'framing/ship-confirmation' 'the forge section'
  holds "$forge" 'gh pr create --draft' 'the forge section'
  holds "$forge" '"chore: Ship confirmation follows the forge"' 'the forge section'
  holds "$forge" 'solo and `human` → back to `automatic (forge)`' 'the forge section'
  holds "$forge" 'The ship does not wait for that draft' 'the forge section'
  holds "$forge" 'the line'"'"'s value stands, and the report names the call that failed' 'the forge section'
  local step0 forge_at step1
  step0=$(grep -n '^## Step 0' "$SHIP" | cut -d: -f1)
  forge_at=$(grep -n "^## The forge's review rule" "$SHIP" | cut -d: -f1)
  step1=$(grep -n '^## Step 1' "$SHIP" | cut -d: -f1)
  [ -n "$step0" ] && [ -n "$forge_at" ] && [ -n "$step1" ] && [ "$step0" -lt "$forge_at" ] && [ "$forge_at" -lt "$step1" ] \
    || fail "the forge section must sit between Step 0 and Step 1 of po-ship.md"
}

test_chosen_value_never_moves() {
  local forge reading
  forge=$(forge_section)
  holds "$forge" 'A `(chosen)` value is never rewritten by an agent' 'the forge section'
  holds "$forge" 'Only a line reading `(forge)`' 'the forge section'
  reading=$(section_of "$RULES" 'Reading settings')
  holds "$reading" '`/po-ship` rewrites a `Ship confirmation` value that reads `(forge)`' 'Reading settings'
  holds "$reading" 'A `(chosen)` value is never rewritten by an agent' 'Reading settings'
}

test_pr_wait_does_not_block_the_fleet() {
  local rows stale wait ship
  rows=$(section_of "$DRIVE" 'Resuming' | grep '^| ')
  stale=$(grep -n -F 'Reviewed tree:' <<< "$rows" | grep -F 'the review stage' | head -n 1 | cut -d: -f1)
  wait=$(grep -n -F 'printing `OPEN`' <<< "$rows" | grep -F 'a human merge — the lane waits' | head -n 1 | cut -d: -f1)
  ship=$(grep -n -F 'is `yes` | the ship' <<< "$rows" | cut -d: -f1)
  [ -n "$wait" ] || fail "the resuming table has no row for a pull request waiting for a human merge"
  [ -n "$stale" ] && [ -n "$ship" ] && [ "$stale" -lt "$wait" ] && [ "$wait" -lt "$ship" ] \
    || fail "the waiting row must sit between the stale-review row and the ship row"
  grep -n -F 'printing `CLOSED`' <<< "$rows" | grep -qF '| a human' || fail "a closed pull request does not go to a human"

  holds "$(section_of "$DRIVE" 'The ready set')" 'takes no `Parallel` slot' 'the ready set'
  holds "$(section_of "$DRIVE" 'Ships, one at a time')" 'is not the landing' 'the ship section'
  holds "$(section_of "$RULES" 'Law 1 — Nothing reaches the code except through a story')" \
    'opening the pull request is not the landing' 'Law 1'
  holds "$(section_of "$DRIVE" 'Report')" 'a pull request waiting for a human merge, with its URL' 'the status reasons'
}

test_ship_gate_unchanged() {
  local gate forge_at step1
  gate=$(grep -n -F 'po-gate ship-allowed <id>' "$SHIP" | head -n 1 | cut -d: -f1)
  forge_at=$(grep -n "^## The forge's review rule" "$SHIP" | cut -d: -f1)
  step1=$(grep -n '^## Step 1' "$SHIP" | cut -d: -f1)
  [ -n "$gate" ] && [ -n "$forge_at" ] && [ -n "$step1" ] && [ "$gate" -lt "$forge_at" ] && [ "$gate" -lt "$step1" ] \
    || fail "po-gate ship-allowed must come before the forge section and Step 1"
  holds "$(forge_section)" 'It never opens, skips or replaces `po-gate ship-allowed <id>`' 'the forge section'
  contains "$SHIP" '`po-gate ship-allowed <id>` is required before any merge, whatever the value'
  holds "$(section_of "$DRIVE" 'Ships, one at a time')" '`po-gate ship-allowed <id>` is required before any merge, whatever the value' 'the ship section'
  holds "$(section_of "$RULES" 'Merging')" '`po-gate ship-allowed` is required before any merge, whatever the value' 'Merging'
}
