# s206 — the real run of the journey repository, its grading and its control arms. Every launch here
# meets a claude double: no test of this file pays, and no real login is ever in its environment.
# A paid run needs a person at a terminal (d-0056), so the launches go through script(1)'s pseudo-terminal.

RTMP="$(mktemp -d)"
trap 'rm -rf "$RTMP"' EXIT
SENTINEL='sk-ant-sentinel-s206-0123456789abcdef'
RR_TOKEN=(ANTHROPIC_API_KEY="$SENTINEL")

# The claude double, first on PATH. It records how it was launched, one `key=value` per line and
# `---` after each call, then plays $FAKE_PLAY in the directory it was launched in. With
# $FAKE_PHRASE set, it plays only when the config it runs on still holds that phrase.
real_setup() {
  mkdir -p "$RTMP/bin" "$RTMP/tmp" "$RTMP/home" "$RTMP/cfg"
  rm -f "$RTMP/calls" "$RTMP/calls.played"
  cat > "$RTMP/bin/claude" <<'SH'
#!/usr/bin/env bash
po="$CLAUDE_CONFIG_DIR/polype/po"
digest() {
  (cd "$CLAUDE_CONFIG_DIR" && find agents commands skills -type f ! -path "${FAKE_PHRASE_FILE:-none}" -print0 \
    | sort -z | xargs -0 cksum | cksum)
}
present=-
[ -z "${FAKE_PHRASE:-}" ] || present="$(grep -cF -- "$FAKE_PHRASE" "$CLAUDE_CONFIG_DIR/$FAKE_PHRASE_FILE" || true)"
{
  printf 'cwd=%s\n' "$PWD"
  printf 'top=%s\n' "$(git rev-parse --show-toplevel 2>/dev/null)"
  printf 'cfg=%s\n' "$CLAUDE_CONFIG_DIR"
  printf 'login=%s\n' "${ANTHROPIC_API_KEY:+set}"
  printf 'bounds=%s\n' "$("$po" state 2>/dev/null | jq -r .bounds)"
  printf 'phrase=%s\n' "$present"
  printf 'digest=%s\n' "$(digest)"
  printf 'arg=%s\n' "$@"
  echo ---
} >> "$FAKE_CALLS"
play="${FAKE_PLAY:-none}"
[ "$present" != 0 ] || play=none
if [ -n "${FAKE_ONCE:-}" ]; then
  if [ -e "$FAKE_CALLS.played" ]; then play=none; else : > "$FAKE_CALLS.played"; fi
fi
land() {
  local id="$1" title
  title="$(sed -n "s/^### $id — //p" docs/stories.md | head -n 1)"
  mkdir -p docs/research docs/plans docs/verif docs/reviews
  printf '# Research — %s\n' "$id" > "docs/research/$id.md"
  printf -- '---\nvalidated: yes\n---\n# Plan — %s\n' "$id" > "docs/plans/$id.md"
  printf '# Verification — %s\n\nVerification status: complete\n' "$id" > "docs/verif/$id.md"
  printf 'Review status: complete\nFix loop: %s\n\nMax severity: minor\nShip allowed: yes\n' "${FAKE_LOOPS:-1}" > "docs/reviews/$id.md"
  git add -A && git -c user.name=double -c user.email=double@example.com commit -qm "$id: $title" \
    && git push -q origin HEAD:main
}
case "$play" in
  land-all) for id in $("$po" state | jq -r '.ready[]'); do land "$id"; done ;;
  land-first) land "$("$po" state | jq -r '.ready[0]')" ;;
esac
# What a model says it did is never a grade; an agent that prints its login is what the scrub is for.
printf '{"type":"result","total_cost_usd":0.01,"result":"All stories landed. %s"}\n' "${ANTHROPIC_API_KEY:-}"
SH
  chmod +x "$RTMP/bin/claude"
}

