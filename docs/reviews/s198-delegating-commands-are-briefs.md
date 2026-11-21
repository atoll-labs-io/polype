# Review — s198-delegating-commands-are-briefs

[Story](../stories.md) · [Plan](../plans/s198-delegating-commands-are-briefs.md) · [Verification](../verif/s198-delegating-commands-are-briefs.md)

Method version: 0.11.0
Recorded: 2026-11-21T01:45:35+01:00

Diff reviewed: `git diff main...story/s198-delegating-commands-are-briefs`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: acd4387af356a355e474fc117db3b05062d543e4

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s198-delegating-commands-are-briefs`. Each path was checked against the story's `Owns`.
- [x] Every path is inside `Owns`. The four commands and the eight edited test files are listed there, and so is the oracle. Research, plan and verification are the story's own evidence. `bin/po-lint` and `po-help.md` are untouched.
- [x] Nothing is outside `Owns`.
- [x] No other running story claims these paths. The only other worktree is `framing-m22` on `fix/qa-deadline-wording`, and it is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0, so the record is reused. The unit suite `bash tests/run.sh` exited 0 on tree `2274993…`, whose code outside `docs/` matches `Tree: ad2d6c7…`. The project has no Typecheck (`—`). "Not proven here" says that the three model-read criteria are left to this review.
- [x] `po-gate qa-current` is not required. `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–8 are all present, and the diff holds nothing outside them.
- [x] Run interdicts were checked one by one:
  - `po/`, `bin/`, `.claude/`, `.polype/`, `method/AGENTS.md`, agents, templates, skills, hooks, `po-help.md` and `po-ship.md` have empty diffs.
  - `po-drive.md` changes only lines 37–39, 64–66, 90 and 92.
  - The oracle sum is intact (`po-gate oracle-intact` exits 0), and no `delegating-commands-are-briefs.test.sh` was created.
  - No phrase assertion was added or reworded, and there is no version bump.
- [x] Track raised from flow to full: justified. Complexity 3 at threshold 3 would give flow. But the contract is a 49-row table across four commands and eight test files, and a separate research context paid for itself: the research is what found the three by-hand cases. No line records the reason for the raise. That is the lead's decisions log to fill, not this diff.

## References
- [x] I opened each "lives in" target of the 49 rows:
  - routing: `lane.rs:53-203`, `lanes.rs:243-350`
  - stops and messages: `qa.md:31` (Dev stop), `templates/agents-local.md:71-73`
  - drive and reports: `po-drive.md:24-30,64-66,90,109`, `po-qa.md` evidence commit, `po-review.md` `## Recording` and its last paragraph
- [x] Every row holds on the paths it names, with the two exceptions in Findings: E16/Q8/V7 (the `—` model rule) and the plan's claim that only three by-hand cases exist.
- [x] Reverse read: I read every removed sentence of the three commands and of `po-drive.md`.
  - Most have a row.
  - The rest are "why" sentences (`po-review.md:19` "worst placed to see its mistakes"; `po-drive.md:92` "the one report you compose yourself"). Law 2, Law 6 and the kept "You transcribe it…" still carry their force.
  - The person-facing "commit it alone: git commit…" of the old `## Outcome` is now done by `/po-qa` itself, through `QA evidence not committed`, so the person no longer does it by hand.
- [x] Kept text: I ran `grep -cF` on `git show main:` and on the branch for 38 sentences. All counted 1 and 1:
  - the five `/po-execute` prompts, Rule, Complexity fallback, Refusal, `## Report`, the not-approved message, "a person decides, given the reason", "exactly so, from your start directory, without `cd`"
  - the `/po-qa` prompt, refusal, Dev stop, evidence-commit steps and closing, `## Report`
  - the `/po-review` prompt and closing line, refusal, loop-2 message, findings-shape message, the two Fix loop sentences, `--composed`, the re-ask, "Any command that records…", the failed-reviewer paragraph
  - in `po-drive`: "You transcribe it…", "A plan without that line…", the model refusal line, "One rule stays yours…"

## Rules
- [x] `po-review.md:12` adds `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)`. It is that verb alone, with no `:*` and no other argument, and nothing wider was granted. Whether it needs an ADR is pending with the owner and is not graded here.
- [x] Checked the routing against `lane.rs`:
  - `/po-execute` goes on for `execute`/`fix`, plus `ship` after a failed ship.
  - `/po-qa` goes on for `qa` (resume included), plus `ask "QA status: blocked"`.
  - `/po-review` goes on for `review`, plus `ask "findings-shape refused"` and `ask "review without verdict"`.
  - These match `lane.rs:110-113,177-201`, but one case is missing (see Findings).
