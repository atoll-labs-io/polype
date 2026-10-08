#!/usr/bin/env bash
# s56 — po-run writes the record's run rows; po-gate verif-current requires a passing run per declared check.

RUN="$METHOD/hooks/po-run.sh"
GATE="$METHOD/hooks/po-gate.sh"
REC="docs/verif/s01-a.md"

story_sandbox() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p src
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
  git checkout -qb story/s01-a
}

# Body rows of the `## Runs` table, header and separator dropped.
run_rows() { sed -n '/^## Runs$/,$p' "$REC" | grep '^| ' | sed '1,2d'; }
cell() { awk -F'|' -v k="$2" '{c = $(NF - k); gsub(/^[[:space:]]+|[[:space:]]+$/, "", c); print c}' <<< "$1"; }

test_po_run_passes_the_exit_code_through() {
  story_sandbox
  local out rc=0
  out="$(bash "$RUN" --story s01-a --label Probe -- bash -c 'echo visible; exit 7')" || rc=$?
  [ "$rc" -eq 7 ] || fail "argv form: expected exit 7, got $rc"
  [ "$out" = visible ] || fail "the command's output did not pass through: $out"
  rc=0; bash "$RUN" --story s01-a --label Probe -- 'exit 3' || rc=$?
  [ "$rc" -eq 3 ] || fail "single-argument form: expected exit 3, got $rc"
  bash "$RUN" --story s01-a --label Probe -- true || fail "a passing command did not exit 0"
}

