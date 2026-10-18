# Review — s142-payload-refuses-foreign-files

[Story](../stories.md) · [Plan](../plans/s142-payload-refuses-foreign-files.md) · [Verification](../verif/s142-payload-refuses-foreign-files.md)

Diff reviewed: `git diff main...story/s142-payload-refuses-foreign-files`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 0377847370dd171fbbdb5b81d6e51df770bbc08a

## Ownership
I listed the diff with `git diff --name-status main...story/s142-payload-refuses-foreign-files` and checked each path against the story's `Owns` (docs/stories.md:2245).
- [x] Every path is inside `Owns`:
  - `bin/polype`
  - `docs/installation.md`
  - the ADR-0095 file (added)
  - the ADR-0088 file (frontmatter only)
  - `tests/drop-keeps-modified.test.sh` (added to `Owns` by c5b4d49, as the plan says)
  - `tests/install-collisions.test.sh`
  - `tests/payload-kept-outside.test.sh`
  - `tests/payload-refuses-foreign-files.test.sh`
  - The research, plan and verif files are the story's own evidence.
- [x] Nothing outside `Owns`.
- [x] No path inside another running story's `Owns`. s143 shares `bin/polype` and `docs/installation.md`, but it depends on s142 and the story order keeps the two serial.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s142-payload-refuses-foreign-files` exits 0. The record is complete, its `Tree:` matches the code outside `docs/`, and its Unit suite row (`bash tests/run.sh`) exited 0. I relied on that record and did not rerun the full suite.
- [x] The project has no type check, no E2E and no build command (`Typecheck: —`, `E2E: —`, `Build: —`), so I ran none.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–8 are all present. I found nothing outside the plan.
  - `from_payload`/`payload_dir` compare physical paths.
  - `load_payload_sums`, `is_payload_state_file` and `sign_payload` are present; signing happens after `finish_sums` in both install and update.
  - The unsigned stop in `collect_shipped` and the `PAYLOAD_SUMS` filter in `shipped_pairs` are present.
  - `refuse_foreign_payload_files` runs before `refuse_taken_kept_copies` and `refuse_collisions`.
  - The payload-collision stop in `refuse_collisions` is present, and the payload put-back in `drop_laid_file` is gone.
  - The remove and check paths are done, along with the usage text, the ADR and the docs.
- [x] I checked each run interdict:
  - `method/`, `.claude/` and `.polype/` have an empty diff.
  - `recorded_mode` keeps its name.
  - Only ADR-0088's `superseded-by` changed.
  - No s143 behaviour was added: the `cmd_update` comparison and the "left modified" count are untouched.
  - Project-mode collisions and collisions outside `polype/` keep `--set-aside`: `refuse_collisions` only branches on `is_payload_path`, which needs `mode=global`.
  - The `polype.kept/` rules are unchanged, and remove still moves edits out first.
  - Every new stop happens before the first write. The `stops` helper checks unchanged snapshots of the home and the project.
  - There are no git worktree, switch or stash calls.

## References
- [x] Every function the diff calls exists in `bin/polype`: `load_checksums`, `finish_sums`, `refuse_taken_kept_copies`, `move_out_of_payload`, `has_drifted`, `is_payload_path`. `state_dir` is `$root/polype` in global mode (bin/polype:120), so `payload.sums` lands in `$payload_dir`. `stamp_mode` writes nothing in global mode, so no unlisted state file can be read as foreign.
- [x] The `PAYLOAD_SUMS` keys (`polype/<from-rel>/<rel>`) match the lines `sign_payload` takes from `checksums`, for global, init and project pairs alike. The state-file list matches the acceptance criterion exactly.

## Rules
- [x] The `AGENTS.md` conventions hold: code and comments are in English, the docs are in French, and the tests are bash with `tests/lib.sh` helpers.
- [x] No accepted ADR is contradicted. ADR-0095 supersedes ADR-0088 on one point only, and ADR-0088 stays accepted with its link updated, as ADR-0092 did before.

## Tests
- [x] Floor: `po-gate floor-guard s142-payload-refuses-foreign-files main` exits 0, so nothing was lowered.
- [x] The assertions pin down every acceptance criterion: exit code, the path named, an unchanged snapshot, and the sums compared with `cksum`. None of the six empty test shapes is present. The tests drive the real `bin/polype` in throwaway homes.
- [x] There are 7 new tests and 3 adjusted ones, within `Test budget` 25.
- [x] Bite. After each mutation I ran only the test files concerned, then restored `bin/polype` with `git checkout --` and confirmed `git diff --exit-code bin/polype` was clean:
  - `PAYLOAD_SUMS` filter in `shipped_pairs` removed → 1 failure (`synced_payload_still_installs`)
  - foreign scan disabled for install, update and init (run flavour) → 2 failures (`foreign_payload_file_stops_install`, `old_set_aside_never_put_back_in_payload`)
  - foreign scan disabled for remove → 1 failure (`remove_stops_on_foreign_payload_file`)
  - payload branch of `refuse_collisions` disabled → 1 failure (`foreign_payload_file_stops_install`)
  - unsigned stop in `collect_shipped` disabled → 1 failure (`unsigned_payload_says_so`)
  - remove exemption for `<p>.before-polype` removed → 1 failure (`old_set_aside_never_put_back_in_payload`)
- [x] Tests the story made false were changed with the rule, and the record says so: `install-collisions.test.sh` (the `polype/bin/polype` set-aside), `payload-kept-outside.test.sh` (the aside home) and `drop-keeps-modified.test.sh:184`.

## Neighbours
- [x] I read the other callers of the changed functions:
  - `drop_laid_file` is called from `cmd_install`, `cmd_update` and `cmd_remove`. Remove handles payload paths through its own `held` branch, so taking out the put-back changes nothing there.
  - `collect_shipped` is called by install and update only, so `check` from an unsigned payload still works.
  - `refuse_collisions` is called by install and update.
- [x] Probe in /tmp/tmp.7XMb5PeeB3 with `~/.claude` as a symlink: a foreign file stops `update --global` whether it is run through the link path or the physical path (exit 1, path named).

## Lenses
Lenses run: none. `bin/polype` is a local installer script. The diff has no auth, routes, migrations, lockfiles, dependency manifests or server-side code.

## Findings
- minor — tests/drop-keeps-modified.test.sh:184 — The assertion now expects `superseded-by: [ADR-0092, ADR-0095]`, but its failure message still says "ADR-0088 does not link to ADR-0092". A failure would point at the wrong missing link.
- minor — bin/polype:270 (`is_payload_state_file`) — `*.next` and `*.polype-next` match at any depth under `polype/`, not only the installer's own temp files at the top. A person's file named, say, `polype/method/notes.next` is never reported as foreign, and `remove --global` deletes it silently with `rm -rf`. This is what the acceptance criterion says ("tout `*.next`"), so it is noted, not treated as a defect. A later cycle could limit the pattern to the state files' own names.

## Not verified
- A real chezmoi sync between two machines. Both the test and this review simulate it with `cp -r` between two throwaway homes. A person should sync `~/.claude/polype/` (with `payload.sums`) to a second machine once and run `~/.claude/polype/bin/polype update --global` there.
- Upgrading a real existing global install that predates this fix (unsigned, possibly holding a `.before-polype` under `polype/` that an earlier install recorded in its manifest). Only fixtures covered this. A person should run `update --global` from the payload on their current machine and check that the "not signed" message appears, then run `install --global` from the repository.
- The full suite was not rerun. I relied on the verification record, whose run is on the same code outside `docs/`.
- Concurrent runs, and payload paths containing newlines, were not exercised.

Max severity: minor
Ship allowed: yes
