# Profile — flutter

## Identity and licence

- Name: Flutter app template (flutter create)
- Origin: https://github.com/flutter/flutter
- Licence: BSD-3-Clause
- Commit profiled: 5fc346839b5d0eef006ed8404392afb4dfae428d

Tag `3.47.6` of the stable branch, commit dated 2026-09-30. This is a template, not a repository: the sources are mustache files in `packages/flutter_tools/templates/app/` and `packages/flutter_tools/templates/app_test_widget/`, and the project is produced by running `flutter create <name>` with Flutter `3.47.6`, with no option. Every path below is a path of the generated project, not of the template.

## Platform

- Platform: mobile

## QA driver

- QA driver: mobile-web

## Commands

```
Install:           flutter pub get
Test:              flutter test
Typecheck:         flutter analyze
E2E:               —
Build:             flutter build web
Dev:               flutter run -d web-server
```

`flutter test` takes test file paths, for example `flutter test test/widget_test.dart`, and runs every `_test.dart` file under `test/` when given none. `flutter analyze` also enforces the `flutter_lints` rule set, and an info-level finding fails the run.

`Dev` serves the web render of the app on a free port and prints a line such as `lib/main.dart is being served at http://localhost:<port>`; that origin is what the driver reads. The `web-server` device opens no browser. The process stays resident until it is stopped.

`Build` is the web build, which runs wherever `Dev` runs. The native builds (`flutter build apk`, `flutter build ipa`) need the Android SDK or a Mac and are not the profile's `Build`. No end-to-end test ships: `integration_test` is not part of the generated app.

## Code map

- `lib/` — the application code; one file, `lib/main.dart`.
- `test/` — one widget test, `test/widget_test.dart`.
- `web/` — the web host page, manifest and icons.
- `android/` — the Android project.
- `ios/` — the iOS project.
- `linux/`, `macos/`, `windows/` — desktop projects, generated only when the platform is enabled on the machine that runs `flutter create`.
- `pubspec.yaml` — package manifest and dependencies.
- `analysis_options.yaml` — analyzer configuration, built on `flutter_lints`.

## Ownership granularity

The app is a single file, `lib/main.dart`, so every story touches it until a first story splits it. After that a story owns a new `lib/<feature>/` together with its `test/<feature>/`. These paths are shared, and a story touching any of them runs alone: `pubspec.yaml`, `lib/main.dart` and the platform directories (`android/`, `ios/`, `web/` and the desktop ones).

## Where each rule lives

The template ships widgets and nothing else, all in `lib/main.dart`: no validation, no access rule, no tenant filter. A story puts its rules under `lib/<feature>/`, outside the widgets, so that they can be tested without a screen.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |

The template provides none of the capabilities of the list.

## UI inventory

A Material 3 `MaterialApp` with a `ColorScheme` seeded from one colour, a `Scaffold` with an `AppBar`, a `FloatingActionButton` that increments a counter, and the `cupertino_icons` package. All of it sits in `lib/main.dart`.

## Known traps

- The profile describes a template, not a repository: there is nothing to clone, and the boilerplate is brought in by installing Flutter `3.47.6` and running `flutter create <name>`.
- Flutter draws on a canvas. Controls appear in the page structure only once accessibility semantics are on, through the `flt-semantics-placeholder` element, so the driver may need to activate it before measuring boxes; report the sizes it measured.
- A `--base-href` given to the web build must start and end with `/`.
- `flutter analyze` fails on infos as well as warnings.
- `.idea/` and `*.iml` files are generated although the generated `.gitignore` ignores them.
- The desktop directories exist only for the platforms enabled when `flutter create` ran.
- The first `Dev` start compiles the app and can take a while before it prints its address.
- `Dev` never exits on its own: stop it when the check is done.
- Image assets of the template come from the `flutter_template_images` package, not from the Flutter repository.
