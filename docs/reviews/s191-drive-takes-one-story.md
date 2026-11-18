# Review — s191-drive-takes-one-story

[Story](../stories.md) · [Plan](../plans/s191-drive-takes-one-story.md) · [Verification](../verif/s191-drive-takes-one-story.md)

Method version: 0.6.1
Recorded: 2026-11-18T13:09:25+01:00

Diff reviewed: `git diff main...story/s191-drive-takes-one-story`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 4eddbeb4bcc76859e42366ed96b9693b82d52601

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s191-drive-takes-one-story`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The 35 paths are either `Owns` entries or the story's own research, plan and verif files.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none
- [ ] No `Owns` line on this story → not the case. The `Owns` line is at `docs/stories.md:3103`.

## Evidence reused
- [x] `po-gate verif-current s191-drive-takes-one-story` → exit 0, so I reused the record. `Unit suite` (`bash tests/run.sh`) exited 0 on code whose content outside `docs/` matches `Tree:`. The project has no type check, so the record has none, and I did not substitute one. I read `## Not proven here`.
- [x] `po-gate qa-current` → not required. `QA stage` is `—`, so the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present.
  - Task 2: the argument line, the check, the id filter and the log entry "each track a planner raised to `full`" are in `po-drive.md:16,26,30,104`.
  - Task 3: the short-track sentence in `po-execute.md:60-62` matches the old `po-flow.md:88` word for word.
  - Task 4: every mention listed in the plan is rewritten.
  - Task 5: every removal matches `## Test triage`.
- [x] Run interdicts, checked one by one:
  - `po/`, `bin/`, `.claude/`, `.polype/`: empty diff.
  - Shipped stories, plans, reviews and ADRs: none touched.
  - No test file added apart from the oracle.
  - The `ask` row of `po-drive.md:42` is unchanged.
  - Every pinned word count holds. Totals: `method/` 69 150 against the 69 702 ceiling; `po-drive.md` 2 449 ≤ 2 450; `po-execute.md` 847 ≤ 850; `AGENTS.md` 3 732 ≤ 3 739.
  - No version bump.
- [x] Departures the implementer named (`plan-flow.md:15`, the D16 cell, `po-help.md:35`, `README.md:45`, the label "Unit suite"): all stay within the plan's wording, except two judged under Findings (`plan-flow.md:15` and D16).

## References
- [x] Every anchor the new text cites exists:
  - `## Ids and branches` at `method/AGENTS.md:135-137`, which holds the matching rule.
  - The planner's `## Limits` at `planner.md:53`.
  - `## Delegation` of `po-execute.md`.
  - The reviewer's short-track clause at `reviewer.md:25`.
  - The ADR reservation at `planner.md:56`.
- [x] `po next` behaviour matches what the filter sentence assumes. A ready story gets an `actions` entry (`po/src/next/mod.rs:88-95`). One held for `parallel`, `owns`, `dependency`, `decision` or `framing` appears under `held` (`wave.rs:57-74`). So "its `actions` entry, or its `held` reason and `ref`, … no entry at all → stop" covers every case.
- [x] No value that only looks right. The word ceilings come from `fb21c56`, and the counts were confirmed with `LC_ALL=C wc -w`.

## Rules
- [x] `AGENTS.md` conventions are respected: method files are in English, `po-help.md` is in French, and no new phrase test was added.
- [x] No accepted ADR is contradicted outright. ADR-0109 asks for exactly this change. The single-story path does lose something ADR-0019:28 tied to the orchestrator; see Findings.

**`drive_takes_an_id`, judged by reading: met.**
- The argument line (`po-drive.md:16`) and `argument-hint` take an id.
- The check (`:26`) defers to the `AGENTS.md` matching rule: zero or several matches → list them and stop.
- The filter (`:30`) keeps only that story's entries from the same `po next` output, so no route is driver-chosen.
- Lane preparation, ADR numbers, ships and the log apply unchanged to one lane.
- The one known limit is the `parallel` hold, issue #384, not raised again.

