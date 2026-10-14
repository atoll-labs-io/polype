#!/usr/bin/env bash
# s99 — the throwaway zone holds.

BOUNDS="$METHOD/hooks/po-bounds.sh"

zone_lane() {
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

zone_input() { jq -n --arg c "$1" --arg d "$SCRATCH" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}'; }
zone_status() { local s=0; zone_input "$2" | bash "$BOUNDS" "$1" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
zone_stderr() { zone_input "$2" | bash "$BOUNDS" "$1" 2>&1 >/dev/null || true; }
zone_expect() { [ "$(zone_status "$1" "$2")" = "$3" ] || fail "$1: $2: expected exit $3, got $(zone_status "$1" "$2")"; }

test_throwaway_refuses_another_work_tree() {
  zone_lane
  local c="$LANE_TMP/clone" tail='checkout main -- .'
  git clone -q "$SCRATCH" "$c"
  local f
  for f in \
    "git -C $c --work-tree=$WT $tail" \
    "git -C $c --work-tree $WT $tail" \
    "git -C $c --git-dir=$SCRATCH/.git $tail" \
    "git -C $c -c core.worktree=$WT $tail" \
    "git -C $c -c Core.WorkTree=$WT $tail" \
    "git -C $c --config-env core.worktree=HOME $tail" \
    "git -C $c --config-env=core.worktree=HOME $tail" \
    "GIT_WORK_TREE=$WT git -C $c $tail" \
    "GIT_DIR=$WT/.git git -C $c $tail" \
    "GIT_DIR=\"$WT/.git\" git -C $c $tail" \
    "export GIT_WORK_TREE=$WT; git -C $c $tail"; do
    zone_expect implementer "$f" 2
  done
  zone_stderr implementer "git -C $c --work-tree=$WT $tail" | grep -qF 'forbidden to the implementer in a throwaway repo' \
    || fail "message missing"
  zone_stderr implementer "git -C $c -c core.worktree=$WT $tail" | grep -qF 'forbidden to the implementer in a throwaway repo' \
    || fail "core.worktree message does not name the throwaway repo"
  zone_expect implementer "git -C $c -c user.name=x checkout -q main" 0
  zone_expect implementer "git -C $c checkout -q main" 0
  zone_expect implementer "GIT_DIR=$SCRATCH/.git git -C $WT log" 0
}

test_story_worktree_is_judged_first() {
  zone_lane
  export TMPDIR="$SCRATCH"
  zone_expect implementer "git -C $WT checkout main" 2
  zone_stderr implementer "git -C $WT checkout main" | grep -qF 'forbidden to the implementer outside a throwaway repo' \
    || fail "message missing"
  git clone -q "$SCRATCH" "$SCRATCH/tmpclone"
  zone_expect implementer "git -C $SCRATCH/tmpclone checkout -q main" 0
}

test_implementer_knows_the_file_url() {
  contains "$METHOD/agents/implementer.md" 'file://<path>' || fail "implementer.md does not mention file://<path>"
}
