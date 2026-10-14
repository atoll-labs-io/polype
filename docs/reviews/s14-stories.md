# Review — s14-stories

[Story](../stories.md) · [Plan](../plans/s14-stories.md) · [Verification](../verif/s14-stories.md)

Review status: complete
Fix loop: 0
Scope: `git diff m2-cadrage...story/s14-stories`, commit 03f60a3. It adds 3 files (`method/commands/po-stories.md`, `method/skills/agentic-stories/SKILL.md`, `tests/stories.test.sh`), one line in `method/commands/po-help.md`, the C05 line in `docs/parite-killer-saas.md`, and the research, plan and verification files under `docs/`.

## 1. Evidence reused
- I ran `po-gate verif-current s14-stories`: exit 0. I also compared the recorded tree `4d127d7…` with HEAD outside `docs/`: they are identical. The record is marked complete and every exit code is 0.
- With `Verification mode: record`, I relied on it without rerunning: focused run 5/5 passed, unit suite `bash tests/run.sh` 96 passed, overlap check run with the Killer SaaS sources present.
- The project has no `Typecheck`, `E2E` or `Build` command (`—` in AGENTS.local.md). No type check, E2E or build was run.
- I read the record's "Not proven here" section. It says the command was never run for real, which I cover below.

## 2. References opened
- `templates/stories.md`: its complexity scale, Owns, Depends on and notes match what the skill says.
- `templates/prd.md`: holds `status: draft|approved` and the sections Core loop, Graveyard, Angle.
- `templates/brief.md`: holds `status: interviewing|approved` and the sections Wedge & non-goals, Premises.
- `Entry mode` values in `method/templates/agents-local.md:23,46`: `replace`, `adapt`, `new`, `—`.
- `settings_read_by`, `contains` and `require_file` exist in `tests/lib.sh`. `section_of` is copied from `tests/brief.test.sh`.
- The pattern "Read the X skill" in a command matches `po-brief.md:26`. The skill is installed recursively.
- `AskUserQuestion` and the commit or env-file check are the same as in `po-prd.md`.
- All exist; nothing is invented.

## 3. Diff against the plan
- Tasks 1 to 6 are all present and match the plan, including the exact sentences it asked for.
- Run interdicts: the diff is empty for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/lib.sh`, `method/templates/`, `method/AGENTS.md` and `docs/stories.md`. The new files do not mention `docs/references/`, `~/dev/vault` or `/spec`.
- Two edits fall outside the story's Owns, and both are justified:
  - `po-help.md`: `pilot.test.sh:38` requires every command to be listed there.
  - The parity matrix line: the project conventions require it.
- No unrequested change.

## 4. Test bite
There are 5 tests against a budget of 25. Each mutation was followed by `bash tests/run.sh stories.test.sh`, then `git restore` and `git diff --exit-code` (restoration confirmed after each; working tree clean at the end).

| Mutation | Tests failed |
| --- | --- |
| po-stories: drop the `status: approved` requirement on the PRD source | **0** |
| po-stories: drop the `status: approved` requirement on the brief source | **0** |
| skill: delete the paragraph that limits the contract-story exception (observable, at least two dependants) | **0** |
| skill: delete the Bad/Good example pair | 1 |
| skill: turn "Nothing from the graveyard becomes a story" into its opposite | 1 |
| po-stories Before writing: delete the vertical-slice, Owns and contract checks | **0** |
| po-stories: replace "append, never renumber" with "renumber from s1" | **0** |

## Findings

**F1 — major — The approval requirement of criterion 1 is not tested.** In `tests/stories.test.sh`, `test_stories_reads_prd_or_brief_by_entry_mode` checks `contains "$STORIES" 'status: approved'`. That phrase appears on both the PRD line and the brief line, so either line alone satisfies it. Removing the approval requirement from either source fails no test. The criterion asks for exactly this on the brief ("`new`, approuvé"). The fix is to check each clause as a whole: "the source is `docs/brief.md`. Missing, or its frontmatter does not say `status: approved`", and the same for the PRD. The command itself is correct; only the test is weak.

**F2 — minor — The limit on the contract-story exception is not tested.** In the skill's `## Owns and contracts first`, deleting the paragraph "This is the only story allowed to face no end user, and only under two conditions…" fails no test. Without it, "create the table" can come back as a "contract" story. The plan's own pivot (a) names this risk. It goes beyond the letter of criterion 3, hence minor.

**F3 — minor — The command's own checklist is only partly tested.** The Owns, contract and vertical-slice checks in `## Before writing` of `po-stories.md` can be deleted without any test failing. Tests do check the equivalent rules in the skill, and they check the complexity, dependency-order and graveyard lines of the checklist.

**F4 — minor — Appending can duplicate stories, and the append rule is untested.** `po-stories.md` Sequence step 6 appends new stories to an existing `docs/stories.md` and never renumbers. Nothing tells the agent to leave out parts of the source that existing stories already cover, so running the command again on the same approved PRD would append duplicates. The user's agreement at step 4 is the only safeguard. The "never renumber" rule is also untested (0 failures when mutated). It was a plan decision, not a criterion.

**F5 — minor — Nothing checks that `Entry mode` and the PRD's `mode:` agree.** `po-stories` picks its source from `Entry mode` but never compares it with the `mode:` in the PRD frontmatter. If the two diverge, the check that only applies in `replace`/`adapt` mode could be applied wrongly.

**F6 — minor — Other files still point users away from the new command.** These files were deliberately left untouched because of Owns:
- `po-prd.md:55`, `po-brief.md:50` and `po-setup.md:46` still say "write the stories in docs/stories.md" and do not name `/po-stories`.
- `method/AGENTS.md` Law 1 does not list `/po-stories` among the setup-time commands.

A later story should fix these.

## Values checked
- `status: approved`, `draft` and `interviewing` match the templates.
- The `Entry mode` values match.
- The commit title `docs: stories for <product>` follows `docs: PRD for <target>`.
- The complexity rules "A 4 names its main risk" and "A 5 is split before anyone plans it" match `templates/stories.md`.
- "About ten plan tasks" and "past seven criteria" come from the C05 description ("≤ ~10 tâches") and from the skill itself. Nothing else confirms them; the seven is the skill's own number.

## What I did not verify
- **No real run of `/po-stories`.** I did not draft stories from a real approved PRD or brief, did not go through the user-agreement steps, and did not run the commit on `Target branch` or the env-file check. Tests only check that sentences exist. *To cover it:* in a scratch repository, set `Entry mode: replace` and add an approved `docs/prd.md` with a graveyard; run `/po-stories`; confirm that it refuses a draft PRD, keeps graveyard items out, produces vertical slices plus contract stories in the right order, and commits only `docs/stories.md`. Then run it again on an existing `docs/stories.md` to see whether it appends duplicates (F4).
- **No real run in `new` mode or with `Entry mode: —`.** *To cover it:* run the same scratch test with each value.
- **No check that the prose is original.** I did not compare the skill's text with the Killer SaaS `agentic-stories` source myself. I relied on the recorded green `overlap.test.sh`, which only catches 8+ word overlaps, not close paraphrase. *To cover it:* have someone read the skill next to the French C05 description.
- **The installed copies were not refreshed.** `.claude/` and `.polype/` do not yet hold the new command and skill, as expected. *To cover it:* rerun `bin/polype-dev-install .` after ship; the recorded install test covers the copy mechanism.

## Verdict
Nothing is critical. Every reference exists, the plan was followed, the interdicts hold and the recorded suite is green on this exact tree. F1 is a real gap in test coverage on an acceptance criterion and should be handled in a later cycle.

Max severity: major
Ship allowed: yes
