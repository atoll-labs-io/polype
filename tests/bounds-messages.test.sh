#!/usr/bin/env bash
# s98 — the last po-bounds messages.

BOUNDS="$METHOD/hooks/po-bounds.sh"
ADRS="$ROOT/docs/decisions"

# A repository with a committed docs/stories.md, one linked story/<id> worktree, and a TMPDIR of its
# own that does not hold $SCRATCH.
msg_lane() {
  scratch_repo
  LANE_TMP="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$LANE_TMP"' EXIT
  export TMPDIR="$LANE_TMP"
  mkdir -p "$SCRATCH/docs" "$SCRATCH/src"
  printf '# Stories\n\n### s01-demo — Demo\n- **Owns**: `src/app.sh`\n' > "$SCRATCH/docs/stories.md"
  : > "$SCRATCH/src/app.sh"
  git -C "$SCRATCH" add -A
  git -C "$SCRATCH" commit -qm stories
  git -C "$SCRATCH" worktree add -q -b story/s01-demo "$SCRATCH/.worktrees/s01-demo"
  WT="$SCRATCH/.worktrees/s01-demo"
}

msg_input() { jq -n --arg c "$1" --arg d "$SCRATCH" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}'; }
msg_status() { local s=0; msg_input "$2" | bash "$BOUNDS" "$1" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
msg_stderr() { msg_input "$2" | bash "$BOUNDS" "$1" 2>&1 >/dev/null || true; }

expect_exit() { [ "$(msg_status "$1" "$2")" = "$3" ] || fail "$1: $2: expected exit $3, got $(msg_status "$1" "$2")"; }

test_every_refusal_is_readable() {
  msg_lane
  local probe="$LANE_TMP/probe" spec mode cmd err
  git init -q "$probe"
  for spec in \
      "reviewer|git -C $probe log --\$(echo o)=/etc/passwd" \
      'qa|git $(echo log)' \
      'reviewer|git -C /etc $(echo log)' \
      'reviewer|git -C /nonexistent $(echo log)' \
      "reviewer|git -C $probe \$(echo log) /etc/x"; do
    mode="${spec%%|*}"; cmd="${spec#*|}"
    expect_exit "$mode" "$cmd" 2
    err="$(msg_stderr "$mode" "$cmd")"
    [[ "$err" != *$'\036'* ]] || fail "$mode: $cmd: the refusal shows the raw marker byte"
    grep -qF '<substitution>' <<< "$err" || fail "$mode: $cmd: the refusal does not say <substitution>: $err"
  done
}

test_named_fd_redirections_are_read() {
  msg_lane
  expect_exit qa "git -C $WT symbolic-ref HEAD {fd}>/dev/null" 0
  expect_exit qa "git -C $WT symbolic-ref HEAD 2>/dev/null" 0
}

test_implementer_explores_a_throwaway_clone() {
  msg_lane
  local t="$LANE_TMP" cmd
  git clone -q "$SCRATCH" "$t/clone"
  git -C "$SCRATCH" worktree add -q --detach "$t/main-wt"
  for cmd in \
      "git -C $t/clone checkout -q main" \
      "git -C $t/clone checkout -b x" \
      "cd $t/clone && git log --oneline" \
      "git -C $t/clone show HEAD:docs/stories.md > $t/out.md"; do
    expect_exit implementer "$cmd" 0
  done
  for cmd in \
      "git -C $WT checkout main" \
      "git -C $SCRATCH checkout main" \
      "git -C $t/main-wt checkout main" \
      "git -C $t/clone checkout main -- $WT/src/app.sh" \
      "git -C $t/clone show HEAD:docs/stories.md > $WT/src/app.sh" \
      "git -C $t/clone diff --output=$WT/x" \
      "git -C $t/clone switch main"; do
    expect_exit implementer "$cmd" 2
  done

  contains "$METHOD/agents/implementer.md" 'never checkout, switch or stash in the story worktree'
  contains "$METHOD/agents/implementer.md" 'clone it under the temp dir, where `git checkout` is allowed'
  ! grep -qF 'never checkout, switch or stash, never' "$METHOD/agents/implementer.md" \
    || fail "implementer.md still bans checkout everywhere"
  contains "$ROOT/docs/installation.md" "hors d'un dépôt jetable sous \`\${TMPDIR:-/tmp}\`"
  contains "$ROOT/docs/installation.md" '`file://` (ADR-0072)'
  local adr
  grep -qx 'supersedes: \[ADR-0050, ADR-0052\]' "$ADRS"/ADR-0072-*.md || fail "ADR-0072 does not supersede ADR-0050 and ADR-0052"
  for adr in "$ADRS"/ADR-0050-*.md "$ADRS"/ADR-0052-*.md; do
    grep -q '^superseded-by: \[.*ADR-0072\]$' "$adr" || fail "${adr#"$ROOT"/} does not name ADR-0072 in superseded-by"
    grep -qx 'status: accepted' "$adr" || fail "${adr#"$ROOT"/} is no longer accepted"
  done
}
