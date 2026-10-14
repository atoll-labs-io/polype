# Verification — s88-ros-simulation-driver

[Story](../stories.md) · [Plan](../plans/s88-ros-simulation-driver.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: aaaed2ee4b4f1e07cacd7082773b422fcdfd0095

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- The driver has never run against a real simulation: this machine has no `ros2`, `gz`, `colcon` or `xvfb-run`. Whether Gazebo's interface and `ogre2` start on Xvfb with Mesa, and whether the isolation holds, is first seen at the first real `behaviour` QA.
- The profile's build and launch commands are taken from the template's source and README, not executed here.
- `ros_profile_is_grounded_in_its_source` fetched the template over the network on this run; offline it skips loudly and proves nothing about the paths.
- No QA stage: the story ships no screen.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 95b095ccfe136bbd1e4679d546b40b20ed3bb4b2 | 2026-10-08T16:53:25Z |
