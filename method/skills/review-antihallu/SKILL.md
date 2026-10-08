---
name: review-antihallu
description: Polype's review procedure for agent-written code — reuse proven runs, open every reference, compare with the plan, make the tests prove they bite, question plausible values, look for collateral damage. Preloaded in the reviewer; nowhere else.
---
# Reviewing code an agent wrote

Agent code usually looks right. The review exists for the cases where looking right and being right diverge, and a reader who did not write the code is the one who notices.

## Before anything: the diff stays inside `Owns`

The `Owns` line of the story in `docs/stories.md` lists the paths it may change, and a directory owned by one story covers every path beneath it. List what the diff really touched — `git diff --name-only <Target branch>...story/<id>` — and hold each path against that line. This comes first because it decides what the rest of the review reads: a file nobody declared is read with different eyes than one the plan announced.

- **Outside `Owns` → major.** Name the path and the `Owns` line it missed, so the choice is visible: drop the change, or widen the story's scope on purpose.
- **Inside another running story's `Owns` → critical.** The path belongs to a story whose worktree appears in `git worktree list` and whose `story/<id>` branch is not merged into `Target branch`. Two lanes are writing the same file, and at ship one of the two edits disappears.

Four cases the bare comparison gets wrong:

- **The story's own pipeline evidence is in scope by construction** — `docs/research/<id>.md`, `docs/plans/<id>.md`, `docs/verif/<id>.md`, `docs/reviews/<id>.md`, `docs/designs/<id>/`, `docs/qa/<id>/`. No `Owns` lists them, and none has to.
- **An ADR the diff adds under `<ADR directory>` and the story's plan names** is in scope by construction too: "adds" is status `A` in `git diff --name-status <Target branch>...story/<id>`, and "names" is the plan's text giving its file name or its `ADR-NNNN` number. An ADR the plan does not name falls back to the other cases; an existing ADR the diff modifies is never covered.
- **A path a written rule of `AGENTS.md` requires** is not a breach by the implementer but a gap in the story's `Owns`: quote the rule, report it **minor**, and leave the code alone.
- **A story with no `Owns` line at all** is reported as unverifiable scope. The check did not run; saying nothing would pass it off as clean.

## Six steps, all of them, in this order

**1. Reuse what is already proven.** Run `po-gate verif-current <id>`; without the hook, do both checks of `verif-current` by hand from the worktree root: `git diff --quiet <Tree> HEAD -- . ':(exclude)docs'` for the tree, then, for each row of `## Checks`, look in `## Runs` for a row with the same label and command, on a tree whose code outside `docs/` equals `<Tree>`, and require that the last such row exited 0.
- With `Verification mode: record`, a record that passes — status complete, all exit codes 0 — proves the unit suite and the type check for this exact code. Do not rerun them; write in the report what you relied on, and read its "Not proven here" section.
- With `Verification mode: rerun`, or a record that is missing, incomplete, outdated or shows a non-zero exit code: run both yourself and say why.
- For a story with a screen, when `QA stage` is `screens`: run `po-gate qa-current <id>` as well. It fails — no report, `QA status: blocked`, or a `Tree:` the code has moved away from, or a report that is current but not committed — → the review is blocked, the gate's message as `Failure cause:` and `/po-qa <id>` as `Next action:`. The one exception is the report that is current but not committed: its `Next action:` is the evidence commit the gate names, `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`, not a new walk, and it does not name `/po-qa`. It passes → the code is the one walked, so each **verified** finding of the report is still open and becomes a finding of this review, graded on this skill's scale; probable and unverified ones go to `## Not verified` unless you confirm them. With `QA stage: —`, or no screen, there is no QA to require.

A sentence saying the tests pass is an opinion; a record whose tree equals the commit is evidence. No record, no evidence.

Leave the end-to-end suite and the production build to ship, except when the diff changes routing or a manifest — the kind of break a type check does not see. Lint and formatting results are taken from the record.

**2. Open everything the diff refers to.** Imports, calls, APIs, configuration keys: open the target of each and confirm name, signature and location. References to things that do not exist are the most frequent agent mistake.

**3. Hold the diff against the plan.** Go task by task. A missing task and an unrequested change are both findings. The same goes for code at odds with what the research established, with an accepted ADR, or with a run interdict.

**4. Make the tests prove themselves.**
- *Floor.* Run `po-gate floor-guard <id> <Target branch>` from the worktree before reading any test: it lists what the diff does to make the checks easier to pass. Exit 0: nothing was lowered. Exit 1: each printed line is a flag: justified in the plan → **minor**, otherwise **major**, except that a deleted test file the plan does not justify → **critical**. Justified means the plan names the file or the directive and gives the reason. Exit 2: the guard could not verify, which is never clean: the review is blocked, with the guard's message as `Failure cause:`.
- *Coverage that is only apparent.* Check for the six kinds of test that prove nothing, listed in the `testing-doctrine` skill. Read fixtures and mocks, not only assertions. Tests of CSS classes, DOM shape, fixed labels, echoed props or inventories do not count as coverage.
- *Excess.* Within `Test budget` unless the plan justified more. Access rules replayed per command, exhaustive enum pairs, adapters retesting a 403: minor findings, still worth naming for the CI time they cost.
- *Bite.* Choose the one or two rules the story depends on — a guard, a condition, a state change, a query filter — and disable each in turn: flip the condition, return the opposite, remove the filter. After each change, run **only the test files that exercise that rule**. Count the tests that fail, then undo the change and confirm with `git diff --exit-code <file>` that the file is back to its committed state, before writing anything. Report each change and its count. **A disabled rule that fails no test is not tested**, however large the suite; that is a finding. Presentation-only changes need a look in the browser rather than a forced mutation. Leaving a mutation in place is worse than any defect you could have found.

**5. Question values that merely look right.** Defaults, formats, status codes, limits, boundary conditions: find where each is confirmed, or report that nothing confirms it.

**6. Check the neighbours.** Find the other callers of what the diff changed and read them.

## After the six steps: the lenses

Run each lens of the preloaded `review-lenses` skill whose trigger the diff contains. Grade what it finds on the scale below, list it under `## Findings`, and record the lenses on the report's `Lenses run:` line.

## Severity

- **critical** — users would get a defect, an exploitable flaw, a call to something that does not exist, or a regression in what already worked. The ship is blocked.
- **major** — a genuine defect or rule breach, contained, with no silent damage. The ship may go ahead; the fix waits for a later cycle.
- **minor** — naming, style, small tidying.
