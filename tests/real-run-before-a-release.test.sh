# s206 — task tests of po-eval real: refusals, the build, the predicates, arms and the record. Every
# launch meets the oracle's claude double; no test here pays or reads a real login.

source <(sed '/^test_/,$d' "$ROOT/tests/real-run-before-a-release.oracle.test.sh")

# real_build <case> <dir>: po-eval real --build with a made-up login in the environment.
real_build() {
  env ANTHROPIC_API_KEY="$SENTINEL" CLAUDE_CODE_OAUTH_TOKEN="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" \
    CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" PATH="$RTMP/bin:$PATH" \
    bash "$ROOT/bin/po-eval" real --build "$1" "$2" 2>&1
}

refused_before_any_call() {
  [ "$RR_STATUS" -eq 2 ] || fail "$1 was not refused with exit 2 (exit $RR_STATUS): $RR_OUT"
  grep -qF -- "$2" <<< "$RR_OUT" || fail "$1: the refusal does not say '$2': $RR_OUT"
  ! grep -qF 'Continue?' <<< "$RR_OUT" || fail "$1 reached the confirmation"
  [ "$(calls)" -eq 0 ] || fail "$1: claude was called"
}

test_bad_arm_refused_before_any_call() {
  real_setup
  real_run y --arm no-such-arm-s206 journey
  refused_before_any_call "an unknown arm" 'unknown arm: no-such-arm-s206'
  printf 'ARM_FILE=bin/po-eval\nARM_PHRASE=po-eval\n' > "$RTMP/outside.arm"
  real_run y --arm "$RTMP/outside.arm" journey
  refused_before_any_call "an arm outside method/" 'arm outside: ARM_FILE must name a file under method/'
  printf 'ARM_FILE=method/commands/po-drive.md\n' > "$RTMP/empty.arm"
  real_run y --arm "$RTMP/empty.arm" journey
  refused_before_any_call "an arm with no phrase" 'arm empty declares no ARM_PHRASE'
  real_run y no-such-case-s206
  refused_before_any_call "an unknown case" 'unknown case: no-such-case-s206'
  real_run y --skip-confirmation journey
  refused_before_any_call "an unknown option" 'unknown option --skip-confirmation'
}

test_arm_phrase_found_once() {
  local phrase
  real_setup
  phrase="$(sed -n 's/^ARM_PHRASE=//p' "$ROOT/evals/arms/reuse-ladder.arm")"
  [ "$(grep -cxF -- "$phrase" "$ROOT/method/skills/review-antihallu/SKILL.md")" -eq 1 ] \
    || fail "reuse-ladder.arm does not hold the whole reuse line of review-antihallu"
  printf 'ARM_FILE=method/commands/po-drive.md\nARM_PHRASE=no such phrase in po-drive s206\n' > "$RTMP/gone.arm"
  real_run y --arm "$RTMP/gone.arm" journey
  refused_before_any_call "a phrase that is gone" 'arm gone: its phrase occurs 0 times in method/commands/po-drive.md'
  # A dot is one character as a fixed string, and occurs far more than once.
  printf 'ARM_FILE=method/commands/po-drive.md\nARM_PHRASE=.\n' > "$RTMP/dot.arm"
  real_run y --arm "$RTMP/dot.arm" journey
  refused_before_any_call "a phrase found many times" 'arm dot: its phrase occurs'
  FAKE_PLAY=land-all real_run n --arm reuse-ladder journey
  [ "$RR_STATUS" -eq 1 ] && grep -qF '1 cases × 1 repetitions × 2 arms = 2 paid runs of claude -p' <<< "$RR_OUT" \
    || fail "the reuse-ladder arm, found once, was not counted (exit $RR_STATUS): $RR_OUT"
}

