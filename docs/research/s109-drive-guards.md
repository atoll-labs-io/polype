# Research — s109-drive-guards

## Structuring facts
- Partly false assumption: criterion `pr_wait_needs_effective_human` reads as if the condition were missing. It is already there, at `method/commands/po-drive.md:65` (s102 added it). The defect is that no test checks it. Removing it leaves 38 of 38 runnable tests green (see `## Diagnostic`). The fix is a test, plus one sentence for the `automatic` case.
- Root cause 1: `method/commands/po-drive.md:87` restates `/po-research`'s worktree steps inline: fetch, start point, `git worktree add`, `.env*`, `Install`. It skips step 2 of `method/commands/po-research.md:34`, which s106 added after this line was written. A story still sitting in an unmerged framing PR therefore gets a lane.
- Root cause 2: `test_pr_wait_does_not_block_the_fleet` (`tests/ship-follows-forge.test.sh:92-104`) checks only where the `OPEN` row sits and the phrase `a human merge — the lane waits`. The row's condition `an effective \`Ship confirmation\` of \`human\`` has no test.
- Root cause 3: `method/AGENTS.md:79` logs *each* lone decision, "an implementation detail" and "an answer given without asking" included. The only writer is `po-drive.md:149`, and its closed list leaves both out. `method/commands/po-orchestrator.md` never mentions a decisions log (grep: no match), yet it approves plans alone (`:56`) and starts fix runs (`:78`).
- Only `po-drive.md`, `po-orchestrator.md` and the new `tests/drive-guards.test.sh` change. Every edit is additive: other tests freeze the existing sentences of both files.

## Diagnostic
Reproduction (defect 2): I copied `method/` and `tests/` into a temp directory outside the worktree, then removed `, and an effective \`Ship confirmation\` of \`human\` (the line, or a collaborative forge as \`/po-ship\` reads it)` from the `OPEN` row with `sed`. `grep -c 'printing \`OPEN\`, and an effective'` printed `0`. I ran `bash run.sh ship-follows-forge.test.sh drive.test.sh resume.test.sh qa-fleet.test.sh escalation-contract.test.sh` and got `38 passed, 1 failed`. The unmodified copy gives the same result. The one failure, `help_and_readme_show_qa`, comes from `README.md` not being copied, so nothing reacts to the removal. Reproduced.

Reproduction (defects 1 and 3): by reading. `po-drive.md:87` has no `git show <start point>:docs/stories.md`. `po-drive.md:149` has neither "implementation detail" nor "answer given without asking". `grep -n decisions method/commands/po-orchestrator.md` prints nothing.

| # | Hypothesis | Observation that would refute it | Verdict |
| --- | --- | --- | --- |
| 1 | The drive lane inherits step 2 because `:87` says "exactly as `/po-research` describes it" | `:87` would only point to `/po-research` and list no steps of its own | discarded: `:87` lists its own steps, and the reader follows that list (review s106 major 1, `docs/reviews/s106-framing-through-pr.md:63-66`) |
| 1b | `:87` predates `po-research.md:34` step 2 and was never updated | `po-research.md` step 2 would predate the `:87` wording | kept: s106 added step 2 and could not edit `po-drive.md` (`docs/reviews/s106-framing-through-pr.md:66`) |
| 2 | Another test, outside `ship-follows-forge`, holds the condition | a test fails once the condition is removed | discarded by the reproduction above |
| 2b | The only test covering the row checks its position and its outcome phrase, not its condition | the test body would quote `effective` | kept: `tests/ship-follows-forge.test.sh:95` greps only `printing \`OPEN\`` plus `a human merge — the lane waits` |
| 3 | The orchestrator logs through `/po-drive` | `po-orchestrator.md` would refer to `po-drive`'s log section | kept as cause: it does not. Under `po-orchestrator.md:35`, the drive's lanes "are not this command's" |

## Story
A fleet lane must check its start point the way `/po-research` does. A merge is awaited as a human merge only under an effective `human`. Every decision taken alone gets logged, the orchestrator's included.
- `lane_checks_its_start_point`: `### Preparing the lanes` adopts step 2 of `/po-research`. A story not yet on `origin/<Target branch>` opens no lane, and the report says it waits for its framing merge.
- `pr_wait_needs_effective_human`: the `OPEN` row requires an effective `human`. A test fails without that condition. Under `automatic`, an open PR resumes at the ship.
- `lone_decisions_are_all_logged`: the drive's log covers every kind of lone decision that `AGENTS.md:79` names. `/po-orchestrator` gains `## The decisions log` with its autonomous plan approval and its fix runs. It writes those rows once the story has shipped or stopped, never before its ship, and lands them by the framing path.

## Current code
- `method/commands/po-drive.md` (166 lines)
  - `## The ready set` `:28-42`: shipped means the subject starts with `<id>:` on `Target branch` (`:31`). The waiting lane takes no `Parallel` slot (`:42`).
  - `## Resuming` `:44-80`: the table at `:49-68`, first match wins (`:47`). `OPEN` + effective human → wait (`:65`). `CLOSED` → human (`:66`). `Ship allowed: yes` → the ship (`:67`).
  - `### Preparing the lanes` `:86-93`: inline worktree steps (`:87`), orphan handling (`:89-91`), ADR numbers (`:93`).
  - `## Ships, one at a time` `:139-146`: "On a resumed ship, `/po-ship` reads the pull request already open for `story/<id>` and never opens a second one" (`:142`).
  - `## The decisions log` `:148-153`: the closed list (`:149`), written after the last ship and landed by `## Landing the framing`, slug `decisions-log` (`:151`).
  - `## Report` `:155-166`: the list of reported items (`:156`) and the `status` reasons (`:164`).
