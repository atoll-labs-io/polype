#!/usr/bin/env bash
# s89 — /po-retro, a retro read from the recorded files (ADR-0067).

RETRO="$METHOD/commands/po-retro.md"

test_retro_writes_nothing() {
  local t
  for t in Write Edit NotebookEdit; do lacks_tool "$RETRO" "$t"; done
}
