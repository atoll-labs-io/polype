#!/usr/bin/env bash
# s50 — the implementer's bounds held by a hook.

BOUNDS="$METHOD/hooks/po-bounds.sh"
IMPLEMENTER="$METHOD/agents/implementer.md"
QA_AGENT="$METHOD/agents/qa.md"

# A repository with a committed docs/stories.md and one linked story/<id> worktree per story,
# plus s99-ghost, whose story the file does not hold.
lane() {
  scratch_repo
  mkdir -p "$SCRATCH/docs"
  cat > "$SCRATCH/docs/stories.md" <<'EOF'
# Stories

### s01-demo — Demo
- **Owns** : `src/app.sh`, `lib/`

## s03-en — En
- **Owns**: `pkg/`

### s02-bare — Bare
- **Size**: 1
EOF
  git -C "$SCRATCH" add -A
  git -C "$SCRATCH" commit -qm stories
  local id
  for id in s01-demo s02-bare s03-en s99-ghost; do
    git -C "$SCRATCH" worktree add -q -b "story/$id" "$SCRATCH/.worktrees/$id"
  done
  WT="$SCRATCH/.worktrees/s01-demo"
}

hook_input() {
  jq -n --arg t "$1" --arg f "$2" --arg v "$3" --arg c "$SCRATCH" \
    '{tool_name: $t, tool_input: {($f): $v}, cwd: $c}'
}

# Exit status of the script for the input $1 and the arguments that follow.
status_with() { local input="$1" s=0; shift; printf '%s' "$input" | bash "$BOUNDS" "$@" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
bounds_status() { status_with "$1" implementer; }
bounds_stderr() { printf '%s' "$1" | bash "$BOUNDS" implementer 2>&1 >/dev/null || true; }

write_status() { bounds_status "$(hook_input "$1" file_path "$2")"; }
bash_status() { bounds_status "$(hook_input Bash command "$1")"; }

expect() { [ "$1" = "$2" ] || fail "$3: expected exit $2, got $1"; }

hook_command() {
  frontmatter "${1:-$IMPLEMENTER}" | grep -m1 '^[[:space:]]*command:' \
    | sed -e "s/^[[:space:]]*command:[[:space:]]*//" -e "s/^'//" -e "s/'\$//"
}

test_implementer_declares_a_pretooluse_hook() {
  local fm matcher
  fm="$(frontmatter "$IMPLEMENTER")"
  grep -q '^  PreToolUse:' <<< "$fm" || fail "no PreToolUse hook in the implementer's frontmatter"
  matcher="$(grep -m1 'matcher:' <<< "$fm")"
  for tool in Edit Write Bash; do
    grep -q "$tool" <<< "$matcher" || fail "the matcher does not cover $tool"
  done
  hook_command | grep -qF '.polype/hooks/po-bounds.sh implementer' || fail "the hook does not call po-bounds.sh implementer"
  contains "$IMPLEMENTER" 'A po-bounds refusal is a stop'
}

test_bounds_hook_blocks_when_the_script_cannot_run() {
  lane
  local cmd pd allowed refused s
  cmd="$(hook_command)"
  [ -n "$cmd" ] || fail "no command line in the frontmatter"
  pd="$SCRATCH/project"
  mkdir -p "$pd/.polype/hooks"
  allowed="$(hook_input Write file_path "$WT/src/app.sh")"
  refused="$(hook_input Write file_path "$WT/src/other.sh")"
  run() { s=0; printf '%s' "$1" | CLAUDE_PROJECT_DIR="$pd" sh -c "$cmd" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
  expect "$(run "$allowed")" 2 "no script laid down"
  cp "$BOUNDS" "$pd/.polype/hooks/po-bounds.sh"
  chmod -x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run "$allowed")" 2 "script without the exec bit"
  chmod +x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run "$allowed")" 0 "executable script, write inside Owns"
  expect "$(run "$refused")" 2 "executable script, write outside Owns"
}

