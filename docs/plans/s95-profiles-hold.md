---
validated: yes
---
# Plan — s95-profiles-hold

Branch `story/s95-profiles-hold`. Read `docs/research/s95-profiles-hold.md` first; this plan builds on it without repeating it. Decision: `docs/decisions/ADR-0069-la-commande-test-d-un-profil-echoue-quand-un-test-echoue.md` (written by the planner, committed by the implementer with the code).

## Story
Every profile's `Test` exits non-zero on a red test, and an offline grounding test shows as skipped. Criteria, one test function each in the new `tests/profiles-hold.test.sh`:
- `test_commands_fail_on_red` — iOS `Test` fails on a red test, Expo's is `npx --no-install jest`; ADR-0069 replaces ADR-0062 and ADR-0064 in part, and their `superseded-by` names it.
- `skipped_grounding_is_visible` — `tests/run.sh` shows a grounding test that could not reach its source as skipped.
- `lint_holds_its_profile_rules` — `po-lint` refuses `mobile-web` with `Dev: —`; partial platform value, `## Platform` without its line, broken `| Platform |` row and driver `—` each have a case.
- `profile_slips_are_fixed` — iOS xcbeautify, Android `customizer.sh` and `ui/<feature>/`, Rust `utils/Cargo.toml`.

## Tasks
1. [x] **`tests/run.sh` shows skips.** Add `skipped=0`. In the success branch (`run.sh:17-18`), when `$out` contains `not reachable: grounding not checked` (`grep -qF`), print `  skip  ${name#test_}`, then `$out`, and count it in `skipped`; otherwise `  ok    ...` as today. A failing test stays `FAIL` whatever its output. Summary becomes `${passed} passed, ${failed} failed, ${skipped} skipped`; the exit code still depends on `failed` alone. Never write `evals` or `po-eval` in this file (`tests/evals.test.sh:141`). No change to any file that prints the marker.
   Fails if wrong: `test_skipped_grounding_is_visible`. It copies `tests/run.sh` and `tests/lib.sh` into a `mktemp -d`, writes there a `fake.test.sh` with `test_reached() { :; }` and `test_offline() { echo "      (src not reachable: grounding not checked)" >&2; }`, runs `bash "$tmp/run.sh" fake.test.sh` and asserts exit 0, a line `  ok    reached`, a line `  skip  offline`, the marker line printed, and `1 passed, 0 failed, 1 skipped`. A second fake file with `test_red() { echo "      (src not reachable: grounding not checked)" >&2; return 1; }` must give `  FAIL  red` and a non-zero exit.

2. [x] **`po-lint` refuses `mobile-web` without `Dev`.** Add beside `profile_commands` (`bin/po-lint:197`) a reader of one command's value from the `## Commands` fence (`<name>:` then the trimmed rest). In the driver branch (`:283-293`), after the file check, when the value is exactly `mobile-web` and the `Dev` value is `—`, `report "$rel" "$line" profile "QA driver 'mobile-web' needs a Dev command, and Dev is '—'"`. A missing `Dev` line is already reported (`command 'Dev' is missing`); do not report it twice. Only `mobile-web`: the template pairs `browser` with `Dev: —` (`method/templates/profile.md:20,32`). Extend the header comment (`:184-191`) with one sentence for this rule.
   Fails if wrong: `test_lint_holds_its_profile_rules`, cases b and c of task 3.

3. [x] **One test holds the profile rules of `po-lint`.** `test_lint_holds_its_profile_rules`, with the `fresh()` pattern of `tests/profile.test.sh:39-49` (copy of `method/`, template as `boilerplates/demo/profile.md`, `bash "$ROOT/bin/po-lint" "$m/method"`). Cases, each on a fresh copy, each checking its mutation applied before linting:
   - a. the template as is → exit 0;
   - b. `- QA driver: browser` → `- QA driver: mobile-web` → exit ≠ 0, exactly one breach, `boilerplates/demo/profile.md:<driver line>: [profile] QA driver 'mobile-web' needs a Dev command`;
   - c. as b plus `Dev:` set to `npm run web` → exit 0;
   - d. `- QA driver: —` → exit 0;
   - e. `- Platform: web` → `- Platform: we` → `platform 'we' is not a value of the Platform setting` at that line (bites `grep -qxF` → `grep -qF`, s78 bite 2);
   - f. the `- Platform: web` line deleted → `<## Platform line>: [profile] no '- Platform:' line under '## Platform'`;
   - g. in the copy's `templates/agents-local.md`, `| Platform |` renamed `| Platforms |` → `templates/agents-local.md:1: [profile] no Platform values in the settings table`;
   - h. the `- QA driver: browser` line deleted → `no '- QA driver:' line under '## QA driver'`.

