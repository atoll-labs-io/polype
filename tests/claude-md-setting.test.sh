#!/usr/bin/env bash
# s131 — the "no project CLAUDE.md" rule becomes the Project CLAUDE file setting.

POLYPE="$ROOT/bin/polype"
GATE="$METHOD/hooks/po-gate.sh"
HOOK="$METHOD/hooks/po-session.sh"

# A committed project whose AGENTS.local.md holds the settings po-session reads, plus $1 when given.
framed_project() {
  scratch_repo
  P="$(cd "$SCRATCH" && pwd -P)"
  export HOME="$P/.home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\n' \
    > "$P/AGENTS.local.md"
  [ -z "${1:-}" ] || printf '%s\n' "$1" >> "$P/AGENTS.local.md"
  printf '.worktrees/\n.home/\n' > "$P/.gitignore"
  git -C "$P" add -A && git -C "$P" commit -qm framing
}

run_polype() {
  case "${CLAUDE_CONFIG_DIR-}" in "$SCRATCH"/*|"$P"/*) ;; *) fail "refusing to run outside a throwaway home" ;; esac
  bash "$POLYPE" "$@" 2>&1 || fail "polype failed: $*"
}

session() { (cd "$P" && CLAUDE_PROJECT_DIR="$P" bash "$HOOK"); }

# -f: a global gitignore may exclude these names.
stage_claude_files() {
  mkdir -p "$P/docs/sub" && echo 'notes' > "$P/docs/sub/CLAUDE.local.md"
  (cd "$P" && git add -f CLAUDE.md docs/sub/CLAUDE.local.md)
}

test_setting_has_two_values() {
  local tpl="$METHOD/templates/agents-local.md"
  awk '/^```/ {f=!f; next} f' "$tpl" | grep -qx 'Project CLAUDE file: absorbed' \
    || fail "the template's settings block lacks Project CLAUDE file: absorbed"
  grep '^| Project CLAUDE file |' "$tpl" | grep -F '`absorbed`' | grep -qF '`kept`' \
    || fail "the template's values table does not give absorbed and kept"
  local step2; step2=$(awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$METHOD/commands/po-setup.md")
  grep -F 'AskUserQuestion call for `Project CLAUDE file`' <<< "$step2" | grep -F '`absorbed` (suggested)' | grep -qF '`kept`' \
    || fail "po-setup Step 2 does not ask Project CLAUDE file with absorbed suggested and kept"
  grep -qx 'Project CLAUDE file: absorbed' "$ROOT/AGENTS.local.md" || fail "Polype's AGENTS.local.md lacks the setting"
  settings_read_by "$METHOD/commands/po-architect.md" | grep -qx 'Project CLAUDE file' \
    || fail "po-architect does not declare it reads Project CLAUDE file"
}

test_kept_keeps_and_imports() {
  framed_project 'Project CLAUDE file: kept'
  printf '# Our notes\nmore\n@AGENTS.md\n' > "$P/CLAUDE.md"
  printf 'local note\n' > "$P/CLAUDE.local.md"
  local local_sum; local_sum="$(cksum < "$P/CLAUDE.local.md")"
  run_polype install "$P" >/dev/null
  [ -f "$P/CLAUDE.md" ] && [ -f "$P/CLAUDE.local.md" ] || fail "kept lost a CLAUDE.md or CLAUDE.local.md"
  [ "$(head -n 1 "$P/CLAUDE.md")" = '@AGENTS.md' ] || fail "CLAUDE.md does not start with @AGENTS.md"
  [ "$(grep -cx '@AGENTS.md' "$P/CLAUDE.md")" -eq 1 ] || fail "CLAUDE.md holds the import more than once"
  [ "$(grep -vx '@AGENTS.md' "$P/CLAUDE.md")" = "$(printf '# Our notes\nmore')" ] || fail "the notes of CLAUDE.md changed"
  [ "$(cksum < "$P/CLAUDE.local.md")" = "$local_sum" ] || fail "CLAUDE.local.md was touched"
  if grep -qF '## Notes moved from CLAUDE.md' "$P/AGENTS.local.md"; then fail "kept moved notes into AGENTS.local.md"; fi
  local sum; sum="$(cksum < "$P/CLAUDE.md")"
  run_polype update "$P" >/dev/null
  [ "$(cksum < "$P/CLAUDE.md")" = "$sum" ] || fail "a second update changed CLAUDE.md"
  if bash "$POLYPE" check "$P" 2>&1 | grep -qF 'Project CLAUDE file'; then fail "check names a setting that is kept"; fi

  stage_claude_files
  (cd "$P" && bash "$GATE" pre-commit 2>/dev/null) || fail "with kept, the pre-commit refused a CLAUDE.md"
  git -C "$P" reset -q
  session | grep -qxF 'Waiting for a human: nothing' || fail "po-session flags a kept CLAUDE.md: $(session)"

  run_polype remove "$P" >/dev/null
  [ "$(cat "$P/CLAUDE.md")" = "$(printf '# Our notes\nmore')" ] || fail "remove did not leave the notes without the import"

  rm -f "$P/CLAUDE.md" "$P/CLAUDE.local.md"
  run_polype install "$P" >/dev/null
  [ ! -e "$P/CLAUDE.md" ] || fail "kept created CLAUDE.md with no CLAUDE file around"
  printf 'local note\n' > "$P/CLAUDE.local.md"
  run_polype update "$P" >/dev/null
  [ "$(cat "$P/CLAUDE.md")" = '@AGENTS.md' ] || fail "with only CLAUDE.local.md, CLAUDE.md does not hold exactly @AGENTS.md"
  run_polype remove "$P" >/dev/null
  [ ! -e "$P/CLAUDE.md" ] || fail "remove left the CLAUDE.md the installer created"
  [ -f "$P/CLAUDE.local.md" ] || fail "remove took CLAUDE.local.md"

  printf '# CRLF notes\r\n@AGENTS.md\r\n' > "$P/CLAUDE.md"
  run_polype install "$P" >/dev/null
  [ "$(cat "$P/CLAUDE.md")" = "$(printf '@AGENTS.md\n# CRLF notes\r')" ] \
    || fail "a CRLF CLAUDE.md kept a second import: $(od -c "$P/CLAUDE.md")"
}

test_missing_setting_changes_nothing() {
  local value
  for value in '' 'Project CLAUDE file: keep'; do
    framed_project "$value"
    printf '@AGENTS.md\n' > "$P/CLAUDE.md"
    printf 'local note\n' > "$P/CLAUDE.local.md"
    local a b out; a="$(cksum < "$P/CLAUDE.md")"; b="$(cksum < "$P/CLAUDE.local.md")"
    out="$(run_polype install "$P")"
    [ "$(cksum < "$P/CLAUDE.md")" = "$a" ] && [ "$(cksum < "$P/CLAUDE.local.md")" = "$b" ] \
      || fail "with '$value', install touched a CLAUDE file"
    grep -qF 'CLAUDE.md left in place: Project CLAUDE file' <<< "$out" || fail "install does not name the setting: $out"
    out="$(run_polype update "$P")"
    [ "$(cksum < "$P/CLAUDE.md")" = "$a" ] || fail "with '$value', update touched CLAUDE.md"
    out="$(bash "$POLYPE" check "$P" 2>&1 || true)"
    if [ -z "$value" ]; then
      grep -qxF 'missing setting: Project CLAUDE file: absorbed' <<< "$out" || fail "check does not name the setting: $out"
    else
      grep -qxF 'invalid setting: Project CLAUDE file: keep (set it to absorbed or kept)' <<< "$out" \
        || fail "check does not name the mistyped setting: $out"
    fi
    if grep -qF 'moves it' <<< "$out"; then fail "check announces a move: $out"; fi
    out="$(session)"
    grep -qF 'set Project CLAUDE file to absorbed or kept' <<< "$out" || fail "po-session does not name the setting: $out"
    if grep -qF 'polype update . moves it' <<< "$out"; then fail "po-session announces a move: $out"; fi
    stage_claude_files
    if (cd "$P" && bash "$GATE" pre-commit 2>/dev/null); then fail "with '$value', the pre-commit let a CLAUDE.md through"; fi
    rm -rf "$SCRATCH"
  done
}

test_adr_records_the_choice() {
  local dir="$ROOT/docs/decisions" files adr old
  files=("$dir"/ADR-0089-*.md)
  [ ${#files[@]} -eq 1 ] && [ -f "${files[0]}" ] || fail "expected exactly one ADR-0089"
  adr="${files[0]}"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0089 is not accepted"
  frontmatter "$adr" | grep '^supersedes:' | grep -qF 'ADR-0086' || fail "ADR-0089 does not supersede ADR-0086"
  local w; for w in '`kept`' '`absorbed`' 'Écartée' 'déjà installé'; do contains "$adr" "$w"; done
  old="$(ls "$dir"/ADR-0086-*.md)"
  frontmatter "$old" | grep '^superseded-by:' | grep -qF 'ADR-0089' || fail "ADR-0086 does not point to ADR-0089"
  frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0086 changed status"
  [ "$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{f=0;next} !f' "$old" | cksum)" = '1287032947 3025' ] \
    || fail "the body of ADR-0086 changed"
  local sentence="Unless \`Project CLAUDE file\` is \`kept\`, the only \`CLAUDE.md\` is the user's global one"
  local f
  for f in "$METHOD/AGENTS.md" "$METHOD/commands/po-setup.md" "$METHOD/commands/po-architect.md"; do
    contains "$f" "$sentence"
  done
  contains "$METHOD/commands/po-setup.md" 'Never commit a `CLAUDE.md` (ADR-0086) unless `Project CLAUDE file` is `kept`'
  contains "$METHOD/commands/po-architect.md" 'Never commit a `CLAUDE.md` (ADR-0086); with `Project CLAUDE file: kept`'
  contains "$METHOD/AGENTS.md" 'with `kept`, both stay, the installer makes the root `CLAUDE.md` start with `@AGENTS.md`'
}
