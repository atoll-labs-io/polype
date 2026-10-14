---
track: flow
validated: yes
---
# Plan (short track) — s84-flutter-profile

[Story](../stories.md)

Short track: this file stands in for the research. Validated autonomously (`Plan validation: autonomous`): no human reviewed it. The source, commit and the `Dev`/`Build` commands are settled in `docs/decisions/ADR-0063-profil-flutter-depuis-le-gabarit-app-de-flutter-create.md` (written by the planner, uncommitted, `accepted`: commit it with the code, never edit its body).

`FL:` = `https://github.com/flutter/flutter` at `5fc346839b5d0eef006ed8404392afb4dfae428d` (tag `3.47.6`, branch `stable`, 2026-09-30). `T:` = `FL:packages/flutter_tools/templates/`. Opened in a sparse clone outside the repository on 2026-10-08.

## Verified facts
**Assumption corrected first.** The story speaks of writing the profile "from the official Flutter app template at a named commit" as if it were a starter repository. It is not: the template is a set of mustache `.tmpl` files inside `FL:`, assembled by `flutter create`. `flutter create <name>` (no `--empty`, no `--sample`) composes `T:app` and `T:app_test_widget` (`FL:packages/flutter_tools/lib/src/commands/create.dart:497`). Suffixes `.tmpl`, `.copy.tmpl`, `.img.tmpl` and `<platform>-<language>.tmpl` directories are stripped on output (`FL:packages/flutter_tools/lib/src/template.dart:69-85,198-202`). So the profile describes the **generated** tree, "bringing the boilerplate in" means installing Flutter `3.47.6` and running `flutter create`, and a grounding test must map generated paths back to `.tmpl` paths. No `skeleton` template exists at this commit. Licence: `FL:LICENSE` is BSD-3-Clause (`Copyright 2014 The Flutter Authors`).

Polype side:
- Profile format: ten `## ` headings (`method/templates/profile.md:5-74`); `A Test command must accept paths` and `Dev … prints the address it serves` (`profile.md:35`).
- `bin/po-lint` `check_profiles` (`bin/po-lint:193-301`): headings, fence names, platform among `web · mobile · …` (`method/templates/agents-local.md:53`), driver a file of `method/skills/qa-drivers/` — `mobile-web.md` exists.
- `mobile-web` needs `Dev` serving the web render (`method/skills/qa-drivers/mobile-web.md:6`), started in the background, reading the origin it prints, else `blocked` (`mobile-web.md:12`); it measures each control's box for touch targets (`mobile-web.md:19`).
- `/po-setup` copies a profile's fence verbatim and tells the person to bring the boilerplate in at `Commit profiled` (`method/commands/po-setup.md:43,55`).
- Precedent: `boilerplates/rust-cli/profile.md`, `tests/cli-api-profiles.test.sh` (lint + mutant, grounding with env override and loud skip), plan `docs/plans/s86-cli-api-profiles.md`. Each test file runs in its own process (`tests/run.sh:17`).

`FL:` facts:
- `T:app/pubspec.yaml.tmpl`: `publish_to: 'none'` (`:25`), `version: 1.0.0+1` (`:40`), deps `flutter` sdk + `cupertino_icons: ^1.0.8` (`:68`), dev `flutter_test` + `flutter_lints: ^6.0.0` (`:83`), `uses-material-design: true` (`:94`).
- `T:app/lib/main.dart.tmpl` (271 lines): `MyApp` (`:37`) a `MaterialApp` with a seeded `ColorScheme`; `MyHomePage` stateful counter (`:68`, `:86`) with `Scaffold`/`AppBar` (`:108-109`) and a `FloatingActionButton`. All in one file.
- `T:app_test_widget/test/widget_test.dart.tmpl:15` — one `testWidgets` counter smoke test importing `package:<name>/main.dart`.
- `T:app/analysis_options.yaml.tmpl:12` includes `package:flutter_lints/flutter.yaml`, excludes `build/**` and platform dirs.
- `flutter test` takes paths (`argResults!.rest`, `FL:…/commands/test.dart:362`), else all of `test/` ending `_test.dart` (`test.dart:46-47`).
- `flutter analyze`: `--fatal-infos` and `--fatal-warnings` default to true (`FL:…/commands/analyze.dart:118-122`) — a lint info fails the run.
- `web-server` device: selectable with `-d web-server` (`FL:…/runner/flutter_command_runner.dart:410-414`), needs `web/` (`FL:…/web/web_device.dart` `isSupportedForProject`), prints `<mainPath> is being served at <url>` (`web_device.dart:454`). `--web-port` absent → a free port (`FL:…/runner/flutter_command.dart:296-301`); host defaults to `any`, printed as `localhost` (`FL:…/web/devfs_config.dart:21`, `FL:…/isolated/web_asset_server.dart:291`).
- `flutter create` default platforms `ios android windows linux macos web` (`FL:…/commands/create_base.dart:21,110`); desktop dirs are skipped when not enabled (`template.dart:261-271`).
- `T:app/web/index.html.tmpl:17` has `<base href="$FLUTTER_BASE_HREF">`, filled by `--base-href`.
- Web rendering draws on a canvas; DOM nodes for controls appear only once semantics are on, via a `flt-semantics-placeholder` element (`FL:engine/src/flutter/lib/web_ui/lib/src/engine/semantics/semantics_helper.dart:187`).
- `T:app/.gitignore.tmpl:16-19` ignores `*.iml` and `.idea/` although `T:app/projectName.iml.tmpl` and `T:app/.idea/` are generated; `.dart_tool/`, `/build/` ignored (`:29,33`). `.img.tmpl` icons come from the `flutter_template_images` package (`T:template_manifest.json:3`).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: one markdown profile and a test | absent — `boilerplates/` holds markdown only; no schema in Polype |
| New screen | absent — `Surface : —` | absent — a profile and a bash test, no UI in the diff |
| Authorization or tenant scope | absent — story text | absent — the template has no access or tenant code (`T:app/lib/main.dart.tmpl`) |
| API contract | absent — story text | absent — `bin/po-lint`, `method/templates/profile.md` and `mobile-web.md` stay untouched |
| New dependency | absent — story text | absent — the test uses `git`, `grep`, `awk`, `sed`, as `tests/cli-api-profiles.test.sh` does |

