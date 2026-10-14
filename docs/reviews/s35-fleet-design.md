# Review — s35-fleet-design

[Story](../stories.md) · [Plan](../plans/s35-fleet-design.md) · [Verification](../verif/s35-fleet-design.md)

Diff reviewed: `git diff m5-distribution...story/s35-fleet-design`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
Diff listed with `git diff --name-only m5-distribution...story/s35-fleet-design`, each path held against the story's `Owns` (`docs/stories.md:525`: `method/agents/designer.md`, `method/commands/po-drive.md`, `tests/fleet-design.test.sh`, `docs/defauts.md`).
- [x] Inside `Owns`: `method/agents/designer.md`, `method/commands/po-drive.md`, `tests/fleet-design.test.sh`, `docs/defauts.md`. Pipeline evidence in scope by construction: `docs/research/`, `docs/plans/`, `docs/verif/` for this id.
- [x] Outside `Owns`, two paths: `docs/decisions/ADR-0019-design-en-lane-sans-approbation.md` and `tests/drive.test.sh` — both required by a written rule (findings 1 and 2), so reported minor, not major.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this story's worktree; `git branch --no-merged m5-distribution` lists only `story/s35-fleet-design`. No lane collision.

## Evidence reused
- [x] `po-gate verif-current s35-fleet-design` → exit 0, record current. Reused: unit suite `bash tests/run.sh` exit 0 (175 passed) and `bash bin/po-lint` exit 0 (23 files), both at tree `e629ce0`. `Typecheck`, `E2E` and `Build` are `—` in `AGENTS.local.md`: the project has none, and I substituted nothing.
- The record's "Not proven here" is read and carried into `## Not verified` below.

## Plan
- [x] Tasks 1-7 all present: ADR-0019, `method/agents/designer.md`, the rewritten stage 2 + following paragraph + `## Report` line of `po-drive.md`, `tests/fleet-design.test.sh` (5 functions), the removal in `drive.test.sh`, defect 24 → `corrigé par s35`, the record.
- [x] Run interdicts checked one by one, all empty diffs as required: `method/commands/po-design.md`, `method/agents/implementer.md`, `method/agents/reviewer.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/AGENTS.md`, `method/templates/*`, `bin/polype-dev-install`, `bin/po-lint`, `.claude/`, `.polype/`, `tests/design.test.sh`, `tests/design-handoff.test.sh`, `tests/structure.test.sh`, `tests/lint.test.sh`, `tests/wiring.test.sh`, `tests/fleet-wiring.test.sh` — none appears in `git diff --name-only`. `docs/defauts.md` changes the status cell of line 39 only.
- [ ] One deviation: the plan said of `tests/drive.test.sh` "nothing else in the file is touched", but `test_drive_dispatches_lanes_in_one_message` also changed (subagent order now `planner designer implementer reviewer`). The change is necessary and correct — without it the suite goes red — but it was neither planned nor called out in the record (finding 2).

## References
- [x] Every path the new prose names was opened and exists: `method/commands/po-design.md`, `method/templates/design-screen.md` (its `## Gaps` and `## Seen and not seen` sections are real), `method/templates/design-brief.md`, `method/skills/design-doctrine/`, `method/agents/implementer.md`, `docs/decisions/ADR-0016`, `ADR-0017`, `ADR-0019`.
- [x] The contract designer.md carries matches its source: `internal → mockup.html` / `external → brief.md` (`po-design.md:52-54`), `python3 -m http.server --bind 127.0.0.1 <free port>` (`:62`), "nothing is measured here" (`:66`), `## Gaps` recorded not filled (`:48`). No value invented.
- [x] `Reads settings: Design source, Design skill, Design tool` — all three exist in `method/templates/agents-local.md:24-26`. ADR-0019's number is free and one past 0018; its frontmatter (`deciders`, `tags`) matches the repo's existing ADRs, and its body follows `templates/adr.md` with two options turned down and their reasons.

