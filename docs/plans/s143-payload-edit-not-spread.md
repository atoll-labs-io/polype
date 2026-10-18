---
validated: yes
---
# Plan — s143-payload-edit-not-spread

[Story](../stories.md) · [Research](../research/s143-payload-edit-not-spread.md)

Branch `story/s143-payload-edit-not-spread`. Read `docs/research/s143-payload-edit-not-spread.md`
first; this plan builds on it without repeating it. Defect story (#115): the root cause is in the
research's first fact (`bin/polype:781-785`, `:830`, `:836-837`).

## Story
A payload file whose sum differs from what `payload.sums` signs is a payload edit. Any run from the
payload reports it and copies it nowhere (ADR-0095, last bullet). Criteria:
`payload_edit_reported_not_spread`, `init_does_not_take_payload_edit`, `check_lists_payload_edit`,
`fresh_source_still_updates` (see the story for their exact wording).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Predicate "this source is a payload edit" | new code, built on `PAYLOAD_SUMS` (`bin/polype:277-284`), `sum_of` (`:144`), `from_payload` (`:43-46`) | no existing helper compares a source with its signed sum; `has_drifted` (`:734`) reads `checksums`, which is the wrong reference for a synced payload |
| Handling of an edited source in the two lay-down loops | new code, one helper shared by `cmd_install` and `cmd_update`, reusing `record_sum` (`:710`) and `RECORDED` (`:698`) | the update branch for modified copies (`:830-834`) cannot be reused as is: its test is false when src and dest are one file, and it must also run in `cmd_install` |
| Count in the global install done message | existing `done_message` (`:749-758`), one extra argument | — |
| Tests | the s142 helpers pattern (`tests/payload-refuses-foreign-files.test.sh:7-60`), redefined in the new file as every test file does | helpers are per test file in this repository (`never_says` is defined in three files) |

## Tasks
1. [x] **Predicate.** In `bin/polype`, next to `load_payload_sums`, add `payload_edit <src>`: true
   when `from_payload = yes`, `PAYLOAD_SUMS["polype/${src#"$base"/}"]` is set, and it differs from
   `sum_of "$src"`. Nothing else may make it true: a run from a repository never sees an edit this
   way. *Test that fails if wrong:* `test_fresh_source_still_updates` (a predicate true from a
   repository would leave the payload file unreplaced) and `test_payload_edit_reported_not_spread`.
2. [x] **One helper for an edited source.** Add `keep_payload_edit <src> <dest>` that returns 1
   (caller lays as before) when `payload_edit "$src"` is false; otherwise writes nothing to disk and
   returns 0 after:
   - dest equal to `polype/${src#"$base"/}` (the payload path itself, global only): manifest line,
     `record_sum` with the **signed** sum `PAYLOAD_SUMS[…]`, never the edited one;
   - any other dest with `RECORDED[dest]` set and `$root/$dest` present: manifest line,
     `record_sum "${RECORDED[$dest]}"` (the active copy keeps its content and its sum);
   - any other dest: no manifest line, no sum, nothing laid (a missing project copy stays missing,
     a file Polype never recorded is not claimed);
   - appends `polype/${src#"$base"/}` to the caller's `modified` array once per source (an
     associative `reported` set declared by the caller), so the global run, where one source feeds
     the active copy and the payload path, prints and counts it once.
   *Test that fails if wrong:* `test_payload_edit_reported_not_spread` (active copy unchanged,
   `checksums` line of the payload path equal to the `payload.sums` one, "1 left modified"),
   `test_init_does_not_take_payload_edit` (missing copy not laid).
3. [x] **Wire it into both loops.** `cmd_update` (`:826-840`): first statement of the loop body
   `if keep_payload_edit "$src" "$dest"; then continue; fi`, before the existing modified branch,
   which stays word for word (it still names an edited active copy of an unedited source, story
   note "Une copie active déjà retouchée garde sa règle d'aujourd'hui"). `cmd_install` (`:781-786`):
   the same first statement; declare `local modified=()` and `declare -A reported=()` there; print
   `polype: modified, left as it is: <path>` on `stderr` for each entry before `done_message`, as
   `cmd_update` does (`:855-857`). Pass `${#modified[@]}` to `done_message`; only its global
   branch uses it: `(<n> files, <m> left modified), payload in …`. The `init` and project
   messages stay unchanged. *Test that fails if wrong:* `test_payload_edit_reported_not_spread`
   (both `install --global` and `update --global` from the payload), `test_check_lists_payload_edit`
   (fails when the update loop lays or re-records the edit — the root cause).
4. [x] **The two other comparisons with `src`.** `refuse_collisions` (`:215-221`): skip a line
   whose source is a payload edit, since nothing is written at its dest. `drop_kept_copies_now_shipped`
   (`:381-389`): skip it too, since an edited source is not what Polype ships, so a kept copy equal
   to the edit is not "now shipped". *Test that fails if wrong:* `test_init_does_not_take_payload_edit`
   for the collision skip (a fresh project holding its own copy outside the manifest stops today;
   see Test strategy). The kept-copy skip is a one-line guard argued in The pivot, with no test of its own.
