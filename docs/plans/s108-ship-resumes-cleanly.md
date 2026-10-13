---
validated: yes
---
# Plan — s108-ship-resumes-cleanly

Branch `story/s108-ship-resumes-cleanly`. Read `docs/research/s108-ship-resumes-cleanly.md` first; this plan builds on it without repeating it. Defect story (`Corrige` line): full track, root causes in the research's `## Structuring facts`.

## Story
A resumed automatic ship merges the commit it already pushed, so a resume never costs a fix attempt; and the three tests left soft by the s105 and s107 reviews bite.
- `resumed_ship_merges_the_pushed_head` — push skipped → `<sha>` taken from `origin/story/<id>`; `--match-head-commit` receives that full SHA, never a rebuilt commit.
- `push_targets_only_the_story_ref` — `test_no_agent_pushes_target_branch` checks the refspec `<sha>:refs/heads/story/<id>` and fails when a `git push` line of `po-ship.md` names `Target branch`.
- `forge_read_pins_and_skips_curlrc` — `curl -q` wherever the forge read says it carries no token; a test fails if `--hostname github.com` leaves `gh api`.

## Tasks
1. [x] **Fix the cause, `method/commands/po-ship.md:74`.** Keep the push sentence (`git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`) byte for byte. Rewrite the skip sentence so it reads on the head: "Skip the push when the head of `origin/story/<id>` already has `<base>` as its only parent and `<tree>` as its tree." Then add, on the same bullet, a sentence carrying these exact phrases: "When the push is skipped, `<sha>` becomes that head: `git rev-parse origin/story/<id>`, its full SHA" and "never the commit `git commit-tree` printed on this run, whose new committer date gives it another SHA". Keep "Every push of the landing names `story/<id>` and nothing else" and the `framing/ship-confirmation` sentence. The bullet must not contain the words `Target branch` (the task 3 test reads every `git push` line). Test able to fail: `test_resumed_ship_merges_the_pushed_head` (task 4).
2. [x] **`po-ship.md:77`, the automatic merge.** Keep `gh pr merge <url> --rebase --match-head-commit <sha>` verbatim (quoted by `tests/ship-through-pr.test.sh:10`); add before it on that line "`<sha>` being the pushed head when the push was skipped". Test able to fail: `test_resumed_ship_merges_the_pushed_head` checks the rebinding sentence sits above the `gh pr merge` line of Step 2.
3. [x] **Strengthen `test_no_agent_pushes_target_branch` in `tests/ship-through-pr.test.sh:27-35`** (the story changes the clause it checks; say so in the commit). Keep its two `contains` and its stray check, then add: the line holding `--force-with-lease=story/<id>` holds `<sha>:refs/heads/story/<id>`; no `git push` line of `po-ship.md` contains `Target branch`; every `refs/heads/…` token on a `git push` line (`grep -o 'refs/heads/[^ `]*'`) is exactly `refs/heads/story/<id>`, so an extra `<sha>:refs/heads/main` refspec fails too. Fails when: the refspec is rewritten to `<sha>:refs/heads/<Target branch>` (the s105 bite), the refspec is removed, or `<Target branch>` is appended to line 74.
4. [x] **New `tests/ship-resumes-cleanly.test.sh`**, header comment `# s108 — a resumed ship merges the head it already pushed; the forge read pins its host and skips curlrc.` Define `section_of`/`holds` as `tests/forge-token-host.test.sh:6-8` does. `test_resumed_ship_merges_the_pushed_head`: on the Step 2 text (`awk` between `## Step 2` and `## Step 3`, as `ship-through-pr.test.sh:48`), holds `git rev-parse origin/story/<id>` and the exact phrase of task 1 that starts "When the push is skipped", the line holding that phrase also holds `Skip the push`, its line number is lower than that of the first `gh pr merge` line, and that `gh pr merge` line still holds `--match-head-commit <sha>`. Fails when task 1's sentence is deleted, moved off the skip bullet, or placed after the merge.
5. [x] **`po-ship.md:27`, the probe.** Replace "plain `curl`, no header, no `.netrc`" with "plain `curl -q`, `-q` first so `~/.curlrc` is never read, no header, no `.netrc`". Keep "The probe carries no token" and "No call to an unrecognised host carries a token" verbatim (`forge-token-host.test.sh:38-39`). Leave line 29 alone: its `curl` sends a token to `https://api.github.com`, outside the criterion. Test able to fail: task 6.
6. [x] **In `tests/ship-resumes-cleanly.test.sh`, `test_forge_read_pins_and_skips_curlrc`**: on the forge section (`## The forge's review rule`), holds `` `gh api`, pinned with `--hostname github.com` ``; every line holding both `curl` and `carries no token` holds `` `curl -q` `` and no `` plain `curl`, `` remains; at least one such line exists. Fails when the pin is removed from `gh api` (the s107 bite) or `-q` is dropped. Then run `bash tests/run.sh ship-resumes-cleanly.test.sh ship-through-pr.test.sh forge-token-host.test.sh ship-follows-forge.test.sh ship.test.sh`, then the full suite once through `po-run --story s108-ship-resumes-cleanly --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Only these paths change outside `docs/`: `method/commands/po-ship.md`, `tests/ship-through-pr.test.sh`, `tests/ship-resumes-cleanly.test.sh`. `tests/forge-token-host.test.sh` stays with an empty diff (owned, but nothing to change there).
- `po-ship.md` changes only on lines 27, 74 and 77 (as numbered on `main`); `## The forge's review rule` keeps every other sentence, Steps 0, 1 and 3 have an empty diff.
- `method/commands/po-setup.md` has an empty diff (its `:81` twin belongs to s110), as do `method/AGENTS.md`, `method/commands/po-drive.md`, `.claude/`, `.polype/`, `docs/stories.md`, `docs/decisions/`.
- No fixed author or committer date for `commit-tree` appears in `po-ship.md` (`GIT_COMMITTER_DATE`, `GIT_AUTHOR_DATE` absent): the rejected route.
- Every existing test keeps passing; only `test_no_agent_pushes_target_branch` changes, and only by added assertions.
- No real `git push`, no `gh` call against a forge.

