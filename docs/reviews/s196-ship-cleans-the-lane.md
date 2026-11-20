# Review — s196-ship-cleans-the-lane

[Story](../stories.md) · [Plan](../plans/s196-ship-cleans-the-lane.md) · [Verification](../verif/s196-ship-cleans-the-lane.md)

Method version: 0.6.1
Recorded: 2026-11-20T12:41:10+01:00

Diff reviewed: `git diff main...story/s196-ship-cleans-the-lane`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 0de74bf55e9bd53f2ce38fc40834b8cca5388578

## Ownership
Diff listed with `git diff --name-only main...story/s196-ship-cleans-the-lane`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. 14 paths match entries of the s196 `Owns` line (`po/src/ship/`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, both command files, the four test files). The other 2 are this story's own plan and record.
- [x] Nothing outside `Owns`, nothing inside another running story's `Owns`.

## Evidence reused
- [x] `po-gate verif-current s196-ship-cleans-the-lane` → exit 0, record reused. `bash tests/run.sh` exited 0 on the committed code. The project has no type check (`Typecheck: —`). I read "Not proven here": no real forge was used, and the lease and `branch-refused` were not bitten.
- [x] `po-gate qa-current` → not required, because `QA stage: —`.

## Plan
- [x] Tasks 1 to 6 are present. The short track was the right choice: complexity 2 is within `Flow threshold: 3`. `## Verified facts` holds up when checked against `land.rs`, `push.rs`, `file.rs` and `context/lanes.rs`.
- [x] Each run interdict was checked:
  - No `-f`, `-D`, `+refspec`, `prune`, `switch`, `checkout` or `stash` in `clean.rs`.
  - No `gh`, gate, `commit` or `merge` in `clean.rs`.
  - The diff of `po/src/context/`, `po/src/next/`, `project.rs`, `method/hooks/`, `po-setup.md`, `po-intake.md`, `method/AGENTS.md` and both oracles is empty.
  - One conflict: the interdict forbids `--force-with-lease`, but `clean.rs:254` uses it. The lead asked for it, but the validated plan was never amended (finding below).

## References
- [x] Every call was opened and confirmed: `land::is_id`, `setting`, `remote_check`, `base`, `title_in`, `landing_by_subject`, `read`, `git_failed`, `push::ls_remote` (now `pub(super)`), `git::run_input` and `output::error/reply`. The `mod.rs` dispatch and USAGE are consistent with `interface-agent.md`.
- [x] The id cannot redirect a deletion: `is_id` allows only `s<digits>-[a-z0-9-]`. Every ref is spelled in full (`refs/heads/story/<id>`), so a tag or a `story/<id>-x` branch is never touched; `clean_owns_only_its_refs` checks this. The title reaches git only as an argv value under `-F`.

## Rules
- [x] `AGENTS.md` conventions respected. The version went to 0.12.0 in three places (ADR-0122).
- [x] No accepted ADR contradicted (ADR-0080, ADR-0081, ADR-0130). The line of ADR-0081 on `MERGED` is already with the owner (d-0048).

