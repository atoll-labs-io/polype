---
validated: yes
---
# Plan — s188-orphan-copy-survives

[Story](../stories.md) · [Research](../research/s188-orphan-copy-survives.md)

Branch `story/s188-orphan-copy-survives`. Read `docs/research/s188-orphan-copy-survives.md` first; this plan builds on it without repeating it.

The choice: where Polype notes that an `AGENTS.md.before-polype` is the copy it set aside itself. Settled by the owner on 2026-11-16 (decision d-0034): **option A** of [ADR-0128](../decisions/ADR-0128-l-installeur-note-la-copie-qu-il-met-de-cote.md), now `accepted` — a sum recorded in `.polype/`. ADR-0128 supersedes in part ADR-0112 and ADR-0088. The tasks below are those of A; the oracle, written against the installer's commands only, is unchanged.

## Story
An `AGENTS.md.before-polype` that Polype did not set aside stays intact through every installer run (#225). Criteria: `orphan_survives_every_run`, `pending_copy_is_still_absorbed`, `remove_restores_as_before`, `existing_installs_lose_nothing`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The record of the copy (write, compare, drop) | Already in this repository: `sum_of` (`bin/polype:177`) for the sum, `state_dir` (`:165`) for where state lives, the `rm -f` list of `cmd_remove` (`:1258`) for its removal | — (the first rung holds; only the file path and three lines that use it are new) |
| Telling an orphan from the waiting copy | Already in this repository: the `from_aside` branch of `absorb_agents_md` (`:514-525`) | — (its condition changes, no new function) |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/orphan-copy-survives.oracle.test.sh` | `3253883048 5433` |

| Criterion | Test |
| --- | --- |
| `orphan_survives_every_run` | `test_orphan_survives_every_run` — fails on `main` (second run absorbs and deletes), checked by the planner |
| `pending_copy_is_still_absorbed` | `test_pending_copy_is_still_absorbed` |
| `remove_restores_as_before` | `test_remove_restores_as_before` — includes `.polype/` gone after `remove`, which a forgotten record would break |
| `existing_installs_lose_nothing` | `test_existing_installs_lose_nothing` — the previous installer's state built by hand: its aside next to Polype's `AGENTS.md`, no record |

## Tasks
1. [x] **Record the copy Polype makes.** In `absorb_agents_md`, right after `mv "$project/AGENTS.md" "$aside"` (`bin/polype:544`), write `sum_of "$aside"` into `$state_dir/agents-md-aside` (one line, the `cksum` output). `state_dir` exists by then in `install`, `init` and `update` (`:1059`, `:1108`). Test: `test_pending_copy_is_still_absorbed` (no record → the copy is never absorbed).
2. [x] **Decide by the record, not by the marker.** Replace the condition at `:515`: the aside is Polype's when it is a regular file, not a link, `$state_dir/agents-md-aside` exists and its content equals `sum_of "$aside"`. A record that designates no matching aside (aside gone, or changed since) is deleted in the same place, without a message. The "kept as it is" message (`:522-525`) keeps its trigger shape and is reworded so it no longer says "no AGENTS.md laid by Polype goes with it" — e.g. `polype: $aside kept as it is: Polype did not set it aside, or it changed since; move its notes into AGENTS.local.md or delete it`; it keeps the full path, on every run. Tests: `test_orphan_survives_every_run`, `test_existing_installs_lose_nothing`, and `test_edited_waiting_copy_is_kept` (task 5).
3. [x] **Drop the record with the copy.** In the absorption branch (`:535-537`), `rm -f` the record next to `rm -f "$aside"`; the message at `:537` stays word for word (the oracle quotes it). Test: `test_pending_copy_is_still_absorbed` (second update after absorption changes nothing).
4. [x] **`remove` takes the record away.** Add `$state_dir/agents-md-aside` to the state files `cmd_remove` deletes (`:1258`), before `prune_empty_dirs` (`:1271`); `unwire_the_project` (`:1208-1217`) is unchanged, so an aside, recorded or not, still goes back to `AGENTS.md`. Update the header comment (`:15-20`) to name the record among the state files, keeping the phrase `or a hand-written AGENTS.md.` at `:13`. Test: `test_remove_restores_as_before` (`.polype/` must be gone).
5. [x] **Story test.** `tests/orphan-copy-survives.test.sh`, one test `test_edited_waiting_copy_is_kept`: project without `AGENTS.local.md`, hand-written `AGENTS.md`; `install`; append a line to the aside; create `AGENTS.local.md`; `update` → the aside is still there with the edit, its text is not in `AGENTS.local.md`, and the output names its full path. It fails if task 2 checks only that the record exists. Same sandbox helpers as the oracle, copied, not sourced.
6. [x] **Docs and ADR links.** `docs/installation.md:291-298`: say the waiting copy is the one Polype noted in `.polype/` when it set it aside, absorbed only while unchanged; any other `AGENTS.md.before-polype`, including one an older installer left, is neither absorbed nor deleted, and every run names it (ADR-0128). `:590-595`: no change in substance (remove still puts the aside back). Keep `ADR-0088`, `ADR-0089`, `--set-aside`, `.before-polype`, `Notes moved from AGENTS.md`, `Project CLAUDE file`, `kept` in the file (`tests/readme-onboarding.test.sh:150-155`). Once ADR-0128 is accepted by `/po-plan`, add `ADR-0128` to the `superseded-by` line of ADR-0112 and of ADR-0088, and change nothing else in them.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/`, `method/`, `README.md`, `tests/installer-leftovers.oracle.test.sh`, `tests/install.test.sh`, `tests/installer.test.sh`, `tests/readme-onboarding.test.sh`, `tests/install-collisions.test.sh` (in `Owns`, but no clause it checks changes).
- `POLYPE_VERSION` (`bin/polype:27`) and `PO_SUMS` unchanged.
- The hint `AGENTS.md kept as AGENTS.md.before-polype: no AGENTS.local.md to move it into; run /po-setup, then …` (`:545`) and the absorption message (`:537`) unchanged.
- ADR-0112 and ADR-0088: only their `superseded-by` line changes, and only after ADR-0128 is accepted.
- No heuristic on `.polype/version` or on the marker to absorb an unrecorded copy: an unrecorded copy is always kept.

## The pivot
Every rule hangs on one test: an aside is Polype's when a record written at the moment of the `mv` still matches it. Ways it could be wrong:
- **The record is written somewhere a copy is made without it.** Compare every writer of `AGENTS.md.before-polype` in project mode: `grep -n 'before-polype' bin/polype` must show the `:544` `mv` as the only one outside `refuse_collisions`' `--set-aside` (which never applies to `AGENTS.md`, `:261`). Case E of `tests/install-collisions.test.sh:225-229` (identical copies) goes through `:544` and must be recorded.
- **The record outlives its install.** `remove` must delete it, or `.polype/` survives; `test_remove_restores_as_before` checks it.
- **The legacy pending copy.** It reads as an orphan and is no longer absorbed: accepted by ADR-0128, and it must still be named on every run, never deleted (`test_existing_installs_lose_nothing`).

## Files touched
`bin/polype`, `tests/orphan-copy-survives.oracle.test.sh` (written, not to change), `tests/orphan-copy-survives.test.sh`, `docs/installation.md`, `docs/decisions/ADR-0128-…md`, `docs/decisions/ADR-0112-…md` and `ADR-0088-…md` (frontmatter link only), `docs/research/s188-orphan-copy-survives.md`, `docs/plans/s188-orphan-copy-survives.md`, `docs/verif/s188-orphan-copy-survives.md`.

## Test strategy
Five tests within `Test budget` 25: four oracle tests (one per criterion) and one story test. All drive `bin/polype` as a person does, in throwaway `HOME`/`CLAUDE_CONFIG_DIR`, and read only what lands on disk and the output: no test reads the record file, so the oracle stands whatever option the owner picks. During tasks: `bash tests/run.sh orphan-copy-survives.oracle.test.sh orphan-copy-survives.test.sh install-collisions.test.sh installer-leftovers.oracle.test.sh install.test.sh installer.test.sh`. Once at the end: `po-run --story s188-orphan-copy-survives --label suite -- 'bash tests/run.sh'`. No type check (`Typecheck: —`). The reviewer's bite checks: restore the marker condition at `:515` (oracle `orphan_survives_every_run` turns red), and compare the record by existence only (`edited_waiting_copy_is_kept` turns red).

## Done when
One commit on `story/s188-orphan-copy-survives` carrying code, tests, docs, research, plan and record; full suite green through `po-run`; ADR-0128 accepted by the owner; a review with no open critical finding; landed through a pull request as `s188-orphan-copy-survives: Une copie orpheline de l'AGENTS.md d'une personne n'est jamais supprimée`.
