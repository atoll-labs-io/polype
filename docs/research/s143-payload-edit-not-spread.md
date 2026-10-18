# Research — s143-payload-edit-not-spread

[Story](../stories.md)

## Structuring facts
- **Root cause.** From the payload, a source *is* the payload file (`base` = `<home>/polype`,
  `bin/polype:36`, `:44`), and nothing compares it with what `payload.sums` signs before laying it:
  `cmd_install` lays every source unconditionally (`bin/polype:781-785`), and `cmd_update` lays it
  too, because its edit test `has_drifted && sum(dest) != sum(src)` (`bin/polype:830`) is false for
  the payload's own path (dest and src are one file) and false for an untouched active copy, so the
  `else` branch lays the edit and records its sum (`bin/polype:836-837`).
- `payload.sums` is never rewritten from the payload (`sign_payload`, `bin/polype:286-291`): that half
  of the first criterion already holds; the recorded `checksums` do take the edited sum today.
- `check --global` already lists the edited payload file **until** a run from the payload records
  the edit (`has_drifted`, `bin/polype:883`, against `checksums`): `check_lists_payload_edit` fails
  today only as a consequence of the root cause, and needs no change in `cmd_check`.
- The reference for "edited" must be `payload.sums`, never `checksums`: a synced payload carries an
  up-to-date `payload.sums` while this machine's `checksums` are older (story notes; s142 test
  `test_synced_payload_still_installs`, `tests/payload-refuses-foreign-files.test.sh:113-137`).
- No false assumption in the story. No ADR needed: the rule is ADR-0095's last bullet
  (`docs/decisions/ADR-0095-…md`, "Retouche d'un fichier signé (#115)"); ADR-0097 stays unused.

## Diagnostic
Reproduced on `story/s143` (= `main` 48eb6fe) in a throwaway `CLAUDE_CONFIG_DIR` under `/tmp`:
1. `bin/polype install --global` from the worktree; `payload.sums` signs
   `2197407912 4466 polype/method/commands/po-help.md`.
2. `echo EDIT >> <home>/polype/method/commands/po-help.md` (sum becomes `1414386972 4471`);
   `check --global` → `modified: polype/method/commands/po-help.md` (correct, before any payload run).
3. `<home>/polype/bin/polype update --global` → "114 files, 0 removed, 0 left modified"; the active
   `commands/po-help.md` ends with `EDIT`; `checksums` now holds `1414386972 4471` for the payload
   path, `payload.sums` still `2197407912 4466`; `check --global` → "114 installed files, none
   modified". The edit spread and vanished from every report.
4. `install --global` from the payload: same spread, done message gives only the file count.
5. `init <proj>` from the payload, then `echo EDIT2 >> <home>/polype/method/templates/plan.md`,
   `update <proj>` from the payload → `.polype/templates/plan.md` of the project ends with `EDIT2`.

Hypotheses:
- H1 — *the update edit test cannot see a payload edit because src and dest are the same file.*
  Refuted if `update` from the payload left the payload path alone. Step 3 shows the active copy
  laid and the payload path re-recorded: **kept**.
- H2 — *`payload.sums` is rewritten from the payload, hiding the edit.* Refuted by `sign_payload`'s
  guard `from_payload = no` (`bin/polype:288`) and by step 3 (`payload.sums` unchanged): **discarded**.
- H3 — *`check` ignores payload paths.* Refuted by step 2 (`check` lists it before the run):
  **discarded**; `check` goes blind only because step 3 rewrote `checksums`.

## Story
Any run from the payload (`install --global`, `update --global`, `init <project>`, and by the same
code `install|update <project>`) must report a payload file whose sum differs from `payload.sums`
and copy it nowhere. Criteria: `payload_edit_reported_not_spread` (file and active copy unchanged,
line `polype: modified, left as it is: <path in polype/>`, counted in "left modified", the global
`install` done message gaining that count, neither `payload.sums` nor `checksums` taking the edited
sum); `init_does_not_take_payload_edit` (project copy kept, or not laid when missing, same line);
`check_lists_payload_edit`; `fresh_source_still_updates` (from a repository: unedited payload file
and active copy replaced, `payload.sums` rewritten).

## Current code
- `shipped_pairs` (`bin/polype:147-157`): one `<src>\t<dest>` per file; from the payload only signed
  sources (`PAYLOAD_SUMS["polype/<pair-from>/<rel>"]`, `:153`). Globally, `PAIRS` maps
  `method/commands:commands` … and `bin:polype/bin`, `method:polype/method` (`:122-123`), so one
  edited source feeds two dests: the active copy and the payload path (itself).
