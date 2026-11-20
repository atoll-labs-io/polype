---
validated: yes
---
# Plan — s194-ship-lands-through-a-pull-request

[Story](../stories.md) · [Research](../research/s194-ship-lands-through-a-pull-request.md)

Branch `story/s194-ship-lands-through-a-pull-request`. Read the research first: this plan builds on it and does not repeat it.

## Story
A new sub-step, `po ship push <id> --sha <sha> --body-file <file>`, named by ADR-0130, takes over the end of `/po-ship` Step 2 and the draft rewrite of a `(forge)` line. It sends the landing commit to `story/<id>` with a lease, then opens or reuses the pull request. It stops there under an effective `human`. Under `automatic`, it waits for the checks, reads the gate again, and merges, bound to the commit it sent. Every rerun resumes and never writes twice. Criteria:
- `pr_mode_never_pushes_target`
- `human_stops_at_the_pull_request`
- `automatic_waits_for_checks`
- `resumed_ship_does_not_land_twice`
- `forge_line_is_rewritten_by_the_command`
- `description_stays_with_the_model` (judged in review)
- `version_goes_up`

No new ADR: ADR-0130 settled the shape, and ADR-0131 stays unused.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Gate, worktree, settings, title, base, probe | Already here: `land.rs:134-316,324-342`, made `pub(super)` | — |
| "Is this still the landing", exact-subject landing | Already here: `still_the_landing` `land.rs:460-464`, `landing_by_subject` `:490-495` | — |
| Effective value and rewrite | Already here: `effective()` `mod.rs:37-50`, `forge::read` `forge.rs:439` | — |
| Running forge tools without a token in an argument | Already here: `trust::forge::program` `trust/forge.rs:20-25` (`PO_GH`) | — |
| Writing git (push, `hash-object -w`, `mktree`, `commit-tree`) | Already here: `ship/git.rs:152` | — |
| JSON of `gh pr list/view/checks` | Installed dependency: `serde_json` | Not in the repo; std has no JSON parser |
| Polling loop and sleep | std (`std::thread::sleep`, `std::env::var`) | Nothing in the repo polls |
| `push.rs`: the order of steps, the PR, the wait, the rewrite | New code | No existing step pushes or calls `gh pr` |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/ship-lands-through-a-pull-request.oracle.test.sh` | `1962838945 20830` |

| Criterion | Test |
| --- | --- |
| `pr_mode_never_pushes_target` | `test_pr_mode_never_pushes_target`: the update hook of the bare origin logs only `refs/heads/story/s01-a`, and an older story head is replaced. One `pr create` runs, `--head story/s01-a --base main`, with the body file copied and its marker in no argument. An open PR is reused and no `create` follows. |
| `human_stops_at_the_pull_request` | `test_human_stops_at_the_pull_request`: a collaborative forge with an `automatic (chosen)` line, then a `human (chosen)` line. The result is `state: waiting-for-human`, the PR URL, no `pr checks`, no `pr merge`, and `main` unmoved. |
| `automatic_waits_for_checks` | `test_automatic_waits_for_checks`: the checks go `[]`, then pending, then pass, and one merge with `--match-head-commit <sha>` follows the last reading. A review switched to `Ship allowed: no` during the checks gives `gate-refused` and no merge. A `fail` bucket gives `checks-failed` naming `/po-execute s01-a` and its link, and no merge. |
| `resumed_ship_does_not_land_twice` | `test_resumed_ship_does_not_land_twice`: base commits that quote the subject in a body or extend the title give `already_landed: false`. Then three interrupted runs: a failed `pr create`, a rebuilt sha with a failed merge, and a rerun after the merge. The result is one push, one PR, one merge, `main` holding the subject once, and `.sha` the first one sent. |
| `forge_line_is_rewritten_by_the_command` | `test_forge_line_is_rewritten_by_the_command`: under `automatic (forge)` on a collaborative forge, `framing/ship-confirmation` is one commit on origin/main, touches only `AGENTS.local.md` (`human (forge)`) and has the chore subject, and a `--draft` PR is opened. A rerun sends nothing and opens nothing. Under `(chosen)` there is no branch and no draft. |
| `description_stays_with_the_model` | — model rule, judged in review. The word ceiling is checked by the task test `test_ship_words_go_down`. |
| `version_goes_up` | `test_version_goes_up`: three places equal, above 0.9.0. |

The interface the oracle fixes:
- the argument shape;
- `PO_SHIP_POLL_SECONDS`, the seconds between two readings, default 30, at most 60 readings;
- the reply fields `sha`, `state`, `effective`, `pull_request.url`, `checks[].link`;
- the error words `gate-refused` and `checks-failed`;
- gh reached through `PO_GH`, and `origin`'s configured URL naming the forge.

All six oracle functions fail on today's code (run: `usage` from `po ship`, and the version still 0.9.0).

## Tasks
1. [x] **Read the forge where git is told to go.**
   - `forge::read` takes `git config --get remote.origin.url` (`forge.rs:442`) instead of `get-url`, which expands `insteadOf`. This is the URL `trust::forge::Forge::of` already reads (`trust/forge.rs:143`). Keep the failure call word stable.
   - Add `pub(super) fn github_repo(project) -> Option<String>`, giving `<owner>/<repo>` when the host is `github.com`, built on `host_and_path`/`owner_repo`.
   - In `ship/git.rs` set `GIT_TERMINAL_PROMPT=0`, so a push never waits on a prompt.
   - Fails if wrong: `test_human_stops_at_the_pull_request` (a collaborative forge unread) and `test_forge_line_is_rewritten_by_the_command`. s192's `tests/ship-reads-the-forge*.sh` stay green.
2. [x] **Share s193's steps.** Make `pub(super)` in `land.rs`, with no behaviour change:
   - `is_id`, `is_sha`, `worktree` (its `wrong-branch` message says `po ship`, not `po ship land`);
   - `gate`, `setting`, `remote_check`, `title`, `base`, `probe`, `Probe`, `conflict`;
   - `still_the_landing`, `landing_by_subject`, `read`, `git_failed`.

   Also make `effective` in `mod.rs` `pub(super)`. Fails if wrong: `tests/ship-builds-the-landing-commit*.sh` (s193) and the `already_landed` line of `test_resumed_ship_does_not_land_twice`.
3. [x] **`po/src/ship/push.rs`: up to the pull request.** Order, nothing written before step 6:
   1. Arguments: the id, `--sha` (40 hex) and `--body-file` (an existing, non-empty file) are all required; anything else → `usage`/`unknown-option` (exit 2).
   2. Worktree, then the gate. A refusal → `gate-refused` (1).
   3. Settings. `Merge mode` is `pr`, else `usage` (2): local has its `--land`/`--sha`. `Ship confirmation` must be present. `Forge checks` is `required`, `—` or missing. `E2E stage`, `Build stage`.
   4. Then `remote_check`, `title`, and `base` (fetch).
   5. `forge::read` + `effective()`. The effective value comes from the code alone: the command takes no option that names a confirmation or asks for a merge.
   6. The draft rewrite (task 5).
   7. `landing_by_subject(base)` → reply `state: merged`, writing nothing.
   8. `probe`: a conflict → `conflict` (1).
   9. Observe the remote head with `git ls-remote origin refs/heads/story/<id>` (never the stale tracking ref). If it is `still_the_landing` on `base` → `sha` = that head, `pushed: false`. Else if `--sha` is `still_the_landing` → `git push --force-with-lease=refs/heads/story/<id>:<observed or empty> origin <sha>:refs/heads/story/<id>`, `pushed: true`. A refusal → `push-refused` (1), never forced further. Else → `stale-landing` (1): rerun `po ship land`.
   10. No GitHub repository (task 1) → `state: no-pull-request`, so a person opens the PR (ADR-0081).
   11. `gh pr list --repo github.com/<o>/<r> --head story/<id> --state all --json number,state,url,headRefOid`, newest number first:
       - `MERGED` → `state: merged`;
       - `CLOSED` → `pull-request-closed` (1, a human stop);
       - `OPEN` → reuse it;
       - none → `gh pr create --repo … --base <Target> --head story/<id> --title "<id>: <title>" --body-file <file>`;
       - a failure or non-JSON → `pr-unreadable`/`pr-failed` (1).
   12. Effective `human` → `state: waiting-for-human` (0).

   The reply (exit 0) holds:
   - `id`, `sha`, `base`, `pushed`;
   - `pull_request` (`url`, `number`, `created`) or null;
   - `verdict`, `effective`, `forge_checks` (null when missing);
   - `checks`, `rewrite`, `state`.

   Fails if wrong:
   - `test_pr_mode_never_pushes_target`, `test_human_stops_at_the_pull_request`, `test_resumed_ship_does_not_land_twice`;
   - the task tests `test_push_refuses_before_writing`, `test_stale_sha_is_refused`, `test_closed_pull_request_goes_to_a_human`, `test_forge_without_pull_requests_asks_a_person`.
4. [x] **The wait and the merge**, under an effective `automatic` only.
   - Wait only when `Forge checks: required` or a `ci` stage (`E2E stage`/`Build stage`) exists.
   - Up to 60 readings, sleeping `PO_SHIP_POLL_SECONDS` (default 30) between them. Each reading:
     - runs `gh pr view <url> --json headRefOid`;
     - once that equals `sha`, runs `gh pr checks <url> --json name,bucket,link`, read from stdout whatever the exit code.
   - What a reading gives:
     - At least one check, every bucket `pass`/`skipping` → go on.
     - Any `fail`/`cancel` → `checks-failed` (1), `checks` holding the failed `{name, bucket, link}`, and a message naming `/po-execute <id>` as a fix run.
     - No JSON or an incomplete set → read again. An empty list is never a pass.
     - Readings exhausted → `checks-timeout` (1, a human, no fix run).
     - `gh` cannot start → `checks-unreadable` (1).
   - Then run `gate` again, then `gh pr merge <url> --repo … --rebase --match-head-commit <sha>`. A failure → `merge-refused` (1).
   - Then `gh pr view <url> --json state`: `MERGED` → `state: merged`, anything else → `state: merging`, since only `MERGED` proves it (Step 3).
   - Fails if wrong: `test_automatic_waits_for_checks` and `test_checks_that_never_pass_merge_nothing`.
5. [x] **The draft rewrite**, when `effective()` gives `rewrite`; a `(chosen)` line never gets one (`mod.rs:44-48`).
   - Build the commit beside any checkout: read `origin/<Target>:AGENTS.local.md`, replace the value after `Ship confirmation:` (key and spacing kept) by `rewrite`, then `hash-object -w --stdin`. Swap the root entry from `ls-tree origin/<Target>` and run `mktree`, then `commit-tree <tree> -p origin/<Target> -m "chore: Ship confirmation follows the forge"`.
   - Skip everything when origin's line already reads `rewrite`. Skip the push when `framing/ship-confirmation` (`ls-remote`) already holds that line. Otherwise push with a lease on that ref only.
   - Open a `gh pr create --draft --base <Target> --head framing/ship-confirmation` with a fixed body and fixed title, or reuse an open one. With no GitHub repository, send the branch only.
   - A refused push or a failed draft does not stop the ship: `rewrite` reports `refused` and the line to write by hand. `rewrite` = `{line, branch, pushed, url, refused}`.
   - Fails if wrong: `test_forge_line_is_rewritten_by_the_command`.
6. [x] **Wiring, contract, version.**
   - `mod.rs` routes `push` and adds it to `USAGE`.
   - `docs/interface-agent.md`: a `ship push` row giving the order of steps, the reply, the refusals by exit code, what it writes (the story ref, `framing/ship-confirmation`, a PR, a merge; never `Target branch`), and `PO_SHIP_POLL_SECONDS`. The `ship forge` row reads the configured URL, and its usage list includes `push`.
   - Version 0.10.0 in `po/Cargo.toml`, `po/Cargo.lock` and `bin/polype`.
   - Fails if wrong: `test_version_goes_up`.
7. [x] **`/po-ship` and its phrase tests.**
   - `po-ship.md`:
     - Add `Write` to its tools.
     - The forge section keeps its heading, its first two paragraphs (`:25-27`, including "It never opens, skips or replaces…"), and the rewrite, reduced to one sentence: `po ship push` builds the settings commit beside any checkout and opens its draft; the ship never waits for it; the finish quotes `rewrite`.
     - Step 2 under `pr`: write the description (what, why, how to test, the verdict as `:50` lists it, minus any finding Step 3 holds) with the file tool into a `mktemp -d` folder outside the worktree. Run `po ship push <id> --sha <sha> --body-file <file>` so that a 30-minute wait is not cut (background), and rerun it when a call is cut. Map each `state` and error word to its finish (`checks-failed` → a fix run; `pull-request-closed`, `checks-timeout`, `push-refused` → a human), and keep the human line "Pull request ready: <url>. Land it with Rebase and merge…".
     - Keep `:44`'s gate sentence, `:46` and Step 0 `:22`. Leave Step 3 and the finish untouched.
     - Reach ≤ 1 698 words.
   - Tests, as the research's Traps list says:
     - drop the falling assertions of `ship-through-pr.test.sh` and of `ship-follows-forge.test.sh:116-119`;
     - drop `test_ship_text_is_complete` from `ship-and-fleet-cleanup.test.sh`, whose `po-drive` mutant stays;
     - delete `tests/ship-resumes-cleanly.test.sh`.
   - Write `tests/ship-lands-through-a-pull-request.test.sh`, sourcing the oracle like `ship-builds-the-landing-commit.test.sh:5-6`, with the task tests named above plus `test_ship_words_go_down`.
   - Fails if wrong: `test_ship_words_go_down`, and `tests/ship.test.sh`, `everything-in-issues.test.sh` and `review-findings-shape.test.sh` staying green.

## Scene viewpoints
—

## Run interdicts
- Code may only push to `refs/heads/story/<id>` and `refs/heads/framing/ship-confirmation`; `grep -n 'push' po/src/ship/push.rs` shows no other refspec. `Target branch` is never pushed.
- Every git write goes through `ship/git.rs`. `po/src/project.rs`, `po/src/trust/` and every other module end with an empty diff.
- No token in an argument, a file or the output. `gh` uses its own login, there is no `curl` write fallback, and every `gh` call carries `--repo github.com/<owner>/<repo>`. Body text only travels by `--body-file`.
- `method/commands/po-ship.md` from `## Step 3` to the end: empty diff. `method/AGENTS.md`, `po-setup.md`, `po-drive.md`, `po-intake.md`, `method/hooks/`, `.claude/`, `.polype/`: empty diff.
- Every phrase that `tests/ship.test.sh`, `everything-in-issues.test.sh` and `review-findings-shape.test.sh` read in `po-ship.md` survives.
- Cleanup and filing (Step 3) are s195/s196's job, so none of them goes into `push`.
- Tests touch no real forge, push nothing to GitHub, and leave nothing in `/tmp`. Never read `.polype/inbox/`.

