# Research — s88-ros-simulation-driver

[Story](../stories.md)

Sources opened in clones under `/tmp/s88src`, outside the repository, on 2026-10-08:
`RG:` = `https://github.com/gazebosim/ros_gz_project_template` at `045e981d03aac1cc3712ab6bb086f52ea79aebf9` (HEAD of `main`, no tag in the repository, 19 commits). `RGZ:` = `gazebosim/ros_gz` branch `jazzy` at `0fa70cb7`. `VS:` = `gazebo-release/gz_sim_vendor` branch `jazzy` at `2c82e303`. `GZ:` = `gazebosim/gz-sim` branch `gz-sim8` at `5db0607b`. `GT:` = `gazebosim/gz-transport` branch `gz-transport13` at `869cb2ee`. `CLI:` = `ros2/ros2cli` `jazzy` at `9ac47fae`. `BAG:` = `ros2/rosbag2` `jazzy` at `29996807`. `RCL:` = `ros2/rcl` `jazzy` at `18d96c9c`. `LOG:` = `ros2/rcl_logging` `jazzy` at `727920c2`.

## Structuring facts
- **Wrong reading of the story first: the template's simulation cannot be launched "without a window".** Its launch opens Gazebo's GUI — it passes only the world path to `gz sim` (`RG:ros_gz_example_bringup/launch/diff_drive.launch.py:44-52`), and `gz sim` without `-s` runs server and GUI (`GZ:src/cmd/cmdsim.rb.in:123`) — and RViz by default (`diff_drive.launch.py:67-72,87-88`). `ros_gz_sim`'s launch offers no server-only switch (`RGZ:ros_gz_sim/launch/gz_sim.launch.py.in:155-178`). As in s87, "sans fenêtre" can only mean *no window on a display a person sees*: the launch runs on a virtual display. The driver must say so (ADR-0066).
- **The template's world starts paused**: no `-r` in the launch, and `-r` is what runs the simulation on start (`GZ:src/cmd/cmdsim.rb.in:121`). A behaviour triggered on it never happens; the world is resumed through `/world/demo/control` (`GZ:src/SimulationRunner.cc:249,325`, world `demo` at `RG:ros_gz_example_gazebo/worlds/diff_drive.sdf:11`).
- The starter is public and free: `RG:` is Apache-2.0 (`RG:LICENSE:1-2`), official Gazebo template, `main` for Gazebo Harmonic onward (`RG:README.md:17`). ROS 2 Jazzy ships Harmonic (`VS:package.xml:15`, `gz-sim8 8.15.0`).
- The row `behaviour` / `robot` → `simulation.md` is already written and tested (`method/skills/qa-drivers/SKILL.md:17`, `tests/qa-drivers.test.sh:30`); `robot` is a `Platform` value (`method/templates/agents-local.md:53`). `bin/po-lint` accepts `- QA driver: simulation` only once `simulation.md` exists (`bin/po-lint:283-293`): the driver lands before or with the profile.
- The temporary directory is removed when the QA ends (`SKILL.md:33-34`): the raw recordings the story puts there do not survive the QA; the readable extract in `docs/qa/<id>/` is the lasting evidence.

## Story
A ROS 2 + Gazebo profile and a driver that checks a behaviour in simulation, so a `behaviour` story reaches review with logs and topic recordings.
- `ros_profile_passes_the_lint` — `boilerplates/ros2-gazebo/profile.md` follows the template, written from a public, freely licensed starter at a named commit, platform `robot`, driver `simulation`; `bin/po-lint` accepts it.
- `simulation_driver_records_behaviour` — `qa-drivers/simulation.md` launches the simulation without a window, triggers the behaviour of each criterion, keeps the logs and a readable extract of the useful topics in `docs/qa/<id>/`, the raw recordings under the temporary directory, then stops everything; what only real hardware would show is reported as not seen.

Complexity 3, depends on s79 (shipped: the table row, `SKILL.md:17`). Owns `boilerplates/ros2-gazebo/`, `method/skills/qa-drivers/simulation.md`, `tests/ros-simulation-driver.test.sh`.

