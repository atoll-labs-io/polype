# Review: s106-framing-through-pr

Reviewed tree: 5a299950f9b7fa53c2bcd81eb41497a00adc8dac
Fix loop: 0
Branch: `story/s106-framing-through-pr` (worktree `/home/lecrabe/dev/atoll/polype/.worktrees/s106-framing-through-pr`)
Scope: `git diff main...story/s106-framing-through-pr`
Lenses run: none (no security, migration, dependency or server-side path or content in the diff)

**Summary: no critical finding, so the story may ship. Two majors go to a later cycle and four minors are style.**

## Scope (Owns)
Every changed path is covered:
- The eight `method/commands/po-*.md` files and `tests/framing-through-pr.test.sh` are inside the story's `Owns` line.
- The plan, research and verification files under `docs/` are the story's own pipeline evidence.

No owned path overlaps a running story:
- `story/s103-project-lead` (not merged) owns `method/AGENTS.md`, `po-session.sh`, `bin/polype`, `po-help.md`, `docs/installation.md` and its test.
- `story/reuse-ladder` touches only `docs/stories.md`.
- s104 (which owns `po-architect.md`) has no worktree yet.

## Step 1: verification reused
- `po-gate verif-current s106-framing-through-pr` exits 0, and `Verification mode` is `record`. The unit suite (`bash tests/run.sh`) has a passing row on this code, so I did not rerun it.
- The project has no `Typecheck`, `E2E` or `Build` command (all `—`).
- The record's "Not proven here" says no real landing (PR or local fast-forward) was run.
- `QA stage` is `—`, so the story does not go to QA.

## Step 2: references
- `## The forge's review rule` exists in `method/commands/po-ship.md:24`.
- The "settings commit of `/po-ship`" that the landing copies is `po-ship.md:44`.
- ADR-0080 and ADR-0081 exist in `docs/decisions/`. ADR-0080 line 27 requires framing and settings commits to go through a branch and a PR.
- `Merge mode` and `Ship confirmation` exist as settings.
- All seven commands have `Bash` and `AskUserQuestion` in their allowed tools.
- `po-gate.sh pre-commit` reads `git diff --cached`, so it honours `GIT_INDEX_FILE`.

## Step 3: diff against the plan
All six tasks are done as written, and every run interdict holds:
- Only owned files changed. No existing test changed. No new ADR.
- The guards stay word for word: `status: approved`, the brief and its ADR in one commit, and the branch and `git status --porcelain` checks. Architect, design-system and stories-review keep their branch check in their early steps (lines 20, 20 and 26).

