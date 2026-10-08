#!/usr/bin/env bash
# s89 — /po-retro, a retro read from the recorded files (ADR-0067).

RETRO="$METHOD/commands/po-retro.md"
HELP="$METHOD/commands/po-help.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_retro_reads_only_recorded_facts() {
  require_file "$RETRO"
  local p
  for p in \
    '`docs/stories.md`' '`docs/reviews/<id>.md`' '`docs/verif/<id>.md`' '`docs/qa/<id>/report.md`' \
    'a milestone or a range of stories' \
    'A milestone is a heading of `docs/stories.md` one level above the story headings' \
    '<first id>..<last id>' \
    '**severities per story**' '**fix loops**' '**blocked reviews and their cause**' \
    '**blocked QA walks and their cause**' '**majors still open**' \
    'open by the last review' \
    'It counts no lines of code and no commits' \
    'an absent file is never a zero'; do
    contains "$RETRO" "$p"
  done
  ! grep -qF 'git log' "$RETRO" || fail "po-retro.md must not read git log"
  ! grep -qF -- '--stat' "$RETRO" || fail "po-retro.md must not read a diff stat"
}

test_retro_writes_nothing() {
  local t
  for t in Write Edit NotebookEdit; do lacks_tool "$RETRO" "$t"; done
  contains "$RETRO" 'This command writes no file'
  contains "$RETRO" 'Bash is used read-only'
  local out
  out=$(section_of "$RETRO" Output)
  grep -qF 'Sources' <<< "$out" || fail "Output section lacks Sources"
  grep -qF 'Every figure names the file and line it comes from' <<< "$out" || fail "Output section lacks the source rule"
}

test_help_lists_the_retro() {
  section_of "$HELP" Outils | grep -qF '`/po-retro' || fail "po-help.md Outils lacks /po-retro"
}
