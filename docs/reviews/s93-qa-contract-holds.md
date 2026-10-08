# Review: s93-qa-contract-holds

Reviewed tree: b0dff26dea0681f63c2356de28927dba062d15a3
Fix loop: 0
Scope: `git diff main...story/s93-qa-contract-holds`. One commit, `dfd1eff`.
Lenses run: none. The diff touches only method prose and a bash test, so no security, migration, dependency or performance trigger fires.

## Scope check (Owns)
The diff touches seven paths:
- `method/agents/qa.md`, `method/skills/qa-drivers/SKILL.md`, `method/skills/qa-drivers/scenarios.md` and `tests/qa-contract-holds.test.sh` are all in the `Owns` line.
- `docs/research|plans|verif/s93-qa-contract-holds.md` are this story's own pipeline evidence, so they are in scope by construction.

Nothing is outside `Owns`.

The plan's run interdicts hold:
- The frontmatter of qa.md is unchanged.
- The pinned sentence at qa.md:43 is byte-identical.
- `tests/qa.test.sh`, `tests/qa-drivers.test.sh` and `tests/scenario-driver.test.sh` are unchanged.
- No ADR, nothing under `.claude/` or `.polype/`, no change to po-bounds.

## Evidence relied on
- **Verification record.** `po-gate verif-current s93-qa-contract-holds` exited 0 (`Verification mode: record`). Its runs show Unit suite `bash tests/run.sh` exit 0 and Lint `bash bin/po-lint` exit 0 on the recorded code. I did not rerun the full suite.
- **Commands the project lacks.** Typecheck, E2E and Build are `—` in this project, so none of them ran.
- **"Not proven here" in the record.** It says only a real `/po-qa` run shows whether a qa subagent obeys the new prose. That item is carried into Not verified below.
- **QA.** The story has `Surface: —`, so it does not go to QA and there is no QA report to check.
- **Floor guard.** `po-gate floor-guard s93-qa-contract-holds main` exited 0: nothing was lowered.
- **Focused run.** `bash tests/run.sh qa-contract-holds.test.sh qa.test.sh qa-drivers.test.sh scenario-driver.test.sh` gave 19 passed, 0 failed.

## Plan conformity
- Tasks 1 to 5 are all present and match the plan's wording, quoted sentences included.
- `settings_read_by`, `contains`, `require_file`, `fail` and `METHOD` exist in `tests/lib.sh`.
- `Install` and `Build` exist in `method/templates/agents-local.md`.
- No change was made that the plan did not ask for.

Neighbours:
- `method/commands/po-qa.md:27` already stops a story whose surface is `—`, so the new zero-row rule cannot block a story that has nothing to check.
- No other method file quotes the changed qa.md wording ("Two sources", "before the walk").

## Bite (ADR-0012)
I ran each mutation on the owned file, then ran only `qa-contract-holds.test.sh`, plus `scenario-driver.test.sh` for the scenarios.md mutations. I undid each one with `git checkout -- <file>`. `git diff --exit-code` was clean at the end.

| # | Mutation | Tests failing |
| --- | --- | --- |
| M1 | qa.md step 2: zero-row sentence deleted | 1 (no_driver_row_blocks) |
| M2 | qa.md step 2: zero-row consequence flipped to `QA status: complete` | **0** |
| M3 | SKILL.md: zero-row paragraph deleted | 1 |
| M4 | qa.md: "never `complete`" sentence deleted | 1 |
| M5 | scenarios.md: `outside docs/qa/<id>/` exception removed | 1 (own_evidence_never_blocks) |
| M6 | scenarios.md: "→ blocked, naming that path" replaced | 1 (scenario_rules_bite) |
| M7 | scenarios.md: scratch-folder sentence deleted | 1 |
| M8 | scenarios.md: "a success code on bad input," deleted | 1 |
| M9 | scenarios.md: 60-second consequence replaced by "keep waiting" | **0** |
| M10 | scenarios.md: "through Bash (a heredoc)" deleted | 1 |
| M11 | qa.md: `Install` dropped from Reads settings | 1 |
| M12 | qa.md: plan line dropped from Scope | 1 |

## Findings

1. **major: the 60-second bound's consequence is not tested.** File: `tests/qa-contract-holds.test.sh`, `test_own_evidence_never_blocks`, the check `line_holds "$SCENARIOS" 'within 60 seconds' 'QA status: blocked'`.
   - The whole API paragraph of `method/skills/qa-drivers/scenarios.md` is one line. The very next sentence ("It prints that it listens on another port … → stop it and end with `QA status: blocked`") already supplies `QA status: blocked`.
   - So when I replaced the 60-second branch's consequence with "keep waiting" (M9), every test stayed green. Only the phrase "within 60 seconds" is pinned.
   - The criterion `own_evidence_never_blocks` ("un service qui ne répond pas dans le délai donne `blocked`") therefore has no test that fails when its rule disappears. The plan's pivot point 2 promised that the same-line checks prevent exactly this.
   - Fix: pin a phrase unique to that sentence, e.g. `within 60 seconds → stop it and end with \`QA status: blocked\``.

2. **minor: the qa.md zero-row consequence can be flipped without a test failing.** Same file, `test_no_driver_row_blocks`.
   - Step 2 of qa.md is one line, and it also holds the missing-file rule's `QA status: blocked`. Flipping the zero-row consequence to `complete` (M2) leaves the test green.
   - This is graded minor because the separate pinned sentence "A walk that followed no driver file is never `complete`" (M4 bites) still holds the rule's intent, and SKILL.md's paragraph is pinned on its own line (M3 bites).
   - Fix: pin `set to \`—\` → write the report with \`QA status: blocked\``.

3. **minor: the first QA in a project can block on its own evidence.** File: `method/skills/qa-drivers/scenarios.md`, the before/after paragraph; the same applies to qa.md step 7.
   - The exception reads "a path outside `docs/qa/<id>/`". When `docs/qa/` does not exist yet, which is the first QA in a project, `git status --porcelain --ignored` collapses the new evidence into one line, `?? docs/qa/`.
   - I confirmed this in a throwaway repo under `/tmp/tmp.CoENtz5KRU/p`: the output was `?? docs/qa/`.
   - That path is a parent of `docs/qa/<id>/`, not inside it. An agent that compares literally ends `blocked` on its own evidence, which is the very case `own_evidence_never_blocks` targets.
   - The failure is visible (`blocked`, never a false `complete`), so it is minor. `--untracked-files=all`, or a sentence saying a parent line covering only `docs/qa/<id>/` is set aside, would close it.

## Values questioned
- **The 60-second bound** is supported only by the plan's own reasoning (pivot point 3: it runs after Install and Build, so it covers only the start, and a too-short bound fails visibly as `blocked`). No ADR or measurement backs it. It is acceptable as a tunable value; this is not a finding.

## Not verified
- **Whether a real `qa` subagent obeys the new prose** (zero-row block, the `docs/qa/<id>/` exception, writing the scratch script through a Bash heredoc, the 60-second bound). Nothing here runs an agent. To cover it, a person runs `/po-qa` on a `command`/`cli` and an `endpoint`/`api`/`lib` story in a project with QA enabled, and once with `Platform` missing or `—`.
- **That po-bounds really lets a qa agent write the heredoc script** through Bash under the temp dir. I read the plan's and research's claim about `po-bounds.sh:271-278`, but did not exercise the hook in `qa` mode.
- **The full unit suite and the lint**: I took them from the record and did not rerun them.

Max severity: major
Ship allowed: yes
