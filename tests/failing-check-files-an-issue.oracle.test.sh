#!/usr/bin/env bash
# s151 — the oracle of the story: `po-intake --label <name> [--sensitive] -- '<command>'` runs a scheduled check and,
# when it fails, files one scrubbed, deduplicated issue in `Issue tracker`, or hands a sensitive failure to the person.
# Every secret is assembled at run time, so no literal one ever sits in this file. `gh` and `task` are stubs first on
# PATH: no test reaches a real tracker.

INTAKE="$METHOD/hooks/po-intake.sh"
GATE="$METHOD/hooks/po-gate.sh"
DOCTRINE="$METHOD/skills/testing-doctrine/SKILL.md"
RULES="$METHOD/AGENTS.md"
HARNAIS="$ROOT/docs/harnais.md"

flat_section() { awk -v h="$2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
holds() { has "$1" "$2" || fail "$3 lacks: $2"; }

set_tracker() { printf '# Settings\n\n```\nIssue tracker:     %s\n```\n' "$1" > "$SCRATCH/AGENTS.local.md"; }

# A committed repository whose origin is on github.com, with the given Issue tracker, and gh/task stubs that log
# every call to $LOG/calls. gh: `issue list` prints $LOG/open (lines `<number>\t<title>`), `label list` prints
# $LOG/labels, `issue create` keeps its title and body as $LOG/created.<n>.title|body, `issue comment` its body.
# task: `_uuids` prints $LOG/task-open, `add` prints a uuid, `annotate` keeps its last argument in $LOG/annotation.
intake_repo() {
  scratch_repo
  STUBS="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$STUBS"' EXIT
  LOG="$STUBS/log"
  mkdir -p "$STUBS/bin" "$LOG" "$STUBS/tmp"
  cat > "$STUBS/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf 'gh %s\n' "$*" >> "$STUB_LOG/calls"
title="" body="" args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[i]}" in --title) title="${args[i+1]}" ;; --body-file) body="${args[i+1]}" ;; esac
done
case "${1:-} ${2:-}" in
  "auth status") exit 0 ;;
  "issue list") cat "$STUB_LOG/open" 2>/dev/null; exit 0 ;;
  "label list") cat "$STUB_LOG/labels" 2>/dev/null; exit 0 ;;
  "issue create")
    n=$(( $(cat "$STUB_LOG/n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_LOG/n"
    printf '%s' "$title" > "$STUB_LOG/created.$n.title"; cp "$body" "$STUB_LOG/created.$n.body"
    echo "https://github.com/acme/widget/issues/$((100 + n))" ;;
  "issue comment") cp "$body" "$STUB_LOG/comment.body" ;;
esac
exit 0
EOF
  cat > "$STUBS/bin/task" <<'EOF'
#!/usr/bin/env bash
printf 'task %s\n' "$*" >> "$STUB_LOG/calls"
case " $* " in
  *" _uuids "*) cat "$STUB_LOG/task-open" 2>/dev/null ;;
  *" add "*) echo "Created task 0c1d2e3f-0000-4000-8000-000000000001." ;;
  *" annotate "*) printf '%s' "${@: -1}" > "$STUB_LOG/annotation" ;;
esac
exit 0
EOF
  chmod +x "$STUBS/bin/gh" "$STUBS/bin/task"
  export PATH="$STUBS/bin:$PATH" STUB_LOG="$LOG" TMPDIR="$STUBS/tmp"
  cd "$SCRATCH"
  set_tracker "$1"
  git remote add origin https://github.com/acme/widget.git
  git add -A && git commit -qm base
  SHA="$(git rev-parse HEAD)"
  REPO="$(pwd -P)"
}

# Runs po-intake with the given arguments and no stdin; sets CODE, OUT (its stdout) and ERR (its stderr).
intake() {
  CODE=0
  OUT="$(bash "$INTAKE" "$@" 2>"$STUBS/err" </dev/null)" || CODE=$?
  ERR="$(cat "$STUBS/err")"
}

calls() { cat "$LOG/calls" 2>/dev/null || true; }
last_title() { cat "$LOG/created.$(cat "$LOG/n").title"; }
last_body() { cat "$LOG/created.$(cat "$LOG/n").body"; }

test_intake_passes_through() {
  intake_repo github
  mkdir -p sub/deeper && cd sub/deeper
  intake --label nightly -- 'pwd -P; echo to-stderr >&2; exit 0'
  [ "$CODE" -eq 0 ] || fail "a passing check exited $CODE through po-intake: $ERR"
  [ "$OUT" = "$REPO" ] || fail "the command did not run from the repository root, or po-intake wrote to stdout: $OUT"
  has "$ERR" 'to-stderr' || fail "the command's stderr did not pass through: $ERR"
  [ -z "$(calls)" ] || fail "a passing check reached a tracker: $(calls)"
  intake --label nightly -- 'echo partial-output; exit 7'
  [ "$CODE" -eq 7 ] || fail "the exit code of a failing check was not passed through: $CODE"
  has "$OUT" 'partial-output' || fail "the output of a failing check did not pass through: $OUT"
}

