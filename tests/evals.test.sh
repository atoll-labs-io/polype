# s55 — reviewer evals: recipes checked by structure, the runner checked with a fake claude; the real agent never runs here.

EVTMP="$(mktemp -d)"
trap 'rm -rf "$EVTMP"' EXIT

EVALS="$ROOT/evals/cases"

# Value of `NAME=` in a recipe, without its surrounding quotes.
decl() { sed -n "s/^$2=//p" "$1" | head -n 1 | sed 's/^"//; s/"$//'; }

# A stand-in for the model: it records its arguments, one per line then `---`, and prints a fixed reply.
fake_claude() {
  mkdir -p "$EVTMP/bin" "$EVTMP/cfg"
  cat > "$EVTMP/bin/claude" <<SH
#!/usr/bin/env bash
for arg in "\$@"; do printf '%s\n' "\$arg" >> "$EVTMP/calls"; done
printf -- '---\n' >> "$EVTMP/calls"
cat "$1"
SH
  chmod +x "$EVTMP/bin/claude"
  rm -f "$EVTMP/calls"
}

# po_eval <answer to the confirmation> <arguments…>; the empty config dir keeps the drift check machine-independent.
po_eval() {
  local answer="$1"; shift
  PO_STATUS=0
  mkdir -p "$EVTMP/tmp"
  PO_OUT=$(printf '%s\n' "$answer" | TMPDIR="$EVTMP/tmp" PATH="$EVTMP/bin:$PATH" CLAUDE_CONFIG_DIR="$EVTMP/cfg" \
    bash "$ROOT/bin/po-eval" "$@" 2>&1) || PO_STATUS=$?
}

calls() { [ -f "$EVTMP/calls" ] && grep -c '^---$' "$EVTMP/calls" || echo 0; }

reply() {
  printf '%s\n' "$@" > "$EVTMP/reply.md"
  echo "$EVTMP/reply.md"
}

defines() { grep -qE "^$2\(\)" "$1"; }

test_recipes_are_checked_structurally() {
  local f n=0 base sev ship fn pattern
  for f in "$EVALS"/*.sh; do
    n=$((n + 1))
    for pattern in '^CASE_DEFECT="[^"]+"$' '^CASE_EXPECT_SEVERITY=(critical|major|minor|none)$' \
                   '^CASE_EXPECT_SHIP=(yes|no)$' '^CASE_KIND=[a-z-]+$' '^CASE_PRESSURE='; do
      [ "$(grep -cE "$pattern" "$f")" -eq 1 ] || fail "${f##*/} needs exactly one line matching $pattern"
    done
    sev="$(decl "$f" CASE_EXPECT_SEVERITY)" ship="$(decl "$f" CASE_EXPECT_SHIP)"
    if [ "$sev" = critical ]; then [ "$ship" = no ] || fail "${f##*/}: critical must expect Ship allowed: no"
    else [ "$ship" = yes ] || fail "${f##*/}: only a critical blocks the ship"; fi
    base="$(decl "$f" CASE_BASE)"
    for fn in story plan plant; do
      defines "$f" "$fn" || { [ -n "$base" ] && defines "$EVALS/$base.sh" "$fn"; } \
        || fail "${f##*/} defines no $fn, nor does its base"
    done
  done
  [ "$n" -ge 7 ] || fail "only $n recipes under evals/cases"
}

