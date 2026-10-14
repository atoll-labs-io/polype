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
`po-gate ship-allowed <id>` from the worktree. Without the hook: the **last** line starting with `Ship allowed:` in `docs/reviews/<id>.md` (a leading `- ` or `* ` allowed) must read `Ship allowed: yes`, and the hash on the last `Reviewed tree:` line between that verdict and the verdict line before it (same leading `- ` or `* `; a full 40-hex hash alone, or followed by a blank and a remark) must pass `git diff --quiet <Reviewed tree> HEAD -- . ':(exclude)docs'` run from the worktree. The last `Review status:` line between that verdict and the previous one, and the last `Review status:` line of the file, must both read `Review status: complete`. No review, no usable `Reviewed tree:`, a diff that fails, or any other answer → stop with "Cannot ship <id>: the review is missing or blocks it. Run /po-review <id>."

Then read the settings above and the project commands from `AGENTS.local.md`; stop if the file or a setting is missing. Every branch below depends on them.

**Coming back after a pull request was merged by hand?** With `Merge mode: pr`, if `gh pr view story/<id> --json state --jq .state` already prints `MERGED`, go straight to cleanup.

## The forge's review rule
Read at every ship, after Step 0 and before any check runs; `/po-setup` reads the forge the same way. It settles the **effective** `Ship confirmation` of this ship. It never opens, skips or replaces `po-gate ship-allowed <id>`.

**Which forge.** From `git remote get-url origin`: host `github.com` → GitHub; a host containing `gitlab` → GitLab; any other host → probe `https://<host>/api/v1/version`, and a JSON answer holding `version` → Forgejo/Gitea. No `origin`, no answer, or a host matching none of these → the forge is unreadable. The probe carries no token: plain `curl -q`, `-q` first so `~/.curlrc` is never read, no header, no `.netrc`. No call to an unrecognised host carries a token.

**How it is read.** A token only ever goes to the host that issued it. GitHub: `gh api`, pinned with `--hostname github.com`, when `gh` is installed and logged in; otherwise `curl` on `https://api.github.com` with `GH_TOKEN` or `GITHUB_TOKEN`, sent in a request header, never echoed, never written to a file. These two variables are the only environment tokens this rule uses, and only because GitHub is recognised on the host `github.com` alone. No CLI and no token → the forge is unreadable.

GitLab and Forgejo/Gitea are read only through their CLI, logged in for the host of `origin`. GitLab: `glab api`, run as `env -u GITLAB_TOKEN -u GITLAB_ACCESS_TOKEN -u OAUTH_TOKEN glab api --hostname <host> …`, because `glab` otherwise prefers those variables to the login stored for the host, whatever the host. Forgejo/Gitea: `tea api`, run as `env -u GITEA_TOKEN -u TEA_HOST -u GITEA_INSTANCE_URL tea api …` against the `tea` login whose URL is that host (check first with `tea api --help` that the installed `tea` has it). Neither has a fallback through a direct HTTP call. No `glab` or `tea` login for the host of `origin` → the forge is unreadable, and the report says which CLI and which host.

**The signals.** Any one of them makes the repository **collaborative**:
- *Another writer.* GitHub: `repos/{owner}/{repo}/collaborators`, an entry whose `permissions.push` is true and whose `login` differs from the `login` of `user`. GitLab: `projects/:id/members/all`, an entry with `access_level` of 30 or more whose `username` is not that of `user`. Forgejo/Gitea: `repos/{owner}/{repo}/collaborators`, then `repos/{owner}/{repo}/collaborators/<login>/permission` reading `write` or `admin`, for a `login` other than that of `user`.
- *A `CODEOWNERS` naming someone else*, read with git from `origin/<Target branch>`, no API call: a `CODEOWNERS` file at the root or in `docs/`, `.github/`, `.gitlab/`, `.gitea/` or `.forgejo/`. Any owner other than `@<own login>` counts, a team or an e-mail address included.
- *A protection requiring an approval* on `Target branch`. GitHub: `repos/{owner}/{repo}/branches/<Target branch>/protection` whose `required_pull_request_reviews.required_approving_review_count` is above 0, or `repos/{owner}/{repo}/rules/branches/<Target branch>` holding a `pull_request` rule whose `required_approving_review_count` is above 0. GitLab: `projects/:id/approval_rules` with `approvals_required` above 0. Forgejo/Gitea: the `repos/{owner}/{repo}/branch_protections` entry for that branch with `required_approvals` above 0.

