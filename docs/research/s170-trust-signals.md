# Research — s170-trust-signals

[Story](../stories.md)

## Structuring facts
- **False assumption 1, `Owns`**: the story says to add the duration to a `po-run` row "without changing what the gate reads", proven by "the existing tests of `po-gate` and `po-run`". That cannot be done inside `Owns`. `po-gate` reads a run row by position from both ends (`method/hooks/po-gate.sh:175-178`: tree `cell[n-1]`, exit `cell[n-2]`, command `cells 2..n-3`), so any new column moves what it reads. `tests/execute.test.sh:58` pins the header `| Check | Command | Exit | Tree | Time (UTC) |`. `tests/run-ledger.test.sh:48`, the existing test of `po-run`, pins the last cell to exactly `^…T..:..:..Z$`. The smallest way through puts the duration in the Time cell (`2026-11-14T10:00:30Z (30s)`), and that changes `tests/run-ledger.test.sh:48`, which is outside `Owns`. `tests/verification*.test.sh`, which the story names, matches no file.
- **False assumption 2, `Owns`**: `tests/state-as-json.oracle.test.sh:136-137` asserts `shipped == null` on a fixture with no story landed. Once `shipped` is computed, that fixture gives `[]`, so the assertion must change. The file is outside `Owns`; s168, s169, s174 and s175 each listed it.
- Root cause of #205: `trust::shipped` returns `None` unconditionally (`po/src/trust/mod.rs:39-41`), and `state_options` refuses every argument, `--all` and `--remote` included (`po/src/trust/mod.rs:31-37`). `po-run` writes no duration (`method/hooks/po-run.sh:61`).
- Every input already exists. The context carries the stories with their milestones, the landed set with each commit and the current milestone (`po/src/context/mod.rs:98-112`). `po record` stamps `Method version:` and the `- Oracle:` line (`po/src/record/compose.rs:106-122`, `po/src/record/mod.rs:184-197`). Since s167, reviews carry `Fix loop:`, `## Not verified` and `Max severity:` (`method/templates/review.md:10,60,63`).
- #286 cannot ride in this story: it needs `po/src/next/`, its fixtures and `tests/driver-next-action*` (s175's files), and it removes an exception from `po-drive.md` (s173's). It needs a story of its own after s170 and s173, which reuses the forge reader this story puts in `po/src/trust/forge.rs`. #278 is also outside `Owns` (`po/src/record/`, `po/src/next/lane.rs`) and needs its own story.

## Diagnostic
Reproduction: `po` was built from this worktree (`CARGO_TARGET_DIR=/tmp/s170-po-target`). `po state` on this repository printed `"shipped":null` with `milestone {"id":"M21","stories":12,"shipped":8}`. `po state --all` and `po state --remote` each exited 2 with `{"error":"unknown-option","message":"po state takes no option --all"}` (or `--remote`). A `po-run` row ends `| 2026-11-14T09:27:49Z |`, with no duration. The oracle written for this plan fails all four tests on this code (0 passed, 4 failed, 2026-11-14), each for one of these reasons.

| Hypothesis | Refuting observation | Result |
| --- | --- | --- |
| H1 — `shipped` is never computed | `po/src/trust/mod.rs:39-41` returns `None` whatever the context | kept |
| H2 — the record lacks a duration to read | `po-run.sh:61` prints the label, command, exit, tree and `date -u` only; the command is never timed (`:51-53`) | kept |
| H3 — the reviews lack the fields to read | `docs/reviews/s169-run-from-outside.md:5,10,55,87` and `s175…:5,10,66,106` carry `Method version:`, `Fix loop:`, `- Oracle:` and `Max severity:` | discarded |

## Story
For each story of the current milestone that has shipped, `po state` returns `shipped[]` with `story`, `commit` and `trust`. `trust` holds `checks`, `oracle`, `fix_loops`, `max_severity`, `not_verified`, `method_version`, `track`, `duration_s` and `cost_usd`. `--all` covers every shipped story. `--remote` alone asks the forge for `checks`. A value that cannot be read is `null`. `po-run` notes each check's duration, and `duration_s` is derived from it. Criteria: `shipped_stories_carry_trust`, `unknown_is_null_never_guessed`, `checks_are_read_only_on_request` and `duration_comes_from_the_record`, all four with an oracle.

## Current code
- `po/src/trust/mod.rs:9-26`: `Trust` (eight `Option` fields, `duration_s: Option<f64>`) and `Shipped { story, commit, trust }`. Only this folder may reshape them (`:1-2`). `StateOptions {}` is empty (`:29-30`).
- `po/src/state/mod.rs:35-38`: options are parsed by `trust::state_options`, and an `Err` becomes exit 2 `unknown-option`. `:85` calls `trust::shipped(context, options)`.
- `po/src/context/lanes.rs:48-95`: `Landed` holds the subjects `<id>:` (or `s<n>:`) on `Target branch` and `origin/<Target branch>`. `commit(id)` (`:91`) returns the **full** hash of the most recent landing.
- `po/src/context/stories.rs:6-18`: `Story { id, …, milestone: Option<String> }`, in file order (`Stories.list`). `po/src/context/framing.rs:95-104`: `milestone(…)` is the first `## M…` section holding a story not landed, and its `id` matches `Story.milestone`.
- `method/hooks/po-run.sh:51-63`: runs the command, then appends `| label | `cmd` | exit | tree | <UTC time> |`. The time is taken after the command, so it is the end time.
- `po/src/record/mod.rs:184-197`: inserts `- Oracle: `po-gate oracle-intact <id>` → exit <n>` right after the first `## Tests` of the answer, with the gate's output indented two spaces. `compose.rs:106-122`: each recorded block starts with `Method version: <v>`. A fix run appends a new block to the same file.
- `po-gate oracle-intact` prints nothing when the oracle is intact, `<path>: changed, logged in ## Oracle changes — …` per logged change, and `po-gate: <id> has no oracle: …` without one (`method/hooks/po-gate.sh:604-660`).