- [x] The stricter by-hand behaviour is accepted. `/po-review` now stops on `execute` when the record is stale, and `/po-qa` stops on `review` when QA is current. Both match `/po-drive <id>` (`lanes.rs:270-289`) and lose no work.
- [x] #423 trap: the driver needs nothing that sits under any `## By hand`.
  - `/po-qa`'s Dev stop is repeated at `qa.md:31` for the driver's runs.
  - The fix-run condition, the QA resume, the Fix loop and the failed-reviewer report all sit under `## Delegation`, `## Fix loop` or `## Recording`, which `po-drive.md:64-66,90` names. Every named section exists.

## Tests
- Oracle: `po-gate oracle-intact s198-delegating-commands-are-briefs` → exit 0
- [x] Floor: `po-gate floor-guard s198-delegating-commands-are-briefs main` exits 0.
- [x] Each removed phrase assertion falls with a row:
  - `execute.test.sh`: E9, and the two functions → E7 and V4
  - `design-handoff`: E13
  - `model-routing`: E16, E17, Q3, V4, D1, D4–D6
  - `qa-drivers`: Q5
  - `qa-fleet`: D5, V5, V8, V10
  - `qa-report-returned-as-text`: Q2, D5
  - `review-findings-shape`: V9
  - `drive`: D7

  The routing behaviour those assertions guarded is held by `tests/fixtures/driver-cases/{resuming,verdict,a-wave,ready-set}.cases`, `driver-next-action*.test.sh` and the `plan-validated` gate tests. Those cover `QA evidence not committed`, `review waited for QA`, `findings-shape refused`, `Max attempts reached`, `QA status: blocked`, `review without verdict`, `verif-current refuses` and `plan-validated refuses`. The `—` model rule assertion has no replacement (see Findings).
- [x] Two oracle tests, within `Test budget` 25.
- [x] Bite 1: changed `po-review.md`'s `po" next)` to `po" next:*)`. `commands_still_lint` failed (1 test), and `words_go_down` stayed ok. Undone; `git diff --exit-code` is clean.
- [x] Bite 2: added `Bash(… po" next:*)` to `po-execute.md`. `bin/po-lint` reported 1 breach (`says it cannot edit files or run a shell but declares …`), so the ADR-0120 lint still bites. Undone; clean.
- [x] Bite 3: weakened `po-execute.md:18` "no `AGENTS.local.md` → stop, naming `/po-setup`" to "→ name `/po-setup`". `bin/po-lint` passed with 0 breaches, so fail-closed no longer reads `## By hand` (see Findings). Undone; clean.
- [x] Word counts:

  | File | Before | After |
  | --- | --- | --- |
  | `po-execute.md` | 847 | 584 |
  | `po-qa.md` | 712 | 543 |
  | `po-review.md` | 1 145 | 873 |
  | The three | 2 704 | 2 000 (−704) |
  | `po-drive.md` | 2 413 | 2 266 |
  | `po-help.md` | 718 | 718 |

## Neighbours
- [x] Checked `po-ship.md:35,42` ("`/po-execute <id>` as a fix run"), `method/AGENTS.md:87,94`, `README.md:45` and `po-help.md:34-36`. None is made false by the diff.
- [x] Commands built in s197 (`po-plan`, `po-research`, `po-design`) use "A subagent skips this paragraph." where these use "`/po-drive` skips this section." The wording differs but nothing breaks.

## Lenses
Lenses run: none. No path or content trigger: the diff is method prose and bash tests. The one permission line was checked under Rules.

## Findings
- major — method/commands/po-review.md:21 — `ask "QA evidence committed twice"` is a fourth by-hand dead end, and the plan says only three exist.
  - `lane.rs:187-191` returns this `ask` when two `<id>: QA evidence` commits sit at the tip after a review blocked on QA. It is tested at `verdict.cases:18-27`.
  - `/po-review` goes on only on `review`, `findings-shape refused` or `review without verdict`, so it now stops on this ask. `/po-qa` and `/po-execute` stop on it too.
  - `po next` keeps returning the ask until a new review is recorded, since the git history does not change. A person who has settled it has no command left that moves the lane.
  - On main, `/po-review` by hand ran in this state.
  - Fix: add this reason to the go-on list of `po-review.md:21`.
