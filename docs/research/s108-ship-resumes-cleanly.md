# Research — s108-ship-resumes-cleanly

## Structuring facts
- **Root cause (M1 of s105):** `method/commands/po-ship.md:74` skips the push when `origin/story/<id>` already holds a commit of parent `<base>` and tree `<tree>`, but never rebinds `<sha>`. `<sha>` stays the one `git commit-tree` just printed at `po-ship.md:70`, which stamps the current time, so `po-ship.md:77` passes `--match-head-commit` a SHA the pull request head does not carry, and the merge is refused. Proof: two `commit-tree` calls on the same tree and parent, five minutes apart, gave `bc38ed2…` and `c40dc0a…` (scratch repo `/tmp/tmp.sOfjIwO04U`).
- **Root cause (M2 of s105):** `tests/ship-through-pr.test.sh:31-34` only asks that each `git push` line name `story/<id>` somewhere; the push line `po-ship.md:74` names it three times outside the refspec. Rewriting the refspec to `<sha>:refs/heads/<Target branch>` left the file at 5 passed, 0 failed (temp copy `/tmp/tmp.ArYOH96YW0`).
- **Root cause (s107 minor 1):** `tests/forge-token-host.test.sh` never quotes `--hostname github.com`; deleting the pin from `po-ship.md:29` left it at 3 passed, 0 failed (same temp copy).
- **Root cause (s107 minor 2):** `po-ship.md:27` says the probe is "plain `curl`, no header, no `.netrc`" — a user's `~/.curlrc` can still add a header or `--netrc`. `curl -q` disables curlrc **only as the first argument** (`man curl`, curl 8.22.0).
- No assumption of the story is false. Fix by taking the pushed SHA, as the story's note settles; the fixed-date route is not needed, so no technical choice and no ADR.

## Story
A resumed automatic ship merges the commit it already pushed, so a resume never costs a fix attempt. Criteria:
- `resumed_ship_merges_the_pushed_head` — push skipped → `<sha>` is taken from `origin/story/<id>`; `--match-head-commit` receives that full SHA, never a freshly rebuilt commit.
- `push_targets_only_the_story_ref` — the test of `tests/ship-through-pr.test.sh` that forbids pushing `Target branch` checks the refspec itself (`<sha>:refs/heads/story/<id>`) and fails if a `git push` line of `po-ship.md` names `Target branch`; removing the refspec or adding `Target branch` to the existing line makes it fail.
- `forge_read_pins_and_skips_curlrc` — the forge read uses `curl -q` wherever it says it carries no token, and a test fails if the `--hostname github.com` of `gh api` disappears.

## Diagnostic
Reproduction (no file created in the worktree):
1. M1: scratch repo, `git merge-tree --write-tree main story` then `commit-tree <tree> -p main` under two `GIT_COMMITTER_DATE` values → two SHAs. `po-ship.md:70-77` read in order: the only definition of `<sha>` is line 70; line 74's skip clause has no assignment; line 77 uses `<sha>`.
2. M2: temp copy, `sed` refspec → `<sha>:refs/heads/<Target branch>`, `bash tests/run.sh ship-through-pr.test.sh` → 5 passed.
3. Pin: temp copy, pin deleted, `grep -c "hostname github.com"` → 0, `forge-token-host.test.sh` → 3 passed.

Hypotheses (M1):
- H1 — `<sha>` is never rebound when the push is skipped. Refuted if any line between 70 and 77 assigns `<sha>` from the remote. Read 66-81: none does. **Kept.**
- H2 — the skip never happens, `--force-with-lease` re-pushes the new SHA so head and `<sha>` agree. Refuted by line 74 itself: "Skip the push when …" is explicit. **Discarded.**
- H3 — `--match-head-commit` tolerates a different SHA with the same tree. Refuted by `gh pr merge --help`: "Commit SHA that the pull request head must match to allow merge". **Discarded.**

