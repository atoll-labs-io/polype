#!/usr/bin/env bash
# s165 — the oracle of the story: `po inbox add` writes one validated decision file into the folder
# `Decision inbox` names, never into git; `po inbox` lists what waits, oldest first (ADR-0107).
# `rules_send_every_stop_to_the_inbox` and `provisional_inbox_is_gone` are judged in review.

POLYPE="$ROOT/bin/polype"

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# po_in <dir> <args...>: sets OUT (stdout) and STATUS; never fails by itself.
po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

# po_add <dir> <json>: `po inbox add` in <dir> with <json> on stdin; sets OUT and STATUS.
po_add() { STATUS=0; OUT="$(cd "$1" && printf '%s' "$2" | "$PO" inbox add 2>/dev/null)" || STATUS=$?; }

one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1: stdout is not one JSON value: $OUT"
  jq -e 'type == "object" and .contract == 1' <<< "$OUT" >/dev/null \
    || fail "$1: not an object carrying \"contract\": 1: $OUT"
}

# refused <code> <exit> <what>: OUT is one error object with that code, and po exited <exit>.
refused() {
  [ "$STATUS" -eq "$2" ] || fail "$3: exited $STATUS instead of $2: $OUT"
  one_object "$3"
  jq -e --arg c "$1" '.error == $c' <<< "$OUT" >/dev/null || fail "$3: error is not $1: $OUT"
}

# Every file under <dir>, hidden ones included; 0 when <dir> does not exist.
files_in() { if [ -d "$1" ]; then find "$1" -type f | wc -l | tr -d ' '; else echo 0; fi; }

# A fresh Polype project at $F (under $SCRATCH, itself no repository) whose .gitignore ignores the
# inbox, with one story worktree at $W.
fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"
  mkdir -p "$F/docs"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cat > "$F/AGENTS.local.md" <<'EOF'
# fixture — Polype settings

```
Target branch:     main
Worktree root:     .worktrees/
Decision inbox:    .polype/inbox/
```
EOF
  printf '# Stories\n\n## M1 — Fixture\n\n### s01-one — One\n' > "$F/docs/stories.md"
  printf '.worktrees/\n.polype/inbox/\n' > "$F/.gitignore"
  git -C "$F" add -A
  git -C "$F" commit -qm init
  W="$F/.worktrees/s01-one"
  git -C "$F" worktree add -q -b story/s01-one "$W" main
}

# set_inbox <value>: rewrites the Decision inbox line of the fixture's settings.
set_inbox() { sed -i "s|^Decision inbox:.*|Decision inbox:    $1|" "$F/AGENTS.local.md"; }

# A decision as the lead hands it to `po inbox add`: no id, no date, no status.
valid() {
  cat <<'EOF'
{
  "motive": "strategic",
  "sensitive": false,
  "question": "Which runner runs the suite?",
  "context": "docs/decisions/ADR-0105-la-suite-tourne-sur-chaque-pull-request.md",
  "options": [
    {"key": "a", "label": "Hosted runners", "consequence": "nothing to install"},
    {"key": "b", "label": "Self-hosted runner", "consequence": "one machine to isolate"}
  ],
  "recommended": "a",
  "why": "the check is a neutral script",
  "reversible": true,
  "blocks": ["s01-one"]
}
EOF
}

# decision_file <dir> <id> <status>: a decision file in the shape of docs/interface-agent.md.
decision_file() {
  local answer=null
  [ "$3" = answered ] && answer='{"key": "a", "at": "2026-11-12T14:20:00+01:00"}'
  mkdir -p "$1"
  valid | jq --arg id "$2" --arg st "$3" --argjson an "$answer" \
    '{id: $id, asked: "2026-11-12T14:05:00+01:00"} + . + {status: $st, answer: $an}' > "$1/$2.json"
}

