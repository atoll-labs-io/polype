# Research — s89-po-retro

## Structuring facts
- **Partly false assumption: "un jalon" is not a concept of the method.** `method/` never says milestone or jalon (grep on `method/`, no hit); `templates/stories.md:7` puts each story at `## <id> — <title>`, with no grouping above it. Only Polype's own `docs/stories.md` groups stories under `## M8 — …` with stories at `###` (`docs/stories.md:1191,1350`). The command has to define what a milestone is itself (ADR-0067); the story needs no rewrite, only that definition.
- Review files stack several reviews: `docs/reviews/s78-platform-setting.md` holds three (`Ship allowed:` at :84, :193, :289), `s75-post-m7-texts.md` two (one `blocked` at :7, then `complete` at :56). A retro that reads only the last verdict, as `po-gate` does (`method/hooks/po-gate.sh:53`), loses every blocked review and every fix loop.
- Real reviews do not keep the template's line shapes: `s78` writes `- Reviewed tree:` / `- Fix loop: 0` as list items (:8-9) and findings as `1. **major — …**` (:63). Reading has to tolerate list markers and emphasis, and report a line it cannot rate instead of guessing.
- No record closes a major. `AGENTS.md:70` sends majors "to a later cycle"; the fix run closes every finding of the review it answers (`method/agents/implementer.md:30`). So the only majors still open by the files are those of a story's **last** review.
- `/po-help` is checked by `tests/pilot.test.sh:38-46` (`test_every_command_listed_in_help`): adding `po-retro.md` without its help line turns that test red. Both land together.

## Story
`/po-retro` summarises a milestone or a range of stories from what the cycle recorded, to show where the cycle costs, with no invented metric.
- `retro_reads_only_recorded_facts` — reads `docs/stories.md`, `docs/reviews/*`, `docs/verif/*`, `docs/qa/*` for a milestone or a story range; reports severities per story, fix loops, blocked reviews and their cause, blocked QA, majors still open; counts neither lines nor commits.
- `retro_writes_nothing` — no Write, no Edit; its output says where each figure comes from.
- `help_lists_the_retro` — `/po-help` presents `/po-retro`.

## Current code
- No `method/commands/po-retro.md`. The nearest sibling is `method/commands/po-status.md` (42 lines): read-only, frontmatter `Read, Glob, Grep, Bash` (:3-7), body "Bash is used read-only: no commit, checkout, merge or file change" (`test_status_derives_from_files`, `tests/pilot.test.sh:22-27`), reads each story "from its worktree `<Worktree root><id>` while it exists and from `Target branch` afterwards" (step 3).
- `method/commands/po-help.md` (French, `disable-model-invocation: true`): section `## Outils` at :35-40 lists orchestrator, drive, drive status, status, flow.
- The rationale for the retro sits in `docs/references/gstack-agent-skills.md:52` ("aucune valeur inventée, pas de métriques de vanité"); `docs/reviews/stories-m8.md:74,174` added `docs/qa/*` to its sources.

## Attachment points
- New file `method/commands/po-retro.md`; installed by directory copy (`bin/polype:86,100` pair `method/commands`), no registry to update.
- One line in `method/commands/po-help.md` `## Outils`, after `/po-status` (:39).
- New `tests/po-retro.test.sh`, picked up by `tests/run.sh` glob `*.test.sh`.

## Verified interfaces
Lines the retro reads, as the cycle writes them:

| Source | Line | Written by |
| --- | --- | --- |
| review | `Review status: <complete \| blocked>`, `Fix loop: <n>` | `templates/review.md:5-6`; `/po-review` computes loop = previous + 1 (`method/commands/po-review.md:26`) |
| review | `Failure cause:`, `Missing:`, `Required adaptation:`, `Next action:` | `templates/review.md:9-13`, `method/agents/reviewer.md:40-47` |
| review | `## Findings`, one per line `severity — file:line — problem` | `templates/review.md:52-53` |
| review | last two lines `Max severity:` / `Ship allowed:` | `method/agents/reviewer.md:53-56` |
| QA | `### Finding <N>` + `Severity:`, `## Not seen`, `Tree:`, `QA status: <complete \| blocked>` | `templates/qa.md:17-31` |
| QA | blocked cause: free text "naming … as its cause", no field | `method/agents/qa.md:43,48,51` |
| record | `## Runs` table `Check \| Command \| Exit \| Tree \| Time (UTC)`, one row per `po-run` launch | `templates/verification-record.md:24-28` |
| record | `Verification status:` | `templates/verification-record.md:22` |

- `Fix loop:` is how `/po-drive` counts attempts (`method/commands/po-drive.md:72`) — same reading for the retro.
- Settings it needs exist in `templates/agents-local.md`: `Target branch`, `Worktree root` (both read by po-status :11).

## Traps
- **Lint fail-closed** (`bin/po-lint:164-183`): inside a `## Checks…` section, an arrow whose left side names an absence must say stop / ask / carry on / never blocks on its right. Per-story absences (no review, no record) go in a later section.
- **Lint tools** (`bin/po-lint:142-149`): a frontmatter saying "cannot edit files or run a shell" while declaring Bash is a breach — do not use that phrase if Bash stays.
- `tests/structure.test.sh:26-35`: the body needs a `Reads settings:` line with names from the template.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS (ADR-0006); write in own words.
- 47 records under `docs/verif/` predate `po-run` and have no `## Runs` section (count on `main`): "no recorded run", never zero runs.
- Every `docs/reviews/s*.md` holds a `Fix loop:` line; `docs/reviews/stories-m6.md` and `stories-m8.md` do not and are not story reviews. The retro reads `docs/reviews/<id>.md` for ids in scope only.
- `docs/qa/` does not exist on `main` here: "no QA report" must be reported as absent, never as zero blocked.
- `docs/parite-killer-saas.md` has no retro line (grep): nothing to update.
- `method/AGENTS.md` Law 1 lists commands but is outside `Owns`; `README.md` too. Neither gets the command; `/po-help` is the only listing in scope.
- `.claude/commands/` is an installed copy: untouched.

## Open questions
- Read from the worktree while it exists, or only from `Target branch`? → plan: same rule as `/po-status` step 3, so an in-flight story shows its current evidence.
- Should `Max attempts` flag stories at the limit? Not asked by the story; left out to keep the settings read minimal.
- Range syntax: `<first id>..<last id>` in file order of `docs/stories.md` — the plan fixes it.

## Complexity
Story: 3 → after reading: **2**. One new prose command, one help line, textual tests in the house style. The real difficulty is definitional (milestone, open major, stacked reviews, tolerant line reading), settled in ADR-0067, not in code.

## Split
— (not at 5)
