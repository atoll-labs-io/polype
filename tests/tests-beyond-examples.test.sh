#!/usr/bin/env bash
# s148 — the testing doctrine goes beyond examples.

DOC="$METHOD/skills/testing-doctrine/SKILL.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_doctrine_says_when_property_tests() {
  local s p
  s=$(section_of "$DOC" 'Beyond examples')
  for p in '**Property test**' 'a rule that holds for every input of a domain' 'round trip' 'idempotence' \
    'pure logic, parsers and serialisers' 'It counts as one test in `Test budget`'; do
    holds "$s" "$p" 'Beyond examples'
  done
  ! grep -qE 'proptest|Hypothesis|fast-check|QuickCheck|libFuzzer|cargo-fuzz|AFL' "$DOC" || fail "doctrine names a library"
}

test_doctrine_says_when_fuzzing() {
  local s p
  s=$(section_of "$DOC" 'Beyond examples')
  for p in '**Fuzzing**' 'code that decodes input coming from outside' 'A story runs only a short campaign with a fixed seed'; do
    holds "$s" "$p" 'Beyond examples'
  done
}

test_doctrine_says_when_simulation() {
  local s p
  s=$(section_of "$DOC" 'Beyond examples')
  for p in '**Deterministic simulation with fault injection**' 'distributed, time-dependent or robotic behaviour' \
    'packets lost' 'a node restarted' 'a clock skewed' 'a sensor gone silent' \
    'A seed makes each failure replayable' 'a failure that does not replay is not a result'; do
    holds "$s" "$p" 'Beyond examples'
  done
}

test_real_service_over_handwritten_mock() {
  local s p
  s=$(section_of "$DOC" 'Real services over hand-written mocks')
  for p in 'A persistence or adapter test talks to the real service' 'when the project can start it' \
    "needs a sentence in the plan's test strategy" 'under shape 6 of `## Tests that prove nothing`'; do
    holds "$s" "$p" 'Real services section'
  done
}

test_long_campaigns_run_outside_stories() {
  local row p
  row=$(section_of "$DOC" 'When does each check run?' | grep -F '| Long fuzzing or simulation campaign |') \
    || fail "no long campaign row"
  for p in 'on a schedule' '`Issue tracker`' 'Law 7' 'the story runs only the short version'; do
    holds "$row" "$p" 'long campaign row'
  done
}
