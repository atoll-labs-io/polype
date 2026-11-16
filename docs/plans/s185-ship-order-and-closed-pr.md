---
validated: yes
---
# Plan — s185-ship-order-and-closed-pr

[Story](../stories.md) · [Research](../research/s185-ship-order-and-closed-pr.md)

Branch `story/s185-ship-order-and-closed-pr`. Read `docs/research/s185-ship-order-and-closed-pr.md` first; this plan builds on it without repeating it.

## Story
Fixes #278 and #286. `po record review` writes `Recorded: <date with offset>` under the `Method version:` stamp of each block, never twice in a block on a re-record (`record_dates_each_verdict`). `po next` orders ships by the last such line of each review (`ships_follow_the_written_date`), by the file's modification time when there is none (`older_reviews_fall_back`). `po-gate ship-allowed`, `po-gate findings-shape` and the trust signals read a dated review as before (`gates_read_the_block_as_before`). `po next --remote` gives `ask`, reason `pull request closed`, to a lane whose pull request was closed without a merge; without the option no forge is asked (`closed_pr_goes_to_a_human`). `/po-drive` loses its closed-PR rule and no word (`drive_no_longer_decides_it`). `po` goes 0.4.0 → 0.5.0 (`version_goes_up`).

**The two choices the story leaves to the plan, settled without an ADR.** The option is `--remote`: d-0009 (owner's variant, recorded in `consumed.ref` and #286) asks for "an explicit option such as `--remote`, built once with the forge reading of s170", and `po state --remote` already means "ask the forge" (`docs/interface-agent.md:33`). `/po-drive` passes it: criterion `drive_no_longer_decides_it` removes the prose rule, and a drive running `po next` without the option would then never see a closed pull request; `po next --remote` itself asks nothing under `Merge mode: local` or off GitHub, so the drive passes it unconditionally. `/po-execute` keeps `po next` without option (ADR-0120): it never ships.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The pull request's state | already here: `Forge`, `gh_program`, `--hostname github.com` (`po/src/trust/forge.rs:11-41`); one method added beside `checks` | — |
| The date written | dependency installed: `chrono::Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)`, the one-liner of `po/src/inbox/rewrite.rs:29-31`, which is private to `inbox` (outside `Owns`) | the repository's copy is not reachable from `record` |
| The date read | dependency installed: `chrono::DateTime::parse_from_rfc3339`, as `po/src/trust/signals.rs:141` | — |
| Two routing cases, one oracle file | already here: the harness and `replay` of `tests/driver-next-action.oracle.test.sh:24-217` and `tests/next-waits-on-dependencies.oracle.test.sh:9-26`; the record fixture of `tests/record-writes-reports.oracle.test.sh:37-85` | — |

## Acceptance tests
Each criterion but one is the first case of the owner's sorting of 2026-11-13: `po record`, `po next`, `po state` and `po-gate` already produce what it fixes, so its test reads their output on a throwaway repository. `drive_no_longer_decides_it` speaks to a model: no oracle test and no phrase test, the reviewer judges it by reading, and it is a candidate for a `po-eval` control arm (#208); its word clause is held by the ceiling task 5 lowers.

| Oracle file | cksum |
| --- | --- |
| `tests/ship-order-and-closed-pr.oracle.test.sh` | `1193026906 9244` |
| `tests/fixtures/driver-cases/ships.cases` | `2186642912 3826` |

| Criterion | Test |
| --- | --- |
| `record_dates_each_verdict` | `test_record_dates_each_verdict` (one dated line with offset; two loops → two; re-recorded onto itself → each `Method version:` block holds exactly one `Recorded:`) |
| `ships_follow_the_written_date` | `test_ships_follow_the_written_date` (replays `case_ships_05_written_date_orders_the_ships`: dates whose offsets invert a text compare; mtimes reversed, then a copy) |
| `older_reviews_fall_back` | `test_older_reviews_fall_back` (replays `case_ships_06_undated_review_falls_back`, then moves the undated file's mtime past the written date) |
| `gates_read_the_block_as_before` | `test_gates_read_the_block_as_before` (a recorded, dated review: `ship-allowed` and `findings-shape` exit 0; landed, `po state --all` gives the trust values the block says) |
| `closed_pr_goes_to_a_human` | `test_closed_pr_goes_to_a_human` (`PO_GH` double; without `--remote`: no call, `merge waiting`; with it: `ask pull request closed`, open stays `merge waiting`, under `automatic` the next lane ships) |
| `drive_no_longer_decides_it` | — read by a model, judged in review; word clause by task 5 |
| `version_goes_up` | `test_version_goes_up` (three places agree, at least 0.5.0) |

Run on the code as it stands, every oracle test fails, each on its own clause (no dated line; s02 ships first; `unknown-option`; 0.4.0). The gates part of `test_gates_read_the_block_as_before` was run with a dated line inserted by hand: it passes on today's gates, as it must.

## Tasks
1. [x] **Dated block** — `po/src/record/compose.rs`: `first_write` and `append` take `recorded: Option<&str>` and write `Recorded: <date>` on the line right after `Method version: <v>` when it is `Some`; `strip_own_header` also treats a line starting `Recorded:` as header. `po/src/record/mod.rs`: the date is taken once, before `text_with` (`:230`), `Some` for `Kind::Review` only, so the two writes of a review with security findings (`:250`, `:265`) carry the same date and QA reports stay as they are. `method/templates/review.md:5`: the note names it — "`Method version:`, `Recorded:` and the `Oracle:` line" (556 → 557 words, both ceilings, 557 and 558, hold; none moves). Tests: `test_record_dates_each_verdict`, `test_gates_read_the_block_as_before`; `tests/record-writes-reports*.test.sh`, `tests/security-findings-stay-private*.test.sh`, `tests/record-review-loose-ends*.test.sh`, `tests/review-header-recorded.oracle.test.sh` stay green unchanged.
2. [x] **Ship order** — `po/src/next/lane.rs` `reviewed_at` (`:199-204`): read `docs/reviews/<id>.md`; the line right after its last `Method version:` line, when it starts `Recorded:` and its value parses with `DateTime::parse_from_rfc3339`, gives `(timestamp, 0)` (a `Recorded:` quoted inside an answer's body is never read); otherwise the modification time as `(secs, nanos)` since the epoch; the key stays `(missing, Option<(i64, u32)>)` so a lane with neither sorts last, and `min_by_key` (`:187`) is otherwise unchanged. The doc comment says what it reads. Tests: `test_ships_follow_the_written_date`, `test_older_reviews_fall_back`, the four existing `ships.cases` through `test_every_routing_case_is_a_fixture`.
3. [x] **Pull request state** — `po/src/trust/forge.rs`: `pub fn pull_request_closed(&self, branch: &str) -> Option<bool>` runs `gh_program()` with `api --hostname github.com repos/<repo>/pulls?head=<owner>:<branch>&state=all&per_page=100` (stdin null, stderr null, as `checks`); a failed run or an answer that is not a JSON array → `None`; `[]` → `Some(false)`; otherwise the item with the highest `number` decides: `state == "closed"` and `merged_at` null → `Some(true)`, anything else `Some(false)`. Module comment: `po state --remote` and `po next --remote` get here. Test: `test_closed_pr_goes_to_a_human` (closed and open answers).
4. [x] **`po next --remote`** — `po/src/next/mod.rs` `main`: every argument must be `--remote` (repeatable); any other keeps today's refusal, `unknown-option`, "po next takes no option <arg>". With it, one `closed` list computed once: when `Forge::of(&context.project)` exists and `lane_settings.merge_mode` is `pr`, each lane at `Stage::Ship`, not landed, with no `waiting_dependency` and no `holding_decision`, whose `pull_request_closed("story/<id>")` is `Some(true)`. `lane::next` and `ship` take `closed: &[String]`; `lane_next` (used by `po/src/state/mod.rs:76`) keeps its signature and passes `&[]`. In `ship` (`lane.rs:174`): a closed lane → `ask`, `pull request closed`, before the `merge waiting` test; closed lanes leave the competitors (`:179-185`), as a merge waiting does. `None` from the forge changes nothing. Tests: `test_closed_pr_goes_to_a_human`; `tests/driver-next-action.test.sh` `test_next_refuses_an_option` unchanged; in `tests/ship-order-and-closed-pr.test.sh`, `test_unreadable_forge_changes_nothing` (a double that exits 1 → `merge waiting`; a `gitlab.com` origin → no call).
5. [x] **Prose and contract** — `method/commands/po-drive.md:29`: the command becomes `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next --remote`; `:43` keeps only the failed-ship rule ("One rule stays yours, since `po` cannot see it: a failed ship …"), the closed-PR sentence goes; the file ends at 2481 words or fewer. `tests/ship-files-the-other-findings.oracle.test.sh:9`: `commands/po-drive.md:2483` → `:2481`, the count before this story. `docs/interface-agent.md:266`: the `next` row adds `--remote` (GitHub only, `gh api --hostname github.com`, under `Merge mode: pr`; closed without merge → `ask`, `pull request closed`, the lane leaves the ship order; an unreadable answer changes nothing; `state` does not ask it) and that ships go in the order of the last `Recorded:` line of each review, the file's modification time without one; `:267`: each block of a review carries `Recorded:` under `Method version:`. Check: `LC_ALL=C wc -w`, `tests/drive-executes-next.oracle.test.sh`, `tests/ship-files-the-other-findings.oracle.test.sh`.
6. [x] **Version and suite** — 0.4.0 → 0.5.0 in `po/Cargo.toml`, `po/Cargo.lock` (the `po` package) and `POLYPE_VERSION` of `bin/polype`. Test: `test_version_goes_up`, `bin/po-version-check` through the suite. Then the full suite once: `po-run --story s185-ship-order-and-closed-pr --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `method/hooks/po-gate.sh` (the research shows it tolerates the line; a change there leaves `Owns`), `po/src/state/`, `po/src/context/`, `po/src/inbox/`, `po/src/run/`, `method/templates/qa.md`, `method/commands/po-execute.md`, `.polype/` (including `.polype/version`), `.claude/`.
- Empty diff for `tests/fixtures/driver-cases/` other than `ships.cases`, and for `tests/driver-next-action.oracle.test.sh` (its floor of 56 and its `replay` stay; `decisions.cases` belongs to s186).
- `po next` without `--remote` runs no process but `git` and the lanes' `po-gate`: no `gh`, no network (`test_closed_pr_goes_to_a_human` checks the double's log).
- No test reaches the network: every forge answer comes from a `PO_GH` double.
- No new crate dependency (ADR-0118); no new warning code, no new field in `po state` or `po next` (`contract` stays `1`).
- #346 is not widened: a lane with an unshipped dependency still reads `wait dependency <id>`, and the forge is not asked about it.

## The pivot
**Where the date lives and who drops it.** The line sits inside each block, right under `Method version:`, so `signals::review` (which reads after the last stamp) and `po-gate` (which reads labels and `## Findings`) never see a label of theirs, and `strip_own_header` drops it so a re-record never carries an old date into a new block. Ways it could be wrong:
- A `Recorded:` line quoted in an answer's body: `reviewed_at` reads only the line under the last `Method version:`, which `po record` wrote; but a body quoting `Method version:` at the start of a line would move that anchor, as it already moves `signals::review`'s. Compare with `trust/signals.rs:25`.
- Mixing dated and undated reviews compares a written instant with an mtime; both are instants since the epoch, so the order is meaningful, but a clock skew between machines would show here. Compare with case 06.
- QA left undated: the story names `po record review` only, and `templates/qa.md` is outside `Owns`.

**A closed lane leaves the ship order.** Before, the prose sent it to a person while the others waited behind it under `automatic`; now the next lane ships, as `## What goes to the person` of `AGENTS.md` asks (the fleet carries on). Ways it could be wrong: a person reopening the pull request expects the lane's place back; it gets it on the next `po next --remote`, since the order is still the written date. And "the highest `number` decides": a branch with an old closed pull request and a new open one reads open, a merged one reads not closed (the merge is then proven by `landed`).

**An unreadable forge changes nothing.** `gh` missing, logged out, or a non-GitHub origin leaves the action computed without the option, as the prose did when `gh pr view` failed; no warning is added. Wrong if the lead needs to tell "not closed" from "unknown": that would be a new warning code, a later story.

## Files touched
`po/src/record/compose.rs`, `po/src/record/mod.rs`, `po/src/next/mod.rs`, `po/src/next/lane.rs`, `po/src/trust/forge.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `method/templates/review.md`, `method/commands/po-drive.md`, `docs/interface-agent.md`, `tests/ship-files-the-other-findings.oracle.test.sh`, `tests/fixtures/driver-cases/ships.cases` (oracle, written), `tests/ship-order-and-closed-pr.oracle.test.sh` (oracle, written), `tests/ship-order-and-closed-pr.test.sh`, `docs/research/…`, `docs/plans/…`.

## Test strategy
All at the layer where each rule lives, the `po` binary on throwaway repositories (the crate has no Rust unit tests): 6 oracle tests, 2 fixture cases (05 and 06 run twice, through their criterion test and through `test_every_routing_case_is_a_fixture`, about a second), 1 task test (`test_unreadable_forge_changes_nothing`, the open question the plan settles). 9 in all, within `Test budget` 25. The forge is a `PO_GH` double, the convention of `tests/trust-signals.test.sh:11-16`; no hand-written mock of a service the project owns. Visual checks: none. Full suite once at the end through `po-run`; `Typecheck: —`, so `cargo build --release --locked` in `tests/run.sh` is the compile check.

## Done when
The seven criteria hold, the full suite is green through `po-run`, `po` is 0.5.0 in its three places, the review has no open critical finding, and the story lands as one commit `s185-ship-order-and-closed-pr: L'ordre des ships vient d'une ligne datée, et une pull request fermée est vue` through a pull request.