- major — method/commands/po-execute.md:21 — the `—` model rule was deleted from all three commands (rows E16, Q8, V7, also `po-qa.md:25`, `po-review.md:27`), and it does not live where the table says.
  - The deleted rule: "a model setting at `—` passes no `model` at all", and "`Light up to: —` means the implementer never takes `Model light`".
  - The table points to `templates/agents-local.md:71-73`. That file defines the settings for `/po-setup`; no command reads it at run time.
  - `AGENTS.md`, "Reading settings", leaves `—` to "carries on without it or stops, as its own file says", and these files no longer say.
  - The kept refusal "never retry with another model or with none" now pushes a model that was handed `—` toward a stop.
  - Only `po-execute.md:47` ("`session` when `—` passed none") still hints at the rule. `po-intake.md:65` and `po-stories-review.md:35` still state it in full, so the method now says it in some places and not others.
  - The model-routing assertion that held it was removed with no replacement.
- minor — method/commands/po-execute.md:18 — `bin/po-lint`'s fail-closed rule (`bin/po-lint:175`) reads only `## Checks|Preconditions|Step 0`. It no longer covers the stop lines that moved into `## By hand`: `po`/exit 2, `AGENTS.local.md`, Agent tool, missing setting, and `/po-qa`'s `Dev` stop.
  - Bite 3 shows that a stop weakened to a bare pointer passes the lint.
  - Every arrow says stop today, and main already covered these files only in part. But the plan does not name this loss of coverage, and s197's three `## By hand` commands share it.
  - Fix: add `By hand` to the section regex, in `Owns` of a later story.

