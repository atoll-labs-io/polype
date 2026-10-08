#!/usr/bin/env bash
# s73 — the last texts lagging behind the method.

test_testing_doctrine_single_quotes_po_run() {
  local f="$METHOD/skills/testing-doctrine/SKILL.md"
  contains "$f" "-- '<command>'"
  ! grep -qF -- '-- "<command>"' "$f" || fail "the double-quoted form is still there"
}

test_replaced_adrs_point_to_their_successor() {
  local pair f line
  for pair in "0024:superseded-by: [ADR-0038, ADR-0039]" "0029:superseded-by: [ADR-0037]" "0037:superseded-by: [ADR-0041, ADR-0044]"; do
    f="$(ls "$ROOT"/docs/decisions/ADR-"${pair%%:*}"-*.md)"
    line="${pair#*:}"
    frontmatter "$f" | grep -qxF "$line" || fail "$f lacks: $line"
    frontmatter "$f" | grep -qx 'status: accepted' || fail "$f is no longer accepted"
  done
}

test_polype_declares_every_template_setting() {
  grep -qx 'QA stage:          —' "$ROOT/AGENTS.local.md" || fail "QA stage missing"
  grep -qx 'Dev:               —' "$ROOT/AGENTS.local.md" || fail "Dev missing"
  local out
  out="$(bash "$ROOT/bin/polype" check "$ROOT" 2>&1 || true)"
  grep -q 'installed in' <<< "$out" || fail "check did not run: $out"
  ! grep -q '^missing setting:' <<< "$out" || fail "$out"
}