## The pivot
**`po ship push` reads the forge and decides the merge itself.** No caller can ask for a merge. Where it could be wrong:
- **The configured URL vs `insteadOf`.** Task 1 makes the forge follow the configured URL. A person whose `insteadOf` maps github.com to a mirror now gets a GitHub reading where s192 said unreadable. The token still only goes to github.com (ADR-0083). Compare with `Forge::of`, which already did this.
- **The remote head wins over `--sha`.** Resume safety hangs on `still_the_landing` comparing a fresh `merge-tree` with the remote head. After a fix run, or once the base moves, the tree differs and the new sha is pushed under a lease taken from `ls-remote`. A lease taken from a stale tracking ref would refuse every push after a deleted branch.
- **The wait lives in one call.** A 30-minute call outlives a 10-minute foreground shell, so `/po-ship` must launch it in the background, and a cut call is simply rerun. The 30-minute bound then holds per call, not overall. Safety stays in code (no merge without passing checks and a passing gate). Check `po-ship.md` says this.
- A failing forge check now names a fix run (criterion), where the prose said none. A timeout or an unreadable forge still goes to a human.

## Files touched
- `po/src/ship/push.rs` (new), `po/src/ship/mod.rs`, `po/src/ship/land.rs`, `po/src/ship/forge.rs`, `po/src/ship/git.rs`
- `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`
- `tests/ship-lands-through-a-pull-request.test.sh` (new), `tests/ship-through-pr.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/ship-and-fleet-cleanup.test.sh`, `tests/ship-resumes-cleanly.test.sh` (deleted)

