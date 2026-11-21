---
validated: yes
---
# Plan — s198-delegating-commands-are-briefs

[Story](../stories.md) · [Research](../research/s198-delegating-commands-are-briefs.md)

Branch `story/s198-delegating-commands-are-briefs`. Read `docs/research/s198-delegating-commands-are-briefs.md` first; this plan builds on it without repeating it.

## Story
The three commands that delegate keep only a `## By hand` routing paragraph, the brief of their subagent and the recording of its answer, and `/po-drive` points to them instead of restating them. Criteria:

| Criterion | Read by |
| --- | --- |
| `routing_is_said_once` | a model |
| `drive_and_commands_share_one_text` | a model |
| `nothing_is_lost` | a model |
| `commands_still_lint` | a script |
| `words_go_down` | a script |

**Correction to the story.** The research's first structuring fact shows a command must go on in three cases `po next` does not route to it. These are the only such cases:
- `/po-execute` on `ship` after `/po-ship` stopped on failing checks;
- `/po-qa` on the `ask` "QA status: blocked";
- `/po-review` on the `ask` "findings-shape refused" or "review without verdict", once the person settled it.

Fix run, 2026-11-21: the review found a fourth, `/po-review` on the `ask` "QA evidence committed twice" (`lane.rs:187-191`), now in its `## By hand`.

## Reuse
No new code: the story cuts prose and removes phrase assertions. The routing it stops restating is already in `po next`, at `po/src/next/lane.rs:53-203` and `po/src/context/lanes.rs:243-350`.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/delegating-commands-are-briefs.oracle.test.sh` | `43086886 2365` |

| Criterion | Test |
| --- | --- |
| `routing_is_said_once` | — model-read (owner rule of 2026-11-13). The reviewer checks that each command's only routing is its `## By hand` section, set against `lane.rs:53-203`. Candidate for a `po-eval` control arm (#208): a model runs `/po-qa` by hand on an `execute` entry and must stop; on the `ask` "QA status: blocked" it must go on. |
| `drive_and_commands_share_one_text` | — model-read. The reviewer greps `po-drive.md` and finds no restated model rule, fix-run condition, QA resume, loop count or blocked-report wording, only pointers to `/po-execute` `## Model` and `## Delegation`, `/po-qa` `## Delegation` and `## The evidence commit`, and `/po-review` `## Fix loop` and `## Recording`. Candidate arm: a driver on an `execute` entry whose review says `Ship allowed: no` appends the fix-run sentence. |
| `nothing_is_lost` | — model-read. The reviewer checks each row of `## Removed sentences` against `git diff main -- method/commands/` and opens each "lives in" reference. **H** rows and the kept list are checked by `grep -cF` of the sentence on `git show main:<file>` and on the branch, never by reading. |
| `commands_still_lint` | `test_commands_still_lint`. `bin/po-lint` exits 0 on `method/`, and the three files keep `Reads settings:`. The tool sets are exact: `/po-execute` has Read, Glob, Grep, Agent and po next (ADR-0120); `/po-review` has its narrow set plus po next; `/po-qa` is unchanged. The lint's ADR-0120 mutations stay in `drive-executes-next.oracle.test.sh:42-64`, untouched. |
| `words_go_down` | `test_words_go_down`. The three files total ≤ 2 004 words (2 704 − 700, `LC_ALL=C wc -w`). Each stays at or under its count before the story: `po-execute.md` 847, `po-qa.md` 712, `po-review.md` 1 145, `po-drive.md` 2 413, `po-help.md` 718. |

## Word arithmetic
Measured on a draft built from tasks 1-4 (`LC_ALL=C wc -w`, bec755c):

| File | Before | After |
| --- | --- | --- |
| `po-execute.md` | 847 | 584 |
| `po-qa.md` | 712 | 543 |
| `po-review.md` | 1 145 | 873 |
| The three | 2 704 | 2 000 |
| `po-drive.md` | 2 413 | 2 266 |

