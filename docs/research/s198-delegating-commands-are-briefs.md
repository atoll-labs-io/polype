# Research — s198-delegating-commands-are-briefs

[Story](../stories.md)

## Structuring facts
- **False assumption: "stop if the returned action is not its own".** Three paths a person takes today reach one of these commands while `po next` says something else, and would become dead ends:
  - `/po-ship` sends a failed ship back to "`/po-execute <id>` as a fix run" (`method/commands/po-ship.md:35,42`), while `po next` still answers `ship` (stage `Ship` once `ship-allowed` passes, `po/src/context/lanes.rs:273-275`). `po-drive.md:44` keeps this rule for itself "since `po` cannot see it".
  - After a QA walk returns `QA status: blocked`, `po next` answers `ask` "QA status: blocked" for as long as that is the report's last status (`po/src/next/lane.rs:108-109`, `lanes.rs:332-334`). Only a new walk clears it, and today `/po-qa` is how a person starts one.
  - A review blocked by the findings shape answers `ask` "findings-shape refused" (`lane.rs:194-196`), a review without a verdict `ask` "review without verdict" (`lane.rs:162`). Only a new review block clears either.
  
  The story is corrected in the plan: each command also goes on in exactly these cases, and no others.
- The story's figures are stale. The files have 73, 50 and 51 lines, not 100+, and the cited passages sit at `po-execute.md:21-45`, `po-qa.md:21-28,39-46` and `po-review.md:23-28,37-51`. The three hold 847 + 712 + 1 145 = **2 704** words (`LC_ALL=C wc -w`, bec755c), not 2 707.
- The kept text weighs about 1 580 words: the prompts the driver copies word for word, the model refusals, `/po-review`'s `## Recording`, `/po-qa`'s `## The evidence commit` and the two `## Report` sections. A draft that keeps them all and every person-facing stop word for word measures 584 + 543 + 873 = **2 000**, which is within 2 004 = 2 704 − 700 (plan, `## Word arithmetic`).
- `po next` only reads, and `/po-review` has no bare Bash (`method/commands/po-review.md:4-11`). Running it there needs one more narrow permission of exactly ADR-0120's form. ADR-0120 restricts only commands "sans shell" and asks for a new ADR only for a new exception among them (`docs/decisions/ADR-0120-…md`, Consequences, Neutral). `/po-review` already declares two narrow Bash lines, and `/po-qa` has bare Bash (`po-qa.md:9`), so neither is such an exception.

## Story
`/po-execute`, `/po-qa` and `/po-review` shrink to: run `po next` by hand, brief the subagent, record its answer. The prompt and the recording are written once, and `/po-drive` points to them.

| Criterion | Kind |
| --- | --- |
| `routing_is_said_once` | model-read |
| `drive_and_commands_share_one_text` | model-read |
| `nothing_is_lost` | model-read |
| `commands_still_lint` | script-read: `bin/po-lint` passes, and ADR-0120's narrow permission holds |
| `words_go_down` | script-read: ≥ 700 fewer words in the three, and no touched `method/` file grows |

## Current code
- **`method/commands/po-execute.md`** (847 words).
  - `:17` no Write or Edit.
  - `:19` Agent tool check.
  - `## Preconditions` `:21-38`:
    - setup, id, worktree registration through the shared git directory (`:24`);
    - plan exists, `validated: yes` with its message (`:26`);
    - `:27-35`: on a review whose last verdict is `Ship allowed: no`, `po next` and a routing table;
    - design glob (`:36`), model settings (`:37`), oracle (`:38`).
  - `## Model` `:40-45`, `## Delegation` `:47-68` (prompt and four appended sentences), `## Report` `:70-73`.
- **`method/commands/po-qa.md`** (712 words).
  - `:17` Bash for two uses.
  - `## Preconditions` `:21-28`: setup, id, worktree, no `docs/verif`, `Dev` `—` on a screen, nothing to check, `Model strong`.
  - `## Delegation` `:30-37`, `## The evidence commit` `:39-46`, `## Report` `:48-50`.
- **`method/commands/po-review.md`** (1 145 words).
  - `:19` Law 2 intro.
  - `## Preconditions` `:23-28`: the `Fix loop:` count `:28`, with the QA returns and the "third blocked review" stop.
  - `## Delegation` `:30-35`, `## Recording` `:37-44` (shape check, re-ask, blocked reports), `## Outcome` `:46-51`, five messages.
- **`method/commands/po-drive.md`** (2 413 words). It restates parts of the three:
  - `:37` the fix-run sentence and the model rule;
  - `:38` the QA resume;
  - `:39` the fix loop;
  - `:64-66` the model per role, `po record qa`, the evidence commit, the no-`QA status:` stop;
  - `:92` the blocked report for a failed reviewer.
  
  It points to them at `:64-66` ("the prompt `/po-X` fixes … word for word") and at `:90` (`## Recording`).
- **`method/commands/po-help.md:34-36`** describes the three in one line each. Nothing there goes stale.

