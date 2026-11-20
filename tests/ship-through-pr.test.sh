#!/usr/bin/env bash
# s105 — every story lands through a pull request, as one commit, and no agent pushes Target branch.

SHIP="$METHOD/commands/po-ship.md"

test_ship_opens_a_pr_and_fast_forwards() {
  require_file "$SHIP"
  contains "$SHIP" 'Pull request ready: <url>. Land it with Rebase and merge'
  ! grep -qF -- '--squash' "$SHIP" || fail "po-ship.md still uses --squash"
}

test_one_commit_per_story() {
  contains "$METHOD/AGENTS.md" 'one commit titled `<id>: <story title>`'
  contains "$METHOD/AGENTS.md" 'no merge commit'
  local f
  for f in AGENTS.md commands/po-ship.md commands/po-drive.md \
           commands/po-help.md agents/implementer.md templates/agents-local.md; do
    require_file "$METHOD/$f"
    ! grep -qi 'squash' "$METHOD/$f" || fail "method/$f still says squash"
  done
}

test_no_agent_pushes_target_branch() {
  contains "$METHOD/AGENTS.md" 'No agent pushes `Target branch`'
  local pushes stray
  pushes=$(grep -F 'git push' "$SHIP")
  [ -n "$pushes" ] || fail "po-ship.md no longer pushes the story branch"
  stray=$(grep -vF 'story/<id>' <<< "$pushes" || true)
  [ -z "$stray" ] || fail "po-ship.md has a git push that does not name story/<id>: $stray"
}

test_local_only_without_remote() {
  local row
  row=$(grep -F '| Merge mode |' "$METHOD/templates/agents-local.md")
  grep -qF 'only for a repository without a remote' <<< "$row" \
    || fail "the Merge mode row of the template does not tie local to a repository without a remote"
  contains "$METHOD/commands/po-setup.md" 'only for a repository without a remote'
  contains "$SHIP" '`Merge mode: local` is only for a repository without a remote'
}

test_ship_gate_unchanged() {
  local adr
  adr=$(ls "$ROOT"/docs/decisions/ADR-0015-*.md 2>/dev/null | head -n 1)
  [ -n "$adr" ] || fail "missing ADR-0015"
  frontmatter "$adr" | grep -qx 'status: superseded' || fail "ADR-0015 is not superseded"
  frontmatter "$adr" | grep -qx 'superseded-by: \[ADR-0080\]' || fail "ADR-0015 is not superseded by ADR-0080"
}
