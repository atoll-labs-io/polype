#!/usr/bin/env bash
# s58 — the designer and /po-design inherit the session's tools, browser included (ADR-0027).

DESIGNER="$METHOD/agents/designer.md"
PO_DESIGN="$METHOD/commands/po-design.md"

test_designer_inherits_the_session_browser() {
  require_file "$DESIGNER"
  local fm; fm=$(frontmatter "$DESIGNER")
  ! grep -q '^tools:' <<< "$fm" || fail "designer.md still restricts itself with tools:"
  local denied; denied=$(grep -m1 '^disallowedTools:' <<< "$fm" || true)
  [ -n "$denied" ] || fail "designer.md has no disallowedTools: line"
  local tool
  for tool in Write Edit Bash; do
    ! grep -qw "$tool" <<< "${denied#disallowedTools:}" || fail "designer.md disallows $tool"
  done
}

test_po_design_can_reach_a_browser() {
  require_file "$PO_DESIGN"
  local fm; fm=$(frontmatter "$PO_DESIGN")
  ! grep -qE '^(allowed-tools|tools):' <<< "$fm" || fail "po-design.md still limits its tools to a list"
  local named; named=$(grep -rniE 'mcp__|playwright|chrome' "$METHOD" || true)
  [ -z "$named" ] || fail "method/ names a browser tool or MCP server: $named"
}

test_design_still_writes_no_source_file() {
  require_file "$PO_DESIGN"
  require_file "$DESIGNER"
  contains "$PO_DESIGN" 'It writes no source file.'
  contains "$PO_DESIGN" 'never code: nothing in it is copied into source files'
  contains "$DESIGNER" 'No source file, no test file, no commit'
}
