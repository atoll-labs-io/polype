# Review: s20-wiring

Diff reviewed: `git diff m2-cadrage...story/s20-wiring` (commits baf3952 and 77b1005). I did not write this code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1

## When blocked
Not applicable.

## Evidence reused
- [x] `bash .polype/hooks/po-gate.sh verif-current s20-wiring` exited 0. I also ran the comparison by hand: `git diff --quiet 88f946bc… HEAD -- . ':(exclude)docs'` returned 0.
- [x] `Verification mode: record`, so I did not rerun the full suite. I relied on the record in `docs/verif/s20-wiring.md`: `bash tests/run.sh` exited 0 with 123 passed and 0 failed.
- [x] The project has no Type check, E2E or Build command (all set to `—`). I did not substitute my own.
- [x] The record's "Not proven here" section says two things. The tests only check that phrases exist, not how an agent behaves. And `implementer.md` and `po-plan.md` do not yet know about design files.

## Plan
- [x] Tasks 1–8 are present. The D10, D16 and D17 cells match the plan word for word, and D18 is unchanged.
- [x] The fix run's changes stay inside the owned files and address findings 1–7. It added one departure the plan did not list: `Design source` in the orchestrator's `Reads settings:`. It comes from finding 4, and `method/templates/agents-local.md:24` defines that setting. The plan's Decisions table was not updated to match. That is acceptable for a fix run.
- [x] The run interdicts hold. The diff touches only the 6 owned files plus `docs/`, and adds no new setting.

## References
- [x] The status values match their sources:
  - `status: draft` in `po-prd.md:25,30` and `templates/prd.md:4`
  - `status: interviewing` in `po-brief.md:30-31` and `templates/brief.md:3`
  - `Stories ready:` in `po-stories-review.md:33`
  - `track: flow` in `templates/plan-flow.md:2`
- [x] The orchestrator's new Stage 0 check for a design system and `Design source` matches the checks `/po-design` makes at `po-design.md` checks 4–5.
- [x] The Stage 5 prompt sentence reuses the pattern `/po-flow` already uses (`po-flow.md:74`).
- [x] The orchestrator and status have Read and Bash, which the checks on `Target branch` need.

## Rules
- [x] Law 4 now lists `docs/designs/<id>/` as expected uncommitted work.
- [ ] `method/agents/implementer.md:18` still lists only research, plan and review as expected uncommitted work, so it contradicts the new Law 4. See finding 1.
- [x] No accepted ADR is contradicted.

## Tests
- [x] 6 tests in `tests/wiring.test.sh`, plus the existing help test, well within the budget of 25. None of them is one of the six kinds of test that prove nothing.
- [x] Bite testing: the auto mode classifier refused an in-place edit of `method/`. I therefore ran every mutation on a `git archive HEAD method tests` copy in `/tmp/s20-bite`, running only `wiring`, `pilot`, `structure` and `review`. Afterwards `git diff --exit-code` and `git status --porcelain` in the worktree were clean.

| Mutation | Tests that failed |
| --- | --- |
| M1: PRD block ("stop and point to `/po-prd`" → "warn … carry on") | 1 (`orchestrator_stops_without_approved_scope`) |
| M2: delete the Stage 5 design prompt paragraph | 1 (`design_files_reach_the_implementer`) |
| M5: reverse the `auto` rule (full at or below the threshold, short above it) | 1 (`orchestrator_picks_the_track_and_runs_design`) |
| M1b: brief block rewritten as "carry on anyway (do not stop and point to `/po-brief`)" | **0**, finding 3 |
| M3: status sends an escalated flow story back to `/po-flow <id>` | **0**, finding 4 |
| M4: delete the new Stage 0 check for a design system and `Design source` | **0**, finding 4 |
| M6: status maps `track: flow` to `full` (track inverted) | **0**, finding 5 |