## Current code
- `po-ship.md:22` — a pr already `MERGED` goes straight to cleanup; not affected.
- `po-ship.md:27` — forge probe to `https://<host>/api/v1/version`, "The probe carries no token: plain `curl`, no header, no `.netrc`. No call to an unrecognised host carries a token."
- `po-ship.md:29` — GitHub read: "`gh api`, pinned with `--hostname github.com`, … otherwise `curl` on `https://api.github.com` with `GH_TOKEN` or `GITHUB_TOKEN`" — this curl carries a token, so the `-q` rule of the criterion does not cover it.
- `po-ship.md:66` — pr mode: `git fetch origin`, `<base>` = `origin/<Target branch>`; that fetch also refreshes `origin/story/<id>`.
- `po-ship.md:69-71` — `<tree>` by `merge-tree`, `<sha>` by `commit-tree`, `story/<id>` never rewritten.
- `po-ship.md:74` — push `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`, the skip clause, then "Every push of the landing names `story/<id>` and nothing else; the only other branch this command ever sends is `framing/ship-confirmation` …".
- `po-ship.md:76` — human: stop with the PR URL; a later run on a moved base rebuilds and pushes again.
- `po-ship.md:77` — automatic: ci, gate again, `gh pr merge <url> --rebase --match-head-commit <sha>`, cleanup.
- `po-ship.md:84` — local proof uses `<sha>`; local mode never skips a push, so unaffected.
- `po-ship.md:86` — `git push origin --delete story/<id>`, the other `git push` line; it names `story/<id>` and no `Target branch`.
- `tests/ship-through-pr.test.sh:27-35` — `test_no_agent_pushes_target_branch`: AGENTS phrase, `--force-with-lease=story/<id>`, every `git push` line names `story/<id>`.
- `tests/forge-token-host.test.sh:6-40` — helpers `section_of`, `holds`, `forge_section`; three tests, none on `--hostname` or `-q`.

## Attachment points
- `po-ship.md:74` — the skip clause gains the rebinding of `<sha>` to the pushed head.
- `po-ship.md:77` — the merge line keeps `--match-head-commit <sha>` verbatim (`tests/ship-through-pr.test.sh:10` quotes it).
- `po-ship.md:27` — `curl` → `curl -q`, said to be the first argument.
- `tests/ship-through-pr.test.sh:27-35` — the existing test the criterion names.
- New `tests/ship-resumes-cleanly.test.sh` — per the convention one file per story; reuse the `section_of`/`holds` pattern of `forge-token-host.test.sh:6-8`.

## Verified interfaces
- `tests/lib.sh:11` `fail`, `:41` `require_file`, `:43` `contains` (exact, `grep -qF --`), `:6` `$METHOD`.
- `tests/run.sh:9-27` sources each file in its own process; `bash tests/run.sh <file>` runs one file.
- `git rev-parse origin/story/<id>` prints the full 40-hex SHA; `<ref>^{tree}` and `<ref>^@` give its tree and parents.
- `gh pr merge --match-head-commit SHA` exists (local `gh`).

## Traps
- Tests that quote `po-ship.md` and must stay green: `ship-through-pr.test.sh:8-12,29,43,59`, `ship-follows-forge.test.sh:31` (`'/api/v1/version'`, host phrases), `:39,68,118`, `forge-token-host.test.sh:14-15,31-33,38-39` (`'The probe carries no token'`, `'No call to an unrecognised host carries a token'` — keep both sentences), `ship.test.sh:43-44`, `review-tree-gate.test.sh:62`.
- `forge-token-host.test.sh:17-21` reads every `curl` line of the forge section for `GITLAB_TOKEN`/`GITEA_TOKEN`; the `-q` edit must not add them.
- The strengthened push test reads every `git push` line: the rewritten line 74 must not contain the words `Target branch`, or the test fails on correct text.
- `po-setup.md:81` has the same `--match-head-commit <sha>` shape for the framing landing; it is owned by s110, out of this story.
- `po-ship.md:46` (`framing/ship-confirmation`) builds with `commit-tree` too but skips by content ("already holds the same line") and never merges by SHA: not affected.
- `.claude/` and `.polype/` are installed copies: never edited.
- No migration, no dependency, no setting.

## Open questions
- Should the skip also require the head's message to be `<id>: <story title>`? Today nothing but `/po-ship` pushes `story/<id>`, so parent and tree are enough; the plan keeps the criterion's two conditions.

## Complexity
Story 2 → 2: one paragraph of `po-ship.md`, one word on another line, one test strengthened, one new test file of two tests.

## Split
—
