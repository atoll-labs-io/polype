# s114 — the rebuilt-helper case and po-eval's YAGNI control arm, run against a fake claude; no paid call.

RLTMP="$(mktemp -d)"
trap 'rm -rf "$RLTMP"' EXIT

PREFIX='New code that an existing helper you can cite by'
RL_TOKEN=(ANTHROPIC_API_KEY=test)

# A config dir holding the method's reviewer and its preloaded skills, so the drift check passes for real,
# and a fake claude that records which reuse sentence each reachable copy of the skill holds.
rl_setup() {
  local skill
  mkdir -p "$RLTMP/bin" "$RLTMP/tmp" "$RLTMP/home" "$RLTMP/cfg/agents" "$RLTMP/cfg/skills"
  cp "$ROOT/method/agents/reviewer.md" "$RLTMP/cfg/agents/reviewer.md"
  for skill in review-antihallu review-lenses testing-doctrine design-doctrine; do
    cp -R "$ROOT/method/skills/$skill" "$RLTMP/cfg/skills/$skill"
  done
  cat > "$RLTMP/bin/claude" <<'SH'
#!/usr/bin/env bash
count() { local n; n="$(grep -cF -- "$1" "$2" 2>/dev/null)" || true; echo "${n:-0}"; }
cfg_skill="$CLAUDE_CONFIG_DIR/skills/review-antihallu/SKILL.md"
proj_skill="$PWD/.claude/skills/review-antihallu/SKILL.md"
{
  echo "cfg=$CLAUDE_CONFIG_DIR"
  echo "cfg_yagni=$(count 'Follow YAGNI.' "$cfg_skill")"
  echo "cfg_prefix=$(count "$RL_PREFIX" "$cfg_skill")"
  echo "proj_yagni=$(count 'Follow YAGNI.' "$proj_skill")"
  echo "proj_prefix=$(count "$RL_PREFIX" "$proj_skill")"
  echo ---
} >> "$RL_CALLS"
printf 'Max severity: major\nShip allowed: yes\n'
SH
  chmod +x "$RLTMP/bin/claude"
  rm -f "$RLTMP/calls"
}

# rl_run <answer to the confirmation> <arguments…>
rl_run() {
  local answer="$1"; shift
  RL_STATUS=0
  RL_OUT=$(printf '%s\n' "$answer" | env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN ${RL_TOKEN[@]+"${RL_TOKEN[@]}"} \
    TMPDIR="$RLTMP/tmp" HOME="$RLTMP/home" CLAUDE_CONFIG_DIR="$RLTMP/cfg" \
    RL_CALLS="$RLTMP/calls" RL_PREFIX="$PREFIX" PATH="$RLTMP/bin:$PATH" \
    bash "$ROOT/bin/po-eval" "$@" 2>&1) || RL_STATUS=$?
}

rl_calls() { [ -f "$RLTMP/calls" ] && grep -c '^---$' "$RLTMP/calls" || echo 0; }

# rl_field <call number> <key>
rl_field() {
  awk -v n="$1" -v k="$2=" 'BEGIN {c = 1} $0 == "---" {c++; next} c == n && index($0, k) == 1 {print substr($0, length(k) + 1)}' "$RLTMP/calls"
}

cfg_listing() { (cd "$RLTMP/cfg" && find . -type f -exec cksum {} + | sort); }

