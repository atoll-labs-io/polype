#!/usr/bin/env bash
# s166 — task tests beside the oracle: parallel answers, unknown fields kept, consume refusals, an
# inbox git no longer ignores, and the word ceiling of the rules.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

refused() {
  [ "$STATUS" -eq "$2" ] || fail "$3: exited $STATUS instead of $2: $OUT"
  jq -e --arg c "$1" '.contract == 1 and .error == $c' <<< "$OUT" >/dev/null || fail "$3: error is not $1: $OUT"
}

sums() { find "$I" -type f | sort | while IFS= read -r f; do printf '%s %s\n' "$f" "$(cksum < "$f")"; done; }

fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"
  I="$F/.polype/inbox"
  mkdir -p "$F/docs"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  printf '# fixture\n\n```\nTarget branch:     main\nDecision inbox:    .polype/inbox/\n```\n' > "$F/AGENTS.local.md"
  printf '# Stories\n' > "$F/docs/stories.md"
  printf '.polype/inbox/\n' > "$F/.gitignore"
  git -C "$F" add -A
  git -C "$F" commit -qm init
}

ask() {
  local out
  out="$(cd "$F" && "$PO" inbox add 2>/dev/null <<'EOF'
{"motive": "strategic", "question": "Which runner?",
 "options": [{"key": "a", "label": "Hosted", "consequence": "x"}, {"key": "b", "label": "Own", "consequence": "y"}],
 "recommended": "a", "why": "neutral", "reversible": true, "blocks": []}
EOF
)" || fail "po inbox add failed: $out"
  ID="$(jq -r '.id' <<< "$out")"
}

test_parallel_answers_record_one() {
  need_po
  fixture
  ask
  local n key pids=()
  for n in 1 2 3 4 5 6 7 8; do
    if [ $((n % 2)) -eq 0 ]; then key=b; else key=a; fi
    ( code=0; cd "$F" && "$PO" answer "$ID" "$key" > "$SCRATCH/out.$n" 2>/dev/null || code=$?; echo "$code" > "$SCRATCH/code.$n" ) &
    pids+=($!)
  done
  wait "${pids[@]}"
  local won=0 lost=0 winner=""
  for n in 1 2 3 4 5 6 7 8; do
    case "$(cat "$SCRATCH/code.$n")" in
      0) won=$((won + 1)); winner="$(jq -r '.answer.key' < "$SCRATCH/out.$n")" ;;
      1) jq -e '.error == "already-answered"' < "$SCRATCH/out.$n" >/dev/null \
           || fail "a losing answer did not say already-answered: $(cat "$SCRATCH/out.$n")"
         lost=$((lost + 1)) ;;
      *) fail "an answer exited $(cat "$SCRATCH/code.$n"): $(cat "$SCRATCH/out.$n")" ;;
    esac
  done
  [ "$won" -eq 1 ] && [ "$lost" -eq 7 ] || fail "$won answers won and $lost lost, not 1 and 7"
  [ "$(jq -r '.answer.key' < "$I/$ID.json")" = "$winner" ] || fail "the file does not carry the winner's key $winner"
  [ "$(find "$I" -type f | wc -l | tr -d ' ')" = 1 ] || fail "a lock or temp was left: $(ls -A "$I")"
}

test_unknown_fields_survive_a_rewrite() {
  need_po
  fixture
  ask
  local file="$I/$ID.json"
  jq '. + {"later": {"x": 1}}' "$file" > "$SCRATCH/with-later" && cp "$SCRATCH/with-later" "$file"
  po_in "$F" answer "$ID" a
  [ "$STATUS" -eq 0 ] || fail "po answer exited $STATUS: $OUT"
  jq -e '.later == {"x": 1}' "$file" >/dev/null || fail "po answer dropped an unknown field: $(cat "$file")"
  po_in "$F" inbox consume "$ID" ADR-0001
  [ "$STATUS" -eq 0 ] || fail "po inbox consume exited $STATUS: $OUT"
  jq -e '.later == {"x": 1} and .consumed.ref == "ADR-0001"' "$file" >/dev/null \
    || fail "po inbox consume dropped an unknown field: $(cat "$file")"
}

test_consume_refusals_write_nothing() {
  need_po
  fixture
  ask
  local before
  before="$(sums)"
  po_in "$F" inbox consume "$ID" ADR-0001
  refused not-answered 1 "consume of a pending decision"
  po_in "$F" answer "$ID"
  refused unknown-option 2 "po answer with no key"
  po_in "$F" inbox consume "$ID"
  refused unknown-option 2 "po inbox consume with no ref"
  [ "$(sums)" = "$before" ] || fail "a refusal on a pending decision wrote into the inbox"

  po_in "$F" answer "$ID" a
  po_in "$F" inbox consume "$ID" ADR-0001
  [ "$STATUS" -eq 0 ] || fail "the first consume exited $STATUS: $OUT"
  before="$(sums)"
  po_in "$F" inbox consume "$ID" ADR-0002
  refused already-consumed 1 "a second consume"
  po_in "$F" inbox consume "$ID" ""
  refused malformed-ref 1 "an empty ref"
  po_in "$F" inbox consume "$ID" $'one\ntwo'
  refused malformed-ref 1 "a two-line ref"
  po_in "$F" inbox consume ../AGENTS.local ADR-0001
  refused unknown-decision 1 "consume of ../AGENTS.local"
  [ "$(sums)" = "$before" ] || fail "a refused consume wrote into the inbox"
}

test_answer_refuses_an_inbox_git_tracks() {
  need_po
  fixture
  ask
  local before
  before="$(cksum < "$I/$ID.json")"
  : > "$F/.gitignore"
  po_in "$F" answer "$ID" a
  refused inbox-not-ignored 1 "po answer into an inbox git does not ignore"
  [ "$(cksum < "$I/$ID.json")" = "$before" ] || fail "the refused answer changed the decision"
}

test_rules_stay_under_the_story_ceiling() {
  local words
  words="$(LC_ALL=C wc -w < "$METHOD/AGENTS.md")"
  [ "$words" -le 3741 ] || fail "method/AGENTS.md holds $words words, over 3741"
}
