# Review — s147-strict-checks-by-default

[Story](../stories.md) · [Plan](../plans/s147-strict-checks-by-default.md) · [Verification](../verif/s147-strict-checks-by-default.md)

I found no critical or major defect, so ship is allowed. The six acceptance criteria each have a test, the gates pass, and the tests fail when the rules they check are disabled. The three findings are minor.

Reviewed tree: 581d764a9245cdc0ee7f78778b49fad02186a0b1
Fix loop: 0
Review status: complete
Lenses run: none (the diff holds no auth, route, migration, lockfile, manifest or server-side path, and no content that triggers a lens)

## Scope
`git diff --name-only main...story/s147-strict-checks-by-default` returns 18 paths. Each one is inside the story's `Owns` or is the story's own pipeline evidence:
- `bin/po-lint`
- `boilerplates/*/profile.md` (9 files)
- `method/commands/po-architect.md`
- `method/templates/architecture.md`
- `method/templates/profile.md`
- `tests/strict-checks-by-default.test.sh`
- `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md` (listed in `Owns` and named in the plan)
- `docs/research|plans|verif/s147-strict-checks-by-default.md`

The plan's run interdicts hold:
- `.claude/`, `.polype/`, `AGENTS*.md` and `method/templates/agents-local.md` are untouched, and no setting was added.
- No `## Commands` fence of any profile changed.
- `po-architect.md` lost no line. `bin/po-lint` lost one line only, the `local` declaration inside `check_profiles`, which the interdict allows.
- No existing test file was edited.

## Steps
1. **Recorded run.** `po-gate verif-current` exits 0. `Verification mode` is `record`, so I relied on the recorded `Unit suite` row (`bash tests/run.sh`, exit 0) and did not rerun it. The project has no type check, end-to-end or build command (`Typecheck`, `E2E` and `Build` are all `—`). The story's `Surface` is `command` and `QA stage` is `—`, so there is no QA to require.
2. **References.** Every helper the diff calls exists: `template_settings`, `settings_read_by`, `frontmatter`, `require_file`, `contains`, `fail`, `$ROOT` and `$METHOD` in `tests/lib.sh`, and `report` in `bin/po-lint`. The `trap ... EXIT` pattern in the new test is already used in `tests/profile.test.sh` and seven other test files.
3. **Plan.** All 8 tasks are present. The new `profile_field_line` helper follows `profile_platform_line` / `profile_driver_line`, as the plan's `## Reuse` section says. The ADR lists the options in the story's order (A retained; B, C, D turned down).
4. **Tests.**
   - `po-gate floor-guard` exits 0, so nothing was lowered.
   - The story adds 6 tests, within the budget of 25.
   - Bite test results:
     - The `report` call of the new `## Strictness` block in `bin/po-lint` was turned into a no-op: 1 of 6 tests failed (`profile_declares_strictness`).
     - `never through a setting of its own` was removed from `po-architect.md`: 1 of 6 failed (`strict_command_reaches_typecheck`).
     - The godot profile's `Passes` value was set to `maybe`: 1 of 6 failed (`every_profile_fills_strictness`).
   - Each mutation was undone, and `git diff --exit-code` came back clean afterwards.
5. **Values.** I checked the rust-starter facts against the upstream at `51ebb2f5`, in a blobless clone under `/tmp`:
   - `justfile:19-20` has `lint: cargo clippy`.
   - `.github/workflows/lint.yml` passes `--all-features`.
   - `Cargo.toml` has no `[lints]` table.

   All three match the profile. Every profile says `Passes at the commit profiled: not run` and none claims `yes`, which matches the record.
6. **Neighbours.** `check_profiles` is the only place that uses the new block. The existing profile and lint suites stay green in the recorded run, including the fresh profile built from the template in `tests/profile.test.sh`.

## Findings
- **minor** — `boilerplates/native-android/profile.md` (`## Strictness`), `boilerplates/ros2-gazebo/profile.md` (`## Strictness`): the `Turned on by:` line names what is *not* set ("where neither `allWarningsAsErrors` … nor `lint { warningsAsErrors = true }` is set", "sets no warning flag"), when the template asks for the file and setting that turn strictness on. On top of that, the `Strict check:` command does not turn warnings into errors for Android, and has no linter half for ROS 2, until a later story changes the base. The prose under each section says so honestly, and `not run` routes both to a "switch to strict" story, so nothing harmful happens. Still, a reader of the line alone gets a command that the template's definition does not call strict. Fix: name the settings to turn on (for example "`app/build.gradle.kts`: `allWarningsAsErrors`, `lint.warningsAsErrors`, not yet set"), or state the gap in the template's wording.
- **minor** — `method/commands/po-architect.md:45`: the new bullet follows an item that already ends the list with a period ("each third-party integration the project depends on."). The new bullet itself also ends with a period, while the other items end with `;`. This is list punctuation only.
- **minor** — `tests/strict-checks-by-default.test.sh` (`test_every_profile_fills_strictness`): `[ "$count" -eq 9 ]` hard-codes the number of profiles, so adding a tenth boilerplate breaks this test even though no strictness rule is broken. The story asks for nine profiles today, but checking the section on every profile found would hold up as the set grows.

## Not verified
- **The nine strict commands were never run**, upstream or here, as the record says (the toolchains were not used). Whether `npx expo lint --max-warnings 0`, `bunx biome check --error-on-warnings`, `bun run --filter '*' typecheck`, `flutter analyze --fatal-infos --fatal-warnings`, the Gradle task names, `swiftlint lint --strict`, `gdlint components` and the colcon line work as written is unproven. To cover it, a person runs each one at its profiled commit before any profile is moved to `yes`.
- **Upstream facts for eight of the nine profiles** (expo, hono-api, next-forge, flutter, native-android, native-ios, godot, ros2-gazebo): I only rechecked rust-starter. The rest rely on the implementer's reading listed in the record. Per the record, the grounding tests reached the upstreams for the backticked paths that match their patterns. `biome.jsonc`, `PrebuildDangerfile` and `.github/workflows/gdlint-on-push.yml` were checked by hand only. To cover it, a person spot-checks those files at each `Commit profiled:`.
- **`/po-architect` running on a real project** with the new Step 3 and Step 4 text: the tests only read the text. To cover it, a person runs `/po-architect` on a project built from a profile and confirms that it drafts the strict-check ADR and writes the switch story into `docs/architecture.md`.

Max severity: minor
Ship allowed: yes
