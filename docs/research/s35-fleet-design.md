# Research — s35-fleet-design

[Story](../stories.md)

## Structuring facts
- **Assumption corrected**: the story's `Owns` is incomplete. `tests/drive.test.sh:129-130` asserts the very clauses this story removes (`no design subagent exists`, `` `/po-design <id>` to run in `<Worktree root><id>` ``); that file must change or the suite goes red, and it is not in `Owns`.
- `method/commands/po-drive.md:84` is the whole design stage today: a stage the lane **stops at**, justified by "a command does not run inside a subagent (ADR-0016)".
- `docs/decisions/ADR-0016-...md:26` states that same reason is why the `planner` subagent exists — a `designer` subagent is the same move, so ADR-0016 is extended in practice, not contradicted; no new ADR is required for the subagent to exist.
- Two steps of `/po-design` cannot run in a subagent as written: the tie-break AskUserQuestion at `method/commands/po-design.md:40` and the approval at `:71`. The lane needs a rule for both.
- `bin/polype-dev-install:45` installs `method/agents` by globbing the directory, so a new agent file ships with no manifest edit; `bin/po-lint:76` and `tests/structure.test.sh:26` glob it too, so `designer.md` must satisfy their rules.

## Story
A story with a screen must cross its lane without a human in the middle of a wave (defect 24, `docs/defauts.md:39`). Four criteria:
1. `designer_agent_carries_the_design_contract` — a `designer` subagent carrying `/po-design`'s requirements (derived vs new, one artefact, rendered and looked at, no invented component, gaps recorded) and preloading `design-doctrine`.
2. `drive_inserts_design_between_plan_and_execute` — the lane dispatches the designer after the plan, before the implementer.
3. `drive_stops_a_screen_lane_without_a_design_system` — no `docs/design-system.md`, or `Design source: —` → the lane stops, says so, never skips.
4. `designer_writes_only_in_the_story_design_folder` — writes only under `docs/designs/<id>/`.

## Current code
- `method/commands/po-drive.md:79-90` — `### Dispatching`: four numbered lane stages; step 2 is the design **stop**. Step 84 names the two `/po-design` conditions, says the stage is never skipped, and points at `/po-design <id>`. Line 88 then explains that the design lands after the plan, that the planner is not re-run, and that the implementer reads the note.
- `method/commands/po-drive.md:48` — `## Resuming` already has the row `` `docs/designs/<id>/design.md` is absent | the design stage ``. Resuming needs no change.
- `method/commands/po-design.md:21-72` — the contract to carry: checks (`:25` design system, `:26` `Design source`, `:30` no screen), `docs/designs/<id>/` as the only output (`:35`), derived/new (`:39-40`), the note from `templates/design-screen.md` with `## Gaps` (`:42-48`), exactly one artefact chosen by `Design source` (`:50-59`), serve over `python3 -m http.server` and look in light/dark, desktop/mobile, never measure (`:61-68`), approval (`:70-71`).
- `method/agents/planner.md` — the model to follow for a fleet subagent: frontmatter `name/description/tools/model: inherit/skills`, a `Reads settings:` line, a `## Checks` block (branch, repo root, unexpected dirty files, missing setting), the ban on `git worktree add|switch|checkout|stash` (`:24`), `## Limits` naming the only files it may write (`:51`), and a final-message section.
- `method/agents/reviewer.md:6-9` already preloads `design-doctrine`; `method/agents/implementer.md:20,38` already reads `docs/designs/<id>/design.md` before the screen tasks and commits the folder. Nothing downstream needs changing.
- `docs/defauts.md:39` — defect 24, status `ouvert`.

## Attachment points
| What | Where |
| --- | --- |
| New subagent | `method/agents/designer.md` (new file) |
| Lane stage 2 rewritten from stop to dispatch | `method/commands/po-drive.md:84` and the paragraph at `:88` |
| Story's own test | `tests/fleet-design.test.sh` (new file) |
| Obsolete assertions | `tests/drive.test.sh:113-143`, clauses at `:128-130` |
| Defect closed | `docs/defauts.md:39` → `corrigé par s35` |

