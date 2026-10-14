---
validated: yes
---
# Plan — s36-installer

[Story](../stories.md) · [Research](../research/s36-installer.md)

Branch `story/s36-installer`. Read `docs/research/s36-installer.md` first; this plan builds on it without repeating it.

## Story
One real installer, `bin/polype`, with four subcommands, replacing `bin/polype-dev-install` without breaking it.

- `installer_supports_install_update_check_and_remove`
- `installer_update_leaves_no_ghost`
- `installer_check_reports_drift`
- `installer_stamps_a_version`
- `installer_remove_leaves_the_project_intact`

## Decisions the research left open
| Question | Decision | Why |
| --- | --- | --- |
| Manifest format | unchanged (one path per line); checksums live in a new `.polype/checksums` | `tests/install.test.sh:72` appends a bare path and must stay green |
| Checksum tool | `cksum` | POSIX, no dependency, already the repository's idiom (`tests/lib.sh:57`) |
| Version source | constant `POLYPE_VERSION` declared at the top of `bin/polype`, stamped into `.polype/version` | no tag, no version file, and Owns allows no new source file |
| `install` vs `update` | `install` lays everything down, overwriting; `update` refreshes unmodified files, leaves modified ones in place and reports them | H01 asks for "unmodified refreshed, modified reported"; `install` must keep the old script's overwriting behaviour for the alias |
| Drift and exit codes | `check` exits 1 when a file drifted or `.polype/version` is missing; `update` exits 0 and reports | the criterion asks `check` to exit non-zero, not `update` |
| Parity matrix | **not touched here** | `docs/stories.md:570` puts `docs/parite-killer-saas.md` in s39's Owns, with a criterion covering H01–H04 |
| ADR | none | H01 and ADR-0004 already settle the direction; the choices above are implementation, reversible in one file |

## Tasks
1. [x] **`bin/polype` — dispatch and payload.** `set -euo pipefail`, `POLYPE_VERSION` constant, `method` resolved from `dirname "$0"/../method`, subcommands `install|update|check|remove|help`, unknown subcommand or option → usage on stderr, exit 2; no subcommand → usage, exit 2. `install <project> [--hooks]` reproduces `bin/polype-dev-install:25-86` exactly: manifest sweep, five trees, `chmod +x` hooks, empty-dir prune, `AGENTS.md` backup-and-rebuild, single `@AGENTS.md` in `CLAUDE.md`, `.gitignore` lines, `core.hooksPath` only when unset or already ours. Test able to fail: `installer_supports_install_update_check_and_remove` (each subcommand runs and produces its effect) plus the eleven legacy tests of `tests/install.test.sh`, run against the alias.
2. [x] **Version and checksums.** `install` writes `POLYPE_VERSION` to `.polype/version` and, for every manifest path, `<cksum> <path>` to `.polype/checksums`; both files are excluded from the manifest so they are never their own ghosts. Test: `installer_stamps_a_version`.
3. [x] **`bin/polype-dev-install` becomes a forwarder.** Body reduced to `exec "$(dirname "$0")/polype" install "$@"`, keeping the shebang and the executable bit. Test: the unmodified `tests/install.test.sh`, including `test_install_copies_skill_subdirectories`, which runs a *copy* of `bin/` next to a copy of `method/`.
4. [x] **`check <project>`.** Prints the installed version (and says when it differs from the shipped one), lists every manifest path whose `cksum` no longer matches `.polype/checksums`, names missing installed files, exits 1 if either list is non-empty or `.polype/version` is absent, 0 otherwise. Test: `installer_check_reports_drift`.
5. [x] **`update <project>`.** Deletes manifest paths no longer shipped, copies shipped files whose checksum still matches, leaves drifted files untouched and names them on stderr, rewrites manifest, version and checksums, then reruns the `AGENTS.md`/`CLAUDE.md`/`.gitignore` steps. Tests: `installer_update_leaves_no_ghost`, `installer_update_preserves_a_modified_file`.
6. [x] **`remove <project>`.** Deletes every manifest path, `.polype/manifest`, `.polype/checksums`, `.polype/version`, prunes the emptied `.claude`/`.polype` directories, drops the `@AGENTS.md` line from `CLAUDE.md`, deletes `AGENTS.md` only when line 1 carries the assembly marker and restores `AGENTS.md.before-polype` over it when that backup exists, unsets `core.hooksPath` only when it equals `.polype/hooks`. Keeps `AGENTS.local.md`, `docs/`, `.gitignore` and any file the project added. Test: `installer_remove_leaves_the_project_intact`.
7. [x] **`tests/installer.test.sh`.** The functions listed in the test strategy, on `scratch_repo` temp projects only.
8. [x] **`docs/installation.md`** (French): what the four subcommands do, what lands in `.claude/` and `.polype/`, the three state files, install versus update, how to read a `check` report, what `remove` keeps. It promises nothing about the global install — that is s37.
9. [x] **Correct the story's `Owns`.** Add `bin/polype-dev-install` to `docs/stories.md:539`; that path is required by the story's own notes (`docs/stories.md:549`) and no other lane claims it. One line, nothing else in that file.

