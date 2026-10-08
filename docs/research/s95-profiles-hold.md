# Research — s95-profiles-hold

## Structuring facts
- **False assumption (iOS Test, partly):** the story wants the iOS `Test` command itself to fail on red, but the lane it names cannot: `scan(... failBuild: .userDefined(false))` is hard-coded in the generated project (`ios-templates@f009d02:template/fastlane/Helpers/Test.swift:33`). A passed parameter beats `SCAN_FAIL_BUILD`, so no flag fixes it; the profile command has to check the result bundle after the lane (ADR-0069). `xcodebuild test` direct stays out, as ADR-0064 said: the scheme is `"<project name> Staging"` (`template/fastlane/Constants/Constant.swift:101-108`).
- **Root cause, skipped grounding:** `tests/run.sh:17-18` prints `ok` for any test that exits 0 and drops its captured output; the grounding tests exit 0 after writing `not reachable: grounding not checked` to stderr (`tests/expo-profile.test.sh:78` and six other files, see Current code).
- **Root cause, lint hole:** the QA driver branch of `check_profiles` (`bin/po-lint:283-293`) only checks that the driver file exists; nothing reads `Dev`, so `- QA driver: mobile-web` with `Dev: —` lints clean.
- **Trap the lint rule must respect:** the profile template itself pairs `- QA driver: browser` with `Dev: —` (`method/templates/profile.md:20,32`), outside `Owns`; a rule extended to `browser` would make every "profile built from the template" case red (`tests/profile.test.sh:50-52`, `tests/qa-drivers.test.sh:100-102`, `tests/platform-setting.test.sh`). The rule stays on `mobile-web`, as the criterion says.
- The other slips are prose, each confirmed in its source at the profiled commit (Diagnostic).

## Story
Every profile's `Test` exits non-zero when a test fails, and an offline grounding test shows as skipped. Criteria:
- `test_commands_fail_on_red` — iOS `Test` exits in error on a red test; Expo's is `npx --no-install jest`; an ADR replacing ADR-0062 and ADR-0064 in part says so, and their `superseded-by` names it.
- `skipped_grounding_is_visible` — a grounding test that could not reach its source shows as skipped in `tests/run.sh` output, not passed.
- `lint_holds_its_profile_rules` — `po-lint` refuses `mobile-web` with `Dev: —`; the partial platform value, `## Platform` without its line, broken `| Platform |` row and driver `—` rules each get a test.
- `profile_slips_are_fixed` — xcbeautify is `latest` (iOS); the full list of what `customizer.sh` deletes and what `ui/<feature>/` owns (Android); the Linux section of `utils/Cargo.toml` (Rust).

Defect story (`Corrige`): s85 F1, F2, F3; s83 minor 1 (npx); s86 minors 1 and 2; s78 minors 2, 3, 4 (lint tests). s78 minor 5 and the s83 `docs/stories.md` minor belong to s97.

## Diagnostic
Reproduced on the worktree as it stands (HEAD of `story/s95-profiles-hold`):
1. `https_proxy=http://127.0.0.1:9 bash tests/run.sh expo-profile.test.sh native-profiles.test.sh` → `ok expo_profile_is_grounded_in_its_source`, `ok native_profiles_are_grounded_in_their_sources`, `6 passed, 0 failed`. The same function run alone prints `(expo/expo not reachable: grounding not checked)` on stderr and exits 0. Reproduced.
2. A copy of `method/` plus `boilerplates/x/profile.md` = native-ios with `- QA driver: mobile-web` and `Dev: —` → `po-lint: no breach in 26 file(s)`, exit 0. Reproduced.
3. iOS: not runnable here (no Xcode). Read: `Test.swift:33` `failBuild: .userDefined(false)`; `Fastfile.swift:169-178` `buildAndTestLane` calls it. Shown by source, not by run.
4. Expo: `npx --no-install jest --version` in an empty dir (npm 12.2.0) → `npx canceled due to missing packages`, exit 1, nothing installed. The bare `npx jest` was not run (it may download jest).
5. Lint rules without a test: s78 review bites 2 and 3 (`docs/reviews/s78-platform-setting.md:251-253`) left them alive at 0 failing tests; `grep` of `tests/` finds no case for `no Platform values` nor `no '- Platform:' line`.

Hypotheses for the one non-obvious defect (offline "ok"):
- H1 the marker is never printed offline — refuted: run alone, the function prints it (step 1).
- H2 `run.sh` swallows it — kept: `out=$(... 2>&1)` captures it, line 18 echoes only `ok` (`tests/run.sh:17-18`).

Source checks (shallow clones at the profiled commits, in `/tmp`):
- `ios-templates@f009d02:template/.mise.toml` → `ruby = "3.2"`, `"asdf:tuist" = "4.110.3"`, `xcbeautify = "latest"`.
- `template/.gitignore:57` ignores `fastlane/test_output`; `Constant.swift:55` `testOutputDirectoryPath = "./fastlane/test_output"`; `Test.swift:31` `resultBundle: .userDefined(true)`; `template/.swift-version` 6.1 (Xcode 16.3+, which ships `xcresulttool get test-results summary`).
- `architecture-templates@5467a8d:customizer.sh:89-92` deletes `.google/`, `.github/`, `CONTRIBUTING.md`, `LICENSE`, `README.md`, `customizer.sh`, `.git/`; `:45` removes the old `java/android` package dirs; `:63,84` delete every `*.bak`.
- Android data: `app/src/main/java/android/template/data/` holds `MyModelRepository.kt`, `data/local/database/MyModel.kt`; tests at `app/src/test/java/android/template/ui/mymodel/MyModelViewModelTest.kt`, `app/src/test/java/android/template/data/DefaultMyModelRepositoryTest.kt`, `app/src/androidTest/java/android/template/ui/mymodel/MyModelScreenTest.kt`.
- `rust-starter@51ebb2f:utils/Cargo.toml:14-25` eleven deps under `[dependencies]`; `:26-30` `slog-journald`, `clap`, `log`, `serde` under `[target.'cfg(target_os = "linux")'.dependencies]`; `utils/src/app_config.rs`, `error.rs`, `types.rs` use clap or serde.

