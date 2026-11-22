#!/usr/bin/env bash
# s101 — the stories review asks with its own tool and never edits the stories or a verdict (ADR-0074).

CMDS="$METHOD/commands"

test_stories_review_surfaces_criticals_only() {
  local review="$CMDS/po-stories-review.md"
  needs_tool "$review" AskUserQuestion
  contains "$review" 'It never edits the stories.'
  contains "$review" "never changed: a verdict is the subagent's"
}