test_add_writes_one_decision_file() {
  need_po
  fixture
  local inbox="$F/.polype/inbox" before
  po_add "$F" "$(valid)"
  [ "$STATUS" -eq 0 ] || fail "po inbox add exited $STATUS: $OUT"
  one_object "po inbox add"
  jq -e '.id == "d-0001" and .status == "pending" and .answer == null
         and .motive == "strategic" and .question == "Which runner runs the suite?"
         and (.options | length) == 2 and .recommended == "a" and .reversible == true and .blocks == ["s01-one"]' \
    <<< "$OUT" >/dev/null || fail "po inbox add did not return the decision it wrote: $OUT"
  jq -e '.asked | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([+-][0-9]{2}:[0-9]{2}|Z)$")' <<< "$OUT" >/dev/null \
    || fail "asked is not a date with its offset: $OUT"
  [ -f "$inbox/d-0001.json" ] || fail "no $inbox/d-0001.json"
  [ "$(jq -S 'del(.contract)' <<< "$OUT")" = "$(jq -S . "$inbox/d-0001.json")" ] \
    || fail "the file differs from the object po returned: $(cat "$inbox/d-0001.json")"

  po_add "$W" "$(valid)"
  [ "$STATUS" -eq 0 ] || fail "po inbox add from a story worktree exited $STATUS: $OUT"
  jq -e '.id == "d-0002"' <<< "$OUT" >/dev/null || fail "the second decision is not d-0002: $OUT"
  [ -f "$inbox/d-0002.json" ] || fail "a decision added from the worktree did not land in the root's inbox"
  [ ! -e "$W/.polype/inbox" ] || fail "po inbox add wrote into the worktree's own .polype/inbox"
  [ "$(files_in "$inbox")" = 2 ] || fail "the inbox holds more than the two decisions: $(ls -A "$inbox")"

  sed -i '/^Decision inbox:/d' "$F/AGENTS.local.md"
  before="$(find "$F" -path "$F/.git" -prune -o -print | sort)"
  po_add "$F" "$(valid)"
  refused no-inbox-setting 2 "po inbox add without the setting"
  jq -e '.message | contains("Decision inbox")' <<< "$OUT" >/dev/null || fail "the refusal does not name the setting: $OUT"
  [ "$(find "$F" -path "$F/.git" -prune -o -print | sort)" = "$before" ] || fail "po inbox add wrote a file without the setting"
}

test_add_refuses_a_malformed_decision() {
  need_po
  fixture
  local inbox="$F/.polype/inbox" filter
  local filters=(
    '.motive = "whim"'
    'del(.question)'
    '.question = "Which runner?\nAnd which machine?"'
    '.question = ("x" * 201)'
    '.options = .options[:1]'
    '.options += [{"key": "c", "label": "C", "consequence": "c"}, {"key": "d", "label": "D", "consequence": "d"}]'
    '.recommended = "z"'
    'del(.why)'
    'del(.reversible)'
    'del(.blocks)'
  )
  for filter in "${filters[@]}"; do
    po_add "$F" "$(valid | jq "$filter")"
    refused malformed-decision 1 "a decision with $filter"
    [ "$(files_in "$inbox")" = 0 ] || fail "a decision with $filter left a file: $(ls -A "$inbox")"
  done

  po_add "$F" "$(valid | jq '.question = ("é" * 200) | .options += [{"key": "c", "label": "C", "consequence": "c"}]')"
  [ "$STATUS" -eq 0 ] || fail "a question of 200 characters with three options was refused: $OUT"
  jq -e '(.question | length) == 200 and (.options | length) == 3' <<< "$OUT" >/dev/null \
    || fail "the accepted decision lost its question or an option: $OUT"
}

test_list_prints_pending_oldest_first() {
  need_po
  fixture
  local inbox="$F/.polype/inbox" start elapsed dir
  decision_file "$inbox" d-0010 pending
  decision_file "$inbox" d-0002 pending
  decision_file "$inbox" d-0001 answered
  decision_file "$inbox" d-0003 pending
  for dir in "$F" "$W"; do
    start="$(date +%s%N)"
    po_in "$dir" inbox
    elapsed=$(( ($(date +%s%N) - start) / 1000000 ))
    [ "$STATUS" -eq 0 ] || fail "po inbox exited $STATUS in $dir: $OUT"
    one_object "po inbox in $dir"
    jq -e '(.pending | map(.id)) == ["d-0002", "d-0003", "d-0010"]' <<< "$OUT" >/dev/null \
      || fail "po inbox in $dir does not list the pending decisions oldest first: $OUT"
    jq -e 'all(.pending[]; .question == "Which runner runs the suite?" and (.options | length) == 2 and .status == "pending")' \
      <<< "$OUT" >/dev/null || fail "po inbox does not give whole decisions: $OUT"
    [ "$elapsed" -lt 1000 ] || fail "po inbox took ${elapsed} ms, not under a second"
  done

  po_in "$F" inbox d-0001
  [ "$STATUS" -eq 0 ] || fail "po inbox d-0001 exited $STATUS: $OUT"
  one_object "po inbox d-0001"
  jq -e '.id == "d-0001" and .status == "answered" and .answer.key == "a"' <<< "$OUT" >/dev/null \
    || fail "po inbox d-0001 does not give the answered decision: $OUT"
  po_in "$W" inbox d-0003
  [ "$STATUS" -eq 0 ] || fail "po inbox d-0003 exited $STATUS: $OUT"
  jq -e '.id == "d-0003" and .status == "pending" and .answer == null' <<< "$OUT" >/dev/null \
    || fail "po inbox d-0003 does not give the pending decision: $OUT"

  rm -rf "$inbox"
  po_in "$F" inbox
  [ "$STATUS" -eq 0 ] || fail "po inbox without its folder exited $STATUS: $OUT"
  jq -e '.pending == []' <<< "$OUT" >/dev/null || fail "po inbox without its folder is not an empty list: $OUT"
}

