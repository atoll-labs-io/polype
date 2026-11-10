# Research — s147-strict-checks-by-default

[Story](../stories.md)

## Structuring facts
- No assumption of the story turned out false: the four starting points of its notes hold (`boilerplates/rust-cli/profile.md:25`, `boilerplates/expo/profile.md:46`, `boilerplates/next-forge/profile.md:31`, `boilerplates/flutter/profile.md:31`). One correction of detail: the next-forge sentence on the missing root type check is at `:31`, not `:108`.
- `bin/po-lint` already reports every `## ` heading of the template missing from a profile (`bin/po-lint:256`, `:266-268`): adding `## Strictness` to `method/templates/profile.md` makes all nine profiles fail the lint until each carries it, so the template, the lint rule and the nine profiles land together or the suite goes red (`tests/cli-api-profiles.test.sh:56` runs the lint on the real tree).
- The three lines need a new presence check in `check_profiles`, on the model of `## Platform` / `- Platform:` (`bin/po-lint:220-226`, `:283-296`), since the section rule checks headings only.
- `/po-architect` already refuses to change settings and asks the person to edit them (`method/commands/po-architect.md:55`, `:57`); the strict command plugs into that sentence, and `Typecheck` is already in its `Reads settings:` (`:14`). No new setting is needed.
- The nine upstreams are reachable (checked on 2026-11-10 with a blobless clone at each `Commit profiled:`); each holds something to read for strictness: `tsconfig.json` with `"strict": true` in expo and hono, `biome.jsonc` in next-forge, `analysis_options.yaml.tmpl` on `flutter_lints` in flutter, `template/.swiftlint.yml` in native-ios, `cargo clippy` in the rust-starter `justfile:20`, `.github/workflows/gdlint-on-push.yml` in godot; native-android and ros2-gazebo show no lint config file at all.

## Story
Each profile states what the strict check of its base is; `/po-architect` retains it by default through a project ADR, and a project keeps a non-strict check only through that ADR. Criteria: `profile_declares_strictness` (template section of three lines, `po-lint` refuses a profile without it or without one line), `every_profile_fills_strictness` (nine profiles, values read upstream at the profiled commit, `not run` for anything not run, `—` with a one-sentence reason when no strict check is possible), `architect_retains_strict` (project ADR at step 3, options ranked), `strict_command_reaches_typecheck` (through `Typecheck`, no new setting, the person edits it; `templates/architecture.md` cites it), `strict_switch_is_a_story` (`no` / `not run` → `docs/architecture.md` names a story to write; `Typecheck` gets the strict command only once it ships), `adr_records_strict_default` (ADR-0097, three options turned down, in order).

## Current code
- `method/templates/profile.md` — sections at `:5` Identity, `:12` Platform, `:18` QA driver, `:24` Commands (fence `:29-36`), `:37` Code map … `:74` Known traps. `:3` lists what `bin/po-lint` checks; it will need the strictness clause.
- `bin/po-lint:184-318` — `check_profiles`: headings (`:266-268`), command names (`:270-281`), `- Platform:` line (`:283-296`), `- QA driver:` line (`:298-310`), capability names (`:312-316`). Messages follow `<rel>:<line>: [profile] <message>`; a missing line is reported on the section heading's line (`:288`, `:303`).
- `method/commands/po-architect.md` — Step 3 (`:40-48`) drafts one ADR per stack, capability and integration, ranked by `capability-bricks`; Step 4 (`:50-57`) writes conventions, never settings, and quotes the commands from the settings (`:57`).
- `method/templates/architecture.md` — `## Commands` table quoting the settings (`:39-49`), `Typecheck` row `:47`; links to ADRs as `<ADR directory, relative to docs/><NNNN>-<slug>.md` (`:10`, `:29`).
- Nine profiles under `boilerplates/*/profile.md` (`bricks/` is not a profile). Their `Typecheck:` today: expo `npx tsc --noEmit` (`expo/profile.md:25`), flutter `flutter analyze` (`flutter/profile.md:25`), godot `—` (`godot/profile.md:25`, CI lints with `gdlint` per `:31`), hono-api `npx tsc --noEmit` (`hono-api/profile.md:25`), native-android `./gradlew compileDebugUnitTestKotlin compileDebugAndroidTestKotlin` (`native-android/profile.md:29`), native-ios `—` (`native-ios/profile.md:29`, `swiftlint` named at `:39`), next-forge `—` (`next-forge/profile.md:25`, `bun run check` Biome at `:31`), ros2-gazebo `—` (`ros2-gazebo/profile.md:25`, `ament_lint_auto` at `:31`), rust-cli `cargo check --workspace --all-targets` (`rust-cli/profile.md:25`).
- `method/templates/verification-record.md:23-24` — `## Not proven here` is the free section where the implementer can say which upstreams it read and which strict commands nobody ran.

