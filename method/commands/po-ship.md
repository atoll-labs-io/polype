---
description: Lands a reviewed story on Target branch as one commit through a pull request, then cleans up once the merge is proven
argument-hint: <story id or name>
allowed-tools:
  - Read
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

**Where the rewrite goes**, when `rewrite` is not null (ADR-0080), built beside any checkout as the landing commit is (ADR-0081): starting from `origin/<Target branch>`, write `AGENTS.local.md` with its line set to `rewrite` as a blob, stage it in a temporary index (`GIT_INDEX_FILE`), write the tree, then `git commit-tree <tree> -p origin/<Target branch> -m "chore: Ship confirmation follows the forge"`. Send that commit to the remote branch `framing/ship-confirmation` on `origin`, with a lease on that ref only — never to `Target branch`, never to a story branch — and skip sending it when that branch already holds the same line. Then open a **draft** pull request from it to `Target branch` with `gh pr create --draft`, or reuse the one already open from that branch. On a forge where `/po-ship` opens no pull request yet (ADR-0081: GitHub only), the branch is sent and the report asks a person to open the pull request. A refused push is never forced: the report gives the line to write by hand.

**The ship does not wait for that draft**: Step 2 acts on the effective value.

## Step 1 — Checks once, then the landing commit
From the worktree, `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" ship land <id>` runs the gate, the remote check, a conflict probe and the checks once, commits the review and record rows on `story/<id>`, and builds the landing commit beside it (ADR-0081).
- **Routes** — under `Build stage: ship-if-route`: `--routes yes` when `git diff --name-only <Target branch>...story/<id>` touches routing, a manifest or file-based routes, else `--routes no`, and the finish says why.
- **`--land`** — only under `Merge mode: local` with an effective `automatic`; `po` refuses it otherwise.
- **`ci`** — under `Merge mode: pr`, a `ci` stage waits for `gh pr checks` on the pull request.

`checks`, `sha`, `tree`, `base` go to the finish; `already_landed` → Step 3. `gate-refused` → Step 0's line; `check-failed` → **One failure and the ship stops**, `/po-execute <id>` as a fix run; `conflict` → a human, with `paths`; `remote-check`, `root-not-clean` or any other refusal → stop, quoting its `message`.

## Step 2 — Land as one commit
Message and title: `<id>: <story title>`.

`po-gate ship-allowed <id>` is required before any merge, whatever the value of `Ship confirmation`. Below, `Ship confirmation` is always the effective value that section settled.

**Remote check** (Step 1): `pr` needs `origin`; `Merge mode: local` is only for a repository without a remote.

**`Merge mode: pr`**, `<sha>`, `<tree>`, `<base>` from Step 1
- Push the landing commit alone: `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`. When `origin/story/<id>` does not exist yet, the push creates it. Skip the push when the head of `origin/story/<id>` has `<base>` as its only parent, `<tree>` as its tree and `<id>: <story title>` as its message (`git log -1 --format=%s origin/story/<id>`). When the push is skipped, `<sha>` becomes that head: `git rev-parse origin/story/<id>`, never this run's commit. The only other branch this command sends is `framing/ship-confirmation`.
- A pull request for `story/<id>` already open → reuse it; none → open one to `Target branch`, titled `<id>: <story title>`, with what changed, why, how to test, and the review verdict (max severity, a findings summary minus any finding Step 3 holds, any `Security findings:` line as written).
- `Ship confirmation: human`, the effective value → stop here: "Pull request ready: <url>. Land it with Rebase and merge — one commit, no merge commit — then run /po-ship <id> again for cleanup." If `Target branch` moves meanwhile, a later run rebuilds and pushes the landing commit, never opening a second pull request.
- `automatic`, the effective value → wait for the checks below, run `po-gate ship-allowed <id>` once more, then `gh pr merge <url> --rebase --match-head-commit <sha>`, then cleanup.
- **The checks**, under `automatic` only. `Forge checks: required` → every 30 seconds, for at most 30 minutes, read `gh pr view <url> --json headRefOid` and, once it equals `<sha>`, `gh pr checks <url> --json name,bucket,link`, deciding on the JSON, never the exit code. At least one check and every bucket `pass` or `skipping` → go on. A `fail` or `cancel` bucket, no complete set after 30 minutes, or a forge `gh` cannot read (not GitHub, `gh` missing or logged out) → stop, merging nothing and starting no fix run; the finish names each failed check with its link, or says none arrived. `Forge checks: —` or no line → wait for `ci` to be green when the project declares it.

