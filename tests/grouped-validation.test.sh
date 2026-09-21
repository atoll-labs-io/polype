#!/usr/bin/env bash
# s30 — the plans of a wave are approved in one question, and the report says who approved them.

DRIVE="$METHOD/commands/po-drive.md"
ADR17="$ROOT/docs/decisions/ADR-0017-validation-groupee.md"
ADR14="$ROOT/docs/decisions/ADR-0014-checkpoints-groupes.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_drive_groups_plan_approval_per_wave() {
  require_file "$DRIVE"
  local approval; approval=$(section_of "$DRIVE" "Validating a wave's plans")
  [ -n "$approval" ] || fail "po-drive.md has no '## Validating a wave'\''s plans' section"

  # One question for the wave, never one per story.
  holds "$approval" '**one AskUserQuestion**, never one per story' 'the approval section'
  holds "$approval" 'the story id, its tasks and its test strategy, and the path `docs/plans/<id>.md`' 'the approval section'

  # The three answers.
  holds "$approval" 'Approve every plan' 'the approval section'
  holds "$approval" 'Choose which ones' 'the approval section'
  holds "$approval" 'Stop the wave' 'the approval section'
  holds "$approval" 'no implementer is dispatched at all' 'the approval section'

  # Only the approved plans are validated, and only through Bash.
  holds "$approval" '`validated: yes` is written through Bash, into the frontmatter of the plans the answer approved and of no other' 'the approval section'
  holds "$approval" 'A plan left unapproved keeps `validated: no`' 'the approval section'
  holds "$approval" 'its lane waits for the next wave' 'the approval section'
  holds "$approval" 'the same `po-gate plan-validated <id>` as everywhere else' 'the approval section'
  holds "$approval" 'the plans stay on disk' 'the approval section'

  # The dispatch step defers to that section instead of settling the approval inline.
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  holds "$wave" "approved as \`## Validating a wave's plans\` settles it, before any implementer starts" 'the wave section'
}

test_drive_says_when_nobody_reviewed() {
  require_file "$DRIVE"
  local report; report=$(section_of "$DRIVE" 'Report')
  [ -n "$report" ] || fail "po-drive.md has no '## Report' section"

  holds "$report" 'the plans were approved without a human reading them and names the stories concerned' 'the report section'
  holds "$report" 'which plans the wave approved and which ones are still waiting' 'the report section'
}

test_adr_0017_records_the_remaining_scope_of_adr_0014() {
  require_file "$ADR17"
  require_file "$ADR14"

  # ADR-0017 is the live decision, and it supersedes ADR-0014.
  local fm17; fm17=$(frontmatter "$ADR17")
  grep -qx 'status: accepted' <<< "$fm17" || fail 'ADR-0017 must be accepted'
  grep -qx 'supersedes: \[ADR-0014\]' <<< "$fm17" || fail 'ADR-0017 must supersede ADR-0014'

  # What it keeps of ADR-0014, and what ADR-0015 already took away.
  contains "$ADR17" 'les plans d'\''une vague se valident en une seule `AskUserQuestion`'
  contains "$ADR17" 'Le ship reste story par story'
  contains "$ADR17" '(ADR-0015)'

  # ADR-0014 stops being a live decision, body untouched.
  local fm14; fm14=$(frontmatter "$ADR14")
  grep -qx 'status: superseded' <<< "$fm14" || fail 'ADR-0014 must be superseded'
  grep -qx 'superseded-by: \[ADR-0017\]' <<< "$fm14" || fail 'ADR-0014 must point at ADR-0017'
}