## Run interdicts
- **Never run `bin/polype` or `bin/polype-dev-install` against this repository.** `.polype/` (18 files) and the root `AGENTS.md` are tracked; a run would rewrite files outside Owns. Install only into `scratch_repo` temporary directories.
- Empty diff required on: `method/` in its entirety, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `CLAUDE.md`, `.gitignore`, `README.md`, `bin/po-lint`, `bin/ks-overlap`, `docs/parite-killer-saas.md`, `docs/defauts.md`, and every `tests/*.test.sh` except the new `tests/installer.test.sh`.
- `docs/stories.md` may change on one line only: the `Owns` of s36.
- No global install, no `~/.claude` path, no `init` subcommand — that is s37.
- Do not touch `core.hooksPath` of this worktree.

## The pivot
Everything rests on **`bin/polype install` being byte-for-byte equivalent in effect to today's `bin/polype-dev-install`**, so the alias keeps eleven tests green while the three new subcommands are built around it. Three ways that could be wrong:
- *The extraction drops a behaviour.* Compare against `bin/polype-dev-install` at commit `abf9024`: the `--hooks` position-independence (`:13-19`), the exit-2 on unknown options, the backup-not-overwritten rule (`:54-57`), the one-and-only-one `@AGENTS.md` (`:67`), the `Worktree root` read from `AGENTS.local.md` (`:71`). `git show abf9024:bin/polype-dev-install` is the reference.
- *The two new state files become ghosts.* If `.polype/version` or `.polype/checksums` end up inside the manifest, the next run deletes them before reading them. Check that the manifest of a fresh install lists neither.
- *`cksum` drift detection gives a false negative.* `cksum` is a CRC: compare a file edited in place, one edited to the same length, and one that only had a line appended.

## Files touched
- `bin/polype` (new, mode 100755)
- `bin/polype-dev-install` (reduced to a forwarder)
- `tests/installer.test.sh` (new)
- `docs/installation.md` (new)
- `docs/stories.md` (one line: the `Owns` of s36)
- `docs/research/s36-installer.md`, `docs/plans/s36-installer.md`, `docs/verif/s36-installer.md` (pipeline evidence)

## Test strategy
`Test budget: 25`. Ten automated tests in `tests/installer.test.sh`, plus the eleven of `tests/install.test.sh` which keep covering the install payload through the alias — nothing is duplicated between the two files: the legacy file tests *what install lays down*, the new one tests *the subcommands and the state files*.

Automated, all against `scratch_repo` temp projects:
1. `installer_supports_install_update_check_and_remove` — the four subcommands exist, each changes the project as announced; an unknown subcommand exits 2.
2. `installer_stamps_a_version` — `.polype/version` exists after `install`, holds the script's `POLYPE_VERSION`, and `check` prints it.
3. `installer_check_reports_drift` — a file edited in place is named by `check`, which exits non-zero; a clean install makes `check` exit 0.
4. `installer_check_is_silent_on_a_clean_install` — no path is reported when nothing drifted.
5. `installer_update_leaves_no_ghost` — a manifest entry no longer shipped is deleted; a file the project added under `.claude/commands/` survives.
6. `installer_update_preserves_a_modified_file` — a drifted installed file keeps its content after `update` and is reported.
7. `installer_update_refreshes_an_untouched_file` — a file whose checksum still matches is rewritten from the method.
8. `installer_remove_leaves_the_project_intact` — after `remove`: no `.polype/manifest`, no installed command; `AGENTS.local.md`, a project document and `.gitignore` are byte-identical to before.
9. `installer_remove_restores_a_hand_written_agents_md` — the `AGENTS.md.before-polype` backup is put back and `@AGENTS.md` leaves `CLAUDE.md`.
10. `installer_state_files_are_not_their_own_ghosts` — the manifest lists neither `.polype/version` nor `.polype/checksums`.

Visual checks: none — this story has no screen.

No lint or type check exists in this project (`Typecheck: —`). The full suite runs at the end of execute (`Full suite: execute-end`): `bash tests/run.sh`.

## Done when
- `bash tests/run.sh` is green, the eleven tests of `tests/install.test.sh` included and unmodified;
- `bin/polype` handles the four subcommands, `bin/polype-dev-install` still works as before through the forwarder;
- `docs/installation.md` describes the installer without promising the global install;
- `docs/verif/s36-installer.md` records the runs with the commands and their output;
- one commit on `story/s36-installer`, message in English, no co-author trailer.
