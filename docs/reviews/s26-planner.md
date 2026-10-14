# Review — s26-planner

[Story](../stories.md) · [Plan](../plans/s26-planner.md) · [Verification](../verif/s26-planner.md)

Diff reviewed: `git diff m3-flotte...story/s26-planner`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `bash .polype/hooks/po-gate.sh verif-current s26-planner` → exit 0, no output. Confirmed independently: `git diff --quiet b2fa4d2b1804944f6b165d22d641898f3ba471d5 HEAD -- . ':(exclude)docs'` is identical, so the record at `docs/verif/s26-planner.md` names this exact code. `Verification mode: record`, record status complete, all exit codes 0 → I reused the unit suite (144 passed), `bash bin/po-lint` (no breach) and `tests/overlap.test.sh` rather than rerunning them. I did confirm the Killer SaaS corpus is still present at the default path `bin/ks-overlap` uses, because `tests/overlap.test.sh:12-15` returns 0 silently when it is absent — the record's claim that the check "really compared" holds.
- Project declares `Typecheck: —`, `E2E: —`, `E2E stage: —`, `Build: —`, `Build stage: —`. The project has no type check, no end-to-end suite and no build command; none was substituted.

## Plan
- [x] All six tasks present and done. Frontmatter, `Reads settings:` line, `## Checks`, `## Which track`, `## The contracts you carry`, `## Validation`, `## Limits`, `## Your final message` all exist in `method/agents/planner.md`; `tests/planner.test.sh` holds exactly the four `test_` functions the story names.
- [x] Nothing outside the plan. `git diff --name-only m3-flotte...story/s26-planner` lists exactly the five files the plan's "Files touched" section allows.
- [x] Run interdicts checked one by one: `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `docs/parite-killer-saas.md`, `method/templates/agents-local.md`, `method/commands/po-research.md`, `method/commands/po-plan.md`, `method/commands/po-flow.md`, `.claude/`, `.polype/`, `tests/run.sh`, `tests/lib.sh` and every pre-existing `*.test.sh` — all absent from the diff. One commit (`8b259c6`), English message, no co-author trailer, no `.env*` file in the diff.

## References
- [x] Every path the new file names resolves: `method/commands/po-research.md`, `method/commands/po-plan.md`, `method/templates/{research,plan,plan-flow,adr}.md`, `method/skills/{codebase-analysis,testing-doctrine}/`, `docs/decisions/` and ADR-0016 all exist.
- [x] The four settings of the `Reads settings:` line — `Story track`, `Flow threshold`, `Plan validation`, `Test budget` — all appear in `method/templates/agents-local.md`, so `tests/structure.test.sh:24` and the *settings* rule of `bin/po-lint` are satisfied. No s27 setting (`Parallel`, `Max attempts`, `Tracker`) leaked in.
- [x] Values checked against their source rather than accepted: the 200/250 caps match `method/commands/po-research.md:48` and `method/commands/po-plan.md:44`; "six tasks at most" / "about 150 lines" / `track: flow` match `method/commands/po-flow.md:59`; the five escalation signals and the "checked twice" rule match `po-flow.md:34-46`; the `auto` rule, including a story with no written complexity taking the full track, matches `po-flow.md:32`.
- [x] `bin/polype-dev-install:45` copies `method/agents` as a tree, so a new agent needs no registry entry. `.claude/` is untracked in this repository, so no installed copy was owed by this commit.

## Rules
- [x] `method/agents/planner.md` follows the house shape of `implementer.md` and `reviewer.md`: one prose line, then `Reads settings:`, then a pointer to the preloaded skills instead of restating them.
- [x] No accepted ADR contradicted. ADR-0012 (no red-first) is respected — the record shows no guard-disabling run by the implementer. ADR-0006 is covered by the reused overlap run.
- [x] `docs/parite-killer-saas.md` untouched is correct here: D02 is already `fait`, and D04 stays `partiel` because the grouped-per-wave validation it waits on is s30, not s26. s26 does not list that file under `Owns`.

## Tests
- [x] 4 tests, well within `Test budget: 25`. No excess, no enum pairs, no rule tested twice.
- [x] None of the six empty shapes: no self-written query, no impossible input, no swallowing `catch`, no fixture or mock answering for the check. The cap-drift assertion in `tests/planner.test.sh:21-30` is genuine coverage — it reads the two commands and compares.
- Bite (each mutation undone, `git diff --exit-code` clean after every one; final worktree verified clean):
  - `tools:` gains `Edit` → 1 failing test (`planner_never_writes_code`).
  - branch-check bullet (`planner.md:19`) deleted → 1 failing test (`planner_never_writes_code`).
  - `po-research.md` cap 200 → 300 → 1 failing test (`planner_carries_the_research_and_plan_contracts`, correct drift message).
  - `- codebase-analysis` removed from `skills:` → 1 failing test (`planner_preloads_testing_doctrine_and_codebase_analysis`).
  - `Flow threshold` removed from the `Reads settings:` line → 1 failing test (`planner_reports_the_track_it_used`).
  - `auto`/`Flow threshold` rule line deleted → 1 failing test (`planner_reports_the_track_it_used`).
  - "Name the track you used and why" reworded → 1 failing test (`planner_reports_the_track_it_used`).
  - **whole `## Validation` section (`planner.md:43-48`) deleted → 0 failing tests**, across `planner.test.sh`, `lint.test.sh` and `structure.test.sh` (17 passed, 0 failed), and `bash bin/po-lint` stayed clean. See F1.
  - **short-track bullet (`planner.md:39`) deleted → 0 failing tests**, same three files green, `po-lint` clean. See F2.
  - `Test budget` and `validated: no` stripped from the plan-contract bullet (`planner.md:38`) → **0 failing tests**. See F3.
