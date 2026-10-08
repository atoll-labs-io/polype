---
track: flow
validated: yes
---
# Plan (short track) — s85-native-profiles

Short track: this file stands in for the research. Validated autonomously (`Plan validation: autonomous`): no human reviewed it. Sources, commits, commands and the `—` driver are settled in `docs/decisions/ADR-0064-profils-natifs-depuis-ios-templates-de-nimble-et-architecture-templates-d-android.md` (written by the planner, uncommitted, `accepted`: commit it with the code, never edit its body).

`IOS:` = `https://github.com/nimblehq/ios-templates` at `f009d02ebaacf3c789c84bd31d9baa2b2447d654` (branch `develop`, the default, 2026-06-22). `T:` = `IOS:template/`. `AND:` = `https://github.com/android/architecture-templates` at `5467a8dcca30a81b4e31fda5863dd6c65836de0d` (branch `base`, 2026-10-05). Both opened in shallow clones under `/tmp` on 2026-10-08. No JDK, Android SDK or Xcode on this machine: no command below was run.

## Verified facts
**Story precisions first.**
1. *"leur QA d'écran est `blocked`"* — no `QA status: blocked` report gets written. With `Dev: —`, the qa subagent stops on a `screen` story before any walk and writes nothing (`method/agents/qa.md:31`); the driver then stops the lane with that reason (`method/commands/po-drive.md:96`). The routing table still sends `screen` + `mobile` to `mobile-web.md` (`method/skills/qa-drivers/SKILL.md:13`), which needs `Dev` (`mobile-web.md:6`). The profile prose must say "blocked" in that sense and never promise a report.
2. *"a public starter template at a named commit"* — for iOS it is a generator, not a clone: `iOSTemplateMaker` renames `{PROJECT_NAME}` dirs (`IOS:scripts/iOSTemplateMaker/Sources/iOSTemplateMaker/SetUpiOSProject.swift:194-199`), moves `T:Tuist/Interfaces/SwiftUI/Sources/` into `<Name>/Sources/` (`:63-69`), runs `tuist generate` (`:225`), deletes `Tuist/` and `Project.swift` (`:252-253`), promotes `template/` to the root with overwrite, deletes `scripts`, `.github`, `.git/index`, runs `git reset` (`:256-270`), then deletes root `AGENTS.md` and `CLAUDE.md` (`:272-275`). It uses BSD `sed -i ""` (`:245`) and `open -a Xcode` (`:289`): macOS only. For Android, `AND:customizer.sh` renames the `android.template` package and `MyModel` (`:38-84`) and deletes `LICENSE`, `README.md`, `.github/`, `customizer.sh` and `.git/` (`:87-92`).

Polype side:
- Profile format: ten `## ` headings (`method/templates/profile.md:5-74`); a `Test` must accept paths (`:35`). `bin/po-lint` `check_profiles` (`bin/po-lint:184-305`) accepts `- QA driver: —` (`:289`); `mobile` is a `Platform` value (`method/templates/agents-local.md:53`).
- Precedent for a `Test` that takes no paths, stated in prose: `boilerplates/rust-cli/profile.md` `## Commands`. Precedent test shape: `tests/flutter-profile.test.sh`, `tests/cli-api-profiles.test.sh` (lint + mutant, grounding with env override and loud skip).

