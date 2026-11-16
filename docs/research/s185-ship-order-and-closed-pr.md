# Research — s185-ship-order-and-closed-pr

[Story](../stories.md)

## Structuring facts
- Root cause #278: `po/src/next/lane.rs:199-204` (`reviewed_at`) orders the ships by `std::fs::metadata(...).modified()` of `docs/reviews/<id>.md`, and nothing in a review carries a date: `po/src/record/compose.rs:106-120` (`first_write`, `append`) writes only `Method version:` above each block. Proof: copying a review file onto itself turned `s01 ship / s02 wait` into `s01 wait / s02 ship` (reproduction below).
- Root cause #286: `po/src/next/mod.rs:54-56` refuses every argument, and no route of `po next` asks a forge: `merge waiting` comes from `refs/remotes/origin/story/<id>` existing (`po/src/context/lanes.rs:347-356`), never from the pull request's state. Proof: a `PO_GH` double answering "closed" was called 0 times, `po next --remote` exits 2 `unknown-option`.
- The forge reading to reuse exists once: `po/src/trust/forge.rs:11-78` (`Forge::of`, `gh api --hostname github.com`, `PO_GH` double, ADR-0083), reached today only by `po state --remote` (`po/src/trust/mod.rs:117-127`). d-0009 (owner's variant, `.polype/inbox/d-0009.json`, `consumed.ref`) and #286 fix the shape: an explicit option "such as `--remote`", built on that reading.
- No assumption of the story is false. Two things it leaves implicit: `po state` also renders `lanes[].next` through `next::lane_next` (`po/src/state/mod.rs:76`) and `po/src/state/` is not in `Owns`, so `po state --remote` will not carry the closed-PR `ask`; and the closed-PR rule only works if `/po-drive` runs `po next --remote`, since criterion `drive_no_longer_decides_it` removes the prose rule (`method/commands/po-drive.md:43`).

## Diagnostic
Reproduction, on the code as it stands (`ba0f67f`), with the `po` built from it (`po/target/release/po` of the main checkout, 0.4.0), using the helpers of `tests/driver-next-action.oracle.test.sh:24-174` in a scratch directory outside the worktree:
- Two lanes at `ship`, reviews touched at 09:00 (s01) and 10:00 (s02): `s01 ship`, `s02 wait ships serial: s01-alpha`. After `cp` of s01's review onto itself: `s01 wait ships serial: s02-bravo`, `s02 ship`. Defect #278 reproduced.
- `Merge mode: pr`, `Ship confirmation: human`, s01 pushed, `PO_GH` double printing `[{"state":"closed","merged_at":null}]`: `po next` gives `s01 wait merge waiting`, `s02 ship`; the double logged 0 calls; `po next --remote` → `{"error":"unknown-option","message":"po next takes no option --remote"}`. Defect #286 reproduced.

Hypotheses:
| # | Hypothesis | Refuted by | Result |
| --- | --- | --- | --- |
| 1 | The ship order is the review file's mtime | an order that holds after a copy | kept: the copy flipped it; `lane.rs:187` sorts on `reviewed_at`, `lane.rs:199-204` reads `modified()` |
| 2 | Some line of the review already dates the verdict and could be read instead | any dated line written by `po record` or asked by the template | discarded: `compose.rs:106-120` writes `Method version:` alone; `method/templates/review.md:1-64` has no date |
| 3 | `po next` cannot be asked to read the forge | an option accepted, or a forge call | kept: `mod.rs:54-56`; 0 calls to the double |
| 4 | `merge waiting` already reads the pull request's state | a `gh` call when a lane is `merge waiting` | discarded: `lanes.rs:351-353` reads a local ref only; 0 calls |

## Story
`po record review` writes a dated line, with its offset, in each block, never twice on a re-record; `po next` orders ships by it and falls back to the mtime for an undated review; the gates and trust signals read a dated review as before; `po next` with the forge option gives `ask` to a lane whose pull request was closed without a merge, and without it asks no forge; `/po-drive` loses its prose rule without growing; `po` goes up a minor step (0.4.0 → 0.5.0).

## Current code
- `po/src/next/lane.rs:21-87` `next`: landed → dependency → decision → stage routes; `Stage::Ship` → `ship` (`:84`). `ship` (`:174-195`): `MergeWaiting` → `wait merge waiting`; else the competitors (stage ship, not landed, not merge-waiting, no holding decision, no waiting dependency, `:179-185`) sorted by `(reviewed_at, story_rank, id)`; the first ships, the others `wait ships serial: <first>`.
- `po/src/next/mod.rs:53-91` `main`: refuses any arg, reads `Context`, maps each lane through `lane_next` (`:98-100`), which `po state` also calls (`po/src/state/mod.rs:76`).
- `po/src/record/mod.rs:143-303`: reads the answer, strips its header (`compose::strip_own_header`, `compose.rs:57-72`: blank, `# Review`, `# QA`, `[Story](`, `Method version:`), then `text_with` (`:230-246`) builds the file with `first_write` or `append`; for reviews with `[security]` findings it is called twice (`:250`, `:265`). QA reports are rewritten whole (`existing` is `None` for QA, `:226-229`).
- `po/src/trust/signals.rs:20-40`: the block starts after the last `Method version:` line; only named prefixes are read (`Fix loop:`, `Max severity:`, `## Not verified`, `- Oracle:`).
- `method/hooks/po-gate.sh:53-61` (`paired_value`), `:78-93` (`ship_allowed`), `:98-128` (`findings_shape`): read labelled lines and the `## Findings` section only; a `Recorded:` line names none of their labels. Verified by running both gates on a review with such a line (simulated): exit 0. No change to `po-gate.sh` is needed.
- `method/commands/po-drive.md:29` runs `po next` with no option; `:43` holds the closed-PR rule (`gh pr view ... CLOSED`). 2481 words (`LC_ALL=C wc -w`).

## Attachment points
- Dated line: `compose::first_write` / `compose::append` (review only), `compose::strip_own_header` (drop a leading `Recorded:`), the date taken once in `record::main` before `text_with`.
- Ship order: `lane.rs` `reviewed_at`.
- Closed PR: `mod.rs` `main` (accept `--remote`), a set of closed lanes computed once there, passed to `lane::next` → `ship`; `forge.rs` gains the pull-request reading. `lane_next` keeps its signature for `po state`.
- Contract text: `docs/interface-agent.md:266-267` (the two lead verbs `next` and `record`).
- Template note: `method/templates/review.md:5`.

## Verified interfaces
- `Forge::of(&Project) -> Option<Forge>` (`forge.rs:38-41`), `Forge.repo` is `<owner>/<repo>`; `gh_program()` honours `PO_GH` (`:17-22`). `Context.project`, `Context.lane_settings.merge_mode`, `Context.landed`, `Context.lanes` are read by `next` already (`lane.rs:17-19,165`, `wave.rs:9-13`).
- `chrono` with `clock` is a dependency (`po/Cargo.toml:10`); `DateTime::parse_from_rfc3339` is used at `signals.rs:141`; `Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)` prints the offset (`inbox/rewrite.rs:29-31`, private to `inbox`; `run/mod.rs:276-278` repeats it).
- `po state --remote` parsing: `trust::state_options` (`trust/mod.rs:117-127`).
- GitHub REST `GET repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=all` returns an array whose items carry `number`, `state` (`open`/`closed`) and `merged_at` (null unless merged). Not called from this research (no network); the double fixes the shape.

## Traps
- `tests/record-writes-reports.oracle.test.sh:121-142` wants one `Method version:` per QA report re-recorded onto itself; QA is out of this story (`method/templates/qa.md` is not in `Owns`), so the dated line is written for reviews only, but `strip_own_header` must drop a leading `Recorded:` for both.
- `tests/security-findings-stay-private.oracle.test.sh:155`: a later loop leaves the earlier block byte-identical (append only); `tests/record-review-loose-ends.oracle.test.sh:17`: a refused record leaves the review byte-identical. Taking the date once keeps both writes of `text_with` equal.
- `tests/review-header-recorded.oracle.test.sh:33` pins the note prefix `<\`po record\` writes these lines`. Word caps of `method/templates/review.md`: 557 (`security-findings-stay-private.oracle.test.sh:161`) and 558 (`record-writes-reports.test.sh:26`), 556 today.
- `tests/ship-files-the-other-findings.oracle.test.sh:9` caps `po-drive.md` at 2483; `tests/drive-executes-next.oracle.test.sh:10` at 2500. No test pins `po-drive.md:43`. `po-execute`'s narrow permission is `po next` without option (ADR-0120, `drive-executes-next.oracle.test.sh:8`): it stays so.
- `tests/driver-next-action.test.sh:8-13` refuses `po next extra`: still refused, only `--remote` is accepted.
- `test_every_routing_case_is_a_fixture` (`tests/driver-next-action.oracle.test.sh:300-326`) replays every case with `po next` and no option: the closed-PR state cannot be a plain case.
- s183 (#346, not decided): a lane with an unshipped dependency returns `wait dependency` before `ship` (`lane.rs:27-29`); the closed-PR check lives in `ship`, so such a lane is never asked about and keeps reading `wait dependency`.
- `bin/po-version-check` (s182) refuses a `po/` change without 0.4.0 moving in `po/Cargo.toml`, `po/Cargo.lock:164-165` and `bin/polype:27` together. `.polype/version` is an installed copy and stays.
- No migration.

## Open questions
- What `po next --remote` does when the forge cannot be read (`gh` missing, logged out, another forge): the plan keeps the action computed without the option, as the prose did when `gh pr view` failed, and adds no warning. A warning code would be a contract addition the story does not ask for.
- `po state --remote` does not get the closed-PR reading (`po/src/state/` outside `Owns`); its `lanes[].next` stays what `po next` without option gives. Filed as a gap for the lead, not widened here.

## Complexity
3 → 3. Two separate mechanisms, each small and local (`next`, `record`, `trust/forge.rs`), with an existing forge reading and test harness to reuse; no data migration.

## Split
—
