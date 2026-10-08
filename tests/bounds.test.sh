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

# s62 — commands read the way bash splits them: quoted text and here-document bodies are not commands.

test_bounds_ignore_heredoc_bodies() {
  lane
  expect "$(bash_status "cat > $WT/docs/x.md <<'EOF'"$'\ngit checkout main\ngit push\nEOF')" 0 "quoted heredoc citing git verbs"
  expect "$(bash_status "cat > $WT/docs/x.md <<EOF"$'\nrun git checkout main, then git push\nEOF')" 0 "unquoted heredoc of plain text"
  expect "$(bash_status "cd $WT && git commit -F - <<'EOF'"$'\nnotes: then git push\nEOF')" 0 "commit message in a heredoc"
  expect "$(bash_status "git -C $SCRATCH commit -F - <<'EOF'"$'\nmsg\nEOF')" 2 "the heredoc opener is read"
  expect "$(bash_status "cat > $WT/docs/x.md <<'EOF'"$'\ntext\nEOF\ngit push')" 2 "a command after the delimiter"
  expect "$(bash_status "cat > $WT/docs/x.md <<EOF"$'\nsee $(git push)\nEOF')" 2 "a substitution in an unquoted heredoc"
  expect "$(bash_status "cat > $WT/docs/x.md <<EOF"$'\ngit stash')" 2 "an unterminated heredoc"
  expect "$(bash_status $'bash <<\'EOF\'\necho ok\nEOF')" 0 "a shell reading a harmless heredoc"
  expect "$(bash_status $'bash <<\'EOF\'\ngit push\nEOF')" 2 "a heredoc fed to bash is read as commands"
  expect "$(bash_status $'sh -s <<EOF\ngit checkout x\nEOF')" 2 "a heredoc fed to sh -s is read as commands"
}

test_bounds_ignore_quoted_arguments() {
  lane
  local c
  for c in 'grep -rn "git checkout" docs' "printf 'run git commit then git push'" \
           'echo "git stash" | wc -l' "cd $WT && git commit -m \"fix; git push\"" \
           'ps aux | grep bash' 'echo x | bash -c "wc -l"' 'echo "git" push'; do
    expect "$(bash_status "$c")" 0 "$c"
  done
  for c in 'bash -c "git push"' "sh -c 'git checkout x'" "eval 'git stash'" 'grep "unclosed' \
           '"bash" -c "git push"' "watch 'git push'" "echo 'git push' | bash" $'cat <<\'EOF\' | sh\necho\nEOF' \
           '(echo x) | bash' 'bash -c "$(cat notes.txt)"' 'echo `echo \`git push\``'; do
    expect "$(bash_status "$c")" 2 "$c"
  done
}

test_bounds_still_catch_real_verbs() {
  lane
  local c
  for c in 'true && git checkout x' 'true; git stash' 'echo $(git push)' 'echo "$(git checkout x)"' \
           'echo `git stash`' 'env git push' "cd $WT && true && git -C $SCRATCH commit -m x" \
           '"git" push' '\git push' 'g"it" push' 'env "git" push' "command 'git' push" 'A=1 \git push' \
           'time \git push'; do
    expect "$(bash_status "$c")" 2 "$c"
  done
  expect "$(bash_status "cd $WT && echo ok && git commit -m x")" 0 "cd carried across simple commands"
}

test_qa_allowlist_refuses_writing_forms() {
  lane
  local c
  for c in "git -C $WT symbolic-ref HEAD refs/heads/main" "git -C $WT symbolic-ref -d HEAD" \
           "git -C $WT diff --output=src/x" "git -C $WT log --output x"; do
    expect "$(qa_status Bash command "$c")" 2 "$c"
  done
  for c in "git -C $WT symbolic-ref --short HEAD" "git -C $WT diff main...story/s01-demo"; do
    expect "$(qa_status Bash command "$c")" 0 "$c"
  done
}

test_bounds_refuse_moving_a_branch() {
  lane
  local c
  for c in "git -C $WT branch -f main HEAD" "git -C $WT branch -D story/s03-en" \
           "git -C $WT update-ref refs/heads/main HEAD" "git -C $SCRATCH reset --hard HEAD" \
           "git -C $SCRATCH merge story/s01-demo"; do
    expect "$(bash_status "$c")" 2 "$c"
  done
  for c in "cd $WT && git reset --soft HEAD" "git -C $WT branch"; do
    expect "$(bash_status "$c")" 0 "$c"
  done
}

