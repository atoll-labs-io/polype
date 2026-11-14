# Verification — s180-record-review-loose-ends

[Story](../stories.md) · [Plan](../plans/s180-record-review-loose-ends.md)

Tree: 4e8f716abbb45b29173c5ed79bac4e53a7d2ecb7

## Checks
| Check | Command | Note |
| --- | --- | --- |
| suite | `bash tests/run.sh` | run on the committed code, around issue #254 |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
- The doc-comment wording of `keep()` and of the shared rollback is judged by reading, not by a test.
- The existing-review case of the last-write failure (restore refused too) is not tested; the shared rollback is held by the existing-review case of `failed_keep_rolls_the_review_back`.
- Fix run 1: the window between the check of the canonical folder and the opening of the file inside `write_private` is judged by reading; no concurrent race was run.
- Fix run 1: the decision's context now names the canonical path of the file; the suite runs on Linux only, so a platform whose temp folder is itself a symlink was not run.
- Fix run 2: the parity of `place` with main was probed by hand on 44 paths with a build of main's `po` (no input main refuses is accepted; every new refusal holds a `..`); the suite holds the shapes the review named and their neighbours, not that comparison.
- Fix run 2: the `Unverified` answer for an ancestor that exists but cannot be canonicalised, or for a path with no existing ancestor, is judged by reading; neither can be reached without a race.

Verification status: complete

## Runs

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| suite | `bash tests/run.sh` | 0 | 761607b1ec96ea0a1288fcb56dcae1f01594c2d5 | 2026-11-14T17:49:11Z (394s) |
| suite | `bash tests/run.sh` | 0 | 2a88f208c7b53af38436558422a67974ffb551b5 | 2026-11-14T19:12:34Z (391s) |
| suite | `bash tests/run.sh` | 0 | 4e8f716abbb45b29173c5ed79bac4e53a7d2ecb7 | 2026-11-14T19:42:05Z (493s) |