test_bounds_deny_writes_outside_owns() {
  lane
  local err
  expect "$(write_status Write "$WT/src/app.sh")" 0 "an Owns file"
  expect "$(write_status Write "$WT/lib/new/deep.sh")" 0 "under an Owns directory, missing dirs"
  expect "$(write_status Write "$WT/docs/anything.md")" 0 "docs/"
  expect "$(write_status Write "$SCRATCH/.worktrees/s03-en/pkg/x")" 0 "template-form Owns"
  expect "$(write_status Write "$WT/src/other.sh")" 2 "outside Owns"
  err="$(bounds_stderr "$(hook_input Write file_path "$WT/src/other.sh")")"
  grep -qF "$WT/src/other.sh" <<< "$err" || fail "the refusal does not name the path: $err"
  grep -qF '**Owns** :' <<< "$err" || fail "the refusal does not quote the Owns line: $err"
  expect "$(write_status Write "$WT/docs/../evil.sh")" 2 "docs/.. escape"
  expect "$(write_status Edit "$WT/src/other.sh")" 2 "Edit outside Owns"
  sed -i.bak 's/`lib\/`/`lib\/`, `src\/`/' "$WT/docs/stories.md"
  grep -qF '`src/`' "$WT/docs/stories.md" || fail "fixture: the working copy was not widened"
  expect "$(write_status Write "$WT/src/other.sh")" 2 "uncommitted widening of Owns"
}

test_bounds_deny_forbidden_git_verbs() {
  lane
  local c
  for c in "cd $WT && git switch main" \
           "true; git -C $WT checkout -b x" \
           "ls | git stash" \
           "cd $WT && git worktree add ../y" \
           "git --no-pager push" \
           "cd $SCRATCH && git commit -m x" \
           "git -C $SCRATCH commit -m x"; do
    expect "$(bash_status "$c")" 2 "$c"
  done
  for c in "cd $WT && git commit -m x" \
           "git -C $WT status" \
           "git worktree list" \
           "echo ok > /tmp/x"; do
    expect "$(bash_status "$c")" 0 "$c"
  done
}

test_bounds_fail_closed() {
  lane
  local outside
  expect "$(write_status Write "$SCRATCH/.worktrees/s99-ghost/src/app.sh")" 2 "story not in stories.md"
  expect "$(write_status Write "$SCRATCH/.worktrees/s02-bare/src/app.sh")" 2 "story without Owns"
  expect "$(write_status Write "$SCRATCH/src/app.sh")" 2 "main worktree"
  outside="$(mktemp -d)"
  expect "$(write_status Write "$outside/x.sh")" 2 "outside any repository"
  rm -rf "$outside"
  expect "$(bounds_status 'not json')" 2 "input that is not JSON"
  expect "$(bounds_status '')" 2 "empty input"
  expect "$(bounds_status "$(hook_input Write content x)")" 2 "Write without file_path"
  expect "$(status_with "$(hook_input Write file_path "$WT/src/app.sh")")" 2 "mode missing"
  expect "$(status_with "$(hook_input Write file_path "$WT/src/app.sh")" nobody)" 2 "unknown mode"
  expect "$(write_status NotebookEdit "$WT/src/app.sh")" 2 "unknown tool"
}

# Claude Code passes the hook input over a socket; a pipe hides a read that only works on pipes.
test_bounds_read_input_from_a_socket() {
  lane
  local input s
  input="$(hook_input Write file_path "$WT/src/app.sh")"
  s="$(python3 -I - "$BOUNDS" "$input" <<'PY'
import socket, subprocess, sys
a, b = socket.socketpair()
a.sendall(sys.argv[2].encode())
a.shutdown(socket.SHUT_WR)
print(subprocess.run(["bash", sys.argv[1], "implementer"], stdin=b, capture_output=True).returncode)
PY
)"
  expect "$s" 0 "a write inside Owns, input read from a socket"
}

qa_status() { status_with "$(hook_input "$1" "$2" "$3")" qa; }

