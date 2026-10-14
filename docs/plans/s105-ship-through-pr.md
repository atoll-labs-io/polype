---
validated: yes
---
# Plan — s105-ship-through-pr

[Story](../stories.md) · [Research](../research/s105-ship-through-pr.md)

Branch `story/s105-ship-through-pr`. Read `docs/research/s105-ship-through-pr.md` first; this plan builds on it without repeating it.

**Waiting for the owner.** The plan follows the recommendation of ADR-0081 (`proposed`). The owner has not yet decided how a story lands on each forge, nor how the ship builds the landing commit (ADR-0077). Until they do, the plan stays at `validated: no`. If the owner picks another option, `## The pivot` lists the tasks that change.

## Story
Each story reaches `Target branch` through a PR, as one commit `<id>: <story title>` with no merge commit, and no agent pushes `Target branch` (ADR-0080, refined by ADR-0081). Criteria:
- `ship_opens_a_pr_and_fast_forwards`.
- `one_commit_per_story`.
- `no_agent_pushes_target_branch`.
- `local_only_without_remote`.
- `ship_gate_unchanged`.

**Correction to the story.** On GitHub, « Rebase and merge » is not a fast-forward: PR #6 proves it, see the research. Under ADR-0081's recommendation:
- **GitHub:** the landed commit keeps the tree and the subject but not the SHA.
- **A true fast-forward** happens in local mode, and later on the forges that offer it.

## Tasks
1. [x] **`method/commands/po-ship.md`: land through a PR as one commit.**
   - *Frontmatter description:* replace "squash merge" with "one commit landed through a pull request".
   - *Step 2*, renamed `## Step 2 — Land as one commit, through a pull request`, in this order:
     - **Remote check.**
       - `Merge mode: pr` with no `origin` remote → stop: a repository without a remote uses `local`.
       - `Merge mode: local` with a remote → stop with "`Merge mode: local` is only for a repository without a remote (ADR-0080); set it to `pr`."
     - **Base.**
       - In pr mode: `git fetch origin`, then `origin/<Target branch>`.
       - In local mode: `<Target branch>`.
     - **Landing commit (ADR-0081)**, built beside the branch:
       - Run `git merge-tree --write-tree <base> story/<id>`. A non-zero exit stops the ship and hands it to a human, with the conflicting paths it printed.
       - Then run `git commit-tree <tree> -p <base> -m "<id>: <story title>"`, which gives `<sha>`.
       - Write the sentence "`story/<id>` is never rewritten: its tree stays the reviewed one, which `po-gate ship-allowed` and the resume of `/po-drive` keep reading."
     - **Pr mode.**
       - Push with `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`. Skip the push when `origin/story/<id>` already holds a commit with parent `<base>` and the same tree.
       - Write "Every push in this command names `story/<id>` and nothing else."
       - Reuse an open PR, or open one exactly as today (`:37`).
       - Under `human`, stop with "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup." Say that a later run rebuilds and repushes the landing commit when `Target branch` has moved, and never recreates the PR.
       - Under `automatic`: green `ci` when the project declares it, then `po-gate ship-allowed <id>` once more, then `gh pr merge <url> --rebase --match-head-commit <sha>`.
     - **Local mode.**
       - Under `human`: AskUserQuestion "Land <id> on <Target branch> as one commit?", answers Merge / Not now.
       - The root must be on `Target branch` and clean, as today. Then `git merge --ff-only <sha>`, and nothing is pushed.
   - *Step 3:*
     - Local proof: `git merge-base --is-ancestor <sha> <Target branch>`.
     - Keep "Do not test the story branch's own commits", with the reason "the landing commit is built beside them".
     - Remote deletion: `git push origin --delete story/<id>`.
   - *Keep word for word:*
     - Step 0.
     - `prints exactly \`MERGED\``.
     - `already prints \`MERGED\`, go straight to cleanup`.
     - `\`--force\` is not an option`.
     - `**One failure and the ship stops**`.
     - `the single end-to-end run of the whole cycle`.
   - *Tests that fail if wrong:* `ship_opens_a_pr_and_fast_forwards`, `no_agent_pushes_target_branch`, `local_only_without_remote`, `ship_gate_unchanged` (task 7). The existing `tests/ship.test.sh` must stay green.
