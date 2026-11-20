# Review — s194-ship-lands-through-a-pull-request

[Story](../stories.md) · [Plan](../plans/s194-ship-lands-through-a-pull-request.md) · [Verification](../verif/s194-ship-lands-through-a-pull-request.md)

Method version: 0.6.1
Recorded: 2026-11-19T15:52:45+01:00

Diff reviewed: `git diff main...story/s194-ship-lands-through-a-pull-request`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 78069cf427554959adb6f0a23fbbfebd48930fde

## When blocked
- Failure cause: none, the review is not blocked
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s194-ship-lands-through-a-pull-request`, and each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The 19 paths are the five `po/src/ship/` files, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`, the four listed test files, the new oracle and task test files, and the story's own research, plan and verif files. `po/src/main.rs` and `tests/ship-files-the-other-findings.oracle.test.sh` are untouched, as the plan says.
- [x] Nothing outside `Owns`.
- [x] Nothing inside another running story's `Owns`: `git worktree list` shows only this lane and `framing-m22` (`fix/qa-deadline-wording`), which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` passes (exit 0), so I reused the record: `Unit suite` `bash tests/run.sh` exited 0 on the recorded tree, with `Typecheck: —` and the compiler check done inside the build. I read its "Not proven here" list: the lease, `GIT_TERMINAL_PROMPT=0`, `--repo` on each `gh` call, the 30-second default, real GitHub, and the word rule. The first four are judged by reading below.
- [x] `po-gate qa-current`: not required, because `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–7 are all present, and nothing lies outside the plan. The implementer's announced departures were each checked:
  - errors after a push carry a fixed message;
  - the draft's body goes through stdin;
  - `rewrite.branch` may be `null`;
  - the Step 1 `ci` bullet and the "Message and title" line are gone, and their content now lives in the code;
  - `/po-ship` gains `Write`.
- [x] Run interdicts, one by one:
  - only `refs/heads/story/<id>` and `refs/heads/framing/ship-confirmation` are pushed (`push.rs:172-181`, called at `:333` and `:479`), and `Target branch` never is;
  - every git write goes through `ship/git.rs`, and `project.rs` and `trust/` are not in the diff;
  - no token appears in any argument, and every `gh` call carries `--repo github.com/<o>/<r>`;
  - the story's description goes by `--body-file`, the draft's by stdin;
  - `po-ship.md` from `## Step 3` to the end is unchanged;
  - `method/AGENTS.md`, `po-setup.md`, `po-drive.md`, `po-intake.md`, `method/hooks/`, `.claude/` and `.polype/` have no diff;
  - nothing of cleanup or filing went into `push`.

## References
- [x] Every call was opened and confirmed:
  - in `land.rs`, `is_id`, `is_sha`, `worktree`, `gate`, `setting`, `remote_check`, `title`, `base(top, mode, target)` (its only other caller, `land.rs:545`, is updated), `probe`, `Probe`, `conflict`, `still_the_landing`, `landing_by_subject`, `read` and `git_failed`;
  - `effective` in `mod.rs:40`, and `forge::github_repo`, `host_and_path` and `owner_repo` in `forge.rs`;
  - `trust::forge::program` and `git::run_input`.
- [x] Values that only look right, judged by reading:
  - `READINGS = 60` × `POLL_SECONDS = 30` matches the old 30-minute, 30-second rule.
  - `--force-with-lease=<ref>:<observed or empty>`: the empty expectation means "must not exist", and the lease is the head `ls-remote` observed, never a tracking ref.
  - `GIT_TERMINAL_PROMPT=0` is set on every git launch in `git.rs`, and `GH_PROMPT_DISABLED=1` on every `gh` call.
  - An empty check list never passes (`push.rs:399`).
  - The gate is read again before the merge (`:548`), and the merge is tied to the commit sent by `--match-head-commit <reply.sha>`, where `reply.sha` is the pushed or resumed head.
  - `parse` rejects every option except `--sha` and `--body-file`, so no caller can ask for a merge.

## Rules
- [x] The `AGENTS.md` conventions are respected: the `Reads settings` line is unchanged, method files are in English, the version is 0.10.0 in all three places, and commit messages are in English.
- [x] No accepted ADR is contradicted: ADR-0079/0080/0081/0083/0130. On ADR-0083 (where a token goes), see Lenses.