4. [x] **The two `Test` commands fail on red, as ADR-0069 decides.**
   - `boilerplates/native-ios/profile.md:28` becomes exactly `Test:              rm -rf fastlane/test_output && bundle exec fastlane buildAndTest && xcrun xcresulttool get test-results summary --path fastlane/test_output/*.xcresult | grep -Eq '"result" *: *"Passed"'`.
   - Rewrite `:37` and the trap `:79` to say: the lane runs `scan` with `failBuild` set to false, so the lane alone exits 0 on a red test; `Test` empties the ignored test output folder, runs the lane, then reads the result bundle with `xcresulttool` and exits non-zero unless it says `Passed` (ADR-0069); never shorten `Test` to the lane; this command was not run on a Mac. The trap carries the exact phrase `never shorten it to the lane`. **Do not backtick `fastlane/test_output`** anywhere in prose: the grounding test would look for it in the source (`tests/native-profiles.test.sh:26`).
   - `boilerplates/expo/profile.md:24` becomes `Test:              npx --no-install jest`; `:31` says that until a first story installs `jest-expo` and `jest`, `npx --no-install jest` fails instead of fetching a jest without the preset; trap `:81` says `use \`npx --no-install jest\``.
   - In `ADR-0062-…sdk-57.md` and `ADR-0064-…android.md`, change only line 8 to `superseded-by: [ADR-0069]`; status stays `accepted`, bodies untouched.
   - `tests/expo-profile.test.sh:67`: the clause changes, so its pattern becomes `^Test:[[:space:]]+npx --no-install jest$` and its message `Test is not 'npx --no-install jest'` (the one existing test this story changes, because the story changes its clause).
   Fails if wrong: `test_test_commands_fail_on_red` — the iOS `Test` value (fence line minus `Test:` and padding) equals the line above exactly; the Expo value equals `npx --no-install jest`; the iOS profile contains `never shorten it to the lane`; ADR-0069 exists with `supersedes: [ADR-0062, ADR-0064]` and `status: accepted`; ADR-0062 and ADR-0064 each hold `superseded-by: [ADR-0069]` and `status: accepted`.

5. [x] **The prose slips match their sources** (research, Diagnostic, source checks):
   - iOS `:35`: `mise install` first, so that Ruby and Tuist match the versions `.mise.toml` pins; `xcbeautify is \`latest\`` there, not pinned.
   - Android trap `:70`: `customizer.sh` deletes `.google/`, `.github/`, `CONTRIBUTING.md`, `LICENSE`, `README.md`, the `.git/` directory and itself, plus every `*.bak` file and the old `android/template` package directories; run it on a fresh clone, then initialise git again.
   - Android ownership `:52`: the story owns `app/src/main/java/android/template/ui/<feature>/` and its tests; the repository and the Room entity live in `app/src/main/java/android/template/data/`, outside that directory, and a story that changes them names those files in its `Owns`. The shared-path list stays.
   - Rust trap `:71`: `clap`, `log`, `serde` and `slog-journald` sit under the Linux-only target section of `utils/Cargo.toml`, the other dependencies of `utils` under `[dependencies]`; `utils` uses clap and serde, so the workspace builds on Linux only.
   Fails if wrong: `test_profile_slips_are_fixed` — iOS contains ``xcbeautify is `latest` `` and not `xcbeautify match the versions`; Android contains `` `CONTRIBUTING.md` ``, `` `.google/` ``, `and itself`, `outside that directory`, and not `with its data and its tests`; Rust contains `` `slog-journald` `` and not ``Every dependency of `utils` ``.

6. [x] **s86 minor 2, helper style.** In `tests/cli-api-profiles.test.sh:19-23` and `tests/native-profiles.test.sh:19-25`, rename the local `head` to `at_head` (both files) and declare `tokens` local (cli-api only; native already does). Behaviour unchanged; no assertion touched.
   Fails if wrong: the existing grounding tests of both files (run with network).