**`nothing_only_they_said_is_lost`, judged by reading.** I compared the table line by line with the old `po-orchestrator.md` and `po-flow.md` on `main`. 30 of its 31 rows hold. I checked these against the code:
- `lane.rs:19-46`: track and forced-full signals; no complexity → `ask`.
- `lane.rs:76-79`: root cause and technical choice → `ask`.
- `lane.rs:86-94`: design system and `Design source`.
- `lane.rs:180-202`: QA returns, two evidence commits, findings-shape, `Max attempts`.
- `planner.md:30,38,40,41,56`.

Rows the plan lets go:
- **Row 2, approved scope.** The reason holds on the normal path: `/po-stories` refuses an unapproved PRD or brief (`po-stories.md:21-24`). It does not hold for a stories file edited by hand under `Entry mode` `new`, `replace` or `adapt`. `po state` only reports `scope_state` (`framing.rs:61-79`), and the `framing` hold of `po next` (`wave.rs:73`) concerns the framing pull request, not approval. `/po-drive` waves never had this check either. No accepted ADR requires it, but the parity row D16 still claims it (see Findings).
- **Row 27, ADR-0036 session-model sentences.** Dropping them is right: they described two commands that no longer exist. But the reason the plan gives is false (see Findings). ADR-0036 still binds `/po-research`, `/po-plan` and `/po-design`, which still carry its sentence (`po-research.md:19`, `po-plan.md:20`, `po-design.md:13`).
- **Row 4, part ("before any worktree") and row 9, part.** The reasons hold: the driver prepares the lane, and `po next` asks at the design stage.
- **Row 24, the track as a logged decision.** The reason holds: the track is computed, not decided. A planner escalation now joins the log list.
- **Row 30, "Nothing is relaxed".** The reason holds: it restated Laws 2 and 3.
- **Missing row: the design approval.** Old orchestrator Stage 3 (`po-orchestrator.md:51`) applied `/po-design` together with its human approval. `/po-drive <id>` dispatches the designer with no approval. The table does not list this rule (see Findings).

**The cuts made to fit the word caps:**
- "No research, plan, record or review is overwritten to give a lane a clean slate" → still carried. The bold sentence "resumed, never replayed" stays at `po-drive.md:46`, and `planner.md:41` adds "never write that file again".
- "It reads files and git, never your memory" → explanation only. The rule "choose no route of your own" stays at `:30`. "From where you were started" is carried by `:50`.
- A lane needing more ADR numbers than it was given → carried by `planner.md:56` ("more ADRs needed than numbers reserved → … create no file whose name you invented").
- The sentence tying the decisions-log list to `AGENTS.md` → a pointer for maintainers, not a rule. The list itself still covers every kind `## What goes to the person` names.
- "so any plan can be opened and read whole" → a rationale; the plan path is still shown.
- `po-execute.md`: "Do not start without an approved plan, do not work outside the story's worktree, and never describe work the implementer did not report" → carried. Preconditions 5 and 3 cover the first two (`po-execute.md:24,26`), the pre-commit hook also covers the plan, and `## Report` says "From the subagent's answer". "A summary, not a transcript" was style only.
- `plan-flow.md:9`, "at most" dropped after "about 150 lines" → the meaning is barely changed, and `planner.md:40` says the same.

## Tests
- Oracle: `po-gate oracle-intact s191-drive-takes-one-story` → exit 0
- [x] Oracle: `po-gate oracle-intact` → exit 0, intact, with no `## Oracle changes`.
- [x] Floor: `po-gate floor-guard s191-drive-takes-one-story main` → exit 1, one flag: `tests/resume-shape-stop.test.sh` was deleted. The plan justifies it (`## Test triage`, `## Files touched`). Graded minor.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes appears. The update test runs the real `bin/polype` against a throwaway `HOME` and project, with no mock.
- [x] Within `Test budget`: 3 tests out of 25.
- [x] Bite test 1: I restored `/po-flow <id>` in `po-status.md:28` → 1 failing test (`two_commands_are_gone`). I undid it and `git diff --exit-code` was clean.
- [x] Bite test 2: I restored the cut sentence in `po-execute.md:17` → 1 failing test (`words_go_down`, 870 > 850). I undid it and `git diff --exit-code` was clean.
- [x] Removed assertions: every one read text of one of the two deleted files.
  - The rules they guarded now live in `po next`, whose oracle fixtures cover them: `findings-shape refused` and `QA evidence committed twice` are in `tests/fixtures/driver-cases/verdict.cases` and `resuming.cases`.
  - The two `HELP` lines dropped from `qa-fleet.test.sh` were phrase tests. The rule they read still stands, reworded, in `po-help.md:35` and is now untested; that is consistent with the direction against phrase tests.
  - The mutation tests of `plan-and-defect-paths-cleanup.test.sh` and `tech-choice-backstop.test.sh` still bite: the suite is green and their phrase follows the rewrite.

