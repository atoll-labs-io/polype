# Review — s94-scene-and-simulation-drivers

Reviewed tree: 8f46f2dfb574c12064e2d1ed4011c47ec92c4d7f
Fix loop: 0
Branch: `story/s94-scene-and-simulation-drivers` (1 commit, cfbbe20), worktree `/home/lecrabe/dev/atoll/polype/.worktrees/s94-scene-and-simulation-drivers`
Scope: `git diff main...story/s94-scene-and-simulation-drivers`
Lenses run: none. No path or content in the diff triggers the security, migration, dependency or performance lens. The diff contains only method text, one profile line and one bash test file.

## Scope (`Owns`)
These diff paths are inside the story's `Owns`:
- `boilerplates/godot/profile.md`
- `method/skills/qa-drivers/scene.md`
- `method/skills/qa-drivers/simulation.md`
- `method/templates/plan.md`
- `method/templates/plan-flow.md`
- `tests/scene-and-simulation-drivers.test.sh`

`docs/research|plans|verif/s94-…md` are the story's own evidence. No path is outside `Owns`. The only other running lane is s93-qa-contract-holds. Its `Owns` and its diff (`method/agents/qa.md`, `qa-drivers/SKILL.md`, `scenarios.md`, its tests) do not overlap this one.

## What I relied on
- **Unit suite:** `po-gate verif-current s94-scene-and-simulation-drivers` exited 0 (`Verification mode: record`). The record is complete, and the `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to this tree. I did not rerun the full suite.
- **No type check, E2E or build:** `Typecheck`, `E2E` and `Build` are `—`. The project has no such commands.
- **Not proven here:** I read the record's "Not proven here" section. No real Godot capture or ROS 2 walk was run.
- **Focused run:** I ran the story's tests plus the guarding neighbours `surface-routing`, `godot-scene-driver`, `ros-simulation-driver`, `qa-drivers` and `overlap`. All 21 passed.
- **No QA stage:** `Surface: —`, so `qa-current` does not apply.

## Steps
1. **Reuse:** covered under "What I relied on".
2. **References:**
   - I fetched ros2cli `jazzy` sources into `/tmp/tmp.YikvEyylkD` to check the ROS 2 claims:
     - `pub.py:86,89,97` defines `--once`, `--times` and `--max-wait-time-secs`.
     - `pub.py:188-201` confirms that the wait is bounded only when `--max-wait-time-secs` is given.
     - `list.py:30,38` confirms that `--all` shows hidden nodes.
   - The Godot `SceneTree.root` claim and the xvfb-run default screen are taken from the research's upstream citations. I did not re-fetch them.
3. **Plan:** tasks 1–6 are all present and nothing was added beyond them. The run interdicts hold:
   - `reviewer.md`, `qa.md`, `SKILL.md`, `scenarios.md`, `browser.md`, `mobile-web.md` and the existing tests have an empty diff.
   - Only line 33 of the profile changes.
   - Only the `## Scene viewpoints` section of each template changes.
   - No ADR is edited or added.
   - The pivot holds: `reviewer.md:32` ("what each must show, its framing, scale and light") is still true against the new template sentence. `scene.md:30` keeps the position/target/framing refusals and the refusal when there is no main scene. `simulation.md` bounds `pub` with `--max-wait-time-secs` and stops the recorder with SIGINT.
   - Every finding of `docs/reviews/s87-godot-scene-driver.md` and `docs/reviews/s88-ros-simulation-driver.md` is addressed.
   - The main-scene default refines ADR-0065 without contradicting it.
