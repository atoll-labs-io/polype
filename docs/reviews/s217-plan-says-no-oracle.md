# Review — s217-plan-says-no-oracle

[Story](../stories.md) · [Plan](../plans/s217-plan-says-no-oracle.md) · [Verification](../verif/s217-plan-says-no-oracle.md)

Method version: 0.13.0
Recorded: 2026-11-27T10:43:53+01:00

Review status: complete
Reviewed tree: 8b3b354c27d002b9c18b759b77e7af899cebbd0f
Fix loop: 0
Lenses run: none (no security, migration, dependency or performance trigger in the diff: `method/hooks/po-gate.sh` reads a plan file, with no auth, routes, lockfiles or queries)

## Scope
`git diff --name-only main...story/s217-plan-says-no-oracle` lists 7 paths. All of them are in scope:
- `method/agents/planner.md`, `method/hooks/po-gate.sh`, `method/templates/plan-flow.md`, `method/templates/plan.md` and `tests/plan-says-no-oracle.oracle.test.sh` each match an entry of the `Owns` line (`docs/stories.md:3534`).
- `docs/plans/s217-plan-says-no-oracle.md` and `docs/verif/s217-plan-says-no-oracle.md` are the story's own pipeline evidence.

The diff touches no path outside `Owns`. The run interdicts hold: `method/word-budget`, `po/`, `bin/polype`, `method/commands/po-plan.md`, `tests/oracle-intact-gate.oracle.test.sh`, `.claude/` and `.polype/` all have an empty diff. The story was planned on the short track, so it has no research file, and the plan's `## Verified facts` takes its place.

## What I relied on
- **Record:** `po-gate verif-current s217-plan-says-no-oracle` exited 0.
  - The record's `Tree: 2d27836…` equals HEAD outside `docs/`.
  - The last `Unit suite` run (`bash tests/run.sh`, tree `425618c…`, which also equals HEAD outside `docs/`) exited 0.
  - `Verification mode: record` applies, so I did not rerun the suite.
  - The project has no type check (`Typecheck: —`).
  - "Not proven here" defers end to end and build to ship (both are `—` in this project). It says `bin/po-lint` was run by hand. I reran it: "no breach in 25 file(s) of method/", exit 0.
- **QA:** `QA stage: —`, so this story does not go to QA.
- **Oracle:** `po-gate oracle-intact` exited 0. Both the installed gate and the story's own `method/hooks/po-gate.sh` agree. `cksum < tests/plan-says-no-oracle.oracle.test.sh` gives `3322980070 2733`, the sum the plan records. `## Oracle changes` is empty.
- **Floor:** `po-gate floor-guard s217-plan-says-no-oracle main` exited 0, so nothing was lowered.
- **Focused run:** `bash tests/run.sh plan-says-no-oracle.oracle.test.sh oracle-intact-gate.oracle.test.sh` gave 4 passed, 0 failed.

## Plan conformity
- **Task 1 (gate):** done as planned.
  - The empty-table branch now needs a `—` line with a reason (`/^—[[:space:]]*[^[:space:]]/`). The exit-0 stdout keeps its wording, which `po/src/trust/signals.rs:69` matches with "has no oracle".
  - A bare `—`, a missing `—`, and a placeholder row whose path starts with `—` now go to `oracle_unreadable`. Each message names the form to write.
- **Task 2 (templates):** the same 30-word sentence replaces the old one in both templates. The `| Oracle file | cksum |` table is kept in both.
- **Task 3 (planner):** "in that criterion's row, never in the oracle table." replaces the old clause, at the same word count.
- **Prose half of the criteria** (speaks to a model, judged by reading): `planner.md` and both templates now describe one form.
  - With no oracle file, a `—` line with its reason replaces the oracle table.
  - A criterion without a test explains itself in its criterion-table row.
  - `method/commands/po-plan.md:32` ("in that criterion's row") is outside `Owns`. It stays compatible with that form.
- **Neighbours:**
  - `po/src/record/mod.rs:212` and `po/src/trust/signals.rs:63-69` read only the exit code and the exit-0 stdout, and both are unchanged.
  - No other text in `method/` describes the old "in place of both tables" form.

## Bite
- **Mutation 1:** I loosened the reason regex at `method/hooks/po-gate.sh:620` back to `/^—/`. `plan-says-no-oracle.oracle.test.sh` then had 1 test failing: `missing_oracle_still_refused`, because a bare `—` exited 0. Restored, and `git diff --exit-code method/hooks/po-gate.sh` exited 0.
- **Mutation 2:** I deleted the placeholder-row branch (`[[ "$path" == —* ]]`, lines 630-631). 1 test failed: `missing_oracle_still_refused`, because the message no longer named the form. Restored, and `git diff --exit-code` exited 0.
- The final `git diff --exit-code` on the whole worktree exited 0.

## Tests
- Oracle: `po-gate oracle-intact s217-plan-says-no-oracle` → exit 0

## Findings
- **minor** — `method/hooks/po-gate.sh:620` and `:623`: two awk programs that differ only in their final regex scan the same section one after the other. A single pass recording "has a `—` line" and "has a `—` line with a reason" would say the same thing once.
- **minor** — `method/hooks/po-gate.sh:626`: the message "names no oracle file and writes no —: write a — line …" puts a colon right after a dash and reads awkwardly. Ending the first clause on a full stop or a semicolon would read better. Exit-2 wording is for people only (`signals.rs` reads exit-0 stdout), so this is style.

## Not verified
- **Plans already in flight in other projects:** a plan that writes a bare `—` under `## Acceptance tests` passed before this change and now exits 2. In this repository, the plan reports that it scanned the 200 plans and three journey fixtures, and I confirmed `tests/oracle-intact-gate.oracle.test.sh` stays green. I did not inspect plans in flight in projects that install Polype, such as Lagon. Their reviews would be blocked until each bare `—` gets a reason; the message says how. A person should check open plans in those projects before or right after the next `polype update`.
- **Whether a real planner now writes the new form:** the prose rule speaks to a model, and no `po-eval` arm exists yet (#208 candidate, named in the plan). I judged the three edited texts by reading only.
- **Full suite:** I did not rerun it myself. I relied on the record's passing run on code identical to HEAD outside `docs/`.

Max severity: minor
Ship allowed: yes
