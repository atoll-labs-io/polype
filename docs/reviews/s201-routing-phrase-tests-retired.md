# Review — s201-routing-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s201-routing-phrase-tests-retired.md) · [Verification](../verif/s201-routing-phrase-tests-retired.md)

Method version: 0.11.0
Recorded: 2026-11-21T14:02:28+01:00

Diff reviewed: `git diff main...story/s201-routing-phrase-tests-retired`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 037c45ef93c2ed7d9be3d70e2a32469ed8cd37f1

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s201-routing-phrase-tests-retired` (46 paths), each held against the `Owns` line at `docs/stories.md:3285`.
- [x] Every path inside `Owns`. The research, plan and record are the story's own evidence. `tests/ship-and-fleet-cleanup.test.sh` is listed in `Owns` (correction 2, `8e2a5ad`), and s202, which also owns it, has no worktree.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane and `framing-m22` (`fix/qa-deadline-wording`), which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exit 0. With `Verification mode: record`, the unit suite `bash tests/run.sh` (exit 0, 477 s) is reused and was not rerun. The project has no `Typecheck` (`—`). I read "Not proven here".
- [x] `po-gate qa-current` not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are present. The 13 files of task 1 are deleted. The edits in tasks 2 to 5 keep the "Stays" column; I spot-checked drive, model-routing, escalation-contract, defect-and-routing-paths, research, ownership, review-findings-shape, the two shipped oracles and ship-and-fleet-cleanup. The two docs of task 6 are in.
- [x] Run interdicts, one by one:
  - Nothing changes under `method/`, `po/`, `bin/`, `.claude/`, `.polype/`, `evals/`, `tests/lib.sh`, `tests/run.sh`, `tests/journey/` or `tests/fixtures/`.
  - No test file outside `Owns` is touched.
  - No phrase is added. The oracle's sum is held (`oracle-intact` exit 0).
  - `tests/routing-phrase-tests-retired.test.sh` was not created.
  - No version bump.
  - The `/tmp/tmp.*` count is unchanged after my oracle run (214 before and after).

## References
- [x] I opened every reader the sampled "Stays" rows cite:
  - `po/src/context/lanes.rs:323,326` (`Root cause: not found`, `Technical choice: waiting for a human`)
  - `po/src/next/lane.rs:187,194` (`QA evidence`, `findings-shape`)
  - `po/src/context/stories.rs:153,159` (`- **Owns**`, `- **Fixes**`/`- **Corrige**`)
  - `method/hooks/po-gate.sh:614-623,645` (`## Acceptance tests`, `Oracle file`, `## Oracle changes`)
  - `bin/polype:627` (`missing setting:`)
  - `po/src/record/compose.rs:7-15` (the first two template lines)
  - `Fix loop` and `Max severity:` read in `po/src/next/lane.rs:165` and `po/src/trust/signals.rs:33-34`
- [x] I opened every proof the sampled "Goes" rows cite:
  - `state-as-json.test.sh:58,98`
  - `fixtures/driver-cases/resuming.cases:92-97` (`QA stage surfaces`)
  - `driver-next-action.oracle.test.sh:330,394`
  - `journey-reaches-every-stop.oracle.test.sh:170`
  - `held-says-what-collides.oracle`, `next-names-the-track.oracle`, `bounds-messages.test.sh`, `record-writes-reports.test.sh`
  - the `gate.test.sh` secret tests (`:170-193`)
  - `Plan validation: human` → `validate-plan` (`lane.rs:99-102`, `resuming.cases:40-51`)
  - The "root clean and on target" citation points at the wrong test; see Findings.

## Rules
- [x] `AGENTS.md` conventions respected. Every test file still has a `test_` function.
- [x] No accepted ADR contradicted. Following the owner rule of 2026-11-13, a rule that only a model reads keeps no phrase test.

