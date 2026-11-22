#!/usr/bin/env bash
# s81 — the scenarios driver runs commands, requests and library calls on a copy and keeps their transcripts.

DRIVER="$METHOD/skills/qa-drivers/scenarios.md"

test_scenarios_run_each_visible_criterion() {
  require_file "$DRIVER"
  contains "$DRIVER" 'No secret enters a transcript'
  contains "$DRIVER" '`<redacted>`'
}

test_scenarios_start_the_service_itself() {
  require_file "$DRIVER"
  contains "$DRIVER" '127.0.0.1'
  contains "$DRIVER" 'and only that one'
  contains "$DRIVER" 'you did not start is never started, stopped, restarted or written to'
}

test_scenarios_leave_the_tree_clean() {
  require_file "$DRIVER"
  contains "$DRIVER" 'runs on a copy, never in the worktree'
  contains "$DRIVER" 'mktemp -d'
  contains "$DRIVER" 'ls-files --others --ignored --exclude-standard'
  contains "$DRIVER" 'status --porcelain --ignored'
}
