# Research — s48-floor-guard

## Structuring facts
- No assumption of the story is false. One is incomplete: the story never says what the review does with exit 2; `reviewer.md:28-37` already answers it — a command that prevents a complete review gives `Review status: blocked`, so exit 2 maps to a blocked review, never to a "not verified" line under a passing verdict.
- `po-gate.sh` maps every refusal to exit 1 (`refuse`, `po-gate.sh:15`) and `set -euo pipefail` (`po-gate.sh:12`) turns any internal error into exit 1 too; `${2:?}` (`po-gate.sh:76-78`) exits 1 as well (checked: bash prints the message and exits 1). For `floor-guard`, 1 means "flags found", so every failure path — missing argument, unknown ref, failing `git diff`, failing `awk` — must exit 2 explicitly.
- The review procedure must keep **exactly six** numbered steps: `tests/review.test.sh:29-30` counts `^\*\*[1-6]\. ` and fails on any other count, `tests/ownership.test.sh:52` pins the heading `## Six steps, all of them, in this order`, and `reviewer.md:15` (outside `Owns`) describes "the scope check that comes first, then six steps". The guard goes inside an existing step, not a seventh.
- Only lines added or removed by `git diff <base>...story/<id>` are read (story note). Assertion drop = removed assertion lines minus added ones, per test file, which equals the full-count difference for a modified file without ever reading whole files.
- Patterns run on GNU awk here (5.4.1), but `po-gate` must run on macOS awk and mawk too: no `\s`, `\b`, `\d`, no `{n}` intervals — POSIX classes only.

## Story
`po-gate floor-guard <id> <base>` scans the story diff for everything that lowers the bar of the checks, and the review runs it and grades what it finds. Criteria (each a test function of `tests/floor-guard.test.sh`):
- `floor_guard_flags_new_suppressions` — added directives: typecheck ignore, lint disable, coverage exclusion, test marked `skip`/`only`.
- `floor_guard_flags_weakened_tests` — a deleted test file; a test file whose assertion count drops (assertion = a line containing `expect(` or `assert`).
- `floor_guard_flags_empty_catch_and_lowered_thresholds` — added empty `catch`; a strict flag set to `false` in `tsconfig*.json`; a coverage threshold lowered in Jest/Vitest config, `pyproject.toml`, `.coveragerc`.
- `floor_guard_has_three_outcomes` — 0 nothing, 1 flags listed with file and line, 2 cannot verify; 2 is never read as clean.
- `review_runs_the_floor_guard` — the review runs it with `Target branch` as base; flag justified in the plan → minor, otherwise major; unjustified deleted test file → critical.

Owns: `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/skills/review-antihallu/`, `tests/floor-guard.test.sh`. Depends on s47 (merged, `4d31c59`).

## Current code
- `method/hooks/po-gate.sh` (81 lines): header documents each subcommand (`:4-11`); helpers `top` (`:14`), `refuse` → exit 1 (`:15`), `first_hash`, `tree_exists`, `code_matches` (`:27-32`); subcommands `plan_validated` (`:19`), `ship_allowed` (`:35`), `verif_current` (`:47`), `pre_commit` (`:60`); dispatch `case` (`:75-81`) whose unknown branch already exits 2 (`:80`). It reads no setting (`AGENTS.md`: "po-gate ... runs from the repository root or from any story worktree"), hence the base as an argument.
- `method/skills/review-antihallu/SKILL.md` (49 lines): scope section (`:9-20`), six steps (`:22-43`), step 4 "Make the tests prove themselves" with bullets *Coverage that is only apparent*, *Excess*, *Bite* (`:36-39`), severity scale (`:45-49`).
- `method/templates/review.md` (53 lines): `## Ownership` (`:15-20`), `## Evidence reused` (`:22-23`), `## Tests` boxes (`:37-41`), `## Findings` (`:46-47`), `## Not verified` (`:49-50`), verdict lines last (`:52-53`).
- `method/agents/reviewer.md`: has Bash (`:4`), preloads `review-antihallu` (`:7`), blocked-report rule (`:28-37`), `Ship allowed: no` only for critical or blocked (`:47`). Not in `Owns`; needs no change.
- No `tests/floor-guard.test.sh` yet. `tests/gate.test.sh:6-11` shows the sandbox pattern: `scratch_repo` (`tests/lib.sh:46-53`) then commits; `passes()` (`gate.test.sh:15`) swallows stderr.

