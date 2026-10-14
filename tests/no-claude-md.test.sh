#!/usr/bin/env bash
# s115 — no CLAUDE.md in a project.

POLYPE="$ROOT/bin/polype"
GATE="$METHOD/hooks/po-gate.sh"
HOOK="$METHOD/hooks/po-session.sh"

# Every run of the installer happens under a throwaway HOME and CLAUDE_CONFIG_DIR.
throwaway_home() {
  scratch_repo
  P="$SCRATCH"
  export HOME="$SCRATCH/.home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
}

run_polype() {
  case "${CLAUDE_CONFIG_DIR-}" in "$SCRATCH"/*) ;; *) fail "refusing to run outside a throwaway home" ;; esac
  bash "$POLYPE" "$@" 2>&1 || fail "polype failed: $*"
}

has_exact_line() { grep -qxF -- "$2" "$1" || fail "${1##*/} lacks the line: $2"; }

test_installer_absorbs_claude_md() {
  throwaway_home
  printf 'Merge mode:        local\nProject CLAUDE file: absorbed\n' > "$P/AGENTS.local.md"
  printf '# Project notes\n@AGENTS.md\n' > "$P/CLAUDE.md"
  printf 'local note\n' > "$P/CLAUDE.local.md"
  local out; out="$(run_polype install "$P")"
  if [ -e "$P/CLAUDE.md" ] || [ -e "$P/CLAUDE.local.md" ]; then fail "install left a CLAUDE.md or CLAUDE.local.md"; fi
  [ "$(head -n 1 "$P/AGENTS.local.md")" = 'Merge mode:        local' ] || fail "the settings no longer open AGENTS.local.md"
  has_exact_line "$P/AGENTS.local.md" '## Notes moved from CLAUDE.md'
  has_exact_line "$P/AGENTS.local.md" '# Project notes'
  has_exact_line "$P/AGENTS.local.md" 'local note'
  if grep -qx '@AGENTS.md' "$P/AGENTS.local.md"; then fail "the @AGENTS.md import was moved into AGENTS.local.md"; fi
  has_exact_line "$P/AGENTS.md" '# Project notes'
  grep -qF 'CLAUDE.md moved into AGENTS.local.md' <<< "$out" || fail "install did not report CLAUDE.md: $out"
  grep -qF 'CLAUDE.local.md moved into AGENTS.local.md' <<< "$out" || fail "install did not report CLAUDE.local.md: $out"

  printf '@AGENTS.md\n' > "$P/CLAUDE.md"
  local settings; settings="$(cksum < "$P/AGENTS.local.md")"
  run_polype update "$P" >/dev/null
  if [ -e "$P/CLAUDE.md" ]; then fail "update left a CLAUDE.md holding only the import"; fi
  [ "$(cksum < "$P/AGENTS.local.md")" = "$settings" ] || fail "an import-only CLAUDE.md added something to AGENTS.local.md"

  printf '# Global notes\n' > "$CLAUDE_CONFIG_DIR/CLAUDE.md"
  local global; global="$(cksum < "$CLAUDE_CONFIG_DIR/CLAUDE.md")"
  local P2="$SCRATCH/.second"
  git init -q -b main "$P2"
  printf 'Merge mode:        local\nProject CLAUDE file: absorbed\n' > "$P2/AGENTS.local.md"
  printf '# Init notes\n' > "$P2/CLAUDE.md"
  run_polype install --global >/dev/null
  run_polype init "$P2" >/dev/null
  if [ -e "$P2/CLAUDE.md" ]; then fail "init left the project's CLAUDE.md"; fi
  has_exact_line "$P2/AGENTS.local.md" '# Init notes'
  [ "$(cksum < "$CLAUDE_CONFIG_DIR/CLAUDE.md")" = "$global" ] || fail "the user's global CLAUDE.md was touched"
}

gate_sandbox() {
  scratch_repo
  cd "$SCRATCH"
  echo 'x' > app.txt
  git add -A && git commit -qm init
}

refused_naming() {
  local err
  if err=$(bash "$GATE" pre-commit 2>&1); then fail "$1 slipped past the pre-commit"; fi
  grep -qF -- "$1: CLAUDE.md staged" <<< "$err" || fail "the refusal does not name $1: $err"
}

test_precommit_refuses_claude_md() {
  gate_sandbox
  # -f: a global gitignore may exclude these names, and an empty index would pass for nothing.
  echo 'notes' > CLAUDE.md && git add -f CLAUDE.md
  refused_naming CLAUDE.md
  git reset -q && rm CLAUDE.md
  mkdir -p docs/sub && echo 'notes' > docs/sub/CLAUDE.local.md && git add -f docs/sub/CLAUDE.local.md
  refused_naming docs/sub/CLAUDE.local.md
  git branch -f feature/x HEAD && git symbolic-ref HEAD refs/heads/feature/x
  refused_naming docs/sub/CLAUDE.local.md
  git commit -qm 'slipped in' --no-verify
  echo 'more' >> docs/sub/CLAUDE.local.md && git add -f docs/sub/CLAUDE.local.md
  refused_naming docs/sub/CLAUDE.local.md
  git reset -q && git rm -qf docs/sub/CLAUDE.local.md
  bash "$GATE" pre-commit 2>/dev/null || fail "deleting a CLAUDE.local.md was refused"
}

test_session_flags_a_claude_md() {
  scratch_repo
  local R; R="$(cd "$SCRATCH" && pwd -P)"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\nProject CLAUDE file: absorbed\n' \
    > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
  git -C "$R" add -A && git -C "$R" commit -qm framing
  printf 'note\n' > "$R/CLAUDE.local.md"
  local out; out="$(cd "$R" && CLAUDE_PROJECT_DIR="$R" bash "$HOOK")"
  grep -qxF -- '- CLAUDE.local.md: Claude Code reads it instead of AGENTS.md → polype update . moves it into AGENTS.local.md' <<< "$out" \
    || fail "po-session did not flag CLAUDE.local.md: $out"
  rm "$R/CLAUDE.local.md"
  out="$(cd "$R" && CLAUDE_PROJECT_DIR="$R" bash "$HOOK")"
  grep -qxF 'Waiting for a human: nothing' <<< "$out" || fail "po-session still flags something: $out"
}

test_rules_say_no_claude_md() {
  local sentence="Unless \`Project CLAUDE file\` is \`kept\`, the only \`CLAUDE.md\` is the user's global one: no agent creates a \`CLAUDE.md\` or a \`CLAUDE.local.md\` in a project, and the project's notes go in \`AGENTS.local.md\`."
  contains "$METHOD/AGENTS.md" "$sentence"
  contains "$METHOD/commands/po-setup.md" "$sentence"
  contains "$METHOD/commands/po-architect.md" "$sentence"
  contains "$METHOD/AGENTS.md" 'the pre-commit refuses one at any depth'
}