## Neighbours
- [x] I read `implementer.md`, `po-execute.md`, `po-flow.md`, `po-design.md`, `po-review.md` and the settings template.
- [x] Review and flow paths: the reviewer now covers the short track itself, which duplicates the sentence `/po-flow` adds to its prompt without harm.
- [ ] The direct path does not know about design files: `/po-plan` and `/po-execute` run outside the orchestrator. See finding 1.

## Status of the findings from fix loop 0
- Finding 1 (critical): **fixed on the orchestrator path.** Law 4 now lists design files, and Stage 5 adds a sentence to the implementer's prompt that allows them. Some of it remains, now rated major: new finding 1.
- Finding 2 (major): **fixed on the orchestrator path.** The Stage 4 plan now reads `design.md`. The rest is folded into new finding 1.
- Finding 3: fixed. M1 fails 1 test.
- Finding 4: fixed, but the new clause is untested (M4).
- Finding 5: fixed. The values are confirmed above.
- Finding 6: fixed for the `auto` rule (M5 fails 1 test). The same weakness remains on the framing block (M1b).
- Finding 7: fixed, but untested (M3).

## Findings
1. **major**: the manual path for design files: `method/agents/implementer.md:18` and `method/commands/po-plan.md` against `method/AGENTS.md` Law 1 and Law 4.
   - Law 1 now officially lists Research → Design → Plan → Execute as separate commands.
   - `/po-plan`, run directly, never reads `docs/designs/<id>/`.
   - `/po-execute`, run directly, sends the implementer a prompt without the design sentence. The implementer's own contract says to stop on any uncommitted file other than research, plan and review, which contradicts the new Law 4.
   - Only `/po-orchestrator` works around both. This gap dates from s18 and is not a regression here. The damage is contained: the implementer stops, nothing is corrupted.
   - The fix needs a story that owns `implementer.md` and `po-plan.md`.
2. **minor**: design-system and `Design source` check (`method/commands/po-orchestrator.md:31`). Wording differs between stages: Stage 0 and Stage 1 say "a story whose text shows a (new) screen", while Stage 3 says "a story with a screen". Stage 0 also blocks a derived-screen story, which is correct because `/po-design` needs the system for derived screens too, but the text is looser than it should be.
3. **minor**: `tests/wiring.test.sh` (`test_orchestrator_stops_without_approved_scope`). The test checks for phrases, so a brief bullet that says "carry on anyway (do not stop and point to `/po-brief`)" still passes (M1b). This is the limit already named in the record. I name it again rather than rely on it.
4. **minor**: two clauses added by the fix run have no test.
   - The Stage 0 check for a design system and `Design source` in `method/commands/po-orchestrator.md` (M4).
   - The "escalated flow → `/po-research <id>`" rule in `method/commands/po-status.md` (M3).
5. **minor**: in `method/commands/po-status.md`, the track mapping (`track: flow` → `flow`, a plan without it → `full`) can be inverted without failing any test. `status_reports_framing_and_track` only checks that the phrase `track: flow` exists (M6).

## Not verified
- I did not run `/po-orchestrator` or `/po-status` on a real project. Nothing observed Stage 0 blocking on an unapproved PRD or brief, the `auto` track choice, the hand-off to `/po-flow` and the escalation back to Stage 2, or Stage 3 → Stage 5 with an uncommitted design folder. A person should run `/po-status` on a project with framing files, then run `/po-orchestrator` once on a story below the flow threshold and once on a screen story, and check that the implementer accepts `docs/designs/<id>/` and commits it.
- The reviewer's new `## Design conformity` section has never been applied to a real screen diff.
- I did not rerun the full suite or `overlap.test.sh`. I relied on the current record (123 passed).
- I ran the bite mutations on a temporary copy, not in the worktree, because an in-place edit of `method/` was refused. The copy was exported from HEAD, so the results apply to the committed code.
- The installed copies under `.claude/` and `.polype/` still hold the pre-s20 text, so this review ran under the old reviewer file. That does not matter here because the story has no screen.
- I checked the French wording in `po-help.md` for meaning, not proofread it.

Max severity: major
Ship allowed: yes
