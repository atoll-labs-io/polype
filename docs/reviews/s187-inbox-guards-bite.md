# Review — s187-inbox-guards-bite

[Story](../stories.md) · [Plan](../plans/s187-inbox-guards-bite.md) · [Verification](../verif/s187-inbox-guards-bite.md)

Method version: 0.3.1

Review status: complete
Reviewed tree: 31c002d7136aa0af84f6c3f4464d9547b7af00be
Fix loop: 0
Lenses run: Security (content: the path checks that keep a sensitive context, the decision inbox and `Private folder` out of the repository, in `po/src/inbox/add.rs` and `po/src/record/security.rs`); Dependencies (paths: `po/Cargo.toml` and `po/Cargo.lock`, which only bump `po`'s own version with no dependency entry changed)

## Scope
`git diff --name-only main...story/s187-inbox-guards-bite` lists 14 paths. All of them are covered by the `Owns` of s187: `bin/polype`, `docs/interface-agent.md`, `po/Cargo.toml`, `po/Cargo.lock`, `po/src/inbox/{add,mod,rewrite}.rs`, `po/src/output.rs`, `po/src/record/security.rs`, `tests/inbox-guards-bite.oracle.test.sh` and `tests/inbox-guards-bite.test.sh`. The other three are the story's own research, plan and record, which are in scope by construction. `git worktree list` shows no other story branch running: `.claude/worktrees/framing-m22` is on `fix/qa-deadline-wording`. s188 also owns `bin/polype`, but it has no worktree yet.

## Evidence relied on
- `po-gate verif-current s187-inbox-guards-bite`: exit 0. `Verification mode: record`, and the record is complete. The last `Unit suite` run (`bash tests/run.sh`) exited 0 on the recorded tree. The project's `Typecheck` command is `—`, so the project has none. I did not rerun the suite. The record's "Not proven here" leaves the mutation proofs and the contract prose to the review; both are done below.
- `po-gate oracle-intact`: exit 0. `po-gate floor-guard ... main`: exit 0, nothing lowered.
- `QA stage: —`: no QA is required.
- Baseline: the story's two test files with `CARGO_TARGET_DIR=/tmp/tmp.IpMOtCeCvA/target`, 8 passed.

## Plan against diff
- Tasks 1 to 5 are all present.
- Rewriting `kept_out_of_git` to return a `Result` keeps the accept and refuse decision exactly as before: `Outside` and an ignored `InRoot` give `Ok`, and `Elsewhere`, `Unverified` and an unignored `InRoot` give `Err`.
- The sensitive-context check is the same (`absolute && Outside`).
- Error codes and exit codes are unchanged.
- Run interdicts hold:
  - `decision.rs`, `context/`, `method/hooks/`, `tests/answer-comes-back.test.sh` and `tests/record-review-loose-ends.test.sh` are untouched.
  - The lock name, `LOCK_TRIES` and `LOCK_PAUSE` are unchanged.
  - No new dependency.
- No `not_built` or `not-built` is left in `po/`, `method/`, `tests/` or `bin/`.

## Bite (mutants built with `CARGO_TARGET_DIR=/tmp/tmp.IpMOtCeCvA/target`; after each one, `git checkout --` the file and `git diff --exit-code` confirmed it was restored; the final `git status --porcelain` is empty)

| Mutation | Files rerun | Result |
| --- | --- | --- |
| A. Lock not exclusive: `rewrite.rs:95` `create_new(true)` → `create(true)` | oracle | `held_lock_is_refused_every_time` fails 5 runs of 5 |
| B. Written-vs-folded comparison off: `add.rs` `if as_written == resolve(...)` → `if true` | oracle + task | 2 fail: `written_and_folded_paths_agree`, `unverified_path_says_so` |
| C. `Elsewhere` → `Outside` in `resolve` | oracle + task | 3 fail: `path_in_an_outside_worktree_is_refused`, `inbox_in_an_outside_worktree_is_refused`, and `not_built_is_gone` (the unused variant raises a dead-code warning) |
| D. `kept_out_of_git` accepts `Place::Elsewhere` | oracle + task | 1 fails: `inbox_in_an_outside_worktree_is_refused` |
| E. Framing guard of `Decision::stale` (#364): `decision.rs:87` → `if false` | task | `blocks_entry_not_of_story_form_is_never_stale` fails |

All three bite proofs the story and the lead asked for (A, B, E) hold, and so do the two extra ones the plan lists (C, D).

## Tests
- Oracle: `po-gate oracle-intact s187-inbox-guards-bite` → exit 0

## Findings
- **minor** — `docs/interface-agent.md:271`: the `record review` row still describes the `private-folder-unusable` refusal as "réglage dans le dépôt ou relatif". It does not mention the unverifiable case that rows 179, 180 and 197 now name, although `po/src/record/security.rs:225` refuses that case with the same code. The contract is incomplete for that one verb.
- **minor** — `po/src/inbox/add.rs:123`: the `Unverified` reason always ends with "write it without `..`". But `resolve` also returns `Unverified` when `canonicalize` fails on an ancestor that exists (`add.rs:162`), and for such a path that advice does not apply.

## Not verified
- The full unit suite was not rerun: I relied on the record, which is current for this code.
- The held-lock mutant was run 5 times, not more. The test plants the lock file, so its result does not depend on timing.
- Running `po answer` against a lock held by a real concurrent `po`, rather than a planted file, is only covered by the existing `test_parallel_answers_record_one`, which I did not run.
- I judged the French wording of the contract rows by reading only.
- The repository's real decision inbox was not read, as instructed.

Max severity: minor
Ship allowed: yes