- [x] No pre-existing test was modified or removed.

## Neighbours
- [x] Every mechanism that loops over `method/agents/*.md` was read and its verdict on the new file checked: `bin/po-lint` rules *settings* (`:87-104`), *tools* (`:112-145`) and *fail-closed* (`:150-172`), and `tests/structure.test.sh:24-34`. The `## Checks` section puts every `→` line under the fail-closed rule and each one ends in "stop and report", so the section is compliant, not merely tolerated.
- [x] No command delegates `subagent_type: planner` yet — `method/commands/po-flow.md`, `po-execute.md`, `po-review.md` and `po-stories-review.md` reference only `implementer`, `reviewer` and `stories-reviewer`. That wiring is s27's, correctly deferred by the run interdicts, and nothing in the suite requires an agent to have a caller.

## Findings
- **F1 — major** — `method/agents/planner.md:43-47` + `tests/planner.test.sh` — the plan's own pivot, "the planner honours `Plan validation` instead of always, or never, approving its own plan", is asserted by no test. Deleting the entire `## Validation` section leaves all 17 relevant tests green and `po-lint` clean; `Plan validation` would then remain on the `Reads settings:` line with nothing in the body using it, and no check notices that either. The plan's task 5 claims "Test that would fail: `planner_reports_the_track_it_used` and `planner_never_writes_code`" — neither test touches validation, so that claim is false. The shipped prose is correct; the decision everything hinges on is simply unguarded, and s27 (execute blocked if the planner never writes `validated: yes`) and s30 (checkpoint deleted if it always does) are the two stories that would pay for a drift. A `contains` on the `autonomous` and `human` clauses closes it.
- **F2 — major** — `method/agents/planner.md:35,39` — the short-track contract is both unanchored and untested. Line 35 binds the subagent to `method/commands/po-research.md` and `method/commands/po-plan.md`, but not to `method/commands/po-flow.md`, so the single bullet at line 39 is the planner's only source for `templates/plan-flow.md`, `track: flow`, six tasks and ~150 lines — exactly the paraphrase that acceptance criterion 1 ("sans les réécrire à sa façon") exists to prevent. Deleting that bullet fails no test. If it drifted to name `templates/plan.md`, every short-track plan the fleet produces would use the wrong template and nothing would catch it. Binding line 35 to `po-flow.md` as well, and extending the cap-drift assertion to the ~150-line figure, would make it hold.
- **F3 — minor** — `tests/planner.test.sh:18-19` — two of the seven assertions in `planner_carries_the_research_and_plan_contracts` cannot fail. `contains "$AGENT" '`Test budget`'` also matches the `Reads settings:` line (`planner.md:12`) and `contains "$AGENT" '`validated: no`'` also matches the `human` branch (`planner.md:45`). Verified: stripping both phrases from the plan-contract bullet at line 38 keeps all four tests green. The story's criterion 1 names "budget de tests" explicitly, so this is apparent coverage of a named criterion. Anchoring them to a longer clause, as the other five assertions do, fixes it.
- **F4 — minor** — `method/agents/planner.md:21` — the uncommitted-change check is narrower than the rule it enforces. It tolerates only `docs/research/<id>.md` and `docs/plans/<id>.md`, while `AGENTS.md` Law 4 lists the design (`docs/designs/<id>/`) and, during a fix run, the review as legitimate uncommitted work in a running story's worktree. A planner re-run on a lane that already holds either would stop on legitimate state. It fails closed, and M3 puts no design stage in the fleet, which is why this is minor rather than major — but `po-plan.md:37` explicitly expects `docs/designs/<id>/design.md` to exist sometimes, so the file contradicts itself in a small way.
- **F5 — minor** — `method/agents/planner.md:39` — the short-track frontmatter is quoted as `track: flow` only, where `po-flow.md:59` requires `track: flow` **and** `validated: no`. Harmless in practice: `method/templates/plan-flow.md:1-4` already carries `validated: no`, so filling the template supplies it. Worth aligning anyway since this file's job is carrying contracts verbatim.

