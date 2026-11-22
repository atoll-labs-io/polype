#!/usr/bin/env bash
# s79 — qa picks its driver from the story's surface and the project's platform.

QA_AGENT="$METHOD/agents/qa.md"
DRIVERS="$METHOD/skills/qa-drivers/SKILL.md"

# The body of the first section whose heading starts with `## <prefix>`.
gate_section() { awk -v h="## $2" '/^## / {on = (index($0, h) == 1); next} on' "$1"; }

test_qa_runs_without_a_screen() {
  contains "$QA_AGENT" 'status --porcelain` again'
  contains "$QA_AGENT" 'mktemp -d'
  contains "$DRIVERS" 'mktemp -d'
}

test_profiles_declare_their_driver() {
  local profile="$METHOD/templates/profile.md" nf="$ROOT/boilerplates/next-forge/profile.md"
  grep -qxF '## QA driver' "$profile" || fail "profile template lacks ## QA driver"
  gate_section "$profile" 'QA driver' | grep -qx -- '- QA driver: browser' || fail "profile template lacks '- QA driver: browser'"

  local m p out status line
  DRIVER_TMP="$(mktemp -d)"; trap 'rm -rf "$DRIVER_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$DRIVER_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$profile" "$p"
  }

  fresh
  lint
  [ "$status" -eq 0 ] || fail "lint rejects a profile built from the template: $out"

  fresh
  sed -i '/^## QA driver$/d' "$p"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without ## QA driver"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## QA driver'" <<< "$out" \
    || fail "lint does not name the missing section: $out"

  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: browsr/' "$p"
  line=$(grep -n -m1 '^- QA driver: browsr$' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no browsr line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the driver browsr"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] QA driver 'browsr' is not a file of qa-drivers" <<< "$out" \
    || fail "lint does not flag browsr at line $line: $out"

  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: SKILL/' "$p"
  grep -qx -- '- QA driver: SKILL' "$p" || fail "mutation not applied: no SKILL line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the driver SKILL"
  grep -qF "QA driver 'SKILL' is not a file of qa-drivers" <<< "$out" || fail "lint does not flag SKILL: $out"

  fresh
  sed -i '/^Dev:/d' "$p"
  ! grep -q '^Dev:' "$p" || fail "mutation not applied: Dev still there"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without Dev"
  grep -qF "[profile] command 'Dev' is missing" <<< "$out" || fail "lint does not flag the missing Dev: $out"
}
