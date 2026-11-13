#!/usr/bin/env bash
# s161 — no stop of the installer leaves a file of the person behind without naming it.
# Every run happens in a throwaway directory, with a throwaway HOME and CLAUDE_CONFIG_DIR.

POLYPE="$ROOT/bin/polype"

leftover_home() {
  scratch_repo
  export HOME="$SCRATCH/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  H="$CLAUDE_CONFIG_DIR"
  mkdir -p "$H"
}

# Sets OUT and STATUS; never fails by itself.
leftover_run() {
  case "${CLAUDE_CONFIG_DIR-}" in
    "$SCRATCH"/*) ;;
    *) fail "refusing to run: CLAUDE_CONFIG_DIR is '${CLAUDE_CONFIG_DIR-unset}', not inside $SCRATCH" ;;
  esac
  STATUS=0
  OUT="$(bash "$POLYPE" "$@" 2>&1)" || STATUS=$?
}

leftover_ok() { leftover_run "$@"; [ "$STATUS" -eq 0 ] || fail "polype $* failed ($STATUS): $OUT"; }

leftover_project() {
  P="$SCRATCH/project"
  mkdir -p "$P"
  git -C "$P" init -q -b main
}

test_failed_remove_names_held_files() {
  leftover_home
  leftover_ok install --global
  local aside="$H/polype/bin/polype.before-polype" shim="$SCRATCH/shim" real saved_path f found=no bin_at method_at
  bin_at="$(grep -nx 'polype/bin/polype' "$H/polype/manifest" | cut -d: -f1)"
  method_at="$(grep -nx 'polype/method/AGENTS.md' "$H/polype/manifest" | cut -d: -f1)"
  [ -n "$bin_at" ] && [ -n "$method_at" ] && [ "$bin_at" -lt "$method_at" ] \
    || fail "the fixture needs polype/bin/polype listed before polype/method/AGENTS.md in the manifest"
  echo "the person's file" > "$aside"
  echo "# mine" >> "$H/polype/method/AGENTS.md"
  # Every move into polype.kept/ fails, so remove stops after it has held the set-aside file.
  real="$(command -v mv)"
  mkdir -p "$shim"
  cat > "$shim/mv" <<EOF
#!/usr/bin/env bash
for last in "\$@"; do :; done
case "\$last" in */polype.kept/*) echo "mv: refused by the test: \$last" >&2; exit 1 ;; esac
exec "$real" "\$@"
EOF
  chmod +x "$shim/mv"
  saved_path="$PATH"
  PATH="$shim:$PATH"
  leftover_run remove --global
  PATH="$saved_path"
  [ "$STATUS" -ne 0 ] || fail "remove --global should stop when a move into polype.kept/ fails: $OUT"
  while IFS= read -r f; do
    grep -qF -- "$f" <<< "$OUT" || fail "remove --global left $f without naming it: $OUT"
    if [ "$(cat "$f")" = "the person's file" ]; then found=yes; fi
  done < <(find "$H" -path "$H/.polype-restore.*" \( -type f -o -type l \))
  if [ -f "$aside" ] && [ "$(cat "$aside")" = "the person's file" ]; then found=yes; fi
  [ "$found" = yes ] || fail "the set-aside file is neither back in its place nor named where it is held: $OUT"
}

test_interrupted_run_leaves_a_named_trace() {
  leftover_home
  leftover_project
  local f last
  mkdir -p "$P/.claude/agents" "$P/.claude/commands"
  echo mine > "$P/.claude/agents/reviewer.md"
  echo mine > "$P/.claude/commands/po-plan.md"
  # A plain file where the state directory goes makes the run fail right after its moves.
  echo "not a directory" > "$P/.polype"
  leftover_run install "$P" --set-aside
  [ "$STATUS" -ne 0 ] || fail "install --set-aside should fail when .polype is a file: $OUT"
  # What the run printed after the failure itself: the polype lines that follow the last other line.
  last="$(awk '!/^polype: / { n = NR } { line[NR] = $0 } END { for (i = n + 1; i <= NR; i++) print line[i] }' <<< "$OUT")"
  for f in agents/reviewer.md commands/po-plan.md; do
    [ -f "$P/.claude/$f.before-polype" ] || fail "the fixture expects $f to be set aside before the failure: $OUT"
    grep -qF -- "$P/.claude/$f -> $P/.claude/$f.before-polype" <<< "$last" \
      || fail "the stop does not end by naming $f and its new path: $OUT"
  done
}

test_orphan_before_polype_is_reported() {
  leftover_home
  leftover_project
  local before
  printf 'Merge mode:        local\n' > "$P/AGENTS.local.md"
  printf '# Notes nobody laid aside through Polype\n' > "$P/AGENTS.md.before-polype"
  before="$(cksum < "$P/AGENTS.md.before-polype")"
  leftover_ok install "$P"
  [ -f "$P/AGENTS.md.before-polype" ] && [ "$(cksum < "$P/AGENTS.md.before-polype")" = "$before" ] \
    || fail "an AGENTS.md.before-polype with no AGENTS.md laid by Polype was not kept as it was: $OUT"
  grep -qF -- 'AGENTS.md.before-polype' <<< "$OUT" || fail "the installer kept the orphan without saying so: $OUT"
}

test_state_pattern_stays_at_the_top() {
  leftover_home
  leftover_ok install --global
  local f
  printf 'half written\n' > "$H/polype/manifest.next"
  leftover_ok update --global
  printf 'my notes\n' > "$H/polype/method/notes.next"
  printf 'my draft\n' > "$H/polype/bin/draft.polype-next"
  leftover_run update --global
  [ "$STATUS" -eq 1 ] || fail "update --global should stop on a deep *.next or *.polype-next, got $STATUS: $OUT"
  for f in method/notes.next bin/draft.polype-next; do
    grep -qF -- "not laid down by Polype, inside the payload: $H/polype/$f" <<< "$OUT" \
      || fail "$f is not reported as a foreign file: $OUT"
  done
}

# Only the word count is a script's to check (owner's rule of 2026-11-13, case 1): what the section
# and docs/installation.md say is judged by the reviewer, reading them.
test_docs_describe_the_kept_copy_stops() {
  local words
  words="$(awk '/^## / { on = ($0 == "## Installed files") } on' "$METHOD/AGENTS.md" | wc -w)"
  [ "$words" -gt 0 ] || fail "method/AGENTS.md has no ## Installed files section"
  [ "$words" -le 516 ] || fail "## Installed files of method/AGENTS.md grew: $words words, 516 before s161"
}
