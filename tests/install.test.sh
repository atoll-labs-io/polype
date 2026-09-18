#!/usr/bin/env bash
# s09 — development installer.

INSTALL="$ROOT/bin/polype-dev-install"

project() { scratch_repo; P="$SCRATCH"; }
install() { bash "$INSTALL" "$@" >/dev/null 2>&1 || fail "installer failed: $*"; }

test_install_copies_commands_agents_skills_templates() {
  project && install "$P"
  [ -f "$P/.claude/commands/po-execute.md" ] || fail "commands not installed"
  [ -f "$P/.claude/agents/reviewer.md" ] || fail "agents not installed"
  [ -f "$P/.claude/skills/testing-doctrine/SKILL.md" ] || fail "skills not installed"
  [ -f "$P/.polype/templates/plan.md" ] || fail "templates not installed"
  [ -x "$P/.polype/hooks/po-gate.sh" ] || fail "gate not installed as executable"
}

test_install_copies_skill_subdirectories() {
  project
  local method_copy; method_copy="$(mktemp -d)"
  cp -r "$ROOT/bin" "$ROOT/method" "$method_copy/"
  mkdir -p "$method_copy/method/skills/testing-doctrine/examples"
  echo 'example' > "$method_copy/method/skills/testing-doctrine/examples/one.md"
  bash "$method_copy/bin/polype-dev-install" "$P" >/dev/null 2>&1 || fail "installer failed on a nested skill folder"
  [ -f "$P/.claude/skills/testing-doctrine/examples/one.md" ] || fail "nested skill file not installed"
  rm -rf "$method_copy"
}

test_install_assembles_agents_md_from_rules_and_settings() {
  project
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  install "$P"
  grep -qF 'Nothing reaches the code except through a story' "$P/AGENTS.md" || fail "rules missing from AGENTS.md"
  grep -qx 'Merge mode:        local' "$P/AGENTS.md" || fail "settings missing from AGENTS.md"
}

test_install_keeps_a_hand_written_agents_md() {
  project
  printf '# Our own agent notes\n' > "$P/AGENTS.md"
  install "$P"
  grep -qx '# Our own agent notes' "$P/AGENTS.md.before-polype" || fail "hand-written AGENTS.md was lost"
  install "$P"
  grep -qx '# Our own agent notes' "$P/AGENTS.md.before-polype" || fail "the backup was overwritten by a reinstall"
}

test_install_adds_claude_md_import_once() {
  project
  printf '# Project notes\n' > "$P/CLAUDE.md"
  install "$P" && install "$P"
  [ "$(grep -cx '@AGENTS.md' "$P/CLAUDE.md")" -eq 1 ] || fail "@AGENTS.md must appear exactly once"
  grep -qx '# Project notes' "$P/CLAUDE.md" || fail "existing CLAUDE.md content was lost"
}

test_install_never_touches_settings() {
  project
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  local before; before=$(cksum < "$P/AGENTS.local.md")
  install "$P"
  [ "$(cksum < "$P/AGENTS.local.md")" = "$before" ] || fail "AGENTS.local.md was modified"
}

test_install_ignores_worktrees_and_env_files() {
  project
  printf 'Worktree root:     wt/\n' > "$P/AGENTS.local.md"
  install "$P" && install "$P"
  [ "$(grep -cx 'wt/' "$P/.gitignore")" -eq 1 ] || fail "configured worktree root not ignored exactly once"
  grep -qxF '.env*' "$P/.gitignore" || fail ".env* not ignored"
}

test_install_removes_files_no_longer_shipped() {
  project && install "$P"
  echo '.claude/commands/po-obsolete.md' >> "$P/.polype/manifest"
  touch "$P/.claude/commands/po-obsolete.md" "$P/.claude/commands/my-own.md"
  install "$P"
  [ ! -e "$P/.claude/commands/po-obsolete.md" ] || fail "a file of the previous install survived"
  [ -e "$P/.claude/commands/my-own.md" ] || fail "a project's own command was removed"
}

test_install_hooks_flag_sets_hooks_path_in_any_position() {
  project && install --hooks "$P"
  [ "$(git -C "$P" config core.hooksPath)" = ".polype/hooks" ] || fail "core.hooksPath not set"
}

test_install_leaves_an_existing_hooks_path_alone() {
  project
  git -C "$P" config core.hooksPath .husky
  install "$P" --hooks
  [ "$(git -C "$P" config core.hooksPath)" = ".husky" ] || fail "an existing core.hooksPath was replaced"
}

test_rules_explain_installed_paths() {
  contains "$METHOD/AGENTS.md" 'a reference to `templates/<name>.md` means `.polype/templates/<name>.md`'
}
