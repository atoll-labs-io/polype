#!/usr/bin/env bash
# s81 — the scenarios driver runs commands, requests and library calls on a copy and keeps their transcripts.

DRIVER="$METHOD/skills/qa-drivers/scenarios.md"

test_scenarios_run_each_visible_criterion() {
  require_file "$DRIVER"
  local h
  for h in '## Needs' '## Start and stop' '## Exercising a criterion' '## Evidence' '## Cannot show'; do
    grep -qxF -- "$h" "$DRIVER" || fail "scenarios.md lacks the section: $h"
  done
  contains "$DRIVER" 'the command with its arguments'
  contains "$DRIVER" 'the request with `curl`'
  contains "$DRIVER" 'calling the public interface'
  contains "$DRIVER" 'One transcript per scenario'
  contains "$DRIVER" 'the input, the output and the exit code'
  contains "$DRIVER" 'docs/qa/<id>/'
  contains "$DRIVER" 'No secret enters a transcript'
  contains "$DRIVER" '`<redacted>`'
}

test_scenarios_cover_failure_paths() {
  require_file "$DRIVER"
  contains "$DRIVER" 'at least one invalid input'
  contains "$DRIVER" 'the error message its user reads'
  contains "$DRIVER" '`<criterion>-error.txt`'
}

test_scenarios_start_the_service_itself() {
  require_file "$DRIVER"
  contains "$DRIVER" '127.0.0.1'
  contains "$DRIVER" 'on which nothing answers before the start'
  contains "$DRIVER" 'setsid'
  contains "$DRIVER" 'and only that one'
  contains "$DRIVER" 'you did not start is never started, stopped, restarted or written to'
}

test_scenarios_leave_the_tree_clean() {
  require_file "$DRIVER"
  contains "$DRIVER" 'runs on a copy, never in the worktree'
  contains "$DRIVER" 'mktemp -d'
  contains "$DRIVER" 'ls-files --others --ignored --exclude-standard'
  contains "$DRIVER" 'status --porcelain --ignored'
  contains "$DRIVER" 'cannot build one'
  contains "$DRIVER" 'ADR-0059'
}
