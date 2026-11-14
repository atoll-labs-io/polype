# Review — s173-drive-executes-next

[Story](../stories.md) · [Plan](../plans/s173-drive-executes-next.md) · [Verification](../verif/s173-drive-executes-next.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s173-drive-executes-next`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 41b81857a15b5a69b12bdb8009b8054deaf07144

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s173-drive-executes-next` (25 paths) and checked each path against the s173 `Owns` line.
- [x] Every path is inside `Owns`. The only exceptions are `docs/plans/`, `docs/research/` and `docs/verif/s173-drive-executes-next.md`, which are this story's own pipeline evidence. The diff adds no ADR. ADR-0120 was already on `main`.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other worktree is `story/s170-trust-signals`. It is an ancestor of `main`, and its `Owns` (on `main` and on the branch) shares no path with this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s173-drive-executes-next` exits 0, so I reused the record. Its `Tree:` (6bd690c…) and the run tree (9121b95…) both equal HEAD outside `docs/` (`git diff --quiet` gives 0 for both). The unit suite `bash tests/run.sh` exited 0. The project has no type check (`Typecheck: —`). The record's "Not proven here" goes to `## Not verified`.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–7 are all present. `bin/po-lint` has the guard and the `Bash\(*` arm. `po-execute.md` has the frontmatter line, the description and precondition 6, at 854 words. `po-drive.md` has the settings list, the `po` check, `## The next action` with its table and the two prose rules, and keeps the `A stage already recorded…` sentence. It is 2494 words (5356 before). The test deletions match the task 6 list file by file, and `design-handoff.test.sh:28` was updated. Nothing is outside the plan.
- [x] Run interdicts, checked one by one. The diff is empty on `po/`, `tests/fixtures/driver-cases/`, `tests/driver-next-action.oracle.test.sh`, `po-orchestrator.md`, `po-flow.md`, `po-review.md`, `po-qa.md`, `po-status.md`, `po-retro.md`, `method/AGENTS.md`, `method/agents/`, `docs/interface-agent.md`, `.claude/` and `.polype/`. The oracle sum holds (`oracle-intact` exits 0). No new phrase assertion was added. The only `Bash` in `po-execute.md` is the exact `po next` line, with no `cd`. The research was not rewritten.

## References
- [x] I opened `po next` (`po/src/next/mod.rs`, `lane.rs`, `wave.rs`, `po/src/context/lanes.rs`). Every action and reason the new `po-drive.md` table names exists in code: `plan`/`ready`, `validate-plan`, `design`, `execute`, `fix`, `qa`/`QA evidence not committed`, `review`, `ship`/`landed`, `wait`/`merge waiting`, `ask`, held `owns` with `entry`/`ref_entry`/`path`, held `framing` with `ref`, and the `orphan-worktree` warning. The verbs `po state` and `po record` exist in `po/src/main.rs:22-26`. The `## Recording` section of `/po-review` holds the re-ask and the stops that `po-drive` now delegates to it.
- [x] The permission string in the frontmatter matches the command written in precondition 6 character for character, and it has the same shape as `po-review.md:12`.

## Rules
- [x] The `AGENTS.md` conventions are respected. One gap with `## What goes to the person` is in the minor findings below.
- [x] No accepted ADR is contradicted. ADR-0120 asks for "ni `po` entier, ni un Bash nu", and the oracle's mutants hold exactly that.

## Tests
- Oracle: `po-gate oracle-intact s173-drive-executes-next` → exit 0
- [x] Floor: `po-gate floor-guard s173-drive-executes-next main` exits 0, so nothing was lowered.
- [x] The oracle tests `/po-execute`'s single shell command at the layer that enforces it, by running `bin/po-lint` on mutants. I found none of the six empty-test shapes. The routing criteria are read by a model, judged by reading below.
- [x] Three new tests, within `Test budget` 25.
- [x] Bite 1: I removed the `Bash\(*` arm of `bin/po-lint:149`. 1 test failed (`execute_refuses_a_shape_blocked_fix`). Undone, and `git diff --exit-code bin/po-lint` is clean.
- [x] Bite 2: I turned the ADR-0120 guard (`bin/po-lint:147`) into a no-op. 5 tests failed (the oracle plus 4 tests in `lint.test.sh`). Undone, and `git diff --exit-code` is clean.
- [x] Assertions made useless by `po next` were removed as task 6 lists them. The full suite is green in the record.

Criteria judged by reading:
- `drive_holds_in_2500_words`: holds (2494 words).
- `drive_executes_what_it_reads`: holds. `po-drive.md:29-43` runs `po next`, acts on each entry, then runs it again. The only routing left is the closed pull request (#286) and the failed ship.
- `drive_stops_without_po`: holds at `po-drive.md:25`.
- `execute_refuses_a_shape_blocked_fix`: holds for #139. `po next` answers `ask` / `findings-shape refused` (`lane.rs:159-160`), and `/po-execute` stops for a person. There is a gap for the `execute` action, in the major finding below.

## Neighbours
- [x] I read `designer.md:49`, `planner.md:42`, `po-status.md:35`, `po-retro.md:37`, `po/src/next/lane.rs:1` and `wave.rs:1`. The ones that now point at prose that is gone are in the minor findings.

## Lenses
Lenses run: security — triggered by a permission/policy check: the narrowed `Bash(...)` grant in `method/commands/po-execute.md` and the tools rule of `bin/po-lint`
- [x] The grant is an exact match on one read-only verb. The lint refuses `next:*`, `record review:*`, `po":*`, bare `Bash` and `Write`, as the oracle mutants show. The security lens found nothing to report.

## Findings
- major — method/commands/po-execute.md:27 — The new precondition 6 sends every action other than `fix` to a stop, and points to a next step only for `qa`, `review` and `ask`. `po next` answers `execute` (reason `verif-current refuses`) whenever the record is stale, and it checks that before it reads the review (`po/src/context/lanes.rs:247-248`).
    - A review with `Ship allowed: no` on code whose record is stale or failing is a reachable state: the reviewer reruns a stale record and blocks on the failure.
    - In that state, `/po-execute` now refuses the very action it exists for, and its message names nothing to do. Before this diff, the same state started a fix run.
    - `wait` (for example `decision d-…` or `ships serial`) and `ship` also get no pointer.
    - The case table of `po-execute.md` needs an `execute` row (start the run, review findings first) and a pointer for every other action.
- minor — method/commands/po-drive.md:18 — "Bash only runs `po`, prepares worktrees and records what a subagent handed you" is narrower than what the same file asks Bash to do: `gh pr view` at :43, writing `validated: yes` at :84, the decisions log at :103.
    - The old safeguard "it never edits a source file" was dropped.
    - A literal reader could refuse the pull-request check that the closed-PR rule depends on.
- minor — method/commands/po-status.md:35 — Still tells the reader to read `Fix loop:` "the way `/po-drive` reads it". The same holds for `method/commands/po-retro.md:37`. `po-drive.md` no longer describes that reading.
    - `po/src/next/lane.rs:1` and `po/src/next/wave.rs:1` still cite `## Resuming` and the ready set of `po-drive.md`, which are removed.
    - All four files are outside `Owns` and under a run interdict, so this calls for a follow-up issue, not a fix here.
- minor — method/commands/po-drive.md:41 — The `ask` row sends a lane to "the person at once, with the reason". It does not mention `po inbox add`, which `method/AGENTS.md` (`## What goes to the person`) requires first.
    - The rewrite also dropped the open findings for a lane at `Max attempts`, and the loops spent that `status` used to list.
    - The general rule still binds the lead, so the effect is small.

## Not verified
- I could not prove that the permission string `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)` matches the command the model actually types (ADR-0120, "Bad"; record, "Not proven here"). A person should run `/po-execute` once on a story with a blocked review and confirm that no permission prompt appears.
- No real `/po-drive` wave was run on top of `po next`. The table was compared with the code of `po/src/next/`, not with a live fleet. A person should run `/po-drive status`, then one wave, on a project with lanes at several stages.
- The model-read rules (`drive_executes_what_it_reads`, `drive_stops_without_po`, and the refusal part of `execute_refuses_a_shape_blocked_fix`) were judged by reading only. They are `po-eval` control-arm candidates (#208).
- The closed-pull-request rule (#286) and "a failed ship returns to a fix run" were not exercised.
- Routing itself was not re-checked here. It rests on s168's cases (`tests/driver-next-action.oracle.test.sh`), which this diff does not touch.
- The project has no end-to-end, build or type-check stage.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s173-drive-executes-next`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: fba11f7eca4953384edcf636a859c5da6bc28168

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-status main...story/s173-drive-executes-next` (26 paths) and checked each path against the s173 `Owns` line.
- [x] Every path outside `docs/` is inside `Owns`. Every path under `docs/` is this story's own evidence: its research, plan, verif and review. The diff adds no ADR.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other worktree is `story/s170-trust-signals`. It is not merged into `main` (`merge-base --is-ancestor` exits 1). Its `Owns` holds `po/src/trust/`, `method/hooks/po-run.sh`, `method/templates/verification-record.md`, `docs/interface-agent.md`, `po/src/context/mod.rs` and its own tests. None of these is in this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s173-drive-executes-next` exits 0, so I reused the record and did not rerun the suite.
  - The record's `Tree:` (74f343f…) equals HEAD outside `docs/`.
  - Its last run (tree eb21358…, which also equals HEAD outside `docs/`) is `bash tests/run.sh`, and it exited 0.
  - The project has no type check (`Typecheck: —`).
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–7 were already checked at loop 0. Since loop 0, the fix commit efb422e touches only `po-drive.md`, `po-execute.md`, the record and the review. `bin/po-lint` and every test are unchanged.
- [x] The loop-0 major is fixed.
  - `po-execute.md:29-35` now routes `execute` to a fix run, findings first.
  - Every other action now has a next step: `qa`, `review`, `ship` and `design` name their command, `plan` and `validate-plan` name `/po-plan`, `wait` and `ask` say what happens.
  - I checked these against `po/src/next/lane.rs`. It returns only `ship`, `wait`, `ask`, `plan`, `validate-plan`, `design`, `execute`, `qa`, `review` and `fix`, so the table covers every action. `method/commands/po-design.md` exists.
- [x] Loop-0 minor on the `ask` row: fixed. `po-drive.md:41` now says `po inbox add` first. `po inbox add` exists (`po/src/main.rs:24`, `po/src/inbox/mod.rs:34`).
- [x] Loop-0 minor on the Bash scope: partly fixed. `po-drive.md:18` now names `gh pr view`, `validated: yes` and the decisions log, and puts back "never edits a source file". What is still missing is in the minor findings below.
- [x] Word budgets hold: `po-drive.md` has 2483 words (limit 2500), `po-execute.md` has 850 (limit 854).
  - The record lists the sentences cut to pay for the fix. All of them are explanations, not rules.
  - The `## Model` sentence that was removed is not quoted by any file under `method/` or `tests/`.
- [x] Run interdicts hold. The fix commit does not touch `po/`, the fixtures, the s168 oracle, the other commands, `method/AGENTS.md`, `.claude/` or `.polype/`. No phrase assertion was added.

## References
- [x] The verbs `po next`, `po state`, `po record` and `po inbox` are dispatched in `po/src/main.rs:22-26`.
- [x] Every `/po-*` command that `po-execute.md` now points to exists under `method/commands/`.
- [x] The permission line in the frontmatter (`po-execute.md:9`) still matches the command written in precondition 6 character for character.

## Rules
- [x] The `AGENTS.md` conventions are respected. The `ask` row now follows `## What goes to the person` (inbox first).
- [x] No accepted ADR is contradicted. ADR-0120 still holds: `/po-execute` may run only `po next`, with no bare `Bash`.

## Tests
- Oracle: `po-gate oracle-intact s173-drive-executes-next` → exit 0
- Oracle: `po-gate oracle-intact s173-drive-executes-next` → exit 0
- [x] Floor: `po-gate floor-guard s173-drive-executes-next main` exits 0, so nothing was lowered.
- [x] None of the six kinds of test that prove nothing. The oracle runs `bin/po-lint` on altered copies of `po-execute.md` that swap the allowed line for another tool.
- [x] Three new tests, within `Test budget` 25.
- [x] Bite 1: I removed `|Bash\(*` at `bin/po-lint:149`.
  - Running `drive-executes-next.oracle.test.sh lint.test.sh`: 1 test failed.
  - I undid it, and `git diff --exit-code bin/po-lint` is clean.
- [x] Bite 2: I turned the ADR-0120 guard at `bin/po-lint:147` into a no-op (`continue` → `true`).
  - Same test files: 5 tests failed.
  - I undid it, and `git diff --exit-code` is clean. `git status --porcelain` is empty.

Criteria judged by reading:
- `drive_holds_in_2500_words`: holds, 2483 words.
- `drive_executes_what_it_reads`: holds. `po-drive.md:28-45` runs `po next`, does each action and runs it again. Only two routing rules remain: the closed pull request (#286) and the failed ship.
- `drive_stops_without_po`: holds, `po-drive.md:25`.
- `execute_refuses_a_shape_blocked_fix`: holds. `po next` answers `ask` with reason `findings-shape refused` (`lane.rs:159-160`), and the `ask` row of `po-execute.md:35` stops with no fix run spent. The case where `po` is missing or exits 2 is covered at `:27`.

## Neighbours
- [x] `po-drive.md:36` and `:63` point to `po-execute.md`'s `## Model`, which still exists.
- [x] `designer.md:49` and `planner.md:42` point to the "already recorded" sentence, which is kept at `po-drive.md:45`.
- [x] The loop-0 minor about `po-status.md:35`, `po-retro.md:37` and `po/src/next/lane.rs:1` still stands. Those files are outside `Owns` and under a run interdict, so it remains a follow-up.

## Lenses
Lenses run: security — triggered by the narrowed `Bash(...)` permission in `method/commands/po-execute.md` and the tools rule of `bin/po-lint`
- [x] The fix commit does not change the permission or the lint. The security lens found nothing new.

## Findings
- minor — method/commands/po-execute.md:29 — The action table sits between items 6 and 7 of the numbered list without being indented.
    - In Markdown this ends the list after item 6, and item 7 starts a new list.
    - A reader may not see that the table belongs to precondition 6.
    - Indenting the table under item 6 fixes it.
- minor — method/commands/po-drive.md:18 — The list of what Bash may do is still shorter than what the file asks of Bash.
    - Landing the decisions log as `## Landing the framing` says (`:105`) means a branch, a commit, a push and a pull request.
    - Preparing a lane commits the `<id>: QA evidence` commit (`:37`, `:64`).
    - A reader who takes the sentence literally could refuse these steps.
- minor — method/commands/po-status.md:35 — Carried over from loop 0, outside `Owns`. These files still point at prose that was removed from `po-drive.md`.
    - `po-status.md:35` and `po-retro.md:37` still say to read `Fix loop:` "the way `/po-drive` reads it".
    - `po/src/next/lane.rs:1` still cites `po-drive.md`'s `## Resuming`.
    - This needs a follow-up issue, not a fix here.
- minor — method/commands/po-drive.md:41 — Carried over from loop 0. The rewrite dropped two items from the report of a lane at `Max attempts`: its open findings and the loops spent. Today they show only through `po next`'s reason.

## Not verified
- I could not prove that the permission string `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)` matches the command the model actually types (ADR-0120). A person should run `/po-execute` once on a story whose review blocked and confirm that no permission prompt appears.
- No real `/po-drive` wave was run on top of `po next`. A person should run `/po-drive status`, then one wave, on a project with lanes at several stages.
- The new `execute` → fix-run row of `/po-execute` (a stale record under a blocked review) was judged by reading `lane.rs`. I did not run it.
- Three criteria were judged by reading only: `drive_executes_what_it_reads`, `drive_stops_without_po`, and the refusal part of `execute_refuses_a_shape_blocked_fix`. They are candidates for a `po-eval` control arm (#208).
- Two rules were not run: the closed pull request (#286) and "a failed ship returns to a fix run".
- I did not recheck routing itself. It rests on s168's cases (`tests/driver-next-action.oracle.test.sh`), which this diff does not touch.
- The project has no end-to-end, build or type-check stage.

Max severity: minor
Ship allowed: yes
