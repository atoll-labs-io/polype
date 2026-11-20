---
description: Lands a reviewed story on Target branch as one commit through a pull request, then cleans up once the merge is proven
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---
# /po-ship

Reads settings: `Merge mode`, `Target branch`, `Ship confirmation`, `Worktree root`, `E2E stage`, `Build stage`, `Issue tracker`, `Forge checks`

Story: $ARGUMENTS

Match the id in `docs/stories.md`. The worktree `<Worktree root><id>` must be on `story/<id>`, or stop without touching any branch. Run commands with `cd <path> &&` or `git -C <path>` unless a step names the repository root.

## Step 0 — The verdict first
`po-gate ship-allowed <id>` from the worktree; a refusal or no hook → stop with "Cannot ship <id>: the review is missing or blocks it. Run /po-review <id>."

Then read the settings above; stop if one is missing, except `Forge checks`, whose absence the finish names.

**After a hand merge**, with `Merge mode: pr`: if `gh pr view story/<id> --json state --jq .state` already prints `MERGED`, go straight to cleanup.

## The forge's review rule
Read at every ship, after Step 0 and before any check runs. It settles this ship's **effective** `Ship confirmation`. It never opens, skips or replaces `po-gate ship-allowed <id>`.

From the worktree, run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship forge`, which writes nothing. Its `effective` is that value; `verdict`, `signals` and `failed` go to the finish, which says when the forge overrides a `(chosen)` line. `po` missing or exit 2 → stop and name `polype install`.

When `rewrite` is not null, `po ship push` (Step 2) builds the settings commit beside any checkout, as the landing commit is (ADR-0080, ADR-0081), and opens its draft; the ship never waits for it, and the finish quotes `rewrite` and asks a person for what its `next` names.

## Step 1 — Checks once, then the landing commit
From the worktree, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship land <id>` runs the gate, the remote check, a conflict probe and the checks once, commits the review and record rows on `story/<id>`, and builds the landing commit beside it (ADR-0081).
- **Routes** — under `Build stage: ship-if-route`: `--routes yes` when `git diff --name-only <Target branch>...story/<id>` touches routing, a manifest or file-based routes, else `--routes no`, and the finish says why.
- **`--land`** — only under `Merge mode: local` with an effective `automatic`; `po` refuses it otherwise.

`checks`, `sha`, `tree`, `base` go to the finish; `already_landed` → Step 3. `gate-refused` → Step 0's line; `check-failed` → **One failure and the ship stops**, `/po-execute <id>` as a fix run; `conflict` → a human, with `paths`; `remote-check`, `root-not-clean` or any other refusal → stop, quoting its `message`.

## Step 2 — Land as one commit
`po-gate ship-allowed <id>` is required before any merge, whatever the value of `Ship confirmation`. Below, `Ship confirmation` is always the effective value that section settled.

**Remote check** (Step 1): `pr` needs `origin`; `Merge mode: local` is only for a repository without a remote.

**`Merge mode: pr`**, `<sha>` from Step 1. Write the pull request description with the file tool into a fresh `mktemp -d` folder outside the worktree: what changed, why, how to test, and the review verdict (max severity, a findings summary minus any finding Step 3 holds, any `Security findings:` line as written). Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship push <id> --sha <sha> --body-file <file>` in the background, since its wait for the forge's checks may last 30 minutes; a cut call is simply run again, as it resumes. It alone decides the merge. Remove the folder once the last call has ended.
- `state`: `merged` → Step 3; `waiting-for-human` → stop with "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup."; `merging` or `no-pull-request` → stop, a person proves the merge or opens the pull request.
- `checks-failed` → stop, merging nothing; the finish names each failed check with its link and `/po-execute <id>` as a fix run. `stale-landing` → Step 1 again. `pull-request-closed`, `checks-timeout`, `checks-unreadable`, `push-refused` or any other refusal → a human, quoting its `message`.

**`Merge mode: local`**
- `Ship confirmation: human`, the effective value → Step 1 without `--land`, then AskUserQuestion "Land <id> on <Target branch> as one commit?", Merge / Not now. Merge → `po ship land <id> --sha <sha>`; `stale-landing` → Step 1 again, then ask.
- `automatic`, the effective value → Step 1's `--land` fast-forwarded the root. Nothing is pushed.

## Step 3 — Cleanup, only after proof
1. Proof. `pr`: `gh pr view story/<id> --json state --jq .state` prints exactly `MERGED` — open, closed or "merging" is not proof, and cleanup does not happen. `local`: the landing commit is an ancestor of `Target branch` (`git merge-base --is-ancestor <sha> <Target branch>`). Do not test the story branch's own commits: the landing commit is built beside them, so they are never ancestors.
2. File the open findings. It comes before the worktree goes; the review is not lost with the worktree, since Step 1 committed it and it lands with the story's commit (Law 6, Law 7, ADR-0090). From the worktree, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship file <id>` files nothing: it proves the landing, reads the last review as it landed, and returns `findings`, `critical`, `security` and `unrecognised` by line number.
   - **Your judgement.** Each finding whose text bears on security — a secret or a token, an authorization or tenant check, an injection — is held with `--hold <line>`, whatever lens ran: it goes to the person in the finish, marked "not filed: security (ADR-0077)". Each finding or `critical` the last block marks fixed is named with `--fixed <line>`. Then run the same call with `--file` and those options; `po` builds titles and bodies, checks what is already open and files through files, never in an argument.
   - **What stays with the person.** `security` is quoted by its count and decision only, with the `Security findings:` line as written, never opening that decision. Each `unrecognised` line is marked "not filed: shape not recognised"; each `critical` left goes too.
   - **Replies.** `filed` gives each issue URL or task uuid, `already_open` what was skipped. `no-tracker`, `listing-failed`, `too-many-open` or `tracker-unavailable` → nothing is filed, and the finish says why and lists `pending`; `file-failed` → run it again, since a rerun files only what is missing. `not-landed` or exit 2 → stop, quoting its `message`. Under `Issue tracker: taskwarrior`, each finding is one task in `project:<name>` tagged `+issue`, `<name>` being the last path segment of `origin` without `.git`, or, with no remote, the folder holding the main repository (the parent of `git rev-parse --path-format=absolute --git-common-dir`) — never the worktree folder.
3. The worktree has no uncommitted change → `git worktree remove <path>`. If it has changes, stop; `--force` is not an option.
4. Delete `story/<id>` locally with `git branch -D` (git sees it unmerged, its own commits never landing; step 1 makes this safe) and, if it was pushed, on the remote with `git push origin --delete story/<id>`.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · the exact step that stopped, what is missing, and the command to run next. Every finish also names the effective `Ship confirmation`, the `verdict`, `signals` and `failed` behind it, any rewritten line with its draft URL, and the checks' outcome when it waited. Every finish after a proven merge also names the issues filed, each with its URL or task uuid, the ones skipped as already open, and the findings held for the person, with why.
