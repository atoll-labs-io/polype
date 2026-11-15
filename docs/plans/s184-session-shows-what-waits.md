---
validated: yes
---
# Plan — s184-session-shows-what-waits

[Story](../stories.md) · [Research](../research/s184-session-shows-what-waits.md)

Branch `story/s184-session-shows-what-waits`. Read `docs/research/s184-session-shows-what-waits.md` first; this plan builds on it without repeating it.

ADR-0126 (`docs/decisions/ADR-0126-un-depot-cadre-a-la-main-lit-son-cadrage-par-les-fichiers-de-la-loi-6.md`, `accepted`) settles the two choices the story left open: the owner chose **1-B** (this repository keeps the single file `docs/reviews/stories.md`, d-0030) and **2-A** (`architecture` stays `missing` while `docs/architecture.md` does not exist, d-0031), on 2026-11-16. The tasks below are written for those two options.

## Story
`po-session` lists the decisions waiting for the owner and counts the answered ones the lead has not consumed; `po` stops reporting this repository's stories review as missing. Criteria: `session_lists_pending_decisions`, `session_counts_answered_not_consumed`, `this_repository_reads_reviewed`, `single_file_projects_read_the_same`, `version_goes_up` (minor).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `Inbox::answered_not_consumed` | already in this repository: the predicate of `po/src/run/mod.rs:171`, moved onto `Inbox` (`po/src/context/mod.rs:85`) | — (the code exists; it gains one home so `run` and `state` share it) |
| `answered` field of `po state` | already in this repository: the shape of `waiting` (`po/src/state/mod.rs:56-63`) | — |
| Session lines for decisions | already in this repository: the `W`/`P` tagging of `po-session.sh:47-85` | — |
| `docs/reviews/stories.md` | already in this repository: `docs/reviews/stories-m22.md`, copied whole | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/session-shows-what-waits.oracle.test.sh` | `1782382889 6775` |

| Criterion | Test |
| --- | --- |
| `session_lists_pending_decisions` | `test_session_lists_pending_decisions` — real `po` and hook; pending ids listed as `- <id>: decision pending → po inbox <id>`, an answered one not listed, a sensitive one's witness text never printed, `nothing` only with an empty inbox |
| `session_counts_answered_not_consumed` | `test_session_counts_answered_not_consumed` — `Decisions answered, not consumed: 2 → po inbox --answered`, a consumed one not counted, `po state .answered` the same ids; `none` when there are none |
| `this_repository_reads_reviewed` | `test_this_repository_reads_reviewed` — option 1-B: this repository's `AGENTS.local.md`, `docs/stories.md` and `docs/reviews/stories*.md`, committed on `main` of a scratch repository, read `stories-review: yes` |
| `single_file_projects_read_the_same` | `test_single_file_projects_read_the_same` — `none` without a file; with `docs/reviews/stories.md` the whole `framing` object is what it was, and a per-milestone or intake file beside it changes nothing |
| `version_goes_up` | `test_version_goes_up` — the three places agree and are at least `0.4.0` |

Checked before the plan against the installed `po` 0.3.1: the first three fail, the fourth passes, so the oracle bites on the code as it stands.

## Tasks
1. [x] **Share the count.** In `po/src/context/mod.rs`, give `Inbox` a method `answered_not_consumed(&self) -> impl Iterator<Item = &Decision>` (status `answered`, `consumed` none). `po/src/run/mod.rs:170-172` uses it (`.next().is_some()`). Remove the `#[allow(dead_code)]` of `Inbox` only if nothing it covers is still unread. Test able to fail: `tests/run-from-outside.test.sh:208` (`nothing-to-do` when the only answered decision is consumed) and the answered cases of `tests/run-from-outside.oracle.test.sh:204-217`.
2. [x] **`po state` carries `answered`.** Add `pub answered: Option<Vec<String>>` to `State`, right after `waiting` (`po/src/state/mod.rs:28`): the ids from task 1's method, in the inbox's id order, `None` when `context.inbox` is `None`. Test able to fail: `test_session_counts_answered_not_consumed` (its `.answered` assertion).
3. [x] **The hook shows what waits.** In `method/hooks/po-session.sh`, inside the non-`setup` branch of the `jq` program:
   - first `W` lines, one per id of `.waiting // []`: `\(.): decision pending → po inbox \(.)` — the id only, whatever `sensitive` says;
   - one `P` line after `Lanes in flight`: `Decisions answered, not consumed: ` then `not read by po` when `.answered` is null, `none` when empty, else `<count> → po inbox --answered`.
   Nothing changes at `setup` stage. Update the hook's header comment only if it states what `W` holds. Tests able to fail: `test_session_lists_pending_decisions`, `test_session_counts_answered_not_consumed`; `tests/commands-read-po-state.oracle.test.sh` (`test_session_hook_prints_from_po_state`, exactly 7 `- ` lines, no `Decision inbox` text) must stay green unchanged.
