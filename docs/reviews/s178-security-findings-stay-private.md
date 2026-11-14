# Review — s178-security-findings-stay-private

[Story](../stories.md) · [Plan](../plans/s178-security-findings-stay-private.md) · [Verification](../verif/s178-security-findings-stay-private.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s178-security-findings-stay-private`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 304fed182ff8df6814badcb72c93712b6d8febac

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Scope
I listed the diff with `git diff --name-only main...story/s178-security-findings-stay-private` (25 paths) and checked each path against the story's `Owns` line.
- [x] Every code, method and test path is inside `Owns`: `po/src/record/`, `po/src/inbox/`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, the six method files, `docs/interface-agent.md`, `docs/decisions/`, the five test files, `AGENTS.local.md`.
- [x] The research, plan and verification files for s178 count as the story's own evidence. The diff adds ADR-0123 (status `A`) and the plan names it. ADR-0090 sits under `docs/decisions/`, which `Owns` lists, and only its `superseded-by` line changed.
- [x] Nothing falls inside another running story's `Owns`. `git worktree list` shows only main and this worktree.

## Evidence reused
- [x] `po-gate verif-current s178-security-findings-stay-private` passes with exit 0. The record is `complete`, and the `Unit suite` run (`bash tests/run.sh`) exited 0. `Typecheck` is `—`. I relied on the record and did not rerun the full suite. I read its "Not proven here" section: model-read rules, the interface doc, a hand check of `po-bounds`, and no live run on a real project.
- [x] `po-gate qa-current`: not required. `QA stage: —`.

## Plan
- [x] Tasks 1–10 hold against the diff. I found no unrequested change. `po-execute.md` was left unchanged, which the plan allowed ("change only a sentence the rule makes false").
- [x] I checked each run interdict:
  - The interdicted paths have an empty diff (`method/hooks/`, `method/AGENTS.md`, `po-ship`/`po-drive`/`po-retro`/`po-orchestrator`/`po-flow`/`po-setup`/`po-execute`, `po/src/{state,trust,next,context}`).
  - No `docs/reviews/` path is in the diff.
  - `AGENTS.local.md` has one added line.
  - ADR-0090: only `superseded-by` changed.
  - `Cargo.toml`: only `version` changed, so `[dependencies]` is untouched.
  - `--composed` and `qa` skip the split (`po/src/record/mod.rs:188`).
  - The tests use the meaningless witness `zq-witness-7f3k`, with `HOME` and `Private folder` in the scratch dir.
  - The word ceilings hold (`test_words_hold`).

## References
- [x] `inbox::find`, `post_decision`/`post`, `place`/`Place`, `NewDecision`/`Choice`/`Motive`, `Project::setting`, `Project::name` (`po/src/project.rs:73`) and `output::REFUSED`/`UNREADABLE` all exist with the signatures used. The worktree build compiles. Its only warning (`output::not_built` unused) already exists on `main`.
- [x] Values I checked:
  - `blocks` is `[id]` exactly when the highest marked severity is major or critical (d-0021).
  - Files are `0600` and created folders `0700`, even under `umask 000` (probe).
  - `~/` is expanded only from an absolute `HOME`, and `$HOME/x` is refused.
  - Missing or `—` setting gives exit 2. A setting that is relative or inside the repository gives exit 1.

## Rules
I compared the trimmed method files with `main` line by line. No rule was lost, and each removed clause is still held elsewhere:
- `po-review.md`: the worktree check details are in `po-execute.md:24`. "That stop goes to the person at once" is in `po-orchestrator.md:35` and `po-drive.md:67`. The `Reviewed tree` rationale is in `po-gate ship-allowed`/AGENTS Law 3.
- `reviewer.md`: the scene viewpoint contents (framing, scale, light) are in `templates/plan.md:34`.
- `templates/review.md` "opened and confirmed" and the `with results` clause: covered by `review-antihallu` steps 1–2.
- The other edits are rephrasings with the same meaning.

The two model-read rules, judged by reading:
- **Reviewer marking rule** (`reviewer.md` `## Your answer`, `review-lenses` Grading, `templates/review.md` note). It is clear: the mark applies whatever lens found the finding, the text appears nowhere else in the answer, and on a fix loop each finding is either declared lifted by decision id or marked again.
- **`fix_run_still_reads_them`** (`implementer.md` `## Fix runs`). It is adequate: it names where the text lives (`po inbox <id>` → `context`) and lists where it must not go (repository, commit message, record, test).

## Tests
- Oracle: `po-gate oracle-intact s178-security-findings-stay-private` → exit 0
- [x] Floor: `po-gate floor-guard s178-security-findings-stay-private main` → 0, nothing lowered.
- [x] The assertions pin the acceptance criteria. They grep the whole scratch dir and the git history for the witness, and they compare the JSON error codes and `written`. None of the six empty test shapes appears.
- [x] 12 new tests, within `Test budget` 25.
- [x] Bite tests. Each mutation was undone, and `git diff --exit-code po/src/record/security.rs` was clean every time:
  - In-repository guard disabled in `private_folder` (`security.rs:210`) → 1 test fails (`unusable_private_folder_is_refused`). Nothing leaked even then, because `post` refuses `sensitive-context-in-repo` and removes the file.
  - Blocking threshold raised to critical only (`holds_critical_or_major`) → 1 test fails (`only_critical_or_major_holds_the_lane`).
  - Misplaced-mark refusal disabled (`security.rs` `if !refused.is_empty()`) → 1 test fails (`security_findings_are_marked`).
- [x] I found no test made useless by the story. The version fixtures now follow `bin/polype`, as planned.
- [x] The one change listed under `## Oracle changes` was made by the planner before any code, for option B, and does not weaken a criterion.

## Neighbours
- [x] `po inbox add` keeps its codes and messages behind the split into `post` and the printing shell. `tests/decision-inbox.oracle.test.sh` is green in the record. `locate()` callers are unchanged.
- [x] The count line passes `findings-shape`, because a non-list line is refused only when its first word is a severity (checked by `test_verdict_still_counts_them`).
- [x] Refusal and JSON replies checked for echoed text:
  - `security-shape` gives line numbers only (probe: `answer line 9: …`).
  - `private-folder-*` messages echo the setting value, not the finding.
  - The question and options of the posted decision are fixed text.
  - The `findings-shape` stderr echoes only the public file.
- [x] Path rules, by probe: another worktree of the same repository and a symlinked `Private folder` into the repository → `private-folder-unusable`, exit 1. `.git`, the project root and relative paths are covered by the own tests. One remaining case is listed under Findings.

## Lenses
Lenses run: security — `po/src/record/security.rs` (file handling, path and permission checks on a user setting); dependencies — `po/Cargo.lock`, `po/Cargo.toml` (only this crate's own version moved, no dependency entry changed)
- [x] Each lens finding is graded and listed under Findings.

## Findings
- major — po/src/record/mod.rs:206 — Every `po record review` call that carries `[security]` items posts a new decision and writes a new private file before the review is written and checked by `findings-shape`. The implementer flagged the re-ask case, and the plan does not address it.
  - Reproduced. I recorded an answer with two marked items plus a line `critical: not a list item`. It was refused with `findings-shape` and `"written": true`, and `d-0001` was posted. I recorded the corrected answer as `/po-review` asks; it posted `d-0002`.
  - The inbox then holds two pending decisions with the same question, both `blocks: ["s01-a"]`, and two private files. The review shows two count lines, `d-0001` in the malformed block and `d-0002` in the accepted one.
  - The lane stays held until the person answers a decision that the accepted verdict no longer names. Nothing is lost silently, but the person gets a duplicate and the lane can stay blocked by a stale decision.
  - Possible fixes: reuse the pending decision of the same story when the private text is identical, or run the shape check on the composed body before posting. Either way, say in `po-review.md` that a re-ask after `findings-shape` reuses or supersedes the first decision.
- minor — po/src/record/security.rs:146 — security finding, detail handed to the lead privately

## Not verified
- **A live `/po-review` on a real project.** `po-review.md`'s new branches (`security-shape` re-ask, stop on `no-private-folder-setting`/`private-folder-unusable`) were judged by reading only. To cover it, a person runs one review whose answer holds a marked finding on a project with `Private folder` set, then one without the setting.
- **The installed `po` 0.2.0 on this machine.** It does not split, which is why this review's own finding uses the lead's interim format. I did not test the upgrade path (`polype update` building or fetching 0.3.0). Covered at release.
- **`po-bounds` letting the reviewer and implementer run `po inbox <id>`.** Taken from the record's hand check. `method/hooks/po-bounds.sh` has no rule naming `po`, and I did not exercise it under the hook.
- **A second machine or a synchronised `Private folder`** (ADR-0123, Neutral consequence). Not exercisable here.
- **`fix_run_still_reads_them` and the reviewer's marking rule.** Judged by reading only. They are `po-eval` control-arm candidates (#208).
- **`docs/interface-agent.md` row.** Read and found consistent with the code, but no script reads it.
- **Non-Linux platforms.** `std::os::unix` is used unconditionally in `security.rs`. The existing code is already Unix-only, and I did not check whether `po` targets Windows.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Review status: complete
Fix loop: 1
Reviewed tree: e1f3600278cad98a6489b8a5404a51c01594e4ce

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Scope
- [x] `git diff --name-only main...story/s178-security-findings-stay-private` lists the same 25 paths that loop 0 checked against `Owns`. The fix commit 7582a19 touches five of them: `po/src/record/mod.rs`, `po/src/record/security.rs`, `method/commands/po-review.md`, `tests/security-findings-stay-private.test.sh` and `docs/verif/<id>.md`. All five are inside `Owns`, or are the story's own evidence.
- [x] `git worktree list` shows only `main` and this worktree, so the diff cannot overlap another running story.

## Evidence reused
- [x] `po-gate verif-current s178-security-findings-stay-private` exits 0. The record is `complete`, and its last `Unit suite` row (`bash tests/run.sh`) exited 0 on tree 5658294… `Typecheck` is `—`, so I did not rerun the full suite. I read "Not proven here": model-read rules, the interface doc, a hand check of `po-bounds`, and no live run.
- [x] QA is not required (`QA stage: —`).

## Plan
- [x] The fix run matches the loop-0 major. `po record review` now runs in this order: `prepare()` (inbox and `Private folder` resolved, nothing written), then the report written with a temporary count line, then `findings-shape`, then `keep()` (private file and decision), then the count line rewritten. When `keep()` fails, the report is rolled back.
- [x] The new test `reasked_answer_posts_one_decision` reproduces the loop-0 scenario and holds it to one decision and one private file.

## References
- [x] `security::prepare`/`keep`/`Keeper` (`po/src/record/security.rs:142-194`) match their only callers (`po/src/record/mod.rs:206`, `:258`). `write_atomic` is at `mod.rs:308`. I built the worktree in a temp target (`/tmp/tmp.KxZyUJERm1/target`). Its one warning already exists on `main`. The installed `~/.claude/polype/po` was not touched.

## Rules
- [x] Words cut from `po-review.md` by the fix run:
  - "nothing appended": the Exit 1 paragraph still says that after `security-shape` "nothing was recorded".
  - "who sets `Private folder`": the refusal message names the setting, and `templates/agents-local.md:77` documents it.
  - Added: "once the shape passes".
  - No rule is lost. The file has 1145 words, under its ceiling of 1147.

## Tests
- Oracle: `po-gate oracle-intact s178-security-findings-stay-private` → exit 0
- [x] Floor: `po-gate floor-guard s178-security-findings-stay-private main` → exit 0.
- [x] The s178 files pass 13/13 on the worktree build. That is 13 tests, within `Test budget` 25.
- [x] Bite tests. Each mutation was undone, and `git diff --exit-code po/src/record/mod.rs` was clean after each:
  - The decision is posted even when `findings-shape` exits 1 (`mod.rs:257`, `if true`) → 1 test fails (`reasked_answer_posts_one_decision`).
  - The rollback after a `keep()` failure is commented out (`mod.rs:261-264`) → 0 tests fail. This is listed under Findings.
- [x] Probes in scratch fixtures (`/tmp/tmp.KxZyUJERm1/probe.sh`):
  - **Refusal before any write.** A `Private folder` that is missing, `—`, unusable, or has no inbox gives `written: false`, no review, no decision and no witness text. The existing tests show this.
  - **`keep()` fails on a new report** (project subfolder at mode 0500) → `private-folder-unusable`, `written: false`, the review is removed, 0 decisions, and the witness text is nowhere.
  - **`keep()` fails on an existing report** → the file is byte-identical to what it was before (`cmp`), with 0 decisions.
  - **Malformed block.** The refused block keeps `Security findings: 2 — none kept, this answer fails findings-shape`. After the corrected answer, the file starts with the malformed bytes unchanged (`cmp -n`). The accepted block holds `decision d-0001`, and only one `none kept` line exists.
  - **Successful run.** The report cannot be left with the temporary line: success is returned only after the rewrite succeeded (`mod.rs:268`).
  - **No path puts the security text in the repository.** `text_with` uses `split.public` whenever `security` is set. Oracle and gate output carry only public text.

## Neighbours
- [x] `security::prepare`/`keep` have no callers other than `record/mod.rs`. The `--composed` and `qa` paths skip the split, the oracle line and the shape check, as before.
- [x] When `findings-shape` cannot run (gate missing, probed), the decision is posted, the review is `written: true`, and po exits 2. A repeated call would post a second decision. However, `po-review.md:42` says this exit records a composed blocked report and never re-asks the reviewer, so the flow does not duplicate it. The findings stay held by the posted decision.

## Lenses
Lenses run: security — `po/src/record/security.rs`, `po/src/record/mod.rs` (file handling, path checks on a user setting, a write-then-rollback around private text); dependencies — `po/Cargo.lock`, `po/Cargo.toml` (unchanged by the fix run, only the crate's own version moved)
- [x] Each lens finding is graded and listed under Findings.

## Findings
- minor — po/src/record/mod.rs:261 — The rollback after a failed `keep()` has no test. Commenting out the restore/remove (`mod.rs:261-264`) leaves all 13 s178 tests green. A regression would leave a review on disk with a verdict and a "none kept" count line while the reply says `written: false` and the findings sit nowhere. The probes show the rollback works today. A test that makes the project subfolder unwritable (mode 0500), once with no review and once with an existing review, would hold it.
- minor — po/src/record/mod.rs:268 — When `keep()` succeeds but rewriting the count line fails, po replies `unwritable` with `written: false`. The report on disk still holds the full block, with its verdict lines and the temporary line `none kept, this answer fails findings-shape`, while a decision has been posted. Both the `written` flag and the line are then false. This is unlikely, since the same atomic write succeeded a moment earlier, and the message names the decision. Restoring `existing` (or removing the file) here, as the `keep()` failure branch does, would make the reply true.
- minor — po/src/record/security.rs:151 — security finding, detail handed to the lead privately

## Not verified
- **A live `/po-review` on a real project** with `Private folder` set, and one without it. Only the bash fixtures and my probes cover it. A person should run one marked review on a real project.
- **The installed `po` 0.2.0.** It does not split, which is why this review uses the interim private format. The upgrade to the worktree's version is not exercised. That is covered at release.
- **`po-bounds` letting the reviewer and implementer run `po inbox <id>`.** I took this from the record's hand check and did not run it under the hook.
- **A second machine or a synchronised `Private folder`** (ADR-0123). Not exercisable here.
- **The model-read rules** (`fix_run_still_reads_them`, the reviewer's marking rule). Judged by reading at loop 0, and unchanged by the fix run. They are `po-eval` candidates (#208).
- **Non-Linux platforms.** `std::os::unix` is used unconditionally. Not checked.

Max severity: minor
Ship allowed: yes
