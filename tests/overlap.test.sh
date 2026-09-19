#!/usr/bin/env bash
# ADR-0006 — method/ must not reuse Killer SaaS text. Needs a local copy of its sources:
# KS_SRC=<killer-saas>/src, or the default below. Without it the check cannot run and says so.

KS_DEFAULT=/home/lecrabe/.claude/jobs/1b2863ed/tmp/ks/src

# Technical invocations whose wording is imposed by git or by the gate format (docs/references/killer-saas.md).
ALLOWED='diff --quiet|verification status space complete|`full suite` `e2e stage`|tree sed -n|validated space yes'

test_method_does_not_reuse_killer_saas_text() {
  local src="${KS_SRC:-$KS_DEFAULT}" hits unexpected
  if [ ! -d "$src" ]; then
    echo "      (Killer SaaS sources not found at $src: overlap not checked)" >&2
    return 0
  fi
  hits=$(python3 "$ROOT/bin/ks-overlap" "$src" 8 || true)
  unexpected=$(grep -vE "$ALLOWED" <<< "$hits" | grep -v '^$' || true)
  [ -z "$unexpected" ] || fail "text shared with Killer SaaS (8+ words): $unexpected"
}
