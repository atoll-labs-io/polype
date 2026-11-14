# Research — s171-po-prebuilt-and-verified

[Story](../stories.md)

## Structuring facts
- **False assumption: `po` has no way to tell its own version.** `main` knows seven verbs and no `--version` (`po/src/main.rs:15-31`); the version lives only as `PO_VERSION` (`po/src/project.rs:6`), surfaced as the `method-version-mismatch` warning of `po state` (`po/src/context/mod.rs:118-127`). `po/` is outside `Owns`, so `check_audits_po` must read a version the installer recorded when it laid `po`, not one `po` reports.
- **False assumption: the machine files of `run` are the only thing under `<git common dir>/polype/`, and both are obsolete-able.** Today's `po` reads `lead-session.json` and `run.lock` (`po/src/run/session.rs:28-36`, `po/src/run/mod.rs:93`) and writes two transient siblings, `.lead-session.json.<pid>.tmp` (`session.rs:94`) and `run.lock.<pid>.stale` (`run/mod.rs:245`), which a cleanup must never remove mid-run. No file there is obsolete yet: the cleanup is a mechanism with nothing to remove on the current version.
- `po` is laid by `build_po` (`bin/polype:808-832`) at `$payload_dir/po` (`:803`), called at the end of `cmd_install` (`:940`) and `cmd_update` (`:1001`); it never changes the exit code. `check` only says `po missing:` (`:1047`).
- Every existing installer test builds `po` with the real `cargo` and never downloads: once the installer holds an expected sum for the current version, those tests would reach the network unless `tests/run.sh` (outside `Owns`) names a refusing download double.
- Two technical choices are open (ADR-0115): drafted as ADR-0121, `status: proposed`.

## Story
A machine without Rust receives `po` prebuilt for its platform, checked against an expected sum. Criteria:
1. `release_builds_one_binary_per_platform` — `bin/po-release` builds `po` for the host and writes the binary and its sum under a name carrying version and platform; the release workflow only calls it, once per published platform, and publishes its output.
2. `installer_downloads_and_verifies` — `install` and `update` fetch through a command the test replaces; a sum mismatch lays nothing, keeps `po`, exits in error naming both sums.
3. `installer_falls_back_to_sources` — no binary for the platform, or no network → build from sources and say so; no `cargo` either → lay the rest, say `po` is missing.
4. `upgrade_cleans_what_the_old_version_left` — an update replacing `po` removes the old binary and the machine files the new one no longer reads, names them, touches no decision inbox and no tracked file.
5. `check_audits_po` — `check` reports a missing `po`, a `po` whose sum is not the installed one, a `po` of another version than the project's.
6. `docs_say_what_is_verified` — judged in review.