## Tests
- Oracle: `po-gate oracle-intact s196-ship-cleans-the-lane` → exit 0
- [x] Floor: `po-gate floor-guard s196-ship-cleans-the-lane main` → exit 0. Oracle: `po-gate oracle-intact` → exit 0.
- [x] Assertions pin the criteria. The fixtures use a local bare `origin` and a `gh` double that must stay unused. None of the six empty test shapes.
- [x] 12 tests (6 oracle + 6) against `Test budget: 25`. The plan announced 11; this is within budget.
- [x] Bite 1: proof made always true (`landing_by_subject(...).or(Some(base))`) → 1 failing test (`nothing_is_removed_before_the_proof`) → undone, `git diff --exit-code` clean.
- [x] Bite 2: patch-id comparison made always true → 1 failing test (`clean_keeps_a_remote_branch_that_is_not_the_landing`) → undone, clean.
- [x] Bite 3: the `landing_by_subject` exclusion made unconditional again → 1 failing test (`cleanup_reruns_cleanly`, cut `worktree-and-branch`, `not-landed`) → undone, clean. The binary was rebuilt from the committed code afterwards (oracle 6/6).
- [x] Removed tests: each fell with prose whose behaviour the code now carries, and that behaviour is tested.
  - In `ship.test.sh`:
    - `MERGED`: no forge call any more, checked by the `gh` double in the oracle.
    - `--force` not an option: covered by `cleanup_is_not_forced` and `clean_stops_where_git_refuses`.
    - "own commits": now `update-ref -d` plus the ref exclusion, covered by bite 3.
    - "straight to cleanup": `landed_lane_is_cleaned_alone` covers the command. The prose routing is read by a model and judged by reading.
  - In `everything-in-issues.test.sh`: "the review is not lost" is now `ship file` reading the review from the landing commit (s195). The order proof < file < clean is still asserted.

## Neighbours
- [x] `landing_by_subject` is also called by `land` (`land.rs:548`), `push` (`push.rs:528`) and `file` (`file.rs:476`). Each of them first requires the worktree on `story/<id>` (`land::worktree`), so the branch exists and the exclusion still applies. The full ref only stops a tag from standing in for the branch. The record's full suite (all ship tests included) passed on this code.
- [x] `po-drive.md:117` now relies on reason `landed` from `po next`/`po state`, which `context/lanes.rs:80-110` provides.

## Lenses
Lenses run: security — by the lane's request: `po ship clean` deletes a worktree, a local ref and a remote ref (`po/src/ship/clean.rs`). Dependencies: `po/Cargo.lock` changed, but only the `po` package's own version moved, so it has nothing to judge.
- [x] Each lens finding graded and listed under Findings.

Interruption replay, by reading and through the oracle's cuts:
- Cut after the worktree removal: a rerun reports `worktree: absent` and deletes the rest. Exit 0.
- Cut after the local deletion: the proof still holds without the exclusion. Exit 0.
- Cut after the remote deletion: a rerun reports everything `absent`. Exit 0.
- After `delete-refused`, a rerun finishes the remote deletion.
- After `remote-kept`, a rerun gives the same state with exit 1, and the remote waits for a person. That is the right behaviour.

## Findings
Security findings: 3 — decision d-0049
- major — method/commands/po-ship.md:50 — `/po-ship` cannot resume a cleanup that was cut after the worktree went. Three things block it:
  - the lane disappears from `po next`, because lanes are listed from worktrees (`po/src/context/lanes.rs:222`);
  - Step 0's gate runs "from the worktree";
  - Step 3.2's `po ship file` requires the worktree (`land.rs:134-160`, `wrong-branch` → exit 2 → stop).

  The command itself reruns cleanly, but the method never reaches it again, so the local and remote `story/<id>` linger with nothing listing them. Step 3 should say that once the worktree is gone (filing already done), only `po ship clean <id>` from the root is rerun. `po-drive` status should list a story branch without a worktree.
- minor — method/commands/po-ship.md:32 — The word cap removed "and the finish says why" from the `--routes` rule. That rule is the model's own judgement, so the person no longer sees why the build ran or was skipped. It was lost to the cap, not moved into code.
- minor — docs/plans/s196-ship-cleans-the-lane.md:83 — The validated plan was not amended for the lead's addition. Its run interdict still forbids `--force-with-lease` in `clean.rs`, and Task 1's replies have no `remote-kept`. The code (`clean.rs:249-275`) follows the request, not the plan.
- minor — docs/interface-agent.md:276 — After `remote-kept`, "une relance rend la même réponse" is not quite true. The rerun keeps the same `state`, `remote` and exit code, but `worktree` and `branch` become `absent` instead of `removed`/`deleted`.