2. [x] **`method/AGENTS.md`.**
   - Law 1 Ship row (`:39`) → "one commit on `Target branch`, landed through a pull request".
   - Law 6 (`:97`) → "Ship lands the story as one commit `<id>: <story title>` on `Target branch`, with no merge commit."
   - `## Merging` (`:115`), rewritten. It must contain:
     - "No agent pushes `Target branch`".
     - "one commit titled `<id>: <story title>`".
     - "no merge commit".
     - The fact that `local` is only for a repository without a remote.
     - ADR-0080 and ADR-0081.
   - Done means (`:131`) → "one commit landed through a pull request (or locally, without a remote)".
   - Keep `**Ships stay serial**` and the rest of `:53` untouched.
   - *Tests:* `one_commit_per_story`, `no_agent_pushes_target_branch`. `tests/fleet-wiring.test.sh` stays green.
3. [x] **`method/commands/po-drive.md`.**
   - `:135`: replace "the squash merge titled `<id>: <story title>`" with "the one commit titled `<id>: <story title>`, landed through its pull request".
   - Append to that paragraph: "On a resumed ship, `/po-ship` reads the pull request already open for `story/<id>` and never opens a second one."
   - Keep every phrase frozen by `tests/drive.test.sh:78-85` word for word, including the AskUserQuestion sentence that s102 owns.
   - *Test:* `one_commit_per_story`. `tests/drive.test.sh` stays green.
4. [x] **The descriptions of the ship.**
   - `method/commands/po-flow.md:82`: "the squash merge per …" → "the one-commit landing per …".
   - `method/commands/po-orchestrator.md:79`: "then the merge" → "then the one-commit landing through its pull request". Keep the AskUserQuestion / pull-request checkpoint sentence.
   - `method/commands/po-help.md:33`, in French: "verdict vérifié, contrôles lourds une fois, un commit par PR, nettoyage."
   - `method/agents/implementer.md:47`: "Ship squashes the branch anyway." → "Ship lands the branch as one commit anyway."
   - *Test:* `one_commit_per_story`, through its scan of the owned method files.
5. [x] **Setup and template: `local` only without a remote.**
   - `method/commands/po-setup.md:31`: say `pr` when the repository has a remote, and `local` only for a repository without a remote. Suggest it from `git remote`.
   - `method/templates/agents-local.md:42`, the Merge mode row: `pr` — a pull request to the target branch, landed as one commit · `local` — only for a repository without a remote: the commit lands on this machine and nothing is pushed.
   - No `#` in template lines (`tests/structure.test.sh`). The default `Merge mode: pr` (`:10`) stays.
   - *Test:* `local_only_without_remote`.
6. [x] **French docs.**
   - `docs/conception.md:33`: "Ship (un commit par PR, ADR-0080)".
   - `docs/conception.md:110`: ADR-0015 struck through as "remplacée par ADR-0080", with an ADR-0080 line added after ADR-0017.
   - `docs/migration.md:115`: "chaque story Polype arrive sur `Target branch` en un commit, par une PR (ADR-0080)".
   - `docs/migration.md:51`: also cite `docs/decisions/ADR-0080-…md`.
   - Keep the `:38` row as it is: it is history, and `tests/migration-doc.test.sh:33-34` freezes it.
   - *Visual check:* reread both paragraphs. `tests/migration-doc.test.sh` stays green.
7. [x] **Tests.**
   - `tests/ship.test.sh`: delete `test_ship_always_squashes_with_the_story_subject` (`:16-21`). The clause it checks is the one this story replaces. Say so in the commit message.
   - New file `tests/ship-through-pr.test.sh` with five functions named after the criteria (see the test strategy).
   - Then run the focused files, followed by the full suite once through `po-run`.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `method/hooks/po-gate.sh`: its detection of a shipped story assumes no squash.
  - `method/commands/po-status.md`: it already shows an open PR as "waiting for merge" (`:31`).
  - `.claude/`, `.polype/`, `README.md`.
  - `docs/parite-killer-saas.md`, `docs/stories.md`.
  - `docs/decisions/ADR-0015-…md`, `docs/decisions/ADR-0080-…md`.
  - Every test file except `tests/ship.test.sh` and `tests/ship-through-pr.test.sh`.
- `docs/decisions/ADR-0081-…md` stays `status: proposed`. Only the owner accepts it.
- No method file holds a `git push` whose refspec names `Target branch`.
- No s102 material:
  - No forge detection.
  - No `(forge)` or `(chosen)` suffix.
  - No change to `Ship confirmation` defaults.
  - The sentence "`Ship confirmation: human` means one AskUserQuestion per merge" stays as it is.
- No s106 material: no framing command is changed.
- No new setting.
- No GitLab or Forgejo wiring in `/po-ship`. It still drives `gh` only.

