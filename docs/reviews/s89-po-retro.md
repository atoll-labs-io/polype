# Review — s89-po-retro

[Story](../stories.md) · [Plan](../plans/s89-po-retro.md) · [Verification](../verif/s89-po-retro.md)

Diff reviewed: `git diff main...story/s89-po-retro`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 0bba12e3b7df844318023cd405258bf861dc8b8e

## When blocked
Not applicable.

## Ownership
`git diff --name-status main...story/s89-po-retro` lists 7 paths:
- [x] `method/commands/po-retro.md` (A), `method/commands/po-help.md` (M), `tests/po-retro.test.sh` (A): all three are in `Owns`.
- [x] `docs/research/`, `docs/plans/`, `docs/verif/s89-po-retro.md`: the story's own pipeline evidence, so in scope by construction.
- [x] `docs/decisions/ADR-0067-la-retro-ne-chiffre-que-les-lignes-ecrites-par-le-cycle.md`: added (status `A`), and the plan names it. In scope by construction.
- [x] No path is outside `Owns`.
- [x] No path is in another running story's `Owns`. The only other running lane is s88-ros-simulation-driver, which owns `boilerplates/ros2-gazebo/`, `method/skills/qa-drivers/simulation.md` and `tests/ros-simulation-driver.test.sh`. None of those overlap this story.

## Evidence reused
- [x] `po-gate verif-current s89-po-retro` exits 0. The record says `Verification status: complete`, its `Tree:` is 97d5ae0…, and the code outside `docs/` on HEAD matches that tree (`git diff --quiet` passes). The `Unit suite` row (`bash tests/run.sh`) exits 0. I relied on that run and did not rerun the suite.
  - The project has no type check, E2E or build command (`—`).
  - The record's "Not proven here" says `/po-retro` was never run on real `docs/`. I carry that under Not verified.
- [x] `po-gate qa-current`: not required. `Surface: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–4 are all present. Nothing in the diff is outside the plan.
- [x] Run interdicts, checked one by one:
  - The diff list matches the allowed set.
  - The diff is empty on `method/AGENTS.md`, `po-status.md`, `po-drive.md`, `method/templates/`, `bin/`, `README.md`, `docs/stories.md` and `docs/parite-killer-saas.md`.
  - No existing test was edited, and nothing under `.claude/` or `.polype/`.
  - `po-help.md` has a one-line diff, placed right after the `/po-status` line.
  - ADR-0067 is the only ADR added.

## References
- [x] Every reference was opened and confirmed:
  - `Fix loop:` read the way `/po-drive` reads it: `method/commands/po-drive.md:72`.
  - Review lines `Review status:`, `Failure cause:`, `Max severity:`, `Ship allowed:` and `## Findings`: `method/templates/review.md`.
  - `QA status:`: `method/templates/qa.md:31`.
  - `## Runs` with its `Exit` column: the verification record.
  - The worktree rule `/po-status` uses: `method/commands/po-status.md:22,34`.
  - Both settings the command reads (`Target branch`, `Worktree root`) exist. The structure test in the full suite checks this.
- [x] The research claims review files stack several reviews. This holds on real files: `docs/reviews/s78-platform-setting.md` holds three reviews (`- Fix loop:` at lines 9, 98 and 207), and seven other review files hold two each. The "list marker changes nothing" tolerance is needed.
- [x] The example given, `M8` → `## M8 — Toutes les plateformes`, resolves to a single heading in `docs/stories.md:1191`, and that milestone stops at `:1390`.

## Rules
- [x] The command file is in English and the help line in French. It starts with a `Reads settings:` line. It has no Write or Edit.
- [x] No accepted ADR is contradicted. The command follows ADR-0067 as written; ADR-0006 is covered by `overlap.test.sh` inside the green suite.

## Tests
- [x] Floor: `po-gate floor-guard s89-po-retro main` exits 0. Nothing was lowered.
- [x] There is one test per acceptance criterion, named after it. None of the six empty test shapes appears. `section_of` checks that each clause sits in its own section, not just anywhere in the file.
- [x] 3 tests against a budget of 25.
- [x] Bite checks. Each change was undone and `git diff --exit-code` came back clean every time:
  - Added `Write` to `allowed-tools` → 1 failing test (`retro_writes_nothing`).
  - Deleted the `/po-retro` line from `po-help.md` → 2 failing tests (`help_lists_the_retro` and `pilot.test.sh`'s `every_command_listed_in_help`).
  - Replaced the no-count clause with "counts lines of code and commits from git log" → 1 failing test (`retro_reads_only_recorded_facts`).
- [x] No test is made useless by this story.

## Neighbours
- [x] The only other file touched is `po-help.md`; `pilot.test.sh` and the help-freezing tests are green in the record.
- [x] `README.md:37` mentions `/po-status` but not `/po-retro`. The plan forbids touching it and no rule requires it, so this is not a finding.

## Lenses
Lenses run: none. The diff has no auth, route, migration, lockfile or server-side code paths, and none of the content triggers.

## Findings
- **major** — `method/commands/po-retro.md:24`: the milestone rule matches by prefix ("the heading's text … starts with it") and stops when more than one heading matches (`:20`). It never lets an exact match win, so a milestone whose full title is a prefix of another heading can never be chosen. In this repository:
  - `Correctifs hors jalon` (`docs/stories.md:882`) also matches `Correctifs hors jalon (suite)` (`:1390`). The command lists the headings and stops, and no argument can select that milestone.
  - `M7` matches both `## M7 — Durcissement` and `## M7 bis — Les derniers trous`.

  The command stops cleanly with a list, and a range still works, so no wrong figure is produced. Fix: an exact full-text match takes precedence over prefix matches.
- **minor** — `method/commands/po-retro.md:41`: "majors still open" reads only the last review. When that review is blocked (on QA, or by a failing command), it has no `## Findings`, so it shows zero open majors even when the review before it listed some. The wording "open by the last review" keeps this technically accurate, but it can mislead. Suggest using the last review that is not blocked.

## Not verified
- **The command's output on real data.** `/po-retro` is prose that an agent carries out, and nobody has run it: not the implementer (the plan forbids it), and not this review. That covers how it parses findings when the severity word comes in various shapes, the `path:line` citations, the ranking, and the "unrated" line. The tests only check that the clauses exist. A person should run `/po-retro M8` and `/po-retro s78-platform-setting..s80-…` on this repository and check a few cited lines against `docs/reviews/s78-platform-setting.md`.
- **The "Bash is used read-only" rule.** Only the prose enforces it; no hook does. Its effect in practice was not observed.
- **QA-shaped findings.** The plan's pivot raised the `### Finding N` + `Severity:` shape. The retro reads only `QA status:` from QA reports, so this was not exercised.

Max severity: major
Ship allowed: yes