The draft is 4 words under the 2 004 cap. The cut stays clear of every **H** row and every kept sentence: about 1 580 of the 2 000 words are the prompts, refusals, recording, evidence commit and reports kept word for word. If the wording runs over, cut in this order:
1. `po-execute.md` `## Model`: the bold labels `**Rule.**`, `**Complexity read.**`, `**Refusal.**`, leaving the sentences;
2. `po-review.md` `## By hand`: the words "or `review without verdict`".

Never cut an **H** row or a kept sentence. No test outside `Owns` reads a sentence that goes. `po-help.md` is not edited: its lines 34-36 stay true.

## How the files separate the two readers (#423)
`## By hand` holds only what a person needs to run the command alone. Its first sentence is "`/po-drive` skips this section.", and the whole heading is what it skips. The driver never needs any of it: it runs `po next` itself (`po-drive.md:30`).

Every line the driver needs sits under another heading, which `po-drive.md` names:
- `/po-execute`: `## Model`, and `## Delegation` with its four append conditions;
- `/po-qa`: `## Delegation`, whose first line is the QA resume, and `## The evidence commit`;
- `/po-review`: `## Fix loop`, `## Delegation` and `## Recording`.

No subagent reads these files: `implementer.md:3`, `qa.md:3` and `reviewer.md:3` only name them as callers.

## Removed sentences
"Lives in" is where the rule holds after the story. **H** marks a human checkpoint, a stop that goes to a person, or a private rule. Each **H** row keeps its person-facing words verbatim, now keyed on `po next`'s entry.