- `method/commands/po-research.md:31-36`
  - Step 1: fetch, then start from `origin/<Target branch>`.
  - Step 2: `git show <start point>:docs/stories.md` holds `## <id>` or `### <id>`. When it does not, the command stops with "<id> is not on <start point> yet: its framing pull request waits for its merge…".
  - Step 3: `git worktree add`.
- `method/commands/po-orchestrator.md` (83 lines)
  - Stages 0 to 8.
  - Stage 2 (`:48`) creates the worktree "as `/po-research` describes", which already includes step 2. That is correct and stays as is.
  - Stage 4 approves plans autonomously (`:56`). Stage 7 starts fix runs (`:78`).
  - Stage 8 ships (`:81`). The finish line is `:83`.
  - It has Write and AskUserQuestion (`:4-11`) and reads `Merge mode`, `Ship confirmation` and `Target branch` (`:15`). That covers everything `## Landing the framing` reads.
- `method/commands/po-setup.md:60-90` (`## Landing the framing`) works from the root and stays on `Target branch`.
  - It stages `<paths>` in the root index (`:74`).
  - Under `pr` + `human`, it stops at "Framing pull request ready" (`:80`).
  - Under `local` + `human`, it asks Merge / Not now (`:87`).
- `method/commands/po-ship.md:81`: a local ship requires the root to have no staged or modified tracked file. That is why a log row is never written before a ship.
- `method/templates/decisions-log.md:6`: header `| Date | Story | Decision | Reason |`.

## Attachment points
- `po-drive.md:87`: insert the start-point check between the start point and `git worktree add`, and define what happens when it fails: the lane is dropped from the wave, no worktree is created, and the report entry says it waits for its framing merge. This mirrors the orphan rule at `:91`.
- `po-drive.md:156`, `## Report`: add "the stories waiting for their framing pull request to merge".
- `po-drive.md`, after the table (`:68`): add one sentence saying that under an effective `automatic` an open pull request matches no waiting row and resumes at the ship, which reuses the open PR (`:142`).
- `po-drive.md:149`: extend the list with each implementation detail settled without the person and each answer given without asking.
- `po-orchestrator.md`: a new `## The decisions log` between Stage 8 and the finish line, which moves below it.
- `tests/drive-guards.test.sh`: new, three `test_<criterion>` functions. It defines its own `section_of` and `holds`, like every test file (`tests/drive.test.sh:8-10`), plus a `###` subsection reader for `Preparing the lanes`.

## Verified interfaces
- `tests/lib.sh`
  - `contains` uses `grep -qF` (`:43`). `fail` ends the test (`:11`). `require_file` (`:41`). `scratch_repo` (`:46`).
  - `tests/run.sh` takes file names relative to `tests/` (`:5-6`).
- `section_of` in test files: `awk -v h="## $2" '$0 == h …'`. It keeps `###` subsections inside their `##` section (`tests/drive.test.sh:7-8`), so `section_of "$DRIVE" 'A wave'` contains `### Preparing the lanes`.
- Phrases frozen elsewhere, which must stay intact:
  - `drive.test.sh:41-42`: "You prepare each lane's worktree yourself" and `git worktree add -b story/<id>` in `A wave`.
  - `resume.test.sh:76`: the orphan no-repair list.
  - `ship-follows-forge.test.sh:95-103`: `printing \`OPEN\``, `a human merge — the lane waits`, `is \`yes\` | the ship`, `printing \`CLOSED\`` with `| a human`, and the row order stale < wait < ship.
  - `escalation-contract.test.sh:90-96`: `templates/decisions-log.md`, `Landing the framing`, `slug \`decisions-log\``, `after the wave's last ship`, and `decisions-log` in `Report`.
  - `pilot.test.sh:11`: counts `^## Stage .* — checkpoint$` headings. The new heading must not end in "— checkpoint".
  - `qa-fleet.test.sh:32-35`: the Stage 5, 6 and 7 headings.
  - `escalation-contract.test.sh:66,73-74`: orchestrator `Stage 4` marker, `at once`, `nothing here pauses them`.

## Traps
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS. Write new prose from scratch.
- `docs/stories.md:1714-1744`: s112 depends on s109 because both own `po-drive.md`. Keep the `## The ready set` shipped rule (`:31`) untouched.
- A test that only greps the word "effective" anywhere would bite on nothing: `effective` appears at `:42` and `:142-144` too. The test must read the `OPEN` row itself.
- Start-point test: grepping `git show <start point>:docs/stories.md` across the whole file would not bite if the phrase lived elsewhere. Read it inside `### Preparing the lanes` and check it sits before `git worktree add -b`, as `tests/framing-through-pr.test.sh:59-69` does for research.
- The drive must not stop the wave on this check, unlike `/po-research`, which stops the command. Only that lane drops.
- Orchestrator on the short track: `/po-flow` approves and fixes inside this run (`po-orchestrator.md:45`). The log section must cover those too, or it narrows `AGENTS.md:79` again.
- No migration, no dependency, no ADR (no structural choice).

## Open questions
- Should `/po-drive status` also report a story whose framing is unmerged? It does not prepare worktrees. The plan leaves `status` (`:164`) unchanged, since the criterion names only `### Preparing the lanes` and the report.
- Should the slot of a lane dropped by the start-point check go to the next ready story within the same wave? The plan copies the orphan rule: the lane is dropped and nothing is pulled in mid-wave.

## Complexity
Story: 3. After reading: 3. The work is three independent text fixes across two command files plus one test file of three functions. There is no code, but the bite tests must read specific rows and sections.

## Split
—
