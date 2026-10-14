---
validated: yes
---
# Plan — s48-floor-guard

[Story](../stories.md) · [Research](../research/s48-floor-guard.md)

Branch `story/s48-floor-guard`. Read `docs/research/s48-floor-guard.md` first; this plan builds on it without repeating it. The structural choices are settled in `docs/decisions/ADR-0025-garde-de-plancher-lit-le-diff.md` (diff only, patterns inside `po-gate.sh`, POSIX awk, exit 2 blocks the review).

## Story
`po-gate floor-guard <id> <base>` reports what the story's diff does to make the checks easier to pass; the review runs it with `Target branch` as base and grades each flag. Criteria: `floor_guard_flags_new_suppressions`, `floor_guard_flags_weakened_tests`, `floor_guard_flags_empty_catch_and_lowered_thresholds`, `floor_guard_has_three_outcomes`, `review_runs_the_floor_guard` (see `docs/stories.md`, s48).

## Contract of the subcommand (settled here, the tests hold it)
- Call: `po-gate floor-guard <id> <base>`. Reads `git diff <base>...story/<id>`, nothing else of the repository.
- **Exit 0** — no flag, stdout empty. **Exit 1** — one flag per stdout line, exactly `<path>:<line>: <rule>: <detail>`, then `po-gate: <N> flag(s) lower the bar of <id> against <base>` on stderr. **Exit 2** — `po-gate: cannot verify the floor of <id>: <reason>` on stderr, nothing on stdout.
- `<line>` is the line number in the story tip (`+c` of the `-U0` hunk header, counted forward). A finding carried by a removed line takes the story-side position where that line stood. A deleted file uses `0`.
- Rules (the `<rule>` token): `typecheck-ignored`, `lint-disabled`, `coverage-excluded`, `test-skipped`, `test-only`, `test-file-deleted`, `assertions-dropped`, `empty-catch`, `strict-off`, `threshold-lowered`, `threshold-removed`.

## Tasks
1. [x] **Frame and exit codes** — in `method/hooks/po-gate.sh`: a header line under `:4-9` documenting `floor-guard <id> <base>` and its three exits; a helper `unverifiable()` that prints the exit-2 message and `exit 2`; a `floor-guard)` branch in the dispatch `case` (`:75-81`) that checks both arguments itself (no `${2:?}`, which exits 1 — research fact 2). In `floor_guard`: refuse with 2 when `story/<id>` or `<base>` does not resolve (`git rev-parse --verify --quiet "<ref>^{commit}"`), when there is no merge base, when `git diff` fails, when awk exits non-zero, and when the diff is non-empty but awk parsed no `+++ b/` file header (a format it cannot read must never come out as 0). Diff command, pinned against user config (research, Traps): `git -C "$(top)" -c core.quotePath=false diff --no-color --no-ext-diff --no-textconv --src-prefix=a/ --dst-prefix=b/ -U0 <base>...story/<id>`; deletions from `git … diff --name-status --find-renames <base>...story/<id>` (only `D` counts). Capture each into a variable with an explicit `|| unverifiable …` so `set -e` never turns an error into 1. Existing functions untouched.
   Test: `floor_guard_has_three_outcomes` — clean story → 0 with empty stdout; a story adding one flagged line → 1 and stdout holds `<path>:<line>:`; missing `<base>` argument, unknown base ref, absent `story/<id>` → 2 each, and stdout empty.
