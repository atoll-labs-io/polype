#!/usr/bin/env bash
# s160 — the oracle of the story: the issue title po-intake files, `<label>: <fingerprint>`, is cut at 80 characters
# without splitting one, a pytest line drops its assertion message, the other forms keep their title, and
# `po-gate findings-shape` on an unreadable review exits 2 saying so. `gh` is a stub first on PATH.

INTAKE="$METHOD/hooks/po-intake.sh"
GATE="$METHOD/hooks/po-gate.sh"

# A committed repository with `Issue tracker: github`, its origin on github.com, and a gh stub: `issue list` prints
# $LOG/open, `issue create` keeps its title as $LOG/created.<n>.title, every call is logged to $LOG/calls.
title_repo() {
  scratch_repo
  STUBS="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$STUBS"' EXIT
  LOG="$STUBS/log"
  mkdir -p "$STUBS/bin" "$LOG"
  cat > "$STUBS/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf 'gh %s\n' "$*" >> "$STUB_LOG/calls"
title="" args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do [ "${args[i]}" = --title ] && title="${args[i+1]}"; done
case "${1:-} ${2:-}" in
  "issue list") cat "$STUB_LOG/open" 2>/dev/null ;;
  "label list") echo polype-intake ;;
  "issue create")
    n=$(( $(cat "$STUB_LOG/n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_LOG/n"
    printf '%s' "$title" > "$STUB_LOG/created.$n.title" ;;
esac
exit 0
EOF
  chmod +x "$STUBS/bin/gh"
  export PATH="$STUBS/bin:$PATH" STUB_LOG="$LOG"
  cd "$SCRATCH"
  printf 'Issue tracker: github\n' > AGENTS.local.md
  git remote add origin https://github.com/acme/widget.git
  git add -A && git commit -qm base
}

# Runs po-intake on a check that prints $1 and exits 1; sets ERR to its stderr.
fail_with() {
  printf '%s\n' "$1" > "$STUBS/line"
  bash "$INTAKE" --label nightly -- "cat '$STUBS/line'; exit 1" >/dev/null 2>"$STUBS/err" </dev/null || true
  ERR="$(cat "$STUBS/err")"
}

last_title() { cat "$LOG/created.$(cat "$LOG/n" 2>/dev/null || echo 0).title" 2>/dev/null || true; }
repeat() { local s="" i; for ((i = 0; i < $2; i++)); do s+="$1"; done; printf '%s' "$s"; }

test_title_is_cut_at_80_characters() {
  title_repo
  local name want
  # 400 characters of test name, two bytes each past the ASCII head: a cut counted in bytes splits one.
  name="$(repeat a 10)$(repeat é 390)"
  fail_with "not ok 1 $name"
  want="nightly: $(repeat a 10)$(repeat é 61)"
  [ -n "$(last_title)" ] || fail "a 400-character failing line filed no issue: $ERR"
  case "$ERR" in *"nothing filed"*) fail "a 400-character failing line was not filed: $ERR" ;; esac
  [ "$(last_title)" = "$want" ] || fail "the title is not the first 80 characters: '$(last_title)'"
  # The 80th character is a space: it is trimmed, as GitHub trims it, so the exact compare still matches.
  fail_with "not ok 1 $(repeat b 70) $(repeat c 30)"
  [ "$(last_title)" = "nightly: $(repeat b 70)" ] || fail "a space left by the cut was kept: '$(last_title)'"
}

test_fingerprint_drops_the_assertion_message() {
  title_repo
  local first
  fail_with 'FAILED tests/test_a.py::test_b - assert 41 == 7'
  first="$(last_title)"
  [ "$first" = 'nightly: tests/test_a.py::test_b' ] || fail "the fingerprint kept the message: '$first'"
  printf '101\t%s\n' "$first" > "$LOG/open"; : > "$LOG/calls"
  fail_with 'FAILED tests/test_a.py::test_b - assert 42 == 7 at 0x7f3a'
  ! grep -q '^gh issue create' "$LOG/calls" || fail "a failure whose message alone changed was filed again"
  grep -qE '^gh issue comment 101( |$)' "$LOG/calls" || fail "the first issue was not commented: $(cat "$LOG/calls")"
}

test_existing_fingerprints_unchanged() {
  title_repo
  local cmd want n=0 eighty
  eighty="nightly: $(repeat z 71)"
  while IFS='|' read -r cmd want; do
    n=$((n + 1))
    bash "$INTAKE" --label nightly -- "$cmd" >/dev/null 2>&1 </dev/null || true
    [ "$(cat "$LOG/n" 2>/dev/null)" = "$n" ] || fail "for: $cmd — no issue filed"
    [ "$(last_title)" = "$want" ] || fail "for: $cmd — filed title '$(last_title)', want '$want'"
  done <<EOF
printf "ok 1 fine\nnot ok 2 parses dates\n"; exit 1|nightly: parses dates
printf "not ok 3 - parses times - twice\n"; exit 1|nightly: - parses times - twice
printf "collected 2\nFAILED tests/test_a.py::test_b\n"; exit 1|nightly: tests/test_a.py::test_b
printf "test parser::rejects_bad ... FAILED\n"; exit 101|nightly: parser::rejects_bad
printf "x.test.sh\n  ok    a\n  FAIL  b_breaks\n"; exit 1|nightly: b_breaks
echo boom; exit 3|nightly: 3
printf "not ok 1 $(repeat z 71)\n"; exit 1|$eighty
EOF
}

test_unreadable_review_exits_2() {
  scratch_repo
  local review="$SCRATCH/docs/reviews/s01-a.md" rc=0 err
  mkdir -p "$SCRATCH/docs/reviews"
  printf 'Review status: complete\n\n## Findings\n- minor — a.sh:1 — x\n\nShip allowed: yes\n' > "$review"
  chmod 000 "$review"
  if [ -r "$review" ]; then
    chmod 644 "$review"; echo "      running as root: a mode-000 file stays readable, nothing to check" >&2; return 0
  fi
  err="$(cd "$SCRATCH" && bash "$GATE" findings-shape s01-a 2>&1 >/dev/null)" || rc=$?
  chmod 644 "$review"
  [ "$rc" -eq 2 ] || fail "an unreadable review exits $rc, not 2: $err"
  case "$err" in *"cannot be read"*) ;; *) fail "the message does not say the review cannot be read: $err" ;; esac
  case "$err" in *"no verdict block"*|*"## Findings"*) fail "an unreadable review is reported as malformed: $err" ;; esac
}
