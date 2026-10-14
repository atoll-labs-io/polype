# Review: s137-modified-copy-survives-drop

[Story](../stories.md) · [Plan](../plans/s137-modified-copy-survives-drop.md) · [Verification](../verif/s137-modified-copy-survives-drop.md)

Reviewed tree: 8172afbd222d53b3c9804734b3415472cb25acfc
Fix loop: 0
Lenses run: none (the diff touches a bash installer, docs, ADRs and a test file; it has no auth, route, migration, lockfile or server-side query trigger)

## Summary
The change does what the story asks for project targets. A modified copy that Polype no longer lays survives `init`, `install`, `update` and `remove`, and is reported as `polype: modified, kept: <path>`. Ghost entries are counted correctly, the `.before-polype` variant works, and a later pose stops on the kept copy as a collision. All diff paths are inside `Owns`. There is one gap, graded major: under `--global`, a kept modified file under the payload (`~/.claude/polype/`) does not "become the person's file". The next run from the payload ships it again as live method, which contradicts ADR-0092 and `docs/installation.md`.

## Scope check
`git diff --name-status main...story/s137-modified-copy-survives-drop` lists these paths: `bin/polype` (M), `docs/installation.md` (M), ADR-0088 (M, frontmatter only), ADR-0092 (A, named by the plan), `tests/drop-keeps-modified.test.sh` (A), and the story's own research, plan and verif files. Every path is covered by the `Owns` line or is in scope by construction. No path belongs to another running story; s138 owns `method/hooks/po-session.sh` and `tests/update-keeps-mode.test.sh`, and the diff touches neither.

## Step 1: what is already proven
- `po-gate verif-current s137-modified-copy-survives-drop` exited 0. The record is complete, `Tree: a7bb461…`, with one `Unit suite` row (`bash tests/run.sh`) that exited 0 on tree `84602f7…`, which has the same code outside `docs/`.
- With `Verification mode: record`, I relied on that row and did not rerun the full suite. The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
- The record's "Not proven here" section names macOS bash and a `remove` without `jq`.
- `QA stage: —`, so the story does not go to QA.

## Step 2: references
Every function the diff calls exists with the signature it uses:
- `has_drifted` (bin/polype:571)
- `load_checksums` (:535)
- `drop_laid_file` (:238)
- `refuse_collisions` (:192)
- `finish_sums` (:560)

`has_drifted` needs `RECORDED`, and all three callers now call `load_checksums` before their drop loop (lines 600, 641, 744).

## Step 3: diff against the plan
- Tasks 1 to 7 are all present.
- The run interdicts hold:
  - `recorded_mode` is unchanged.
  - The ADR-0088 diff is the single `superseded-by` line, and its status stays `accepted`.
  - The `modified, left as it is:` and `put back:` wording is unchanged.
  - `refuse_collisions` and the global hold-aside branch are unchanged.
  - Nothing changed under `method/`, `.claude/`, `.polype/` or `README.md`.
- The `## Reuse` rows match the diff.

## Step 4: tests
- **Floor:** `po-gate floor-guard s137-modified-copy-survives-drop main` exited 0, so nothing was lowered.
- **Coverage:** there are 7 tests, within `Test budget` (25). Each drives the real installer in a sandboxed `HOME`/`CLAUDE_CONFIG_DIR` with a guard. The fixtures are real installs, nothing is mocked, and none of the six kinds of test that prove nothing appears.
- **Bite:** I ran only `tests/drop-keeps-modified.test.sh` each time. The baseline was 7 passing. After each mutation I restored `bin/polype` and confirmed it with `git diff --exit-code`.
  1. `has_drifted` guard in `drop_laid_file` replaced with `false`: 5 failures.
  2. `load_checksums` removed from `cmd_remove`: 2 failures (`remove_keeps…`, `modified_copy_over_a_set_aside_file`).
  3. The `polype/` payload branch of `cmd_remove` disabled: 1 failure (`remove_keeps…`, global half).
  4. `load_checksums` removed from `cmd_install`: 2 failures (`init_keeps…`, `kept_copy_becomes_the_persons`).

  Every rule I disabled was caught by at least one test.

