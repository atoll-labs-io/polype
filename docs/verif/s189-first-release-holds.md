# Verification — s189-first-release-holds

[Story](../stories.md) · [Plan](../plans/s189-first-release-holds.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: a168ca4f83e576b5550b6436f44936359bb71c0b

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/po-prebuilt-and-verified.oracle.test.sh` (s171's oracle, not this story's) | `test_release_builds_one_binary_per_platform` accepts a `run:` value matching `^(bash )?(\./)?bin/po-release --tag ` without counting it as a build; the count of builds stays exactly 1 and every other assertion stays | task 4 adds the tag check to job `create`, which changes the clause "runs only `bin/po-release <dir>` and `gh release`" (plan task 5). Checked: the test still fails when `release.yml` gains `- run: echo hi` |
| `tests/po-prebuilt-and-verified.oracle.test.sh` (s171's oracle, fix run) | the `--tag` clause is anchored: it accepts only `bin/po-release --tag "$GITHUB_REF_NAME" <ref>` up to the end of the line | review minor at :132: the open-ended clause let `bin/po-release --tag x; <anything>` through. Checked in a throwaway copy: appending `; echo hi` to the `--tag` line of `release.yml` fails the test |
| `tests/first-release-holds.oracle.test.sh` | fix run: `publish` first gives the copy an `origin/main` holding its own `bin/polype` (empty `PO_SUMS`), as the release job's `fetch-depth: 0` checkout does; no assertion changes | review major at `release.yml:33`: `bin/po-release --tag` now reads `PO_SUMS` at `origin/main` and refuses when it cannot, so a replay without that ref fails every release. The fixture gives the replay what the real checkout gives; `release_reruns_cleanly` and `tag_must_match_the_version` still assert what they did. The sum in the plan no longer matches this file |
| `tests/first-release-holds.oracle.test.sh` | fix run 3: `test_sums_are_written_by_a_command` gives the copy a commit of `origin/main` tagged `v$VERSION` (new helper `tagged_on_main`) and calls `bin/po-release --sums "$sums" origin/main`; no assertion changes | the fix of the security finding of d-0036 makes `--sums` take the target ref as a second argument, as ADR-0105 wants it given what it compares against; the fixture gives the command what a person's clone of `main` gives. The written block, the byte-identical second run and the install from the sums are asserted as before |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- The real workflow on GitHub Actions: the tests replay `release.yml`'s `run:` lines in file order against a gh double, not Actions' job ordering (`needs: create`) nor the real `gh`. The first tag push proves it, after the story.
- `bin/po-release --sums` against a real release's `.sha256` files: the tests use files written by `bin/po-release` and hand-made sums for the platforms this host does not build.
- That `actions/checkout` with `fetch-depth: 0` on a tag push brings `refs/remotes/origin/main`, which the rerun guard reads: the tests build that ref by hand. The first tag push proves it; a missing ref makes the release refuse, never pass.
- That a tag push's checkout leaves HEAD at the tagged commit with a full (not shallow) history, which the guard's ancestry and history checks read: the tests build both by hand. A shallow checkout makes the guard refuse, never pass.
- Fix run 2: the security finding of d-0035 is closed, held by `test_release_only_from_a_commit_of_the_target_branch` (`tests/first-release-holds.test.sh`). The guard's history search, fail-closed branches and block check are held by `test_rerun_refused_after_later_sums_replace_them` and `test_tag_guard_fails_closed`. No oracle file changed in this run.
- Fix run 3: the security finding of d-0036 is closed, held by `test_sums_only_for_a_tag_of_the_target_branch` (`tests/first-release-holds.test.sh`). The review minor at `bin/po-release:44` is closed: its refusal is held by `test_tag_guard_fails_closed`; the loop's refusal of a commit whose `bin/polype` cannot be read, unless that commit dropped the file, is held by no test, since a normal clone cannot reach it (the history search reads the same blobs first). `test_sums_refuse_a_broken_line` now runs with a tag on `origin/main` and expects each refusal's own message.
- Fix run 4: the security finding of d-0037 is closed by no code in this story, as the owner decided (d-0037 to d-0039); ADR-0129 records the decision and `docs/ci.md` (« Publier une version ») links to it. The review minor at `bin/po-release:47` is settled by removing the branch that told a commit which dropped `bin/polype` apart: every commit the history search lists whose `bin/polype` cannot be read now refuses, in one line. No test was added for it: a normal clone cannot reach that line, since the history search reads the same blobs first.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1657045ef5477ff9f6cc34077f60bb275821254d | 2026-11-16T12:45:55Z (404s) |
| Unit suite | `bash tests/run.sh` | 0 | c24faee79662783d248cc6c1bcd794d9ee35ebb0 | 2026-11-16T13:01:04Z (407s) |
| Unit suite | `bash tests/run.sh` | 0 | 310dcf6d9e7ed655ae16e6e00d1a5e76678de6f3 | 2026-11-18T08:28:34Z (458s) |
| Unit suite | `bash tests/run.sh` | 0 | 5a1fea17fa17ed471f65cc94949584d22749b98b | 2026-11-18T09:02:19Z (527s) |
| Unit suite | `bash tests/run.sh` | 0 | 87502b6503374fe00dadab78c7f2e70d63e908fe | 2026-11-18T10:00:40Z (1498s) |
