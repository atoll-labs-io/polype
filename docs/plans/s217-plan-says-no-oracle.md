---
track: flow
validated: yes
---
# Plan (short track) — s217-plan-says-no-oracle

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s217-plan-says-no-oracle.md`. Track `flow`: `Story track: auto`, complexity 2 ≤ `Flow threshold` 3, no escalation signal.

## Verified facts
No assumption of the story proved false. The three places it names say what it says they do.

- **The template pulls one way.** `method/templates/plan.md:20` and `method/templates/plan-flow.md:37` say the same sentence word for word: "write `—` with its reason in place of both tables", but only "for a story where no criterion can be checked by a test (purely visual), or an exploration story". A story whose `Owns` admits no test file (the Lagon case of #484) is in neither case.
- **The agent pulls the other way.** `method/agents/planner.md:55`: "An oracle file the story's `Owns` does not list is not written: you report it as a gap in the story, and that criterion's row in the plan says so." "Row in the plan" does not say which table; two Lagon planners (#484) put a `| — (reason) | — |` row in the oracle table.
- **What the gate reads.** `po-gate oracle-intact` (`method/hooks/po-gate.sh:603`, dispatched at `:677`) reads only the first table of `## Acceptance tests` whose first header cell is `Oracle file` (`table_rows`, `:582-600`); the criterion table is never read. No `## Acceptance tests` section → exit 0 "has no oracle" (`:614-616`).
- **Empty oracle table** (`:619-624`): any line of the section starting with `—` → exit 0, "has no oracle: its plan writes — under ## Acceptance tests" (`:620-621`); a bare `—` with no reason passes too. No such line → exit 2 "names no oracle file and writes no —" (`:623`).
- **Placeholder row** (`:625-628`): each oracle row needs a path and a sum `^[0-9]+ [0-9]+$`; `| — (reason) | — |` fails that and exits 2 with "unreadable row in the oracle table of the plan" (`:628`), which names no form to write instead. Exit 2 goes through `oracle_unreadable` (`:577`), stderr.
- **Who reads the output.** `po` reads only the stdout of an exit-0 run, matching "has no oracle" (`po/src/trust/signals.rs:69`); the exit-2 path and its wording are read by nobody but the reviewer. The exit-0 wording stays as it is.
- **The form this repository already uses.** Oracle files only in the oracle table; a criterion without a test explains itself in its row of the criterion table (`docs/plans/s162-defects-seen-on-products.md:29-30`). No plan of `docs/plans/` has a bare `—` or a `—` row under `## Acceptance tests` (scanned all 200), and the three journey fixtures write `— no oracle: …` with a reason (`tests/journey/answers/{plain,flow,choice}/plan.md`), so turning a bare `—` into exit 2 breaks no existing plan or test.
- **Existing tests to keep green.** `tests/oracle-intact-gate.oracle.test.sh:42` uses `— no criterion can be checked by a test: …` (has a reason: still exit 0). `tests/planner-writes-the-oracle.test.sh:23` requires `| Oracle file | cksum |` in both templates' section: the table stays. No phrase test reads the sentences changed here (grep of `tests/`).
- **Word ceilings** (`method/word-budget:9,56,57`, counted `LC_ALL=C awk '{n+=NF}'`, `bin/po-lint:371`): `agents/planner.md` 1336/1336, `templates/plan-flow.md` 734/734, `templates/plan.md` 509/509. Every edit must leave its file at or under its count today. The hook `po-gate.sh` has no ceiling.
- **Outside `Owns`, left alone.** `method/commands/po-plan.md:27` says "report it as a gap of the story, in that criterion's row" — already readable as the criterion table; not touched.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: prose and one hook | absent — no data store involved |
| New screen | absent — `Surface: command` | absent — no UI in `Owns` |
| Authorization or tenant scope | absent — story text | absent — `po-gate.sh:603-660` reads a plan, no access rule |
| API contract | absent — story text | absent — `po` reads only exit-0 stdout "has no oracle" (`signals.rs:69`), unchanged; exit-2 wording is for people |
| New dependency | absent — story text | absent — bash and awk already used by `po-gate.sh` |
| Technical choice that deserves an ADR | absent — the issue's option 1 was framed | absent — a format alignment; bare `—` → exit 2 settled by the lead as an implementation detail |
| Defect to fix (`Fixes` or `Corrige` line) | absent — `docs/stories.md:3528-3540` has no `Corrige` line | absent — same |

