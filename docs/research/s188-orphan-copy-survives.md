# Research — s188-orphan-copy-survives

[Story](../stories.md)

## Structuring facts
- Root cause: `absorb_agents_md` takes `AGENTS.md.before-polype` for the copy Polype set aside whenever `AGENTS.md` carries the assembly marker (`bin/polype:515`), and `assemble_agents_md` lays that marked `AGENTS.md` at the end of every run (`bin/polype:549-560`, called from `wire_the_project` `:796-797`). After any first run the test at `:515` is therefore true for every aside, including one the person wrote; the next run with `AGENTS.local.md` appends it and runs `rm -f "$aside"` (`:527-537`). Proof: the reproduction below, second run prints the `:537` message and the file is gone.
- Nothing on disk records that Polype made a copy: the only writer of the aside is `mv "$project/AGENTS.md" "$aside"` (`bin/polype:544`), which leaves no trace; `.polype/` holds `manifest`, `checksums`, `version`, `mode` (`bin/polype:15-20`, `:130-133`), and `AGENTS.md` is in none of them (repro: `grep -c AGENTS .polype/manifest` → 0). Hence the technical choice the story names: where that record lives.
- Story notes' line numbers are stale but the functions are the same: `absorb_agents_md` is now `:513-547`, `assemble_agents_md` `:549-560` (the notes say the same); `unwire_the_project` `:1208-1224`, `cmd_remove` `:1226-1279`.
- No false assumption in the story. One correction to its framing: today the orphan is **not lost** — its text lands in `AGENTS.local.md` before the `rm` (`:528-534`). The defect is that ADR-0112 promises "ni absorbé ni supprimé" (ADR-0112, Decision Outcome, bullet 3) and `docs/installation.md:295-298` repeats it, while the code keeps that state one run only; a person who follows the message (`:524`) and copies the notes by hand gets them twice (review s161, finding 1).
- `existing_installs_lose_nothing` cannot rely on a version test: this story raises no version (`POLYPE_VERSION="0.6.1"`, `bin/polype:27`, tied to `po/`). A copy set aside by the previous installer carries no record and, whatever option is chosen, reads as an orphan: kept and named, never deleted.

## Diagnostic
Reproduced with `HOME` and `CLAUDE_CONFIG_DIR` under `mktemp -d`, nothing written in the worktree.

| Run | Seen |
| --- | --- |
| project with `AGENTS.local.md` (`Merge mode: local`) and `AGENTS.md.before-polype` = `# Notes nobody laid aside through Polype` (cksum `2050602963 41`); `install <p>` | `…AGENTS.md.before-polype kept as it is: no AGENTS.md laid by Polype goes with it; move its notes into AGENTS.local.md or delete it` (`:524`); file present; `AGENTS.md` line 1 starts `<!-- Assembled by Polype.` |
| `update <p>` | `AGENTS.md.before-polype moved into AGENTS.local.md under ## Notes moved from AGENTS.md, then deleted` (`:537`); file gone; `AGENTS.local.md:3-5` holds the heading and the text |
| second `update <p>` | nothing said about the aside (there is none left) |
| `remove` after `install` on the orphan project | marked `AGENTS.md` deleted, orphan moved to `AGENTS.md` (`:1211-1217`); `.polype/` and `.claude/` gone |
| `remove` after `install` on a project with a hand-written `AGENTS.md` and no `AGENTS.local.md` | `AGENTS.md` = the hand-written text, no aside, no `.polype/`, no `.claude/` |

Hypotheses:
- H1 "the first `install` already absorbs or deletes the orphan (s161's fix incomplete)" — refuted by the aside surviving the first run unchanged, and by `test_orphan_before_polype_is_reported` (`tests/installer-leftovers.oracle.test.sh:86-97`) passing on `main`. Discarded.
- H2 "the deletion comes from the manifest path (`drop_laid_file` puts back or removes a `.before-polype`, `:497-499`)" — refutable by `AGENTS.md` being absent from the manifest and no `put back:` line; manifest has no `AGENTS` line and the update prints the `:537` message only. Discarded.
- H3 "`absorb_agents_md:515` cannot tell an orphan from the waiting copy because the marker it tests is laid by every run" — refutable by a marked `AGENTS.md` absent after `install`, or by the second run not printing `:537`; both observed the other way. Kept: root cause above.

## Story
An `AGENTS.md.before-polype` that Polype did not set aside stays intact through every installer run. Criteria: `orphan_survives_every_run` (install + two updates, file identical, each run names it), `pending_copy_is_still_absorbed` (ADR-0088 flow intact), `remove_restores_as_before`, `existing_installs_lose_nothing` (no run deletes an aside it has not absorbed). Fixes #225.

