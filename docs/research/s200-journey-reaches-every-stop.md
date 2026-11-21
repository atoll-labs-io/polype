# Research — s200-journey-reaches-every-stop

[Story](../stories.md)

## Structuring facts
- **The story's list of `ask` reasons is incomplete.** `po/src/next/lane.rs` returns 18 `act("ask", …)` calls with 17 distinct reasons. The story's notes miss four: `setting unreadable: Story track` (`lane.rs:22`), `setting unreadable: Flow threshold` (`:40`), `no complexity` (`:43`) and `pull request closed` (`:209`). `setting unreadable: QA stage` comes from two sites (`:32` for a story still to open, `:69` for a lane whose stage cannot be read). `mod.rs`, `wave.rs` and `overlap.rs` hold none.
- **Defect in `po`, outside `Owns`: a merge made by a person is never seen by `po next` on its own.** The lane stays `wait (merge waiting)` (`lanes.rs:353-362`). `Landed::read` reads only the local `main` and `refs/remotes/origin/main` (`lanes.rs:81-111`). `po next --remote` asks the forge only for pull requests that were closed without a merge (`next/mod.rs:118-134`), and no stage of `/po-drive` fetches except when it prepares a new lane (`po-research.md:28`). The walk below shows it. The story still holds, because `po-ship.md:41` tells the person to run `/po-ship <id>` again after merging. `po ship land` and `po ship push` fetch (`ship/land.rs:309`), and that run cleans up. What stays unreachable without some other fetch is `/po-drive`'s `ship (landed)` cleanup route (`po-drive.md:40`). The lead should file this.
- **The journey cannot reach five of these reasons as written.** It runs `po next` without `--remote` (`journey.sh:125`), while `/po-drive` runs `po next --remote` (`po-drive.md:30`), so `pull request closed` is unreachable. It stops on a warning before it logs the wave's entries (`journey.sh:277-279`), so `no po-gate`, which comes with a `no-gate` warning (`lanes.rs:266-268`), is never logged. It requires a `plan.md` answer (`journey.sh:188`), so a planner that stops on `Root cause: not found` with the research alone cannot be played. It knows no `design`, `qa` or `fix` action (`journey.sh:261`). It also refuses any `effective` value other than `automatic` (`journey.sh:236`).
- **The forge double needs two more answers.** It drops the query string of `gh api` (`doubles/gh:63`), so the `pulls?head=acme:story/<id>&state=all` read of `Forge::pull_request_closed` (`trust/forge.rs:171-183`) is logged as unexpected. It also has no `pr close`.
- **The same `po` binary answers every route.** No change to `po/` is needed, so `po` keeps its version (ADR-0122 does not apply).

## Story
Extend s199's journey to cover six criteria, each read by a script (`po`, `po-gate`, the journey):
- `short_track_lands`
- `screen_story_goes_through_design_and_qa`
- `blocked_review_loops_then_asks`
- `pending_decision_holds_the_lane`
- `human_confirmation_waits_for_the_merge`
- `every_ask_reason_is_reached`

`Owns`: `tests/journey/`, the two s200 test files, `docs/harnais.md`.

