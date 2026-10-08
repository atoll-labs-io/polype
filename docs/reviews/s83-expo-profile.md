# Review — s83-expo-profile

Diff reviewed: `git diff main...story/s83-expo-profile`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 4c80ac66ed1f7374efe1a822f2e71e85a0fc205b

## Ownership
I listed the diff with `git diff --name-status main...story/s83-expo-profile` (one commit, 0510124) and checked it against `Owns: boilerplates/expo/, tests/expo-profile.test.sh`.
- [x] Every path is inside `Owns` or in scope by construction:
  - `boilerplates/expo/profile.md` (A) and `tests/expo-profile.test.sh` (A) are covered by `Owns`.
  - `docs/plans/s83-expo-profile.md` and `docs/verif/s83-expo-profile.md` are the story's own evidence.
  - `docs/decisions/ADR-0062-…sdk-57.md` is added (status A) and the plan names it.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other worktree is s84-flutter-profile, which owns `boilerplates/flutter/` and `tests/flutter-profile.test.sh`. No overlap.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s83-expo-profile` passed (exit 0), so I reused the record. Its Unit suite row is `bash tests/run.sh`, exit 0, on tree 06c4f5f3…. `git diff --quiet 06c4f5f3… HEAD -- . ':(exclude)docs'` confirms the code outside `docs/` is the same. The project has no type check command (`Typecheck: —`), so no type check was run. Its "Not proven here" says the profile's `npx jest`, `npx tsc --noEmit` and `npm run web` were never run.
- [x] `po-gate qa-current` is not required: the story has no screen (`Surface : —`).

## Plan
- [x] Task 1 (profile) and task 2 (test file, three tests) are present with the content the plan describes. Task 3 is shown by the record. Task 4 (full suite through `po-run`) was done according to the record's Runs row, but its checkbox is still unticked (minor, below). Nothing in the diff is outside the plan.
- [x] Each run interdict, checked against the diff:
  - `bin/po-lint`, `method/templates/profile.md`, `method/templates/agents-local.md` and `method/skills/qa-drivers/*` are untouched.
  - `boilerplates/hono-api/`, `boilerplates/rust-cli/`, `boilerplates/next-forge/` and `tests/cli-api-profiles.test.sh` are untouched.
  - `.claude/` and `.polype/` are untouched.
  - `docs/stories.md` is untouched. The false story assumption about `Test` is reported in the plan and ADR-0062, not patched.
  - `docs/parite-killer-saas.md` is untouched.
  - ADR-0062 was written by the planner, inside the same single commit.

## References
- [x] I opened `bin/po-lint` (`METHOD="${1:-…}"` argument, `check_profiles` at lines 234–301), `tests/lib.sh` (`ROOT`, `METHOD`), `tests/run.sh` (each file is sourced in its own `bash -c`, so the redefined `section_of`, `grounding_breaches` and `source_of` helpers cannot clash with `cli-api-profiles.test.sh`) and `.polype/templates/verification-record.md`.
- [x] I checked every fact of the profile against my own sparse checkout of expo/expo at `345ae1660abdeb7e43ebca0e41b63e72b30969e8`:
  - That commit is currently the head of `sdk-57` (`ls-remote`). It is dated 2026-10-08.
  - Template `package.json`: `"license": "0BSD"`, version `57.0.29`, main `expo-router/entry`. The scripts are exactly `start`, `reset-project`, `android`, `ios`, `web`, `lint`, with `web` = `expo start --web`. There is no `test` script.
  - The root `LICENSE` is MIT.
  - `app.json`: portrait, web output `static`, `typedRoutes` and `reactCompiler` on.
  - `tsconfig.json`: strict, `@/*` → `./src/*`, includes `.expo/types` and `expo-env.d.ts`.
  - `gitignore` ignores `.expo/`, `expo-env.d.ts`, `example`, `/ios` and `/android`.
  - The stray `expo-template-default-57.0.10.tgz` is present.
  - Every `src/…` path the profile lists exists, including the `.web` variants of `app-tabs`, `animated-icon` and `use-color-scheme`.
  - CLI: `Waiting on` is printed in the non-interactive branch (`startAsync.ts:156`), `isInteractive` is `!CI && isTTY`, the default port is 8081, `--web` opens a desktop browser, and `create-expo` defaults to `expo-template-default`.
- [x] No value merely looks right; each one traced to the source above. One nuance: the URL that `Waiting on` prints is `location.url`, which can be a LAN address rather than `localhost`. The profile says to read that line, so it is not wrong.

## Rules
- [x] `AGENTS.local.md` conventions are respected: the method file is in English, the tests are bash with `test_<criterion>` names, and nothing in `.claude/` or `.polype/` was edited. The ADR file name follows the repository's existing `ADR-NNNN-` pattern.
- [x] No accepted ADR is contradicted. ADR-0062 is consistent with ADR-0061 (and with the ADR-0010 pattern it cites).

## Tests
- [x] Floor: `po-gate floor-guard s83-expo-profile main` exited 0, so nothing was lowered.
- [x] The assertions pin down both acceptance criteria. None of the six empty test shapes applies. The lint test uses a mutant (a copy without `## Known traps`), and the grounding test runs against the real source at the named commit plus a made-up-path mutant.
- [x] Three tests, within the `Test budget` of 25.
- [x] Bite 1: in the profile, `- QA driver: mobile-web` → `scenarios`. 1 failing test (`names_its_web_render`). Undone; `git diff --exit-code boilerplates/expo/profile.md` was clean.
- [x] Bite 2: in the profile, `` `src/hooks/` `` → `` `src/hook/` `` and `Dev: npm run web` → `npm run webx`. 2 failing tests: `is_grounded_in_its_source` reported both "npm script not in the source: webx" and "path not in the source: src/hook/", and `names_its_web_render` also failed. Undone; `git diff --exit-code` was clean. The grounding test reached the network in these runs; it did not skip.
- [x] The story makes no test useless.

## Neighbours
- [x] `po-setup` offers profiles by `- Platform:`, and `tests/catalogue-wiring.test.sh` checks only the glob. No other file lists profiles by name, so nothing else needs to change.

## Lenses
Lenses run: none. The diff touches no auth, routes, migrations, lockfiles, dependency manifests or server-side code.
- [x] There were no lens findings.

## Findings
- minor — `boilerplates/expo/profile.md:24,31` — `Test: npx jest` on a project where jest is not installed does not simply "fail". `npx` offers to download, or downloads, the latest `jest` from npm and runs it without the `jest-expo` preset. The profile's statement that "`npx jest` fails" until a story installs it understates this. `npx --no-install jest`, or a sentence saying so, would make the trap exact.
- minor — `docs/verif/s83-expo-profile.md:3` — the record's first template paragraph is truncated. It starts mid-sentence with "Tree:`, the `## Checks` table…" because the opening "The implementer writes this file before its final runs, then edits only `" was lost. The gate is unaffected.
- minor — `docs/plans/s83-expo-profile.md` task 4 — still `[ ]` even though the record holds a passing `po-run` row for `bash tests/run.sh` on the committed code.
- minor — `docs/stories.md:1287` (outside this lane, for a person) — the criterion `expo_profile_names_its_web_render` assumes the starter has a `Test` command. It has none. ADR-0062 settles it as `npx jest` installed by a first story; the story text should be corrected by a person, as the plan asks.

## Not verified
- I did not run the profile's commands (`npm install`, `npx jest`, `npx tsc --noEmit`, `npm run web`), in line with the plan's interdict on running anything from the cloned source. So these are unchecked: that `npm run web` serves a usable web render, that `npx tsc --noEmit` passes on a fresh project (including the typed-routes trap), and that `npx jest` with `jest-expo` accepts paths. A person should generate a project with `npx create-expo-app` (SDK 57) in a sandbox and run the three commands once.
- I checked the Expo guide facts (`docs/pages/develop/unit-testing.mdx` lines 36, 69, 73) only through the plan and ADR-0062. I did not open that file.
- I did not rerun the full suite. I relied on the record's passing `po-run` row (Verification mode: record).
- When the grounding test cannot reach the network, it skips with a stderr note that `tests/run.sh` hides on success. A green suite run offline therefore does not prove grounding. The two bite runs above did reach the network.

Max severity: minor
Ship allowed: yes
