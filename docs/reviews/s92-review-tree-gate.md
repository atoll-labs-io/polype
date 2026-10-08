# Review — s92-review-tree-gate

Diff reviewed: `git diff main...story/s92-review-tree-gate`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ee7b77a28b7c8d14c7a72b1f2bbaa266e38d8a54

## When blocked
Not applicable. The tree was taken again just before answering and had not changed. The worktree is clean and `git diff --exit-code` passes.

## Ownership
I listed the diff with `git diff --name-only main...story/s92-review-tree-gate` and checked each path against the story's Owns line: `method/hooks/po-gate.sh`, `method/commands/po-ship.md`, `bin/po-eval`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`.
- [x] Inside Owns: `method/hooks/po-gate.sh`, `method/commands/po-ship.md`, `bin/po-eval`, `tests/review-tree-gate.test.sh`.
- [x] In scope by construction: `docs/plans/s92-review-tree-gate.md` and `docs/verif/s92-review-tree-gate.md`. The diff also adds `docs/decisions/ADR-0056-le-hash-d-une-gate-est-lu-dans-le-bloc-de-son-dernier-verdict.md` (status A), and the plan names it.
- [ ] Outside Owns, so this is a major finding: `docs/defauts.md`. The story's Owns line does not list it, and no written rule of `AGENTS.md` requires the change. The plan's task 5 announces it, and earlier stories that fix defects (s21–s25 and others) put `docs/defauts.md` in their Owns, so the change is intended. The story's scope just never declared it. Either widen Owns on purpose, or keep the row update out of the story.
- [x] Not in another running story's Owns. The only other open lane is `story/s78-platform-setting` (worktree present, not an ancestor of main). Its Owns and its diff share no path with s92.

