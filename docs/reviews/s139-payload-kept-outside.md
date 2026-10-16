# Review — s139-payload-kept-outside

[Story](../stories.md) · [Plan](../plans/s139-payload-kept-outside.md) · [Verification](../verif/s139-payload-kept-outside.md)

Reviewed tree: dfd3c8e513e7f510bdfe7c807286992237326061
Fix loop: 0
Review status: complete
Lenses run: none. bin/polype is a local installer: it has no auth, routes, HTTP, migration, lockfile or server-side code, so none of the four triggers is in the diff.

## Scope (Owns)
Every path in `git diff --name-only main...story/s139-payload-kept-outside` falls inside the story's `Owns` line or is its own pipeline evidence:
- covered by Owns: `bin/polype`, `docs/installation.md`, ADR-0093 (added, named in the plan), `docs/decisions/ADR-0092-*` (frontmatter only), `tests/drop-keeps-modified.test.sh`, `tests/payload-kept-outside.test.sh`
- pipeline evidence: `docs/plans/`, `docs/research/` and `docs/verif/` of this story

The run interdict holds: `method/`, `.claude/` and `.polype/` have an empty diff.

## Evidence reused
- `po-gate verif-current s139-payload-kept-outside` exited 0. With `Verification mode: record`, the unit suite (`bash tests/run.sh`) counts as proven green for this code, and I did not rerun it.
- The project has no type check, E2E or build command (all `—`), as the record's "Not proven here" says.
- `po-gate floor-guard s139-payload-kept-outside main` exited 0: nothing in the diff lowers the checks.
- The story does not go to QA (`QA stage: —`).

## Plan conformity
Tasks 1–8 are all in the diff:
- the five helpers
- the new `drop_laid_file` branch
- the new order in install and update: `load_checksums`, then `refuse_taken_kept_copies dropped`, then `refuse_collisions`
- the sweep after each lay-down loop
- the merged global branch of `cmd_remove`, with the "kept copies left in" line
- the new test file
- the #110 change and its meta test
- ADR-0092 frontmatter only; ADR-0093 and the docs

`recorded_mode` keeps its name, and `shipped_pairs` and `refuse_collisions` are unchanged. ADR-0092 keeps `status: accepted` and its body. The plan's `## Reuse` table matches the diff. I found no change the plan did not ask for.

## Bite tests
Each mutation was made in `bin/polype` and run only against the relevant test files. Each was undone with `git checkout -- bin/polype` and confirmed by `git diff --exit-code bin/polype`.

| # | Mutation | Tests failing |
| --- | --- | --- |
| 1 | move-out branch of `drop_laid_file` disabled (`if false && …`) | 3 of 6: payload_copy_moves_out, moved_copy_is_not_shipped, existing_kept_copy_never_overwritten |
| 2 | `refuse_taken_kept_copies` moved after `refuse_collisions` in `cmd_install` | 1: existing_kept_copy_never_overwritten (the `--set-aside` snapshot case) |
| 3 | `rm -f "$kept"` disabled in `drop_kept_copies_now_shipped` | 1: kept_copy_removed_once_shipped |
| 4 | `.before-polype` put-back disabled in the payload branch of `drop_laid_file` | **0** across payload-kept-outside, drop-keeps-modified, install-collisions and global-install (36 tests) |
| 5 | `drop_kept_copies_now_shipped` call disabled in `cmd_update` | **0** (14 tests) |

Tests: 7 new plus one changed assertion, within `Test budget: 25`. None of the six kinds of test that prove nothing turned up: the fixtures use real installs from a copy of the method, and the run from the payload goes through `$H/polype/bin/polype`.

## Findings

- major — bin/polype:301-304 — **A person's own file put back into the payload is shipped again.** When a dropped, modified payload file covered a `.before-polype` (a file the person had there before Polype), the new branch puts that file back at the payload path, under `polype/method/`. The next run from the payload lists it as a source again, which is the #111 mechanism this story removes.
  - Reproduced in /tmp/tmp.DRNqj8e0qg:
    1. a person's file at `polype/method/commands/po-help.md`, then `install --global --set-aside`
    2. edit the payload copy, drop the file from the method copy, `install --global`: it prints "moved out" and "put back", and the person's file is back in the payload
    3. `$H/polype/bin/polype update --global`: `commands/po-help.md` is laid again (from the person's file), and the manifest lists po-help twice
  - Not introduced from nothing: the unmodified branch (`bin/polype:315-319`, unchanged) already put payload files back this way before s139.
  - No test covers this branch (bite 4: 0 failures).
  - It needs a person's file inside `~/.claude/polype/` before install, so it is rare and causes no silent loss: major, not critical.
  - Fix direction: hold the file outside the payload, as `cmd_remove` does, or route it to `polype.kept/`. This needs an issue.
- minor — tests/payload-kept-outside.test.sh (test_kept_copy_removed_once_shipped) — The AC says "par une pose ou une mise à jour globale", but only `install --global` is tested. Disabling the sweep call in `cmd_update` (`bin/polype:742`) fails no test (bite 5). I checked by hand that `update --global` removes an identical kept copy and the emptied `polype.kept/`, so the code works; the gap is coverage only.
- minor — bin/polype:266 — `refuse_taken_kept_copies` tests `[ -f "$root/$path" ]` without the `[ ! -L … ]` that `drop_laid_file` (`:299`) and `cmd_remove` (`:820`) apply. A payload path that is a symlink to a drifted file can therefore be refused over a kept copy it would never have moved. The run stops too often; nothing is lost.
- minor — bin/polype:252-253 — `move_out_of_payload` runs inside `drop_laid_file … || true` or `&&`, where `set -e` does not apply. If `polype.kept/<dir>` exists as a regular file, `mkdir -p` and `mv` fail but the "moved out of the payload" line is still printed. The file stays in the payload, leaves the manifest, and is re-shipped from the payload. `refuse_taken_kept_copies` checks only the kept path itself, not its parents. Rare edge case.

No critical finding.

## Not verified
- **The full suite on this tree:** taken from the `po-run` record (exit 0, code tree equal to `Tree:` by `verif-current`), not rerun by me.
- **Type check, E2E, build:** the project has none (`—` in AGENTS.local.md).
- **Running `remove --global` from the payload's own `bin/polype` when that script is itself modified:** it would move its own running script. The research says the open inode survives this, but I did not run it. To cover it, run `$H/polype/bin/polype remove --global` after editing `$H/polype/bin/polype`.
- **Already known, outside this story:** the research's open question 4. A modified payload file Polype **still ships**, updated from the payload, is recorded as intact and spreads to the active copy. That issue is still to file; I did not check whether it has been.
- **A real `~/.claude`:** every check ran in throwaway homes under /tmp.

Two items for the lead: file the major finding and the open question 4 in `Issue tracker` (github), as Law 7 asks.

Max severity: major
Ship allowed: yes
