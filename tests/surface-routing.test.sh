#!/usr/bin/env bash
# s80 — design and QA are routed by the story's Surface line and QA stage, defined once in AGENTS.md (ADR-0058).

RULES="$METHOD/AGENTS.md"
DRIVE="$METHOD/commands/po-drive.md"
ORCH="$METHOD/commands/po-orchestrator.md"
STATUS="$METHOD/commands/po-status.md"
FLOW="$METHOD/commands/po-flow.md"
HELP="$METHOD/commands/po-help.md"
SKILL="$METHOD/skills/review-antihallu/SKILL.md"
REVIEWER="$METHOD/agents/reviewer.md"
REVIEW_TEMPLATE="$METHOD/templates/review.md"
README="$ROOT/README.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

lacks() { ! grep -qF -- "$2" "$1" || fail "${1#"$ROOT"/} still says: $2"; }

test_design_follows_a_screen_surface() {
  require_file "$RULES"
  contains "$RULES" 'A story **has a screen** when its `Surface` line says `screen`, or when it has no `Surface` line and its text shows a screen'
  contains "$ORCH" 'A story with a screen (`AGENTS.md`, Law 1) also needs'
  local f
  for f in "$DRIVE" "$ORCH" "$STATUS" "$FLOW"; do lacks "$f" 'text shows a'; done
}

test_qa_follows_the_qa_stage() {
  contains "$RULES" 'when `QA stage` is `screens` and the story has a screen'
  contains "$RULES" 'when `QA stage` is `surfaces` and its `Surface` line says anything but `—`'
  contains "$RULES" 'a story with no `Surface` line goes only when it has a screen'
  local rows
  rows=$(section_of "$DRIVE" 'Resuming' | grep -cF '| record current, the story goes to QA,')
  [ "$rows" -eq 3 ] || fail "po-drive.md resuming table: expected 3 QA rows routed by 'goes to QA', found $rows"
  contains "$STATUS" 'for a story that goes to QA:'
  local f
  for f in "$DRIVE" "$ORCH" "$STATUS"; do
    lacks "$f" '`QA stage` is `screens`'
    lacks "$f" '`QA stage: screens`'
    lacks "$f" 'screen story'
  done
}

test_flow_escalates_a_surface_with_qa() {
  settings_read_by "$FLOW" | grep -qx 'QA stage' || fail "po-flow.md does not read QA stage"
  local signals; signals=$(section_of "$FLOW" 'Escalation signals')
  holds "$signals" 'A story that goes to QA (`AGENTS.md`, Law 1) escalates the same way' 'the escalation signals'
  holds "$signals" '`/po-flow` runs no QA' 'the escalation signals'
}

test_review_requires_qa_for_a_surface() {
  local step1; step1=$(awk '/^\*\*1\. / {on=1} /^\*\*2\. / {exit} on' "$SKILL")
  holds "$step1" 'For a story that goes to QA (`AGENTS.md`, Law 1)' 'step 1 of review-antihallu'
  holds "$step1" 'every item of the report'"'"'s `## Not seen`' 'step 1 of review-antihallu'
  lacks "$SKILL" 'For a story with a screen, when `QA stage` is `screens`'
  contains "$REVIEWER" 'when it goes to QA (`AGENTS.md`, Law 1), `docs/qa/<id>/report.md`'
  contains "$REVIEWER" 'judge the scene against the viewpoints its plan names under `## Scene viewpoints`'
  contains "$REVIEWER" 'never against `docs/design-system.md`'
  contains "$REVIEWER" 'Everything the QA report lists under `## Not seen` belongs there too, with its reason.'
}

test_plan_names_scene_viewpoints() {
  local t s tasks scene interdicts body
  for t in plan.md plan-flow.md; do
    s="$METHOD/templates/$t"
    require_file "$s"
    tasks=$(grep -nx '## Tasks' "$s" | cut -d: -f1)
    scene=$(grep -nx '## Scene viewpoints' "$s" | cut -d: -f1)
    interdicts=$(grep -nx '## Run interdicts' "$s" | cut -d: -f1)
    [ -n "$tasks" ] && [ -n "$scene" ] && [ -n "$interdicts" ] || fail "$t needs ## Tasks, ## Scene viewpoints and ## Run interdicts"
    [ "$tasks" -lt "$scene" ] && [ "$scene" -lt "$interdicts" ] || fail "$t: ## Scene viewpoints must sit between ## Tasks and ## Run interdicts"
    body=$(section_of "$s" 'Scene viewpoints')
    holds "$body" '`scene`' "$t scene viewpoints"
    holds "$body" 'framing' "$t scene viewpoints"
    holds "$body" 'scale' "$t scene viewpoints"
    holds "$body" 'light' "$t scene viewpoints"
  done
}

test_rules_speak_of_surfaces() {
  contains "$RULES" '| the review of a story that goes to QA |'
  lacks "$RULES" 'stories with a screen, when'
  contains "$REVIEW_TEMPLATE" '(a story that goes to QA'
  contains "$REVIEW_TEMPLATE" 'not required: the story does not go to QA'
  contains "$HELP" 'un agent vérifie sa surface avec le pilote qui lui va'
  lacks "$HELP" 'parcourt en navigateur les écrans touchés'
  contains "$README" 'la surface vérifiée avec son pilote'
  lacks "$README" 'story avec écran, `QA stage: screens`'
}
