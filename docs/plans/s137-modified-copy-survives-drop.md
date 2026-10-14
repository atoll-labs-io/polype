---
validated: yes
---
# Plan — s137-modified-copy-survives-drop

[Story](../stories.md) · [Research](../research/s137-modified-copy-survives-drop.md)

Branch `story/s137-modified-copy-survives-drop`. Read `docs/research/s137-modified-copy-survives-drop.md`
first; this plan builds on it without repeating it.

## Story
Fixes #89 and #96. A copy Polype laid, edited by the person (recorded sum exists and differs, the
`has_drifted` sense), that `init`, `install`, `update` or `remove` no longer lays, stays on disk byte for
byte, leaves the manifest and both sum files, and is reported on stderr as `polype: modified, kept:
<path>`. It becomes the person's file: the next run shipping that path stops on it as a collision
(ADR-0088). Criteria: `init_keeps_a_modified_copy`, `update_ghost_keeps_a_modified_copy`,
`remove_keeps_a_modified_copy`, `modified_copy_over_a_set_aside_file`, `kept_copy_becomes_the_persons`,
`header_lists_the_mode_file`, `adr_records_the_choice`.

The choice itself was settled by the owner at framing (M14 objective, 2026-10-14): ADR-0092 records
it as `accepted`; there is no technical choice left open.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| "is this copy modified?" in `drop_laid_file` | already here: `has_drifted` (`bin/polype:560`) and `load_checksums` (`bin/polype:524`) | — |
| dropping kept entries from manifest and sums | already here: `cmd_install`/`cmd_update` rebuild both from `SHIPPED_LINES` only, `finish_sums` (`bin/polype:549`); `remove` deletes all state | — no new code |
| treating a kept copy as the person's file next time | already here: `refuse_collisions` (`bin/polype:165`) | — no new code |
| sandbox helpers of the new test file | per-file convention: copy `sandbox`/`new_project`/`run`/`ok`/`says`/`snapshot`/`copy_of_the_method` from `tests/install-collisions.test.sh:8-61` | `tests/lib.sh` has no installer sandbox; each test file is sourced alone (`tests/run.sh:17`) |
| the "kept" branch and its message (≈10 lines) | new code | no existing function reports a kept file; the existing `modified, left as it is` (`bin/polype:673`) is for shipped files |

## Tasks
1. [x] **Protect in `drop_laid_file`** (`bin/polype:236`). Before `rm`, when `[ -f "$root/$dest" ] &&
   has_drifted "$dest"`: print `polype: modified, kept: $root/$dest` on stderr and `return 1`, touching
   nothing; when `$root/$dest.before-polype` also exists (or is a link), the line instead reads
   `polype: modified, kept: $root/$dest; $root/$dest.before-polype left as it is` and neither file
   moves. Otherwise unchanged behaviour, `return 0`. Update the function's comment in one line (kept
   copy and why). The `[ -f ]` guard is required: `sum_of` on a missing file errors.
   Test: `test_init_keeps_a_modified_copy`, `test_modified_copy_over_a_set_aside_file`.
2. [x] **Load sums and make callers errexit-safe.** `cmd_install`: call `load_checksums` after
   `refuse_collisions`, before the drop loop (`bin/polype:595`), and write the drop as
   `if [ -z "${SHIPPED[$old]-}" ]; then drop_laid_file "$old" || true; fi`. `cmd_update`
   (`bin/polype:639`): `if [ -z "${SHIPPED[$old]-}" ] && drop_laid_file "$old"; then ghosts=$((ghosts + 1)); fi`,
   so a kept ghost is not counted in "removed". `cmd_remove`: call `load_checksums` before the loop
   (`bin/polype:731`); add a branch before `drop_laid_file` so a global payload path under `polype/`
   is deleted with `rm -f` and never reported kept (`rm -rf "$state_dir"` takes it anyway); the other
   lines call `drop_laid_file "$path" || true`. Without `load_checksums`, `has_drifted` aborts the run
   on an arithmetic error (research, Structuring facts); without the `if`/`|| true`, `set -e` aborts it.
   Test: `test_init_keeps_a_modified_copy` (install), `test_update_ghost_keeps_a_modified_copy` (count),
   `test_remove_keeps_a_modified_copy` (project and global payload halves).