Pivot 1 (the root's fast-forward refuses because the framing files are staged there) was probed in a throwaway repo under `/tmp/tmp.B37tgU0AHx`:
- I built the commit beside the checkout with a temporary index and `commit-tree`, then staged the file in the root's own index.
- I merged it on the "remote" side, then ran `git merge --ff-only origin/main` in the root.
- It exited 0 and left a clean status. The plan's claim holds.

## Step 4: tests
- **Floor guard:** `po-gate floor-guard s106-framing-through-pr main` exits 0, so no check was made easier to pass.
- **Budget:** 3 tests, within the budget of 25.
- **Fake coverage:** none found. These are text checks on method files, which is the only layer this repository has.
- **Bite checks:** each mutation ran only `framing-through-pr.test.sh`. Each was undone and confirmed back to its committed state with `git diff --exit-code`.

| Mutation | Tests failing |
| --- | --- |
| `po-architect.md` step 4 reverted to "On `Target branch`, commit …" | 1 (`framing_commits_on_a_branch`) |
| `po-research.md` step 2 (the story-on-start-point check) deleted | 1 (`research_waits_for_framing_merge`) |
| `po-setup.md` `git merge --ff-only origin/<Target branch>` changed to a plain `git merge` | 1 (`framing_pr_fast_forwards`) |
| `po-setup.md` sentence "It never commits to `Target branch` directly and never pushes it." deleted | **0** (see finding 6) |

## Steps 5 and 6: values and neighbours
Covered by the findings below.

## Findings

1. **major: `/po-drive` builds lanes without the new guard.** `method/commands/po-drive.md:86` (a neighbour, outside `Owns`) lists the worktree steps inline: "fetch … start from `origin/<Target branch>` …, `git worktree add -b story/<id> …`".
   - It says "exactly as `/po-research` describes it", but its own list omits the new step 2, which checks that the story is on the start point.
   - So a fleet lane can be created for a story whose framing PR is not merged yet, which is the case `research_waits_for_framing_merge` exists to stop.
   - The cause is outside this story's scope: s106 could not edit `po-drive.md`. A follow-up should add the check to that line; s104 already owns the file.

2. **major: on a non-GitHub forge, a second landing can drop earlier files.** `method/commands/po-setup.md` `## Landing the framing`, **Base**: the stacking decision rests only on `gh pr list --head framing/<slug> --state open`.
   - On a forge where no pull request is opened (ADR-0081: GitHub only), or whenever `gh` cannot answer, a second run of the same slug picks `<base> = origin/<Target branch>`.
   - Its push then replaces `framing/<slug>` with the lease, because after the fetch the remote-tracking ref matches.
   - Example: a second `/po-architect` run carrying a different ADR file drops the first run's ADR from the branch. The file stays staged in the root, so the loss is contained.
   - The base should also be `origin/framing/<slug>` when that remote branch exists and is not already in `origin/<Target branch>`, whatever the PR lookup says.

3. **minor: nothing updates the root after a person merges.** In pr mode under `human`, no step fast-forwards the root once the person merges the framing PR. The stop sentence does not say who should. Local `Target branch` lags, and the framing files stay staged in the root until a later automatic landing or a manual `git merge --ff-only`.

4. **minor: a refused fast-forward is unhandled in local mode.** Under **`Merge mode: local`**, the text does not say what happens when `git merge --ff-only framing/<slug>` refuses. That happens when `Target branch` moved after a "Not now" (for example a story shipped). The pr branch does say "A refusal is reported …".

5. **minor: the secret scan compares against the wrong base.** `GIT_INDEX_FILE=<tmp> .polype/hooks/po-gate.sh pre-commit` compares the temporary index against `HEAD` (local `Target branch`), not against `<base>`.
   - When `<base>` is ahead of local HEAD (`origin/<Target branch>` after a fetch, or a stacked `origin/framing/<slug>`), the scan reads more than the new commit's lines.
   - It never scans less, so the risk is a false refusal, not a missed secret.

6. **minor: one rule is never frozen by a test.** No test freezes the explicit rule "never commits to `Target branch` directly and never pushes it" (bite check above: 0 failures). The negative checks on `git push` lines and on "commit … on `Target branch`" cover it only in part.

## Not verified
- **Pushes and pull requests.** `git push --force-with-lease=framing/<slug> …` is untested, including what it does on a first push when no remote-tracking ref exists. So are `gh pr create`, `gh pr merge --rebase --match-head-commit` and the `MERGED` proof. `po-bounds` refuses `git push` everywhere, and no forge was reachable. A person should run one real framing command in pr mode on a scratch GitHub repo.
- **Local mode end to end.** The `update-ref` → AskUserQuestion → `merge --ff-only framing/<slug>` → `branch -d` path never ran. A person should run `/po-brief` on a repo without a remote.
- **Non-GitHub forges** (GitLab, Forgejo) were not exercised; they appear only in the text.
- **Secret scan on the temporary index.** I reasoned from `po-gate.sh` that it uses `git diff --cached`; I did not run it.
- **Root fast-forward when the merge rewrites the commit.** I probed only the root fast-forward with staged identical files. A GitHub "Rebase and merge" rewrites the commit, and the fast-forward onto that rewritten commit was not exercised.
- **Settings missing in the project.** The project has no `Typecheck`, `E2E` or `Build` command, and `QA stage` is `—`, so there is no QA report and no `## Not seen` to carry over.

Max severity: major
Ship allowed: yes