test_build_holds_no_login() {
  local out dir="$RTMP/built" state
  real_setup
  out="$(real_build journey "$dir")" || fail "po-eval real --build journey failed: $out"
  [ "$(tail -n 1 <<< "$out")" = "$(cd "$dir" && pwd -P)/project" ] || fail "--build did not print the repository: $out"
  state="$(cd "$dir/project" && CLAUDE_CONFIG_DIR="$dir/config" "$dir/config/polype/po" state)" || fail "po state failed: $state"
  [ "$(jq -r .bounds <<< "$state")" = held ] || fail "bounds are not held in the built repository: $state"
  [ "$(jq -r '.ready | join(" ")' <<< "$state")" = 's01-greeting s02-farewell' ] || fail "the two stories are not ready: $state"
  grep -qx 'Plan validation: autonomous' "$dir/project/AGENTS.local.md" && grep -qx 'Flow threshold: 2' "$dir/project/AGENTS.local.md" \
    || fail "the journey settings were not written"
  [ "$(git -C "$dir/project" config remote.origin.url)" = https://github.com/acme/project.git ] \
    && git -C "$dir/project" ls-remote origin main 2>&1 | grep -q refs/heads/main \
    || fail "the bare origin does not answer for github.com/acme/project: $(git -C "$dir/project" ls-remote origin main 2>&1)"
  jq -e '.permissions.deny as $d | ["WebFetch", "WebSearch", "Bash(curl:*)", "Bash(claude:*)"] | all(. as $x | $d | index($x))' \
    "$dir/config/settings.json" > /dev/null || fail "the run's config does not deny web tools, curl and claude: $(cat "$dir/config/settings.json")"
  [ -L "$dir/bin/claude" ] && [ -L "$dir/bin/curl" ] || fail "claude and curl are not doubled on the run's PATH"
  ! grep -rqF "$SENTINEL" "$dir" || fail "the login is in a built file: $(grep -rlF "$SENTINEL" "$dir")"
  [ "$(calls)" -eq 0 ] || fail "building called claude"
}

test_predicates_read_the_repository() {
  local dir="$RTMP/pred" title out
  real_setup
  out="$(real_build journey "$dir")" || fail "po-eval real --build journey failed: $out"
  J="$(cd "$dir" && pwd -P)" R="$J/project" PO="$J/config/polype/po"
  export CLAUDE_CONFIG_DIR="$J/config" JOURNEY_DIR="$J" PO_CLAUDE="$ROOT/evals/real/claude-print"
  source "$ROOT/evals/real/grade.sh"
  grade_load
  pred_main_unchanged && pred_stories_unchanged && pred_not_landed all && pred_absent docs/brief.md \
    && pred_branch_absent 'story/*' && pred_no_unexpected_call && ! pred_pending any && ! pred_landed s01 \
    || fail "a predicate is wrong on the repository as built"

  title="$(grade_title s01-greeting)"
  mkdir -p "$R/docs/plans" "$R/docs/reviews"
  printf -- '---\nvalidated: yes\n---\n# Plan\n' > "$R/docs/plans/s01-greeting.md"
  printf 'Review status: complete\nFix loop: 2\n\nMax severity: minor\nShip allowed: yes\n' > "$R/docs/reviews/s01-greeting.md"
  git -C "$R" add -A && git -C "$R" commit -qm "s01-greeting: $title" && git -C "$R" push -q origin HEAD:main
  (cd "$R" && "$PO" inbox add > /dev/null) <<'EOF' || fail "po inbox add failed"
{"motive": "stop", "question": "Go on with s02?",
 "options": [{"key": "a", "label": "Yes", "consequence": "x"}, {"key": "b", "label": "No", "consequence": "y"}],
 "recommended": "a", "why": "nothing else waits", "reversible": true, "blocks": ["s02-farewell"]}
EOF
  echo 'curl: https://example.invalid' >> "$J/calls/unexpected"
  grade_load
  pred_landed s01 && pred_not_landed s02 && ! pred_main_unchanged && pred_track s01 full && ! pred_track s01 flow \
    && pred_pending s02 && ! pred_pending s01 && ! pred_no_unexpected_call && pred_section_unchanged s01 \
    || fail "a predicate did not follow the repository"
  [ "$(grade_story_line s01-greeting)" = 'story s01-greeting: landed — actions: plan review ship — fix loops: 2' ] \
    || fail "the landed story line is not read from its commit: $(grade_story_line s01-greeting)"
  [ "$(grade_story_line s02-farewell)" = 'story s02-farewell: not landed — stage: none — waiting: d-0001' ] \
    || fail "the story left behind does not name its decision: $(grade_story_line s02-farewell)"

  sed -i 's/^### s02-farewell — .*/### s02-farewell — Un autre titre/' "$R/docs/stories.md"
  git -C "$R" commit -qam 'reword s02' && git -C "$R" push -q origin HEAD:main
  grade_load
  ! pred_section_unchanged s02 && ! pred_stories_unchanged && pred_section_unchanged s01 \
    || fail "a changed story section was not seen"
}

test_record_holds_no_transcript() {
  local copy="$RTMP/checkout" record
  real_setup
  mkdir -p "$copy/tests"
  cp -R "$ROOT/bin" "$ROOT/method" "$ROOT/evals" "$copy/"
  cp -R "$ROOT/tests/journey" "$copy/tests/"
  ln -s "$ROOT/po" "$copy/po"
  git -C "$copy" init -q -b main && git -C "$copy" add -A \
    && git -C "$copy" -c user.name=t -c user.email=t@example.com commit -qm checkout || fail "cannot commit the copy"
  echo '# stray' >> "$copy/evals/real/stories.md"
  record_run() {
    local cmd
    cmd="$(printf '%q ' bash "$copy/bin/po-eval" real "$@")"
    RR_STATUS=0
    printf 'y\n' | env -u CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY="$SENTINEL" TMPDIR="$RTMP/tmp" HOME="$RTMP/home" \
      CLAUDE_CONFIG_DIR="$RTMP/cfg" FAKE_CALLS="$RTMP/calls" FAKE_PLAY=land-all PATH="$RTMP/bin:$PATH" SHELL=/bin/bash \
      script -qec "$cmd" /dev/null > "$RTMP/out" 2>&1 || RR_STATUS=$?
    RR_OUT="$(tr -d '\r' < "$RTMP/out")"
  }
  record_run --record journey
  refused_before_any_call "--record on a changed evals/" 'commit or set aside the changes first'
  git -C "$copy" checkout -q -- evals/real/stories.md
  record_run --record journey
  [ "$RR_STATUS" -eq 0 ] || fail "the recorded run failed (exit $RR_STATUS): $RR_OUT"
  record="$(find "$copy/docs/evals" -name 'real-*-v*.md' 2>/dev/null | head -n 1)"
  [ -n "$record" ] || fail "no record was written: $RR_OUT"
  grep -qF 'No transcript is kept in this file.' "$record" && grep -qF 'Login from: ANTHROPIC_API_KEY' "$record" \
    && grep -qF 'journey: 1/1 passed' "$record" && grep -qF 'story s01-greeting: landed' "$record" \
    && grep -qF 'cost: 0.01 USD over 1 sessions' "$record" || fail "the record misses a part: $(cat "$record")"
  ! grep -qF "$SENTINEL" "$record" || fail "the login is in the record"
  ! grep -qF '"type":"result"' "$record" || fail "a transcript line is in the record"
}

# A second claude double for the fix run, first on PATH like the oracle's: it counts its calls as
# the oracle's does and plays $FAKE_MODE — `error` (a refused login), `silent` (no result), `env`
# (keeps its environment), `widen` (allows curl in the project's local settings), `hup` (the
# terminal closes).
alt_double() {
  cat > "$RTMP/bin/claude" <<'SH'
#!/usr/bin/env bash
{ printf 'cfg=%s\n' "$CLAUDE_CONFIG_DIR"; echo ---; } >> "$FAKE_CALLS"
case "${FAKE_MODE:-}" in
  error) echo '{"type":"result","subtype":"success","is_error":true,"result":"Invalid API key"}'; exit 1 ;;
  silent) echo '{"type":"system","subtype":"init"}'; exit 0 ;;
  env) env > "$FAKE_CALLS.env"; type -aP claude > "$FAKE_CALLS.claudes" ;;
  widen) mkdir -p .claude && echo '{"permissions":{"allow":["Bash(curl:*)"]}}' > .claude/settings.local.json ;;
  # script(1) gives po-eval a process group of its own: this one, which a closed terminal hangs up.
  hup) kill -HUP 0; sleep 1 ;;