## Tests
- Oracle: `po-gate oracle-intact s201-routing-phrase-tests-retired` → exit 0
- [x] Floor: `po-gate floor-guard` exit 1, with 14 flags: 13 `test-file-deleted` and `ship-and-fleet-cleanup.test.sh:17 assertions-dropped`. The plan justifies all 14 (task 1, task 5, correction 2), so they are graded minor.
- [x] Oracle: `po-gate oracle-intact` exit 0. The two shipped oracles were lightened without an `## Oracle changes` row, which the story's notes allow:
  - `review-header-recorded.oracle`: the parts removed are the reviewer and `po-review` wording, the note order and the ADR-0104 body. The script criterion stays: the template's two header lines, `po record`, and the `po-link-artifacts` run.
  - `oracle-intact-gate.oracle`: the parts removed are the `po-gate` usage comment and the review step-4 wording. Both `po-gate oracle-intact` behaviour tests stay.
  - In both files the script-read criteria are still held. The model-read ones (review step 4, reviewer header) are M.
- [x] Bite of the count: in a throwaway clone of the story branch I deleted `test_plan_validated_fails_without_file` from `tests/gate.test.sh`. `scripts_kept_their_tests . origin/main` → rc 1, `po-gate.sh: launched by 135 test functions on origin/main, 134 here`. Undone with `git checkout`, and the clone is clean. The story worktree was never touched (`git diff --exit-code` clean).
- [x] Launch counts per script are identical on base and story: po 178, polype 143, po-gate.sh 135, po-run.sh 52, po-bounds.sh 48, pre-commit 31, po-session.sh 25, po-lint 24, po-eval 20, po-intake.sh 13, po-release 12, polype-dev-install 12, po-version-check 5, po-link-artifacts 4, po-ci 2. The 705 launch lines are identical too.
- [x] What the count cannot see, probed on a throwaway test file:
  - a launch inside single-quoted `bash -c`: not counted (documented);
  - a launch through a helper sourced inside a test function: not counted;
  - a test that only `grep`s a script's text, or tests it with `[ -x ]`: not counted, which is right;
  - a launch that always fails (`|| true`): counted;
  - `python3 - <script>` that only reads the file: counted as a launch;
  - `cp` of a hook: counted, as documented;
  - every launch in a file that defines or sources the count's own helpers: dropped (see Findings).