Tasks: 4. No story Surface, no QA stage.

## Story
A developer gets a Flutter boilerplate profile, so `/po-setup` and `/po-architect` start from verified facts.
- `flutter_profile_passes_the_lint` — `boilerplates/flutter/profile.md` follows the template, written from Flutter's official app template at a named commit, under its licence; `bin/po-lint` accepts it.
- `flutter_profile_names_its_web_render` — platform `mobile`, driver `mobile-web`, `Dev` serves the web render (`flutter run -d web-server` or equivalent), `Test` accepts paths.

## Tasks
1. [x] **Sparse clone** into a `mktemp -d` outside the repository: `git init`, `git fetch --depth 1 --filter=blob:none origin <commit>`, sparse `/LICENSE`, `/packages/flutter_tools/templates/app/`, `/packages/flutter_tools/templates/app_test_widget/` (about 2 s, 4 MB). Re-open any fact above you rely on; nothing of the clone enters the repository. Test able to fail: task 3's grounding test.
2. [x] **`boilerplates/flutter/profile.md`**, English, own words, the template's ten `## ` headings verbatim and in order, no other.
   - Identity: `- Name: Flutter app template (flutter create)`, `- Origin: https://github.com/flutter/flutter`, `- Licence: BSD-3-Clause`, `- Commit profiled: 5fc346839b5d0eef006ed8404392afb4dfae428d`. Then: tag `3.47.6`, 2026-09-30; the templates are `packages/flutter_tools/templates/app/` and `app_test_widget/`; the project is produced by `flutter create <name>` with Flutter `3.47.6`, not cloned; every path below is a generated path.
   - `- Platform: mobile`, `- QA driver: mobile-web`.
   - Fence: `Install: flutter pub get`, `Test: flutter test`, `Typecheck: flutter analyze`, `E2E: —`, `Build: flutter build web`, `Dev: flutter run -d web-server`. Under it: `flutter test` takes test file paths, all of `test/` otherwise; `flutter analyze` also enforces `flutter_lints` with infos fatal; `Dev` serves the web render on a free port and prints `lib/main.dart is being served at http://localhost:<port>`, the origin the driver reads, no browser opened; native builds (`flutter build apk`, `flutter build ipa`) need the Android SDK or a Mac and are not the profile's `Build`; no end-to-end test ships (`integration_test` is added only for plugin examples).
   - Code map: `lib/`, `test/`, `web/`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `pubspec.yaml`, `analysis_options.yaml`, each in backticks; desktop dirs only when enabled.
   - Ownership: the app is one file, `lib/main.dart`, so it is shared until a first story splits it; a story then owns a new `lib/<feature>/` with its `test/<feature>/`; `pubspec.yaml`, `lib/main.dart` and the platform dirs are shared and run alone.
   - Where each rule lives: nothing ships beyond widgets in `lib/main.dart`; no validation, access or tenant code — say so, and that a story puts its rules under `lib/<feature>/`, not in widgets.
   - Capabilities: none provided; keep the table header and one line saying so.
   - UI inventory: Material 3 `MaterialApp` with a seeded `ColorScheme`, `Scaffold`, `AppBar`, `FloatingActionButton`, `cupertino_icons`, all in `lib/main.dart`.
   - Known traps: profile is a template not a repo; canvas rendering and `flt-semantics-placeholder` (the driver may need to enable semantics before measuring boxes; report measured sizes); `--base-href` must start and end with `/`; `flutter analyze` infos are fatal; `.idea/` and `*.iml` generated yet ignored; desktop dirs depend on enabled platforms; `Dev` stays resident and must be stopped; `.img.tmpl` assets come from `flutter_template_images`.
