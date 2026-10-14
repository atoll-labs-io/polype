#!/usr/bin/env bash
# s100 — QA evidence never blocks its own walk, and the bounded waits have biting tests.

QA_AGENT="$METHOD/agents/qa.md"
SCENARIOS="$METHOD/skills/qa-drivers/scenarios.md"
SCENE="$METHOD/skills/qa-drivers/scene.md"
SIMULATION="$METHOD/skills/qa-drivers/simulation.md"
SET_ASIDE_PARENT='A line naming a parent of `docs/qa/<id>/`, such as `?? docs/qa/` at a project'\''s first QA, is set aside too when `git -C <path> ls-files --others --exclude-standard -- <that parent>` lists nothing outside `docs/qa/<id>/`.'

lacks() { ! grep -qF -- "$2" "$1" || fail "${1#"$ROOT"/} still says: $2"; }

test_first_qa_sets_its_evidence_aside() {
  local f
  for f in "$QA_AGENT" "$SCENARIOS" "$SCENE" "$SIMULATION"; do
    require_file "$f"
    contains "$f" "$SET_ASIDE_PARENT"
  done
}

test_bounded_waits_bite() {
  contains "$SCENARIOS" 'within 60 seconds → stop it and end with `QA status: blocked`'
  contains "$QA_AGENT" 'set to `—` → write the report with `QA status: blocked`, naming the surface and the platform as its cause.'
}

test_scene_and_recorder_stop_cleanly() {
  contains "$SCENE" 'stop every process group the walk started'
  contains "$SCENE" 'then `quit()`'
  lacks "$SCENE" 'the process group you started, and only that one'
  contains "$SIMULATION" 'a recorder still running after 30 seconds is a finding'
  contains "$SIMULATION" 'wait at most 30 seconds of real time'
  lacks "$SIMULATION" 'wait until it exits, so the bag'
}