## The pivot
`<sha>` is rebound to the pushed head rather than made reproducible with fixed dates — the route the story's note retains, which leaves the first-pass commit unchanged. Ways it could be wrong:
- The skip condition reads a stale `origin/story/<id>`: it is only fresh because pr mode runs `git fetch origin` at `po-ship.md:66` before the landing commit is built. Check that line stays and still precedes line 74.
- A head that passes the parent-and-tree test but is not a landing commit (message other than `<id>: <story title>`). Today nothing but `/po-ship` pushes `story/<id>` (research, `## Open questions`); compare `git grep 'git push' method/` before trusting it.
- The test of task 3 matching `Target branch` on correct prose: if task 1 writes those words on line 74, the test fails on a right text. Compare the final bullet against the task 1 interdict.

## Files touched
- `method/commands/po-ship.md`
- `tests/ship-through-pr.test.sh`
- `tests/ship-resumes-cleanly.test.sh` (new)
- `docs/research/s108-ship-resumes-cleanly.md`, `docs/plans/s108-ship-resumes-cleanly.md`, `docs/verif/s108-ship-resumes-cleanly.md`

## Test strategy
Method files are prose; their layer is the grep test on the file under test (`AGENTS.md`, Conventions).
Automated, 2 new tests + 1 strengthened, budget 25:
- `test_resumed_ship_merges_the_pushed_head` (new file) — the rebinding rule.
- `test_no_agent_pushes_target_branch` (existing, `ship-through-pr.test.sh`) — carries `push_targets_only_the_story_ref`, as the criterion names that test; no duplicate under the criterion's name, which would test the same rule twice.
- `test_forge_read_pins_and_skips_curlrc` (new file) — pin and `-q`.
Bite targets for the reviewer: delete the task 1 sentence; restore s105's refspec mutation; append `<sha>:refs/heads/main` to line 74; drop `--hostname github.com`; drop `-q`. Each must turn exactly its test red.
Visual checks: none (`Surface: —`, `QA stage: —`).

## Done when
One commit `s108-ship-resumes-cleanly: Un ship automatique repris aboutit` landed through a pull request; the full suite green through `po-run`; a review with no open critical; the three bite targets above red under the reviewer's mutation.