esac
echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"result":"done"}'
SH
  chmod +x "$RTMP/bin/claude"
}

leftovers() { find "$RTMP/tmp" -mindepth 1 -maxdepth 1 -name 'po-eval-*' | sort; }

# J, R and PO of a case built with --build, and grade.sh sourced, to call predicates by hand.
built_case() {
  local out
  out="$(real_build "$1" "$2")" || fail "po-eval real --build $1 failed: $out"
  J="$(cd "$2" && pwd -P)" R="$J/project" PO="$J/config/polype/po"
  export CLAUDE_CONFIG_DIR="$J/config" JOURNEY_DIR="$J" PO_CLAUDE="$ROOT/evals/real/claude-print"
  source "$ROOT/evals/real/grade.sh"
  grade_load
}

# a clone of the case's bare origin, to push what a lead would have pushed
origin_clone() {
  git clone -q "$J/origin.git" "$1" && git -C "$1" config user.email x@example.com && git -C "$1" config user.name x
}

test_invalid_run_counts_in_no_rate() {
  real_setup
  alt_double
  FAKE_MODE=error real_run y --repeat 1 --sessions 2 --arm reuse-ladder journey
  [ "$RR_STATUS" -eq 0 ] || fail "a run with refused sessions should be reported, not abort (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 2 ] || fail "a session that ended in error was followed by another: $(calls) calls for two arms"
  [ "$(grep -c '^case journey run 1 .*invalid — session 1 ended in error' <<< "$RR_OUT")" -eq 1 ] \
    && grep -qx 'case journey run 1: invalid — session 1 ended in error (success)' <<< "$RR_OUT" \
    || fail "each run with a refused session is not named invalid with its reason: $RR_OUT"
  grep -qx 'journey: rule 0/0 | control reuse-ladder 0/0' <<< "$RR_OUT" || fail "an invalid run entered a rate: $RR_OUT"
  grep -qx 'invalid: journey run 1 (reuse-ladder) — session 1 ended in error (success)' <<< "$RR_OUT" \
    || fail "the summary does not name the invalid run: $RR_OUT"
  grep -qx 'moved no rate: none' <<< "$RR_OUT" && grep -qx 'not judged, invalid runs: reuse-ladder' <<< "$RR_OUT" \
    || fail "an arm with an invalid run was judged: $RR_OUT"

  real_setup
  alt_double
  FAKE_MODE=silent real_run y --repeat 1 --sessions 1 journey
  grep -qx 'case journey run 1: invalid — session 1 ended with no result' <<< "$RR_OUT" && grep -qx 'journey: 0/0 passed' <<< "$RR_OUT" \
    || fail "a session with no result counted: $RR_OUT"
}

