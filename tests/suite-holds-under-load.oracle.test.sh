#!/usr/bin/env bash
# s215 — the oracle of the story: the journey run and the time bound of `po state` give the same
# verdict on a loaded machine as on an idle one. Load is simulated, never produced: a git that
# writes slowly stands for a writer that loses the CPU, a git that waits stands for a process
# waiting for one, so each case replays the same way on every machine.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-before-a-release.oracle.test.sh")

# slow_git <dir> <mode>: a git first on PATH in <dir>, wrapping the real one. `slow-log`: a `git log`
# writing to a pipe hands its lines one by one, 50 ms apart, as a starved writer does.
# `wait-once`: the first call made from $ROOT waits 1.1 s before running, as a process does that
# finds every core busy. Each slowed call appends one line to <dir>/slowed.
slow_git() {
  local dir="$1" mode="$2" real
  real="$(command -v git)"
  mkdir -p "$dir"
  : > "$dir/slowed"
  cat > "$dir/git" <<SH
#!/usr/bin/env bash
set -o pipefail
args=("\$@") i=0 sub=
while [ "\$i" -lt "\${#args[@]}" ]; do
  case "\${args[i]}" in -C|-c) i=\$((i + 2)) ;; -*) i=\$((i + 1)) ;; *) sub="\${args[i]}"; break ;; esac
done
if [ "$mode" = slow-log ] && [ "\$sub" = log ] && [ -p /dev/stdout ]; then
  echo log >> "$dir/slowed"
  "$real" "\$@" | while IFS= read -r line; do printf '%s\n' "\$line"; sleep 0.05; done
  exit
fi
if [ "$mode" = wait-once ] && [ "\$PWD" = "$ROOT" ] && [ ! -s "$dir/slowed" ]; then
  echo wait >> "$dir/slowed"
  sleep 1.1
fi
exec "$real" "\$@"
SH
  chmod +x "$dir/git"
}

landed_lines() { grep -cE '^story s[0-9]+-[a-z0-9-]+: landed — actions: research plan execute review ship — fix loops: 1$' <<< "$RR_OUT" || true; }

test_journey_run_holds_under_load() {
  slow_git "$RTMP/slow" slow-log
  real_setup
  PATH="$RTMP/slow:$PATH" FAKE_PLAY=land-all real_run y --repeat 1 journey
  [ -s "$RTMP/slow/slowed" ] || fail "no git log of the run met the slow writer, so nothing was simulated"
  [ "$RR_STATUS" -eq 0 ] || fail "the real run failed under a slow git (exit $RR_STATUS): $RR_OUT"
  [ "$(landed_lines)" -eq 2 ] || fail "under a slow git, each story is not reported landed: $RR_OUT"
  grep -qx 'case journey run 1: pass' <<< "$RR_OUT" || fail "under a slow git, the run was not graded a pass: $RR_OUT"

  real_setup
  PATH="$RTMP/slow:$PATH" FAKE_PLAY=land-first FAKE_ONCE=1 real_run y --repeat 1 journey
  grep -q '^story s02-farewell: not landed — ' <<< "$RR_OUT" \
    || fail "a story that never landed is not reported not landed under a slow git: $RR_OUT"
  [ "$(landed_lines)" -eq 1 ] && grep -q '^story s01-greeting: landed — ' <<< "$RR_OUT" \
    || fail "only the story that landed must be reported landed: $RR_OUT"
  grep -qx 'case journey run 1: fail' <<< "$RR_OUT" || fail "a run that left a story unlanded was not graded a fail: $RR_OUT"
}

# state_test <PATH prefix> <po>: runs s164's test_state_reads_only_files_and_git in its own process,
# as tests/run.sh does, with that PATH in front and that po; sets ST_STATUS and ST_OUT.
state_test() {
  ST_STATUS=0
  ST_OUT="$(cd "$ROOT/tests" && PATH="$1:$PATH" STATE_PO="$2" bash -c \
    'set -eu; source ./lib.sh; PO="$STATE_PO"; source ./state-as-json.oracle.test.sh; test_state_reads_only_files_and_git' 2>&1)" \
    || ST_STATUS=$?
}

test_state_time_bound_holds_under_load() {
  local t="$RTMP/state" fake
  slow_git "$t/wait" wait-once
  state_test "$t/wait" "$PO"
  [ -s "$t/wait/slowed" ] || fail "po state on this repository met no waiting git, so nothing was simulated"
  [ "$ST_STATUS" -eq 0 ] || fail "po state failed its test while it only waited for the machine: $ST_OUT"

  fake="$t/po-fetch"
  cat > "$fake" <<'SH'
#!/usr/bin/env bash
git ls-remote origin >/dev/null 2>&1 || true
printf '%s\n' '{"contract":1}'
SH
  chmod +x "$fake"
  state_test "$t/none" "$fake"
  [ "$ST_STATUS" -ne 0 ] && grep -qF 'ran a git command that writes or asks a remote' <<< "$ST_OUT" \
    || fail "a po state that asks a remote passed the test (exit $ST_STATUS): $ST_OUT"

  # Work, not waiting: the bound still holds po to under a second of its own and its children's CPU.
  fake="$t/po-burn"
  cat > "$fake" <<'SH'
#!/usr/bin/env bash
f="$(mktemp)"
while :; do
  for _ in {1..20000}; do :; done
  times > "$f"; read -r u s < "$f"
  u="${u//[^0-9]/}" s="${s//[^0-9]/}"
  [ $((10#$u + 10#$s)) -lt 1200 ] || break
done
rm -f "$f"
printf '%s\n' '{"contract":1}'
SH
  chmod +x "$fake"
  state_test "$t/none" "$fake"
  [ "$ST_STATUS" -ne 0 ] && grep -qF 'not under a second' <<< "$ST_OUT" \
    || fail "a po state that works more than a second passed the test (exit $ST_STATUS): $ST_OUT"
}