| # | Sentence removed (file:line on main) | Lives in, or why it goes |
| --- | --- | --- |
| E1 | `po-execute.md:2` "by construction," | why only; the lint phrase "cannot edit files or run a shell" stays (`bin/po-lint:144`) |
| E2 | `:13` `Test budget`, `Full suite` | no remaining line reads them |
| E3 | `:17` no Write or Edit, `po next` only reads | frontmatter `:2-9`; ADR-0120; `bin/po-lint:144-151`; Law 2 |
| E4 | `:19` no Agent tool → stop | `## By hand` |
| E5 | `:22` no `AGENTS.local.md` → `/po-setup` | `## By hand`; `po next` exit 2 (`next/mod.rs:79-85`) |
| E6 | `:23` id match | `method/AGENTS.md` `## Ids and branches`; no entry → stop, as `/po-drive <id>` (`po-drive.md:30`) |
| E7 | `:24` worktree registered, the shared-git-directory method | a lane only at `<Worktree root><id>` on `story/<id>` (`lanes.rs:216-226`); otherwise warning `orphan-worktree` (`:228-236`), "a warning naming the story … ends the command"; no lane → `plan`/`ready` (`mod.rs:93-94`), reported; no repair: Law 4 |
| E8 | `:25` no plan → `/po-plan` | `po next` `plan` (`lane.rs:73-75,95-97`), reported |
| E9 **H** | `:26` not `validated: yes` → the "not approved yet" message | `po next` stage `Plan` (`lanes.rs:270-272`) → `validate-plan` (`lane.rs:100`), message verbatim in `## By hand`; `plan` under `autonomous` (`:101`) is reported; `po-gate plan-validated` and the pre-commit (Law 3) |
| E10 | `:27` `po next` only on a blocked review; no entry → `polype install`; never read `Next action:` yourself | `## By hand` runs it always; no entry → `po-drive.md:30`; routing never reads the review |
| E11 | `:29-34` table rows `fix`/`execute`, `qa`…`wait` | `## By hand` "Go on only on…", "reported and ends the command"; the new `po next` entry names what comes next |
| E12 **H** | `:35` `ask` → "stop; a person decides, given the reason" | verbatim in `## By hand` |
| E13 | `:36` design glob, "**has a design**" | `## Delegation` "When `docs/designs/<id>/` holds a file" |
| E14 | `:37` a model setting missing → stop | `## By hand` "a setting this command reads missing"; `po-drive.md:24` |
| E15 | `:38` "**has an oracle**" | `## Delegation` "When `## Acceptance tests` of the plan names at least one file" |
| E16 | `:43` `—` passes no model; `Light up to: —` | kept, not removed (fix run, 2026-11-21): the bullet stays verbatim in `## Model`, since `templates/agents-local.md` is read by no command at run time |
| E17 | `:44` a fix run follows the same rule | why only: the rule reads only the story's complexity |
| E18 | `:68` "Wait for the subagent to finish." | why only: `## Report` needs the answer; the driver dispatches in the background (`po-drive.md:60`) |
| E19 | `:73` "Implementation finished. Next: /po-review <id>" | `## By hand` "At the end, report a new `po next` entry" |
| Q1 | `po-qa.md:2` description tail | `qa.md:3`; tools `:4-9`; `:17` |
| Q2 | `:17` "no Write or Edit tool"; "checks … returns its report; it fixes nothing, and neither does this command"; "two uses" | tools; `qa.md:3` "without fixing anything"; "three uses" names `po next` |
| Q3 | `:19`, `:22-24`, `:28` Agent, setup, id, worktree, `Model strong` | as E4-E7, E14, through `## By hand` of `/po-execute` |
| Q4 | `:25` no `docs/verif` → `/po-execute` | stage `Execute` (`lanes.rs:276-278`) → `execute`, reported |
| Q5 **H** | `:26` `screen` with `Dev` `—` → stop, ask for `Dev` | verbatim in `## By hand` (`po next` does not read `Dev`); `qa.md:31` for the driver's runs |
| Q6 | `:27` nothing to check | `qa` only for a story that goes to QA (`lanes.rs:279-288`); `qa.md:30` |
| Q7 | `:35` Wait | as E18 |
| Q8 | `:37` `Model strong` at `—` | kept (fix run, 2026-11-21): "`Model strong` at `—` passes no `model` at all." before the refusal in `## Delegation` |
| V1 | `po-review.md:2` description | why only |
| V2 | `:15` `Verification mode`, `Test budget` | no remaining line reads them |
| V3 | `:19` verdict from the reviewer; one file through `po record`; critical blocks | Law 2, Law 3 "**Critical** stops the ship"; `## Recording` "Write nothing by hand"; `reviewer.md` |
| V4 | `:21`, `:24-27` Agent, setup, id, `Model strong`, worktree, "do not switch branches" | as E4-E7, E14; Law 4 |
| V5 | `:28` blocked-on-QA definitions, "nothing less makes either" | `## Fix loop`, same condition in one sentence |
| V6 **H** | `:28` third blocked review → hand the findings to a human; QA returns not counted | `po next` `ask` "Max attempts reached" (`lane.rs:197-200`, `lanes.rs:336-350`; QA returns skipped `lane.rs:187-193`); the person-facing message of V10 verbatim |
| V7 | `:35` `Model strong` at `—` | kept as Q8 (fix run, 2026-11-21) |
| V8 | `:47-48` blocked on QA, on uncommitted evidence | `qa` "qa-current refuses" or "QA evidence not committed" (`lane.rs:110-113`), and `/po-qa` goes straight to the commit; "no fix run is spent" → `## Fix loop` |
| V9 **H** | `:49` findings-shape stop message | `ask` "findings-shape refused" (`lane.rs:194-196`); message verbatim in `## By hand` |
| V10 **H** | `:50` other `no` → fix run; at loop 2 the "Ship still blocked…" message | `fix` (`lane.rs:201`); the loop-2 message verbatim in `## By hand` |
| V11 | `:51` `yes` → `/po-ship` | `ship` (`lanes.rs:273-275`) |
| D1 | `po-drive.md:37` fix-run sentence, model rule | `/po-execute` `## Delegation` (fix-run condition) and `## Model` |
| D2 | `:38` QA resume | `/po-qa` `## Delegation` first line; `## The evidence commit` step 2 |
| D3 | `:39` "at the `Fix loop:` that `/po-review` computes" | `/po-review` `## Fix loop`, named in step 5 |
| D4 | `:64` model rule | `/po-execute` `## Model`, named in step 3 |
| D5 | `:65` `Model strong`, `po record qa`, the commit, the no-`QA status:` stop | `/po-qa` `## Delegation`, `## The evidence commit` `:46` |
| D6 | `:66` `Model strong` | `/po-review` `## Delegation` |
| D7 | `:92` blocked report for a failed reviewer, "A severity is never guessed" | `/po-review` `## Recording` last paragraph ("nor guess a severity"), named at `:90` |

