# Research — s105-ship-through-pr

## Structuring facts
- **False assumption: on GitHub, « Rebase and merge » is not a fast-forward.** PR #6 (`gh pr view 6`): head `33e887b…`, landed commit `a380428…`, same tree `f8e542d…`, and `git merge-base --is-ancestor 33e887b main` exits 1. GitHub recreates every commit with new committer data and a new SHA. ADR-0080 (`docs/decisions/ADR-0080-…md:22`) and criterion `ship_opens_a_pr_and_fast_forwards` both equate the two. How to land "in fast-forward" per forge is a technology choice: ADR-0081 sets out the options, ranked, with status `proposed`. The owner decides (ADR-0077).
- **A trap the story does not name:** if `/po-ship` squashed and rebased `story/<id>` in place, `po-gate ship-allowed` would refuse the branch as soon as `Target branch` has moved. The gate compares `Reviewed tree:` with `HEAD` outside `docs/` (`method/hooks/po-gate.sh:51,62`). The drive's resume table would then send the lane back to review (`method/commands/po-drive.md:61`) rather than to the ship. A resumed human ship would always hit this.
- `po-gate.sh` has no notion of a shipped story: only its header comment mentions a squash (`method/hooks/po-gate.sh:17-18`). Per the story's note, it stays unchanged.
- Half of `ship_gate_unchanged` is already on disk: ADR-0015 is `status: superseded`, `superseded-by: [ADR-0080]` (`docs/decisions/ADR-0015-…md:4,9`, commit a380428).
- `/po-ship` drives only GitHub today (`gh pr view`, `gh pr merge`, `method/commands/po-ship.md:22,39,46`). No other forge is wired anywhere in the method.

## Story
s105 (complexity 3, no Surface, no dependency). Every story lands on `Target branch` through a PR, as one commit `<id>: <title>` with no merge commit, and no agent pushes `Target branch` (ADR-0080). Criteria: `ship_opens_a_pr_and_fast_forwards`, `one_commit_per_story`, `no_agent_pushes_target_branch`, `local_only_without_remote`, `ship_gate_unchanged`.

## Current code
- `method/commands/po-ship.md`
  - Description and Step 2 say squash (`:2`, `:33`).
  - In pr mode, Step 2 pushes the branch and opens or reuses a PR (`:37`). Under `human` it stops at the PR (`:38`), under `automatic` it runs `gh pr merge <url> --squash --subject …` (`:39`).
  - In local mode, Step 2 runs `git merge --squash story/<id>` from the repository root on `Target branch`, then pushes if there is a remote (`:43`). So an agent pushes `Target branch` today.
  - Resume: `MERGED` → cleanup (`:22`).
  - Proof of merge: `MERGED` in pr mode, `merge-base --is-ancestor <squash hash>` in local mode (`:46`). The local branch is deleted with `-D` (`:48`).
- `method/AGENTS.md`
  - Ship row: "one squash commit on `Target branch`" (`:39`).
  - Law 6: "Ship squashes everything into one commit" (`:97`).
  - Merging: "Either way the merge is a squash titled …" (`:115`).
  - Done means: "one squash commit (or one pull request)" (`:131`).
  - Ships stay serial (`:53`, frozen by `tests/fleet-wiring.test.sh:36`).
- `method/commands/po-drive.md`
  - Shipped = a commit whose subject starts with `<id>:` on `Target branch` (`:31`, also the done row `:63`).
  - Resume rows: ship refused (`:61`), ship (`:62`).
  - Ship section: "the squash merge titled …" (`:135`). The section also holds the phrases frozen by `tests/drive.test.sh:78-85`, including "requires the repository root clean and on `Target branch`" and "`Ship confirmation: human` means one AskUserQuestion per merge".
- `method/commands/po-orchestrator.md:79` describes Stage 8: AskUserQuestion before a local merge, the PR itself in pr mode. No squash wording.
- `method/commands/po-flow.md:82`: "the squash merge per `Merge mode` …".
- `method/commands/po-help.md:33` (French): "verdict vérifié, contrôles lourds une fois, squash, nettoyage."
- `method/commands/po-status.md:31` already counts as shipped any `<id>:` commit on `Target branch` or `origin/<Target branch>`, and shows an open PR as "waiting for merge". Nothing in it depends on a squash.
- `method/commands/po-setup.md:31`: "How stories land: `Merge mode` `pr` or `local`". Nothing ties `local` to the absence of a remote.
- `method/templates/agents-local.md`: default `Merge mode: pr` (`:10`), and a row describing `local` as "squash merge on this machine" (`:42`).
- `method/agents/implementer.md:47`: "Ship squashes the branch anyway."
- `docs/conception.md`: diagram "Ship (squash dans la branche cible, ADR-0015)" (`:33`), and ADR-0015 listed as current (`:110`).
- `docs/migration.md`: table row on ADR-0015 (`:38`, frozen by `tests/migration-doc.test.sh:33-34`), ADR-0015 cited (`:51`), and "chaque story Polype squashe directement" (`:115`).