test_qa_writes_are_bounded_by_the_hook() {
  lane
  local c
  expect "$(qa_status Write file_path "$WT/docs/qa/s01-demo/a.png")" 0 "docs/qa/<id>/, missing folders"
  expect "$(qa_status Write file_path "$WT/docs/qa/s03-en/a.png")" 2 "another story's qa folder"
  expect "$(qa_status Write file_path "$WT/docs/plans/x.md")" 2 "docs/ outside docs/qa/<id>/"
  expect "$(qa_status Write file_path "$WT/src/app.sh")" 2 "a file inside Owns"
  expect "$(qa_status Write file_path "$WT/docs/qa/s01-demo/../../x")" 2 "escape from docs/qa/<id>/"
  expect "$(qa_status Edit file_path "$WT/docs/qa/s01-demo/r.md")" 2 "Edit"
  for c in "git -C $WT add -A" "cd $WT && git commit -m x" "git -C $WT restore ." "git -C $WT branch x"; do
    expect "$(qa_status Bash command "$c")" 2 "$c"
  done
  for c in "git -C $WT diff main...story/s01-demo" "git -C $WT rev-parse 'story/s01-demo^{tree}'" "cd $WT && npm run dev"; do
    expect "$(qa_status Bash command "$c")" 0 "$c"
  done

  local fm cmd pd input s
  fm="$(frontmatter "$QA_AGENT")"
  ! grep -q '^tools:' <<< "$fm" || fail "qa.md declares tools:, which cancels disallowedTools"
  grep -m1 '^disallowedTools:' <<< "$fm" | grep -qw Edit || fail "qa.md does not remove Edit through disallowedTools"
  cmd="$(hook_command "$QA_AGENT")"
  grep -qF 'po-bounds.sh qa' <<< "$cmd" || fail "the qa hook does not call po-bounds.sh qa: $cmd"
  pd="$SCRATCH/project"
  mkdir -p "$pd/.polype/hooks"
  input="$(hook_input Write file_path "$WT/docs/qa/s01-demo/report.md")"
  run() { s=0; printf '%s' "$input" | CLAUDE_PROJECT_DIR="$pd" sh -c "$cmd" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
  expect "$(run)" 2 "qa hook, no script laid down"
  cp "$BOUNDS" "$pd/.polype/hooks/po-bounds.sh"
  chmod -x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run)" 2 "qa hook, script without the exec bit"
  chmod +x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run)" 0 "qa hook, executable script, write in docs/qa/<id>/"
}

# Throwaway HOME, as in global-install.test.sh: nothing may reach the real ~/.claude.
global_home() {
  scratch_repo
  P="$SCRATCH"
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
}

guard_home() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
}

test_installer_ships_the_bounds_hook() {
  global_home
  guard_home
  bash "$ROOT/bin/polype" install --global >/dev/null 2>&1 || fail "polype install --global failed"
  bash "$ROOT/bin/polype" init "$P" >/dev/null 2>&1 || fail "polype init failed"
  [ -x "$P/.polype/hooks/po-gate.sh" ] || fail "init: po-gate.sh missing"
  [ -x "$P/.polype/hooks/po-bounds.sh" ] || fail "init: po-bounds.sh missing or not executable"
  local p2="$SCRATCH/p2"
  mkdir -p "$p2"
  git -C "$p2" init -q -b main
  bash "$ROOT/bin/polype-dev-install" "$p2" >/dev/null 2>&1 || fail "polype-dev-install failed"
  [ -x "$p2/.polype/hooks/po-gate.sh" ] || fail "install <project>: po-gate.sh missing"
  [ -x "$p2/.polype/hooks/po-bounds.sh" ] || fail "install <project>: po-bounds.sh missing or not executable"
}

test_installation_doc_names_the_upgrade_path() {
  local doc="$ROOT/docs/installation.md"
  contains "$doc" 'relance `polype init <projet>`'
  contains "$doc" "le hook fermé refuse toute écriture de l'implementer"
  contains "$doc" '`jq`'
}

# s61 — Owns read at the fork point, globs, unreadable entries refused.

