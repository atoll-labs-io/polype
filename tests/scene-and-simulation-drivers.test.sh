#!/usr/bin/env bash
# s94 — the scene and simulation QA drivers read the viewpoint lines the plan writes and leave no process behind.

SCENE="$METHOD/skills/qa-drivers/scene.md"
SIMULATION="$METHOD/skills/qa-drivers/simulation.md"

SET_ASIDE='a path outside `docs/qa/<id>/` that the first output did not list'

test_scene_capture_is_sized_and_scripted() {
  require_file "$SCENE"
  contains "$SCENE" "$SET_ASIDE"
}

test_simulation_leaves_nothing_running() {
  require_file "$SIMULATION"
  contains "$SIMULATION" "$SET_ASIDE"
}
