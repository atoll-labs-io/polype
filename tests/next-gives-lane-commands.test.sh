#!/usr/bin/env bash
# s211 — the edge cases of the commands `po next` gives to open a lane: no remote, a branch left
# without its worktree, an environment file git does not ignore, Install missing or `—`, and a project
# whose path holds a space.

# fixture: the driver oracle's project with one ready story s01-alpha, Install set, no remote.
fixture() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  project
  story s01-alpha command -
  printf 'Install: touch installed-here\n' >> "$F/AGENTS.local.md"
}

# commands_of <id>: sets CMDS to the JSON value of the entry's commands, after a successful po next.
commands_of() {
  po_in "$F" next
  next_shape "po next"
  CMDS="$(jq -c --arg id "$1" '[.actions[] | select(.story == $id)][0].commands' <<< "$OUT")"
}

# run_all: runs every command of CMDS as given, one bash -c each, from /.
run_all() {
  local cmd
  jq -e 'type == "array"' <<< "$CMDS" >/dev/null || fail "no list of commands: $OUT"
  while IFS= read -r cmd; do
    (cd / && bash -c "$cmd") >/dev/null 2>&1 || fail "command failed when run as given: $cmd"
  done < <(jq -r '.[]' <<< "$CMDS")
}

# lane_opened <id> <commit>: the lane of <id> is a worktree on story/<id> at <commit>, Install ran there.
lane_opened() {
  local lane="$F/.worktrees/$1"
  git -C "$F" worktree list --porcelain | grep -qxF "worktree $lane" || fail "no worktree at $lane"
  [ "$(git -C "$lane" rev-parse --abbrev-ref HEAD)" = "story/$1" ] || fail "the lane is not on story/$1"
  [ "$(git -C "$lane" rev-parse HEAD)" = "$2" ] || fail "the lane does not start at $2"
  [ -f "$lane/installed-here" ] || fail "Install did not run inside the lane"
}

test_no_remote_no_fetch() {
  fixture
  start
  commands_of s01-alpha
  jq -e 'all(.[]; contains(" fetch ") | not)' <<< "$CMDS" >/dev/null || fail "a fetch without a remote: $CMDS"
  jq -e --arg f "$F" 'any(.[]; . == "git -C \($f) worktree add -b story/s01-alpha \($f)/.worktrees/s01-alpha main")' \
    <<< "$CMDS" >/dev/null || fail "the lane does not open from main: $CMDS"
  run_all
  lane_opened s01-alpha "$(git -C "$F" rev-parse main)"
}

test_existing_branch_is_checked_out() {
  fixture
  start
  git -C "$F" branch story/s01-alpha main
  git -C "$F" commit -q --allow-empty -m "later on main"
  commands_of s01-alpha
  jq -e 'all(.[]; contains(" -b ") | not)' <<< "$CMDS" >/dev/null || fail "the existing branch is created again: $CMDS"
  run_all
  lane_opened s01-alpha "$(git -C "$F" rev-parse main~1)"
}

test_unignored_env_asks() {
  fixture
  start
  printf 'KEY=one\n' > "$F/.env"
  po_in "$F" next
  next_shape "po next"
  jq -e '[.actions[] | select(.story == "s01-alpha") | [.action, .reason, has("commands"), has("track")]]
    == [["ask", "env file not ignored", false, false]]' <<< "$OUT" >/dev/null \
    || fail "an .env git does not ignore does not ask: $OUT"
}

test_missing_install_gives_null() {
  fixture
  setting Install -
  start
  commands_of s01-alpha
  [ "$CMDS" = null ] || fail "commands without Install are not null: $CMDS"
  printf 'Install: —\n' >> "$F/AGENTS.local.md"
  commands_of s01-alpha
  jq -e 'type == "array" and all(.[]; startswith("(cd ") | not)' <<< "$CMDS" >/dev/null \
    || fail "Install: — still gives an install command, or no commands: $CMDS"
}

test_paths_with_a_space_run() {
  fixture
  local spaced="$SCRATCH/my project's copy"
  mv "$F" "$spaced"
  F="$spaced"
  printf '.env\n' >> "$F/.gitignore"
  printf 'KEY=one\n' > "$F/.env"
  start
  commands_of s01-alpha
  run_all
  lane_opened s01-alpha "$(git -C "$F" rev-parse main)"
  cmp -s "$F/.env" "$F/.worktrees/s01-alpha/.env" || fail "the ignored .env was not copied into the lane"
  po_in "$F" next
  jq -e '[.actions[] | select(.story == "s01-alpha") | .reason] == ["no research"]' <<< "$OUT" >/dev/null \
    || fail "the lane opened in a spaced path is not read back: $OUT"
}
