# s212 — each session of a real run runs inside an outer sandbox the launcher sets up (ADR-0139),
# and Claude Code checks nothing inside it. No test here pays: every launch meets a claude double.
# The launches that prove the confinement meet the real bwrap, never the suite's presence stubs.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-is-usable.oracle.test.sh")

# The caller's PATH without the presence stubs of real-run-before-a-release.oracle.test.sh.
outer_path() { tr ':' '\n' <<< "$PATH" | grep -vxF "$RTMP/sandbox-tools" | paste -sd: -; }

outer_needs_bwrap() {
  (PATH="$(outer_path)"; command -v bwrap > /dev/null) \
    || fail "bwrap is not installed: the outer sandbox cannot be proven on this machine"
}

# outer_double: a claude double, first on PATH, that reports in one `probe` line of its stream what
# the session it plays could do: its arguments, the process at the root of its pid namespace, a
# write inside the run folder, writes outside it, and reads of the person's login files. It writes
# nowhere else, so it reports the same whether it is confined or not.
outer_double() {
  mkdir -p "$RTMP/outside" "$RTMP/home/.claude" "$RTMP/cfg"
  echo '{"claudeAiOauth":{"accessToken":"person-login-s212-home"}}' > "$RTMP/home/.claude/.credentials.json"
  echo '{"claudeAiOauth":{"accessToken":"person-login-s212-config"}}' > "$RTMP/cfg/.credentials.json"
  {
    echo '#!/usr/bin/env bash'
    printf 'OUTSIDE=%q PERSON_HOME=%q PERSON_CONFIG=%q\n' "$RTMP/outside" "$RTMP/home" "$RTMP/cfg"
    cat <<'SH'
w() { if (: > "$1") 2> /dev/null; then echo done; else echo refused; fi; }
r() { if cat "$1" > /dev/null 2>&1; then echo read; else echo unreadable; fi; }
jq -nc --arg inside "$(w "$TMPDIR/s212-inside")" --arg outside "$(w "$OUTSIDE/escaped")" \
  --arg home "$(w "$PERSON_HOME/escaped")" --arg cred_home "$(r "$PERSON_HOME/.claude/.credentials.json")" \
  --arg cred_config "$(r "$PERSON_CONFIG/.credentials.json")" --arg root "$(cat /proc/1/comm 2> /dev/null || echo unknown)" \
  --arg login "${ANTHROPIC_API_KEY:+set}" --argjson args "$(printf '%s\0' "$@" | jq -Rs 'split("\u0000")[:-1]')" \
  '{type: "probe", inside: $inside, outside: $outside, home: $home, cred_home: $cred_home,
    cred_config: $cred_config, root: $root, login: $login, args: $args}'
echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0}'
SH
  } > "$RTMP/bin/claude"
  chmod +x "$RTMP/bin/claude"
}

# outer_launch: one kept run of the journey on a pseudo-terminal, PATH leading to the double and
# to the real bwrap; sets PROBE to the double's report and RESULTS to the kept folder.
outer_launch() {
  local cmd
  cmd="$(printf '%q ' bash "$ROOT/bin/po-eval" real --repeat 1 --sessions 1 --keep journey)"
  RR_STATUS=0
  printf 'y\n' | env -u CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" \
    CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$(outer_path)" SHELL=/bin/bash \
    script -qec "$cmd" /dev/null > "$RTMP/out" 2>&1 || RR_STATUS=$?
  RR_OUT="$(tr -d '\r' < "$RTMP/out")"
  [ "$RR_STATUS" -eq 0 ] || fail "the run failed (exit $RR_STATUS): $RR_OUT"
  RESULTS="$(sed -n 's/^results: //p' <<< "$RR_OUT" | head -n 1)"
  [ -f "$RESULTS/journey.1.session1.jsonl" ] || fail "no kept stream for the session: $RR_OUT"
  PROBE="$(jq -c 'select(.type == "probe")' "$RESULTS/journey.1.session1.jsonl" 2> /dev/null | head -n 1)"
  [ -n "$PROBE" ] || fail "the double never played the session: $(head -c 600 "$RESULTS/journey.1.session1.jsonl")"
}

