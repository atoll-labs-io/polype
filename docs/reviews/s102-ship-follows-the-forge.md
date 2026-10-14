# Review — s102-ship-follows-the-forge

[Story](../stories.md) · [Plan](../plans/s102-ship-follows-the-forge.md) · [Verification](../verif/s102-ship-follows-the-forge.md)

Reviewed tree: 1a5f711b2f85354c6e87ac903d6eb3c0279a45e8
Fix loop: 0
Review status: complete
Lenses run: Security (content: `po-ship.md` `## The forge's review rule` builds an HTTP call to a host taken from `git remote get-url origin` and sends an environment token to it)

## What I relied on
- **Scope:** every path in `git diff --name-only main...story/s102-ship-follows-the-forge` is covered by the story's `Owns` line or is pipeline evidence: the research, the plan, the record, and `docs/decisions/ADR-0079-…`. ADR-0079 is added (status `A`) and the plan names it. Running `git worktree list` shows one other story branch, `story/reuse-ladder`. It is not merged into `main`, but its diff against `main` is empty and `docs/stories.md` has no such story, so nothing overlaps.
- **Step 1:** `po-gate verif-current` exited 0 (`Verification mode: record`). Its `Tree:` (`269f510…`) and the run tree (`947215f…`) both match HEAD outside `docs/`. The single run of `bash tests/run.sh` exited 0, so I did not rerun the full suite. The project has no type check, end-to-end run or build (`Typecheck: —`, `E2E: —`, `Build: —`). The story does not go to QA (`QA stage: —`).
- **Step 4, floor:** `po-gate floor-guard s102-ship-follows-the-forge main` exited 0. The only existing test that changed is `tests/drive.test.sh:85`, and both the plan and the story notes justify it.
- **Steps 2 and 3:** every referenced section exists:
  - `## The forge's review rule` sits between Step 0 and Step 1, after the gate.
  - The new resume rows in `po-drive.md` sit above the ship row.
  - The frozen phrases are still there: Ships stay serial, Pull request ready, `git push` lines naming `story/<id>`, no `squash`.
  - `po-setup` Step 2 still has exactly five numbered lines.
  
  All seven plan tasks are present and every acceptance criterion maps to text. The test file has 8 tests, within `Test budget: 25`.

## Findings

1. **major — Security: an environment token is sent to whatever host `origin` names.** In `method/commands/po-ship.md`, `## The forge's review rule`, under "How it is read", the fallback is `curl on the forge's API with the token the environment already gives that CLI — GH_TOKEN or GITHUB_TOKEN, GITLAB_TOKEN, GITEA_TOKEN`.
   - Any host containing `gitlab` gets `GITLAB_TOKEN`.
   - Any host whose `/api/v1/version` returns JSON with a `version` field (trivial to fake) gets `GITEA_TOKEN`.
   - Nothing ties the token to the host it was issued for (for example `GITLAB_HOST`, or the CLI's per-host config).
   
   A repository cloned from a third-party GitLab or Forgejo leaks the user's token for another instance to that operator during `/po-setup` or `/po-ship`. GitHub is safe: its token only goes to github.com.
   
   **Fix:** send an env token only when its declared host matches `origin`'s host; otherwise treat the forge as unreadable.
   
   It is contained (a narrow precondition, and glab's own handling of the env token is similar), so it is not critical.

2. **major — Bite: the waiting row in `po-drive.md` has no test for its "effective `human`" condition.** I removed `, and an effective \`Ship confirmation\` of \`human\` (the line, or a collaborative forge as \`/po-ship\` reads it)` from the `OPEN` row of `## Resuming`. I then ran `ship-follows-forge`, `drive`, `resume` and `qa-fleet`: 33 passed, 0 failed. I restored the file and `git diff --exit-code` was clean.
   
   Without that condition, a lane under effective `automatic` whose PR is open waits forever for a human. This is exactly the first way the plan's own `## The pivot` section says it could be wrong. `test_pr_wait_does_not_block_the_fleet` checks only where the row sits and the phrase "a human merge — the lane waits".

3. **minor — Bite: Step 2 of `po-ship.md` has no test tying it to the effective value.** I removed three things:
   - "Below, `Ship confirmation` is always the effective value that section settled."
   - the `, the effective value` clause on the pr `human` branch
   - the same clause on the local `human` branch, and on the `automatic` branch
   
   I then ran `ship-follows-forge`, `ship`, `ship-through-pr` and `drive`: 31 passed, 0 failed. I restored the file and `git diff --exit-code` was clean. The impact is small because the forge section still says it "settles the **effective** `Ship confirmation`" and that "Step 2 already acts on the effective value", but the link from Step 2 itself has no test.

4. **minor — `po-setup.md` reads the forge before `Target branch` is known.** The new Step 1 bullet reads the forge "exactly as `/po-ship` reads it". That includes the protection of `Target branch` and `CODEOWNERS` from `origin/<Target branch>`, but `Target branch` is only answered in question 1 of Step 2. The text does not say which branch to use: the default branch found in Step 1, or the answer to question 1. Say which one, or read the protection after question 1.

5. **minor — Two sentences in `po-drive.md` pull against each other.** `## Ships, one at a time` keeps the frozen "you ship one story, prove it, then ship the next, in the order their reviews passed", while the new paragraph lets the fleet open the next PR at once and land stories "in the order a person merges them". The acceptance criterion requires this; a short clause saying "prove it" means proving the PR is open under effective `human` would remove the ambiguity. `method/AGENTS.md`'s "in the order the reviews passed" next to the new paragraph has the same issue.

## Not verified
- **No forge API was called** (plan run interdicts, and the review limits). I did not observe any of these against a live forge: the GitHub `collaborators`, `protection` and `rules/branches` reads; the 403 "Upgrade to GitHub Pro" classification; `gh pr create --draft`. A person should run `/po-ship` once on a solo private GitHub repository and once on a repository with a second writer, and check the effective value the finish reports.
- **GitLab and Forgejo/Gitea calls** (`members/all`, `approval_rules`, `collaborators/<login>/permission`, `branch_protections`, `/api/v1/version`) come from documentation only; ADR-0079 says so too. In particular, GitLab Free may answer `approval_rules` with something other than a 404 or an empty list. That would mark every GitLab Free project unreadable, the same trap the plan avoided for GitHub. To cover it, probe a GitLab Free project and a Forgejo instance.
- **The `framing/ship-confirmation` rewrite** (blob, temporary index, `commit-tree`, push with lease, draft PR, skip when unchanged) has never been executed.
- **Two PRs open at once under `human` on a forge with true fast-forward** (GitLab `ff`, Forgejo; ADR-0081): after the first merges, the second can no longer fast-forward, and the waiting row forbids the fleet from rerunning the ship. This is not reachable today because `/po-ship` opens PRs on GitHub only, but no story covers it.
- **`/po-drive status` and resume now need a forge read** to decide whether the effective value is `human`. I did not check that this fits the command's time or network budget.

Max severity: major
Ship allowed: yes
