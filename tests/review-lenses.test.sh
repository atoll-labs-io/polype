#!/usr/bin/env bash
# s53 — review lenses triggered by the diff.

SKILL="$METHOD/skills/review-lenses/SKILL.md"
AGENT="$METHOD/agents/reviewer.md"
ANTIHALLU="$METHOD/skills/review-antihallu/SKILL.md"
TPL="$METHOD/templates/review.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

row_of() { awk -v p="| $2 |" 'index($0, p) == 1' "$1"; }

test_lenses_are_triggered_by_the_diff() {
  require_file "$SKILL"
  local which; which=$(section_of "$SKILL" 'Which lenses run')
  holds "$which" 'git diff --name-only <Target branch>...story/<id>' 'Which lenses run'
  local lens
  for lens in Security Migration Dependencies Performance; do
    awk -v p="| $lens |" 'index($0, p) == 1 {found=1} END {exit !found}' <<< "$which" \
      || fail "Which lenses run has no row for $lens"
  done
  local runs; runs=$(grep -c '^Lenses run:' "$TPL")
  [ "$runs" -eq 1 ] || fail "review template needs exactly one 'Lenses run:' line, found $runs"
  local lenses_line verdict_line
  lenses_line=$(grep -n '^Lenses run:' "$TPL" | cut -d: -f1)
  verdict_line=$(grep -n '^Max severity:' "$TPL" | cut -d: -f1)
  [ "$lenses_line" -lt "$verdict_line" ] || fail "'Lenses run:' must come before 'Max severity:'"
}

test_security_lens_rates_a_missing_authz_check_critical() {
  local sec; sec=$(section_of "$SKILL" Security)
  local p
  for p in '**A missing authorization check is critical.**' authorization URL upload webhook \
    signature 'rate limit' 'shared store' 'error message' LLM; do
    holds "$sec" "$p" 'Security lens'
  done
}

test_migration_lens_rejects_in_place_renames() {
  local mig; mig=$(section_of "$SKILL" Migration)
  local p
  for p in '**Renaming or dropping a column in place is major.**' expand contract rollback; do
    holds "$mig" "$p" 'Migration lens'
  done
}

test_dependency_lens_triggers_on_a_lockfile() {
  local row; row=$(row_of "$SKILL" Dependencies)
  [ -n "$row" ] || fail "no '| Dependencies |' row"
  local p
  for p in package-lock.json pnpm-lock.yaml yarn.lock Cargo.lock go.sum; do
    holds "$row" "$p" 'Dependencies trigger row'
  done
  local dep; dep=$(section_of "$SKILL" Dependencies)
  for p in 'one dependency per change' changelog 'install scripts' 'reason in the plan'; do
    holds "$dep" "$p" 'Dependencies lens'
  done
}

test_performance_lens_never_invents_numbers() {
  local perf; perf=$(section_of "$SKILL" Performance)
  local p
  for p in 'N+1' unbounded pagination sequential '**potential impact**' 'Never put a number on it'; do
    holds "$perf" "$p" 'Performance lens'
  done
}

test_one_reviewer_one_verdict() {
  frontmatter "$AGENT" | grep -qx '  - review-lenses' || fail "reviewer must preload review-lenses"
  local f
  for f in "$METHOD"/agents/*.md; do
    [ "$f" = "$AGENT" ] && continue
    ! frontmatter "$f" | grep -qx '  - review-lenses' || fail "${f##*/} must not preload review-lenses"
  done
  lacks_tool "$AGENT" Write

  local grading; grading=$(section_of "$SKILL" Grading)
  holds "$grading" 'No scale of its own' 'Grading'
  holds "$grading" 'review-antihallu' 'Grading'
  ! grep -qE '^(Max severity|Ship allowed):' "$SKILL" || fail "review-lenses must not carry a verdict line"

  local n
  n=$(grep -c '^Max severity:' "$TPL"); [ "$n" -eq 1 ] || fail "template has $n 'Max severity:' lines"
  n=$(grep -c '^Ship allowed:' "$TPL"); [ "$n" -eq 1 ] || fail "template has $n 'Ship allowed:' lines"

  local step6 lenses severity
  step6=$(grep -n '^\*\*6\. ' "$ANTIHALLU" | head -n 1 | cut -d: -f1)
  lenses=$(grep -nxF '## After the six steps: the lenses' "$ANTIHALLU" | head -n 1 | cut -d: -f1)
  severity=$(grep -nxF '## Severity' "$ANTIHALLU" | head -n 1 | cut -d: -f1)
  [ -n "$lenses" ] || fail "review-antihallu has no '## After the six steps: the lenses' section"
  [ "$step6" -lt "$lenses" ] && [ "$lenses" -lt "$severity" ] \
    || fail "the lenses section must sit between step 6 and ## Severity"
  holds "$(section_of "$ANTIHALLU" 'After the six steps: the lenses')" 'review-lenses' 'the lenses section'
}

test_a_lens_opens_what_the_diff_calls() {
  holds "$(section_of "$SKILL" 'Which lenses run')" 'A lens judges only what the diff changes, and opens what that code calls to confirm a finding' 'the lens reach bullet'
  ! grep -qF 'never at the rest of the repository' "$SKILL" || fail "the old lens reach line is still there"
}
