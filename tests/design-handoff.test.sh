#!/usr/bin/env bash
# s21 — design handoff to plan, execute and setup.

IMPLEMENTER="$METHOD/agents/implementer.md"
EXECUTE="$METHOD/commands/po-execute.md"
PLAN="$METHOD/commands/po-plan.md"
SETUP="$METHOD/commands/po-setup.md"
DEFECTS="$ROOT/docs/defauts.md"

test_implementer_expects_the_design_folder() {
  local expected
  expected=$(grep -m1 '^- `git -C <path> status --porcelain` may list' "$IMPLEMENTER" || true)
  [[ "$expected" == *'`docs/designs/<id>/` for a story with a screen'* ]] \
    || fail "the implementer's expected uncommitted files omit docs/designs/<id>/"
  [[ "$expected" == *'those are expected. Any other change you did not make → stop and report.'* ]] \
    || fail "the expected-files line lost its stop clause"
  contains "$IMPLEMENTER" 'When `docs/designs/<id>/design.md` exists, read it before the screen tasks'
  grep -F -- '- First run: **one commit**' "$IMPLEMENTER" | grep -qF 'the design folder `docs/designs/<id>/` when there is one' \
    || fail "the first-run commit does not include the design folder"
}

test_execute_mentions_the_design_when_present() {
  contains "$EXECUTE" 'Glob `docs/designs/<id>/*` in the worktree: any match means the story **has a design**'
  contains "$EXECUTE" 'When the story has a design, append:'
  contains "$EXECUTE" '> This story has a design: docs/designs/<id>/ is expected uncommitted work, like the research and the plan. Read design.md before the screen tasks, build the screen it settles, and commit the folder with the story.'
  local tool
  for tool in Bash Write Edit; do lacks_tool "$EXECUTE" "$tool"; done
  [ "$(tools_of "$EXECUTE" | sort | tr '\n' ' ')" = "Agent Glob Grep Read " ] \
    || fail "po-execute tools changed: $(tools_of "$EXECUTE" | tr '\n' ' ')"
}

test_plan_reads_the_design_when_present() {
  awk '/^## Inputs/ {on=1; next} /^## / {on=0} on' "$PLAN" | grep -qF '`docs/designs/<id>/design.md` when it exists' \
    || fail "po-plan inputs omit the design file"
  awk '/^## Writing the plan/ {on=1; next} /^## / {on=0} on' "$PLAN" \
    | grep -qF 'When `docs/designs/<id>/design.md` exists, the screen tasks build what it settles, cite it, and add nothing it leaves out.' \
    || fail "po-plan does not bind screen tasks to the design"
}

test_setup_asks_design_details_after_the_source() {
  local step
  step=$(awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$SETUP")
  ! grep -qi 'in the same call' "$SETUP" || fail "po-setup still asks the design detail in the same call"
  grep -qE '^4\. .*`Design source`.*Only the source is asked here\.' <<< "$step" \
    || fail "question 4 does not ask the source alone"
  ! grep -qE '^4\. .*`Design (skill|tool)`' <<< "$step" || fail "question 4 still asks the design detail"
  grep -qF 'Once the `Design source` answer is known, make one separate AskUserQuestion call for its detail: the `Design skill` when the answer is `internal`, the `Design tool` when it is `external`' <<< "$step" \
    || fail "no separate follow-up call conditional on the source"
  grep -qF 'When the source is not decided yet, skip this call: both stay `—`.' <<< "$step" \
    || fail "the follow-up is not skipped when the source is undecided"
}

test_defects_one_to_three_marked_fixed() {
  local n row
  for n in 1 2 3; do
    row=$(grep -m1 "^| $n |" "$DEFECTS" || true)
    [[ "$row" == *'| corrigé par s21 |' ]] || fail "defect $n is not marked fixed by s21"
  done
  # s22 closed 4 and 5, s23 closed 6; every other row of the table must still read ouvert.
  for n in 4 5; do
    row=$(grep -m1 "^| $n |" "$DEFECTS" || true)
    [[ "$row" == *'| corrigé par s22 |' ]] || fail "defect $n is not marked fixed by s22"
  done
  row=$(grep -m1 '^| 6 |' "$DEFECTS" || true)
  [[ "$row" == *'| corrigé par s23 |' ]] || fail "defect 6 is not marked fixed by s23"
  for n in 7 8 9 10 11; do
    row=$(grep -m1 "^| $n |" "$DEFECTS" || true)
    [[ "$row" == *'| ouvert |' ]] || fail "defect $n no longer reads ouvert"
  done
}
