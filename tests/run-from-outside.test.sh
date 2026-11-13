#!/usr/bin/env bash
# s169 — task tests of `po run`: it writes only under the git common dir, records nothing when the
# launch fails, and never guesses a session it cannot read. The fixture is copied from the oracle,
# not sourced, so its tests are not run twice.

po_in() { local dir="$1"; shift; STATUS=0; OUT="$(cd "$dir" && "$PO" "$@" 2>/dev/null)" || STATUS=$?; }

refused() {
  [ "$STATUS" -eq "$2" ] || fail "$3: exited $STATUS instead of $2: $OUT"
  jq -e --arg c "$1" '.contract == 1 and .error == $c' <<< "$OUT" >/dev/null || fail "$3: error is not $1: $OUT"
}

# The stand-in for Claude Code: a launch fails when $SCRATCH/fail exists, and `agents --json`
# prints no JSON when $SCRATCH/garbage exists.
setup() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  export CLAUDE_CONFIG_DIR="$SCRATCH/claude"
  mkdir -p "$CLAUDE_CONFIG_DIR/agents" "$SCRATCH/calls" "$SCRATCH/bin"
  local name
  for name in implementer qa reviewer; do cp "$METHOD/agents/$name.md" "$CLAUDE_CONFIG_DIR/agents/$name.md"; done
  cat > "$SCRATCH/bin/claude" <<EOF
#!/usr/bin/env bash
S="$SCRATCH"
EOF
  cat >> "$SCRATCH/bin/claude" <<'EOF'
n=$(( $(ls "$S/calls" | wc -l) + 1 ))
printf '%s\n' "$@" > "$S/calls/$n"
if [ "${1:-}" = agents ]; then
  if [ -e "$S/garbage" ]; then echo "Sessions: none"; exit 0; fi
  if [ -s "$S/live" ]; then
    u="$(cat "$S/live")"
    printf '[{"pid": 4242, "sessionId": "%s", "state": "working"}]\n' "$u"
  else
    echo '[]'
  fi
  exit 0
fi
[ -e "$S/fail" ] && { echo "launch refused" >&2; exit 1; }
u="" prev=""
for a in "$@"; do
  case "$prev" in --session-id|--resume) u="$a" ;; esac
  prev="$a"
done
printf '%s\n' "$u" > "$S/live"
EOF
  chmod +x "$SCRATCH/bin/claude"
  export PO_CLAUDE="$SCRATCH/bin/claude"

  F="$SCRATCH/p"
  mkdir -p "$F/.polype/hooks" "$F/docs/reviews" "$F/src"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cp "$METHOD/hooks/po-gate.sh" "$METHOD/hooks/po-bounds.sh" "$F/.polype/hooks/"
  chmod +x "$F/.polype/hooks/po-gate.sh" "$F/.polype/hooks/po-bounds.sh"
  sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype" > "$F/.polype/version"
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
  printf '# Stories\n\n## M1 — Fixture\n\n### s01-alpha — s01-alpha\n- **Complexité** : 1\n- **Surface** : command\n\n' > "$F/docs/stories.md"
  printf 'Stories ready: yes\n' > "$F/docs/reviews/stories.md"
  printf '# Architecture\n' > "$F/docs/architecture.md"
  printf '.worktrees/\n.polype/inbox/\n' > "$F/.gitignore"
  echo app > "$F/src/app.txt"
  git -C "$F" add -A
  git -C "$F" commit -qm init
}

