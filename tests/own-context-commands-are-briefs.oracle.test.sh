#!/usr/bin/env bash
# s197 — the oracle of the story: the three commands that work in their own context still lint.
# `routing_is_said_once`, `worktree_is_prepared_in_one_place` and `subagents_keep_their_procedure`
# speak to a model and are judged in review.

test_commands_still_lint() {
  local out f
  out="$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1)" || fail "bin/po-lint fails on method/: $out"
  for f in po-research po-plan po-design; do
    require_file "$METHOD/commands/$f.md"
    grep -q '^Reads settings: `' "$METHOD/commands/$f.md" || fail "$f.md lost its Reads settings line"
  done
  [ "$(tools_of "$METHOD/commands/po-research.md" | tr '\n' ' ')" = "Read Glob Grep Write Bash " ] \
    || fail "po-research.md tools changed: $(tools_of "$METHOD/commands/po-research.md" | tr '\n' ' ')"
  [ "$(tools_of "$METHOD/commands/po-plan.md" | tr '\n' ' ')" = "Read Glob Grep Write Bash AskUserQuestion " ] \
    || fail "po-plan.md tools changed: $(tools_of "$METHOD/commands/po-plan.md" | tr '\n' ' ')"
  [ -z "$(tools_of "$METHOD/commands/po-design.md")" ] || fail "po-design.md now limits its tools to a list"
}
