# Verification — s47-review-tree

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: b9e960adc8a4cfedf252d2b51fecb9201aea2696

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 240 passed · 0 skipped | 2026-10-07T16:49:53Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

Focused runs during the tasks: `bash tests/run.sh gate.test.sh` (18 passed), `review.test.sh` (8 passed), `ship.test.sh` (7 passed), `drive.test.sh resume.test.sh` (15 passed), all exit 0.

## Not proven here
- `bin/ks-overlap` against gstack (`28f1385`) and agent-skills (`1401c8b`), asked by M6 before the PR: neither source tree is present on this machine, so it did not run. `tests/overlap.test.sh` (Killer SaaS) is part of the suite above and passed. Someone with the sources checked out should run `bin/ks-overlap <src>` for each before the ship.
- The installed copies (`.polype/hooks/po-gate.sh`, `.claude/`, root `AGENTS.md`) still hold the old gate until `bin/polype-dev-install .` runs after the merge; this story's own ship goes through the old gate.
- The reviewer's two `rev-parse` captures (before reading, again before answering) are method text; no test runs a real reviewer to prove it does them.

Verification status: complete
