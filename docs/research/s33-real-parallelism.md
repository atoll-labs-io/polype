# Research — s33-real-parallelism

[Story](../stories.md)

## Structuring facts
- **Wrong assumption, the story's `Corrige` line.** The numbers 22, 23 and 24 each name two different defects: `docs/defauts.md:37-39` (M3 reviews, opened by s32's research, about ADR-0003, ADR-0016 and the missing design subagent) and `docs/defauts.md:45-47` (fleet validation, the three this story fixes). The ids the story cites are ambiguous, and no row can be marked corrected without saying which of the two. The story is corrected by renumbering, not worked around: `docs/defauts.md` is in `Owns`, the fleet-validation rows become 25, 26, 27, and the story's `Corrige` line then reads those.
- Criterion 1 is half there: `method/commands/po-drive.md:71` already says "in a single message" and "one Agent call per lane, all of them in that one message". What is missing is the scope (*every* subagent of one stage), the prohibition (never one call per message), and the reason — the three strings of `tests/drive.test.sh:36-38` are pinned and must survive unchanged.
- Criterion 3 has nothing today: `po-drive.md` never says the driver stays put, and the wave section addresses lanes by the relative `<Worktree root><id>` (`:64`, `:75`). `git -C <path>` appears once (`:66`) and "the absolute worktree path" once (`:74`).
- Criterion 4 collides with a pinned sentence: the planner may write an ADR (`method/agents/planner.md:51`) while `:50` says it writes the research and the plan "and no other file" — and that exact sentence is asserted by `tests/planner.test.sh:46`. The number the planner would choose today is unconstrained; `docs/decisions/` holds ADR-0001 to ADR-0017, so the next free one is 0018.
- Criterion 2 lands in `## Report`, whose body is already pinned by `tests/grouped-validation.test.sh:45-46` and `tests/resume.test.sh:48-57`: the stage-by-stage count is an addition, never a rewrite.

## Story
s33 makes the fleet keep its parallelism promise, closing the three defects the 2026-09-22 sandbox run recorded (`docs/defauts.md:45-47`).
1. `drive_dispatches_a_whole_stage_in_one_message` — the command demands that every subagent of one stage of a wave leaves in **a single message** (several tool calls in it), forbids one call per message, and says why: one call per message runs the lanes one after the other.
2. `drive_reports_what_it_observed_not_what_it_intended` — the wave report states, per stage, how many subagents were launched together; it never claims a parallelism it did not exercise.
3. `drive_uses_absolute_paths_only` — the driver never changes directory: `git -C <absolute path>` and absolute paths handed to subagents; the test fails if the command allows a `cd`.
4. `shared_numbering_is_assigned_by_the_driver` — ADR numbers are assigned by the driver before a wave is launched, one per lane that needs one, and the planner never picks a number itself.

## Current code
- `method/commands/po-drive.md` (121 lines) — `## Checks` `:20`, `## The ready set` `:27`, `## Resuming` `:39`, `## A wave` `:61` (with `### Preparing the lanes` `:63` and `### Dispatching` `:70`), `## Validating a wave's plans` `:83`, `## The verdict, and the fix runs` `:100`, `## Ships, one at a time` `:107`, `## Report` `:114`. No Write, no Edit (`:4-11`); Bash prepares worktrees and records answers (`:18`).
- `method/agents/planner.md` (55 lines) — `tools: Read, Write, Bash, Grep, Glob` (`:4`); `## Checks` `:16` already tells it its shell forgets its directory and bans `git worktree add|switch|checkout|stash` (`:17`, `:24`); `## Limits` `:49-52` holds the "no other file" sentence and the ADR permission.
- `tests/drive.test.sh` (147 lines) — six tests. `section_of` (`:8`) extracts one `## ` section, `holds` (`:10`) is an exact `grep -F` on that body. `test_drive_dispatches_lanes_in_one_message` (`:31`) is where criteria 1 and 3 belong; `:45-47` asserts the dispatch order `planner implementer reviewer` by scanning `subagent_type:` occurrences of the whole `## A wave` section.
- `docs/defauts.md` (47 lines) — three tables, one heading per campaign (`:5`, `:23`, `:41`), columns `# · Source · Défaut · Statut`.

