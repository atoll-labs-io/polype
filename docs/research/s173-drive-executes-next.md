# Research — s173-drive-executes-next

[Story](../stories.md)

## Structuring facts
- **False assumption 1 — `Owns` is too narrow (issue #241, M1 confirmed).** Removing the routing rules of `method/commands/po-drive.md` breaks assertions in **14 test files outside `Owns`** (table below). The story cannot be built inside its bounds: no plan is written until the lead widens `Owns` on `main`.
- **False assumption 2 — `/po-execute` cannot "read `po next`".** It has no shell, by construction (`method/commands/po-execute.md:2`, `:4-8`, `:16`). Three tests outside `Owns` and `bin/po-lint:142-147` pin that: `tests/execute.test.sh:8-13`, `tests/design-handoff.test.sh:27-29`, `tests/lint.test.sh:75-78`. To run `po next` it would need Bash, which reverses a deliberate rule. That choice belongs to the owner (see Open questions).
- **False assumption 3 — "s168's case table is the reference".** Three routing rules of `po-drive.md` have no case in `tests/fixtures/driver-cases/`, and `po next` does not compute them: a closed pull request (`po-drive.md:67`), a failed ship that goes back to a fix run (`:155`), and a story missing from the start point `origin/<Target branch>` (`:31`, `:92`). The story's notes say: "sinon arrête-toi et dis lequel manque".
- **Root cause of #139.** `method/commands/po-execute.md:26` (precondition 6) treats every last `Ship allowed: no` as a fix run and exempts only the two QA blocks. The blocked report that `po record review --composed` writes for a findings-shape stop also carries `Ship allowed: no` (`method/commands/po-review.md:42`). Run on its own, `/po-execute` therefore starts a fix run on it. `po next` already answers `ask` for that state (`po/src/next/lane.rs:159-161`; cases `resuming_16`, `verdict_05`).
- The `po next` side is built and green: `bash tests/run.sh driver-next-action.oracle.test.sh` gives 7 passed on this worktree (2026-11-13).

## Story
`/po-drive` runs `po next`, does each line's action through the command or subagent it names, and starts again. It no longer states any routing rule and fits in 2,500 words (5,356 today, `LC_ALL=C wc -w`). Run on its own, `/po-execute` refuses a fix run whose action is `ask`. Without `po`, or when `po` exits 2, `/po-drive` stops and names the installer. Criteria: `drive_holds_in_2500_words`, `drive_executes_what_it_reads`, `execute_refuses_a_shape_blocked_fix`, `drive_stops_without_po`, `phrase_tests_give_way_to_cases`. Three of them (`drive_executes_what_it_reads`, `execute_refuses_a_shape_blocked_fix`, `drive_stops_without_po`) are judged in review and are candidates for a `po-eval` control arm. Fixes #203 (in part) and #139.

## Diagnostic (#139)
- Reproduction, by reading only: `/po-execute` is model prose, so there is nothing to run. On the state of case `resuming_16` (a review whose last block is `Review status: blocked`, `Next action: a person settles the findings shape — …`, `Ship allowed: no`), precondition 6 (`po-execute.md:26`) matches its first clause and neither exception. `po next` answers `ask 'findings-shape refused'` (oracle green, above).
- H1: "the composed report says `Ship allowed: yes` or has no verdict". Refuted: `po-review.md:42` writes `Max severity: critical` and `Ship allowed: no`.
- H2: "`/po-execute` reads the `Next action:` for a shape stop elsewhere". Refuted: the only `Next action:` exceptions in the file are the two QA ones (`po-execute.md:26`). `grep -n findings-shape method/commands/po-execute.md` finds nothing.
- Root cause kept: `po-execute.md:26`, exception list incomplete.

## Current code
- `po-drive.md` (176 lines). Routing lives in `## The ready set` (:28-42), `## Resuming` with its 19-row table (:44-83), the dispatch steps that route (:104-107), `## The verdict, and the fix runs` (:135-144), `## Ships, one at a time` (:146-155) and the `status` reasons (:173). What the model keeps: preparing worktrees and orphans (:89-98), dispatch overlap (:100-114), grouped plan validation (:116-133), recording through `po record` (:136-140), the decisions log (:157-162), the report (:164-175).
- `po next` (`po/src/next/mod.rs:43-81`) prints `{actions:[{story,action,reason}], ready, held, warnings}`, exit 0. Outside a project it exits 2 (`mod.rs:50-56`). Its binary sits at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po` (`docs/interface-agent.md:13-15`). Ready stories get the action `plan`, reason `ready` (`mod.rs:67-73`).
- `po-execute.md` (854 words): read-only preconditions (:20-29), `## Model` (:31-38), the prompt (:40-55).

## Attachment points
- `method/commands/po-drive.md`: a rewrite. `method/commands/po-execute.md`: precondition 6, plus the tool question.
- Tests in `Owns`: `tests/drive.test.sh`, `tests/drive-guards.test.sh`, `tests/fleet-wiring.test.sh`, `tests/fleet-design.test.sh`, plus the story's own `tests/drive-executes-next{,.oracle}.test.sh`.

## Tests outside `Owns` that pin a phrase this story removes
"Routing" means the story removes the phrase (criterion `drive_executes_what_it_reads`). "Cap" means the phrase is not routing but likely falls to the 2,500-word cap (the plan's choice).

| File | Lines | What it pins | Why it breaks |
| --- | --- | --- | --- |
| `tests/resume.test.sh` | 11-40 | `## Resuming` exists, 10 phrases incl. table rows `… \| the code stage`, `a fix run, at loop …`, `nothing — the story is done`, and the order `## Resuming` before `## A wave` | routing |
| `tests/resume.test.sh` | 43-58 | `## Report` status reasons: `the loops already spent against \`Max attempts\``, `a dependency not shipped and which one`, `an \`Owns\` collision …`, `\`Max attempts\` reached with the open findings`, `an orphan worktree as it was found` | routing / cap |
| `tests/resume.test.sh` | 62-75 | orphan detection in `## A wave`: `confirmed on two axes, never repaired`, … | cap (po warns `orphan-worktree`; case `ready_set_13`) |
| `tests/escalation-contract.test.sh` | 61-71 | `## Resuming` rows: exactly one marker row sends to `a human`, and it comes before the row `the lane keeps that file and never writes it again`; marker in `## Validating a wave's plans` | routing |
| `tests/escalation-contract.test.sh` | 76-79, 97-103 | `at once, in a message of its own`, `Meanwhile the other lanes carry on.`; `## The decisions log` phrases | cap (person / log, not routing) |
| `tests/defect-and-routing-paths.test.sh` | 39-52 | one `Root cause: not found` row in `## Resuming` going to `a human`, `as a whole line`; planner step `sends its lane to a human`, `no plan is approved or dispatched for it`; row order | routing |
| `tests/qa-fleet.test.sh` | 66-86, 140, 170, 174-186 | 7 `## Resuming` rows and their order; `Commits whose subject is \`<id>: QA evidence\` …`; `a current report left uncommitted fails it` | routing |
| `tests/qa-fleet.test.sh` | 120-123, 141-142 | `## The verdict, and the fix runs`: `A review blocked on QA is not a fix run: …`, `Blocked on QA means … nothing less`, P2 | routing |
| `tests/qa-fleet.test.sh` | 47-64 | one line each for `subagent_type: implementer/qa/reviewer`, in order; the qa line holds `for a story that goes to QA`, `QA evidence`, `-- docs/qa/<id>/`; `then every implementer, then every qa, then every reviewer`; `## Checks` QA-stage line | cap |
| `tests/qa-fleet.test.sh` | 153-157 | `po-execute.md` preconditions keep the P1/P2 stops | only if precondition 6 is rewritten around `po next` |
| `tests/review-findings-shape.test.sh` | 86-92, 141-142 | verdict section `checked through Bash with \`po-gate findings-shape <id>\` …`, `no \`Max attempts\` unit is spent; …`; resume rows findings-shape before fix run, `the check could not run (exit <n>)`; `Any other exit is not a malformed review: …` | routing (rows), cap (re-ask text) |
| `tests/ship-follows-forge.test.sh` | 94-107 | resume rows OPEN/CLOSED between stale review and ship; ready set `takes no \`Parallel\` slot`; ships `is not the landing`; report `a pull request waiting for a human merge, with its URL` | routing |
| `tests/ship-follows-forge.test.sh` | 119 | ships section `\`po-gate ship-allowed <id>\` is required before any merge, whatever the value` | cap |
| `tests/surface-routing.test.sh` | 34-35 | exactly 3 `## Resuming` rows `\| record current, the story goes to QA,` | routing |
| `tests/owns-overlap.test.sh` | 18, 36 | `## The ready set` holds the overlap RULE and the check-8 citation | routing |
| `tests/owns-overlap.test.sh` | 52-58 | ≥2 `## Report` lines with `the path that collided` + `the two entries that overlapped and one path matching both` | routing; and `po`'s `held` carries no path (#280, `po/src/next/mod.rs:21-26`) |
| `tests/docs-and-eval-cleanup.test.sh` | 52 | `po-drive.md` holds the shipped SENTENCE (`a story \`s<n>-<slug>\` is shipped when …`) | routing |
| `tests/docs-and-eval-cleanup.test.sh` | 67-73 | resume row `refuses it, whatever the reason`, `a \`Review status:\` missing or other than \`complete\``; ships section `Review status:` | routing |
| `tests/short-subject-shipped.test.sh` | 26-29 | `po-drive.md` holds the same shipped SENTENCE | routing |
| `tests/ship-and-fleet-cleanup.test.sh` | 42-48 | resume row and planner step hold `` `Root cause: not found` as a whole line (`grep -x` ``; ships section `The order the reviews passed decides …`, `Proving a ship means seeing it land` | routing |
| `tests/ship-and-fleet-cleanup.test.sh` | 82, 101-111 | mutations need ` Meanwhile the other lanes carry on.` once, and ` A planner that answers with a research holding` … `no plan is approved or dispatched for it.` | the python `index`/`assert` fails when the phrase is gone |
| `tests/plan-and-defect-paths-cleanup.test.sh` | 78 | mutation needs `sends its lane to a human` exactly once in `po-drive.md` | routing |
| `tests/everything-in-issues.test.sh` | 50-52 | `prints \`MERGED\`, gets \`/po-ship <id>\` once more: …`; report `the merged lanes waiting for cleanup, …`; status `a merged lane waiting for cleanup — …` | routing (case `resuming_21`) |
| `tests/grouped-validation.test.sh` | 13-46 | `## Validating a wave's plans` (one AskUserQuestion, three answers, Bash writes `validated: yes`); wave defers to it; report says who approved | cap |
| `tests/model-routing.test.sh` | 47, 72-75, 107, 114-116 | `subagent_type: <role>` and `` `Model strong` `` on one line, for planner/designer/qa/reviewer; report models column; model refusal sentence; implementer and `fix-run sentence` lines with `` `Model light` up to `Light up to`, `Model strong` above `` | cap |
| `tests/qa-report-returned-as-text.test.sh` | 43-48 | one `subagent_type: qa` line in `## A wave`, holding `no \`QA status:\` line` | cap |

These stay safe: `tests/record-writes-reports.test.sh:22` (word count below 5,470), `tests/adr-directory.test.sh:5` and `tests/everything-in-issues.test.sh:88-89` (they hold while `Reads settings` keeps `ADR directory` and `Issue tracker`), `tests/distribution-wiring.test.sh:161-162` (it reads `docs/parite-killer-saas.md`), and the negative checks of `tests/surface-routing.test.sh:26,38-42` and `tests/ship-through-pr.test.sh:20`. The `po-execute` assertions of `design-handoff:23-25`, `planner-writes-the-oracle:77-79`, `model-routing:57-66,99-101` and `defect-and-routing-paths:68` hold while the prompt and `## Model` stay. The installer tests only check that the file exists.

**For the lead:** every row marked routing must enter `Owns`, 14 files in all: `resume`, `escalation-contract`, `defect-and-routing-paths`, `qa-fleet`, `review-findings-shape`, `ship-follows-forge`, `surface-routing`, `owns-overlap`, `docs-and-eval-cleanup`, `short-subject-shipped`, `ship-and-fleet-cleanup`, `plan-and-defect-paths-cleanup`, `everything-in-issues`, `grouped-validation`. Add `model-routing` and `qa-report-returned-as-text` if the plan may reword the dispatch lines. If the owner gives `/po-execute` a shell, add `execute`, `design-handoff`, `lint`, and `bin/po-lint` as well, whose rule (`:142-147`) keys on the description "cannot edit files or run a shell".

## Verified interfaces
- `po next`, no argument; any argument → exit 2 `unknown-option` (`po/src/next/mod.rs:43-46`). Actions are those of `docs/interface-agent.md:85`. Evidence commit = `qa` with reason `QA evidence not committed` (`lane.rs:75-76`); the driver tells it apart by its reason (#241 m3).
- `po record review|qa <id>` exists (s167). `/po-review` pipes into it (`po-review.md:38`).
- Merge-waiting comes from `refs/remotes/origin/story/<id>` existing, not from `gh pr view` printing `OPEN` (`po/src/context/lanes.rs:320-328`).
- Ship order comes from the review file's mtime (`lane.rs:193-200`, #278), not from "the order the reviews passed" (`method/AGENTS.md`, Law 1).
- An answered decision holds its lanes until it is consumed (`next/mod.rs:100-111`, case `decisions_02`; #279).

## Traps
- `method/AGENTS.md` (`### The fleet`, `## The project lead`) restates the fleet rules; it is outside `Owns` and the story does not ask to change it. The lead reads `/po-drive status`, which today is `po-drive.md:173`.
- `/po-orchestrator` and `/po-flow` stay as they are (ADR-0109, proposed): they keep their own routing prose.
- Direction rule: no prose rule may be added to `method/` unless as many words leave the same file. That matters for `po-execute.md` too (#241 m7: no word criterion, so the reviewer counts).
- The full suite builds `po` (`tests/run.sh:19-23`).

## Open questions
1. **`/po-execute` and `po next` (owner).** Options, ranked by the owner's criteria. (a) Keep no shell and add the findings-shape stop to precondition 6, read from the file like the QA stops. This fixes #139 within `Owns`, but the story text ("lit `po next`") has to change. (b) Give `/po-execute` a narrowed `Bash(…/polype/po next)` permission, as `/po-review` narrows `Bash(.polype/hooks/po-gate.sh findings-shape:*)` (`po-review.md:10`). This reverses "by construction" and needs an ADR (reserved number ADR-0120) plus the three tests and `bin/po-lint` in `Owns`. (c) Let the implementer run `po next` and stop. Rejected: the coordinator has already chosen a fix run by then.
2. **Missing cases.** Who adds the closed pull request (`po-drive.md:67`), the failed ship (`:155`) and the start-point check (`:92`): s168's fixtures (shipped) or this story? Without them, these rules either stay in prose or are lost. `po next` cannot see the forge (s164 reads files and git only), so the closed pull request needs either a `--remote` read or a rule that stays in prose.
3. **The colliding path in the report (#280).** `held` names the lane, not the path. Either `owns-overlap.test.sh:52-58` and the report rule give way, or `po` gains a field (outside `Owns`: `po/src/next/`).

## Complexity
Story: 3 → after reading the code: 4. The prose rewrite is mechanical, but it moves about 14 to 17 test files outside `Owns`, reverses or keeps a tool rule of `/po-execute`, and depends on three missing cases.

## Split
Not required at 4. If the owner chooses option (b) of question 1, a split is possible: the `/po-execute` part (#139) can ship alone ahead of the `/po-drive` rewrite.
