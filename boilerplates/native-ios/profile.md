# Profile — native-ios

## Identity and licence

- Name: Nimble iOS template (iOSTemplateMaker)
- Origin: https://github.com/nimblehq/ios-templates
- Licence: MIT
- Commit profiled: f009d02ebaacf3c789c84bd31d9baa2b2447d654

Branch `develop`, the default one, commit dated 2026-06-22. This is a generator, not a clone: the project is produced by running `iOSTemplateMaker` (a Swift package in the repository, under `scripts/`) with a project name, and `{PROJECT_NAME}` below stands for that name. Every path below is a path of the generated project, not of the repository. The maker is macOS only.

## Platform

- Platform: mobile

## QA driver

- QA driver: —

The `mobile-web` driver does not apply: this app has no web render, so `Dev` is `—`. Its screens show only in the iOS simulator, which needs a Mac with Xcode, and no Polype driver runs it yet.

Until then the screen QA of a story on this profile is `blocked`: the qa subagent stops before any walk, writes no report, and the lane waits for a human.

## Commands

```
Install:           bundle install && bundle exec arkana
Test:              rm -rf fastlane/test_output && bundle exec fastlane buildAndTest && xcrun xcresulttool get test-results summary --path fastlane/test_output/*.xcresult | grep -Eq '"result" *: *"Passed"'
Typecheck:         —
E2E:               —
Build:             —
Dev:               —
```

Every command needs a Mac with Xcode, and `mise install` run first, so that Ruby and Tuist match the versions `.mise.toml` pins; xcbeautify is `latest` there, not pinned.

`Test` takes no paths: the lane runs the whole test plan on a simulator, and a focus is given by test identifier, not by file. The lane runs `scan` with `failBuild` set to false in `fastlane/Helpers/Test.swift`, so the lane alone exits 0 on a red test. `Test` therefore empties the ignored test output folder, runs the lane, then reads the result bundle with `xcresulttool` and exits non-zero unless its summary says `Passed` (ADR-0069). This command was not run on a Mac. The KIF UI tests are part of the test plan. Swift has no type check apart from compiling, which `Test` does, hence `Typecheck: —`.

The build lanes sign through `match`, which needs the team's certificates repository, hence `Build: —`. Nothing is served, hence `Dev: —`. `swiftlint` is the linter the template documents; it is not a profile command.

## Code map

- `Modules/Domain/` — entities, interfaces and use cases; no framework code.
- `Modules/Data/` — implementations of the Domain interfaces: network API, repositories, storage managers, remote config.
- `Modules/Model/` — shared models.
- `Modules/Analytics/` — the analytics trackers.
- `{PROJECT_NAME}/` — the app target: `Sources/` holds the application entry point, the coordinators and the SwiftUI screens.
- `{PROJECT_NAME}Tests/` — unit tests of the app target.
- `{PROJECT_NAME}KIFUITests/` — UI tests written with KIF.
- `fastlane/` — the lanes, written in Swift.
- `Package.swift` — the Swift Package Manager dependencies.

Each of the four modules carries its own `Sources/` and `Tests/`.

## Ownership granularity

A story owns one screen directory of the app target, `{PROJECT_NAME}/Sources/Presentation/Modules/<screen>/`, with its tests. These paths are shared, and a story touching any of them runs alone: `Package.swift`, `fastlane/`, `Modules/Domain/Sources/Interfaces/` and the build configurations.

## Where each rule lives

Business rules sit in the use cases of `Modules/Domain/Sources/UseCases/`, behind the interfaces of `Modules/Domain/Sources/Interfaces/`. Data access, token handling and storage are in `Modules/Data/`, which implements those interfaces. The app target only composes and displays. The template's own rule is the order: a Domain interface first, then its Data implementation, then the app wiring.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |
| Auth | token refresh in `Modules/Data/Sources/NetworkAPI/`, keychain storage | no sign-in screen logic beyond what the code shows |
| Observability | `Modules/Analytics/` | a console tracker by default |

## UI inventory

SwiftUI screens under `{PROJECT_NAME}/Sources/Presentation/Modules/`: Landing, Home, Settings, SignOut and ForceUpdate, driven by coordinators in `{PROJECT_NAME}/Sources/Presentation/Coordinators/`. A design reuses them before drawing new ones.

## Known traps

- The maker deletes the root `AGENTS.md` and `CLAUDE.md`, `scripts`, `.github` and the git index while it generates. Generate in a scratch directory and copy the result into the project.
- The maker is macOS only and uses BSD `sed` and `open -a Xcode`.
- The README of the generated project still tells to run `tuist generate`, although the maker has already run it and deleted `Tuist/` and `Project.swift`.
- `failBuild` is false in the test lane, so the lane alone exits 0 on a red test; `Test` reads the result bundle after it, so never shorten it to the lane (ADR-0069).
- `.env` is copied from `.env.example` and feeds Arkana, which generates the secrets code; run `bundle exec arkana` again after changing it.
- A `GoogleService-Info.plist` is expected per environment for the Firebase SDK.
- `NimbleExtension` is pinned to the `master` branch in `Package.swift`, so a resolve is not reproducible.
