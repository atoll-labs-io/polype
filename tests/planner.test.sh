#!/usr/bin/env bash
# s26 — the planner subagent.

AGENT="$METHOD/agents/planner.md"
RESEARCH_CMD="$METHOD/commands/po-research.md"
PLAN_CMD="$METHOD/commands/po-plan.md"

# The nth `<number> lines at most` of a file, empty when there is no nth one.
cap_of() { grep -o '[0-9]\+ lines at most' "$1" | sed -n "${2}p"; }

test_planner_carries_the_research_and_plan_contracts() {
  require_file "$AGENT"
  contains "$AGENT" 'templates/research.md'
  contains "$AGENT" 'templates/plan.md'
  contains "$AGENT" 'every fact carries its `path:line`'
  contains "$AGENT" '`## Run interdicts`'
  contains "$AGENT" '`## The pivot`'
  contains "$AGENT" '`validated: no`'
  contains "$AGENT" '`Test budget`'

  # The caps the subagent quotes are the ones its commands impose: if a command
  # changes its cap and this file does not follow, the two have drifted apart.
  require_file "$RESEARCH_CMD"; require_file "$PLAN_CMD"
  local agent_research agent_plan
  agent_research=$(cap_of "$AGENT" 1); agent_plan=$(cap_of "$AGENT" 2)
  [ -n "$agent_research" ] && [ -n "$agent_plan" ] || fail "planner.md must quote the research cap then the plan cap"
  [ "$agent_research" = "$(cap_of "$RESEARCH_CMD" 1)" ] \
    || fail "research cap drifted: planner.md says '$agent_research', po-research.md says '$(cap_of "$RESEARCH_CMD" 1)'"
  [ "$agent_plan" = "$(cap_of "$PLAN_CMD" 1)" ] \
    || fail "plan cap drifted: planner.md says '$agent_plan', po-plan.md says '$(cap_of "$PLAN_CMD" 1)'"
}

test_planner_preloads_testing_doctrine_and_codebase_analysis() {
  require_file "$AGENT"
  frontmatter "$AGENT" | grep -qx '  - codebase-analysis' || fail "planner must preload codebase-analysis"
  frontmatter "$AGENT" | grep -qx '  - testing-doctrine' || fail "planner must preload testing-doctrine"
}

test_planner_never_writes_code() {
  require_file "$AGENT"
  lacks_tool "$AGENT" Edit
  needs_tool "$AGENT" Write
  needs_tool "$AGENT" Bash
  contains "$AGENT" '`git -C <path> rev-parse --abbrev-ref HEAD` not printing `story/<id>` → stop and report'
  contains "$AGENT" 'Never run `git worktree add`, `switch`, `checkout` or `stash`'
  contains "$AGENT" 'You write `docs/research/<id>.md` and `docs/plans/<id>.md`, and no other file.'
}

test_planner_reports_the_track_it_used() {
  require_file "$AGENT"
  local settings; settings=$(settings_read_by "$AGENT")
  grep -qx 'Story track' <<< "$settings" || fail "planner must read Story track"
  grep -qx 'Flow threshold' <<< "$settings" || fail "planner must read Flow threshold"
  contains "$AGENT" 'is at most `Flow threshold`; above it, or with no complexity written, take the full track'
  contains "$AGENT" 'Name the track you used and why'
}
