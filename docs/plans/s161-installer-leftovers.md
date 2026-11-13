---
validated: yes
---
# Plan — s161-installer-leftovers

[Story](../stories.md) · [Research](../research/s161-installer-leftovers.md)

Branch `story/s161-installer-leftovers`. Read `docs/research/s161-installer-leftovers.md` first; this plan builds on it without repeating it.

## Story
No stop of `bin/polype` leaves a file of the person behind without naming it. Criteria: `failed_remove_names_held_files`, `interrupted_run_leaves_a_named_trace`, `orphan_before_polype_is_reported`, `state_pattern_stays_at_the_top`, `docs_describe_the_kept_copy_stops`. Fixes #143, #137, #144, #132 and the installer points of #79. ADR-0112 (written by the planner, `accepted`, supersedes ADR-0095 on the `*.next` depth only) records the rule.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Report at a failed exit | platform: bash `trap … EXIT` | `bin/polype` has no trap or exit hook today (`grep -n 'trap ' bin/polype` → nothing) |
| Putting a held file back | repository: the put-back of `cmd_remove` (`bin/polype:1013-1017`, `mkdir -p` + `mv`) | — |
| "AGENTS.md is Polype's" | repository: `$marker` (`bin/polype:48`) and the test in `hand_written_agents_md` (`:468-470`) | — |
| Root-only state pattern | platform: a `case` branch on `*/*` in `is_payload_state_file` (`:270-275`) | the repository has no depth test to reuse |

No new option, setting, state file or helper script.

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/installer-leftovers.oracle.test.sh` | `3010334706 5377` |

Owner's rule of 2026-11-13 (Objectif of M20), criterion by criterion. The oracle gate admits a criterion with no test (research, Structuring facts, last line).

| Criterion | Case | Test |
| --- | --- | --- |
| `failed_remove_names_held_files` | 1 — the script's behaviour | `test_failed_remove_names_held_files`: a `mv` shim refuses moves into `polype.kept/`; after the stop, the set-aside file is back in place or every file left under `.polype-restore.*` is named |
| `interrupted_run_leaves_a_named_trace` | 1 | `test_interrupted_run_leaves_a_named_trace`: `.polype` a plain file; the `polype:` lines printed after the failure name each moved file as `<old> -> <new>` |
| `orphan_before_polype_is_reported` | 1 | `test_orphan_before_polype_is_reported`: aside kept byte for byte, output names `AGENTS.md.before-polype` |
| `state_pattern_stays_at_the_top` | 1 | `test_state_pattern_stays_at_the_top`: root `manifest.next` passes; deep `notes.next` and `draft.polype-next` stop `update --global` as foreign |
| `docs_describe_the_kept_copy_stops` | 1 for "sans allonger la section"; 3 for the rest | `test_docs_describe_the_kept_copy_stops` counts the words of `## Installed files` (≤ 516, the count on `main` e0a43b8). The `--set-aside` / `~/.claude/polype/` sentence speaks to agents: case 3, the reviewer reads it, **candidate for a `po-eval` control arm (#208)**. The two stops in `docs/installation.md` speak to a person: case 3, the reviewer reads them; no agent acts on them, so not a `po-eval` candidate. No phrase test. |

On today's code the four behaviour tests fail and the word count passes (run by the planner, outside the worktree's files).