test_po_run_appends_a_row() {
  story_sandbox
  mkdir -p docs/verif
  printf '# Verification — s01-a\n\nTree: head-line-kept\n' > "$REC"
  echo 'fresh' > src/new.txt
  bash "$RUN" --story s01-a --label "Unit suite" -- 'echo LEAK-$((1000 + 234))' >/dev/null
  bash "$RUN" --story s01-a --label "Type check" -- 'exit 4' || true

  [ "$(head -n 1 "$REC")" = '# Verification — s01-a' ] && grep -qx 'Tree: head-line-kept' "$REC" \
    || fail "the head of the record did not survive"
  local rows first second tree
  rows="$(run_rows)"
  [ "$(wc -l <<< "$rows")" -eq 2 ] || fail "expected two run rows, got: $rows"
  first="$(sed -n 1p <<< "$rows")" second="$(sed -n 2p <<< "$rows")"
  [[ "$first" == '| Unit suite | `echo LEAK-$((1000 + 234))` | 0 | '* ]] || fail "first row is wrong: $first"
  [[ "$second" == '| Type check | `exit 4` | 4 | '* ]] || fail "second row is wrong or out of order: $second"
  [[ "$(cell "$first" 1)" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || fail "no UTC time: $first"
  ! grep -qF 'LEAK-1234' "$REC" || fail "the command's output was written into the record"
  git status --porcelain | grep -qx '?? src/new.txt' || fail "po-run staged an untracked file in the real index"

  tree="$(cell "$first" 2)"
  [[ "$tree" =~ ^[0-9a-f]{40}$ ]] || fail "no full tree hash: $first"
  git add -A
  # The record itself grows between the runs, so the comparison leaves docs/ out, as the gate does.
  git diff --quiet "$tree" "$(git write-tree)" -- . ':(exclude)docs' || fail "the row's tree is not the working copy"
  git cat-file -e "$tree:src/new.txt" || fail "the row's tree misses the untracked file"
}

test_po_run_refuses_outside_a_story_worktree() {
  scratch_repo
  cd "$SCRATCH"
  echo 'x' > app.txt && git add -A && git commit -qm init
  local rc
  rc=0; bash "$RUN" --story s01-a --label Probe -- 'touch ran' 2>/dev/null || rc=$?
  [ "$rc" -eq 125 ] || fail "on main: expected 125, got $rc"
  git checkout -qb story/s02-b
  rc=0; bash "$RUN" --story s01-a --label Probe -- 'touch ran' 2>/dev/null || rc=$?
  [ "$rc" -eq 125 ] || fail "on another story's branch: expected 125, got $rc"
  rc=0; bash "$RUN" --story ../x --label Probe -- 'touch ran' 2>/dev/null || rc=$?
  [ "$rc" -eq 125 ] || fail "a path as story id: expected 125, got $rc"
  [ ! -e ran ] || fail "the command ran although po-run refused"
  [ ! -e docs ] && [ ! -e ../x.md ] || fail "a refused launch wrote a record"
}

# A record declaring `Unit suite` as `exit ${RC:-0}`, plus a `—` row that needs no run.
fresh_record() {
  mkdir -p docs/verif
  printf '# Verification — s01-a\n\nTree: pending\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | `%s` | |\n| Type check | — | no such command in this project |\n\nVerification status: complete\n' \
    "${1:-exit \${RC:-0\}}" > "$REC"
}
seal() {
  git add -A
  awk -v t="$(git write-tree)" '/^Tree: / {$0 = "Tree: " t} {print}' "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
  git add -A && git commit -qm record
}
accepted() { bash "$GATE" verif-current s01-a 2>/dev/null; }
unit() { RC="$1" bash "$RUN" --story s01-a --label "Unit suite" -- "${2:-exit \${RC:-0\}}" || true; }

test_verif_current_requires_a_passing_run_per_check() {
  story_sandbox
  fresh_record; seal
  ! accepted || fail "a declared check with no run was accepted"

  fresh_record; unit 1; unit 0; seal
  accepted || fail "a failing then passing run on the same code was refused"

  fresh_record; unit 0; unit 1; seal
  ! accepted || fail "a passing then failing run was accepted"

  fresh_record; unit 0 'exit 0'; seal
  ! accepted || fail "a passing run of another command under the same label was accepted"

  fresh_record; unit 0
  echo 'later' > src/app.txt
  seal
  ! accepted || fail "a passing run on earlier code only was accepted"

  fresh_record 'true | cat'; unit 0 'true | cat'; seal
  accepted || fail "a declared command holding '|' did not match its run"

  fresh_record '—'; seal
  accepted || fail "a record declaring only '—' checks needs no run"

  printf 'Tree: pending\n\nVerification status: complete\n' > "$REC"; unit 0; seal
  ! accepted || fail "a record without a Checks table was accepted"
}

# s60 — a Checks row the gate cannot read refuses the record and names the row, rather than vanishing.
test_verif_current_refuses_a_malformed_checks_row() {
  story_sandbox
  local err
  mkdir -p docs/verif
  printf '# Verification — s01-a\n\nTree: pending\n\n## Checks\n| Check | Command |\n| --- | --- |\n| Unit suite | `exit 0` |\n\nVerification status: complete\n' > "$REC"
  unit 0 'exit 0'; seal
  err="$(bash "$GATE" verif-current s01-a 2>&1)" && fail "a two-cell Checks row was accepted"
  grep -qF 'has a row it cannot read' <<< "$err" && grep -qF 'Unit suite' <<< "$err" \
    || fail "the two-cell refusal does not name the row: $err"

  printf '# Verification — s01-a\n\nTree: pending\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| -- Unit suite | `exit 0` | |\n\nVerification status: complete\n' > "$REC"
  unit 0 'exit 0'; seal
  err="$(bash "$GATE" verif-current s01-a 2>&1)" && fail "a Checks row labelled like a separator was accepted"
  grep -qF 'has a row it cannot read' <<< "$err" && grep -qF -- '-- Unit suite' <<< "$err" \
    || fail "the dash-label refusal does not name the row: $err"

  fresh_record; unit 0; seal
  accepted || fail "the template's own Checks table was refused"
}

test_implementer_runs_checks_through_po_run() {
  local agent="$METHOD/agents/implementer.md"
  contains "$agent" 'po-run.sh --story'
  contains "$METHOD/skills/testing-doctrine/SKILL.md" 'po-run --story'
  ! grep -qF 'list each command you ran with its exit code' "$agent" \
    || fail "the implementer still copies results by hand"
}

test_eval_recipes_follow_the_new_record() {
  local wt id=s01-archive-note cmd
  LEDGER_TMP="$(mktemp -d)"
  trap 'rm -rf "$LEDGER_TMP"' EXIT
  wt="$(bash "$ROOT/bin/po-eval" --build foreign-resource "$LEDGER_TMP/repo" 2>"$LEDGER_TMP/log")" \
    || fail "foreign-resource does not build: $(tail -n 5 "$LEDGER_TMP/log")"
  cmd="$(sed -n 's/^Test:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$wt/AGENTS.local.md" | head -n 1)"
  [ -n "$cmd" ] || fail "the built repository has no Test command"
  git -C "$wt" show "story/$id:docs/verif/$id.md" | grep -qF "| Unit suite | \`$cmd\` | 0 | " \
    || fail "the committed record has no passing Unit suite row for $cmd"
  (cd "$wt" && bash .polype/hooks/po-gate.sh verif-current "$id") || fail "the built record is not current"
}