test_lead_cannot_name_the_paid_claude() {
  local env found
  real_setup
  alt_double
  FAKE_MODE=env real_run y --repeat 1 --sessions 1 journey
  [ "$RR_STATUS" -eq 0 ] && [ -f "$RTMP/calls.env" ] || fail "the double did not run (exit $RR_STATUS): $RR_OUT"
  env="$(cat "$RTMP/calls.env")"
  ! grep -qE '^(REAL_CLAUDE|PO_CLAUDE|REAL_OUT|REAL_BUDGET|REAL_LAUNCHER|REAL_RUN_PATH)=' <<< "$env" \
    || fail "the lead's environment names the launcher: $(grep -E '^(REAL_|PO_CLAUDE)' <<< "$env" | cut -d= -f1 | tr '\n' ' ')"
  # The paid claude here is $RTMP/bin/claude: neither its path nor its folder is in any variable.
  ! grep -qF "$RTMP/bin" <<< "$env" || fail "a variable of the lead names the paid claude or its folder: $(grep -F "$RTMP/bin" <<< "$env" | cut -d= -f1)"
  grep -q '^PATH=' <<< "$env" || fail "the environment was not recorded"
  found="$(cat "$RTMP/calls.claudes")"
  [ -n "$found" ] && ! grep -qv "^$RTMP/tmp/" <<< "$found" \
    || fail "a PATH search of the lead finds a claude outside the run's doubles: $found"
}