## Tests
- Oracle: `po-gate oracle-intact s194-ship-lands-through-a-pull-request` → exit 0
- [x] Floor: `po-gate floor-guard` exited 1 with one flag, `tests/ship-resumes-cleanly.test.sh` deleted. The plan names that file and points to the research's Traps for the reason, so it is graded minor (listed under Findings).
- [x] Oracle: `po-gate oracle-intact` exited 0, and `## Oracle changes` is empty.
- [x] The assertions pin the criteria through the behaviour of the binary:
  - an update hook on a bare origin, and a `gh` double that keeps PR state;
  - the body's marker is checked to reach no argument;
  - three interrupted reruns.
  None of the six empty test shapes appears. The `gh` double ignores `--repo` and models no fork pull request (see Findings).
- [x] 12 tests (6 oracle, 6 task), within `Test budget` 25.
- [x] Bite 1: I removed the exact-subject filter in `land.rs` `landing_by_subject`. 1 test failed (`resumed_ship_does_not_land_twice`: "a commit only quoting the title, or extending it, passed for the landing"), then I undid it and `git diff --exit-code` was clean.
- [x] Bite 2: I removed the gate read before `gh pr merge` in `push.rs`. 1 test failed (`automatic_waits_for_checks`), then I undid it and `git diff --exit-code` was clean.
- [x] Removed phrase tests:
  - `ship-through-pr.test.sh`: the merge line, the lease phrase, `test_push_targets_only_the_story_ref` and the gate-before-merge order are replaced by the oracle's update-hook log, the `--match-head-commit` check and bite 2.
  - `ship-follows-forge.test.sh`: 4 draft phrases, replaced by `test_forge_line_is_rewritten_by_the_command`.
  - `ship-and-fleet-cleanup.test.sh`: `test_ship_text_is_complete`, whose push and skip clauses now live in `push.rs` and are covered by the resume tests.
  - `ship-resumes-cleanly.test.sh`: the rebinding of `<sha>` to the pushed head, covered by `resumed_ship_does_not_land_twice` (`.sha` stays the first one sent).

## Neighbours
- [x] Callers read: `land::base` (its only other caller is updated), `forge::read` (also used by `po ship forge`) and `mod.rs` routing. The `wrong-branch` wording change has no test or document reader. `forge.rs:453` keeps the call word `git remote get-url origin` on purpose, as the plan asks.

## Lenses
Lenses run: security — `po/src/ship/push.rs` writes on the forge (`git push`, `gh pr create/merge`) and `forge.rs` changes which URL decides where a token goes; dependencies — `po/Cargo.lock` changed, though only `po`'s own version moved and no dependency entry did.
- [x] Each lens finding is graded and listed under Findings. The security lens found one matter, held in the marked item below.
- On the configured URL of `origin` (`forge.rs:441`): a token still reaches only the host that URL names. The `gh`/curl paths are pinned to github.com, and the `glab`/`tea` logins are matched by host. When pushes are rewritten to another host, the forge reading and the pull request concern the configured repository, and the merge stays bound to `--match-head-commit` with a `headRefOid` equal to the sent sha. So a commit that did not reach that repository is never merged there: the run times out to a human or ends in `pr-failed`. The one functional change is graded minor below.
- Replay of an interruption after each step, from reading backed by the oracle:
  - After the push: the remote head is still the landing, so nothing is pushed and the PR is created.
  - After the PR: the open PR is reused, with no second create.
  - After the merge: the subject is found on the fetched base, so `state: merged` and nothing is written.
  - After the draft: the framing branch already holds the line, so nothing is pushed and the open draft is reused.
  - In the `merging` state, a rerun waits and merges again, and `gh` refuses (`merge-refused`). Nothing lands twice.
- A failed check: the code merges nothing, names the failed checks with their links and `/po-execute <id>`, and starts no fix run. `po-ship.md:47` says the same, and `po-drive.md:44` sends a failed ship back to a fix run. A timeout, an unreadable forge and a closed PR stay with a human, in both the code and the prose.

