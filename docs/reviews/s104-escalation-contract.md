# Review — s104-escalation-contract

[Story](../stories.md) · [Plan](../plans/s104-escalation-contract.md) · [Verification](../verif/s104-escalation-contract.md)

Diff reviewed: `git diff main...story/s104-escalation-contract` (one commit, 0235fac), read in a context that did not write it. Findings are graded critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 542df88829b06041d0d078bd9f4addc8c4e3e583

## When blocked
Does not apply. The tree was the same at the start and at the end of the review.

## Ownership
- [x] Every path is inside `Owns`. The diff touches 13 paths. Ten are named in the story's `Owns` line. The other three are the story's own evidence (`docs/plans/`, `docs/research/` and `docs/verif/s104-escalation-contract.md`).
- [x] No path lies inside another running story's `Owns`.
  - s107 (`.worktrees/s107-forge-token-bound-to-host`) owns `method/commands/po-ship.md` and `tests/forge-token-host.test.sh`. Neither is in this diff.
  - The `story/reuse-ladder` worktree is not merged, but its diff touches only `docs/stories.md`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s104-escalation-contract` exited 0. With `Verification mode: record`, the record is reused: `bash tests/run.sh` exited 0 on the same code outside `docs/`. The project has no type check (`Typecheck: —`), no E2E command (`E2E: —`) and no build command (`Build: —`).
- [x] `po-gate qa-current` is not required: `QA stage: —` and `Surface: —`.

## Plan
- [x] Tasks 1 to 7 are all present. Nothing in the diff falls outside the plan.
- [x] Each run interdict holds:
  - `.claude/`, `.polype/`, the root `AGENTS.md` and `AGENTS.local.md` are untouched.
  - `method/hooks/`, `po-setup.md`, `po-ship.md`, `po-status.md`, `po-help.md`, `plan.md`, `plan-flow.md` and `adr.md` are untouched.
  - No existing test file is modified.
  - No new setting and no new gate.
  - The three existing sections of `capability-bricks` change nothing: the diff is additive only.
  - No ADR file and no `docs/decisions-log.md` were created.
  - `planner.md` holds 0 mentions of AskUserQuestion.
  - `bin/po-lint method` exits 0.

## References
- [x] Every reference was opened and checked:
  - `## Landing the framing` in `po-setup.md:60-90`: slug, paths, message, and the root-index `git add` at `:74`.
  - `po-ship.md:79`: the local ship stops on a staged or modified tracked file.
  - ADR-0070, ADR-0077 and ADR-0080 exist and are accepted.
  - `bin/polype:98-101` copies `method/templates` whole, so the new template gets installed.
  - AskUserQuestion is declared in `po-plan.md` and `po-orchestrator.md`.
  - `/po-drive` has Bash and no Write, which matches "append through Bash".
- [x] The marker string is the same in all five writers and readers. The criteria order matches ADR-0077.

## Rules
- [x] The `AGENTS.md` conventions are respected: method text in English, tests in bash, ids unchanged.
- [x] No accepted ADR is contradicted. The new text puts ADR-0077 into the method, and the stops of ADR-0070 stay stops.

## Tests
- [x] Floor: `po-gate floor-guard s104-escalation-contract main` exited 0, so nothing was lowered.
- [x] None of the six empty test shapes appears. The tests quote phrases inside the section that must hold them. Two weak spots are listed under Findings.
- [x] Budget: 6 tests out of 25.
- [x] Bite. Each mutation was undone and `git diff --exit-code <file>` came back clean:
  - The new "goes to the person at once, in a message of its own" sentence removed from `po-drive.md` `## A wave` → 1 failing test (`human_stops_do_not_halt_the_fleet`).
  - The marker row moved after the plain plan row in the `po-drive.md` resume table → 1 failing test (`plan_with_a_tech_choice_waits_for_a_human`).
  - The planner's `## Validation` paragraph removed ("keeps `validated: no` whatever `Plan validation` says") → 1 failing test (`plan_with_a_tech_choice_waits_for_a_human`).
  - The `po-plan.md` `## Approval` paragraph removed (the step that puts the choice to the person, accepts the ADR and removes the marker) → **0 failing tests**, across `escalation-contract.test.sh` and `plan.test.sh`. This rule is not tested (see Findings).
- [x] The story makes no test useless.