## Attachment points
- `po-ship.md` Step 2 and Step 3 are the only places that land and prove a merge. Everything else describes them: AGENTS Law 1, Law 6, Merging and Done means; drive `:135`; flow `:82`; help `:33`; implementer `:47`; template `:42`; setup `:31`; conception; migration.
- Resume: the drive row `:62` sends the lane back to `/po-ship`. The ship's own check at `:22`, plus PR reuse at `:37`, is where it reads an existing PR instead of recreating it.

## Verified interfaces
- `git merge-tree --write-tree <base> story/<id>` (git 2.56.0 here, needs ≥ 2.38): prints the merged tree and exits 1 on conflict. Then `git commit-tree <tree> -p <base> -m "<id>: <title>"` gives one commit on top of `<base>`, while `story/<id>` keeps its reviewed tree. `git merge --ff-only <sha>` advances the target. Checked in a throwaway repo under `/tmp`: one commit, parent = target tip, files from both sides.
- `gh` 2.102.0: `gh pr merge` has `--rebase`, `--squash` and `--match-head-commit SHA`. The last one refuses the merge if the PR head is not the gated commit. There is no fast-forward flag: GitHub offers merge, squash and rebase only.
- `po-gate ship-allowed` (`method/hooks/po-gate.sh:54-63`) needs the review's last `Ship allowed: yes`, plus `Reviewed tree` = `HEAD` outside `docs/`. The tree is compared, not the commit.
- Remote: `origin` = `git@github.com:atoll-io/polype.git`.

## Traps
- **Frozen tests not owned by the story.** Keep their phrases word for word:
  - `tests/drive.test.sh:78-85`: the `Ships, one at a time` section, including "requires the repository root clean and on `Target branch`" and "`Ship confirmation: human` means one AskUserQuestion per merge". s102 changes the latter, not s105.
  - `tests/migration-doc.test.sh:33-34`: 'squash direct sur `Target branch`' and '(ADR-0015)'.
  - `tests/fleet-wiring.test.sh:36`: '**Ships stay serial**'.
- **`tests/ship.test.sh`, owned by the story.**
  - `test_ship_always_squashes_with_the_story_subject` (`:16-21`) checks the clause this story changes. It goes away, and the plan says so.
  - `:13`, `:25-27` and `:40` are kept: the gate phrase, cleanup on proof, "Do not test the story branch's own commits" (still true, since the local branch never becomes an ancestor), and "already prints `MERGED`, go straight to cleanup".
- **Not owned, still saying squash. Left as is and reported:**
  - `README.md:33`.
  - `docs/parite-killer-saas.md:62,63,86,113`.
  - `.claude/` and `.polype/`, installed copies, never edited.
- **Rewriting `story/<id>` in place breaks resume.** See the second structuring fact: the landing commit has to be built beside the branch, not in place of it.
- **Conflicts.** A conflict with a `Target branch` that has moved used to surface in `git merge --squash`. It now surfaces in `merge-tree` (exit 1, conflicting paths listed). The implementer cannot rebase (`po-bounds`), so a conflict stops the ship and goes to a human.
- **s102 and s106 come after s105** (both depend on it). Leave them the forge detection, the `(forge)`/`(chosen)` suffix and the PR wait that does not block the fleet. Framing commands commit locally without pushing (`grep push` in `method/commands`: only `po-ship.md`). So writing "no agent pushes `Target branch`" breaks nothing before s106.
- No migration, no new setting: `structure.test.sh` stays satisfied.

## Open questions
1. Per forge, how to land "in fast-forward" (ADR-0081, proposed; owner decides): accept the rewrite done by GitHub's rebase, push the PR head onto `Target` (which breaks ADR-0080's "no agent pushes"), or use each forge's native mode (GitLab `ff`, Forgejo/Gitea `fast-forward-only`, the latter not verified on a live instance).
2. Does a human merging on GitHub use « Rebase and merge » or « Squash and merge »? Both keep one commit and the tree; only the committer data and the SHA change.
3. Should GitLab and Forgejo be wired by s105 or by a later story? Today the ship knows only `gh`. The plan stays on GitHub.

## Complexity
Story: 3. After reading: 3. The changes are mostly texts across about twelve files. The landing mechanism has one real trap (resume against the gate), but no new code: the hooks do not change.

## Split
—