## Findings
Security findings: 1 — decision d-0046
- major — method/commands/po-ship.md:30 — A rule of the old forge section was lost instead of moved into the code. On a forge where no pull request is opened (not GitHub), the old text said the `framing/ship-confirmation` branch is sent "and the report asks a person to open the pull request". Now `rewrite()` returns `url: null` with `refused: false` (`push.rs:340`), and `po-ship.md` only says "the finish quotes `rewrite`" and "any rewritten line with its draft URL". Nothing tells the person to open the draft, so on GitLab or Forgejo the `(forge)` line silently stays unrewritten. Restore that sentence, or make the reply carry a state the finish must turn into a request to a person.
- minor — po/src/ship/forge.rs:441 — Reading `remote.origin.url` instead of the URL git expands means a remote configured through an `insteadOf` shorthand (for example `gh:owner/repo`) is now read as an unrecognised host. `ship forge` gives `unreadable` where s192 read GitHub, and `ship push` stops at `no-pull-request`. The failure is safe and the plan intends it, but `docs/interface-agent.md` and `po-ship.md` do not tell a user why their ship no longer opens a pull request.
- minor — tests/ship-resumes-cleanly.test.sh:0 — The floor guard flags this deleted test file. The plan names the deletion, but its reason lives only in the research's Traps list, and the rule it held is now covered by `resumed_ship_does_not_land_twice`.
- minor — method/commands/po-ship.md:44 — The description goes into "a fresh `mktemp -d` folder", but nothing says to remove that folder after `po ship push` ends. Each ship leaves a file behind in the temp dir.

