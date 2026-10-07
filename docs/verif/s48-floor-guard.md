# Verification — s48-floor-guard

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: d01ff1d1c8c5831e55918c451ded8be4edd65b0e

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 252 passed · 0 failed · 0 skipped | 2026-10-07T17:16:40Z |
| Type check | — | no such command in this project | — |
| Lint (plan task 6) | `bin/po-lint` | exit 0 · no breach in 23 file(s) of method/ | run right after the suite, which started 2026-10-07T17:16:40Z |
| Floor guard on this story (plan task 6) | `bash method/hooks/po-gate.sh floor-guard s48-floor-guard main` | exit 0, nothing printed | 2026-10-07T17:17:36Z |
| End to end | — | no such command in this project (`E2E stage: —`) | — |
| Build | — | no such command in this project (`Build stage: —`) | — |

Floor guard run: `story/s48-floor-guard` had no commit yet, so its diff would have been empty and the 0 vacuous. The command ran instead in a throwaway `git clone --shared` where `story/s48-floor-guard` pointed at a commit of the staged tree above (7 files, 466 insertions against `main`). No branch of this repository was created.

Portability: `tests/floor-guard.test.sh` was also run with `awk` resolving to `gawk --posix` (4 guard tests green); no mawk or BSD awk is installed here.

## Not proven here
- The guard under the real macOS awk and mawk: only `gawk --posix` was available. POSIX-only constructs were used (`[[:space:]]`, `match` with `RSTART`/`RLENGTH`, `ENVIRON`, `\047`).
- The guard under a user git config that changes the diff format beyond what the tests set (`diff.noprefix`, `diff.renames=false`, `color.diff=always` in the scratch repositories; `diff.mnemonicPrefix` was tried by hand → same result).
- Formatting: no formatter in this project.

Verification status: complete
