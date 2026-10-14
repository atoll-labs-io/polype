# Review: s59-model-by-complexity

[Story](../stories.md) · [Plan](../plans/s59-model-by-complexity.md) · [Verification](../verif/s59-model-by-complexity.md)

Diff reviewed: `git diff main...story/s59-model-by-complexity`, read in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 216aa58ae9f8645d42548b84a87cda48ddf34dd2

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s59-model-by-complexity` and checked each path against the `Owns` line at `docs/stories.md:904`.
- [x] All 12 code and test paths are inside `Owns`. The research, plan and verification files are the story's own pipeline evidence.
- [x] One path is outside `Owns`: `docs/decisions/ADR-0036-le-plan-ecrit-dans-le-contexte-de-la-commande-tourne-sur-le-modele-de-la-session.md`. AGENTS.md Law 6 requires an ADR for a structural decision, and the planner contract (`method/agents/planner.md:52`) puts it on the story branch. So this is a gap in `Owns`, not a breach by the implementer. It is graded **minor** below.
- [x] No path belongs to another running story. `git worktree list` shows only main and this lane, and no other `story/*` branch is unmerged.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s59-model-by-complexity` exits 0. The record is complete and its `Tree:` (e02116b…) matches HEAD outside `docs/`. Its single run (`bash tests/run.sh`, exit 0, tree 55b2a1b…) also matches HEAD outside `docs/`. I relied on it and did not rerun the suite. The project has no type check (`Typecheck: —`), no end-to-end command (`E2E: —`) and no build (`Build: —`). I read "Not proven here": the record states that no real dispatch was made with a `model` value.
- [x] `po-gate qa-current`: not required, because the story has no screen.

## Plan
- [x] Tasks 1 to 8 are all present, and I found nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`: not in the diff.
  - `method/agents/`: only line 5 of `implementer.md` changes. The other five agents stay `model: inherit`.
  - `docs/parite-killer-saas.md` and `tests/distribution-wiring.test.sh`: not in the diff.
  - No new dispatch was added. The orchestrator and `/po-flow` still launch no planner or designer.
  - The only existing test changed is `tests/execute.test.sh`, at its old line 34, which the plan justifies.
  - No fallback wording: every refusal sentence says to stop and never retry.
  - No model names beyond `opus` and `sonnet`.

## References
- [x] I opened the targets of every reference:
  - `/po-execute`'s `## Model` section exists, and the drive, orchestrator and flow files point to it.
  - Every name on the `Reads settings:` lines is in the template's block, as `structure.test.sh` requires.
  - There are no other Agent dispatch sites in `method/commands`. Only `po-drive` dispatches the planner or the designer.
  - The research's complexity line format, `Story <n> → <m>`, matches the "Complexity read" rule.
- [x] Values: the defaults `opus` / `sonnet` / `2` match the story's criterion `setup_offers_the_defaults`. The list of names the Agent tool accepts could not be confirmed from the repository (see Not verified).

## Rules
- [x] AGENTS.md conventions are respected, with one exception: the parity matrix line (minor finding below).
- [x] No accepted ADR is contradicted. The change follows ADR-0032, and ADR-0036 adds to it without editing it.

## Tests
- [x] Floor: `po-gate floor-guard s59-model-by-complexity main` exits 0, so nothing was lowered. The `model: opus` assertion removed from `tests/execute.test.sh` is justified in plan task 2, and the clause moved to `test_implementer_no_longer_pins_a_model`.
- [x] Assertions pin the six acceptance criteria, and none of the six empty test shapes appears. These are text-contract tests that quote exact phrases.
- [x] Six tests, within `Test budget` 25.
- [x] Bite tests. Each mutation was undone, and `git diff --exit-code` was clean after each one.
  1. I removed "`model:` set to `Model strong` …" from the `/po-review` delegation line → 1 failing test (`deciders_always_run_on_the_strong_model`).
  2. I inverted the implementer rule in `/po-drive` item 3 to "`Model strong` up to `Light up to`, `Model light` above" → **0 failing tests** (model-routing and drive suites, 18 tests).
  3. I changed the `/po-execute` refusal rule from "stop and report" to "dispatch it again without `model` and report", leaving the "Never retry" sentence → **0 failing tests** (model-routing and execute suites, 15 tests).
- [x] No test was made useless by the story.

## Neighbours
- [x] I read the other places that refer to the changed rule:
  - `/po-design`, `/po-plan` and `/po-research` dispatch no subagent.
  - `docs/parite-killer-saas.md:106` (H04) is now stale (minor finding below).
  - Projects with an existing `AGENTS.local.md` will now stop in every dispatching command (major finding below).

## Lenses
Lenses run: none. The diff touches only Markdown method files and bash tests: no auth paths, routes, migrations, lockfiles or server code.

## Findings
- **major**: existing `AGENTS.local.md` files now stop every dispatching command.
  - Where: `method/commands/po-execute.md:28`, `po-review.md:24`, `po-qa.md:28`, `po-stories-review.md:26`, `po-drive.md:24`, `po-flow.md:36`, `po-orchestrator.md:24`.
  - Problem: every project with an existing `AGENTS.local.md`, Polype included, lacks `Model strong` / `Model light` / `Light up to`. `bin/polype` never touches that file. So after an `update`, `/po-execute`, `/po-review`, `/po-qa`, `/po-flow`, `/po-orchestrator`, `/po-stories-review` and even `/po-drive status` stop until a person adds the three lines. Before this story, these commands worked.
  - Why only major: the stop is loud and names the setting, as AGENTS.md "Reading settings" requires, and the story notes accept it for Polype. But no upgrade note tells other projects. `/po-drive` already makes an exception for `QA stage` for this reason, and nothing similar was considered here.
  - What to do: add an update or migration note (e.g. `docs/installation.md`). Also mention it in the ship report.
- **major**: the refusal rule's "stop" is not tested.
  - Where: `method/commands/po-execute.md:37` (refusal rule) and `tests/model-routing.test.sh:66`.
  - Problem: the story names this as its risk ("la commande doit dire quoi faire d'un refus"). Replacing "stop and report" with a redispatch without `model` keeps all tests green, because the test only quotes "Never retry with another model or with none". The same gap applies to the refusal sentences of `po-review`, `po-qa`, `po-stories-review` and `po-drive`, none of which are asserted at all.
- **minor**: the direction of the implementer rule is untested in three files.
  - Where: `tests/model-routing.test.sh:13-16` (`implementer_adapts_in`), against `method/commands/po-drive.md:93`, `po-flow.md:75` and `po-orchestrator.md:57`.
  - Problem: the helper only checks that `Light up to` appears on the implementer line. Swapping strong and light in `/po-drive` item 3 fails no test. The single statement in `/po-execute` is pinned exactly, which limits the risk.
- **minor**: ADR-0036 is outside `Owns` (see Ownership).
  - Where: `docs/decisions/ADR-0036-le-plan-ecrit-dans-le-contexte-de-la-commande-tourne-sur-le-modele-de-la-session.md`.
  - Problem: Law 6 and the planner contract require this ADR, so `Owns` does not list `docs/decisions/` when it should. Nothing to change in the code.
- **minor**: parity matrix line H04 is now out of date.
  - Where: `docs/parite-killer-saas.md:106`.
  - Problem: H04 still says "implémenteur épinglé sur le modèle le plus fort", which is no longer true. The project convention says a story updates the parity lines it implements. The plan deliberately left this file out, because it is outside `Owns` and `distribution-wiring.test.sh` pins `partiel`. A person should reword it.
- **minor**: the session-model caveat is not stated in the standalone commands.
  - Where: `method/commands/po-plan.md`, `po-design.md`, `po-research.md`.
  - Problem: these standalone commands write plan, design and research in the session's context, but do not carry the ADR-0036 sentence ("start the session on `Model strong`"). The same limitation holds there unstated. These files are outside `Owns`, so this is for a later story.

## Not verified
- **Agent tool model names.** I did not check that the Agent tool accepts `opus` and `sonnet` as a per-call `model`, or that the value overrides a subagent's `model: inherit`. I have no Agent tool in this context and no dispatch was performed. To cover it, a person should run `/po-review` or `/po-execute` on a throwaway story with the settings in place, and check which model ran (e.g. the session transcript or `/cost` breakdown). Then set one setting to a bogus name and confirm the command stops without writing a review.
- **Real orchestration runs.** No `/po-drive`, `/po-orchestrator` or `/po-flow` run was made. The routing exists only as prose for the commands to follow, and no hook enforces which model a subagent ran on. To cover it, run `/po-drive status` and one wave on a project that has the settings, and check that the models column of the report is filled.
- **Unit suite, lint and overlap.** I did not rerun the full unit suite, `po-lint` or the overlap test. I relied on the current verification record (exit 0, tree matches HEAD outside `docs/`).
- **Polype's own settings.** Polype's own `AGENTS.local.md` still lacks the three settings. A person must add `Model strong: opus`, `Model light: sonnet` and `Light up to: 2` after ship, before the next pipeline run uses the refreshed installed copies.

Max severity: major
Ship allowed: yes
