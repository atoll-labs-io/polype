#!/usr/bin/env bash
# s166 — the oracle of the story: `po answer` accepts only a listed option of a pending decision and
# launches nothing; `po inbox --answered` lists what the lead has not consumed yet, and
# `po inbox consume` takes a decision out of that list. `rules_say_who_consumes` is judged in review.

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# po_in <dir> <args...>: sets OUT (stdout) and STATUS; never fails by itself.
po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

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

# Every path under <dir> with the sum of each file, hidden ones included.
snapshot() {
  local path
  find "$@" | sort | while IFS= read -r path; do
    if [ -f "$path" ] && [ ! -L "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"; else printf '%s\n' "$path"; fi
  done
}

DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([+-][0-9]{2}:[0-9]{2}|Z)$'

# A fresh Polype project at $F (under $SCRATCH, itself no repository) whose .gitignore ignores the
# inbox, with one story worktree at $W, and its inbox at $I.
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

# ask: one decision posed through `po inbox add`, options a and b; sets ID.
ask() {
  local out
  out="$(cd "$F" && "$PO" inbox add 2>/dev/null <<'EOF'
{
  "motive": "strategic",
  "question": "Which runner runs the suite?",
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
)" || fail "po inbox add failed: $out"
  ID="$(jq -r '.id' <<< "$out")"
}

test_answer_accepts_only_a_listed_option() {
  need_po
  fixture
  ask
  local file="$I/$ID.json" before key
  before="$(cksum < "$file")"
  for key in z A ' a' 'a ' '' '$(touch pwned)' '"a"' 'a;b'; do
    po_in "$F" answer "$ID" "$key"
    refused not-an-option 1 "po answer $ID with the key [$key]"
    [ "$(cksum < "$file")" = "$before" ] || fail "a refused key [$key] changed $file"
  done
  [ ! -e "$F/pwned" ] && [ ! -e "$SCRATCH/pwned" ] || fail "a key was handed to a shell"

  po_in "$W" answer "$ID" b
  [ "$STATUS" -eq 0 ] || fail "po answer $ID b from a story worktree exited $STATUS: $OUT"
  one_object "po answer $ID b"
  jq -e --arg id "$ID" '.id == $id and .status == "answered" and .answer.key == "b" and .question == "Which runner runs the suite?"' \
    <<< "$OUT" >/dev/null || fail "po answer did not return the answered decision: $OUT"
  jq -e --arg re "$DATE_RE" '.answer.at | test($re)' <<< "$OUT" >/dev/null \
    || fail "answer.at is not a date with its offset: $OUT"
  [ "$(jq -S 'del(.contract)' <<< "$OUT")" = "$(jq -S . "$file")" ] \
    || fail "the decision file differs from the object po answer returned: $(cat "$file")"
  [ ! -e "$W/.polype/inbox" ] || fail "po answer wrote into the worktree's own .polype/inbox"
  po_in "$F" inbox "$ID"
  jq -e '.status == "answered" and .answer.key == "b"' <<< "$OUT" >/dev/null \
    || fail "po inbox $ID does not show the answer: $OUT"
}

test_answer_refuses_twice_and_unknown() {
  need_po
  fixture
  ask
  po_in "$F" answer "$ID" a
  [ "$STATUS" -eq 0 ] || fail "the first answer exited $STATUS: $OUT"

  local before id
  before="$(snapshot "$F")"
  po_in "$F" answer "$ID" a
  refused already-answered 1 "a second answer to $ID"
  po_in "$W" answer "$ID" b
  refused already-answered 1 "a second answer to $ID with another key"
  for id in d-0999 ../AGENTS.local d-1/../x D-0001; do
    po_in "$F" answer "$id" a
    refused unknown-decision 1 "po answer $id"
  done
  [ "$(snapshot "$F")" = "$before" ] || fail "a refused answer wrote something in the project"
  po_in "$F" inbox "$ID"
  jq -e '.answer.key == "a"' <<< "$OUT" >/dev/null || fail "the first answer did not stay: $OUT"
}

test_answer_launches_nothing() {
  need_po
  fixture
  ask
  local stubs="$SCRATCH/stubs" calls="$SCRATCH/calls" real_git cmd before
  real_git="$(command -v git)"
  mkdir -p "$stubs"
  : > "$calls"
  for cmd in claude gh codex curl wget ssh tmux nohup setsid polype po; do
    printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" %s "$*" >> "%s"\nexit 0\n' "$cmd" "$calls" > "$stubs/$cmd"
    chmod +x "$stubs/$cmd"
  done
  printf '#!/usr/bin/env bash\nprintf "git %%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$calls" "$real_git" > "$stubs/git"
  chmod +x "$stubs/git"

  before="$(snapshot "$F" | grep -vF "$I/")"
  STATUS=0
  OUT="$(cd "$F" && PATH="$stubs:$PATH" "$PO" answer "$ID" a 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po answer exited $STATUS: $OUT"
  one_object "po answer"
  if grep -vE '^git ' "$calls" | grep -q .; then fail "po answer launched a command: $(grep -vE '^git ' "$calls")"; fi
  if grep '^git ' "$calls" | grep -qwE 'fetch|pull|push|ls-remote|commit|add|checkout|switch|stash|worktree|update-ref|hook|config'; then
    fail "po answer ran a git command that writes or asks a remote: $(grep '^git ' "$calls")"
  fi
  [ "$(snapshot "$F" | grep -vF "$I/")" = "$before" ] || fail "po answer changed a file outside the inbox"
  [ "$(find "$I" -type f | wc -l | tr -d ' ')" = 1 ] || fail "po answer left a file beside the decision: $(ls -A "$I")"
}

test_answered_decisions_are_listed_until_consumed() {
  need_po
  fixture
  local first second third
  ask; first="$ID"
  ask; second="$ID"
  ask; third="$ID"
  po_in "$F" inbox --answered
  [ "$STATUS" -eq 0 ] || fail "po inbox --answered exited $STATUS: $OUT"
  one_object "po inbox --answered"
  jq -e '.answered == []' <<< "$OUT" >/dev/null || fail "pending decisions are listed as answered: $OUT"

  po_in "$F" answer "$third" a
  po_in "$F" answer "$first" b
  po_in "$W" inbox --answered
  [ "$STATUS" -eq 0 ] || fail "po inbox --answered from a worktree exited $STATUS: $OUT"
  jq -e --arg a "$first" --arg c "$third" '(.answered | map(.id)) == [$a, $c]' <<< "$OUT" >/dev/null \
    || fail "po inbox --answered does not list the answered decisions oldest first: $OUT"
  jq -e --arg a "$first" '.answered[0].answer.key == "b" and .answered[0].question == "Which runner runs the suite?"' \
    <<< "$OUT" >/dev/null || fail "po inbox --answered does not give whole decisions: $OUT"
  po_in "$F" inbox
  jq -e --arg b "$second" '(.pending | map(.id)) == [$b]' <<< "$OUT" >/dev/null \
    || fail "po inbox no longer lists only the pending decision: $OUT"

  local ref="docs/decisions/ADR-0120-hosted-runners.md"
  po_in "$F" inbox consume "$first" "$ref"
  [ "$STATUS" -eq 0 ] || fail "po inbox consume exited $STATUS: $OUT"
  one_object "po inbox consume"
  jq -e --arg id "$first" --arg r "$ref" '.id == $id and .status == "answered" and .consumed.ref == $r' <<< "$OUT" >/dev/null \
    || fail "po inbox consume does not return the decision with what it produced: $OUT"
  jq -e --arg re "$DATE_RE" '.consumed.at | test($re)' <<< "$OUT" >/dev/null \
    || fail "consumed.at is not a date with its offset: $OUT"
  po_in "$F" inbox --answered
  jq -e --arg c "$third" '(.answered | map(.id)) == [$c]' <<< "$OUT" >/dev/null \
    || fail "a consumed decision is still listed as answered: $OUT"
  po_in "$F" inbox "$first"
  jq -e --arg r "$ref" '.status == "answered" and .answer.key == "b" and .consumed.ref == $r' <<< "$OUT" >/dev/null \
    || fail "po inbox $first does not keep the answer and what it produced: $OUT"

  po_in "$W" inbox consume "$third" s02-hosted-runners
  [ "$STATUS" -eq 0 ] || fail "po inbox consume from a worktree exited $STATUS: $OUT"
  po_in "$F" inbox --answered
  jq -e '.answered == []' <<< "$OUT" >/dev/null || fail "every answered decision is consumed, yet some are listed: $OUT"
}
