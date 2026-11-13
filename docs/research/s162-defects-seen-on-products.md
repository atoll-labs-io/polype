# Research — s162-defects-seen-on-products

[Story](../stories.md)

## Structuring facts
- **False assumption (criterion 3)**: the designer cannot load `~/.claude/skills/<name>/SKILL.md` today. It reads the skill only from `.claude/skills/<Design skill>/SKILL.md` *in the worktree* (`method/agents/designer.md:37`) and stops when no `SKILL.md` is at that path (`method/agents/designer.md:39`). If `/po-setup` accepted a user-level skill without changing the designer, #87 would come back. `designer.md` is in `Owns`, so the plan fixes this with a task. It does not work around it.
- **Root cause #184**: `method/agents/designer.md:20` allows only `docs/research/<id>.md`, `docs/plans/<id>.md` and `docs/designs/<id>/` as uncommitted changes. The fleet sends the designer *after* the plan (`method/commands/po-drive.md:55`, `:110`), and by then the planner has written the oracle files uncommitted (`method/commands/po-plan.md:41`). The planner (`method/agents/planner.md:22`), the implementer (`method/agents/implementer.md:24`) and Law 4 (`method/AGENTS.md:105`) already list those files. The designer is the only stage that does not.
- **Root cause #166**: none of `method/templates/stories.md:13` (`Owns` placeholder), `method/skills/agentic-stories/SKILL.md:21` or `method/skills/stories-review/SKILL.md:25` (check 8) mentions an oracle (`grep -ci oracle` = 0 in all three, and in `stories-reviewer.md` and `po-stories.md`). A missing oracle path therefore first shows up when the planner refuses to write it (`po-plan.md:41`).
- **Root cause #87**: `method/commands/po-setup.md:46` asks for `Design skill` and writes the answer without checking that it exists (`grep -c 'SKILL.md\|skills/' po-setup.md` = 0). Nothing checks the skill until the designer stops at `designer.md:39`.
- **Oracle gate (M20 rule)**: `po-gate oracle-intact` reads only the table whose first header is `Oracle file` (`method/hooks/po-gate.sh:608`). It never reads the `Criterion | Test` table. No script under `method/hooks/` or `bin/` reads `Criterion`. A criterion with no test is therefore admitted, and the lane carries on.

## Story
Three avoidable stops seen on products. #184 on lagon: the designer stopped on the oracle files the planner had written. #166: the `Owns` of a story does not list its oracle file. #87 on lophelia: `/po-setup` wrote a `Design skill` that was not installed.
- `designer_accepts_the_oracle_files`: the designer's status check accepts the uncommitted files that `## Acceptance tests` of the plan lists, and only those. Any other file outside `docs/` still stops it.
- `owns_lists_the_oracle`: the template and `agentic-stories` say that `Owns` lists the oracle file. `stories-review` makes a missing one a **major** finding, inside check 8 and not in a new check.
- `setup_refuses_a_missing_design_skill`: `/po-setup` writes `Design skill: <name>` only if `.claude/skills/<name>/SKILL.md` or `~/.claude/skills/<name>/SKILL.md` exists. A plugin skill is accepted only if research shows the designer loads it. Otherwise setup says so, offers `—` and does not write the name.
- `no_file_grows`: no touched `method/` file has more words after the story than before.

