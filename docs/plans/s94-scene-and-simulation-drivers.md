---
validated: yes
---
# Plan — s94-scene-and-simulation-drivers

Branch `story/s94-scene-and-simulation-drivers`. Read `docs/research/s94-scene-and-simulation-drivers.md` first. This plan builds on it without repeating it, and each root cause cited here is shown there under `## Diagnostic`.

Validated autonomously against the three acceptance criteria (`Plan validation: autonomous`): no human reviewed this plan.

## Story
The `scene` and `simulation` QA drivers read the viewpoint lines the plan really writes and leave no process behind, so that their QA produces usable evidence. This fixes the major and the minors of `docs/reviews/s87-godot-scene-driver.md` and `docs/reviews/s88-ros-simulation-driver.md`.
- `viewpoint_lines_match_the_plan`: both plan templates and `scene.md` ask for the same viewpoint fields (scene, position, target, framing). A line with no scene aims at the project's main scene.
- `scene_capture_is_sized_and_scripted`: the virtual screen gets the capture's size, the right way to read the image from a `--script` script is given, and `docs/qa/<id>/` is set aside in the before/after comparison.
- `simulation_leaves_nothing_running`: `--once`/`--times`, every process started during the walk stopped, `ros2 node list --all`, rate = count / duration, `docs/qa/<id>/` set aside.

## Tasks
Several clauses below must appear **verbatim**, because the test of task 5 quotes them. They are marked «…». Write the rest of the prose in your own words: `overlap.test.sh` forbids 8+ words shared with Killer SaaS.

1. [x] **Plan templates** (`method/templates/plan.md:16`, `method/templates/plan-flow.md:34`). Replace the middle sentence of the identical placeholder, "One line per viewpoint to capture: where it looks from, what it must show, and its framing, scale and light.", with «One line per viewpoint to capture, giving its scene, its position, its target, what it must show, and its framing, scale and light.» followed by «A line that names no scene aims at the project's main scene.» Keep the opening clause (`Surface` is `scene`; write `—` for any other) and the closing sentence ("The QA captures these viewpoints…") unchanged. Keep the heading where it is.
   - Fails if wrong: `viewpoint_lines_match_the_plan`. `surface-routing.test.sh` `plan_names_scene_viewpoints` must stay green.
2. [x] **Scene driver, viewpoint lines** (`method/skills/qa-drivers/scene.md:26,30`).
   - `:26` becomes «Each viewpoint line gives its scene, its position, its target, what it must show, and its framing, scale and light.» followed by «A line that names no scene aims at the project's main scene», with how to find that scene: for Godot, `run/main_scene` in `project.godot` (template `project.godot:18`). Keep the framing → field of view rule and the 1920×1080 default.
   - `:30`: a line goes to `## Not seen`, saying what it lacks, when it lacks a position, a target or a framing, when it names a scene that does not exist, or when it names no scene in a project that has no main scene. Keep the phrase `never guesses a camera`.
   - Fails if wrong: `viewpoint_lines_match_the_plan`.
3. [x] **Scene driver, capture and stop** (`scene.md:19,21,28`), plus **the Godot profile** (`boilerplates/godot/profile.md:33`).
   - `:19`: start the engine under «xvfb-run -a -s "-screen 0 <width>x<height>x24"», the screen sized to the capture resolution of the viewpoint being captured (one engine run per capture script). Keep `--display-driver x11`, `--xr-mode off`, `setsid` and `WAYLAND_DISPLAY`.
   - `:28`: a `--script` file extends `SceneTree`, which has no `get_viewport()`. For Godot, await `RenderingServer.frame_post_draw`, then call «root.get_texture().get_image().save_png()». The string `get_viewport().get_texture()` must no longer appear.
   - `:21`: «a path outside `docs/qa/<id>/` that the first output did not list» → `QA status: blocked`, naming that path, and nothing is removed.
   - Profile `:33`: the engine command starts «xvfb-run -a -s "-screen 0 1920x1080x24" godot --path <copy>». Keep the rest of the line and its two sentences unchanged.
   - Fails if wrong: `scene_capture_is_sized_and_scripted`. `godot-scene-driver.test.sh`'s three tests must stay green, including grounding when the network is up.
4. [x] **Simulation driver** (`method/skills/qa-drivers/simulation.md:15,21,28,30,41`).
   - `:15` and `:21`: every `ros2 node list` becomes «ros2 node list --no-daemon --all». Say at `:21` that this check includes hidden nodes, such as the CLI's own.
   - `:28`: each `ros2 bag record` and each `ros2 topic echo` starts in a process group of its own (`setsid`), with its PID kept in the temporary directory.
   - `:30`: trigger with «ros2 topic pub --once», or `--times <n>` when the criterion needs several messages, always with «--max-wait-time-secs». Run `ros2 service call` and `ros2 action send_goal` under a time bound (`timeout`). A trigger that hits its bound is a finding, with its output. "Stop the recording" becomes: SIGINT to the recorder's group, then wait for it to exit so the bag closes; the echoes stop the same way.
   - `:21`: «stop every process group the walk started», meaning the simulation's and each one a criterion started, and only those. Then run `ros2 daemon stop`, then the node check. The old wording "the process group you started, and only that one" must disappear from this file only.
   - `:21`: the set-aside clause of task 3, «a path outside `docs/qa/<id>/` that the first output did not list», word for word.
   - `:41`: the message count comes from `ros2 bag info`, and the rate is «computed as that count divided by the bag's duration». The words `count and rate from` must disappear.
   - Keep every phrase that `ros-simulation-driver.test.sh:75-92` pins.
   - Fails if wrong: `simulation_leaves_nothing_running`.