# real_launch <tty|pipe> <answer to the confirmation> <arguments of po-eval real…>. `tty` runs the
# command on a pseudo-terminal, as a person at a terminal does; `pipe` gives it no terminal at all.
real_launch() {
  local how="$1" answer="$2" cmd; shift 2
  cmd="$(printf '%q ' bash "$ROOT/bin/po-eval" real "$@")"
  RR_STATUS=0
  if [ "$how" = tty ]; then
    printf '%s\n' "$answer" | env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN ${RR_TOKEN[@]+"${RR_TOKEN[@]}"} \
      TMPDIR="$RTMP/tmp" HOME="$RTMP/home" CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" \
      PATH="$RTMP/bin:$PATH" SHELL=/bin/bash script -qec "$cmd" /dev/null > "$RTMP/out" 2>&1 || RR_STATUS=$?
  else
    printf '%s\n' "$answer" | env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN ${RR_TOKEN[@]+"${RR_TOKEN[@]}"} \
      TMPDIR="$RTMP/tmp" HOME="$RTMP/home" CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" \
      PATH="$RTMP/bin:$PATH" bash -c "$cmd" > "$RTMP/out" 2>&1 || RR_STATUS=$?
  fi
  RR_OUT="$(tr -d '\r' < "$RTMP/out")"
}

real_run() { real_launch tty "$@"; }

calls() { if [ -f "$RTMP/calls" ]; then grep -c '^---$' "$RTMP/calls"; else echo 0; fi; }

# field <call number> <key>: every value of <key> in that call, one per line.
field() {
  awk -v n="$1" -v k="$2=" 'BEGIN {c = 1} $0 == "---" {c++; next} c == n && index($0, k) == 1 {print substr($0, length(k) + 1)}' "$RTMP/calls"
}

