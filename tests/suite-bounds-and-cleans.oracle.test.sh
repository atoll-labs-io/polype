#!/usr/bin/env bash
# s219 — the oracle of the story: the last real-time bounds of the suite hold on a loaded machine and
# keep what they prove, a po that blocks without computing is still caught, and no folder made by
# scratch_repo outlives its test. Load and blocking are simulated by a double standing for po, so each
# case replays the same way on every machine.

# po_double <path> <mode>: a po first in line for the test under check, wrapping the real one.
# `wait`: `po inbox` and `po next` wait 1.1 s before running, as a process does that finds every core
# busy. `burn`: every call spends 1.2 s of CPU, then runs. `block`: `po state` run from $ROOT sleeps a
# minute without computing; any other call runs.
po_double() {
  cat > "$1" <<SH
#!/usr/bin/env bash
case "$2" in
  wait) case "\$*" in inbox|next) sleep 1.1 ;; esac ;;
  block) [ "\$PWD" = "$ROOT" ] && [ "\$*" = state ] && exec sleep 60 ;;
  burn)
    f="\$(mktemp)"
    while :; do
      for _ in {1..20000}; do :; done
      times > "\$f"; read -r u s < "\$f"
      u="\${u//[^0-9]/}" s="\${s//[^0-9]/}"
      [ \$((10#\$u + 10#\$s)) -lt 1200 ] || break
    done
    rm -f "\$f" ;;
esac
exec "$PO" "\$@"
SH
  chmod +x "$1"
}

# own_test <po> <file> <test>: runs <test> of tests/<file> in its own process, as tests/run.sh does,
# with that po; sets OT_STATUS, OT_OUT and OT_MS, the wall time of the whole run.
own_test() {
  local start
  start="$(date +%s%N)"
  OT_STATUS=0
  OT_OUT="$(cd "$ROOT/tests" && OWN_PO="$1" bash -c \
    "set -eu; source ./lib.sh; PO=\"\$OWN_PO\"; source './$2'; $3" 2>&1)" || OT_STATUS=$?
  OT_MS=$(( ($(date +%s%N) - start) / 1000000 ))
}

doubles_dir() { S219_TMP="$(mktemp -d)"; trap 'rm -rf "$S219_TMP"' EXIT; }

test_bounds_hold_under_load() {
  doubles_dir
  po_double "$S219_TMP/po-wait" wait
  po_double "$S219_TMP/po-burn" burn
  local pair file name
  for pair in decision-inbox.oracle.test.sh:test_list_prints_pending_oldest_first \
              driver-next-action.test.sh:test_next_on_this_repository_is_fast_and_writes_nothing; do
    file="${pair%%:*}" name="${pair#*:}"
    own_test "$S219_TMP/po-wait" "$file" "$name"
    [ "$OT_STATUS" -eq 0 ] || fail "$name failed while po only waited for the machine: $OT_OUT"
    own_test "$S219_TMP/po-burn" "$file" "$name"
    [ "$OT_STATUS" -ne 0 ] && grep -qF 'not under a second' <<< "$OT_OUT" \
      || fail "$name passed a po that works more than a second (exit $OT_STATUS): $OT_OUT"
  done
}

test_blocking_state_is_caught() {
  doubles_dir
  po_double "$S219_TMP/po-block" block
  own_test "$S219_TMP/po-block" state-as-json.oracle.test.sh test_state_reads_only_files_and_git
  [ "$OT_STATUS" -ne 0 ] && grep -qF 'did not answer within 10 s' <<< "$OT_OUT" \
    || fail "a po state that blocks without computing was not caught by the 10 s cap (exit $OT_STATUS): $OT_OUT"
  [ "$OT_MS" -lt 30000 ] || fail "the test waited ${OT_MS} ms for a blocked po state instead of stopping it at 10 s"
}

test_suite_leaves_no_scratch() {
  local t left
  S219_TMP="$(mktemp -d)"; t="$S219_TMP"
  trap 'rm -rf "$S219_TMP"' EXIT
  mkdir "$t/several" "$t/failing" "$t/framing"
  (cd "$ROOT/tests" && TMPDIR="$t/several" bash -c 'set -eu; source ./lib.sh; scratch_repo; scratch_repo; scratch_repo') \
    || fail "three scratch_repo calls in one process did not run"
  if (cd "$ROOT/tests" && TMPDIR="$t/failing" bash -c 'set -eu; source ./lib.sh; scratch_repo; scratch_repo; fail stop' 2>/dev/null); then
    fail "a test ending in fail exited 0"
  fi
  (cd "$ROOT/tests" && TMPDIR="$t/framing" bash -c \
    'set -eu; source ./lib.sh; source ./state-as-json.test.sh; test_framing_next_follows_the_stage' >/dev/null 2>&1) \
    || fail "test_framing_next_follows_the_stage failed with its own TMPDIR"
  left="$(find "$t/several" "$t/failing" "$t/framing" -mindepth 1 -maxdepth 1)"
  [ -z "$left" ] || fail "folders made by scratch_repo outlived their test: $left"
}