## Neighbours
- [x] No remaining mention of either command in `method/`, `README.md`, `bin/`, `po/` or the non-history files of `docs/`. Remaining mentions are in history files only: `defauts.md`, `decisions-log.md`, `validation/`, and the shipped stories, plans, reviews and ADRs.
- [x] `po run` launches `/po-drive` and is untouched.

## Lenses
Lenses run: none. The diff is prose and bash tests only, and no lens trigger appears in its paths or content.
- [x] No lens findings.

## Findings
- major — docs/plans/s191-drive-takes-one-story.md:121 — The table `## Rules the two commands carried` leaves out one rule: the human design approval that old `po-orchestrator.md:51` ran on the single-story path ("Apply `/po-design` … The approval here is the one `/po-design` defines"). Row 11 records only "design only for a screen, reused".
    - `/po-drive <id>` dispatches the `designer` subagent with no approval. The report only names the design as unapproved (`po-drive.md:113`).
    - ADR-0019:28 names the orchestrator's story-by-story path as the place where that approval stays. So a person driving one story with a screen silently loses a checkpoint, and `nothing_only_they_said_is_lost` is not fully met.
    - Fix: add the row and say why the approval goes (pointing to `/po-design <id>` for a person who wants it), or carry the approval for the `<id>` form.
- minor — method/templates/plan-flow.md:15 — The rewritten sentence credits the planner's `## Limits` with two claims it does not make: that "this file stays on disk" and that "the story goes to `/po-research <id>`". `planner.md:53-57` says neither. `planner.md:30` says the planner takes the full track itself in the same lane. The `/po-research <id>` route is stale and may mislead a planner filling a short-track plan. The plan forced this phrase for the mutation test, so this is wording only.
- minor — docs/plans/s191-drive-takes-one-story.md:137 — Row 27 gives a false reason ("no command writes research or plan in its own context"). `/po-research`, `/po-plan` and `/po-design` still do, on the session model, and carry ADR-0036 themselves (`po-research.md:19`, `po-plan.md:20`, `po-design.md:13`). Dropping the two sentences is still correct.
- minor — docs/parite-killer-saas.md:65 — The D16 row is marked `fait — method/commands/po-drive.md`, but its mechanism "bloqué si le cadrage manque" is no longer done by `/po-drive` or `po next`. The old orchestrator checks were dropped (plan row 2). `framing.rs` only reports scope, and the `framing` hold of `wave.rs:73` concerns the framing pull request. The Polype column should name that departure.
- minor — tests/resume-shape-stop.test.sh:1 — The test file was deleted (`floor-guard` flag). The plan justifies it, and `tests/driver-next-action.oracle.test.sh` covers the rule through its `verdict.cases` and `resuming.cases` fixtures.

## Not verified
- I ran no live `/po-drive <id>`. `drive_takes_an_id` was judged by reading the prose against `po next`'s output shape only. A person should run `/po-drive <id>` once on a scratch project for a ready story, a held one, and a non-exact name matching zero and then two stories. It is also a candidate for a `po-eval` control arm (#208).
- I did not rerun the full suite. I relied on the `po-run` row (exit 0) that `verif-current` accepts. Only the oracle file ran here, during the two bite tests.
- The installed copies under `.claude/` and `.polype/` of this repository still hold both commands until the next install. That is out of this story's scope; the oracle's update test is the only proof that a project loses them.
- The ADR-0036 sentences that remain in `po-research.md`, `po-plan.md` and `po-design.md` are untested now that the model-routing loop over the deleted files is gone. I checked them by reading only.
- Issue #384 (`/po-drive <id>` on a story held for `parallel`) was known beforehand and not re-examined.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T13:38:20+01:00

