# Research — s189-first-release-holds

[Story](../stories.md)

## Structuring facts
- **Wrong assumption of #299**: `--clobber` alone does not make a rerun pass. `gh release create` (`.github/workflows/release.yml:16`) fails first on a release that exists: gh 2.103.3 carries `a release with the same tag name already exists: %s` (binary strings), and the replay below stops there. Both steps must tolerate a second run.
- Root cause #297: `clean_machine_files` (`bin/polype:946-963`) keeps its guards `po_refused = no` (`:948`) and `version = POLYPE_VERSION` (`:952`), but no test puts the machine in either case: `test_upgrade_cleans_what_the_old_version_left` (`tests/po-prebuilt-and-verified.oracle.test.sh:206-235`) only checks the positive path, and the tamper scenario (`:159-170`) never looks at machine files. Neutralizing either guard leaves all 8 tests of s171 green (reproduced).
- Root cause of the tag defect: the release runs on any `v*` tag (`release.yml:4-5`) and nothing compares the tag with the version: `bin/po-release:10-15` compares `bin/polype` with `po/Cargo.toml`, never with a tag; it takes exactly one argument (`:6`).
- `PO_SUMS` (`bin/polype:30-34`) is filled by hand: `docs/ci.md:26-27` says a pull request pastes the `.sha256` lines; no command exists.
- `Owns` holds no new `bin/` file: the tag check and the sums writer both live in `bin/po-release`, which forces one change to s171's oracle (`:132`, one argument only), itself in `Owns`.

## Diagnostic
**Reproduction** (in a `git archive` copy under `/tmp/tmp.AOh660EZAG`, nothing written in the worktree):
1. #297 — `bin/polype:952` replaced by `true`, then `:948` stripped of `&& [ "$po_refused" = no ]`; each time the 8 tests of `tests/po-prebuilt-and-verified{.oracle,}.test.sh` pass. The guards are untested.
2. #297, the harm — with `:952` neutralized, an install by an installer at `0.0.1` then an `update` at 0.6.1 with no `cargo` on the PATH prints `cargo not found; po was not built, … kept as it was` then `removed …/.git/polype/old-session.json: left by an older po`: the older po stays and loses its file.
3. #299 and the tag — the `run:` lines of `release.yml`, replayed in file order against a `gh` double that refuses what gh refuses: a second replay of `v0.6.1` stops at `create` with `a release with the same tag name already exists: v0.6.1`; a replay of tag `v9.9.9-not-0.6.1` builds and uploads `po-0.6.1-linux-x86_64` and its `.sha256`.
4. Sums — `bin/po-release --sums <dir>` answers `usage: po-release <out-dir>` (exit 2).

**Hypotheses**
| # | Hypothesis | Refuting observation | Verdict |
| --- | --- | --- | --- |
| H1 | The guards are covered indirectly by `test_upgrade_cleans…` or `test_installer_downloads_and_verifies` | a guard neutralized and those tests still green | discarded: reproduction 1 |
| H2 | The version guard is redundant: a failed pose never leaves a stale `po.sum` | an update without cargo cleaning anyway once the guard is gone | discarded: reproduction 2 |
| H3 | `po_refused` matters only when `po.sum` already names this version while the binary in place differs (in the usual upgrade, `:952` already blocks) | a refused update, `po.sum` at this version, cleaning once `:948` is stripped | kept: the draft oracle's refused test fails only with `:948` stripped, and the cleanup test only with `:952` neutralized |
| H4 | #299 is upload alone (`--clobber`) | the rerun failing before upload | discarded: reproduction 3 stops at `create` |

## Story
A release of `po` refuses a tag that is not `v<version>`, reruns cleanly, the cleanup after a pose is guarded by tests, and a command writes `PO_SUMS`. Criteria: `tag_must_match_the_version`, `release_reruns_cleanly`, `cleanup_waits_for_the_new_po`, `refused_po_cleans_nothing`, `sums_are_written_by_a_command`. Publishes nothing, touches no `po/`, raises no version.

