---
validated: yes
---
# Plan — s197-own-context-commands-are-briefs

[Story](../stories.md) · [Research](../research/s197-own-context-commands-are-briefs.md)

Branch `story/s197-own-context-commands-are-briefs`. Read `docs/research/s197-own-context-commands-are-briefs.md` first; this plan builds on it without repeating it.

## Story
The three commands that work in their own context keep only their stage's procedure: no precondition or outcome `po next` computes or `po-gate` checks, the worktree steps written once, and nothing the planner or the designer reads in them lost. Criteria: `routing_is_said_once`, `worktree_is_prepared_in_one_place`, `subagents_keep_their_procedure` (model-read), `commands_still_lint`, `words_go_down` (script-read).

## Reuse
No new code: the story cuts prose and removes test assertions; the routing it stops restating is already in `po next` (`po/src/next/lane.rs:53-119`) and the steps it stops restating are already in the templates and skills named in the table below.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/own-context-commands-are-briefs.oracle.test.sh` | `1826618741 2076` |

| Criterion | Test |
| --- | --- |
| `routing_is_said_once` | — model-read (owner rule of 2026-11-13): the reviewer reads the three files and checks that the only routing left is the `## By hand` paragraph of task 1-3, against the stops of `lane.rs:53-119` and `wave.rs:57-74`. Candidate for a `po-eval` control arm (#208): a model running `/po-research` by hand on a held story stops. |
| `worktree_is_prepared_in_one_place` | — model-read: the reviewer greps `git worktree add -b` in `method/commands/` and finds it in `po-research.md` alone, `po-drive.md` pointing to `## The worktree`. |
| `subagents_keep_their_procedure` | — model-read: the reviewer checks each row of `## Removed sentences` against the diff and opens each "lives in" reference. Candidate for a `po-eval` control arm (#208): a planner fills `templates/research.md` and `templates/plan.md` fully without the removed restatements. |
| `commands_still_lint` | `test_commands_still_lint` — `bin/po-lint` passes on `method/`, the three keep a `Reads settings:` line, `po-research.md` and `po-plan.md` keep their tool lists, `po-design.md` declares none. Mutations: task 5. |
| `words_go_down` | `test_words_go_down` — the three ≤ 1 821 words (`LC_ALL=C wc -w`), and `po-research.md` ≤ 764, `po-plan.md` ≤ 871, `po-design.md` ≤ 886, `po-drive.md` ≤ 2 441, `planner.md` ≤ 1 336, `designer.md` ≤ 959. |

## Word arithmetic
Measured on a draft built from tasks 1-3 (`LC_ALL=C wc -w`, sections as `## ` cuts them):

| File | Before | After | Head | First section | Investigation / Writing / Steps | Report / Approval |
| --- | --- | --- | --- | --- | --- | --- |
| `po-research.md` | 764 | 499 | 117 → 80 | Checks 59 → By hand 82; Worktree 263 → 144 | 224 → 128 | 101 → 65 |
| `po-plan.md` | 871 | 624 | 123 → 84 | Checks 131 → By hand 136; Inputs 48 → 22 | 413 → 241 | 156 → 141 |
| `po-design.md` | 886 | 660 | 170 → 117 | Checks 152 → By hand 110; Where 81 → 39 | Steps 1-4: 435 → 332 | 48 → 62 |
| Three together | 2 521 | 1 783 | | | | |

1 783 ≤ 1 821: margin 38 words. `po-drive.md` 2 441 → 2 413. No human checkpoint, stop to a person or private matter was cut to reach it (rows marked **H** below all keep their rule). If the implementer's wording runs over, the next cuts are the `po-design.md` frontmatter `description` (36 words, read by no test) and the examples list of Step 4 "Look for what is broken" — never an **H** row.

## Removed sentences
"Lives in" is where the rule holds after the story. **H** marks a human checkpoint or a stop that goes to a person: each keeps its rule, through `po next`'s `ask`/`held` reported "as a question for the person" by the new `## By hand` paragraph, or by staying in the command.

| # | Sentence removed (file:line today) | Lives in, or why it goes |
| --- | --- | --- |
| R1 | `po-research.md:19` "`/po-drive` passes `Model strong` to the planner it dispatches instead." (the rest of the sentence stays, shortened) | `po-drive.md:62` |
| R2 | `po-research.md:22` no `AGENTS.local.md` → `/po-setup` | `po next` exits 2 (`next/mod.rs:79-85`, `project.rs:43-45`) → "stop, naming `polype install`" |
| R3 | `po-research.md:23` match the id | `method/AGENTS.md` `## Ids and branches` |
| R4 | `po-research.md:24` soft `Stories ready:` warning (never blocks) | `po state` framing item `stories-review` and `po-session` "Framing next:" (`po/src/context/framing.rs:81-85,102-103`) |
| R5 | `po-research.md:30` "A story must see every story merged before it." | why only; the start-point rule stays in step 1 |
| R6 **H** | `po-research.md:31` story not on the start point → stop, merge the framing pull request | `po next` `held` reason `framing` (`wave.rs:70-73`, `start.rs:15-31`; `tests/held-says-what-collides.oracle.test.sh:87-99`), reported to the person |
| R7 **H** | `po-research.md:36` existing worktree on another branch, detached, root, foreign → end; "Do not repair it with `switch`, `checkout` or `stash`." | `po next` warning `orphan-worktree` (`lanes.rs:226-236`), no entry for the story (`wave.rs:37-49`), reported; no repair: `method/AGENTS.md` Law 4, `po-drive.md:55` |
| R8 | `po-research.md:43` step 1, restate the story | `templates/research.md:8-9` `## Story` |
| R9 | `po-research.md:44` step 2, files and what they do | `templates/research.md:11-12` `## Current code` |
| R10 | `po-research.md:46` step 4, traps | `templates/research.md:20-21` `## Traps` |
| R11 | `po-research.md:47` step 5, doubts stay questions | `templates/research.md:23-24`; `planner.md:37`; `codebase-analysis` "Only name what you have opened" |
| R12 | `po-research.md:48` step 6, own complexity, split at 5 | `templates/research.md:26-30`; `planner.md:37` |
| R13 **H** | `po-research.md:55` `Root cause: not found` → finish "goes to a human, no plan" | `po next` `ask` "Root cause: not found" (`lane.rs:77`, `lanes.rs:323-324`), reported by the new finish line as a question for the person; `diagnostic` skill `## Three hypotheses, then stop`; `planner.md:38` |
| R14 | `po-research.md:57` "Next: /po-plan <id>" | the entry of a new `po next` |
| P1 | `po-plan.md:14` `Target branch` in `Reads settings:` | no longer read by any remaining line |
| P2 | `po-plan.md:20` drive half of the model sentence | `po-drive.md:62` |
| P3 | `po-plan.md:23` setup check | as R2 |
| P4 | `po-plan.md:24` id match | as R3 |
| P5 | `po-plan.md:25` worktree must exist on `story/<id>`, point to `/po-research`; no branch switching | no lane → `plan` reason `ready`, `/po-research`'s action (`next/mod.rs:96`); wrong branch as R7; Law 4 |
| P6 **H** | `po-plan.md:26` `Root cause: not found` → stop, goes to a human | as R13 |
| P7 **H** | `po-plan.md:35` no research → warn, continue only on the user's go-ahead | the path closes: `po next` answers `plan` reason `no research` (`lane.rs:73-75`), which only `/po-research` takes, so `/po-plan` reports it and ends. The question goes because planning without research is no longer possible, the stricter outcome |
| P8 | `po-plan.md:39` "plus lint and type check instead; do not invent a component test to fill the column" (the task-test rule stays, shortened) | `templates/plan.md:30`; `testing-doctrine` `## Which layer?` (Component) and `## When does each check run?` |
| P9 | `po-plan.md:40` budget and layer rules | `templates/plan.md:46`; `testing-doctrine` `## How many tests?`, `## Four things to cut` |
| P10 | `po-plan.md:41` "through the interface the tasks fix", "`cksum < <file>`" (the oracle rule stays, shortened) | `templates/plan.md:20`; `planner.md:55` |
| P11 | `po-plan.md:42` Run interdicts | `templates/plan.md:36-37`; `planner.md:39` |
| P12 | `po-plan.md:43` The pivot | `templates/plan.md:39-40`; `planner.md:39` |
| P13 | `po-plan.md:44` Reuse ladder | `templates/plan.md:13-14`; `planner.md:39-40`; `review-antihallu` step 3 |
| P14 | `po-plan.md:57` `/po-execute` refuses a plan without `validated: yes` | `po-gate plan-validated` and the pre-commit (`method/AGENTS.md` Law 3); `planner.md:51` |
| P15 | `po-plan.md:59` finish messages | the entry of a new `po next` |
| D1 | `po-design.md:11` "The plan and the code … someone already decided." | why only |
| D2 | `po-design.md:13` drive half of the model sentence | `po-drive.md:63` |
| D3 | `po-design.md:16-18` setup, id, worktree checks; never create or switch a branch | as R2, R3, P5; `designer.md:18-19,25` |
| D4 **H** | `po-design.md:19` no `docs/design-system.md` → stop, point to `/po-design-system` | `po next` `ask` "no docs/design-system.md" (`lane.rs:87-88`; `a-wave.cases:5-13`); `designer.md:21` |
| D5 **H** | `po-design.md:20` `Design source` `—` → the person chooses and writes it; never set for them | `po next` `ask` "Design source unset" (`lane.rs:90-91`; `a-wave.cases:16-24`); `method/AGENTS.md` `## Reading settings`; `designer.md:22` |
| D6 | `po-design.md:22` "Either way the command writes nothing and draws no mockup." | the `## By hand` "ends the command, writing nothing" |
| D7 | `po-design.md:24` no screen → stop | `po next` sends `design` only for a screen (`lane.rs:81-94`); the no-`Surface` case stays in `## By hand` |
| D8 | `po-design.md:26` "when present" for the research | `design` comes only once a research or a plan exists (`lane.rs:71-75`) |
| D9 | `po-design.md:29` "These files are the source of truth … runs `/po-design` again." | `design-doctrine` `## Where the truth lives`; `templates/design-screen.md:3` |
| D10 | `po-design.md:42` inventory names; gaps recorded, not filled | `design-doctrine` `## No invention`, `## Gaps` (gaps left to a person); `templates/design-screen.md:18,32-33`; `designer.md:31` |
| D11 | `po-design.md:53` a brief is not rendered | `templates/design-screen.md:30`; `designer.md:34` |
| D12 | `po-design.md:56` "where fonts, scripts … served page" | why only; "never through `file://`" stays |
| D13 | `po-design.md:60` contrast measured by `/po-design-system` | `design-doctrine` `## Measuring`; `designer.md:33`; "Nothing is measured here." stays |
| D14 | `po-design.md:62` examples "no browser tool…, a state the page cannot reach" | `templates/design-screen.md:30`; `designer.md:34` |
| D15 | `po-design.md:67` "Next: /po-plan <id>" | the entry of a new `po next` |
| V1 | `po-drive.md:53` fetch, `worktree add`, start point, `.env*`, `Install` | `po-research.md` `## The worktree` |

Kept whole (**H** or private): `po-research.md:33` (`.env*` not ignored → stop), `po-plan.md:47` (ADR drafted, never settled), `:52` (technical choice settled with the person), `:54` (`human` approval), `:55` (`autonomous`, says no human reviewed), `po-design.md:34` (ask once when unclear), `:46` (`Design skill` `—` → stop), `:65` (approval, ADR-0019, d-0040). `planner.md` and `designer.md` are not edited.

## Tasks
1. [x] `method/commands/po-research.md`: replace `## Checks first` and the model sentence by `## By hand` below; in `## The worktree`, put this line under Path/Branch: "`/po-drive` prepares each lane by these steps; reason `no research` means the worktree is already there.", step 1 = today's :30 without its last sentence, step 2 = `` `git worktree add -b story/<id> <path> <start point>`. ``, steps 3-4 = :33-34, report :38; delete :31, :36; `## The investigation` keeps :41 and :45 (unnumbered); `## The report` keeps :51, :53; delete :55; finish: `Finish with "Research written to docs/research/<id>.md in <path>." and the story's entry from a new \`po next\`, an \`ask\` as a question for the person.` — Test: `test_words_go_down`, `research.test.sh`.
   `## By hand` text: "This research runs on the session's model, which no command can choose (ADR-0036); start the session on `Model strong`. After step 1 of `## The worktree`, run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`. Go on only on `plan` with reason `ready` or `no research`. Any other entry, or a warning naming the story, is reported, an `ask` as a question for the person, and ends the command."
2. [x] `method/commands/po-plan.md`: `Reads settings:` without `Target branch`; replace :20-26 by `## By hand` (same as task 1 from "This plan is written on the session's model…", no "After step 1" clause, and "Go on only on `plan` with reason `research, no plan` or `plan-validated refuses`, on `validate-plan`, or on the `ask` whose reason is `Technical choice: waiting for a human`."); :28 ends "inside `<Worktree root><id>`."; delete :35, :40, :42-44, :57; :39 becomes the last sentence of the :38 bullet: "Each names the test that would fail if it were wrong; a purely visual task names its visual check instead."; :41 becomes "**Acceptance tests**: before the plan, write the oracle files its `## Acceptance tests` names and no other test file, then record their sums. An oracle file outside the story's `Owns` is not written: report it as a gap of the story, in that criterion's row."; finish: `Finish with the story's entry from a new \`po next\`, an \`ask\` as a question for the person.` — Test: `test_words_go_down`, `test_commands_still_lint` (AskUserQuestion still in the body), `plan.test.sh`, `escalation-contract.test.sh`.
3. [x] `method/commands/po-design.md`: :11 → "This command decides a story's screen from the recorded system and writes it down in the story's worktree. It writes no source file."; replace :13-26 by `## By hand` (same frame; "Go on only on `design`, or on a `plan` entry of a story with no `Surface` line whose text shows a screen (`AGENTS.md`, Law 1).", ending "…and ends the command, writing nothing.") then "Then read the `design-doctrine` skill, the story, `docs/research/<id>.md` and `docs/design-system.md`. Everything below reads and writes inside `<Worktree root><id>`."; `## Where the design lives` keeps its first sentence and :31; Step 2 → "Fill `templates/design-screen.md` into `docs/designs/<id>/design.md`: for a derived screen, the pattern it reuses and the deltas only, with no artefact; for a new one, every section."; delete :53; :56 "…<free port>`, never through `file://`."; :60 + :62 → "Nothing is measured here. Write in `## Seen and not seen` what was looked at and what could not be seen, with the reason, then stop the server."; finish: `Finish with "Design written to docs/designs/<id>/ in <path>." and the story's entry from a new \`po next\`, an \`ask\` as a question for the person.` — Test: `test_words_go_down`, `design.test.sh`, `designer-browser.test.sh`.
4. [x] `method/commands/po-drive.md:53` → "You prepare each lane's worktree yourself, before any subagent starts, by the steps of `## The worktree` in `/po-research`. `planner` may not run `git worktree add`, so a lane you did not prepare cannot exist." Nothing else in the file changes. — Test: `test_words_go_down` (2 413 ≤ 2 441), `drive.test.sh`.
5. [x] Tests (each removal is a phrase whose sentence task 1-4 removes; no phrase test is added):
   - `tests/lint.test.sh` `test_lint_checks_fail_closed_rules_have_a_stop`: mutate `agents/designer.md` instead — `sed -i 's|^\(.*\`Design source\` at \`—\`, or another setting you need missing\) →.*|\1 → pick internal.|'`, expected at `agents/designer.md:$(line_of "$f" '`Design source` at `—`')`; negative controls `sed -i 's|^- The story showing no screen.*|&\n- \`replace\` or \`adapt\` → continue.|'` and `sed -i "s|^## Drawing with the project's skill\$|&\n- No mockup yet → continue.|"` (both checked on a draft: one breach, then none).
   - `research.test.sh:9` ('Do not repair it…'): R7. `design.test.sh`: delete `test_design_fails_closed_without_system_or_source` (:21-27, D4-D6) and `test_design_test_message_matches_its_assertion` with its comment (:28-57, D4-D7); in `test_design_lives_in_the_story_worktree` drop :82 (`Checks` `story/<id>`, D3) and the phrase at :86 (D9).
   - `reuse-ladder.test.sh:59-62` and the `PO_PLAN` line :7 (P13). `plan-and-defect-paths-cleanup.test.sh`: in `test_defect_stops_agree` drop the `report`/`checks` reads and :46-49 (R13, P6), keep the `opens with` guard and the planner holds; drop :66 (R13); drop `PLAN=` :5.
   - `tech-choice-backstop.test.sh:24-26` `test_plan_checks_stop_on_the_marker` (P6: `/po-plan` now goes on on that `ask`). `defect-and-routing-paths.test.sh:29-30` and `PLAN=` :6 (P6).
   - `framing-through-pr.test.sh:59-70` `test_research_waits_for_framing_merge` and `RESEARCH=` :5 (R6). `stories-review.test.sh:47,50-53` and `RESEARCH=` :8 (R4), keeping :48-49.
   - `drive.test.sh:23` and `drive-guards.test.sh:17` (`git worktree add -b story/<id>` in po-drive, V1); the guards' other lines stay.
   — Test: those files, run focused.
6. [x] Checks: `bash tests/run.sh own-context-commands-are-briefs.oracle.test.sh lint.test.sh research.test.sh plan.test.sh design.test.sh reuse-ladder.test.sh plan-and-defect-paths-cleanup.test.sh tech-choice-backstop.test.sh defect-and-routing-paths.test.sh framing-through-pr.test.sh stories-review.test.sh drive.test.sh drive-guards.test.sh model-routing.test.sh planner.test.sh escalation-contract.test.sh planner-writes-the-oracle.test.sh design-handoff.test.sh designer-browser.test.sh overlap.test.sh`, then the full suite once through `po-run`. — Test: the suite.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/`, `bin/polype`, `bin/po-lint`, `.claude/`, `.polype/`, `method/AGENTS.md`, `method/agents/planner.md`, `method/agents/designer.md`, `method/templates/`, `method/skills/`, every `method/commands/` file but the four of tasks 1-4.
- `po-drive.md`: only line 53 changes.
- `tests/own-context-commands-are-briefs.oracle.test.sh` keeps its sum `1826618741 2076`.
- No test file is created besides the oracle, no phrase assertion is added, no test outside `Owns` is edited; `tests/own-context-commands-are-briefs.test.sh` is not created (it would hold no test).
- No **H** row's rule is reworded away: the kept-whole lines above stay as they are; `which no command can choose (ADR-0036); start the session on \`Model strong\`` stays verbatim in all three.
- No version bump: the story does not touch `po/`.

## The pivot
Each command routes by `po next` and goes on only on its own actions, reporting everything else. Ways it could be wrong:
- `po next` decides more than the old checks: by hand, a story beyond `Parallel` or colliding on `Owns` now reads `held` and `/po-research` stops (`wave.rs:57-66`). Compare with `/po-drive <id>` (`po-drive.md:30`), which already behaves so.
- `po next` decides less: it never fetches (`start.rs:16-22`), hence "After step 1" in `/po-research`; and it reads only `Surface` (`stories.rs:25-27`), hence the kept clause of `/po-design`. Compare each `## By hand` with `lane.rs:53-119`.
- A subagent reading the command takes `## By hand` for itself: the heading says it is for a hand run, and `planner.md:27-28`, `designer.md:15-25` give the subagents their own checks. Compare with the planner's and designer's next real runs.

## Files touched
`method/commands/po-research.md`, `po-plan.md`, `po-design.md`, `po-drive.md`; `tests/own-context-commands-are-briefs.oracle.test.sh` (written); `tests/lint.test.sh`, `research.test.sh`, `design.test.sh`, `reuse-ladder.test.sh`, `plan-and-defect-paths-cleanup.test.sh`, `tech-choice-backstop.test.sh`, `defect-and-routing-paths.test.sh`, `framing-through-pr.test.sh`, `stories-review.test.sh`, `drive.test.sh`, `drive-guards.test.sh`; `docs/research/` and `docs/plans/` of the story.

## Test strategy
Two oracle tests (`test_commands_still_lint`, `test_words_go_down`), within `Test budget` 25. The other test changes remove phrase assertions whose sentence goes (AGENTS.local.md, owner rule of 2026-11-13) and move one lint mutation; the behaviour of each stop that moves to `po next` is already tested outside `Owns` (research `## Traps`). Visual checks: none.

## Done when
The oracle and the focused files pass, the full suite passes through `po-run`, `bin/po-lint` is clean, and the reviewer checks `## Removed sentences` against the diff; one commit by the implementer with the research and the plan.
