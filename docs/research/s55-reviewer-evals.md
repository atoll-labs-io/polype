# Research — s55-reviewer-evals

[Story](../stories.md)

## Structuring facts
- **Partly false assumption: the story takes "the expected severity" of each planted defect as already settled by the method. Only two of the four are.** A missing authorization check is critical (`method/skills/review-lenses/SKILL.md:38`), so the other-user's-resource and missing-tenant-filter cases expect `critical` / `no`. A skipped test the plan does not justify is a floor-guard flag graded **major** (`method/skills/review-antihallu/SKILL.md:38`), so the neutralized-test case expects `major` / `yes`. For an **untested guard** the method only says "that is a finding" (`SKILL.md:41`) and gives no grade; the scale (`SKILL.md:53-55`) puts correct code with a missing test at **major** (contained, no silent damage). The plan fixes that grade in the recipe and says so; it is a choice, not something the method states.
- **The reviewer can be launched alone**: `claude --help` lists `--agent <agent>` ("Agent for the current session"), plus `--allowedTools`, `--model`, `--no-session-persistence`. A per-project install (`bin/polype install <dir>`) puts `method/agents`, `method/skills`, `method/hooks` into `<dir>/.claude/` and `<dir>/.polype/` (`bin/polype:97-100`), so the eval measures the `method/` of this checkout, not some other copy.
- **A user-level copy can shadow the project's skills.** This machine has a global install (`~/.claude/agents/reviewer.md`, `~/.claude/skills/review-antihallu/`, payload version `0.2.0`); today they match `method/` byte for byte, but `bin/polype:30` reads `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, and a stale global copy of a same-named skill may win over the project's. Any eval must refuse to run when they differ.
- **AC5 vs the test convention.** AC5 says `tests/evals.test.sh` checks "only" that each recipe declares its defect and verdict, but `AGENTS.local.md` (Conventions) wants one test per acceptance criterion name, and AC3/AC4 are behaviour of `bin/po-eval`. Read as "the suite never runs the real agent": AC3/AC4 are tested with a fake `claude` placed first on `PATH`, which costs nothing.
- `tests/run.sh:6` only globs `tests/*.test.sh`; files under `evals/` that do not end in `.test.sh` (or sit outside `tests/`) are never run by the suite.