All are in `Owns`. `po/src/main.rs` and `tests/ship-files-the-other-findings.oracle.test.sh` need no change.

## Test strategy
- **Automated, one layer: the `po` binary run as a command against throwaway repositories.** There are no Rust unit tests in this crate.
  - The oracle has 6 tests.
  - The task file has 6: `test_push_refuses_before_writing`, `test_stale_sha_is_refused`, `test_closed_pull_request_goes_to_a_human`, `test_checks_that_never_pass_merge_nothing`, `test_forge_without_pull_requests_asks_a_person`, `test_ship_words_go_down`.
  - That makes 12 of the 25 allowed.
- **What each task test checks:**
  - `test_push_refuses_before_writing`: a refused gate, `Merge mode: local` and a missing body file each leave origin's refs and the gh write calls unchanged.
  - `test_checks_that_never_pass_merge_nothing`: an always-empty list gives `checks-timeout`, and gh failing to start gives `checks-unreadable`, both with no merge.
  - `test_forge_without_pull_requests_asks_a_person`: a gitlab URL sends the branch and makes no `gh pr` call.
- **The forge double:** the gh double is a script in the test, as in s192. Pull requests are JSON files, heads are read from the bare origin, and a merge is replayed as the forge's rebase. Writing to a real forge is not possible in a test, which is why the double stands in.
- **What a test cannot prove:**
  - The lease itself: nothing can move origin between `ls-remote` and the push. The reviewer checks the `--force-with-lease=refs/heads/story/<id>:<observed>` form by reading it.
  - The 30-second default: covered by reading, since the tests run at 0.
- **Checks run:** the full suite once at the end through `po-run`, and `cargo build --locked` by `tests/run.sh`.

## Done when
- All 7 tasks are ticked.
- The oracle, the task tests and the full suite are green, recorded by `po-run`.
- `po-ship.md` is at ≤ 1 698 words.
- Version 0.10.0 is in three places.
- One commit with the research, the plan and the oracle.
- A review with no open critical finding, and the story landed through its pull request.
