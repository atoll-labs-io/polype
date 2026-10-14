# Verification — s40-profile-format

[Story](../stories.md) · [Plan](../plans/s40-profile-format.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: b81e2ebe66084f6b01c18a4bd123c64da2835204

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 214 passed · 0 skipped · 0 failed | 2026-09-22T19:26:30Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

Focused runs during the tasks: `bash tests/run.sh lint.test.sh` (exit 0, 6 passed, after the lint rule) and `bash tests/run.sh profile.test.sh` (4 passed once `docs/catalogue.md` existed). `bash bin/po-lint` on the real tree: exit 0, "no breach in 23 file(s) of method/".

## Not proven here
- No real profile exists yet (`boilerplates/` arrives with s42): the lint rule is proven only on a profile copied from the template and three mutants of it (missing section, renamed command, unknown capability). A template command removed from a profile's fence is reported by the code but not exercised by a test.
- Whether the French wording of `docs/catalogue.md` and the parity cells reads right is left to the review.
- No type check, end-to-end or build: this project has none of these commands.

Verification status: complete
