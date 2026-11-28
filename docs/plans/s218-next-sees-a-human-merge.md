---
validated: yes
---
# Plan — s218-next-sees-a-human-merge

[Story](../stories.md) · [Research](../research/s218-next-sees-a-human-merge.md)

Branch `story/s218-next-sees-a-human-merge`. Read `docs/research/s218-next-sees-a-human-merge.md` first; this plan builds on it without repeating it.


Where the fetch lives is drafted in [ADR-0141](../decisions/ADR-0141-po-next-remote-recupere-origin-avant-de-lire.md) (`proposed`), options ranked A (`po next --remote` fetches), C (forge merged state), B (`/po-drive` fetches). The tasks below are written for **A**. Under B, task 1 moves to `method/commands/po-drive.md` and `test_human_merge_is_seen` leaves the oracle; under C, task 1 reads `merged_at` in `po/src/trust/forge.rs` instead of fetching. Tasks 2 to 6 hold for every option.

Track: full, although `Story track: auto` and complexity 3 ≤ `Flow threshold` 3 allowed the short one: the escalation signal "technical choice that deserves an ADR" is present (research, first structuring fact).

## Story
The owner wants `po next` to read a fresh forge state and the effective `Ship confirmation`, so a pull request merged by hand no longer reads `merge waiting` and a collaborative repository really waits for its person (#420, #437, #389).
- `human_merge_is_seen` — after a person merged a lane's pull request, `po next --remote` no longer says `merge waiting` for it, with no fetch run by hand.
- `effective_confirmation_drives_merge_waiting` — `merge waiting` follows the effective `Ship confirmation` (that of `po ship forge`), not the written line.
- `version_raised` — po's version goes up (ADR-0122).

Why the fetch lives in `po` (option A) rather than in `/po-drive`: every reader of `po next --remote` gets the fresh answer — the driver and the external agent of `docs/interface-agent.md` — with no prose rule a model may skip, a script can check it, and the proof stays ADR-0131's title on `origin/<target>` on every forge. Its cost, a git write from a read verb, is what ADR-0141 puts to the owner.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `fetch -q origin` from `po next --remote` | in this repository: `ship::git::run` (`po/src/ship/git.rs:26`), as `po ship land` calls it (`po/src/ship/land.rs:309`); one `pub(crate)` wrapper only | — |
| `origin` exists | in this repository: `project.git(&["remote", "get-url", "origin"])`, as `po/src/next/open.rs:40` | — |
| effective `Ship confirmation` | in this repository: `ship::forge::read` (`po/src/ship/forge.rs:465`) + `ship::effective` (`po/src/ship/mod.rs:43`), exposed by one `pub(crate)` function | — |
| `awaits_merge` on `Lane` and the override of the `merge-waiting` stop | new code, a field and one function in `po/src/context/lanes.rs` | the condition exists only inlined in `stops` (`lanes.rs:358-365`) with the line's value baked in; it is split, not copied |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/next-sees-a-human-merge.oracle.test.sh` | `3538480208 6327` |

| Criterion | Test |
| --- | --- |
| `human_merge_is_seen` | `test_human_merge_is_seen` — a bare origin behind a github.com URL (`insteadOf`); a person squash-merges from another clone; `po next` without the option still waits and leaves `origin/main` where it was; `po next --remote` answers `ship` `landed` |
| `effective_confirmation_drives_merge_waiting` | `test_effective_confirmation_drives_merge_waiting` — line `automatic` + a CODEOWNERS naming a team on origin (collaborative) → `wait` `merge waiting` under `--remote`, `ship` offline; line `human` on a solo forge (gh double) → `ship` `ship-allowed passes` under `--remote`, `wait` offline |
| `version_raised` | `test_version_raised` — `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype` agree, above 0.13.1 |

Run once on the current code (2026-11-28): the three fail where expected, at the `--remote` steps and the version; the fixture steps before them pass.

## Tasks
1. [x] **Fetch before reading, under `--remote` (option A).** In `po/src/ship/git.rs` add `pub(crate) fn fetch_origin(root: &Path) -> bool` (`run(root, &["fetch", "-q", "origin"]).ok()`), and rewrite its module doc so it names `po next --remote` as the one caller outside `po/src/ship/`. In `po/src/next/mod.rs` `main`, under `remote`, before `Context::read`: when `project.setting("Merge mode")` is `pr` and `project.git(&["remote", "get-url", "origin"])` is `Some`, call it and ignore the result — a failed fetch reads the local refs as today. Rewrite `po/src/project.rs:18-19` so it no longer says `po` never fetches (the launcher `git()` itself stays read-only). — `test_human_merge_is_seen` fails if the fetch is missing (still `merge waiting`) or runs without `--remote` (`origin/main` moves).
2. [x] **Split the `merge-waiting` condition.** In `po/src/context/lanes.rs` add `pub awaits_merge: bool` to `Lane`: `Ship allowed: yes`, `Merge mode: pr`, not landed, `refs/remotes/origin/story/<id>` present — the condition of `:358-365` without the confirmation. `stops` pushes `MergeWaiting` when `awaits_merge` and the line reads `human`, exactly as today. Add `pub fn confirm_merges(lanes: &mut [Lane], effective: &str)`: for each lane with `awaits_merge`, drop its `MergeWaiting` stop, push it back last when `effective == "human"`, and reset `blocked_by` to the first stop's code. — the offline steps of `test_effective_confirmation_drives_merge_waiting` and the suites `driver-next-action*`, `ship-order-and-closed-pr*` fail if the offline reading moves.
3. [x] **Read the effective value under `--remote`, only when a lane awaits a merge.** In `po/src/ship/mod.rs` add `pub(crate) fn effective_confirmation(project: &Project, target: &str, line: &str) -> String` (`effective(line, forge::read(project, target).verdict()).0`). In `po/src/next/mod.rs` `main`, make `context` mutable; under `remote`, when some lane has `awaits_merge`, `context.target` is `Some` and the `Ship confirmation` line is set, call it and `lanes::confirm_merges` before `closed_pull_requests` and the routing. Re-export what `next` needs through `crate::context` as the module already does for `Lane`. — `test_effective_confirmation_drives_merge_waiting` fails in one direction or the other if the line is still read, or if the stop is dropped whatever the value.
4. [x] **The story's own tests**, in `tests/next-sees-a-human-merge.test.sh`, with the oracle's helpers sourced in a subshell: `test_unreachable_origin_changes_nothing` — `origin` rewritten by `insteadOf` to a path that does not exist: `po next --remote` exits 0 with the same actions as `po next`; `test_forge_read_only_when_a_merge_waits` — a lane at stage `execute` under `Merge mode: pr`, a gh double that logs its calls: `po next --remote` makes no `gh api` call for `user` or `collaborators`. — each fails if task 1 lets a fetch failure through or task 3 reads the forge on every run.
5. [x] **Raise po's version** to `0.13.2` in `po/Cargo.toml:3`, the `po` entry of `po/Cargo.lock` and `POLYPE_VERSION` in `bin/polype:28`; `PO_SUMS` stays as it is. — `test_version_raised`.
6. [x] **Full suite once, at the end**, through `po-run --story s218-next-sees-a-human-merge --label 'unit suite' -- 'bash tests/run.sh'` (`Full suite: execute-end`; `Typecheck: —`, the build inside `tests/run.sh` compiles `po`). `tests/ship-order-and-closed-pr.oracle.test.sh` and `tests/ship-order-and-closed-pr.test.sh` must pass unchanged; they now fetch from a github.com URL that does not exist: report their time in the verification record if it grows, never edit them.

## Scene viewpoints
—

## Run interdicts
- `docs/interface-agent.md` ends with an empty diff: not in `Owns` (gap reported to the lead; its `next --remote` row should name the fetch and the effective value once the `Owns` allows it).
- `method/commands/po-drive.md` and `method/word-budget` end with an empty diff under option A.
- `tests/ship-order-and-closed-pr.oracle.test.sh`, `tests/ship-order-and-closed-pr.test.sh`, `tests/driver-next-action.oracle.test.sh` and `tests/fixtures/driver-cases/` end with an empty diff.
- `po/src/state/`, `po/src/run/` and `po/src/project.rs`'s `git()` body unchanged: `po state` keeps reading the line; only `project.rs:18-19`'s comment changes.
- The JSON of `po next` keeps its shape: no new field, no new reason.
- `fetch` appears in `po/src/` only through `po/src/ship/git.rs` (`grep -rn '"fetch"' po/src`); no `pull`, `push` or `commit` added outside `po/src/ship/`.
- `PO_SUMS` in `bin/polype` unchanged.

## The pivot
The forge reading is applied after `Context::read`, by rewriting the `merge-waiting` stop of the lanes that await a merge; everything downstream (`lane::ship` `:211`, the serial order `:218`) reads `blocked_by`. Ways it could be wrong:
- `blocked_by` left stale after `confirm_merges` while `stops` changed: a lane with an earlier stop (Max attempts) must keep it first — compare `blocked_by` with `stops.first()` for every lane.
- The forge read only when a lane awaits a merge: `awaits_merge` must not depend on the line, or a line `automatic` on a collaborative forge never triggers the reading — the first half of the second oracle test covers it.
- The fetch placed after `Context::read` would leave `Landed` stale for this run — compare the order in `next::main` with the oracle's `ship` `landed`.

## Files touched
`po/src/ship/git.rs`, `po/src/ship/mod.rs`, `po/src/next/mod.rs`, `po/src/context/lanes.rs`, `po/src/context/mod.rs` (re-export only, if needed), `po/src/project.rs` (comment), `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `tests/next-sees-a-human-merge.test.sh`; already written: `tests/next-sees-a-human-merge.oracle.test.sh`, `docs/research/…`, this plan, `docs/decisions/ADR-0141-…` (status set by `/po-plan`).

## Test strategy
Five tests, within `Test budget` 25, all at the adapter layer that `po` is tested at (bash through the release binary, no Rust unit tests in this crate). Oracle: three, one per criterion. Implementer: two, each for a rule no oracle test bites — a fetch failure changes nothing, and the forge is read only when a merge waits. Forge tools are doubles named by `PO_GH` and `PO_CURL`, origin a local bare repository behind `insteadOf`, so no test of this story reaches a forge or the network. No visual check.

## Done when
One commit `s218-next-sees-a-human-merge: …` landed through a pull request; the full suite green, the two `ship-order-and-closed-pr` files unchanged and passing; a review with no open critical finding; ADR-0141 accepted or rewritten by the owner before execution.