# s70 — the reviewer held by po-bounds in mode reviewer (ADR-0047).
REVIEWER="$METHOD/agents/reviewer.md"

# The temp root is a separate mktemp -d: inside $SCRATCH it would sit in the scratch repo.
reviewer_lane() {
  lane
  TMPROOT="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$TMPROOT"' EXIT
  export TMPDIR="$TMPROOT"
  git init -q "$TMPROOT/probe"
  git -C "$SCRATCH" worktree add -q --detach "$TMPROOT/main-wt"
}

rev_status() { status_with "$(hook_input "$1" "$2" "$3")" reviewer; }
rev_bash() { rev_status Bash command "$1"; }

test_reviewer_declares_a_pretooluse_hook() {
  reviewer_lane
  local fm matcher tool cmd pd allowed s
  fm="$(frontmatter "$REVIEWER")"
  grep -q '^  PreToolUse:' <<< "$fm" || fail "no PreToolUse hook in the reviewer's frontmatter"
  matcher="$(grep -m1 'matcher:' <<< "$fm")"
  for tool in Edit Write Bash; do
    grep -q "$tool" <<< "$matcher" || fail "the matcher does not cover $tool"
  done
  cmd="$(hook_command "$REVIEWER")"
  grep -qF '.polype/hooks/po-bounds.sh reviewer' <<< "$cmd" || fail "the hook does not call po-bounds.sh reviewer: $cmd"
  pd="$SCRATCH/project"
  mkdir -p "$pd/.polype/hooks"
  allowed="$(hook_input Edit file_path "$WT/src/app.sh")"
  run() { s=0; printf '%s' "$allowed" | CLAUDE_PROJECT_DIR="$pd" sh -c "$cmd" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }
  expect "$(run)" 2 "reviewer hook, no script laid down"
  cp "$BOUNDS" "$pd/.polype/hooks/po-bounds.sh"
  chmod -x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run)" 2 "reviewer hook, script without the exec bit"
  chmod +x "$pd/.polype/hooks/po-bounds.sh"
  expect "$(run)" 0 "reviewer hook, executable script, Edit in the story worktree"
  contains "$REVIEWER" 'A po-bounds refusal is a stop'
}

test_reviewer_writes_only_in_its_story_or_temp() {
  reviewer_lane
  ln -s "$SCRATCH" "$TMPROOT/link"
  expect "$(rev_status Edit file_path "$WT/src/other.sh")" 0 "Edit outside Owns, in the story worktree"
  expect "$(rev_status Write file_path "$WT/src/app.sh")" 0 "Write in the story worktree"
  expect "$(rev_status Write file_path "$TMPROOT/notes/deep/x.md")" 0 "Write under the temp dir, missing folders"
  expect "$(rev_status Edit file_path "$TMPROOT/probe/f")" 0 "Edit in a throwaway repo"
  expect "$(rev_status Edit file_path "$SCRATCH/src/app.sh")" 2 "main checkout"
  expect "$(rev_status Write file_path "$TMPROOT/main-wt/x")" 2 "a worktree of the real repo in the temp dir"
  expect "$(rev_status Edit file_path "$WT/.git")" 2 ".git of the story worktree"
  expect "$(rev_status Write file_path "$TMPROOT/../x")" 2 "escape from the temp dir"
  expect "$(rev_status Write file_path "$TMPROOT/link/src/x")" 2 "symlink from the temp dir to the main checkout"
}

test_reviewer_git_is_read_only_outside_restores() {
  reviewer_lane
  local c
  for c in "git -C $WT status" "cd $WT && git diff --exit-code src/app.sh" "git -C $WT checkout -- src/app.sh" \
           "git -C $WT restore src/app.sh" "git -C $WT restore --worktree -- src/app.sh" "git -C $WT worktree list" \
           "git -C $TMPROOT/probe commit -m x" "cd $TMPROOT/probe && git branch x && git reset --hard" \
           "cd $TMPROOT && git init other"; do
    expect "$(rev_bash "$c")" 0 "$c"
  done
  for c in push "commit -m x" "reset --hard" stash "branch x" "merge main" "checkout main" "checkout -b x" \
           "checkout --" restore "restore --staged src/app.sh" "restore --source=main src/app.sh" "diff --output=x"; do
    expect "$(rev_bash "git -C $WT $c")" 2 "in the story worktree: git $c"
  done
  for c in "git status" "git -C $SCRATCH log" "git -C $TMPROOT/probe push" "git -C $TMPROOT/main-wt commit -m x" \
           "GIT_DIR=$SCRATCH/.git git -C $TMPROOT/probe log" "git --git-dir=$SCRATCH/.git -C $TMPROOT/probe log" \
           'cd "$(mktemp -d)" && git init'; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
  c="cat > $TMPROOT/probe/notes.sh <<'END'
echo probe
END
git push"
  expect "$(rev_bash "$c")" 2 "a here-document closed, then git push (the s62 incident)"
}