## Current code
- `method/skills/qa-drivers/SKILL.md` — table (`:9-17`), driver read from the skill's base directory, missing → `QA status: blocked` (`:23-24`), five things a driver says (`:26-31`), the `mktemp -d` directory for by-products, removed at the end (`:33-34`), real hardware → `## Not seen` (`:36-37`).
- `scene.md` (s87) is the closest model: the five headings `## Needs`, `## Start and stop`, `## Exercising a criterion`, `## Evidence`, `## Cannot show` (`scene.md:5,16,25,38,41`); a run on a copy with `status --porcelain --ignored` compared before and after (`:17,21`); a virtual display with the display forced (`:19`); a standing `## Not seen` line plus one per criterion (`:52`). `scenarios.md` gives the isolation pattern: a free port on `127.0.0.1`, `setsid`, nothing touched it did not start (`scenarios.md:14-18`), one transcript per criterion with input, output, exit code (`:30-32`).
- `method/agents/qa.md` — Write held to `docs/qa/<id>/` by `po-bounds` (`:9-14,22`, `method/hooks/po-bounds.sh:13-18`); Bash is free except git writes; scope is the criteria observable "in a behaviour" (`qa.md:37`).
- `method/templates/qa.md` — `## Not seen` reasons include "only real hardware" (`:28`).
- `method/templates/profile.md` — ten `## ` headings (`:5-74`), fence names (`:26-33`), `Test` accepts paths, `Dev` prints the address it serves (`:35`), no-screen one-liner (`:72`).
- `bin/po-lint` `check_profiles` (`:234-301`): headings, fence names, platform among `agents-local.md:53` values, driver file exists (`:283-293`).
- Precedent: `boilerplates/godot/profile.md` and `tests/godot-scene-driver.test.sh` (lint with two mutants `:35-65`, driver phrases `:67-96`, grounding with env override and loud skip `:98-119`); plan `docs/plans/s87-godot-scene-driver.md`.

## Attachment points
- New `method/skills/qa-drivers/simulation.md` — found by the existing table row; nothing else to wire.
- New `boilerplates/ros2-gazebo/profile.md` — found by `po-lint`'s glob (`bin/po-lint:248`) and by `/po-setup` for `Platform: robot`.
- New `tests/ros-simulation-driver.test.sh` — picked up by `tests/run.sh:6`.

## Verified interfaces
`RG:` (the template)
- Packages: `ros_gz_example_application/` (CMake only, `CMakeLists.txt:1-5`), `ros_gz_example_bringup/` (`launch/diff_drive.launch.py`, `launch/rrbot_setup.launch.py`, `config/ros_gz_example_bridge.yaml`, `config/diff_drive.rviz`, `config/rrbot.rviz`), `ros_gz_example_description/` (`models/diff_drive/`, `models/rrbot/`, `hooks/`), `ros_gz_example_gazebo/` (`src/BasicSystem.cc`, `src/FullSystem.cc`, `include/`, `worlds/diff_drive.sdf`, `hooks/`). Root: `README.md`, `LICENSE`, `.gitignore`.
- Bridge (`config/ros_gz_example_bridge.yaml:2,7,12,17,22,27,32`): `/diff_drive/cmd_vel` (ROS→GZ, `Twist`), `/clock`, `/diff_drive/odometry`, `/diff_drive/scan`, `/joint_states`, `/tf`, `/tf_static` (GZ→ROS).
- Launch: `robot_state_publisher` with `use_sim_time` (`diff_drive.launch.py:55-64`), bridge node (`:75-83`), argument `rviz` default `true` (`:87-88`). `rrbot_setup.launch.py` starts `joint_state_publisher_gui`, another window (`:43-49`).
- Build: `ros_gz_example_gazebo/CMakeLists.txt:41-51` finds `gz-sim8` only when `GZ_VERSION` is `harmonic`, else `gz-sim7` (Garden). Install path of systems and worlds `:98-110`; environment hooks `:124-125`.
- README: workspace layout `~/template_ws/src/` (`README.md:43-45`), `rosdep install --from-paths src --ignore-src -i -y` after `sudo rosdep init` (`:56-60`), `colcon build` (`:66`), `source install/setup.bash` (`:72`), `ros2 launch ros_gz_example_bringup diff_drive.launch.py` (`:78`).
- World: sensors system with `<render_engine>ogre2</render_engine>` (`worlds/diff_drive.sdf:16-20`); model sensor `gpu_lidar` (`models/diff_drive/model.sdf:164-166`); diff drive plugin under its legacy name `ignition-gazebo-diff-drive-system` (`model.sdf:228-230`).
- `.gitignore` (32 lines) ignores compiled objects only: no `build/`, `install/`, `log/`.
- Hooks disagree: `ros_gz_example_gazebo/hooks/*.dsv.in` sets `GZ_SIM_SYSTEM_PLUGIN_PATH`, `*.sh.in` sets `GZ_SIM_PLUGIN_PATH`.

