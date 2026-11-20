---
track: flow
validated: yes
---
# Plan (short track) — s196-ship-cleans-the-lane

[Story](../stories.md)

Written by the planner on the short track (`po next`: flow; complexity 2 ≤ `Flow threshold: 3`). This file stands in for the research. Plan validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
- **No false assumption.** The story's note cites `po-ship.md:99-103` and `po-drive.md:95-100`: stale line numbers. Cleanup is now `po-ship.md:52-59` (proof `:53`, removal `:58-59`); `po-drive.md` cites it at `:40` (`reason landed → its cleanup only`) and `:117` (status: "its pull request prints `MERGED`", a forge read by branch name).
- **The forge-by-branch proof d-0047 removes**: `po-ship.md:23` (Step 0, `gh pr view story/<id> ... MERGED`) and `:53` (Step 3.1, same call). `gh pr view <branch>` resolves the repository `gh` infers, by branch name alone.
- **The landing proof `po` already shares**: `land::landing_by_subject` (`po/src/ship/land.rs:490-495`), the newest commit of `<base>` outside `story/<id>` whose subject is exactly `<id>: <title>`; `<base>` from `land::base` (`land.rs:302-316`): `git fetch -q origin` then `refs/remotes/origin/<target>` under `pr`, `refs/heads/<target>` under `local`. Used by `land` (`land.rs:548`), `push` (`push.rs:528`, before any forge call) and `file` (`file.rs:476`, refusing `not-landed`). So: **local mode** → found once `--land`/`--sha` fast-forwarded the root; **rebase merge** → GitHub rebuilds the commit with the same subject on origin's main → found after the fetch; **a merge whose subject a person changed** (squash with an edited title) → not found → `not-landed`, nothing removed, a person cleans by hand. `push` alone also accepts a merged pull request whose head is the commit sent (`push.rs:578-583`); `file` does not, and `clean` follows `file`: no forge call at all.
- **Trap in the shared proof**: `landing_by_subject` excludes `^story/{id}` (`land.rs:491`). Once the local branch is deleted, `git log ... ^story/<id>` fails, `read` returns `None` and the proof is lost: a rerun after the local deletion would answer `not-landed`. Also `story/<id>` resolves a tag `refs/tags/story/<id>` before the branch.
- **Where a sub-step attaches**: `ship::main` dispatches `land|push|file` (`po/src/ship/mod.rs:84-90`), usage string `mod.rs:17-19`; `main.rs:228` routes `ship`. Writing git goes through `ship::git::run` (`git.rs:162`, `LC_ALL=C`, no prompt); reads through `land::read` (`land.rs:484`). Errors: `output::error(REFUSED|UNREADABLE, code, msg)` (`output.rs:5-7,36`).
- **Every earlier sub-step demands the worktree as cwd** (`land::worktree`, `land.rs:134-160`). `clean` deletes that worktree, so it runs from the repository root: `Project::find` resolves the main checkout from root or worktree (`po/src/project.rs:38-48`). The lane path is `<root>/<Worktree root><id>` matched against `git worktree list --porcelain` (`po/src/context/lanes.rs:208-219`; that parser `lanes.rs:128-143` is private and outside `Owns`).
- `po next` gives `ship`, reason `landed` from the subject prefix `<id>:` on `<target>` or `origin/<target>` (`po/src/next/lane.rs:56-57`, `context/lanes.rs:80-110`), without the gate (probe: minimal fixture, no hooks → `{"action":"ship","reason":"landed"}`).
- Remote story head: `push::ls_remote` (`push.rs:166-176`, private; reads `origin` itself, never a tracking ref).
- Git probes (scratch, removed): `git worktree remove` without `--force` removes a worktree holding only ignored files (`.env`), refuses an untracked or modified file (exit 128), and succeeds on a listed worktree whose folder is gone; `git push origin --delete` of a missing ref exits 0 on a local bare (GitHub refuses it), so absence is read first; `git update-ref -d <ref> <old>` refuses when the ref moved. `git branch -d` always refuses a story branch (its commits never land, ADR-0081): deletion is `update-ref -d` with the head read at the start, never `branch -D`.
- **Out of `Owns`, still true after the change**: `po-setup.md:74` says framing branches are proven "as step 3 of `/po-ship` proves a ship" and carries its own `gh pr view framing/<slug>` proof; `method/AGENTS.md:129,141`, `po-intake.md:24,76`, `po-gate.sh:94` cite `## Step 3`, step 3.2, its taskwarrior `<name>` rule and `## The forge's review rule`: all kept. ADR-0081 (Consequences) says "la preuve de merge reste donc `MERGED`, jamais `--is-ancestor`"; the code has used the subject proof since s193-s195, and d-0047 makes it the cleanup's — not a contradiction of the decision, but that line is outdated (reported, not planned around).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — no data store; git refs only |
| New screen | absent — `Surface: command` | absent |
| Authorization or tenant scope | absent — story text | absent — no forge call, no token |
| API contract | absent — story text | absent — one more `po ship` sub-step, `contract` stays 1, no existing field changes (`docs/interface-agent.md:272-275`) |
| New dependency | absent — story text | absent — std + `serde` already in `po/Cargo.toml` |
| Technical choice that deserves an ADR | absent — ADR-0130 names `po ship clean <id>` | absent — the proof is the shared one, set by d-0047 in the criterion |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no such line | absent |

