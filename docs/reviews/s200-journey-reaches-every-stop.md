# Review — s200-journey-reaches-every-stop

[Story](../stories.md) · [Plan](../plans/s200-journey-reaches-every-stop.md) · [Verification](../verif/s200-journey-reaches-every-stop.md)

Method version: 0.11.0
Recorded: 2026-11-21T12:36:23+01:00

Diff reviewed: `git diff main...story/s200-journey-reaches-every-stop`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 40e39be3800b4fd9ccb91e1a62f9f608c62861d7

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s200-journey-reaches-every-stop`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `tests/journey/**`, the two `journey-reaches-every-stop` test files and `docs/harnais.md` are all listed in `Owns`. Research, plan and verification are the story's own evidence.
- [x] Nothing outside `Owns`. `po/`, `method/`, `bin/`, `tests/lib.sh`, `answers/plain/` and both s199 test files are untouched: `git diff --quiet` gave 0 on those paths.
- [x] No path inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s200-journey-reaches-every-stop` exited 0, so the record is reused. The unit suite `bash tests/run.sh` passed (exit 0) on this code. The project has no type check (`Typecheck: —`). I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. `QA stage: —` and `Surface: command`, so the story does not go to QA.

## Plan
- [x] All ten tasks are present and nothing falls outside the plan. The implementer named these departures, and each one holds:
  - numbered answers `<stem>.<n>.<ext>`;
  - a tenth test, still within `Test budget` 25;
  - extra helpers in `journey.sh`;
  - the double merging onto the pull request's own base;
  - `po ship push` skipped when `po ship land` answers `already_landed: true`, which follows `method/commands/po-ship.md:35` ("`already_landed` → Step 3").
- [x] The planner raised the track from flow to full, and that is justified. The story has ten tasks, about 1,300 added lines, a new script, a forge double and eight answer folders. That is too much for research and plan in one file. The plan says the complexity rises to 4, but `docs/stories.md` still says 3 (it is outside `Owns`). That is only a note.
- [x] Run interdicts, one by one:
  - **Protected paths:** the diff on `po/ method/ bin/ .claude/ .polype/ tests/lib.sh evals/`, the s199 files and `answers/plain/` is empty.
  - **Oracle sum:** `po-gate oracle-intact` exited 0.
  - **`journey_po_next`:** `grep journey_po_next tests/journey/stops.sh` finds nothing.
  - **Test files:** there is no new `*.test.sh` under `tests/journey/`.
  - **No fetch to hide the merge defect:** the journey's only `git fetch` is in `journey_open_lane` (`journey.sh:334`). It runs only when the lane does not exist yet, as `po-research` does. `journey_by_hand ship` never reaches it.
  - **No long sleep:** the only sleep is 0.1 s.

## References
- [x] Every `po` verb used exists: `po record qa`, `po record review --composed`, `po inbox add`, `po inbox <id>`, `po answer`, `po inbox consume`, `po next --remote` and `po state --all`.
- [x] The findings-shape outcomes match `po/src/record/mod.rs:282-303`: exit 1 is `findings-shape` with `written: true`, and exit 2 is `findings-shape-unrunnable`.
- [x] All 17 reasons live in `po/src/next/lane.rs:22-209`, in 18 literal call sites. Nowhere else in `po/src/` holds a `"ask"` token.
- [x] No value that only looks right. The decision inbox resolves to `.polype/inbox/` relative to `$R` (template default, `agents-local.md:40`). `Private folder` points to `$J/private/`.

## Rules
- [x] `AGENTS.md` conventions respected: bash tests, one test function per criterion, commit message in English.
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s200-journey-reaches-every-stop` → exit 0
- [x] Floor: `po-gate floor-guard s200-journey-reaches-every-stop main` exited 0, so nothing was lowered.
- [x] Assertions pin the acceptance criteria, and none of the six empty test shapes appears.
- [x] Within `Test budget`: 10 tests.
- [x] Bite 1: I renamed `stop_pull_request_closed` in `stops.sh`. 1 test failed: `every_ask_reason_is_reached` ("po next can answer ask with a reason no journey reaches: pull request closed"). Undone, `git diff --exit-code` clean.
- [x] Bite 2: I neutralised `bad = 1` in the token-count awk of `journey_ask_reasons` (`journey.sh:207`), together with bite 1. 2 tests failed: `every_ask_reason_is_reached` and `reason_reader_reads_every_ask`. Undone, `git diff --exit-code` clean.
- [x] A probe in a temp folder: a reason in a nested `po/src/next/sub/x.rs` is not read (see Findings).
- [x] No test the story made useless. The four journey files pass here: 19/19 in 35.2 s. No `polype-journey.*` folder was left under `/tmp`, and the worktree is clean.

How each new stage is driven, and which real script writes what the next gate reads:
- **Short track.** The `flow/plan.md` answer carries `track: flow`. The lane goes through `validate-plan`, the pre-commit probe, `po-run` and `po record review`, as in s199. The test asserts there is no research on `main`, and that `po state` reads the track as `flow`.
- **Design.** The `design` action writes the design note, which is a model's answer. `po next` then reads it from the lane and moves on to `plan (research, no plan)`.
- **QA.** `po record qa` writes the report; the test checks its `Method version:` line. The evidence is then committed alone with `-- docs/qa/<id>/`. The test asserts the evidence commit holds only `docs/qa/<id>/` and that `po-gate qa-current` passes.
- **Fix runs.**
  - Each run applies a patch, rewrites the record's `Tree:` from `git write-tree`, runs `po-run` and commits through the pre-commit hook.
  - Each review is recorded by `po record review` at `Fix loop` 0, 1 and 2.
  - `po next` gives `ask (Max attempts reached)` from the real reviews and branch.
- **Decision.**
  - `po inbox add` posts it from `$R`, the throwaway project's own inbox.
  - `po answer` answers it, and `po next` still gives `wait` until the decision is consumed.
  - The test then removes the marker line from the plan, standing in for `/po-plan`, which is a model's step, and runs `po inbox consume`.
- **Human confirmation.**
  - `po ship push` answers `waiting-for-human`, and `po next --remote` then gives `wait (merge waiting)`.
  - The double merges, and the person's `/po-ship` is run by hand (`journey_by_hand ship`).
  - `po ship land` answers `already_landed`, followed by `file` and `clean`.
  - The next run finds nothing to do.
  - No test freezes the #437 behaviour after the merge: the post-merge run asserts an empty lane, not `merge waiting`. `docs/harnais.md` says the driver's own `ship (landed)` route is not proven.

The 17 `ask` reasons, and how each stop reaches its state:
- **Settings, rewritten in the committed `AGENTS.local.md` on `main`:** `setting unreadable: Story track`, `QA stage` (first site, `lane.rs:32`), `Flow threshold`, `Plan validation`, `Max attempts`, and `Design source unset`. All are real.
- **A story field removed in `docs/stories.md`:** `no complexity`. Real.
- **A file removed from `main`, and the lane opened from it:**
  - `no po-gate`: the gate is dropped from `main`'s index.
  - `no docs/design-system.md`: the file is removed with `git rm`.
  - Both are real git states.
- **A marker carried by a planner answer:** `Root cause: not found` and `Technical choice: waiting for a human`. Real; `po` reads the lane's files.
- **Reports written through `po record`:**
  - `QA status: blocked`: `po record qa`, then the evidence commit.
  - `QA evidence committed twice`: a second `/po-qa` run by hand, then a blocked review naming `/po-qa` through `po record review`.
  - `findings-shape refused`: two refusals by `po record review`, then the blocked report through `--composed`.
  - `Max attempts reached`: real fix runs.
  - All four are real.
- **`pull request closed`:** the double's `pr close`, read through `po next --remote` and the double's `pulls?head=` answer. Real through the double.
- **`review without verdict`:** `po record review` really writes the review with no verdict (`written: true`, exit 2). The stop then overrides `journey_record_blocked` to do nothing, which stands for a coordinator that stopped before writing its blocked report. The state is forced by leaving out a step, but every file in it is real. This is acceptable and said in a comment.

No stop overrides `journey_po_next`. The coverage test and `stops.sh` write no reason as text. Two criterion tests quote the one reason their own stop must end on.

## Neighbours
- [x] s199's nine tests pass unchanged against the changed `journey.sh` (`--remote`, named snapshots, the entry log before the warning stop). The s199 oracle file is untouched.

## Lenses
Lenses run: none
- [x] No lens trigger: test scripts, test doubles and documentation only.

## Findings
- major — tests/journey/journey.sh:202 — The coverage reader misses reasons in subfolders of `po/src/next/`.
  - **What happens.** `journey_ask_reasons` reads only `"$dir"/*.rs`, at line 203 (`grep`) and line 208 (`awk`). Neither the reason list nor the `"ask"` token count looks into subfolders.
  - **Proof.** A probe added `act("ask", "nested decoy")` in `po/src/next/sub/x.rs` of a temp copy. The reader did not print it and still exited 0.
  - **Impact.** The criterion `every_ask_reason_is_reached` is about `po/src/next/`. If that module is split into subfolders, which is common in Rust, new reasons would escape the test silently. The plan's pivot does not list this escape.
  - **Fix.** Read recursively, for example `grep -rho --include='*.rs'` and `find "$dir" -name '*.rs'` for the token count.
  - Contained: no subfolder exists today, so every current reason is covered.

## Not verified
- The full unit suite and the type check were not rerun. I relied on the record (`Unit suite` exit 0 on this code, `verif-current` passes), and the project has no type check.
- The double's forge answers (`pulls?head=`, `pr close`, merge onto the base) are not compared with GitHub's. A person should check them once against a real GitHub repository before trusting the `pull request closed` route.
- No QA walk is real: the report and capture are written in advance. The second site of `setting unreadable: QA stage` (`lane.rs:69`) is not walked on its own.
- The driver's route after a human merge, `ship (landed)` from `po next --remote`, is not proven. This is #437, already filed: only the person's `/po-ship` run by hand is walked.
- I bit two rules only: one stop removed, and the reader's token-count guard. The guards the record says it bit itself, #432 (`JOURNEY_SETUP` and git's location variables) and #434 (`--repo`, merge base), I judged by reading the tests, not by disabling them myself.
- I judged the record's three guards left unbitten by reading:
  - the `-- docs/qa/<id>/` pathspec;
  - emptying `$J/count` on restore;
  - the `already_landed` skip.
  The reasons it gives hold: nothing else is dirty when the evidence is committed, `qa` is applied twice in one stop only, and push after a merge also answers `merged`. They are untested, so a regression there would pass silently. The `already_landed` skip follows `po-ship.md:35`.
- I did not test what a SIGKILL leaves behind. By reading, it is one `polype-journey.*` folder under `$TMPDIR`, as `docs/harnais.md` says.
- Writing to this repository: every `rm -rf` targets `$J/…`, `$R` or `$ORIGIN`, all set by `journey_init`. When a variable is empty, `rm -rf ""` does nothing. I did not run the journey with `J` unset.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-21T12:56:40+01:00

Diff reviewed: `git diff main...story/s200-journey-reaches-every-stop`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 9c47e875ca99494d708664798c96e38017d0e823

## Ownership
Diff listed with `git diff --name-only main...story/s200-journey-reaches-every-stop`. Each path was checked against the story's `Owns` (`tests/journey/`, `tests/journey-reaches-every-stop.oracle.test.sh`, `tests/journey-reaches-every-stop.test.sh`, `docs/harnais.md`).
- [x] Every path is inside `Owns`. The research, plan, record and review files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

Fix commit 56a9194 touches only `tests/journey/journey.sh`, `tests/journey-reaches-every-stop.test.sh`, `docs/harnais.md`, `docs/verif/s200-journey-reaches-every-stop.md` and `docs/reviews/s200-journey-reaches-every-stop.md`. Nothing else changed.

## Evidence reused
- [x] `po-gate verif-current s200-journey-reaches-every-stop` → exit 0, record reused. The last `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to `Tree:` d796370. I did not run the full suite again.
- [x] `po-gate qa-current` is not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] The fix stays inside the previous major and the loop's brief: a recursive reader, a check that the `act` action is a literal, and the list of escapes. Nothing outside the plan.
- [x] Run interdicts held: no change under `po/`, and `tests/lib.sh` is untouched.

## References
- [x] `journey_ask_reasons` and `journey_unreached` have two callers: `tests/journey-reaches-every-stop.oracle.test.sh:180-182` and the reader test. `find`, `mapfile` and `sort` are used correctly under bash. `read_exact(` in `po/src/run/session.rs:112` and `po/src/ship/file.rs:354` lies outside the folder read and would not match anyway, because `_` comes before `act(`.
- [x] Today, `po/src/next/` passes the new check for the right reason. Every `act(` call there has a literal first argument; this includes `..act("plan", reason)` at `lane.rs:24`. The definition at `lane.rs:13` is the only line the `fn act(` exclusion skips.

## Rules
- [x] `AGENTS.md` conventions respected: English comments, French docs.
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s200-journey-reaches-every-stop` → exit 0
- [x] Oracle: `po-gate oracle-intact` → 0, intact.
- [x] Floor: `po-gate floor-guard s200-journey-reaches-every-stop main` → 0, nothing lowered.
- [x] The assertions pin the reader's behaviour: the nested reason is named by `journey_unreached`, and the non-literal action is named with its `file:line`. None of the six empty test shapes.
- [x] Within `Test budget`: 4 tests plus 6 oracle tests.
- [x] Bite 1: changed `find "$dir"` to `find "$dir" -maxdepth 1`, reverting the recursion. `journey-reaches-every-stop.test.sh` → 1 failure (`reason_reader_reads_every_ask`: "a reason in a nested file passed"). Undone with `git checkout`; `git diff --exit-code` clean.
- [x] Bite 2: disabled the non-literal check (`if (0 && …`). Same file → 1 failure (`reason_reader_reads_every_ask`). Undone; `git diff --exit-code` clean. The `held.rs` fixture also trips the older token check on its `const` line, so this test catches the new check only through its message (`sub/held.rs:3 calls act`). It still catches it.
- [x] Four journey files run here: `journey-reaches-every-stop{,.oracle}.test.sh` and `journey-runs-to-a-landed-commit{,.oracle}.test.sh` → 19 passed, 0 failed. s199's tests are green. No new entries left in `/tmp` (398 before and after).

**Previous major (`tests/journey/journey.sh:202`, subfolders not read) is closed.** Both the reason list and the token count now read every `.rs` file under the folder, and bite 1 shows the test holds that.

**The new non-literal-`act` check, on its own merits.** I appended probes to `lane.rs` in a throwaway copy:
- These pass: a doc line `/// Returns act("plan", ...)`, `contract(`, `extract(`, `read_exact(`, `pub(crate) fn act(…)`.
- These fail the reader, correctly: `act(a, "r")`, `act(&format!(…), "r")`, `act( "ask", "r")`.
- These fail on code that is fine: a plain comment `// … act(action, reason).` and a method call `self.act(x)`. A `#[cfg(test)]` module that compares an action to `"ask"` also fails, through the older token count.

Every false failure is loud, names its line, and is never silent. See the minor finding below.

**Escapes listed in the record and in `docs/harnais.md:144`.** My probes confirm the list is true:
- `act(` followed on the next line by `ASK` passes unseen.
- `concat!` or a constant passed to `act` directly is caught. It escapes only when used outside `act`, which is how the list puts it.
- `include!`, `#[path]` and an `ask` built outside the folder are out of reach of a text reader by construction.

I found no unlisted escape that a plain code shape reaches. What remains needs a deliberate, unusual shape, so it is graded as accepted residual risk and needs no finding.

## Neighbours
- [x] Callers read: the oracle `every_ask_reason_is_reached` (it passes on the real `po/src/next/`) and the reader test.

## Lenses
Lenses run: none
- [x] No lens trigger in the diff: test scripts and docs only, no auth, route, migration, lockfile or server code.

## Findings
- minor — tests/journey/journey.sh:210 — The non-literal-`act` check also matches comments and method calls.
  - **What happens.** The pattern `(^|[^A-Za-z0-9_])act\([^"]` is applied to every line. It matches an ordinary comment such as `// Each stop goes through act(action, reason).` and a method call like `self.act(x)`.
  - **Proof.** I appended each to `lane.rs` in a throwaway copy. Each made `journey_ask_reasons` exit non-zero with "calls act with an action that is not a literal".
  - **Impact.** A harmless comment added to `po/src/next/` would turn `every_ask_reason_is_reached` red. The failure is loud and names its line, so nothing escapes silently.
  - **Fix.** Skip lines whose first non-blank characters are `//` before the check. The token count could do the same.

## Not verified
- The full unit suite was not rerun here. I relied on the `po-run` row of the record (exit 0, code equal to `Tree:`), as `Verification mode: record` allows. The project has no type check (`Typecheck: —`), no E2E and no build stage.
- No QA: `QA stage: —`. The story has no screen and no scene.
- Taken from the record and not checked again: the second site of `setting unreadable: QA stage` (`lane.rs:69`) is not walked on its own. The `ship (landed)` cleanup route of `/po-drive` after a human merge is not proven. A person should confirm that the lead files the `wait (merge waiting)` defect the record names.
- The escape list was checked by probes against shapes I could think of, not by an exhaustive Rust parse. Code pulled in by `include!` or `#[path]` cannot be reached by any text reader.

Max severity: minor
Ship allowed: yes
