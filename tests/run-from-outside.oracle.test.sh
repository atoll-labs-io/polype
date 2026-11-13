#!/usr/bin/env bash
# s169 — the oracle of the story: `po run` and `po continue` launch the project lead through Claude
# Code, which the test replaces by a stand-in named by PO_CLAUDE; they refuse a second session,
# unproven bounds, nothing to do and any free text. `docs_show_the_agent_loop` is judged in review.

STORIES="s01-alpha s02-beta"
DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([+-][0-9]{2}:[0-9]{2}|Z)$'

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

# started <what>: OUT is one launch reply carrying session, started and command.
started() {
  [ "$STATUS" -eq 0 ] || fail "$1: exited $STATUS: $OUT"
  one_object "$1"
  jq -e '(.session | type == "string" and length > 0) and (.command | type == "string")' <<< "$OUT" >/dev/null \
    || fail "$1: no session and command in the reply: $OUT"
  jq -e --arg re "$DATE_RE" '.started | type == "string" and test($re)' <<< "$OUT" >/dev/null \
    || fail "$1: started is not a date with its offset: $OUT"
}

# A $SCRATCH (no repository itself), an empty Claude Code configuration, and the stand-in for
# Claude Code. Each call of the stand-in leaves one file under $SCRATCH/calls: its directory, then
# one `arg` line per argument. `agents --json` lists the session made live with a pid, and the
# stopped one without, as Claude Code lists a session whose process is gone.
setup() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  [ -x "$PO" ] || fail "po is not built at $PO (tests/run.sh builds it before the suite)"
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  SCRATCH="$(cd "$SCRATCH" && pwd -P)"
  export CLAUDE_CONFIG_DIR="$SCRATCH/claude"
  mkdir -p "$CLAUDE_CONFIG_DIR" "$SCRATCH/calls" "$SCRATCH/bin"
  cat > "$SCRATCH/bin/claude" <<EOF
#!/usr/bin/env bash
S="$SCRATCH"
EOF
  cat >> "$SCRATCH/bin/claude" <<'EOF'
n=$(( $(ls "$S/calls" | wc -l) + 1 ))
{ printf 'cwd %s\n' "$PWD"; for a in "$@"; do printf 'arg %s\n' "$a"; done; } > "$S/calls/$n"
if [ "${1:-}" = agents ]; then
  entries=()
  if [ -s "$S/live" ]; then
    u="$(cat "$S/live")"
    entries+=("{\"pid\": 4242, \"id\": \"${u:0:8}\", \"cwd\": \"$PWD\", \"kind\": \"background\", \"sessionId\": \"$u\", \"status\": \"busy\", \"state\": \"working\"}")
  fi
  if [ -s "$S/stopped" ]; then
    u="$(cat "$S/stopped")"
    entries+=("{\"id\": \"${u:0:8}\", \"cwd\": \"$PWD\", \"kind\": \"background\", \"sessionId\": \"$u\", \"state\": \"blocked\"}")
  fi
  (IFS=,; printf '[%s]\n' "${entries[*]}")
  exit 0
fi
u="" prev=""
for a in "$@"; do
  case "$prev" in --session-id|--resume) u="$a" ;; esac
  prev="$a"
done
[ -n "$u" ] || { echo "no session id given" >&2; exit 1; }
printf '%s\n' "$u" > "$S/live"
rm -f "$S/stopped"
printf 'Started %s\n' "${u:0:8}"
EOF
  chmod +x "$SCRATCH/bin/claude"
  export PO_CLAUDE="$SCRATCH/bin/claude"
}