5. [x] **Tests**: `tests/scene-and-simulation-drivers.test.sh`, header comment `# s94 — …`, three functions named after the criteria. Use `lib.sh` helpers. A local `section_of` and a local `lacks` (same shape as `surface-routing.test.sh:15,19`) are allowed.
   - `test_viewpoint_lines_match_the_plan`: for `plan.md` and `plan-flow.md`, the `## Scene viewpoints` section holds both clauses of task 1. The `## Exercising a criterion` section of `scene.md` holds both clauses of task 2 (same two strings).
   - `test_scene_capture_is_sized_and_scripted`:
     - `scene.md` contains `-screen 0 <width>x<height>x24`, `root.get_texture().get_image().save_png()` and the set-aside clause.
     - `scene.md` lacks `get_viewport().get_texture()`.
     - The profile contains `xvfb-run -a -s "-screen 0 1920x1080x24" godot`.
   - `test_simulation_leaves_nothing_running`:
     - `simulation.md` contains `ros2 topic pub --once`, `--times`, `--max-wait-time-secs`, `stop every process group the walk started`, `computed as that count divided by the bag's duration` and the set-aside clause.
     - It lacks `count and rate from` and `the process group you started, and only that one`.
     - Every line holding `ros2 node list` also holds `--all`, and there are at least 2 such lines.
6. [x] **Run.** Focused run first:

   ```
   bash tests/run.sh scene-and-simulation-drivers.test.sh surface-routing.test.sh godot-scene-driver.test.sh ros-simulation-driver.test.sh qa-drivers.test.sh
   ```

   Then, once, the full suite through `po-run --story s94-scene-and-simulation-drivers --label 'Unit suite' -- 'bash tests/run.sh'`. `Typecheck: —`: no type check.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/agents/reviewer.md`, `method/agents/qa.md`, `method/templates/review.md`, `method/skills/qa-drivers/SKILL.md`, `scenarios.md`, `browser.md` and `mobile-web.md`. These are out of `Owns`, and s93 owns several of them.
- Empty diff on the existing tests `tests/surface-routing.test.sh`, `tests/godot-scene-driver.test.sh`, `tests/ros-simulation-driver.test.sh` and `tests/qa-drivers.test.sh`. They are in `Owns` or nearby, but every change here is additive to what they pin.
- In `boilerplates/godot/profile.md`, only line 33 changes. No other file under `boilerplates/` is touched.
- No edit to any accepted ADR: ADR-0065 and ADR-0066 keep their bodies. No new ADR (the reserved ADR-0070 stays unused).
- Nothing under `.claude/` or `.polype/`. No change to `docs/stories.md`, `docs/parite-killer-saas.md` or `README.md`.
- No clone or download inside the worktree. Upstream checks, if any, run under `mktemp -d`.
- Only the two templates' `## Scene viewpoints` sections change. Their other sections stay byte-identical.

## The pivot
**One verbatim field list shared by the three files.** The fix for the s87 major is to make the producer (two templates) and the consumer (`scene.md`) carry the same clause, so the test can tie them together. It could be wrong in three ways:
- **`reviewer.md:32` drifts out of truth.** It judges "what each must show, its framing, scale and light". The new clause keeps all four, so it stays right. Compare `reviewer.md:32` against the new template sentence.
- **The main-scene default hides a vague line.** A scene-less line now gets a camera in the main scene instead of `## Not seen`. That is only right because position, target and framing are still required (`scene.md:30`), and because a project without a main scene still sends the line to `## Not seen`. Check that `:30` kept those three refusals.
- **The leak only moves.** Making `pub` stop with `--once` is worthless if it then waits forever for a subscriber (`pub.py:91-100`). Making `bag record` stop is worthless if a SIGKILL leaves no metadata for `bag info`. Check that `simulation.md` bounds the wait and stops the recorder with SIGINT.

## Files touched
- `method/templates/plan.md`, `method/templates/plan-flow.md`
- `method/skills/qa-drivers/scene.md`, `method/skills/qa-drivers/simulation.md`
- `boilerplates/godot/profile.md` (line 33)
- `tests/scene-and-simulation-drivers.test.sh` (new)
- `docs/research/s94-scene-and-simulation-drivers.md`, `docs/plans/s94-scene-and-simulation-drivers.md`, `docs/verif/s94-scene-and-simulation-drivers.md`

## Test strategy
Three tests, one per criterion, within the `Test budget` of 25. These are text contracts of method files, the only layer this repository has for them. Each assertion quotes the exact clause of its rule, so deleting the rule turns its test red:
- dropping "its target" from one template fails `viewpoint_lines_match_the_plan`;
- putting back the bare `xvfb-run -a godot` fails `scene_capture_is_sized_and_scripted`;
- removing `--all` from either node check fails `simulation_leaves_nothing_running`.

The `lacks` checks catch an old wording left beside the new one. The existing tests of `surface-routing`, `godot-scene-driver`, `ros-simulation-driver` and `qa-drivers` guard the phrases this story must keep.

Visual or real checks: none can run here. Godot, Xvfb and ROS 2 are absent, so a real capture and a real simulation walk stay under "Not proven here" in the record.

## Done when
- One commit on `story/s94-scene-and-simulation-drivers` carrying the code, the test, the research, the plan and the record.
- The full suite green through `po-run`, `overlap.test.sh` included.
- A review with no open critical finding, then a squash on `main`.