## Story
`po ship clean <id>` removes a landed lane, once it proves the landing itself. Criteria: `nothing_is_removed_before_the_proof` (proof read on origin for the landing commit; `po-ship.md` no longer asks the forge by branch name, Step 0 nor cleanup), `cleanup_is_not_forced` (worktree without force, then local and remote branch; uncommitted work stops it, named), `landed_lane_is_cleaned_alone` (no gate, no commit), `cleanup_reruns_cleanly`, `ship_is_a_short_command` (`po-ship.md` < 1 000 words, `po-drive.md` ≤ 2 449), `version_goes_up`.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Landing proof | in repo: `land::landing_by_subject` (`land.rs:490`), `land::base` (`land.rs:302`) | — (fixed in place for the trap above) |
| Title of the story | in repo: `land::title` (`land.rs:257`), split into `title_in(text, id)` read from `git show <base>:docs/stories.md` | the worktree file may be gone on a rerun |
| Remote check, settings, git launcher, errors | in repo: `land::remote_check` `:239`, `land::setting` `:208`, `git::run`, `land::git_failed` `:294`, `output` | — |
| Remote head | in repo: `push::ls_remote` `:166`, made `pub(super)` | — |
| Worktree listing parser (~15 lines) | new code in `po/src/ship/clean.rs` | `context/lanes.rs:128` is private and outside `Owns`; no std or crate parses porcelain |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/ship-cleans-the-lane.oracle.test.sh` | `3020211613 9490` |

| Criterion | Test |
| --- | --- |
| `nothing_is_removed_before_the_proof` | `test_nothing_is_removed_before_the_proof` — sent not merged; landed on root's `main` only; origin commit quoting the subject in its body; subject extended; `local` not landed: each `not-landed`, lane intact; no `gh` call; no `gh pr view|list` in `po-ship.md` |
| `cleanup_is_not_forced` | `test_cleanup_is_not_forced` — untracked file → `dirty-worktree` naming it, nothing removed; then cleaned after a rebase merge (`.env` goes, origin `main` unmoved); `local` cleaned with `remote: null` |
| `landed_lane_is_cleaned_alone` | `test_landed_lane_is_cleaned_alone` — `po next` says `ship`/`landed`; no gate hook, review `Ship allowed: no`; cleaned, no new commit in root or origin, `HEAD` unmoved |
| `cleanup_reruns_cleanly` | `test_cleanup_reruns_cleanly` — cut after the worktree, its folder only, worktree + local branch, remote only, everything: each rerun exits 0, all gone |
| `ship_is_a_short_command` | `test_ship_is_a_short_command` — word counts; the rest is model-read, judged in review |
| `version_goes_up` | `test_version_goes_up` — above 0.11.0, three places equal |

## Tasks
1. [x] **`po ship clean <id>`** in new `po/src/ship/clean.rs`, wired in `mod.rs` (dispatch, module doc, `USAGE` gains `| po ship clean <id>`). From cwd anywhere in the project; every git call runs in `project.root`. Order, every check before the first deletion: args (one id, `land::is_id`; any option → `unknown-option`); settings `Target branch` (not `—`), `Merge mode` (`pr|local`), `Worktree root`; `land::remote_check`; `land::base`; title from `<base>:docs/stories.md` (`no-title`); proof `landing_by_subject` → else exit 1 `not-landed` ("no commit of <target> is titled `<subject>`: nothing is removed"); worktree listing: the lane path holding another branch → `not-the-lane`, another path holding `refs/heads/story/<id>` → `branch-in-use` (path named); lane folder present → `git status --porcelain` non-empty → `dirty-worktree` with `paths`; local head `rev-parse -q --verify refs/heads/story/<id>`; under `pr`, `ls_remote(root, "refs/heads/story/<id>")` (failure → `git-failed`). Then: `git worktree remove <path>` when listed (never `--force`; refusal → `worktree-refused` quoting git, nothing after it runs); `git update-ref -d refs/heads/story/<id> <head>`; under `pr` with a head, `git push -q origin --delete refs/heads/story/<id>` (refusal → `delete-refused`). Reply exit 0: `state: "cleaned"`, `id`, `landed` (sha), `worktree` `removed|absent`, `branch` `deleted|absent`, `remote` `deleted|absent`, `null` under `local`. In `land.rs`: `landing_by_subject` excludes `^refs/heads/story/<id>` only when that ref exists; `title` reads through `title_in`. `push::ls_remote` → `pub(super)`. — Fails: the oracle's four behaviour tests; `cleanup_reruns_cleanly` (cut `worktree-and-branch`) fails if the exclusion fix is missing.
2. [x] **`tests/ship-cleans-the-lane.test.sh`**, same fixture shape as the oracle: (a) owns only its refs — `upstream` remote's `story/s01-a`, tag `story/s01-a`, `story/s01-a-b` local and on origin, origin `main` all kept; (b) `branch-in-use` — lane removed by hand, `story/s01-a` checked out at another path: refused, branch and remote kept, path named; (c) `not-the-lane` — lane path on another branch: refused, nothing removed; (d) a locked worktree (`git worktree lock`): `po`'s own status check passes, git refuses → `worktree-refused`, local and remote branches kept (tells the two dirty guards apart); (e) usage: no id, a bad id, an option → exit 2. — Each fails when its guard is removed.
3. [x] **`method/commands/po-ship.md` to ≤ 999 words** (1 250 now; a full draft counted 987, every rule kept). Step 0 opens: "A story `po next` answers `ship` with reason `landed` goes straight to Step 3: no gate, no check." and drops `:23`. Step 3: item 1 "Proof. Each call below reads it itself: a commit of `Target branch`, on `origin` under `pr`, titled exactly `<id>: <story title>`. No call files or removes anything without it."; item 2 keeps `2. File the open findings`, from the worktree, before it goes; items 3-4 become one: "From the repository root, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship clean <id>` removes the worktree without `--force`, then `story/<id>` locally and on `origin`, as `git push origin --delete refs/heads/story/<id>` would; a rerun finishes what is left. `dirty-worktree`, `not-landed` or any other refusal → stop, quoting its `message`." Cuts, by section (before → after): preamble 97 → 81 (`po` checks the branch); Step 0 76 → 53 (settings refusals are `po`'s, `missing-setting`); forge rule 124 → 92 ("Read at every ship…" and the rewrite sentence shortened); Step 1 140 → 120 (what `land` runs; refusal list → "any other refusal"); Step 2 299 → 265 (`Remote check (Step 1): pr needs origin;`, "merging nothing", the effective-value sentence); Step 3 + finish 514 → 376 (proof and removal into `po`, `filed`/`already_open` named once in the finish, which also names a null `forge_checks`). Must stay (tests outside `Owns`): `Pull request ready: <url>. Land it with Rebase and merge`, `` `Merge mode: local` is only for a repository without a remote ``, `## Step 3 — Cleanup, only after proof`, a line starting `2. File the open findings`, the taskwarrior `<name>` sentence, `## The forge's review rule` between Step 0 and Step 1, every `git push` line naming `story/<id>`, no `squash`. — Fails: `test_ship_is_a_short_command`, the `gh pr` check of the oracle, `ship-through-pr`, `ship-files-open-findings` (out of `Owns`).
4. [x] **`method/commands/po-drive.md:117`**: "a merged lane waiting for cleanup — its pull request prints `MERGED` while its worktree still exists — is listed among them under that name, with its pull request URL" → "a lane whose reason is `landed` is listed among them as a merged lane waiting for cleanup, with its pull request URL" (2 449 → 2 442). — Fails: `test_ship_is_a_short_command`.
5. [x] **Phrase tests in `Owns`**: `tests/ship.test.sh` — `test_ship_cleans_up_only_on_proven_merge` keeps `Cleanup, only after proof` and drops `prints exactly \`MERGED\``, `` `--force` is not an option ``, `Do not test the story branch's own commits`; `test_ship_goes_straight_to_cleanup_after_a_human_merge` is deleted (now `test_landed_lane_is_cleaned_alone`). `tests/everything-in-issues.test.sh` — `test_ship_files_open_findings` drops `the review is not lost with the worktree…`, anchors the removal on `ship clean <id>` instead of `git worktree remove <path>` (order proof < file < clean kept), drops the `prints \`MERGED\` while its worktree still exists` assertion. `ship-and-fleet-cleanup`, `ship-follows-forge`, `drive`, `ship-files-the-other-findings.oracle` need no change. — Fails: the full suite.
6. [x] **`docs/interface-agent.md`**: new row `ship clean <id>` after `ship file` (order of checks, proof, replies and refusals of task 1, "écrit : le fetch sous `pr`, le retrait du worktree, `refs/heads/story/<id>` local et sur `origin` ; ni porte, ni commit, ni forge"), and `:272` usage list adds `clean`. **Version 0.11.0 → 0.12.0** in `po/Cargo.toml`, `po/Cargo.lock`, `POLYPE_VERSION` of `bin/polype`. — Fails: `test_version_goes_up`, `po-change-needs-a-version`.

