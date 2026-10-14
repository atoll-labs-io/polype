---
track: flow
validated: yes
---
# Plan (short track) — s34-method-consistency

[Story](../stories.md)

Six documented inconsistencies, each with its source review. No research file: this section stands in for it.

## Verified facts

- **Defect 17 confirmed.** `method/templates/review.md` has `## Evidence reused`, `## Plan`, `## References`, `## Rules`, `## Tests`, `## Neighbours` (`:14-36`) — one per step of the six — and no slot for the scope check that `method/skills/review-antihallu/SKILL.md:9-20` puts *before* them. Source: `docs/reviews/s28-review-ownership.md`, first major.
- The scope check has exactly four outcomes to record: inside `Owns`, outside → major (`SKILL.md:13`), inside a running story's `Owns` → critical (`:14`), plus the three corrections at `:18-20` — pipeline evidence in scope by construction, a path an `AGENTS.md` rule forces → minor, **no `Owns` line at all → unverifiable scope**.
- `tests/review.test.sh:21-25` pins only the template's *last two* non-empty lines (`Max severity`, `Ship allowed`). A section inserted at the top leaves it green.
- **Defect 18 confirmed.** `po-drive.md:45` sends a lane to "the same stage, at the plan", but the dispatch line `:78` hands `planner` only "the story id and the absolute worktree path", and `method/agents/planner.md` has no clause about an existing `docs/research/<id>.md` — it writes research *then* plan (`:37-38`). The lane would overwrite the research that `po-drive.md:59` forbids overwriting.
- **Defect 19 confirmed.** In the resume table (`po-drive.md:42-51`) the row `record current, no docs/reviews/<id>.md → the review stage` (`:48`) cannot match after a fix run, since a review file exists; the lane falls to `:49` and gets a **second** fix run — replaying a recorded stage and burning one `Max attempts` unit. No precedence is declared anywhere in the section.
- **A mechanical discriminator exists.** The record carries `Tree:`, the hash of `git write-tree` at check time (`method/templates/verification-record.md:5-7`, written by the implementer per `method/agents/implementer.md:36`); `AGENTS.md` Law 6 states a fix run adds one commit of its own. So the number of implementer commits on `story/<id>` compared with the review's `Fix loop:` tells a review that judged the current code from one that judged an earlier commit.
- **Defect 30 confirmed.** `po-drive.md:75` requires a stage to leave "in a single message" and `:123` makes the report count messages. `docs/defauts.md:45` records that this measure is wrong: a subagent starts in the background and returns at once, so messages do not measure overlap — activity windows grouped by `parent_tool_use_id` do.
- **Defect 29 confirmed.** `method/agents/planner.md:50` says "and no other file", `:51` makes the planner write an ADR from the number the driver reserved.
- **Trap — an `Owns` gap.** `tests/planner.test.sh:46` asserts that exact sentence with `contains` (exact, case-sensitive, `tests/lib.sh`). Closing defect 29 turns it red. `docs/stories.md:397` gives that file to s26, shipped; s34's `Owns` (`:510`) does not list it. The one assertion must change; nothing else in that file may.
- `tests/planner.test.sh:25-30` compares the **first** two `N lines at most` phrases of `planner.md` with those of its two commands. New prose must introduce no such phrase before `planner.md:37`.
- **Defect 20 confirmed, with its fix already written.** `tests/design.test.sh:36-37` claims "does not stop on its own line" but asserts only that *some* line holding the trigger also holds `stop`. `docs/reviews/s25-method-lint.md:50` proved it by mutation: rule rewritten to `carry on`, one decoy line added, suite still green. Its fix: require the trigger to occur once and that occurrence to carry `stop`. Both triggers occur exactly once today (`method/commands/po-design.md:25`, `:26`).
- `tests/design-handoff.test.sh:54-73` reads only defect rows 1-11; rows 17-20, 29, 30 can be restatused freely.
- `tests/fleet-wiring.test.sh:32` pins `AGENTS.md` Law 1 ("advances those lanes at the same time") — true under the new wording, so `method/AGENTS.md` needs no change.
- `bin/po-lint`'s fail-closed rule applies to gate sections only (`bin/po-lint:158-162`); `## Checks` of `po-drive.md` is untouched here.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — `docs/stories.md:505-517`, no data | absent — the diff is markdown and bash only |
| New screen | absent — the story shows none | absent — no template, no mockup, no `docs/designs/` |
| Authorization or tenant scope | absent — no actor, no permission | absent — no such notion in these files |
| API contract | absent — no interface in the story | absent — prose contracts between agents, not an API |
| New dependency | absent — none named | absent — bash and grep only, already used |

