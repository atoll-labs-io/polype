---
description: Takes a story with a passing review to Target branch — verdict gate, the one run of the expensive checks, one commit landed through a pull request, then cleanup once the merge is proven
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Bash
  - AskUserQuestion
---
# /po-ship

Reads settings: `Merge mode`, `Target branch`, `Ship confirmation`, `Worktree root`, `Full suite`, `E2E stage`, `E2E scope`, `E2E browsers`, `Build stage`

Story: $ARGUMENTS

Match the id in `docs/stories.md`. The worktree `<Worktree root><id>` must exist on `story/<id>` (`git -C <path> rev-parse --abbrev-ref HEAD`); otherwise stop without touching any branch. Run commands with `cd <path> &&` or `git -C <path>` unless a step says to use the repository root.

## Step 0 — The verdict, before anything else
`po-gate ship-allowed <id>` from the worktree. Without the hook: the **last** line starting with `Ship allowed:` in `docs/reviews/<id>.md` (a leading `- ` or `* ` allowed) must read `Ship allowed: yes`, and the hash on the last `Reviewed tree:` line between that verdict and the verdict line before it (same leading `- ` or `* `; a full 40-hex hash alone, or followed by a blank and a remark) must pass `git diff --quiet <Reviewed tree> HEAD -- . ':(exclude)docs'` run from the worktree. No review, no usable `Reviewed tree:`, a diff that fails, or any other answer → stop with "Cannot ship <id>: the review is missing or blocks it. Run /po-review <id>."

Then read the settings above and the project commands from `AGENTS.local.md`; stop if the file or a setting is missing. Every branch below depends on them.

**Coming back after a pull request was merged by hand?** With `Merge mode: pr`, if `gh pr view story/<id> --json state --jq .state` already prints `MERGED`, go straight to cleanup.

## Step 1 — The expensive checks, once
Commit `docs/reviews/<id>.md` on `story/<id>` if it is not committed yet, so the story carries its review. Then, using the project commands verbatim:
- **Unit suite** — with `Full suite: execute-end` the implementer already ran it, and a passing `po-gate verif-current <id>` is the proof; a failing proof means `<Test>` runs now. With `ship` or `both`, `<Test>` always runs now.
- **End to end** — when `E2E stage` is `ship`, this is the single end-to-end run of the whole cycle: `<E2E>`, limited to `E2E scope`, across every browser the project configures.
- **Build** — when `Build stage` is `ship`, `<Build>` runs. When it is `ship-if-route`, `<Build>` runs only for a diff that touches routing, a manifest or file-based routes; for any other diff, write that the build was skipped and why.
- **`ci`** (only meaningful with `Merge mode: pr`) — do not run the check here; wait for `gh pr checks` to be green on the pull request.

A command set to `—` is reported as absent, never replaced. **One failure and the ship stops**: the story goes back to `/po-execute <id>` as a fix run.

## Step 2 — Land as one commit, through a pull request
Message and title: `<id>: <story title>`.

**Remote check.** `Merge mode: pr` with no `origin` remote → stop: a repository without a remote uses `local`. `Merge mode: local` with a remote → stop with "`Merge mode: local` is only for a repository without a remote (ADR-0080); set it to `pr`."

**Base.** In pr mode, `git fetch origin`, then `<base>` is `origin/<Target branch>`. In local mode, `<base>` is `<Target branch>`.

**Landing commit (ADR-0081)**, built beside the branch, from the worktree:
- `git merge-tree --write-tree <base> story/<id>` prints `<tree>`. A non-zero exit means a conflict: stop the ship and hand it to a human, listing the conflicting paths it printed.
- `git commit-tree <tree> -p <base> -m "<id>: <story title>"` prints `<sha>`, one commit on top of `<base>`.
- `story/<id>` is never rewritten: its tree stays the reviewed one, which `po-gate ship-allowed` and the resume of `/po-drive` keep reading.

**`Merge mode: pr`**
- Push the landing commit alone to the story branch on the remote: `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`. Skip the push when `origin/story/<id>` already holds a commit whose parent is `<base>` and whose tree is `<tree>`. Every push in this command names `story/<id>` and nothing else.
- A pull request for `story/<id>` already open → reuse it. None → open one to `Target branch`, titled `<id>: <story title>`, with what changed, why, how to test, and the review verdict (max severity and a summary of the findings).
- `Ship confirmation: human` → stop here. The pull request is the human's decision point: "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup." When `Target branch` has moved before that, a later run rebuilds the landing commit on the new base and pushes it again; it never opens a second pull request.
- `automatic` → wait for `ci` to be green when the project declares it, run `po-gate ship-allowed <id>` once more, then `gh pr merge <url> --rebase --match-head-commit <sha>`, then cleanup.

**`Merge mode: local`**
- `Ship confirmation: human` → AskUserQuestion "Land <id> on <Target branch> as one commit?", answers Merge / Not now. Continue on Merge only.
- In the repository root: it must be on `Target branch` with no staged or modified tracked file (`git status --porcelain --untracked-files=no` prints nothing); otherwise stop and describe what you found. Then `git merge --ff-only <sha>`. Nothing is pushed.

## Step 3 — Cleanup, only after proof
1. Proof. `pr`: `gh pr view story/<id> --json state --jq .state` prints exactly `MERGED` — open, closed or "merging" is not proof, and cleanup does not happen. `local`: the landing commit is an ancestor of `Target branch` (`git merge-base --is-ancestor <sha> <Target branch>`). Do not test the story branch's own commits: the landing commit is built beside them, so they are never ancestors.
2. The worktree has no uncommitted change → `git worktree remove <path>`. If it has changes, stop; `--force` is not an option.
3. Delete `story/<id>` locally with `git branch -D` (git considers the branch unmerged, since its own commits never land; step 1 is what makes this safe) and, if it was pushed, on the remote with `git push origin --delete story/<id>`.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · the exact step that stopped, what is missing, and the command to run next.
