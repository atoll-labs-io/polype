#!/usr/bin/env bash
# s37 — the global install in ~/.claude and the per-project `init`.
# Every test runs against a throwaway HOME: nothing here may reach the developer's configuration.

POLYPE="$ROOT/bin/polype"

# A throwaway project and a throwaway user home. HOME *and* CLAUDE_CONFIG_DIR are both redefined,
# so a forgotten override cannot fall back on the real ~/.claude.
global_home() {
  scratch_repo
  P="$SCRATCH"
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  H="$CLAUDE_CONFIG_DIR"
  mkdir -p "$H"
}

# Refuses to run at all if the home under test is not the throwaway one.
guard_home() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
}

# Same guard, for the copies of the installer a test runs instead of the repository's one.
run_polype_at() { local exe="$1"; shift; guard_home; bash "$exe" "$@"; }
run_polype() { run_polype_at "$POLYPE" "$@"; }

polype() { run_polype "$@" >/dev/null 2>&1 || fail "polype failed: $*"; }

exit_status_of() { local s=0; run_polype "$@" >/dev/null 2>&1 || s=$?; printf '%s' "$s"; }

test_installer_global_puts_commands_in_the_user_home() {
  global_home
  polype install --global
  [ -f "$H/commands/po-execute.md" ] || fail "no command in the user home"
  [ -f "$H/agents/reviewer.md" ] || fail "no subagent in the user home"
  [ -f "$H/skills/testing-doctrine/SKILL.md" ] || fail "no skill in the user home"
  if [ -e "$H/.claude" ]; then fail "the global install nested a .claude/ inside the user home"; fi
  [ -x "$H/polype/bin/polype" ] || fail "the payload's installer is missing or not executable"
  [ -f "$H/polype/method/AGENTS.md" ] || fail "the payload's method is missing"
  [ -f "$H/polype/version" ] || fail "the global install left no version stamp"
  # Resolving ../method happens when the script loads, so `help` alone proves the payload stands on its own.
  bash "$H/polype/bin/polype" help >/dev/null 2>&1 || fail "the installed payload cannot resolve its own method"
  if [ -e "$H/AGENTS.md" ] || [ -e "$H/CLAUDE.md" ] || [ -e "$H/.gitignore" ]; then
    fail "the global install wrote a project file into the user home"
  fi
}

test_installer_init_activates_a_project_after_a_global_install() {
  global_home
  polype install --global
  polype init "$P"
  [ -f "$P/.polype/templates/plan.md" ] || fail "init laid no template down"
  [ -x "$P/.polype/hooks/po-gate.sh" ] || fail "the gate is missing or not executable"
  grep -qF 'Nothing reaches the code except through a story' "$P/AGENTS.md" || fail "init did not assemble AGENTS.md"
  if [ -e "$P/CLAUDE.md" ]; then fail "init created a CLAUDE.md"; fi
  [ -f "$P/.polype/version" ] || fail "init left no version stamp"
  if [ -e "$P/.claude/commands" ]; then fail "init copied the commands the global install already serves"; fi
  if [ -e "$P/.claude/agents" ] || [ -e "$P/.claude/skills" ]; then fail "init copied subagents or skills into the project"; fi
  if grep -q '^\.claude/' "$P/.polype/manifest"; then fail "init listed a .claude/ file in the manifest"; fi
}

test_installer_global_update_is_idempotent() {
  global_home
  polype install --global
  local first count_first
  first="$(cat "$H/polype/manifest")"
  count_first="$(find "$H" -type f | wc -l)"
  polype install --global
  [ "$(cat "$H/polype/manifest")" = "$first" ] || fail "a second global install changed the manifest"
  [ "$(find "$H" -type f | wc -l)" = "$count_first" ] || fail "a second global install changed how many files are laid down"
  [ "$(sort "$H/polype/manifest" | uniq -d | wc -l)" -eq 0 ] || fail "the manifest holds a duplicate line"
  polype update --global
  [ "$(cat "$H/polype/manifest")" = "$first" ] || fail "update --global changed the manifest"
  polype check --global
}

