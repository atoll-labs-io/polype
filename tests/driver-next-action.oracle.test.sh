#!/usr/bin/env bash
# s168 — the oracle of the story: `po next` computes each lane's next action and the ready and held
# stories from files and git, and `po state` carries the same in `lanes[].next`, `ready` and `held`
# (#203, #139). The routing cases live in tests/fixtures/driver-cases/, one file per section of
# method/commands/po-drive.md.

PO="${PO:-${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po}"
CASES="$ROOT/tests/fixtures/driver-cases"
ACTIONS='["plan","validate-plan","design","execute","qa","review","fix","ship","wait","ask"]'

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# po_in <dir> <args...>: sets OUT (stdout) and STATUS; never fails by itself.
po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

# The version the installer stamps, so po does not warn about another version.
stamp() { sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype"; }

# project: a fresh Polype project at $F (inside $SCRATCH, removed on exit) with the gate, the version
# stamp, the settings below, a design system and no story yet. `story` lines come next, then `start`.
project() {
  need_po
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"
  mkdir -p "$F/.polype/hooks" "$F/docs/reviews" "$F/src"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cp "$ROOT/method/hooks/po-gate.sh" "$F/.polype/hooks/po-gate.sh"
  chmod +x "$F/.polype/hooks/po-gate.sh"
  stamp > "$F/.polype/version"
  cat > "$F/AGENTS.local.md" <<'EOF'
# fixture — Polype settings

```
Merge mode:        local
Target branch:     main
Ship confirmation: automatic
Plan validation:   autonomous
QA stage:          —
Design source:     internal
Worktree root:     .worktrees/
Entry mode:        —
Parallel:          3
Max attempts:      2
Decision inbox:    .polype/inbox/
```
EOF
  printf '# Stories\n\n## M1 — Fixture\n\n' > "$F/docs/stories.md"
  printf 'Stories ready: yes\n' > "$F/docs/reviews/stories.md"
  printf '# Architecture\n' > "$F/docs/architecture.md"
  printf '# Design system\n' > "$F/docs/design-system.md"
  printf '.worktrees/\n.polype/inbox/\n' > "$F/.gitignore"
  echo app > "$F/src/app.txt"
}

# setting <name> <value|->: rewrites the setting in AGENTS.local.md; `-` deletes its line.
setting() {
  if [ "$2" = - ]; then sed -i "/^$1:/d" "$F/AGENTS.local.md"; else sed -i "s|^$1:.*|$1: $2|" "$F/AGENTS.local.md"; fi
}

# story <id> <surface> <depends: ids comma-separated, or -> [owns...]
story() {
  local id="$1" surface="$2" deps="$3" owns="" entry
  shift 3
  for entry in "$@"; do owns+="${owns:+, }\`$entry\`"; done
  {
    printf '### %s — %s\n- **Complexité** : 1\n- **Surface** : %s\n' "$id" "$id" "$surface"
    [ "$deps" = - ] || printf -- '- **Dépend de** : %s\n' "${deps//,/, }"
    [ -z "$owns" ] || printf -- '- **Owns** : %s\n' "$owns"
    printf '\n'
  } >> "$F/docs/stories.md"
}

# start: commits the project on main, stories included.
start() { git -C "$F" add -A; git -C "$F" commit -qm init; }

# land <id>: the story's landing commit on main.
land() { git -C "$F" commit -q --allow-empty -m "$1: Landed"; }

# lane <id>: the worktree of story <id> at <Worktree root><id>, on story/<id>; sets W.
lane() { W="$F/.worktrees/$1"; git -C "$F" worktree add -q -b "story/$1" "$W" main; }

# orphan <id>: story/<id> checked out outside <Worktree root>.
orphan() { git -C "$F" worktree add -q -b "story/$1" "$SCRATCH/elsewhere-$1" main; }

# research_in <id> [line]
research_in() { mkdir -p "$W/docs/research"; printf '# Research — %s\n%s\n' "$1" "${2:-}" > "$W/docs/research/$1.md"; }

# plan_in <id> <yes|no> [line]
plan_in() {
  mkdir -p "$W/docs/plans"
  printf -- '---\nvalidated: %s\n---\n# Plan — %s\n%s\n' "$2" "$1" "${3:-}" > "$W/docs/plans/$1.md"
}

design_in() { mkdir -p "$W/docs/designs/$1"; printf '# Design — %s\n' "$1" > "$W/docs/designs/$1/design.md"; }

# code_in <id> [subject]: one implementer commit in the lane.
code_in() {
  echo "$RANDOM$RANDOM" > "$W/src/$1-$(git -C "$W" rev-list --count HEAD).txt"
  git -C "$W" add -A
  git -C "$W" commit -qm "${2:-$1: code}"
}

# record_in <id>: a complete verification record bound to the lane's committed code.
record_in() {
  mkdir -p "$W/docs/verif"
  printf 'Tree: %s\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | — | none here |\n\nVerification status: complete\n' \
    "$(git -C "$W" rev-parse 'HEAD^{tree}')" > "$W/docs/verif/$1.md"
}

# recorded_lane <id>: a lane with research, a validated plan, one implementer commit and its record.
recorded_lane() { lane "$1"; research_in "$1"; plan_in "$1" yes; code_in "$1"; record_in "$1"; }

# qa_in <id> <complete|blocked> [commit]: a QA report of the lane's code; committed alone with `commit`.
qa_in() {
  mkdir -p "$W/docs/qa/$1"
  printf '# QA — %s\nWalk %s\nTree: %s\n\nQA status: %s\n' "$1" "$RANDOM$RANDOM" \
    "$(git -C "$W" rev-parse 'HEAD^{tree}')" "$2" > "$W/docs/qa/$1/report.md"
  if [ "${3:-}" = commit ]; then git -C "$W" add -- "docs/qa/$1"; git -C "$W" commit -qm "$1: QA evidence" -- "docs/qa/$1"; fi
}

# review_in <id> <complete|blocked> <fix loop> <yes|no> [next action]: a review of the lane's code.
review_in() {
  local findings='none' severity='none'
  [ "$4" = no ] && findings='- major — src/app.txt:1 — the rule is not met' severity='major'
  mkdir -p "$W/docs/reviews"
  {
    printf 'Review status: %s\nFix loop: %s\nReviewed tree: %s\n\n' "$2" "$3" "$(git -C "$W" rev-parse 'HEAD^{tree}')"
    [ -z "${5:-}" ] || printf '## When blocked\n- Failure cause: see below\n- Next action: %s\n\n' "$5"
    printf '## Findings\n%s\n\nMax severity: %s\nShip allowed: %s\n' "$findings" "$severity" "$4"
  } > "$W/docs/reviews/$1.md"
}

# reviewed_at <id> <date>: when the lane's review was recorded, as its file's modification time.
reviewed_at() { touch -d "$2" "$F/.worktrees/$1/docs/reviews/$1.md"; }

# pushed <id>: the story branch exists on origin, as after /po-ship opened its pull request.
pushed() { git -C "$F" update-ref "refs/remotes/origin/story/$1" "refs/heads/story/$1"; }

# decision <id> <pending|answered|consumed> <blocked story>: one decision of the inbox.
decision() {
  local status=pending answer=null consumed=''
  [ "$2" = pending ] || { status=answered; answer='{"key": "a", "at": "2026-11-12T14:20:00+01:00"}'; }
  [ "$2" = consumed ] && consumed=',
  "consumed": {"ref": "docs/decisions/ADR-0001-x.md", "at": "2026-11-12T15:00:00+01:00"}'
  mkdir -p "$F/.polype/inbox"
  cat > "$F/.polype/inbox/$1.json" <<EOF
{
  "id": "$1",
  "asked": "2026-11-12T14:05:00+01:00",
  "motive": "strategic",
  "sensitive": false,
  "question": "Which way does the story go?",
  "context": null,
  "options": [
    {"key": "a", "label": "One way", "consequence": "this"},
    {"key": "b", "label": "Another way", "consequence": "that"}
  ],
  "recommended": "a",
  "why": "it is simpler",
  "reversible": true,
  "blocks": ["$3"],
  "status": "$status",
  "answer": $answer$consumed
}
EOF
}

# Expectations a case records; `replay` checks them against one `po next`.
expect_lane() { printf 'lane\t%s\t%s\t%s\n' "$1" "$2" "$3" >> "$SCRATCH/expect"; }
expect_ready() { printf 'ready\t%s\n' "$1" >> "$SCRATCH/expect"; }
expect_held() { printf 'held\t%s\t%s\t%s\n' "$1" "$2" "${3:-null}" >> "$SCRATCH/expect"; }
expect_none() { printf 'none\t%s\n' "$1" >> "$SCRATCH/expect"; }
expect_collision() { printf 'collision\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$SCRATCH/expect"; }

# check_expectations: every line of $SCRATCH/expect holds in OUT, the output of `po next`; sets BAD.
check_expectations() {
  local kind id a b c got
  BAD=""
  while IFS=$'\t' read -r kind id a b c; do
    case "$kind" in
      lane)
        got="$(jq -c --arg id "$id" '[.actions[]? | select(.story == $id) | [.action, .reason]]' <<< "$OUT")"
        [ "$got" = "$(jq -cn --arg a "$a" --arg b "$b" '[[$a, $b]]')" ] || BAD+="lane $id: $got instead of [$a, $b]; " ;;
      ready)
        jq -e --arg id "$id" '(.ready | index($id)) != null
          and ([.actions[] | select(.story == $id) | [.action, .reason]] == [["plan", "ready"]])' <<< "$OUT" >/dev/null \
          || BAD+="$id is not ready with the action plan; " ;;
      held)
        got="$(jq -c --arg id "$id" '[.held[]? | select(.story == $id) | [.reason, (.ref // "null")]]' <<< "$OUT")"
        [ "$got" = "$(jq -cn --arg a "$a" --arg b "$b" '[[$a, $b]]')" ] || BAD+="held $id: $got instead of [$a, $b]; " ;;
      collision)
        got="$(jq -c --arg id "$id" '[.held[]? | select(.story == $id) | [.entry, .ref_entry, (.path // "null")]]' <<< "$OUT")"
        [ "$got" = "$(jq -cn --arg a "$a" --arg b "$b" --arg c "$c" '[[$a, $b, $c]]')" ] \
          || BAD+="collision $id: $got instead of [$a, $b, $c]; " ;;
      none)
        jq -e --arg id "$id" '(.ready | index($id)) == null and all(.held[]; .story != $id)
          and all(.actions[]; .story != $id)' <<< "$OUT" >/dev/null || BAD+="$id is listed although it must not be; " ;;
    esac
  done < "$SCRATCH/expect"
}

