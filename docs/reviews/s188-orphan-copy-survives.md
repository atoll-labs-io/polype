# Review — s188-orphan-copy-survives

[Story](../stories.md) · [Plan](../plans/s188-orphan-copy-survives.md) · [Verification](../verif/s188-orphan-copy-survives.md)

Method version: 0.6.1
Recorded: 2026-11-16T13:11:17+01:00

Diff reviewed: `git diff main...story/s188-orphan-copy-survives`, read in a context that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 9fa328e65e83a4695248a6204fbeaeca14c727fb

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s188-orphan-copy-survives` and held each path against the story's `Owns` line.
- [x] Every path is inside `Owns`:
  - `bin/polype`, `docs/installation.md`, `tests/orphan-copy-survives.oracle.test.sh` and `tests/orphan-copy-survives.test.sh` are listed by name.
  - `tests/drop-keeps-modified.test.sh` and `tests/payload-refuses-foreign-files.test.sh` were added to `Owns` on main in d8f3b26. Each changes one assertion only, the `superseded-by` line of ADR-0088, as the story notes allow.
  - ADR-0088, ADR-0112 and the new ADR-0128 are covered by the `docs/decisions/` entry. Only the `superseded-by` frontmatter line of ADR-0088 and of ADR-0112 changed, which Law 6 permits.
  - The research, plan and verification files are pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s189 and s190 also own `bin/polype`, `docs/installation.md` and other paths, but they depend on s188 and cannot run alongside it.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s188-orphan-copy-survives` exits 0, so I reused the record. Its last `bash tests/run.sh` row exits 0 on the recorded code. The project has no type check (`Typecheck: —`). I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, each at the place the plan names:
  - The record is written right after the `mv` (`bin/polype:548`).
  - The condition compares the record's sum with the copy's sum, refuses a symlink, and deletes a stale record without a message (`:516-521`).
  - The record is deleted together with the copy (`:539`).
  - `cmd_remove` deletes the record (`:1262`), and the header comment names it (`:18-19`).
  - The message is reworded and still carries the full path.
  - `docs/installation.md` is updated, and both ADR links are added.
  - Nothing appears in the diff that the plan did not ask for.
- [x] Run interdicts, checked one by one:
  - `po/`, `method/`, `README.md` and the five protected test files are untouched.
  - `POLYPE_VERSION` and `PO_SUMS` are unchanged.
  - The hint at `:549` and the absorption message at `:540` are unchanged, word for word.
  - ADR-0088 and ADR-0112 differ only on their `superseded-by` line.
  - Nothing reads the marker or the version to absorb a copy that has no record.

## References
- [x] Every reference was opened and confirmed:
  - `sum_of` (`:177`) and `state_dir` (`:166`, project and init modes) exist.
  - `refuse_collisions` runs before `wire_the_project` in both install (`:1062`/`:1095`) and update (`:1117`/`:1158`).
  - `unwire_the_project` (`:1212-1222`) is unchanged.
  - The payload's foreign-file check (`is_payload_path`, `:302`) applies only in global mode, so the new `.polype/agents-md-aside` cannot be taken for a foreign file.
- [x] Values: `cksum` is the comparison every other part of the installer uses. A copy whose sum collides with the record would be absorbed before it is deleted, so even that case loses no text.

## Rules
- [x] `AGENTS.md` conventions are respected: comments are in English and sparse, and the docs are in French.
- [x] No accepted ADR is contradicted. ADR-0128 is `accepted` and records the owner's answer d-0034; `docs/decisions-log.md:316` traces it. It explicitly replaces the ADR-0088 promise that a legacy copy would be absorbed once, and the third bullet of ADR-0112's decision.

## Tests
- Oracle: `po-gate oracle-intact s188-orphan-copy-survives` → exit 0
- [x] Floor: `po-gate floor-guard s188-orphan-copy-survives main` exits 0, so nothing was lowered. `po-gate oracle-intact` also exits 0.
- [x] The assertions pin the four criteria plus the case of an edited copy:
  - Every test drives `bin/polype` in a throwaway HOME and `CLAUDE_CONFIG_DIR`.
  - The tests only read what lands on disk and the installer's output.
  - None of them has any of the six shapes of a test that proves nothing.
