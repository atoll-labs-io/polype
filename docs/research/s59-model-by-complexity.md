# Research — s59-model-by-complexity

## Structuring facts
- **False assumption, corrected — Owns was incomplete.** Moving the implementer to `model: inherit` breaks `tests/execute.test.sh:34`, which asserts the exact line `model: opus`; `po-bounds` lets the implementer write only `docs/` and the committed `Owns` of its story (`method/hooks/po-bounds.sh:4-6`, `owns_line` reads `HEAD:docs/stories.md`). Commit `101cf2a` added `tests/execute.test.sh` to the `Owns` line (`docs/stories.md:904`), and this lane's HEAD is that commit.
- **False assumption — not every listed command launches a planner or designer.** Only `/po-drive` dispatches `subagent_type: planner` and `designer` (`method/commands/po-drive.md:91-92`). `/po-orchestrator` writes research, design and plan in its own context (`method/commands/po-orchestrator.md:43-52`), `/po-flow` writes research and plan in its own (`method/commands/po-flow.md:53-61`), and `/po-design` dispatches no agent at all. No command can choose its own context's model: settled by ADR-0036.
- Today no command passes a `model` to the Agent tool; the only pinned model is `model: opus` in `method/agents/implementer.md:5`, every other subagent being `model: inherit` (planner, designer, qa, reviewer, stories-reviewer, line 5 each).
- The complexity of a story is readable in two places: `- **Complexité** : <n>` in `docs/stories.md` (format `method/templates/stories.md:10`) and the first line of `## Complexity` in `docs/research/<id>.md`, written `Story <n> → <m>` (`docs/research/s58-designer-browser.md:54`, `s57-qa-in-the-fleet.md:60`).
- A missing setting stops the command that needs it (`AGENTS.md`, "Reading settings"); `po-lint`'s fail-closed rule rejects, inside `## Checks` / `## Preconditions` / `## Step 0`, any `→` line whose trigger names an absence or `—` without saying stop, ask, carry on or never blocks (`bin/po-lint:158-182`).

## Story
Deciders (planner, designer, reviewer, qa, stories-reviewer) always run on `Model strong`; only the implementer adapts: `Model light` while the story's complexity is at most `Light up to`, `Model strong` above. ADR-0032 records it. Criteria: `settings_declare_the_model_routing`, `implementer_no_longer_pins_a_model`, `deciders_always_run_on_the_strong_model`, `only_the_implementer_adapts`, `drive_reports_the_model_of_each_lane`, `setup_offers_the_defaults`. Notes: complexity read from the research when it exists, else from `docs/stories.md`; a model the Agent tool refuses stops the lane, no silent fallback.

## Current code
- `method/templates/agents-local.md:9-34` — the Pipeline block (last line `Tracker:` at 33); `:36-61` — the values table, one row per setting. No model setting exists.
- `method/agents/implementer.md:5` — `model: opus`. Its body reads no model setting and needs none.
- `method/commands/po-drive.md:14` — Reads settings; `:24` — "One of the settings above missing, `QA stage` excepted → stop and name it"; `:87-95` — dispatching, one numbered item per stage (planner, designer, implementer, qa, reviewer); `:125` — fix run back to `implementer`; `:134-141` — `## Report`, a table "story · stage reached · plan · verdict · shipped" and activity windows per stage.
- `method/commands/po-orchestrator.md:15` — Reads settings; `:54-58` Stage 5 delegates "the way `/po-execute` does"; `:60-63` Stage 6 applies `/po-qa`; `:65-70` Stage 7 delegates to `reviewer` "the way `/po-review` does". It has no generic missing-setting stop; Stage 1 stops on a missing `Story track` (`:34`).
- `method/commands/po-flow.md:15` — Reads settings; `:32` "A missing setting is a stop, never a guess."; `:73` execute via `subagent_type: implementer`; `:75` review via `subagent_type: reviewer`; `:76` fix loops.
- `method/commands/po-execute.md:12` — Reads settings; `:20-27` preconditions (no Bash: reads files only); `:29-42` delegation with `subagent_type: implementer`, prompt, fix-run sentence at `:36`.
- `method/commands/po-review.md:13`, `:21` Preconditions, `:27-30` delegation to `reviewer`.
- `method/commands/po-qa.md:13`, `:21` Preconditions, `:29-32` delegation to `qa`.
- `method/commands/po-stories-review.md:13`, `:17` Checks, `:27-30` delegation to `stories-reviewer`.
- `method/commands/po-setup.md:30-35` — the five numbered questions; `:43` — "Nothing else is asked … every other setting keeps the template's value"; `:48` — the template is copied and answers filled in.

