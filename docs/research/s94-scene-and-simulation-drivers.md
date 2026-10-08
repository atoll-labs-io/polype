# Research — s94-scene-and-simulation-drivers

## Structuring facts
- No assumption of the story is false. The plan templates ask only for "where it looks from, what it must show, and its framing, scale and light" (`method/templates/plan.md:16`, `method/templates/plan-flow.md:34`), but `scene.md:26` reads "a scene, a position, a target and a framing" and sends a line that lacks one to `## Not seen` (`scene.md:30`). Root cause of the s87 major: the producer and the consumer of a viewpoint line were written in two stories, and nothing ties them together.
- Root cause of the s88 major: `simulation.md:30` triggers with a bare `ros2 topic pub`, which publishes at 1 Hz until killed (ros2cli jazzy `ros2topic/verb/pub.py:79-90`). The `echo`/`bag record`/`pub` processes started at `:28-30` are outside the one `setsid` group that `:21` stops. The end check at `:21` (`ros2 node list --no-daemon`) hides hidden nodes such as the CLI's own `_ros2cli_*`: `ros2node/verb/list.py:29-31,38` shows them only with `-a/--all`.
- Neither driver sets aside its own evidence: `scene.md:21` and `simulation.md:21` block on "a path the first output did not list", and both write under `docs/qa/<id>/` during the walk. `agents/qa.md:48` already excludes `docs/qa/<id>/`.
- Scene minors, both confirmed upstream: `xvfb-run` starts Xvfb at `-screen 0 1280x1024x24` unless `-s/--server-args` replaces it (Debian `xvfb-run:16,117`), which is smaller than the 1920×1080 capture of `scene.md:26`. A `--script` file is a `SceneTree`, whose viewport is `root`, a `Window` (Godot 4.7.2 `doc/classes/SceneTree.xml:300`). `SceneTree` has no `get_viewport()`, yet `scene.md:28` tells the script to call it.
- The rate minor is confirmed: `ros2 bag info` prints a `Count` per topic and one `Duration` for the bag (rosbag2 jazzy `rosbag2_py/src/rosbag2_py/format_bag_metadata.cpp:131,276`), so it prints no rate, although `simulation.md:41` says it does.

## Diagnostic
Reproduction: the defects are contradictions in method text, so they were reproduced by reading the lines side by side (cited above) and by checking each engine or CLI claim against its upstream source. The sources were fetched into a `mktemp -d` outside the worktree: ros2cli `jazzy`, rosbag2 `jazzy`, Godot `4.7.2-stable` docs, Debian `xvfb-run`, and `godot-xr-template@7d8261cd` `project.godot`. Godot, Xvfb and ROS 2 are absent from this machine (`command -v` printed nothing), so nothing was run.

| Hypothesis | Observation that would refute it | Result |
| --- | --- | --- |
| H1 Viewpoint fields: the template asks for scene and target somewhere else (`reviewer.md`, the review template) | `grep -rn viewpoint method/` finds a scene/target field | kept: the only other mentions are `reviewer.md:32` and `templates/review.md:56`, and neither names one |
| H2 Leftover processes: `--once` is not in the Jazzy CLI, so the review's fix cannot be applied | `pub.py` lacks `--once`/`--times` | kept (the fix applies): `-1/--once` at `:86` and `-t/--times` at `:89` exist. Both default `--wait-matching-subscriptions` to 1 and wait without end unless `--max-wait-time-secs` is given (`:91-100`) |
| H3 Leftover processes: `ros2 node list` already lists CLI nodes | `list.py` shows hidden nodes by default | kept (the bug is real): `include_hidden_nodes=args.all` (`list.py:38`). `--no-daemon` is accepted beside it (`ros2cli/node/strategy.py:82`) |
| H4 Screen size: `xvfb-run`'s default already fits 1920×1080 | `XVFBARGS` default ≥ 1920×1080 | kept (the bug is real): the default is `1280x1024x24` |
| H5 `--script` API: `SceneTree` inherits a `get_viewport()` | the method is in `SceneTree.xml` | kept (the bug is real): only the `root` member exists. `Viewport.get_texture` and the `await RenderingServer.frame_post_draw` advice are at `Viewport.xml:122,126-130` |

No hypothesis was discarded. Each review finding stands as its root cause.

## Story
Make the `scene` and `simulation` QA drivers read the viewpoint lines the plan really writes and leave no process behind. Acceptance criteria:
- `viewpoint_lines_match_the_plan`: both plan templates' `## Scene viewpoints` and `scene.md` ask for the same viewpoint fields (scene, position, target, framing). A line with no scene aims at the project's main scene.
- `scene_capture_is_sized_and_scripted`: the virtual screen gets the capture's size, the driver gives the right way to read the image from a `--script` script, and `docs/qa/<id>/` is set aside in the before/after comparison.
- `simulation_leaves_nothing_running`: triggers use `--once` or `--times`, every process started during the walk is stopped, the check uses `ros2 node list --all`, a rate is computed as count / duration, and `docs/qa/<id>/` is set aside.

