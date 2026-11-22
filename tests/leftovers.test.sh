#!/usr/bin/env bash
# s73 — the last texts lagging behind the method.

test_polype_declares_every_template_setting() {
  grep -qx 'QA stage:          —' "$ROOT/AGENTS.local.md" || fail "QA stage missing"
  grep -qx 'Dev:               —' "$ROOT/AGENTS.local.md" || fail "Dev missing"
  local out
  out="$(bash "$ROOT/bin/polype" check "$ROOT" 2>&1 || true)"
  grep -q 'installed in' <<< "$out" || fail "check did not run: $out"
  ! grep -q '^missing setting:' <<< "$out" || fail "$out"
}