probe() { jq -r ".$1" <<< "$PROBE"; }

test_outer_sandbox_confines_the_session() {
  local farm="$RTMP/farm" d f n cmd status=0 out
  real_setup
  # Every program of PATH but bwrap and any claude: the run finds no outer sandbox.
  mkdir -p "$farm"
  while IFS= read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      n="${f##*/}"
      case "$n" in bwrap|claude) continue ;; esac
      [ -f "$f" ] && [ -x "$f" ] && [ ! -e "$farm/$n" ] && ln -s "$f" "$farm/$n"
    done
  done < <(tr ':' '\n' <<< "$PATH")
  cmd="$(printf '%q ' bash "$ROOT/bin/po-eval" real --repeat 1 journey)"
  printf 'y\n' | env -u CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" \
    CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$farm" SHELL=/bin/bash \
    script -qec "$cmd" /dev/null > "$RTMP/out" 2>&1 || status=$?
  out="$(tr -d '\r' < "$RTMP/out")"
  [ "$status" -eq 2 ] || fail "a run with no bwrap was not refused with exit 2 (exit $status): $out"
  grep -qw bwrap <<< "$out" || fail "the refusal does not name bwrap: $out"
  ! grep -qF 'Continue?' <<< "$out" || fail "the run reached its confirmation without its outer sandbox: $out"
  [ "$(calls)" -eq 0 ] || fail "claude was called with no outer sandbox to run in"

  outer_needs_bwrap
  real_setup
  outer_double
  outer_launch
  [ "$(probe root)" = bwrap ] || fail "the session does not run inside bwrap's own pid namespace: $PROBE"
  [ "$(probe inside)" = done ] || fail "the session cannot write inside its run folder: $PROBE"
}

test_claude_code_checks_off_inside() {
  local s args
  real_setup
  usable_build "$RTMP/off"
  s="$J/config/settings.json"
  jq -e 'has("sandbox") | not' "$s" > /dev/null || fail "Claude Code's sandbox is still configured: $(jq -c '.sandbox' "$s")"
  jq -e '(.permissions.allow // []) == []' "$s" > /dev/null || fail "an allow list is left: $(jq -c '.permissions.allow' "$s")"
  jq -e '[(.permissions.deny // [])[] | select(startswith("Bash"))] == []' "$s" > /dev/null \
    || fail "a Bash rule, git's exception included, is left: $(jq -c '.permissions.deny' "$s")"

  outer_needs_bwrap
  real_setup
  outer_double
  outer_launch
  args="$(jq -r '.args[]' <<< "$PROBE")"
  grep -qx -- --dangerously-skip-permissions <<< "$args" || grep -A1 -x -- --permission-mode <<< "$args" | grep -qx bypassPermissions \
    || fail "the session does not run with Claude Code's permission checks bypassed: $(tr '\n' ' ' <<< "$args")"
  grep -A1 -x -- --permission-prompts <<< "$args" | grep -qx none \
    || fail "a permission prompt could still wait for someone: $(tr '\n' ' ' <<< "$args")"
}

test_escape_is_tested() {
  outer_needs_bwrap
  real_setup
  outer_double
  outer_launch
  [ "$(probe inside)" = done ] || fail "the session cannot write inside its run folder, so nothing below proves a bound: $PROBE"
  [ "$(probe outside)" = refused ] && [ ! -e "$RTMP/outside/escaped" ] \
    || fail "the session wrote outside its run folder: $PROBE"
  [ "$(probe home)" = refused ] && [ ! -e "$RTMP/home/escaped" ] || fail "the session wrote in the person's HOME: $PROBE"
  [ "$(probe cred_home)" = unreadable ] || fail "the session read the login file of the person's HOME: $PROBE"
  [ "$(probe cred_config)" = unreadable ] || fail "the session read the login file of the person's Claude Code config: $PROBE"
  [ "$(probe login)" = set ] || fail "the login handed to the session did not reach it: $PROBE"
  ! grep -rqF person-login-s212 "$RESULTS" || fail "a login file of the person reached the kept results"
}