- [x] Real numbers (the implementer's numbers are confirmed):
  - Main has 192 files and 960 `^test_` lines; the plan says 193.
  - The story has 180 files and 825 sourced test functions. Counting `^test_` lines gives 832, which includes 3 heredoc lines in the oracle and 4 names defined twice.
  - Removed: 134 `test_` lines.
  - No test file is left without a `test_` function.
- [x] The three oracle tests are within `Test budget` 25.
- [x] The tests the story made useless are removed. The helpers left unused were removed. `SHIP` in `ship-and-fleet-cleanup.test.sh:4` was already unused on main.

## Neighbours
- [x] `ship-and-fleet-cleanup.test.sh` used to call `escalation-contract.test.sh:test_human_stops_do_not_halt_the_fleet`; that call is removed with the function. No other file sources a deleted file (checked with grep).

## Lenses
Lenses run: none. Only bash tests and French docs changed; no path or content triggers a lens.
- [x] No lens findings.

## Findings
- major — tests/routing-phrase-tests-retired.oracle.test.sh:96 — The count goes blind in exactly the files that reuse it.
    The reader splits its input on the literal `@@FILE `. That literal also sits inside `LAUNCH_READER` itself (`split("@@FILE ")`, printed by `declare -p`) and inside the body of `script_launches` (`:127`, printed by `declare -f`). So for any test file that defines or sources these helpers, the stream is cut in the middle of the file. Its `@@FUNCS` marker is lost and none of its test functions is read.
    - Proof 1: this oracle's own `test_contract_tests_stay` launches `bin/po-lint` (`:209`), yet the oracle shows no line in the launch list.
    - Proof 2: a probe file sourcing the helpers with `sed '/^test_/,$d'`, as `docs/harnais.md` and `docs/stories.md:3311` tell the s202 to s204 oracles to do, had its `po-gate.sh` launch dropped. The same launch in a plain file was counted.
    - Consequence: every script test written in those oracles will be invisible to `no_script_lost_its_tests`.
    - Fix: use a separator no file can hold (for example NUL), or leave the helpers' own variables and functions out before the dump.
- major — docs/plans/s201-routing-phrase-tests-retired.md:77 — Several human checkpoints, a stop that goes to the person and a model rule are now guarded only by a model, with no test left. Each is classified **M**:
    - `validated: yes` written "on Approve and on nothing else", plus "state that no human reviewed it" (`plan.test.sh`). `po-gate plan-validated` reads the line, not who wrote it.
    - Under `Plan validation: human`, one grouped AskUserQuestion that validates only the plans the answer approved (`grouped-validation`, plan `:87`). `po next` → `validate-plan` still holds the per-story stop (`lane.rs:99-100`, `resuming.cases:40-51`); the "only the approved ones" part is unguarded.
    - "If the Agent tool rejects the model name, stop" and "Never retry with another model or with none" (`model-routing`).
    - The deciders (reviewer, qa, stories-reviewer, planner, designer) dispatched on `Model strong` (`model-routing`, plan `:69`). `po` reads no model setting.
    - "goes to the person at once, one at a time, and the fleet carries on" (`escalation-contract`, plan `:71`). `po inbox` (J `inbox`) and `po-session` hold the stop itself, not the "carries on" part.
    - All of this is the owner's rule of 2026-11-13, so it is not an implementation defect. Until s206 / #208 exists, a rewording of these lines goes unseen. s206 or #208 should name each of these rules explicitly.
- minor — docs/plans/s201-routing-phrase-tests-retired.md:63 — Two citations in the `drive` row point at the wrong proof.
    - "Root clean and on target" cites `ship-builds-the-landing-commit.test.sh` (`dirty-worktree`). `dirty-worktree` is the lane cleanup (`po/src/ship/clean.rs:215`, `ship-cleans-the-lane.oracle.test.sh:156`). The real guard is `root-not-clean` (`po/src/ship/land.rs:275-295`, `tests/ship-builds-the-landing-commit.oracle.test.sh:180`).
    - "under `local`, one AskUserQuestion per merge is M" understates the cover: `po ship land` refuses with `confirmation-required` (`tests/ship-builds-the-landing-commit.test.sh:244`).
    - Both behaviours are guarded; only the plan's citations are off.
- minor — docs/harnais.md:1 — The new `## Le compte des lancements` section leaves out real blind spots and has no clear exit for a legitimate change.
    - Unlisted blind spots:
        - a helper sourced inside a test function is invisible; `test_every_ask_reason_is_reached` (`tests/journey-reaches-every-stop.oracle.test.sh:172`, sourcing `stops.sh`) counts as launching nothing;
        - a file that sources the helpers is invisible (first finding);
        - `python3 - <script>` that only reads the file counts as a launch.
    - Legitimate change: refactoring a launch into such a helper fails the count. So does rightly removing a script's test. The section says "allège cet oracle", but the oracle has no per-script allowance. Lightening it means editing the shared helper that s202 to s204 must source unchanged. Once s201 has shipped, `po-gate oracle-intact` no longer watches that edit. The doc should say exactly what to change.
- minor — tests/structure.test.sh:73 — Two completeness checks of the same kind as #442 (a set held against a registry) leave with nothing guarding them. #442 does not list them:
    - `test_rules_list_every_installed_hook`: every file of `method/hooks/` named in `## Installed files` of `method/AGENTS.md`. Removed; line taken on main.
    - Every fleet and model setting has a documented `^| <name> |` row in the values table of `templates/agents-local.md`. Removed from `drive.test.sh` and `model-routing.test.sh:19-21` on main.
    - Both could join #442 as `po-lint` candidates.
- minor — tests/ship-and-fleet-cleanup.test.sh:17 — The `floor-guard` flags, 13 `test-file-deleted` plus one `assertions-dropped`, are all justified in the plan (tasks 1 and 5, correction 2).

## Not verified
- I did not rerun the full suite. I relied on the `po-run` record (exit 0); the gate holds it current for this code.
- I did not mutate the reader's `launched` function (the plan's pivot). The count's bite was shown instead by removing a launching test, as the lane asked.
- I sampled about 15 of the 42 classification rows: drive, fleet-wiring, surface-routing, escalation-contract, defect-and-routing-paths, research, plan, resume, grouped-validation, ownership, model-routing, review-findings-shape, the two shipped oracles, structure, ship-and-fleet-cleanup. Not opened: planner, planner-writes-the-oracle beyond the `po-gate` lines, execute, diagnostic beyond its two kept lines, review-lenses, project-lead, leftovers, docs-and-eval-cleanup, strict-checks-by-default, drop-keeps-modified. A person can open those rows' "Stays" lines against the cited readers.
- I did not check whether any agent prompt fixed word for word in the deleted files is read by a script. I found none in the sample.
- Whether models actually follow the M-rules is s206's question; nothing here measures it.
- I did not run `bin/po-lint` separately. `test_contract_tests_stay` ran it and passed in my oracle run.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-22T11:02:16+01:00