2. [x] **Pattern table and suppression scan** — one table near the top of the floor-guard section, a line per entry `<extensions>|<rule>|<ERE>`, POSIX ERE only (`[[:space:]]`, no `\s`/`\b`/intervals), read by awk and applied to **added** lines of files whose extension is listed. Entries at least:
   - `ts tsx js jsx mjs cjs mts cts`: `typecheck-ignored` `@ts-(ignore|nocheck|expect-error)`; `lint-disabled` `eslint-disable|biome-ignore`; `coverage-excluded` `(istanbul|c8|v8) ignore`; `test-skipped` `(^|[^A-Za-z0-9_$.])(it|test|describe|suite|context)\.skip([^A-Za-z0-9_$]|$)` and `(^|[^A-Za-z0-9_$.])x(it|test|describe)[[:space:]]*\(`; `test-only` the same two shapes with `.only` and `f(it|describe)`.
   - `py pyi`: `typecheck-ignored` `#[[:space:]]*(type|pyright):[[:space:]]*ignore`; `lint-disabled` `#[[:space:]]*(noqa|pylint:[[:space:]]*disable|ruff:[[:space:]]*noqa)`; `coverage-excluded` `#[[:space:]]*pragma:[[:space:]]*no[[:space:]]*cover`; `test-skipped` `pytest\.mark\.(skip|skipif|xfail)|pytest\.skip\(|unittest\.skip|skipTest\(`.
   A comment above the table says how to add a language. `<detail>` is the added line, trimmed.
   Test: `floor_guard_flags_new_suppressions` — one `.ts` and one `.py` file in the story each carrying a typecheck ignore, a lint disable, a coverage exclusion, a skipped test (and `it.only` in the `.ts`) → each rule appears at the right `path:line`; the same directive already present on `main` and untouched by the story → not flagged.
3. [x] **Weakened tests** — a test path is one matching `(^|/)(tests?|__tests__|specs?)/` or a basename `*.test.*`, `*.spec.*`, `test_*.py`, `*_test.py` (a second small list next to the table). `test-file-deleted` for each `D` path of the name-status on a test path, line `0`. `assertions-dropped` when, in one test file, removed lines containing `expect(` or `assert` outnumber added ones; `<detail>` is `<removed> removed, <added> added`; line = story-side position of the first removed assertion. A renamed test file is not a deletion.
   Test: `floor_guard_flags_weakened_tests` — a deleted `tests/old.test.ts` → `tests/old.test.ts:0: test-file-deleted`; `test_calc.py` losing one `assert` and `calc.test.ts` losing one `expect(` → `assertions-dropped` for each; a renamed test file with the same assertions, and an assertion rewritten in place (one removed, one added) → not flagged.
4. [x] **Empty catch, strict flags, thresholds** —
   - `empty-catch` (JS/TS extensions): an added line matching `catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}` or `\.catch\([[:space:]]*(\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)?[[:space:]]*=>[[:space:]]*\{[[:space:]]*\}[[:space:]]*\)`; or an added line ending in `catch (…) {` immediately followed, in the same hunk, by an added line that is only `}`. Python: `except…:` followed by `pass` or `...`, on one added line or on two consecutive added lines.
   - `strict-off`: in a file whose basename matches `tsconfig*.json`, an added line `"<flag>"[[:space:]]*:[[:space:]]*false` for `strict`, `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitThis`, `alwaysStrict`, `useUnknownInCatchVariables`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`.
   - `threshold-lowered` / `threshold-removed`: in `jest.config.*`, `vitest.config.*`, `vite.config.*` (Vitest reads it), `pyproject.toml`, `.coveragerc`, key `branches|functions|lines|statements` or `fail[-_]under` (also inside `--cov-fail-under=`) followed by `[:=]` and a number. Per file and key, removed values are paired in order with added ones; added < removed → `threshold-lowered` at the added line, detail `<key> <old> → <new>`; a removed value with no added one → `threshold-removed`. Negative Jest thresholds are out of scope (ADR-0025).
   Test: `floor_guard_flags_empty_catch_and_lowered_thresholds` — `} catch (e) {}` in `.ts`, a two-line `except ValueError:` / `pass` in `.py`, `"strict": false` in `tsconfig.build.json`, `lines: 80` → `lines: 60` in `vitest.config.ts`, `fail_under = 90` → `70` in `.coveragerc`, `fail_under` removed from `pyproject.toml` → six flags at the right lines; a threshold raised (`80` → `90`) and a `catch` with a body → not flagged.
5. [x] **The review runs it** — in `method/skills/review-antihallu/SKILL.md`, step 4 (`:36-39`) gains a first bullet, keeping six numbered steps (research fact 3), with these exact phrases: `` *Floor.* Run `po-gate floor-guard <id> <Target branch>` from the worktree``; exit 1: `each printed line is a flag: justified in the plan → **minor**, otherwise **major**`; `a deleted test file the plan does not justify → **critical**`; exit 2: `the guard could not verify, which is never clean: the review is blocked`, with the guard's message as `Failure cause:`. "Justified" means the plan names the file or the directive and says why. In `method/templates/review.md`, `## Tests` gains a first box: `` - [ ] Floor: `po-gate floor-guard <id> <Target branch>` → <0 nothing lowered | 1 each flag graded, listed under Findings | 2 review blocked> ``.
   Test: `review_runs_the_floor_guard` — `contains` on the skill for each quoted phrase and on the template for the box; the numbered-step count stays held by `review.test.sh:27-33`.