## Evidence reused
- [x] `po-gate verif-current s92-review-tree-gate` returns 0, with both the installed gate and the gate from this story. With `Verification mode: record`, I relied on the record: the unit suite (`bash tests/run.sh`) exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`), and the record says so under "Not proven here".
- [x] `po-gate qa-current` is not required: the story has no screen (`Surface: —`), and `QA stage` is not set.
- I also ran the focused files myself for the bite proofs: review-tree-gate, gate, qa-gate, run-ledger, ship and evals. Result: 59 passed, 0 failed.

## Plan
- [x] Tasks 1–5 are all present. `paired_hash` replaces `first_hash`, with one awk pass, the bullet strip, the bounds of the block and the blank boundary after the hash. The three call sites use the planned verdict EREs. The Step 0 sentence of `po-ship.md` contains the exact phrase required. `po-eval` changes only at line 100. The new test file holds three AC-named functions. Row 35 is set to `corrigé par s92`, and the record is complete.
- [x] I checked each run interdict:
  - `method/templates/*`, `method/agents/reviewer.md`, `po-drive.md`, `po-review.md` and `evals/` have an empty diff.
  - `.claude/` and `.polype/` have an empty diff.
  - `po-gate.sh` changes only in the header, the helper and the three call sites. `record_rows`, `runs_cover_checks`, the secret scan, the floor guard and the pre-commit are untouched.
  - In `po-ship.md`, only the Step 0 sentence changes. In `po-eval`, only line 100 changes.
  - The reading is not widened beyond the criteria: no indentation, no `+ ` bullet, no punctuation stuck to the hash, no text after `yes`.
  - No existing test is edited. `docs/stories.md` is not edited.

## References
- [x] `paired_hash` is defined at `po-gate.sh:36` and called at :60, :71 and :149. No caller of `first_hash` is left in code; the remaining mentions are in older docs and reviews only. `tree_exists`, `code_matches` and `refuse` are unchanged. The test uses `scratch_repo`, `contains`, `fail`, `$METHOD` and `$ROOT`, which come from `tests/lib.sh` and `run.sh`; the run is green.
- [x] Values: the hash shape is checked as `length == 40 && /^[0-9a-f]+$/`, and its 41st character must be `[[:space:]]`. I probed it with `gawk --posix` in a temp dir:
  - a bullet plus a remark is accepted;
  - a TAB before the hash and CRLF line endings are accepted, as `first_hash` accepted them before;
  - 41 hex characters are refused.
  Awk already uses `[[:space:]]` elsewhere in `po-gate.sh` (comment at :268), so the helper adds no new portability risk.

## Rules
- [x] `AGENTS.md` conventions are respected: method files in English, the comment explains the why, and the test file has the `# s92 — …` header.
- [x] No accepted ADR is contradicted. ADR-0056 is new, written in French like the other ADRs in `docs/decisions/`, and the code matches its decision. That includes the refusal of `<hash>.`, which leaves the s78 review still blocked, as the ADR and the plan say.

## Tests
- [x] Floor: `po-gate floor-guard s92-review-tree-gate main` returned 0, so nothing was lowered.
- [x] The assertions pin down the three acceptance criteria. Every check runs the real gate or the real `grade` on a throwaway repo, and the fixtures use the template shapes. None of the six shapes of test that prove nothing appears.
- [x] 3 tests, well within `Test budget` 25.
- [x] Bite proofs. After each one I ran `git checkout --`, and `git diff --exit-code` came back clean:
  - The awk closes only the first block (`$0 ~ verdict && !closed`): 2 failing tests (`ship_gate_reads_the_last_review`, `other_tree_lines_read_the_same_way`).
  - The blank-boundary condition after the hash is removed: 1 failing test (`verdict_lines_may_be_list_items`).
  - `bin/po-eval` line 100 is reverted to the unbulleted grep: 1 failing test (`other_tree_lines_read_the_same_way`).
- [x] No test is made useless by the story. The existing gate, QA-gate, ship and evals tests still cover the refusals that did not change.

## Neighbours
- [x] I read the other readers of the verdict lines: `po-drive.md:59-61,134`, `po-status.md:30`, `po-execute.md:26`, `po-review.md:36`, `po-orchestrator.md:68`, and `method/AGENTS.md:63,66`. They are prose read by agents ("the last `Ship allowed:`"), and none describes a line shape the new reading contradicts. `po-eval` still reads `Max severity:` and `Review status:` without a bullet; ADR-0056 states this as a neutral consequence.

## Lenses
Lenses run: none. No path or content in the diff matches a trigger: the diff changes shell gates that read markdown, with no auth, route, migration, lockfile or server-side query.

## Findings
- major — `docs/defauts.md:85` — the path is outside the story's Owns line (`method/hooks/po-gate.sh`, `method/commands/po-ship.md`, `bin/po-eval`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`). Plan task 5 announces the change, but the story never declared the path, unlike the earlier stories that fix defects. Fix: widen Owns on purpose, or keep the row update out of this story.
- minor — `method/hooks/po-gate.sh:44` and `:60` — `ship-allowed` now also counts a list item that starts with "Ship allowed:" (after `- ` or `* `) as a verdict line. A bullet in a review's findings that begins with those words, placed between the header tree and the final verdict, closes a block early. The final verdict then has no `Reviewed tree:` in its block, and the gate refuses. This fails safe (refusal, never a false pass), and the old code had the same effect with an unbulleted line, but the widened reading makes it more likely. A sentence in the reviewer template could warn against starting a body line that way.
- minor — `tests/review-tree-gate.test.sh:63` — `source <(sed … bin/po-eval)` defines `grade` in the shell that runs the tests, and it stays defined for every test that runs after it. This is harmless today. A subshell would keep it contained.

## Not verified
- I did not run the gate under mawk or BSD/macOS awk, because neither is installed here (`awk` is gawk). I only ran a `gawk --posix` probe. To cover it, run `bash tests/run.sh review-tree-gate.test.sh gate.test.sh qa-gate.test.sh` on a machine with mawk and one with macOS awk.
- I did not run `/po-ship` end to end, and I did not run the no-hook Step 0 by hand. I only read the sentence and checked that it matches the gate. To cover it, a person can follow Step 0 by hand on a stacked review fixture.
- The installed copies in `.polype/hooks/po-gate.sh` and `.claude/` still hold the old `first_hash` reading, by design of this story. Until someone refreshes them after the ship (`bin/polype-dev-install .`), lanes on this repository (including s78) keep being judged by the old gate.
- The s78 review stays refused even after this change: its last tree line has `<hash>.` with the full stop stuck to the hash. ADR-0056 states this on purpose. A person has to decide how s78 gets out of that state (re-review, or edit its review line).
- The type check was not run: the project has none (`Typecheck: —`).

Max severity: major
Ship allowed: yes
