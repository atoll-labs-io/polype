# Verification — s85-native-profiles

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: a6e0b17c003902ad9933f7656ccd1c59647c023b

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The project has no type check, end-to-end or build command. The profiles are checked against their starters only when the network (or `NATIVE_IOS_SRC` / `NATIVE_ANDROID_SRC`) is reachable; otherwise the test skips loudly. No JDK, Android SDK or Xcode was available: none of the profile commands (`fastlane`, `./gradlew`, `iOSTemplateMaker`, `customizer.sh`) was run, and the Android `Typecheck` task names are unverified.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 7273a8bf28af2d9ba346051fc3d1a74fd41ed167 | 2026-10-08T16:34:08Z |