**Answers that mean absence.** A 404 for an unprotected branch, an empty list, and the 403 GitHub gives when the feature needs another plan — its message says "Upgrade to GitHub Pro", the case of a private repository on a free plan — all count as "no protection"; collaboration is then still read from the other two signals. Any other failure leaves that signal unreadable.

**Verdict.** One positive signal → collaborative. No positive signal and all three read → solo. No positive signal and one left unreadable → the forge is unreadable: the line's value stands, and the report names the call that failed and why.

**Effective value** of this ship: `human` on a collaborative repository, whatever the line says, a `(chosen)` line included. Otherwise the line's value with its suffix dropped — except that a value reading `(forge)` on a solo repository is `automatic`.

**Rewriting the line.** Only a line reading `(forge)`, suffixed or bare, and only when its value itself changes: collaborative and not `human` → `human (forge)`; solo and `human` → back to `automatic (forge)`. A bare `automatic` on a solo repository is left as it is. A `(chosen)` value is never rewritten by an agent; on a collaborative repository the report says the forge overrides it for this ship.

**Where the rewrite goes** (ADR-0080), built beside any checkout as the landing commit is (ADR-0081): starting from `origin/<Target branch>`, write the new `AGENTS.local.md` as a blob, stage it in a temporary index (`GIT_INDEX_FILE`), write the tree, then `git commit-tree <tree> -p origin/<Target branch> -m "chore: Ship confirmation follows the forge"`. Send that commit to the remote branch `framing/ship-confirmation` on `origin`, with a lease on that ref only — never to `Target branch`, never to a story branch — and skip sending it when that branch already holds the same line. Then open a **draft** pull request from it to `Target branch` with `gh pr create --draft`, or reuse the one already open from that branch. On a forge where `/po-ship` opens no pull request yet (ADR-0081: GitHub only), the branch is sent and the report asks a person to open the pull request. A refused push is never forced: the report gives the line to write by hand.

**The ship does not wait for that draft**: Step 2 already acts on the effective value, whether or not the draft is ever merged.

## Step 1 — The expensive checks, once
Commit `docs/reviews/<id>.md` on `story/<id>` if it is not committed yet, so the story carries its review. Then, using the project commands verbatim:
- **Unit suite** — with `Full suite: execute-end` the implementer already ran it, and a passing `po-gate verif-current <id>` is the proof; a failing proof means `<Test>` runs now. With `ship` or `both`, `<Test>` always runs now.
- **End to end** — when `E2E stage` is `ship`, this is the single end-to-end run of the whole cycle: `<E2E>`, limited to `E2E scope`, across every browser the project configures.
- **Build** — when `Build stage` is `ship`, `<Build>` runs. When it is `ship-if-route`, `<Build>` runs only for a diff that touches routing, a manifest or file-based routes; for any other diff, write that the build was skipped and why.
- **`ci`** (only meaningful with `Merge mode: pr`) — do not run the check here; wait for `gh pr checks` to be green on the pull request.

A command set to `—` is reported as absent, never replaced. **One failure and the ship stops**: the story goes back to `/po-execute <id>` as a fix run.

## Step 2 — Land as one commit, through a pull request
Message and title: `<id>: <story title>`.

`po-gate ship-allowed <id>` is required before any merge, whatever the value of `Ship confirmation`; nothing in `## The forge's review rule` opens or skips it. Below, `Ship confirmation` is always the effective value that section settled.