## Rules
- [x] `AGENTS.md` conventions: method prose in English, one commit, no `.env` in the diff, `git status --porcelain` empty, test file named after the story, acceptance criteria used verbatim as test function names.
- [x] No accepted ADR contradicted. ADR-0016 (a command does not run in a subagent → subagents carry the contracts) is extended the same way the `planner` extended it, not broken; `/po-design` keeps its human approval for the single-story path, and `po-orchestrator.md:47` still says so.
- [ ] Two coherence wrinkles, findings 4 and 5.

## Tests
- [x] Five functions, one per acceptance criterion plus the autonomy clause; far inside `Test budget: 25`. No assertion runs its own reimplementation, no fixture, no mock, no `catch`, no inventory test — each one quotes a clause of the file under test that a reader would act on.
- [x] Bite, five mutations, each restored and proven restored with `git diff --exit-code`:
  - `po-drive.md:84` `subagent_type: designer` → "a stage the lane stops at": **2 failing** (`drive_inserts_design_between_plan_and_execute`, `drive_dispatches_lanes_in_one_message`).
  - `po-drive.md:128` "names every story whose design no human approved" → "mentions the screens": **1 failing** (`drive_stops_a_screen_lane_without_a_design_system`).
  - `designer.md` Limits "You write under `docs/designs/<id>/` and nowhere else" → "wherever the story needs it": **1 failing** (`designer_writes_only_in_the_story_design_folder`).
  - `designer.md` tie-break "take the screen as **new**" → "**derived**": **1 failing** (`designer_asks_no_one`).
  - `po-drive.md:84` stripped of its arguments and its contract file: **1 failing** (`drive_inserts_design_between_plan_and_execute`), caught by the `method/agents/designer.md` assertion, not by the arguments one — see finding 6.
  - Working tree confirmed clean afterwards: `git status --porcelain` prints nothing.
- [x] The test the story makes obsolete (`test_drive_lane_includes_design_when_the_story_has_a_screen`) is removed, and every clause of it that is still true is re-asserted in `tests/fleet-design.test.sh`.

## Neighbours
- [x] Every other file mentioning `/po-design` read: `po-orchestrator.md:31,39,47` (single-story path, approval kept — consistent with ADR-0019), `po-status.md:38`, `po-help.md:23`, `AGENTS.md:32`, `implementer.md` (reads `docs/designs/<id>/design.md` before the screen tasks — unchanged and still correct), `reviewer.md` (preloads `design-doctrine`). Nothing downstream is left claiming a lane stops at design, except `po-drive.md:18` itself (finding 3).
- [x] `## Resuming` (`po-drive.md:47`) still routes a screen lane without a note to the design stage; the "first row that matches wins" order is untouched.
- [x] The story has no `Matrice` line, so `docs/parite-killer-saas.md` needed no update.

