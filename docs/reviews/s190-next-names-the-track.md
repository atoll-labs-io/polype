# Review — s190-next-names-the-track

[Story](../stories.md) · [Plan](../plans/s190-next-names-the-track.md) · [Verification](../verif/s190-next-names-the-track.md)

Method version: 0.6.1
Recorded: 2026-11-18T11:45:04+01:00

Diff reviewed: `git diff main...story/s190-next-names-the-track`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 7804692c3da432d439375bdfa1ac5485496d8284

## Ownership
Diff listed with `git diff --name-only main...story/s190-next-names-the-track` (19 paths). Each path was held against the story's `Owns` (`docs/stories.md:3085`) using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The research, plan and verification record under `docs/` are the story's own evidence, so they are in scope by construction. The diff adds no ADR.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane and `.claude/worktrees/framing-m22` on branch `fix/qa-deadline-wording`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s190-next-names-the-track` exits 0, so the record is reused. `Unit suite` (`bash tests/run.sh`) exited 0 on code equal to `Tree:` outside `docs/`. The project has no `Typecheck` command (`—`). I read the record's "Not proven here": `bin/po-version-check` runs after the commit. I ran it here and got exit 0, "po at 0.7.0, consistent with origin/main".
- [x] `po-gate qa-current` not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–9 are present as written. Task 10 (whole suite) is covered by the record's run.
  - Task 2 extracts `goes_to_qa` with the same rule as before.
  - Task 3: one `plan()` builds every `plan` action, and every `ask` reason is a literal.
  - Task 4 moves the design block above `research, no plan` and the `Plan validation` branch.
  - Task 6 changes the version in all three places.
  - Task 7 updates `## Which track` and `Reads settings:` in `planner.md`.
  - Task 8 updates step 1 of `po-drive.md`.
  - Task 9 updates `interface-agent.md` at the two rows.
- [x] The implementer named two departures.
  - `tests/planner.test.sh`: the three assertions and the `local settings` line it removed are exactly the `:52-54` that task 7 lists. That is not a departure.
  - `tests/driver-next-action.oracle.test.sh:267`: the change from `{story, action, reason}` to `{story} + .next` was not announced in task 5. It makes the comparison stricter, since the whole `next` object, `track` included, must now equal `po next`'s entry. The change is needed once `track` exists, and the record discloses it under "Not proven here". Graded minor below.
- [x] Each run interdict checked:
  - The oracle checksum is intact (`oracle-intact` exit 0).
  - Nothing changed outside `Owns`; `po/src/trust/`, `po/src/state/`, `po-flow.md`, `po-orchestrator.md`, `.claude/` and `.polype/` are untouched.
  - There is no new `Warning` variant, and `plan()` pushes no warning.
  - `contract` stays `1` and `ACTIONS` is unchanged.
  - No existing `expect_*` line was edited; one case was added (`a-wave.cases`).
  - No `ask` reason is built with `format!`.
  - Word counts (`LC_ALL=C wc -w`): `planner.md` 1333 (was 1353), `po-drive.md` 2450 (was 2452).

## References
- [x] Every import, call, API and configuration key is confirmed:
  - `goes_to_qa` is re-exported at `po/src/context/mod.rs:17`.
  - `Story::has_screen` (`stories.rs:25`), `setting` and `number` (`lane.rs:121,150`), `Stories::find` and `LaneSettings.qa_stage` all exist.
  - `Track` serializes in lowercase; `skip_serializing_if` keeps every other action as `{action, reason}`.
- [x] Values checked:
  - `Flow threshold` is read only under `auto`, as `method/templates/agents-local.md:67` requires.
  - The `<=` comparison matches "at most `Flow threshold`".
  - Complexity takes the leading ASCII digits, so `2 — risk: …` gives 2; the oracle pins this.
  - The template defaults (`Story track: auto`, `Flow threshold: 2`) are readable values.

## Rules
- [x] `AGENTS.md` conventions respected: commit message in English, method files in English.
- [x] No accepted ADR contradicted. The pivot (a screen story with no research still gets `plan`/`no research`/`full`, and `design` comes once the research is on disk) follows the order ADR-0109 adopts ("recherche, design, plan", line 24) and the stage machine at `lanes.rs:256-264`. `po state` now reports `stage: design` and `next: design` together; the oracle checks this.

