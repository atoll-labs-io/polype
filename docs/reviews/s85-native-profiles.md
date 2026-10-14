# Review: s85-native-profiles

[Story](../stories.md) · [Plan](../plans/s85-native-profiles.md) · [Verification](../verif/s85-native-profiles.md)

Reviewed tree: 791a83aa205e393ceb61f5c8134629df07376eee
Fix loop: 0
Track: flow (short track; the plan's `## Verified facts` stands in for research)
Lenses run: none (no security, migration, dependency or performance path or content in the diff)

## Scope
Files changed (`git diff --name-status main...story/s85-native-profiles`), all added:
- `boilerplates/native-ios/profile.md` and `boilerplates/native-android/profile.md`: inside `Owns`.
- `tests/native-profiles.test.sh`: inside `Owns`.
- `docs/decisions/ADR-0064-profils-natifs-depuis-ios-templates-de-nimble-et-architecture-templates-d-android.md`: a new ADR the plan names, so it is in scope.
- `docs/plans/s85-native-profiles.md` and `docs/verif/s85-native-profiles.md`: this story's own pipeline evidence.

Nothing falls outside `Owns`. The only other running lane is s87-godot-scene-driver. It touches `boilerplates/godot/`, `method/skills/qa-drivers/scene.md`, its own test and ADR-0065, so it shares no path with this story. The plan's run interdicts hold: nothing changed under `method/`, `bin/`, the existing tests, `.claude/` or `.polype/`.

## What was relied on
- **Recorded checks:** `po-gate verif-current s85-native-profiles` exits 0. The record is complete and the unit suite (`bash tests/run.sh`) exited 0 on this code. I did not rerun the full suite (`Verification mode: record`). The project has no type check, E2E or build command (`—`).
- **QA:** the story's `Surface` is `—`, so it does not go to QA.
- **Lint and story test:** I ran `bin/po-lint` (no breach in 25 files) and `bash tests/run.sh native-profiles.test.sh` (3 passed).
- **Starters checked against their sources:** I made shallow clones of both starters at the profiled commits (since deleted).
  - **Commits and licences:** `f009d02…` is dated 2026-06-22 and the licence is MIT. `5467a8d…` is dated 2026-10-05 and the licence is Apache 2.0.
  - **iOS facts:**
    - layout: `template/` has `Modules/{Analytics,Data,Domain,Model}` and `{PROJECT_NAME}`, `{PROJECT_NAME}Tests`, `{PROJECT_NAME}KIFUITests`; the five SwiftUI screens are under `Tuist/Interfaces/SwiftUI/Sources/Presentation/Modules`
    - test lane: `failBuild: .userDefined(false)` (`Test.swift:33`), `onlyTesting` takes identifiers, `devices = ["iPhone 15 Pro"]`
    - maker: copies `.env.example` to `.env`; deletes `AGENTS.md`/`CLAUDE.md`, `scripts`, `.github` and `.git/index`
    - other traps: `NimbleExtension` is on `branch: "master"`; the generated README still says `tuist generate`; there is one `GoogleService-Info.plist` per environment
  - **Android facts:**
    - only the `:app` module; Gradle 9.8.0; AGP 9.4.1
    - `HiltTestRunner`; `room.schemaLocation` is `$projectDir/schemas`
    - `customizer.sh` needs bash 4 and uses `sed -i.bak`
    - the README credits "Now in Android"
    - CI runs JDK 17 with `assembleDebug` and `testDebug`
- **ADR-0064 and the QA claim:** ADR-0064 is consistent with the profiles. The `blocked` wording matches `method/agents/qa.md` (stop and write nothing when `Dev` is `—` on a `screen` story).

## Floor
`po-gate floor-guard s85-native-profiles main` exits 0: nothing was lowered.

## Bite
1. I changed `- QA driver: —` to `- QA driver: mobile-web` in the Android profile and ran `native-profiles.test.sh`: 1 test failed (`native_profiles_say_what_qa_cannot_do`). Restored; `git diff --exit-code` is clean.
2. I renamed `Modules/Analytics/` to `Modules/Telemetry/` in the iOS code map: 1 test failed (`native_profiles_are_grounded_in_their_sources`, "path not in the source: Modules/Telemetry/"). This also proves the grounding half really ran against the network. Restored; `git diff --exit-code` is clean.

Side note: `bin/po-lint` accepted `QA driver: mobile-web` together with `Dev: —`. That is outside this story's scope; the story's own test catches it.

## Findings

**F1 (major): the iOS `Test` command exits 0 when tests fail.**
- File: `boilerplates/native-ios/profile.md`, `## Commands`, `Test: bundle exec fastlane buildAndTest`.
- The lane runs `scan` with `failBuild: .userDefined(false)`, so a red test exits 0.
- `/po-setup` copies this command into a project's `AGENTS.local.md`. From then on `po-run` writes exit 0 into `docs/verif/<id>.md`, and the "Record current" gate of Law 3 accepts a run with failing tests.
- The profile does say so in prose and in `## Known traps`, and ADR-0064 accepted the choice, so it is not a hidden defect. It is still a real one: the one command the gates trust does not report failure.
- Fix for a later cycle: give a command that fails on red tests (for example, chain a check of the result bundle), or make the first story of such a project set `failBuild` to true, a step `/po-setup` actually enforces rather than prose.

**F2 (minor): the grounding test's "loud skip" is not loud.**
- File: `tests/native-profiles.test.sh:111-112`.
- When a source cannot be reached, the message goes to stderr, but `tests/run.sh` prints a test's output only when it fails. An offline run reports `ok` for `native_profiles_are_grounded_in_their_sources` without checking anything.
- This is the same pattern as the earlier profile tests (`cli-api-profiles`, `flutter-profile`, `expo-profile`, `next-forge-profile`), so it should be fixed across them, not in this story alone.

**F3 (minor): small factual slips in the profiles.**
- iOS profile: says `mise install` makes xcbeautify "match the versions the template pins", but `template/.mise.toml` sets `xcbeautify = "latest"`.
- Android `## Known traps`: lists what `customizer.sh` deletes as `.git/`, `LICENSE`, `README.md` and `.github/`. The script also deletes `CONTRIBUTING.md`, `.google/` and itself.
- Android `## Ownership granularity`: says a story owns `ui/<feature>/` "with its data". The data of a feature lives in `data/`, outside that directory, so the wording suggests an ownership the path does not give.

## Not verified
- **No command in either profile was run.** There is no Xcode, JDK or Android SDK here, so `bundle exec fastlane buildAndTest`, `./gradlew testDebugUnitTest`, `./gradlew assembleDebug` and the `Install` lines are unproven. A person with a Mac should generate a project with `iOSTemplateMaker` and run `Install` and `Test`. Someone with JDK 17 and the SDK should run the three Gradle commands on a fresh clone at `5467a8d`.
- **The Android `Typecheck` task names** (`compileDebugUnitTestKotlin compileDebugAndroidTestKotlin`) are unverified under AGP 9's built-in Kotlin, as the profile admits. Check them with `./gradlew tasks --all | grep compile`.
- **The iOS test device:** whether the "iPhone 15 Pro" simulator in `Constant.devices` exists on Xcode 26 by default was not checked. If it does not, `Test` may fail for a reason other than the code.
- **The generator's output:** `iOSTemplateMaker` and `customizer.sh` were not run (a plan interdict). The generated tree was inferred from the maker's source, not observed.
- **The full suite:** not rerun. I relied on the `po-run` record (exit 0, gate current).

## Verdict
No critical finding. The profiles agree with their sources at the named commits, the lint passes, and the tests bite. F1 should be handled in a later cycle.

Max severity: major
Ship allowed: yes
