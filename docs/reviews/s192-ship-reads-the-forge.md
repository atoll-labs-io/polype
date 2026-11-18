# Review — s192-ship-reads-the-forge

[Story](../stories.md) · [Plan](../plans/s192-ship-reads-the-forge.md) · [Verification](../verif/s192-ship-reads-the-forge.md)

Method version: 0.6.1
Recorded: 2026-11-18T16:30:55+01:00

Review status: complete
Reviewed tree: 991f37e83a0d608e3ec515e640e678b83f6a90cd
Fix loop: 0
Lenses run: Security (the diff reads forges with tokens and decides whether an agent may merge alone: `po/src/ship/forge.rs`, `po/src/trust/forge.rs`); Dependencies (`po/Cargo.lock` changed, but only `po`'s own version moved, with no dependency entry added, removed or bumped, so the lens found nothing)

## Scope
Every path in `git diff --name-only main...story/s192-ship-reads-the-forge` falls inside the story's `Owns`, or is the story's own pipeline evidence (research, plan, verif). ADR-0130 sits under `docs/decisions/`, which `Owns` lists, and the plan names it. No other story is running: `git worktree list` shows no other `story/*` lane.

## Verification relied on
- `po-gate verif-current s192-ship-reads-the-forge` exits 0 (`Verification mode: record`). The `Unit suite` row ran `bash tests/run.sh` and exited 0, on code equal to `Tree:` outside `docs/`. I did not rerun the full suite. The project has no `Typecheck`, `E2E` or `Build` command (`—`). `tests/run.sh` builds `po` with `cargo build --release --locked`.
- `po-gate oracle-intact` exits 0.
- `po-gate floor-guard … main` exits 1 with one flag: `tests/forge-token-host.test.sh` was deleted. The plan names that file and gives the reason (its three tests fall and `test_token_never_travels` holds the behaviour), so the flag is a justified minor (finding 3).
- I ran the story's two test files myself: 10 passed.

## Bite
Each mutation was undone, and `git diff --exit-code po/src/ship/forge.rs` was clean after each one. Test files run: `ship-reads-the-forge.oracle.test.sh` and `ship-reads-the-forge.test.sh`.
1. `protection_absent` was changed to read any 403 as an absence: 1 test failed (`absence_is_not_an_error`).
2. `glab` was launched with its token variables left in place: 1 test failed (`token_never_travels`).
3. The Forgejo full-page rule was disabled (`full` forced false, `po/src/ship/forge.rs:295`): 0 tests failed. The rule is not tested (finding 4).

## Removed phrase tests
I checked each fallen assertion against where the behaviour now lives:
- **`ship-follows-forge.test.sh`, 19 assertions:** the rules they quoted (forge recognition, the three signals, the "Upgrade to GitHub Pro" 403, the effective-value and rewrite tables, the line standing when the forge is unreadable) are now in `po/src/ship/` and are held through the doubles by the oracle tests `verdict_follows_the_three_signals`, `absence_is_not_an_error` and `chosen_is_never_rewritten` (a 9-row table). The draft-branch phrases, which stay prose until s194, are kept.
- **`forge-token-host.test.sh` (deleted):** held by `test_token_never_travels`. It checks that `curl` gets the token on stdin and only for `https://api.github.com/`, that `glab` and `tea` run without their token variables, and that the probe carries no header or credentials.
- **`ship-resumes-cleanly.test.sh`, one test:** replaced by the task test `test_github_read_is_pinned_and_curl_skips_curlrc`.

## The model-read criterion `ship_command_reads_the_value`
I judged it by reading `po-ship.md` and `po-setup.md`.
- `## The forge's review rule` keeps its heading and its place. It keeps "never opens, skips or replaces `po-gate ship-allowed`", runs `po ship forge`, and takes `effective` from its output.
- The finish names the verdict, the signals and `failed`, and still says when the forge overrides a `(chosen)` line.
- `po-setup.md:27,75,90` now refer to the command's output. `po-intake.md:76` and `AGENTS.md:141` still resolve.
- Word counts: `po-ship.md` went from 3302 to 2700 words (602 fewer, the criterion asks for at least 600). `po-setup.md` went from 2274 to 2272.
- No rule was lost. Each removed clause is either in the code (bare `automatic` on a solo repository left as it is; the token rules of ADR-0083) or still in the prose.
- One small loss of detail: "the report says which CLI and which host" now comes out only as a fixed reason word. That is covered by finding 2.

## Departures named by the implementer
- **`tea api … -i`:** needed, because without a status line every answer would read `unreadable`. It is unverified on a real `tea` (see Not verified).
- **Forgejo collaborators read with `?limit=50`:** see findings 1 and 4.
- **`failed[].signal` can be `null`:** documented in `docs/interface-agent.md`. Acceptable.
- **The reason `"HTTP <code>"`:** consistent with the contract's "an HTTP status".
- **A team or e-mail CODEOWNERS owner counts as true when the own login is unknown:** correct. The old prose counted them whatever the login, and only `@user` owners stay undecided.
- **The suite was run after the first commit, and the record was folded in with `--amend`:** the record gate passes on the reviewed code, so this is fine.
- **Word ceilings lowered in two earlier oracle tests:** planned in task 8, and they make those tests stricter, not looser.
- **The weakness the implementer named, `call: "user"` when access cannot be set up:** confirmed, finding 2.

## Tests
- Oracle: `po-gate oracle-intact s192-ship-reads-the-forge` → exit 0

## Findings
Security findings: 2 — decision d-0043
- minor — po/src/ship/forge.rs:449 — When access cannot be set up (`no-cli-no-token`, `no-glab-login`, `no-tea-login`), the `failed` entries name `call: "user"`, a call that was never made. Before this story, the prose report said "which CLI and which host". The plan's contract says `call` is an API path or a `git show`. Naming the tool's own status call (`gh auth status`, `glab auth status`, `tea logins list`) would match the contract.
- minor — tests/forge-token-host.test.sh:0 — The test file was deleted. `floor-guard` flags it, and the plan names the file and justifies the deletion (its three tests are held by `test_token_never_travels`), so it grades minor.
- minor — po/src/ship/forge.rs:295 — The Forgejo full-page rule (a page of 50 counts as cut short, so `list-truncated`) fails no test when it is disabled. Only the GitHub page of 100 is tested (`test_full_collaborator_page_is_unreadable`). Adding a Forgejo case to that test would cover it.

## Not verified
- **GitLab and Forgejo/Gitea on a real instance:** never tried (#75, already filed). The flags `glab api -i --hostname`, `glab auth status --hostname`, `tea api --login <name> -i`, `tea api --help` and `tea logins list --output json` with its `name`/`url` fields were exercised only against doubles. A person should run `po ship forge` once against a real GitLab and a real Forgejo repository.
- **The real `gh api -i` and `curl -i` output format (status line, blank-line separator, a redirect giving a single block):** taken from the plan's pivot (checked 2026-11-18 by the implementer), not reproduced here, because no real forge may be called. A person should run `po ship forge` once on a real GitHub repository, with `gh` and with only `GH_TOKEN`.
- **Whether GitHub reports branch protection for a token without admin rights as 403 or 404:** the code follows ADR-0079 as written, and I did not check what GitHub actually returns.
- **A branch name containing `/` in the GitHub protection and ruleset paths:** not tried on GitHub.
- **The behaviour of `/po-ship` and `/po-setup` driven by a model reading the new prose:** this is a model-read rule, judged by reading only. It is a candidate for a `po-eval` control arm (#208).
- **The full suite:** I relied on the record and did not rerun it.

Max severity: minor
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T17:20:17+01:00

Review status: complete
Reviewed tree: 968e1b20c9dfaac76b1f87d0000a233cc96f5f51
Fix loop: 1
Lenses run: Security (the diff reads forges with tokens and builds API paths from the `Target branch` setting: `po/src/ship/forge.rs`, `po/src/trust/forge.rs`). Dependencies (`po/Cargo.lock` changed, but only `po`'s own version moved and no dependency entry did, so the lens found nothing).

## Scope
Every path in `git diff --name-only main...story/s192-ship-reads-the-forge` is covered by the story's `Owns` (`docs/stories.md:3120`) or is the story's own evidence (research, plan, verif, review). The plan names ADR-0130, which the diff adds under `docs/decisions/`. The fix commit fb1f76d touches `po/src/ship/forge.rs`, `po/src/trust/forge.rs` and `tests/ship-reads-the-forge.test.sh`, plus the review and verif files, and all of these are owned. `git worktree list` shows no other `story/*` lane.

## Verification relied on
- `po-gate verif-current s192-ship-reads-the-forge` exits 0 under `Verification mode: record`. The record's `Tree:` (6ff8040…) matches the committed code outside `docs/`, and the last `Unit suite` run (`bash tests/run.sh`) exited 0. I did not rerun the full suite.
- The project has no `Typecheck`, `E2E` or `Build` command (each is `—`).
- `po-gate oracle-intact` exits 0, and `## Oracle changes` is empty.
- `po-gate floor-guard … main` exits 1 with one flag, the same as loop 0: `tests/forge-token-host.test.sh` was deleted. The plan justifies it, so it stays minor.
- I ran the story's two test files myself (`bash tests/run.sh ship-reads-the-forge.test.sh ship-reads-the-forge.oracle.test.sh`): 12 passed. That is 12 tests in all, within `Test budget` 25.

## Previous findings
- **The first security finding of d-0043 is closed.** `test_full_collaborator_page_is_unreadable` holds it with its Forgejo cases (total `2` and total `-`). Bites 1 and 2 below prove it.
- **The second security finding of d-0043 is closed.** `test_target_branch_is_one_path_segment` holds it through both `gh` and `curl`. Bites 3 and 4 below prove it.
- **Minor `forge.rs:449` (`call: "user"` on access failures): closed for the two entries it named.** `test_access_failure_names_its_call` holds it (bite 5). A third entry of the same kind is still there (new finding 1).
- **Minor: deleted `tests/forge-token-host.test.sh`: still present.** It is justified by the plan and floor-guard still flags it, so it stays minor (finding 2).
- **Minor: Forgejo full-page rule untested: closed.** Covered by bites 1 and 2.

## Bite
I ran the bites the implementer had not. I changed each rule, ran only the story's test files, then undid the change and confirmed it with `git diff --exit-code po/src/ship/forge.rs` (clean every time).
1. Put the condition at `forge.rs:313` back to its previous fixed-count form: 1 failure (`full_collaborator_page_is_unreadable`, Forgejo case with total 2).
2. Changed the same condition so that a missing total counts as complete: 1 failure (same test, Forgejo case with total `-`).
3. Replaced `path_segment(self.target)` at `forge.rs:372` with the raw target: 1 failure (`target_branch_is_one_path_segment`, through `gh`).
4. Removed `--globoff` from the GitHub `curl` read at `forge.rs:211`: 1 failure (`target_branch_is_one_path_segment`, its curl-argument check).
5. Put the access-failure entries at `forge.rs:467-468` back to `"user"`: 1 failure (`access_failure_names_its_call`).

`--globoff` on the Forgejo version probe (`forge.rs:97`) fails no test when removed. That URL holds only a host already restricted to `[a-z0-9.-]` (`forge.rs:76-77`), so nothing depends on it.

## The fix judged
- **Forgejo/Gitea writer rule (`forge.rs:313`)**
  - A non-empty page counts as complete only when `X-Total-Count` parses as a number equal to the page length.
  - Missing header: `header()` gives `None`, so the list counts as cut short. The verdict is `unreadable` (`list-truncated`), never `solo`. I proved this with bite 2.
  - Malformed header: `parse::<u64>()` fails and the result is `None`, so the list again counts as cut short. I judged this by reading only, not by a probe.
  - An empty page counts as complete without any header.
  - A total that differs in either direction counts as cut short.
  - A writer found on the page still gives `collaborative` before truncation is considered.
  - The rule fails safe in every case.
  - Header lookup (`trust/forge.rs:52-58`) ignores case, so it covers lowercase HTTP/2 header names. It reads only the first header block, which is the one `parse_included` takes.
  - Cost: if a real `tea api -i` does not print response headers, every Forgejo repository with any other collaborator reads `unreadable`. That is unverified (#75, already filed).
- **`failed[].call` (`forge.rs:139-200`, `:466-468`)**
  - Each value names the call that was actually made: `gh auth status`, `glab auth status`, `tea api --help`, `tea logins list`.
  - The contract row of `docs/interface-agent.md:272` says nothing about what `call` holds, so it still tells the truth.
  - The plan's output table (`docs/plans/s192-ship-reads-the-forge.md:22`, "`call` an API path or `git show <ref>:<path>`") no longer covers these values, nor the existing `git remote get-url origin`. It is a story artefact, so I record no finding.
- **Branch in API paths (`forge.rs:144-151`)**
  - Bytes outside the unreserved set are percent-encoded and `/` is kept.
  - A git ref cannot hold a `..` component or a component starting with `.`, so keeping `/` cannot climb out of the path.
  - The target is used in a path only on GitHub.
- **Commit message, test names and comments:** they match the code, except the wording flagged in finding 3.

## Tests
- Oracle: `po-gate oracle-intact s192-ship-reads-the-forge` → exit 0

## Findings
- minor — po/src/ship/forge.rs:433 — When access cannot be set up, `read` (`:469`) still calls `codeowners` with no login. A `CODEOWNERS` that holds only `@user` owners then adds an entry with `call: "user"`, reason `unknown-login`, although no `user` call was made on that path. The fix closed this mismatch for the two access entries but not for this third one. The call that failed there is the access call in `call` (or the `git show` of the file).
- minor — tests/forge-token-host.test.sh:0 — The test file is deleted. `floor-guard` flags it, and the plan names the file and justifies the deletion (its tests are held by `test_token_never_travels`).
- minor — po/src/ship/forge.rs:144 — The doc comment of `path_segment` and the test name `test_target_branch_is_one_path_segment` say the branch becomes "one path segment", but the function keeps `/`, so a branch like `release/1.0` spans two segments. The commit message also says "the status call that failed", while `tea api --help` (`:180`) is a capability probe and `tea logins list` (`:199`) can succeed and still match no login. These are wording only: the code is right.

## Not verified
- **GitLab and Forgejo/Gitea on a real instance** (#75): the following were tried only against doubles:
  - the flags `glab api -i --hostname`, `glab auth status --hostname`, `tea api --login <name> -i`, `tea api --help` and `tea logins list --output json`;
  - whether a real `tea api -i` prints the `X-Total-Count` header of the collaborator list.

  A person should run `po ship forge` once against a real Forgejo repository that has one other collaborator, and once against a real GitLab repository.
- **A malformed `X-Total-Count` value:** I judged it by reading only (it reads as cut short), with no probe.
- **The real `gh api -i` and `curl -i` output format, header block included:** taken from the plan's pivot, because no real forge may be called. A person should run `po ship forge` on a real GitHub repository, once with `gh` and once with only `GH_TOKEN`.
- **A percent-encoded branch name, and a branch name containing `/`, in GitHub's protection and ruleset paths:** never sent to GitHub. A person should run `po ship forge --target <branch>` on a real repository with such a protected branch.
- **Whether GitHub answers 403 or 404 for branch protection read without admin rights:** the code follows ADR-0079 as written.
- **`/po-ship` and `/po-setup` driven by a model reading the new prose:** this is a model-read rule, judged by reading in loop 0, and fb1f76d did not change that prose. It is a candidate for a `po-eval` control arm (#208).
- **The full suite:** I relied on the record and did not rerun it.

Max severity: minor
Ship allowed: yes