## Attachment points
- Settings: three new lines in the Pipeline block of the template and three rows of its values table.
- Each dispatching command: its `Reads settings:` line, its check section (missing setting → stop), and the sentence that calls the Agent tool, which gains the `model` to pass.
- `/po-execute` delegation is the single place the implementer prompt is fixed; `/po-drive` (`:93`), `/po-orchestrator` (`:55`) and `/po-flow` (`:73`) reuse it, so the complexity rule belongs there and the three others state it and point to it.
- `/po-drive` `## Report`: one more column or line per lane and stage.
- `/po-setup` `:43`: the sentence that lists which settings keep their template value.

## Verified interfaces
- `template_settings` (`tests/lib.sh:32-34`) lists every `Name:` line inside the fenced blocks of the template; `test_every_setting_read_by_a_command_exists_in_template` (`tests/structure.test.sh:24-34`) and `po-lint check_settings` (`bin/po-lint:98-115`) require every `Reads settings:` name to be one of them.
- `test_setup_asks_entry_mode_and_design_source` (`tests/setup-modes.test.sh:31-39`) counts lines matching `^[0-9]+\. ` in Step 2 and requires exactly 5, and requires `Nothing else is asked`.
- Setting lines must match `^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$` (`tests/structure.test.sh:8-13`): `Light up to:       2` passes.
- `frontmatter` helper (`tests/lib.sh:13-15`) prints the frontmatter lines; `contains` is exact (`tests/lib.sh:43`).
- `tests/drive.test.sh:141-145` pins the activity-window sentences of the drive report; `:38` pins "Never two calls for the same story at once".

## Traps
- `tests/execute.test.sh:34` must change with the implementer frontmatter (see the top); it is in `Owns` since `101cf2a`.
- `tests/distribution-wiring.test.sh:134-136` requires H04 of `docs/parite-killer-saas.md:106` to stay `partiel`, name `method/agents/` and say `par story`. s59 adds no per-story override, so H04 stays as it is; the file is outside `Owns` anyway.
- `po-lint` fail-closed: a line such as "`Model light` is `—` → no model" inside a `## Checks` or `## Preconditions` section fails the lint (`tests/adr-directory.test.sh:35-36` runs it). Put the `—` rule outside the gate sections.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write the new clauses from scratch.
- Polype's own `AGENTS.local.md` has no model settings; after ship, every dispatching command stops on it until a human adds them (the story notes say they will, by hand). Not a lane concern, but the ship report must say so.
- `.claude/` and `.polype/` are installed copies: never edited by this story.
- No migration, no dependency, no screen.

## Open questions
- Which exact names the Agent tool's `model` parameter accepts (`opus`, `sonnet`, `haiku` are the expected ones; whether a full model id is accepted) cannot be checked from this repository. The plan names no list: the template says "a name the Agent tool accepts", and a refusal stops the lane.
- Whether H04 of the parity matrix should be reworded now that the implementer is no longer pinned: left for a human, outside this lane's bounds.

## Complexity
Story 3 → 3. Text edits across ten method files and one test file, no script; the risk is consistency (every dispatch site, every `Reads settings:` line, the fail-closed lint) and the Owns gap, not size.

## Split
Not needed at 3.