## Not verified
- My own probes on throwaway repositories did not run. po-bounds refused `git push` everywhere, and refused `git commit` inside a temp worktree under `.worktrees/<id>` (reviewer mode, reading verbs only). I did not route around it. The two security findings above are judged by reading. A person should replay, in a `mktemp -d` repository with a local bare `origin`, a title-only commit on `main` before and after the send, and a remote head whose parent is off the base. Then confirm what `po ship clean` removes.
- The lease on the remote deletion and `branch-refused` were not bitten (implementer's record), and I judged them only by reading. The lease spelling `--force-with-lease=refs/heads/story/<id>:<head>` together with `--delete` is valid git, and `update-ref -d <ref> <old>` refuses a moved ref.
- No real forge or GitHub remote was used. GitHub's refusal to delete a missing ref is handled by reading `ls-remote` first; I did not run it against GitHub.
- The rules read by a model in `po-ship.md` (998 words) and `po-drive.md` (2 441) were judged by reading only, with no `po-eval` control arm:
  - Step 0 sends a landed lane straight to Step 3: present and coherent.
  - "file before clean": present (item 2 before item 3).
  - The pull request description, the held findings and what goes to the person: kept, apart from the losses listed above.
- I did not run the full suite or the other ship test files; I relied on the record (`po-run` row, exit 0, matching tree).

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-20T23:34:04+01:00

Review status: complete
Fix loop: 1
Reviewed tree: effe8ed2b0401b793b52efb1716c59aa69da8f58

Diff reviewed: `git diff main...story/s196-ship-cleans-the-lane`, in a context that did not write it. Findings rated critical, major or minor.

## Ownership
Diff listed with `git diff --name-only main...story/s196-ship-cleans-the-lane`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. 15 paths match entries of the s196 `Owns` line. The other 3 are this story's own plan, review and record.
- [x] Nothing outside `Owns`, nothing inside another running story's `Owns`.

## Evidence reused
- [x] `po-gate verif-current s196-ship-cleans-the-lane` returned exit 0, so I reused the record. Its last `bash tests/run.sh` row exited 0 on the code. The project has no type check (`Typecheck: —`). From "Not proven here": no real forge was used; the lease and `branch-refused` were never bitten; listing a branch that has no worktree is left outside `Owns`.
- [x] `po-gate qa-current` is not required, because `QA stage: —`.
- [x] I rebuilt `po` from the committed code. I ran only `tests/ship-cleans-the-lane.test.sh` and `tests/ship-cleans-the-lane.oracle.test.sh`: 15/15 passed.

## Plan
- [x] The fix run matches the plan's `## Notes after validation`: `branch-not-landed`, the stricter test on the remote head, `Ran.bytes`, Step 3 resume, and `po-drive.md` left unchanged. The run interdicts still hold in `clean.rs`: no `-f`, `-D`, `+refspec`, `prune`, `switch`, `checkout`, `stash`, `gh`, gate, `commit` or `merge`.

## References
- [x] I opened every call: `land::read`, `land::git_failed`, `git::run`, `git::run_input`, and the new `Ran.bytes` field (`git.rs:12-13`, filled at `:58`, and empty on a launch error at `:61`).
- [x] `git merge-tree --write-tree`, `git patch-id --verbatim` and `git merge-base --is-ancestor` all exist with the flags used. `land.rs:331` already requires git ≥ 2.38.

## Rules
- [x] The `AGENTS.md` conventions are respected. The version bump is still held by `version_goes_up`.
- [x] No accepted ADR is contradicted.
- [x] Word caps: `po-ship.md` has 998 words (cap 1 000). `po-drive.md` has 2 441 (2 449 on main).
- [x] The three restored rules now read as they do on main:
  - "and the finish says why" (`--routes`);
  - "`Security findings:` line as written" (pull request body);
  - "never opening that decision" (what stays with the person).
- [x] The five cuts of the fix, one by one:
  - Step 0's sentence on a missing setting: no loss. The finish still names a null `forge_checks`.
  - "beside it" in Step 1: descriptive only.
  - The definition of the proof in Step 3.1: no loss. `po` reads the proof itself, and the story's criterion asks the prose to stop restating it. The `## Step 3` title and its "only after proof" stay, so what other files cite from it still holds.
  - "without `--force`" in Step 3.3: no loss. The code never forces the removal, and `cleanup_is_not_forced` holds this.
  - The list of named refusals in Step 3.3: replaced by "any refusal", same meaning.

  None of these cuts drops a rule the model needs. One older loss, from the first commit, is listed under Findings.
- [x] Commit message, test names and comments: they say what the code does.
  - The commit message names the decision and lists what changed.
  - The doc comments of `is_in` and `is_landing` describe the checks as written. Only "on a parent that `base` holds" leaves out that the parent must also be the only one, which the code checks.
  - `Ran.bytes` is commented as the bytes before the lossy conversion, which is what it holds.

## Tests
- Oracle: `po-gate oracle-intact s196-ship-cleans-the-lane` → exit 0
- Oracle: `po-gate oracle-intact s196-ship-cleans-the-lane` → exit 0
- [x] Floor: `po-gate floor-guard s196-ship-cleans-the-lane main` → exit 0.
- [x] 15 tests (6 oracle + 9) against `Test budget: 25`. None of the six empty test shapes:
  - the fixtures use a local bare `origin`;
  - `gh` is a double that fails;
  - the remote heads in the new tests are built through a second clone.
- [x] For each bite I ran only the two story files, then reverted the source file and checked `git diff --exit-code po/src/ship/clean.rs` came back clean. Afterwards I rebuilt the binary from the committed code.
  - Bite 1: the `is_in` filter disabled (`false && …`, `clean.rs:228`) → 1 failure (`clean_keeps_a_branch_that_the_landing_does_not_hold`).
  - Bite 2: the `merge-base --is-ancestor <parent> <base>` condition disabled (`clean.rs:139`) → 1 failure (`clean_keeps_a_remote_head_whose_parent_is_not_on_the_base`).
  - Bite 3a: `--verbatim` changed back to `--stable` (`clean.rs:107`) → 1 failure (`clean_compares_the_change_of_a_remote_head_byte_for_byte`, case `two |two`).
  - Bite 3b: `&diff.bytes` replaced with `diff.stdout.as_bytes()` → 1 failure (same test, case `two\xff|two\xfe`).

## Previous findings (Fix loop: 0)
- The first security finding of d-0049 is closed. It is held by `clean_keeps_a_branch_that_the_landing_does_not_hold` (cases `empty`, `partial`, `conflicting`), and bite 1 confirms it.
- The second security finding of d-0049 is closed. It is held by `clean_keeps_a_remote_head_whose_parent_is_not_on_the_base` (variants `none`, `moved`) and `clean_compares_the_change_of_a_remote_head_byte_for_byte`. Bites 2, 3a and 3b confirm it, each condition bitten on its own.
- The third security finding of d-0049 is closed, at `method/commands/po-ship.md:40` and `:52`. Both phrases are restored word for word as on main. This rule is read by a model, so it was judged by reading, with no test.
- Major, `po-ship.md:50` (a cut cleanup could not be resumed): closed as far as `/po-ship <id>` goes. Step 0 now sends a story whose worktree is gone to Step 3, and Step 3.3 reruns only `po ship clean <id>` from the root. What remains — nothing lists the branch — is graded minor below.
- Minor, `--routes` "and the finish says why": closed (`po-ship.md:32`).
- Minor, plan not amended: closed by `## Notes after validation` in the plan.
- Minor, the rerun after `remote-kept` in `interface-agent.md:276`: closed. The text now says `worktree` and `branch` become `absent`.

## Neighbours
- [x] The order of the new `branch-not-landed` refusal:
  - It comes after every other check and before the first deletion (`clean.rs:227-234`, the deletions start at `:245`), on every path.
  - On a rerun after a cut, `landed` and the local head have not changed, so `is_in` gives the same answer.
  - After the local branch is gone, the check is skipped and only the remote head is judged.
- [x] Legitimate lanes are still cleaned, probed with the story's own fixtures in a `mktemp -d` folder with a local bare origin, then removed:
  - a rebase merge with the same tree → `cleaned`, exit 0;
  - a rebase merge on a base that moved (`merged_after`) → `cleaned`, `branch: deleted`, exit 0.
- [x] A branch that gained a commit after its landing commit was built. I judged this by reading; the probe was refused, see Not verified.
  - `land.rs:540-620` commits the review (`commit_docs`) before it builds the landing from that same branch. Nothing in `push`, `file` or `clean` commits on `story/<id>` afterwards.
  - So a later commit only happens outside the method's flow. Its content truly never landed, and `branch-not-landed` sends it to a person.
  - That refusal is conservative, not wrong.
- [x] `Ran.bytes` adds one owned buffer per git call. All other callers keep reading `stdout`.

## Lenses
Lenses run: security — by the lane's request and the content: `po ship clean` deletes a worktree, a local ref and a remote ref after its own checks (`po/src/ship/clean.rs`). Dependencies: `po/Cargo.lock` changed, but only the `po` package's own version moved; nothing to judge there.
- [x] Each lens finding graded and listed under Findings.

## Findings
- minor — method/commands/po-ship.md:54 — A branch is left behind with nothing listing it. When a cleanup is cut between `git worktree remove` and the ref deletions, and nobody reruns `/po-ship <id>`, `story/<id>` stays behind, locally and on `origin`. `po next` and `po state` list lanes from worktrees only (`po/src/context/lanes.rs`, outside `Owns`), so neither `/po-drive` nor `/po-drive status` ever shows it again. The content of the branch is already proven landed at that point (`is_in` passed before the cut), so nothing is lost, only left lying around. It deserves an issue: `po state` should list a `story/<id>` branch that has no worktree and whose story has landed.
- minor — method/commands/po-ship.md:19 — Step 0 sends a story "whose worktree is gone" to Step 3, and Step 3.3 only covers the case where "the filing done". It says nothing for a landed story whose worktree a person removed by hand before the filing. `po ship file` needs the worktree, so the model gets no instruction there. The case is rare and stays out of the normal flow. One clause would cover it: stop and name it.
- minor — method/commands/po-ship.md:53 — This loss comes from the first commit and was not raised before. In the `no-tracker`, `listing-failed`, `too-many-open` or `tracker-unavailable` replies, "the finish says why and lists `pending`" (main) became "the finish lists `pending`". The finish paragraph gives a reason only for held findings, so the person no longer learns why nothing was filed.

## Not verified
- The "branch gained a commit after the landing was built" probe did not run. po-bounds refused plumbing writes (`hash-object`, `commit-tree`, `update-ref`) in the fixture repository, which it took for a story worktree with no `Owns` line. I did not route around it, and I judged that case by reading `land.rs` and `is_in`, as written above. To cover it, a person adds one commit under `docs/` to `story/s01-a` after `sent; merged` in the test fixture, and checks that `po ship clean s01-a` refuses with `branch-not-landed` and removes nothing.
- The single-parent condition of `is_landing` (a merge commit as the remote head) has no test of its own. I checked it by reading only.
- Not bitten, by the implementer or by me: the lease on the remote deletion and `branch-refused`. Both are races between a read and a delete that no fixture can interleave.
- No real forge or GitHub remote was used, and nothing was pushed outside the throwaway bare repositories.
- I did not run the full suite or the other ship test files. I relied on the record (`po-run` row, exit 0, matching code).
- The rules a model reads in `po-ship.md` and `po-drive.md` were judged by reading only, with no `po-eval` control arm.
- I rebuilt `po/target/release/po` (ignored) several times for the bites, and last of all from the committed code. The worktree is clean (`git status --porcelain` empty), and the tree did not move during the review.

Max severity: minor
Ship allowed: yes
