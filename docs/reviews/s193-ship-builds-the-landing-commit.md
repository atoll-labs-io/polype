# Review — s193-ship-builds-the-landing-commit

[Story](../stories.md) · [Plan](../plans/s193-ship-builds-the-landing-commit.md) · [Verification](../verif/s193-ship-builds-the-landing-commit.md)

Method version: 0.6.1
Recorded: 2026-11-18T18:11:10+01:00

Diff reviewed: `git diff main...story/s193-ship-builds-the-landing-commit`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 0af9fde5c9357b4093c89311cdfb7d9542ba53f9

## When blocked
- Not blocked. The tree was taken before reading and again before answering, and it had not moved.

## Ownership
Diff listed with `git diff --name-only main...story/s193-ship-builds-the-landing-commit`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The three `docs/{plans,research,verif}/s193-…md` files are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other worktree is `.claude/worktrees/framing-m22` on `fix/qa-deadline-wording`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s193-…`: exit 0. The record is reused: Unit suite `bash tests/run.sh` exit 0. The project has no type check (`Typecheck: —`). I read "Not proven here".
- [x] `po-gate qa-current`: not required, because `QA stage: —`.

## Plan
- [x] Tasks 1–11 are all present.
  - Task 1 lists one task test, and tasks 3, 5 and 6 list six more. The plan names 7 tests in total, so the "8" in its test strategy is a miscount, not a missing test.
  - Departures I judged acceptable: `unknown-option` and `check-unrunnable`, both documented in `docs/interface-agent.md`; `command: null`; the "Unit suite" label.
- [x] Run interdicts, one by one:
  - The diff of `po/src/project.rs`, `record/`, `trust/`, `context/`, `ship/forge.rs`, `method/hooks/`, `method/AGENTS.md`, `po-setup.md`, `po-drive.md`, `.claude/`, `.polype/` and `docs/decisions/` is empty.
  - `## The forge's review rule` and `## Step 3` are unchanged.
  - The only new `Command::new("git")` is in `po/src/ship/git.rs`, which is `pub(super)` inside a private `mod git`. The compiler therefore keeps it inside `po/src/ship/`, as ADR-0130 asks.
  - There is no `push` in `po/src/ship/`.
  - No ADR was written.

## References
- [x] Confirmed: `Project::find` (it resolves the main checkout through `--git-common-dir`, so settings and `root` come from the root and never from the story branch), `project::git`, `output::{reply,error,REFUSED,UNREADABLE}`, `po-gate ship-allowed`/`verif-current`, and `po-run` exit 125.
  - The setting value lists match `method/templates/agents-local.md:52-56`.
- [x] Every git write, and what it can touch:
  - `fetch -q origin` (pr only) updates remote-tracking refs.
  - `add`/`commit -- <paths>` on `story/<id>` commits only those two paths. I probed this: a stray staged file stayed staged and out of the commit.
  - `merge-tree` and `commit-tree` write loose objects and no ref.
  - `merge --ff-only <40-hex>` runs in the root only after `root_clean` is checked again.
  - The id is validated as `s<n>-<slug>` and cannot start with `-`. The title travels as an argv element, never through a shell. I probed a title holding quotes, `$(…)`, backticks and `;`, and it landed verbatim.
  - A dirty root gives `root-not-clean`, tested.
  - A moved base gives `stale-landing`, or makes `--ff-only` fail with `git-failed` and no damage.
  - An untracked root file the merge would overwrite: `--ff-only` refuses and the result is `git-failed` (probed).
  - A refusing pre-commit under `core.hooksPath`: `git-failed`, exit 2, after the checks and before any landing (probed).

## Rules
- [ ] `AGENTS.md` conventions: one gap in `Reads settings:` (minor, below).
- [x] ADR-0080, ADR-0081 and ADR-0130 are followed. The `project.rs:18-19` comment ("po never … writes") is now false for `ship/`, as the ADR-0130 consequences already note. That file is outside `Owns` and under an interdict.

## Tests
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0
- [x] Floor: `po-gate floor-guard … main`: exit 0. Oracle: `po-gate oracle-intact`: exit 0.
- [x] The assertions pin the criteria, against the real hooks copied from `method/hooks/`, with no mock.
- [x] The removed phrase assertions each fell with prose that the code now carries:
  - Step 0's hand fallback, `Review status`, `Reviewed tree:` and `':(exclude)docs'`: the gate tests and `gate_comes_first` still hold the behaviour.
  - merge-tree, commit-tree, `--ff-only` and "never rewritten": held by `one_commit_no_merge` and `local_mode_lands_here`.
  - "single end-to-end run": now has no behavioural test (minor, below).
- [x] Test budget: 12 tests out of 25.
- [x] Bite results, each change undone with `git diff --exit-code` clean:
  - Gate call removed: 1 failing (`gate_comes_first`).
  - `landed = local` (ignoring `--land`): 1 failing (`local_mode_lands_here`).
  - Tree condition of `still_the_landing` neutralised: **0 failing** (major, below).
- [x] No test was made useless.

