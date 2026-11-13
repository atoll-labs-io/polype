#!/usr/bin/env bash
# s165 — task tests of `po inbox`: ids never reach the filesystem, parallel writers never share an
# id, `po state` and `po inbox` agree, `—` is no inbox, and the rules stay under their word ceilings.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO"
}

# run_po <args...> in $F; sets OUT and STATUS.
run_po() { STATUS=0; OUT="$(cd "$F" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

expect() {
  [ "$STATUS" -eq "$2" ] || fail "$3: exited $STATUS instead of $2: $OUT"
  jq -e --arg c "$1" '.contract == 1 and .error == $c' <<< "$OUT" >/dev/null || fail "$3: error is not $1: $OUT"
}

fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  F="$SCRATCH/project"
  mkdir -p "$F"
  git -C "$F" init -q -b main
  printf '```\nTarget branch:     main\nWorktree root:     .worktrees/\nDecision inbox:    .polype/inbox/\n```\n' > "$F/AGENTS.local.md"
  printf '.polype/inbox/\n' > "$F/.gitignore"
}

decision() {
  printf '%s' '{"motive":"stop","question":"Retry the lane?","options":[{"key":"a","label":"Yes","consequence":"one more run"},{"key":"b","label":"No","consequence":"the lane waits"}],"recommended":"a","why":"the cause is known","reversible":true,"blocks":[]}'
}

test_an_id_never_reaches_the_filesystem() {
  need_po
  fixture
  mkdir -p "$F/.polype/inbox"
  printf '{"id":"x","status":"pending"}' > "$F/.polype/x.json"
  local id
  for id in ../x ../../AGENTS.local d-1/../x d- D-0001 d-00a1; do
    run_po inbox "$id"
    expect unknown-decision 1 "po inbox $id"
  done
  run_po inbox add extra
  expect unknown-option 2 "po inbox add extra"
  run_po inbox --all
  expect unknown-option 2 "po inbox --all"
}

test_parallel_adds_never_share_an_id() {
  need_po
  fixture
  local i pids=()
  for i in 1 2 3 4 5 6 7 8; do
    (cd "$F" && decision | "$PO" inbox add >/dev/null 2>&1) &
    pids+=($!)
  done
  for i in "${pids[@]}"; do wait "$i" || fail "one parallel po inbox add failed"; done
  local got
  got="$(cd "$F/.polype/inbox" && ls -A | sort | tr '\n' ' ')"
  [ "$got" = "d-0001.json d-0002.json d-0003.json d-0004.json d-0005.json d-0006.json d-0007.json d-0008.json " ] \
    || fail "eight parallel adds left: $got"
  run_po inbox
  [ "$(jq -c '[.pending[].id] | unique | length' <<< "$OUT")" = 8 ] || fail "the eight decisions do not carry eight ids: $OUT"
}

test_state_waiting_agrees_with_the_list() {
  need_po
  fixture
  local inbox="$F/.polype/inbox"
  mkdir -p "$inbox"
  (cd "$F" && decision | "$PO" inbox add >/dev/null) || fail "po inbox add failed"
  (cd "$F" && decision | "$PO" inbox add >/dev/null) || fail "po inbox add failed"
  jq 'del(.why)' "$inbox/d-0002.json" > "$inbox/d-0010.json"
  jq '.id = "d-0010"' "$inbox/d-0010.json" > "$inbox/tmp" && mv "$inbox/tmp" "$inbox/d-0010.json"
  printf '{ not json' > "$inbox/d-0005.json"
  run_po inbox
  [ "$STATUS" -eq 0 ] || fail "po inbox exited $STATUS: $OUT"
  local listed waiting
  listed="$(jq -c '[.pending[].id]' <<< "$OUT")"
  [ "$listed" = '["d-0001","d-0002","d-0010"]' ] || fail "po inbox listed $listed"
  jq -e '.pending[2].why == null' <<< "$OUT" >/dev/null || fail "a missing why does not read as null: $OUT"
  run_po state
  waiting="$(jq -c '.waiting' <<< "$OUT")"
  [ "$waiting" = "$listed" ] || fail "po state waits on $waiting, po inbox lists $listed"
  jq -e 'any(.warnings[]; .code == "unreadable-decision" and (.path | endswith("/d-0005.json")))' \
    <<< "$OUT" >/dev/null || fail "po state does not name the unreadable file: $OUT"
}

test_a_dash_is_no_inbox() {
  need_po
  fixture
  sed -i 's|^Decision inbox:.*|Decision inbox:    —|' "$F/AGENTS.local.md"
  run_po inbox
  expect no-inbox-setting 2 "po inbox with Decision inbox: —"
  STATUS=0; OUT="$(cd "$F" && decision | "$PO" inbox add 2>/dev/null)" || STATUS=$?
  expect no-inbox-setting 2 "po inbox add with Decision inbox: —"
  [ ! -e "$F/—" ] || fail "po inbox add took — for a folder"
}

test_rules_stay_under_their_word_ceilings() {
  local words
  words="$(awk '/^## / { on = ($0 == "## What goes to the person") } on' "$METHOD/AGENTS.md" | LC_ALL=C wc -w)"
  [ "$words" -le 378 ] || fail "## What goes to the person holds $words words, over 378"
  words="$(awk '/^## / { on = ($0 == "## Installed files") } on' "$METHOD/AGENTS.md" | LC_ALL=C wc -w)"
  [ "$words" -le 516 ] || fail "## Installed files holds $words words, over 516"
  words="$(LC_ALL=C wc -w < "$METHOD/AGENTS.md")"
  [ "$words" -le 3743 ] || fail "method/AGENTS.md holds $words words, over 3743"
}