## Attachment points
- One `## By hand` section per command. It holds only what a person running the command needs: a heading-scoped section that `/po-drive` skips (#423). Its full frame, with the exact command line, sits in `/po-execute`; `/po-qa` and `/po-review` route "as `## By hand` of `/po-execute` says" and add their own actions.
- Driver-needed lines stay out of `## By hand`:
  - the fix-run, design and oracle conditions, now inside `/po-execute` `## Delegation`;
  - the QA resume, the first line of `/po-qa` `## Delegation`;
  - the loop count, a new `/po-review` `## Fix loop`.
- `po-drive.md:37-39,64-66,90-92` become pointers to those sections.

## Verified interfaces
- `po next` entries carry `story`, `action`, `reason`, `track`, and no path (`po/src/next/mod.rs:50-56`). It exits 2 only with neither `AGENTS.local.md` nor `.polype/version` (`mod.rs:79-85`).
- A lane exists only for a worktree at `<Worktree root><id>` on `story/<id>`. Anything else is warning `orphan-worktree` (`lanes.rs:216-236`). With no lane, the story is `plan`/`ready` or `held` (`mod.rs:93-94`).
- Stage order: no plan → `Research`/`Design`/`Plan`; `plan-validated` refuses → `Plan`; `ship-allowed` passes → `Ship`; `verif-current` refuses → `Execute`; goes to QA and `qa-current` refuses → `Qa`; else `Review` (`lanes.rs:243-290`).
- Actions:
  - `execute` "verif-current refuses" (`lane.rs:106`);
  - `qa` "QA evidence not committed" or "qa-current refuses" (`lane.rs:110-113`);
  - `review` "no review", "ship-allowed refuses", "review judged earlier code", "review waited for QA" (`lane.rs:158-192`);
  - `fix` "Ship allowed: no" (`lane.rs:201`);
  - `ask` "Max attempts reached" when `Fix loop` ≥ `Max attempts`. A review blocked on QA does not count (`lane.rs:187-200`, `lanes.rs:336-350`).
  - `validate-plan` "plan-validated refuses" under `human` (`lane.rs:100`).
- `qa.md:30-31` stops on a surface `—` and on `screen` with `Dev` `—`. The template rows `templates/agents-local.md:71-73` define `—` for `Model strong`, `Model light` and `Light up to`.
- `bin/po-lint:123,146-147`: the ADR-0120 exception keys on `commands/po-execute.md` and the description phrase "cannot edit files or run a shell". `po-review.md`'s description lacks it, so a po next line there trips no rule. The fail-closed rule reads only `## Checks|Preconditions|Step 0` (`bin/po-lint:175`).
- `bin/po-eval:94` reads the line `^> Story <id>\.` of `po-review.md`. The prompt stays.

## Traps
- **Phrase tests that fall.** On a draft tree these fail, all in `Owns` (list in the plan):
  - `execute.test.sh:16,21-29`;
  - `qa-drivers.test.sh:40,44,48`;
  - `qa-fleet.test.sh:36-37,62-63,66-69,73-76`;
  - `qa-report-returned-as-text.test.sh:39,48-49`;
  - `review-findings-shape.test.sh:84,124`;
  - `drive.test.sh:48-50`;
  - `model-routing.test.sh:13-18,46,48-50,58-59,102-104`;
  - `design-handoff.test.sh:23-24`.
- **Phrases that must stay**, read by tests or scripts:
  - prompts: `defect-and-routing-paths.test.sh:39-43` (outside `Owns`), `planner-writes-the-oracle.test.sh:72`, `design-handoff.test.sh:25`, `bin/po-eval:94`;
  - `review.test.sh:170-177,195` and `review-header-recorded.oracle.test.sh:23`;
  - `review-findings-shape.test.sh:74-83,118-123` (`## Recording`);
  - `qa-report-returned-as-text.test.sh:27,33-36,54-56`;
  - `qa.test.sh:106-107` (the `Dev` stop, "This command never authors a report");
  - `qa-gate.test.sh:104-108`;
  - `model-routing.test.sh:42-43,54-61,93-101`;
  - `drive.test.sh:24-30,42-44`, `qa-fleet.test.sh:29-39,61,78-83`;
  - the ADR-0120 tool sets in `drive-executes-next.oracle.test.sh:42-64` and `design-handoff.test.sh:27-29`.
- **Word caps outside `Owns`.** All of them hold on the draft:
  - `po-execute.md` ≤ 850 (`drive-takes-one-story.oracle.test.sh:11`, `security-findings-stay-private.oracle.test.sh:161`);
  - `po-review.md` ≤ 1 147;
  - `po-drive.md` ≤ 2 441 (`own-context-commands-are-briefs.oracle.test.sh:9`) and ≤ 2 449 (`ship-cleans-the-lane.oracle.test.sh:221`).
- `po-gate floor-guard` will flag the dropped assertions. The reviewer reads them against the plan's table.
- This story does not touch `po/`, so no version goes up.

## Open questions
- A fix run sent by a failed ship. Today `/po-execute` runs it without the fix-run sentence: the review passed, so there are no findings in `docs/reviews/<id>.md` to work from. The plan keeps that behaviour. Telling the implementer which checks failed is a gap of `/po-ship`, outside `Owns`.

## Complexity
3 → 4. The commands are prose, but every removed line needs a check that `po next` reaches every path it covered (three did not), and the human messages must survive word for word inside a 700-word cut that leaves a 4-word margin.

## Split
—
