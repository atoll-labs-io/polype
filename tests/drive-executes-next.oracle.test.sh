#!/usr/bin/env bash
# s173 — /po-drive executes what `po next` says. Oracle of the two criteria a script reads:
# the word cap of po-drive.md, and the single shell /po-execute may run (ADR-0120), which
# bin/po-lint holds. The other criteria speak to a model and are judged in review.

DRIVE="$METHOD/commands/po-drive.md"
EXECUTE="$METHOD/commands/po-execute.md"
PO_NEXT_TOOL='Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)'

test_drive_holds_in_2500_words() {
  require_file "$DRIVE"
  local words; words="$(LC_ALL=C wc -w < "$DRIVE")"
  [ "$words" -le 2500 ] || fail "po-drive.md holds $words words, past 2500"
}

MUTANTS="$(mktemp -d)"
trap 'rm -rf "$MUTANTS"' EXIT

# A copy of method/ where awk program $1 rewrites po-execute.md: `tool` is the line of $2,
# `old` the po next line.
execute_mutant() {
  local dir f
  dir="$(mktemp -d "$MUTANTS/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  f="$dir/method/commands/po-execute.md"
  awk -v tool="  - $2" -v old="  - $PO_NEXT_TOOL" "$1" "$f" > "$f.new" && mv "$f.new" "$f"
  echo "$dir/method"
}

# po-lint must refuse the mutant, naming the tool line of po-execute.md and nothing else.
lint_refuses() {
  local m="$1" tool="$2" n out rc=0
  n="$(grep -n -m1 -x -F -- "  - $tool" "$m/commands/po-execute.md" | cut -d: -f1)"
  [ -n "$n" ] || fail "mutation did not apply: $tool"
  out="$(bash "$ROOT/bin/po-lint" "$m" 2>&1)" || rc=$?
  [ "$rc" -eq 1 ] || fail "po-lint exited $rc on /po-execute declaring $tool: $out"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach for $tool, po-lint said: $out"
  grep -qF -- "commands/po-execute.md:$n: [tools] says it cannot edit files or run a shell but declares $tool" <<< "$out" \
    || fail "po-lint did not name $tool at commands/po-execute.md:$n: $out"
}

test_execute_refuses_a_shape_blocked_fix() {
  require_file "$EXECUTE"
  # The lint rule keys on this description: losing it would switch the check off.
  frontmatter "$EXECUTE" | grep -qF 'cannot edit files or run a shell' \
    || fail "po-execute.md no longer says it cannot edit files or run a shell"
  local tools
  tools="$(tools_of "$EXECUTE" | LC_ALL=C sort | tr '\n' '|')"
  [ "$tools" = "Agent|$PO_NEXT_TOOL|Glob|Grep|Read|" ] || fail "po-execute tools are not exactly Read, Glob, Grep, Agent and po next: $tools"

  local out rc=0
  out="$(bash "$ROOT/bin/po-lint" 2>&1)" || rc=$?
  [ "$rc" -eq 0 ] || fail "po-lint refuses the real tree: $out"

  local add='{print} $0 == "  - Agent" {print tool}' extra
  for extra in Bash Write \
      'Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next:*)' \
      'Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)'; do
    lint_refuses "$(execute_mutant "$add" "$extra")" "$extra"
  done
  local whole='Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po":*)'
  local swap='$0 == old {print tool; next} {print}'
  lint_refuses "$(execute_mutant "$swap" "$whole")" "$whole"
}
