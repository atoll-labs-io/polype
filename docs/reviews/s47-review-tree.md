# Review: s47-review-tree

Diff reviewed: `git diff main...story/s47-review-tree` (commit 3a451a5), by a reviewer that did not write it.

Review status: complete
Fix loop: 0
Reviewed tree: aa0ef833a6169f3451d471d8066ea5d575f9a16f

I took the tree before reading the diff and again before answering. Both reads gave the same hash, and the worktree was clean at the end (`git diff --exit-code` passed).

## Scope (`Owns`)
- All 13 non-evidence paths in the diff are in the s47 `Owns` line: `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/commands/po-review.md`, `method/agents/reviewer.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/AGENTS.md`, the four `tests/*.test.sh` files and `docs/defauts.md`.
- The other three paths are this story's own evidence: `docs/research/`, `docs/plans/` and `docs/verif/` for s47.
- One other lane is running, `s50-implementer-bounds`. Its `Owns` and its actual diff (`method/agents/implementer.md`, `method/hooks/po-bounds.sh`, `bin/polype`, `docs/installation.md`, `tests/bounds.test.sh`) do not overlap with s47.
- The plan's run interdicts all hold:
  - nothing changed under `.polype/`, `.claude/`, the root `AGENTS.md` or `docs/reviews/`;
  - `grep -c "':(exclude)docs'" method/hooks/po-gate.sh` prints `1`;
  - the tools and the `:30` prompt of `po-review.md` are unchanged;
  - the protected `po-drive.md` rows and the `:58` prose are unchanged;
  - `po-flow.md`, `po-orchestrator.md`, `po-execute.md` and `review-antihallu` are untouched.

## Evidence reused
- `Verification mode: record`. `po-gate verif-current s47-review-tree` exits 0, and a direct check (`git diff --quiet b9e960ad… HEAD -- . ':(exclude)docs'`) also exits 0.
- The record is complete: `bash tests/run.sh` exited 0 with 240 passed. I relied on it and did not rerun the suite.
- Type check, E2E and Build are `—` in `AGENTS.local.md`: the project has none of them, and I substituted nothing.
- I read the record's "Not proven here" section. Its points are carried into the list of things not verified below.

## References checked
- `first_hash`, `tree_exists` and `code_matches` are defined in `po-gate.sh` and called by both `ship_allowed` and `verif_current`.
- `verif_current` still produces its four refusal messages. Its old local `root` is gone with no remaining use.
- `refuse … || return 1` chaining is preserved under `set -e`.
- The test helpers used all exist (`scratch_repo`, `section_of`, `contains`, `require_file`, `$TPL`, `$AGENT`, `$CMD`, `$METHOD`).
- The `po-ship.md` line numbers cited by the plan and research match the files.

## Against the plan
Tasks 1 to 7 are all present and match the plan's decisions:
- the first 40-hex `Reviewed tree:` line is the one that counts;
- the check order is file, then verdict, then a usable hash, then tree exists, then code matches;
- the reviewer captures the tree and `/po-review` gets no Bash;
- the new drive row sits above the ship row.

I found no unrequested change. Defect 32 is now `corrigé par s47`.

## Test bite
Each mutation was made in `method/hooks/po-gate.sh`, checked with `bash tests/run.sh gate.test.sh` only, then undone and confirmed with `git diff --exit-code`.

| Mutation | Tests that failed |
| --- | --- |
| `ship_allowed`: `{ tree_exists && code_matches; }` reduced to `{ tree_exists; }` | 1 (`ship_allowed_fails_when_code_changed_after_review`) |
| `code_matches`: removed `':(exclude)docs'` | 3 (`ship_allowed_ignores_docs_changes_after_review`, `verif_current_ignores_docs_changes`, `verif_current_passes_when_tree_matches`) |
| `first_hash`: `\{40\}` relaxed to `\{7,40\}` | 1 (`ship_allowed_fails_without_reviewed_tree`) |

- The test budget holds: 6 new tests plus 3 adjusted fixtures, against a budget of 25.
- None of the new tests is one of the six kinds that prove nothing. The gate tests run the real script on scratch repositories, and the fixture's tree comes from `git rev-parse`, not from a value made up to match the check.

## Values and neighbours
- `docs/` is excluded from the comparison. This is backed by `/po-ship` Step 1 committing the review after the gate runs (`po-ship.md:25`).
- `HEAD` as the comparison point is backed by "from the worktree" (`po-ship.md:18`) and by the new CI note in the hook's header.
- `po-flow.md:77` and `po-orchestrator.md:61` defer to `/po-ship` Step 0, so they inherit the new check without any change.
- `po-execute.md:26` only reacts to `no`, which is consistent: a favourable but stale review goes to review, not to a fix run.
- The blocked report that `po-review.md:35` writes by hand carries no tree. That is harmless because its `Ship allowed: no` is refused first.

## Findings

### Critical
None.

### Major
None.

### Minor
1. **The "first line wins" rule for `Reviewed tree:` is not tested.** Changing `head -n 1` to `tail -n 1` in `first_hash` would fail no test, because every fixture has a single `Reviewed tree:` line. The plan's pivot names this exact case (a report quoting an older tree), so a one-line fixture with two lines would pin it. The same gap already existed for `Tree:` in `verif_current`.
2. **The `/po-drive` "no `cd`" gap, already flagged in the research.** The new resume row and the `/po-status` column both rely on `po-gate ship-allowed`, which compares against the `HEAD` of the directory it runs in, and `/po-drive` never says how a lane's gate runs inside the worktree. This was there before s47 and affects every gate; I record it here only so it stays visible.

## Not verified
- **`bin/ks-overlap` against gstack (`28f1385`) and agent-skills (`1401c8b`)**, which M6 requires before the PR. Neither source is on this machine and I did not run it. Someone with both sources checked out should run `bin/ks-overlap <src>` for each before shipping. The Killer SaaS overlap test passed as part of the recorded suite.
- **A real reviewer actually doing the two `rev-parse` captures.** This is method text only; no test runs a reviewer.
- **The installed copies** (`.polype/hooks/po-gate.sh`, `.claude/`, the root `AGENTS.md`) still hold the old gate. This story's own ship goes through the old gate, and the new one only applies after `bin/polype-dev-install .`. Someone should reinstall after the merge, and accept that lanes holding reviews without `Reviewed tree:` will then be refused, which is the intended effect of criterion 4.
- **The CI behaviour on a merge ref.** It is only documented in the hook's header and was not exercised.
- **The `/po-drive` resume row and the `/po-status` stale display.** I checked them as text only; I did not run a driver session.

Max severity: minor
Ship allowed: yes
