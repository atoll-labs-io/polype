# Review — s77-last-review-leftovers

[Story](../stories.md) · [Plan](../plans/s77-last-review-leftovers.md) · [Verification](../verif/s77-last-review-leftovers.md)

Reviewed tree: 2efed951e0a667f55d43c36033f486694fc746bb
Fix loop: 0
Branch: story/s77-last-review-leftovers (commit 45bbf40), worktree /home/lecrabe/dev/atoll/polype/.worktrees/s77-last-review-leftovers
Lenses run: Security (path `method/hooks/po-bounds.sh`, the subagents' access policy; the diff widens what that policy allows)

## Summary
The story closes the remaining minor findings from the M7-bis reviews:
- **Readable refusals.** When `po-bounds` refuses a redirection target or a temp-zone path, the message now shows `<substitution>` instead of the raw `\036` byte.
- **Two new redirection targets.** `/dev/fd/1` and `/dev/fd/2` are allowed by exact spelling, recorded by ADR-0053.
- **Reviewer text.** `reviewer.md` now says the hook guards against the reviewer's mistakes, not against a deliberate bypass (ADR-0052).
- **ADR rules.** Law 6 says an accepted ADR changes only in its frontmatter links, plus its `status` when wholly replaced. The ADR template's link lines carry no comments.
- **Overlap wording.** `po-status` and check 8 of `stories-review` now say "overlap" in plainer sentences.

## Scope (Owns)
Diff paths checked against the `Owns` line at `docs/stories.md:1181`:
- Every `method/` and `tests/` path is listed.
- `docs/decisions/ADR-0052-…md` is listed explicitly.
- `docs/decisions/ADR-0053-…md` is added (status A) and named by the plan, so it is in scope by construction.
- The research, plan and verif files are the story's own pipeline evidence.

No other story is running: `git worktree list` shows only main and this lane. Nothing is out of scope.

## Evidence reused
- `po-gate verif-current s77-last-review-leftovers` exited 0.
- `Verification mode: record`. The record (`docs/verif/s77-last-review-leftovers.md`) is complete and has one passing `po-run` row for the unit suite (`bash tests/run.sh`, exit 0). That row proves the unit suite for this code; I did not rerun the full suite.
- The project has no Typecheck, E2E or Build command (all `—`), so none were run.
- The record's "Not proven here" covers other `/dev/fd` spellings and macOS. I probed the spellings myself (see below).

## Plan conformity
- All six tasks are present and match the plan.
- Run interdicts hold:
  - `.claude/`, `.polype/`, the root `AGENTS.md`, `po-architect.md`, `po-drive.md`, `agentic-stories/` and `docs/installation.md` have an empty diff.
  - In `po-bounds.sh`, only the new helper, the two deny lines, the `case` and the comments changed.
  - In ADR-0052, only `superseded-by:` changed.
  - Among existing tests, only the `stories-review.test.sh:34` pin moved, and one function was added to `bounds.test.sh`.
- The new Law 6 wording matches `method/commands/po-architect.md:48`, including the `status: superseded` clause the plan argued for.
- ADR-0053 follows Law 6 as now written: partial supersession, ADR-0052 stays `accepted`, back-link set.

## Tests
- **Floor:** `po-gate floor-guard s77-last-review-leftovers main` exited 0. Nothing was lowered.
- **Budget:** 4 new tests and 1 moved pin, within the budget of 25.
- **Bite:** I changed `method/hooks/po-bounds.sh` three times and ran only `bounds.test.sh` each time. Each change was undone with `git checkout --`, and `git diff --exit-code` confirmed the file was restored.

  | Mutation | Failing tests |
  | --- | --- |
  | Redirect deny prints `$r` again instead of `$(readable "$r")` | 1 (`refusal_messages_are_readable`) |
  | `/dev/fd/1\|/dev/fd/2` removed from the allowlist | 1 |
  | Allowlist widened to `/dev/fd/*` | 1 |

- **Text tests:** each of the three text tests in `tests/final-leftovers.test.sh` checks that the new phrase is present and the old one is gone, so restoring the old text would fail them.
- **Spelling probes:** I fed reviewer-mode JSON to the worktree hook from a throwaway temp dir. `/dev/fd//1`, `/dev/./fd/1`, `/dev/fd/01` and `/dev/fd/1x` all exit 2, so other spellings stay refused. `2>/dev/fd/2 >/dev/fd/1` exits 0.

## Security lens
The allowlist widens by two exact spellings that write to the same place as `/dev/stdout` and `/dev/stderr`. Their one gap, a prior `exec 1>…`, is the same one `/dev/stdout` already has. ADR-0053 states it and ADR-0052 accepts it. Descriptors 3 and above stay refused, and the test checks that. Nothing exploitable is added.

## Findings
- **m1 (minor):** the raw `\036` byte is still printed by a sibling deny in the same function. At `method/hooks/po-bounds.sh:636` (`check_temp_paths`), the "outside the temp dir" message prints `$a` as is. When the substitution sits in the option name and the value is a plain path, the byte reaches the message. Probe: `git -C <probe> log --$(echo o)=/etc/passwd` gives `git log names --^^=/etc/passwd, which lies outside the temp dir`. The fix is `$(readable "$a")` there too. The AC only names redirection targets, and the plan named only `:631` and `:646`, so this is a leftover in the same message family, not a breach.
- **m2 (minor):** in the `po-bounds.sh` header, the edited line 29 (`/dev/stderr, /dev/fd/1 or /dev/fd/2 (ADR-0053). A git call runs where …`) runs well past the wrap width of the surrounding comment block. This is style only.

## Not verified
- **macOS:** I did not run `/dev/fd/1` on macOS, where `/dev/fd` is a separate filesystem rather than a symlink. The allowlist matches the exact string before any resolution, so it should behave the same. A person on macOS can confirm it with `test_refusal_messages_are_readable`.
- **Full suite:** I did not rerun it. I relied on the `po-run` row in the record, whose tree matches this code outside `docs/`.
- **Installed copies:** `.claude/` and `.polype/` are deliberately not refreshed by this story. Until the post-ship refresh, live reviewer sessions still run the old hook and read the old `reviewer.md`. Someone should refresh the installed method after ship.
- **Screens:** the story has no screen, so there is no QA and no design check to require.

Max severity: minor
Ship allowed: yes
