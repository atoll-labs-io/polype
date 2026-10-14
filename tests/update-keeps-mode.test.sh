#!/usr/bin/env bash
# s135 — polype update keeps the activation mode of the project (#73).

POLYPE="$ROOT/bin/polype"
HOOK="$METHOD/hooks/po-session.sh"
ADR_GLOB="$ROOT/docs/decisions/ADR-0091-*.md"

# A throwaway home holding a global install, and a committed project $P beside it.
fresh_project() {
  scratch_repo
  P="$(cd "$SCRATCH" && pwd -P)"
  export HOME="$P/.home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  printf '.worktrees/\n.home/\n' > "$P/.gitignore"
  git -C "$P" add -A && git -C "$P" commit -qm start
  run_polype install --global >/dev/null
}

run_polype() {
  case "${CLAUDE_CONFIG_DIR-}" in "$P"/*) ;; *) fail "refusing to run outside a throwaway home" ;; esac
  bash "$POLYPE" "$@" 2>&1 || fail "polype failed: $*"
}

laid() { wc -l < "$P/.polype/manifest" | tr -d ' '; }
init_count() { find "$METHOD/templates" "$METHOD/hooks" -type f | wc -l | tr -d ' '; }
mode_is() { [ "$(cat "$P/.polype/mode" 2>/dev/null)" = "$1" ] || fail "$2: .polype/mode is not $1"; }

no_command_copies() {
  local d
  for d in commands agents skills; do
    [ -z "$(find "$P/.claude/$d" -type f 2>/dev/null)" ] || fail "$1: files under .claude/$d"
  done
  if grep -q '^\.claude/' "$P/.polype/manifest"; then fail "$1: the manifest lists .claude/ copies"; fi
}

test_init_then_update_stays_init() {
  fresh_project
  local n; n="$(init_count)"
  run_polype init "$P" >/dev/null
  [ "$(laid)" = "$n" ] || fail "init laid $(laid) files, expected $n"
  run_polype update "$P" >/dev/null
  [ "$(laid)" = "$n" ] || fail "update on an init project laid $(laid) files, expected $n"
  no_command_copies "update after init"

  run_polype install "$P" >/dev/null
  local full; full="$(laid)"
  [ "$full" -gt "$n" ] || fail "install after init did not lay a full install ($full files)"
  run_polype update "$P" >/dev/null
  [ "$(laid)" = "$full" ] || fail "update on a full install laid $(laid) files, expected $full"
}

test_mode_is_recorded() {
  fresh_project
  run_polype init "$P" >/dev/null
  mode_is init "after init"
  run_polype install "$P" >/dev/null
  mode_is project "after install <project>"
  run_polype remove "$P" >/dev/null
  [ ! -e "$P/.polype/mode" ] || fail "remove left .polype/mode"
  [ -z "$(find "$CLAUDE_CONFIG_DIR" -name mode -type f)" ] || fail "the global install wrote a mode file"
}

test_mode_inferred_without_state() {
  fresh_project
  local n; n="$(init_count)"
  run_polype init "$P" >/dev/null
  rm "$P/.polype/mode"
  echo 'my notes' > "$P/CLAUDE.md"
  local out; out="$(run_polype update "$P")"
  [ "$(laid)" = "$n" ] || fail "update without a mode file laid $(laid) files, expected $n"
  no_command_copies "inferred init"
  mode_is init "after an inferred update"
  grep -F 'CLAUDE.md left in place' <<< "$out" | grep -qF 'then polype init .' \
    || fail "the update hint does not say then polype init .: $out"
  if grep -qF 'then polype update .' <<< "$out"; then fail "the update hint says then polype update .: $out"; fi

  rm "$P/CLAUDE.md"
  run_polype install "$P" >/dev/null
  local full; full="$(laid)"
  rm "$P/.polype/mode"
  run_polype update "$P" >/dev/null
  [ "$(laid)" = "$full" ] || fail "update on a full install without mode laid $(laid), expected $full"
  mode_is project "after an inferred update of a full install"
}

test_init_shrinks_a_full_install() {
  fresh_project
  run_polype install "$P" >/dev/null
  run_polype init "$P" >/dev/null
  [ "$(laid)" = "$(init_count)" ] || fail "init on a full install left $(laid) files"
  no_command_copies "init on a full install"
  mode_is init "after init on a full install"
  grep -qF 'polype init .' "$ROOT/docs/installation.md" || fail "installation.md names no polype init . repair"
  grep -qF '(#73)' "$ROOT/docs/installation.md" || fail "installation.md does not name #73 for the repair"
}

test_hints_say_init() {
  fresh_project
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\nProject CLAUDE file: absorbed\n' \
    > "$P/AGENTS.local.md"
  run_polype init "$P" >/dev/null
  git -C "$P" add -A && git -C "$P" commit -qm activate
  printf 'note\n' > "$P/CLAUDE.local.md"
  local out; out="$(cd "$P" && CLAUDE_PROJECT_DIR="$P" bash "$HOOK")"
  grep -qxF -- '- CLAUDE.local.md: Claude Code reads it instead of AGENTS.md → polype init . moves it into AGENTS.local.md' <<< "$out" \
    || fail "po-session does not say polype init . on an init project: $out"

  local step3
  step3="$(awk '/^## Step 3/ {on=1; next} /^## / {on=0} on' "$METHOD/commands/po-setup.md")"
  grep -qF '`polype init .` on a project activated by `init`' <<< "$step3" \
    || fail "po-setup step 3 does not name polype init . for an init project"
  local doc
  for doc in "$ROOT/README.md" "$ROOT/docs/installation.md"; do
    if grep -qF 'poserait' "$doc"; then fail "${doc#"$ROOT"/} still says update would lay the commands"; fi
  done
}

test_adr_records_the_mode() {
  local adr
  adr="$(ls $ADR_GLOB 2>/dev/null | head -n 1)"
  [ -n "$adr" ] || fail "no ADR-0091 in docs/decisions/"
  contains "$adr" '.polype/mode'
  contains "$adr" 'update --init'
  contains "$adr" 'inference'
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0091 is not accepted"
}