# Commits story $1 with Owns value $2 on main, then forks its worktree, so the fork point holds it.
add_story() {
  printf '\n### %s — Added\n- **Owns**: %s\n' "$1" "$2" >> "$SCRATCH/docs/stories.md"
  git -C "$SCRATCH" commit -qam "add $1"
  git -C "$SCRATCH" worktree add -q -b "story/$1" "$SCRATCH/.worktrees/$1"
}

test_owns_are_read_where_the_story_started() {
  lane
  local fork err origin other
  fork="$(git -C "$SCRATCH" rev-parse --short main)"
  sed -i.bak 's/`lib\/`/`lib\/`, `src\/`/' "$WT/docs/stories.md"
  rm -f "$WT/docs/stories.md.bak"
  git -C "$WT" commit -qam widen
  expect "$(write_status Write "$WT/src/other.sh")" 2 "Owns widened by a commit of the story"
  err="$(bounds_stderr "$(hook_input Write file_path "$WT/src/other.sh")")"
  grep -qF "at $fork " <<< "$err" || fail "the refusal does not name the fork commit $fork: $err"
  expect "$(write_status Write "$WT/src/app.sh")" 0 "Owns as committed at the fork point"

  # A lane forked from origin/main while the local main lags behind it.
  origin="$SCRATCH/origin.git"
  other="$SCRATCH/other"
  git clone -q --bare "$SCRATCH" "$origin"
  git -C "$SCRATCH" remote add origin "$origin"
  git -C "$SCRATCH" fetch -q origin
  git -C "$SCRATCH" branch -q -u origin/main main
  git clone -q "$origin" "$other"
  git -C "$other" config user.email test@example.com
  git -C "$other" config user.name test
  printf '\n### s06-remote — Remote\n- **Owns**: `rem/`\n' >> "$other/docs/stories.md"
  git -C "$other" commit -qam "add s06-remote"
  git -C "$other" push -q origin main
  git -C "$SCRATCH" fetch -q origin
  git -C "$SCRATCH" worktree add -q -b story/s06-remote "$SCRATCH/.worktrees/s06-remote" origin/main
  expect "$(write_status Write "$SCRATCH/.worktrees/s06-remote/rem/x")" 0 "lane forked from the upstream of main"

  git -C "$SCRATCH" checkout -q --detach
  expect "$(write_status Write "$WT/src/app.sh")" 2 "main worktree detached"
}

test_owns_accept_globs() {
  lane
  add_story s04-globs '`crates/*/Cargo.toml`, `crates/**/tests/`, `tools/**`, `cfg/*.sh`'
  local g="$SCRATCH/.worktrees/s04-globs" p
  for p in crates/core/Cargo.toml crates/a/b/tests/t.rs crates/tests/t.rs tools/a/b/c cfg/run.sh; do
    expect "$(write_status Write "$g/$p")" 0 "$p"
  done
  for p in crates/a/b/Cargo.toml crates/core/src/lib.rs cfg/runXsh cfg/sub/run.sh; do
    expect "$(write_status Write "$g/$p")" 2 "$p"
  done
}

test_bounds_refuse_an_entry_they_cannot_read() {
  lane
  local n=10 owns bad wt err
  while IFS='|' read -r owns bad; do
    n=$((n + 1))
    add_story "s$n-bad" "$owns"
    wt="$SCRATCH/.worktrees/s$n-bad"
    expect "$(write_status Write "$wt/src/app.sh")" 2 "Owns $owns"
    err="$(bounds_stderr "$(hook_input Write file_path "$wt/src/app.sh")")"
    grep -qF "cannot read: $bad" <<< "$err" || fail "the refusal does not name $bad: $err"
    expect "$(write_status Write "$wt/docs/notes.md")" 0 "docs/ with Owns $owns"
  done <<'CASES'
`src/`, src/x.sh|src/x.sh
`src/`, `/abs/x`|`/abs/x`
`src/`, `../up/`|`../up/`
`src/`, `a//b`|`a//b`
`src/`, `a/**b`|`a/**b`
`src/`, `src/[ab].sh`|`src/[ab].sh`
`src/app.sh`, `src/x` and more|and more
CASES
}
