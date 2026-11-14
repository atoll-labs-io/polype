---
validated: yes
---
# Plan — s171-po-prebuilt-and-verified

[Story](../stories.md) · [Research](../research/s171-po-prebuilt-and-verified.md)

Branch `story/s171-po-prebuilt-and-verified`. Read `docs/research/s171-po-prebuilt-and-verified.md` first; this plan builds on it without repeating it.

## Story
A machine without Rust receives `po` prebuilt for its platform and checked against an expected SHA-256; the build from sources stays the fallback (ADR-0115). Criteria: `release_builds_one_binary_per_platform`, `installer_downloads_and_verifies`, `installer_falls_back_to_sources`, `upgrade_cleans_what_the_old_version_left`, `check_audits_po`, `docs_say_what_is_verified` (review only).

## Technical choices
Both settled by the owner on 2026-11-14 (d-0013, d-0014) and recorded in [ADR-0121](../decisions/ADR-0121-po-precompile-plateformes-et-somme-attendue.md), `accepted`: the expected sum lives in the versioned `bin/polype` (a `PO_SUMS` block filled by a commit after publication), and the published platforms are `linux-x86_64`, `linux-aarch64`, `macos-aarch64`. The tasks below are written for these.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Source build inside the new `lay_po` | already here: `build_po` body, `bin/polype:808-832`, kept with its three messages | — |
| Atomic replacement of `po` | already here: `.polype-next` then `mv -f`, `bin/polype:825-826` | — |
| SHA-256 of a file | platform: `sha256sum`, else `shasum -a 256` | `sum_of` (`bin/polype:171`) is `cksum`, a CRC: no proof against a chosen binary |
| Download | platform: `curl -fsSL --proto =https`, else `wget --https-only` | nothing in the repository downloads |
| Platform name `<os>-<arch>` | new code, `uname -s`/`uname -m` mapped, about eight lines, written in both `bin/polype` and `bin/po-release` | no shared bash library between `bin/` scripts; the oracle's release-then-install run checks the two agree |
| Release script | new code, `bin/po-release`, shaped like `bin/po-ci` (no forge variable) | the release must run unchanged on GitHub and Forgejo runners (ADR-0105) |
| Cleanup of machine files | new code in `bin/polype`, about twenty lines | nothing removes files under the git common dir today |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/po-prebuilt-and-verified.oracle.test.sh` | `1679792638 12337` |

| Criterion | Test |
| --- | --- |
| `release_builds_one_binary_per_platform` | `test_release_builds_one_binary_per_platform` |
| `installer_downloads_and_verifies` | `test_installer_downloads_and_verifies` |
| `installer_falls_back_to_sources` | `test_installer_falls_back_to_sources` |
| `upgrade_cleans_what_the_old_version_left` | `test_upgrade_cleans_what_the_old_version_left` |
| `check_audits_po` | `test_check_audits_po` |
| `docs_say_what_is_verified` | — documentation, judged in review; candidate for a `po-eval` control arm (#208) |

The oracle runs on a throwaway copy of Polype: `cargo` is a double first on the `PATH`, `CARGO_TARGET_DIR` is the test's own, and the download command is the double named by `POLYPE_PO_FETCH`. Nothing is downloaded. The interfaces it fixes: `bin/po-release <out-dir>`; the `PO_SUMS='` line opening the sums block of `bin/polype`, one `sha256sum` line per binary inside it; `POLYPE_PO_FETCH <url> <file>`; the `check` lines starting `po missing`, `po modified`, `po version`.

## Tasks
1. [x] **Prebuilt first, sources in fallback** — in `bin/polype`, after `POLYPE_VERSION` (`:27`): `PO_RELEASES="https://github.com/atoll-labs-io/polype/releases/download"` and a block opened by the line `PO_SUMS='` and closed by `'`, empty in this story (comment: lines are the `.sha256` files `bin/po-release` writes, added by the release commit, `docs/ci.md`). Helpers: `po_platform` (`Linux`→`linux`, `Darwin`→`macos`; `x86_64|amd64`→`x86_64`, `aarch64|arm64`→`aarch64`; else none), `sha256_of` (`sha256sum`, else `shasum -a 256`, else fail), `po_fetch <url> <file>` (`"$POLYPE_PO_FETCH" "$url" "$file"` when set; else `curl -fsSL --proto =https --tlsv1.2 --max-time 300 -o`; else `wget -q --https-only -O`; else fail). Replace `build_po` by `lay_po`, in this order, each fallback line ending `; building po from sources` and then running the unchanged body of `build_po` (`:809-831`):
   - `POLYPE_PO_FROM_SOURCES=1` → `polype: POLYPE_PO_FROM_SOURCES is set; building po from sources`;
   - no SHA-256 tool → `polype: neither sha256sum nor shasum found; building po from sources`;
   - no platform, or no `PO_SUMS` line named `po-<POLYPE_VERSION>-<platform>` → `polype: no prebuilt po <version> for <platform>; building po from sources`;
   - `po` already in place with the expected sum → keep it, write its record (task 2), nothing said;
   - download `<PO_RELEASES>/v<version>/po-<version>-<platform>` to `<po>.polype-next`; failure → `polype: could not download <url>; building po from sources`;
   - sum differs → remove `<po>.polype-next`, print `polype: po refused: <url> has sha256 <found>, bin/polype expects <expected>; <po_left>`, set `po_refused=yes`, no fallback;
   - sum matches → `chmod +x`, `mv -f` onto `po`.
   `cmd_install` and `cmd_update` call `lay_po` where they called `build_po` (`:940`, `:1001`) and end with `exit 1` after their last line when `po_refused=yes`. The `no po sources`, `cargo not found` and `cargo could not build` messages stay word for word (`tests/state-as-json*.test.sh` grep them). Tests: `test_installer_downloads_and_verifies`, `test_installer_falls_back_to_sources`.