## Attachment points
- `method/templates/profile.md` — new `## Strictness` section after `## Commands` (before `:37`), three bullet lines in the profile's `- Name: value` habit (`:7-10`, `:14`, `:20`).
- `bin/po-lint` — one awk helper beside `profile_platform_line` (`:220-226`) and one block in `check_profiles` after the QA driver block (`:298-310`).
- `boilerplates/<name>/profile.md` ×9 — the same section, after `## Commands`.
- `method/commands/po-architect.md` — a bullet in Step 3's list (`:41-44`) plus a paragraph after `:46`; a sentence after `:57` in Step 4.
- `method/templates/architecture.md` — a `## Strict check` section after `## Commands` (`:39-49`).
- `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md` — new, French like `ADR-0096`, `status: accepted`, `scope: story s147-strict-checks-by-default`.

## Verified interfaces
- `po-lint [method dir]` — exit 0 clean, 1 on breaches, 2 when it read no file (`bin/po-lint:8`, `:80-83`, `:330`); profiles are read from `$METHOD/../boilerplates` (`:196`), so a mutant tree copies `method/` and adds `boilerplates/demo/profile.md` (pattern `tests/profile.test.sh:43-49`).
- Test helpers: `contains`, `require_file`, `fail`, `frontmatter` (`tests/lib.sh`); `section_of` is redefined per file (`tests/architect.test.sh:8`).
- ADR lookup by number: `ls "$ROOT"/docs/decisions/ADR-<n>-*.md` (`tests/profiles-hold.test.sh:13`).

## Traps
- **The template must lint clean as it is**: `tests/profile.test.sh:51-53` and `tests/profiles-hold.test.sh:75-76` copy the template as a profile and expect exit 0; `tests/profile.test.sh:60` expects exactly one breach when `## Known traps` alone is removed. The template's three lines must therefore carry values the new check accepts.
- **The section list of the template is frozen by name**, not by count (`tests/profile.test.sh:19-22`): adding a heading is safe; renaming one is not.
- **Commands fences are frozen** in several tests (`tests/profiles-hold.test.sh:11-23` greps `^Test:` over the whole file; `tests/godot-scene-driver.test.sh:47-49`, `tests/flutter-profile.test.sh:84-85`). No line of `## Strictness` may begin with `Test:`, `Typecheck:`, `Dev:` …; bullet lines `- Strict check:` avoid it. The `Typecheck:` value of each fence stays as it is.
- **Grounding tests check backticked paths against the upstream** when it is reachable: rust `^(src|cli|core|utils|tests|docker|\.github)/|^(Cargo\.toml|justfile|LICENSE)$` (`tests/cli-api-profiles.test.sh:27`), hono `src/`, `package.json`, `tsconfig.json` (`:31`), expo `tests/expo-profile.test.sh:22`, flutter `analysis_options.yaml` resolved in the templates (`tests/flutter-profile.test.sh:41`), iOS `.swiftlint.yml` under `template/` (`tests/native-profiles.test.sh:26`), Android `:40`, godot `tests/godot-scene-driver.test.sh:31`, next-forge `tests/next-forge-profile.test.sh:14`. A file named in `Turned on by:` must exist at the profiled commit, or those tests go red.
- **Phrases of `po-architect.md` frozen elsewhere**: `tests/architect.test.sh` (Step 3, Step 4 sentences at `:39`, `:56-63`, `:76-83`), `tests/conversational-framing.test.sh:39-50`, `tests/escalation-contract.test.sh:108` (`Ranking the options` in Step 3), `tests/claude-md-setting.test.sh:139`, `tests/post-m7-texts.test.sh:32`, `tests/capability-bricks.test.sh`. Edits there are additions only.
- `tests/adr-directory.test.sh:29` refuses `(decisions/` links in `templates/architecture.md`.
- `tests/overlap.test.sh` fails on 8+ words shared with Killer SaaS; new method text is written fresh.
- `.claude/` and `.polype/` are installed copies; only `method/` and `bin/` change.
- No migration. Running a strict command upstream needs each toolchain (cargo, node, flutter, Gradle, Xcode, Godot, colcon); whatever cannot be run here stays `not run`.

## Open questions
- Third line when no strict check exists (`—` on the first two lines): the story lists only `yes`, `no`, `not run`. Plan decides `not run` (nothing was run).
- Should `po-lint` also refuse a `Passes` value outside the three words? The story asks only for presence; the plan keeps presence only and leaves the value to review.
- Strict command for a project with no profile, or an empty repository: the plan takes it from step 2's analysis, and for an empty repository the ADR retains strict and the command arrives with the story that brings the base.

## Complexity
Story 4 → 4. The method edits are small and additive; the weight is reading nine upstreams at their commit, choosing one honest command each, and keeping six suites of profile tests green.

## Split
Not needed: the plan holds nine tasks.