test_sensitive_failure_goes_to_the_person() {
  intake_repo github
  local tok path="" row
  intake --label fuzz --sensitive -- 'echo crash-input-0042; exit 2'
  [ "$CODE" -eq 2 ] || fail "a sensitive failure exited $CODE, not the command's 2"
  ! grep -q '^gh issue\|^task ' <<< "$(calls)" || fail "a sensitive failure reached a tracker: $(calls)"
  while IFS= read -r tok; do
    tok="${tok%[.,;:)]}"
    [ -f "$tok" ] && { path="$tok"; break; }
  done < <(grep -oE '/[^[:space:]]+' <<< "$ERR")
  [ -n "$path" ] || fail "po-intake named no report file on stderr: $ERR"
  case "$(cd "$(dirname "$path")" && pwd -P)/" in "$REPO"/*) fail "the report was written inside the repository: $path" ;; esac
  grep -qF crash-input-0042 "$path" || fail "the report does not hold the failure: $path"
  row="$(grep -F '| Long fuzzing or simulation campaign |' "$DOCTRINE" || true)"
  holds "$row" 'a fuzzing campaign, or any check that exercises a decoder of input from outside, runs with `--sensitive`' \
    "the doctrine's long campaign row"
  holds "$row" '`po-intake`' "the doctrine's long campaign row"
}

test_failure_files_one_issue() {
  intake_repo github
  local cmd want body
  while IFS='|' read -r cmd want; do
    intake --label nightly -- "$cmd"
    [ "$(last_title 2>/dev/null)" = "$want" ] || fail "for: $cmd — filed title '$(last_title 2>/dev/null)', want '$want'"
  done <<'EOF'
printf "ok 1 fine\nnot ok 2 parses dates\nnot ok 3 later one\n"; exit 1|nightly: parses dates
printf "collected 2\nFAILED tests/test_a.py::test_b\n"; exit 1|nightly: tests/test_a.py::test_b
printf "test parser::rejects_bad ... FAILED\n"; exit 101|nightly: parser::rejects_bad
printf "x.test.sh\n  ok    a\n  FAIL  b_breaks\n"; exit 1|nightly: b_breaks
echo boom; exit 3|nightly: 3
EOF
  cmd='printf "%s\n" "not ok 1 odd \$(touch pwned) \`touch pwned2\` it"; exit 1'
  intake --label nightly -- "$cmd"
  [ "$(last_title)" = 'nightly: odd $(touch pwned) `touch pwned2` it' ] || fail "an odd title was altered: $(last_title)"
  [ ! -e "$REPO/pwned" ] && [ ! -e "$REPO/pwned2" ] || fail "the failing test's name ran as a command"
  cmd='for i in $(seq 1 300); do echo "line-$i"; done; exit 4'
  intake --label nightly -- "$cmd"
  [ "$(last_title)" = 'nightly: 4' ] || fail "a failure with no test form is not titled by its exit code: $(last_title)"
  body="$(last_body)"
  holds "$body" "$SHA" "the body"
  holds "$body" "$cmd" "the body"
  holds "$body" 'Exit code: 4' "the body"
  grep -qx 'line-300' <<< "$body" || fail "the body lacks the end of the output"
  ! grep -qx 'line-100' <<< "$body" || fail "the body holds more than the last 200 lines of output"
  [ "$(grep -c '^line-' <<< "$body")" -le 200 ] || fail "the body holds more than 200 lines of output"
  [ "$(cat "$LOG/n")" -eq 7 ] || fail "seven failures did not file seven issues: $(cat "$LOG/n")"
}

test_secrets_are_scrubbed() {
  intake_repo github
  local d='-----' a36 b24 tok pem_begin pem_end desk body v out
  a36="$(printf 'a%.0s' {1..36})"; b24="$(printf 'b%.0s' {1..24})"
  tok="gh""p_$a36"; desk="desk_live_$b24"
  pem_begin="${d}BEGIN RSA PRIV""ATE KEY${d}"; pem_end="${d}END RSA PRIV""ATE KEY${d}"
  printf 'before-pem\n%s\nMIIEsecretbodyline1\nsecretbodyline2\n%s\nafter-pem\ntoken=%s\nenv=%s\nkeep=%s\n' \
    "$pem_begin" "$pem_end" "$tok" 'envsecretvalue42' "$desk" > "$STUBS/leak.txt"
  export INTAKE_DEPLOY_TOKEN=envsecretvalue42
  intake --label nightly -- "cat '$STUBS/leak.txt'; exit 1"
  body="$(last_body)"
  for v in MIIEsecretbodyline1 secretbodyline2 "$tok" envsecretvalue42 'BEGIN RSA'; do
    ! has "$body" "$v" || fail "the filed body still holds: $v"
  done
  for v in before-pem after-pem "$desk" '[redacted]'; do holds "$body" "$v" "the filed body"; done

  printf 'before-open\n%s\nunendedbody\nmore-unended\n' "$pem_begin" > "$STUBS/open.txt"
  out="$(bash "$GATE" redact "$STUBS/open.txt")" || fail "po-gate redact failed"
  has "$out" before-open || fail "redact dropped what precedes the key: $out"
  ! has "$out" unendedbody && ! has "$out" more-unended || fail "a key with no END line was not erased to the end: $out"

  [ "$(grep -c 'gh\[pousr\]_' "$GATE")" -eq 1 ] || fail "po-gate.sh does not hold the token list exactly once"
  ! grep -qE 'gh\[pousr\]|AKIA|sk-ant-' "$INTAKE" || fail "po-intake.sh copies the secret list"
  awk -v q="'" '!done && index($0, "SECRET_PATTERNS=" q) == 1 {
      print "SECRET_PATTERNS=" q "zz-probe|8|ZZQ[0-9]+"; $0 = substr($0, length("SECRET_PATTERNS=" q) + 1); done = 1 }
    { print }' "$GATE" > "$STUBS/po-gate.sh"
  grep -qF 'zz-probe' "$STUBS/po-gate.sh" || fail "SECRET_PATTERNS is no longer defined in po-gate.sh"
  printf 'x ZZQ12345678 y\n' > "$STUBS/probe.txt"
  out="$(bash "$STUBS/po-gate.sh" redact "$STUBS/probe.txt")" || fail "the probed po-gate redact failed"
  ! has "$out" ZZQ12345678 || fail "redact does not read SECRET_PATTERNS: a line added to it was not redacted"
}

test_same_failure_not_filed_twice() {
  intake_repo github
  printf '17\tnightly: parses dates\n18\tnightly: parses dates later\n' > "$LOG/open"
  printf 'polype-intake\n' > "$LOG/labels"
  intake --label nightly -- 'printf "not ok 1 parses dates\n"; exit 1'
  [ "$CODE" -eq 1 ] || fail "the exit code was not passed through: $CODE"
  ! grep -q '^gh issue create' <<< "$(calls)" || fail "a failure already open was filed a second time"
  grep -qE '^gh issue comment 17( |$)' <<< "$(calls)" || fail "no comment on the open issue 17: $(calls)"
  holds "$(cat "$LOG/comment.body")" "$SHA" "the comment"
  holds "$(cat "$LOG/comment.body")" "$(date -u +%F)" "the comment"
}

test_tracker_values_hold() {
  intake_repo github
  intake --label nightly -- 'echo boom; exit 3'
  grep -q '^gh label create polype-intake' <<< "$(calls)" || fail "the missing label was not created: $(calls)"
  grep -q '^gh issue create .*--label polype-intake' <<< "$(calls)" || fail "the issue lacks the label: $(calls)"
  ! grep -q '^gh api' <<< "$(calls)" || fail "po-intake called gh api"
  ! grep -qE '(^|[^A-Za-z])(curl|wget)([^A-Za-z]|$)' "$INTAKE" || fail "po-intake makes a direct HTTP call"
  printf 'polype-intake\n' > "$LOG/labels"; : > "$LOG/calls"
  intake --label nightly -- 'echo boom; exit 5'
  ! grep -q '^gh label create' <<< "$(calls)" || fail "an existing label was created again"

  set_tracker taskwarrior; : > "$LOG/calls"
  intake --label nightly -- 'echo boom; exit 3'
  [ "$CODE" -eq 3 ] || fail "taskwarrior: exit code $CODE"
  grep -E '^task .* add ' <<< "$(calls)" | grep -F 'project:widget' | grep -F '+issue' | grep -qF '+polype-intake' \
    || fail "no task in project:widget tagged +issue +polype-intake: $(calls)"
  grep -q '^task .*annotate' <<< "$(calls)" || fail "the task was not annotated with the body"
  holds "$(cat "$LOG/annotation")" "$SHA" "the annotation"
  ! grep -q '^gh ' <<< "$(calls)" || fail "taskwarrior reached gh"

  set_tracker '—'; : > "$LOG/calls"
  intake --label nightly -- 'echo boom; exit 3'
  [ "$CODE" -eq 3 ] || fail "—: exit code $CODE"
  [ -z "$(calls)" ] || fail "— reached a tracker: $(calls)"
  holds "$ERR" 'nightly: 3' "the report on stderr"
  holds "$ERR" 'Exit code: 3' "the report on stderr"
}

test_rules_name_po_intake() {
  local files law harnais p
  files="$(flat_section "$RULES" '## Installed files')"
  holds "$files" '`.polype/hooks/po-intake.sh`, called `po-intake`' "## Installed files"
  law="$(flat_section "$RULES" '## Law 7 — Defects are not stories')"
  holds "$law" '`po-intake` files, as the lead does, the failure of a scheduled check that is not sensitive' "Law 7"
  require_file "$HARNAIS"
  harnais="$(cat "$HARNAIS")"
  for p in '# Le harnais' 'po-intake --label' 'schedule:' 'cron:' '[Timer]' 'OnCalendar='; do
    holds "$harnais" "$p" "docs/harnais.md"
  done
}