# project <dir> <Entry mode>: a Polype project at $F=<dir>; with `—`, its framing is done and both
# stories are ready.
project() {
  F="$1"
  mkdir -p "$F/.polype/hooks" "$F/docs/reviews" "$F/src"
  git -C "$F" init -q -b main
  git -C "$F" config user.email test@example.com
  git -C "$F" config user.name test
  git -C "$F" config commit.gpgsign false
  cp "$METHOD/hooks/po-gate.sh" "$METHOD/hooks/po-bounds.sh" "$F/.polype/hooks/"
  chmod +x "$F/.polype/hooks/po-gate.sh" "$F/.polype/hooks/po-bounds.sh"
  sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$ROOT/bin/polype" > "$F/.polype/version"
  cat > "$F/AGENTS.local.md" <<EOF
# fixture — Polype settings

\`\`\`
Merge mode:        local
Target branch:     main
Ship confirmation: automatic
QA stage:          —
Worktree root:     .worktrees/
Entry mode:        $2
Parallel:          3
Max attempts:      2
Decision inbox:    .polype/inbox/
\`\`\`
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

# agents_in <dir>: the three subagents whose hooks hold the bounds, laid down under <dir>/agents.
agents_in() {
  local name
  mkdir -p "$1/agents"
  for name in implementer qa reviewer; do cp "$METHOD/agents/$name.md" "$1/agents/$name.md"; done
}
global_agents() { agents_in "$CLAUDE_CONFIG_DIR"; }
project_agents() { agents_in "$F/.claude"; }

land_all() { local id; for id in $STORIES; do git -C "$F" commit -q --allow-empty -m "$id: $id"; done; }

# The session the stand-in runs stops: Claude Code still lists it, without a process.
stop_session() { if [ -s "$SCRATCH/live" ]; then mv "$SCRATCH/live" "$SCRATCH/stopped"; fi; }

# decision <id> <status>: one decision of the project's inbox, blocking nothing.
decision() {
  local answer=null
  [ "$2" = answered ] && answer='{"key": "a", "at": "2026-11-12T14:20:00+01:00"}'
  mkdir -p "$F/.polype/inbox"
  cat > "$F/.polype/inbox/$1.json" <<EOF
{
  "id": "$1",
  "asked": "2026-11-12T14:05:00+01:00",
  "motive": "strategic",
  "sensitive": false,
  "question": "Which runner runs the suite?",
  "context": null,
  "options": [
    {"key": "a", "label": "Hosted runners", "consequence": "nothing to install"},
    {"key": "b", "label": "Self-hosted runner", "consequence": "one machine to isolate"}
  ],
  "recommended": "a",
  "why": "the check is a neutral script",
  "reversible": true,
  "blocks": [],
  "status": "$2",
  "answer": $answer
}
EOF
}

# The stand-in's calls that launch a session, oldest first.
launches() { local call; for call in $(ls "$SCRATCH/calls" | sort -n); do grep -qx 'arg --bg' "$SCRATCH/calls/$call" && echo "$SCRATCH/calls/$call"; done; true; }
launch_count() { launches | grep -c . || true; }
last_launch() { launches | tail -n 1; }
args_of() { sed -n 's/^arg //p' "$1"; }
# value_after <flag> <call>: the argument that follows <flag> in that call.
value_after() { args_of "$2" | awk -v f="$1" 'prev == f {print; exit} {prev = $0}'; }

test_run_starts_one_lead_session() {
  setup
  project "$SCRATCH/p" "—"
  global_agents
  po_in "$F/src" run
  started "po run"
  jq -e '.command == "/po-drive"' <<< "$OUT" >/dev/null || fail "po run does not announce /po-drive: $OUT"
  [ "$(launch_count)" = 1 ] || fail "po run did not launch exactly one session: $(launch_count)"
  local call arg skip=0 uuid
  call="$(last_launch)"
  grep -qx "cwd $F" "$call" || fail "the session was not launched at the project root: $(head -n 1 "$call")"
  [ "$(args_of "$call" | tail -n 1)" = /po-drive ] || fail "the session's one instruction is not /po-drive: $(args_of "$call" | tr '\n' ' ')"
  uuid="$(value_after --session-id "$call")"
  [ -n "$uuid" ] || fail "po run gave Claude Code no session id: $(args_of "$call" | tr '\n' ' ')"
  while IFS= read -r arg; do
    if [ "$skip" = 1 ]; then skip=0; continue; fi
    case "$arg" in
      --bg|/po-drive) ;;
      --session-id) skip=1 ;;
      *) fail "po run passed Claude Code an argument of its own: $arg" ;;
    esac
  done < <(args_of "$call")
}

test_continue_resumes_after_an_answer() {
  setup
  project "$SCRATCH/p" "—"
  global_agents
  po_in "$F" run
  started "po run"
  local first uuid call
  first="$(jq -r '.session' <<< "$OUT")"
  uuid="$(value_after --session-id "$(last_launch)")"
  stop_session
  decision d-0001 answered

  po_in "$F" continue
  started "po continue after an answer"
  jq -e --arg s "$first" '.session == $s and .command == "/po-drive"' <<< "$OUT" >/dev/null \
    || fail "po continue did not answer for the session run started ($first): $OUT"
  [ "$(launch_count)" = 2 ] || fail "po continue did not launch exactly once: $(launch_count) launches"
  call="$(last_launch)"
  grep -qx "cwd $F" "$call" || fail "po continue did not resume at the project root"
  [ "$(value_after --resume "$call")" = "$uuid" ] || fail "po continue did not resume session $uuid: $(args_of "$call" | tr '\n' ' ')"
  [ "$(args_of "$call" | tail -n 1)" = /po-drive ] || fail "the resumed session's instruction is not /po-drive"

  project "$SCRATCH/q" "—"
  decision d-0001 answered
  po_in "$F" continue
  started "po continue with no session known"
  [ "$(launch_count)" = 3 ] || fail "po continue with no session known launched nothing"
  call="$(last_launch)"
  grep -qx "cwd $F" "$call" || fail "po continue with no session known did not launch at the project root"
  [ -n "$(value_after --session-id "$call")" ] || fail "po continue with no session known did not start one as run does"
  if grep -qx 'arg --resume' "$call"; then fail "po continue resumed a session the project never started"; fi
}

test_run_refuses_a_second_session() {
  setup
  project "$SCRATCH/p" "—"
  global_agents
  po_in "$F" run
  started "po run"
  local sid verb
  sid="$(jq -r '.session' <<< "$OUT")"

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e --arg s "$sid" '.session == {"running": true, "id": $s}' <<< "$OUT" >/dev/null \
    || fail "po state does not carry the running session $sid: $(jq -c '.session' <<< "$OUT")"
  for verb in run continue; do
    po_in "$F" "$verb"
    refused already-running 1 "po $verb while the lead runs"
  done
  [ "$(launch_count)" = 1 ] || fail "a second session was launched while the first runs"

  stop_session
  po_in "$F" state
  jq -e --arg s "$sid" '.session == {"running": false, "id": $s}' <<< "$OUT" >/dev/null \
    || fail "po state still says running once the session stopped: $(jq -c '.session' <<< "$OUT")"
}

test_run_refuses_unproven_bounds() {
  setup
  project "$SCRATCH/p" "—"
  project_agents
  po_in "$F" state
  jq -e '.bounds == "unproven"' <<< "$OUT" >/dev/null || fail "subagents only in the repository give bounds $(jq -c '.bounds' <<< "$OUT")"
  po_in "$F" run
  refused bounds-unproven 1 "po run with the subagents only in the repository"

  global_agents
  po_in "$F" state
  jq -e '.bounds == "unproven"' <<< "$OUT" >/dev/null \
    || fail "the repository's subagents, which Claude Code prefers, give bounds $(jq -c '.bounds' <<< "$OUT")"
  po_in "$F" run
  refused bounds-unproven 1 "po run with the subagents in the repository and globally"
  [ "$(launch_count)" = 0 ] || fail "po run launched a session with unproven bounds"

  rm -rf "$F/.claude"
  po_in "$F" state
  jq -e '.bounds == "held"' <<< "$OUT" >/dev/null || fail "the global installation gives bounds $(jq -c '.bounds' <<< "$OUT")"
  po_in "$F" run
  started "po run with the global installation"
}

test_run_refuses_when_nothing_to_do() {
  setup
  project "$SCRATCH/p" "—"
  global_agents
  land_all
  decision d-0001 pending
  local verb
  for verb in run continue; do
    po_in "$F" "$verb"
    refused nothing-to-do 1 "po $verb with framing done, no story ready, no lane and no answer"
  done
  [ "$(launch_count)" = 0 ] || fail "a session was launched with nothing to do"

  git -C "$F" worktree add -q -b story/s01-alpha "$F/.worktrees/s01-alpha" main
  po_in "$F" run
  started "po run with a lane on disk"
  stop_session
  git -C "$F" worktree remove --force "$F/.worktrees/s01-alpha"

  sed -i 's/^Entry mode:.*/Entry mode:        new/' "$F/AGENTS.local.md"
  po_in "$F" run
  started "po run on a project whose framing waits for its brief"
  jq -e '.command == "/po-brief"' <<< "$OUT" >/dev/null || fail "po run does not launch the missing framing stage: $OUT"
  [ "$(args_of "$(last_launch)" | tail -n 1)" = /po-brief ] || fail "the framing session's instruction is not /po-brief"
}

test_run_takes_no_free_text() {
  setup
  project "$SCRATCH/p" "—"
  global_agents
  local verb arg
  for verb in run continue; do
    for arg in "/po-drive" "build the login page" "--prompt" "-p" ""; do
      po_in "$F" "$verb" "$arg"
      refused unknown-option 2 "po $verb '$arg'"
    done
    po_in "$F" "$verb" /po-drive extra
    refused unknown-option 2 "po $verb with two arguments"
  done
  [ "$(launch_count)" = 0 ] || fail "an argument reached a launched session"
}
