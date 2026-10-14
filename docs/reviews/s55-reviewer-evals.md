# Review — s55-reviewer-evals

[Story](../stories.md) · [Plan](../plans/s55-reviewer-evals.md) · [Verification](../verif/s55-reviewer-evals.md)

Diff reviewed: `git diff main...story/s55-reviewer-evals`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 208289c5c13d3478b79db134794b3094cffc132c

## Ownership
I listed the diff with `git diff --name-only main...story/s55-reviewer-evals` and held each path against `Owns: evals/, bin/po-eval, tests/evals.test.sh`.
- [x] `bin/po-eval`, `evals/lib.sh`, the seven files under `evals/cases/` and `tests/evals.test.sh` are all inside `Owns`.
- [x] `docs/research/`, `docs/plans/` and `docs/verif/s55-reviewer-evals.md` are the story's own pipeline evidence, so they are in scope by construction.
- [x] `docs/decisions/ADR-0033-evals-du-reviewer-en-depot-jetable.md` is outside `Owns`. It is required by the written rule "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`", so the gap is in the story's `Owns`, not in the implementer's work. Minor.
- [x] No path falls inside another running story's `Owns`. `git worktree list` showed s57-qa-in-the-fleet, which owns `method/commands/po-review.md`. This story only reads that file (see Neighbours) and does not change it. The s57 worktree had gone by the end of the review. s56 also owns `evals/`, but it has no worktree.

## Evidence reused
- [x] `po-gate verif-current s55-reviewer-evals` exited 0. `git diff --quiet 01c6f597… HEAD -- . ':(exclude)docs'` came back clean. The record is complete, all exit codes are 0, and it shows 287 tests passed with `bin/po-lint` clean. I relied on it and did not rerun the suite. `Typecheck: —`: the project has none. I read the "Not proven here" section: it covers no real `claude` run, the unverified `--agent` skill preload, and `evals/` not being checked by the overlap scan.
- [x] `po-gate qa-current` is not required: the story has no screen and `QA stage` is not set to screens.

## Plan
- [x] Tasks 1–6 are all present:
  - `evals/lib.sh` has `eval_base`, `eval_story`, `eval_record` and `eval_research`.
  - There are four defect recipes and three pressure recipes, each declaring `CASE_BASE=foreign-resource`.
  - `bin/po-eval` has the loader, drift check, confirmation, launch message, grading and report.
  - `tests/evals.test.sh` has five tests.
  - There are no changes outside what the plan lists.
- [x] Each run interdict holds:
  - `method/`, `.claude/`, `.polype/`, `bin/polype`, `tests/run.sh`, `tests/lib.sh` and existing tests are untouched.
  - No `evals/**/*.test.sh` file exists.
  - The tests call `claude` only through the fake.
  - Fixtures go under `mktemp -d`; I built one and the worktree stayed clean.
  - Fixtures do not name their flaw. `test_each_recipe_plants_one_known_defect` greps for this, and I read the recipes.
  - ADR-0033 is the only new ADR.

## References
- [x] I opened every reference and confirmed it:
  - `method/commands/po-review.md:30` (the `> Story <id>.` line exists).
  - `method/agents/reviewer.md`: `skills:` uses `  - ` items, which the awk parser expects.
  - `po-gate.sh:42-43`: the strict last-line verdict regex matches `grade()`.
  - `bin/polype install <repo>`: a built fixture holds `.claude/agents/reviewer.md` and the four preloaded skills.
  - `claude --help` lists `--agent`, `--allowedTools`, `--no-session-persistence` and `--model`.
- [x] Values:
  - The default `--repeat 3` and the integer percentage match the plan.
  - The expected severities match the plan's decision table.
  - The drift check passes on this machine: `~/.claude` agent and skills are identical to `method/`.

