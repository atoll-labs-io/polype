# Verification — s134-everything-to-handle-is-an-issue

[Story](../stories.md) · [Plan](../plans/s134-everything-to-handle-is-an-issue.md)

Tree: 777f62f13a4ba8a70e1a762b156f30728f1868e9

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
- The first unit-suite run (exit 1) failed on `docs/reviews/stories-m12.md`, a framing file outside `Owns`; the lead fixed it on `main` (875acee) and the branch was rebased onto it. The second run, on the same code outside `docs/`, passed.
- The filing itself is prose an agent follows: no test runs `gh issue` or `task add`, so no filing against a real forge or Taskwarrior was exercised. Covered at the first real ship that has open findings.
- Fix run 1: the title and body commands of `/po-ship` Step 3 are executed by the tests on a fixture review (quotes, `$(…)`, numbered, bold and plain shapes, a sub-bullet); which lines an agent takes as one item, and the "shape not recognised" hand-over, stay prose and are not executed.
- Fix run 2: the title command is run under `LC_ALL=C` on an accented finding longer than 80 characters, and the body on a review holding two `Fix loop:` lines; both on GNU sed and coreutils here. BSD `sed`, a missing `C.UTF-8` locale, and the refusal of a failed or 1000-title listing are not executed (no `gh`/`task` call is allowed).
- `.claude/`, `.polype/` and the root `AGENTS.md` still hold the old method until the post-milestone refresh.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | c41da1c39c1ceda389dcd60de6d8e4f693f136dc | 2026-10-14T13:20:21Z |
| Unit suite | `bash tests/run.sh` | 0 | 4a5b258bd9b4977a81846279e45dbc112f397030 | 2026-10-14T13:28:08Z |
| Unit suite | `bash tests/run.sh` | 0 | cd23e7693a4675c9e3f23fdaf67e945973d827bf | 2026-10-14T13:40:28Z |
| Unit suite | `bash tests/run.sh` | 0 | 20dc82f4baeb2e5d1115394dafc79fad71ed7906 | 2026-10-14T13:50:34Z |
