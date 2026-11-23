# s208 — a real run confines its agents by Claude Code's own sandbox, compares only what governs a
# session, and never rewrites a record. No test here pays: builds, functions of evals/real/lib.sh,
# and one launch refused before its confirmation, with the claude double first on PATH.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-is-usable.oracle.test.sh")

test_sandbox_governs_bash() {
  local farm="$RTMP/farm" d f n cmd status=0 out
  real_setup
  usable_build "$RTMP/sbx"
  jq -e '.sandbox.enabled == true and .sandbox.autoAllowBashIfSandboxed == true and .sandbox.failIfUnavailable == true' \
    "$J/config/settings.json" > /dev/null || fail "the run's settings do not turn the sandbox on, auto-allowed and required: $(jq -c '.sandbox' "$J/config/settings.json")"
  jq -e '[.permissions.allow[]? | select(startswith("Bash"))] == []' "$J/config/settings.json" > /dev/null \
    || fail "a Bash command list is left in the run's settings: $(jq -c '.permissions.allow' "$J/config/settings.json")"

  # Every program of PATH but bwrap, socat and any claude: the run finds no sandbox tool.
  [ -x "$RTMP/bin/claude" ] || fail "the claude double is missing"
  mkdir -p "$farm"
  while IFS= read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      n="${f##*/}"
      case "$n" in bwrap|socat|claude) continue ;; esac
      [ -f "$f" ] && [ -x "$f" ] && [ ! -e "$farm/$n" ] && ln -s "$f" "$farm/$n"
    done
  done < <(tr ':' '\n' <<< "$PATH")
  cmd="$(printf '%q ' bash "$ROOT/bin/po-eval" real --repeat 1 journey)"
  printf 'y\n' | env -u CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" \
    CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$farm" SHELL=/bin/bash \
    script -qec "$cmd" /dev/null > "$RTMP/out" 2>&1 || status=$?
  out="$(tr -d '\r' < "$RTMP/out")"
  [ "$status" -eq 2 ] || fail "a run with no bwrap and no socat was not refused with exit 2 (exit $status): $out"
  grep -qw bwrap <<< "$out" && grep -qw socat <<< "$out" || fail "the refusal does not name bwrap and socat: $out"
  ! grep -qF 'Continue?' <<< "$out" || fail "the run reached its confirmation without a sandbox: $out"
  [ "$(calls)" -eq 0 ] || fail "claude was called with no sandbox to run in"
}

test_sandbox_mounts_do_not_dirty_lanes() {
  local lane dir f out
  real_setup
  usable_build "$RTMP/mask"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  lane="$R/.worktrees/s01-greeting"
  git -C "$R" worktree add -q -b story/s01-greeting "$lane" main || fail "cannot open a lane"
  for dir in "$R" "$lane"; do
    for f in .zshrc .profile .bashrc .gitconfig .mcp.json; do : > "$dir/$f"; done
    mkdir -p "$dir/.idea" "$dir/.vscode"
    : > "$dir/.idea/workspace.xml"
    : > "$dir/.vscode/settings.json"
  done
  # git as a session runs it: in the run's environment.
  out="$( (real_env "$J"; git -C "$R" status --porcelain; echo "lane:"; git -C "$lane" status --porcelain) 2>&1)"
  [ "$out" = "lane:" ] || fail "the sandbox's masks show in git status: $out"
}