Diff reviewed: `git diff main...story/s191-drive-takes-one-story`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: e7cdeafba64a2cef4c3f3de6e4009ae3b0d13de9

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-status main...story/s191-drive-takes-one-story` (36 paths) and held each path against the `Owns` line at `docs/stories.md:3103`.
- [x] Every path is inside `Owns` or is the story's own evidence (research, plan, verif, review). The fix commit `a6cf078` touches 7 paths, all in that set.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none. The only other worktree is `.claude/worktrees/framing-m22`, on branch `fix/qa-deadline-wording`, which is not a story lane.
- [ ] No `Owns` line on this story → not the case.

## Evidence reused
- [x] `po-gate verif-current s191-drive-takes-one-story` → exit 0. `Verification mode` is `record`, so I reused the last `Unit suite` row (`bash tests/run.sh`, exit 0, tree `f1d66db…`) and did not rerun the suite.
  - The project has no `Typecheck` (`—`), so the record has none and I did not substitute one.
  - I read `## Not proven here`.
- [x] `po-gate qa-current` → not required. `QA stage` is `—`, so the story does not go to QA.

## Plan
- [x] Fix run 1 maps to the five findings of Fix loop 0. Each one is judged under `### Previous findings` below.
- [x] Run interdicts still hold on the fix commit:
  - `po/`, `bin/`, `.claude/` and `.polype/` are untouched.
  - No version bump.
  - No new phrase test: the one test line that changed is the mutation phrase of `plan-and-defect-paths-cleanup.test.sh:68`, which follows the rewritten sentence.
- [x] Word counts:
  - `po-help.md` is 718 words against 758 on `main`.
  - `plan-flow.md` is 734 words against 735 on `main`.
  - The `words_go_down` oracle test passes.

### Previous findings (Fix loop 0)
- **major, plan:121, missing design-approval row → closed.**
  - Row 32 of the plan's table and the pivot list now record the owner's decision d-0040, option a, faithfully: the approval leaves the driven path (one journey, ADR-0109), `/po-design <id>` run first keeps its approval (ADR-0019), and the wave report names unapproved designs.
  - That report rule is real: `po-drive.md:113`, "names every story whose design no human approved". `po-design.md:64-65` keeps its `## Approval` step.
  - `po-help.md:41` says the same in one sentence: "Pour approuver un écran toi-même, lance `/po-design <story>` avant : `/po-drive` n'approuve aucun design."
  - With that row, `nothing_only_they_said_is_lost` is met: the table lists every rule, judged by reading.
- **minor, `plan-flow.md:15`, false credit to the planner's `## Limits` → closed.**
  - The sentence now says that the planner takes the full track in the same lane (`planner.md:30`), and that a technical choice puts the line `Technical choice: waiting for a human` in that plan (`planner.md:56`).
  - The stale `/po-research <id>` route is gone, and no other file quotes the old wording.
- **minor, plan row 27, false reason → closed.** The row now says the sentences go with their two commands, and that ADR-0036 still binds `/po-research`, `/po-plan` and `/po-design`, citing `po-research.md:19`, `po-plan.md:20` and `po-design.md:13`.
- **minor, D16 parity row → closed.** The Polype column now says that missing framing no longer blocks the drive and that `po state` reports it. That matches `framing.rs`, as the previous review established.
- **minor, `tests/resume-shape-stop.test.sh` deleted → still flagged by `floor-guard`, still justified.** It is re-listed below because the guard flags it on every run; it needs no further action.

## References
- [x] Every anchor the new text names exists:
  - `planner.md:30` (full track in the same lane)
  - `planner.md:56` (the line goes in the plan)
  - `po-drive.md:113`
  - `po-design.md:64` `## Approval`
  - `po-research.md:19`, `po-plan.md:20` and `po-design.md:13` (the ADR-0036 sentences)