## Neighbours
- [x] `ship::main` now dispatches `land` before `forge`, so the forge path is unchanged. The usage rows of `docs/interface-agent.md` match the code.
- [x] `po-setup.md:67` ("Remote check, as in `/po-ship`") and `:81` (the settings commit) remain true.

## Lenses
Lenses run: dependencies — `po/Cargo.lock` changed. Only `po`'s own version line moved; no dependency entry changed.
- [x] Nothing from the lens to report.

## Findings
- major — po/src/ship/land.rs:526 — A rerun after a local landing does not recognise that the story already landed, for example `/po-ship` interrupted between the fast-forward and Step 3.
  - Reproduced on a scratch repo with `Full suite: execute-end` and the suite recorded: the second `po ship land s01-a --land` returned `landed: true` and put a second, empty commit `s01-a: Un titre` on `main`, which then held two commits for one story.
  - When the checks append rows instead, the second run runs the checks and commits `s01-a: review` on `story/<id>`. It then answers `conflict` on `docs/verif/<id>.md`, "a human resolves it". That also breaks `conflict_goes_to_a_human`'s "n'écrit rien" on the second-probe path (`:524`).
  - The old prose had the same gap, so this is not a regression. It is local only and nothing is pushed.
  - A cheap guard: refuse, or report already landed, when `merge-tree <base> story/<id>` equals `<base>^{tree}` and `<base>`'s subject is `<id>: <title>`, before any check runs.
- major — po/src/ship/land.rs:463 — No test holds the tree condition of `still_the_landing`; neutralising it leaves all 12 tests green.
  - `test_stale_landing_is_refused` only moves the base, which the parent condition already catches.
  - This condition is the pivot's own named risk: a docs-only commit on `story/<id>` between the build and `--sha` changes the tree. Without the condition, the `--sha` call lands a commit that misses it.
- major — method/commands/po-ship.md:11 — `E2E scope` and `E2E browsers` left `Reads settings:`, and nothing at ship reads them any more.
  - `po ship land` runs `<E2E>` verbatim, which the plan decided.
  - But `method/templates/agents-local.md:55` still says of `E2E browsers` "Ship uses them all", and the `testing-doctrine` stage table still lists both settings for the end-to-end run at ship.
  - Old Step 1 ("limited to `E2E scope`, across every browser the project configures") was dropped rather than moved: a project with `E2E scope: nominal` now gets whatever its `<E2E>` command runs.
  - Either the command applies them, or the template and doctrine say they no longer reach ship. Both files are outside this story's `Owns`, so this needs an issue or a story.
- major — po/src/ship/land.rs:531 — `--land` is accepted whatever the effective `Ship confirmation` is, so the human checkpoint in local mode rests only on prose.
  - The prose itself is firm enough: `po-ship.md:36` and `:56` both say it, and the forge rule settles the effective value before Step 1.
  - Plainly, I think the code should hold it. Under `Merge mode: local` there is no `origin`, so the effective value is just the line's value as read by `effective()` (`po/src/ship/mod.rs:37-41`), without any forge call. Refusing `--land` unless that value is `automatic` costs a few lines in the same module and takes a person's approval out of a model's hands.
- minor — method/commands/po-ship.md:11 — `E2E stage` was dropped from `Reads settings:`, but the `ci` bullet (`:37`) and the `Forge checks: —` fallback still need it to know whether a `ci` stage exists. This breaks the convention that the line lists every setting the command reads.
- minor — method/commands/po-ship.md:37 — The `ci` bullet lost "(only meaningful with `Merge mode: pr`)" and now reads as if it applied under `local`, where there is no pull request.
  - The other cuts in the `pr` bullets only removed reasons or restatements and lost no rule: "replaced by the push", "its full SHA", "whose committer date differs", "the human's decision point", "`<sha>` being the pushed head", "stays open".
- minor — tests/ship-builds-the-landing-commit.test.sh:78 — No test sets `E2E stage: ship`, `Build stage: ship` or `--routes yes`, so the `<E2E>`/`<Build>` branches of `checks()` (`land.rs:375-379`) are untested; a swap or a wrong match arm would pass. The record names this gap.

