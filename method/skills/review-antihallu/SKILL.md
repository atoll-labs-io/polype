---
name: review-antihallu
description: The review procedure that catches what an agent gets plausibly wrong — invented APIs, drift from the plan, tests that do not bite, values never checked. Preloaded in the reviewer; the only home of the procedure.
---
# Anti-hallucination review

Generated code is plausible. Plausible is not correct. This review hunts the gap, and a context that did not write the code sees it best.

## Procedure — every step, in order

**1. Start from what is already proven.** The implementer wrote `docs/verif/<id>.md`. Check it with `po-gate verif-current <id>` (or `git diff --quiet <Tree> HEAD -- . ':(exclude)docs'` where the hook is not installed).
- **Current** — exit 0, `Verification status: complete`, every recorded exit code 0 — with `Verification mode: record`: the suite and the type check are proven for this exact code. Do not run them again. Say what you took from the record and read its "Not proven here".
- **Missing, incomplete, stale, a non-zero exit code, or `Verification mode: rerun`** → run them yourself and say why.

Prose saying "tests pass" is a claim; a record whose tree matches the commit is a fact. An absent record is never a pass.

Do not run the production build or the end-to-end suite: they run at ship. One exception: a diff that moves a route or a manifest, the break a type check cannot see. Take the linter and the formatter as recorded.

**2. Open every reference.** For each import, call, API and configuration key in the diff, open its target and check the name, the signature and the location. Invented references are the most common agent failure.

**3. Compare the diff with the plan, task by task.** Every task present? Anything the plan never asked for? Drift either way is a finding. So is a diff that contradicts a verified fact of the research or an accepted ADR, or one that breaks a run interdict.

**4. Read the tests like production code.**
- *The net.* Look for tests that name a rule without exercising it — the six shapes of the `testing-doctrine` skill. Read the fixtures and the mocks, not only the assertions. Decorative tests (CSS classes, DOM structure, static labels, echoed props, inventories) are not coverage.
- *The volume.* `Test budget` per story unless the plan justified more. A permission matrix replayed per command, an enum tested pair by pair, an adapter re-asserting a 403: each is a minor finding, worth naming because CI time is real.
- *The bite.* Take the one or two invariants the story turns on — a guard, a predicate, a state transition, a query clause — and neutralize each: invert the condition, return the opposite constant, drop the clause. **Run only the test files that name that invariant, never the whole suite.** Count the red tests. Restore, and prove the tree clean with `git diff --exit-code` on the file **before writing a line of the report**. Report what you neutralized and how many tests turned red. **Zero red means the invariant is untested**, whatever the suite total says: a finding, not a detail. A presentational change needs browser evidence, not a forced mutation. An unrestored mutation is worse than the defect you were looking for.

**5. Hunt plausible-but-wrong values.** Defaults, formats, status codes, limits, edge conditions that look right and were never checked against reality.

**6. Look for regressions.** What else calls the code this diff touched? Open it.

## Severity

- **critical** — ships a bug, a security hole, an invented API, or breaks existing behaviour. Blocks the ship.
- **major** — a real defect or rule violation, contained and not silently corrupting anything. Ship allowed; fixed in a later cycle.
- **minor** — style, naming, small cleanups.