## Step 5: values
- "Modified" means the recorded sum exists and differs, which is the `has_drifted` sense the story's notes require.
- The `[ -f ]` guard before `has_drifted` prevents `sum_of` from running on a missing file.
- The line uses absolute paths (`$root/$dest`), the same as `put back:` in the same function, as the plan chose.
- The manifest count of 23 is computed from `method/templates` plus `method/hooks`, not hard-coded.

## Step 6: neighbours
- `drop_laid_file` has exactly three callers (`cmd_install`, `cmd_update`, `cmd_remove`), and all three are errexit-safe.
- `cmd_check` is unaffected.
- `prune_empty_dirs` cannot remove a directory that still holds a kept file.

## Findings

### F1: major. A kept modified payload file comes back as live method under `--global`
`bin/polype:238-247` (`drop_laid_file`), reached from `cmd_install` and `cmd_update` in global mode.

When a file under `~/.claude/polype/` (the payload) is no longer shipped and the person edited it, it is now kept in the payload directory. The payload is also the source tree when Polype runs from `~/.claude/polype/bin/polype`, which is the normal entry through the `~/.local/bin/polype` symlink (`docs/installation.md:61`). `shipped_pairs` then lists the kept file as shipped. It is its own source, so `refuse_collisions` sees no difference and does not stop. The file is laid again as a live command and silently put back in the manifest.

I reproduced this in a throwaway HOME (`/tmp/tmp.h1jzLtPCCf`):
1. `install --global` from the worktree.
2. Appended a line to `polype/method/commands/po-help.md`.
3. `install --global` from a copy with `po-help.md` deleted. Output: `modified, kept: …/polype/method/commands/po-help.md`, absent from the manifest.
4. `~/.claude/polype/bin/polype update --global`. Result: `commands/po-help.md` reappeared in `~/.claude/commands/` with the edit, and both paths are back in the manifest.

The same mechanism would ship a kept payload template or hook into every project through `polype init`.

This contradicts ADR-0092 and `docs/installation.md`, which say the kept copy "devient le fichier de la personne" and that the next pose stops on it as a collision. A command retired by Polype comes back without anyone deciding it.

It is contained: the person must have edited a file inside the payload, and no data is lost. Possible fixes:
- extend the `polype/` exemption that `cmd_remove` already has to `drop_laid_file` in global mode for paths under `polype/`, and name it as a limit in the ADR and the docs; or
- move such a file outside the payload.

Either way the choice should be recorded, since ADR-0092 is accepted and is not edited.

### F2: minor. The update test does not check the shared sum file
`tests/drop-keeps-modified.test.sh`, `test_update_ghost_keeps_a_modified_copy`, checks that the kept ghost is gone from the manifest and from `.claude/.polype-checksums`, but not from `.polype/checksums`. The init test checks all three files through `out_of_the_state`. Using `out_of_the_state` here as well would close the gap. The code is correct today, because `finish_sums` rebuilds `.polype/checksums` from `SHIPPED_LINES`.

## Not verified
- **macOS bash (brew) and a project `remove` on a machine without `jq`.** Both appear in the record's "Not proven here", and only Linux bash was run. Run the new test file under macOS bash 5, and run `remove` with `jq` absent from PATH.
- **`remove --global` on a modified non-payload global copy (`~/.claude/commands/…`).** No test covers it; I only read the code, which goes through `drop_laid_file` and should keep the copy. To cover it, edit `~/.claude/commands/po-plan.md` after `install --global`, run `remove --global`, and check that the file stays and the `kept` line is printed.
- **A fresh clone, where the `.claude/` sums are absent.** ADR-0092 documents that the copy is deleted in that case, and no test covers it. Clone a project with an edited, committed `.claude/` copy, run `init`, and confirm that git still holds the edit.
- **`docs/installation.md` line-length and pinned-phrase tests.** I relied on the recorded full-suite pass and did not rerun them.

Review status: complete

Max severity: major
Ship allowed: yes