## Findings
- major — `method/agents/designer.md:4` and `:33` — the frontmatter grants `tools: Read, Write, Edit, Bash, Grep, Glob`, an explicit allowlist, while the contract at `:33` requires the mockup to be "served and looked at": opened "with the browser tool the session has", gone through in light and dark at two widths, and fixed where it shows up broken. No browser tool is in that list, and an explicit `tools:` list does not inherit the session's MCP tools, so a fleet-produced mockup is never actually looked at — the "rendered and looked at" half of acceptance criterion 1 is stated but not executable. The failure is at least honest, not silent: `:34` makes the designer record "no browser tool in the session" under `## Seen and not seen`, which is why this is major and not critical. Closing it means either naming the project's browser tool in `tools:`, or saying in the file that a lane's mockup normally goes unlooked-at, the way ADR-0019 says it goes unapproved.
- minor — `docs/decisions/ADR-0019-design-en-lane-sans-approbation.md` — outside the story's `Owns` line (`docs/stories.md:525`). `AGENTS.md` Law 6 requires it ("Structural decisions are ADRs in `docs/decisions/NNNN-<slug>.md`"), and the decision — a lane's design goes out unapproved — is structural, so this is a gap in the story's `Owns`, not a breach by the implementer. The plan and the research both declared it in advance.
- minor — `tests/drive.test.sh` — outside `Owns`, for the same kind of reason: its removed test asserted the three clauses this story deletes, and its order assertion had to gain `designer`, so the project's own convention "Keep existing tests green" forced the edit. Two gaps: the story's `Owns` should have listed it (s27, s33 and s34 all did), and the plan's interdict "only the one named test is removed / nothing else in the file is touched" was overrun by the necessary order-assertion edit, which the record does not mention ("change an existing test only when the story changes the clause it checks, **and say so**").
- minor — `method/commands/po-drive.md:18` — the driver's own opening still reads "`planner`, `implementer` and `reviewer` each work in their own context under the contract their own file fixes (ADR-0016)". The lane now has a fourth subagent and the file dispatches it twelve lines later; the sentence is in a file this story owns and was not updated.
- minor — `method/agents/designer.md:28` — "read `method/commands/po-design.md` in this repository before writing" points at a path that exists only in the Polype repository itself: an installed project has `.claude/commands/po-design.md` and no `method/` tree, so the designer's one source of contract is unreachable exactly where the fleet runs. This copies `method/agents/planner.md:35` verbatim, so it is the repository's existing convention rather than a regression of this story — but the story adds a second instance of it, and both will need the same fix.
- minor — `method/agents/designer.md:9` versus `po-drive.md:84,128` — the designer is told "the accepted ADRs in `docs/decisions/` bind you", while the rule it is bound by, ADR-0019, is `status: proposed`. The same mismatch is already open as defect 23 for ADR-0016, and the plan explicitly asked for `proposed`, so the implementer conformed; it is worth one line in `docs/defauts.md` rather than a fix here.
- minor — `tests/fleet-design.test.sh:57` — `holds "$wave" 'the story id and the absolute worktree path'` is satisfied by the planner line at `po-drive.md:83`, so it proves nothing about the designer stage: mutation E stripped that exact phrase from stage 2 and the assertion still passed (the sibling assertion on `` `method/agents/designer.md` `` is what turned the test red). Anchor it to the designer line or drop it.

## Not verified
- **No wave was ever run.** Nothing here shows a real `/po-drive` dispatching a `designer`, starting the design stage whole, or printing the report line about unapproved designs — the fleet is method prose, and I judged the contract, not a run. A person should run `/po-drive` on a project holding a story with a screen and check three things: a designer is actually dispatched, the note lands under `docs/designs/<id>/` uncommitted, and the report names that story as one whose design nobody approved.
- **The new subagent is not installed anywhere yet.** No `.claude/agents/designer.md` exists in this worktree; the installed copies are produced by `bin/polype-dev-install` (which globs `method/agents`, per the research), so the designer cannot be dispatched in this repository until someone re-runs the installer after the ship. I read the glob, I did not run the installer.
- **The browser half of finding 1 was reasoned, not executed.** I derived it from the frontmatter allowlist and the contract text; no designer was launched to confirm it cannot open a page. A person can settle it in one run by launching the subagent on any screen story and reading its `## Seen and not seen`.
- **Killer SaaS overlap not machine-checked.** `tests/overlap.test.sh` skips when the sources are absent, and they are absent on this machine, so the new prose in `designer.md` and `po-drive.md` was never held against the 8-word rule (ADR-0006). A person with the sources should rerun that file alone.
- **No design conformity review.** This story has no screen: no `docs/designs/s35-fleet-design/`, nothing opened in a browser, `docs/design-system.md` not exercised. Nothing to check there.
- **Unit suite and lint reused, not rerun**, on the strength of the current record; I ran only `tests/run.sh fleet-design.test.sh drive.test.sh` for the five mutations.

Max severity: major
Ship allowed: yes