`IOS:` facts:
- `IOS:LICENSE:1` `MIT License`. README: SwiftUI, Tuist `4.110.3`, SPM, Factory DI, Quick + Nimble, KIF UI tests, SwiftLint/SwiftFormat/Danger, Arkana secrets, four configurations (`IOS:README.md:14-36`); generate with `swift run --package-path scripts/iOSTemplateMaker iOSTemplateMaker make …` (`:48-53`). Requires Ruby 3.2+, Xcode 26+, Swift 6.1+, mise (`:20-23`); `T:.mise.toml:5-8` pins ruby, tuist, xcbeautify.
- Generated layout (from `T:AGENTS.md:26-32` and the tree): `Modules/Domain/`, `Modules/Data/`, `Modules/Model/`, `Modules/Analytics/` (each `Sources/` + `Tests/`), `{PROJECT_NAME}/` (app; `Sources/` filled from `T:Tuist/Interfaces/SwiftUI/Sources/`: `Application/`, `Presentation/Coordinators/`, `Presentation/Modules/{Landing,Home,Settings,SignOut,ForceUpdate}/`), `{PROJECT_NAME}Tests/`, `{PROJECT_NAME}KIFUITests/`, `{PROJECT_NAME}.xctestplan`, `fastlane/`, `Package.swift`, `.swiftlint.yml`, `.env.example`, `.arkana.yml`.
- Rules: Domain holds interfaces and use cases (`T:Modules/Domain/Sources/{Interfaces,UseCases}/`), Data implements them (`T:Modules/Data/Sources/Repositories/`, `NetworkAPI/`); "Domain interface first, then Data, then App" (`T:AGENTS.md:93`).
- Capabilities seen: Auth — token refresh (`T:Modules/Data/Sources/NetworkAPI/Authentication/`, `Repositories/AuthRepository.swift`, keychain in `Managers/KeychainManager/`); Observability — `Modules/Analytics/` with a console tracker (`T:Tuist/Interfaces/SwiftUI/Sources/Application/App.swift:11-12`); Firebase SDK (`T:Package.swift:26`) and `GoogleService-Info.plist` per environment.
- Commands: `T:AGENTS.md:44-45` documents `swiftlint` and `bundle exec fastlane buildAndTest`; that lane runs `scan` on `Constant.devices = ["iPhone 15 Pro"]` (`T:fastlane/Constants/Constant.swift:93`) with `failBuild: .userDefined(false)` (`T:fastlane/Helpers/Test.swift:33`) — a failing test does not fail the exit code. `onlyTesting` takes test identifiers, not paths (`Test.swift:13,27`). Every build lane signs through `match` (`T:AGENTS.md:61`). Install: `bundle install`, `bundle exec arkana` (`SetUpiOSProject.swift:238-239`).
- Trap: `T:README.md:18-20` tells the generated project to run `tuist generate`, but the maker has deleted `Tuist/` and `Project.swift`.

`AND:` facts:
- `AND:LICENSE:1-2` Apache License 2.0; `AND:README.md:40` wrongly says "Now in Android is distributed". Features: Room, Hilt, ViewModel, Compose Material3, Navigation, repository, coroutines/Flow, unit tests, Hilt UI tests (`AND:README.md:11-19`); clone `--branch base`, run `./customizer.sh your.package.name DataItemType [MyApplication]` (`:26-33`); the script needs bash 4 (`customizer.sh:19-23`) and GNU-style `sed -i.bak`.
- Single module `:app` (`AND:settings.gradle.kts:31-33`); Gradle `9.8.0` wrapper (`AND:gradle/wrapper/gradle-wrapper.properties:3`); AGP `9.4.1`, Kotlin `2.4.20`, Compose BOM `2026.09.00`, Room `2.8.5`, Hilt `2.60.1`, Navigation 3 `1.2.0` (`AND:gradle/libs.versions.toml:2-17`); compileSdk/targetSdk 37, minSdk 24, runner `android.template.HiltTestRunner` (`AND:app/build.gradle.kts:27-36`); Room schemas to `$projectDir/schemas` (`:63-65`).
- Code: `app/src/main/java/android/template/` — `data/` (`MyModelRepository.kt:25-41`, `data/local/database/AppDatabase.kt:22`, `data/di/`), `ui/` (`MainActivity.kt`, `Navigation.kt:30-46`, `ui/mymodel/MyModelScreen.kt:42-81`, `MyModelViewModel.kt:34-55`, `ui/theme/`); unit tests `app/src/test/java/android/template/{data,ui}/`; instrumented `app/src/androidTest/java/android/template/`.
- CI (`AND:.github/workflows/build_and_local_tests.yml:16-30`): JDK 17, `./gradlew assembleDebug`, `./gradlew testDebug`. Instrumented tests need a device or emulator (`instrumented_tests.yml`).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: two markdown profiles and a test | absent — `boilerplates/` holds markdown only |
| New screen | absent — `Surface : —` | absent — profiles and a bash test, no UI in the diff |
| Authorization or tenant scope | absent — story text | absent — the profiles describe third-party auth code; Polype's rules are untouched |
| API contract | absent — story text | absent — `bin/po-lint`, `method/templates/profile.md`, `qa-drivers` stay untouched; `—` is already accepted (`bin/po-lint:289`) |
| New dependency | absent — story text | absent — the test uses `git`, `grep`, `awk`, `sed`, like `tests/cli-api-profiles.test.sh` |

Tasks: 5.

## Story
A developer gets an iOS (Swift) profile and an Android (Kotlin) profile, so a native project starts from verified facts even though its QA has no web render.
- `native_profiles_pass_the_lint` — both profiles follow the template, each from a public, libre-licensed starter at a named commit; `bin/po-lint` accepts them.
- `native_profiles_say_what_qa_cannot_do` — platform `mobile`; each says the web driver does not apply, that the iOS simulator needs a Mac and the Android emulator a later batch, and so their screen QA is `blocked` until then.

