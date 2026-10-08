#!/usr/bin/env bash
# s36 — the installer and its four subcommands. Every run happens in a throwaway project.

POLYPE="$ROOT/bin/polype"

project() { scratch_repo; P="$SCRATCH"; }
polype() { bash "$POLYPE" "$@" >/dev/null 2>&1 || fail "polype failed: $*"; }

# A copy of bin/ and method/ in a temp dir, so a test may change what the installer ships.
# Sets COPY (removed with the scratch project) and POLYPE to the copy's installer.
copy_of_the_method() {
  COPY="$SCRATCH/.method-copy"
  mkdir -p "$COPY"
  cp -r "$ROOT/bin" "$ROOT/method" "$COPY/"
  POLYPE="$COPY/bin/polype"
}

test_installer_supports_install_update_check_and_remove() {
  project
  polype install "$P"
  [ -f "$P/.claude/commands/po-execute.md" ] || fail "install laid nothing down"
  polype update "$P"
  [ -f "$P/.claude/commands/po-execute.md" ] || fail "update dropped an installed file"
  polype check "$P"
  polype remove "$P"
  if [ -e "$P/.claude/commands/po-execute.md" ]; then fail "remove left an installed file behind"; fi
  if [ -e "$P/.polype/manifest" ]; then fail "remove left the manifest behind"; fi
  local status=0
  bash "$POLYPE" frobnicate "$P" >/dev/null 2>&1 || status=$?
  [ "$status" -eq 2 ] || fail "an unknown subcommand must exit 2, got $status"
}

test_installer_stamps_a_version() {
  project && polype install "$P"
  require_file "$P/.polype/version"
  local shipped; shipped=$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$POLYPE" | head -n 1)
  [ -n "$shipped" ] || fail "bin/polype declares no POLYPE_VERSION"
  [ "$(cat "$P/.polype/version")" = "$shipped" ] || fail "the stamp is not the shipped version"
  bash "$POLYPE" check "$P" | grep -qF "$shipped" || fail "check does not show the installed version"
}

test_installer_check_reports_drift() {
  project && polype install "$P"
  bash "$POLYPE" check "$P" >/dev/null || fail "check must exit 0 on a clean install"
  printf 'hand edit\n' >> "$P/.claude/commands/po-execute.md"
  local out
  if out=$(bash "$POLYPE" check "$P" 2>&1); then fail "check must exit non-zero when a file drifted"; fi
  grep -qF '.claude/commands/po-execute.md' <<< "$out" || fail "check did not name the modified file: $out"
}

test_installer_check_is_silent_on_a_clean_install() {
  project && polype install "$P"
  local out; out=$(bash "$POLYPE" check "$P" 2>&1)
  if grep -qF '.claude/commands/po-execute.md' <<< "$out"; then fail "check named a file that did not drift"; fi
  grep -qF 'none modified' <<< "$out" || fail "check does not say the install is clean: $out"
}

test_installer_update_leaves_no_ghost() {
  project && polype install "$P"
  echo '.claude/commands/po-obsolete.md' >> "$P/.polype/manifest"
  touch "$P/.claude/commands/po-obsolete.md" "$P/.claude/commands/my-own.md"
  polype update "$P"
  if [ -e "$P/.claude/commands/po-obsolete.md" ]; then fail "a file no longer shipped survived the update"; fi
  [ -e "$P/.claude/commands/my-own.md" ] || fail "update removed a command the project added"
  if grep -qxF '.claude/commands/po-obsolete.md' "$P/.polype/manifest"; then fail "the ghost is still in the manifest"; fi
}

test_installer_update_preserves_a_modified_file() {
  project && polype install "$P"
  printf 'our own rule\n' >> "$P/.claude/commands/po-execute.md"
  local out; out=$(bash "$POLYPE" update "$P" 2>&1) || fail "update failed"
  grep -qxF 'our own rule' "$P/.claude/commands/po-execute.md" || fail "update overwrote a modified file"
  grep -qF '.claude/commands/po-execute.md' <<< "$out" || fail "update did not report the modified file: $out"
}

test_installer_update_refreshes_an_untouched_file() {
  project && copy_of_the_method
  polype install "$P"
  printf 'a line shipped by a newer version\n' >> "$COPY/method/commands/po-execute.md"
  polype update "$P"
  grep -qxF 'a line shipped by a newer version' "$P/.claude/commands/po-execute.md" \
    || fail "an untouched file was not refreshed from the method"
}

test_installer_remove_leaves_the_project_intact() {
  project
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  mkdir -p "$P/docs"
  printf '# our notes\n' > "$P/docs/notes.md"
  polype install "$P"
  local settings gitignore notes
  settings=$(cksum < "$P/AGENTS.local.md")
  gitignore=$(cksum < "$P/.gitignore")
  notes=$(cksum < "$P/docs/notes.md")
  polype remove "$P"
  if [ -e "$P/.polype/manifest" ]; then fail "the manifest survived remove"; fi
  if [ -e "$P/.claude/commands/po-execute.md" ]; then fail "an installed command survived remove"; fi
  [ "$(cksum < "$P/AGENTS.local.md")" = "$settings" ] || fail "AGENTS.local.md was touched"
  [ "$(cksum < "$P/.gitignore")" = "$gitignore" ] || fail ".gitignore was touched"
  [ "$(cksum < "$P/docs/notes.md")" = "$notes" ] || fail "a document of the project was touched"
}

