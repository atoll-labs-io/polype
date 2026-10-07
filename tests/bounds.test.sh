#!/usr/bin/env bash
# s50 — the implementer's bounds held by a hook.

BOUNDS="$METHOD/hooks/po-bounds.sh"
IMPLEMENTER="$METHOD/agents/implementer.md"

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
  frontmatter "$IMPLEMENTER" | grep -m1 '^[[:space:]]*command:' \
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
