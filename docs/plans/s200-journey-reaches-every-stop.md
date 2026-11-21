---
validated: yes
---
# Plan — s200-journey-reaches-every-stop

[Story](../stories.md) · [Research](../research/s200-journey-reaches-every-stop.md)

Branch `story/s200-journey-reaches-every-stop`. Read `docs/research/s200-journey-reaches-every-stop.md` first; this plan builds on it without repeating it.

## Story
s199's journey learns the rest of the automaton:
- the short track;
- a story with a screen, through `design` and `qa`;
- a refused review, through its fix runs, up to `Max attempts`;
- a decision of the inbox;
- a human merge;
- every `ask` reason that `po/src/next/` can return. There are 17 distinct ones; the story's notes missed four (research, first fact).

All six criteria are read by scripts (`po`, `po-gate`, the journey), so each one gets an oracle test. `docs/harnais.md` is prose for people and gets no test. Nothing outside `Owns` changes, and `po/` does not change.

Track raised from `flow` to `full`: the story needs ten tasks (more than about six), and its complexity rises to 4.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Projects, answers, loop, gates | `tests/journey/journey.sh` and `answers/plain/` (s199), extended | — first rung |
| Forge reads `pulls?head=` and `pr close` | the s199 double `tests/journey/doubles/gh`, extended | — first rung |
| Clearing git's location variables (#432) | `git rev-parse --local-env-vars` (the platform) | A hand-written list would miss `GIT_COMMON_DIR` and the variables git adds later. |
| The QA report, the review report, the blocked report | `po record qa`, `po record review`, `po record review --composed` | — the scripts the method runs, so nothing is written by hand |
| The decision | `po inbox add`, `po answer`, `po inbox consume`, on the throwaway project's own inbox | — |
| Reading the ask reasons | `grep -o` over `po/src/next/*.rs`, checked against a count of `"ask"` tokens | `po` lists no reasons. `docs/interface-agent.md` is prose, and copying the list into the test is what the story forbids. |
| The stop journeys | new file `tests/journey/stops.sh`, one `stop_<name>` function per route | No file walks these routes today. The fixtures of `tests/driver-next-action.oracle.test.sh` write gate files by hand. |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/journey-reaches-every-stop.oracle.test.sh` | `1224395356 11810` |

| Criterion | Test |
| --- | --- |
| `short_track_lands` | `test_short_track_lands` |
| `screen_story_goes_through_design_and_qa` | `test_screen_story_goes_through_design_and_qa` |
| `blocked_review_loops_then_asks` | `test_blocked_review_loops_then_asks` |
| `pending_decision_holds_the_lane` | `test_pending_decision_holds_the_lane` |
| `human_confirmation_waits_for_the_merge` | `test_human_confirmation_waits_for_the_merge` |
| `every_ask_reason_is_reached` | `test_every_ask_reason_is_reached` |

## The interface the oracle fixes
Everything in s199's interface (`docs/plans/s199-…md`) stays: its functions, its variables and its stop messages. The additions follow.

**Changed behaviour.**
- `journey_init` also unsets `JOURNEY_SETUP` and every name `git rev-parse --local-env-vars` prints (#432).
- `journey_po_next` runs `"$PO" next --remote`, as `/po-drive` does (`po-drive.md:30`).
- `journey_snapshot [<name>]` and `journey_restore [<name>]`:
  - the default name keeps `$J/snapshot`;
  - both also save and restore `$J/prs`;
  - restoring empties `$J/count`, never `$J/asks`.

**Projects and stories.**
- `journey_kind <local|screen|pr-human>`. The first call per journey folder removes any `$R`, `$ORIGIN` and `$J/prs`, builds the kind and snapshots it under `kind.<name>`. Every later call restores that snapshot and empties `$J/bound`. The kinds:
  - `local` = `journey_project local`;
  - `screen` = `local` + `QA stage: screens` + `Design source: internal`;
  - `pr-human` = `journey_project pr` + `Ship confirmation: human (chosen)`.
- `journey_setting <name> <value>` rewrites the line `<name>:` of `$R/AGENTS.local.md` to exactly `<name>: <value>`. It commits on main and pushes under pr (`JOURNEY_SETUP=1`). No such line → fail.
- `journey_story_set <id> <field> <value>` sets `- **<field>** : <value>` in the story's block, or removes that line when the value is `-`. It commits and pushes the same way.
- `journey_answers <id> <dir> [<dir>…]`: a file is taken from the first folder that holds it.

**Answers.**
- `<file>.<n>` stands in for `<file>` on the n-th application of an action to a story, for n ≥ 2. The counts live under `$J/count/`.
- Placeholders:
  - `@N@` is that count;
  - `@LOOP@` is the Fix loop of `po-review.md:24`;
  - `@TREE@` is `story/<id>^{tree}` for review, qa and record.

**Logs.** New lines:
- `asked<TAB><id><TAB><decision id>`;
- `byhand<TAB><id><TAB><action>`;
- `pr-waiting<TAB><id><TAB><url>`.

Every entry of a wave is logged before the warning stop. Every `ask` entry also appends its reason to `$J/asks`.

**Functions.**
- `journey_by_hand <id> <action>` applies that action's answer once, outside `po next`: the person's `/po-qa` after `QA status: blocked` is settled, or `/po-ship` after a merge (`po-ship.md:41`). It returns 0 when the answer applied, and 1 on a stop, which it logs.
- `journey_asks` prints the reasons reached since `journey_init`, sorted and unique.
- `journey_ask_reasons <dir>` prints the literal reasons of `act("ask", "<reason>")` in `<dir>/*.rs`, sorted and unique. It returns 1 when the count of `"ask"` tokens differs from the count of those literal calls. Each `<file>:<line>` holding a `"ask"` it could not read then goes to stderr.
- `journey_unreached <dir>` prints each reason of `journey_ask_reasons <dir>` missing from `journey_asks`. It returns 1 when there is any, or when the reader fails.
- Overridable step: `journey_record_blocked <id> <fix loop> <tree> <cause> <next action>`.
- `journey_record_review` now returns 1 on `findings-shape` and 2 on `findings-shape-unrunnable`. Both reports are written. Any other refusal stops, as in s199.

**`tests/journey/stops.sh`** defines only `stop_*` functions. Each one starts with `journey_kind`, runs real journeys with no override of `journey_po_next`, and returns 0 only when its last run stopped with an `ask` entry logged.

## Tasks
1. [x] **Answer folders** under `tests/journey/answers/`. `plain/` stays byte for byte. Each folder is layered over `plain` except `root-cause`.
   - `flow/plan.md`: `track: flow` above `validated: no`.
   - `screen/`: `design.md`; `qa.md` in the shape of `templates/qa.md` below its header (coverage, no finding, `Tree: @TREE@`, `QA status: complete`); `qa-capture.txt`.
   - `refused/`:
     - `review.md`: `Fix loop: @LOOP@`, one `- critical — src/@ID@.txt:1 — …`, `Max severity: critical`, `Ship allowed: no`;
     - `fix.patch`: creates `src/@ID@.fix@N@.txt`.
   - `choice/`: `plan.md` = plain's plan plus the technical-choice marker line; `decision.json` (motive `technical-choice`, two options, `blocks: ["@ID@"]`).
   - `root-cause/research.md`: the research with the `Root cause` marker line. Bound alone.
   - `shape/`: `review.md` and `review.retry.md`, whose finding is a `### minor — …` heading.
   - `no-verdict/review.md`: plain's review without its two verdict lines.
   - `qa-twice/`:
     - `qa.md` (`QA status: blocked`) and `qa.2.md` (`complete`);
     - `review.md`: `Review status: blocked`, `## When blocked` with `- Next action: /po-qa @ID@ — …`, one major finding, `Ship allowed: no`.

   Test: the oracle, and `every_ask_reason_is_reached` for the folders only `stops.sh` binds.
2. [x] **Forge double.**
   - `api` keeps the query string. `GET repos/acme/project/pulls` answers, for `head=acme:<branch>`, `[{number, state: open|closed, merged_at}]`, with `merged_at` set only on `MERGED`.
   - `pr close <url>` sets `CLOSED`.
   - Every `pr` and `issue` call whose `--repo` is not `github.com/acme/project` is unexpected (#434).
   - `pr merge` rebases onto `refs/heads/<baseRefName>` (#434).

   Test: `human_confirmation_waits_for_the_merge`, `stop_pull_request_closed`, and `forge_double_holds_its_repository` (Task 8).
3. [x] **`journey.sh`, environment and projects**: `journey_init` (#432), `journey_po_next --remote`, `journey_setting`, `journey_story_set`, layered `journey_answers`, named snapshots that include `$J/prs`, and `journey_kind`. Test: every oracle test; `journey_clears_the_callers_git`.
4. [x] **`journey.sh`, the loop.**
   - Every entry is logged, and appended to `$J/asks` when it is an ask, before the warning stop.
   - On `ask`, when `decision.json` is bound: fill it, pipe it into `"$PO" inbox add` from `$R`, log `asked` with its `.id` (a refusal stops quoting `error`), then stop as in s199.
   - The per-action counts and `<file>.<n>`.
   - `journey_by_hand`, `journey_asks`.

   Test: `pending_decision_holds_the_lane`; `stop_no_gate` (a warning stop) in `every_ask_reason_is_reached`.
5. [x] **`journey.sh`, the actions.**
   - `plan`: on the full track, write the research when `research.md` is bound. Write the plan when `plan.md` is bound, except while `design.md` is bound and the lane has no `docs/designs/<id>/design.md` (`planner.md:32`). Nothing written → `no written answer for plan of <id>`.
   - `design`: `design.md` → `docs/designs/<id>/design.md`.
   - `qa`:
     - fill `qa.md` at `@TREE@` and pipe it into `po record qa` from the lane; `.path` is awaited;
     - copy `qa-capture.txt` to `docs/qa/<id>/capture.txt` when it is bound;
     - `git add -- docs/qa/<id>/`, then `git commit -qm "<id>: QA evidence" -- docs/qa/<id>/` through the hook (`po-qa.md:31-36`).
   - `fix`:
     - `git apply` `fix.patch`, then `git add -A`;
     - put `git write-tree` on the record's `Tree:` line;
     - run `journey_po_run`;
     - commit `<id>: address review findings` (`implementer.md:47`).
   - `review`:
     - compute `@LOOP@`;
     - `findings-shape` → record `review.retry.md` (missing → `no written answer for review retry of <id>`); refused again → `journey_record_blocked` with `a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`;
     - `findings-shape-unrunnable` → `journey_record_blocked` with `a person runs po-gate findings-shape <id> — the check could not run (exit 2)`;
     - `journey_record_blocked` pipes the blocked report of `po-review.md:38` (`Review status: blocked`, the same loop, `## When blocked` with its four `- …:` lines, `Max severity: critical`, `Ship allowed: no`) into `po record review <id> --composed`.
   - `ship`: `effective` `human` under pr takes `land`, then `push`.
     - `waiting-for-human` → log `pr-waiting` with `.pull_request.url`, and the answer ends.
     - `merged` → `file` and `clean`, as in s199.
     - `human` under local → refused.

   Test: `screen_story…`, `blocked_review…`, `human_confirmation…`, `stop_findings_shape`, `stop_review_without_verdict`.
6. [x] **The reader**: `journey_ask_reasons` and `journey_unreached`, as the interface says. Test: `every_ask_reason_is_reached`; `reason_reader_reads_every_ask` (Task 8).
7. [x] **`tests/journey/stops.sh`**: 16 functions, story `s01-stop`.
   - `local` kind, by setting:
     - `Story track: sometimes`;
     - `QA stage: sometimes`;
     - `Flow threshold: low`;
     - `Complexité` removed;
     - `Plan validation: sometimes`.
   - `local` kind, by answers or project:
     - `root-cause`;
     - `choice`;
     - `po-gate.sh` dropped from main's index;
     - `shape`;
     - `no-verdict`, with `journey_record_blocked` overridden to do nothing (the coordinator stopped between `po record` and its blocked report);
     - `refused` + `Max attempts: two`;
     - `refused`.
   - `screen` kind (story `Surface screen`):
     - `Design source: —`;
     - `docs/design-system.md` removed on main;
     - `qa-twice`: run → `QA status: blocked`, `journey_by_hand qa`, run → twice.
   - `pr-human` kind: run → `merge waiting`, `gh pr close`, run.

   Test: `every_ask_reason_is_reached`.
8. [x] **`tests/journey-reaches-every-stop.test.sh`**, the journey's new guards:
   - `test_reason_reader_reads_every_ask`, on a copy of `po/src/next/` under `$J`:
     - an added `act("ask", "s200 decoy")` is read, and `journey_unreached` names it;
     - an `act(` split over lines makes `journey_ask_reasons` return 1 and name the file.
   - `test_journey_clears_the_callers_git`: `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` aimed at `/nonexistent/…`, and `JOURNEY_SETUP=1`, exported before `journey_init`. A pr story still lands, and the push log holds its branch.
   - `test_forge_double_holds_its_repository`:
     - `gh pr list --repo github.com/other/project …` fails, and the audit names it;
     - a `pulls?head=` read of a branch with no pull request answers `[]` and passes the audit.
9. [x] **`docs/harnais.md`**, under `## Le parcours rejoué`, in French.
   - What is added: the short track, design and QA through `po record qa`, fix runs, the inbox, the human merge, the stop journeys, and the reader of the reasons.
   - What is not proven:
     - no QA walk is real (no browser);
     - the second site of `setting unreadable: QA stage` (`lane.rs:69`) is not walked on its own;
     - the human merge is cleaned up by the person's `/po-ship` alone (the defect in the research).
   - The duration, and what a SIGKILL leaves behind.

   No test.
10. [x] **Measure.** Run `bash tests/run.sh journey-reaches-every-stop.oracle.test.sh journey-reaches-every-stop.test.sh journey-runs-to-a-landed-commit.oracle.test.sh journey-runs-to-a-landed-commit.test.sh` and write its duration under "Not proven here". Then run the full suite through `po-run`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s200-journey-reaches-every-stop -- po/ method/ bin/ .claude/ .polype/ tests/lib.sh evals/ tests/journey-runs-to-a-landed-commit.oracle.test.sh tests/journey-runs-to-a-landed-commit.test.sh tests/journey/answers/plain/` is empty.
- The oracle keeps `1224395356 11810`; any change goes through `## Oracle changes`.
- `grep -n 'journey_po_next' tests/journey/stops.sh` prints nothing: every stop goes through the real `po next --remote`.
- No new `*.test.sh` under `tests/journey/`. `journey.sh`, `stops.sh` and the doubles write only under `$J`.
- No journey against this repository, its worktrees, its remote, its inbox, a real forge or a real tracker. No build. No sleep longer than one second.
- #433 and #435 stay open. No task works around the merge defect: the journey runs no `git fetch` of its own outside the lane opening of `po-research.md:28`.

## The pivot
The coverage test reads the reasons from the code, as `act("ask", "<literal>")`, and compares them with what real journeys logged. That could be wrong in three ways:
- **A reason written another way** (a `format!`, a constant, a call that `rustfmt` splits) escapes the `grep`. The count of `"ask"` tokens has to equal the literal calls, otherwise the reader fails, naming the line: today 18 = 18 (`lane.rs`). Compare it with `reason_reader_reads_every_ask`. A reason built far from any `"ask"` token would still escape; the reviewer reads `po/src/next/` for one.
- **A stop reached by a forgery.** If a stop function used a canned `po next` or wrote a gate's file by hand, it would "reach" a reason `po` never gave on real files. Compare `stops.sh` with the run interdict above. The files each stop writes are answers or settings, and every report goes through `po record`.
- **The human merge is cleaned up by `/po-ship` run by hand, not by `po next`.** The research shows that `po next --remote` never sees the merge without a fetch. The test follows `po-ship.md:41` rather than the fleet. If the lead reads "la relance" as a `/po-drive` relaunch, this criterion cannot hold without changing `po/` or `method/`. That is the defect to file, not a reason to make the journey fetch.

## Files touched
- `tests/journey/journey.sh`
- `tests/journey/stops.sh`
- `tests/journey/doubles/gh`
- `tests/journey/answers/{flow,screen,refused,choice,root-cause,shape,no-verdict,qa-twice}/…`
- `tests/journey-reaches-every-stop.oracle.test.sh` (written, sum above)
- `tests/journey-reaches-every-stop.test.sh`
- `docs/harnais.md`
- this story's research, plan and record

## Test strategy
- **Automated: 9 tests**, within `Test budget` 25: the 6 of the oracle and 3 for the guards (Task 8). They are end-to-end: real `po`, `po-gate`, pre-commit, `po-run`, `po record` and `po inbox`. Only the forge, `cargo`, the tracker and the models are doubled.
- **Each new guard, and the test that fails without it:**
  - entries before the warning stop: `every_ask` (`stop_no_gate`);
  - `--remote`, and the double's `pulls` answer: `every_ask` (`stop_pull_request_closed`);
  - the research-only planner of a screen story: `screen_story…`, since the design would come after the plan;
  - the evidence commit kept alone: `screen_story…`;
  - the Fix loop computation: `blocked_review…` (`0 1 2`);
  - the recording protocol: `every_ask` (`stop_findings_shape`, `stop_review_without_verdict`);
  - the posting of the ask decision: `pending_decision…`;
  - numbered answers and `journey_by_hand`: `every_ask` (`stop_qa…`) and `human_confirmation…`;
  - the reader: `reason_reader_reads_every_ask`;
  - #432: `journey_clears_the_callers_git`;
  - #434: `forge_double_holds_its_repository`.

  The `$J/prs` snapshot only fixes a latent restore; it guards nothing.
- **Costs.**
  - Builds: none.
  - Installs: about 10 (one per test, and three kinds for `every_ask`).
  - Measured by hand: 1.4 s for a journey through two fix runs, 2.0 s for seven stops on one project. The estimate is about 25 s added to s199's 9 s, measured at Task 10; above 90 s, stop and report rather than cut tests.
  - `/tmp`: one folder per test, about 12 MB for `every_ask` (three projects and their snapshots), removed on exit, HUP, INT and TERM. A SIGKILL leaves that one `polype-journey.*` folder.
- **Visual checks:** none.

## Done when
- The four journey files pass in `tests/run.sh`, and the full suite passes through `po-run` (Task 10).
- A review with no open critical finding.
- One commit landed through a pull request whose description names the reasons the story's list missed and the merge defect left for the lead.