5. [x] **Tests.** Create `tests/payload-edit-not-spread.test.sh` (header comment `# s143 — …`),
   helpers copied from the s142 file pattern, four functions named after the criteria:
   - `test_payload_edit_reported_not_spread`: `install --global` from `$ROOT`; save the
     `payload.sums` line and the active `commands/po-help.md` sum; append to
     `$H/polype/method/commands/po-help.md`; from the payload `update --global`: payload file still
     edited, active copy sum unchanged, says `polype: modified, left as it is: polype/method/commands/po-help.md`,
     last line holds `, 1 left modified)`, `payload.sums` unchanged byte for byte, the `checksums` line
     of that path equal to the saved signed line. Then `install --global` from the payload: the same
     checks, and the last line holds `1 left modified`.
   - `test_init_does_not_take_payload_edit`: global install from `$ROOT`; `init "$P"` from the
     payload; append to `$H/polype/method/templates/plan.md`; `init "$P"` again from the payload:
     `$P/.polype/templates/plan.md` unchanged, says the line with `polype/method/templates/plan.md`.
     Then delete that project copy and `init` again: it is not laid. Then a second fresh project
     holding its own `.polype/templates/plan.md` (no manifest): `init` succeeds and leaves it as it is.
   - `test_check_lists_payload_edit`: edit as above, `update --global` from the payload, then
     `check --global` exits 1 and prints `modified: polype/method/commands/po-help.md`.
   - `test_fresh_source_still_updates`: global install from `$ROOT`; a copy of `$ROOT/bin` and
     `$ROOT/method` under `$SCRATCH/newer` whose `method/commands/po-help.md` differs; from that copy
     `update --global`: `$H/polype/method/commands/po-help.md` and `$H/commands/po-help.md` equal the
     new file, and the `payload.sums` line of that path carries the new sum.
   Run `bash tests/run.sh payload-edit-not-spread.test.sh payload-refuses-foreign-files.test.sh
   payload-kept-outside.test.sh global-install.test.sh local-copy-checksums.test.sh`.
6. [x] **Docs.** `docs/installation.md`: in the chezmoi section after the paragraph ending
   "sort comme tout fichier que Polype ne livre plus." (`:186-190`), one paragraph in French: a
   payload file whose content differs from what `payload.sums` signs is an edit; a run from the
   payload leaves it as it is, lays it nowhere (neither the active copy nor a project's
   `.polype/`), says `polype: modified, left as it is: polype/<chemin>`, counts it in "left
   modified" (the global `install` message included), and records the signed sum, so `check
   --global` keeps listing it (ADR-0095). Prose lines ≤ 100 characters. Then the full suite once:
   `po-run --story s143-payload-edit-not-spread --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `docs/decisions/` ends with an empty diff: no ADR (ADR-0095 holds the rule; ADR-0097 unused).
- `.claude/` and `.polype/` (installed copies) end with an empty diff.
- `sign_payload` (`bin/polype:286-291`), `cmd_check` (`:861-897`), `cmd_remove` (`:917-969`) and
  `refuse_foreign_payload_files` (`:297-335`) end unchanged.
- `recorded_mode` is not renamed (s142 note).
- The existing `cmd_update` modified branch (`:828-838`) and its message format stay word for word;
  `tests/local-copy-checksums.test.sh` and `tests/payload-kept-outside.test.sh` are not edited.
- No test file other than `tests/payload-edit-not-spread.test.sh` is created or changed.
- Out of scope: kept-copy edge cases (#119-#121, s146), the stale comment at `bin/polype:339`.

## The pivot
**The edit is judged against `payload.sums`, and the payload path keeps the signed sum in
`checksums`.** Ways it could be wrong:
- A synced payload read as edited: compare with `test_synced_payload_still_installs`
  (`tests/payload-refuses-foreign-files.test.sh:113`): every synced file matches its new
  `payload.sums`, so `payload_edit` must be false for all of them.
- The active copy recorded with the signed sum instead of `RECORDED`: harmless when versions match,
  but after a sync the active copy (older content, not laid) would read as hand-edited in `check`.
- An edited source still compared somewhere with `src`: `refuse_collisions` and
  `drop_kept_copies_now_shipped` are the only other readers of `src` contents (`:218`, `:385`);
  `lay_down` is reached only when `keep_payload_edit` returned 1. The reviewer should grep for
  `sum_of "$src"` and `lay_down` to confirm.

## Files touched
- `bin/polype`
- `docs/installation.md`
- `tests/payload-edit-not-spread.test.sh` (new)
- `docs/research/s143-payload-edit-not-spread.md`, `docs/plans/s143-payload-edit-not-spread.md`

## Test strategy
Four automated tests, one per criterion, all at the installer's own layer (the CLI run in a scratch
`CLAUDE_CONFIG_DIR`), far within `Test budget` (25). Bites:
- disabling `keep_payload_edit` in `cmd_update` → `test_payload_edit_reported_not_spread` and
  `test_check_lists_payload_edit` fail; in `cmd_install` → the install half of the first test fails;
- making `payload_edit` ignore `from_payload` → `test_fresh_source_still_updates` fails;
- removing the collision skip → the second-project half of `test_init_does_not_take_payload_edit`
  stops with exit 1;
- recording `RECORDED[dest]` instead of the signed sum for the payload path changes nothing when
  installed from `$ROOT` (both equal); this sub-rule is argued, not tested, as is the kept-copy skip.
No visual check. Full suite once at the end through `po-run`; no type check (`Typecheck: —`).

## Done when
One commit on `story/s143-payload-edit-not-spread` with code, test, docs, research and plan; the
four new tests and the full suite green; a review with no open critical finding; landed by
`/po-ship` through a pull request.