## Story
As the owner, I want the way the planner writes a criterion with no oracle to be the one `po-gate oracle-intact` accepts, so that a story no longer pays a fix loop for one plan line (#484, seen on Lagon).

- `no_oracle_row_passes_the_gate` — a plan whose criterion speaks to the model (case 3 of the direction), written as `method/agents/planner.md` says, passes `po-gate oracle-intact`.
- `missing_oracle_still_refused` — a criterion a script reads, with no oracle and no reason, is still refused.

**The one form.** No oracle file at all, whatever the reason (visual, exploration, `Owns` gap, every criterion in case 3): a `—` line **with its reason** replaces the oracle table. A criterion without a test says why in **its row of the criterion table**, never in the oracle table. The gate keeps refusing a placeholder row, and refuses a bare `—`; both exit-2 messages name the form.

## Reuse
No new code beyond two edited branches of `oracle_intact`: the `—` detection reuses the awk of `po-gate.sh:620`, the refusals reuse `oracle_unreadable` (`:577`).

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests
Both criteria are read by a script, the gate, so both have an oracle test, run from `main` against `story/<id>` like `tests/oracle-intact-gate.oracle.test.sh`. The prose half of the criterion (that the planner writes this form) speaks to a model: the reviewer reads it in the three edited files; `po-eval` candidate (#208): a planner on a story whose `Owns` holds no test file writes a `—` line, not a placeholder row.

On the start point, `no_oracle_row_passes_the_gate` passes (regression guard: the gate already accepts the form) and `missing_oracle_still_refused` fails on the exit-2 message of the placeholder row, then would fail on the bare `—`, which exits 0 today.

| Oracle file | cksum |
| --- | --- |
| `tests/plan-says-no-oracle.oracle.test.sh` | `3322980070 2733` |

| Criterion | Test |
| --- | --- |
| `no_oracle_row_passes_the_gate` | `test_no_oracle_row_passes_the_gate`: a `—` line with its reason plus a criterion row "— case 3 …" → exit 0 "has no oracle"; an oracle table with one file plus the same criterion row → exit 0 |
| `missing_oracle_still_refused` | `test_missing_oracle_still_refused`: a `\| — (reason) \| — \|` row → exit 2; a bare `—` → exit 2; both stderr hold `write a — line with its reason in place of the oracle table`; an empty oracle table and no `—` line → exit 2 |

## Tasks

1. [x] **Gate** (`method/hooks/po-gate.sh:619-628`). (a) Empty-table branch: accept only a `—` line with a reason, e.g. awk `on && /^—[[:space:]]*[^[:space:]]/`; keep the exit-0 message of `:621` word for word (`signals.rs:69`). A section whose only `—` lines are bare → `oracle_unreadable "$id" "## Acceptance tests of the plan writes — with no reason: write a — line with its reason in place of the oracle table"`. Keep `:623` as it is, or end it with the same clause. (b) In the row loop, before the sum check of `:627`: a path cell starting with `—` → `oracle_unreadable "$id" "a row of the oracle table names no file: with no oracle file, write a — line with its reason in place of the oracle table"`. Every other row keeps the message of `:628`. Test: `bash tests/run.sh plan-says-no-oracle.oracle.test.sh oracle-intact-gate.oracle.test.sh trust-signals.oracle.test.sh`.
2. [x] **Templates** (`method/templates/plan.md:20`, `method/templates/plan-flow.md:37`, the same sentence in both). Replace "For a story where no criterion can be checked by a test (purely visual), or an exploration story, which its measure judges, write `—` with its reason in place of both tables." (32 words) with: "No oracle file, whatever the reason: `—` and that reason replace the oracle table; a criterion without a test says why in its criterion-table row, never in the oracle table." (30 words). Keep the `| Oracle file | cksum |` table in both placeholders. Test: `bash tests/run.sh planner-writes-the-oracle.test.sh plan.test.sh flow.test.sh` and `bin/po-lint` (budget).
3. [x] **Planner** (`method/agents/planner.md:55`). Replace "and that criterion's row in the plan says so." (9 words) with "in that criterion's row, never in the oracle table." (9 words). Test: `bash tests/run.sh planner.test.sh escalation-contract.test.sh diagnostic-skill.test.sh defect-and-routing-paths.test.sh` and `bin/po-lint`.
4. [x] **Whole suite and lint** once, at the end: `Test` through `po-run`, then `bin/po-lint`. No word ceiling of `method/word-budget` is raised.

## Scene viewpoints
—

## Run interdicts
- `tests/plan-says-no-oracle.oracle.test.sh` keeps sum `3322980070 2733`; any change goes through `## Oracle changes` of the record.
- `method/word-budget` ends with an empty diff: no ceiling raised.
- `method/commands/po-plan.md`, `po/`, `bin/polype` and `tests/oracle-intact-gate.oracle.test.sh` end with an empty diff (outside `Owns`; `po` is not touched, so no version raise, ADR-0122).
- The exit-0 stdout lines of `oracle_intact` (`po-gate.sh:615`, `:621`) keep their wording: `po` matches "has no oracle".
- `tests/plan-says-no-oracle.test.sh` is not created unless it holds a test (`tests/run.sh` fails a file with none).
- No edit to `.claude/` or `.polype/` (installed copies).

## Files touched
`method/hooks/po-gate.sh`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/agents/planner.md`, `tests/plan-says-no-oracle.oracle.test.sh` (written by the planner, committed by the implementer), `docs/plans/s217-plan-says-no-oracle.md`, `docs/verif/s217-plan-says-no-oracle.md`.

## Test strategy
Two oracle tests at the gate's own layer (the script that reads the plan), well within `Test budget` 25. No phrase test on the prose (direction, 2026-11-13: the rule speaks to a model, the reviewer reads it). Bite: deleting the `—`-row branch of task 1 or loosening the reason regex back to `/^—/` turns `missing_oracle_still_refused` red; deleting the `—`-line acceptance turns `no_oracle_row_passes_the_gate` red. Existing guards: `oracle-intact-gate.oracle.test.sh` (dash with reason still exit 0), `trust-signals.oracle.test.sh` ("has no oracle" wording).

## Done when
The four tasks are ticked, the full suite and `bin/po-lint` are green on the committed tree, the record is complete, one commit lands `s217-plan-says-no-oracle: Un plan dit « pas d'oracle » sous une forme que po-gate accepte` through a pull request, and the review leaves no critical finding open. #484 is closed by the ship.