## Tests
- Oracle: `po-gate oracle-intact s190-next-names-the-track` → exit 0
- [x] Floor: `po-gate floor-guard s190-next-names-the-track main` exits 0; nothing was lowered. `oracle-intact` exits 0.
- [x] The assertions pin each criterion through the built `po` binary. I found none of the six empty test shapes. Each forced signal is isolated: the QA run repeats with `QA stage: —`, where `s05-echo` drops to `flow`.
- [x] Within `Test budget`: 6 new tests out of 25.
- [x] Bite 1: in `lane.rs:30`, `story.fixes` replaced by `false` → 2 failing tests in `next-names-the-track.oracle.test.sh` → undone, `git diff --exit-code` clean.
- [x] Bite 2: in `lane.rs`, the `research, no plan` check moved back above the design block → 2 failing tests (`design_comes_before_plan`, and `every_routing_case_is_a_fixture` through `case_a_wave_05`) → undone, `git diff --exit-code` clean.
- [x] Tests the story made obsolete were removed: the `Flow threshold` phrase assertions in `planner.test.sh`.

## Neighbours
- [x] Callers read:
  - `stage()` in `lanes.rs:279` gives the same result through the extracted `goes_to_qa`.
  - `po state` builds `lanes[].next` from `lane_next`, and the oracle checks that it carries `track`.
  - `po-drive.md` is the only place that dispatches the planner. `po-orchestrator` and `po-flow` do not, so "No track given → stop" breaks no other caller.
- [ ] `po-drive.md:29` ends a wave only when `ready` is empty. A ready story can now come back as `ask`. See Findings.

## Lenses
Lenses run: dependencies — `po/Cargo.lock` changed. Only the `po` package's own version moved (0.6.1 → 0.7.0); no third-party entry was added, removed or bumped. Nothing to grade.
- [x] Each lens finding graded and listed under Findings: none from the lens.

## Findings
- major — po/src/next/mod.rs:96 — A ready story's entry now goes through `lane::plan()`, so it can be `ask` (`setting unreadable: Story track`, `setting unreadable: Flow threshold`, `no complexity`, `setting unreadable: QA stage`) while the story stays in `ready`.
    - Before this story, a ready entry was always `plan`/`ready`.
    - `method/commands/po-drive.md:29` still ends the wave only "when every entry is `wait` or `ask` and `ready` is empty". A project with `Story track` missing, or a story with no complexity under `auto`, therefore leaves `ready` non-empty forever. The driver has no written way to end the wave, and nothing tells it not to post the same `ask` to the inbox again on every rerun.
    - `docs/interface-agent.md` does not say that a `ready` story can come back as `ask`.
    - Either drop such a story from `ready` (holding it with a reason), or change the end condition in `po-drive.md` and document the case in the contract.
- major — method/agents/planner.md:30 — The rewrite drops "Check them on the story text before you read anything". The planner now raises `flow` to `full` only when "your reading of the code shows a signal the story files do not".
    - `po next` forces `full` only for a `Fixes`/`Corrige` line, a `Surface: screen` or QA routing. It cannot see the other listed signals when they appear only in the story text: a migration, an API contract, a new dependency, authorization, an ADR-worthy choice, or a screen shown by text with no `Surface` line (ADR-0054).
    - Read literally, a low-complexity story under `auto` whose text announces a migration gets `flow`, and the planner is told to raise the track only for signals the story files do *not* carry. Before this story, that case was escalated. This story's own plan escalated on such a signal ("Escalation signal found on the story text: an API contract").
    - It is a rule read by a model, judged here by reading. The wording should keep both the story-text check and the code check, within the word cap.
- minor — tests/driver-next-action.oracle.test.sh:267 — The comparison in s168's oracle changed from `{story, action, reason}` to `{story} + .next` without being announced in task 5 of the plan. It is stricter, not weaker, needed once `track` exists, and disclosed under "Not proven here" of the record rather than in a plan amendment.