test_reviewer_bounds_fail_closed() {
  reviewer_lane
  local ghost="$SCRATCH/.worktrees/s99-ghost"
  expect "$(rev_status Edit file_path "$ghost/src/app.sh")" 2 "story not in stories.md"
  expect "$(rev_bash "git -C $ghost status")" 2 "git in a story not in stories.md"
  expect "$(rev_status Edit file_path "$SCRATCH/.worktrees/s02-bare/src/app.sh")" 2 "story without Owns"
  expect "$(status_with 'not json' reviewer)" 2 "input that is not JSON"
  expect "$(status_with '' reviewer)" 2 "empty input"
  expect "$(rev_status Edit content x)" 2 "Edit without file_path"
  expect "$(rev_status Bash description x)" 2 "Bash without command"
  expect "$(rev_status Edit file_path src/app.sh)" 2 "relative path"
  expect "$(rev_status NotebookEdit file_path "$WT/src/app.sh")" 2 "unknown tool"
  expect "$(status_with "$(jq -n '{tool_name: "Bash", tool_input: {command: "git status"}}')" reviewer)" 2 "Bash without cwd"
  expect "$(TMPDIR=/ rev_status Write file_path "$TMPROOT/x")" 2 "TMPDIR is /"
  expect "$(TMPDIR="$TMPROOT/missing" rev_status Write file_path "$TMPROOT/x")" 2 "TMPDIR does not exist"
}

# s71 — a heredoc read as bash will read it; a quoted git past a wrapper's option (ADR-0050).

test_unquoted_heredoc_is_expanded_before_reading() {
  lane
  expect "$(bash_status $'bash <<EOF\necho \\`git push\\`\nEOF')" 2 "escaped backquotes in a body bash reads"
  expect "$(bash_status $'sh -s <<EOF\nx=\\$(git stash)\nEOF')" 2 "an escaped substitution in a body sh reads"
  expect "$(bash_status $'bash <<EOF\necho \'$(git push)\'\nEOF')" 2 "a substitution the outer bash runs"
  expect "$(bash_status $'bash <<EOF\necho \\\\\\`git push\\\\\\`\nEOF')" 0 "doubly escaped backquotes stay text"
  expect "$(bash_status $'bash <<\'EOF\'\necho \\`git push\\`\nEOF')" 0 "a quoted body is read as typed"
  expect "$(bash_status "cat > $WT/docs/x.md <<EOF"$'\nsee \\`git push\\`\nEOF')" 0 "plain text in an unquoted heredoc"
}

test_quoted_git_after_a_wrapper_option_is_caught() {
  lane
  local c
  for c in 'env -u X "git" push' 'sudo -u x "git" push' "nice -n 5 'git' push" 'sudo -u x "bash" -c "git push"'; do
    expect "$(bash_status "$c")" 2 "$c"
  done
  for c in 'sudo -u x grep "git" docs' 'env -u X grep -n "git" docs'; do
    expect "$(qa_status Bash command "$c")" 0 "qa: $c"
  done
}

test_accepted_gaps_are_written_in_an_adr() {
  local adr="$ROOT/docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md"
  local old="$ROOT/docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md"
  local p
  require_file "$adr"
  for p in 'supersedes: [ADR-0039]' '**Lecture des heredocs**' '**Refus du pipe vers un shell**' \
           '**Interprètes reconnus**' 'un script écrit puis lancé' '`bash <(…)`' 'un alias git' '`GIT_DIR=…`'; do
    contains "$adr" "$p"
  done
  contains "$old" 'superseded-by: [ADR-0050]'
  contains "$old" 'status: superseded'
}