Diff reviewed: `git diff main...story/s201-routing-phrase-tests-retired`, after fix run 1 (9768252 on top of e2a06af), by a context that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: ed61c9fd308372012eefa43c65b24d71bb1861c6

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s201-routing-phrase-tests-retired` (47 paths) and checked each one against `Owns` at `docs/stories.md:3285`.
- [x] Every path is inside `Owns`. The plan, research, record and review are the story's own evidence. The fix commit touches only five files: the oracle, `docs/harnais.md`, the plan, the record and the review.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane and framing or fix branches, none of them a `story/` branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exit 0. `Verification mode: record`: the unit suite `bash tests/run.sh` (exit 0, 538 s, latest row) is reused and was not rerun. The project has no `Typecheck` (`—`). I read "Not proven here".
- [x] QA not required: `QA stage: —`.

## Plan
- [x] Previous findings, one by one:
  - Major 1 (the count was blind in files that reuse its helpers): **closed**. The markers are now `\0@@FILE ` and `\0@@FUNCS` (`:64`, `:96`, `:128`, `:133`).
  - Major 2 (five checkpoints and stops now held by a model only): no longer a finding (d-0051, option a). The plan still marks them **M**, as candidates for s206, and claims no test for them, which is true. The record (`docs/verif/…:34`) still says "pending the owner's decision d-0051". That was true when written and is now overtaken by the decision. Wording only.
  - Minor on the `drive` row citations: **closed** by the dated note at plan `:106`, which I checked against the cited lines.
  - Minor on `docs/harnais.md`: **partly closed**. The blind spots are listed and an exit for a legitimate drop exists. The new exit has a hole, and one blind spot is still missing. Both are in Findings.
  - Minor on the two completeness checks: closed by filing (#442 comment).
  - Minor on the floor flags: unchanged and still justified. Restated below.
- [x] Nothing outside the oracle, `docs/harnais.md`, the plan note, the record and the review changed in the fix. No test was restored or removed: the oracle still defines its three tests.

## References
- [x] I opened `tests/lib.sh:5-6` (`ROOT`, `METHOD`) and `tests/run.sh` (how a file is sourced). I read the whole reader (`LAUNCH_READER`, `script_launches`, `script_counts`, `scripts_kept_their_tests`).

## Rules
- [x] The `AGENTS.md` conventions are respected. No accepted ADR is contradicted.

## Tests
- Oracle: `po-gate oracle-intact s201-routing-phrase-tests-retired` → exit 0
  tests/routing-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — The reader's two markers start with a NUL (`\0@@FILE `, `\0@@FUNCS`), in `script_launches` and `LAUNCH_READER`. `test_no_script_lost_its_tests` gains a bite on a throwaway copy: a file that sources the helpers, as `docs/harnais.md` says, has its launch counted and its removal named, and this oracle's own `test_contract_tests_stay` is counted as launching `po-lint`. New cksum `511014532 17744` (with the row below). — Review fix loop 1, major at `:96`: the literal `@@FILE ` sat inside `LAUNCH_READER` and the body of `script_launches`, so every file that defines or sources the helpers was cut and none of its tests read. No variable or function body can hold a NUL.
  tests/routing-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — New `LOWERED_COUNTS` (empty), one line `<script> <count on the base> <count after> <story id>` per allowed drop; `scripts_kept_their_tests` lets a drop through only for a line matching the base count exactly, and names the story. The bite: a matching line passes and is named, a line for another base count fails. Same cksum `511014532 17744`. — Review fix loop 1, minor on `docs/harnais.md`: the count had no per-script allowance, so a story rightly removing a script's test had to edit the shared helpers by hand. A line keyed to the base count is explicit in the diff and goes inert once the story ships.
  po-gate: 2 logged oracle change(s) of s201-routing-phrase-tests-retired to judge
- Oracle: `po-gate oracle-intact s201-routing-phrase-tests-retired` → exit 0
  - The file's cksum is `511014532 17744`, as logged. I judged both `## Oracle changes` rows:
  - Row 1 (NUL markers plus a bite on a throwaway copy): it adds assertions and removes none, so it does not weaken the criterion.
  - Row 2 (`LOWERED_COUNTS`): it is empty today, so for s201 the criterion holds exactly as before. Its future allowance is broader than the record and `docs/harnais.md` say; see the first finding.
