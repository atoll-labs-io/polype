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

Match the id in `docs/stories.md`; the worktree is `<Worktree root><id>`. Run commands there by Law 4, unless a step names the repository root.

## Step 0 — The verdict first
A story `po next` answers `ship` with reason `landed`, or whose worktree is gone, goes straight to Step 3, with no gate nor check.

Otherwise `po-gate ship-allowed <id>` from the worktree; a refusal or no hook → stop with "Cannot ship <id>: the review is missing or blocks it. Run /po-review <id>."

## The forge's review rule
Read at every ship, after Step 0, before any check. It settles the **effective** `Ship confirmation`. It never opens, skips or replaces `po-gate ship-allowed <id>`.

From the worktree, run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship forge`. Its `effective` is that value; `verdict`, `signals` and `failed` go to the finish, which says when the forge overrides a `(chosen)` line. `po` missing or exit 2 → stop, naming `polype install`.

A `rewrite` that is not null goes to the finish, which asks a person for what its `next` names.

## Step 1 — Checks once, then the landing commit
From the worktree, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship land <id>` runs the gate, a conflict probe and the checks once, commits the review and record rows on `story/<id>`, and builds the landing commit.
- **Routes** — under `Build stage: ship-if-route`: `--routes yes` when `git diff --name-only <Target branch>...story/<id>` touches routing, a manifest or file-based routes, else `--routes no`, and the finish says why.
- **`--land`** — only under `Merge mode: local` and an effective `automatic`.

`checks`, `sha`, `base` go to the finish; `already_landed` → Step 3. `gate-refused` → Step 0's line; `check-failed` → **One failure and the ship stops**, `/po-execute <id>` as a fix run; `conflict` → a human, with `paths`; any other refusal → stop, quoting its `message`.

## Step 2 — Land as one commit
`po-gate ship-allowed <id>` is required before any merge, whatever the value of `Ship confirmation`, the effective one below.

**`Merge mode: pr`**, `<sha>` from Step 1. Write the pull request description with the file tool into a fresh `mktemp -d` folder: what changed, why, how to test, the review verdict (max severity, findings summary minus any finding Step 3 holds, any `Security findings:` line as written). Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship push <id> --sha <sha> --body-file <file>` in the background, since its wait for the checks may last 30 minutes; a cut call is run again. It alone decides the merge. Remove the folder after.
- `state`: `merged` → Step 3; `waiting-for-human` → stop with "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup."; `merging` or `no-pull-request` → stop, a person proves the merge or opens the pull request.
- `checks-failed` → stop, naming each failed check with its link and `/po-execute <id>` as a fix run. `stale-landing` → Step 1 again. `pull-request-closed`, `checks-timeout`, `checks-unreadable`, `push-refused` or any other refusal → a human, quoting its `message`.

`Merge mode: local` is only for a repository without a remote.
- `human` → Step 1 without `--land`, then AskUserQuestion "Land <id> on <Target branch> as one commit?", Merge / Not now; Merge → `po ship land <id> --sha <sha>`; `stale-landing` → Step 1 again, then ask.
- `automatic` → Step 1's `--land` fast-forwarded the root. Nothing is pushed.

## Step 3 — Cleanup, only after proof
1. Proof. Each call below reads it itself and files or removes nothing without it.
2. File the open findings, from the worktree, before it goes (Law 7, ADR-0090). `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship file <id>` files nothing: it returns the last review's `findings`, `critical`, `security` and `unrecognised` by line number.
   - **Your judgement.** A finding whose text bears on security — a secret or a token, an authorization or tenant check, an injection — is held with `--hold <line>`, and goes to the person, marked "not filed: security (ADR-0077)". A finding or `critical` the last block marks fixed is named with `--fixed <line>`. Then run the same call with `--file` and those options; `po` skips what is already open.
   - **What stays with the person.** `security` is quoted by its count and decision only, with the `Security findings:` line as written, never opening that decision. Each `unrecognised` line is marked "not filed: shape not recognised", as is each `critical` left.
   - **Replies.** `no-tracker`, `listing-failed`, `too-many-open` or `tracker-unavailable` → nothing is filed; the finish lists `pending`; `file-failed` → run it again, which files only what is missing. `not-landed` or exit 2 → stop, quoting its `message`. Under `Issue tracker: taskwarrior`, each finding is one task in `project:<name>` tagged `+issue`, `<name>` being the last path segment of `origin` without `.git`, or, with no remote, the folder holding the main repository — never the worktree folder.
3. From the repository root, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship clean <id>` removes the worktree, then `story/<id>` locally and on `origin`, as `git push origin --delete refs/heads/story/<id>` would; a rerun finishes what is left. `remote-kept` or any refusal → stop, quoting its `message`. Once the worktree is gone and the filing done, `/po-ship <id>` reruns only this call, from the root.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · the exact step that stopped, what is missing, and the command to run next. Every finish names the effective `Ship confirmation` with its `verdict`, `signals` and `failed`, any rewritten line with its draft URL, a null `forge_checks`, and the checks' outcome when it waited. After a proven merge it also names the issues filed (`filed`, each with its URL or task uuid), the ones skipped (`already_open`), and the findings held, with why.
