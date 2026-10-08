# Profile — native-android

## Identity and licence

- Name: Android architecture template (base)
- Origin: https://github.com/android/architecture-templates
- Licence: Apache-2.0
- Commit profiled: 5467a8dcca30a81b4e31fda5863dd6c65836de0d

Branch `base`, commit dated 2026-10-05. The project is a clone of that branch on which `customizer.sh` is run once: it renames the `android.template` package and the `MyModel` example. The paths below are those before the script ran, and `android/template` in them stands for the package you give it.

## Platform

- Platform: mobile

## QA driver

- QA driver: —

The `mobile-web` driver does not apply: this app has no web render, so `Dev` is `—`. Its screens show only on an Android emulator or device; an emulator driver is planned for a later batch.

Until then the screen QA of a story on this profile is `blocked`: the qa subagent stops before any walk, writes no report, and the lane waits for a human.

## Commands

```
Install:           —
Test:              ./gradlew testDebugUnitTest
Typecheck:         ./gradlew compileDebugUnitTestKotlin compileDebugAndroidTestKotlin
E2E:               —
Build:             ./gradlew assembleDebug
Dev:               —
```

A JDK 17 and the Android SDK must be installed. The Gradle wrapper downloads Gradle on the first task, which is why `Install` is `—`.

`Test` takes no paths: it runs every local unit test, and a focus is given with `--tests '<class pattern>'`. `Typecheck` compiles the Kotlin of the unit tests and of the instrumented tests without running them; these task names were not run when the profile was written, so a project whose Android Gradle Plugin names them differently corrects them. The instrumented tests, `./gradlew connectedDebugAndroidTest`, need a device or an emulator, hence `E2E: —`. Nothing is served, hence `Dev: —`.

## Code map

- `app/src/main/java/android/template/data/` — the repository, the Room database and the dependency injection modules.
- `app/src/main/java/android/template/ui/` — the activity, the navigation, the Compose screens and the theme.
- `app/src/test/java/android/template/` — local unit tests.
- `app/src/androidTest/java/android/template/` — instrumented tests, with the Hilt test runner.
- `gradle/libs.versions.toml` — the version catalog.
- `app/build.gradle.kts` — the single module's build.
- `settings.gradle.kts` — the project settings; one module, `:app`.
- `customizer.sh` — the one-shot renaming script.

## Ownership granularity

A story owns one feature directory, `app/src/main/java/android/template/ui/<feature>/`, and its tests. The repository and the Room entity live in `app/src/main/java/android/template/data/`, outside that directory, and a story that changes them names those files in its `Owns`. These paths are shared, and a story touching any of them runs alone: `app/build.gradle.kts`, `gradle/libs.versions.toml`, `app/src/main/java/android/template/data/local/database/AppDatabase.kt`, `app/src/main/java/android/template/ui/MainActivity.kt` and `app/src/main/java/android/template/ui/Navigation.kt`.

## Where each rule lives

The template has no separate domain layer. Data access and the rules around it sit in the repository of `app/src/main/java/android/template/data/`, and each screen has a view model in its `ui/<feature>/` directory that calls the repository. A story puts a rule in the repository or the view model, so that a local unit test can reach it without a screen.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |
| Database | Room | schemas exported to a `schemas` directory of the module |

## UI inventory

A Compose Material 3 theme in `app/src/main/java/android/template/ui/theme/`, and one example screen, `MyModelScreen`, made of a text field, a Save button and a list. Navigation goes through `Navigation.kt`.

## Known traps

- `customizer.sh` deletes `.google/`, `.github/`, `CONTRIBUTING.md`, `LICENSE`, `README.md`, the `.git/` directory and itself, plus every `*.bak` file and the old `android/template` package directories: run it on a fresh clone, then initialise git again.
- The script needs bash 4 and GNU-style `sed -i.bak`; the default bash and `sed` of macOS do not work.
- The README names another project as the one distributed; the licence is Apache-2.0, the text of `LICENSE` decides.
- Room exports its schema to a `schemas` directory of the module (set in `app/build.gradle.kts`): it appears after the first build.
- The instrumented tests run with `HiltTestRunner`, set in `app/build.gradle.kts`; a renamed package must rename it there too.
- The first Gradle task downloads the wrapper and every dependency, and can take a while.