# A body line of <file>, past its frontmatter, neither a heading nor its `Reads settings:` line,
# longer than 40 characters and without trailing blank,
# that occurs once in the file.
once_line() {
  awk 'NR == 1 && $0 == "---" {fm = 1; next} fm && $0 == "---" {fm = 0; next} fm {next}
    length($0) > 40 && $0 !~ /[[:space:]]$/ && $0 !~ /^(#|Reads settings:)/ {c[$0]++; o[++n] = $0}
    END {for (i = 1; i <= n; i++) if (c[o[i]] == 1) {print o[i]; exit}}' "$1"
}

# arm <name> <file under method/>: a declaration in the scratch dir that removes one phrase of that file.
arm() {
  local phrase
  phrase="$(once_line "$ROOT/method/$2")"
  [ -n "$phrase" ] || fail "no line of method/$2 occurs once"
  printf 'ARM_FILE=method/%s\nARM_PHRASE=%s\n' "$2" "$phrase" > "$RTMP/$1.arm"
  printf '%s\n' "$phrase"
}

method_listing() { (cd "$ROOT" && find method evals -type f -exec cksum {} + | sort); }

test_real_run_drives_the_journey_repository() {
  local uuid
  real_setup
  RR_TOKEN=()
  real_run y --repeat 1 journey
  [ "$RR_STATUS" -eq 2 ] && grep -qF ANTHROPIC_API_KEY <<< "$RR_OUT" && grep -qF CLAUDE_CODE_OAUTH_TOKEN <<< "$RR_OUT" \
    || fail "a real run without a login was not refused (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 0 ] || fail "claude was called without a login"
  RR_TOKEN=(ANTHROPIC_API_KEY="$SENTINEL")

  FAKE_PLAY=land-all real_launch pipe y --repeat 1 journey
  [ "$RR_STATUS" -eq 2 ] && grep -qF 'needs a terminal' <<< "$RR_OUT" && grep -qF 'nothing run' <<< "$RR_OUT" \
    || fail "a run with no terminal on its confirmation was not refused (exit $RR_STATUS): $RR_OUT"
  FAKE_PLAY=land-all real_launch pipe y --yes --repeat 1 journey
  [ "$RR_STATUS" -eq 2 ] || fail "an option skipped the attended confirmation (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 0 ] || fail "claude was called with no one at a terminal"

  FAKE_PLAY=land-all real_run n --repeat 1 journey
  [ "$RR_STATUS" -eq 1 ] && grep -qF '1 cases × 1 repetitions = 1 paid runs of claude -p' <<< "$RR_OUT" \
    && grep -qF 'nothing run' <<< "$RR_OUT" || fail "paid runs not announced, or declining went on (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 0 ] || fail "claude was called before the confirmation"

  FAKE_PLAY=land-all real_run y --repeat 1 journey
  [ "$RR_STATUS" -eq 0 ] || fail "the real run failed (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -ge 1 ] || fail "the lead was never launched"
  field 1 arg | grep -qx -- -p && field 1 arg | grep -qx /po-drive && field 1 arg | grep -qx -- --session-id \
    || fail "the lead was not launched as claude -p /po-drive with a session id: $(field 1 arg | tr '\n' ' ')"
  [ "$(field 1 cwd)" = "$(field 1 top)" ] || fail "the lead did not start at a repository root: $(field 1 cwd)"
  case "$(field 1 cwd)" in "$RTMP/tmp"/*) ;; *) fail "the repository is not a throwaway one under TMPDIR: $(field 1 cwd)" ;; esac
  case "$(field 1 cfg)" in "$RTMP/tmp"/*) ;; *) fail "the lead's config is not a temporary one: $(field 1 cfg)" ;; esac
  [ "$(field 1 bounds)" = held ] || fail "the lead ran where bounds are '$(field 1 bounds)'"
  [ "$(field 1 login)" = set ] || fail "the login did not reach claude through its environment"
  uuid="$(field 1 arg | grep -A1 -x -- --session-id | tail -n 1)"
  grep -qF "session: ${uuid:0:8}" <<< "$RR_OUT" || fail "the session po run recorded is not reported: $RR_OUT"
  [ "$(grep -cE '^story s[0-9]+-[a-z0-9-]+: landed — actions: research plan execute review ship — fix loops: 1$' <<< "$RR_OUT")" -ge 2 ] \
    || fail "each story is not reported landed with its actions and fix loops: $RR_OUT"
  grep -qx 'case journey run 1: pass' <<< "$RR_OUT" || fail "the run was not graded: $RR_OUT"
}

test_a_run_is_graded_by_scripts() {
  real_setup
  FAKE_PLAY=land-first FAKE_ONCE=1 FAKE_LOOPS=2 real_run y --repeat 1 --sessions 2 journey
  [ "$RR_STATUS" -eq 0 ] || fail "the real run failed (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 2 ] || fail "with work left and nothing waiting, the lead should run twice, not $(calls) times"
  field 2 arg | grep -qx -- --resume || fail "the second session did not resume the first: $(field 2 arg | tr '\n' ' ')"
  [ "$(grep -cE '^story s[0-9]+-[a-z0-9-]+: landed — actions: research plan execute review ship — fix loops: 2$' <<< "$RR_OUT")" -eq 1 ] \
    || fail "the landed story is not graded from its own files: $RR_OUT"
  [ "$(grep -cE '^story s[0-9]+-[a-z0-9-]+: not landed — ' <<< "$RR_OUT")" -ge 1 ] || fail "a story left behind is not reported: $RR_OUT"
  grep -qx 'case journey run 1: fail' <<< "$RR_OUT" || fail "a run the model calls complete was graded a pass: $RR_OUT"
}

test_suite_never_pays() {
  local f results
  for f in "$ROOT"/tests/*.sh; do
    grep -E 'bash +"[^"]*(po-eval|\$PE)"' "$f" | grep -vqE '"[[:space:]]+--(build|build-all|list|rules)([[:space:]]|$)' || continue
    grep -qE '/bin/claude"' "$f" || fail "${f#"$ROOT"/} launches po-eval with no claude double of its own"
  done

  real_setup
  FAKE_PLAY=land-all real_run y --repeat 1 --keep journey
  [ "$RR_STATUS" -eq 0 ] || fail "the real run failed (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -ge 1 ] && [ "$(field 1 login)" = set ] || fail "the double did not run with the login in its environment"
  results="$(sed -n 's/^results: //p' <<< "$RR_OUT" | head -n 1)"
  case "$results" in "$RTMP/tmp"/*) ;; *) fail "results kept outside TMPDIR: $results" ;; esac
  [ -d "$results" ] && [ "$(stat -c %a "$results")" = 700 ] || fail "the kept results are not a mode 700 folder: $results"
  [ -n "$(find "$results" -type f)" ] || fail "--keep kept nothing"
  ! grep -qF "$SENTINEL" <<< "$RR_OUT" || fail "the login was printed"
  ! grep -qF "$SENTINEL" "$RTMP/calls" || fail "the login reached claude's arguments"
  ! grep -rqF "$SENTINEL" "$results" || fail "the login is in a kept file: $(grep -rlF "$SENTINEL" "$results")"
}

test_any_rule_can_have_a_control_arm() {
  local phrase c1 c2
  real_setup
  phrase="$(arm t-drive commands/po-drive.md)"
  FAKE_PLAY=land-all FAKE_PHRASE="$phrase" FAKE_PHRASE_FILE=commands/po-drive.md \
    real_run y --repeat 1 --sessions 1 --model test-model --arm "$RTMP/t-drive.arm" journey
  [ "$RR_STATUS" -eq 0 ] || fail "the arm run failed (exit $RR_STATUS): $RR_OUT"
  grep -qF '1 cases × 1 repetitions × 2 arms = 2 paid runs of claude -p' <<< "$RR_OUT" || fail "the arms were not counted: $RR_OUT"
  [ "$(calls)" -eq 2 ] || fail "expected one rule run and one control run, got $(calls) calls"
  [ "$(printf '%s\n' "$(field 1 phrase)" "$(field 2 phrase)" | sort | tr '\n' ' ')" = '0 1 ' ] \
    || fail "one arm must hold the phrase and the other not: $(field 1 phrase) $(field 2 phrase)"
  [ "$(field 1 digest)" = "$(field 2 digest)" ] || fail "the two configs differ beyond the phrase's file"
  field 1 arg | grep -qx test-model && field 2 arg | grep -qx test-model || fail "the two arms did not run the same --model"
  c1="$(field 1 cfg)" c2="$(field 2 cfg)"
  [ "$c1" != "$c2" ] || fail "the two arms shared one config: $c1"
  [ ! -e "$c1" ] && [ ! -e "$c2" ] || fail "a temporary config survived the run"
  grep -qF 'journey: rule 1/1 | control t-drive 0/1' <<< "$RR_OUT" || fail "no rates side by side: $RR_OUT"
}

test_a_rule_that_moves_nothing_is_reported() {
  local phrase before line
  real_setup
  before="$(method_listing)"
  phrase="$(arm t-drive commands/po-drive.md)"
  arm t-inert skills/qa-drivers/SKILL.md > /dev/null
  FAKE_PLAY=land-all FAKE_PHRASE="$phrase" FAKE_PHRASE_FILE=commands/po-drive.md \
    real_run y --repeat 2 --sessions 1 --model test-model --arm "$RTMP/t-drive.arm" --arm "$RTMP/t-inert.arm" journey
  [ "$RR_STATUS" -eq 0 ] || fail "the arm run failed (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 6 ] || fail "expected 2 runs × 3 arms, got $(calls) calls"
  line="$(grep '^moved no rate:' <<< "$RR_OUT" | head -n 1)"
  grep -qw t-inert <<< "$line" && ! grep -qw t-drive <<< "$line" \
    || fail "the arm whose removal moved nothing is not the one listed: '$line' in $RR_OUT"
  [ "$(method_listing)" = "$before" ] || fail "the command changed method/ or evals/: it must retire nothing itself"
}

test_m21_bis_rules_have_their_cases() {
  local rules cases id line name out status=0
  real_setup
  rules="$(bash "$ROOT/bin/po-eval" real --rules)" || fail "po-eval real --rules failed"
  cases="$(bash "$ROOT/bin/po-eval" real --list)" || fail "po-eval real --list failed"
  for id in s201-H1 s201-H2 s201-H3 s201-H4 s201-H5 s202-H1 s202-H4 s202-H6 s202-H7 \
            s203-H1 s203-H2 s203-H3 s203-H4 s203-H5 s203-H6 s203-H7 s203-H8 s203-H9 s203-H10 \
            s204-H1 s204-H2 s204-H3 s204-H4 s204-H5 s204-H6 s204-H7 s204-H8 s204-H9; do
    line="$(grep -E "^$id: " <<< "$rules" | head -n 1)"
    case "$line" in
      "$id: case "*) name="${line#"$id: case "}"; name="${name%%[ ;]*}"
        grep -qx -- "$name" <<< "$cases" || fail "$id names the case '$name', which po-eval real --list does not know" ;;
      "$id: no case — "?*) ;;
      *) fail "$id has neither a case nor a reason in the registry: '$line'" ;;
    esac
  done
  out="$(env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN TMPDIR="$RTMP/tmp" HOME="$RTMP/home" CLAUDE_CONFIG_DIR="$RTMP/cfg" \
    FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$PATH" bash "$ROOT/bin/po-eval" real --build-all "$RTMP/built" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "some case does not build (exit $status): $out"
  while IFS= read -r name; do
    grep -qx "$name: built" <<< "$out" || fail "the case $name was not built: $out"
  done <<< "$cases"
  [ "$(calls)" -eq 0 ] || fail "building the cases called claude"
}
