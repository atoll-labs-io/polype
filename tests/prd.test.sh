#!/usr/bin/env bash
# s12 — kill PRD command and template.

PRD="$METHOD/commands/po-prd.md"
PRD_TEMPLATE="$METHOD/templates/prd.md"

# The body of the adapt section, heading excluded.
adapt_section() { awk '/^## Adapt mode/ {on=1; next} /^## / {on=0} on' "$PRD"; }

test_prd_reads_entry_mode_and_refuses_new() {
  require_file "$PRD"
  settings_read_by "$PRD" | grep -qx 'Entry mode' || fail "po-prd.md does not read \`Entry mode\`"
  contains "$PRD" '`new` → stop: "This project starts from an idea, not from an existing SaaS: run /po-brief instead."'
  contains "$PRD" '`—` → stop'
}

test_prd_asks_one_question_at_a_time() {
  contains "$PRD" 'One question per message.'
  contains "$PRD" 'Nothing enters `docs/prd.md` before the user validates it.'
}

test_prd_template_has_core_loop_graveyard_and_angle() {
  local heading
  require_file "$PRD_TEMPLATE"
  for heading in '## Target' '## Mode' '## Core loop' '## Graveyard' '## Angle' '## Success criteria'; do
    grep -qx -- "$heading" "$PRD_TEMPLATE" || fail "prd.md template lacks $heading"
  done
  contains "$PRD_TEMPLATE" '| Feature | Complexity (1–5) | Justification |'
  contains "$PRD_TEMPLATE" '| Feature | Why it is left out |'
  contains "$PRD_TEMPLATE" '| Criterion | Target | How it is measured |'
}

test_prd_challenges_the_angle_in_adapt_mode() {
  local section probe
  section=$(adapt_section)
  [ -n "$section" ] || fail "po-prd.md has no adapt section"
  for probe in '**Evidence of pain**' '**Exact consumer**' '**Success signal**'; do
    grep -qF -- "$probe" <<< "$section" || fail "adapt section lacks the probe $probe"
  done
}

test_prd_scores_heavy_features_toward_the_graveyard() {
  contains "$PRD" 'A feature scored 4 or 5 must justify its place in the core loop'
  contains "$PRD" 'No convincing answer → it goes to the graveyard.'
}