## Attachment points
- Criterion 1 → `### Dispatching`, `method/commands/po-drive.md:70-72`, extending the existing paragraph.
- Criterion 2 → `## Report`, `method/commands/po-drive.md:114-121`, a sentence added to the report's contents.
- Criterion 3 → `### Preparing the lanes` / `### Dispatching`: one rule stating the driver resolves `<repository root>/<Worktree root><id>` once and never runs `cd`.
- Criterion 4 → `### Preparing the lanes` (the driver allocates before dispatching) and `method/agents/planner.md:49-52` (the planner takes the number it was handed, or reports it needs one).
- The four criteria → four new `test_<criterion name>` functions in `tests/drive.test.sh`; the acceptance criterion's name is the test function's name (AGENTS.local.md, Conventions).

## Verified interfaces
- `tests/lib.sh:5-6` — `ROOT` is the repository, `METHOD="$ROOT/method"`. The suite reads `method/`, never the installed `.claude/` or `.polype/` copies; `git show --stat 040ed47` confirms s32 committed nothing under `.claude/`.
- `tests/lib.sh:41-43` — `require_file`, `contains` (exact `grep -qF`). `lacks_tool`/`needs_tool` (`:27-29`) read the frontmatter. `settings_read_by` (`:37`) parses the `Reads settings:` line.
- `tests/drive.test.sh:8` — `section_of` stops at the next `^## `, so `### Preparing the lanes` and `### Dispatching` are both inside the `## A wave` body: a rule written in either is visible to the wave-section assertions.
- `method/commands/po-research.md:29` — the worktree path the fleet reuses is `<repository root>/<Worktree root><id>`; that is what "absolute" resolves to.
- `docs/decisions/` — ADR-0001 … ADR-0017, four digits, `ADR-NNNN-<slug>.md`. `method/AGENTS.md` writes the same shape as `docs/decisions/NNNN-<slug>.md`; the files on disk carry the `ADR-` prefix.

## Traps
- **Three pinned strings in the dispatch paragraph** (`tests/drive.test.sh:36-38`): `in a single message`, `one Agent call per lane, all of them in that one message`, `Never two calls for the same story at once`. Rewriting that paragraph instead of extending it turns four green tests red.
- **`tests/drive.test.sh:130`** pins ``` `/po-design <id>` to run in `<Worktree root><id>` ``` and `:143` pins a Resuming row using the same relative form. The absolute-path rule must be stated once, as a rule, without converting those pinned mentions.
- **A ban on `cd` contains the word `cd`.** A test grepping for `cd ` in `po-drive.md` would match the prohibition itself; the assertion has to distinguish the rule from a permission (for instance: every `cd` occurrence of the file sits on a line that forbids it).
- **`tests/planner.test.sh:46`** pins `You write \`docs/research/<id>.md\` and \`docs/plans/<id>.md\`, and no other file.` — the ADR rule is added around it, that sentence stays verbatim.
- **`tests/drive.test.sh:45-47`** rebuilds the dispatch order from every `subagent_type:` string in `## A wave`: a new sentence naming a subagent type in that section breaks the equality check.
- **`## Report` is pinned twice** (`tests/grouped-validation.test.sh:45-46`, `tests/resume.test.sh:48-57`): add, never reword.
- `bin/po-lint` checks the `Reads settings:` declarations against `method/templates/agents-local.md`; this story introduces no setting, so nothing to declare.
- `tests/overlap.test.sh` fails on 8+ consecutive words shared with Killer SaaS: the new sentences are written from the criteria, not from any source.
- No migration, no dependency, no screen. The whole story is method text and its tests.

## Open questions
- **The allocation policy is a design choice the plan must settle and cannot record as an ADR.** The driver cannot know, before dispatching, which lanes will need an ADR — the planner discovers it while planning. Reserving one number per lane of the wave leaves gaps when a lane needs none; asking the planner to report the need and allocating afterwards keeps the numbering dense but makes the planner wait. `docs/decisions/` is **not** in this story's `Owns`, and `docs/defauts.md:31` records a past review finding for exactly that overstep, so the reasoning belongs in the plan's pivot section and an ADR is a human's call.
- **`AGENTS.local.md` of this repository declares no `Parallel`, `Max attempts` or `Tracker`** (they exist only in `method/templates/agents-local.md:29-31`), so `/po-drive` run here stops on a missing setting (`method/commands/po-drive.md:24`). Out of `Owns`; worth a new defect row rather than a fix in this story.
- Whether the renumbering of `docs/defauts.md` should also correct the story's `Corrige` line in `docs/stories.md`: that file lives on `Target branch` and is not in `Owns`.

## Complexity
Story: 3 → after reading the code: 3. Four documents, no code path, but the edits are surgical: five pinned test strings run through the two sections being changed, and one criterion needs a test assertion that does not trip over its own subject.

## Split
Not applicable (score 3).
