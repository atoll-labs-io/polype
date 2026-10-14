# Research — s135-update-keeps-init-mode

[Story](../stories.md)

## Structuring facts
- Root cause: `bin/polype:754` — `main` dispatches `update` through `parse_target yes`, which leaves `mode=project` (default, `bin/polype:39`); only `init` sets `mode=init`. `target_is_a_project` (`bin/polype:110-115`) then picks the five `PAIRS` of a full install, and `cmd_update` (`bin/polype:610-659`) lays all 65 files. Proof: reproduction below, 23 → 65 files, 20 under `.claude/commands/`.
- No state file holds the mode: `.polype/` = `checksums hooks manifest templates version` after init and after update (reproduction). `stamp_version` (`bin/polype:506`) writes only the version.
- The repair path the story asks for already works: `polype init` on the inflated project drops the 42 extra copies through `cmd_install`'s ghost loop (`bin/polype:582-586`) — re-init gave 23 files and 0 commands on disk. Only recording the mode is missing there.
- The mode must be known **before** `target_is_a_project` builds `PAIRS`, i.e. inside `parse_target`, since `state_dir` is set in `target_is_a_project` itself (`bin/polype:107`).
- `po-session` already reads `.polype/version` (`method/hooks/po-session.sh:12`); its `absorbed` hint is hard-coded `polype update .` (`method/hooks/po-session.sh:244`).

## Diagnostic
**Reproduction** (throwaway HOME, `bin/polype` of this worktree, no file created in the worktree): `install --global` → 114 files; `init <proj>` → 23 files; `update <proj>` → "65 files, 0 removed", manifest 65 lines, 20 `.claude/commands/` entries; `init <proj>` again → 23 files, `.claude/commands/` empty on disk.

**Hypotheses**
1. *`update` reads the mode from somewhere and misreads it.* Refuted would be: a state file or manifest check in `cmd_update`/`parse_target`. Read `bin/polype:63-117,610-659`: no such read exists. → kept as part of the cause (no read at all).
2. *`init` lays the 23 files under a different state dir, so `update` sees no manifest and falls back to `cmd_install`.* Refuted if update reports "updated … 0 removed" rather than "installed". It reported "updated in … (65 files, 0 removed…)" → discarded.
3. *`mode=project` default at `bin/polype:39` + `update` dispatch at `:754` not overriding it.* Refuted if `PAIRS` were built for init during update; reproduction shows commands laid → kept: this is the root cause.

## Story
`polype update` on an init-activated project keeps it init (23 files); the mode is recorded in `.polype/`, inferred from the manifest when absent; `init` on a full install shrinks it and records `init`; hints (po-session, installer, `/po-setup` step 3) name the right command; README and installation.md stop claiming `update` would lay the commands; an ADR records where the mode lives. Criteria: `init_then_update_stays_init`, `mode_is_recorded`, `mode_inferred_without_state`, `init_shrinks_a_full_install`, `hints_say_init`, `adr_records_the_mode`.

## Current code
- `bin/polype:39` defaults; `:63-88` `parse_target` sets target then `manifest`/`checksums`/`version_file`; `:104-117` `target_is_a_project` builds `PAIRS` from `$mode`.
- `:506` `stamp_version`, called by `cmd_install` (`:599`) and `cmd_update` (`:648`).
- `:562-569` `done_message` switches on `$mode` (init → "activated").
- `:605-608` `cmd_init` = `warn_without_a_global_install` + `cmd_install`.
- `:713-733` `cmd_remove`: `rm -f "$manifest" "$checksums" "$version_file"` (`:729`).
- Installer hints already switch on `$mode`: `absorb_agents_md` (`:257-258`), `handle_claude_md` (`:415-416`). They will be right on update once `$mode` is set from the state.
- `method/hooks/po-session.sh:241-247` CLAUDE.md lines; `:244` the `absorbed` hint.
- `method/commands/po-setup.md:59` step 3: "Rerun the installer if it is available".
- `README.md:114-115`, `docs/installation.md:210-212`: "jamais `polype update .`, qui y poserait les commandes".

## Attachment points
- `parse_target`, project branch, before `target_is_a_project`: when the command is `update` (or `check`/`remove`, harmless), read the recorded mode from `<project>/.polype/<mode file>`; absent → infer from `<project>/.polype/manifest` (no line starting `.claude/commands/` → `init`; else `project`); no manifest → `project` (fresh `update` falls back to `cmd_install`, `bin/polype:611`).
- A `stamp_mode` next to `stamp_version` (`:506`), called at `:599` and `:648`, project modes only (`$mode != global`).
- `cmd_remove` `:729`: remove the mode file too.
- `po-session.sh:244`: compute the command from the same rule (mode file, else manifest inference).

## Verified interfaces
- `parse_target <allow_global> args…` (`bin/polype:63`); `main` passes `yes` for install/update/check/remove, `init` sets `mode=init` first (`:753-754`).
- `drop_laid_file <dest>` (`:223`) — removes and puts back `.before-polype`; out of scope (#89).
- `cmd_check` (`:662-693`) reads version + manifest only; the story no longer asks it to read the mode.
- `po-session` resolves `$top` with `git rev-parse --show-toplevel` (`po-session.sh:9-11`), so `$top/.polype/` is the project's state.

## Traps
- **`install <proj>` after `init`** must record `project` (the user explicitly asks a full install); only `update` reads the state. Inferring in `install` would make `install` impossible to escalate.
- Manifest lines are paths relative to `$root`, e.g. `.claude/commands/po-ship.md`; inference must match `^\.claude/commands/`.
- `tests/no-claude-md.test.sh:98` pins `polype update . moves it into AGENTS.local.md` for a **full** install (`run_polype update` at `:42`) — that phrase stays right for a full install; the test only changes if the wording changes. `tests/claude-md-setting.test.sh:113` greps `polype update . moves it` as a negative — keep the exact fragment or update both.
- `tests/readme-onboarding.test.sh:94` forbids `polype update .` in the README update block — the block keeps `polype init .`; `:155-170` pins installer hints per pose (`init`→`polype init .`), unaffected.
- `tests/installer.test.sh:179` pins 'relance `polype init <projet>` ou `polype update <projet>`' in installation.md — keep it.
- `tests/hooks-installer-docs-cleanup.test.sh`: prose lines ≤ 100 chars in docs. `tests/docs-and-eval-cleanup.test.sh`: keep « ceux qu'il trouve (ADR-0086) ».
- Polype's own `.polype/` is a full install (installed copies): `polype-dev-install`/`update .` on this repo must still record `project`; its manifest has `.claude/commands/` lines, so inference agrees.
- The mode file sits in `.polype/`, which `prune_empty_dirs` (`PRUNE_DIRS`) prunes only when empty — fine.
- No migration; ADR-0087 describes the state files ("quatre fichiers") and is not superseded but extended by ADR-0091.

## Open questions
- Name and format of the state file: a separate `.polype/mode` (one word: `init`|`project`) vs a second line in `version`. A separate file avoids breaking readers of `version` (`cmd_check` `:666`, `po-session.sh:12` only tests existence). The plan decides; `.polype/mode` looks least coupled.
- Should `check` report a missing mode file? Not asked by the story (dropped after review); leave out.

## Complexity
Story 3 → 3. Small code surface (`bin/polype` ~20 lines, `po-session.sh` ~8), but three docs, an ADR and tests that pin wording; the repair path already works.

## Split
Not needed.
