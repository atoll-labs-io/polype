# s209 — task test: an invalid run keeps the first changed file, before and after, found by its label.

source <(sed '/^test_/,$d' "$ROOT/tests/git-runs-outside-the-sandbox.oracle.test.sh")

test_kept_pair_follows_the_first_change() {
  local kept
  real_setup
  usable_build "$RTMP/pair"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  REAL_OUT="$RTMP/results/journey.1"
  mkdir -p "$RTMP/results"
  echo '{"type":"result","subtype":"success","is_error":false}' > "$REAL_OUT.session1.jsonl"
  echo 1 > "$REAL_OUT.sessions"
  real_hold_governing "$RTMP/held"
  cp "$R/.git/config" "$RTMP/git-config.before"

  git config --file "$R/.git/config" core.hooksPath /dev/null
  ! real_session_held || fail "a changed git config did not stop the run"
  kept="$REAL_OUT.changed"
  cmp -s "$kept/before" "$RTMP/git-config.before" || fail "the kept before is not the git config as built: $(cat "$kept/before")"
  cmp -s "$kept/after" "$R/.git/config" || fail "the kept after is not the changed git config: $(cat "$kept/after")"
  grep -qF 'hooksPath = /dev/null' "$kept/after" || fail "the kept after misses the change: $(cat "$kept/after")"

  jq '.permissions.allow += ["Bash(curl:*)"]' "$J/config/settings.json" > "$RTMP/s.json" && cp "$RTMP/s.json" "$J/config/settings.json"
  ! real_session_held || fail "the second check let the run go on"
  cmp -s "$kept/before" "$RTMP/git-config.before" && cmp -s "$kept/after" "$R/.git/config" \
    || fail "a later check rewrote the kept pair: $(cat "$kept/before")"
}

test_lane_outside_the_root_maps_to_its_path() {
  local got
  real_setup
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  R="$RTMP/repo" J="$RTMP/run"
  got="$(real_governing_file 'worktree//x/lane/AGENTS.md')"
  [ "$got" = /x/lane/AGENTS.md ] || fail "a lane outside the root maps to $got"
  got="$(real_governing_file 'worktree/.worktrees/s01/AGENTS.md')"
  [ "$got" = "$R/.worktrees/s01/AGENTS.md" ] || fail "a lane under the root maps to $got"
}
