#!/usr/bin/env bash
# s182 — the live rule: this repository's own diff against origin/<Target branch> passes the version check.

test_this_repository_versions_po() {
  local out
  out="$("$ROOT/bin/po-version-check" 2>&1)" || fail "bin/po-version-check refused this repository: $out"
}