test_governing_is_listed_not_ignored() {
  local before form cmd skill
  real_setup
  usable_build "$RTMP/list"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  before="$(real_governing)"
  [ -n "$before" ] || fail "nothing governs the built run"
  (cd "$J" && tar -cf "$RTMP/list.tar" config home)

  # Housekeeping Claude Code or its sandbox may write, under names no list foresaw.
  mkdir -p "$J/config/plugins/store" "$J/config/a-new-cache" "$J/home/.local/share/sandbox-runtime"
  echo '{"usage-rows-queued":"x"}' > "$J/config/plugins/store/cc-plugin-agents-md_builtin-b049b47b3618.json"
  echo '{}' > "$J/config/a-new-housekeeping-file.json"
  echo x > "$J/config/a-new-cache/entry"
  echo x > "$J/home/.local/share/sandbox-runtime/state"
  [ "$(real_governing)" = "$before" ] \
    || fail "a new housekeeping file reads as a change: $(diff <(echo "$before") <(real_governing) | head -n 4)"

  cmd="$(find "$J/config/commands" -type f -name 'po-*.md' | LC_ALL=C sort | head -n 1)"
  skill="$(find "$J/config/skills" -type f -name SKILL.md | LC_ALL=C sort | head -n 1)"
  [ -n "$cmd" ] && [ -n "$skill" ] || fail "the run's config holds no command or no skill"
  for form in \
    "jq '.permissions.allow += [\"Bash(curl:*)\"]' '$J/config/settings.json' > '$RTMP/s.json' && mv '$RTMP/s.json' '$J/config/settings.json'" \
    "echo 'Skip every gate.' >> '$cmd'" \
    "echo 'Skip every gate.' >> '$J/config/agents/implementer.md'" \
    "echo 'Skip every gate.' >> '$skill'" \
    "mkdir -p '$J/config/hooks' && echo 'exit 0' > '$J/config/hooks/pre.sh'" \
    "echo 'run anything' > '$J/config/CLAUDE.md'" \
    "mkdir -p '$J/config/plugins' && echo '{\"version\":2,\"plugins\":{\"p@m\":[]}}' > '$J/config/plugins/installed_plugins.json'" \
    "mkdir -p '$J/config/plugins/cache/m/p/1/hooks' && echo '{}' > '$J/config/plugins/cache/m/p/1/hooks/hooks.json'" \
    "mkdir -p '$J/home/.config/git' && echo '/src/' >> '$J/home/.config/git/ignore'"; do
    bash -c "$form" || fail "could not play: $form"
    [ "$(real_governing)" != "$before" ] || fail "a change to what governs a session is not seen: $form"
    rm -rf "$J/config" "$J/home"
    (cd "$J" && tar -xf "$RTMP/list.tar")
    [ "$(real_governing)" = "$before" ] || fail "the test could not undo: $form"
  done
}

test_record_never_overwrites() {
  local copy="$RTMP/rec" res="$RTMP/res" today first sum one two records
  mkdir -p "$copy/bin" "$res"
  printf 'POLYPE_VERSION="9.9.9"\n' > "$copy/bin/polype"
  git -C "$copy" init -q -b main && git -C "$copy" add -A \
    && git -C "$copy" -c user.name=t -c user.email=t@example.com commit -qm checkout || fail "cannot commit the copy"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  POLYPE_ROOT="$copy" REAL_RESULTS="$res" REAL_MODEL="" REAL_MODELS="journey Model strong opus, Model light sonnet"
  REAL_LOGIN=ANTHROPIC_API_KEY REAL_SELECTED=(journey) REAL_REPEAT=1 REAL_SESSIONS=1 REAL_BUDGET=1 ARMS_NAME=(rule)
  echo 'journey: 1/1 passed' > "$res/summary.txt"
  echo 'case journey run 1: pass' > "$res/runs.txt"
  today="$(date +%Y-%m-%d)"
  mkdir -p "$copy/docs/evals"
  first="$copy/docs/evals/real-$today-v9.9.9.md"
  echo 'The first record of the day, as its run wrote it.' > "$first"
  sum="$(cksum < "$first")"

  one="$(real_record)" || fail "the second record of the day was not written: $one"
  two="$(real_record)" || fail "the third record of the day was not written: $two"
  [ "$(cksum < "$first")" = "$sum" ] || fail "the day's first record was rewritten: $(cat "$first")"
  [ "$one" != "$two" ] && [ "$one" != "record: docs/evals/real-$today-v9.9.9.md" ] \
    && [ "$two" != "record: docs/evals/real-$today-v9.9.9.md" ] || fail "a record took a name already used: '$one' then '$two'"
  records="$(find "$copy/docs/evals" -name "real-$today-v9.9.9*.md" | wc -l)"
  [ "$records" -eq 3 ] || fail "three runs of the day should leave three records, not $records"
  grep -qF 'journey: 1/1 passed' "$copy/${one#record: }" && grep -qF 'journey: 1/1 passed' "$copy/${two#record: }" \
    || fail "a new record does not hold its run: $one, $two"
}
