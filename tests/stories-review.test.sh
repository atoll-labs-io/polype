#!/usr/bin/env bash
# s15 — stories review: command, subagent, skill and template.

COMMAND="$METHOD/commands/po-stories-review.md"
AGENT="$METHOD/agents/stories-reviewer.md"
SKILL="$METHOD/skills/stories-review/SKILL.md"
TEMPLATE="$METHOD/templates/stories-review.md"
RESEARCH="$METHOD/commands/po-research.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_stories_reviewer_is_read_only_without_shell() {
  require_file "$AGENT"
  needs_tool "$AGENT" Read
  lacks_tool "$AGENT" Write
  lacks_tool "$AGENT" Edit
  lacks_tool "$AGENT" Bash
  frontmatter "$AGENT" | grep -qx '  - stories-review' || fail "stories-reviewer does not preload stories-review"
}

test_stories_review_checks_coverage_first() {
  local first
  require_file "$SKILL"
  require_file "$TEMPLATE"
  first=$(section_of "$SKILL" 'Checks, in this order' | grep -m1 '^\*\*1\.')
  grep -qF 'Coverage' <<< "$first" || fail "the first check of stories-review is not coverage"
  contains "$SKILL" 'An item of the scope that no story covers is critical.'
  section_of "$TEMPLATE" 'Coverage' | grep -q '^| Scope item' || fail "the template has no coverage table"
}

test_stories_review_checks_owns_overlap() {
  require_file "$SKILL"
  contains "$SKILL" 'Two stories with no dependency between them that share an `Owns` path are flagged as critical: run side by side, they would edit the same files.'
  section_of "$TEMPLATE" 'Checks' | grep -qF 'Owns' || fail "the template checks do not mention Owns"
}

test_stories_review_template_ends_with_stories_ready() {
  local last_two
  require_file "$TEMPLATE"
  last_two=$(grep -v '^[[:space:]]*$' "$TEMPLATE" | tail -n 2)
  [ "$last_two" = $'Max severity: <critical | major | minor | none>\nStories ready: <yes | no>' ] \
    || fail "the template does not end with Max severity then Stories ready"
}

test_stories_review_is_a_soft_gate() {
  local checks
  require_file "$COMMAND"
  contains "$COMMAND" 'writes `docs/reviews/stories.md` on `Target branch`'
  checks=$(section_of "$RESEARCH" 'Checks first')
  grep -qF 'docs/reviews/stories.md' <<< "$checks" || fail "po-research does not check the stories review"
  grep -qF 'Stories ready:' <<< "$checks" || fail "po-research does not read the Stories ready verdict"
  grep -qF 'this check never blocks' <<< "$checks" || fail "po-research does not keep the stories review soft"
}

# s23 — a brief's non-goals are the exclusion list, not scope to cover.
test_stories_review_treats_non_goals_as_the_graveyard() {
  local checks coverage exclusions
  require_file "$SKILL"
  checks=$(section_of "$SKILL" 'Checks, in this order')
  coverage=$(grep -m1 '^\*\*1\.' <<< "$checks")
  exclusions=$(grep -m1 '^\*\*2\.' <<< "$checks")
  grep -qF 'From a brief: the wedge,' <<< "$coverage" \
    || fail "the coverage check does not take the wedge alone as the brief's scope item"
  ! grep -qF '`## Wedge & non-goals` and each entry' <<< "$coverage" \
    || fail "the coverage check still counts the non-goals among the items to cover"
  grep -qF '## Graveyard' <<< "$exclusions" || fail "check 2 does not read the graveyard of a PRD"
  grep -qF 'non-goals' <<< "$exclusions" || fail "check 2 does not read the non-goals of a brief"
  ! grep -qF 'not applicable' "$SKILL" || fail "stories-review still drops a check as not applicable"
  section_of "$SKILL" 'Severity' | grep -qF 'non-goal' \
    || fail "the severity scale does not rate a revived non-goal"
}

test_stories_review_template_separates_scope_and_exclusions() {
  local coverage exclusions
  require_file "$TEMPLATE"
  coverage=$(section_of "$TEMPLATE" 'Coverage')
  exclusions=$(section_of "$TEMPLATE" 'Exclusions')
  grep -q '^| Scope item' <<< "$coverage" || fail "the template has no coverage table"
  ! grep -qFi 'non-goal' <<< "$coverage" || fail "the template still offers the non-goals as a coverage source"
  grep -q '^| Excluded item' <<< "$exclusions" || fail "the template has no exclusions table"
  grep -qF '## Graveyard' <<< "$exclusions" || fail "the exclusions table does not name the graveyard of a PRD"
  grep -qFi 'non-goal' <<< "$exclusions" || fail "the exclusions table does not name the non-goals of a brief"
  section_of "$TEMPLATE" 'Checks' | grep -qF 'Exclusions:' \
    || fail "the template checks do not list the exclusions check"
  ! grep -qF 'PRD only' "$TEMPLATE" || fail "the template still restricts the exclusions check to a PRD"
}