- [x] Floor: `po-gate floor-guard` exit 1, with the same 14 flags as loop 0, all justified in the plan → minor.
- [x] Bite of the fix, in a throwaway clone of the story branch (base `origin/main` = 8e2a5ad):
  - `test_no_script_lost_its_tests` as committed: rc 0.
  - With the four NUL markers reverted to their e2a06af form: rc 1, stopping at "the launch of a file that sources the count is not counted".
  - Restored, and `git diff --exit-code` was clean.
  - The committed test covers what the lane asked:
    - a file sourcing the helpers as `docs/harnais.md` says has its launch counted (`:280`);
    - removing that launch is named (`:283-285`);
    - this oracle's own `po-lint` launch is counted (`:291-293`).
- [x] `LOWERED_COUNTS` probes, run on a throwaway repo with three `po-gate.sh` launches. Results are in Findings:
  - a line for another script allows nothing;
  - a line without a story id allows nothing;
  - a line with a non-numeric "after" such as `x` allows nothing;
  - a line with base count 3 and "after" 3 does not cover a real count of 2;
  - **a stale line reactivates**;
  - a line whose "after" is `0` or `-` lets the drop through.
- [x] Counts per script, base against story, compared on a throwaway copy:
  - All 705 launch lines of the base are present on the story, so no script lost a launch.
  - The counts are **not** identical any more. The story has 709 lines: po-gate.sh 135→136, pre-commit 31→32, po-lint 24→26. The fix makes the oracle readable to its own count, so its four launch lines now appear.
  - Only `test_contract_tests_stay`→po-lint is a real launch. `test_no_script_lost_its_tests` is counted as launching po-gate.sh, po-lint and pre-commit, but it runs none of them (third finding).
- [x] The blind spots `docs/harnais.md` lists match the reader:
  - a helper sourced inside a test function is not seen, because `declare -f` holds only file-level functions;
  - single-quoted text is dropped by `unquoted`;
  - a path built at run time is not seen;
  - `python3` is not in `readers`, so a `python3 - <script>` that only reads the file counts as a launch.
- [x] Three oracle tests, within `Test budget` 25.

## Neighbours
- [x] The s202 to s204 oracles will source the helper block, `LOWERED_COUNTS` included. Being read at run time, they pick up any line added to it, and their own sums do not move. The stale-line hole below therefore reaches them too.

## Lenses
Lenses run: none. Only bash tests and French docs changed; no path or content triggers a lens.
- [x] No lens findings.

## Findings
- major — tests/routing-phrase-tests-retired.oracle.test.sh:175 — A `LOWERED_COUNTS` line does not go inert once its story ships. It comes back to life whenever the base count passes through its first value again.
    The match keys only on `$2 == old`, and nothing ever removes a line. Probe on a throwaway repo:
    - story sX lowers po-gate.sh 3→2 with the line `po-gate.sh 3 2 sX` and ships;
    - a later story adds a launch, so the base is back at 3;
    - a third story silently drops one launch: `scripts_kept_their_tests` → rc 0, "lowered by sX".
    Counts on busy scripts (po-gate.sh 136, po 178) move by one all the time, so this will happen. `docs/harnais.md:156` ("après le ship, elle ne permet plus rien") and the row-2 justification ("goes inert once the story ships") are false.
    Possible fixes:
    - key the line on the base commit, or on a ref holding the story id that must not be an ancestor of the base;
    - or require the story to delete its line, which `test_no_script_lost_its_tests` can check by failing when a line's story id is already on the base (`git log --grep`).