2. [x] **The record of the laid `po`** — whichever path lays `po`, write `$payload_dir/po.sum` holding one line `<sha256> <POLYPE_VERSION> <prebuilt|sources>` (`-` as the sum when no SHA-256 tool exists), through `.polype-next` and `mv -f`. Add `po.sum` to `is_payload_state_file` (`:299-305`). A run that keeps `po` without laying it (`no po sources`, `cargo not found`) leaves `po.sum` as it is. Test: `test_po_record_is_a_state_file_of_the_payload` (task tests).
3. [x] **Cleanup of what an older `po` left** — `clean_machine_files`, called by `lay_po`'s caller in project mode (install, init, update), only when `po` exists and `po.sum` names `POLYPE_VERSION`: in `<git -C "$project" rev-parse --path-format=absolute --git-common-dir>/polype/`, every regular file directly in it (never a directory, never a symlink's target, never deeper) whose name is not one this `po` reads or writes — `lead-session.json`, `run.lock`, `.lead-session.json.*.tmp`, `run.lock.*.stale` (comment cites `po/src/run/session.rs:36,94` and `po/src/run/mod.rs:93,245`) — is removed, each with `polype: removed <path>: left by an older po, not read by po <version>`. A project outside git cleans nothing. The decision inbox is a folder and the walk never enters one; git-tracked files cannot sit under the git common dir. The replaced binary itself is gone by the `mv -f` of task 1, and a leftover `po.polype-next` is overwritten by the next lay. Test: `test_upgrade_cleans_what_the_old_version_left`.
4. [x] **`check` audits `po`** — replace the line at `:1047` by: no `po` → `po missing: <path> (rerun polype install or update)`, exit unchanged; no `po.sum`, or its sum is `-` → `po not verified: <path> has no recorded sha256 (rerun polype update)`, exit unchanged; SHA-256 differs → `po modified: <path> (sha256 <found>, laid as <recorded>)`, exit 1; recorded version differs from the project's `.polype/version` (from `$version_file` in `--global`) → `po version differs: <path> is <x>, <this project|this install> is <y>`, exit unchanged. Tests: `test_check_audits_po`; `test_check_accepts_a_po_laid_before_s171` (task tests).
5. [x] **`bin/po-release <out-dir>`** — executable bash, `set -euo pipefail`, reads no forge variable: root from its own path as `bin/po-ci` does; refuses (exit 2) without an argument; refuses (exit 1, both named) when `version` of `po/Cargo.toml` differs from `POLYPE_VERSION` of `bin/polype`; refuses (exit 1) an unknown platform or a missing `cargo`; runs `cargo build --release --locked --manifest-path <root>/po/Cargo.toml --target-dir ${CARGO_TARGET_DIR:-<root>/po/target}`; copies the binary to `<out-dir>/po-<version>-<platform>` and writes `<out-dir>/po-<version>-<platform>.sha256` as `<sha256>  po-<version>-<platform>`; prints both paths. Same `po_platform` mapping as task 1. Test: `test_release_builds_one_binary_per_platform`.
6. [x] **`.github/workflows/release.yml`** — on `push` of tags `v*`; `permissions: contents: write`; job `create` on `ubuntu-latest` runs one line `gh release create "$GITHUB_REF_NAME" --repo "$GITHUB_REPOSITORY" --verify-tag --title "$GITHUB_REF_NAME" --notes "po $GITHUB_REF_NAME"` with `GH_TOKEN: ${{ github.token }}`; job `po`, `needs: create`, matrix `runner: [ubuntu-latest, ubuntu-24.04-arm, macos-latest]`, `runs-on: ${{ matrix.runner }}`, steps: `actions/checkout` pinned on the commit `ci.yml` uses, `run: bin/po-release dist`, `run: gh release upload "$GITHUB_REF_NAME" dist/po-* --repo "$GITHUB_REPOSITORY"`. No other `run:`, no Rust setup. Test: `test_release_builds_one_binary_per_platform`.
7. [x] **Docs** — `docs/installation.md`: rewrite « Le binaire `po` » (`:74-99`): where the binary comes from (the release of the tag `v<version>`, the URL), what the SHA-256 proves (the binary is the one whose sum the reviewed `bin/polype` carries) and does not prove (that it was built from these sources: the hosted runner stays trusted; a too-old glibc), the fallback lines and their order, the refusal line and its exit 1, how to force sources (`POLYPE_PO_FROM_SOURCES=1`), `POLYPE_PO_FETCH`; add `po.sum` to the state files table (`:331-338`); say the update removes the files an older `po` left under `<dossier commun de git>/polype/` and keeps the inbox (`:347-357`, replacing « s171 les nettoie »); the four `po` lines of `check` (`:493-495`); `po.sum` beside `po` among what chezmoi does not follow (`:209-213`). `docs/ci.md`: a « Publier une version » section — bump `POLYPE_VERSION` and `po/Cargo.toml` together, tag `v<version>` and push it, `release.yml` publishes one binary and its `.sha256` per platform, then a pull request pastes the `.sha256` lines into `PO_SUMS`; until it lands, installers build from sources; the publish step is the one line to swap on Forgejo. Judged in review.
8. [x] **The suite never downloads** — `tests/run.sh`, one line beside the other exports (`:9-11`): `export POLYPE_PO_FETCH=false`, unconditional, with a comment saying the suite never downloads `po` (a test that needs a download sets its own double). Through it, every installer run of the suite falls back to sources once `PO_SUMS` holds sums, as it does today with the block empty. Test: `test_suite_environment_refuses_downloads` (task tests). Check before the record: the full suite run once with `curl` and `wget` stubs first on the `PATH` that log every call and exit 1 leaves the log empty.