launch_count() { grep -lx -- '--bg' "$SCRATCH"/calls/* 2>/dev/null | wc -l; }

# Every file of the project outside .git, with its content.
work_tree() { (cd "$F" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha1sum); }

test_run_leaves_the_work_tree_clean() {
  setup
  local before
  before="$(work_tree)"
  po_in "$F" run
  [ "$STATUS" -eq 0 ] || fail "po run exited $STATUS: $OUT"
  [ -z "$(git -C "$F" status --porcelain --ignored)" ] || fail "po run left files in the work tree: $(git -C "$F" status --porcelain --ignored)"
  [ "$(work_tree)" = "$before" ] || fail "po run changed a file outside .git"
  [ -f "$F/.git/polype/lead-session.json" ] || fail "po run left no session record under the git common dir"
  [ ! -e "$F/.git/polype/run.lock" ] || fail "po run left its launch lock behind"
}

test_launch_failure_records_nothing() {
  setup
  touch "$SCRATCH/fail"
  po_in "$F" run
  refused launch-failed 2 "po run when Claude Code refuses the launch"
  [ ! -e "$F/.git/polype/lead-session.json" ] || fail "a session was recorded although the launch failed"
  po_in "$F" state
  jq -e '.session == {"running": false, "id": null}' <<< "$OUT" >/dev/null \
    || fail "po state names a session after a failed launch: $(jq -c '.session' <<< "$OUT")"
}

test_unreadable_listing_is_never_guessed() {
  setup
  po_in "$F" run
  [ "$STATUS" -eq 0 ] || fail "po run exited $STATUS: $OUT"
  rm -f "$SCRATCH/live"
  touch "$SCRATCH/garbage"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e 'has("session") and .session == null' <<< "$OUT" >/dev/null \
    || fail "po state guessed a session from a listing it cannot read: $(jq -c '.session' <<< "$OUT")"
  po_in "$F" run
  refused session-unreadable 2 "po run with an unreadable listing"
  [ "$(launch_count)" -eq 1 ] || fail "po run launched again although it could not tell whether the lead runs"
}

# bounds_are <held|unproven> <what>: po state reports it, and po run launches only when held.
bounds_are() {
  po_in "$F" state
  jq -e --arg b "$1" '.bounds == $b' <<< "$OUT" >/dev/null || fail "$2: bounds $(jq -c '.bounds' <<< "$OUT") instead of $1"
  [ "$1" = held ] && return 0
  po_in "$F" run
  refused bounds-unproven 1 "$2"
}

test_bounds_are_proven_not_named() {
  setup
  bounds_are held "Polype's three global subagents and the project's hook"
  local name agents="$CLAUDE_CONFIG_DIR/agents"
  for name in implementer qa reviewer; do
    printf -- '---\nname: %s\ndescription: my own %s\n---\n' "$name" "$name" > "$agents/$name.md"
    bounds_are unproven "a global $name.md that carries no po-bounds hook"
    cp "$METHOD/agents/$name.md" "$agents/$name.md"
  done
  sed -i 's/po-bounds.sh reviewer/po-bounds.sh implementer/' "$agents/reviewer.md"
  bounds_are unproven "a reviewer whose hook bounds it as another subagent"
  cp "$METHOD/agents/reviewer.md" "$agents/reviewer.md"
  chmod -x "$F/.polype/hooks/po-bounds.sh"
  bounds_are unproven "a project whose po-bounds.sh cannot be run"
  rm "$F/.polype/hooks/po-bounds.sh"
  bounds_are unproven "a project without the po-bounds.sh its subagents call"
  [ "$(launch_count)" -eq 0 ] || fail "po run launched a session with unproven bounds"
}

test_stale_launch_lock_is_taken_over() {
  setup
  local lock="$F/.git/polype/run.lock" dead live
  mkdir -p "$F/.git/polype"
  sleep 60 & live=$!
  printf '%s\n' "$live" > "$lock"
  po_in "$F" run
  kill "$live" 2>/dev/null
  refused already-running 1 "po run while a live po holds the launch lock"
  [ "$(cat "$lock" 2>/dev/null)" = "$live" ] || fail "po run removed the lock of a po that still runs"
  [ "$(launch_count)" -eq 0 ] || fail "po run launched past a live lock"

  ( exit 0 ) & dead=$!
  wait "$dead"
  printf '%s\n' "$dead" > "$lock"
  po_in "$F" run
  [ "$STATUS" -eq 0 ] || fail "po run stayed blocked by the lock of a po that died: $STATUS $OUT"
  [ ! -e "$lock" ] || fail "po run left the stale lock behind"
  rm -f "$SCRATCH/live"

  sleep 60 & live=$!
  printf '%s\n' "$live" > "$lock"
  touch -d '-1 hour' "$lock"
  po_in "$F" run
  kill "$live" 2>/dev/null
  [ "$STATUS" -eq 0 ] || fail "po run stayed blocked by an hour-old lock: $STATUS $OUT"
}

test_consumed_answer_is_nothing_to_do() {
  setup
  git -C "$F" commit -q --allow-empty -m "s01-alpha: s01-alpha"
  mkdir -p "$F/.polype/inbox"
  cat > "$F/.polype/inbox/d-0001.json" <<'JSON'
{
  "id": "d-0001",
  "asked": "2026-11-12T14:05:00+01:00",
  "motive": "strategic",
  "sensitive": false,
  "question": "Which runner runs the suite?",
  "context": null,
  "options": [{"key": "a", "label": "Hosted runners", "consequence": "nothing to install"}],
  "recommended": "a",
  "why": "the check is a neutral script",
  "reversible": true,
  "blocks": [],
  "status": "answered",
  "answer": {"key": "a", "at": "2026-11-12T14:20:00+01:00"},
  "consumed": {"ref": "docs/decisions/ADR-0001-x.md", "at": "2026-11-12T15:00:00+01:00"}
}
JSON
  po_in "$F" run
  refused nothing-to-do 1 "po run when the only answered decision is already consumed"
  [ "$(launch_count)" -eq 0 ] || fail "po run launched for a decision already consumed"
}
