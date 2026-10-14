# Review: s95-profiles-hold

[Story](../stories.md) · [Plan](../plans/s95-profiles-hold.md) · [Verification](../verif/s95-profiles-hold.md)

Story: s95-profiles-hold. Les profils disent vrai et leurs tests le prouvent
Reviewed tree: f5408108929b2eae21cd6bb1e5a5fa493183eb75
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s95-profiles-hold (branch `story/s95-profiles-hold`, one commit `4927647`)
Scope: `git diff main...story/s95-profiles-hold`
Lenses run: none (no auth, migration, lockfile or server-side path or content in the diff)

## Scope check (Owns)
I checked all 16 changed paths against the story's `Owns` line in `docs/stories.md:1449`:
- `bin/po-lint` and `tests/run.sh` are listed.
- The four profiles fall under the folder entries `boilerplates/native-ios/`, `native-android/`, `expo/` and `rust-cli/`.
- The four test files are listed: `tests/cli-api-profiles.test.sh`, `tests/expo-profile.test.sh`, `tests/native-profiles.test.sh` and `tests/profiles-hold.test.sh`.
- ADR-0062 and ADR-0064 are listed by their full file names. Only line 8 (`superseded-by: [ADR-0069]`) changed in each, as the run interdict requires.
- ADR-0069 was added (status `A`) and the plan names it, so it is in scope by construction.
- The research, plan and verification record are the story's own evidence.

Nothing is outside `Owns`. The only other worktree is `s96-defect-and-routing-paths`, which has already landed on `main` (`539b1d4`). Its paths do not overlap this story's in any case. I compared the run interdicts with the name list: nothing under `method/`, `.claude/`, `.polype/`, `docs/stories.md`, `tests/lib.sh`, any s93 or s94 test file, or any other boilerplate was touched.

## Step 1: Proven work reused
- I ran `po-gate verif-current s95-profiles-hold` and it **exited 0**. The record says `Verification status: complete`, and its one declared check, `Unit suite` (`bash tests/run.sh`), exited 0 on the code it names. `Verification mode: record` applies, so I did not rerun the full suite.
- The project has no type check (`Typecheck: —`), no E2E command (`E2E: —`) and no build command (`Build: —`). I substituted nothing for them.
- I read the record's "Not proven here": the iOS command was never run, the Android and Expo commands were not run on a real project, and `po-lint` was run by hand, not as a declared check.
- QA does not apply (`Surface: —`), so no QA gate.
- My own reruns, for the bite proofs only:
  - `bash tests/run.sh profiles-hold.test.sh expo-profile.test.sh` gave 7 passed, 0 failed, 0 skipped.
  - `bin/po-lint method` found no breach in 26 files.

## Step 2: What the diff refers to
- **`bin/po-lint`:**
  - The new `profile_command_value` reads the `## Commands` fence the same way `profile_commands` does.
  - The new `elif` sits after the check that the driver file exists, so `mobile-web` resolves to `method/skills/qa-drivers/mobile-web.md`.
  - A missing `Dev` line yields an empty value, not `—`, so it is not reported twice. The existing "command 'Dev' is missing" message still covers it.
- **`tests/run.sh`:** every file that prints the skip marker uses the exact substring `not reachable: grounding not checked` (`native-profiles:111-112`, `cli-api-profiles:99-100`, `expo-profile:78`, `flutter:95`, `next-forge:92`, `godot-scene-driver:108`, `ros-simulation-driver:112`).
- **Summary line format:** nothing in `tests/`, `bin/`, `method/` or `.polype/` parses the old `N passed, M failed` line, so adding `, K skipped` breaks no reader.
- **Profile facts against their sources:** I fetched each source at its profiled commit into `/tmp/tmp.Q2rG0JRwa8/`.
  - `ios-templates@f009d02`:
    - `.mise.toml` has `xcbeautify = "latest"`.
    - `Test.swift` has `outputDirectory: Constant.testOutputDirectoryPath`, `resultBundle: .userDefined(true)` and `failBuild: .userDefined(false)`.
    - `Constant.swift:55` is `"./fastlane/test_output"` and `.gitignore:57` ignores it.
  - `architecture-templates@5467a8d`, `customizer.sh`:
    - The final lines remove `.google/`, `.github/`, `CONTRIBUTING.md`, `LICENSE`, `README.md`, `customizer.sh` and `.git/`.
    - It also deletes every `*.bak` and runs `rm -rf ... $n/java/android`.
  - `rust-starter@51ebb2f`, `utils/Cargo.toml`: `slog-journald`, `clap`, `log` and `serde` sit under `[target.'cfg(target_os = "linux")'.dependencies]`, and the rest under `[dependencies]`.

