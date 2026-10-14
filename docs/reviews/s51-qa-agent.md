# Review: s51-qa-agent

[Story](../stories.md) · [Plan](../plans/s51-qa-agent.md) · [Verification](../verif/s51-qa-agent.md)

Fix loop: 0
Scope: `git diff main...story/s51-qa-agent`, which is one commit, d5c8e8c, touching 14 files.
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s51-qa-agent, on branch `story/s51-qa-agent`. It was clean before the review and is clean after it (`git diff --exit-code` and `git status --porcelain` both print nothing).

## Scope check against `Owns`
- Every path under `method/` and `tests/` is inside the story's `Owns` line.
- The story's own evidence files (`docs/research/s51-qa-agent.md`, `docs/plans/s51-qa-agent.md`, `docs/verif/s51-qa-agent.md`) are in scope by construction.
- `docs/decisions/ADR-0026-qa-herite-le-navigateur-et-lit-git-par-liste-blanche.md` is outside `Owns`. Law 6 requires structural decisions to be ADRs, so this is a gap in the story's `Owns` line, not a breach by the implementer. Finding m1.
- One other lane is running: `story/s48-floor-guard`. Its `Owns` is `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/skills/review-antihallu/` and `tests/floor-guard.test.sh`, so it shares no path with s51. Its ADR is numbered 0025 and this one 0026, so the numbers don't clash either.

## Step 1: reuse what is already proven
- `Verification mode: record`. `po-gate verif-current s51-qa-agent` exits 0, and `git diff --quiet 1c194c5… HEAD -- . ':(exclude)docs'` exits 0. The record is complete and every exit code in it is 0.
- What I relied on from the record:
  - `bash tests/run.sh`: 254 passed.
  - `bin/po-lint`: clean.
- The project has no `Typecheck`, `E2E` or `Build` command (all `—`), so none of those was run.
- I read the record's "Not proven here" section. It says the agent was never dispatched in a real session.
- The diff changes no routing and no manifest, so nothing else was needed before ship.

## Step 2: what the diff refers to
- The installer copies `method/agents`, `method/commands`, `method/templates` and `method/hooks` as whole directories (`bin/polype:86-101`). So the new `qa` agent, `/po-qa` and `templates/qa.md` are all installed; `/po-qa`'s `subagent_type: qa` points at an agent that will exist.
- `check_bash` gained a third argument, `mode`. It has only one call site, and that call passes it.
- `designer.md` preloads `design-doctrine`.
- `tests/lib.sh` helpers are used as the research describes; `disallowedTools` is parsed directly, because `lacks_tool` would prove nothing on a file with no `tools:` line.

## Step 3: diff against the plan
- Tasks 1 to 9 are all present.
- I checked the run interdicts:
  - Every forbidden file has an empty diff (`git diff --stat` on the list prints nothing).
  - `grep -rniE 'mcp__|playwright|chrome' method/` finds nothing.
  - The existing tests are unchanged, apart from `hook_command` gaining an optional argument.
- Nothing contradicts ADR-0022 or ADR-0026, except the allowlist content (M1 below).

## Step 4: do the tests bite?
Test count: 7 tests for 7 criteria, within the budget of 25.

I disabled one rule at a time and ran only `bounds.test.sh`. Each change was undone with `git checkout --`, and `git diff --exit-code method/hooks/po-bounds.sh` confirmed the file was back to its committed state.

| Rule disabled | Tests failed |
| --- | --- |
| `check_write_qa` accepts all of `docs/*` | 1 (`qa_writes_are_bounded_by_the_hook`: another story's qa folder) |
| The qa verb allowlist never refuses | 1 (same test: `git add -A`) |
| `worktree` in qa mode not limited to `list` | **0**, which is finding m2 |

The six tests in `qa.test.sh` check the text of method files, which is how this repository tests. `browser_contract_is_written_once` does have bite: it counts files with `grep -rlF`, so a second copy of a rule would fail it.

## Step 5: values that look right
I sent these commands straight to `po-bounds.sh qa` and recorded its exit code:
- `git symbolic-ref HEAD refs/heads/main` → 0 (allowed)
- `git diff --output=src/x` → 0 (allowed)
- `git branch --show-current` → 2 (refused; ADR-0026 accepts this cost)
- `env git add -A` → 2 and `command git commit -m x` → 2 (refused)
- `rm -rf src` → 0 and `git log -1 > src/x` → 0 (allowed; the story only bounds git verbs, and ADR-0026 accepts this)

## Step 6: other callers
- `implementer.md` still calls `po-bounds.sh implementer`, and every implementer case keeps its verdict (the existing tests are green in the record).
- The installed copy `.polype/hooks/po-bounds.sh` is left alone, as the rules require.

## Findings

### M1 (major): the qa git allowlist lets through git commands that write
- File: `method/hooks/po-bounds.sh`, the `QA_GIT_VERBS` line. The same list is in ADR-0026.
- Rule broken: the criterion `qa_writes_are_bounded_by_the_hook` says the qa mode "refuse tout verbe git qui écrit", and `method/agents/qa.md` tells the agent "a hook holds … git to reading verbs".
- `symbolic-ref` with two arguments rewrites HEAD. `git symbolic-ref HEAD refs/heads/main` exits 0, which would move the QA worktree off `story/<id>`.
- `git diff --output=<file>` and `git log --output=<file>` write a file anywhere, and the hook allows them.
- Why it is contained: the next stage's branch check would stop on a moved HEAD, so the damage would not go unnoticed.
- Fix:
  - Limit `symbolic-ref` to one argument, or drop it, since `rev-parse --abbrev-ref HEAD` already does the job.
  - Refuse `--output`.
  - Add one test case for each.
  - Change ADR-0026 through a new ADR, because an accepted ADR is never edited.

### m1 (minor): the ADR file is not in `Owns`
- Path: `docs/decisions/ADR-0026-…md`.
- Rule that requires it: Law 6, "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`".
- The story's `Owns` line does not list it. Nothing in the code needs to change.

### m2 (minor): the `worktree list` limit has no test
- If the `worktree` branch of the qa mode is disabled, so that `git worktree add`, `remove` or `prune` pass, no test fails.
- Fix: one case `git -C $WT worktree remove …` → 2.

### m3 (minor): an unclear stop condition in `/po-qa`
- File: `method/commands/po-qa.md`, precondition 6, "The story shows no screen".
- It doesn't say what to read to decide this (for example, whether `docs/designs/<id>/` exists, or the orchestrator's own test), so two runs could decide differently.

## Not verified, and why
- **No real QA run.** The `qa` agent was never dispatched in a real Claude Code session. Two things rest only on the research's reading of the 2.1.292 binary:
  - that, with no `tools:` line, it inherits the session's browser tool;
  - that `disallowedTools` removes Edit from it.
  
  To cover it, a person should run `/po-qa` on a story with a screen in a session that has a browser tool, check that Edit is unavailable, and check that a `Write` outside `docs/qa/<id>/` is refused.
- **Files the hook never sees.** Captures saved by the browser tool or copied in Bash, and shell redirections, bypass `po-bounds`. ADR-0026 accepts this and the story claims no more. Nobody has checked what a real browser tool writes, or where.
- **The `/po-setup` follow-up question.** The `QA stage` question was only checked as text; no setup was run.
- **No screen in this story**, so there was no visual check and the design-conformity check does not apply.
- **The full suite and lint were not rerun.** I relied on the current record.

Max severity: major
Ship allowed: yes