## Tasks
1. [x] **Shallow clones** into a `mktemp -d` outside the repository: `IOS:` and `AND:` at the commits above (`git clone --depth 1` then `fetch --depth 1 origin <commit>`, `checkout`). Re-open every fact above you rely on; nothing of the clones enters the repository. Test able to fail: task 4's grounding test.
2. [x] **`boilerplates/native-ios/profile.md`**, English, own words, the ten headings verbatim and in order.
   - Identity: `- Name: Nimble iOS template (iOSTemplateMaker)`, `- Origin: https://github.com/nimblehq/ios-templates`, `- Licence: MIT`, `- Commit profiled: f009d02ebaacf3c789c84bd31d9baa2b2447d654`; then: branch `develop`; a generator, not a clone; every path below is a path of the generated project, `{PROJECT_NAME}` standing for the name given to the maker.
   - `- Platform: mobile`, `- QA driver: —`, then the paragraph of the pivot (iOS wording).
   - Fence: `Install: bundle install && bundle exec arkana`, `Test: bundle exec fastlane buildAndTest`, `Typecheck: —`, `E2E: —`, `Build: —`, `Dev: —`. Prose: all need a Mac with Xcode and `mise install` first; `Test` takes no paths (focus is by test identifier) and its `scan` runs with `failBuild` false, so a red test exits 0 until a story sets it true in `fastlane/Helpers/Test.swift`; KIF UI tests run inside the test plan; Swift has no type check apart from compiling, done by `Test`; build lanes sign through `match`, hence `Build: —`; `Dev: —`, nothing is served.
   - Code map: `Modules/Domain/`, `Modules/Data/`, `Modules/Model/`, `Modules/Analytics/`, `{PROJECT_NAME}/`, `{PROJECT_NAME}Tests/`, `{PROJECT_NAME}KIFUITests/`, `fastlane/`, `Package.swift`, each in backticks. Ownership: a story owns a `{PROJECT_NAME}/Sources/Presentation/Modules/<screen>/` plus its tests; `Package.swift`, `fastlane/`, `Modules/Domain/Sources/Interfaces/`, configurations run alone. Rules: Domain interfaces/use cases, Data implementations, App composition. Capabilities: only rows from the template's list that the code shows (Auth, Observability; nothing for the rest). UI inventory: SwiftUI views of `Presentation/Modules/`. Traps: the maker deletes root `AGENTS.md`/`CLAUDE.md`, `scripts`, `.github`, the git index — generate in a scratch clone, copy in; macOS-only maker; stale `tuist generate` in the generated README; `failBuild` false; `.env` from `.env.example` feeds Arkana; `GoogleService-Info.plist` per environment; `NimbleExtension` tracks `master` (`T:Package.swift:27`).
3. [x] **`boilerplates/native-android/profile.md`**, same rules.
   - Identity: `- Name: Android architecture template (base)`, `- Origin: https://github.com/android/architecture-templates`, `- Licence: Apache-2.0`, `- Commit profiled: 5467a8dcca30a81b4e31fda5863dd6c65836de0d`; branch `base`; paths are those before `customizer.sh`, which renames `android/template` and `MyModel`.
   - `- Platform: mobile`, `- QA driver: —`, the pivot paragraph (Android wording).
   - Fence: `Install: —`, `Test: ./gradlew testDebugUnitTest`, `Typecheck: ./gradlew compileDebugUnitTestKotlin compileDebugAndroidTestKotlin`, `E2E: —`, `Build: ./gradlew assembleDebug`, `Dev: —`. Prose: JDK 17 and the Android SDK; Gradle resolves on first task; `Test` takes no paths, focus is `--tests '<class pattern>'`; instrumented tests (`./gradlew connectedDebugAndroidTest`) need a device or emulator, hence `E2E: —`.
   - Code map: `app/src/main/java/android/template/data/`, `.../ui/`, `app/src/test/java/android/template/`, `app/src/androidTest/java/android/template/`, `gradle/libs.versions.toml`, `app/build.gradle.kts`, `settings.gradle.kts`, `customizer.sh`. Ownership: a story owns a `ui/<feature>/` with its data and tests; `app/build.gradle.kts`, `gradle/libs.versions.toml`, `AppDatabase.kt`, `MainActivity.kt`, `ui/Navigation.kt` run alone. Capabilities: Database (Room). UI inventory: Compose Material3 theme in `ui/theme/`, `MyModelScreen` (text field, Save button, list). Traps: customizer deletes `.git/` and `LICENSE`; bash 4 + GNU sed; README's wrong licence line; Room schema export dir; Hilt test runner.