# OUT is one JSON object with "contract": 1, exit 0, an action from the contract's list for each entry.
next_shape() {
  [ "$STATUS" -eq 0 ] || fail "$1: po next exited $STATUS: $OUT"
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1: stdout is not one JSON value: $OUT"
  jq -e --argjson allowed "$ACTIONS" '.contract == 1 and (.actions | type == "array")
    and all(.actions[]; (.action as $a | $allowed | index($a)) != null and (.reason | type == "string" and length > 0))' \
    <<< "$OUT" >/dev/null || fail "$1: not the shape of po next: $OUT"
}

test_next_gives_one_action_per_lane() {
  project
  setting Parallel 6
  story s01-alpha command -
  story s02-bravo command -
  story s03-charlie command -
  story s04-delta command -
  story s05-echo command -
  story s06-foxtrot command -
  start
  lane s01-alpha
  lane s02-bravo
  research_in s02-bravo
  lane s03-charlie
  research_in s03-charlie 'Root cause: not found'
  lane s04-delta
  research_in s04-delta
  plan_in s04-delta yes
  lane s05-echo
  research_in s05-echo
  plan_in s05-echo yes
  code_in s05-echo
  record_in s05-echo
  review_in s05-echo complete 0 yes

  po_in "$F" next
  next_shape "po next"
  local bad="" id action reason
  while read -r id action reason; do
    expect_lane "$id" "$action" "$reason"
  done <<'EOF'
s01-alpha plan no research
s02-bravo plan research, no plan
s03-charlie ask Root cause: not found
s04-delta execute verif-current refuses
s05-echo ship ship-allowed passes
EOF
  expect_ready s06-foxtrot
  check_expectations
  [ -z "$BAD" ] || fail "po next: $BAD"
  [ "$(jq '.actions | length' <<< "$OUT")" = 6 ] || fail "not one action per lane and per ready story: $OUT"

  local next="$OUT"
  po_in "$W" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e --argjson n "$next" '
      ([.lanes[] | {story, action: .next.action, reason: .next.reason}] | sort_by(.story))
        == ($n.actions | map(select(.story as $s | $n.ready | index($s) | not)) | sort_by(.story))
      and .ready == $n.ready and .held == $n.held' <<< "$OUT" >/dev/null \
    || fail "po state does not carry what po next computes.
      po next:  $(jq -c . <<< "$next")
      po state: $(jq -c '{lanes, ready, held}' <<< "$OUT")"
}