- [x] `test_tech_choice_paths_agree` (`plan-and-defect-paths-cleanup.test.sh:54-62`) still reads the `## Escalation signals` section of `plan-flow.md` for the line `Technical choice: waiting for a human`, which the new sentence keeps.

## Rules
- [x] `AGENTS.md` conventions hold: `po-help.md` stays in French, and the method files stay in English.
- [x] No accepted ADR is contradicted. The ADR-0019 gap on the single-story path was settled by the owner (d-0040), so I do not raise it again.

## Tests
- Oracle: `po-gate oracle-intact s191-drive-takes-one-story` → exit 0
- Oracle: `po-gate oracle-intact s191-drive-takes-one-story` → exit 0
- [x] Oracle intact, and `## Oracle changes` is empty.
- [x] Floor: `po-gate floor-guard s191-drive-takes-one-story main` → exit 1, one flag: `tests/resume-shape-stop.test.sh` was deleted. The plan justifies it, so it is graded minor.
- [x] Within `Test budget`: the oracle holds 3 tests, out of 25.
- [x] Bite test 1: I removed `Technical choice: waiting for a human` from the rewritten sentence of `plan-flow.md:15` and ran `plan-and-defect-paths-cleanup.test.sh`.
  - Result: 2 failing tests, `tech_choice_paths_agree` and `plan_tests_bite`.
  - Undone with `git checkout --`; `git diff --exit-code` is clean.
- [x] Bite test 2: I added a mention of `/po-orchestrator` to the new `po-help.md:41` sentence and ran `drive-takes-one-story.oracle.test.sh`.
  - Result: 1 failing test, `two_commands_are_gone`.
  - Undone; `git diff --exit-code` is clean.
- [x] None of the six empty test shapes appears in the changed tests.

## Neighbours
- [x] No file outside the history files quotes the old `plan-flow.md` sentence. The `po-help.md` map entry for `/po-design <story>` (line 32) is consistent with the new line 41.
- [x] Issue #384 (`/po-drive <id>` on a story held for `parallel`) is known and filed, so I did not raise it.

## Lenses
Lenses run: none. The diff is prose and bash tests only; no lens trigger appears in its paths or content.
- [x] No lens findings.

## Findings
- minor — method/commands/po-help.md:41 — "lance `/po-design <story>` avant" tells the person to run `/po-design` before `/po-drive`. But `/po-design` stops when the story worktree is missing and sends the person to `/po-research <id>` (`po-design.md:20`, check 3). On a story not yet started, the documented order is therefore `/po-research`, then `/po-design`, then `/po-drive <story>`. The decision itself is the owner's (d-0040); only the sequence in the sentence is incomplete. The person is redirected rather than misled, so this is wording only.
- minor — tests/resume-shape-stop.test.sh:1 — The test file was deleted (`floor-guard` flag). The plan justifies it in `## Test triage`, and the `verdict.cases` and `resuming.cases` fixtures of `tests/driver-next-action.oracle.test.sh` cover its rule. This is carried over from Fix loop 0 and needs no action.

## Not verified
- I ran no live `/po-drive <id>`. `drive_takes_an_id` and the d-0040 path were judged by reading only. A person should run the following once on a scratch project with a screen story:
  - `/po-research`, then `/po-design` with its approval, then `/po-drive <id>`, confirming that the approved design is reused and not replayed;
  - `/po-drive <id>` on an unapproved design, confirming that the report names it.

  This is a candidate for a `po-eval` control arm (#208).
- I did not rerun the full suite. I relied on the `po-run` row (exit 0) that `verif-current` accepts. Only `plan-and-defect-paths-cleanup.test.sh` and the oracle file ran here, during the bite tests.
- I did not check whether `/po-drive` can tell that a design was approved through `/po-design`: no file marks an approval. The `po-drive.md:113` rule that names unapproved designs predates this story (it is at `main:po-drive.md:112`), so this story did not change it.
- The installed copies under `.claude/` and `.polype/` still hold both commands until the next install. This is out of scope; the oracle's update test is the only proof that a project loses them.
- Issue #384 was not re-examined.

Max severity: minor
Ship allowed: yes