3. [x] **`tests/flutter-profile.test.sh`**, header `# s84 — the flutter profile: lint, web render, grounding in Flutter's app template.` Helpers `section_of`, `identity_value`, `tokens_matching` as in `tests/cli-api-profiles.test.sh`. Three functions:
   - `test_flutter_profile_passes_the_lint` — `require_file`; `bash "$ROOT/bin/po-lint"` exits 0; `Origin` is `https://github.com/flutter/flutter`, `Licence` is `BSD-3-Clause`, `Commit profiled` is 40 hex. Mutant: on a `mktemp -d` copy (`method/` + the profile) with `## Known traps` deleted, `po-lint` exits non-zero and names `boilerplates/flutter/profile.md`.
   - `test_flutter_profile_names_its_web_render` — exact lines `- Platform: mobile`, `- QA driver: mobile-web`; the Commands fence holds `Dev:` with `flutter run -d web-server` and a `Test:` value starting `flutter test`; the section under the fence says `is being served at`.
   - `test_flutter_profile_is_grounded_in_its_source` — source `$FLUTTER_SRC` when set, else the sparse fetch of task 1 at `Commit profiled`; unreachable → stderr `(flutter/flutter not reachable: grounding not checked)` and return 0. With a source: `HEAD` equals `Commit profiled`; `LICENSE` holds `Redistribution and use in source and binary forms`; each backticked token matching `^(lib|test|web|android|ios|linux|macos|windows)/|^(pubspec\.yaml|analysis_options\.yaml)$`, skipping `<` and `*`, resolves under `T:app/` or `T:app_test_widget/` as itself, itself + `.tmpl`, or with its first segment + `.tmpl` (`android/` → `android.tmpl/`); at least 6 resolve. One function prints one line per breach; it runs once more on a copy with a made-up `` `lib/src/router.dart` `` and must report it.
   Run `bash tests/run.sh flutter-profile.test.sh profile.test.sh lint.test.sh`.
4. [x] **Closing checks**, once: `bin/po-lint` clean, then the full suite through `po-run` as `/po-execute` says. Delete task 1's clone.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/`, `bin/`, `boilerplates/` outside `boilerplates/flutter/`, every existing `tests/*.test.sh`, `docs/stories.md`, `docs/catalogue.md`, `docs/parite-killer-saas.md`, `README.md`, `.claude/`, `.polype/`.
- `git diff --stat main...` lists only the profile, the test, ADR-0063 and this story's `docs/` files; no file of `FL:` enters the repository; no clone inside a worktree.
- No `## ` heading beyond those of `method/templates/profile.md`; no capability row outside the template's list.
- ADR-0063 committed as written; no other ADR created.

## The pivot
**The profile describes the tree `flutter create` generates at `3.47.6`, and the grounding maps it back to `.tmpl` sources.** Everything else (commands, ownership, traps) follows from that reading. How it could be wrong:
- `flutter create` output also depends on `--platforms`, `--org`, `--android-language` and the user's desktop config; the profile names the defaults only. A reviewer may want the exact `flutter create` invocation in the profile: write `flutter create <name>` with no option.
- `flutter run -d web-server` in the background with no terminal was not run here (no Flutter SDK on this machine): if it waits on stdin or prints its URL only after a slow first compile, the driver's "reads the origin it prints" still holds but may need patience; state the first-compile delay as a trap rather than invent a flag.
- Canvas rendering may defeat `mobile-web`'s box measurement; the profile flags it, it does not change the driver (out of this story's `Owns`).

## Files touched
`boilerplates/flutter/profile.md` (new), `tests/flutter-profile.test.sh` (new), `docs/decisions/ADR-0063-profil-flutter-depuis-le-gabarit-app-de-flutter-create.md` (planner), this plan, `docs/verif/s84-flutter-profile.md`.

## Test strategy
3 tests of 25, at the only layer there is: the document, checked by the lint and against its source.
- `flutter_profile_passes_the_lint` — fails on a template breach or a wrong identity line; the mutant proves the lint reads this file.
- `flutter_profile_names_its_web_render` — fails if the platform, driver, web-server `Dev` or path-taking `Test` goes.
- `flutter_profile_is_grounded_in_its_source` — fails on a wrong commit, licence or path; its mutant proves the checker bites. Network-dependent, skips loudly.
Existing `profile.test.sh`, `lint.test.sh`, `next-forge-profile.test.sh`, `cli-api-profiles.test.sh` stay unchanged and green.

## Done when
Profile, test, ADR-0063, this plan and the record in one commit on `story/s84-flutter-profile`; `bin/po-lint` clean; full suite green through `po-run`; review with no open critical; squash on `main`.
