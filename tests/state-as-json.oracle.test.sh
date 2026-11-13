#!/usr/bin/env bash
# s164 — the oracle of the story: `po state` prints a project's state as one JSON object, read from
# files and git only, and the installer builds `po` from its sources (ADR-0106, ADR-0107, ADR-0117).

PO="${PO:-${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po}"
POLYPE="$ROOT/bin/polype"
STORIES="s01-worktree-only s02-plan-draft s03-plan-approved s04-code-recorded s05-review-blocked s06-review-passed s07-landed"

need_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
}

# The version the installer stamps into .polype/version, which po must carry as its own.
shipped_version() { sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$POLYPE"; }

# po_in <dir> <args...>: sets OUT (stdout) and STATUS; never fails by itself.
po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

# OUT is exactly one JSON value, an object carrying "contract": 1.
one_object() {
  [ "$(jq -s 'length' <<< "$OUT" 2>/dev/null)" = 1 ] || fail "$1: stdout is not one JSON value: $OUT"
  jq -e 'type == "object" and .contract == 1' <<< "$OUT" >/dev/null \
    || fail "$1: not an object carrying \"contract\": 1: $OUT"
}

# A fresh $SCRATCH (not a repository itself) holding a Polype project at $F: settings, stories and
# framing files on main, the gate, the version stamp. Removed when the test process exits.
fixture() {
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  F="$SCRATCH/project"
  mkdir -p "$F/.polype/hooks" "$F/docs/reviews" "$F/src"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cp "$METHOD/hooks/po-gate.sh" "$F/.polype/hooks/po-gate.sh"
  chmod +x "$F/.polype/hooks/po-gate.sh"
  shipped_version > "$F/.polype/version"
  cat > "$F/AGENTS.local.md" <<'EOF'
# fixture — Polype settings

```
Merge mode:        local
Target branch:     main
Ship confirmation: automatic
QA stage:          —
Worktree root:     .worktrees/
Entry mode:        —
Parallel:          3
Max attempts:      2
Decision inbox:    .polype/inbox/
```
EOF
  local id
  {
    printf '# Stories\n\n## M1 — Fixture\n\n'
    for id in $STORIES; do printf '### %s — %s\n- **Complexité** : 1\n- **Surface** : command\n\n' "$id" "$id"; done
  } > "$F/docs/stories.md"
  printf 'Stories ready: yes\n' > "$F/docs/reviews/stories.md"
  printf '# Architecture\n' > "$F/docs/architecture.md"
  printf '.worktrees/\n.polype/inbox/\n' > "$F/.gitignore"
  echo app > "$F/src/app.txt"
  git -C "$F" add -A
  git -C "$F" commit -qm init
}

# lane <id>: the worktree of story <id> at <Worktree root><id>, on story/<id>; sets W.
lane() { W="$F/.worktrees/$1"; git -C "$F" worktree add -q -b "story/$1" "$W" main; }
plan_in() { mkdir -p "$W/docs/plans"; printf -- '---\nvalidated: %s\n---\n# Plan — %s\n' "$2" "$1" > "$W/docs/plans/$1.md"; }
code_in() { echo "$1" > "$W/src/$1.txt"; git -C "$W" add -A; git -C "$W" commit -qm "$1: code"; }
# A complete verification record bound to the code committed in the lane.
record_in() {
  mkdir -p "$W/docs/verif"
  printf 'Tree: %s\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | — | none here |\n\nVerification status: complete\n' \
    "$(git -C "$W" rev-parse 'HEAD^{tree}')" > "$W/docs/verif/$1.md"
}
# review_in <id> <yes|no>: a complete review of the lane's code with that verdict.
review_in() {
  mkdir -p "$W/docs/reviews"
  printf 'Review status: complete\nFix loop: 0\nReviewed tree: %s\n\n## Findings\nnone\n\nMax severity: none\nShip allowed: %s\n' \
    "$(git -C "$W" rev-parse 'HEAD^{tree}')" "$2" > "$W/docs/reviews/$1.md"
}

# decision <dir> <id> <status>: one decision file in the shape of docs/interface-agent.md.
decision() {
  local answer=null
  [ "$3" = answered ] && answer='{"key": "a", "at": "2026-11-12T14:20:00+01:00"}'
  mkdir -p "$1"
  cat > "$1/$2.json" <<EOF
{
  "id": "$2",
  "asked": "2026-11-12T14:05:00+01:00",
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
  "blocks": ["s01-worktree-only"],
  "status": "$3",
  "answer": $answer
}
EOF
}

# Every path under the given directories, with the checksum of each file.
snapshot() {
  local path
  find "$@" | sort | while IFS= read -r path; do
    if [ -f "$path" ] && [ ! -L "$path" ]; then printf '%s %s\n' "$path" "$(cksum < "$path")"; else printf '%s\n' "$path"; fi
  done
}

test_state_prints_one_json_object() {
  need_po
  fixture
  lane s03-plan-approved
  plan_in s03-plan-approved yes
  local dir verb
  for dir in "$F" "$W"; do
    po_in "$dir" state
    [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS in $dir: $OUT"
    one_object "po state in $dir"
    jq -en --argjson o "$OUT" 'all("project", "commit", "method_version", "framing", "milestone", "lanes", "waiting"; . as $k | $o | has($k))' \
      >/dev/null || fail "a field of the contract is missing from po state in $dir: $OUT"
    jq -e '.project == "project" and (.lanes | length) == 1 and .lanes[0].story == "s03-plan-approved"' <<< "$OUT" >/dev/null \
      || fail "po state in $dir does not describe the project and its one lane: $OUT"
    jq -en --argjson o "$OUT" 'all("ready", "held", "session", "bounds", "shipped"; . as $k | $o | has($k) and .[$k] == null)' \
      >/dev/null || fail "a field another story computes is not present as null in $dir: $OUT"
    jq -e 'all(.lanes[]; has("next") and .next == null)' <<< "$OUT" >/dev/null \
      || fail "lanes[].next is not present as null in $dir: $OUT"
  done

  mkdir -p "$SCRATCH/outside" "$SCRATCH/plain"
  git -C "$SCRATCH/plain" init -q -b main
  for dir in "$SCRATCH/outside" "$SCRATCH/plain"; do
    po_in "$dir" state
    [ "$STATUS" -eq 2 ] || fail "po state outside a Polype project ($dir) exited $STATUS instead of 2: $OUT"
    one_object "po state outside a Polype project"
    jq -e '.error | type == "string" and length > 0' <<< "$OUT" >/dev/null || fail "no error code outside a project: $OUT"
  done

  for verb in next answer run continue; do
    po_in "$F" "$verb"
    [ "$STATUS" -eq 2 ] || fail "po $verb exited $STATUS instead of 2: $OUT"
    one_object "po $verb"
    jq -e '.error == "not-built"' <<< "$OUT" >/dev/null || fail "po $verb does not say not-built: $OUT"
  done

  po_in "$F" no-such-verb
  [ "$STATUS" -eq 2 ] || fail "an unknown verb exited $STATUS instead of 2: $OUT"
  one_object "po no-such-verb"
  jq -e '.error | type == "string" and length > 0' <<< "$OUT" >/dev/null || fail "an unknown verb gave no error code: $OUT"
}

test_state_reads_only_files_and_git() {
  need_po
  fixture
  lane s06-review-passed
  plan_in s06-review-passed yes
  code_in s06-review-passed
  record_in s06-review-passed
  review_in s06-review-passed yes
  decision "$F/.polype/inbox" d-0001 pending

  local stubs="$SCRATCH/stubs" calls="$SCRATCH/calls" real_git cmd before start elapsed
  real_git="$(command -v git)"
  mkdir -p "$stubs"
  : > "$calls"
  for cmd in gh claude curl wget ssh; do
    printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" %s "$*" >> "%s"\nexit 0\n' "$cmd" "$calls" > "$stubs/$cmd"
    chmod +x "$stubs/$cmd"
  done
  printf '#!/usr/bin/env bash\nprintf "git %%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$calls" "$real_git" > "$stubs/git"
  chmod +x "$stubs/git"

  before="$(snapshot "$F")"
  STATUS=0
  OUT="$(cd "$F" && PATH="$stubs:$PATH" "$PO" state 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  one_object "po state"
  [ "$(snapshot "$F")" = "$before" ] || fail "po state changed a file of the project, its worktrees or its .git"
  if grep -qE '^(gh|claude|curl|wget|ssh) ' "$calls"; then fail "po state ran a forge, a model or the network: $(cat "$calls")"; fi
  if grep '^git ' "$calls" | grep -qwE 'fetch|pull|push|ls-remote|commit|checkout|switch|stash|worktree add|update-ref'; then
    fail "po state ran a git command that writes or asks a remote: $(grep '^git ' "$calls")"
  fi

  start="$(date +%s%N)"
  po_in "$ROOT" state
  elapsed=$(( ($(date +%s%N) - start) / 1000000 ))
  one_object "po state on this repository"
  [ "$elapsed" -lt 1000 ] || fail "po state took ${elapsed} ms on this repository, not under a second"
}

test_lane_stage_follows_the_gates() {
  need_po
  fixture
  lane s01-worktree-only

  lane s02-plan-draft
  plan_in s02-plan-draft no

  lane s03-plan-approved
  plan_in s03-plan-approved yes

  lane s04-code-recorded
  plan_in s04-code-recorded yes
  code_in s04-code-recorded
  record_in s04-code-recorded

  lane s05-review-blocked
  plan_in s05-review-blocked yes
  code_in s05-review-blocked
  record_in s05-review-blocked
  review_in s05-review-blocked no

  lane s06-review-passed
  plan_in s06-review-passed yes
  code_in s06-review-passed
  record_in s06-review-passed
  review_in s06-review-passed yes

  lane s07-landed
  plan_in s07-landed yes
  code_in s07-landed
  record_in s07-landed
  review_in s07-landed yes
  git -C "$F" commit -q --allow-empty -m 's07-landed: Landed'

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  one_object "po state"
  local id stage got bad=""
  while read -r id stage; do
    got="$(jq -r --arg id "$id" '[.lanes[] | select(.story == $id) | .stage] | if length == 1 then .[0] else "missing" end' <<< "$OUT")"
    [ "$got" = "$stage" ] || bad+="$id: $got instead of $stage; "
  done <<'EOF'
s01-worktree-only research
s02-plan-draft plan
s03-plan-approved execute
s04-code-recorded review
s05-review-blocked review
s06-review-passed ship
s07-landed ship
EOF
  [ -z "$bad" ] || fail "lane stages do not follow the gates: $bad"
}

test_waiting_reads_the_inbox_setting() {
  need_po
  fixture
  decision "$F/.polype/inbox" d-0001 pending
  decision "$F/.polype/inbox" d-0002 answered
  decision "$F/.polype/inbox" d-0003 pending

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  one_object "po state"
  jq -e '.waiting == ["d-0001", "d-0003"]' <<< "$OUT" >/dev/null || fail "waiting is not the pending decisions: $OUT"

  rm -rf "$F/.polype/inbox"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS without an inbox folder: $OUT"
  jq -e '.waiting == []' <<< "$OUT" >/dev/null || fail "waiting is not [] when the inbox folder is missing: $OUT"

  sed -i '/^Decision inbox:/d' "$F/AGENTS.local.md"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS without the Decision inbox line: $OUT"
  one_object "po state without the setting"
  jq -e 'has("waiting") and .waiting == null' <<< "$OUT" >/dev/null || fail "waiting is not null without the setting: $OUT"
  jq -e '.warnings | tostring | contains("Decision inbox")' <<< "$OUT" >/dev/null \
    || fail "warnings do not name the missing Decision inbox setting: $OUT"
}

test_installer_builds_po_from_sources() {
  command -v cargo >/dev/null 2>&1 || fail "cargo is required by this test"
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  export CLAUDE_CONFIG_DIR="$SCRATCH/claude"
  local H="$CLAUDE_CONFIG_DIR" P="$SCRATCH/p" Q="$SCRATCH/q" bin="$SCRATCH/bin" out status cmd
  mkdir -p "$H" "$P" "$Q" "$bin"
  git -C "$P" init -q -b main
  git -C "$Q" init -q -b main

  out="$(bash "$POLYPE" install "$P" 2>&1)" || fail "install failed: $out"
  [ -x "$H/polype/po" ] || fail "install did not lay po at $H/polype/po: $out"
  STATUS=0
  OUT="$(cd "$P" && "$H/polype/po" state 2>/dev/null)" || STATUS=$?
  one_object "the installed po"

  rm -f "$H/polype/po"
  out="$(bash "$POLYPE" check "$P" 2>&1)" || true
  grep -qF 'po missing' <<< "$out" || fail "check did not report the missing po: $out"
  out="$(bash "$POLYPE" update "$P" 2>&1)" || fail "update failed: $out"
  [ -x "$H/polype/po" ] || fail "update did not build po again: $out"

  rm -f "$H/polype/po"
  for cmd in bash env cat cp mv rm mkdir chmod find sed sort head tail grep awk git wc cksum dirname basename readlink touch tr jq; do
    if command -v "$cmd" >/dev/null 2>&1; then ln -s "$(command -v "$cmd")" "$bin/$cmd"; fi
  done
  if PATH="$bin" command -v cargo >/dev/null 2>&1; then fail "cargo is still reachable from the test PATH"; fi
  status=0
  out="$(PATH="$bin" "$bin/bash" "$POLYPE" install "$Q" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "install without cargo exited $status: $out"
  [ -f "$Q/AGENTS.md" ] && [ -x "$Q/.polype/hooks/po-gate.sh" ] || fail "install without cargo did not lay the rest: $out"
  [ ! -e "$H/polype/po" ] || fail "a po appeared without cargo"
  grep -qF 'cargo not found' <<< "$out" || fail "install without cargo did not say why po is missing: $out"
}

test_po_warns_on_another_version() {
  need_po
  fixture
  local mismatch
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  one_object "po state"
  jq -e '[.warnings[]? | select(.code == "method-version-mismatch")] | length == 0' <<< "$OUT" >/dev/null \
    || fail "po warned although .polype/version is its own version $(shipped_version): $OUT"

  printf '0.0.1-other\n' > "$F/.polype/version"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state refused to answer on another version (exit $STATUS): $OUT"
  one_object "po state on another version"
  mismatch="$(jq -c '[.warnings[] | select(.code == "method-version-mismatch")]' <<< "$OUT")"
  [ "$(jq 'length' <<< "$mismatch")" = 1 ] || fail "no single method-version-mismatch warning: $OUT"
  grep -qF '"0.0.1-other"' <<< "$mismatch" || fail "the warning does not name the project's version: $mismatch"
  grep -qF "\"$(shipped_version)\"" <<< "$mismatch" || fail "the warning does not name po's version: $mismatch"
  jq -e '.method_version == "0.0.1-other" and has("lanes") and has("framing")' <<< "$OUT" >/dev/null \
    || fail "po did not answer the state as well: $OUT"
}