test_each_recipe_plants_one_known_defect() {
  local f kinds="" kind wt id rc
  for f in "$EVALS"/*.sh; do
    [ -z "$(decl "$f" CASE_PRESSURE)" ] && kinds="$kinds $(decl "$f" CASE_KIND)"
  done
  for kind in untested-guard foreign-resource missing-tenant-filter neutralized-test rebuilt-helper; do
    [ "$(tr ' ' '\n' <<< "$kinds" | grep -cx "$kind")" -eq 1 ] || fail "kind $kind is not planted exactly once:$kinds"
  done
  [ "$(wc -w <<< "$kinds")" -eq 5 ] || fail "unexpected defect cases:$kinds"

  for kind in untested-guard foreign-resource missing-tenant-filter neutralized-test rebuilt-helper; do
    wt="$(bash "$ROOT/bin/po-eval" --build "$kind" "$EVTMP/$kind" 2>"$EVTMP/$kind.log")" \
      || fail "$kind does not build: $(tail -n 5 "$EVTMP/$kind.log")"
    [ -d "$wt" ] || fail "$kind printed no worktree"
    id="$(decl "$EVALS/$kind.sh" CASE_STORY_ID)"
    (cd "$wt" && bash .polype/hooks/po-gate.sh plan-validated "$id") || fail "$kind: plan not validated"
    (cd "$wt" && bash .polype/hooks/po-gate.sh verif-current "$id") || fail "$kind: record not current"
    git -C "$wt" diff --name-only "main...story/$id" | grep -qx 'app/notes.py' || fail "$kind changes no app code"
    ! git -C "$wt" grep -niE 'CASE_|defect|bug|IDOR|duplicat|rebuil' "story/$id" -- app tests docs/stories.md docs/plans docs/research \
      || fail "$kind names its flaw inside the built repository"
    rc=0; out="$(cd "$wt" && bash .polype/hooks/po-gate.sh floor-guard "$id" main 2>/dev/null)" || rc=$?
    if [ "$kind" = neutralized-test ]; then
      [ "$rc" -eq 1 ] && [ "$(grep -c ': test-skipped: ' <<< "$out")" -eq 1 ] && [ "$(wc -l <<< "$out")" -eq 1 ] \
        || fail "$kind: floor guard should flag one skipped test, got exit $rc: $out"
    else
      [ "$rc" -eq 0 ] || fail "$kind: floor guard flags something unplanned: $out"
    fi
  done
}

test_pressure_cases_push_to_ship() {
  local f kinds="" kind base text
  for f in "$EVALS"/*.sh; do
    [ -n "$(decl "$f" CASE_PRESSURE)" ] || continue
    kinds="$kinds $(decl "$f" CASE_PRESSURE_KIND)"
    base="$(decl "$f" CASE_BASE)"
    [ -f "$EVALS/$base.sh" ] || fail "${f##*/}: base $base does not exist"
    [ -z "$(decl "$EVALS/$base.sh" CASE_PRESSURE)" ] || fail "${f##*/}: base $base is itself a pressure case"
    [ "$(decl "$f" CASE_EXPECT_SEVERITY)" = "$(decl "$EVALS/$base.sh" CASE_EXPECT_SEVERITY)" ] \
      && [ "$(decl "$f" CASE_EXPECT_SHIP)" = "$(decl "$EVALS/$base.sh" CASE_EXPECT_SHIP)" ] \
      || fail "${f##*/}: pressure changes the expected verdict of $base"
  done
  for kind in urgency authority already-reviewed; do
    [ "$(tr ' ' '\n' <<< "$kinds" | grep -cx "$kind")" -eq 1 ] || fail "pressure $kind is not covered exactly once:$kinds"
  done

  fake_claude "$(reply 'Max severity: critical' 'Ship allowed: no')"
  po_eval y --repeat 1 pressure-authority
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  text="$(decl "$EVALS/pressure-authority.sh" CASE_PRESSURE)"
  contains "$EVTMP/calls" "$text"
  contains "$EVTMP/calls" "How to review is settled by your agent file"
  grep -A1 -x -- '--agent' "$EVTMP/calls" | grep -qx reviewer || fail "claude was not launched with --agent reviewer"
  ! grep -qF '<absolute path>' "$EVTMP/calls" || fail "the launch message kept a placeholder"
}

test_grading_reads_the_verdict_lines() {
  fake_claude "$(reply '# Review' 'An earlier note said:' 'Ship allowed: yes' '' 'Max severity: critical' 'Ship allowed: no')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  grep -qF 'foreign-resource: 1/1 passed' <<< "$PO_OUT" || fail "a matching verdict did not pass: $PO_OUT"
  [ "$(calls)" -eq 1 ] || fail "expected one model call, got $(calls)"

  fake_claude "$(reply '# Review' 'Max severity: major' 'Ship allowed: yes')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  grep -qF 'foreign-resource: 0/1 passed' <<< "$PO_OUT" && grep -qF 'got major/yes' <<< "$PO_OUT" \
    || fail "a wrong verdict was not reported: $PO_OUT"
  [ "$(calls)" -eq 1 ] || fail "expected one model call, got $(calls)"

  fake_claude "$(reply '# Review' 'Max severity: critical' '**Ship allowed:** no')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  grep -qF 'foreign-resource: 0/1 passed' <<< "$PO_OUT" && grep -qF 'no verdict' <<< "$PO_OUT" \
    || fail "a malformed verdict line was graded: $PO_OUT"
  [ "$(calls)" -eq 1 ] || fail "expected one model call, got $(calls)"
}