- [x] Five tests, within the `Test budget` of 25.
- [x] Bite checks, each one undone afterwards and the file proven back to its committed state with `git diff --exit-code`:
  - Restoring the old marker condition at `:516`: 2 tests fail (`orphan_survives_every_run`, `edited_waiting_copy_is_kept`).
  - Comparing the record by existence only: 1 test fails (`edited_waiting_copy_is_kept`).
  - Taking the record out of the `cmd_remove` deletion at `:1262`: 1 test fails (`remove_restores_as_before`).
- [x] The two changed existing assertions follow the clause they check, and the record says so.

## Neighbours
- [x] I read the callers and the code around the change: `wire_the_project` (`:800`), `refuse_collisions` (the check before anything is written, `:256-263`), `unwire_the_project`, the `.before-polype` handling in `drop_laid_file` (`:489-499`) and `po-session.sh`, which reads only `version`, `mode` and `manifest` in `.polype/`.
- [x] I checked the implementer's claim, and the wider question of whether the installer ever deletes a person's file without absorbing it, with a probe: a throwaway HOME and projects under `/tmp/tmp.27pItyM33G`, `POLYPE_PO_FETCH=false`.
  - **The planner's case** (copy set aside with a record, then a new hand-written `AGENTS.md`, then `AGENTS.local.md`): `update` adds both texts to `AGENTS.local.md` under one `## Notes moved from AGENTS.md` heading ("First", then "Second"), then deletes the copy and its record. A second `update` changes nothing. **The claim holds.**
  - **Edited copy plus new `AGENTS.md`, with `AGENTS.local.md`:** the edited copy is kept and named, and only the new `AGENTS.md` is absorbed.
  - **Copy with a record plus a different hand-written `AGENTS.md`, no `AGENTS.local.md`:** the check before writing stops the run (exit 1). Nothing is written and the record is intact.
  - **Edited copy, no `AGENTS.local.md`:** two updates keep it and name it each time. `remove` then puts it back as `AGENTS.md`, its text intact.
  - **Init mode:** the copy is recorded and absorbed the same way.
  - **`remove` after a waiting copy:** gives back the hand-written `AGENTS.md`, and `.polype/` is gone.
  - **Every path in the code that deletes or overwrites a copy, read one by one:**
    - `rm -f "$aside"` runs only in the `from_aside=yes` branch, after the `mv -f` of `AGENTS.local.md.polype-next` has succeeded under `set -e`.
    - `mv AGENTS.md "$aside"` can only replace content that is identical, or no file at all, because the check before writing rules out anything else.
    - `remove` renames the copy; it never deletes it.
  - Conclusion: no path deletes a file of the person without having absorbed it.

## Lenses
Lenses run: none. The diff is a shell installer and tests: no auth, routes or uploads, no migration, no lockfile or manifest, no server-side queries.
- [x] No lens findings.

## Findings
- minor — docs/installation.md:296 — The doc says the waiting copy is absorbed "tant que la copie n'a pas changé depuis". An edited copy drops its record on the next run (`bin/polype:520`), so a copy edited and then reverted to its exact recorded bytes is never absorbed again. I reproduced this in the probe: it stays an orphan, kept and named, and no text is lost. The sentence reads as if reverting the copy would bring absorption back. Either word the doc as "un passage qui la trouve changée la laisse à la personne", or keep the record until the copy is absorbed or gone.

## Not verified
- A clone that carries `.polype/agents-md-aside` without the copy, or the copy without the record (for example `.polype/` not committed). I only reasoned about it: the record is deleted silently, and the copy reads as an orphan, kept and named. A person could confirm by cloning a project installed with a waiting copy, once with the copy left uncommitted and once with `.polype/` left uncommitted, then running `polype update .` in each.
- I did not rerun the full suite: the reused record covers it. For each bite check I ran only the story's two test files, not `install-collisions`, `installer-leftovers`, `install` or `installer`.
- The owner's answer d-0034 itself, in the decision inbox. I relied on ADR-0128's accepted status and the line in `docs/decisions-log.md:316`.
- The probe never built `po`: it printed `rustup could not choose a version of cargo`, because HOME was moved. That has no effect on the AGENTS.md logic.

Max severity: minor
Ship allowed: yes
