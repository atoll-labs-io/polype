# Review — s108-ship-resumes-cleanly

Diff reviewed: `git diff main...story/s108-ship-resumes-cleanly`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 006d168c22c5459637a2b1d1811cd1e5d8536e49

## Ownership
I listed the diff with `git diff --name-only main...story/s108-ship-resumes-cleanly` and held each path against the story's `Owns` line: `method/commands/po-ship.md`, `tests/ship-through-pr.test.sh`, `tests/forge-token-host.test.sh`, `tests/ship-resumes-cleanly.test.sh`.
- [x] Every path is inside `Owns`. The diff changes `method/commands/po-ship.md` (M), `tests/ship-through-pr.test.sh` (M) and `tests/ship-resumes-cleanly.test.sh` (A). The other three paths are the story's own evidence: `docs/research/`, `docs/plans/`, `docs/verif/`. `tests/forge-token-host.test.sh` is owned but untouched, as the plan says.
- [x] Nothing outside `Owns`.
- [x] Nothing inside another running story's `Owns`. The only other lane in `git worktree list` is s109-drive-guards, which owns `method/commands/po-drive.md`, `method/commands/po-orchestrator.md` and `tests/drive-guards.test.sh`. None of them overlaps this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s108-ship-resumes-cleanly` → exit 0. With `Verification mode: record`, the record proves the unit suite: `bash tests/run.sh`, exit 0, on a tree whose code outside `docs/` equals `Tree: 98aa3899…`. I did not rerun the full suite. The project has no type check, E2E or build command (`—`). The record's "Not proven here" section says no real push and no `gh pr merge` were run against a forge.
- [x] `po-gate qa-current`: not required. `Surface: —` and `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All six tasks are present, and the diff makes no change the plan did not ask for. Line 74 adds the rebinding sentence with the exact phrases. Line 77 adds "`<sha>` being the pushed head when the push was skipped". The `test_no_agent_pushes_target_branch` test was strengthened. The new test file holds both tests. Line 27 now uses `curl -q`.
- [x] Each run interdict holds:
  - Only the three planned code paths change outside `docs/`.
  - `po-ship.md` changes only on lines 27, 74 and 77.
  - `po-setup.md`, `AGENTS.md`, `po-drive.md`, `.claude/`, `.polype/`, `docs/stories.md` and `docs/decisions/` are untouched.
  - `GIT_COMMITTER_DATE` and `GIT_AUTHOR_DATE` are absent from `po-ship.md` (count 0).
  - The existing test changed only by added assertions, and the commit message says so.
  - The diff makes no real push.
- [x] I checked the pivot's three risks:
  - The `git fetch origin` of the "Base" paragraph still comes before the landing bullet, so `origin/story/<id>` is fresh when the skip condition reads it.
  - `git grep 'git push' method/` shows nothing else in the method pushes `story/<id>`.
  - Line 74 does not contain the words `Target branch`.

## References
- [x] I opened every reference and confirmed it:
  - `git rev-parse origin/story/<id>` and `gh pr merge --match-head-commit`, as the research verified.
  - `curl -q` must be the first argument to skip `~/.curlrc`, and the text says "`-q` first".
  - The helper `section_of` is copied from `forge-token-host.test.sh`; `fail` and `$METHOD` come from `tests/lib.sh`.
- [x] No value only looks right. "only parent" makes the old skip condition stricter, which is safe. The test's exact phrases match the file text.

## Rules
- [x] The `AGENTS.md` conventions are respected: method text in English, bash tests in one file per story, commit message in English with no co-author trailer. One deviation is under Findings.
- [x] No accepted ADR is contradicted. ADR-0081 still holds: the landing commit is built beside the branch and `story/<id>` is never rewritten.

## Tests
- [x] Floor: `po-gate floor-guard s108-ship-resumes-cleanly main` → exit 0, nothing lowered.
- [x] The assertions pin down the three criteria. None of the six empty test shapes is present: no `catch`, and no fixture or mock (the tests grep the file under test).
- [x] 2 new tests and 1 strengthened test, within `Test budget: 25`.
- [x] Bite, run on a copy of `method/` and `tests/` under `/tmp/tmp.s1VNws5F2O`, never in the worktree. Each time I ran only `ship-resumes-cleanly.test.sh`, `ship-through-pr.test.sh` and `forge-token-host.test.sh`:
  - Baseline on the copy: 1 failure, `ship_gate_unchanged`. This comes from the copy, not the code: the same three files pass in the real worktree (10 passed, 0 failed). That failure appears in every row below and is not counted.
  - B1, rebinding sentence deleted from line 74 → `resumed_ship_merges_the_pushed_head` fails (1 test).
  - B2, refspec rewritten to `<sha>:refs/heads/<Target branch>` (the s105 bite) → `no_agent_pushes_target_branch` fails (1).
  - B3, extra `<sha>:refs/heads/main` refspec appended → `no_agent_pushes_target_branch` fails (1).
  - B3b, "then onto <Target branch>" appended to the push line → `no_agent_pushes_target_branch` fails (1).
  - B4, `, pinned with --hostname github.com` removed (the s107 bite) → `forge_read_pins_and_skips_curlrc` fails (1).
  - B5, line 27 reverted to main's "plain `curl`," → `forge_read_pins_and_skips_curlrc` fails (1).
  - B5b, only `-q` dropped → `forge_read_pins_and_skips_curlrc` fails (1).
  - B6, rebinding sentence moved below the `gh pr merge` line → `resumed_ship_merges_the_pushed_head` fails (1).
  - After each mutation the copy was restored from `orig.md`; `cmp` confirmed it was identical. In the worktree, `git diff --exit-code` and `git status --porcelain` are clean.
- [x] No test became useless because of the story.

## Neighbours
- [x] I read the other callers of `--match-head-commit <sha>` and `git push`:
  - `po-setup.md:77-81`, the framing landing, always pushes and never skips, so its `<sha>` is always the head it just pushed. The s105 defect does not exist there, and the file belongs to s110.
  - `po-ship.md:84`, the local proof, and `:86`, the remote delete, are unaffected.
  - `po-drive.md` has no `--match-head-commit`.

## Lenses
Lenses run: security — the diff changes the forge probe line, an HTTP call whose URL host comes from `git remote get-url origin`. No finding: the change only hardens it (`-q` stops `~/.curlrc` from adding a header or `--netrc`), and no token is added. Migration, dependencies and performance did not run: their triggers are absent.
- [x] No lens finding.

## Findings
- minor — `tests/ship-through-pr.test.sh:27` — The criterion `push_targets_only_the_story_ref` has no test function under its own name. `AGENTS.local.md` says "An acceptance criterion's name is its test function's name", but here the criterion is carried by `test_no_agent_pushes_target_branch`. The plan's test strategy justifies this (the criterion itself names that test, and a duplicate would test the same rule twice), so I graded it minor.
- minor — `method/commands/po-ship.md:74` — The skip condition says "the head of `origin/story/<id>`" without saying what happens when that ref does not exist yet. That is the normal first pass in pr mode, where nothing is skipped and the push runs. A reader can infer it, so this is clarity only.
- minor — `method/commands/po-ship.md:74` — The research's open question still stands: the skip condition checks parent and tree, not the commit message `<id>: <story title>`. It is safe today, because only `/po-ship` pushes `story/<id>`. A future command that pushes there would make the rebound `<sha>` merge a commit with another message.

## Not verified
- The real skip-then-merge path against a forge: no `git push`, `gh pr view` or `gh pr merge` was run, because the reviewer's hook refuses `git push` and the plan forbids forge calls. The fix is prose, and the tests check its wording, not its behaviour. A person should, on a throwaway GitHub repository, run `/po-ship` to the open PR, interrupt it before the merge, run it again, and confirm that `gh pr merge --match-head-commit` is given the head already pushed and succeeds.
- `curl -q` reading no `~/.curlrc` on the user's curl version: I relied on the research's `man curl` reading (curl 8.22.0) and did not run it. A person can check it with a `~/.curlrc` that adds a header, then `curl -q -v https://<host>/api/v1/version`.
- The full unit suite was not rerun here. The record is current (`po-gate verif-current` passes), and I ran only the three affected test files: 10 passed.

Max severity: minor
Ship allowed: yes