3. [x] **Header comment** (`bin/polype:15-19`): state files of a project name `.polype/mode` (the
   activation mode `update` keeps, ADR-0091) beside manifest, checksums, version and
   `.claude/.polype-checksums`. Do not rename `recorded_mode`. Test: `test_header_lists_the_mode_file`.
4. [x] **ADR-0092 and ADR-0088.** Write `docs/decisions/ADR-0092-une-copie-modifiee-que-polype-ne-pose-plus-reste-en-place.md`
   from `templates/adr.md`, in French: `status: accepted`, `scope: story s137-modified-copy-survives-drop`,
   `supersedes: [ADR-0088]`. Options: A keep in place, becomes the person's file (chosen, owner
   2026-10-14); B set aside under a new suffix — écartée, one more file to sort; C stop the command as
   for a collision — écartée, a repair `init` blocked by one edit; D exempt `remove` — écartée, the edit
   is lost at the moment Polype is taken away. Consequences name the two limits: a copy with no
   recorded sum is deleted as before (fresh clone, `.claude/` sums out of git since ADR-0087: git keeps
   the edit), and at `remove --global` the payload under `~/.claude/polype/` goes whole with its
   directory, with no "kept" line. Say it replaces ADR-0088 only on the put-back of a `.before-polype`
   whose covering copy was modified. In ADR-0088 change only `superseded-by: []` → `superseded-by: [ADR-0092]`.
   Test: `test_adr_records_the_choice`.
5. [x] **`docs/installation.md`.** In `### Les collisions`, after "`remove` remet chaque fichier mis de
   côté à sa place", add the exception (modified covering copy: both stay, ADR-0092). Add a
   subsection `### Une copie modifiée que Polype ne pose plus` at the end of `## \`install\` ou
   \`update\``: what "modified" means (recorded sum differs), the four commands, the stderr line
   `polype: modified, kept: <chemin>`, out of the manifest and sums, becomes the person's file (next
   pose stops on it, `--set-aside`), not counted in « removed », and the two limits. In
   `## Ce que remove garde`, add kept modified copies to what stays. Prose lines ≤100 chars; keep
   every phrase pinned by `tests/docs-and-eval-cleanup.test.sh:13-22`. Test: `test_adr_records_the_choice`
   (doc half) and the existing line-length test.
6. [x] **`tests/drop-keeps-modified.test.sh`**, seven functions named after the criteria, each in a
   throwaway `HOME`/`CLAUDE_CONFIG_DIR` under `$SCRATCH` with a guard refusing to run elsewhere:
   - `test_init_keeps_a_modified_copy`: `install <p>`; edit `.claude/commands/po-architect.md`, keep
     a copy; `init <p>`; `cmp` byte for byte; absent from `.polype/manifest`, `.polype/checksums`
     and `.claude/.polype-checksums` (absent file counts); output has `polype: modified, kept: $P/.claude/commands/po-architect.md`;
     an unmodified extra (`.claude/agents/reviewer.md`) is gone; manifest = count of
     `method/templates` + `method/hooks` files (23 today).
   - `test_update_ghost_keeps_a_modified_copy`: `copy_of_the_method`; `install` from the copy; edit
     copy X, leave Y; delete both from the copy's `method/`; `update`: X kept and reported, out of
     manifest and local sums; Y gone and never reported kept; final line says `1 removed`.
   - `test_remove_keeps_a_modified_copy`: `install <p>`, edit one copy, `remove <p>`: it stays with
     its content, reported; an unmodified copy is gone. Global half: `install --global`, edit a file
     under `$H/polype/method/`, `remove --global`: `$H/polype` gone and no `modified, kept:` line
     naming `polype/`.
   - `test_modified_copy_over_a_set_aside_file`: `echo mine > .claude/agents/reviewer.md`,
     `install <p> --set-aside`, edit the laid `reviewer.md`, `remove <p>`: `reviewer.md` holds the edited
     content, `reviewer.md.before-polype` holds `mine`, the output line names both paths.
   - `test_kept_copy_becomes_the_persons`: after the init of the first test's setup, `install <p>`
     exits 1 and the snapshot is unchanged, output names the path; `install <p> --set-aside` moves the
     edited file to `.before-polype` and lays the shipped one.
   - `test_header_lists_the_mode_file`: the comment lines of `bin/polype` before `set -euo pipefail`
     contain `.polype/mode`; `recorded_mode()` is still defined.
   - `test_adr_records_the_choice`: exactly one `ADR-0092-*.md`, `status: accepted`, frontmatter
     `supersedes: [ADR-0088]`; contains `Écartée` and phrases for the three rejected options and the two
     limits (`ADR-0087`, `polype/`); ADR-0088 frontmatter has `superseded-by: [ADR-0092]` and stays
     `status: accepted`; `docs/installation.md` contains `modified, kept:` and `ADR-0092`.
   Run it alone: `bash tests/run.sh drop-keeps-modified.test.sh`.
