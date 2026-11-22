#!/usr/bin/env bash
# s35 — a lane also carries a story with a screen.

DESIGNER="$METHOD/agents/designer.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# The skills a subagent preloads, from the `skills:` list of its frontmatter.
skills_of() {
  frontmatter "$1" | awk '/^skills:/ {list=1; next} list && /^  - / {sub(/^  - /, ""); print; next} list {list=0}'
}

test_designer_agent_carries_the_design_contract() {
  require_file "$DESIGNER"
  grep -qx 'name: designer' <<< "$(frontmatter "$DESIGNER")" || fail "designer.md is not named designer"
  skills_of "$DESIGNER" | grep -qx 'design-doctrine' || fail "designer.md does not preload design-doctrine"
}

test_designer_writes_only_in_the_story_design_folder() {
  require_file "$DESIGNER"
  local limits; limits=$(section_of "$DESIGNER" 'Limits')
  [ -n "$limits" ] || fail "designer.md has no '## Limits' section"

  holds "$limits" 'You write under `docs/designs/<id>/` and nowhere else' 'the designer limits'
  holds "$limits" 'No source file, no test file, no commit' 'the designer limits'
  holds "$limits" 'the files stay uncommitted' 'the designer limits'
  holds "$limits" 'never code' 'the designer limits'

  # It prepared no lane and repairs none.
  contains "$DESIGNER" 'Never run `git worktree add`, `switch`, `checkout` or `stash`'
}

test_designer_asks_no_one() {
  require_file "$DESIGNER"
  frontmatter "$DESIGNER" | grep -m1 '^disallowedTools:' | grep -qw AskUserQuestion \
    || fail "designer.md does not disallow AskUserQuestion"
}