- `collect_shipped` (`:175-184`) loads `PAYLOAD_SUMS` (`load_payload_sums`, `:277-284`, value
  `"<crc> <size>"`, same format as `sum_of`, `:144`) and stops an unsigned run from the payload.
- `refuse_collisions` (`:209-264`) compares a dest not in the old manifest with `sum_of src` (`:218`).
- `drop_kept_copies_now_shipped` (`:378-391`) removes a `polype.kept/` copy equal to `src` (`:385`).
- `cmd_install` (`:760-797`): no `modified` list; `done_message` (`:749-758`) global branch prints
  `(<n> files), payload in …`.
- `cmd_update` (`:804-859`): `local modified=()` (`:825`), lines printed after wiring (`:855-857`),
  final line `(<n> files, <g> removed, <m> left modified)` (`:858`).
- `has_drifted` (`:734-738`), `RECORDED` from `load_checksums` (`:698-705`); in init/project mode
  `RECORDED` holds the project's `.polype/checksums`.
- `from_payload` is mode-independent (`:43-46`): `init` from the payload uses `PAYLOAD_SUMS` too.

## Attachment points
- One predicate "this source is a payload edit": `from_payload = yes` and
  `PAYLOAD_SUMS["polype/${src#"$base"/}"]` differs from `sum_of "$src"`.
- The two lay-down loops: `cmd_install` `:781-786`, `cmd_update` `:826-840`.
- `refuse_collisions` `:215-221` and `drop_kept_copies_now_shipped` `:381-389`: both compare with
  `src`, which for an edited source is not what Polype ships.
- `done_message` global branch `:752`; `cmd_install` prints no `modified` lines today.
- `docs/installation.md`: chezmoi section `:160-190`, `update` section `:310-318`.

## Verified interfaces
- `sum_of <file>` → `cksum < file` = `"<crc> <size>"` (`bin/polype:144`).
- `record_sum <crc size> <dest>` (`:710-715`); `lay_down <src> <dest>` (`:197-203`).
- `is_payload_path <dest>` true only in global mode for `polype/…` (`:266`).
- Test helpers of s142 (`tests/payload-refuses-foreign-files.test.sh:7-60`): `home_in`, `run`, `ok`,
  `says`, `snapshot`, `from_payload`, `from_repo`, `project`; a newer "repository" is a copy of
  `$ROOT/bin` and `$ROOT/method` (`:115-121`). `tests/lib.sh`: `fail`, `scratch_repo`.

## Traps
- **Synced payload**: files that match `payload.sums` are not edits even when `checksums` differ;
  `test_synced_payload_still_installs` must stay green.
- **Payload path recorded sum**: record the signed sum for the payload path, not the edited one,
  or `check` goes blind again (the root cause). For the active copy, keep `RECORDED[dest]` (its
  content was laid by Polype; with a synced payload the signed sum would make it look edited).
- An active copy of an edited source that is not in `RECORDED` (person's file, or never laid) must
  neither be written nor claimed in the manifest; a missing one is not laid (init criterion).
- Dedupe: one edited source, two dests globally → the line must be printed and counted once.
- `refuse_collisions` would stop `init` on a project copy outside the manifest by comparing it with
  the edited source, though nothing is written there.
- Stale comment `bin/polype:339` ("A run from the payload ships whatever lies under it") predates
  ADR-0095; only touch it if the line becomes wrong in the changed code.
- Tests that will run and pin texts: `tests/local-copy-checksums.test.sh:82,130-131,150`
  (`modified, left as it is` for project copies), `tests/payload-kept-outside.test.sh:82` (update's
  final line `, 1 removed, `), `tests/global-install.test.sh:141-152,208` (runs from the payload,
  unedited), `tests/hooks-installer-docs-cleanup.test.sh:108` (doc prose ≤ 100 chars).
- No migration; installed copies `.claude/`, `.polype/` are not touched.

## Open questions
- Should a project-mode `install|update <project>` from the payload follow the same rule? The code
  path is shared, so yes by construction; the story names only `init`. The plan does not add a test.
- `init`/project done messages: the story asks the count only for global `install`; left unchanged.

## Complexity
Story 2 → 3: one predicate, but two loops, the collision and kept-copy comparisons, the recorded-sum
choice per dest kind and the done message; still one file of code and one test file.

## Split
—