## Current code
- `tests/journey/journey.sh` (308 lines). It sources after `tests/lib.sh`. One loop (`:265-303`) applies one written answer per action. Logs are written as `entry`, `stopped` and `done` lines. The repeat guard is keyed on `(action, reason)` per story (`:295`). Snapshot and restore cover `$R` and `$ORIGIN` only (`:93-105`): restore deletes `$J/prs` without having saved it. `journey_init` unsets the forge tokens, but leaves `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` and `JOURNEY_SETUP` as the caller set them (`:30`, issue #432).
- `tests/journey/doubles/gh` (83 lines) answers a solo `acme/project`. Its `pr` subcommands ignore `--repo`. `pr merge` rebases onto `main` whatever `baseRefName` says (#434).
- s199's two test files are unchanged by this story, and their nine tests pass on main (`docs/reviews/s199-…md`, 8.6 s).

## Attachment points
- New actions go in `journey_apply`'s `case` (`journey.sh:185-262`): `design`, `qa` and `fix`.
- The `ask` and `wait` handling sits in the loop (`:291-294`).
- The settings of a project come from `journey_settings` (`:37-43`). A story's fields come from `journey_story` (`:82-91`).
- New answer folders go under `tests/journey/answers/`. The stop journeys go in a new `tests/journey/stops.sh` (not a `*.test.sh`).

## Verified interfaces (walked by hand, throwaway projects under `mktemp -d`, main's `po` 0.12.0)
All of these come from the hand walks:

| Route | What po next / po answered |
| --- | --- |
| Complexité 2, `Flow threshold: 2` | `plan (ready) flow` → validate-plan → execute → review → ship. Lands with no research. `trust.track` (`trust/signals.rs:80-93`) reads `track: flow` from the plan. |
| `Surface: screen`, `QA stage: screens`, `Design source: internal` | `plan (ready) full` → `design (no design)`. The planner writes the research alone (`planner.md:32`). |
| After `design.md` | `plan (research, no plan)` → validate → execute → `qa (qa-current refuses)`. |
| `po record qa` with `Tree:` of `story/<id>^{tree}` | `qa (QA evidence not committed)`. After `git commit -m "<id>: QA evidence" -- docs/qa/<id>/` (`po-qa.md:31-36`) → `review (no review)` → lands. |
| Review `Ship allowed: no`, then a fix commit `<id>: address review findings` (`implementer.md:47`) with the record's `Tree:` rewritten and `po-run` rerun | `fix (Ship allowed: no)` → `review (review judged earlier code)`. At `Fix loop: 2` it gives `ask (Max attempts reached)`, under the template's `Max attempts: 2`. |
| `po inbox add` with `blocks: [id]` (fields `motive`, `question`, `options[{key,label,consequence}]`, `recommended`, `why`, `reversible`, `blocks`; `inbox/decision.rs:23-46`) | `wait (decision d-0001)`. It stays that way after `po answer d-0001 <key>`. After `po inbox consume d-0001 <ref>`, the lane resumes. The inbox is the throwaway project's `.polype/inbox/`, which the installer ignores. |
| `Ship confirmation: human (chosen)` under pr | `po ship push` → `waiting-for-human`, then `wait (merge waiting)`. A plain `human` reads as `(forge)`, and on a solo forge it gives `effective: automatic`, so `(chosen)` is needed. |
| After `gh pr merge` on the double | `po next --remote` keeps `wait (merge waiting)`. It becomes `ship (landed)` only after `git fetch` (the defect above). By hand, `po ship forge`, `land` (`already_landed: true`), `push` (`merged`), `file` (`filed`) and `clean` (`cleaned`) run, then `po next` has no action left. |
| Pull request set to `CLOSED` on the double, with `pulls` answered | `ask (pull request closed)`. |

Each other reason, reached through real files:
- `Story track: sometimes`, `Flow threshold: low`, a story with no `Complexité` line, and `QA stage: sometimes` (with `Surface: command`) → the ask at wave 1, with no warning.
- `Plan validation: sometimes` → wave 2.
- A research holding `Root cause: not found` with no plan → wave 2.
- A plan holding the `Technical choice` line → wave 2.
- `Max attempts: two` and a refused review → wave 5.
- `po-gate.sh` dropped from main's index → `ask (no po-gate)` plus a `no-gate` warning.
- `Design source: —` → `Design source unset`. `docs/design-system.md` removed from main → `no docs/design-system.md`.
- A review whose finding is a heading: `po record review` exits 1 (`findings-shape`, written). A second time, then `po record review --composed` with `- Next action: … findings-shape …` (`po-review.md:38`) → `findings-shape refused`.
- A review with no verdict lines: `po record review` writes it and exits 2 (`findings-shape-unrunnable`). If the blocked report `po-review.md:38` asks for is not recorded, the result is `review without verdict`.
- QA reported `blocked` and committed → `QA status: blocked`. A second walk `complete`, committed, then a review blocked with `- Next action: /po-qa …` → `QA evidence committed twice` (`lane.rs:187-191`).

Cost measured: one local journey through two fix runs takes 1.4 s including the install. Seven settings and file stops on one project, with restores between them, take 2.0 s.

## Traps
- **The repeat guard** (`journey.sh:295`) would stop a second `qa (qa-current refuses)`. The QA that is resumed after `QA status: blocked` is a person's by-hand run (`po-qa.md` `## By hand`), not a route `po next` gives twice.
- **Layered answers.** The research-only planner of a screen story must find no `plan.md` before the design exists. The root-cause answers must not fall through to `plain/plan.md`, so that folder is bound alone.
- **Fix loop** is computed as `po-review.md:24` says: the previous `Fix loop` + 1, the same after a block that names `/po-qa` or `QA evidence`, and 0 for the first review. s199's `review.md` hard-codes `Fix loop: 0`, which stays right for a first review.
- **Ship from the root under local.** `po ship land --land` refuses a dirty root. Every setting or story edit is therefore committed on main, and pushed under pr.
- **Logging entries before the warning stop** changes no s199 test. The canned warning has no actions (`journey-runs-to-a-landed-commit.test.sh:24`).
- **`--remote` on local projects** asks nothing: there is no `origin` (`trust/forge.rs:142-145`). On pr projects, each lane at `ship` adds one `api … pulls?…` read. s199's assertions on the gh log count `pr create`, `pr merge` and `issues`, so they are unaffected.
- **`/tmp` is in memory.** Each journey folder takes about 2 MB, and only one exists per test.

## Open questions
- Should `/po-drive` or `po next --remote` see a person's merge? That is a change outside `Owns` (`po/` or `method/`), for the lead to file. This story follows `po-ship.md:41` and writes no test that freezes the current behaviour.
- #433 (the probe takes any refusal for the plan gate): the plan does not touch those lines (`journey.sh:203-208`), so it stays open. #435 sits in s199's oracle, which is outside this story's `Owns`, so it stays open.

## Complexity
3 → **4**. Three new actions, a by-hand resume, a recording protocol, layered answers, a reader of `po`'s sources, and 16 stop journeys. That is more than the short track's six tasks.

## Split
—
