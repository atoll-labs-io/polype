#!/usr/bin/env bash
# s132 — the README alone gets a newcomer installed, started and updated, and an old bash is named.

README="$ROOT/README.md"
CLONE_URL='https://github.com/atoll-labs-io/polype.git'

readme_section() { awk -v h="## $1" '$0 == h {on=1; next} on && /^## / {exit} on {print}' "$README"; }

# The fenced blocks of a text, each one preceded by a line `@@ <language>`.
fenced_blocks() {
  awk '/^```/ { if (f) {f=0; next} f=1; lang=substr($0, 4); print "@@ " lang; next } f {print}'
}

guard_block() { sed -n '/^if .*BASH_VERSINFO/,/^fi$/p' "$1"; }

first_line_matching() { grep -nE "$2" "$1" | head -n 1 | cut -d: -f1; }

# Runs a guard block with a fake version; prints "<status>|<stdout>|<stderr>".
run_guard() {
  local block="$1" version="$2" out err status=0 errfile
  errfile="$(mktemp)"
  out="$(bash -c "FAKE_VERSINFO=($version); ${block//BASH_VERSINFO/FAKE_VERSINFO}
echo reached" 2>"$errfile")" || status=$?
  err="$(cat "$errfile")"; rm -f "$errfile"
  printf '%s|%s|%s' "$status" "$out" "$err"
}

test_old_bash_is_named() {
  local file name block guard first r status out err v
  for file in "$ROOT/bin/polype" "$METHOD/hooks/po-session.sh"; do
    name="${file##*/}"
    guard="$(first_line_matching "$file" '^if .*BASH_VERSINFO')"
    [ -n "$guard" ] || fail "$name has no bash version guard"
    first="$(first_line_matching "$file" 'declare -|mapfile|readarray')"
    [ "$guard" -lt "$first" ] || fail "$name: the guard (line $guard) comes after a bash 4 construct (line $first)"
    block="$(guard_block "$file")"
    for v in '3 2' '4 1'; do
      r="$(run_guard "$block" "$v")"
      status="${r%%|*}" r="${r#*|}" out="${r%%|*}" err="${r#*|}"
      if grep -qF reached <<< "$out"; then fail "$name went on under bash $v"; fi
      if [ "$name" = polype ]; then
        [ "$status" = 1 ] || fail "polype exited $status under bash $v, not 1"
        grep -qF "bash ${v/ /.} found" <<< "$err" && grep -qF '4.2' <<< "$err" \
          || fail "polype did not name bash ${v/ /.} and 4.2 on stderr: $err"
      else
        [ "$status" = 0 ] || fail "po-session exited $status under bash $v, not 0"
        grep -qF "bash ${v/ /.} found" <<< "$out" && grep -qF '4.2' <<< "$out" \
          || fail "po-session did not name bash ${v/ /.} and 4.2 on stdout: $out"
      fi
    done
    for v in '4 2' '5 0'; do
      r="$(run_guard "$block" "$v")"
      r="${r#*|}"
      grep -qF reached <<< "${r%%|*}" || fail "$name refused bash $v"
    done
  done
  first="$(first_line_matching "$ROOT/bin/polype" '^[[:space:]]*(mkdir|cp|mv) ')"
  guard="$(first_line_matching "$ROOT/bin/polype" '^if .*BASH_VERSINFO')"
  [ "$guard" -lt "$first" ] || fail "bin/polype: the guard comes after a write (line $first)"
}

test_prerequisites_are_listed() {
  local sec phrase
  sec="$(readme_section 'Prérequis')"
  [ -n "$sec" ] || fail "README has no ## Prérequis section"
  for phrase in 'Claude Code' 'git' '4.2' 'brew install bash' 'jq' 'SessionStart' 'gh' 'BSD'; do
    grep -qF -- "$phrase" <<< "$sec" || fail "## Prérequis does not say: $phrase"
  done
}

test_quickstart_runs_as_written() {
  local sec blocks langs clone sh1 text sh2 script dir newpath="" n
  sec="$(readme_section 'Démarrage rapide')"
  [ -n "$sec" ] || fail "README has no ## Démarrage rapide section"
  blocks="$(fenced_blocks <<< "$sec")"
  langs="$(grep '^@@ ' <<< "$blocks" | tr '\n' ' ')"
  [ "$langs" = '@@ sh @@ sh @@ text @@ sh ' ] || fail "expected blocks sh, sh, text, sh in ## Démarrage rapide, got: $langs"
  clone="$(awk '/^@@ / {n++; next} n==1' <<< "$blocks")"
  sh1="$(awk '/^@@ / {n++; next} n==2' <<< "$blocks")"
  text="$(awk '/^@@ / {n++; next} n==3' <<< "$blocks")"
  sh2="$(awk '/^@@ / {n++; next} n==4' <<< "$blocks")"
  # The clone stands alone, so the reader can stop before any --global.
  [ "$clone" = "git clone $CLONE_URL ~/src/polype" ] || fail "the first block is not the clone alone: $clone"
  local prev=0 step
  for step in "install --global" "ln -s" "polype init"; do
    n="$(grep -nF -- "$step" <<< "$sh1" | head -n 1 | cut -d: -f1)"
    [ -n "$n" ] && [ "$n" -gt "$prev" ] || fail "the first block does not run '$step' in order"
    prev="$n"
  done
  n="$(grep -n '^/po-setup' <<< "$text" | cut -d: -f1)"
  [ -n "$n" ] && [ "$n" -lt "$(grep -n '^/po-drive' <<< "$text" | cut -d: -f1)" ] \
    || fail "the Claude Code block does not hold /po-setup then /po-drive"
  if grep -qF '/po-' <<< "$sh1$sh2"; then fail "a shell block holds a Claude Code command"; fi
  if grep -qF 'polype update .' <<< "$sh2"; then fail "the update block runs polype update . on an init project"; fi
  # The risk-free try sits between the clone and the global install.
  local intro
  intro="$(awk '/^```/ {f++; next} f==2 {print} f==3 {exit}' <<< "$sec")"
  grep -qF '~/src/polype/bin/polype install ~/' <<< "$intro" && grep -qF '~/src/polype/bin/polype remove ~/' <<< "$intro" \
    || fail "the throwaway-clone try does not come before the global install"

  scratch_repo
  export HOME="$SCRATCH/home"
  # Not the default ~/.claude, so a link hard-coding that path dangles.
  export CLAUDE_CONFIG_DIR="$HOME/.config/claude"
  case "$CLAUDE_CONFIG_DIR" in "$SCRATCH"/*) ;; *) fail "refusing to run outside the scratch dir" ;; esac
  mkdir -p "$HOME/mon-projet"
  git -C "$HOME/mon-projet" init -q -b main
  # polype must resolve only through the link the block creates.
  local dirs
  IFS=: read -r -a dirs <<< "$PATH"
  for dir in "${dirs[@]}"; do
    if [ -n "$dir" ] && [ ! -e "$dir/polype" ]; then newpath="${newpath:+$newpath:}$dir"; fi
  done
  script="$(printf '%s\n%s\n%s\n' "$clone" "$sh1" "$sh2" | sed "s|$CLONE_URL|file://$ROOT|")"
  [ "$(grep -c "file://$ROOT" <<< "$script")" = 1 ] || fail "the clone URL was not substituted exactly once"
  local out
  out="$(cd "$SCRATCH" && PATH="$newpath" bash -e -c "$script" 2>&1)" || fail "the quickstart failed: $out"
  out="$(cd "$SCRATCH" && PATH="$newpath" bash -e -c "$(grep -F 'ln -s' <<< "$sh1")" 2>&1)" \
    || fail "the link line fails when the first block is run again: $out"
  out="$(PATH="$HOME/.local/bin:$newpath" polype check --global 2>&1)" || fail "check --global failed: $out"
  grep -qF 'none modified' <<< "$out" || fail "check --global found drift: $out"
  out="$(PATH="$HOME/.local/bin:$newpath" polype check "$HOME/mon-projet" 2>&1)" || fail "project check failed: $out"
  grep -qF 'none modified' <<< "$out" || fail "project check found drift: $out"
  [ ! -e "$HOME/mon-projet/.claude/commands" ] || fail "the update laid commands into the init project"
}

test_existing_config_is_explained() {
  local sec phrase n kib
  sec="$(readme_section 'Ce que Polype fait de ta configuration')"
  [ -n "$sec" ] || fail "README has no ## Ce que Polype fait de ta configuration section"
  for phrase in '--set-aside' '.before-polype' 'AGENTS.md' 'Notes moved from AGENTS.md' 'CLAUDE.md' \
      'Project CLAUDE file' 'absorbed' 'kept' 'polype install'; do
    grep -qF -- "$phrase" <<< "$sec" || fail "the configuration section does not say: $phrase"
  done
  n="$(grep -oE 'environ [0-9]+ Ko' <<< "$sec" | grep -oE '[0-9]+')"
  [ -n "$n" ] || fail "the configuration section gives no size as 'environ N Ko'"
  kib=$(( $(wc -c < "$METHOD/AGENTS.md") / 1024 ))
  [ $((n * 4)) -ge $((kib * 3)) ] && [ $((n * 4)) -le $((kib * 5)) ] \
    || fail "the README says $n Ko, method/AGENTS.md is $kib Ko"
}

test_install_doc_tells_the_truth() {
  local doc="$ROOT/docs/installation.md" joined phrase para
  for phrase in '--set-aside' '.before-polype' 'Notes moved from AGENTS.md' 'Project CLAUDE file' \
      'kept' 'ADR-0088' 'ADR-0089'; do
    contains "$doc" "$phrase"
  done
  joined="$(tr '\n' ' ' < "$doc")"
  if grep -qF "ni aux fichiers qu'on a ajoutés" <<< "$joined"; then fail "the doc still says added files are never touched"; fi
  if grep -qF "écrit à la main est d'abord sauvegardé" <<< "$joined"; then fail "the doc still backs AGENTS.md up"; fi
  para="$(awk -v RS= '/ceux qu.il trouve \(ADR-0086\)/' "$doc")"
  [ -n "$para" ] || fail "no paragraph holds ceux qu'il trouve (ADR-0086)"
  grep -qF 'Project CLAUDE file' <<< "$para" || fail "the ADR-0086 paragraph does not name Project CLAUDE file"
}

# The hints left by a pose that found a CLAUDE.md or an AGENTS.md and no AGENTS.local.md name the same pose again.
test_setup_hint_names_the_pose() {
  local pose expected wrong p out hint
  scratch_repo
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  for pose in init install; do
    if [ "$pose" = init ]; then expected='polype init .' wrong='polype update .'
    else expected='polype update .' wrong='polype init .'; fi
    p="$SCRATCH/$pose"
    mkdir -p "$p" && git -C "$p" init -q -b main
    echo 'my notes' > "$p/CLAUDE.md"
    echo 'my rules' > "$p/AGENTS.md"
    out="$(bash "$ROOT/bin/polype" "$pose" "$p" 2>&1)" || fail "polype $pose failed: $out"
    for hint in 'CLAUDE.md left in place' 'AGENTS.md kept as AGENTS.md.before-polype'; do
      grep -F "$hint" <<< "$out" | grep -qF "run /po-setup, then $expected" \
        || fail "polype $pose: the '$hint' hint does not say then $expected: $out"
    done
    if grep -qF "then $wrong" <<< "$out"; then fail "polype $pose says then $wrong: $out"; fi
  done
}