- minor — tests/routing-phrase-tests-retired.oracle.test.sh:175 — The "after" field acts as a floor (`$3 <= n`), not an exact count. A line keeps allowing drops below what its author wrote.
    - `po-gate.sh 3 0 sW` allows any drop, down to zero launches.
    - A malformed `po-gate.sh 3 - sM` passes too, because awk compares the string `-` and finds it ≤ `2`.
    - `docs/harnais.md:156` calls the field `<compte après>`, which reads as exact.
    - Fix: match `$3 == n` and require `$2` and `$3` to be integers.
- minor — docs/harnais.md:158 — The blind-spot list is missing a false-positive case. Text the reader rebuilds counts as a launch: heredoc bodies, and variable values expanded into a body.
    - This oracle's own `test_no_script_lost_its_tests` counts as launching po-gate.sh and po-lint, through its fixture heredocs (`:247-253`, `:275-278`).
    - It also counts as launching pre-commit, because `$LAUNCH_READER`, expanded in `script_launches`, contains `hooksPath`.
    - Every s202–s204 oracle test that calls these helpers will count pre-commit the same way.
    - This only inflates counts, so no drop slips through. But a later edit to those fixtures shows up as a "lost" launch nobody can explain.
- minor — tests/ship-and-fleet-cleanup.test.sh:17 — The `floor-guard` flags (13 `test-file-deleted`, 1 `assertions-dropped`) remain. All are justified in the plan (tasks 1 and 5, correction 2).

## Not verified
- I did not rerun the full suite. I relied on the `po-run` record (exit 0), which the gate holds current for this code.
- I ran the oracle's `test_no_script_lost_its_tests` directly in the throwaway clone, against that clone's `origin/main` (= local `main` 8e2a5ad), not against the forge's `origin/main`. The forge comparison is covered by the recorded suite run only.
- I did not run `tests/run.sh` on any file. Its cargo build of `po` would have used the clone's memory and disk; the test function was sourced the way `run.sh` sources it instead.
- I did not reopen the classification rows sampled in loop 0. The fix did not touch them.
- Whether models follow the five **M** rules of d-0051 is s206's question; nothing here measures it.
- I did not read `.polype/inbox/` or the private folder. Decision d-0051 is taken as stated by the lane.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-22T11:46:11+01:00