## Attachment points
- `po-gate.sh`: a `floor_guard` function plus a `floor-guard)` branch in the dispatch `case` (`:75-81`), and a header line (`:4-11`).
- `review-antihallu/SKILL.md` step 4 (`:36-39`): a new bullet; the step stays number 4.
- `templates/review.md` `## Tests` (`:37-41`): one box recording the guard's exit code and each flag's grade.

## Verified interfaces
- `po-gate` invocation: installed as `.polype/hooks/po-gate.sh`, executable (`tests/install.test.sh:15`, `tests/bounds.test.sh:160`); the installer pairs `method/hooks` with `.polype/hooks` (`bin/polype:98-101`), so no installer change.
- `refuse()` prints `po-gate: …` on stderr and returns 1 (`po-gate.sh:15`).
- Test helpers: `scratch_repo` sets `$SCRATCH` and an EXIT trap (`lib.sh:46-53`); `contains file phrase` exact, case-sensitive (`lib.sh:43`); `fail` exits the test (`lib.sh:11`). `run.sh` runs each `test_*` in `set -eu` (`run.sh:17`) — a test must capture the gate's exit code with `|| code=$?`, not let it abort.
- `git diff <a>...<b>` diffs `merge-base(a,b)` against `b`; `git diff --name-status` reports `D` for deletions, `R<n>` for renames with rename detection on.

## Traps
- **Exit-code collisions** (fact 2): `set -e` inside `floor_guard` would exit 1 on any failing command. Compute the diff into a variable with an explicit `|| exit 2`, check the awk exit status, and validate both refs (`git rev-parse --verify --quiet "<ref>^{commit}"`) and the merge base before diffing.
- **Diff format drift**: user git config can change prefixes (`diff.noprefix`, `diff.mnemonicPrefix`), quote paths (`core.quotePath`), run external diffs or textconv. Pin `--no-color --no-ext-diff --no-textconv --src-prefix=a/ --dst-prefix=b/ -U0` and `-c core.quotePath=false`. Tests already neutralise global config (`lib.sh:9`), so they would not catch this; the reviewer must check it.
- **Renames**: with `--no-renames`, a moved test file would appear deleted. Use rename detection for the deletion check, so only a real `D` is flagged; a renamed file's assertions are still compared through its diff.
- **Six-step count** (fact 3): a heading or bold `**7. ` line breaks `review.test.sh`.
- **Self-scan**: the pattern lists live in a `.sh` file and the fixtures in `tests/floor-guard.test.sh`; the guard matches by file extension (`.ts`/`.js` family, `.py`), so running it on this story yields no flag from its own code. Fixtures written in the test must use `.ts`/`.py` paths inside the scratch repo only.
- **`tests/overlap.test.sh`** fails on 8+ consecutive words shared with Killer SaaS; the gstack summary (`docs/references/gstack-agent-skills.md:23`) is French prose, not source — write the method text fresh.
- **Neighbours**: s49 and s52 also own `po-gate.sh` and depend on s48 (`docs/stories.md:739`, `:790`); they cannot run concurrently. Nothing reads the dispatch `case` except the hook `method/hooks/pre-commit:4` (calls `pre-commit` only).
- No migration, no screen, no setting, no new dependency (no `jq`, no python: `po-gate` has none today).

## Open questions
- Line number for findings with no added line (deleted file, assertions only removed, threshold removed): the plan picks the story-side position and `0` for a whole deleted file.
- Jest thresholds can be negative (max uncovered count, where lowering the number raises the bar). Treated as out of scope; the plan states it.
- Lint rules switched `off` in an ESLint config file, and coverage thresholds in `package.json` (`jest` key) or `setup.cfg`, are not in the story's list; the plan leaves them out and makes the list easy to extend.
- Multi-line empty `catch` across non-consecutive lines (comment inside the braces) is not detected; only same-line and two consecutive added lines.

## Complexity
Story 3 → 3. One self-contained bash/awk function, one bullet, one template box, one test file; the risk is in exit-code discipline and diff parsing, not in breadth.

## Split
Not needed.