test_installer_global_check_reports_payload_drift() {
  global_home
  polype install --global
  printf 'hand edit\n' >> "$H/polype/method/AGENTS.md"
  local out
  if out="$(run_polype check --global 2>&1)"; then fail "check --global must exit non-zero when the payload drifted"; fi
  grep -qF 'polype/method/AGENTS.md' <<< "$out" || fail "check --global did not name the drifted payload file: $out"
}

test_installer_global_remove_leaves_the_user_home_intact() {
  global_home
  polype install --global
  printf 'my own command\n' > "$H/commands/my-own.md"
  printf '{}\n' > "$H/settings.json"
  polype remove --global
  [ -d "$H" ] || fail "remove --global deleted the user home"
  grep -qx 'my own command' "$H/commands/my-own.md" || fail "remove --global took a command the user wrote"
  [ -f "$H/settings.json" ] || fail "remove --global took a file it never laid down"
  if [ -e "$H/polype" ]; then fail "the payload survived remove --global"; fi
  if [ -e "$H/commands/po-execute.md" ]; then fail "an installed command survived remove --global"; fi
  if [ -e "$H/agents/reviewer.md" ]; then fail "an installed subagent survived remove --global"; fi
}

test_installer_global_rejects_a_project_and_global_together() {
  global_home
  [ "$(exit_status_of install --global "$P")" = 2 ] || fail "--global with a project directory must exit 2"
  [ "$(exit_status_of install)" = 2 ] || fail "install without a target must exit 2"
  [ "$(exit_status_of init --global)" = 2 ] || fail "init --global must exit 2"
  if [ -e "$H/commands" ]; then fail "a rejected invocation laid files down anyway"; fi
}

test_installer_usage_names_global_and_init() {
  global_home
  local out; out="$(run_polype help 2>&1)" || fail "polype help failed"
  grep -qF -- '--global' <<< "$out" || fail "the usage does not name --global: $out"
  grep -qF 'init <project-dir>' <<< "$out" || fail "the usage does not name init <project-dir>: $out"
}

test_docs_explain_the_chezmoi_path() {
  local doc="$ROOT/docs/installation.md"
  require_file "$doc"
  contains "$doc" 'chezmoi'
  contains "$doc" '`~/.claude/polype/`'
  contains "$doc" 'CLAUDE_CONFIG_DIR'
  contains "$doc" 'polype init <projet>'
  grep -qF 'manifest' "$doc" && grep -qF 'checksums' "$doc" || fail "the doc does not name the state files"
  grep -qF "n'existe pas encore" "$doc" && fail "the doc still says the global install does not exist"
  return 0
}

# The documented cross-machine command: after a dotfiles sync, the fresh payload installs itself.
# Its sources live inside the install root, so an installer that deletes before it copies wipes
# the very files it is about to lay down — and says nothing.
test_installer_global_install_from_the_payload_keeps_it_whole() {
  global_home
  polype install --global
  local manifest_before files_before out
  manifest_before="$(cat "$H/polype/manifest")"
  files_before="$(find "$H" -type f | wc -l)"
  [ "$(wc -l < "$H/polype/manifest")" -gt 0 ] || fail "the first global install laid nothing down"

  out="$(run_polype_at "$H/polype/bin/polype" install --global 2>&1)" \
    || fail "the payload could not install itself: $out"
  [ "$(cat "$H/polype/manifest")" = "$manifest_before" ] || fail "the payload's own install changed the manifest"
  [ "$(find "$H" -type f | wc -l)" = "$files_before" ] || fail "the payload's own install changed how many files are there"
  [ -x "$H/polype/bin/polype" ] || fail "the payload destroyed its own installer"
  [ -f "$H/polype/method/AGENTS.md" ] || fail "the payload destroyed its own method"
  [ -f "$H/commands/po-execute.md" ] || fail "the payload's own install dropped a command"

  out="$(run_polype_at "$H/polype/bin/polype" update --global 2>&1)" \
    || fail "the payload could not update itself: $out"
  [ -x "$H/polype/bin/polype" ] || fail "update --global from the payload destroyed it"
  run_polype_at "$H/polype/bin/polype" check --global >/dev/null 2>&1 \
    || fail "check --global is not clean after the payload installed and updated itself"
  if [ -e "$H/polype/manifest.next" ] || [ -e "$H/polype/checksums.next" ]; then
    fail "a half-written state file was left behind"
  fi
}