4. [x] **`tests/native-profiles.test.sh`**, header `# s85 — the native-ios and native-android profiles: lint, what QA cannot do, grounding in their starters.` Helpers as in `tests/cli-api-profiles.test.sh`. Three functions:
   - `test_native_profiles_pass_the_lint` — both `require_file`; `po-lint` exits 0; exact `Origin`, `Licence` (`MIT`, `Apache-2.0`), 40-hex `Commit profiled`. Mutant: a `mktemp -d` copy with `## Known traps` deleted from both; `po-lint` exits non-zero and names both files.
   - `test_native_profiles_say_what_qa_cannot_do` — each: exact lines `- Platform: mobile` and `- QA driver: —`; Commands fence `Dev:` value `—`; `## QA driver` section contains `mobile-web`, `does not apply` and `` `blocked` ``; iOS section contains `needs a Mac`, Android section `later batch`.
   - `test_native_profiles_are_grounded_in_their_sources` — sources `$NATIVE_IOS_SRC` / `$NATIVE_ANDROID_SRC` when set, else clones at `Commit profiled`; unreachable → stderr `(… not reachable: grounding not checked)`, skip that half. `HEAD` equals `Commit profiled`; licence (`^MIT License` / `Apache License` + `Version 2.0`). iOS tokens `^(Modules|\{PROJECT_NAME\}[A-Za-z]*|fastlane)/|^(Package\.swift|\.swiftlint\.yml|\.env\.example)$` resolve under `T:` as is, or `{PROJECT_NAME}/Sources/X` under `T:Tuist/Interfaces/SwiftUI/Sources/X`; at least 6. Android tokens `^(app|gradle)/|^(settings\.gradle\.kts|build\.gradle\.kts|customizer\.sh|gradlew)$` resolve under the root; at least 6. One mutant per side with a made-up path (`Modules/Payments/`, `app/src/main/java/android/template/billing/`) must be reported.
   Run `bash tests/run.sh native-profiles.test.sh profile.test.sh lint.test.sh`.
5. [x] **Closing checks**, once: `bin/po-lint` clean, then the full suite through `po-run` as `/po-execute` says. Delete task 1's clones.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/`, `bin/`, `boilerplates/` outside the two new directories, every existing `tests/*.test.sh`, `docs/stories.md`, `docs/parite-killer-saas.md`, `README.md`, `.claude/`, `.polype/`.
- `git diff --stat main...` lists only the two profiles, the test, ADR-0064 and this story's `docs/` files; no file of `IOS:`/`AND:` in the repository; no clone inside the worktree; `iOSTemplateMaker` and `customizer.sh` never run.
- No `## ` heading beyond the template's; no capability row outside its list; no profile claims a `QA status: blocked` report or a simulator/emulator driver that exists.
- ADR-0064 committed as written; no other ADR.

## The pivot
**Both profiles declare `- QA driver: —` and `Dev: —`, and their `## QA driver` section carries this paragraph (wording fixed, quoted by the test):** "The `mobile-web` driver does not apply: this app has no web render, so `Dev` is `—`. Its screens show only in the iOS simulator, which needs a Mac with Xcode, and no Polype driver runs it yet." — Android: "…only on an Android emulator or device; an emulator driver is planned for a later batch." — both: "Until then the screen QA of a story on this profile is `blocked`: the qa subagent stops before any walk, writes no report, and the lane waits for a human."
How it could be wrong:
- The table of `qa-drivers` still routes `screen` + `mobile` to `mobile-web`; the profile does not change routing, the absent `Dev` does. A project mixing `web` and `mobile` with a `Dev` would still get a web walk; out of scope (`Owns`).
- iOS `Test` exits 0 on red tests (`failBuild` false). Choosing it over a hand-written `xcodebuild` follows the template's own documentation (ADR-0064); a reviewer may prefer flagging it harder — it is the first trap.
- Android `Typecheck` task names under AGP 9 built-in Kotlin were not run here; if they differ, the implementer writes `—` with a sentence rather than invent another task.

## Files touched
`boilerplates/native-ios/profile.md`, `boilerplates/native-android/profile.md`, `tests/native-profiles.test.sh` (new); `docs/decisions/ADR-0064-…md` (planner); this plan; `docs/verif/s85-native-profiles.md`.

## Test strategy
3 tests of 25, at the only layer there is: the documents, checked by the lint and against their sources.
- `native_profiles_pass_the_lint` — fails on a template breach or wrong identity; the mutant proves the lint reads both files.
- `native_profiles_say_what_qa_cannot_do` — fails if the platform, the `—` driver, `Dev: —` or a clause of the pivot paragraph goes.
- `native_profiles_are_grounded_in_their_sources` — fails on a wrong commit, licence or path; mutants prove the checker bites. Network-dependent, skips loudly.
Existing profile tests stay unchanged and green.

## Done when
Profiles, test, ADR-0064, this plan and the record in one commit on `story/s85-native-profiles`; `bin/po-lint` clean; full suite green through `po-run`; review with no open critical; squash on `main`.