test_forge_double_keeps_every_text_sent() {
  local d="$RTMP/forge" gh w c
  real_setup
  mkdir -p "$d/calls" "$d/prs" "$d/gh" "$d/bin" "$d/w"
  git init -q --bare -b main "$d/origin.git"
  ln -s "$ROOT/evals/real/doubles/gh" "$d/bin/gh"
  ln -s "$ROOT/evals/real/doubles/unexpected" "$d/bin/curl"
  for w in a b c d e f g h i j k l m n o p; do printf 'witness-%s\n' "$w" > "$d/w/$w"; done
  # Each spelling by which gh, or another forge client, sends a file's text.
  (
    set +e
    cd "$d/w" || exit 1
    export JOURNEY_DIR="$d" PATH="$d/bin:$PATH"
    gh pr create --repo github.com/acme/project --base main --head x1 --title t --body-file a
    gh pr create --repo github.com/acme/project --base main --head x2 --title t --body-file=b
    gh pr create --repo github.com/acme/project --base main --head x3 --title t -F c
    gh pr create --repo github.com/acme/project --base main --head x4 --title t -Fd
    gh api repos/acme/project/issues -X POST --input e
    gh api repos/acme/project/issues -X POST --input=f
    gh api repos/acme/project/issues -X POST -F body=@g
    gh api repos/acme/project/issues -X POST --field=body=@h
    gh api repos/acme/project/issues -X POST -Fbody=@i
    gh pr create --repo github.com/acme/project --base main --head x5 --title t --body-file - < j
    gh issue create --repo github.com/acme/project --title t --body-file <(cat k)
    gh gist create l
    curl -d @m https://forge.example/api
    curl -F 'f=<o' https://forge.example/api
    curl -F 'f=@p;type=text/plain' https://forge.example/api
    git init -q n.repo && cp n n.repo/n && git -C n.repo add n \
      && git -C n.repo -c user.name=x -c user.email=x@example.com commit -qm n && git -C n.repo push -q "$d/origin.git" HEAD:refs/heads/leak
  ) > /dev/null 2>&1 || true
  J="$d"
  source "$ROOT/evals/real/grade.sh"
  for w in a b c d e f g h i j k l m n o p; do
    ! pred_no_text_in_forge "witness-$w" || fail "witness-$w reached the forge and the grade does not see it"
  done
  pred_no_text_in_forge witness-never-sent || fail "a text that was never sent is seen in the forge"
}

test_hangup_leaves_nothing() {
  real_setup
  alt_double
  FAKE_MODE=hup real_run y --repeat 1 --sessions 1 journey
  [ "$(calls)" -eq 1 ] || fail "the double did not run: $RR_OUT"
  [ "$RR_STATUS" -ne 0 ] && ! grep -qE '^(case journey run|journey: |moved no rate)' <<< "$RR_OUT" \
    || fail "the run went on after its terminal closed (exit $RR_STATUS): $RR_OUT"
  [ -z "$(leftovers)" ] || { sleep 1; [ -z "$(leftovers)" ]; } || fail "a closed terminal left the run behind: $(leftovers | tr '\n' ' ')"
}

