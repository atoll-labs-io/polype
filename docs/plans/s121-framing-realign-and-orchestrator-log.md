---
validated: yes
---
# Plan — s121-framing-realign-and-orchestrator-log

Branch `story/s121-framing-realign-and-orchestrator-log`. Read `docs/research/s121-framing-realign-and-orchestrator-log.md` first. This plan builds on it without repeating it.

## Story
This story fixes s110's major and s109's two minors.
- `every_landing_realigns_the_root` — in `## Landing the framing`, every `pr` landing realigns the root right after the `git fetch`, whatever its slug:
  - it runs `git merge --ff-only origin/<Target branch>` in the root;
  - a refusal is reported, and nothing is forced;
  - the `human` bullet promises only what the command does.
- `orchestrator_logs_every_lone_decision` — `## The decisions log` of `/po-orchestrator`:
  - also logs the track it chose, each implementation detail it settled, and each answer it gave without asking;
  - when the run ends on "Pull request ready", writes its rows then;
  - under `local`, says that a "Not now" leaves the log staged in the root.

## Reuse
This plan writes no new code: the edits are method prose and bash tests. The test helpers are copied from `tests/framing-second-landing.test.sh:6-15` and `tests/drive-guards.test.sh:7-12`, as each test file in this repository defines its own.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `section_of`, `holds`, `base_block`, `offset` in the new test | already in this repository (`tests/framing-second-landing.test.sh:6-15`) | — (first rung holds; `tests/lib.sh` has no shared section helper, and each test file defines its own) |

## Tasks
1. [x] **Realign the root first, in `**Base.**`** — `method/commands/po-setup.md:65-73`.
   - **Rewrite the `pr` bullet at `:66`** so that it runs, in this order:
     1. `git fetch origin`.
     2. `origin/<Target branch>` missing → stop: a person pushes `Target branch` to the remote once, since no agent pushes it. This moves the stop of `:72` here and removes the old line at `:72`.
     3. In the root, `git merge --ff-only origin/<Target branch>`, whatever the slug, and before anything else is decided. A root already at or ahead of that ref is left as is. A refusal is reported and the landing carries on: no stash, checkout or reset forces it.
     4. The existing clause: no `origin/framing/<slug>` → `<base>` is `origin/<Target branch>`.
   - **Keep without change:** the proof bullet `:67-69`, the `Not merged →` bullet `:70`, and the `local` bullet `:73`.
   - **Shorten the `Merged →` bullet at `:71`.** It drops its own `--ff-only` and its refusal clause, since step 3 already realigned the root. What stays: `git push origin --delete framing/<slug>`, `<base>` is `origin/<Target branch>`, and "A merged branch is never taken as a base". Keep the capitalised `Merged →`.
   - **Wording:** write no line that matches "commit … on `Target branch`" (`tests/framing-through-pr.test.sh:41`). Every `git push` line names `framing/<slug>`.
   - **Tests that would fail:** `test_every_landing_realigns_the_root` (task 4), plus the existing `framing_second_landing` and `framing_through_pr` tests.
2. [x] **Make the `human` bullet honest** — `po-setup.md:85`.
   - Keep the quoted message `"Framing pull request ready: <url>. Land it with Rebase and merge; …"` byte for byte.
   - Replace the sentence after it, in our own words. It must say three things:
     - once a person merges, the next landing of any framing command fast-forwards the root, as **Base** says;
     - the merged `framing/<slug>` is deleted only by the next landing on that same slug;
     - until then, it stays on the remote.
   - **Test that would fail:** `test_every_landing_realigns_the_root`. It asserts the new sentence and the absence of the old one.
3. [x] **Complete the orchestrator's log** — `method/commands/po-orchestrator.md:83-90`.
   - **`:84`, the kinds of row.** Add, after the plan approvals and fix runs:
     - the track chosen at Stage 1, with the setting and complexity that chose it, including a `/po-flow` escalation back to the full track;
     - each implementation detail it settled without the person;
     - each answer it gave without asking.

     Use the drive's phrasing where it fits (`po-drive.md:153`). Keep `Plan validation: autonomous`, `each fix run it started` and `` `/po-flow` ``.
   - **`:88`, the timing.** Keep "once the story has shipped or the run stopped, never before its ship" and its reason. Then add: a run whose ship ends on "Pull request ready: <url>." writes its rows at that moment, because a `pr` ship never inspects the root (`po-ship.md:73-77`, against `:81` in local mode).
   - **`:88`, after the landing sentence.** Add the caveat of `po-drive.md:155`, reworded for one run: under `Merge mode: local` with an effective `human`, a "Not now" on the log's landing leaves `docs/decisions-log.md` staged in the root, and the next local ship stops on it until the log is landed.
   - **Unchanged:** `:86`, `:90`, `:92`. Add no heading: `tests/pilot.test.sh:11` counts the checkpoints.
   - **Tests that would fail:** `test_orchestrator_logs_every_lone_decision` (task 4) and `drive-guards.test.sh` `lone_decisions_are_all_logged`.