test_ready_and_held_say_why() {
  project
  setting Parallel 3
  story s01-alpha command - 'src/a/'
  story s02-bravo command s01-alpha 'src/b/'
  story s03-charlie command - 'src/a/x.txt'
  story s04-delta command - 'src/d/'
  story s05-echo command - 'src/e/'
  story s06-foxtrot command - 'src/f/'
  story s07-golf command - 'src/g/'
  start
  lane s01-alpha
  decision d-0001 pending s04-delta

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e '.ready == ["s05-echo", "s06-foxtrot"]' <<< "$OUT" >/dev/null \
    || fail "ready is not the stories that may open, in the order of docs/stories.md, within Parallel: $OUT"
  jq -e '.held == [
      {"story": "s02-bravo", "reason": "dependency", "ref": "s01-alpha"},
      {"story": "s03-charlie", "reason": "owns", "ref": "s01-alpha",
       "entry": "src/a/x.txt", "ref_entry": "src/a/", "path": "src/a/x.txt"},
      {"story": "s04-delta", "reason": "decision", "ref": "d-0001"},
      {"story": "s07-golf", "reason": "parallel", "ref": null}]' <<< "$OUT" >/dev/null \
    || fail "held does not say why each story waits: $(jq -c .held <<< "$OUT")"
}