## Attachment points
- `po/src/trust/mod.rs`: the options, `shipped`, and the types (`track` added, `duration_s` an integer).
- New files in `po/src/trust/`: reading the landed files, parsing the review, plan and record, and the forge (`forge.rs`).
- `method/hooks/po-run.sh:51-61`: time the command and write the duration in the Time cell.
- `docs/interface-agent.md:33`, `:89`, `:92-106`: the second bound, `shipped` no longer `null`, and the signals table.
- Outside `Owns`, pending the correction: `tests/run-ledger.test.sh:48` and `tests/state-as-json.oracle.test.sh:136-137`.

## Verified interfaces
- `pub fn shipped(_context: &Context, _options: &StateOptions) -> Option<Vec<Shipped>>` (`po/src/trust/mod.rs:39`), and `pub fn state_options(args: &[String]) -> Result<StateOptions, String>` (`:31`).
- `pub fn commit(&self, id: &str) -> Option<&str>` (`po/src/context/lanes.rs:91`), `pub milestone: Option<Milestone>` (`po/src/context/mod.rs:110`) and `pub struct Milestone { pub id, … }` (`framing.rs:24-28`).
- `pub fn git(dir: &Path, args: &[&str]) -> Option<String>` (`po/src/project.rs:20`) sets `GIT_OPTIONAL_LOCKS=0` and nulls stdin. A batch read needs its own `Command`.
- The double pattern: `PO_CLAUDE` read in `po/src/run/session.rs:39-44`, with `claude` as the fallback.
- `chrono` 0.4 (`clock`, `std`) is in `po/Cargo.toml`, and `DateTime::parse_from_rfc3339` needs no other feature. No crate may be added (ADR-0118).
- The forge: `/po-ship` reads `git remote get-url origin`, where the host `github.com` means GitHub (`method/commands/po-ship.md:27`), and calls `gh api` pinned with `--hostname github.com` (`:29`, ADR-0083). `gh api repos/<o>/<r>/commits/<sha>/check-runs` returned `{"total_count":1,"check_runs":[{"status":"completed","conclusion":"success"}]}` for `acae0a2`. `ci.yml` runs on every push to `main`, so a landed commit has its own checks.

## Traps
- `docs/reviews/s169-run-from-outside.md:135,138`: the fix-run block holds **two** `- Oracle:` lines. The first is `po`'s, followed by the logged change; the second is an echo from the answer. The last one would read `intact` where the truth is `changed-with-reason`. Read the first `- Oracle: `po-gate oracle-intact` line after the last `Method version:` line.
- A review from before s167 has no `Method version:` line. Its `- [x] Oracle:` lines were written by a model, so `oracle` is `null` there. It is never inferred from prose.
- `tests/state-as-json.oracle.test.sh:157-193`: `po state` (no option) must run no `gh`, and no git command that writes or asks a remote, and must answer in under a second on this repository. Read every landed file with one `git cat-file --batch` (allowed by that list) rather than three `git show` per story: `--all` covers more than 150 stories here.
- `tests/verbs-read-project-context.oracle.test.sh:20` drops `.shipped` before comparing, so it is unaffected. No other test reads `shipped`.
- Landing in `pr` mode is a rebase merge, so the landed commit is the one on `main`, and the checks on it come from the `push` run of `ci.yml`.
- `tests/execute.test.sh:58` (header) and `po-gate.sh:175-178` (positions) stay untouched: the duration rides in the Time cell only.
- No `#[cfg(test)]` in the crate: every test is bash, through the binary built by `tests/run.sh`.

## Open questions
- `oracle` after `exit 1` or `2`, or after `not run`: the plan returns `null`, which is outside the contract's three values. A shipped story with an oracle changed without a reason is unlikely, since the review blocks it.
- `checks` while a check run is not `completed`: `null`. On a non-GitHub forge, or when `gh` is missing or fails: `null`, with no warning. The plan keeps the contract's values.
- `duration_s` spans from the start of the first `po-run` check (its time minus its duration) to the end of the last one, fix runs included. It is not research or planning time. `null` when the first row has no duration.
- `--remote` with `--all` makes one forge call per shipped story. No time bound is claimed with `--remote`.
- `shipped` is `[]` when no milestone is current (all landed); `--all` still lists them.
- Where to read the cost: no file holds it, so `cost_usd` stays `null` and the lead is told.

## Complexity
Story 3 → 3. One verb folder filled, one line of bash, one contract paragraph. The spread is the two `Owns` gaps, a one-line change in each of two tests.

## Split
—