**Kept word for word.** Check each by `grep -cF` on main and on the branch:
- `/po-execute`: the five prompt blockquotes, the `**Refusal.**` sentence, `## Report`, "The plan for <id> is not approved yet. Review it, then run /po-plan <id>.", "a person decides, given the reason", "exactly so, from your start directory, without `cd`".
- `/po-qa`: the prompt, the refusal sentence, `## The evidence commit` and `## Report` whole, "Never describe a walk the subagent did not report.", the `Dev` stop.
- `/po-review`: the prompt, the refusal sentence, `## Recording` whole, the loop-2 message, the findings-shape message, "its `Fix loop:` value plus one…(0 when there is none)", "this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034, ADR-0041)".
- `/po-drive`: `:68`, `:70`, "You transcribe it, you do not author it: no severity is yours to choose, no finding yours to soften or drop.", "A plan without that line never reaches an implementer."

## Tasks
1. [x] `method/commands/po-execute.md`.
   - `:2`: delete " by construction,".
   - `:13`: `Reads settings: \`Worktree root\`, \`Model strong\`, \`Model light\`, \`Light up to\``.
   - Replace `:17-38` by `## By hand`, then this one line: "`/po-drive` skips this section. Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` exactly so, from your start directory, without `cd`, and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`; no `AGENTS.local.md` → stop, naming `/po-setup`; no Agent tool, or a setting this command reads missing → stop, naming it. Go on only on `execute` or `fix`, or on `ship` once `/po-ship` stopped on failing checks, which `po next` cannot see. On `validate-plan`, stop with "The plan for <id> is not approved yet. Review it, then run /po-plan <id>." Any other entry, or a warning naming the story, is reported and ends the command; on `ask`, stop; a person decides, given the reason. At the end, report a new `po next` entry likewise."
   - Delete `:43-44`.
   - `:52` → "For a fix run — `po next` answered `fix`, or `execute` while the last `Ship allowed:` of `docs/reviews/<id>.md` is `no` — append:".
   - `:56` → "When `docs/designs/<id>/` holds a file, append:".
   - `:64` → "When `## Acceptance tests` of the plan names at least one file, append:".
   - Delete `:68` and `:73` with their blank lines.
   - Test: `test_words_go_down`, `test_commands_still_lint`.
2. [x] `method/commands/po-qa.md`.
   - `:2` → `description: Hands one story's surface to the qa subagent, records its report and commits the evidence alone`.
   - `:13` unchanged.
   - `:17` → "Bash serves exactly three uses, `po next` by hand, the record and the evidence commit below; any other shell command is out of bounds. Never describe a walk the subagent did not report."
   - Replace `:19-28` by `## By hand`, then: "`/po-drive` skips this section. Run `po next` and route as `## By hand` of `/po-execute` says, going on only on `qa`, or on the `ask` `QA status: blocked` once the person has settled what blocked the walk." followed, on the same line, by `:26` verbatim from "The story's surface is `screen`" to "`AGENTS.local.md`.".
   - First line under `## Delegation`, then a blank line: "Reason `QA evidence not committed` → no walk: go straight to `## The evidence commit`."
   - Delete `:35` and the first sentence of `:37`.
   - Test: `test_words_go_down`, `qa.test.sh`.