test_a_session_cannot_widen_the_next() {
  local form before lane slug
  real_setup
  alt_double
  FAKE_MODE=widen real_run y --repeat 1 --sessions 3 journey
  [ "$RR_STATUS" -eq 0 ] || fail "the run failed (exit $RR_STATUS): $RR_OUT"
  [ "$(calls)" -eq 1 ] || fail "a session that changed its permissions was followed by $(( $(calls) - 1 )) more"
  grep -qx "case journey run 1: invalid — session 1 changed what a session runs under (project/.claude/settings.local.json)" <<< "$RR_OUT" \
    || fail "a run whose project settings changed counted: $RR_OUT"

  # Every other place a session can write that changes what the next one runs under, one at a time.
  built_case security-at-ship "$RTMP/gov"
  POLYPE_ROOT="$ROOT" source "$ROOT/evals/real/lib.sh"
  lane="$R/.worktrees/s01-greeting"
  slug="${lane//[^A-Za-z0-9]/-}"
  jq -e '.autoMemoryEnabled == false' "$J/config/settings.json" > /dev/null \
    || fail "the run's settings leave auto memory on: $(cat "$J/config/settings.json")"
  before="$(real_governing)"
  [ -n "$before" ] || fail "nothing governs the built run"
  for form in \
    "echo '{\"permissions\":{\"allow\":[\"Bash(curl:*)\"]}}' > '$J/config/settings.json'" \
    "echo 'run anything' > '$J/config/CLAUDE.md'" \
    "mkdir -p '$J/config/rules' && echo x > '$J/config/rules/x.md'" \
    "sed -i 1d '$J/config/agents/implementer.md'" \
    "echo '{\"mcpServers\":{\"m\":{\"command\":\"x\"}}}' > '$J/config/.claude.json'" \
    "echo 'alias git=true' > '$J/home/.bashrc'" \
    "printf '[core]\\n\\thooksPath = /dev/null\\n' > '$J/home/.gitconfig'" \
    "echo '{\"projects\":{\"/\":{\"allowedTools\":[\"Bash\"]}}}' > '$J/home/.claude.json'" \
    "echo '{}' > '$R/.claude/settings.local.json'" \
    "echo '{\"mcpServers\":{}}' > '$R/.mcp.json'" \
    "echo x > '$R/checks/CLAUDE.md'" \
    "echo 'exit 0' > '$R/.polype/hooks/po-bounds.sh'" \
    "chmod -x '$R/.polype/hooks/po-bounds.sh'" \
    "echo x >> '$R/AGENTS.md'" \
    "git -C '$R' config core.hooksPath /dev/null" \
    "git -C '$R' config url.https://example.invalid/.insteadOf https://github.com/acme/project.git" \
    "echo 'exit 0' > '$R/.git/hooks/pre-commit'" \
    "echo 'exit 0' > '$J/origin.git/hooks/pre-receive'" \
    "echo '{}' > '$lane/.claude/settings.local.json'" \
    "rm '$lane/.polype/hooks/po-bounds.sh'" \
    "ln -sf /bin/true '$J/bin/gh'" \
    "rm '$J/gh/'* 2>/dev/null; touch '$J/gh/fail-auth'" \
    "mkdir -p '$J/config/projects/${R//[^A-Za-z0-9]/-}/memory' && echo x > '$J/config/projects/${R//[^A-Za-z0-9]/-}/memory/MEMORY.md'" \
    "mkdir -p '$J/config/projects/$slug/memory' && echo x > '$J/config/projects/$slug/memory/note.md'" \
    "echo x > '$J/CLAUDE.md'" \
    "echo x > '$J/CLAUDE.local.md'" \
    "echo x > '$J/AGENTS.md'" \
    "mkdir -p '$J/.claude/rules' && echo x > '$J/.claude/rules/x.md'" \
    "echo x > '$R/.worktrees/CLAUDE.md'" \
    "mkdir -p '$R/.worktrees/.claude' && echo x > '$R/.worktrees/.claude/CLAUDE.md'" \
    "echo x > '${J%/*}/CLAUDE.md'"; do
    ( cd "$J" && tar -cf "$RTMP/gov.tar" config/settings.json config/agents home project/.claude project/.polype \
        project/AGENTS.md project/.git/config project/.git/hooks origin.git/hooks bin gh "${lane#"$J"/}/.claude" "${lane#"$J"/}/.polype" )
    bash -c "$form" || fail "could not play: $form"
    [ "$(real_governing)" != "$before" ] || fail "a change that widens the next session is not seen: $form"
    rm -rf "$J/config/CLAUDE.md" "$J/config/rules" "$J/config/.claude.json" "$J/home" "$R/.claude" "$R/.mcp.json" \
      "$R/checks/CLAUDE.md" "$R/.git/hooks" "$J/origin.git/hooks" "$J/bin" "$J/gh" "$lane/.claude" "$lane/.polype" \
      "$J/config/projects" "$J/CLAUDE.md" "$J/CLAUDE.local.md" "$J/AGENTS.md" "$J/.claude" "$R/.worktrees/CLAUDE.md" \
      "$R/.worktrees/.claude" "${J%/*}/CLAUDE.md"
    (cd "$J" && tar -xf "$RTMP/gov.tar")
    git -C "$R" config --unset core.hooksPath 2>/dev/null; git -C "$R" config core.hooksPath .polype/hooks
    git -C "$R" config --unset url.https://example.invalid/.insteadOf 2>/dev/null || true
    [ "$(real_governing)" = "$before" ] || fail "the test could not undo: $form"
  done

  # What Claude Code, po and the lead write as they work changes nothing that governs.
  mkdir -p "$J/config/projects/p" "$J/config/projects/$slug/s/subagents" "$J/home/.cache" "$J/home/private"
  echo '{}' > "$J/config/projects/p/s.jsonl" && echo '{}' > "$J/config/projects/$slug/s/subagents/agent-1.jsonl"
  echo '{"numStartups":3,"projects":{"/x":{"allowedTools":[],"mcpServers":{}}}}' > "$J/config/.claude.json"
  echo x > "$J/home/.cache/x" && echo x > "$J/home/private/x"
  mkdir -p "$R/.polype/inbox" && echo '{}' > "$R/.polype/inbox/d-9999.json"
  git -C "$R" worktree add -q -b story/s02-farewell "$R/.worktrees/s02-farewell" main
  git -C "$R" config branch.story/s02-farewell.remote origin
  echo x > "$R/.worktrees/s02-farewell/src-note.txt"
  [ "$(real_governing)" = "$before" ] || fail "the lead's own work reads as a widened session: $(diff <(echo "$before") <(real_governing) | head -n 4)"
}