ROS 2 Jazzy and Gazebo Harmonic
- `gz sim` options: `--headless-rendering` (`GZ:src/cmd/cmdsim.rb.in:119`), `-r` (`:121`), `-s` (`:123`); `-s` turns off waiting for the GUI (`:296-299`).
- `gz service -s <name> --reqtype --reptype --timeout -r/--req` (`GT:src/cmd/service_main.cc:113-147`). Gazebo transport reads `GZ_PARTITION` (`GT:src/NodeOptions.cc:35`) and `GZ_IP` (`GT:src/NetUtils.cc:128`).
- Discovery: `ROS_AUTOMATIC_DISCOVERY_RANGE` with value `LOCALHOST` (`RCL:rcl/src/rcl/discovery_options.c:35,70`); `ROS_LOCALHOST_ONLY` deprecated (`RCL:rcl/src/rcl/init.c:174-175`); `ROS_DOMAIN_ID` (`RCL:rcl/src/rcl/domain_id.c:25`).
- Logs: `ROS_LOG_DIR`, then `ROS_HOME` (`LOG:rcl_logging_interface/src/logging_dir.c:38,51`); default is under the user's home.
- `ros2 bag record -o/--output` (`BAG:ros2bag/ros2bag/verb/record.py:58`), `--topics` (`:71`), `--use-sim-time` (`:166-168`).
- `ros2 topic echo` `--csv` (`CLI:ros2topic/ros2topic/verb/echo.py:62`), `--no-arr` (`:88`), `--once` (`:103`), `--timeout` (`:105`); `ros2 topic pub --once` (`CLI:ros2topic/ros2topic/verb/pub.py:86`); verbs `ros2 service call`, `ros2 action send_goal` exist; `--no-daemon` (`CLI:ros2cli/ros2cli/node/strategy.py:82`).

## Traps
- **Windows on the person's display**: Gazebo's GUI and RViz are Qt; under this machine's Wayland session they may open on the person's screen unless forced onto the virtual display (`WAYLAND_DISPLAY` unset, Qt on `xcb`), as s87 found for Godot.
- **Paused world** (above): `/clock` does not advance until resumed.
- **Cross-talk**: ROS 2 discovery and Gazebo transport both reach other processes of the machine and of the network by default; a QA run could drive a developer's running stack or a real robot on the LAN. Isolation: a domain on which nothing answers, `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST`, a `GZ_PARTITION` of its own, `GZ_IP=127.0.0.1`.
- **Writes outside the copy**: ROS logs go under the home by default (`logging_dir.c:51`), Gazebo keeps its files under `~/.gz/` (`cmdsim.rb.in:70` names `~/.gz/sim/log`), `ros2` CLI starts a daemon that outlives the call. Point `HOME`, `ROS_HOME`, `ROS_LOG_DIR` into the temporary directory, pass `--no-daemon`, and `ros2 daemon stop` at the end.
- **Build**: `GZ_VERSION=harmonic` is required on Jazzy (`CMakeLists.txt:41-51`); `colcon` writes `build/`, `install/`, `log/` next to the sources, not ignored (`.gitignore`). `rosdep install` calls apt as root (`README.md:56-60`): not a per-QA command.
- **Software rendering**: `gpu_lidar` under `ogre2` needs OpenGL; on Mesa without GPU `/diff_drive/scan` may be slow or empty.
- **Tests**: `qa-drivers.test.sh`, `profile.test.sh`, `lint.test.sh`, `surface-routing.test.sh`, `overlap.test.sh` read the files around this story and stay green unchanged. No migration, no shared method file.

## Open questions
- Server-only `gz sim -s --headless-rendering` (EGL) or the whole launch on a virtual display? The template's launch cannot pass `-s` without being edited, and QA edits nothing. → plan / ADR-0066 (virtual display).
- How the driver triggers a behaviour no plan section names: from the criterion, the code and `ros2 topic list -t` of the running simulation, never an invented topic. → plan.
- `Install` and `Test` of the profile: `rosdep` needs root, and `colcon test` takes package names, not paths (`templates/profile.md:35`). → plan (both `—`, said in prose).
- Whether `colcon build` from the repository root, rather than from `<ws>/src/`, builds the four packages, and whether Gazebo's GUI and `gpu_lidar` run on Xvfb with Mesa: not runnable here (no `ros2`, `gz`, `colcon`, `xvfb-run` on this machine). The profile states them as conditions, not observations.

## Complexity
Story 3 → 3. Two new markdown files and one test file, no shared file changes; the work is the launch route (windows, paused world, isolation, writes outside the copy) and grounding the profile in `RG:`, settled in ADR-0066.

## Split
—