## Scene viewpoints
—

## Run interdicts
- `po/`, `method/`, `.github/workflows/ci.yml`, `tests/lib.sh` and every existing test file end with an empty diff; `tests/run.sh` changes by the one `POLYPE_PO_FETCH` export of task 8 and nothing else.
- `PO_SUMS` stays empty in this story: no sum is invented before a release exists.
- No test reaches the network: every installer run in the new tests sets `POLYPE_PO_FETCH` to a double, and the suite stays green offline.
- The SHA-256 of `po` is never computed with `cksum`.
- `clean_machine_files` removes nothing outside `<git common dir>/polype/`, no directory, nothing in a global run.
- ADR-0121's body stays as accepted on 2026-11-14.

## The pivot
The whole trust rests on the expected sum travelling in the versioned `bin/polype`, not beside the download (ADR-0121 option 1). Ways it could be wrong:
- `PO_SUMS` is read by a pattern looser or stricter than the `sha256sum` line `bin/po-release` writes: compare the lookup with the oracle's `expect_release_sum`.
- `bin/po-release` and `lay_po` name the platform differently on a host the suite never runs on (macOS): the oracle only proves agreement on its own host; compare both mappings line by line.
- The cleanup's list of files `po` reads drifts from `po/src/run/`: a later story adding a machine file would see it removed on the next update. Compare the list with every `dir.join(` under `po/src/`.

## Files touched
`bin/polype`, `bin/po-release` (new), `.github/workflows/release.yml` (new), `docs/installation.md`, `docs/ci.md`, `tests/run.sh` (one line), `tests/po-prebuilt-and-verified.oracle.test.sh` (written), `tests/po-prebuilt-and-verified.test.sh` (new), plus `docs/research/`, `docs/plans/` and `docs/decisions/ADR-0121-…` of this story.

## Test strategy
Automated, 8 tests within `Test budget` 25, all at the installer's own layer (bash, through `bin/polype` and `bin/po-release` of a throwaway copy, with doubles for `cargo` and the download):
- the oracle, five tests (table above);
- `tests/po-prebuilt-and-verified.test.sh`, three task tests on the same fixture shape (copied, not sourced): `test_po_record_is_a_state_file_of_the_payload` (`install --global` from the copy with a published sum, then `update --global` from the payload: no foreign-file stop, `po.sum` kept) and `test_check_accepts_a_po_laid_before_s171` (`po.sum` removed: `check --global` exits 0 and says `po not verified`) and `test_suite_environment_refuses_downloads` (a copy of Polype whose `PO_SUMS` holds a line for this platform, run with the `POLYPE_PO_FETCH` the suite exported and `curl`/`wget` stubs that log first on the `PATH`: the log stays empty and `po` is built from sources by the `cargo` double).
The existing `tests/state-as-json*.test.sh` keep proving the real source build. Visual checks: none. The full suite runs once through `po-run` at the end; no typecheck command.

## Done when
One commit `s171-po-prebuilt-and-verified: Une machine sans Rust reçoit po, vérifié` landed through a pull request, the full suite green offline, a review with no open critical finding, ADR-0121 accepted.
