# Research — s19-flow

## Structuring facts
- The short track has no `docs/research/<id>.md`, yet `implementer` reads it (`method/agents/implementer.md:19`) and `reviewer` lists it among its inputs (`method/agents/reviewer.md:17`). Both files are outside Owns (`reviewer.md` belongs to s20): `/po-flow` must say, in its delegation prompts, that the plan's verified facts replace the research.
- `Story track` and `Flow threshold` already exist in the settings template (`method/templates/agents-local.md:27-28`, rows `:50-51`, added by s11): no new setting is needed.
- The gates do not depend on the track: `po-gate plan-validated` reads only `validated: yes` in the plan frontmatter (`method/hooks/po-gate.sh:18-22`), so a `plan-flow` frontmatter with `track: flow` plus `validated:` passes the pre-commit hook unchanged.
- Adding `method/commands/po-flow.md` makes `every_command_listed_in_help` fail until `/po-flow` appears in `method/commands/po-help.md` (`tests/pilot.test.sh:38-46`) — a one-line edit outside Owns, same precedent as s18 (`/po-design` sub-line).

## Story
`/po-flow <story>` runs research and plan in one pass for a simple story, then the same execute → review → ship cycle, so a complexity-1 story does not pay for six contexts. Criteria (test names in `tests/flow.test.sh`): `flow_keeps_every_gate`, `flow_checks_escalation_signals_twice`, `flow_respects_story_track`, `plan_flow_template_carries_verified_facts`. Matrix line D15 (`docs/parite-killer-saas.md:64`): three contexts (research+plan merged), nothing relaxed, five escalation signals checked before and after reading the code, ≤ ~6 tasks, verified facts at the top of the plan, ~150-line ceiling.

## Current code
- `method/commands/po-research.md`: creates the worktree from the freshest `Target branch`, copies ignored `.env*`, runs `Install`; writes `docs/research/<id>.md` from `templates/research.md`, uncommitted.
- `method/commands/po-plan.md`: requires the worktree, writes `docs/plans/<id>.md` from `templates/plan.md` with `validated: no`, then approval per `Plan validation` (`human` → AskUserQuestion Approve/Change/Stop; `autonomous` → self-check and say so).
- `method/commands/po-execute.md` / `po-review.md`: no Write/Bash for execute; delegate to `implementer` / `reviewer` with fixed prompts; review records `Fix loop:` and the two verdict lines; missing verdict → written as blocked.
- `method/commands/po-ship.md`: verdict gate, expensive checks once, squash merge, cleanup after proof.
- `method/commands/po-orchestrator.md`: sequences the five stages in one context; delegates execute/review; two fix loops max; checkpoints per settings. It does not know `Story track` yet (wiring is s20).
- `method/templates/plan.md`: frontmatter `validated: no`; sections Story, Tasks, Run interdicts, The pivot, Files touched, Test strategy, Done when.

## Attachment points
- New `method/commands/po-flow.md` (Owns).
- New `method/templates/plan-flow.md` (Owns), referenced as `templates/plan-flow.md`.
- New `tests/flow.test.sh` (Owns).
- `method/commands/po-help.md` — one line (outside Owns, required by the help test).
- `docs/parite-killer-saas.md` D15 status cell (convention).
- Installer copies every `method/commands/*.md` and `method/templates/*.md` (`tests/install.test.sh:9`); nothing to register.

## Verified interfaces
- `settings_read_by`, `template_settings` (`tests/lib.sh`): every backticked name on `Reads settings:` must be a template setting (`tests/structure.test.sh:24-34`).
- `needs_tool` / `lacks_tool` read `allowed-tools:` YAML lists (`tests/lib.sh`).
- Section-scoped assertions: local `section_of` helper pattern in `tests/design.test.sh:9-19`.
- Five signals, verbatim from the story: migration, new screen, authorization or tenant scope, API contract, new dependency.

## Traps
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; never open `ks-flow` or `plan-flow` from Killer SaaS — write from D15's French description.
- `Story track: flow` means every story takes the short track; `auto` accepts only complexity ≤ `Flow threshold`; `full` refuses. A story without a complexity under `auto` cannot be compared → refuse (fail closed).
- The short track must not skip `/po-design`: "new screen" is an escalation signal, so a story with a new screen goes to the full track anyway.
- The escalation check after reading the code must be able to turn the run around even after the worktree exists: the worktree is kept, `/po-research <id>` reuses it.
- Nothing is committed by `/po-flow` itself: the plan stays uncommitted like on the full track (Law 4); the implementer's first commit carries it. The implementer's status check tolerates only research/plan/review files (`implementer.md:18`) — a plan-only worktree is fine.
- Orchestrator/status/rules wiring of the track is s20's: do not touch them.

## Open questions
- Does `/po-flow` stop after the validated plan (Next: `/po-execute`) or carry on through execute, review, ship itself? D15 says "same cycle in three contexts", which reads as: the flow context coordinates everything, implementer and reviewer are the other two. The plan decides.
- Task ceiling: D15 says ≤ ~6 tasks; exceeding it — escalate or allow with justification?

## Complexity
Story: 3 → 3. Prose command plus template plus structural tests, like s18; the delegation-prompt workaround for the missing research is the only subtle point.

## Split
Not needed.
