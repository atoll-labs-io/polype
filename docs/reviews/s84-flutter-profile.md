# Review — s84-flutter-profile

Story: s84-flutter-profile — Le profil Flutter
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s84-flutter-profile
Reviewed tree: 58a3ced233bbb5910634cb3bc0d52184b7657bdb
Fix loop: 0
Lenses run: none (the diff is one markdown profile, one bash test, an ADR and the story's docs; no auth, migration, lockfile or server-code trigger)

## Verdict
The story can ship. It has no critical, major or minor finding. I checked the profile against Flutter's source at the commit it names, and every fact I checked holds. The story's tests fail when the rules they cover are broken.

## Scope (`Owns`)
`Owns`: `boilerplates/flutter/`, `tests/flutter-profile.test.sh`. The diff touches five files:
- `boilerplates/flutter/profile.md` (A): inside `Owns`.
- `tests/flutter-profile.test.sh` (A): inside `Owns`.
- `docs/decisions/ADR-0063-profil-flutter-depuis-le-gabarit-app-de-flutter-create.md` (A): an added ADR that the plan names, so it is in scope by construction.
- `docs/plans/s84-flutter-profile.md` and `docs/verif/s84-flutter-profile.md`: the story's own evidence.

The other running lane is s83-expo-profile. Its `Owns` is `boilerplates/expo/` and `tests/expo-profile.test.sh`, so the two stories do not overlap.

## Step 1 — Reused evidence
- `po-gate verif-current s84-flutter-profile` exits 0. The record is complete, and the `Unit suite` check (`bash tests/run.sh`) exited 0 on code whose files outside `docs/` match `Tree:`. I relied on that run and did not rerun the full suite.
- The project has no type check, E2E or build command (all `—` in `AGENTS.local.md`). I used no substitute.
- The story has no `Surface`, so there is no QA stage and no design check.
- I also ran `bin/po-lint` myself: exit 0.

## Step 2 — References
I made a sparse fetch of `flutter/flutter` at `5fc346839b5d0eef006ed8404392afb4dfae428d` (commit dated 2026-09-30) into a temp dir, which I deleted afterwards. The following facts in the profile and plan match that source:
- **Licence:** BSD-3-Clause.
- **Templates:** `app` and `app_test_widget` are what `flutter create` uses by default, with the widget test left out by `--empty` or a sample (`create.dart`). `app_integration_test` is used only for plugin examples (`create.dart:805`).
- **Dev output:** `web_device.dart:454` prints `$mainPath is being served at $url`.
- **Analyze:** `analyze.dart:118-122` makes `--fatal-infos` and `--fatal-warnings` default to true.
- **Base href:** `build_web.dart:250-253` requires `--base-href` to start and end with `/`.
- **Canvas trap:** `flt-semantics-placeholder` is at `semantics_helper.dart:187`.
- **Generated `.gitignore`:** it ignores `*.iml`, `.idea/` and `/build/`.
- **Desktop directories:** `template.dart` builds them only when the platform is enabled.
- **Package and app:** `cupertino_icons ^1.0.8` and `flutter_lints ^6.0.0` are the dependencies. The app uses `colorScheme: .fromSeed(...)`, an `AppBar` and a `FloatingActionButton`. The widget test imports `package:{{projectName}}/main.dart`.

The test helpers it calls (`require_file`, `fail`, `$METHOD`, `$ROOT`) exist in `tests/lib.sh`, and `bin/po-lint` accepts a method-dir argument.

## Step 3 — Against the plan
All four tasks are done as written:
- Identity lines, the ten template headings in order, and the commands fence are as planned.
- The code map, ownership and rule placement are there, and the capabilities table says "none".
- Every planned trap is there.
- The test file has the three planned functions and the planned header.

The plan's run interdicts hold: nothing in `method/`, `bin/`, other profiles, existing tests, `docs/stories.md` or the installed copies changed, and no other ADR was added. ADR-0063 matches what was built.

## Step 4 — Tests
- **Floor:** `po-gate floor-guard s84-flutter-profile main` exits 0. Nothing in the diff makes the checks easier to pass.
- **Budget:** 3 tests out of 25.
- **Tests that prove nothing:** none of the six kinds. The lint mutant runs on a copy of the method with `## Known traps` removed, and the test checks that po-lint names the flutter file. The grounding mutant adds a made-up `lib/src/router.dart` and checks that it is reported.
- **Grounding actually runs:** with `FLUTTER_SRC` pointed at my fetch it reports no breach and resolves 12 path tokens (6 needed). Called directly without the override, it fetched the source itself and did not take the "not reachable" skip.
- **Bite 1:** I changed `Dev: flutter run -d web-server` to `flutter run -d chrome` in the profile. 1 test failed (`flutter_profile_names_its_web_render`: "Dev does not serve the web render"). I restored the file and `git diff --exit-code` was clean.
- **Bite 2:** I changed `` `test/widget_test.dart` `` to `` `test/app_test.dart` ``. 1 test failed (`flutter_profile_is_grounded_in_its_source`: "path not in the source: test/app_test.dart"). I restored the file and `git diff --exit-code` was clean.

## Step 5 — Values
- The commit hash, tag date, `^1.0.8` and `^6.0.0` versions, `--base-href` rule and "infos fatal" all match the source (see step 2).
- "Material 3": the template does not set `useMaterial3`, so this relies on the framework default (Material 3 since Flutter 3.16). I did not open `ThemeData` at this commit; it is listed under Not verified.

## Step 6 — Neighbours
`/po-setup` finds profiles by the glob `boilerplates/*/profile.md` and filters them on the `- Platform:` line, so the new profile shows up there with no other change. `po-help` and `po-architect` refer to the catalogue in general terms only. No neighbour needs a change.

## Findings
None.

## Not verified
- **No Flutter SDK was run, by me or by the implementer** (the record's "Not proven here" says the same). So `flutter create`, `flutter pub get`, `flutter test`, `flutter analyze` and `flutter build web` were never run, and neither was `flutter run -d web-server` running in the background without a terminal (whether it waits on input, how long the first compile takes). To cover this, a person installs Flutter 3.47.6, runs `flutter create demo`, then runs each command in the fence and checks that `Dev` prints `... is being served at http://localhost:<port>` while detached.
- **The `mobile-web` driver on Flutter's canvas render.** The driver may not be able to measure touch targets until accessibility semantics are switched on. The profile flags this as a trap but does not solve it, and changing the driver was outside this story's `Owns`. A person should run `/po-qa` on a Flutter screen once and see whether the driver can measure the boxes or comes back `blocked`.
- **The "Material 3" default at this commit** (see step 5). To cover it, read the `useMaterial3` default in `packages/flutter/lib/src/material/theme_data.dart` at the profiled commit.
- **macOS:** the grounding mutant uses GNU sed's `\n` in a replacement (line 100), as the precedent profile tests do. I ran it on Linux only. On BSD sed it would fail loudly ("the mutant was not built"), not pass silently.

Max severity: none
Ship allowed: yes
