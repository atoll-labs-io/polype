---
description: Ship a reviewed story — mechanical gate, the cycle's only expensive checks, squash merge per the project's settings, cleanup only on a proven merge
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Bash
  - AskUserQuestion
---
# /po-ship — The exit gate

Reads settings: `Merge mode`, `Target branch`, `Ship confirmation`, `Worktree root`, `Full suite`, `E2E stage`, `E2E scope`, `Build stage`

Target story: $ARGUMENTS

Resolve the id against `docs/stories.md`. Locate `<Worktree root><id>`, check it is on exactly `story/<id>`, and run every step from that absolute path unless a step says otherwise. Missing worktree, wrong branch or detached HEAD → STOP; never check the story branch out in the repository root.

## 0. Gate — mechanical, before anything
Run `po-gate ship-allowed <id>` (or `grep -qE '^Ship allowed:[[:space:]]*yes[[:space:]]*$' docs/reviews/<id>.md` where the hook is not installed). Missing file or failure → STOP: "Ship blocked: review missing or negative. Run /po-review <id>." Nothing below runs otherwise.

Read the settings listed above and the project commands from `AGENTS.local.md`. A missing file or setting → STOP: "No project settings. Run /po-setup." Never assume a mode: every step below branches on them.

## 1. Exit checks — the only place the expensive ones run
Commit `docs/reviews/<id>.md` on `story/<id>` if it is not committed yet: the story carries its review. Then, with the project's own commands quoted verbatim:
- **Unit suite.** `Full suite: execute-end` → it already ran; confirm with `po-gate verif-current <id>` and run `<Test>` only if that fails. `ship` or `both` → run `<Test>` here.
- **End to end.** `E2E stage: ship` → run `<E2E>` once, at `E2E scope`, on every browser the project configures. This is the cycle's only end-to-end run.
- **Build.** `Build stage: ship` → run `<Build>`. `ship-if-route` → only when the story's diff moved a route, a manifest or file-based routing; otherwise skip it and say so.
- **`ci`** for any of them → do not run it here: read the branch's checks (`gh pr checks`) and stop unless they are green.

A command set to `—` does not exist here: say so, never substitute one. **Any red → stop and go back to `/po-execute <id>` in fix mode.** Nothing merges on red.

## 2. Confirmation
`Ship confirmation: human` → ask with AskUserQuestion, "Merge <id> into <Target branch>?": Merge / Not now. Only an explicit Merge continues. The gate allows the ship; the human decides it.

## 3. Merge — always a squash
One story, one commit on `Target branch`, message `<id>: <story title>`.
- **`Merge mode: pr`.** If a pull request for `story/<id>` already exists, do not open another: `MERGED` → go to cleanup; `OPEN` → continue with it. Otherwise push the branch and open a pull request to `Target branch` with a clear title, what / why / how to test, and the review verdict (max severity and findings summary).
  - confirmation `human` → **do not merge.** End with: "PR opened: <url>. Squash-merge it when you decide, then rerun /po-ship <id> to clean up."
  - confirmation `automatic` → `gh pr merge <url> --squash`, then cleanup.
- **`Merge mode: local`.** In the repository root, which must be on `Target branch` with a clean tree (otherwise STOP and say what is checked out): `git merge --squash story/<id>`, commit with the story message, note the new commit's sha, push if the project has a remote. Then cleanup.

## 4. Cleanup — only on a proven merge
1. **Prove it.** `pr` → `gh pr view story/<id> --json state --jq .state` must print exactly `MERGED`; anything else — open, closed without merge, "about to merge" — skips cleanup entirely. `local` → the squash commit's sha is an ancestor of `Target branch` (`git merge-base --is-ancestor <sha> <Target branch>`). Never test the story branch's own commits for ancestry: a squash rewrites them, so that check fails on every correct merge.
2. Check the worktree is clean, then `git worktree remove <absolute worktree path>` — a dirty worktree is a hard stop, never `--force`.
3. Only then delete the branch, locally with `git branch -D story/<id>` (a squashed branch always looks unmerged to `-d`; the proof of step 1 is the safety) and on the remote if it was pushed.

End with: "Story <id> shipped. Next: /po-status" — or "PR opened: <url>. Merging is yours." — or the exact blocking state: which step, what is missing, which command comes next.