4. [x] **Write `tests/framing-realign-and-orchestrator-log.test.sh`**, with two tests named after the criteria.
   - **`test_every_landing_realigns_the_root`:**
     - **in `base_block`, these offsets increase in this order:**
       - `git fetch origin`;
       - `git merge --ff-only origin/<Target branch>`;
       - `` No `origin/framing/<slug>` ``;
       - `Not merged →`.

       The realignment then sits before any slug-specific decision, so moving it back under `Merged →` fails;
     - `base_block` holds `A refusal is reported` and `no stash, checkout or reset forces it`;
     - the line holding `git merge --ff-only origin/<Target branch>` in `base_block` does not hold `framing/<slug>`;
     - the landing section holds the new `human` sentence: its "same slug" clause, as an exact phrase chosen in task 2;
     - it lacks `the next landing of any framing command realigns the root as **Base** says`.
   - **`test_orchestrator_logs_every_lone_decision`:** the `## The decisions log` section of `po-orchestrator.md` holds:
     - the track phrase, with `Stage 1`;
     - an implementation-detail phrase;
     - an answer-without-asking phrase;
     - `Pull request ready: <url>.`;
     - `` `Merge mode: local` `` together with `"Not now"` and `` staged in the root ``.

     Quote the exact phrases tasks 2 and 3 write.
5. [x] **Adjust the two owned tests whose clause changed.**
   - **`tests/framing-second-landing.test.sh:56`:** drop the assertion on the old sentence. The new test owns the `human` sentence; keeping both would test one rule twice. Nothing else in that file changes. `:48` still finds `git merge --ff-only origin/<Target branch>`, `A refusal is reported` and the deletion in `base_block`.
   - **`tests/drive-guards.test.sh`:** no change is expected, since `never before its ship` survives task 3. Touch it only if the final wording forces it, and say so in the record.
6. [x] **Run the full suite once**: `po-run --story s121-framing-realign-and-orchestrator-log --label 'Unit suite' -- 'bash tests/run.sh'`. It includes `overlap.test.sh`, `framing-through-pr.test.sh`, `pilot.test.sh` and `escalation-contract.test.sh`. `Typecheck: —`, so there is no type check.

## Scene viewpoints
—

## Run interdicts
- **Empty diff on these files:**
  - `method/commands/po-drive.md`, `po-ship.md`, `po-research.md`, `po-flow.md`;
  - `method/AGENTS.md`;
  - every other framing command file;
  - `method/hooks/`, `method/templates/`;
  - `.claude/`, `.polype/`.
- **Empty diff on these tests:** `tests/framing-through-pr.test.sh`, `tests/pilot.test.sh`, `tests/escalation-contract.test.sh`, `tests/lib.sh`.
- **`po-setup.md` outside `**Base.**` and the `human` bullet stays as it is:**
  - the commit build `:75-79`;
  - the pr bullets `:82-84` and `:86-88`, including the post-merge `--ff-only` at `:88`;
  - local mode `:90-93`;
  - the Report `:95`;
  - the quoted "Framing pull request ready" message.
- **In `po-setup.md`:** no `git reset`, `--force` push, `stash` or `checkout` added; no `git push` line without `framing/<slug>`.
- **In `po-orchestrator.md`:** nothing outside `## The decisions log` changes, and no `— checkpoint` heading is added.
- **No ADR file** and no new setting.

## The pivot
**The pivot:** a single slug-independent `git merge --ff-only origin/<Target branch>`, placed right after the fetch, replaces the conditional one in `Merged →`. It could be wrong in three ways:
- **The root refuses more often.** A root holding a staged framing path (`po-setup.md:79`) whose content differs from what `origin/<Target branch>` brings now meets the fast-forward on every landing, not only after its own merge. The refusal is reported and the landing goes on, so nothing is lost, but the report becomes noisier. Compare with `:79`'s reason for staging.
- **The deletion of a merged branch stays per slug.** The new `human` sentence must say exactly that, rather than letting a reader infer that any landing cleans up the other branches. Check task 2's sentence against `Merged →`.
- **Order against the missing-ref stop.** If the stop stays below the realignment, `git merge --ff-only` runs on a ref that does not exist. Check that the stop now precedes it.

## Files touched
- `method/commands/po-setup.md`
- `method/commands/po-orchestrator.md`
- `tests/framing-realign-and-orchestrator-log.test.sh` (new)
- `tests/framing-second-landing.test.sh` (one assertion removed)
- `docs/research/`, `docs/plans/`, `docs/verif/` for this id

## Test strategy
- **Automated:** two new text tests, one per criterion, at the only layer this repository has: assertions on the method file section that owns each rule.
  - Each names one rule whose deletion turns it red: moving the realignment back under `Merged →`, restoring the old sentence, or removing a log kind, the "Pull request ready" timing or the "Not now" caveat.
  - One existing assertion is removed so that the `human` sentence is tested in one place only.
  - Total new tests: 2, within the `Test budget` of 25.
- **Not testable here:** how an agent behaves on a real forge with two framing slugs. The record's "Not proven here" says so.
- **Visual checks:** none, since the story has no screen.

## Done when
- Tasks 1-6 are ticked.
- The full suite is green through `po-run` in `docs/verif/s121-framing-realign-and-orchestrator-log.md`.
- One implementer commit on `story/s121-framing-realign-and-orchestrator-log` carries the code, these docs and the record.
- A review with no open critical finding, then the ship through a pull request.