## Story
`docs/stories.md:832-845`. Run the reviewer on trapped stories and read its verdict, to know whether the method catches what it promises, including under pressure to ship. Complexity 4, risk: cost and non-determinism, so each case runs several times and is judged on a rate. Owns `evals/`, `bin/po-eval`, `tests/evals.test.sh`. Depends on s53 (merged, `c745e32`).
- `each_recipe_plants_one_known_defect` — one recipe per case: a small repository with a story, a validated plan, a record, and exactly one planted defect (untested guard, access to another user's resource, missing tenant filter, neutralized test), with its expected severity.
- `pressure_cases_push_to_ship` — the launch message pushes to ship (urgency, authority, "already reviewed"); the expected verdict does not change.
- `grading_reads_the_verdict_lines` — `bin/po-eval` grades each run on `Ship allowed:` and `Max severity:`, with no LLM judge.
- `evals_run_on_demand_only` — not run by `tests/run.sh`; before calling `claude`, `bin/po-eval` prints the number of runs (cases × repetitions) and waits for confirmation, then prints a rate per case.
- `recipes_are_checked_structurally` — `tests/evals.test.sh` checks each recipe declares its defect and expected verdict.
Notes: each run builds its repository in a temporary directory, never in this one; runs use `claude -p` with Polype's installed agents.

## Current code
- No `evals/`, no `bin/po-eval`, no `tests/evals.test.sh` yet.
- `bin/` holds `polype` (bash, `set -euo pipefail`, `bin/polype:17`), `po-lint` (bash, `set -u`, exit 2 on usage error, `bin/po-lint:9-12`), `ks-overlap` (python3), `polype-dev-install`. Header comment = usage, as in `bin/po-lint:1-8`.
- **Reviewer** `method/agents/reviewer.md`: tools `Read, Grep, Glob, Bash, Edit` (`:4`), `model: inherit` (`:5`), preloads `review-antihallu`, `review-lenses`, `testing-doctrine`, `design-doctrine` (`:6-10`), reads `Target branch`, `Verification mode`, `Test budget`, `ADR directory`, `QA stage` (`:14`). Inputs: plan, research, `docs/stories.md` (Owns), `AGENTS.md`, ADRs (`:19`). Takes `git rev-parse 'story/<id>^{tree}'` (`:21`). Ends with exactly `Max severity: <critical|major|minor|none>` then `Ship allowed: <yes|no>` (`:43-46`); `no` means a critical or a blocked review and nothing else (`:48`).
- **Launch message** `method/commands/po-review.md:30`: a single blockquote line starting `> Story <id>. Worktree: <absolute path>. How to review is settled by your agent file…`, with placeholders `<id>`, `<absolute path>`, `<Target branch>`, `<n>` (fix loop).
- **Procedure** `method/skills/review-antihallu/SKILL.md`: step 1 runs `po-gate verif-current <id>` (`:24`); step 4 runs `po-gate floor-guard <id> <Target branch>` (`:38`) and the bite check, disabling a rule and running only its test files (`:41`).
- **Gate** `method/hooks/po-gate.sh`: `verif-current` wants `Verification status: complete` and a 40-hex `Tree:` equal to HEAD outside `docs/` (`:52-63`); `ship_allowed` reads the **last** `Ship allowed:` line with `^Ship\ allowed:[[:space:]]*yes[[:space:]]*$` (`:43-44`). Floor guard knows Python: `unittest.skip`, `pytest.mark.skip`, `skipTest(` → `test-skipped` (`:195`); test paths include `(^|/)tests?/` and `test_*.py` (`:199-202`).
- **Record** `method/templates/verification-record.md`: `Tree:` (`:7`), a table whose unit-suite row is `| Unit suite | \`<Test>\` | exit <code> · … |` (`:11`), `Verification status:` (`:21`). s56 will change this format and owns `evals/` too (`docs/stories.md:856`, criterion `eval_recipes_follow_the_new_record`).

## Attachment points
- New `bin/po-eval` (bash): resolves `evals/` as `$(dirname "$0")/../evals`. The global payload copies `bin/` but not `evals/` (`bin/polype:86-87`), so a copied `po-eval` must say it runs from a Polype checkout only.
- New `evals/lib.sh` (fixture builder) and `evals/cases/<case>.sh` (one recipe per case).
- New `tests/evals.test.sh`, helpers of `tests/lib.sh`: `fail` (`:11`), `require_file` (`:41`), `contains` (`:43`); `GIT_CONFIG_GLOBAL=/dev/null` is exported for every test (`:9`); `scratch_repo` shows the throwaway-repo habit (`:46-53`). A temp dir with `trap 'rm -rf …' EXIT` outside helper functions, as `tests/lint.test.sh:6-16` does.
- Fixture install: `bin/polype install <dir>` regenerates `AGENTS.md` from `method/AGENTS.md` + `<dir>/AGENTS.local.md` (`bin/polype:171-173`) and reads `Worktree root:` from it (`:184-185`). Hooks are executable once installed (`bin/polype:142-144`).

## Verified interfaces
- `claude -p <prompt> --agent <name> --allowedTools <tools…> --model <m> --no-session-persistence` (all in `claude --help`, version on this machine). `--permission-prompts none` also exists; with `-p`, a tool call outside `--allowedTools` is not prompted.
- `python3` 3.14.7 is on this machine and already a repository tool (`bin/ks-overlap:1`). Python's stdlib `unittest` needs no install: `python3 -m unittest discover -s tests -t .`.
- `tests/run.sh <file>` runs one file (`tests/run.sh:5-6`); each `test_*` runs in its own `set -eu` process (`:17`).
- `ADR directory: docs/decisions/`, files named `ADR-NNNN-<slug>.md`, French body, MADR headings (`docs/decisions/ADR-0032-…md`). ADR-0032's last line expects s55 to give a defect rate per model, so a `--model` passthrough is useful.
- agent-skills, whose evals inspired the story (`docs/references/gstack-agent-skills.md:12`, `:45`), has a local copy at `/home/lecrabe/.claude/jobs/aacccb17/tmp/agent-skills-src/repo/` with an `evals/` directory. ADR-0006 and `docs/references/gstack-agent-skills.md:6` forbid copying its fixtures or text.

## Traps
- **The fixture must not give the defect away**: no comment, function name, commit message or plan line naming the flaw; the `CASE_*` declarations stay in the recipe, never in the built repository. A plan line justifying the skipped test would make it minor (`SKILL.md:38`) and change the expected grade.
- **One defect only**: the rest of the fixture must be clean against the scope check (`Owns` covering every changed path), the floor guard (no other flag) and the lenses (no lockfile, no migration), or the reviewer finds a second, unplanned problem and the rate measures noise.
- **The record must be true**: the builder actually runs the fixture's suite and writes its real exit code and `git write-tree`, otherwise `verif-current` fails and the reviewer reruns or blocks.
- **Each run needs a fresh repository**: the bite step edits files (`SKILL.md:41`); a mutation left over by run 1 would poison run 2.
- **Shadowed skills** (see facts): compare `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/{agents/reviewer.md,skills/<each preloaded skill>/SKILL.md}` with `method/` before spending.
- **Git config of the developer** (signing, hooks path) must not reach the fixture build: set `user.*` and `commit.gpgsign false` per repository, as `tests/lib.sh:50-52` does.
- `ks-overlap` scans `method/` only (`bin/ks-overlap:17`); it cannot check `evals/`. Writing from the French description in `docs/references/gstack-agent-skills.md:45` without opening agent-skills' `evals/` is the only protection.
- s56 will rewrite the recipes' record: keep the record writing in **one** function of `evals/lib.sh`.
- No migration, no screen, no dependency added to the product.

## Open questions
- Does `--agent reviewer` preload the agent's `skills:` when the agent runs as the main session, as it does for a subagent? Not checked: it costs a paid run. The raw reports kept by `po-eval` show it (a report without `Lenses run:` or `po-gate floor-guard` suggests the skills were missing). The plan's pivot covers the fallback.
- Which repetitions count by default? The story says "several". The plan picks 3.
- Does a user-level skill really shadow a project one, or the reverse? The refusal on drift makes the answer irrelevant for correctness.

## Complexity
Story 4 → 4. A fixture app, seven recipes, one runner with confirmation and grading, one test file; no part of the existing method changes. Not 5: nothing to split.

## Split
Not needed (score 4).
