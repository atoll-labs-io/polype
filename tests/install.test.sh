#!/usr/bin/env bash
# s09 — development installer.

INSTALL="$ROOT/bin/polype-dev-install"

project() {
  local dir; dir="$(mktemp -d)"
  git -C "$dir" init -q -b main
  echo "$dir"
}

test_install_copies_commands_agents_skills_templates() {
  local p; p=$(project)
  bash "$INSTALL" "$p" >/dev/null || fail "installer failed" || return 1
  [ -f "$p/.claude/commands/po-execute.md" ] || fail "commands not installed" || return 1
  [ -f "$p/.claude/agents/reviewer.md" ] || fail "agents not installed" || return 1
  [ -f "$p/.claude/skills/testing-doctrine/SKILL.md" ] || fail "skills not installed" || return 1
  [ -f "$p/.polype/templates/plan.md" ] || fail "templates not installed" || return 1
  [ -x "$p/.polype/hooks/po-gate.sh" ] || fail "gate not installed as executable"
}

test_install_assembles_agents_md_from_rules_and_settings() {
  local p; p=$(project)
  printf 'Merge mode:        local\n' > "$p/AGENTS.local.md"
  bash "$INSTALL" "$p" >/dev/null || return 1
  grep -qF 'No code is written outside the pipeline' "$p/AGENTS.md" || fail "rules missing from AGENTS.md" || return 1
  grep -qx 'Merge mode:        local' "$p/AGENTS.md" || fail "settings missing from AGENTS.md"
}

test_install_adds_claude_md_import_once() {
  local p; p=$(project)
  printf '# Project notes\n' > "$p/CLAUDE.md"
  bash "$INSTALL" "$p" >/dev/null && bash "$INSTALL" "$p" >/dev/null || return 1
  [ "$(grep -cx '@AGENTS.md' "$p/CLAUDE.md")" -eq 1 ] || fail "@AGENTS.md must appear exactly once" || return 1
  grep -qx '# Project notes' "$p/CLAUDE.md" || fail "existing CLAUDE.md content was lost"
}

test_install_never_touches_settings() {
  local p before; p=$(project)
  printf 'Merge mode:        local\n' > "$p/AGENTS.local.md"
  before=$(cksum < "$p/AGENTS.local.md")
  bash "$INSTALL" "$p" >/dev/null || return 1
  [ "$(cksum < "$p/AGENTS.local.md")" = "$before" ] || fail "AGENTS.local.md was modified"
}

test_install_removes_files_no_longer_shipped() {
  local p; p=$(project)
  bash "$INSTALL" "$p" >/dev/null || return 1
  echo '.claude/commands/po-obsolete.md' >> "$p/.polype/manifest"
  touch "$p/.claude/commands/po-obsolete.md" "$p/.claude/commands/my-own.md"
  bash "$INSTALL" "$p" >/dev/null || return 1
  [ ! -e "$p/.claude/commands/po-obsolete.md" ] || fail "a file of the previous install survived" || return 1
  [ -e "$p/.claude/commands/my-own.md" ] || fail "a project's own command was removed"
}

test_install_hooks_flag_sets_hooks_path() {
  local p; p=$(project)
  bash "$INSTALL" "$p" --hooks >/dev/null || return 1
  [ "$(git -C "$p" config core.hooksPath)" = ".polype/hooks" ] || fail "core.hooksPath not set"
}

test_rules_explain_installed_paths() {
  contains "$METHOD/AGENTS.md" '`templates/<name>.md` anywhere in these rules or in a command means `.polype/templates/<name>.md`'
}