**Remote check.** `Merge mode: pr` with no `origin` remote → stop: a repository without a remote uses `local`. `Merge mode: local` with a remote → stop with "`Merge mode: local` is only for a repository without a remote (ADR-0080); set it to `pr`."

**Base.** In pr mode, `git fetch origin`, then `<base>` is `origin/<Target branch>`. In local mode, `<base>` is `<Target branch>`.

**Landing commit (ADR-0081)**, built beside the branch, from the worktree:
- `git merge-tree --write-tree <base> story/<id>` prints `<tree>`. A non-zero exit means a conflict: stop the ship and hand it to a human, listing the conflicting paths it printed.
- `git commit-tree <tree> -p <base> -m "<id>: <story title>"` prints `<sha>`, one commit on top of `<base>`.
- `story/<id>` is never rewritten: its tree stays the reviewed one, which `po-gate ship-allowed` and the resume of `/po-drive` keep reading.

**`Merge mode: pr`**
- Push the landing commit alone to the story branch on the remote: `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`. When `origin/story/<id>` does not exist yet — the branch was never pushed, or a cleanup deleted it — nothing is skipped: the push creates it. Skip the push when the head of `origin/story/<id>` already has `<base>` as its only parent, `<tree>` as its tree and `<id>: <story title>` as its message (`git log -1 --format=%s origin/story/<id>`); a head that differs on any of the three is replaced by the push. When the push is skipped, `<sha>` becomes that head: `git rev-parse origin/story/<id>`, its full SHA, never the commit `git commit-tree` printed on this run, whose new committer date gives it another SHA. Every push of the landing names `story/<id>` and nothing else; the only other branch this command ever sends is `framing/ship-confirmation`, from `## The forge's review rule`.
- A pull request for `story/<id>` already open → reuse it. None → open one to `Target branch`, titled `<id>: <story title>`, with what changed, why, how to test, and the review verdict (max severity and a summary of the findings).
- `Ship confirmation: human`, the effective value → stop here. The pull request is the human's decision point: "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup." When `Target branch` has moved before that, a later run rebuilds the landing commit on the new base and pushes it again; it never opens a second pull request.
- `automatic`, the effective value → wait for `ci` to be green when the project declares it, run `po-gate ship-allowed <id>` once more, then, `<sha>` being the pushed head when the push was skipped, `gh pr merge <url> --rebase --match-head-commit <sha>`, then cleanup.

**`Merge mode: local`**
- `Ship confirmation: human`, the effective value → AskUserQuestion "Land <id> on <Target branch> as one commit?", answers Merge / Not now. Continue on Merge only.
- In the repository root: it must be on `Target branch` with no staged or modified tracked file (`git status --porcelain --untracked-files=no` prints nothing); otherwise stop and describe what you found. Then `git merge --ff-only <sha>`. Nothing is pushed.

## Step 3 — Cleanup, only after proof
1. Proof. `pr`: `gh pr view story/<id> --json state --jq .state` prints exactly `MERGED` — open, closed or "merging" is not proof, and cleanup does not happen. `local`: the landing commit is an ancestor of `Target branch` (`git merge-base --is-ancestor <sha> <Target branch>`). Do not test the story branch's own commits: the landing commit is built beside them, so they are never ancestors.
2. The worktree has no uncommitted change → `git worktree remove <path>`. If it has changes, stop; `--force` is not an option.
3. Delete `story/<id>` locally with `git branch -D` (git considers the branch unmerged, since its own commits never land; step 1 is what makes this safe) and, if it was pushed, on the remote with `git push origin --delete story/<id>`.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · the exact step that stopped, what is missing, and the command to run next. Every finish also names the effective `Ship confirmation` and why — collaborative, solo, or unreadable with the call that failed — and any rewritten line with its branch `framing/ship-confirmation` and its draft URL.