Diff reviewed: `git diff main...story/s201-routing-phrase-tests-retired`, after fix run 2 (8723a75, on top of d83e441, 9768252 and e2a06af), by a context that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: 103b6209824cf5cbe74b2cd936de696a463d6c3b

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s201-routing-phrase-tests-retired` (47 paths) and checked each path against `Owns` (`docs/stories.md`, story at `:3278`).
- [x] Every path is inside `Owns`. Fix run 2 (8723a75) touches only three files:
  - `tests/routing-phrase-tests-retired.oracle.test.sh` and `docs/harnais.md`, both in `Owns`;
  - `docs/verif/s201-routing-phrase-tests-retired.md`, which is the story's own evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows this lane, `framing/adr-0131-0132` and `fix/qa-deadline-wording`. Neither of the other two is a `story/` branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exit 0. `Verification mode: record`, so I reused the unit suite `bash tests/run.sh` and did not rerun it. Its latest row exited 0 (639 s). The project has no `Typecheck` (`—`). I read "Not proven here". It admits that the floor case is untested, and it now cites d-0051 as answered.
- [x] QA not required: `QA stage: —`.

## Plan
- [x] Loop-1 findings, one by one:
  - **Major at `:175`, a stale `LOWERED_COUNTS` line comes back to life: closed.**
    - The fix: `story_landed` (`:155-157`) makes a line inert once a commit of the base ref has a subject starting with `<id>: `. The test function replays the scenario at `:302-308`.
    - Bite M1 (below) shows the check is held.
    - Rebase-merge keeps the subject, and `/po-ship` asks for it (`method/commands/po-ship.md:41`). The real landing `s200-journey-reaches-every-stop: …` on `main` has that shape. No two commits on `main` share a story prefix.
  - **Minor at `:175`, the "after" field acts as a floor and lets `-` through: closed in the code.**
    - `$3 == n` now applies, with both counts required to be integers (`:185`).
    - The exactness itself is not tested (see Findings). The record says so.
  - **Minor on `docs/harnais.md`, a false positive missing from the list: closed.** `:158` now lists heredoc bodies and expanded variable values, with the `pre-commit`/`hooksPath` case.
  - **Minor on the floor flags: unchanged, still justified.** Restated below.
- [x] Fix run 2 removed no test and restored none. The oracle still defines its three tests.

## References
- [x] I read `story_landed` and the new filter in full. I checked:
  - `git log --format=%s <ref>` on the ref that `scripts_kept_their_tests` was given;
  - that `ENVIRON["P"]` with `index(...) == 1` builds no regex from the id;
  - `ci.yml:18` (`fetch-depth: 0`, so CI has full history).

## Rules
- [x] The `AGENTS.md` conventions are respected. No accepted ADR is contradicted. The record's d-0051 line cites the decision by id only.

## Tests
- Oracle: `po-gate oracle-intact s201-routing-phrase-tests-retired` → exit 0
  tests/routing-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — The reader's two markers start with a NUL (`\0@@FILE `, `\0@@FUNCS`), in `script_launches` and `LAUNCH_READER`. `test_no_script_lost_its_tests` gains a bite on a throwaway copy: a file that sources the helpers, as `docs/harnais.md` says, has its launch counted and its removal named, and this oracle's own `test_contract_tests_stay` is counted as launching `po-lint`. New cksum `511014532 17744` (with the row below). — Review fix loop 1, major at `:96`: the literal `@@FILE ` sat inside `LAUNCH_READER` and the body of `script_launches`, so every file that defines or sources the helpers was cut and none of its tests read. No variable or function body can hold a NUL.
  tests/routing-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — New `LOWERED_COUNTS` (empty), one line `<script> <count on the base> <count after> <story id>` per allowed drop; `scripts_kept_their_tests` lets a drop through only for a line matching the base count exactly, and names the story. The bite: a matching line passes and is named, a line for another base count fails. Same cksum `511014532 17744`. — Review fix loop 1, minor on `docs/harnais.md`: the count had no per-script allowance, so a story rightly removing a script's test had to edit the shared helpers by hand. A line keyed to the base count is explicit in the diff and goes inert once the story ships.
  tests/routing-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — A `LOWERED_COUNTS` line is read only while no commit of the base ref (the one `scripts_kept_their_tests` is given) has a subject starting with `<story id>: `, the landing commit `/po-ship` writes; the new helper `story_landed` compares that prefix as a fixed string (awk `index`, no regex built from the id, subjects only). A landed line allows nothing, silently. The "after" field is exact (`$3 == n`), and a line whose second or third field is not a non-negative integer allows nothing. `test_no_script_lost_its_tests` gains two assertions: a line with `-` as its count after does not let the drop through; after `s999-lowered: …` lands and `s998-back` brings the count back, a new drop under the same line is refused. New cksum `1727973062 19069`. — Review fix loop 1, major at `:175`: a line keyed only on the base count came back to life whenever the base passed through that count again, so a later story could drop a launch silently. Minor at the same line: the "after" field acted as a floor and accepted a malformed `-`. A landed line does not fail the test, because its own story cannot delete it.
  po-gate: 3 logged oracle change(s) of s201-routing-phrase-tests-retired to judge
- Oracle: `po-gate oracle-intact s201-routing-phrase-tests-retired` → exit 0, with three logged changes. I judged each one:
  - Rows 1 and 2 were already judged in loop 1.
  - Row 3 (`story_landed`, exact integer counts, two new assertions) only narrows what a line allows. It weakens no criterion. The cksum matches the log (`1727973062 19069`).
- [x] Floor: `po-gate floor-guard … main` exit 1, with the same 14 flags as before (13 `test-file-deleted`, 1 `assertions-dropped`). The plan justifies all of them, so they are minor.
- [x] Baseline: I sourced `lib.sh` and the oracle in `tests/` and ran `test_no_script_lost_its_tests` the way `run.sh` does (without its cargo build). rc 0, against local `origin/main` = `main` = 5dc9fc4.
- [x] Bite, run in the worktree. Each mutation was undone with `git checkout --` and confirmed with `git diff --exit-code`:
  - **M1**: dropped `! story_landed …` from the filter. The test failed: "a LOWERED_COUNTS line whose story has landed let a later drop through … lowered by s999-lowered". **1 failure.**
  - **M2**: changed `$3 == n` back to `$3 <= n`. **0 failures.**
  - **M3**: removed the two integer regexes. **0 failures.** That is right: exact equality already rejects `-`, so the regexes only add a second guard.
  - **M4**: changed `P="$3: "` to `P="$3"` (no `: ` after the id). **0 failures.** No assertion tells `s99` from `s999-…`. Story numbers are unique, so a bare-prefix collision cannot happen between two real ids, and I raise no finding.
  - The `/tmp` entry count was the same before and after every run (445). The test's own `trap` removed its repository.
- [x] Three oracle tests, within `Test budget` 25.

## Neighbours
The s202 to s204 oracles source these helpers. I checked the cases the lane named:
- **Revert commit**: `Revert "sX: …"` does not match, so the line becomes live again. The same revert also takes the line out of `LOWERED_COUNTS`, because the line landed in that commit, so nothing opens.
- **One id a prefix of another**: guarded by the trailing `: `. It is also impossible between real ids, since story numbers are unique (M4 above).
- **Shallow clone**: CI fetches full history. In a shallow local clone, `git log` stops at the graft, so a line that landed beyond it reads as not landed and becomes live again (fail-open). Reaching that needs a shallow clone, a base count back at its first value and a new drop. Not a finding; noted below.
- **Base ref missing**: refused before any count, and the ref is named (`:165-166`, asserted at `:277-278`).
- **`git log` itself failing**: also fails open, but only after the ref was checked.
- **Main moves while the lane runs**: a line keyed to the old base count fails closed in the PR's CI. The story has to rewrite its line. This is safe, and the wording in `docs/harnais.md` implies it.

## Lenses
Lenses run: none. Only bash tests and French docs changed. No path or content triggers a lens.
- [x] No lens findings.

## Findings
- minor — tests/routing-phrase-tests-retired.oracle.test.sh:185 — No assertion holds that the "after" count is exact. Turning `$3 == n` back into `$3 <= n` (M2) fails no test, because the `-` assertion at `:300-301` is already stopped by the integer regex. The floor reading that loop 1 reported could come back unseen. The record admits it ("The floor case … is not exercised by a test"). One assertion would cover it: with `LOWERED_COUNTS='po-gate.sh 1 1 s996-floor'` against a real count of 0, the drop must fail.
- minor — tests/ship-and-fleet-cleanup.test.sh:17 — The `floor-guard` flags remain: 13 `test-file-deleted` and 1 `assertions-dropped`. The plan justifies all of them (tasks 1 and 5, correction 2).

## Not verified
- I did not rerun the full suite. I relied on the `po-run` record (exit 0), which `verif-current` holds current for this code.
- I ran `test_no_script_lost_its_tests` against the local `origin/main` (5dc9fc4), not a fresh fetch from the forge. I made no forge call.
- I did not run `tests/run.sh` on any file, to avoid its cargo build. The function was sourced the way `run.sh` sources it.
- I did not exercise the shallow-clone fail-open of `story_landed` (a local shallow clone with a line that landed beyond the graft). CI uses `fetch-depth: 0`. A person working from a shallow clone should run `git fetch --unshallow` before relying on the count.
- I did not reopen the classification rows sampled in loop 0. Neither fix run touched them.
- Whether models follow the five M rules of d-0051 is a question for s206. Nothing here measures it.
- I did not read `.polype/inbox/` or the private folder.

Max severity: minor
Ship allowed: yes