# s74 — the reviewer judges the git command git will run (ADR-0051).
test_chained_git_dirs_are_folded() {
  reviewer_lane
  local c
  mkdir -p "$TMPROOT/probe/~"
  for c in "cd $TMPROOT/probe && git -C $SCRATCH -C . commit -m x" \
           "cd $TMPROOT/probe && git -C \"\$(echo $SCRATCH)\" commit -m x" \
           "cd $TMPROOT/probe && cd \"\$(echo $SCRATCH)\" && git commit -m x" \
           "cd $TMPROOT/probe && cd && git commit -m x" \
           "cd $TMPROOT/probe && git -C ~ commit -m x"; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
  c="cd $WT && git -C $SCRATCH -C . commit -m x"
  expect "$(bash_status "$c")" 2 "implementer: $c"
  c="git -C $TMPROOT -C probe commit -m x"
  expect "$(rev_bash "$c")" 0 "$c"
}

test_global_option_values_are_not_verbs() {
  reviewer_lane
  local c
  for c in "cd $TMPROOT/probe && git --attr-source HEAD push" \
           "cd $TMPROOT/probe && git --config-env x.y=HOME push"; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
  c="git -C $WT --attr-source HEAD status"
  expect "$(rev_bash "$c")" 0 "$c"
}

test_config_worktree_override_is_refused() {
  reviewer_lane
  local c
  for c in "git -C $TMPROOT/probe -c core.worktree=$SCRATCH reset --hard" \
           "git -C $WT -c core.worktree=$SCRATCH checkout -- src/app.sh" \
           "git -C $TMPROOT/probe -c Core.WorkTree=$SCRATCH status" \
           "git -C $TMPROOT/probe --config-env core.worktree=HOME status" \
           "git -C $TMPROOT/probe --config-env=core.worktree=HOME status" \
           "GIT_CONFIG_COUNT=1 git -C $TMPROOT/probe status" \
           "GIT_CONFIG_PARAMETERS=x git -C $TMPROOT/probe status"; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
  c="git -C $TMPROOT/probe -c user.name=x commit -m x"
  expect "$(rev_bash "$c")" 0 "$c"
}

test_temp_zone_verbs_keep_their_paths_in_temp() {
  reviewer_lane
  local c
  ln -s "$SCRATCH" "$TMPROOT/link"
  for c in "cd $TMPROOT/probe && git init $SCRATCH/x" \
           "git -C $TMPROOT/probe clone $SCRATCH $SCRATCH/sub" \
           "git -C $TMPROOT/probe worktree add $SCRATCH/evil" \
           "git -C $TMPROOT/probe worktree add ../../$(basename "$SCRATCH")/evil" \
           "git -C $TMPROOT init --separate-git-dir=$SCRATCH/g x" \
           "git -C $TMPROOT/probe archive -o$SCRATCH/a.tar HEAD" \
           "git -C $TMPROOT/probe config core.worktree $SCRATCH" \
           "git -C $TMPROOT/probe init '\$X'/y" \
           "git -C $TMPROOT/probe init $TMPROOT/link/x"; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
  for c in "git -C $TMPROOT/probe worktree add $TMPROOT/wt2" \
           "git -C $TMPROOT clone file://$SCRATCH c" \
           "git -C $TMPROOT clone probe c2" \
           "git -C $TMPROOT/probe commit -m x"; do
    expect "$(rev_bash "$c")" 0 "$c"
  done
}

test_reviewer_knows_how_to_check_merged() {
  contains "$REVIEWER" 'git branch --merged'
  contains "$REVIEWER" 'merge-base --is-ancestor'
  contains "$REVIEWER" 'file://'
}

test_reviewer_rules_are_written_in_adr_0051() {
  local adr="$ROOT/docs/decisions/ADR-0051-le-reviewer-juge-la-commande-git-que-git-executera.md"
  local old="$ROOT/docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md"
  local p fm
  require_file "$adr"
  for p in 'supersedes: [ADR-0047]' '**Répertoire**' 'core.worktree' "la portée d'un \`cd\`"; do
    contains "$adr" "$p"
  done
  fm="$(frontmatter "$old")"
  grep -qx 'superseded-by: \[ADR-0051, ADR-0052\]' <<< "$fm" || fail "ADR-0047 does not say superseded-by: [ADR-0051, ADR-0052]"
  grep -qx 'status: accepted' <<< "$fm" || fail "ADR-0047 is no longer accepted"
}