# `ln -s ~/.claude/polype/bin/polype ~/.local/bin/polype` is how the doc puts it on the PATH:
# $0 is then the link, and the method must still be found next to the real script.
test_installer_runs_through_a_symlink() {
  global_home
  polype install --global
  mkdir -p "$SCRATCH/bin"
  ln -s "$H/polype/bin/polype" "$SCRATCH/bin/polype"
  local out
  out="$(run_polype_at "$SCRATCH/bin/polype" init "$P" 2>&1)" || fail "init through a symlink failed: $out"
  [ -f "$P/.polype/templates/plan.md" ] || fail "init through a symlink laid no template down"
  [ -s "$P/AGENTS.md" ] || fail "init through a symlink left an empty AGENTS.md"
  grep -qF 'Nothing reaches the code except through a story' "$P/AGENTS.md" \
    || fail "AGENTS.md was not assembled through the symlink"
  out="$(run_polype_at "$SCRATCH/bin/polype" install --global 2>&1)" \
    || fail "install --global through a symlink failed: $out"
  [ -f "$H/commands/po-execute.md" ] || fail "install --global through a symlink emptied the user home"
  [ "$(wc -l < "$H/polype/manifest")" -gt 0 ] || fail "install --global through a symlink recorded an empty manifest"
}

test_installer_refuses_an_incomplete_payload() {
  global_home
  polype install --global
  local manifest_before broken out status=0
  manifest_before="$(cat "$H/polype/manifest")"
  broken="$SCRATCH/broken"
  mkdir -p "$broken"
  cp -r "$H/polype/bin" "$H/polype/method" "$broken/"
  rm -rf "$broken/method/skills"
  out="$(run_polype_at "$broken/bin/polype" install --global 2>&1)" || status=$?
  [ "$status" -ne 0 ] || fail "an incomplete copy of Polype installed successfully: $out"
  grep -qF 'incomplete' <<< "$out" || fail "the refusal does not say the copy is incomplete: $out"
  [ "$(cat "$H/polype/manifest")" = "$manifest_before" ] || fail "the refused run rewrote the manifest"
  [ -f "$H/commands/po-execute.md" ] || fail "the refused run deleted an installed file"
}

test_installer_init_warns_without_a_global_install() {
  global_home
  local out
  out="$(run_polype init "$P" 2>&1)" || fail "init must lay the project down without a global install: $out"
  grep -qF 'no global install' <<< "$out" || fail "init said nothing about the missing global install: $out"
  [ -f "$P/.polype/templates/plan.md" ] || fail "init laid nothing down"
}

# A payload that travelled through a sync may have lost its executable bits; the gate must be
# executable in the project whatever mode the source carries.
test_installer_makes_the_gate_executable_from_a_stale_payload() {
  global_home
  polype install --global
  chmod -x "$H/polype/method/hooks/po-gate.sh"
  run_polype_at "$H/polype/bin/polype" init "$P" >/dev/null 2>&1 || fail "init from the payload failed"
  [ -x "$P/.polype/hooks/po-gate.sh" ] || fail "the gate is not executable although its source had lost the bit"
}

test_installer_global_remove_keeps_the_standard_directories() {
  global_home
  polype install --global
  polype remove --global
  [ -d "$H" ] || fail "remove --global deleted the user home"
  [ -d "$H/commands" ] || fail "remove --global pruned ~/.claude/commands itself"
  [ -d "$H/agents" ] || fail "remove --global pruned ~/.claude/agents itself"
  [ -d "$H/skills" ] || fail "remove --global pruned ~/.claude/skills itself"
  [ -z "$(find "$H/commands" -type f)" ] || fail "an installed command survived remove --global"
  if [ -e "$H/skills/testing-doctrine" ]; then fail "an emptied skill directory survived remove --global"; fi
}

test_installer_global_check_does_not_create_the_user_home() {
  global_home
  rm -rf "$H"
  [ "$(exit_status_of check --global)" = 1 ] || fail "check --global without an install must exit 1"
  if [ -e "$H" ]; then fail "check --global created the user home"; fi
  [ "$(exit_status_of remove --global)" = 1 ] || fail "remove --global without an install must exit 1"
  if [ -e "$H" ]; then fail "remove --global created the user home"; fi
}