## Not verified
- No `po-eval` control arm was run for the three model-read criteria (#208): `routing_is_said_once`, `drive_and_commands_share_one_text`, `nothing_is_lost`. A person should run `/po-qa` by hand on an `execute` entry and check it stops, and run a driver on a `fix` entry and check it appends the fix-run sentence and the model.
- I judged the by-hand routing against `lane.rs` by reading only, and did not run `po next` on a live lane. A person should replay `verdict.cases:18-27` and then try `/po-review` by hand.
- The full suite was not rerun (record reused, as the brief asks).
- A blocked QA walk whose cause is in the code: `/po-execute` stops on `ask "QA status: blocked"`, and only `/po-qa` goes on. On main no command handled this path either, so it is not a regression of this diff. It may deserve a look when QA is next touched.
- A fix run sent by a failed ship: it deserves its own issue (it belongs to `/po-ship`). On `ship` the last `Ship allowed:` is `yes`, so `## Delegation` appends no fix-run sentence. The implementer gets the plain prompt, every task ticked and a current record, with nothing naming the failed check.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-21T02:03:38+01:00

Diff reviewed: `git diff main...story/s198-delegating-commands-are-briefs`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 9d4f825893394b47f673bde4276ab671a34dec24

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s198-delegating-commands-are-briefs` (19 paths). Each path was held against the story's `Owns` (`docs/stories.md:3231`).
- [x] Every path is inside `Owns`. That covers the four commands, `bin/po-lint` (newly touched by the fix run), the oracle and the nine edited test files. Research, plan, verif and review are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] No other running story claims these paths. `git worktree list` shows only `framing-m22` on `fix/qa-deadline-wording`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` → exit 0, so the record is reused.
  - `Tree: 247b296…`. Unit suite `bash tests/run.sh` exited 0 on `54551af…` (fix run).
  - Merge 222a16c brought only `docs/stories.md` and `docs/decisions-log.md`, so the code is unchanged.
  - The project has no Typecheck (`—`).
  - "Not proven here" leaves the three model-read criteria, the `—` rule in `/po-qa` and `/po-review`, and the new `/po-review` go-on case to this review.
- [x] `po-gate qa-current` is not required: `QA stage: —` sends no story to QA.

## Plan
- [x] Fix run 6193d95 against the three findings of loop 0:
  - **Major 1, `QA evidence committed twice`: closed.** `po-review.md:21` now goes on for it, and the plan records it (line 26).
    - I held every `act(...)` of `po/src/next/lane.rs` against the three commands' `## By hand`:
      - `execute`/`fix`, and `ship` after a failed ship → `/po-execute`
      - `qa` (both reasons) and `ask QA status: blocked` → `/po-qa`
      - `review` (`no review`, `ship-allowed refuses`, `review judged earlier code`, `review waited for QA`) and `ask review without verdict` / `findings-shape refused` / `QA evidence committed twice` → `/po-review`
      - `plan`, `design`, `validate-plan` → s197's commands
      - `wait`, plus `ship` (`landed` and `ship-allowed passes`) → `/po-ship`
      - every `setting unreadable:*`, `no po-gate`, `no complexity`, `no docs/design-system.md`, `Design source unset` → the person fixes the file, and `po next` moves on its own
      - `Root cause: not found` and `Technical choice: waiting for a human` → the plan stage (s197)
    - After the new review is recorded on `QA evidence committed twice`, its last `Review status:` is no longer `blocked`, so `lane.rs:185-193` stops returning the ask.
    - Two stops remain for a person: `Max attempts reached` (`lane.rs:200`) and `pull request closed` (`lane.rs:209`). Neither is new. Main's `/po-review` already said "A third blocked review in a row is not requested: stop and hand the open findings to a human", main's `/po-execute` stopped on every `ask`, and `pull request closed` belongs to `/po-ship`.
    - No dead end remains.
  - **Major 2, the `—` model rule: closed.**
    - `po-execute.md:23` restores main's bullet word for word (`grep -cF` 1/1).
    - `po-qa.md:29` and `po-review.md:31` hold "`Model strong` at `—` passes no `model` at all" (1/1 against main). Only main's tail ("the qa subagent / the reviewer runs on the session's model") is gone.
    - The rule keeps its force. `method/agents/qa.md` and `method/agents/reviewer.md` declare `model: inherit`, so passing no `model` already means the session's model. The refusal "never retry with another model or with none" fires only once the Agent tool rejects a name, and with `—` no name is passed, so the two no longer clash.
    - `po-intake.md:65` uses the same short form.
  - **Minor, `## By hand` not linted: closed.** `bin/po-lint:176` adds `By hand` to the gate sections. See Tests for the bite proof and the departure.
- [x] The fix run touched only `bin/po-lint`, the three commands, the oracle, `lint.test.sh` and `model-routing.test.sh`. `po/`, `.claude/`, `.polype/`, `po-drive.md` and `po-help.md` are untouched by it.
- [x] No version bump.

## References
- [x] Kept sentences, by `grep -cF` on `git show main:` and on the branch. All count 1 and 1:
  - the seven prompt blockquotes
  - the `/po-execute` Refusal, `—` bullet, not-approved message, "a person decides, given the reason" and "exactly so, from your start directory, without `cd`"
  - the `/po-qa` refusal, "Never describe a walk…" and the `Dev` stop
  - the `/po-review` refusal, loop-2 message, findings-shape tail and both Fix loop sentences
  - in `po-drive`: "You transcribe it…" and "A plan without that line…"
- [x] Whole sections compared with main:
  - `/po-qa` `## The evidence commit` and `## Report` are identical.
  - `/po-review` `## Recording` differs only by a trailing blank line.
  - `/po-execute` `## Report` loses only "Finish with: …", which is row E19 and was already accepted at loop 0.

## Rules
- [x] `AGENTS.md` conventions are respected: the method stays in English and nothing installed was edited.
- [x] The `po next` permission of `/po-review` is unchanged since loop 0. Whether it needs an ADR is pending with the owner and is not graded here.

## Tests
- Oracle: `po-gate oracle-intact s198-delegating-commands-are-briefs` → exit 0
  tests/delegating-commands-are-briefs.oracle.test.sh: changed, logged in ## Oracle changes — `test_words_go_down`: the three commands' cap goes from `THREE_BEFORE - 700` (2 004) to `THREE_BEFORE - 650` (2 054), its failure message saying 650; nothing else changes — Fix run, 2026-11-21: the lead lowered the word criterion to 2 054 at most through a framing pull request on main, to make room for the two majors of the review only, the `ask` `QA evidence committed twice` in `/po-review` `## By hand` and the `—` model rule put back in the three commands
  po-gate: 1 logged oracle change(s) of s198-delegating-commands-are-briefs to judge
- Oracle: `po-gate oracle-intact s198-delegating-commands-are-briefs` → exit 0, with 1 logged change to judge.
  - The change: `THREE_BEFORE - 700` → `THREE_BEFORE - 650`, message included.
  - Main's reworded criterion (`docs/stories.md:3238`) reads "au moins 650 mots de moins qu'avant (2 704 mesurés, soit 2 054 au plus)". `THREE_BEFORE=2704`, so the test caps at exactly 2 054.
  - It follows the criterion, which was lowered through framing, and does not weaken it.
- [x] Floor: `po-gate floor-guard s198-delegating-commands-are-briefs main` → exit 0.
- [x] The `model-routing.test.sh` assertion the fix run put back is identical to main's (line 59 there), so it is not a new phrase test.
- [x] Within `Test budget` 25: the fix run adds no test function.
- [x] Word counts (`LC_ALL=C wc -w`):

  | File | Words |
  | --- | --- |
  | `po-execute.md` | 614 |
  | `po-qa.md` | 552 |
  | `po-review.md` | 886 |
  | The three | 2 052, cap 2 054 |
  | `po-drive.md` | 2 266, limit 2 413 |
  | `po-help.md` | 718, limit 718 |

- [x] Lint: `bin/po-lint method` → no breach in 25 files. `bash tests/run.sh lint.test.sh` → 6 passed.
- [x] Bite A: removed `|By hand` from `bin/po-lint:176`. `lint_checks_fail_closed_rules_have_a_stop` failed (1 test). Undone; `git diff --exit-code` is clean.
- [x] Each of the five new mutations, applied alone to a temp copy of `method/`, gave these fail-closed reports:

  | Mutation | Branch lint | Main's lint | Branch lint without the cut |
  | --- | --- | --- | --- |
  | po-execute | 1 | 0 | 1 |
  | po-research | 1 | 0 | 0 |
  | po-plan | 1 | 0 | 0 |
  | po-design | 1 | 0 | 0 |
  | po-qa | 1 | 0 | 1 |

  - All five bite.
  - Three of them need the clause cut: there the old rule let a later "stop" on the line vouch for the weakened arrow.
- [x] The fail-closed rule has not gone blind. The cut only shortens the text that is searched, so inside the old sections every arrow is judged at least as strictly as before, and `## By hand` is added. I probed a synthetic `## By hand` and `## Preconditions`:
  - two arrows on one line, with the stop on the second (`→ name X; no Y → stop`): flagged on the first, as it should be
  - `→ stop, naming X; no Y → name it`: flagged
  - `→ stop; no Y → stop`: clean
  - `→ name it, then stop`: clean
- [x] `/po-review`'s `## By hand` holds no arrow of its own. Its two arrows sit in `## Recording`, outside the gate sections as on main, and its routing defers to `/po-execute`'s linted line. A weakening written into `/po-review`'s `## By hand` therefore stays invisible to the lint.

## Neighbours
- [x] `po-drive.md:64-66,90,109` still names `## Delegation`, `## The evidence commit`, `## Fix loop` and `## Recording`, and `session` when `—` passed none. The fix run changed none of them, and all are still true.
- [x] The new lint scope also covers s197's `po-research.md:19`, `po-plan.md:20` and `po-design.md:13`. They lint clean.

## Lenses
Lenses run: none. The diff is method prose, a bash lint and bash tests, and no path or content trigger matches.

## Findings
- minor — bin/po-lint:181 — the new clause cut also flags real stops, and the plan does not record it.
  - The cut at the first `;` or `. ` turns some genuine stops into false positives: `→ name X; stop.`, `→ say so. Stop.`, `→ e.g. stop now`. Each was probed, and each is flagged now while main's lint passed it.
  - This fails safe: the author only has to move the stop first, and nothing in `method/` trips it today.
  - The departure is named only in commit message 6193d95. The plan's fix-run note (line 26) covers only the fourth `ask` and says nothing of the lint change or the cut.

## Not verified
- No `po-eval` control arm was run for the three model-read criteria, `/po-qa`'s and `/po-review`'s `—` sentence, or the new `/po-review` go-on case. A person should replay `tests/fixtures/driver-cases/verdict.cases:18-27`, then run `/po-review` by hand and check that it dispatches.
- Lane routing was judged by reading `lane.rs`; no `po next` was run on a live lane.
- The full suite was not rerun: the record was reused as the gate allows, and memory is tight. Only `lint.test.sh` was run.
- The `/po-review` `po next` permission ADR question is left to the owner.

Max severity: minor
Ship allowed: yes