7. [x] **Full suite** once, at the end: `po-run --story s137-modified-copy-survives-drop --label test
   -- 'bash tests/run.sh'`. No type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `README.md`, `method/`, `.claude/`, `.polype/`, `tests/` other than the new file: empty diff.
- In ADR-0088, only the `superseded-by` line changes (`git diff` shows one line); its `status` stays
  `accepted`. No other ADR is touched.
- `recorded_mode` keeps its name and body (`bin/polype:94-101`).
- The update message for shipped modified files (`modified, left as it is:`, `bin/polype:673`) and the
  `put back:` paths (`bin/polype:240-242`, `:752`) keep their wording.
- `cmd_install` still overwrites a shipped copy even when modified (reinstall is the "clean method"
  path, `docs/installation.md:279`): the protection covers only entries no longer laid.
- `refuse_collisions` and the global hold-aside branch (`bin/polype:733-741`) are unchanged.
- No test runs `bin/polype` outside a throwaway `HOME`/`CLAUDE_CONFIG_DIR`.
- `po-session.sh` (#95) and the test helper of #102 are s138's: untouched.

## The pivot
The whole fix rests on `drop_laid_file` being the single deletion point and on `has_drifted` being
the right meaning of "modified". Ways it could be wrong:
- A caller loses the "kept" status or aborts: compare each of the three call sites with Task 2 —
  `load_checksums` before the loop, call inside `if`/`|| true`. A missing `load_checksums` aborts the
  run with an arithmetic error (proved in research); bite: drop it from `cmd_install` → the init test fails.
- The global payload exemption is wrong-way: a modified file under `polype/` reported kept then
  destroyed by `rm -rf`; compare with the global half of `test_remove_keeps_a_modified_copy`.
- Absolute paths chosen for the line (`$root/$dest`, as `put back:` in the same function) where a
  reader might expect relative ones as in update's `modified, left as it is:`; tests match the absolute
  form, so a change of form is a deliberate edit of both.

## Files touched
`bin/polype`, `docs/installation.md`, `docs/decisions/ADR-0092-une-copie-modifiee-que-polype-ne-pose-plus-reste-en-place.md`
(new), `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md`
(frontmatter line), `tests/drop-keeps-modified.test.sh` (new), plus this plan, the research and
`docs/verif/s137-modified-copy-survives-drop.md`.

## Test strategy
Seven bash tests in one file, within `Test budget` (25). Each drives the real installer end to end in
a sandbox — the installer's behaviour is the rule; there is no lower layer to test it at. Bites the
reviewer can run: remove the `has_drifted` branch of `drop_laid_file` → the four behaviour tests fail;
drop `load_checksums` from `cmd_install` or `cmd_remove` → init or remove test fails; count ghosts
unconditionally → `1 removed` fails; drop the payload branch of `cmd_remove` → the global half fails;
drop the `.before-polype` variant of the line → set-aside test fails. Existing tests that pin the
neighbouring behaviour stay unchanged (research, Traps). No visual check.

## Done when
All tasks ticked; `bash tests/run.sh` green through `po-run`; the reviewer finds no critical; one
commit `s137-modified-copy-survives-drop: …` landed through a pull request; `#89` and `#96` closed by it.
