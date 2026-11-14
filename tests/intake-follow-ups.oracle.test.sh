#!/usr/bin/env bash
# s177 — the oracle of the story: `po-gate redact` erases exactly what the pre-commit secret scan flags, each match
# judged on the original line, and /po-intake does not grow. Witness strings are assembled at run time and mean
# nothing; no literal one sits in this file.

GATE="$METHOD/hooks/po-gate.sh"
INTAKE_CMD="$METHOD/commands/po-intake.md"

# The rules the pre-commit scan reports for one staged line, one per output line, sorted.
scan_rules() {
  printf '%s\n' "$1" > "$SCRATCH/w.txt"
  git -C "$SCRATCH" add w.txt
  (cd "$SCRATCH" && bash "$GATE" pre-commit 2>&1 >/dev/null) \
    | sed -n 's/^po-gate: w\.txt:1: \([a-z-]*\) (value not shown)$/\1/p' | sort
  git -C "$SCRATCH" rm -q --cached w.txt
}

test_redact_follows_the_scan_rule() {
  scratch_repo
  git -C "$SCRATCH" commit -q --allow-empty -m base
  local up lo aws gh ant one two out
  up=QWERTYUIOPASDFGH; lo="$(printf 'w%.0s' {1..36})"
  aws="AK""IA$up"
  gh="gh""p_$lo"
  ant="sk-a""nt-witnesswitness-${aws}abcdefghijklmnopqrstuvwxyz"
  one="one ${aws}${gh} end"
  two="two ${ant} end"

  # The scan's verdicts, which this story must leave as they are.
  [ "$(scan_rules "$one")" = "aws-access-key" ] || fail "scan verdict changed on a string right after a match: $(scan_rules "$one")"
  [ "$(scan_rules "$two")" = "anthropic-key
aws-access-key" ] || fail "scan verdict changed on a match inside a longer one: $(scan_rules "$two")"

  printf '%s\n%s\n' "$one" "$two" > "$SCRATCH/in"
  cp "$SCRATCH/in" "$SCRATCH/orig"
  out="$(bash "$GATE" redact "$SCRATCH/in")" || fail "po-gate redact failed"
  [ "$(sed -n 1p <<< "$out")" = "one [redacted]${gh} end" ] \
    || fail "redact erased a string the scan does not flag, right after an erased one: $(sed -n 1p <<< "$out")"
  [ "$(sed -n 2p <<< "$out")" = "two [redacted] end" ] \
    || fail "redact left part of a value the scan flags whole: $(sed -n 2p <<< "$out")"
  cmp -s "$SCRATCH/in" "$SCRATCH/orig" || fail "redact changed the file"
}

test_intake_holds_in_its_words() {
  require_file "$INTAKE_CMD"
  local n; n="$(LC_ALL=C wc -w < "$INTAKE_CMD" | tr -d ' ')"
  [ "$n" -le 1550 ] || fail "po-intake.md holds $n words, more than the 1550 it held before the story"
}
