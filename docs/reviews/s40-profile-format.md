# Review — s40-profile-format

[Story](../stories.md) · [Plan](../plans/s40-profile-format.md) · [Verification](../verif/s40-profile-format.md)

Diff reviewed: `git diff m4-catalogue...story/s40-profile-format` (one commit, 2e026ce), read in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the diff with `git diff --name-only m4-catalogue...story/s40-profile-format` and checked each path against `Owns`: `method/templates/profile.md`, `bin/po-lint`, `tests/profile.test.sh`, `docs/catalogue.md`.
- [x] `method/templates/profile.md`, `bin/po-lint`, `tests/profile.test.sh` and `docs/catalogue.md` are inside `Owns`.
- [x] `docs/plans/s40-profile-format.md` and `docs/verif/s40-profile-format.md` are the story's own evidence, in scope by construction.
- [x] `docs/parite-killer-saas.md` is not in `Owns`, but a written rule requires it. The rule in AGENTS.local.md Conventions says: "When a story implements lines of the parity matrix, it updates their status cell in `docs/parite-killer-saas.md`". The story names B03 and C07, and only those two cells changed. Rated minor as a gap in `Owns`, not a breach.
- [x] No other running story is affected. `git worktree list` shows only this story's worktree. s41 and s43 also own `docs/catalogue.md`, but neither has a worktree yet and both depend on s40.

## Evidence reused
- [x] `po-gate verif-current s40-profile-format` exited 0. `git diff --quiet b81e2eb HEAD -- . ':(exclude)docs'` exited 0 too, so `Tree:` matches the committed code.
- [x] With `Verification mode: record`, I relied on the record: `bash tests/run.sh` exit 0, 214 passed, 0 failed. The project has no type check, end-to-end or build command (all `—`), and I ran none in their place.
- [x] "Not proven here" says: there is no real profile yet, and a template command removed from a profile's fence is not exercised by a test. My bite run below confirms the second point.

## Plan
- [x] Tasks 1 to 5 are all present, and nothing was added outside the plan.
- [x] Every run interdict holds:
  - `method/commands/po-architect.md`, `.claude/`, `.polype/` and `AGENTS.md` are not in the diff.
  - No `boilerplates/` directory is committed.
  - In the parity matrix, only B03 and C07 changed.
  - `tests/lint.test.sh` is unchanged.

## References
- [x] Opened and confirmed:
  - ADR-0020: 12 capabilities. The template's English names map one to one, in the ADR's order.
  - ADR-0008:19 (profile contents), ADR-0007:19, 27 and 28 (`src/modules/<domaine>/`, `src/core/`, third-party ownership granularity), ADR-0009:28 and ADR-0001. All are accepted.
  - The sentence "A `Test` command must accept paths to test files" in the template matches `method/templates/agents-local.md:70`.
  - `po-architect.md:26-33` matches what the catalogue says about the "aucun" level.
  - `template_settings`, `ROOT` and `METHOD` exist in `tests/lib.sh`.
- [x] Values checked: the five command names, the eight headings and the `line 1` rule for a missing section all match the plan. The summary line of po-lint is unchanged, and `lint.test.sh` asserts it.

## Rules
- [x] The method file is in English and the doc in French. The installer copies `method/templates` as a whole directory (`bin/polype:98,101`), so the new template reaches `.polype/templates/` with no change to the installer.
- [x] No accepted ADR is contradicted.

## Tests
- [x] There are 4 tests, one per acceptance criterion, within the budget of 25. `test_lint_checks_profiles` runs the real `bin/po-lint` on a copy of `method/` and checks that each mutation was actually applied. None of the six kinds of test that prove nothing appears.
- [x] Bite: I disabled the capability check (`|| report … capability` → `|| true`). 1 test failed (`lint_checks_profiles`, "lint accepts a Blockchain capability"). Undone, and `git diff --exit-code bin/po-lint` is clean.
- [x] Bite: I disabled the missing-section check (`grep -qxF "$heading"` → `true`). 1 test failed (`lint_checks_profiles`, "lint accepts a profile without Known traps"). Undone, and `git diff --exit-code` is clean.
- [x] Bite: I disabled the missing-command check (`bin/po-lint:242`, `|| report … "command '$name' is missing"` → `|| true`). **0 tests failed** in `profile.test.sh` and `lint.test.sh` (10 passed). Undone, and `git diff --exit-code` is clean.
- [x] No existing test is made useless by this story.

## Neighbours
- [x] The only callers of `bin/po-lint` are `tests/lint.test.sh` and `tests/profile.test.sh`. `check_profiles` returns silently when there is no `boilerplates/` folder, so the lint mutants stay at exactly one breach. `git status --porcelain` is empty after my runs.

## Findings
- minor — `bin/po-lint:242` — The rule that reports a template command missing from a profile's fence (for example a dropped `Build:` line) is covered by no test. When I disabled it, all 10 tests still passed. The `Tests:` mutant also triggers this report, but the test only greps for the "not a setting" line. The record says so openly. The fix is to add one assertion to `test_lint_checks_profiles`, such as deleting `^Build:` and expecting `command 'Build' is missing`.
- minor — `tests/profile.test.sh:89,91` — `contains "$doc" "maison"` and `contains "$doc" "aucun"` quote common French words ("aucun" matches almost any French prose). The test would still pass if the three-level table lost its cost column. The doc itself does explain all three levels and their cost.
- minor — `bin/po-lint:196,205,230` — The lint reads the profile line by line and ignores code fences outside `## Commands`. A `## ` line inside a fenced example in another section would either count as a required heading or switch the section the lint is reading. No profile exists yet, so this is a robustness note for s42.
- minor — `docs/parite-killer-saas.md` — This path is required by the parity-matrix rule in the AGENTS.local.md Conventions but is missing from `Owns`. Widen `Owns` in `docs/stories.md` for later stories that tick matrix lines.

## Not verified
- **The lint on a real profile.** None exists until s42. The rule was only run on the template itself and on three mutants. When s42 lands, a person should run `bash bin/po-lint` on the real `boilerplates/next-forge/profile.md`.
- **Suite, type check, end-to-end and build.** I did not rerun the suite: the record matches the commit and I relied on it. The project has no type check, end-to-end or build command.
- **The overlap test (ADR-0006).** I did not check it independently. It is part of the recorded full suite, which passed.
- **The French wording.** I read `docs/catalogue.md` and the two parity cells for accuracy against the ADRs, not for tone. A French-speaking person should reread them.

Max severity: minor
Ship allowed: yes