## Verified interfaces
- `tests/lib.sh:18-29` — `tools_of` reads either `allowed-tools:` (YAML list) or `tools: A, B`; `needs_tool` / `lacks_tool` assert on it. Subagents use the inline `tools:` form (`method/agents/planner.md:4`).
- `tests/lib.sh:37-39` — `settings_read_by` reads the backticked names of the first `^Reads settings:` line.
- `method/templates/agents-local.md:24-26` — `Design source`, `Design skill`, `Design tool` exist as settings; `Worktree root` too. Any other name in `designer.md`'s `Reads settings:` line fails `tests/structure.test.sh:24` and `bin/po-lint` rule `settings`.
- `tests/drive.test.sh:8` — `section_of` cuts on `^## `, so the design stage must stay inside `## A wave`; `:121` locates it by the literal `**The design stage**` and `:124` requires its line number between `subagent_type: planner` and `subagent_type: implementer`.
- `bin/polype-dev-install:45` — `install_tree "$method/agents" .claude/agents`: directory-wide, no per-file manifest.

## Traps
- **`bin/po-lint` rule `fail-closed`** (`bin/po-lint:164-181`): inside a `## Checks`, `## Preconditions` or `## Step 0` heading only, any `→` whose left side names an absence (`No `, `no `, `missing`, `` `—` ``, `not `…) must have `stop`, `ask`, `carry on` or `never blocks` on its right. `designer.md`'s checks must obey it, and `tests/lint.test.sh:47` runs the lint over the real `method/` as part of the suite.
- **`tests/overlap.test.sh`** fails on any 8-word run shared with Killer SaaS sources. New prose must be written from `docs/parite-killer-saas.md`, never copied.
- **`tests/structure.test.sh:24`** and `bin/po-lint` both iterate `method/agents/*.md`: the new file needs its `Reads settings:` line or two tests go red at once.
- **`tests/design.test.sh` and `tests/design-handoff.test.sh` must stay green**: this story changes the fleet, not `/po-design` itself nor the implementer's handoff.
- `method/commands/po-orchestrator.md` stage 3 keeps applying `/po-design` for the single-story path; it is outside `Owns` and outside the criteria — leave it alone. `po-drive.md:88` currently contrasts the two paths and will need rewording, not deletion.
- No migration, no dependency, no contract change. s34 is shipped (`4f2af38`), so the dependency is satisfied.

## Open questions
- **Who approves a design a lane produced?** `/po-design:70-71` ends on an AskUserQuestion; a subagent asks no one. There is no `Design validation` setting, and the story's criteria do not mention approval. The plan must choose between mirroring `Plan validation: autonomous` (the note is recorded, the wave report says no human read it) and adding a setting — the second widens the story's scope.
- **What does the designer do when derived vs new is unclear?** `/po-design:40` asks once; the subagent cannot. Treating the doubt as a new screen produces one artefact and records the doubt in `## Gaps`; stopping the lane reintroduces the very interruption the story removes.
- **Is `tests/drive.test.sh`'s design test edited in place, or moved to `tests/fleet-design.test.sh`?** Moving keeps each test file tied to the story that owns the clauses, and leaves `drive.test.sh` asserting only what s27/s33 still guarantee.
- **Does the designer get the `Design skill` named by the project, which it cannot load?** A subagent's `skills:` list is fixed at write time, while `Design skill` is per project. The plan must say what the designer does when `Design source: internal` names a skill it does not carry.

## Complexity
Story: 3 → after reading the code: 3. One new subagent file, one rewritten section of `po-drive.md`, one new test file plus the removal of obsolete assertions in another. The doctrinal questions above are the real cost, not the volume.

## Split
Not needed at 3.