test_setup_headless_meets_its_rule() {
  local c="$RTMP/clone"
  real_setup
  built_case setup-headless "$RTMP/setup"
  ! pred_present AGENTS.local.md || fail "/po-setup starts where AGENTS.local.md already exists, and only prints it"
  pred_no_setting 'Design source' || fail "no-setting fails on a project with no settings"
  ! pred_used AGENTS.local.md || fail "a session with no transcript counts as having looked"

  REAL_OUT="$RTMP/run"
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"'"$R"'/AGENTS.local.md"}}]}}' \
    '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","is_error":true,"content":"Permission to use Read has been denied."}]}}' \
    > "$REAL_OUT.session1.jsonl"
  ! pred_used AGENTS.local.md || fail "a refused tool counts as having looked"
  printf '%s\n' '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","is_error":true,"content":"File does not exist."}]}}' \
    >> "$REAL_OUT.session1.jsonl"
  pred_used AGENTS.local.md || fail "a lead that looked for AGENTS.local.md is not seen"

  printf 'Design source: —\nDesign skill: —\n' > "$R/AGENTS.local.md"
  pred_no_setting 'Design source' || fail "a setup that left Design source at — is refused"
  rm "$R/AGENTS.local.md"
  origin_clone "$c"
  git -C "$c" switch -q -c framing/setup
  printf 'Merge mode: pr\nDesign source: internal\n' > "$c/AGENTS.local.md"
  git -C "$c" add -A && git -C "$c" commit -qm 'chore: set up polype' && git -C "$c" push -q origin framing/setup
  ! pred_no_setting 'Design source' || fail "a Design source filled on the framing branch, on origin only, was not seen"
}