test_inbox_never_enters_git() {
  need_po
  fixture
  printf '.worktrees/\n' > "$F/.gitignore"
  po_add "$F" "$(valid)"
  refused inbox-not-ignored 1 "po inbox add into a folder git does not ignore"
  [ ! -e "$F/.polype/inbox" ] || fail "po inbox add created the inbox git would commit"

  printf 'private/\n' >> "$F/.gitignore"
  set_inbox private/inbox/
  po_add "$F" "$(valid)"
  [ "$STATUS" -eq 0 ] || fail "po inbox add into an ignored folder of the repository exited $STATUS: $OUT"
  [ -f "$F/private/inbox/d-0001.json" ] || fail "no decision in the ignored folder private/inbox/"

  set_inbox "$SCRATCH/elsewhere/inbox"
  po_add "$W" "$(valid)"
  [ "$STATUS" -eq 0 ] || fail "po inbox add into a folder outside the repository exited $STATUS: $OUT"
  [ -f "$SCRATCH/elsewhere/inbox/d-0001.json" ] || fail "no decision in the folder outside the repository"
  po_in "$F" inbox
  jq -e '(.pending | map(.id)) == ["d-0001"]' <<< "$OUT" >/dev/null || fail "po inbox does not read the folder outside: $OUT"

  export CLAUDE_CONFIG_DIR="$SCRATCH/claude"
  local P="$SCRATCH/p" bin="$SCRATCH/bin" out cmd
  mkdir -p "$CLAUDE_CONFIG_DIR" "$P" "$bin"
  git -C "$P" init -q -b main
  # cargo hidden: the installer lays everything but po, which this test does not need.
  for cmd in bash env cat cp mv rm mkdir chmod find sed sort head tail grep awk git wc cksum dirname basename readlink touch tr jq; do
    if command -v "$cmd" >/dev/null 2>&1; then ln -s "$(command -v "$cmd")" "$bin/$cmd"; fi
  done
  out="$(PATH="$bin" "$bin/bash" "$POLYPE" install "$P" 2>&1)" || fail "install failed: $out"
  [ "$(grep -cxF '.polype/inbox/' "$P/.gitignore" || true)" = 1 ] || fail "install did not add .polype/inbox/ to .gitignore once: $(cat "$P/.gitignore")"
  grep -qF 'added .polype/inbox/ to .gitignore' <<< "$out" || fail "install did not say it ignored the inbox: $out"
  out="$(PATH="$bin" "$bin/bash" "$POLYPE" update "$P" 2>&1)" || fail "update failed: $out"
  [ "$(grep -cxF '.polype/inbox/' "$P/.gitignore" || true)" = 1 ] || fail "update added .polype/inbox/ a second time"
  if grep -qF 'added .polype/inbox/' <<< "$out"; then fail "update said it added a line already there: $out"; fi
}

test_sensitive_decisions_carry_no_detail() {
  need_po
  fixture
  local inbox="$F/.polype/inbox" context
  for context in docs/report.md "$F/docs/report.md" "$W/report.md"; do
    po_add "$F" "$(valid | jq --arg c "$context" '.sensitive = true | .motive = "security" | .context = $c')"
    refused sensitive-context-in-repo 1 "a sensitive decision whose context is $context"
  done
  po_add "$F" "$(valid | jq '.sensitive = true | .motive = "security" | del(.context)')"
  [ "$STATUS" -eq 1 ] || fail "a sensitive decision without context exited $STATUS instead of 1: $OUT"
  one_object "a sensitive decision without context"
  [ "$(files_in "$inbox")" = 0 ] || fail "a refused sensitive decision left a file: $(ls -A "$inbox")"

  po_add "$F" "$(valid | jq --arg c "$SCRATCH/private/report.md" '.sensitive = true | .motive = "security" | .context = $c')"
  [ "$STATUS" -eq 0 ] || fail "a sensitive decision whose context lies outside the repository exited $STATUS: $OUT"
  jq -e '.sensitive == true and .id == "d-0001"' <<< "$OUT" >/dev/null || fail "the sensitive decision was not written as such: $OUT"
  po_add "$F" "$(valid)"
  po_in "$F" inbox
  jq -e '(.pending | map(.id)) == ["d-0001", "d-0002"] and ([.pending[] | keys] | unique | length) == 1' <<< "$OUT" >/dev/null \
    || fail "po inbox does not give the sensitive decision like the others: $OUT"
}
