---
validated: yes
---
# Plan — s142-payload-refuses-foreign-files

[Story](../stories.md) · [Research](../research/s142-payload-refuses-foreign-files.md)

Branch `story/s142-payload-refuses-foreign-files`. Read `docs/research/s142-payload-refuses-foreign-files.md`
first; this plan builds on it without repeating it.

**`Owns` corrected (2026-10-18).** Task 6 edits `tests/drop-keeps-modified.test.sh:184`; the lead added
that file to the `Owns` of s142 on `main` (PR #131, commit c5b4d49) and moved this lane onto it.

## Story
The payload under `<root>/polype/` signs itself with `payload.sums`; a file there that Polype did not lay
down and does not ship stops `install`, `update`, `init` and `remove --global` before any write;
`--set-aside` no longer applies under `polype/`; a synced newer payload still installs; an unsigned
payload stops runs launched from it and is reported by `check`/`remove --global`. ADR-0095 records it and
supersedes ADR-0088 on that one point. Criteria: `payload_signs_itself`,
`foreign_payload_file_stops_install`, `synced_payload_still_installs`,
`old_set_aside_never_put_back_in_payload`, `remove_stops_on_foreign_payload_file`,
`unsigned_payload_says_so`, `adr_records_the_payload_rule`.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `payload.sums` writing | this repository: the checksums lines `record_sum` already writes (`bin/polype:614-619`), filtered to `polype/` paths | — |
| Loading `payload.sums` | this repository: the `read -r crc size path` loop of `load_checksums` (`:602-609`) | — |
| Foreign-file scan | new code, built on `find` and the `KNOWN` manifest map pattern of `refuse_collisions` (`:193-197`) | no existing function walks the payload directory: `refuse_collisions` walks shipped destinations only |
| Payload collision stop | this repository: the existing loop and messages of `refuse_collisions` (`:213-220`) | — |
| Remove check | the same scan as task 3, called with a remove flavour | — |

## Tasks
1. [x] **Know where the payload is and whether it is signed.** Near `bin/polype:36-42`, add
   `payload_dir` = `<home>/polype` and `from_payload` = yes when `base` equals it; compare physical paths
   (`cd … && pwd -P` on both sides; `<home>` may not exist yet → not from the payload). Add
   `load_payload_sums`: fills a global map `PAYLOAD_SUMS[path]` from `$payload_dir/payload.sums` (same
   line form as `checksums`: `<crc> <size> polype/<…>`) and sets `payload_signed=yes|no`; call it after
   `load_checksums` in `cmd_install`, `cmd_update`, `cmd_check`, `cmd_remove`. Add
   `is_payload_state_file <rel>` for `manifest`, `checksums`, `version`, `payload.sums`, `*.next`,
   `*.polype-next`. On a global run whose source is not the payload, write `payload.sums` right after
   `finish_sums` in both `cmd_install` and `cmd_update`: the lines of the just-moved `checksums` whose
   path starts with `polype/`, through `payload.sums.next` then `mv`. It never enters the manifest.
   — Test `test_payload_signs_itself`: fails if the file is not written, lists a state file, misses a
   payload file of the manifest, or a sum differs from the file's `cksum`; also rewritten by
   `update --global` from the repository after being deleted.
2. [x] **A run from the payload ships what the payload signs, and only when it is signed.** At the top
   of `collect_shipped` (`:163`), when `from_payload` and not signed: exit 1 before any write with
   `polype: the payload in <payload_dir> is not signed (no payload.sums): run the install once from a
   Polype repository (<clone>/bin/polype install --global); nothing written`. In `shipped_pairs`
   (`:137-145`), when `from_payload`, skip a source whose `polype/<from-rel>/<rel>` is not a key of
   `PAYLOAD_SUMS` (so `PAYLOAD_SUMS` must be loaded before `collect_shipped`, or `collect_shipped` loads
   it). A manifest file the synced payload no longer lists is thus not shipped and falls under the
   existing drop rules. — Tests `test_unsigned_payload_says_so` (install/update/init part: exit 1,
   snapshot of home and project unchanged, says `not signed` and `Polype repository`) and
   `test_synced_payload_still_installs` (fails without the filter: the dropped file would be laid again).
3. [x] **Refuse foreign payload files and payload collisions.** New `refuse_foreign_payload_files`,
   called in `cmd_install` and `cmd_update` after `load_checksums`/`load_payload_sums` and before
   `refuse_taken_kept_copies`, only when `mode=global` or `from_payload` (so `init` from the payload is
   covered, a project run from a repository is not). It walks `find "$payload_dir" ! -type d` (files and
   links). A path is skipped when it is a state file, or listed in **the global manifest**
   (`$payload_dir/manifest`, never `$manifest`, which is the project's under `init`), or — from the
   payload — a key of `PAYLOAD_SUMS`, or — from a repository — a shipped destination. A `*.before-polype`
   under `polype/` is foreign whatever the manifest says (see The pivot). Any foreign path → each named
   `polype: not laid down by Polype, inside the payload: <abs path>`, then `polype: nothing written; move
   each one out of <payload_dir> (--set-aside does not apply under polype/)`, exit 1. In
   `refuse_collisions`, a collision whose destination is under `polype/` stops the same way before the
   set-aside branch (`:213`), whatever `set_aside` says. In `drop_laid_file`, drop the payload put-back
   (`:301-304`) and guard the generic put-back (`:316`) with `! is_payload_path`: the scan guarantees no
   `.before-polype` under `polype/` reaches them. Usage `:57-58`: say `--set-aside` does not apply under
   `polype/`. — Tests `test_foreign_payload_file_stops_install` (from the payload: `update`, `install`,
   `init <project>`; from the repository: `install --global --set-aside`; a symlink; a collision at
   `polype/bin/polype` under `--set-aside`; each exit 1 with an unchanged snapshot and the path named)
   and `test_old_set_aside_never_put_back_in_payload` (a hand-made
   `polype/method/commands/po-help.md.before-polype` stops `update` from the payload and `install` from
   the repository).
4. [x] **`remove --global` and `check --global`.** In `cmd_remove`, before the loop (`:817`) and in global
   mode only, scan the payload: foreign = not a state file, not in the manifest, not in `PAYLOAD_SUMS`,
   and not `<p>.before-polype` for a manifest path `p` (the `held` path `:823-829` stays). Foreign → named,
   exit 1, nothing written; reads no shipped source. Unsigned → one line `polype: the payload is not
   signed (no payload.sums): remove trusts the manifest alone`, then carry on. In `cmd_check`, global and
   unsigned → `polype: the payload is not signed (no payload.sums); run the install once from a Polype
   repository`, exit status unchanged by it. — Tests `test_remove_stops_on_foreign_payload_file`
   (foreign `polype/notes.md` → exit 1, snapshot unchanged, named; a file listed in `payload.sums` and
   absent from the manifest does not stop it), the check/remove part of `test_unsigned_payload_says_so`,
   and the remove part of `test_old_set_aside_never_put_back_in_payload` (the hand-made `.before-polype`
   is back at `polype/method/commands/po-help.md` after `remove --global`).
5. [x] **New test file** `tests/payload-refuses-foreign-files.test.sh` holding the seven tests above,
   reusing the throwaway-home helpers of `tests/payload-kept-outside.test.sh:7-45` (copied, as each
   test file defines its own) and a method copy for the synced case: home A from a copy with one new
   command and one command removed, home B from `$ROOT`; copy A's `polype/bin`, `polype/method` and
   `polype/payload.sums` over B's with `cp -r`; `$B/polype/bin/polype update --global` → exit 0, the new
   command laid in `commands/` and listed in the manifest, the removed one gone from `commands/`.
6. [x] **Existing tests that change with the rule** (say so in the record):
   `tests/install-collisions.test.sh:165-177` — the `polype/bin/polype` file now stops
   `install --global --set-aside` (exit 1, nothing set aside); remove it, then keep the `agents/` set-aside
   and the link part as they are. `tests/payload-kept-outside.test.sh:165-176` — the "aside" home installs
   first, then writes `$A.before-polype` by hand before editing `$A`; the `remove --global` assertions stay.
   `tests/drop-keeps-modified.test.sh:184` — `superseded-by: \[ADR-0092, ADR-0095\]` (**needs the `Owns`
   correction**). `tests/global-install.test.sh` should need no change; touch it only if a run there
   turns out unsigned.
7. [x] **ADR and doc.** `docs/decisions/ADR-0095-la-charge-utile-se-signe-et-n-accueille-aucun-fichier-etranger.md`
   from `templates/adr.md`, `status: accepted`, `supersedes: [ADR-0088]`, scope `story s142-…`: the
   payload signs itself; a file outside the signature stops the run (#118); an edit of a signed file does
   not leave the payload (#115), implemented by s143 and said so; options turned down (trust the payload
   run from itself; require a repository as source; file a foreign file into `polype.kept/`; spread the
   edit while saying so), each with the AC's reason; replaces ADR-0088 only on setting aside under
   `polype/`. ADR-0088: only `superseded-by: [ADR-0092, ADR-0095]` changes. `docs/installation.md`: the
   opening (`:3-6`), "Les collisions" (`:233-244`), "Les fichiers d'état" (a `payload.sums` row, keeping
   the pinned phrases), the chezmoi section (`:160-181`: `payload.sums` is tracked with `bin/` and
   `method/`; an unsigned payload asks for one run from a repository), "Ce que `remove` garde" (stops on a
   foreign payload file), citing ADR-0095; prose ≤ 100 chars. — Test `test_adr_records_the_payload_rule`
   (ADR-0095 accepted, supersedes ADR-0088, names `#118`, `#115`, `s143`, `polype.kept`; ADR-0088 still
   accepted with the new link; `installation.md` names `payload.sums` and `ADR-0095`).
8. [x] **Full suite** once, `po-run --story s142-payload-refuses-foreign-files --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `method/`, `.claude/`, `.polype/` end with an empty diff (`method/AGENTS.md`'s "unless `--set-aside`
  moves it (ADR-0088)" stays: outside `Owns`).
- `recorded_mode` keeps its name; ADR-0088's body and every other ADR's body unchanged.
- No s143 behaviour: the `cmd_update` comparison at `bin/polype:731` and the "left modified" count are
  untouched; an edited signed file run from the payload keeps today's behaviour.
- Project-mode collisions and collisions outside `polype/` keep `--set-aside` (ADR-0088): the existing
  `tests/install-collisions.test.sh` project cases and `tests/drop-keeps-modified.test.sh:160-162` stay green.
- `polype.kept/` rules (ADR-0093) unchanged; `remove --global` still moves edits out before deleting.
- No write before the last check: every new stop leaves the home and the project snapshot unchanged.
- No `git worktree`, `switch`, `checkout`, `stash`; no text from Killer SaaS (`tests/overlap.test.sh`).

## The pivot
`payload.sums` becomes the payload's identity: written only by runs from a repository, read by runs from
the payload as the list of their sources, and by `remove` as the list of what it may delete. Ways it
could be wrong:
- **Run origin misread.** `base` and `root` use logical `pwd` (`bin/polype:36`, `:109`); with a symlinked
  `~/.claude` or a PATH link to the physical path, a string compare would call a payload run a repository
  run and skip the filter. Compare `pwd -P` on both; check with the symlink test of
  `tests/global-install.test.sh:161-176`.
- **Stale `.before-polype` under a polluted manifest.** The AC defines foreign as "absent from the
  manifest", but a `.before-polype` the bug already put in a manifest (research, step 3) would then be
  dropped with `rm` as an unmodified laid file and lost. This plan treats any `*.before-polype` under
  `polype/` as foreign in install/update/init, in line with `old_set_aside_never_put_back_in_payload`;
  `remove` exempts `<p>.before-polype` for a manifest path `p`, so its held path still puts it back.
- **Synced payload over an older install.** New files are not in B's manifest: they pass only because
  `payload.sums` lists them and source equals destination (`:201`); dropped ones pass only because the
  manifest lists them. `test_synced_payload_still_installs` exercises both halves.

## Files touched
`bin/polype`, `docs/installation.md`, `docs/decisions/ADR-0095-la-charge-utile-se-signe-et-n-accueille-aucun-fichier-etranger.md`,
`docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md` (frontmatter),
`tests/payload-refuses-foreign-files.test.sh` (new), `tests/install-collisions.test.sh`,
`tests/payload-kept-outside.test.sh`, `tests/drop-keeps-modified.test.sh` (after the `Owns` correction),
`docs/research/…`, `docs/plans/…`, `docs/verif/…`.

## Test strategy
Seven new tests, one per criterion, in `tests/payload-refuses-foreign-files.test.sh`, each driving the
real `bin/polype` in a throwaway `HOME`/`CLAUDE_CONFIG_DIR` (guarded as in the existing files), plus
three existing tests adjusted (task 6): 10 within `Test budget` 25. Each stop asserts exit 1, the path
named, and an unchanged snapshot. Bite points the reviewer can neutralise: the `payload.sums` write
(task 1), the `PAYLOAD_SUMS` filter in `shipped_pairs` (synced test), the unsigned stop, the foreign scan,
the `polype/` branch in `refuse_collisions`, the `.before-polype` rule, the remove scan and its held-path
exemption. Task tests run with `bash tests/run.sh payload-refuses-foreign-files.test.sh` and the two
adjusted files; the full suite once at the end through `po-run` (task 8). No visual check.

## Done when
All seven criteria hold, the full suite is green through `po-run`, the verification record is complete,
one commit on `story/s142-payload-refuses-foreign-files` carries code, tests, ADR, doc, research and plan,
and a review with no open critical finding lets `/po-ship` land it.