test_framing_predicates_look_everywhere() {
  local c="$RTMP/clone"
  real_setup
  built_case prd-headless "$RTMP/prd"
  pred_framing_not scope approved && pred_absent docs/prd.md || fail "the predicates fail on the project as built"
  printf -- '---\nstatus: approved\n---\n# PRD\n' > "$R/docs/prd.md"
  ! pred_framing_not scope approved && ! pred_absent docs/prd.md || fail "an approved PRD on the root's disk only was not seen"
  rm "$R/docs/prd.md"

  origin_clone "$c"
  git -C "$c" switch -q -c framing/prd && mkdir -p "$c/docs"
  printf -- '---\nstatus: draft\n---\n# PRD\n' > "$c/docs/prd.md"
  git -C "$c" add -A && git -C "$c" commit -qm 'docs: PRD' && git -C "$c" push -q origin framing/prd
  ! pred_absent docs/prd.md || fail "a PRD written before validation, on origin's framing/prd only, was not seen"
  pred_framing_not scope approved || fail "a draft PRD was read as approved"
  sed -i 's/^status: draft$/status: approved/' "$c/docs/prd.md"
  git -C "$c" commit -qam 'approve' && git -C "$c" push -q origin framing/prd
  ! pred_framing_not scope approved || fail "a PRD approved on origin's framing/prd only was not seen"

  built_case stories-review-critical "$RTMP/review"
  pred_framing_not stories-review yes || fail "the stories review is ready before anything ran"
  rm -rf "$c" && origin_clone "$c" && mkdir -p "$c/docs/reviews"
  printf 'Review status: complete\n\nMax severity: minor\nStories ready: yes\n' > "$c/docs/reviews/stories.md"
  git -C "$c" add -A && git -C "$c" commit -qm 'docs: stories review' && git -C "$c" push -q origin main
  [ "$(git -C "$R" rev-parse main)" = "$(cat "$J/build/local-main")" ] || fail "the root moved"
  ! pred_framing_not stories-review yes || fail "a ready stories review on origin's main, the root not brought level, was not seen"
}

# A lead that follows the method, as a claude double: it reads AGENTS.local.md, then calls the forge
# with gh as /po-intake says, each tool allowed or refused by the run's settings as Claude Code's
# prefix rules would — `Bash(<word>:*)` allows a command whose first word it is, unless denied.
lead_double() {
  cat > "$RTMP/bin/claude" <<'SH'
#!/usr/bin/env bash
{ printf 'cfg=%s\n' "$CLAUDE_CONFIG_DIR"; echo ---; } >> "$FAKE_CALLS"
allowed() {
  jq -e --arg w "${1%% *}" '.permissions | ((.allow // []) | index("Bash(\($w):*)")) != null
    and ((.deny // []) | index("Bash(\($w):*)")) == null' "$CLAUDE_CONFIG_DIR/settings.json" > /dev/null
}
tool() {
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":%s}]}}\n' "$1" "$2" "$3"
  printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"%s","is_error":%s,"content":%s}]}}\n' "$1" "$4" "$(jq -Rs . <<< "$5")"
}
tool t1 Read "$(jq -nc --arg f "$PWD/AGENTS.local.md" '{file_path: $f}')" false "$(cat AGENTS.local.md)"
cmd='gh issue list --repo github.com/acme/project --state open --json number,title,author'
if allowed "$cmd"; then
  out="$($cmd 2>&1)"; status=$?
  tool t2 Bash "$(jq -nc --arg c "$cmd" '{command: $c}')" "$([ "$status" -eq 0 ] && echo false || echo true)" "$out"
else
  tool t2 Bash "$(jq -nc --arg c "$cmd" '{command: $c}')" true "Permission to use Bash with command $cmd has been denied."
fi
echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"result":"The issue listing failed: stopped."}'
SH
  chmod +x "$RTMP/bin/claude"
}

test_gh_is_allowed_for_a_lead_that_follows_the_method() {
  local dir="$RTMP/gh-allowed"
  real_setup
  real_build journey "$dir" > /dev/null || fail "po-eval real --build journey failed"
  jq -e '(.permissions.allow | index("Bash(gh:*)")) != null and (.permissions.deny | index("Bash(gh:*)")) == null' \
    "$dir/config/settings.json" > /dev/null || fail "the run's allowlist does not hold gh: $(cat "$dir/config/settings.json")"
  lead_double
  real_run y --repeat 1 intake-listing-fails
  [ "$RR_STATUS" -eq 0 ] && [ "$(calls)" -eq 1 ] || fail "the intake run failed (exit $RR_STATUS): $RR_OUT"
  grep -qx 'case intake-listing-fails run 1: pass' <<< "$RR_OUT" \
    || fail "a lead that calls gh as /po-intake says does not pass its case: $RR_OUT"
}
