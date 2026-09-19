#!/usr/bin/env bash
# s13 — brief command, interrogation skill and template.

BRIEF="$METHOD/commands/po-brief.md"
SKILL="$METHOD/skills/interrogation/SKILL.md"
BRIEF_TEMPLATE="$METHOD/templates/brief.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_brief_runs_only_in_new_mode() {
  require_file "$BRIEF"
  settings_read_by "$BRIEF" | grep -qx 'Entry mode' || fail "po-brief.md does not read \`Entry mode\`"
  contains "$BRIEF" '`replace` or `adapt` → stop: "This project starts from an existing SaaS, not from an idea: run /po-prd <target SaaS> instead."'
  contains "$BRIEF" '`—` → stop'
}

test_interrogation_skill_has_stance_forcing_questions_gap_map_premortem() {
  local section name
  require_file "$SKILL"
  contains "$SKILL" 'skeptical cofounder'

  section=$(section_of "$SKILL" 'Forcing questions')
  [ "$(grep -cE '^[0-9]+\. \*\*' <<< "$section")" -eq 7 ] || fail "forcing questions are not exactly seven numbered items"
  for name in 'Evidence of pain' 'Status quo' 'Exact consumer' 'Narrowest wedge' 'Success signal' 'Why now' 'Future-fit'; do
    grep -qF -- "**$name**" <<< "$section" || fail "forcing questions lack **$name**"
  done

  section=$(section_of "$SKILL" 'Gap map')
  for name in 'Problem & evidence' 'Consumer & job' 'Wedge & non-goals' 'Success metrics' 'Incumbents & alternatives' \
              'Domain model' 'Interface contract' 'Security & abuse' 'Evaluation'; do
    grep -F -- '★' <<< "$section" | grep -qF -- "$name" || fail "gap map does not mark $name as critical (★)"
  done
  grep -qF -- 'A critical dimension (★) never stays unmarked.' <<< "$section" || fail "gap map lets critical dimensions stay unmarked"

  grep -qF -- 'fresh context' <<< "$(section_of "$SKILL" 'Pre-mortem')" || fail "pre-mortem is not run in a fresh context"

  section=$(section_of "$SKILL" 'Alternatives')
  grep -qF -- 'at least three approaches' <<< "$section" || fail "alternatives do not ask for at least three approaches"
  grep -qF -- 'the cheapest' <<< "$section" || fail "alternatives do not include the cheapest"
}

test_brief_persists_between_sessions() {
  require_file "$BRIEF_TEMPLATE"
  contains "$BRIEF" 'After each theme, write what it settled into docs/brief.md and keep status: interviewing.'
  contains "$BRIEF" 'continue at the first theme not yet settled'
  frontmatter "$BRIEF_TEMPLATE" | grep -qx 'status: interviewing' || fail "brief template does not start with status: interviewing"
}

test_brief_has_exit_criteria() {
  local section item
  section=$(section_of "$BRIEF" 'Exit criteria')
  grep -qF -- 'status: approved is written only when all of these hold:' <<< "$section" || fail "po-brief.md does not gate status: approved"
  for item in 'one-liner' 'wedge' 'success metric' 'three non-goals' 'critical dimension' 'pre-mortem finding' 'agreement'; do
    grep -qF -- "$item" <<< "$section" || fail "exit criteria lack: $item"
  done
}