All the new prose matches its source.

## Step 3: Diff against the plan
I checked tasks 1–7 one by one, and each is implemented as written:
- The `Test` value is the exact iOS string the plan gives.
- The trap holds `never shorten it to the lane`.
- `fastlane/test_output` is not backticked in prose.
- `expo-profile.test.sh:67` was changed. This is the one existing test the plan allows to change, because the story changes the clause it checks.
- In the two existing test files, the local `head` became `at_head`, and `tokens` became local in cli-api.
- The `po-lint` header comment gained the sentence the plan asks for.

I found no change the plan did not ask for. ADR-0069 is consistent with ADR-0064 (it keeps the rejection of a direct `xcodebuild test`) and with the precedent for partially superseding an ADR (ADR-0047).

## Step 4: Do the tests prove anything?
- **Floor:** `po-gate floor-guard s95-profiles-hold main` exited 0, so nothing was lowered.
- **Tests that only look like coverage:**
  - `test_skipped_grounding_is_visible` runs a copy of the real `run.sh` on fake test files. It never runs the real suite, so it cannot recurse.
  - `test_lint_holds_its_profile_rules` runs the real `po-lint` on mutated copies, and each case first checks that its mutation was applied.
  - `test_test_commands_fail_on_red` and `test_profile_slips_are_fixed` pin exact text. As the plan says, they prove the text, not that the commands behave.
  - None of the six "tests that prove nothing" patterns applies.
- **Excess:** 4 new tests against a budget of 25.
- **Bite proofs:**
  1. `bin/po-lint`: replaced the `mobile-web` condition with `elif false`. Ran `profiles-hold.test.sh` and `expo-profile.test.sh`: **1 test failed** (`lint_holds_its_profile_rules`, case b). Restored with `git checkout -- bin/po-lint`; `git diff --exit-code bin/po-lint` came back clean.
  2. `tests/run.sh`: replaced the skip condition (`grep -qF 'not reachable…'`) with `false`. Ran `profiles-hold.test.sh`: **1 test failed** (`skipped_grounding_is_visible`, "no skip line for offline"). Restored with `git checkout -- tests/run.sh`; `git diff --exit-code tests/run.sh` came back clean.

## Step 5: Values that only look right
- `npx --no-install jest`: the research observed that it exits 1 with "npx canceled due to missing packages" on npm 12.2.0.
- The iOS regex `"result" *: *"Passed"` and the glob `fastlane/test_output/*.xcresult` are confirmed only from the source code and Apple's documented format, not from a run. They are listed under Not verified.
- `xcresulttool get test-results summary` needs Xcode 16+. The template's `.swift-version` is 6.1, which needs Xcode 16.3+.
- Run interdict `[ "$failed" -eq 0 ]` is still the exit condition of `run.sh`.

## Step 6: Neighbours
- Every profile with driver `mobile-web` (expo, flutter) has a real `Dev` command, and the template pairs `browser` with `Dev: —`, which the new rule leaves alone. `po-lint` stays clean on all of them.
- In `native-profiles` and `cli-api-profiles`, one test can check one source and skip the other. That whole test now reports `skip`. This is deliberate in the research and is not a defect.
- `main` has moved forward by s96 (`539b1d4`) since this story branched. s96 touched none of this story's files.

## Findings

None at any severity.

## Not verified
- **The iOS `Test` command was never run.** No Mac or Xcode is available here or in the implementer's environment. Three things are unproven:
  - whether fastlane resolves `./fastlane/test_output` relative to the project root;
  - whether scan names the bundle `*.xcresult` in that folder;
  - whether the top-level summary key `"result"` is the only `result` key and reads `Passed` or `Failed`.

  A person with a Mac should generate a project from `ios-templates@f009d02` and run the new `Test` twice: once green, and once with one assertion forced to fail. Exit 0 then non-zero is the expected outcome.
- **The Expo and Android commands were not run** on a generated project. A person should generate the Expo project, install `jest-expo` and `jest`, and run `npx --no-install jest` once green and once red.
- **I did not exercise the offline skip path on the real grounding tests myself.** My runs had network access, and the record says this path was only observed by hand behind an unreachable proxy. The fake-file test covers what `run.sh` itself does.
- **Lint on the merged code was not checked.** `po-lint` was not run against `main` after s96's `method/` changes merged with this branch. Running `bin/po-lint method` once after the squash would cover it.

Max severity: none
Ship allowed: yes