## Diagnostic
**Reproduction** (on the code as it stands, no file created beyond the planner's own):
- #184: once the oracle `tests/defects-seen-on-products.oracle.test.sh` was written, `git status --porcelain` in this worktree printed `?? tests/defects-seen-on-products.oracle.test.sh`. That path is not among the three that `designer.md:20` accepts, so a designer sent here would stop. This is the lagon case: the same kind of path, outside `docs/`.
- #166: `grep -ci oracle` on the five framing files gives 0 (see above).
- #87: `ls .claude/skills/frontend-design ~/.claude/skills/frontend-design` → neither exists on this machine. `po-setup.md` has no step that would look for them.

**Hypotheses**
| # | Hypothesis | Observation that would refute it | Result |
| --- | --- | --- | --- |
| H1 | #184: the driver sent the designer before the plan existed, so no plan named the files | design is dispatched only after `po-gate plan-validated` passes (`po-drive.md:55`); "A lane designs after it has planned" (`po-drive.md:110`); the issue says "after its plan was validated" | discarded |
| H2 | #184: the designer's allow-list omits the oracle files | an oracle mention in `designer.md` → `grep -ci oracle` = 0; the three other agents and Law 4 do list them | kept |
| H3 | #166: the oracle rule lives only in plan-side files, never where stories are written or reviewed | an oracle mention in the template, `agentic-stories`, `stories-review`, `stories-reviewer` or `po-stories` → 0 in each | kept |
| H4 | #87: setup writes the name without checking it, and the designer resolves only one path | a check in `po-setup.md` → none; the designer resolving a second place → only `designer.md:37` | kept |

## Current code
- `method/agents/designer.md` (967 words): checks `:18-23`; status allow-list `:20`; skill resolution `:36-39`. `tests/fleet-design.test.sh:40` freezes '`.claude/skills/<Design skill>/SKILL.md`', and `You never draw from taste` is frozen by `fleet-design.test.sh`.
- `method/templates/stories.md` (315 words): the `Owns` placeholder `:13` restates the syntax and the overlap rule.
- `method/skills/agentic-stories/SKILL.md` (1119): `## Owns and contracts first` `:20-21`. `tests/stories.test.sh:33-34,79-80` freeze `Every story declares Owns:` and the entry syntax.
- `method/skills/stories-review/SKILL.md` (1248): check 8 `:25`, the decision table `:27-35`, severity `:52-55`. `owns-overlap.test.sh:9` and `stories-review.test.sh:34` freeze the overlap rule and the critical sentence.
- `method/agents/stories-reviewer.md` (451): defers every check to the skill (`:14`). No change is needed. It is in `Owns` and may end with an empty diff.
- `method/commands/po-setup.md` (2278): the design follow-up `:46` and the `—` rule `:54` (`Setup never fills it` frozen by `setup-modes.test.sh`; `Only the source is asked here` and the `:46` sentence frozen by `design-handoff.test.sh:47`). Its tools include `Bash` and `Glob` (`:3-10`), so it can test a path.

## Attachment points
- `designer.md:20`: add the oracle files, using the planner's wording from `planner.md:22`: "the oracle files that `## Acceptance tests` of the plan names".
- `designer.md:37,39`: a second path, `~/.claude/skills/<Design skill>/SKILL.md`, tried after the worktree's.
- `stories.md:13`, `agentic-stories:21`: one clause saying `Owns` lists the story's oracle file(s).
- `stories-review:25` (check 8) plus the major list `:54`: a missing oracle path is major.
- `po-setup.md:46`: after the `Design skill` answer, test both paths. Neither exists → say so, offer `—`, write `—`.

## Verified interfaces
- The designer's tools: no `tools:` line, `disallowedTools: AskUserQuestion, NotebookEdit` (`designer.md:4`). It has Read and Bash, so it can read under `~`.
- The designer loads its project skill **only by reading a file path** (`designer.md:37`: "which you read yourself from …"). Nothing in it calls a plugin skill. **A plugin-only skill is therefore not loaded by the designer**, and setup must refuse it, as the story asks when research does not show otherwise (`docs/decisions-log.md:194`).
- `/po-design` (`method/commands/po-design.md:46`) names no path. It is outside `Owns` and is not changed.
- The oracle table syntax that `po-gate` reads: `| Oracle file | cksum |` (`po-gate.sh:570-591`).

## Traps
- **Word budget**: each owned `method/` file must end at or below its count (designer 967, template 315, agentic-stories 1119, stories-review 1248, stories-reviewer 451, po-setup 2278, `LC_ALL=C wc -w`). Every addition is paid for by a cut in the same file. Cuts must avoid frozen phrases: check them with `grep -lF '<phrase>' tests/*.sh`. Unfrozen candidates checked: `designer.md:13` "Apply it; it is not restated here."; `designer.md:37` "your `skills:` list was fixed when the method was written, while `Design skill` belongs to the project"; `stories.md:13` "stories whose entries overlap … never run at the same time" (restates check 8); `agentic-stories:21` "Agents run stories side by side,"; `po-setup.md:46` "the other one stays `—`".
- Tests reading these files: `fleet-design`, `designer-browser`, `drive`, `qa`, `model-routing`, `adr-directory`, `stories`, `stories-review`, `owns-overlap`, `setup-modes`, `design-handoff`, `structure`, `commands-and-texts`, `platform-setting`, `post-m7-texts`, `intake-issue-becomes-a-story.oracle`, `wiring`, `framing-commands-cleanup` (non-exhaustive: `grep -l` the file name before editing).
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS (ADR-0006).
- `.claude/` and `.polype/` are installed copies and are never edited. `AGENTS.md` is regenerated after the ship.
- No migration. Other M20 lanes (s161 `method/AGENTS.md`, s163 QA files) own disjoint paths.
- `po-stories.md:47` (outside `Owns`) has a checklist line on `Owns`. It is left unchanged, since it reads the template and the skill.

## Open questions
- "listed under `## Acceptance tests` with their checksum": should the designer *recompute* each sum? Recomputing costs words in a file that must not grow, and `po-gate oracle-intact` already checks the sums at review (`review-antihallu/SKILL.md:41`). The plan decides: no recompute. "With their checksum" is read as the table row that names the file.
- How should stories-review know an oracle path? Its location is project-specific (Polype: `tests/<slug>.oracle.test.sh`; lagon used `site/tests/*.test.ts`). The plan decides: the reviewer flags a story with acceptance criteria where no `Owns` entry could hold a test file (an entry or folder covering it), and does not demand a name pattern.

## Complexity
Story 2 → 2. Six prose files, no script, one oracle test. The work is in the word budget, not in logic.

## Split
—