## The pivot
The proof is `landing_by_subject` on `<base>` after `po`'s own fetch, with no forge call. If wrong: a squash merge whose title a person edited is never proven, and the lane waits for a person (`not-landed`) — chosen on purpose, since `/po-ship` tells the person "Rebase and merge", which keeps the subject. Second hinge: `clean` must run from the root and survive its own deletions; the exclusion fix in `landing_by_subject` is what makes a rerun after the local deletion prove the landing again.

## Run interdicts
- No `--force`, `-f`, `-D`, `+refspec` or `--force-with-lease` in `clean.rs`; no `git worktree prune`, `switch`, `checkout`, `stash`.
- `clean.rs` never runs `po-gate`, `gh`, `commit`, `commit-tree` or `merge`, and pushes only `--delete refs/heads/story/<id>` to `origin`.
- Empty diff: `po/src/context/`, `po/src/next/`, `po/src/project.rs`, `method/hooks/`, `method/commands/po-setup.md`, `method/commands/po-intake.md`, `method/AGENTS.md`, the oracle file (sum above), `tests/ship-files-the-other-findings.oracle.test.sh`.
- No test touches a worktree or branch of this repository; fixtures live under one `mktemp -d`, removed on exit.

## Notes after validation
Dated 2026-11-20; the validated tasks above are not rewritten.
- **Interdicts and Task 1.** At the lead's request `clean.rs` does use `--force-with-lease=<ref>:<head>` on the remote deletion (above, the interdict forbids it), and Task 1's replies gain `state: "remote-kept"` (exit 1, `remote: "kept"`, `remote_head`, `message`) for a remote head that is not the landing; the local cleanup already done stays done. `docs/interface-agent.md` describes both.
- **Fix run 1 (decision d-0049, `fix-here`).** `clean.rs` gains, before any deletion, a check on the local branch (refusal `branch-not-landed`) and a stricter test of the remote head, and `git::Ran` keeps the raw bytes of stdout. Tests: `clean_keeps_a_branch_that_the_landing_does_not_hold`, `clean_keeps_a_remote_head_whose_parent_is_not_on_the_base`, `clean_compares_the_change_of_a_remote_head_byte_for_byte` (15 tests in all, within budget). `po-ship.md` Step 3 says a cut cleanup is resumed by rerunning `po ship clean <id>` alone from the root; `po next` and `po state` list lanes from worktrees only, so `po-drive.md` is unchanged.