**`Merge mode: local`**
- `Ship confirmation: human`, the effective value → Step 1 without `--land`, then AskUserQuestion "Land <id> on <Target branch> as one commit?", Merge / Not now. Merge → `po ship land <id> --sha <sha>`; `stale-landing` → Step 1 again, then ask.
- `automatic`, the effective value → Step 1's `--land` fast-forwarded the root. Nothing is pushed.

## Step 3 — Cleanup, only after proof
1. Proof. `pr`: `gh pr view story/<id> --json state --jq .state` prints exactly `MERGED` — open, closed or "merging" is not proof, and cleanup does not happen. `local`: the landing commit is an ancestor of `Target branch` (`git merge-base --is-ancestor <sha> <Target branch>`). Do not test the story branch's own commits: the landing commit is built beside them, so they are never ancestors.
2. File the open findings. It comes before the worktree goes, since it reads the review there; the review is not lost with the worktree, since Step 1 committed it and it lands with the story's commit (Law 6, Law 7, ADR-0090).
   - **Which findings.** Read `## Findings` of the last review — the block that ends with its last `Ship allowed:` line, as Step 0 reads it. A finding is an item whose first line starts with a list marker — `- `, `* ` or a number and a dot (`1. `) — then its severity, bare or in bold, then `—`, `:` or `-`, the colon inside or outside the bold: `- major —`, `- **major** —`, `1. **minor**:`, `* minor:` all open one. The item is taken whole: its first line and every line after it — sub-bullets, indented or continuation lines — up to the next item, the next heading, or the first line that follows a blank line without being indented. Those whose severity is `major` or `minor` are filed, less any that block itself marks fixed.
   - **Nothing is dropped unread.** Under that `## Findings`, a line outside the items taken as above that could still be a finding goes to the person in the finish, quoted with its line number and marked "not filed: shape not recognised": a list item whose first line holds the word `critical`, `major` or `minor` without opening with it, a heading — a line starting with `#` — that holds the word `critical`, `major` or `minor`, in any case, or a line that opens with one of those words, bare or in bold, outside a list. So does an item of severity `critical` that the block does not mark fixed. A sentence such as "No critical or major finding." is neither and stays where it is.
   - **Title and body.** Title `<id>: <severity> — <start>`, where `<start>` is the item's first line after its marker, severity and separator, bold marks removed, cut to its first 80 characters, a space left at its end trimmed. Findings of one review that share a title make one issue whose body holds both. The body names the story id, the review path `docs/reviews/<id>.md` with the `Fix loop:` of the last review, the severity, the full finding — every line of the item, as the review writes it — and, under `Merge mode: pr`, the pull request URL.
   - **The finding text never enters a command.** Review text is input, possibly quoted from an untrusted diff. So no title, body or finding text is ever written into a shell argument, a heredoc or an `echo`, quoted or not: it goes from the review file to a file, and from a file to the tracker. Each finding gets a fresh folder `d=$(mktemp -d)`, filled by line numbers only, `<first>` and `<last>` being the item's first and last lines:
     - title: `{ printf '%s: %s — ' '<id>' '<severity>'; sed -n '<first>p' docs/reviews/<id>.md | LC_ALL=C.UTF-8 sed -E 's/^ *([-*]|[0-9]+\.) +//; s/^(\*\*)?(critical|major|minor)(:)?(\*\*)? *[—:-]? *//; s/^(.{80}).*/\1/; s/ +$//'; } > "$d/title"`;
     - body: `{ printf 'Story: %s\nReview: docs/reviews/%s.md\nSeverity: %s\nPull request: %s\n' '<id>' '<id>' '<severity>' '<url or —>'; grep '^Fix loop:' docs/reviews/<id>.md | tail -n1; echo; sed -n '<first>,<last>p' docs/reviews/<id>.md; } > "$d/body"`;
     - the title's `sed` runs under `LC_ALL=C.UTF-8`, so the cut counts characters, never bytes; a trailing space is trimmed, as GitHub trims it, so the exact compare below matches. The body takes the last review's `Fix loop:`;
     - only values that are not review text reach a `printf`: the story id, the severity word, the pull request URL `gh` printed. Every command below reads those files, or expands one as `"$(cat "$d/title")"`, one argument the shell never parses again. Extraction and filing of one finding run in one shell command.
   - **No duplicate.** An issue already open with exactly that title is not filed again. The comparison is exact, line against line, never through a search index. A listing that fails — `gh issue list` or `task` exiting non-zero, an empty listing being a success — proves nothing, so nothing is filed on that tracker: the finish says the listing failed, quotes its error and lists the findings. A `github` listing that returns 1000 titles, its `--limit`, may have left some out, so it is refused the same way rather than paged: nothing is filed, and the finish says the repository has too many open issues to rule out a duplicate.
   - **`Issue tracker: github`.** Only when the `forge` that `po ship forge` reported is `github`, and `gh auth status --hostname github.com` passes. List the open titles with `gh issue list --repo github.com/<owner>/<repo> --state open --limit 1000 --json title --jq '.[].title' > "$d/open"`; `grep -qxF -f "$d/title" "$d/open"` succeeding means already open. Otherwise `gh issue create --repo github.com/<owner>/<repo> --title "$(cat "$d/title")" --body-file "$d/body"`. The token goes only to the host that issued it (ADR-0083): no direct HTTP call, no other host. `gh` missing or not logged in, or `origin` not on `github.com` → nothing is filed, and the finish says so and lists the findings.
   - **`Issue tracker: taskwarrior`.** One task in `project:<name>` with the tag `+issue`, `<name>` being the last path segment of `origin` without `.git`, or, with no remote, the folder holding the main repository (the parent of `git rev-parse --path-format=absolute --git-common-dir`) — never the worktree folder. List the pending descriptions with `task project:<name> +issue status:pending _unique description > "$d/open"`; `grep -qxF -f "$d/title" "$d/open"` succeeding means already filed. Otherwise create with `task rc.verbose=new-uuid add project:<name> +issue -- "$(cat "$d/title")"`, then `task <uuid> annotate -- "$(cat "$d/body")"`. `task` missing → nothing is filed, and the finish says so and lists the findings.
   - **`Issue tracker: —`.** Nothing is filed; the finish says so and lists the open findings for the person.
   - **Security stays with the person.** A finding marked `[security]`, or whose text bears on security — a secret or a token, an authorization or tenant check, an injection — is not filed, whatever lens ran: it goes to the person in the finish, marked "not filed: security (ADR-0077)". The `Security findings:` line is no finding: the finish quotes it as written, never opening its decision.
3. The worktree has no uncommitted change → `git worktree remove <path>`. If it has changes, stop; `--force` is not an option.
4. Delete `story/<id>` locally with `git branch -D` (git sees it unmerged, its own commits never landing; step 1 makes this safe) and, if it was pushed, on the remote with `git push origin --delete story/<id>`.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · the exact step that stopped, what is missing, and the command to run next. Every finish also names the effective `Ship confirmation`, the `verdict`, `signals` and `failed` behind it, any rewritten line with its draft URL, and the checks' outcome when it waited. Every finish after a proven merge also names the issues filed, each with its URL or task uuid, the ones skipped as already open, and the findings held for the person, with why.
