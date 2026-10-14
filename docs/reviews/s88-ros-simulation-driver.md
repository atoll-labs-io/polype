# Review — s88-ros-simulation-driver

[Story](../stories.md) · [Plan](../plans/s88-ros-simulation-driver.md) · [Verification](../verif/s88-ros-simulation-driver.md)

I reviewed the diff `git diff main...story/s88-ros-simulation-driver` (commit ff74e66). I did not write this code. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 193c20938d0ffe4ef10aa640a14deb9ad2434330

## Ownership
I listed the changed files with `git diff --name-status main...story/s88-ros-simulation-driver` and checked each one against the story's `Owns` line: `boilerplates/ros2-gazebo/`, `method/skills/qa-drivers/simulation.md`, `tests/ros-simulation-driver.test.sh`.
- [x] Every path is inside `Owns`:
  - `boilerplates/ros2-gazebo/profile.md`, `method/skills/qa-drivers/simulation.md` and `tests/ros-simulation-driver.test.sh` are covered by `Owns`.
  - The story's own research, plan and verif files count as in scope by construction.
  - `docs/decisions/ADR-0066-le-pilote-simulation-lance-la-simulation-isolee-sur-un-affichage-virtuel.md` is newly added (status `A`) and the plan names it, so it is in scope.
- [x] No path lies outside `Owns`.
- [x] No path lies inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s88-ros-simulation-driver` exited 0, so I reused the record (`Verification mode: record`). The unit suite (`bash tests/run.sh`) ran on tree 95b095cc…, exit 0. That tree's code outside `docs/` equals the recorded `Tree:` aaaed2ee…. The project has no type check (`Typecheck: —`), E2E or Build command, so none was run. I read the record's "Not proven here" section, and its items are carried to Not verified.
- [x] `po-gate qa-current` is not required: `Surface: —`, so the story does not go to QA.

## Plan
- [x] All four tasks are present:
  - The driver has the five headings of `scene.md` in order and every verbatim phrase the plan requires.
  - The profile has the ten template headings, the identity values, the fence values, the `Simulation command:` and `Resume command:` lines, and the code map, ownership and traps sections.
  - The test file has 3 tests.
  - The recorded run is present.
- [x] Each run interdict checked:
  - There is no change to `qa-drivers/SKILL.md`, `browser.md`, `mobile-web.md`, `scenarios.md` or `scene.md`, `agents/`, `commands/`, `templates/`, `design-doctrine/`, `hooks/` or `bin/`.
  - No existing test was edited, and nothing under `.claude/` or `.polype/` changed.
  - No other `boilerplates/` folder was touched.
  - `docs/stories.md`, `catalogue.md`, `parite-killer-saas.md` and `README.md` are unchanged.
  - There is no clone in the worktree, ADR-0066 is the only ADR added, and the record shows `overlap.test.sh` green.

## References
- [x] Every reference was opened and confirmed:
  - **In the repository:** ADR-0054, ADR-0059 and ADR-0066 exist. The `behaviour | robot | simulation.md` row is already in `method/skills/qa-drivers/SKILL.md`. The headings of `method/templates/profile.md` match the profile. `bin/po-lint` accepts the profile.
  - **In the template** (I fetched `ros_gz_project_template` at `045e981d…` into a temp-dir repository):
    - All paths the profile names exist, and LICENSE is Apache 2.0.
    - The world is named `demo`, so `/world/demo/control` in the resume command is correct.
    - `gz_args` passes no `-r`, so the world does start paused.
    - `rviz` is a declared launch argument, defaulting to `true`.
    - `GZ_VERSION` = harmonic selects `gz-sim8`; otherwise the build defaults to gz-sim7 (Garden).
    - The two hooks set `GZ_SIM_SYSTEM_PLUGIN_PATH` and `GZ_SIM_PLUGIN_PATH`.
    - `.gitignore` lists compiled objects only.
    - `gpu_lidar` and `ogre2` are present, and `rrbot_setup.launch.py` opens `joint_state_publisher_gui`.
- [ ] Not every value is confirmed. `ros2 bag info` is said to give a per-topic "rate", but it prints a count and an overall duration (minor finding below).

## Rules
- [x] `AGENTS.md` conventions are respected: method text in English, the test is bash using the `lib.sh` helpers, and test names are the acceptance-criterion names.
- [x] No accepted ADR is contradicted. The driver follows ADR-0054, ADR-0059 and ADR-0066.

## Tests
- [x] Floor: `po-gate floor-guard s88-ros-simulation-driver main` exited 0, so nothing was lowered.
- [x] The assertions pin the criteria, and none of the six empty test shapes appears. The lint test runs real `po-lint` against two mutants (missing section; driver file removed). The grounding test runs against the real source at the named commit, plus a mutant with a made-up path.
- [x] 3 tests, within a budget of 25.
- [x] Bite checks. After each one I undid the change and `git diff --exit-code` came back clean:
  - Removed "the raw recordings stay in the temporary directory" from `simulation.md`. Running `ros-simulation-driver.test.sh` and `qa-drivers.test.sh` gave 1 failing test (`simulation_driver_records_behaviour`).
  - Changed the profile's `ros_gz_example_bringup/config/rrbot.rviz` to `rrbot2.rviz`. This gave 1 failing test (`ros_profile_is_grounded_in_its_source`, which names the path).
  - Changed the profile's `- QA driver: simulation` to `scene`. `po-lint` alone accepts this, but 1 test failed (`ros_profile_passes_the_lint`).
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read the other callers. The driver table, `po-lint`'s driver-file check and the profile/lint/surface-routing tests are covered by the green full suite in the record. No other file lists the boilerplates or drivers by name.

## Lenses
Lenses run: none. There are no auth, route or handler paths, no migration, no lockfile or manifest, and no server code.

## Findings
- **major** — `method/skills/qa-drivers/simulation.md:30` and `:21`: processes started for each criterion are never reliably stopped, and the end-of-QA check cannot see them.
  - The trigger says "Trigger with `ros2 topic pub` …" with no `--once` or `--times`. By default, `ros2 topic pub` keeps publishing at 1 Hz until it is killed. The research itself records that `ros2 topic pub --once` exists (`docs/research/s88-ros-simulation-driver.md:51`), so a velocity command keeps driving the simulated robot through later criteria.
  - The `ros2 topic pub`, `ros2 topic echo` and `ros2 bag record` processes started at line 28 are not in the `setsid` group. The stop step (line 21) stops "the process group you started, and only that one", and line 30 only says "stop the recording".
  - The leftover check is `ros2 node list --no-daemon` without `--all`. CLI nodes (`_ros2cli_*`) are hidden from that listing, so a leftover `pub` or `echo` process passes the check and outlives the QA.
  - The damage stays inside the QA's own domain and localhost-only discovery, so this is major, not critical.
  - Fix: trigger with `--once` or `--times N`, stop every process the walk started, and run the final check with `--all`.
- **minor** — `method/skills/qa-drivers/simulation.md:41`: "its message count and rate from `ros2 bag info`" is inaccurate. `ros2 bag info` prints a count per topic and one duration for the whole bag, not a rate. Say the rate is computed as count / duration.

## Not verified
- **Nothing was run against a real simulation.** This machine has no `ros2`, `gz`, `colcon` or `xvfb-run`; the record says the same. So none of these was seen:
  - the Gazebo interface or `ogre2` starting on Xvfb with Mesa;
  - the isolation holding: `ROS_DOMAIN_ID`, LOCALHOST discovery range, `GZ_PARTITION`, `GZ_IP`;
  - the resume command un-pausing the world;
  - the build and launch commands of the profile.

  A person should run one real `behaviour` QA on a Jazzy/Harmonic machine with Xvfb.
- **CLI flags not checked against a running ROS 2:**
  - `ros2 topic echo --no-daemon`;
  - `ros2 bag record --use-sim-time --topics`;
  - the hidden-node behaviour of `ros2 node list` that the major finding relies on.

  I took these from my own knowledge of ros2cli and the research's source citations. Check them with `--help` on Jazzy.
- **The grounding test needs the network.** Offline it skips loudly and proves nothing about the paths. I fetched the commit myself, and the test also passed with network access.
- **`simulation.log` cutting:** the 1 MB threshold, the 200-message cap and the 30 s default wait are design choices. No source confirms them, and nothing exercises them.
- **No QA stage:** the story has no screen and `Surface: —`, so there is no QA report and no `## Not seen` to carry over.

Max severity: major
Ship allowed: yes