## Current code
- `bin/polype` (1138 lines, bash ≥ 4.2, `set -euo pipefail`, `:21-26`). `POLYPE_VERSION="0.2.0"` (`:27`) equals `version = "0.2.0"` of `po/Cargo.toml:3`; the s164 oracle checks they match (`tests/state-as-json.oracle.test.sh:15`).
- `payload_dir` is `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype` (`:38-42`); a project install also lays `po` there (one per machine, ADR-0117).
- `build_po` (`:808-832`): no `po/Cargo.toml` → `no po sources in <base>; po was not built, <po_left>` (`:811-813`); no `cargo` → `cargo not found; po was not built, <po_left> (install Rust, then rerun)` (`:815-817`); `cargo build --release --locked --quiet --manifest-path … --target-dir ${CARGO_TARGET_DIR:-$base/po/target}` (`:819-820`); copy to `po.polype-next`, `chmod +x`, `mv -f` (`:825-826`). `po_left` says `kept as it was` or `is missing` (`:806`).
- `is_payload_state_file` (`:299-305`) lists `manifest|checksums|version|payload.sums|po|*.next|*.polype-next` at the payload root; anything else unlisted stops a global run as foreign (`refuse_foreign_payload_files`, `:356-395`).
- `cmd_check` (`:1013-1050`): exit 1 on modified/missing laid files or a missing version stamp; the `po missing` line and `missing_settings` do not change the exit.
- `ignore_decision_inbox` (`:584-594`): the inbox is a folder, `.polype/inbox/` by default (`method/templates/agents-local.md:40`), any path per its setting (`:75`).
- `.github/workflows/ci.yml`: one job, `actions/checkout` pinned on `11d5960a…` (v4.4.0), `jq` install, `bin/po-ci`. Its oracle forbids any write right in `ci.yml` (`tests/ci-on-every-pr.oracle.test.sh`), a rule that targets that file only.
- `tests/run.sh:9-24` exports `CARGO_TARGET_DIR` (the repository's `po/target`) and builds `po` once before the suite; every test sees the same `CLAUDE_CONFIG_DIR`.
- `docs/installation.md:74-99` ("Le binaire `po`") describes the build from sources and says "Jusqu'à s171…"; `:324-357` lists state files and the two machine files of `po run`; `:484-501` reads a `check` report. `docs/ci.md` (27 lines) has no release section.
- No git tag exists; the repository is `github.com/atoll-labs-io/polype`.

## Attachment points
- `bin/polype`: replace `build_po` with a step that tries the prebuilt binary first, then the existing build; extend `is_payload_state_file`; extend `cmd_check`; the cleanup runs in project mode after `po` is in place.
- New `bin/po-release` (shipped to the payload with the rest of `bin/`, `bin/polype:150`).
- New `.github/workflows/release.yml`.
- Docs: `docs/installation.md` sections above; `docs/ci.md` new section.

## Verified interfaces
- `sum_of` is `cksum` (`bin/polype:171`): a CRC, not a security hash. The binary's sum must be SHA-256 (`sha256sum`, or `shasum -a 256` on macOS; both present here).
- `curl` and `wget` present on this machine; the installer currently uses neither.
- Machine dir: `<git rev-parse --path-format=absolute --git-common-dir>/polype` (`po/src/run/session.rs:29-32`).
- The s164 tests the installer must keep green: `test_installer_builds_po_from_sources` (`tests/state-as-json.oracle.test.sh:276-310`, greps `po missing`, `cargo not found`, needs exit 0 without cargo), `test_po_is_a_state_file_of_the_payload` (`tests/state-as-json.test.sh:146-165`, greps `no po sources`, needs `check --global` exit 0 after a source build).

## Traps
- **Network in the suite.** With an empty sums block (the state this story ships), no test downloads. The first release commit that adds sums for the current version makes every installer test fetch for real, unless `tests/run.sh` exports a refusing `POLYPE_PO_FETCH`. `tests/run.sh` is not in `Owns`: a gap of the story.
- A new state file beside `po` (the recorded sum and version) must be added to `is_payload_state_file`, or every global run from the payload stops on it as foreign (ADR-0095).
- The oracle's cargo double writes into `$CARGO_TARGET_DIR/release/po`: the oracle overrides `CARGO_TARGET_DIR`, and `bin/po-release` must honour it exactly as `build_po` does, or the suite's real `po` gets overwritten.
- A sum mismatch must exit non-zero after the method is laid: under `set -e` and the `report_the_stop` EXIT trap (`:79-101`), which only prints set-aside notes.
- `po-release` must refuse when `po/Cargo.toml`'s version differs from `POLYPE_VERSION`: `check` and `po state` both assume they match.
- `check` on a `po` laid by the s164 installer has no recorded sum: it must say so without failing, or `check --global` turns red on every machine upgraded from s164.
- Tests that freeze the installer: `tests/install*.test.sh`, `tests/global-install.test.sh`, `tests/installer-leftovers*.test.sh`, `tests/state-as-json*.test.sh`, `tests/payload-refuses-foreign-files.test.sh`.
- No migration.

## Open questions
- Whether `ubuntu-24.04-arm` and `macos-latest` runners ship `cargo` and `gh` (`ubuntu-latest` does): `po-release` exits naming `cargo` if absent; the first tagged run shows it.
- A Linux binary built on `ubuntu-latest` needs a recent glibc: an older machine fails to run it after the sum check passed. The plan does not probe the binary; the docs say how to force sources.
- The publish step (`gh release`) is GitHub-specific; on Forgejo only that step changes (ADR-0105 allows it, the call to `bin/po-release` stays).
- When a later `po` adds a machine file, the installer's list of files `po` reads must grow with it, or an upgrade removes it: no test links the two.

## Complexity
Story 4 → 4. One bash file of 1138 lines with two install paths, a release script and workflow, a cleanup and a check; the oracle runs entirely on doubles. Not 5: no Rust change, no new dependency of the crate.

## Split
—