## Not verified
- How a model follows the new `po-ship.md` (`ship_command_calls_it`): I judged it by reading only. It is a candidate for a `po-eval` control arm (#208).
- I did not exercise the real Polype pre-commit on the `<id>: review` commit, only a refusing stand-in hook. A person should run one local ship on a project with `core.hooksPath=.polype/hooks`.
- I did not exercise a failing `git fetch`, a real `<E2E>`/`<Build>` through `po-run`, or a git older than 2.38 (no `merge-tree --write-tree`).
- The full suite was not rerun here: I relied on the record (unit suite, exit 0, on this code outside `docs/`).
- No forge was called and nothing was pushed. The probes ran on throwaway repos under a `mktemp -d` folder, which has been removed.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T18:25:54+01:00

Diff reviewed: `git diff main...story/s193-ship-builds-the-landing-commit`, in a context that did not write it. Fix run 1 is commit f04ee55, on top of 077c132.

Review status: complete
Fix loop: 1
Reviewed tree: 1b5dc06e1909407920952b8921374efd0bc74107

## When blocked
- Not blocked. I took the tree before reading the diff and again before answering. It had not moved, and the worktree is clean (`git diff --exit-code` and `git status --porcelain` both empty).

## Ownership
I listed the diff with `git diff --name-only main...story/s193-ship-builds-the-landing-commit` and held each path against the story's `Owns` (`docs/stories.md:3138`).
- [x] Every path is inside `Owns`. `docs/{plans,research,reviews,verif}/s193-…md` are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other worktree is `.claude/worktrees/framing-m22` on `fix/qa-deadline-wording`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s193-…` exited 0. The record's last row is `Unit suite`, `bash tests/run.sh`, exit 0, on the fix's code. I relied on it and did not run the full suite again. The project has no type check (`Typecheck: —`). I read "Not proven here".
- [x] `po-gate qa-current` is not required, because `QA stage: —`.
- I ran `bash tests/run.sh` only on the story's two test files: 15 of 15 pass on the committed code.

## Plan
- [x] Tasks 1–11 are present (checked in loop 0). The fix adds:
  - the `already_landed` guard;
  - the `confirmation-required` refusal;
  - the tests the loop-0 findings asked for;
  - matching rows in `docs/interface-agent.md` (they agree with the code: `confirmation-required` exit 1, `already_landed` in the reply).
- [x] Leaving `--sha` unguarded is right. That call is the one a person's Merge answer triggers, and `po` cannot see that answer.
- [x] Reading the line rather than the effective value is right under `local`. With no `origin`, `effective()` (`po/src/ship/mod.rs:37-41`) returns the line's value, and `(forge)`/`(chosen)` are stripped by the same `origin()`.
- [x] Run interdicts: the diff is empty for every interdicted path. There is no new `Command::new("git")` outside `po/src/ship/git.rs`, and no `push` in `po/src/ship/`.
- [x] The two cut sentences of `po-ship.md` lose no rule:
  - "nothing in `## The forge's review rule` opens or skips it" is still said at `:25`.
  - "`po` missing → `polype install`" is still said at `:27`, which runs before Step 1.
  - The file has 2 298 words (`LC_ALL=C wc -w`), against 2 700 on `main`: 402 fewer.
- [x] `ship_command_calls_it`, judged by reading: Step 1 is one call to `po ship land`, and it names each refusal's next move, including `already_landed` → Step 3.

## Status of the previous findings
- major `land.rs:526`, rerun after landing: **partly closed**.
  - The guard catches a rerun while the landing commit is still the tip of the base. `test_rerun_after_landing_writes_nothing` holds this, and my probe under `pr` confirms it.
  - A rerun after the base has moved still lands a second commit (new major, below).
- major `land.rs:463`, tree condition of `still_the_landing`: **closed**. It is held by the second case of `test_stale_landing_is_refused`, and that test bites.
- major `po-ship.md:11`, `E2E scope` and `E2E browsers`: **still open, filed as #395**. Not raised again.
- major `land.rs:531`, `--land` accepted whatever the confirmation: **closed**. `confirmation_allows_landing` and `test_land_needs_automatic` hold it, and the test bites.
- minor `po-ship.md:11`, `E2E stage` missing from `Reads settings:`: **closed**.
- minor `po-ship.md:37`, the `ci` bullet: **closed**. It now says "under `Merge mode: pr`".
- minor, the `<E2E>`/`<Build>` branches untested: **closed** by `test_e2e_and_build_run_at_ship`, which bites.

## Rules
- [x] ADR-0080, ADR-0081 and ADR-0130 are followed.
- [x] `AGENTS.md` conventions: the `Reads settings:` line is now complete.

## Tests
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0
  tests/ship-builds-the-landing-commit.oracle.test.sh: changed, logged in ## Oracle changes — The fixture of `project` writes one more setting line, `Ship confirmation: automatic`; no assertion changes (cksum `4197583642 9815`). — Fix run, review major at `land.rs:531`: `po` now refuses `--land` unless the `Ship confirmation` line reads `automatic`, so `test_local_mode_lands_here`, which calls `--land` as an effective `automatic` would, needs the project to declare it.
  po-gate: 1 logged oracle change(s) of s193-ship-builds-the-landing-commit to judge
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0, with one logged change to judge.
  - The change adds the fixture line `Ship confirmation: automatic`. The cksum `4197583642 9815` matches the file, and no assertion changed.
  - It does not weaken any criterion: `local_mode_lands_here` still lands under `--land`, now as an effective `automatic` really would.
- [x] Floor: `po-gate floor-guard … main` → exit 0.
- [x] No test is coverage only in appearance. The hooks are the real ones from `method/hooks/`, with no mock, and `true`/`false` stand in for the commands.
- [x] Test budget: 15 tests out of 25.
- [x] Bite. Each mutation ran against `tests/ship-builds-the-landing-commit.test.sh` only and was undone with `git checkout --`, and `git diff --exit-code po/src/ship/land.rs` was clean after each one:
  - `already_landed` forced to `None`: 1 failing (`rerun_after_landing_writes_nothing`, which now gets `conflict`).
  - Tree condition of `still_the_landing` neutralised: 1 failing (`stale_landing_is_refused`, second case).
  - `confirmation_allows_landing` skipped: 1 failing (`land_needs_automatic`).
  - `("ship-if-route", Some(true))` arm removed: 1 failing (`e2e_and_build_run_at_ship`).
  - E2E check given `<Build>`'s command: 1 failing (`e2e_and_build_run_at_ship`).
  - After the mutations I rebuilt `po` from the committed code: 10 of 10 pass.

## Neighbours
- [x] Step 3's proof under `local` (`merge-base --is-ancestor <sha> <Target>`) holds when `sha` is the base, as `already_landed` returns it.
- [x] Under `pr`, `already_landed` → Step 3 still needs `MERGED` from the forge, so reporting a merged pull request as landed is truthful. My probe confirms it: I pushed the landing commit to origin's `main` as a rebase merge would, and the rerun answered `already_landed: true` with that sha.
- [x] Can the guard fire on a story that has not landed?
  - A base tip that carries the same subject but not the story's code does not fire (probed).
  - It fires only when the tip carries the subject `<id>: <title>` and `story/<id>` brings nothing to it. I probed a story with no commit of its own on such a tip: it answers `landed: true` and leaves the uncommitted review behind.
  - Ids are never reused, so that state only exists after a real landing. I judged it acceptable and raise no finding.

## Lenses
Lenses run: none. The lockfile change only moves `po`'s own version, so the dependencies lens has nothing to judge. No other lens's trigger is in the diff.

## Findings
- major — po/src/ship/land.rs:489 — `already_landed` recognises a landing only while it is still the tip of the base. Once `Target branch` has moved past it, a rerun lands the same story a second time.
  - Reproduced on a scratch repo under `Merge mode: local`, with `Full suite: execute-end` and the suite recorded:
    - `po ship land s01-a --land` landed;
    - one more commit went on `main`;
    - a second `--land` returned `landed: true, already_landed: false`, and `main` then held two commits `s01-a: Un titre`, the second one empty.
  - When the checks append record rows instead, the rerun commits on `story/<id>` and answers `conflict` on `docs/verif/<id>.md`, "a human resolves it", for a story that already landed.
  - Under `pr`, the same rerun after the pull request merged and `origin/<Target>` moved builds an empty landing commit for s194 to push.
  - This is local, nothing is pushed, and the loop-0 guard itself suggested checking only the tip, so it is a narrowing of the old major, not a regression.
  - A fix that does not depend on the subject: when `merge-tree <base> story/<id>` equals `<base>^{tree}` (the story brings nothing), report `already_landed` or refuse, before any check. Or look for an ancestor of the base with the subject `<id>: <title>` and that tree.

## Not verified
- How a model follows the new `po-ship.md` (`ship_command_calls_it`, the `already_landed` → Step 3 route): judged by reading only. It is a candidate for a `po-eval` control arm (#208).
- These branches have no test, and I read them without running them:
  - `missing-setting` for `Ship confirmation` under `--land`;
  - the second conflict after the docs commit.
- I exercised the `pr` already-landed path only by pushing to a local bare origin, never through a real forge or a real rebase merge.
- I never exercised the real Polype pre-commit under `core.hooksPath` on the `<id>: review` commit. A person should run one local ship on a project with the hooks on.
- I did not run a real `<E2E>`/`<Build>`, a failing `git fetch`, or a git older than 2.38.
- The full suite was not rerun: I relied on the record, which passes `verif-current` on this code outside `docs/`.
- No forge was called, nothing was pushed, and the decision inbox was not read. The probes ran on throwaway repos under `mktemp -d` whose only remote was a local bare repository, and their folders were removed.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T18:40:28+01:00

Diff reviewed: `git diff main...story/s193-ship-builds-the-landing-commit`, in a context that did not write it. Fix run 2 is commit 653bc4b, on top of f04ee55 and 077c132.

Review status: complete
Fix loop: 2
Reviewed tree: 53621f7116df9fa9ab470b8ac2b814af7adc9bb6

## When blocked
- Not blocked. I took the tree before reading the diff and again before answering, and it had not moved. `git diff --exit-code` and `git status --porcelain` are both empty in the worktree.

## Ownership
I listed the diff with `git diff --name-only main...story/s193-ship-builds-the-landing-commit` and held each path against the story's `Owns` in `docs/stories.md`.
- [x] Every path is inside `Owns`. Fix run 2 touched only `po/src/ship/land.rs`, `docs/interface-agent.md` and `tests/ship-builds-the-landing-commit.test.sh`, plus the story's own `docs/{reviews,verif}/s193-…md`.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other worktree is `.claude/worktrees/framing-m22` on `fix/qa-deadline-wording`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s193-ship-builds-the-landing-commit` → exit 0.
  - The last `Unit suite` row (`bash tests/run.sh`, exit 0) is on this code outside `docs/`. I relied on it and did not run the full suite.
  - The project has no type check (`Typecheck: —`).
  - I read "Not proven here".
- [x] `po-gate qa-current` is not required, because `QA stage: —`.
- I ran `bash tests/run.sh ship-builds-the-landing-commit.test.sh` on the committed code: 11 of 11 pass.

## Plan
- [x] Tasks 1–11 were checked in loops 0 and 1. Fix run 2 changes only the `already_landed` guard and its tests, and updates the `ship land` row of `docs/interface-agent.md` to match.
- [x] The code matches the row.
  - The probe now runs once, before the guard.
  - The guard fires when `merge-tree <base> story/<id>` equals `<base>^{tree}`.
  - `sha` is the newest commit in `<base> ^story/<id>` whose subject is exactly `<id>: <title>` (fixed-string `--grep`, then an exact compare), else `<base>`.
  - The same probe result then feeds `--sha` and the first conflict check.
- [x] Run interdicts: there is no new `Command::new("git")` outside `po/src/ship/git.rs`, and no `push` in `po/src/ship/`.

## Status of the previous findings
- major `po/src/ship/land.rs:489`, a rerun after the base moved past the landing: **closed for the case it describes**. A rerun after `Target branch` moved on through commits that leave the story's lines alone now answers `already_landed: true` with the landing's sha and writes nothing. This holds under `local` and after a merged pull request under `pr`, and both new tests bite (below).
  - One case is still uncovered: later commits that touch the story's own lines (new major, below).
- #395, #384, #389, #396: still open, already filed, not raised again.

## Rules
- [x] ADR-0080, ADR-0081 and ADR-0130 are followed. The guard writes nothing and sits after the gate, the settings, the remote check and `root_clean`.
- [x] `AGENTS.md` conventions hold.

## Tests
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0
  tests/ship-builds-the-landing-commit.oracle.test.sh: changed, logged in ## Oracle changes — The fixture of `project` writes one more setting line, `Ship confirmation: automatic`; no assertion changes (cksum `4197583642 9815`). — Fix run, review major at `land.rs:531`: `po` now refuses `--land` unless the `Ship confirmation` line reads `automatic`, so `test_local_mode_lands_here`, which calls `--land` as an effective `automatic` would, needs the project to declare it.
  po-gate: 1 logged oracle change(s) of s193-ship-builds-the-landing-commit to judge
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0
  tests/ship-builds-the-landing-commit.oracle.test.sh: changed, logged in ## Oracle changes — The fixture of `project` writes one more setting line, `Ship confirmation: automatic`; no assertion changes (cksum `4197583642 9815`). — Fix run, review major at `land.rs:531`: `po` now refuses `--land` unless the `Ship confirmation` line reads `automatic`, so `test_local_mode_lands_here`, which calls `--land` as an effective `automatic` would, needs the project to declare it.
  po-gate: 1 logged oracle change(s) of s193-ship-builds-the-landing-commit to judge
- [x] Oracle change judged: it is the same fixture line judged in loop 1. Fix run 2 left the oracle file alone. It weakens no criterion.
- [x] Floor: `po-gate floor-guard s193-ship-builds-the-landing-commit main` → exit 0.
- [x] No test is coverage only in appearance.
  - The tests use the real hooks from `method/hooks/`, with no mock.
  - `test_rerun_after_landing_writes_nothing` now covers both kinds of check: checks that append record rows, and a suite already recorded.
  - Both rerun tests move `main` after the landing.
- [x] Test budget: 16 tests out of 25 (5 oracle, 11 task).
- [x] Bite. Each mutation was run against `tests/ship-builds-the-landing-commit.test.sh` (plus the oracle file for the third) and undone with `git checkout --`. `git diff --exit-code po/src/ship/land.rs` was clean after each one.
  - `already_landed` forced to return `None`: 2 failing (`rerun_after_landing_writes_nothing`, `rerun_after_a_merged_pull_request`).
  - Landing search dropped (`sha` always the base): 2 failing (the same two).
  - Tree-equality condition removed (fires on any clean merge): 10 failing, including `local_mode_lands_here` and `one_commit_no_merge`. So the condition that keeps the guard off a story that still brings something is held.

## Neighbours
- [x] `po-ship.md:39` routes `already_landed` to Step 3.
  - Under `local`, the proof (`merge-base --is-ancestor <sha> <Target branch>`) holds for both values of `sha`.
  - Under `pr`, the proof still needs `MERGED` from the forge.
- [x] I probed the guard's input with `git merge-tree --write-tree` on a throwaway repository under `mktemp -d`, since removed:
  - **The story brings something and has not landed:** the result differs from the base's tree, so the guard cannot fire. The third mutation confirms this.
  - **The story branch brings nothing** (no commit of its own): `merge-tree` gives back the base's tree, so `po` answers `landed: true, already_landed: true` with `sha` = the base (minor, below).
  - **After a landing, a later commit edits a line the story changed:** `merge-tree` exits 1 with `CONFLICT (content)`. `po` therefore answers `conflict` with `paths`, "a human resolves it", exit 1, and writes nothing.
  - **After a landing, a later commit removes or reverts what the story brought:** `merge-tree` exits 0 with a tree that puts the story's change back. The guard misses, and the run goes on to the checks, the `<id>: review` commit and a second landing commit (major, below).

## Lenses
Lenses run: dependencies — `po/Cargo.lock` is in the diff. Only `po`'s own version line moved; no dependency entry changed, and fix run 2 did not touch either manifest.
- [x] Nothing from the lens to report.

## Findings
- major — po/src/ship/land.rs:491 — After a story landed, a rerun only sees the landing while the later commits on `Target branch` leave the story's lines alone. Otherwise the tree test fails and the subject is never consulted.
  - **A later commit edits a line the story changed** (the next story raising the same version line, a common case in a fleet): `po` answers `conflict` on that path, "a human resolves it", exit 1, and writes nothing.
    - This is contained: the ship stops and goes to a person. But it sends a person a false conflict for a story that has already landed.
  - **A later commit deletes a line or a file the story added, or reverts a line it changed:** the three-way merge puts the story's change back with no conflict. The rerun then:
    - runs the checks;
    - commits `<id>: review` on `story/<id>`;
    - builds a second `<id>: <title>` commit that undoes the later commit's work.
    - Under `local --land` it fast-forwards the root. Under `pr` it hands that commit to the push.
    - I confirmed the `merge-tree` outcome on a scratch repository. I could not run `po` itself on it (see `## Not verified`).
  - This only happens on a rerun of a story that already landed (a ship interrupted before cleanup), and it is no regression over `main`'s prose ship. So I grade it major, not critical. It goes to the tracker, since this was the last fix run.
  - `docs/interface-agent.md:273` ("même si la base a avancé depuis") and the record's "Not proven here" understate this second case. The record says only "a different tree or a conflict", not that the different tree lands again.
  - A fix that closes both cases: report `already_landed` when a commit of `<base> ^story/<id>` carries exactly the subject `<id>: <title>`, whatever the tree. Ids are never reused, and the lookup is already written at `land.rs:495-499`. Keep the tree test for a base that holds the story without that subject.
- minor — po/src/ship/land.rs:488 — A story branch with no commit of its own is reported `landed: true, already_landed: true`, with `sha` = the base, though nothing ever landed.
  - Step 3 then proves the landing trivially under `local` and may file the review's findings before it stops on the uncommitted review.
  - Reaching ship this way needs a review whose `Reviewed tree:` equals the base's tree, so it is rare. Refusing a branch that brings nothing, when no commit carries the subject, would be truthful.

## Not verified
- **The fix run's probes, run without `po`.** po-bounds refused two probes:
  - the fixture-driven probe script (`git reset runs in an unknown or missing directory`);
  - writing the review file into a scratch story worktree (`story s01-a has no **Owns** line in docs/stories.md`).
  - I did not route around the hook. The three cases above (empty branch, later edit, later revert) were established with `git merge-tree` alone on the scratch repository, and what `po` does next was read from `land.rs:529-611`.
  - A person should run `po ship land s01-a --land` twice on a scratch project where a commit between the two runs reverts `code.txt`, and confirm that `main` gets a second `s01-a:` commit.
- **The `^story/<id>` exclusion of the landing search.** No test exercises it, and its case (the local `story/<id>` holding the landing commit) cannot arise while `po` never moves that branch. I judged it by reading.
- **How a model follows the new `po-ship.md`** (`ship_command_calls_it`, the `already_landed` → Step 3 route). I judged it by reading only. It is a candidate for a `po-eval` control arm (#208).
- **Branches with no test**, read without running them:
  - `missing-setting` for `Ship confirmation` under `--land`;
  - the second conflict after the docs commit.
- **Things no review has exercised:**
  - the real Polype pre-commit under `core.hooksPath` on the `<id>: review` commit;
  - a real `<E2E>` or `<Build>`;
  - a failing `git fetch`;
  - a git older than 2.38.
  - A person should run one local ship on a project with the hooks on.
- **The `pr` already-landed path.** It was exercised only through the test's local bare origin, never a real forge or a real rebase merge.
- **The full suite was not rerun.** I relied on the record, which passes `verif-current` on this code outside `docs/`.
- **Nothing outside the scratch repositories was touched.** No forge was called, nothing was pushed, and the decision inbox was not read. The test runs and the probe used throwaway repositories under `mktemp -d`, which are removed.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-19T11:19:01+01:00

Diff reviewed: `git diff main...story/s193-ship-builds-the-landing-commit`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 3
Reviewed tree: a4f553e534adee1e3eb56a9ab86721a3024f1beb

## When blocked
- Not blocked. I took the tree before reading the diff and again before answering, and it had not moved. `git diff --exit-code` and `git status --porcelain` are both empty in the worktree after every mutation.

## Ownership
I listed the diff with `git diff --name-only main...story/s193-ship-builds-the-landing-commit` and checked each path against the story's `Owns` in `docs/stories.md`.
- [x] Every path is inside `Owns`. Fix run 3 (27c621a) touched only `po/src/ship/land.rs`, `docs/interface-agent.md` and `tests/ship-builds-the-landing-commit.test.sh`, plus the story's own `docs/{reviews,verif}/s193-…md`.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s193-ship-builds-the-landing-commit` → exit 0.
  - The last `Unit suite` row (`bash tests/run.sh`, exit 0, 2026-11-19T10:13:38Z) is on this code outside `docs/`. I relied on it and did not run the full suite.
  - The project has no type check (`Typecheck: —`).
  - I read "Not proven here".
- [x] `po-gate qa-current` is not required, because `QA stage: —`.
- I ran `bash tests/run.sh ship-builds-the-landing-commit.test.sh` on the committed code: 13 of 13 pass.

## Plan
- [x] Tasks 1–11 were checked in the earlier loops. Fix run 3 changes only the already-landed guard, its tests and the `ship land` row of `docs/interface-agent.md`.
- [x] The row matches the code:
  - The subject step runs before the probe.
  - `nothing-to-land` exits 1.
  - The tree step answers with `sha` = the base.
  - The gap it does not cover is stated.
- [x] Run interdicts: there is no new `Command::new("git")` outside `po/src/ship/git.rs`, and no `push` in `po/src/ship/`.

## References
- [x] `read`, `landing_by_subject`, `brings_nothing` and `already_landed` (`land.rs:484-520`) are new local helpers. `project::git` (`po/src/project.rs`) gives `Some("")` on an empty `git log`, so the subject step falls through correctly.
- [x] `po-ship.md:39` routes `already_landed` to Step 3. `nothing-to-land` falls under "any other refusal → stop, quoting its `message`".

## Status of the previous findings
- **major `po/src/ship/land.rs:491` — closed.** A commit of `<base> ^story/<id>` whose subject is exactly `<id>: <title>` now answers `already_landed` before the probe, whatever later commits did to the story's lines. I checked this in two ways:
  - The tests below.
  - A probe with the real binary: land, revert `code.txt` on `main`, rerun with `--land` → `already_landed: true` with the first landing's sha, and `main` holds one `s01-a:` commit.
- **minor `po/src/ship/land.rs:488` — closed.** A branch with no change of its own since its merge base, and with no subject match, is refused as `nothing-to-land` (exit 1, nothing written).
- #395, #384, #389, #396: still open, already filed, not raised again.

## The subject step on its own merits
I probed this with the real binary on throwaway projects built by the oracle's fixture. The scratch directories are removed.
- **Regex and shell characters.** Title `Un [t]itre.* (é) $HOME `x` \d+`:
  - `--grep` runs with `-F`, and no shell is involved.
  - A base commit `s01-a: Un tXitre-- (é) /home `x` 9`, which would match the title read as a regex, did not fire the step.
  - The landing, and a rerun after a later revert, were then found exactly once.
- **Body quote.** A base commit whose body quotes `s01-a: Un titre` did not fire.
- **Prefixes.** None of these fired:
  - `s01-a: Un titre long` (the title as a prefix);
  - `s01-ab: Un titre` (a longer id);
  - `xs01-a: Un titre`.
  - The final `found == subject` check on `%s` is what rejects all of them (see the finding).
- **The implementer's own commit.** It carries the same `<id>: <title>` subject but lives on `story/<id>`, and `^story/<id>` excludes it.
- **`already_landed` for `--sha`.** This answer is right:
  - After an interrupted `--sha` whose fast-forward happened, the rerun now answers `already_landed: true` with the same sha (probed). Before, it would have been `stale-landing`, because the parent check fails once the base moved.
  - When another landing of the same story is on the base, the reply carries that commit's sha, not the requested one, so it never claims the requested commit landed.
- **A second landing.** I found no path left where a rerun builds or lands a second commit of a story whose landing kept its subject.
- **The gap the record names** (a landing whose subject was changed, for example a squash appending ` (#N)`) does not matter under ADR-0081:
  - `gh pr merge --rebase` (`po-ship.md:52`) and the GitLab and Forgejo fast-forward modes keep the subject. Under `local` there is no forge squash at all.
  - It arises only when a person merges by squash in the forge's interface. Even then, the tree step catches the common case.
  - What remains (a squash, then later edits of the story's lines) would build a new commit for a pull request a person sees, never a silent landing. No finding.

## Rules
- [x] ADR-0080, ADR-0081 and ADR-0130 are followed. The guard writes nothing and sits after the gate, the settings, the remote check and `root_clean`.
- [x] `AGENTS.md` conventions hold.

## Tests
- Oracle: `po-gate oracle-intact s193-ship-builds-the-landing-commit` → exit 0
  tests/ship-builds-the-landing-commit.oracle.test.sh: changed, logged in ## Oracle changes — The fixture of `project` writes one more setting line, `Ship confirmation: automatic`; no assertion changes (cksum `4197583642 9815`). — Fix run, review major at `land.rs:531`: `po` now refuses `--land` unless the `Ship confirmation` line reads `automatic`, so `test_local_mode_lands_here`, which calls `--land` as an effective `automatic` would, needs the project to declare it.
  po-gate: 1 logged oracle change(s) of s193-ship-builds-the-landing-commit to judge
- [x] Oracle: `po-gate oracle-intact` → exit 0. Its one logged change (the `Ship confirmation: automatic` fixture line) was judged in loop 1, and fix run 3 left the oracle file alone. It weakens no criterion.
- [x] Floor: `po-gate floor-guard s193-ship-builds-the-landing-commit main` → exit 0.
- [x] None of the six empty test shapes. The tests use the real `po-gate.sh` and `po-run.sh` and a local bare origin. The new tests check the later work stays on `main` (`show main:<file>`).
- [x] Test budget: 18 tests out of 25 (5 oracle, 13 task).
- [x] Bite. Each mutation was undone with `git checkout --`, and `git diff --exit-code po/src/ship/land.rs` was clean after each one.
  - **Subject step disabled** (`landing_by_subject(...).filter(|_| false)`): 3 tests fail.
    - `rerun_after_later_work_on_the_story_lines`: its edit half answers `conflict`.
    - `rerun_after_a_merged_pull_request`.
    - `rerun_after_landing_writes_nothing`.
    - The revert half, run alone against the mutant through a one-case probe script, also fails. It answered `conflict` on `docs/verif/s01-a.md` once the review was committed: the checks ran and the docs commit was made.
    - So `test_rerun_after_later_work_on_the_story_lines` bites on both halves.
  - **`nothing-to-land` refusal disabled** (`if false && brings_nothing(...)`): 1 test fails, `branch_bringing_nothing`. The mutant answered `landed: true, already_landed: true` with the base as sha.
  - **Exact subject check removed** (`.filter(|(_, found)| true || *found == subject)`): 0 of 18 fail across both files (finding below).

## Neighbours
- [x] `po-ship.md:39` and Step 3's landing proof read `sha`. Under `local`, `merge-base --is-ancestor` holds for a landing found by subject and for the base. Under `pr`, the proof still needs `MERGED`.
- [x] `still_the_landing` was only refactored onto the shared `read` helper, with the same three checks.

## Lenses
Lenses run: dependencies — `po/Cargo.lock` and `po/Cargo.toml` are in the diff. Only `po`'s own version line moved; no dependency entry changed, and fix run 3 touched neither file.
- [x] Nothing from the lens to report.

## Findings
- major — po/src/ship/land.rs:494 — The exact subject check `*found == subject` in `landing_by_subject` is held by no test. Removing it fails 0 of the 18 tests of the story's two files.
  - It is the only thing between `git log -F --grep`, which matches any line of any message holding the subject as a substring, and a false `already_landed`.
  - Without it, my probes answered `landed: true, already_landed: true` for a story that never landed in two cases:
    - a base commit that quotes `s01-a: Un titre` in its body;
    - a base commit titled `s01-a: Un titre long`.
    - A `Revert "<id>: <title>"` subject is the same shape.
  - Under `local`, Step 3's `--is-ancestor` proof would then pass on that unrelated commit, and cleanup would follow.
  - The code is correct today, so the ship may go. But the guard against the step's one false positive is untested: one task test with such a base commit would hold it.

## Not verified
- **Squash-merged landings.** A squash with a changed subject followed by later edits of the story's lines was read from the code, not run (see the subject step section).
- **The `^story/<id>` exclusion of the landing search.** No test exercises a local `story/<id>` that holds a landing commit. I judged it by reading. s194, which pushes the landing to the story branch, should keep the local ref unmoved.
- **How a model follows the new `po-ship.md`** (`ship_command_calls_it`, the `already_landed` → Step 3 route, `nothing-to-land` as "any other refusal"). I judged it by reading only. It is a candidate for a `po-eval` control arm (#208).
- **Branches with no test**, read without running them:
  - `missing-setting` for `Ship confirmation` under `--land`;
  - the second conflict after the docs commit (the subject-step mutant reached it, so it fires, but no test asserts it);
  - story commits that undo each other, refused as `nothing-to-land`.
- **Things no review has exercised:**
  - the real Polype pre-commit under `core.hooksPath` on the `<id>: review` commit;
  - a real `<E2E>` or `<Build>`;
  - a failing `git fetch`;
  - a git older than 2.38.
  - A person should run one local ship on a project with the hooks on.
- **The `pr` already-landed path.** It was exercised only through the test's local bare origin, never a real forge or a real rebase merge.
- **The full suite was not rerun.** I relied on the record, which passes `verif-current` on this code outside `docs/`.
- **Nothing outside the scratch repositories was touched.**
  - No forge was called, nothing was pushed, and the decision inbox was not read.
  - The probe scripts and scratch projects lived under `mktemp -d`, and those directories are removed.
  - `po/target/release/po` was rebuilt from the committed source after the last mutation.

Max severity: major
Ship allowed: yes
