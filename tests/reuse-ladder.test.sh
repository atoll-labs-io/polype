#!/usr/bin/env bash
# s113 — every plan says what its new code could have reused, and the review flags a rebuilt helper.

PLAN="$METHOD/templates/plan.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
PLANNER="$METHOD/agents/planner.md"
PO_PLAN="$METHOD/commands/po-plan.md"
PO_FLOW="$METHOD/commands/po-flow.md"
ANTIHALLU="$METHOD/skills/review-antihallu/SKILL.md"

FILLED='`## Reuse` section filled in'
ONE_LINE='one line when the plan writes no new code'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

line_of() { grep -nx -- "$2" "$1" | head -n1 | cut -d: -f1; }

test_plans_carry_a_reuse_section() {
  local f name section flat story reuse tasks pos last rung
  for f in "$PLAN" "$PLAN_FLOW"; do
    require_file "$f"
    name="${f#"$ROOT"/}"
    story="$(line_of "$f" '## Story')"
    reuse="$(line_of "$f" '## Reuse')"
    tasks="$(line_of "$f" '## Tasks')"
    [ -n "$reuse" ] || fail "$name has no ## Reuse heading"
    [ -n "$story" ] && [ -n "$tasks" ] || fail "$name lacks ## Story or ## Tasks"
    [ "$story" -lt "$reuse" ] && [ "$reuse" -lt "$tasks" ] || fail "$name: ## Reuse is not between ## Story and ## Tasks"
    section="$(section_of "$f" Reuse)"
    holds "$section" 'the first rung that holds' "$name ## Reuse"
    holds "$section" 'why each rung above it fails' "$name ## Reuse"
    holds "$section" 'no option, setting or abstraction the story does not ask for' "$name ## Reuse"
    flat="$(tr '\n' ' ' <<< "$section")"
    last=0
    for rung in 'already in this repository, cited by `path:line`' 'the standard library or the platform' 'a dependency already installed' '; new code'; do
      pos="$(awk -v s="$flat" -v r="$rung" 'BEGIN { print index(s, r) }')"
      [ "$pos" -gt "$last" ] || fail "$name ## Reuse: rung out of order or missing: $rung"
      last="$pos"
    done
  done
  [ "$(section_of "$PLAN" Reuse)" = "$(section_of "$PLAN_FLOW" Reuse)" ] || fail "the two templates' ## Reuse sections differ"
}

test_never_cut_list_is_explicit() {
  local f
  for f in "$PLAN" "$PLAN_FLOW"; do
    require_file "$f"
    holds "$(section_of "$f" Reuse)" 'never cuts validation at a trust boundary, security, or the error handling that keeps data from being lost' "${f#"$ROOT"/} ## Reuse"
  done
}

test_planner_requires_the_ladder() {
  local bullet section f
  require_file "$PLANNER"
  for bullet in '- **Plan** —' '- **Short track** —'; do
    holds "$(grep -F -- "$bullet" "$PLANNER" | grep -- "^- ")" "$FILLED, $ONE_LINE" "planner.md $bullet"
  done
  require_file "$PO_PLAN"
  section="$(section_of "$PO_PLAN" 'Writing the plan')"
  holds "$section" "$FILLED" 'po-plan.md ## Writing the plan'
  holds "$section" "$ONE_LINE" 'po-plan.md ## Writing the plan'
  require_file "$PO_FLOW"
  section="$(section_of "$PO_FLOW" 'The plan')"
  holds "$section" "$FILLED" 'po-flow.md ## The plan'
  holds "$section" "$ONE_LINE" 'po-flow.md ## The plan'
  for f in "$PLAN" "$PLAN_FLOW"; do
    contains "$f" 'says so in one line instead of leaving this section out'
  done
}

test_review_flags_rebuilt_helpers() {
  local step
  require_file "$ANTIHALLU"
  step="$(awk '/^\*\*4\. / {exit} /^\*\*3\. / {on=1} on' "$ANTIHALLU")"
  holds "$step" 'an existing helper you can cite by `path:line`, or the standard library, already provided is a **major** finding' 'review-antihallu step 3'
  holds "$step" "a gap between the plan's \`## Reuse\` section and the diff is judged as a gap against a task" 'review-antihallu step 3'
  [ "$(grep -cF -- '**major**' <<< "$step")" -eq 1 ] || fail 'review-antihallu step 3 must hold **major** on exactly one line'
}