## Current code
- `bin/polype:28` `POLYPE_VERSION="0.6.1"`; `:29` `PO_RELEASES`; `:30-34` `PO_SUMS='` alone on its line, then `'` alone.
- `lay_po` (`bin/polype:889-930`): name `po-$POLYPE_VERSION-$platform` (`:901`); sum looked up by `po_expected_sum` (`:838-844`, line shape `^[0-9a-f]{64}` then name); a refused download sets `po_refused=yes` (`:920`) and keeps the po in place; `record_po` (`:855-859`) writes `po.sum` = `<sha256> <version> <prebuilt|sources>` only when a po is laid.
- `build_po` (`:861-887`): no cargo → message `cargo not found; po was not built`, `po.sum` untouched (`:868-871`).
- `clean_machine_files` (`:946-963`), called after `lay_po` in `cmd_install` (`:1096-1097`) and `cmd_update` (`:1159-1160`); both exit 1 after a refusal (`:1103`, `:1170`).
- `bin/po-release` (37 lines): one argument (`:6`), version equality (`:10-15`), platform (`:18-23`), cargo build (`:27`), `.sha256` = `<sum>  <name>` (`:33-35`).
- `release.yml`: `on.push.tags ['v*']` (`:4-5`), `permissions: contents: write` (`:7-8`); job `create` has no checkout and one step `gh release create … --verify-tag` (`:16`); job `po` (`needs: create`, matrix of 3 runners, `:18-23`) checks out (`:27`), runs `bin/po-release dist` (`:29`) and `gh release upload … dist/po-*` without `--clobber` (`:30`).
- `docs/ci.md:17-30` "Publier une version": four steps, step 4 is the hand paste.

## Attachment points
- `bin/po-release`: two new modes beside `<out-dir>`, both after the version check of `:10-15` and before the platform and cargo checks (`:18-24`), so the `create` job needs no cargo.
- `release.yml` job `create`: a checkout, the tag check, then a create that tolerates an existing release; job `po`: `--clobber`.
- `bin/polype:30-32`: the comment naming how `PO_SUMS` is filled.
- `docs/ci.md:17-30`.
- `tests/po-prebuilt-and-verified.oracle.test.sh:129-140`: the run-line loop that must accept the tag check.

## Verified interfaces
- `po_expected_sum <name>` (`bin/polype:838`) reads `PO_SUMS` line by line with `read -r sum name`; any line for another version is never matched (`:901`), so replacing the whole block loses nothing.
- s171 fixture helpers: `copy_of_polype` (oracle `:17-45`), `fetch_double` (`:66-76`), `path_without_cargo` (`:94-107`), `expect_release_sum` (`:59-62`, requires exactly one `^PO_SUMS='$` line). The convention is "copied, not sourced" (`tests/po-prebuilt-and-verified.test.sh:2-4`).
- s171 oracle run-line rule (`:129-142`): each `run:` on one line, either `^(bash )?(\./)?bin/po-release <one token>$` (counted, must be exactly 1, `:140`) or starting `gh release `; no `cargo|rustup|rustc` anywhere (`:127`); an upload naming the build dir (`:141`).
- `tests/run.sh:14` exports `POLYPE_PO_FETCH=false`; `tests/lib.sh:47-53` `scratch_repo`.
- gh 2.103.3: `release upload --clobber` "Delete and re-upload existing assets of the same name"; strings `asset under the same name already exists: %v` and `a release with the same tag name already exists: %s`.
- `bin/po-version-check:33-48` reads the three version places; this story changes none.

## Traps
- `tests/ci-on-every-pr.oracle.test.sh` (out of `Owns`) reads only `ci.yml` (`:5`): `release.yml` may gain a checkout step.
- The oracle replays `run:` lines with `bash -e -c`: a `${{ … }}` expression in a `run:` line breaks it (and would also let a tag name reach the shell unquoted). Read `$GITHUB_REF_NAME` from the environment, as `:16` and `:30` do.
- The replay keeps file order: job `create` must stay above job `po`.
- The rewritten `bin/polype` must stay executable (index mode 100755), keep `PO_SUMS='` and `'` alone on their lines, and parse (`bash -n`).
- `bin/po-release` header (`:2-3`): it reads no forge variable (ADR-0105); the tag arrives as an argument.
- s188 just changed `bin/polype` (`.polype/agents-md-aside`): untouched by this story.
- No migration, no `po/` change, no version bump (`bin/po-version-check` stays green: nothing under `po/` moves).

## Open questions
- Should a release whose matrix job failed for one platform still let `--sums` write the two others? The plan writes what is there and names each line it writes; the missing platform builds from sources (ADR-0115).
- Automating the sums pull request from the workflow (a job pushing a branch) is not taken: the story asks for a command, and it would give the release token a write path to a branch. Left to the lead to file if wanted.
- No ADR drafted: ADR-0121 fixes where the sums live and that a commit after publication writes them, ADR-0105 that scripts read no forge variable and the workflow only calls them. The place of the tag check and the command's shape are details inside `bin/po-release`; the caller may judge otherwise.

## Complexity
3 → 3. Two small modes in a 37-line script, three workflow lines, a doc section, tests in an existing fixture shape. The one surprise (create also fails on rerun) costs one line.

## Split
—