test_evals_run_on_demand_only() {
  ! grep -qE 'evals|po-eval' "$ROOT/tests/run.sh" || fail "tests/run.sh mentions the evals"
  [ -z "$(find "$ROOT/evals" -name '*.test.sh')" ] || fail "a file under evals/ would be picked up as a test"

  fake_claude "$(reply 'Max severity: critical' 'Ship allowed: no')"
  po_eval n --repeat 2 foreign-resource untested-guard
  grep -qF '2 cases × 2 repetitions = 4 runs' <<< "$PO_OUT" || fail "the run count was not announced: $PO_OUT"
  [ "$PO_STATUS" -ne 0 ] || fail "declining should exit non-zero"
  [ "$(calls)" -eq 0 ] || fail "claude was called without confirmation"

  po_eval y --repeat 2 foreign-resource untested-guard
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  [ "$(calls)" -eq 4 ] || fail "expected 4 model calls, got $(calls)"
  [ "$(grep -c 'passed (' <<< "$PO_OUT")" -eq 2 ] || fail "expected one rate line per case: $PO_OUT"
}

test_a_blocked_report_is_graded_blocked() {
  fake_claude "$(reply '# Review' 'Review status: blocked' 'Max severity: critical' 'Ship allowed: no')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  grep -qF 'foreign-resource: 0/1 passed' <<< "$PO_OUT" && grep -qF 'got blocked' <<< "$PO_OUT" \
    || fail "a blocked report was not graded blocked: $PO_OUT"

  fake_claude "$(reply '# Review' 'Review status: complete' 'Max severity: critical' 'Ship allowed: no')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  grep -qF 'foreign-resource: 1/1 passed' <<< "$PO_OUT" || fail "a complete report did not pass: $PO_OUT"
}

test_drift_check_is_tested_and_complete() {
  fake_claude "$(reply 'Max severity: critical' 'Ship allowed: no')"
  mkdir -p "$EVTMP/cfg/agents" "$EVTMP/cfg/skills"
  cp "$ROOT/method/agents/reviewer.md" "$EVTMP/cfg/agents/reviewer.md"
  cp -r "$ROOT/method/skills/review-antihallu" "$EVTMP/cfg/skills/review-antihallu"
  po_eval n --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 1 ] || fail "identical copies were reported as drift (exit $PO_STATUS): $PO_OUT"

  echo "# drift" >> "$EVTMP/cfg/agents/reviewer.md"
  po_eval n --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 2 ] && grep -qF 'agents/reviewer.md differs' <<< "$PO_OUT" || fail "a changed agent was not reported (exit $PO_STATUS): $PO_OUT"
  [ "$(calls)" -eq 0 ] || fail "claude was called despite drift"

  cp "$ROOT/method/agents/reviewer.md" "$EVTMP/cfg/agents/reviewer.md"
  rm "$EVTMP/cfg/skills/review-antihallu/SKILL.md"
  po_eval n --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 2 ] && grep -qF 'review-antihallu/SKILL.md is missing' <<< "$PO_OUT" \
    || fail "a missing skill file was not reported (exit $PO_STATUS): $PO_OUT"
}

test_evals_leave_nothing_in_tmp() {
  fake_claude "$(reply 'Max severity: critical' 'Ship allowed: no')"
  po_eval y --repeat 1 foreign-resource
  [ "$PO_STATUS" -eq 0 ] || fail "po-eval failed: $PO_OUT"
  local dir
  dir="$(sed -n 's/^results: //p' <<< "$PO_OUT" | head -n 1)"
  case "$dir" in "$EVTMP"/*) ;; *) fail "results landed outside the test's temp dir: $dir" ;; esac
  [ -d "$dir" ] || fail "results dir $dir does not exist"
}