## Neighbours
- [x] Other readers were checked by grepping every reader of `Root cause: not found`.
  - `method/hooks/po-session.sh` (s103) and `po-status.md` do not read the new marker. Both are outside `Owns`, and the research already reported it.
  - The stacking and staging done by `/po-setup`'s landing fit the decisions-log flow under `pr` and `local` with `automatic`. The local-plus-human "Not now" case is accepted in the text, as the plan requires.

## Lenses
Lenses run: none. No auth, route, upload or webhook path; no migration; no lockfile or manifest; no server-side code. The diff is prose in the method plus one bash test.

## Findings
- **major** — `method/commands/po-flow.md:74`, with `method/commands/po-plan.md:30`
  - The new Approval clause sends a short-track plan that needs an ADR-worthy choice to `/po-research <id>`, but it leaves the flow plan on disk without the marker and without a drafted ADR.
  - `/po-research` never handles an existing plan.
  - `/po-plan` sees "A plan file already present? Skip to Approval". With no marker, the choice is never put to the person. Under `Plan validation: autonomous` the plan validates itself, which is exactly what the criterion `plan_with_a_tech_choice_waits_for_a_human` forbids.
  - Mitigating: the second signal check (`po-flow.md:46-48`, "write no plan") normally fires first. This is only a backstop that does not hold.
  - Fix direction: say what happens to the plan already written. Either the clause writes the marker and `status: proposed` into it, or the plan is removed before pointing to `/po-research`.
- **major** — `tests/escalation-contract.test.sh` `test_plan_with_a_tech_choice_waits_for_a_human`
  - The one step that actually settles the choice with the person (`po-plan.md:50`, the `## Approval` paragraph) can be deleted and no test fails.
  - The checks on `po-plan.md` use `contains` on the whole file, and the marker and the `whatever`-phrase are also satisfied by the bullet at `:45`.
  - Fix direction: assert the marker inside `section_of "$PLAN_CMD" 'Approval — per \`Plan validation\`'`.
- **minor** — `tests/escalation-contract.test.sh` `test_human_stops_do_not_halt_the_fleet`
  - `holds "$wave" 'the other lanes carry on'` already passed on `main`: the model-rejection paragraph of `## A wave` holds that phrase. The assertion adds no bite.
  - `contains "$ORCH" 'at once'` is checked against the whole file, not the new paragraph.
- **minor** — `method/AGENTS.md:79`
  - The rule says *each* decision the lead takes alone is logged, including "an implementation detail" and "an answer given without asking".
  - The only writer, `po-drive.md` `## The decisions log`, logs a closed list without those two.
  - `/po-orchestrator` logs nothing for its own lone decisions: autonomous plan approval and fix runs.
  - The story criterion says "chaque décision prise seule". The plan narrowed it to waves, and that narrowing is not written down as a limit.
- **minor** — `method/agents/planner.md:56`. In the fallback "No number there … write the ranked options in the plan", the marker line is not repeated. A reader could take it that the marker is only written when an ADR file is.
- **minor** (outside `Owns`, for a later story) — `method/hooks/po-session.sh` and `method/commands/po-status.md` do not recognise `Technical choice: waiting for a human`. A plan waiting on a choice is missing from the session-start picture and from `/po-status`; it shows only in `/po-drive status`.

## Not verified
- **Behaviour of an agent following the text.** The suite and this review check method prose by quoted phrases. Nobody ran a `/po-drive` wave to see a human stop raised at once in its own message, the decisions log appended after the last ship and landed through `## Landing the framing`, or a planner leaving `validated: no` on a marked plan. A person should run one wave on a sample project that has an ADR-worthy story and one ordinary story, and confirm that the ordinary lane carries on while the other waits.
- **The decisions-log landing against a real forge.** The `pr` path was not exercised against GitHub: stacking on an open `framing/decisions-log` PR, then the ff of the root with a staged copy. It was only read against `po-setup.md:61-88`. A person should try one landing under `Merge mode: pr` with `automatic` and one with `human`.
- **The `/po-plan` Approval flow with a marker.** Asking the ranked options, rewriting or accepting the ADR, and removing the marker were never run. A person should run `/po-plan` on a plan holding the marker.
- **No QA report:** `QA stage: —`, so no QA and no `## Not seen` to carry over.
- **No type check, E2E or build:** the project has none of these commands.

Max severity: major
Ship allowed: yes