Six tasks exactly, so the short-track cap holds. Complexity scored after reading the code: **3** against the 2 written at `docs/stories.md:508` — seven files and six defects, but none of them deep.

## Story

Make the method documents stop contradicting each other, so an agent never meets two rules at once. Acceptance criteria, each becoming the test function of the same name:

1. `review_template_has_an_ownership_section` — the ownership check sits at the head of `templates/review.md`, before the six steps, one box per case: in scope, outside `Owns`, another lane's `Owns`, story with no `Owns`.
2. `drive_resume_table_is_complete_and_ordered` — every resume state names the stage the lane restarts at; overlapping cases carry a declared precedence, the stop after a fix run in particular.
3. `drive_requires_overlapping_lanes_not_a_message_shape` — the command asks that a wave's lanes overlap in time and that the report prove it with their activity windows; it prescribes no dispatch shape.
4. `planner_writes_only_its_documents_and_the_adr_assigned_to_it` — research, plan, and the ADR only when the driver reserved its number.
5. `design_test_message_matches_its_assertion` — the `/po-design` test checks what its failure message announces.

## Tasks

1. [x] **`method/templates/review.md`** — insert `## Ownership` between `## When blocked` and `## Evidence reused`, naming the diff listing (`git diff --name-only <Target branch>...story/<id>`) and four boxes: every path inside `Owns`; a path outside `Owns` → major, with the path and the line it missed; a path inside a running story's `Owns` → critical; the story has no `Owns` line → unverifiable scope. Fails without it: `test_review_template_has_an_ownership_section` (new, `tests/ownership.test.sh`).
2. [x] **`method/commands/po-drive.md` — `## Resuming`** — state that the table is read top to bottom and the first matching row wins; complete the plan row by saying the lane keeps the research it finds; insert, before the fix-run row, the row for a lane stopped after a fix run — record current and a blocked review that judged an earlier commit, recognised by its `Fix loop:` against the implementer commits on `story/<id>` → the review stage at loop `Fix loop:` + 1. Keep the exact text of the rows `tests/resume.test.sh:22,26,27` pins. Fails without it: `test_drive_resume_table_is_complete_and_ordered` (new).
3. [x] **`method/commands/po-drive.md` — `## Dispatching` and `## Report`** — replace the single-message requirement with the real one: a wave's lanes must overlap in time, the report proves it with each lane's activity window, and no dispatch shape is imposed; say why counting messages proves nothing (a subagent runs in the background and returns at once). Use no backquoted `` `cd ` `` anywhere. Fails without it: `test_drive_requires_overlapping_lanes_not_a_message_shape` (rewritten from `test_drive_dispatches_a_whole_stage_in_one_message`) and `test_drive_reports_what_it_observed_not_what_it_intended` (updated).
4. [x] **`method/agents/planner.md` — `## Limits`** — make `:50` list the research, the plan and, only when the driver reserved a number for this lane, the ADR that number names; everything else stays forbidden. Add to `## Checks` or `## The contracts you carry` that an existing `docs/research/<id>.md` is read and reused, never rewritten (defect 18's other half). Introduce no `N lines at most` phrase before the existing ones. Fails without it: `test_planner_writes_only_its_documents_and_the_adr_assigned_to_it` (new, `tests/drive.test.sh`).
5. [x] **`tests/design.test.sh`** — rename `test_design_stop_rules_bite` to `test_design_test_message_matches_its_assertion` and pin each trigger: it must occur exactly once in `po-design.md` and that occurrence must carry `stop`; same treatment for the `no screen` / `writing nothing` pair at `:43-44`. Make each failure message say what is actually asserted. Prove it by the s25 mutation: rewrite the rule to `carry on` and add a decoy line elsewhere — the test must go red.
6. [x] **`docs/defauts.md`** — set rows 17, 18, 19, 20, 29 and 30 to `corrigé par s34`, touching no other row. Fails without it: nothing mechanical; the reviewer checks it against this plan.

## Run interdicts

- `method/AGENTS.md` — empty diff. Law 1's wording stays true and `tests/fleet-wiring.test.sh:32` pins it.
- `docs/stories.md` — empty diff. A story is not rewritten while it runs.
- `tests/resume.test.sh`, `tests/review.test.sh`, `tests/fleet-wiring.test.sh`, `tests/design-handoff.test.sh`, `tests/lint.test.sh` — empty diff. The new text must fit the clauses they already pin.
- `tests/planner.test.sh` — **exactly one line changes**, the assertion at `:46`, to the new wording of `planner.md`. Declared here as an `Owns` gap: the file belongs to s26 (`docs/stories.md:397`) and s34 invalidates the clause it checks, which `AGENTS.md` says must then be updated and said out loud. No other line of that file moves.
- `.claude/`, `.polype/`, `bin/`, `method/hooks/` — empty diff. Installed copies and tooling are out of scope.
- No backquoted `` `cd ` `` in `po-drive.md`: `tests/drive.test.sh:179` refuses it.
- `docs/parite-killer-saas.md` — empty diff. The story declares no `Matrice` line.

## Files touched

`method/templates/review.md`, `method/commands/po-drive.md`, `method/agents/planner.md`, `tests/drive.test.sh`, `tests/design.test.sh`, `tests/ownership.test.sh`, `docs/defauts.md`, and the single assertion of `tests/planner.test.sh`.

## Test strategy

One layer only: bash assertions over the method files, the layer every story of this repository uses — there is no runtime to exercise. Five test functions carry the five criteria, named after them:

| Function | File | Checks |
| --- | --- | --- |
| `test_review_template_has_an_ownership_section` | `tests/ownership.test.sh` | the section exists in `templates/review.md`, sits before `## Evidence reused`, and carries one box per case |
| `test_drive_resume_table_is_complete_and_ordered` | `tests/drive.test.sh` | the first-match rule is stated, the fix-run row exists and precedes the blocked-review row |
| `test_drive_requires_overlapping_lanes_not_a_message_shape` | `tests/drive.test.sh` | the overlap requirement and the activity windows are there, and no single-message requirement remains |
| `test_planner_writes_only_its_documents_and_the_adr_assigned_to_it` | `tests/drive.test.sh` | `planner.md` names the three files and conditions the ADR on the reserved number |
| `test_design_test_message_matches_its_assertion` | `tests/design.test.sh` | each trigger occurs once and that occurrence stops |

Plus two updated in place: `test_drive_dispatches_lanes_in_one_message` and `test_drive_reports_what_it_observed_not_what_it_intended`, whose pinned phrases task 3 removes. Five new functions against a `Test budget` of 25 — well within it. Run `bash tests/run.sh` whole: seven method files change and the suite is the only thing that sees the blast radius.

## The pivot

Everything in task 2 rests on one claim: **a fix run leaves exactly one new commit on `story/<id>`**, so commit count against `Fix loop:` separates a stale review from a current one. `AGENTS.md` Law 6 says it ("A fix run adds one commit of its own"), but it also allows a migration its own commit. On a story with a migration the count drifts and the discriminator misreads. It could be wrong that way. The declared first-match precedence is what actually closes defect 19; the discriminator only makes the new row decidable. If it proves fragile, keep the precedence and let the row say the driver compares the record's `Tree:` with the commit the review names — a weaker but safer test.

## Done when

`bash tests/run.sh` is green, the five criteria have the five test functions named after them, the six defect rows read `corrigé par s34`, the `tests/planner.test.sh` gap is stated in the commit message, and a review finds no open critical.
