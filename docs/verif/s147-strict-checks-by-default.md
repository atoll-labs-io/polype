# Verification — s147-strict-checks-by-default

[Story](../stories.md) · [Plan](../plans/s147-strict-checks-by-default.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 434284c2ae46988354c68282cf4b9694c784e8b3

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- **Strict commands of the nine profiles: none was run.** Every profile says `Passes at the commit profiled: not run`; the toolchains (node, bun, flutter, Gradle, Xcode, cargo, Godot, colcon) were not used, and running upstream build scripts here was not in the plan. The commands not run: expo `npx tsc --noEmit && npx expo lint --max-warnings 0`; hono-api `npx tsc --noEmit`; next-forge `bunx biome check --error-on-warnings . && bun run --filter '*' typecheck`; flutter `flutter analyze --fatal-infos --fatal-warnings`; native-android `./gradlew lintDebug compileDebugUnitTestKotlin compileDebugAndroidTestKotlin`; native-ios `swiftlint lint --strict`; rust-cli `cargo clippy --workspace --all-targets --all-features -- -D warnings`; godot `gdlint components`; ros2-gazebo the `colcon build --cmake-args -DCMAKE_CXX_FLAGS='-Wall -Wextra -Werror' && colcon test && colcon test-result --verbose` line.
- **Upstreams read at their `Commit profiled:`** (blobless fetch under `/tmp`, read with `git show` / `git ls-tree` / `git grep`, nothing checked out or run): expo/expo `345ae166` (`templates/expo-template-default/tsconfig.json`, `package.json`, `packages/@expo/cli/src/lint/`); honojs/starter `110fb1c4` (`templates/nodejs/tsconfig.json`, `package.json`); vercel/next-forge `f189de79` (`biome.jsonc`, `tsconfig.json`, `turbo.json`, `packages/typescript-config/base.json`, `apps/app/package.json`, `apps/web/package.json`); flutter/flutter `5fc34683` (`packages/flutter_tools/templates/app/analysis_options.yaml.tmpl`); android/architecture-templates `5467a8dc` (`app/build.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `.github/workflows/build_and_local_tests.yml`); nimblehq/ios-templates `f009d02e` (`template/.swiftlint.yml`, `template/PrebuildDangerfile`, grep for `SWIFT_TREAT_WARNINGS_AS_ERRORS`); rust-starter/rust-starter `51ebb2f5` (`justfile`, `.github/workflows/lint.yml`, `Cargo.toml`); GodotVR/godot-xr-template `7d8261cd` (`.github/workflows/gdlint-on-push.yml`, `project.godot`); gazebosim/ros_gz_project_template `045e981d` (every `CMakeLists.txt` and `package.xml`).
- Flag support not proven by a run: `expo lint --max-warnings` is read from the CLI's help text at the commit; `biome check --error-on-warnings` and `bun run --filter` come from those tools' documentation, not from the upstream.
- The grounding tests of the profile suites reached the upstreams in the unit-suite run (0 skipped), so the backticked paths they match exist at each commit; paths outside their patterns (`biome.jsonc`, `PrebuildDangerfile`, `.github/workflows/gdlint-on-push.yml`) were checked by hand only.
- No type check, end-to-end or build exists in this repository (`Typecheck`, `E2E`, `Build` are `—`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | cefb2f245c03181ef4314402c2e98b7792b04c0f | 2026-11-10T17:31:11Z |