test_every_routing_case_is_a_fixture() {
  need_po
  local file name cases=0 failed=""
  for file in "$CASES"/*.cases; do
    [ -f "$file" ] || fail "no case file under tests/fixtures/driver-cases/"
    for name in $(bash -c "source '$file' && declare -F" | awk '$3 ~ /^case_/ {print $3}'); do
      cases=$((cases + 1))
      # Each case builds its own project in a process of its own.
      if ! out="$( (
          project
          : > "$SCRATCH/expect"
          # shellcheck source=/dev/null
          source "$file"
          "$name"
          po_in "$F" next
          next_shape "$name"
          check_expectations
          [ -z "$BAD" ] || fail "$BAD"
        ) 2>&1 )"; then
        failed+="  ${file##*/} $name: $out"$'\n'
      fi
    done
  done
  [ "$cases" -ge 56 ] || fail "only $cases routing cases under tests/fixtures/driver-cases/"
  [ -z "$failed" ] || fail "routing cases that po next does not follow:
$failed"
}

test_blocked_on_shape_asks_and_never_fixes() {
  project
  story s01-alpha command -
  story s02-bravo command -
  start
  local id
  for id in s01-alpha s02-bravo; do
    lane "$id"
    research_in "$id"
    plan_in "$id" yes
    code_in "$id"
    record_in "$id"
  done
  W="$F/.worktrees/s01-alpha"
  review_in s01-alpha blocked 0 no 'a person settles the findings shape — po-gate findings-shape s01-alpha refused the reviewer twice'
  W="$F/.worktrees/s02-bravo"
  review_in s02-bravo blocked 0 no 'a person runs po-gate findings-shape s02-bravo — the check could not run (exit 2)'
  : > "$SCRATCH/expect"
  expect_lane s01-alpha ask 'findings-shape refused'
  expect_lane s02-bravo ask 'findings-shape refused'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "a review blocked on its findings shape does not go to a person: $BAD"
}