Observation, outside this diff and not a finding: ADR-0016, which the plan and the story both lean on, still carries `status: proposed` in `docs/decisions/ADR-0016-flotte-un-driver-des-subagents.md`, while `AGENTS.md` speaks of "the accepted ADRs". It arrived on `m3-flotte` with the framing commit `515272e`, so it is outside `m3-flotte...story/s26-planner`. A person should decide whether to accept it before s27 builds on it.

## Not verified
- **Nothing runs `method/agents/planner.md`.** Every test in this story asserts what the file *says*; none proves a planner subagent given this prompt actually stops on a branch mismatch, picks the right track, or writes `validated: yes`. This is the story's central untested surface and it cannot be closed by the suite. A person should run one real lane in s27 — with `Plan validation: autonomous` on a complexity-1 story and again on a complexity-4 one — and read the two plans the planner produces.
- **The drift guard compares only the two length caps.** A requirement of `/po-research` or `/po-plan` that changes without touching a cap passes unnoticed, as the record itself admits. I read the two commands against `planner.md` by hand for this review and found them aligned today; nothing keeps them aligned tomorrow.
- **The unit suite, `bin/po-lint` and the Killer SaaS overlap check were reused from the record, not rerun** (`Verification mode: record`, tree matches). I reran only `planner.test.sh`, `lint.test.sh` and `structure.test.sh`, as the mutation step requires. I did not re-execute `bin/ks-overlap` on the new prose; I only confirmed its corpus is still present so the recorded run was a real comparison.
- **No type check, no end-to-end run, no production build**: the project declares none of these commands (`Typecheck: —`, `E2E: —`, `Build: —`). Nothing was substituted.
- **No screen, so no design review.** `docs/designs/` does not exist in this worktree and the story produces no interface; `docs/design-system.md` was not consulted.
- **I did not verify that the `skills:` frontmatter key actually preloads a skill at runtime** — only that `planner.md` matches the shape `reviewer.md` and `stories-reviewer.md` already use and that `bin/po-lint:52-61` parses it. If preloading silently failed, every existing subagent would share the problem.

Max severity: major
Ship allowed: yes
