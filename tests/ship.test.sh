#!/usr/bin/env bash
# s07 — ship.

CMD="$METHOD/commands/po-ship.md"

test_ship_can_ask_before_merging() {
  needs_tool "$CMD" AskUserQuestion
}