3. [x] `method/commands/po-review.md`.
   - `:2` → `description: Has the reviewer subagent judge a story in a fresh context and records its verdict`.
   - After `:11`, add `  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)`.
   - `:15` → `Reads settings: \`Target branch\`, \`Worktree root\`, \`Model strong\``.
   - Replace `:19-28` by `## By hand`, then: "`/po-drive` skips this section. Run `po next` and route as `## By hand` of `/po-execute` says, going on only on `review`, or on the `ask` `findings-shape refused` or `review without verdict` once the person has settled it. At the end, on the `ask` `Max attempts reached`: "Ship still blocked after two fix runs. Open findings: <list>. A human decides what happens next." On the `ask` `findings-shape refused`: " followed by `:49`'s quoted message verbatim, from "Review of <id> stopped:" to "no fix run is spent.", and a closing quote.
   - Add `## Fix loop`, then: "Read the previous `docs/reviews/<id>.md` if there is one: its `Fix loop:` value plus one is this review's loop number (0 when there is none). When that previous review carries `Review status: blocked` and a `Next action:` naming `/po-qa` or the `<id>: QA evidence` commit, this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034, ADR-0041)."
   - Delete the first sentence of `:35`.
   - Delete `## Outcome` (`:45-51`).
   - Test: `test_commands_still_lint`, `test_words_go_down`, `review-findings-shape.test.sh`.
4. [x] `method/commands/po-drive.md`, only these lines.
   - `:37` → "| `execute`, `fix` | the implementer, step 3 |".
   - `:38` → "| `qa` | the qa subagent, step 4 |".
   - `:39` → "| `review` | the reviewer, step 5 |".
   - `:64` → "3. `subagent_type: implementer` — the prompt `/po-execute` fixes (`method/commands/po-execute.md`), its appended sentences and model included, word for word, for each lane whose `docs/plans/<id>.md` holds `validated: yes`. A plan without that line never reaches an implementer."
   - `:65` → "4. **The QA stage**: `subagent_type: qa` — the model and the prompt `/po-qa` fixes (`method/commands/po-qa.md`), word for word, from its `## Delegation` through `## The evidence commit` (ADR-0102). Like the others, every qa of a wave leaves before any of them is waited on."
   - `:66` → "5. `subagent_type: reviewer` — the model and the prompt `/po-review` fixes (`method/commands/po-review.md`), word for word, at the `Fix loop:` its `## Fix loop` computes."
   - `:90`: "its shape check, re-ask and stops included." → "its shape check, re-ask, stops and blocked report for a failed reviewer included."
   - Delete `:92` and its blank line.
   - Test: `test_words_go_down`, `drive.test.sh`.
5. [x] Tests on `/po-execute` (each removal is a phrase whose sentence a row removes; no phrase test is added):
   - `execute.test.sh:16` (E9); `:21-29`, two whole functions (E7, V4).
   - `design-handoff.test.sh:23-24` (E13).
   - `model-routing.test.sh`:
     - `:13-18`, the helper left unused;
     - `:46`, keep only `planner designer` (D5, D6);
     - `:47-50` → `contains "$CMDS/po-stories-review.md" '\`Model strong\` missing → stop and name it.'` (Q3, V4);
     - `:58-59` (E17, E16);
     - `:102-104` (D1, D4).
   - Test: those files, focused.
6. [x] Tests on `/po-qa`:
   - `qa-drivers.test.sh`: delete `:40` and `:44`; `:48` reads `printf '%s\n' "$checks"`; `local checks line` (Q3, Q5 move out of a gate section).
   - `qa-fleet.test.sh:36-37` (D5); `:62-63` (V8, V10); `:66-69` and `:73-76` (V5, V8, V9).
   - `qa-report-returned-as-text.test.sh:39` (Q2); `:48-49`, with `local wave n` (D5).
   - Test: those files.
7. [x] Tests on `/po-review` and `/po-drive`:
   - `review-findings-shape.test.sh:84,124` (V9, now in `## By hand`);
   - `drive.test.sh:48-50` (D7).
   - Test: those files.
