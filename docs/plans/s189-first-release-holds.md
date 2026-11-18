---
validated: yes
---
# Plan — s189-first-release-holds

[Story](../stories.md) · [Research](../research/s189-first-release-holds.md)

Branch `story/s189-first-release-holds`. Read `docs/research/s189-first-release-holds.md` first; this plan builds on it without repeating it. Full track: the story carries `Corrige` (#297, #299). Validated by the planner under `Plan validation: autonomous`; no human reviewed it.

## Story
A release of `po` refuses a tag that is not `v<version>`, reruns cleanly, the cleanup after a pose is held by tests, and a command writes `PO_SUMS`. Criteria: `tag_must_match_the_version`, `release_reruns_cleanly`, `cleanup_waits_for_the_new_po`, `refused_po_cleans_nothing`, `sums_are_written_by_a_command`. The story publishes nothing, touches no `po/`, raises no version.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `bin/po-release --tag <tag>` | new code, a few lines reusing the version read and equality check of `bin/po-release:10-15` | no script compares a tag with the version; `bin/po-version-check` compares files with a git base, not a tag |
| `bin/po-release --sums <dir>` | new code; the line shape is the one `bin/po-release:33-35` writes and `po_expected_sum` (`bin/polype:838-844`) reads; `awk`/`mv` of the platform | nothing in the repository rewrites `PO_SUMS`; the s171 tests' `sed …/r` (`tests/po-prebuilt-and-verified.oracle.test.sh:59-62`) appends and is not idempotent |
| idempotent release steps | gh already on the runner: `gh release view`, `gh release upload --clobber` | — (no new code) |
| test fixtures | copied from s171's oracle (`copy_of_polype`, `fetch_double`, `path_without_cargo`), per the "copied, not sourced" convention (`tests/po-prebuilt-and-verified.test.sh:2-4`) | — |

## Acceptance tests
All five criteria are read by a script (the workflow, `bin/po-release`, `bin/polype`): each has its oracle test. No criterion is a model-read rule, so none is a `po-eval` candidate.

| Oracle file | cksum |
| --- | --- |
| `tests/first-release-holds.oracle.test.sh` | `346624413 11057` |

| Criterion | Test |
| --- | --- |
| `tag_must_match_the_version` | `test_tag_must_match_the_version` — replays `release.yml`'s `run:` lines against a gh double: a wrong tag, and a right tag with `po/Cargo.toml` at another version, fail with no upload; the right tag publishes |
| `release_reruns_cleanly` | `test_release_reruns_cleanly` — the same replay twice on one tag; the second passes and the assets stay |
| `cleanup_waits_for_the_new_po` | `test_cleanup_waits_for_the_new_po` — install by an installer at `0.0.1`, update at this version with no cargo: the older po's file stays; with cargo it goes |
| `refused_po_cleans_nothing` | `test_refused_po_cleans_nothing` — a tampered download is refused and the machine file stays; an intact one cleans it |
| `sums_are_written_by_a_command` | `test_sums_are_written_by_a_command` — `bin/po-release --sums <dir>` writes the three lines, a second run leaves `bin/polype` byte-identical, and the installer lays the published po from them |

The two guard tests pass on today's code: they add the missing proof. In research, each fails only when its own guard is removed (`bin/polype:952` → cleanup test, `:948` → refused test).

## Tasks
1. [x] **Guard tests in place.** Run `bash tests/run.sh first-release-holds.oracle.test.sh`: `test_cleanup_waits_for_the_new_po` and `test_refused_po_cleans_nothing` pass with `clean_machine_files` (`bin/polype:946-963`) unchanged. No code. Fails if: a guard is wrong or the fixture does not reach it (the reviewer's bite check removes each guard).
2. [x] **`bin/po-release --tag <tag>`.** Usage becomes `usage: po-release <out-dir> | --tag <tag> | --sums <dir>` (exit 2 on any other shape). The mode runs after the version equality of `:10-15` and before the platform and cargo checks (`:18-24`): exit 0 when `<tag>` is exactly `v<version>`, else exit 1 with a line naming the tag and the version expected; it writes nothing. The `<out-dir>` mode is unchanged. Test: oracle `test_tag_must_match_the_version`.
3. [x] **`bin/po-release --sums <dir>`.** After the same equality check, reads every `<dir>/po-<version>-*.sha256`. Each file must hold one line `<64 lowercase hex>  <name>`, `<name>` equal to the file name without `.sha256` and of the shape `po-<version>-(linux|macos)-(x86_64|aarch64)`. Any bad file, or none found → exit 1 naming it, `bin/polype` untouched. Otherwise the lines between `PO_SUMS='` and `'` of `$root/bin/polype` are replaced wholly by these lines, sorted by name (sums of another version are never read, `bin/polype:901-902`); `PO_SUMS='` and `'` stay alone on their lines. Same content → nothing written; else write beside it and `mv`, keeping the file executable. Prints each line written, or that the block was already current. Tests: oracle `test_sums_are_written_by_a_command`; task test `test_sums_refuse_a_broken_line` (a malformed sum, a name that differs from its file, a directory with no sum of this version: exit non-zero, `cksum` of `bin/polype` unchanged).
4. [x] **`release.yml`.** Job `create` (kept above job `po`): add the checkout step with the same pinned SHA as `:27`; then `- run: bin/po-release --tag "$GITHUB_REF_NAME"`; then `- run: gh release view "$GITHUB_REF_NAME" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1 || gh release create "$GITHUB_REF_NAME" --repo "$GITHUB_REPOSITORY" --verify-tag --title "$GITHUB_REF_NAME" --notes "po $GITHUB_REF_NAME"`. Job `po`: append `--clobber` to the upload (`:30`). Each `run:` on one line, values from the environment, no `${{ }}` inside a `run:`. Tests: oracle `test_tag_must_match_the_version`, `test_release_reruns_cleanly`; task test `test_wrong_tag_creates_no_release` (a replay of a wrong tag leaves no release on the gh double: the check runs before `create`).
5. [x] **s171's oracle accepts the tag check.** In `tests/po-prebuilt-and-verified.oracle.test.sh:129-139`, a `run:` value matching `^(bash )?(\./)?bin/po-release --tag ` is accepted without counting as a build; the build count stays exactly 1 (`:140`) and every other assertion stays. This changes the clause "runs only `bin/po-release <dir>` and `gh release`" that task 4 changes; record it in `## Oracle changes` of the verification record, as a change to s171's oracle. Test: `test_release_builds_one_binary_per_platform` passes on the new workflow and fails if `release.yml` gains any other command.
6. [x] **Words.** `bin/polype:30-32`: the comment says the block is written by `bin/po-release --sums` from a release's `.sha256` files (docs/ci.md), not pasted. `docs/ci.md` "Publier une version" (`:17-30`), in French: step 3 says the `create` job checks the tag with `bin/po-release --tag` and stops before creating anything when it is not `v<version>`, and that rerunning a release, all jobs or the failed ones, is safe; step 4 becomes: `gh release download v<version> --pattern '*.sha256' --dir <dossier>`, then `bin/po-release --sums <dossier>`, then a pull request, with the Forgejo note kept. Add one sentence: once the sums have landed, never rerun that release, since a rebuild changes the binary and every installer would refuse it; publish a new version instead. Check: reading; `bash tests/run.sh` stays green (no test reads `docs/ci.md`).

## Scene viewpoints
—

## Run interdicts
- `po/`, `bin/po-version-check`, `bin/po-ci`, `.github/workflows/ci.yml`, `tests/ci-on-every-pr*.test.sh`, `tests/po-prebuilt-and-verified.test.sh`, `docs/installation.md`: empty diff.
- `bin/polype`: the diff touches only the comment of `:30-32`. `POLYPE_VERSION` stays `0.6.1`, the `PO_SUMS` block stays empty, `clean_machine_files` and `lay_po` are unchanged.
- No `git tag`, no push of a tag, no `gh release` against the real forge, no `bin/po-release --sums` on the worktree's own `bin/polype`: the story publishes nothing.
- `release.yml`: `permissions` stay `contents: write` alone; no `uses:` other than `actions/checkout` at the SHA already pinned; no `cargo`, `rustc`, `rustup`; no `${{ }}` inside a `run:`.
- `tests/first-release-holds.oracle.test.sh` keeps its sum unless `## Oracle changes` of the record says why.
- The `<out-dir>` mode of `bin/po-release` keeps its output names, its `.sha256` line and its refusal when the two versions differ.

## The pivot
The tag check lives in `bin/po-release --tag`, called by the `create` job before anything is created, and the rerun is made safe by `view || create` and `--clobber`. Ways it could be wrong:
- **Order.** The oracle replays `run:` lines in file order; Actions orders jobs by `needs: create`. Compare: `po` keeps `needs: create`, `create` stays first in the file.
- **`--clobber` against the sums.** A rerun rebuilds; builds are not reproducible, so the binary and its `.sha256` change together. That is safe while `PO_SUMS` does not name them, and breaks every install once it does. Compare: task 6's sentence in `docs/ci.md`; a "skip what exists" upload would be worse, pairing an old binary with a new `.sha256` after a partial upload.
- **`view ||` hides a failure.** If `gh release view` fails for a reason other than "not found", `create` runs and fails loudly: no silent pass. Compare: the gh double refuses `create` on an existing release, as gh 2.103.3 does.

## Files touched
`bin/po-release`, `.github/workflows/release.yml`, `bin/polype` (comment), `docs/ci.md`, `tests/po-prebuilt-and-verified.oracle.test.sh`, `tests/first-release-holds.oracle.test.sh` (written by the planner), `tests/first-release-holds.test.sh`, `docs/research/s189-first-release-holds.md`, `docs/plans/s189-first-release-holds.md`.

## Test strategy
Automated, 7 new tests within `Test budget: 25`: the 5 oracle tests, plus `test_wrong_tag_creates_no_release` and `test_sums_refuse_a_broken_line` in `tests/first-release-holds.test.sh` (same fixture shape, copied). One changed assertion in s171's oracle (task 5). The workflow is tested by replaying its `run:` lines against a gh double: the double reproduces gh's two refusals (an existing release on `create`, an existing asset on `upload` without `--clobber`), the very conditions the criteria are about, which no test can reach on the real forge; that is the sentence the doctrine asks of a hand-written double. The cargo double and the download double are s171's. Task tests run per task with their files only; the full suite once at the end through `po-run`. Reviewer bite checks: strip `&& [ "$po_refused" = no ]` from `bin/polype:948` → `test_refused_po_cleans_nothing` fails; replace `:952` by `true` → `test_cleanup_waits_for_the_new_po` fails; drop `--clobber` or the `view ||` → `test_release_reruns_cleanly` fails; drop the `--tag` step → `test_tag_must_match_the_version` fails.

No visual check.

## Done when
The five oracle tests and the two task tests pass, the full suite is green through `po-run`, the review leaves no open critical finding, and the story lands as one commit through a pull request. #297 and #299 close with it. Pushing the first tag and landing its sums stay gestures the lead proposes to the owner afterwards.