## The pivot
**The landing commit is built beside `story/<id>` (`merge-tree` then `commit-tree`), and on GitHub it is merged with `gh pr merge --rebase --match-head-commit <sha>`.** Everything hangs on ADR-0081.
- **The owner picks another option for question 1:**
  - *Option 2 (rebase or squash everywhere):* only the wording of tasks 1, 2 and 6 changes. "Fast-forward" disappears from the local-mode text.
  - *Option 3 (push the PR head onto `Target branch`):* it contradicts the criterion `no_agent_pushes_target_branch` and ADR-0080. Stop: the story and ADR-0080 must be rewritten before any plan.
- **The owner picks another option for question 2:**
  - *Option 2 (squash and rebase in place):* the gate refuses any branch rebased onto a moved `Target branch`. It would need a change in `po-gate.sh`, which `ship_gate_unchanged` forbids. That is a story conflict, so stop.
  - *Option 3 (temporary worktree):* only task 1 changes.
- **Check `merge-tree` against a squash merge.** On a clean merge, `merge-tree` must give the same tree as the old `git merge --squash`. Compare in a throwaway repo under the temp dir: same base, one moved target, two story commits. The research did this once.
- **Check `--match-head-commit`.** It must refuse when the PR head is not `<sha>`. Read `gh pr merge --help`. Do not merge a real PR to prove it.

## Files touched
- `method/commands/po-ship.md`
- `method/AGENTS.md`
- `method/commands/po-drive.md`
- `method/commands/po-flow.md`
- `method/commands/po-orchestrator.md`
- `method/commands/po-help.md`
- `method/agents/implementer.md`
- `method/commands/po-setup.md`
- `method/templates/agents-local.md`
- `docs/conception.md`
- `docs/migration.md`
- `tests/ship.test.sh`
- `tests/ship-through-pr.test.sh`
- Plus, from planning: `docs/research/s105-ship-through-pr.md`, this plan, and `docs/decisions/ADR-0081-…md`.

## Test strategy
Five text tests, the repository's layer for method files, out of a budget of 25. One test is removed (`ship.test.sh:16-21`). Each test quotes the exact phrases the tasks write, and each one bites when its rule is deleted.

Automated tests, in `tests/ship-through-pr.test.sh`:
- `test_ship_opens_a_pr_and_fast_forwards`
  - `po-ship.md` contains:
    - `git merge-tree --write-tree <base> story/<id>`.
    - `git commit-tree <tree> -p <base> -m "<id>: <story title>"`.
    - `gh pr merge <url> --rebase --match-head-commit <sha>`.
    - `git merge --ff-only <sha>`.
    - `Pull request ready: <url>. Land it with Rebase and merge`.
  - `po-ship.md` holds no `--squash`.
- `test_one_commit_per_story`
  - `method/AGENTS.md` contains "one commit titled `<id>: <story title>`" and "no merge commit".
  - None of these files contains `squash`, case-insensitive: `method/AGENTS.md`, `po-ship.md`, `po-drive.md`, `po-flow.md`, `po-orchestrator.md`, `po-help.md`, `implementer.md`, `templates/agents-local.md`.
- `test_no_agent_pushes_target_branch`
  - `method/AGENTS.md` contains "No agent pushes `Target branch`".
  - Every line of `po-ship.md` that holds `git push` also holds `story/<id>`.
  - `po-ship.md` contains `--force-with-lease=story/<id>`.
- `test_local_only_without_remote`
  - The Merge mode row of the template contains "only for a repository without a remote".
  - So does `po-setup.md`.
  - `po-ship.md` contains "`Merge mode: local` is only for a repository without a remote".
- `test_ship_gate_unchanged`
  - In `## Step 2` of `po-ship.md`, the line holding `po-gate ship-allowed <id>` comes before the line holding `gh pr merge`.
  - `po-ship.md` contains "`story/<id>` is never rewritten".
  - The frontmatter of ADR-0015 reads `status: superseded` and `superseded-by: [ADR-0080]`.

Kept green, not edited:
- `tests/ship.test.sh` (other functions).
- `tests/drive.test.sh`.
- `tests/fleet-wiring.test.sh`.
- `tests/migration-doc.test.sh`.
- `tests/structure.test.sh`.
- `tests/lint.test.sh`.
- `tests/overlap.test.sh`. Write in your own words: no 8-word run from Killer SaaS.

Runs:
- Focused: `bash tests/run.sh ship.test.sh ship-through-pr.test.sh drive.test.sh fleet-wiring.test.sh migration-doc.test.sh structure.test.sh`.
- Full suite: once, through `po-run --story s105-ship-through-pr --label test -- 'bash tests/run.sh'`.

Visual checks: tasks 4 (the `po-help.md` sentence) and 6 (the docs paragraphs), reread.

## Done when
- One commit on `Target branch`, carrying a description of what, why and how to check.
- The full suite is green.
- The review has no open critical finding.
- ADR-0081 has been accepted by the owner before execution.
