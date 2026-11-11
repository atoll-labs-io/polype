#!/usr/bin/env bash
# s151 — the implementer's tests of po-intake and po-gate redact, beside the oracle. `gh` and `task` are stubs first
# on PATH that only log their calls; secrets are assembled at run time.

INTAKE="$METHOD/hooks/po-intake.sh"
GATE="$METHOD/hooks/po-gate.sh"

# $1: the Issue tracker line, or "" for none; $2: the origin URL.
own_repo() {
  scratch_repo
  STUBS="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$STUBS"' EXIT
  mkdir -p "$STUBS/bin" "$STUBS/tmp"
  cat > "$STUBS/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf 'gh %s\n' "$*" >> "$STUB_CALLS"
case "${1:-} ${2:-}" in
  "issue list") [ -z "${GH_LIST_FAIL:-}" ] || { echo "HTTP 502" >&2; exit 1; } ;;
esac
exit 0
EOF
  printf '#!/usr/bin/env bash\nprintf "task %%s\\n" "$*" >> "$STUB_CALLS"\n' > "$STUBS/bin/task"
  chmod +x "$STUBS/bin/gh" "$STUBS/bin/task"
  export PATH="$STUBS/bin:$PATH" STUB_CALLS="$STUBS/calls" TMPDIR="$STUBS/tmp"
  cd "$SCRATCH"
  if [ -n "$1" ]; then printf '```\n%s\n```\n' "$1" > AGENTS.local.md; else printf '# Settings\n' > AGENTS.local.md; fi
  git remote add origin "$2"
  git add -A && git commit -qm base
}

run_intake() {
  CODE=0
  OUT="$(bash "$INTAKE" "$@" 2>"$STUBS/err" </dev/null)" || CODE=$?
  ERR="$(cat "$STUBS/err")"
}

stub_calls() { cat "$STUB_CALLS" 2>/dev/null || true; }
says() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

test_redact_keeps_near_miss_and_erases_each_token() {
  local a36 one two near out t
  REDACT_DIR="$(mktemp -d)"; trap 'rm -rf "$REDACT_DIR"' EXIT; t="$REDACT_DIR"
  a36="$(printf 'a%.0s' {1..36})"
  one="gh""p_$a36"; two="gh""o_$a36"; near="gh""p_0123456789"
  printf 'pair %s and %s end\nshort %s\n' "$one" "$two" "$near" > "$t/in"
  cp "$t/in" "$t/orig"
  out="$(bash "$GATE" redact "$t/in")" || fail "redact failed"
  [ "$(sed -n 1p <<< "$out")" = 'pair [redacted] and [redacted] end' ] || fail "two tokens on one line: $(sed -n 1p <<< "$out")"
  [ "$(sed -n 2p <<< "$out")" = "short $near" ] || fail "a match shorter than the minimum was redacted"
  cmp -s "$t/in" "$t/orig" || fail "redact changed the file"
  bash "$GATE" redact "$t/missing" >/dev/null 2>&1 && fail "redact of a missing file exited 0"
  return 0
}

test_missing_tracker_setting_files_nothing() {
  own_repo "" https://github.com/acme/widget.git
  run_intake --label nightly -- 'echo boom; exit 6'
  [ "$CODE" -eq 6 ] || fail "exit code $CODE, not the command's 6"
  says "$ERR" 'Issue tracker' || fail "stderr does not name the setting: $ERR"
  [ -z "$(stub_calls)" ] || fail "a missing setting reached a tracker: $(stub_calls)"
}

test_origin_off_github_files_nothing() {
  own_repo 'Issue tracker:     github' https://gitlab.com/acme/widget.git
  run_intake --label nightly -- 'printf "not ok 1 breaks\n"; exit 1'
  [ "$CODE" -eq 1 ] || fail "exit code $CODE"
  ! grep -q '^gh issue' <<< "$(stub_calls)" || fail "an origin off github.com reached gh: $(stub_calls)"
  says "$ERR" 'nightly: breaks' || fail "the report is not on stderr: $ERR"
}

test_failing_listing_files_nothing() {
  own_repo 'Issue tracker:     github' git@github.com:acme/widget.git
  export GH_LIST_FAIL=1
  run_intake --label nightly -- 'echo boom; exit 2'
  [ "$CODE" -eq 2 ] || fail "exit code $CODE"
  grep -q '^gh issue list --repo github.com/acme/widget ' <<< "$(stub_calls)" || fail "no listing: $(stub_calls)"
  ! grep -q '^gh issue create\|^gh issue comment' <<< "$(stub_calls)" || fail "filed after a failed listing: $(stub_calls)"
}

test_usage_error_refuses_before_running() {
  own_repo 'Issue tracker:     github' https://github.com/acme/widget.git
  run_intake --label nightly -- 'touch ran-one' 'touch ran-two'
  [ "$CODE" -eq 125 ] || fail "two command arguments exited $CODE, not 125"
  run_intake --label nightly 'touch ran-three'
  [ "$CODE" -eq 125 ] || fail "a missing -- exited $CODE, not 125"
  [ ! -e ran-one ] && [ ! -e ran-two ] && [ ! -e ran-three ] || fail "the command ran despite a usage error"
}
