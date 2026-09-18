---
name: review-antihallu
description: Polype's review procedure for agent-written code — reuse proven runs, open every reference, compare with the plan, make the tests prove they bite, question plausible values, look for collateral damage. Preloaded in the reviewer; nowhere else.
---
# Reviewing code an agent wrote

Agent code usually looks right. The review exists for the cases where looking right and being right diverge, and a reader who did not write the code is the one who notices.

## Six steps, all of them, in this order

**1. Reuse what is already proven.** Run `po-gate verif-current <id>`; without the hook, `git diff --quiet <Tree> HEAD -- . ':(exclude)docs'` from the worktree root does the same comparison.
- With `Verification mode: record`, a record that passes — status complete, all exit codes 0 — proves the unit suite and the type check for this exact code. Do not rerun them; write in the report what you relied on, and read its "Not proven here" section.
- With `Verification mode: rerun`, or a record that is missing, incomplete, outdated or shows a non-zero exit code: run both yourself and say why.

A sentence saying the tests pass is an opinion; a record whose tree equals the commit is evidence. No record, no evidence.

Leave the end-to-end suite and the production build to ship, except when the diff changes routing or a manifest — the kind of break a type check does not see. Lint and formatting results are taken from the record.

**2. Open everything the diff refers to.** Imports, calls, APIs, configuration keys: open the target of each and confirm name, signature and location. References to things that do not exist are the most frequent agent mistake.

**3. Hold the diff against the plan.** Go task by task. A missing task and an unrequested change are both findings. The same goes for code at odds with what the research established, with an accepted ADR, or with a run interdict.

**4. Make the tests prove themselves.**
- *Coverage that is only apparent.* Check for the six kinds of test that prove nothing, listed in the `testing-doctrine` skill. Read fixtures and mocks, not only assertions. Tests of CSS classes, DOM shape, fixed labels, echoed props or inventories do not count as coverage.
- *Excess.* Within `Test budget` unless the plan justified more. Access rules replayed per command, exhaustive enum pairs, adapters retesting a 403: minor findings, still worth naming for the CI time they cost.
- *Bite.* Choose the one or two rules the story depends on — a guard, a condition, a state change, a query filter — and disable each in turn: flip the condition, return the opposite, remove the filter. After each change, run **only the test files that exercise that rule**. Count the tests that fail, then undo the change and confirm with `git diff --exit-code <file>` that the file is back to its committed state, before writing anything. Report each change and its count. **A disabled rule that fails no test is not tested**, however large the suite; that is a finding. Presentation-only changes need a look in the browser rather than a forced mutation. Leaving a mutation in place is worse than any defect you could have found.

**5. Question values that merely look right.** Defaults, formats, status codes, limits, boundary conditions: find where each is confirmed, or report that nothing confirms it.

**6. Check the neighbours.** Find the other callers of what the diff changed and read them.

## Severity

- **critical** — users would get a defect, an exploitable flaw, a call to something that does not exist, or a regression in what already worked. The ship is blocked.
- **major** — a genuine defect or rule breach, contained, with no silent damage. The ship may go ahead; the fix waits for a later cycle.
- **minor** — naming, style, small tidying.
