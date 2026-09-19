#!/usr/bin/env bash
# s20 — framing and short track wired into rules, status, orchestrator and reviewer.

RULES="$METHOD/AGENTS.md"
ORCH="$METHOD/commands/po-orchestrator.md"
STATUS="$METHOD/commands/po-status.md"
AGENT="$METHOD/agents/reviewer.md"

# The body of one `## <heading>` section of a file, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

# Line number of the first line holding the phrase, empty when absent.
line_of() { grep -nF -- "$2" <<< "$1" | head -n 1 | cut -d: -f1; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

reads_setting() { settings_read_by "$1" | grep -qx "$2" || fail "${1##*/} does not read $2"; }

test_rules_list_framing_before_the_story_cycle() {
  require_file "$RULES"
  local law framing per_story cmd
  law=$(section_of "$RULES" 'Law 1 — Nothing reaches the code except through a story')
  local f p; f=$(line_of "$law" '### Framing'); p=$(line_of "$law" '### Per story')
  [ -n "$f" ] && [ -n "$p" ] && [ "$f" -lt "$p" ] || fail "Law 1 must show ### Framing before ### Per story"
  framing=$(sed -n "${f},${p}p" <<< "$law")
  per_story=$(sed -n "${p},\$p" <<< "$law")
  for cmd in /po-setup /po-prd /po-brief /po-stories /po-stories-review /po-architect /po-design-system; do
    holds "$framing" "\`$cmd\`" "framing table"
  done
  holds "$per_story" '`/po-design`' "per-story cycle"
  holds "$per_story" '`/po-flow`' "per-story cycle"
  local r d pl
  r=$(line_of "$per_story" '`/po-research`'); d=$(line_of "$per_story" '`/po-design`'); pl=$(line_of "$per_story" '`/po-plan`')
  [ -n "$r" ] && [ -n "$d" ] && [ -n "$pl" ] && [ "$r" -lt "$d" ] && [ "$d" -lt "$pl" ] \
    || fail "the design row must sit between research and plan"
}

test_status_reports_framing_and_track() {
  require_file "$STATUS"
  reads_setting "$STATUS" 'Entry mode'
  reads_setting "$STATUS" 'Story track'
  reads_setting "$STATUS" 'Flow threshold'
  contains "$STATUS" '`docs/prd.md`'
  contains "$STATUS" '`docs/brief.md`'
  contains "$STATUS" '`Stories ready:`'
  contains "$STATUS" '`docs/architecture.md`'
  contains "$STATUS" '`docs/design-system.md`'
  contains "$STATUS" '`track: flow`'
  contains "$STATUS" '`/po-flow <id>`'
}

test_orchestrator_picks_the_track_and_runs_design() {
  require_file "$ORCH"
  reads_setting "$ORCH" 'Story track'
  reads_setting "$ORCH" 'Flow threshold'
  local track; track=$(section_of "$ORCH" 'Stage 1 — Track')
  holds "$track" '`Story track`' "track stage"
  holds "$track" '`Flow threshold`' "track stage"
  holds "$track" 'is at most `Flow threshold`; above it, or with no complexity written, the full track' "track stage"
  holds "$track" '`/po-flow`' "track stage"
  local d p
  d=$(grep -n '^## Stage [0-9]* — Design$' "$ORCH" | head -n 1 | cut -d: -f1)
  p=$(grep -n '^## Stage [0-9]* — Plan — checkpoint$' "$ORCH" | head -n 1 | cut -d: -f1)
  [ -n "$d" ] && [ -n "$p" ] && [ "$d" -lt "$p" ] || fail "a design stage must come before the plan checkpoint"
  holds "$(section_of "$ORCH" "$(sed -n "${d}p" "$ORCH" | sed 's/^## //')")" '`/po-design`' "design stage"
}

test_orchestrator_stops_without_approved_scope() {
  require_file "$ORCH"
  reads_setting "$ORCH" 'Entry mode'
  local gate; gate=$(section_of "$ORCH" 'Stage 0 — Can this start?')
  holds "$gate" '`docs/prd.md` with `status: approved`' "framing check"
  holds "$gate" 'stop and point to `/po-prd`' "framing check"
  holds "$gate" '`docs/brief.md` with `status: approved`' "framing check"
  holds "$gate" 'stop and point to `/po-brief`' "framing check"
  holds "$gate" 'there is no scope to check' "framing check"
  holds "$gate" 'that verdict informs, it does not block' "framing check"
}

test_design_files_reach_the_implementer() {
  require_file "$RULES"; require_file "$ORCH"
  contains "$RULES" 'the design of a story with a screen (`docs/designs/<id>/`)'
  local exec; exec=$(section_of "$ORCH" 'Stage 5 — Execute')
  holds "$exec" 'docs/designs/<id>/ is expected uncommitted work' "execute stage"
  holds "$(section_of "$ORCH" 'Stage 4 — Plan — checkpoint')" 'When `docs/designs/<id>/design.md` exists, read it' "plan stage"
}

test_reviewer_checks_design_conformity_without_measuring() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - design-doctrine' || fail "reviewer must preload design-doctrine"
  local body; body=$(section_of "$AGENT" 'Design conformity')
  holds "$body" '**major**' "design conformity"
  holds "$body" '**critical**' "design conformity"
  holds "$body" 'visual coherence' "design conformity"
  holds "$body" 'measures nothing' "design conformity"
}