## Files touched
`po/src/ship/clean.rs` (new), `po/src/ship/mod.rs`, `po/src/ship/land.rs`, `po/src/ship/push.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `tests/ship-cleans-the-lane.test.sh` (new), `tests/ship.test.sh`, `tests/everything-in-issues.test.sh`, this plan, the oracle.

## Test strategy
Adapter layer only (the `po` binary through its CLI and JSON), against throwaway repositories with a local bare `origin` and a logging `gh` double that must stay unused: 6 oracle tests + 5 in `ship-cleans-the-lane.test.sh` = 11, within `Test budget: 25`. The remote-deletion and `update-ref` old value are the form of the call, not separate guards. Model-read rules (Step 0 routing, file before clean) are judged in review. Focused runs: `bash tests/run.sh ship-cleans-the-lane.oracle.test.sh ship-cleans-the-lane.test.sh ship.test.sh everything-in-issues.test.sh ship-through-pr.test.sh ship-files-open-findings.test.sh ship-follows-forge.test.sh`; then the full suite once through `po-run`.

## Done when
The oracle and the focused files pass, the full suite passes once through `po-run`, `po-ship.md` < 1 000 and `po-drive.md` ≤ 2 449 words, the version is 0.12.0 in three places, and one commit carries code, tests, this plan and the oracle.
