#!/usr/bin/env bash
# s122 — the docs and the eval say what Polype does.

source <(sed '/^test_/,$d' "$ROOT/tests/reuse-ladder-eval.test.sh")

SENTENCE='a story `s<n>-<slug>` is shipped when a commit on `Target branch` or `origin/<Target branch>` has a subject starting with `<id>:`, or, when no commit does, with `s<n>:` exactly, its number written as the id writes it'
STATUS="$METHOD/commands/po-status.md"
DRIVE="$METHOD/commands/po-drive.md"

section() { awk -v h="## $2" '$0 == h {on=1; next} on && /^## / {exit} on {print}' "$1"; }

test_installation_cites_adr_0086() {
  local doc="$ROOT/docs/installation.md" t="$ROOT/tests/install.test.sh"
  ! grep -qF 'ADR-0073' "$doc" || fail "installation.md still cites ADR-0073"
  contains "$doc" 'ceux qu'"'"'il trouve (ADR-0086)'
  contains "$doc" 'ni `CLAUDE.local.md` : Claude Code ne lit'
  contains "$doc" 'même privé'
  contains "$doc" 'qui est commité'
  ! grep -qF 'test_install_writes_no_claude_md()' "$t" || fail "the old install test name is still declared"
  grep -qF 'test_install_creates_no_claude_md_and_spares_one_without_settings() {' "$t" \
    || fail "the renamed install test is not declared"
  contains "$t" 'without AGENTS.local.md, install changed the project'
}

test_drift_message_fits_the_mode() {
  rl_setup
  echo "# drift" >> "$RLTMP/cfg/agents/reviewer.md"
  rl_run y --control --model test-model --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] || fail "a --control drift run exited $RL_STATUS: $RL_OUT"
  grep -qF 'guards that install' <<< "$RL_OUT" || fail "the --control drift message does not say what it guards: $RL_OUT"
  ! grep -qF 'would shadow the method under test' <<< "$RL_OUT" || fail "the --control drift message claims a shadowing"
  rl_run y --repeat 1 rebuilt-helper
  [ "$RL_STATUS" -eq 2 ] || fail "a drift run exited $RL_STATUS: $RL_OUT"
  grep -qF 'would shadow the method under test' <<< "$RL_OUT" || fail "the plain drift message changed: $RL_OUT"
  ! grep -qF 'guards that install' <<< "$RL_OUT" || fail "the plain drift message took the --control wording"
  [ "$(rl_calls)" -eq 0 ] || fail "claude was called despite drift"
}

test_recipe_plan_counts_three_tests() {
  local case="$ROOT/evals/cases/rebuilt-helper.sh" body
  contains "$case" 'The three tests pass'
  ! grep -qF 'Both tests pass' "$case" || fail "rebuilt-helper still says Both tests pass"
  body="$(awk '/^test_demo_app_unchanged\(\) \{/ {on=1} on {print} on && /^\}/ {exit}' "$ROOT/tests/rebuilt-helper-single-defect.test.sh")"
  [ -n "$body" ] || fail "test_demo_app_unchanged is gone"
  ! grep -qF 'wc -l' <<< "$body" || fail "test_demo_app_unchanged still counts recipes"
  ! grep -qF 'eval_archive' <<< "$body" || fail "test_demo_app_unchanged still checks the archive cases"
}

test_status_shipped_rule_reads_once() {
  local line f
  ! grep -qF 'as the id writes it → shipped' "$STATUS" || fail "po-status.md still says shipped twice"
  for f in "$STATUS" "$DRIVE"; do contains "$f" "$SENTENCE"; done
  line="$(grep -F -- '- shipped:' "$STATUS")"
  [ "$(grep -o 'shipped' <<< "$line" | wc -l)" -le 2 ] || fail "the shipped line repeats shipped: $line"
}

test_status_design_system_matches_session() {
  local line
  line="$(grep -F -- '- `docs/design-system.md` present or not' "$STATUS")"
  for phrase in '`design system not needed`' '`Surface`' '`screen`' 'never proposed'; do
    grep -qF -- "$phrase" <<< "$line" || fail "the design-system bullet lacks: $phrase"
  done
}

test_drive_resumes_a_review_the_gate_refuses() {
  local resuming ships review
  resuming="$(section "$DRIVE" Resuming)"
  grep -qF 'refuses it, whatever the reason' <<< "$resuming" || fail "the resume row does not cover any refusal"
  grep -qF 'a `Review status:` missing or other than `complete`' <<< "$resuming" || fail "the resume row omits the status refusal"
  ! grep -qF 'refuses its `Reviewed tree:` |' <<< "$resuming" || fail "the resume row still names only the tree"
  ships="$(section "$DRIVE" 'Ships, one at a time')"
  grep -qF 'Review status:' <<< "$ships" || fail "the ships section does not cite the review status"
  review="$(grep -F -- '- review:' "$STATUS")"
  grep -qF 'whatever the reason' <<< "$review" || fail "the po-status review bullet does not cover any refusal"
  grep -qF 'a `Review status:` missing or other than `complete`' <<< "$review" || fail "the po-status review bullet omits the status refusal"
  ! grep -qF 'no longer matches the code is shown as stale' <<< "$review" || fail "the po-status review bullet still names only the tree"
}

test_law3_row_states_both_status_checks() {
  local row gate="$METHOD/hooks/po-gate.sh"
  row="$(grep -F '| Ship allowed |' "$METHOD/AGENTS.md")"
  grep -qF 'of that verdict' <<< "$row" || fail "the Law 3 row omits the verdict's own status"
  grep -qF 'the last `Review status:` line of the file' <<< "$row" || fail "the Law 3 row omits the file's last status"
  awk '/^paired_hash\(\) \{/ {print prev; exit} {prev = $0}' "$gate" | grep -qF '40 hex' \
    || fail "the 40-hex comment does not sit above paired_hash"
  ! awk '/^paired_value\(\) \{/ {exit} /^#/ {block = block $0 "\n"; next} {block = ""} END {printf "%s", block}' "$gate" \
    | grep -qF '40 hex' || fail "the comment above paired_value still holds the 40-hex rule"
}