# s76 — po-bounds guards against mistakes; a redirection is not a git path (ADR-0052).
test_redirections_are_not_git_paths() {
  reviewer_lane
  local c
  for c in "git -C $TMPROOT/probe log 2>/dev/null" \
           "git -C $TMPROOT/probe log >/dev/null" \
           "git -C $TMPROOT/probe log &>/dev/null" \
           "git -C $TMPROOT/probe log 2>&1 | head" \
           "git -C $TMPROOT/probe log > $TMPROOT/out.txt" \
           "cd $TMPROOT/probe && git log > out.txt"; do
    expect "$(rev_bash "$c")" 0 "$c"
  done
  expect "$(qa_status Bash command "git -C $WT symbolic-ref HEAD 2>/dev/null")" 0 "qa symbolic-ref HEAD 2>/dev/null"
  for c in "git -C $TMPROOT/probe log > $SCRATCH/out.txt" \
           "git -C $TMPROOT/probe log 2> $SCRATCH/err.txt" \
           "git -C $TMPROOT/probe log > out.txt"; do
    expect "$(rev_bash "$c")" 2 "$c"
  done
}

test_refusal_messages_are_readable() {
  reviewer_lane
  local c err adr53 adr52
  for c in "git -C $TMPROOT/probe log > >(cat)" "git -C $TMPROOT/probe log > \$(echo x)/y"; do
    expect "$(rev_bash "$c")" 2 "$c"
    err="$(printf '%s' "$(hook_input Bash command "$c")" | bash "$BOUNDS" reviewer 2>&1 >/dev/null || true)"
    case "$err" in *$'\036'*) fail "the refusal still holds a raw separator: $c" ;; esac
    grep -qF 'redirects to <substitution>' <<< "$err" || fail "no readable placeholder in the refusal of: $c"
  done
  expect "$(rev_bash "git -C $TMPROOT/probe log >/dev/fd/1")" 0 "log >/dev/fd/1"
  expect "$(rev_bash "git -C $TMPROOT/probe log 2>/dev/fd/2")" 0 "log 2>/dev/fd/2"
  expect "$(rev_bash "git -C $TMPROOT/probe log >/dev/fd/3")" 2 "log >/dev/fd/3"
  adr53="$(ls "$ROOT"/docs/decisions/ADR-0053-*.md)"
  adr52="$(ls "$ROOT"/docs/decisions/ADR-0052-*.md)"
  frontmatter "$adr53" | grep -E '^supersedes:' | grep -qF 'ADR-0052' || fail "ADR-0053 does not supersede ADR-0052"
  frontmatter "$adr52" | grep -E '^superseded-by:' | grep -qF 'ADR-0053' || fail "ADR-0052 does not name ADR-0053"
  frontmatter "$adr52" | grep -qx 'status: accepted' || fail "ADR-0052 is no longer accepted"
}

test_bounds_threat_model_is_written() {
  local adr fm f p
  adr="$(ls "$ROOT"/docs/decisions/ADR-0052-*.md)"
  require_file "$adr"
  fm="$(frontmatter "$adr")"
  grep -qx 'supersedes: \[ADR-0047, ADR-0051\]' <<< "$fm" || fail "ADR-0052 does not supersede ADR-0047 and ADR-0051"
  grep -qx 'status: accepted' <<< "$fm" || fail "ADR-0052 is not accepted"
  for p in 'garde-fou contre les erreurs' '-zf<chemin>' "la portée d'un \`cd\`" 'un alias git' \
           "les hooks d'un dépôt jetable" '`GIT_CONFIG_GLOBAL`' 'une clé construite par substitution' 'bac à sable'; do
    contains "$adr" "$p"
  done
  for f in 0047 0051; do
    frontmatter "$(ls "$ROOT"/docs/decisions/ADR-$f-*.md)" | grep -E '^superseded-by:' | grep -qF 'ADR-0052' \
      || fail "ADR-$f does not name ADR-0052 in superseded-by"
  done
  frontmatter "$(ls "$ROOT"/docs/decisions/ADR-0034-*.md)" | grep -E '^superseded-by:' | grep -qF 'ADR-0041' \
    || fail "ADR-0034 does not name ADR-0041"
  frontmatter "$(ls "$ROOT"/docs/decisions/ADR-0041-*.md)" | grep -E '^supersedes:' | grep -qF 'ADR-0034' \
    || fail "ADR-0041 does not name ADR-0034"
  for f in 0047 0051 0034; do
    frontmatter "$(ls "$ROOT"/docs/decisions/ADR-$f-*.md)" | grep -qx 'status: accepted' || fail "ADR-$f is no longer accepted"
  done
}
