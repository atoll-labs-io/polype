#!/usr/bin/env bash
# s28 — the diff of a story stays inside what it owns.

SKILL="$METHOD/skills/review-antihallu/SKILL.md"
AGENT="$METHOD/agents/reviewer.md"
SCOPE='Before anything: the diff stays inside `Owns`'

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_reviewer_checks_the_diff_against_owns() {
  require_file "$SKILL"
  local scope; scope=$(section_of "$SKILL" "$SCOPE")
  [ -n "$scope" ] || fail "review-antihallu has no '## $SCOPE' section"

  # Where the paths come from and what they are held against.
  holds "$scope" 'git diff --name-only <Target branch>...story/<id>' 'the scope check'
  holds "$scope" 'a directory owned by one story covers every path beneath it' 'the scope check'

  # The two severities, and what makes the second one critical.
  holds "$scope" '**Outside `Owns` → major.**' 'the scope check'
  holds "$scope" 'Name the path and the `Owns` line it missed' 'the scope check'
  holds "$scope" '**Inside another running story'"'"'s `Owns` → critical.**' 'the scope check'
  holds "$scope" 'git worktree list' 'the scope check'
  holds "$scope" 'not merged into `Target branch`' 'the scope check'

  # The story's own evidence never appears in an `Owns`, so it must not raise a finding.
  holds "$scope" 'pipeline evidence is in scope by construction' 'the scope check'
  holds "$scope" '`docs/verif/<id>.md`' 'the scope check'
  # A rule of AGENTS.md that forces a path is the story's gap, not the implementer's fault.
  holds "$scope" 'not a breach by the implementer but a gap in the story'"'"'s `Owns`' 'the scope check'
  holds "$scope" 'report it **minor**' 'the scope check'
  # Missing `Owns` is never silence.
  holds "$scope" 'no `Owns` line at all' 'the scope check'
  holds "$scope" 'unverifiable scope' 'the scope check'

  # The reviewer reads the file the `Owns` lines live in, and announces the check.
  require_file "$AGENT"
  local inputs; inputs=$(section_of "$AGENT" 'Inputs')
  holds "$inputs" '`docs/stories.md`' 'the reviewer inputs'
  holds "$inputs" '`Owns`' 'the reviewer inputs'
  contains "$AGENT" 'The procedure — the scope check that comes first, then six steps and the severity scale'
}

test_review_procedure_places_the_ownership_step_first() {
  require_file "$SKILL"
  local scope_line steps_line
  scope_line=$(grep -nxF -- "## $SCOPE" "$SKILL" | cut -d: -f1)
  steps_line=$(grep -nxF -- '## Six steps, all of them, in this order' "$SKILL" | cut -d: -f1)
  [ -n "$scope_line" ] || fail "review-antihallu has no '## $SCOPE' heading"
  [ -n "$steps_line" ] || fail "review-antihallu lost its '## Six steps' heading"
  [ "$scope_line" -lt "$steps_line" ] \
    || fail "the scope check (line $scope_line) must come before the six steps (line $steps_line)"

  # Ordering is a rule, not an accident of layout: the section says why it comes first.
  local scope; scope=$(section_of "$SKILL" "$SCOPE")
  holds "$scope" 'This comes first because it decides what the rest of the review reads' 'the scope check'
}