test_installer_remove_restores_a_hand_written_agents_md() {
  project
  printf '# Our own agent notes\n' > "$P/AGENTS.md"
  printf '# Project notes\n' > "$P/CLAUDE.md"
  polype install "$P"
  polype remove "$P"
  grep -qx '# Our own agent notes' "$P/AGENTS.md" || fail "the hand-written AGENTS.md was not put back"
  if [ -e "$P/AGENTS.md.before-polype" ]; then fail "the backup was left next to the restored file"; fi
  if grep -qx '@AGENTS.md' "$P/CLAUDE.md"; then fail "the import was left in CLAUDE.md"; fi
  grep -qx '# Project notes' "$P/CLAUDE.md" || fail "the project's CLAUDE.md content was lost"
}

test_remove_deletes_a_claude_md_it_created() {
  project
  polype install "$P"
  polype remove "$P"
  if [ -e "$P/CLAUDE.md" ]; then fail "the CLAUDE.md the installer created was left behind"; fi
  rm -rf "$SCRATCH"
  project
  printf '# Project notes\n' > "$P/CLAUDE.md"
  polype install "$P"
  polype remove "$P"
  require_file "$P/CLAUDE.md"
  grep -qx '# Project notes' "$P/CLAUDE.md" || fail "the project's CLAUDE.md content was lost"
  if grep -qx '@AGENTS.md' "$P/CLAUDE.md"; then fail "the import was left in CLAUDE.md"; fi
}

test_remove_leaves_no_empty_file_behind() {
  project
  polype install "$P"
  polype remove "$P"
  local empty leftover
  empty="$(find "$P" -path "$P/.git" -prune -o -type f -empty -print)"
  [ -z "$empty" ] || fail "empty files left after remove: $empty"
  leftover="$(find "$P" -path "$P/.git" -prune -o -name '*.polype-next' -print)"
  [ -z "$leftover" ] || fail "temporary files left after remove: $leftover"
}

test_installer_state_files_are_not_their_own_ghosts() {
  project && polype install "$P"
  if grep -qxF '.polype/version' "$P/.polype/manifest"; then fail ".polype/version is listed in the manifest"; fi
  if grep -qxF '.polype/checksums' "$P/.polype/manifest"; then fail ".polype/checksums is listed in the manifest"; fi
  polype update "$P"
  require_file "$P/.polype/version"
  require_file "$P/.polype/checksums"
}

# s65 — an upgrade names the settings the template gained and the project lacks, and writes none.

test_update_lists_missing_settings() {
  project
  grep -v -e '^Model strong:' -e '^Test:' "$METHOD/templates/agents-local.md" > "$P/AGENTS.local.md"
  local before after out listed status=0
  before="$(cksum < "$P/AGENTS.local.md")"
  polype install "$P"
  out="$(bash "$POLYPE" update "$P" 2>&1)" || fail "update failed: $out"
  listed="$(grep '^missing setting:' <<< "$out" || true)"
  [ "$listed" = "missing setting: Model strong: opus
missing setting: Test: —" ] || fail "update listed: $listed"
  out="$(bash "$POLYPE" check "$P" 2>/dev/null)" || status=$?
  [ "$status" -eq 0 ] || fail "missing settings must not change check's exit status, got $status"
  listed="$(grep '^missing setting:' <<< "$out" || true)"
  [ "$listed" = "missing setting: Model strong: opus
missing setting: Test: —" ] || fail "check listed: $listed"
  after="$(cksum < "$P/AGENTS.local.md")"
  [ "$before" = "$after" ] || fail "the installer wrote AGENTS.local.md"
}

test_installation_doc_has_an_upgrade_section() {
  local section
  section="$(awk '/^## Après une mise à jour$/ {on=1; next} /^## / {on=0} on' "$ROOT/docs/installation.md")"
  [ -n "$section" ] || fail "docs/installation.md has no ## Après une mise à jour section"
  local phrase
  for phrase in 'missing setting: <Nom>: <valeur>' 'ajoute chaque ligne à `AGENTS.local.md`' \
      '`polype check <projet>`' 'relance `polype init <projet>` ou `polype update <projet>`'; do
    grep -qF -- "$phrase" <<< "$section" || fail "the upgrade section does not say: $phrase"
  done
}

test_installation_doc_lists_the_hook_refusals() {
  local section phrase
  section="$(awk "/^### Le hook des bornes de l'implementer\$/ {on=1; next} /^## / {on=0} on" "$ROOT/docs/installation.md")"
  [ -n "$section" ] || fail "docs/installation.md has no bounds-hook section"
  for phrase in 'git update-ref' '-D' '--force' 'cherry-pick' 'pull' 'story/*' 'ADR-0050' \
      'git fetch . HEAD:main' 'GIT_DIR='; do
    grep -qF -- "$phrase" <<< "$section" || fail "the bounds-hook section does not say: $phrase"
  done
}