## Not verified
- No real forge was called, by instruction. The behaviour of `gh pr list/create/view/checks/merge` (JSON fields, the `--head` matching of fork PRs, `--match-head-commit`, `--body-file -` for the draft) is judged from gh's documented interface. A person should run one ship of a throwaway story on a real GitHub test repository, including a fork PR with the same branch name.
- The lease could not be exercised under a concurrent push (nothing moves origin between `ls-remote` and the push), so I judged its form by reading. The same goes for `GIT_TERMINAL_PROMPT=0`, `--repo` on every `gh` call and the 30-second default.
- GitLab and Forgejo (#75, already filed) were not tried: the code sends the branch only, with no merge.
- The 30-minute wait in the background from a real `/po-ship` session (a cut call that is rerun) was not run.
- I ran no throwaway-repository probe of my own beyond the oracle and task files, whose fixtures already use a `mktemp -d` bare origin with doubles and remove it themselves.
- I did not rerun the full suite, as asked; the record covers it.
- `description_stays_with_the_model`, judged by reading: the description is written by the model and passed by file. `po-ship.md` holds 1 975 words, at most 1 998 as required (2 298 before). The only rule lost is the one under Findings; the rest of old Step 2 moved into the code.

Max severity: critical
Ship allowed: no

Method version: 0.6.1
Recorded: 2026-11-20T11:04:11+01:00

Diff reviewed: `git diff main...story/s194-ship-lands-through-a-pull-request`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 773b6d12db18080efdf473d709013fe19940246c

## When blocked
- Failure cause: none, the review is not blocked
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s194-ship-lands-through-a-pull-request` and held each path against the story's `Owns` line.
- [x] All 20 paths are inside `Owns`, or are the story's own research, plan, verif and review files. The fix run (0b58f79) touched only these:
  - `po/src/ship/push.rs`
  - `docs/interface-agent.md`
  - `method/commands/po-ship.md`
  - the oracle and task test files
  - the story's verif and review files
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only this lane and `framing-m22` (`fix/qa-deadline-wording`), which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exited 0, so I reused the record. Its last row is `Unit suite` `bash tests/run.sh`, exit 0, recorded 2026-11-20T09:57:24Z. The project's `Typecheck` is `—`, so there is none to run. I did not run the full suite again, as asked.
- [x] I read the record's "Not proven here" list:
  - the lease;
  - `GIT_TERMINAL_PROMPT=0`;
  - `--repo` on every `gh` call;
  - the 30-second default;
  - the 10-reading bound `HEAD_READINGS`;
  - the gh fields `isCrossRepository` and `headRepositoryOwner`;
  - real GitHub.

  I judged these by reading; see `## Not verified`.
- [x] `po-gate qa-current` was not required: `QA stage: —` sends no story to QA.

## Previous findings (Fix loop: 0)
- The security finding of d-0046 is closed. The tests that hold it are `test_only_pull_requests_from_origin_are_used`, `test_pull_request_on_another_commit_is_not_reported_ready` and `test_forge_without_pull_requests_asks_a_person`. Their bite is listed under Tests. I checked every path of `push.rs` that reuses, reports or merges a pull request:
  - the story listing and its `MERGED`, `CLOSED` and `OPEN` branches;
  - `pr create`, followed under `waiting-for-human` by `points_at`;
  - the wait and the merge under `automatic`, with and without a wait, the merge staying bound by `--match-head-commit`;
  - the `merging` state and the resume paths through `landing_by_subject`;
  - the reuse and the creation of the `(forge)` draft.
- major `po-cmd po-ship.md:30` (a rule lost on forges without pull requests): **closed**.
  - `rewrite.next` now says `open-pull-request` when the branch is sent but no draft can be opened, and `write-line` when the rewrite is refused.
  - `po-ship.md:30` tells the finish to ask a person for what `next` names.
  - Removing `next = Some("open-pull-request")` fails `test_forge_without_pull_requests_asks_a_person`.
- minor `forge.rs:441` (the `insteadOf` shorthand): **closed**. `docs/interface-agent.md` now says that a remote written through a shorthand reads as an unrecognised host.
- minor `tests/ship-resumes-cleanly.test.sh:0` (deleted test file): **still open**. The floor guard flags it again; it is listed under Findings.
- minor `po-ship.md:44` (temp folder left behind): **closed**. The line now says "Remove the folder once the last call has ended."

## Plan
- [x] The fix stays within tasks 3, 5 and 7 and the review's findings.
- [x] The run interdicts still hold:
  - the only refs pushed are `story/<id>` and `framing/ship-confirmation`;
  - `po-ship.md` from Step 3 onward is unchanged;
  - `project.rs` and `trust/` have no diff;
  - the description travels by `--body-file`.
- [x] `description_stays_with_the_model`, judged by reading: the description is written by the model and handed over as a file. `po-ship.md` holds 1 993 words, within the ceiling of 1 998.
- [x] Commit message, comments and test names say what the code does. The 0b58f79 message names the two tests behind the security fix, `next`, the interface note and the folder removal, all of which are present. The doc comments on `HEAD_READINGS`, `Listing::Unsure`, `from_origin` and `Rewrite.next` match the code. The test names say what their assertions check.

## References
- [x] Every function the fix calls exists, and I opened each one: `head_of`, `points_at`, `head_differs`, `from_origin`, `Listing`, `PR_FIELDS`, `text_of_url`, `poll_seconds`.
- [x] `gh pr list --json` documents `isCrossRepository` and `headRepositoryOwner` among its fields. I did not confirm this on a live forge.

## New in the fix, judged on its own merits
- **`pr-head-differs`** — sound. A merged pull request on another commit is refused instead of ending the run as merged. `po-ship.md:46` sends any other refusal to a human. One rough edge is under Findings: gh that cannot start is also reported as `pr-head-differs`.
- **Up to 10 readings of the head under `human`** — sound in principle: it is a bounded wait for the forge to catch up after a push. Two caveats:
  - The default spacing is `PO_SHIP_POLL_SECONDS` (30 s), so it can wait up to 4.5 minutes. `/po-ship` already runs the call in the background.
  - The value 10 is confirmed by nothing, and no test counts the readings.
- **`rewrite.next`** — consistent with the reply table in `docs/interface-agent.md`. A draft whose head lags just after a push is reported as `write-line` without a second reading. That is safe; the person writes the line.
- **The oracle's `gh` double**, logged under `## Oracle changes` (`po-gate oracle-intact` exit 0, one logged change). It does not weaken any criterion:
  - The default fields make every existing fixture origin's own, which is what the old double implied.
  - `headRefOid` still comes from the bare origin unless a fixture pins it, and no oracle fixture pins it.
  - `pr list` now returns every pull request of the head. That is closer to gh, and the code still picks the newest.
  - No assertion and no test function changed.
- **The point the implementer raised: Step 0 and Step 3 of `po-ship.md` (lines 23 and 53).** The security lens found one matter here, held in the marked item under Findings. These lines are unchanged by this diff and lie outside it by the plan's interdicts.

## Tests
- Oracle: `po-gate oracle-intact s194-ship-lands-through-a-pull-request` → exit 0
  tests/ship-lands-through-a-pull-request.oracle.test.sh: changed, logged in ## Oracle changes — The gh double only: a pull request it answers carries `isCrossRepository` and `headRepositoryOwner` (origin's own unless its file says otherwise) and keeps a `headRefOid` its file names; `pr list` returns every pull request of the head, no longer the first. No assertion and no test function changes. — The security finding of d-0046: the task tests `test_only_pull_requests_from_origin_are_used` and `test_pull_request_on_another_commit_is_not_reported_ready` need the double to answer these fields.
  po-gate: 1 logged oracle change(s) of s194-ship-lands-through-a-pull-request to judge
- Oracle: `po-gate oracle-intact s194-ship-lands-through-a-pull-request` → exit 0
- [x] Floor: `po-gate floor-guard … main` exited 1 with one flag, `tests/ship-resumes-cleanly.test.sh` deleted. The plan names the file, so it is graded minor.
- [x] 14 tests in all (6 oracle, 8 task), within `Test budget` 25. None of the six empty test shapes appears. The two new fixtures (`other_repository_pr`, `pinned_pr`) are payloads a real gh can return.
- [x] Bite. Each change was made in `push.rs`, the binary rebuilt, and only the named test functions run. All three tests passed on the unmodified code first.

| # | Change | Failing tests |
| --- | --- | --- |
| 1 | `from_origin` always says "origin's own" | 1 (`test_only_pull_requests_from_origin_are_used`, caught by the head check behind it) |
| 2 | Only the `!cross` condition removed | **0** |
| 3 | Only the owner condition removed | **0** |
| 4 | A pull request that does not say its origin is accepted | 1 (`test_only_…`) |
| 5 | The head check on `MERGED` removed | 1 (`test_pull_request_on_another_commit_is_not_reported_ready`) |
| 6 | `points_at` under `human` skipped | 1 (`test_pull_request_on_another_commit_…`) |
| 7 | The head check on the draft's URL removed | 1 (`test_pull_request_on_another_commit_…`) |
| 8 | `next = open-pull-request` removed | 1 (`test_forge_without_pull_requests_asks_a_person`) |

  Changes 2 and 3 survive because the fixture flips both fields together (listed under Findings). After the last change I ran `git checkout -- po/src/ship/push.rs`, then `git diff --exit-code` (clean) and an empty `git status --porcelain`. I rebuilt the binary from the committed code and the three tests passed again. The temp folders were removed.

## Neighbours
- [x] `newest_pull_request` has two callers, the story listing and the draft, and both handle the new `Listing` error. `head_of` is shared by `points_at` and `wait_for_checks`, and `wait_for_checks` keeps its `checks-unreadable` mapping.

## Lenses
Lenses run: security — `po/src/ship/push.rs` chooses which pull request on the forge is reused, reported ready or merged. dependencies — `po/Cargo.lock` changed, though only `po`'s own version moved (0.10.0, the same in three places).
- [x] The security lens found one matter, held in the marked item below. The dependencies lens found nothing: no dependency entry moved.

## Findings
Security findings: 1 — decision d-0047
- minor — po/src/ship/push.rs:233 — In `from_origin`, removing `!cross` alone or the owner comparison alone fails no test, because `other_repository_pr` sets both `isCrossRepository: true` and another owner. The owner condition is also redundant: `isCrossRepository: false` on a listing pinned to `--repo` already means the head lives in origin's repository. It can turn a renamed owner, still named by its old login in `origin`'s URL, into `pr-failed`. Keep one condition and give the fixture a case that tells them apart, or say why both are kept.
- minor — po/src/ship/push.rs:275 — When gh cannot start, `points_at` returns `false`, and the refusal reads `pr-head-differs`, "does not point at the commit sent". That is the wrong word for the cause. `wait_for_checks` maps the same case to `checks-unreadable`; doing the same here would tell the person the truth.
- minor — tests/ship-resumes-cleanly.test.sh:0 — The floor guard flags this deleted test file. The plan names the deletion, its reason lives in the research's Traps list, and `resumed_ship_does_not_land_twice` now holds the rule. Still open from Fix loop 0.

## Not verified
- I called no real forge, as instructed. Three things are judged from gh's documented interface:
  - the `isCrossRepository` and `headRepositoryOwner` fields of `gh pr list`;
  - how `gh pr view <branch>` matches the head label of a cross-repository pull request;
  - how soon `headRefOid` updates after a push.

  A person should run one ship of a throwaway story on a GitHub test repository, with a fork pull request on a same-named branch open beside it, under both `human` and `automatic`.
- The value 10 of `HEAD_READINGS` and the 30-second default: judged by reading; no test counts readings.
- The lease, `GIT_TERMINAL_PROMPT=0` and `--repo` on every `gh` call: unchanged since Fix loop 0 and judged by reading. No test can move origin between `ls-remote` and the push.
- GitLab and Forgejo (#75) were tried only through the doubles in the task tests.
- I ran no probe of my own beyond the named test functions. Their fixtures already use a `mktemp -d` bare origin with doubled forge tools and remove it themselves.
- I did not rerun the full suite; the record covers this tree.

Max severity: minor
Ship allowed: yes