## Current code
- `absorb_agents_md` (`:513-547`): `from_aside=yes` when the aside is a file and `AGENTS.md` is marked (`:515-518`); a hand-written `AGENTS.md` is a second source (`:519`); "kept as it is" message when the aside is not a source and either `AGENTS.local.md` exists or `AGENTS.md` is not hand-written (`:522-525`); with `AGENTS.local.md`, appends every source under `## Notes moved from AGENTS.md` through `AGENTS.local.md.polype-next` and deletes the aside (`:527-540`); without it, moves a hand-written `AGENTS.md` onto the aside (`:541-546`).
- `refuse_collisions` preflight (`:256-263`): hand-written `AGENTS.md`, no `AGENTS.local.md`, aside a link or of different content → stop, nothing written. Identical content → the `mv` at `:544` overwrites it with the same bytes (`tests/install-collisions.test.sh:225-229`).
- `cmd_install` (`:1053-1100`) and `cmd_update` (`:1107-1167`) both create `state_dir` before `wire_the_project` (`:1059`; update requires an existing manifest, `:1108`).
- `cmd_remove` (`:1226-1279`) deletes `manifest checksums version mode` (`:1258`), prunes `.claude/` and `.polype/` when empty (`:1271`, `PRUNE_DIRS` `:173`), then `unwire_the_project` (`:1208-1217`): deletes a marked `AGENTS.md`, then moves any `AGENTS.md.before-polype` to `AGENTS.md` when none is left.

## Attachment points
- The test at `bin/polype:515`: the one place that decides "this aside is Polype's".
- The `mv` at `bin/polype:544`: the one place Polype creates the copy, where a record would be written.
- The absorption branch `:535-537`: where the record is dropped with the copy.
- `cmd_remove:1258`: the state files remove deletes, before `prune_empty_dirs` (`:1271`).
- Header comment `bin/polype:15-20` listing the state files; `docs/installation.md:291-298` (behaviour) and `:590-595` (remove).

## Verified interfaces
- `marker='<!-- Assembled by Polype.'` (`bin/polype:54`); `method/AGENTS.md:1` starts with it.
- `hand_written_agents_md()` (`:504-506`): `AGENTS.md` is a file whose first line lacks the marker.
- `sum_of() { cksum < "$1"; }` (`:177`), used for every content comparison.
- `state_dir="$root/.polype"` for a project in both `init` and `project` modes (`:165`).
- `done_message` asks to commit `.polype/` (`:1047`, `:1049`): `.polype/` travels in git; `.claude/.polype-checksums` is the one state file kept out of git (`:578-586`).
- Test harness: `tests/run.sh` sets `POLYPE_PO_FETCH=false` and a throwaway `CLAUDE_CONFIG_DIR`; `scratch_repo` (`tests/lib.sh:47-54`).

## Traps
- `tests/installer-leftovers.oracle.test.sh:86-97` (s161 oracle, outside `Owns`) must stay green: install with an orphan keeps it and names `AGENTS.md.before-polype`.
- `tests/install.test.sh:37-44` (outside `Owns`): no `AGENTS.local.md`, hand-written `AGENTS.md`, two installs → the aside keeps the text. The second install must not take the waiting copy for an orphan and drop it (it never drops anything without `AGENTS.local.md`, so it holds).
- `tests/install-collisions.test.sh:190-230`: W case (pending copy absorbed by the first `update`, then a second `update` changes neither `AGENTS.local.md` nor `AGENTS.md`), D case (stop), E case (identical copies kept as one). Any record must be written in case E too, since the `mv` covers it.
- `tests/installer.test.sh:103-113`: remove puts back a hand-written `AGENTS.md` and leaves no aside.
- `tests/install.test.sh` remove test asserts `.polype/manifest` gone; any new state file must go in `cmd_remove:1258` or `.polype/` survives `remove`.
- `tests/readme-onboarding.test.sh:150-155` requires `docs/installation.md` to keep `--set-aside`, `.before-polype`, `Notes moved from AGENTS.md`, `Project CLAUDE file`, `kept`, `ADR-0088`, `ADR-0089`; `:177` requires the hint `AGENTS.md kept as AGENTS.md.before-polype` with `run /po-setup, then <pose>`. Outside `Owns`; the hint at `:545` must not change.
- `tests/install-collisions.test.sh:236` pins the phrase `or a hand-written AGENTS.md.` in `bin/polype` (header `:13`).
- `README.md:124-127` describes only the waiting copy; still true, outside `Owns`.
- ADR-0088 (Decision Outcome, bullet "Un projet posé par l'ancien installeur…") promises the old installer's aside is absorbed once by the first `update` with `AGENTS.local.md`. Every option of ADR-0128 drops that promise for copies with no record: ADR-0128 supersedes that bullet too, not only ADR-0112.
- No migration, no dependency, no version change, nothing under `po/`.

## Open questions
- Where Polype records that the copy is its own — ADR-0128, waiting for the owner. The plan's tasks are written for the top-ranked option.
- A waiting copy the person edits after Polype set it aside: absorb it (it is still the copy) or keep it as an orphan (safe side)? The record option settles it by its sum: edited → orphan, kept and named. The plan states it; the reviewer may weigh it.

## Complexity
Story 3 → 3. One function changes its test, one `mv` gains a record, `remove` drops one more state file, two doc paragraphs and an ADR. The risk is the four existing test files that pin the ADR-0088 flow, all read above.

## Split
—