test_fix_loops_stop_at_max_attempts() {
  project
  story s01-alpha command -
  story s02-bravo command -
  story s03-charlie command -
  start
  local id loop
  for id in s01-alpha s02-bravo s03-charlie; do
    lane "$id"
    research_in "$id"
    plan_in "$id" yes
    code_in "$id"
    # Fix loop <n> judged the story's (n + 1)th implementer commit.
    loop=0
    case "$id" in s02-bravo) loop=1 ;; s03-charlie) loop=2 ;; esac
    for _ in $(seq 1 "$loop"); do code_in "$id" "$id: fix run"; done
    record_in "$id"
    review_in "$id" complete "$loop" no
  done
  : > "$SCRATCH/expect"
  expect_lane s01-alpha fix 'Ship allowed: no'
  expect_lane s02-bravo fix 'Ship allowed: no'
  expect_lane s03-charlie ask 'Max attempts reached'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "with Max attempts 2: $BAD"

  setting 'Max attempts' 1
  : > "$SCRATCH/expect"
  expect_lane s01-alpha fix 'Ship allowed: no'
  expect_lane s02-bravo ask 'Max attempts reached'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "with Max attempts 1: $BAD"
}

test_ships_stay_serial_in_review_order() {
  project
  story s01-alpha command - 'src/a/'
  story s02-bravo command - 'src/b/'
  start
  local id
  for id in s01-alpha s02-bravo; do
    lane "$id"
    research_in "$id"
    plan_in "$id" yes
    code_in "$id"
    record_in "$id"
    review_in "$id" complete 0 yes
  done
  reviewed_at s01-alpha '2026-11-13 10:00'
  reviewed_at s02-bravo '2026-11-13 09:00'
  : > "$SCRATCH/expect"
  expect_lane s02-bravo ship 'ship-allowed passes'
  expect_lane s01-alpha wait 'ships serial: s02-bravo'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "the review that passed first does not ship first: $BAD"

  reviewed_at s02-bravo '2026-11-13 11:00'
  : > "$SCRATCH/expect"
  expect_lane s01-alpha ship 'ship-allowed passes'
  expect_lane s02-bravo wait 'ships serial: s01-alpha'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "with the order of the reviews reversed: $BAD"
}

test_answered_decision_releases_its_lanes() {
  project
  story s01-alpha command -
  start
  lane s01-alpha
  research_in s01-alpha
  plan_in s01-alpha yes
  decision d-0001 pending s01-alpha
  : > "$SCRATCH/expect"
  expect_lane s01-alpha wait 'decision d-0001'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "a lane a pending decision blocks does not wait: $BAD"

  decision d-0001 consumed s01-alpha
  : > "$SCRATCH/expect"
  expect_lane s01-alpha execute 'verif-current refuses'
  po_in "$F" next
  next_shape "po next"
  check_expectations
  [ -z "$BAD" ] || fail "the lane does not resume once its decision is answered and consumed: $BAD"
}
