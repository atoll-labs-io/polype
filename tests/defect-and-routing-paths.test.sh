#!/usr/bin/env bash
# s96 — the diagnostic and the routing hold on every path.

SKILL="$METHOD/skills/diagnostic/SKILL.md"
RESEARCH="$METHOD/commands/po-research.md"
PLANNER="$METHOD/agents/planner.md"
DRIVE="$METHOD/commands/po-drive.md"
EXECUTE="$METHOD/commands/po-execute.md"
ADR68="$ROOT/docs/decisions/ADR-0068-une-story-de-defaut-porte-une-ligne-fixes-et-passe-par-le-diagnostic.md"
ADR70="$ROOT/docs/decisions/ADR-0070-une-recherche-sans-cause-racine-porte-une-ligne-et-va-a-un-humain.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_every_path_runs_the_diagnostic() {
  local f heading body
  for f in "$RESEARCH|The investigation"; do
    heading=${f#*|}
    body=$(section_of "${f%%|*}" "$heading")
    grep -qF '`diagnostic` skill' <<< "$body" || fail "$heading does not name the diagnostic skill"
    grep -qF '`Fixes`' <<< "$body" || fail "$heading does not name the Fixes line"
    grep -qF 'Corrige' <<< "$body" || fail "$heading does not name the Corrige line"
  done
}

test_no_root_cause_goes_to_a_human() {
  section_of "$SKILL" 'Three hypotheses, then stop' | grep -qF '`Root cause: not found`' \
    || fail "the skill does not fix the marker line"
  local defect
  defect=$(section_of "$PLANNER" 'The contracts you carry' | grep '^- \*\*Defect story\*\*')
  grep -qF 'Root cause: not found' <<< "$defect" || fail "the planner defect bullet lacks the marker"
  grep -qF 'write no plan' <<< "$defect" || fail "the planner defect bullet does not forbid the plan"

  frontmatter "$ADR70" | grep -qx 'supersedes: \[ADR-0068\]' || fail "ADR-0070 does not supersede ADR-0068"
  frontmatter "$ADR68" | grep -qx 'superseded-by: \[ADR-0070\]' || fail "ADR-0068 is not marked superseded by ADR-0070"
}

test_implementer_may_explore_a_throwaway_clone() {
  local prompt
  prompt=$(grep '^> Story <id>\. Worktree:' "$EXECUTE")
  [[ -n $prompt ]] || fail "implementer prompt not found"
  grep -qF 'never checkout or stash in the story worktree' <<< "$prompt" \
    || fail "the checkout ban is not scoped to the story worktree"
  ! grep -qF 'never checkout or stash.' <<< "$prompt" || fail "the prompt still forbids checkout everywhere"
}