6. [x] **Whole run** — `bash tests/run.sh` (every file green, `review.test.sh` and `ownership.test.sh` included) and `bin/po-lint`; then run the new guard on this very story, `bash method/hooks/po-gate.sh floor-guard s48-floor-guard main` from the worktree, and record its exit code (expected 0) in `docs/verif/s48-floor-guard.md`.

## Run interdicts
- `method/agents/reviewer.md`, `method/commands/po-review.md`, `method/AGENTS.md`, `bin/`, `.claude/`, `.polype/` end with an empty diff.
- In `po-gate.sh`, the bodies of `plan_validated`, `ship_allowed`, `verif_current`, `pre_commit` and the helpers above them are unchanged: the diff of that file only adds lines (header, table, `unverifiable`, `floor_guard`, one `case` branch).
- `tests/gate.test.sh`, `tests/review.test.sh`, `tests/ownership.test.sh` unchanged.
- `review-antihallu/SKILL.md` still has exactly six `**N. ` lines and its `## Six steps, all of them, in this order` heading.
- No `jq`, `python`, `perl` or GNU-only awk/grep construct (`\s`, `\b`, `\d`, `{n}`, `gensub`, `match(…, arr)`) in `po-gate.sh`.
- `docs/decisions/ADR-0025-…` is not edited (accepted); `docs/parite-killer-saas.md` and `docs/references/` untouched (no matrix line for this story).
- No ESLint-config `off` rules, `package.json`/`setup.cfg` thresholds: out of scope.

## The pivot
**A guard that cannot read the diff must say 2, never 0.** Everything rests on the diff parsing and the exit-code discipline. Ways it could be wrong:
- `set -euo pipefail` (`po-gate.sh:12`) turns an internal failure into exit 1, or a pipeline with `grep` finding nothing aborts the function: compare each failure path of task 1 with its test, and force one (e.g. `story/<id>` absent) to see 2, not 1.
- A diff format awk does not recognise (prefixes, quoted paths, colour) yields no flag and exit 0: check the pinned options of task 1 and the "non-empty diff, no file header parsed → 2" rule; with `git -c diff.noprefix=true` set in the scratch repo the result must not change.
- Line numbers drift: `-U0` headers omit `,count` when it is 1 (`@@ -3 +3 @@`) and use `,0` for pure deletions; check the expected `path:line` of the tests against `git show story/<id>:<path>`.

## Files touched
- `method/hooks/po-gate.sh` (tasks 1–4)
- `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md` (task 5)
- `tests/floor-guard.test.sh` (new)
- Pipeline evidence: `docs/research/s48-floor-guard.md`, this plan, `docs/verif/s48-floor-guard.md`, `docs/decisions/ADR-0025-garde-de-plancher-lit-le-diff.md` (written by the planner; outside `Owns`, under `docs/`).

## Test strategy
Five tests, one per acceptance criterion, named after it, in `tests/floor-guard.test.sh` (budget 25). Tasks 1–4 are tested at the only layer they have, the script on a throwaway repository: `scratch_repo` on `main`, a base commit, then `git checkout -qb story/s01-a` and the story's commits; call `bash "$METHOD/hooks/po-gate.sh" floor-guard s01-a main` and capture with `out=$(…) || code=$?` (the runner uses `set -eu`). Each test asserts flagged `path:line: rule` lines with `grep -qF`, and at least one negative case per rule family (unchanged base line, rewrite in place, rename, raised threshold, non-empty catch), so deleting any single rule from the table turns its test red. Task 5 is prose: `contains` on short exact phrases. No visual check.
Fixture files carry `.ts`/`.py`/config names only inside the scratch repository; `tests/floor-guard.test.sh` itself is `.sh`, so the guard never flags its own fixtures.

## Done when
The six tasks ticked; `bash tests/run.sh` green with the five new tests; `bin/po-lint` clean; the guard returns 0 on this story; one commit on `story/s48-floor-guard`; review with no open critical finding.