7. [x] **Closing checks**, once: `bash tests/run.sh profiles-hold.test.sh expo-profile.test.sh native-profiles.test.sh cli-api-profiles.test.sh profile.test.sh qa-drivers.test.sh platform-setting.test.sh evals.test.sh` with network; `bin/po-lint` clean; then the full suite through `.polype/hooks/po-run.sh --story s95-profiles-hold --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `method/` (all of it, including `method/templates/profile.md`), `.claude/`, `.polype/`, `docs/stories.md`, `docs/parite-killer-saas.md`.
- Empty diff: `tests/godot-scene-driver.test.sh`, `tests/ros-simulation-driver.test.sh` (s94), `tests/qa-drivers.test.sh` (s93), `tests/flutter-profile.test.sh`, `tests/next-forge-profile.test.sh`, `tests/platform-setting.test.sh`, `tests/profile.test.sh`, `tests/lib.sh`.
- Empty diff: `boilerplates/` other than `native-ios/`, `native-android/`, `expo/`, `rust-cli/` profiles.
- ADR-0062 and ADR-0064: only their `superseded-by:` line changes.
- In `tests/run.sh`, `[ "$failed" -eq 0 ]` stays the exit condition: a skip never turns the suite red or green on its own.
- `po-lint` refuses `browser` with `Dev: —` nowhere; no new rule beyond `mobile-web`.
- No command of the iOS, Android or Expo profiles is run or claimed run; no clone is kept in the worktree.

## The pivot
The iOS `Test` line: everything else is mechanical. It could be wrong in three ways:
1. **The summary format.** If `xcresulttool get test-results summary` prints `"result":"Passed"` with other spacing, the regex `"result" *: *"Passed"` still matches; if it nests another `result` key that says `Passed` while the top level says `Failed`, the command passes on red. Compare with Apple's Xcode 16 `xcresulttool` help, or with one red run on a Mac.
2. **The bundle location.** Fastlane runs actions from the project root, so `./fastlane/test_output` (`Constant.swift:55`) is `fastlane/test_output` there; scan names the bundle after the scheme, hence the glob. If fastlane wrote elsewhere, the glob stays literal and `Test` fails closed — wrong, but never silently green.
3. **The `Passed` positive match** fails closed on an all-skipped plan or on "Nothing to test": accepted in ADR-0069.
Nobody can run it here; the review should say so in "Not verified", not treat the exact-string test as proof that the command works.

## Files touched
- `tests/run.sh`, `bin/po-lint`
- `boilerplates/native-ios/profile.md`, `boilerplates/expo/profile.md`, `boilerplates/native-android/profile.md`, `boilerplates/rust-cli/profile.md`
- `docs/decisions/ADR-0062-…`, `docs/decisions/ADR-0064-…` (one line each); `docs/decisions/ADR-0069-…` (written by the planner)
- `tests/profiles-hold.test.sh` (new), `tests/expo-profile.test.sh` (line 67), `tests/cli-api-profiles.test.sh`, `tests/native-profiles.test.sh` (helper style)
- `docs/research/s95-profiles-hold.md`, `docs/plans/s95-profiles-hold.md`, `docs/verif/s95-profiles-hold.md`

## Test strategy
Four new tests, one per criterion, in `tests/profiles-hold.test.sh`; one existing pattern changed (`expo-profile.test.sh:67`). Within `Test budget` (25).
- `test_skipped_grounding_is_visible` runs a copy of the real `run.sh` on fake test files: deleting the skip branch turns `skip offline` back into `ok` and fails it; deleting the "failure wins" order fails the red case.
- `test_lint_holds_its_profile_rules` runs the real `po-lint` on mutated copies: removing the new rule fails b; reading the driver name alone without `Dev` fails c; removing the `—` exemption fails d; `grep -qxF` → `grep -qF` fails e; replacing either report with `true` fails f, g or h.
- `test_test_commands_fail_on_red` and `test_profile_slips_are_fixed` pin exact phrases of the profiles and ADR frontmatter, the convention for prose files here; they prove the text, not that a Mac runs the command (pivot).
Not automated: the iOS command on a Mac, green and red; the Android and Expo commands on a real project.

## Done when
One commit on `story/s95-profiles-hold` with code, tests, ADR-0069, research, plan and record; focused tests and `bin/po-lint` clean; full suite green through `po-run`; a review with no open critical finding; squash on `main`.
