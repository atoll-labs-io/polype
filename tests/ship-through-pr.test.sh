#!/usr/bin/env bash
# s105 — every story lands through a pull request, as one commit, and no agent pushes Target branch.

SHIP="$METHOD/commands/po-ship.md"

test_ship_opens_a_pr_and_fast_forwards() {
  require_file "$SHIP"
  contains "$SHIP" 'git merge-tree --write-tree <base> story/<id>'
  contains "$SHIP" 'git commit-tree <tree> -p <base> -m "<id>: <story title>"'
  contains "$SHIP" 'gh pr merge <url> --rebase --match-head-commit <sha>'
  contains "$SHIP" 'git merge --ff-only <sha>'
  contains "$SHIP" 'Pull request ready: <url>. Land it with Rebase and merge'
  ! grep -qF -- '--squash' "$SHIP" || fail "po-ship.md still uses --squash"
}

test_one_commit_per_story() {
  contains "$METHOD/AGENTS.md" 'one commit titled `<id>: <story title>`'
  contains "$METHOD/AGENTS.md" 'no merge commit'
  local f
  for f in AGENTS.md commands/po-ship.md commands/po-drive.md commands/po-flow.md \
           commands/po-orchestrator.md commands/po-help.md agents/implementer.md templates/agents-local.md; do
    require_file "$METHOD/$f"
    ! grep -qi 'squash' "$METHOD/$f" || fail "method/$f still says squash"
  done
}

test_no_agent_pushes_target_branch() {
  contains "$METHOD/AGENTS.md" 'No agent pushes `Target branch`'
  contains "$SHIP" '--force-with-lease=story/<id>'
  local pushes stray
  pushes=$(grep -F 'git push' "$SHIP")
  [ -n "$pushes" ] || fail "po-ship.md no longer pushes the story branch"
  stray=$(grep -vF 'story/<id>' <<< "$pushes" || true)
  [ -z "$stray" ] || fail "po-ship.md has a git push that does not name story/<id>: $stray"
}

test_push_targets_only_the_story_ref() {
  local pushes
  pushes=$(grep -F 'git push' "$SHIP")
  grep -F -- '--force-with-lease=story/<id>' "$SHIP" | grep -qF '<sha>:refs/heads/story/<id>' \
    || fail "the story push no longer sends <sha>:refs/heads/story/<id>"
  ! grep -qF 'Target branch' <<< "$pushes" || fail "a git push line of po-ship.md names Target branch"
  local refs
  refs=$(grep -o 'refs/heads/[^ `]*' <<< "$pushes" | grep -vxF 'refs/heads/story/<id>' || true)
  [ -z "$refs" ] || fail "a git push line names a ref other than story/<id>: $refs"
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
  local step2 gate merge adr
  step2=$(awk '/^## Step 2/ {on=1} /^## Step 3/ {on=0} on' "$SHIP")
  gate=$(grep -nF 'po-gate ship-allowed <id>' <<< "$step2" | head -n 1 | cut -d: -f1)
  merge=$(grep -nF 'gh pr merge' <<< "$step2" | head -n 1 | cut -d: -f1)
  [ -n "$gate" ] && [ -n "$merge" ] && [ "$gate" -le "$merge" ] \
    || fail "Step 2 must run po-gate ship-allowed again before gh pr merge"
  if [ "$gate" -eq "$merge" ]; then
    local line
    line=$(sed -n "${gate}p" <<< "$step2")
    [[ "${line%%gh pr merge*}" == *'po-gate ship-allowed <id>'* ]] \
      || fail "Step 2 must run po-gate ship-allowed again before gh pr merge"
  fi
  contains "$SHIP" '`story/<id>` is never rewritten'
  adr=$(ls "$ROOT"/docs/decisions/ADR-0015-*.md 2>/dev/null | head -n 1)
  [ -n "$adr" ] || fail "missing ADR-0015"
  frontmatter "$adr" | grep -qx 'status: superseded' || fail "ADR-0015 is not superseded"
  frontmatter "$adr" | grep -qx 'superseded-by: \[ADR-0080\]' || fail "ADR-0015 is not superseded by ADR-0080"
}