## Rules
- [x] `AGENTS.local.md` conventions are respected: bash tests using `tests/lib.sh` helpers, English, and test functions named after the criteria.
- [x] ADR-0006 (no copied text) and ADR-0033 are not contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s55-reviewer-evals main` → exit 0, nothing lowered.
- [x] The assertions match the five criteria. The fake `claude` only stands in for the model's text and decides nothing that the code under test decides.
- [x] 5 tests, against a `Test budget` of 25.
- [x] Bite 1: I made every answer pass the confirmation (`*) ;;`) → 1 failing test (`evals_run_on_demand_only`) → undone, `git diff --exit-code` clean.
- [x] Bite 2: I changed `grade()` to read the first verdict line instead of the last (`tail` → `head`) → 1 failing test (`grading_reads_the_verdict_lines`) → undone, clean.
- [x] Bite 3: I made `drift_check()` return 0 straight away → **0 failing tests** → undone, `git diff --exit-code` clean. See Findings.
- [x] No test is made useless by the story.

## Neighbours
- [x] `po-eval` depends on the launch line in `method/commands/po-review.md`. s57's change to that file leaves line 30 as it was. If that line ever moves, `po-eval` exits 2 with a clear message.
- [x] `bin/polype install` and `po-gate.sh` are used unchanged.

## Lenses
Lenses run: security — triggered by content. The fixture heredocs in `evals/cases/*.sh` contain owner and tenant checks on records, and `bin/po-eval` assembles a prompt for an LLM (`claude -p`). The owner and tenant flaws are planted on purpose in throwaway repositories and never reach the product. The model's output is only grepped for its verdict lines and is never executed or rendered. The prompt holds no secret.
- [x] The lens finding (the major below, about the trust placed in the verdict lines) is graded and listed.

## Findings
- **major** — `bin/po-eval:91` (`grade`) — A report that says `Review status: blocked` is graded only on its verdict lines.
  - A blocked report ends `Ship allowed: no`, and per `po-review.md` with `Max severity: critical`. That is exactly the expectation of `foreign-resource`, `missing-tenant-filter` and all three pressure cases.
  - So a reviewer that never found the flaw — for example because `--agent` did not preload its skills (plan pivot 1), or because a tool was missing — counts as a pass, and the catch rate is silently inflated.
  - A deterministic check fixes this without an LLM judge: grade a blocked report as its own label, e.g. `blocked`.
- **minor** — `bin/po-eval:54-71` (`drift_check`) — The drift check is not tested: disabling it fails none of the five tests, because the tests use an empty `CLAUDE_CONFIG_DIR`.
  - The check also only compares files that exist in the user copy. A skill file present in `method/` but missing from `~/.claude/skills/<skill>/` is not reported.
- **minor** — `tests/evals.test.sh:28` / `bin/po-eval:137` — Every test invocation of `po-eval` leaves a `results` directory behind in the system temp directory. During this review, `/tmp/tmp.*` grew from 28 to 41 entries.
  - Exporting `TMPDIR="$EVTMP"` in `po_eval` would keep them under the trap-cleaned directory.
- **minor** — `docs/decisions/ADR-0033-evals-du-reviewer-en-depot-jetable.md` — This file is outside the story's `Owns`. The rule that ADRs live under the ADR directory requires it, so the gap is in `Owns`; no code change is needed.

## Not verified
- **No real `claude -p --agent reviewer` run**: it is paid, and running it needs a person's confirmation by design.
  - So it is unverified whether `--agent` preloads the reviewer's `skills:`, and whether a real report ends with the two exact verdict lines.
  - Whether the expected severities (especially `major` for `untested-guard` and `neutralized-test`) are what the method actually produces is also unverified.
  - A person should run `bin/po-eval --repeat 1 foreign-resource untested-guard` once and read the kept reports against `templates/review.md`: look for a `Lenses run:` line, a floor-guard run and bite counts.
- **Unprompted shell access in a real eval run**: the runner passes `--allowedTools "Read Grep Glob Bash Edit"`. A real run therefore lets the model run any shell command on the user's machine without asking, inside a temporary repository. I did not observe any real run.
- **`evals/` against agent-skills (ADR-0006)**: `bin/ks-overlap` does not scan `evals/`, so I did not machine-check it. I only read the recipes for borrowed text and found none obvious.
- **Interactive confirmation**: I did not exercise `[ -t 0 ]` and the newline handling on a real terminal; only the piped stdin was tested.

Max severity: major
Ship allowed: yes