## Current code
- `tests/run.sh` (25 lines): per test `out=$(bash -c "set -eu; source ./lib.sh; source './${file}'; ${name}" 2>&1)`; exit 0 → `  ok    <name>`, else `  FAIL  <name>` + output; summary `N passed, M failed` (line 24); exit `[ "$failed" -eq 0 ]`.
- Marker emitters: `native-profiles.test.sh:111-112`, `cli-api-profiles.test.sh:99-100`, `expo-profile.test.sh:78`, `flutter-profile.test.sh:95`, `next-forge-profile.test.sh:92`, `godot-scene-driver.test.sh:108`, `ros-simulation-driver.test.sh:112` — all print `(<source> not reachable: grounding not checked)` to stderr; native and cli-api may skip one of two sources and check the other.
- `bin/po-lint` profile rule (`:184-301`): `profile_commands` (`:197`) prints `<line>\t<name>` of the Commands fence, no value; `profile_platform_line` (`:206`), `profile_driver_line` (`:214`); platforms read from the `| Platform |` row (`:245-246`); missing `- Platform:` line (`:273`); per-value whole-line match `grep -qxF` (`:276-278`); driver `—` exemption and file check (`:288-291`).
- `boilerplates/native-ios/profile.md`: `Test: bundle exec fastlane buildAndTest` (`:28`); `:35` "xcbeautify match the versions the template pins"; `:37` red test exits 0, read the result bundle; trap `:79`.
- `boilerplates/expo/profile.md`: `Test: npx jest` (`:24`); `:31` "`npx jest` fails"; trap `:81` "use `npx jest`".
- `boilerplates/native-android/profile.md`: ownership `:52` "with its data and its tests"; rules `:56`; trap `:70` deletes `.git/`, `LICENSE`, `README.md`, `.github/`.
- `boilerplates/rust-cli/profile.md:71` "Every dependency of `utils` sits under the Linux-only target section".
- `tests/cli-api-profiles.test.sh:19-27` and `tests/native-profiles.test.sh:19-25`: `local ... head` shadows the `head` command used two lines later; `tokens` assigned without `local` in cli-api only (s86 minor 2).

## Attachment points
- `tests/run.sh:17-21` — the ok/FAIL branch; a third outcome `skip` and a counter.
- `bin/po-lint:283-293` — the driver branch; a value reader for `Dev` beside `profile_commands` (`:197`).
- The four profiles above; ADR-0062 and ADR-0064 frontmatter `superseded-by: []` (line 8 of each).
- New file `tests/profiles-hold.test.sh`, one function per criterion.

## Verified interfaces
- Test harness: `tests/lib.sh` gives `ROOT`, `METHOD`, `fail`, `contains`, `require_file`; each test runs in its own `bash -c` (`run.sh:17`), so helpers redefined per file never clash.
- Lint fixture pattern: `tests/profile.test.sh:39-52` `fresh()` copies `method/` to `$m/method` and the template to `$m/boilerplates/demo/profile.md`, then `bash "$ROOT/bin/po-lint" "$m/method"`; breach lines read `boilerplates/demo/profile.md:<line>: [profile] <message>`.
- ADR frontmatter of a partial supersession: `status: accepted`, `superseded-by: [ADR-0051, ADR-0052]` (`ADR-0047…md:4,9`); ADR file names are `ADR-NNNN-<slug>.md`.
- `tests/evals.test.sh:141` fails if `tests/run.sh` mentions `evals` or `po-eval`.

## Traps
- `tests/expo-profile.test.sh:67` pins `^Test:[[:space:]]+npx jest$`: it must change with the clause (allowed, say so).
- iOS grounding (`native-profiles.test.sh:26`) checks every backticked token starting `fastlane/` against the source; `fastlane/test_output` is not in it (ignored). Never backtick that path in prose; the `Test` line inside the fence is not scanned.
- Same for Android tokens starting `app/` (`:40`): backticked `app/...` paths must exist at `5467a8d`; paths with `<feature>` are skipped by `grep -v '[<*]'`.
- `godot-scene-driver.test.sh` and `ros-simulation-driver.test.sh` belong to s94, `qa-drivers.test.sh` to s93: untouched; `run.sh` recognises their marker as is.
- `method/templates/profile.md:3` lists the lint rules; it is outside `Owns`, so the new `mobile-web` rule goes only in `po-lint`'s header comment.
- A test of `run.sh` must run a copy of it on a fake test file: running the real suite inside a test would recurse.
- No migration, no dependency. Nobody here can run the iOS command; the review must say so.

## Open questions
- `xcresulttool get test-results summary` prints `"result" : "Passed"` at top level — read from Apple's Xcode 16 format, not observed on a Mac. A person with a Mac should run the new `Test` once green and once red.
- Should `browser` with `Dev: —` also be refused? Its driver needs `Dev` (`method/skills/qa-drivers/browser.md:6`), but the template pairs them; changing the template is another story.
- A skipped grounding still exits 0: the gate trusts a suite whose grounding was skipped. The story asks for visibility only; whether a skip should block is for a person.

## Complexity
Story 3 → 3. Five small independent fixes; the only hard part is an iOS command nobody can run here.

## Split
—