4. **Tests:**
   - `po-gate floor-guard s94-scene-and-simulation-drivers main` exited 0: nothing was lowered.
   - There are 3 tests, within the budget of 25. They are text contracts, and their assertions quote the exact clauses.
   - Bite proofs, each undone and confirmed with `git diff --exit-code`:

     | Mutation | Tests failed |
     | --- | --- |
     | Removed "its target," from `plan-flow.md`'s viewpoint sentence | 1 (`viewpoint_lines_match_the_plan`) |
     | Removed `--all` from `simulation.md:15` | 1 (`simulation_leaves_nothing_running`) |
     | Reverted the `docs/qa/<id>/` set-aside in `simulation.md:21` | 1 (`simulation_leaves_nothing_running`) |

   - The final `git diff --exit-code` and `git status --porcelain` were both empty.
5. **Values:**
   - `-screen 0 1920x1080x24` matches the profile's `--resolution 1920x1080`.
   - `ros2 node list --no-daemon --all` uses flags that are valid together (research cites `strategy.py:82`; `--all` I confirmed above).
   - The rate as count / bag duration matches what `ros2 bag info` prints (research cites `format_bag_metadata.cpp`).
6. **Neighbours:**
   - Nothing in `method/`, `boilerplates/`, `tests/` or the top-level docs I searched still uses "where it looks from", `get_viewport()`, "count and rate" or the bare `xvfb-run -a godot`. (`docs/` was searched only at its top-level files; see `## Not verified`.)
   - `qa.md:48` already sets `docs/qa/<id>/` aside the same way.

## Findings
- **minor** — `method/skills/qa-drivers/scene.md:19,21`: line 19 now says "one engine run per capture script", so a walk with several viewpoints starts several `setsid` groups. Line 21 still says "stop the process group you started, and only that one" (singular). The capture script is also never told to quit the engine after `save_png()`. A literal reader could leave earlier engine runs alive. `simulation.md` got the plural ("stop every process group the walk started"); `scene.md` did not. The plan did not ask for this change, so it is a gap in the plan rather than an implementer error.
- **minor** — `method/skills/qa-drivers/simulation.md:30`: "send SIGINT to the recorder's process group and wait until it exits" gives no bound on that wait. Every other wait in the file is bounded. A recorder that hangs on close would stall the walk instead of ending it with a finding or `blocked`.
- **minor** — `boilerplates/godot/profile.md:33` vs `scene.md:19,26`: the profile's engine command hard-codes `1920x1080` twice (`-screen` and `--resolution`). The driver says the screen follows the viewpoint's resolution when a line asks for another. The driver "reads" the profile line, so the profile should either use a placeholder or say the values are the default.
- **minor** — `scene.md:26`: "the `run/main_scene` setting of `project.godot`". The setting's full path is `application/run/main_scene`; the file shows `run/main_scene` under `[application]`. A reader can still find it, but the wording is loose.

## Not verified
- **No real scene capture was run.** Godot and Xvfb are absent, as the record notes. Unconfirmed in practice:
  - `xvfb-run -a -s "-screen 0 WxHx24"` together with `--resolution`;
  - `root.get_texture().get_image().save_png(<path>)` from a `SceneTree` `--script` after `await RenderingServer.frame_post_draw`;
  - whether autoloads disturb that (an open question carried over from s87).

  To cover it, a person runs one capture with the profile command on a machine with Godot 4.7.2 and Xvfb.
- **No real ROS 2 walk was run.** Unconfirmed in practice: that SIGINT to a `setsid` group running `ros2 bag record` closes the bag with readable metadata, that `timeout` on `ros2 service call` / `ros2 action send_goal` exits cleanly, and that `ros2 node list --no-daemon --all` after `ros2 daemon stop` shows nothing on a clean domain. To cover it, a person runs one walk on the jazzy profile.
- **Godot `SceneTree` API and xvfb-run default:** taken from the research's upstream citations, not re-fetched here.
- **Installed copies:** `.claude/` and `.polype/` are not refreshed by this story (by design). The installed copies stay stale until the next refresh.
- **Docs coverage:** I did not grep the French documentation under `docs/` beyond top-level files for the old wordings.

Max severity: minor
Ship allowed: yes