4. [x] **Pinned tests follow the new field and lines.** `tests/verbs-read-project-context.oracle.test.sh:20`: add `.answered` to the fields `normalised` drops, with the reason in its comment (a field s184 adds). `tests/state-carries-session-lines.oracle.test.sh:151-172`: `SESSION_LINES` puts the `.waiting` lines first in the waiting list, as the hook does, so that test stays the mirror of the hook. Each change is named in `## Oracle changes` of the record (both are oracles of earlier stories). Test able to fail: the two files themselves, run after task 3.
5. [x] **This repository holds `docs/reviews/stories.md`** (option 1-B). Create it as a byte copy of `docs/reviews/stories-m22.md` (`cp`), last `Stories ready:` line `yes`. `stories-m22.md` and the other per-milestone files stay untouched. Test able to fail: `test_this_repository_reads_reviewed`; `tests/artifact-links-backfill.test.sh` (`test_existing_artifacts_backfilled`) stays green.
6. [x] **Contract and version.** `docs/interface-agent.md`: after `:93` (`waiting`), one bullet for `answered` (sorted ids of the decisions `answered` and not consumed, the same list as `inbox --answered`; `null` when `waiting` is); add `"answered": []` after `"waiting"` in the `state` sample (`:57`). `contract` stays `1` (`:30`). Raise `po` to `0.4.0` in `po/Cargo.toml:3`, `po/Cargo.lock` (the `po` package), and `POLYPE_VERSION` of `bin/polype:27`. Tests able to fail: `test_version_goes_up`; `bin/po-version-check` through the suite.

Then the full suite through `po-run` (`Full suite: execute-end`), after the commit, since `tests/readme-onboarding.test.sh` clones the committed HEAD.

## Scene viewpoints
—

## Run interdicts
- `method/AGENTS.md`, `method/commands/`, `method/templates/` and every installed copy (`.polype/`, `.claude/`, `.polype/hooks/po-session.sh`) end with an empty diff.
- The reading rule of `po/src/context/framing.rs` is unchanged under 1-B: `git diff main -- po/src/context/framing.rs` is empty.
- `po/src/inbox/` unchanged (its own copy of the predicate, `inbox/mod.rs:179`, stays; out of `Owns`).
- No `docs/reviews/stories-m*.md` file changes, moves or disappears; no `docs/architecture.md` is written (2-A puts it in a separate framing pull request).
- `"contract"` stays `1` in `po` and in `docs/interface-agent.md`.
- The hook never prints a decision's question, context or options; it prints ids only.
- No test fixture copies a real decision of `.polype/inbox/` or `Private folder`.

## The pivot
The plan rests on 1-B, the owner's choice: the fix for #244 is a file in this repository, not a rule in `po`. It could be wrong in two ways:
- The copy drifts: the lead writes M23's review into a new `stories-m23.md` again. Nothing checks the habit (the owner accepted that cost, d-0030); the decisions log and the lead's notes must carry it.
- `this_repository_reads_reviewed` reads the working tree, not `main`: it proves the file the story ships, not what `po state` says on `main` before the ship. After the ship, `po state` at the root is the confirmation.
For #315, the pivot is the hook printing ids only: a reviewer checks that no `jq` path in the hook reads `.question`, `.context` or `.options`.

## Files touched
`po/src/context/mod.rs`, `po/src/run/mod.rs`, `po/src/state/mod.rs`, `method/hooks/po-session.sh`, `docs/interface-agent.md`, `docs/reviews/stories.md` (new), `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `tests/verbs-read-project-context.oracle.test.sh`, `tests/state-carries-session-lines.oracle.test.sh`, plus this story's research, plan, oracle and ADR-0126.

## Test strategy
Five oracle tests (one per criterion), at the layer each rule lives: the hook's lines through the real hook and the real `po` (adapter layer, the output the lead reads); the field through `po state`; the framing read through `po state` on scratch repositories. No `tests/session-shows-what-waits.test.sh` is needed under 1-B and 2-A: the moved predicate is covered by the existing `po run` tests (task 1), and the two pinned-test edits are mirrors, not new tests. Total 5, under `Test budget` 25.
Criteria sorted per the owner's rule (2026-11-13): all five are read by a script (the hook's output, `po state`, the version files), so all five have an oracle test; none speaks only to a model, so no `po-eval` candidate.
Visual checks: none.

## Done when
One commit on `story/s184-session-shows-what-waits` holding the code, the oracle, ADR-0126 (accepted), research, plan and record; the full suite green through `po-run`; a review with no open critical; landed through a pull request. After the ship, `po state` at the repository root reads `stories-review: yes`.
