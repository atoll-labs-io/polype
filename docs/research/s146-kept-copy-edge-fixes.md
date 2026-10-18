# Research — s146-kept-copy-edge-fixes

[Story](../stories.md)

## Structuring facts
- **Root cause #121** — `refuse_taken_kept_copies` checks only the kept path itself (`bin/polype:397-398`), never its parents; `move_out_of_payload` then runs `mkdir -p` and `mv` unchecked (`bin/polype:379-380`) and prints the "moved out" line whatever they returned (`bin/polype:381`). It is reached through `drop_laid_file "$old" || true` (`bin/polype:805`) and `&& drop_laid_file` (`bin/polype:857`), where `set -e` (`bin/polype:21`) does not apply. Proof: reproduction 3 below.
- **Root cause #120** — `bin/polype:394` tests `[ -f "$root/$path" ]`, which follows a symlink, while the two places that actually move a payload edit skip symlinks (`bin/polype:428`, `bin/polype:970`). Proof: reproduction 2.
- **Root cause #119** — coverage only: the only test of the sweep, `test_kept_copy_removed_once_shipped`, runs `install --global` alone (`tests/payload-kept-outside.test.sh:91-110`); the `update` call of the sweep (`bin/polype:880`) is held by no test.
- **False assumption (issue #121, not the story)**: the file left in place is *not* "re-shipped from the payload" any more. Since s142 the payload is re-signed without it (`sign_payload`, `bin/polype:316-321`), so every later run stops on it as a foreign file (`refuse_foreign_payload_files`, `bin/polype:326-363`). Reproduced: both `update` from the payload and `install` from the copy stop with "not laid down by Polype, inside the payload". The home stays blocked until the person moves the file; no silent re-ship.
- **Gap the AC wording leaves**: a parent that is a *read-only directory* yields the same false "moved out" line (reproduction 4), and no parent check catches it. The AC's second clause ("never written for a file left in place") therefore needs `move_out_of_payload` to check its own `mkdir`/`mv`, not only the new parent check.

## Story
Three defects of s139's kept copies (issues #119, #120, #121), `Corrige` line → full track, diagnostic skill. Owns `bin/polype`, `tests/payload-kept-outside.test.sh`.
- `update_sweeps_shipped_kept_copy` — `update --global` removes a `polype.kept/` copy identical to what the payload now ships; fails when the sweep call in `cmd_update` is removed.
- `symlink_payload_path_not_refused` — a payload path that is a symlink no longer stops the run over a kept copy it would never move: same `[ ! -L … ]` as `drop_laid_file`.
- `failed_move_is_not_reported_as_done` — a parent of `polype.kept/<path>` that is a regular file stops the command before any write, naming that parent; "moved out of the payload" is never printed for a file left in place.

## Diagnostic
Every run in a throwaway home under `/tmp` (`HOME`, `CLAUDE_CONFIG_DIR`), from a copy of `bin/` and `method/`; nothing written in the worktree.

1. **#119** — `grep` of the test file: `update --global` appears only in `test_payload_copy_moves_out`, `test_moved_copy_is_not_shipped`, `test_existing_kept_copy_never_overwritten`; none places an identical kept copy before an `update`. The s139 review's bite 5 found the same (`docs/reviews/s139-payload-kept-outside.md`, `## Findings`). Not a runtime defect.
2. **#120** — install; replace `polype/method/AGENTS.md` by a symlink to a drifted copy; write a different `polype.kept/method/AGENTS.md`; `remove --global` → "…already exists and differs…; nothing moved, nothing written", stopped. Same with `install --global` after dropping `po-help.md` from the copy and symlinking its payload path. On a scratch copy with `[ ! -L "$root/$path" ]` added at `:394`, `remove --global` exits 0, the kept copy still says `other`.
3. **#121** — install from the copy; append to payload `po-help.md`; drop it from the copy; `printf x > ~/.claude/polype.kept`; `install --global` → `mkdir: … N'est pas un dossier`, `mv: …`, then `polype: modified, moved out of the payload: …` printed; the file is still in the payload, the manifest lists `po-help` 0 times, `payload.sums` 0 times. Same with `polype.kept/method` a regular file. On a scratch copy with a parent check in `refuse_taken_kept_copies`, `install`, `update` and `remove` all exit 1 naming the parent, manifest unchanged (po-help listed twice: payload and active copy).
4. **Read-only parent** — same as 3 but `mkdir -p polype.kept/method; chmod 555` it: `mkdir` "Permission non accordée", `mv` fails, the false line is printed, the file stays in the payload; the sweep's `find -empty -delete` (`bin/polype:420`) then removes the empty read-only directory, so nothing shows what happened.

Hypotheses (#121):
- H1 kept — the refusal misses a non-directory parent. Refuted if `refuse_taken_kept_copies` stopped on reproduction 3: it did not (run went on to `mkdir`).
- H2 discarded — "`set -e` would stop at the failed `mkdir`". Refuted by reproduction 3: the run went on and exited after laying everything, the call sitting under `|| true` (`:805`).
Hypothesis (#120): H1 kept — `-f` follows the symlink at `:394`. Refuted if adding `[ ! -L ]` there changed nothing: it turned the stop into exit 0 (reproduction 2).

## Current code
- `kept_path` (`bin/polype:366`) maps `polype/<p>` to `$root/polype.kept/<p>`.
- `move_out_of_payload <dest>` (`bin/polype:371-382`): identical kept copy → `rm` the payload file, "already kept"; else `mkdir -p`, `mv`, "moved out". Callers: `drop_laid_file` (`:429`, payload, regular, drifted) and `cmd_remove` (`:971`, same three tests at `:970`).
- `refuse_taken_kept_copies dropped|all` (`bin/polype:386-404`): for each manifest line that is a payload path, `-f`, drifted (`:394`) — and with `dropped` not shipped now — stops (`:403`) when the kept path is a symlink, a non-file, or a file of other content. Called before any write: `cmd_install` `:794`, `cmd_update` `:846`, `cmd_remove` `:960`. Message form `polype: <kept> already exists and differs from <payload>; nothing moved, nothing written` (`:399`).
- `drop_kept_copies_now_shipped` (`bin/polype:407-421`): for each shipped payload path not a payload edit, removes an identical regular kept copy, then deletes empty dirs of `polype.kept/`. Called at `cmd_install` `:820` and `cmd_update` `:880`, after the lay-down loop.
- `cmd_update` (`bin/polype:841-898`): with no manifest it calls `cmd_install` and returns (`:842`).

## Attachment points
- `bin/polype:394` — add `[ ! -L "$root/$path" ]` (#120).
- `bin/polype:386-404` — a parent check before the leaf check, same `taken=yes` / `exit 1` path, message naming the parent (#121).
- `bin/polype:379-381` — the "moved out" line printed only after `mkdir -p` and `mv` succeeded; otherwise stop (#121, read-only case).
- `tests/payload-kept-outside.test.sh` — three `test_<AC name>` functions, reusing `home_in`, `ok`, `run`, `says`, `never_says`, `not_listed`, `snapshot`, `edited_payload_file_dropped`, `stops_on_the_taken_copy` (`:8-140`).

## Verified interfaces
- `edited_payload_file_dropped <name>` (`tests/…:50-63`) sets `COPY`, `POLYPE`, `PAY`, `KEPT`, `EDITED`; the dropped file is `method/commands/po-help.md`.
- `stops_on_the_taken_copy <args>` (`tests/…:112-119`): exit 1, home snapshot unchanged, output names `$KEPT` and `$PAY`. A parent message that names `$KEPT` and `$PAY` as well as the parent satisfies it.
- `scratch_repo` installs `trap 'rm -rf "$SCRATCH"' EXIT` (`tests/lib.sh:46-48`).
- `tests/run.sh` runs each `test_*` in `bash -c "set -eu; …"`.
- `has_drifted` (`bin/polype:764-768`) needs `RECORDED`, loaded before `refuse_taken_kept_copies` in all three commands.

## Traps
- `update --global` with no manifest runs `cmd_install` (`:842`): the #119 test must install first, then place the kept copy, then update — or it tests install again.
- A dangling symlink as parent has `-e` false: the parent test must be `{ -e || -L } && ! -d`.
- In the read-only case the sweep (`:420`) deletes the empty read-only dir; a stop before the sweep leaves it read-only but empty, which `rm -rf` of the scratch still removes. `chmod` has no effect as root: the read-only check must skip under `id -u` 0.
- Exiting from `move_out_of_payload` in the drop phase (`:805`, `:857`) leaves files dropped before it removed while the manifest and sums are still the old ones; a rerun treats them as missing and lays them again — no loss.
- `docs/installation.md:355-372` describes the stop on a taken kept copy; not in `Owns`, frozen by several tests (s142 notes): unchanged here.
- `test_existing_kept_copy_never_overwritten` (`tests/…:121-138`) asserts the leaf message; it must keep passing unchanged.
- Out of scope: the s139 major finding (a `.before-polype` put back into the payload) and #115/s143 work.

## Open questions
- On a failed `mkdir`/`mv`, stop the whole run (`exit 1`) or skip the file and keep it in the manifest? The plan picks `exit 1`: the file stays in the payload and the old manifest still lists it.
- Should a symlink parent pointing at a directory be refused? `-d` follows it, so it passes, as `mkdir -p` would; the AC names only a regular file. Left accepted.

## Complexity
Story 2 → 2. Three local edits in one file and three tests; the read-only gap adds one guard, not a new mechanism. No escalation signal beyond the `Corrige` line; no ADR (ADR-0097 unused).

## Split
—