8. [x] Checks: `bash tests/run.sh delegating-commands-are-briefs.oracle.test.sh execute.test.sh qa.test.sh review.test.sh qa-gate.test.sh qa-drivers.test.sh qa-fleet.test.sh qa-report-returned-as-text.test.sh review-findings-shape.test.sh review-header-recorded.oracle.test.sh drive.test.sh model-routing.test.sh design-handoff.test.sh lint.test.sh drive-executes-next.oracle.test.sh defect-and-routing-paths.test.sh drive-takes-one-story.oracle.test.sh own-context-commands-are-briefs.oracle.test.sh ship-cleans-the-lane.oracle.test.sh security-findings-stay-private.oracle.test.sh record-writes-reports.test.sh overlap.test.sh`, then the full suite once through `po-run`.
   - On the draft tree, the full suite failed only on git-history checks of a copy without `.git` (`po-change-needs-a-version`).
   - Test: the suite.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `po/`, `bin/` (including `bin/po-lint`), `.claude/`, `.polype/`;
  - `method/AGENTS.md`, `method/agents/`, `method/templates/`, `method/skills/`, `method/hooks/`;
  - `method/commands/po-help.md`, `method/commands/po-ship.md`, and every other command but the four of tasks 1-4.
- `po-drive.md` changes only lines 37-39, 64-66, 90 and 92.
- `tests/delegating-commands-are-briefs.oracle.test.sh` keeps its sum `43086886 2365`. No test file is created besides it, and `tests/delegating-commands-are-briefs.test.sh` is not created.
- No phrase assertion is added or reworded, and no test outside `Owns` is edited.
- Every sentence of the kept list and every **H** message passes `grep -cF` with the same count on main and on the branch.
- No version bump: the story does not touch `po/`.

## The pivot
Each command routes by `po next` and goes on only on its own action plus the three listed cases. Ways it could be wrong:
- **`po next` decides more than the old checks.** By hand:
  - `/po-review` on a story whose record is not current now stops on `execute`;
  - `/po-qa` on a story already QA-current stops on `review`.
  
  Compare with `/po-drive <id>`, which already behaves so (`lanes.rs:243-290`).
- **`po next` misses a path the old text served.** The research found three: failed ship, blocked QA, shape stop. Compare the old preconditions line by line with `lane.rs:53-203` for any fourth.
- **Extending ADR-0120's narrow form to `/po-review`.** ADR-0120's Neutral consequence asks a new ADR only for a shell-less command. `/po-review` already holds two narrow Bash lines, so this plan takes it as no new exception. If the reviewer reads it otherwise, it is a technical choice for the person, not a fix.

## Files touched
- Commands: `method/commands/po-execute.md`, `po-qa.md`, `po-review.md`, `po-drive.md`.
- Oracle, written: `tests/delegating-commands-are-briefs.oracle.test.sh`.
- Tests edited: `tests/execute.test.sh`, `design-handoff.test.sh`, `model-routing.test.sh`, `qa-drivers.test.sh`, `qa-fleet.test.sh`, `qa-report-returned-as-text.test.sh`, `review-findings-shape.test.sh`, `drive.test.sh`.
- The story's research and plan.

## Test strategy
Two oracle tests, `test_commands_still_lint` and `test_words_go_down`, within `Test budget` 25. The other test changes remove phrase assertions whose sentence goes, as the owner's rule of 2026-11-13 asks. The behaviour of each stop that moves to `po next` is already tested outside `Owns`, by `tests/driver-next-action.oracle.test.sh` and `tests/fixtures/driver-cases/*.cases`. Visual checks: none.

Neighbours checked, none stale:
- In `Owns`: `po-help.md:34-36`.
- Outside `Owns`:
  - `po-ship.md:35,42`, served by E's `ship` case;
  - `method/AGENTS.md:87,94`;
  - `README.md:38-45`;
  - `docs/parite-killer-saas.md` D05, D08;
  - `docs/interface-agent.md:271`;
  - `bin/po-eval:94`, the prompt line it reads stays.

## Done when
- The oracle and the focused files pass, and the full suite passes through `po-run`.
- `bin/po-lint` is clean.
- The reviewer checks `## Removed sentences` and the kept list against `git diff main`.
- The implementer makes one commit, with the research and the plan.