test_eval_plants_a_rebuilt_helper() {
  local case="$ROOT/evals/cases/rebuilt-helper.sh" wt diff added
  grep -qx 'CASE_EXPECT_SEVERITY=major' "$case" && grep -qx 'CASE_EXPECT_SHIP=yes' "$case" \
    || fail "rebuilt-helper must expect major / ship yes"
  wt="$(bash "$ROOT/bin/po-eval" --build rebuilt-helper "$RLTMP/build" 2>"$RLTMP/build.log")" \
    || fail "rebuilt-helper does not build: $(tail -n 5 "$RLTMP/build.log")"
  diff="$(git -C "$wt" diff main...story/s01-archive-note -- app/notes.py)"
  ! grep -v '^--- ' <<< "$diff" | grep -q '^-' || fail "the plant removes lines of app/notes.py: $diff"
  added="$(grep '^+' <<< "$diff" | grep -v '^+++ ')"
  grep -qF 'note = self._notes[note_id]' <<< "$added" && grep -qF 'if note.owner_id != user.id:' <<< "$added" \
    || fail "the plant does not repeat get()'s lookup and owner check: $added"
  ! grep -qF 'self.get(' <<< "$added" || fail "the plant calls get() instead of repeating it"
  git -C "$wt" diff main...story/s01-archive-note -- tests/test_notes.py | grep -qE '^\+.*assertRaises\(Forbidden\)' \
    || fail "the plant does not test the refusal"
}

test_eval_has_a_yagni_control_arm() {
  rl_setup
  rl_run n --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -ne 0 ] || fail "declining should exit non-zero"
  grep -qF '1 cases × 1 repetitions × 2 arms = 2 runs' <<< "$RL_OUT" || fail "the two arms were not announced: $RL_OUT"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called without confirmation"

  rl_run y --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 0 ] || fail "po-eval --control failed: $RL_OUT"
  [ "$(rl_calls)" -eq 2 ] || fail "expected two calls, got $(rl_calls)"
  [ "$(rl_field 1 proj_prefix)" -eq 1 ] && [ "$(rl_field 1 proj_yagni)" -eq 0 ] \
    || fail "the rule arm does not review with the reuse sentence: $(cat "$RLTMP/calls")"
  [ "$(rl_field 2 cfg_yagni)" -eq 1 ] && [ "$(rl_field 2 cfg_prefix)" -eq 0 ] \
    && [ "$(rl_field 2 proj_yagni)" -eq 1 ] && [ "$(rl_field 2 proj_prefix)" -eq 0 ] \
    || fail "the control arm does not hold Follow YAGNI. in both copies: $(cat "$RLTMP/calls")"
  grep -qF 'rebuilt-helper: rule 1/1 (100%) | control 1/1 (100%)' <<< "$RL_OUT" || fail "no side-by-side rates: $RL_OUT"
  ! grep -qF 'po-eval' "$ROOT/tests/run.sh" || fail "tests/run.sh mentions po-eval"
}

test_control_arm_never_touches_the_global_install() {
  local before ctlcfg
  rl_setup
  before="$(cfg_listing)"
  rl_run y --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 0 ] || fail "po-eval --control failed: $RL_OUT"
  [ "$(rl_field 1 cfg)" = "$RLTMP/cfg" ] || fail "the rule arm did not run on the inherited config"
  ctlcfg="$(rl_field 2 cfg)"
  case "$ctlcfg" in "$RLTMP/tmp"/*) ;; *) fail "the control config is outside TMPDIR: $ctlcfg" ;; esac
  [ ! -e "$ctlcfg" ] || fail "the control config $ctlcfg survived the run"
  [ "$(cfg_listing)" = "$before" ] || fail "the real config dir was modified"
  [ ! -e "$RLTMP/home/.claude" ] || fail "something was written under HOME/.claude"

  rl_setup
  echo "# drift" >> "$RLTMP/cfg/agents/reviewer.md"
  rl_run y --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] && grep -qF 'agents/reviewer.md differs' <<< "$RL_OUT" \
    || fail "drift in the real config was not refused (exit $RL_STATUS): $RL_OUT"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called despite drift"

  rm -rf "$RLTMP/cfg"
  rl_setup
  RL_TOKEN=()
  rl_run y --control --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] && grep -qF 'claude setup-token' <<< "$RL_OUT" \
    || fail "a control run without a token was not refused (exit $RL_STATUS): $RL_OUT"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called without a token"
}