## Current code
- `method/skills/qa-drivers/scene.md` (54 lines). Needs `:6`. Copy and porcelain `:17`. Start `:19`: `xvfb-run` "at the capture resolution", with no screen size. Stop and compare `:21`. Viewpoint fields `:26`. Capture script `:28`. Vague line `:30`. Evidence `:39`, where `viewpoints.txt` already records "the scene, the camera position, the target".
- `method/skills/qa-drivers/simulation.md` (57 lines). Domain choice uses `ros2 node list --no-daemon` (`:15`). Start in `setsid` (`:17`). Stop "the process group you started, and only that one", then the node check (`:21`). `--no-daemon` on every verb (`:23`). `bag record` and `topic echo` start with no process group (`:28`). Trigger and "stop the recording" (`:30`). Count and rate (`:41`).
- `method/templates/plan.md:15-16` and `plan-flow.md:33-34`: one identical placeholder sentence each.
- `boilerplates/godot/profile.md:33`: the engine command `xvfb-run -a godot --path <copy> … --resolution 1920x1080 --script <capture script>`, with no `-s`.
- `method/agents/reviewer.md:32` (out of `Owns`) judges against "what each must show, its framing, scale and light". It stays true as long as the templates keep those words.

## Attachment points
- The viewpoint field list: `plan.md:16`, `plan-flow.md:34`, `scene.md:26` and `:30`.
- The main scene for Godot: `[application]` `run/main_scene="res://game/main.tscn"` (template `project.godot:15,18`). The profile already names it under "project settings: main scene" (`profile.md:43`).
- Screen sizing: `scene.md:19` and `profile.md:33`. Script API: `scene.md:28`.
- Process lifetime: `simulation.md:21,28,30`. Node check: `:15,:21`. Rate: `:41`.
- Evidence set-aside: `scene.md:21` and `simulation.md:21`, to word like `qa.md:48`.
- New test file `tests/scene-and-simulation-drivers.test.sh` (in `Owns`), using the `lib.sh` helpers `contains`, `require_file` and `fail` (`tests/lib.sh:11,41,43`).

## Verified interfaces
- `tests/surface-routing.test.sh:63-79` requires that both templates have `## Tasks` < `## Scene viewpoints` < `## Run interdicts`, and that the section holds `` `scene` ``, `framing`, `scale` and `light`.
- `tests/godot-scene-driver.test.sh:73-89` pins phrases in `scene.md`, including `xvfb-run`, `--display-driver x11`, `--xr-mode off`, `never guesses a camera`, `one capture per viewpoint`, `viewpoints.txt` and `docs/qa/<id>/`. The grounding regex (`:31`) only matches tokens that start with `game/`, `components/` and similar, so it ignores the engine command.
- `tests/ros-simulation-driver.test.sh:75-92` pins `ros2 bag record`, `a readable extract`, `the raw recordings stay in the temporary directory`, `ros2 daemon stop`, `simulation.log`, `docs/qa/<id>/` and `ADR-0066`.
- `tests/scenario-driver.test.sh:34` pins `and only that one`, but only in `scenarios.md`, which is out of `Owns` (s93). `simulation.md` may drop that phrase.
- `tests/qa-drivers.test.sh` pins nothing in `scene.md` or `simulation.md`.
- `tests/run.sh` runs every `test_*` function of `tests/*.test.sh`.

## Traps
- `ros2 topic pub --once/--times` waits forever for a subscriber unless `--max-wait-time-secs` is given (`pub.py:91-100`). Replacing a process that never stops with one that never starts would only move the leak.
- `ros2 bag record` must be stopped with SIGINT so it closes its bag. A SIGKILL leaves no metadata, and the later `ros2 bag info` then has nothing to read. This was not run here; it is common rosbag2 behaviour.
- ADR-0066's outcome says "le groupe de processus lancé est arrêté" (singular), and ADR-0065 sends a line lacking "position, cible ou champ" to `## Not seen`. Stopping every group the walk started, and aiming a scene-less line at the main scene, refine both ADRs without contradicting them. No accepted ADR is edited and no new one is needed.
- Concurrent lanes: s93 owns `qa-drivers/SKILL.md`, `scenarios.md` and `agents/qa.md`. s96 owns the planner and the research/plan commands. None overlaps this story's `Owns`.
- `tests/overlap.test.sh` fails on 8+ words shared with Killer SaaS. New method text must be written fresh.
- The parity matrix has no scene or simulation line (s87 review `:31`), so `docs/parite-killer-saas.md` is not touched.

## Open questions
- The capture script awaits `frame_post_draw` from `SceneTree._initialize()`. Whether autoloads under `--script` disturb this was not run (s87 review "Not verified"). It stays an unverified note and does not change the plan.
- Whether a viewpoint should own its resolution beyond the 1920×1080 default is already settled by `scene.md:26`: the line may ask for another, and the screen then follows it. The plan keeps that rule.

## Complexity
Story: 3. After reading the code: 3. Two method files and two templates change, one profile line changes, and one new test file is added. No code, no new mechanism.

## Split
Not needed (score 3).