## Tasks
1. [x] **Trap and remove (#143).** In `bin/polype`, add global arrays `HELD=()` (manifest paths held) and `SET_ASIDE=()` (`<old> -> <new>` lines) and a global `HOLD=""`, next to the globals of `:49-51`. Add `report_the_stop`, registered once in `main` (`:1029`) with `trap report_the_stop EXIT`: its first statement keeps `$?`; it returns at once when that is 0. Otherwise, for each `HELD` path still present under `$HOLD`: target = `$root/<path>.before-polype` while `$state_dir` exists, `$root/<path>` once it is gone; when nothing sits at the target (`-e`/`-L`) and `mkdir -p` + `mv` succeed, print `polype: put back: <target>`; else print `polype: still held in <HOLD>: <HOLD>/<path>`. Then remove `$HOLD` if empty (`find … -empty -delete`). Every command in the trap is guarded (`if …; then`), never left to `set -e`, and the trap never calls `exit`. In `cmd_remove` (`:977`), drop the locals `held`/`hold`, set `HOLD="$root/.polype-restore.$$"`, append to `HELD` only after the `mv` into the hold succeeded (`:997-998`), and keep the success path (`:1013-1018`) as it is. — fails: `test_failed_remove_names_held_files`; keeps passing: `tests/payload-kept-outside.test.sh`, `tests/install-collisions.test.sh`.
2. [x] **Trace of the set-aside moves (#79).** In `refuse_collisions` (`:261-264`), after each successful `mv`, append `<old> -> <new>` to `SET_ASIDE`; the per-move line stays. In `report_the_stop`, after the held files, print `polype: set aside before this stop: <old> -> <new>` for each entry, preceded by one line telling the person to rerun the same command once the cause is fixed (the rerun lays Polype's files on the freed paths, and `remove` then puts these back through `drop_laid_file`, `:461-463`). Nothing is moved back. — fails: `test_interrupted_run_leaves_a_named_trace`; keeps passing: `tests/install-collisions.test.sh`, `tests/installer.test.sh`.
3. [x] **Orphan aside (#79).** In `absorb_agents_md` (`:475-498`): the aside is a source only when `$project/AGENTS.md` exists and its first line carries `$marker` (the waiting flow of ADR-0088: a first run without `AGENTS.local.md` set it aside and assembled Polype's file). Otherwise, when `AGENTS.md.before-polype` exists or is a link, it is neither absorbed nor deleted, and the run prints one line naming it, saying no `AGENTS.md` laid by Polype goes with it and that the person moves its notes into `AGENTS.local.md` or deletes it. `rm -f "$aside"` (`:490`) runs only when the aside was a source, and its absorption prints its own line naming `AGENTS.md.before-polype`; the existing line `AGENTS.md moved into AGENTS.local.md under ## Notes moved from AGENTS.md` stays for a hand-written `AGENTS.md`. The no-`AGENTS.local.md` branch (`:492-497`) and the preflight in `refuse_collisions` (`:223-230`) are unchanged. — fails: `test_orphan_before_polype_is_reported`; keeps passing: `test_hand_written_agents_md_is_absorbed` (`tests/install-collisions.test.sh:190-230`), `tests/install.test.sh`, `tests/installer.test.sh`.
4. [x] **State files at the root only (#137).** In `is_payload_state_file` (`:270-275`), a path holding `/` is never a state file; the root names stay `manifest`, `checksums`, `version`, `payload.sums`, `*.next`, `*.polype-next`. Update the comment above `refuse_foreign_payload_files` (`:322-325`) if it says otherwise. — fails: `test_state_pattern_stays_at_the_top`; keeps passing: `tests/payload-refuses-foreign-files.test.sh`, `tests/global-install.test.sh`.
5. [x] **Rules (#132).** In `method/AGENTS.md` `## Installed files`, extend the last sentence so it says `--set-aside` does not apply under `~/.claude/polype/` (ADR-0095), keeping the exact phrase "unless `--set-aside` moves it (ADR-0088)"; cut at least as many words elsewhere in the section, sparing every phrase the research lists under Traps. Section ≤ 516 words, whole file ≤ 3754 (`wc -w`). — fails: `test_docs_describe_the_kept_copy_stops`; keeps passing: every test file that reads `method/AGENTS.md` (research, Traps).
6. [x] **Docs and ADR link (#144).** `docs/installation.md`, in French, adding and never rewriting a sentence an existing test pins: in `### Une copie modifiée que Polype ne pose plus` (`:355-371`), the two s146 stops — "`<parent>` is not a directory…" (before any write: the person moves or renames that file) and "could not move … nothing more written" (the copy stays in the payload: the person frees the kept path, then reruns); in `## Les fichiers d'état` / `### Les collisions` (`:261-267`), that `*.next` and `*.polype-next` are state files only at the root of the payload; in `### Les collisions` (`:254-259`), the trace a failed `--set-aside` run ends with; in the `init`/`install <projet>` list (`:209-213`), the orphan `AGENTS.md.before-polype`; in `## Ce que remove garde` (`:424-433`), what a failed `remove --global` does with held files. Each new rule cites ADR-0112. In `docs/decisions/ADR-0095-*.md`, change only the frontmatter line to `superseded-by: [ADR-0112]` (status stays `accepted`). — no test (case 3); keeps passing: the 16 test files that read `docs/installation.md` (research, Traps).
7. [x] **Suite.** `po-run --story s161-installer-leftovers --label suite -- 'bash tests/run.sh'` once, after the last edit. `Typecheck: —`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s161-installer-leftovers --name-only` lists only: `bin/polype`, `method/AGENTS.md`, `docs/installation.md`, `docs/decisions/ADR-0095-*.md` (frontmatter `superseded-by` line only), `docs/decisions/ADR-0112-*.md`, `docs/research/`, `docs/plans/`, `docs/verif/` of this story, `tests/installer-leftovers.oracle.test.sh`, and `tests/installer-leftovers.test.sh` only if it holds a test.
- No existing test file changes (`git diff main... -- tests/ ':!tests/installer-leftovers*'` empty); `.claude/` and `.polype/` untouched.
- The oracle keeps its sum, or carries a row under `## Oracle changes`.
- No phrase test anywhere: a new test reads a behaviour or a count, never a sentence.
- A run that succeeds prints exactly what it printed before, except the new orphan and aside-absorption lines; exit codes unchanged (0, 1, 2).
- The trap never moves a set-aside file back, never overwrites anything at a target, never calls `exit`.
- `README.md` untouched; the presentation points of #79 (setting column, unlinked "ADR-0005") and its `kept` BOM/symlink point are not taken.
- `bin/polype` is never run against the real `~/.claude` or a real project: scratch `HOME` and `CLAUDE_CONFIG_DIR` only.

## The pivot
**One `EXIT` trap, fed by global arrays, does all the reporting.** Ways it could be wrong:
- It fires where it must not: on a successful run or a usage error (exit 2) with empty arrays it must print nothing. Compare: the output of a clean `install --global`/`remove --global` before and after (`tests/global-install.test.sh`, `tests/installer.test.sh`).
- It moves a held file onto something: the target check must come before `mv`. Compare: `test_failed_remove_names_held_files` and a hand run where `<path>.before-polype` already exists again.
- The orphan line rests on `$marker`: an `AGENTS.md` assembled by Polype means "the aside is the waiting flow of ADR-0088". After an orphan is kept, the same run assembles Polype's `AGENTS.md`, so the *next* run absorbs it, announced by its own line. Compare against `tests/install-collisions.test.sh:190-230` and ADR-0088 lines 33-34.
- A deep `*.polype-next` left by a killed `lay_down` (`:200`) now stops the next run as foreign. Accepted in ADR-0112 (Consequences); the message already tells the person to move it out.

## Files touched
`bin/polype`, `method/AGENTS.md`, `docs/installation.md`, `docs/decisions/ADR-0095-la-charge-utile-se-signe-et-n-accueille-aucun-fichier-etranger.md` (frontmatter), plus, already written by the planner: `docs/decisions/ADR-0112-l-installeur-nomme-ce-qu-il-laisse-a-l-arret.md`, `tests/installer-leftovers.oracle.test.sh`, the research and this plan.

## Test strategy
- Automated, five tests, all in the oracle (budget 25): four drive `bin/polype` in throwaway homes and projects (the "service" layer of an installer: its observable behaviour), one counts words. Failure is injected with a `mv` shim on `PATH` and a plain file at `.polype`, both independent of the user running the suite (a root runner ignores `chmod`).
- No implementer test is required. One goes in `tests/installer-leftovers.test.sh` only for a rule the oracle leaves open (for example the target check of task 1), and that file exists only if it holds a test.
- Each task runs its own test files (`bash tests/run.sh installer-leftovers.oracle.test.sh` plus the files it names); the full suite runs once, task 7.
- Read by the reviewer, not tested: the `## Installed files` sentence (case 3, `po-eval` candidate) and the new text of `docs/installation.md` (case 3).

## Done when
- The oracle passes unchanged and the full suite is green under `po-run`.
- The review has no open critical finding, and checks the M20 word rule on `method/AGENTS.md`.
- Landed as one commit `s161-installer-leftovers: L'installeur ne laisse plus de fichier égaré sans le dire` through a pull request; #143, #137, #144, #132 closed, #79 closed once its two presentation points are recorded as set aside in `docs/decisions-log.md`.
