#!/usr/bin/env bash
# s94 — the scene and simulation QA drivers read the viewpoint lines the plan writes and leave no process behind.

PLAN="$METHOD/templates/plan.md"
PLAN_FLOW="$METHOD/templates/plan-flow.md"
SCENE="$METHOD/skills/qa-drivers/scene.md"
SIMULATION="$METHOD/skills/qa-drivers/simulation.md"
GODOT_PROFILE="$ROOT/boilerplates/godot/profile.md"

FIELDS="One line per viewpoint to capture, giving its scene, its position, its target, what it must show, and its framing, scale and light."
DRIVER_FIELDS="Each viewpoint line gives its scene, its position, its target, what it must show, and its framing, scale and light."
MAIN_SCENE="A line that names no scene aims at the project's main scene"
SET_ASIDE='a path outside `docs/qa/<id>/` that the first output did not list'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

lacks() { ! grep -qF -- "$2" "$1" || fail "${1#"$ROOT"/} still says: $2"; }

test_viewpoint_lines_match_the_plan() {
  local f section
  for f in "$PLAN" "$PLAN_FLOW"; do
    require_file "$f"
    section="$(section_of "$f" 'Scene viewpoints')"
    holds "$section" "$FIELDS" "${f#"$ROOT"/} ## Scene viewpoints"
    holds "$section" "$MAIN_SCENE." "${f#"$ROOT"/} ## Scene viewpoints"
  done
  require_file "$SCENE"
  section="$(section_of "$SCENE" 'Exercising a criterion')"
  holds "$section" "$DRIVER_FIELDS" "scene.md ## Exercising a criterion"
  holds "$section" "$MAIN_SCENE" "scene.md ## Exercising a criterion"
}

test_scene_capture_is_sized_and_scripted() {
  require_file "$SCENE"
  contains "$SCENE" '-screen 0 <width>x<height>x24'
  contains "$SCENE" 'root.get_texture().get_image().save_png()'
  contains "$SCENE" "$SET_ASIDE"
  lacks "$SCENE" 'get_viewport().get_texture()'
  require_file "$GODOT_PROFILE"
  contains "$GODOT_PROFILE" 'xvfb-run -a -s "-screen 0 1920x1080x24" godot'
}

test_simulation_leaves_nothing_running() {
  require_file "$SIMULATION"
  local phrase
  for phrase in 'ros2 topic pub --once' '--times' '--max-wait-time-secs' \
    'stop every process group the walk started' \
    "computed as that count divided by the bag's duration" "$SET_ASIDE"; do
    contains "$SIMULATION" "$phrase"
  done
  lacks "$SIMULATION" 'count and rate from'
  lacks "$SIMULATION" 'the process group you started, and only that one'
  local node_lines
  node_lines="$(grep -cF 'ros2 node list' "$SIMULATION")"
  [ "$node_lines" -ge 2 ] || fail "simulation.md has $node_lines ros2 node list lines, expected at least 2"
  ! grep -F 'ros2 node list' "$SIMULATION" | grep -qvF -- '--all' || fail 'a ros2 node list line of simulation.md lacks --all'
}
