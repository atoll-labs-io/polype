#!/usr/bin/env bash
# s211 — the oracle of the story: `po next` hands the lead the literal commands that open a lane, every
# git one a single `git -C <absolute root>` call, and every verb of `po` answers `--help` with its usage,
# `inbox` with the JSON form `inbox add` takes, exiting 0 and writing nothing (#508, #478).

VERBS="state next inbox answer record run continue ship"

# opening_fixture: the driver oracle's project (sourced here, at run time, so this file does not take on
# its test_ functions), one ready story, an origin that moved on since the last fetch, two environment
# files git ignores and an Install that leaves a mark where it runs. Sets F, ORIGIN and TIP.
opening_fixture() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  project
  story s01-alpha command -
  printf 'Install: touch installed-here\n' >> "$F/AGENTS.local.md"
  printf '.env\n.env.local\n' >> "$F/.gitignore"
  printf 'KEY=one\n' > "$F/.env"
  printf 'KEY=two\n' > "$F/.env.local"
  start
  ORIGIN="$SCRATCH/origin.git"
  git init -q --bare -b main "$ORIGIN"
  git -C "$F" remote add origin "$ORIGIN"
  git -C "$F" push -q origin main
  git -C "$F" fetch -q origin
  git clone -q "$ORIGIN" "$SCRATCH/other"
  git -C "$SCRATCH/other" config user.email test@example.com
  git -C "$SCRATCH/other" config user.name test
  git -C "$SCRATCH/other" commit -q --allow-empty -m "later on origin"
  git -C "$SCRATCH/other" push -q origin main
  TIP="$(git -C "$ORIGIN" rev-parse main)"
}

test_next_gives_lane_commands() {
  opening_fixture
  po_in "$F" next
  next_shape "po next"
  jq -e '[.actions[] | select(.story == "s01-alpha") | [.action, .reason]] == [["plan", "ready"]]' <<< "$OUT" >/dev/null \
    || fail "s01-alpha is not a lane to open: $OUT"
  local commands
  commands="$(jq -c '[.actions[] | select(.story == "s01-alpha")][0].commands' <<< "$OUT")"
  jq -e 'type == "array" and length > 0 and all(.[]; type == "string" and length > 0)' <<< "$commands" >/dev/null \
    || fail "the lane to open carries no list of commands: $OUT"
  jq -e 'all(.actions[]; .reason == "ready" or (has("commands") | not))' <<< "$OUT" >/dev/null \
    || fail "an entry that opens no lane carries commands: $OUT"

  local cmd count=0 lane="$F/.worktrees/s01-alpha"
  while IFS= read -r cmd; do
    count=$((count + 1))
    case "$cmd" in *'$'* | *'`'*) fail "command $count holds a variable or a substitution: $cmd" ;; esac
    if grep -qw git <<< "$cmd"; then
      case "$cmd" in "git -C $F "*) ;; *) fail "git command $count does not start with git -C $F: $cmd" ;; esac
      case "$cmd" in *';'* | *'&'* | *'|'* | *'<('* | *'>'* | *' for '* | *' while '* | *' cd '*)
        fail "git command $count is more than one call: $cmd" ;; esac
    fi
    (cd / && bash -c "$cmd") >/dev/null 2>&1 || fail "command $count failed when run as given from /: $cmd"
  done < <(jq -r '.[]' <<< "$commands")
  jq -e --arg lane "$lane" 'any(.[]; startswith("git -C ") and contains(" worktree add ") and contains($lane))' \
    <<< "$commands" >/dev/null || fail "no git -C … worktree add names the absolute lane path $lane: $commands"

  git -C "$F" worktree list --porcelain | grep -qx "worktree $lane" || fail "the commands opened no worktree at $lane"
  [ "$(git -C "$lane" rev-parse --abbrev-ref HEAD)" = story/s01-alpha ] || fail "the lane is not on story/s01-alpha"
  [ "$(git -C "$lane" rev-parse HEAD)" = "$TIP" ] || fail "the lane does not start from origin/main as fetched now"
  cmp -s "$F/.env" "$lane/.env" && cmp -s "$F/.env.local" "$lane/.env.local" \
    || fail "the environment files git ignores were not copied into the lane"
  [ -f "$lane/installed-here" ] || fail "Install did not run inside the lane"
  [ ! -e "$F/installed-here" ] || fail "Install ran at the repository root"

  po_in "$F" next
  next_shape "po next once the lane is open"
  jq -e '[.actions[] | select(.story == "s01-alpha") | [.action, .reason, has("commands")]] == [["plan", "no research", false]]' \
    <<< "$OUT" >/dev/null || fail "the opened lane is not read back as a lane without research: $OUT"
}

# snapshot: every path of the project and of the Claude Code folder, with size and modification time.
snapshot() { find "$F" "$CLAUDE_CONFIG_DIR" -printf '%p %s %T@\n' | sort; }

test_every_verb_has_help() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  project
  start
  export CLAUDE_CONFIG_DIR="$SCRATCH/claude"
  mkdir -p "$CLAUDE_CONFIG_DIR" "$SCRATCH/bin"
  printf '#!/usr/bin/env bash\ntouch "%s/launched"\n' "$SCRATCH" > "$SCRATCH/bin/claude"
  chmod +x "$SCRATCH/bin/claude"
  export PO_CLAUDE="$SCRATCH/bin/claude" PATH="$SCRATCH/bin:$PATH"
  local decision='{"motive":"stop","question":"Retry the lane?","options":[{"key":"a","label":"Yes","consequence":"one more run"},{"key":"b","label":"No","consequence":"the lane waits"}],"recommended":"a","why":"the cause is known","reversible":true,"blocks":[]}'

  local before verb
  before="$(snapshot)"
  for verb in $VERBS; do
    STATUS=0; OUT="$(cd "$F" && "$PO" "$verb" --help </dev/null 2>/dev/null)" || STATUS=$?
    [ "$STATUS" -eq 0 ] || fail "po $verb --help exited $STATUS: $OUT"
    [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "po $verb --help is not one JSON value: $OUT"
    jq -e --arg v "$verb" '.contract == 1 and .verb == $v and (.usage | type == "string" and contains("po " + $v))' \
      <<< "$OUT" >/dev/null || fail "po $verb --help does not give the usage of po $verb: $OUT"
  done
  STATUS=0; OUT="$(cd "$F" && printf '%s' "$decision" | "$PO" inbox add --help 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po inbox add --help exited $STATUS: $OUT"
  jq -e '.contract == 1 and .verb == "inbox" and (.input | type == "object")' <<< "$OUT" >/dev/null \
    || fail "po inbox add --help does not give the JSON form inbox add takes: $OUT"
  [ "$(snapshot)" = "$before" ] || fail "a --help call wrote something: $(diff <(printf '%s\n' "$before") <(snapshot) | head -n 5)"
  [ ! -e "$SCRATCH/launched" ] || fail "a --help call launched a session"

  local input="$OUT"
  STATUS=0; OUT="$(cd "$F" && jq -c '.input' <<< "$input" | "$PO" inbox add 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] && jq -e '.status == "pending"' <<< "$OUT" >/dev/null \
    || fail "po inbox add refuses the form its own --help gives (exit $STATUS): $OUT"
}