## Not verified
- `planner_follows_the_track_it_is_given` is judged by reading only. No planner was run with a `track` to see whether it takes it, raises it, or stops when none is given. A person, or a `po-eval` control arm (#208), should run the planner once with `track: flow` on a story whose text names a migration, and once with no track.
- The research-only path for a screen story, where the planner writes the research and stops, was not run end to end with real subagents. Only `po next`'s routing was exercised. A person should drive one screen story through `/po-drive` on a scratch project.
- `po next --remote` was not exercised: the closed-pull-request path is untouched by this diff, and no forge was queried.
- The full unit suite and `bin/po-lint` were not rerun. The record proves the suite on this code, and `po-lint` is not among its declared checks. A person can run `bin/po-lint` before ship.
- The project has no type check, build or end-to-end command (`—`), so none was run.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T12:26:21+01:00

Diff reviewed: `git diff main...story/s190-next-names-the-track`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 5b12b7c2d657303bdc167e67fec11d2a54ef1085

## Ownership
I listed the diff with `git diff --name-only main...story/s190-next-names-the-track`: 21 paths. I checked each one against the story's `Owns` line (`docs/stories.md:3085`) using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`.
  - The fix run added one file, `tests/next-names-the-track.test.sh`, and `Owns` lists it.
  - The research, plan, verification record and review are the story's own evidence. The diff adds no ADR.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none.
  - `git worktree list` shows only this lane and `.claude/worktrees/framing-m22`.
  - `.claude/worktrees/framing-m22` is on `fix/qa-deadline-wording`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s190-next-names-the-track` exits 0, so I reused the record.
  - `Unit suite` (`bash tests/run.sh`) exited 0 on tree `3dd51db…`, whose code outside `docs/` equals `Tree:`.
  - The project has no `Typecheck` command (`—`).
  - I read the record's "Not proven here". `bin/po-version-check` is run after the commit, so I ran it here: exit 0, "po at 0.7.0, consistent with origin/main".
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–10 are present. The fix run (df6e2cc) changes only what the previous findings asked for:
  - one sentence in `method/commands/po-drive.md:29`;
  - one sentence in `docs/interface-agent.md:104`;
  - one sentence in `method/agents/planner.md:30`;
  - a row under `## Oracle changes` of the record;
  - one new test file;
  - the comment at `po/src/next/lane.rs:1`, which no longer cites a `## Resuming` order the code does not follow. This is harmless.
  - The text of task 7 in the plan still says "when the code shows a signal the story files do not". `planner.md` now departs from that wording on purpose, as the previous review asked.
- [x] Each run interdict, checked one by one:
  - `oracle-intact` exits 0.
  - The diff is empty outside `Owns`, including `po/src/trust/`, `po/src/state/`, `po-flow.md`, `po-orchestrator.md`, `.claude/` and `.polype/`.
  - There is no new `Warning` variant.
  - `contract` stays `1`.
  - No existing `expect_*` line was edited.
  - No `ask` reason is built with `format!`.
  - Word counts (`LC_ALL=C wc -w`): `planner.md` 1336 (cap 1353), `po-drive.md` 2450 (cap 2452).

## Previous findings (Fix loop: 0)
- **Major `po/src/next/mod.rs:96` (a ready story that asks stays in `ready` forever): closed.**
  - `po-drive.md:29` now ends the wave "when every entry is `wait` or `ask`, those of `ready` included". This is coherent: each `ready` id is also an entry of `actions` (`mod.rs:96`), so the old clause "`ready` is empty" added nothing except the dead end.
  - `docs/interface-agent.md:104` now names the case.
  - Keeping `ready` unchanged is right. `po state` and `po next` agree on it, which the new test checks.
  - The lead asked what stops the driver from posting the same question again on every rerun. I ran a probe on a throwaway copy of the fixture, since removed:
    - A ready story with no complexity gives `ask`/`no complexity` and stays in `ready`.
    - After `po inbox add` with `"blocks": ["s01-alpha"]`, the next `po next` moves it to `held` with reason `decision` and ref `d-0001`. It leaves `ready` and `actions`, and `po state`'s `ready` drops it too.
    - So the code prevents a repost through `holding_decision` (`po/src/next/wave.rs:59`). But only when the driver names the story in `blocks`, and nothing in `po-drive.md` tells it to. See the first minor finding below.
- **Major `method/agents/planner.md:30` (the story-text check was dropped): closed.**
  - The sentence now reads: "Raise `flow` to `full` on any of these signals, found in the story text or in your reading of the code".
  - The signal list, the `Fixes`/`Corrige` phrase, the six-task rule and "say which one you found" are all kept, within the word cap.
- **Minor `tests/driver-next-action.oracle.test.sh:267` (the comparison change was not announced): closed.**
  - The change now has a row under `## Oracle changes` of the record, with its reason.
  - It makes the comparison stricter, not weaker.

## References
- [x] Every call is confirmed:
  - `holding_decision` (`mod.rs:153`) is used by both `wave.rs:59` and `lane.rs:62`.
  - `lane::plan` is called from `mod.rs:96`, and `goes_to_qa` is re-exported from `context`.
  - The `blocks` field of `po inbox add` is read at `po/src/inbox/add.rs:241`.
- [x] Values: `<=` against `Flow threshold` matches "at most". The fixture defaults are `auto`/`2`.

## Rules
- [x] `AGENTS.md` conventions are respected: the commit message and the method files are in English, and no co-author trailer was added.
- [x] No accepted ADR is contradicted. The order research, design, plan follows ADR-0109.

## Tests
- Oracle: `po-gate oracle-intact s190-next-names-the-track` → exit 0
- [x] Floor: `po-gate floor-guard s190-next-names-the-track main` exits 0; nothing was lowered. `oracle-intact` exits 0.
- [x] The assertions pin the criteria through the built `po` binary. I found none of the six empty test shapes.
  - The new `test_ready_story_that_asks_stays_ready` checks `po next`'s entries and `ready` under `Story track: auto` and with it missing.
  - It also checks that `po state`'s `ready` equals `po next`'s.
- [x] Within `Test budget`: 7 new tests out of 25.
- [x] Bite 1: at `lane.rs:45`, `complexity <= threshold` changed to `<` → 4 failing tests (3 in the oracle, plus the new test) → undone, `git diff --exit-code` clean.
- [x] Bite 2: at `lane.rs:30`, `story.has_screen()` removed from the forced-`full` signals → 2 failing tests (`plan_action_names_its_track`, `design_comes_before_plan`) → undone, `git diff --exit-code` clean.
- [x] After the bites I rebuilt the binary from the clean tree (6 passed). The worktree is clean.
- [x] Tests the story made useless were removed: `planner.test.sh:52-54`.

## Neighbours
- [x] `po state` takes `ready` from the same `wave::ready_and_held`, and the new test checks that the two agree.
- [x] `po-drive.md:41` handles every `ask` through `po inbox add`. A decision whose `blocks` names the story holds it (`held`/`decision` for a ready story, `wait`/`decision <id>` for a lane) until it is consumed.

## Lenses
Lenses run: dependencies — `po/Cargo.lock` changed. Only the `po` package's own version moved (0.6.1 → 0.7.0); no third-party entry changed. Nothing to grade.
- [x] Each lens finding graded and listed under Findings: none from the lens.

## Findings
- minor — method/commands/po-drive.md:41 — The `ask` row does not tell the driver to name the story in the decision's `blocks`.
    - Only that field moves the story out of `ready` and into `held` with reason `decision`, as the probe showed. Without it, every rerun of `po next` returns the same `ask`, and the driver would post the same question again.
    - This story widens the case. One unreadable `Story track` or `Flow threshold` now makes every ready story ask at once, which means N identical questions per wave.
    - The gap already existed for lane asks, and the driver is likely to fill a required field naturally, so this is graded minor. Naming `blocks: [<id>]` in the row would close it.
- minor — docs/interface-agent.md:104 — "elle reste dans `ready` jusqu'à ce que la réponse de la personne la rende planifiable" does not match what `po next` does once the decision is posted.
    - A decision whose `blocks` names the story moves it to `held` with reason `decision` until the decision is consumed (`wave.rs:59`). It does not stay in `ready`.
    - The sentence holds only between the `ask` and the `po inbox add`.

## Not verified
- `planner_follows_the_track_it_is_given` and the wave-end sentence of `po-drive.md` were judged by reading only. No planner or driver was run.
  - A person, or a `po-eval` control arm (#208), should run the planner once with `track: flow` on a story whose text names a migration, and once with no track.
  - They should also drive a wave with `Story track` missing, to see that the driver ends the wave and posts one decision per story, with `blocks` set.
- The research-only path for a screen story was not run end to end with real subagents. A person should drive one screen story through `/po-drive` on a scratch project.
- `po next --remote` was not exercised: the diff does not touch the closed-pull-request path, and no forge was queried.
- The full unit suite was not rerun: the record proves it on this code. I did not run `bin/po-lint`, because it is not among the record's declared checks. A person can run it before ship.
- The project has no type check, build or end-to-end command (`—`), so none was run.

Max severity: minor
Ship allowed: yes
