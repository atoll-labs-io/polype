# Verification — s45-clean-uninstall

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 84202168c122a0ec72f39defdb706e45cef5ee5c

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused tests | `bash tests/run.sh installer.test.sh` | exit 0 · 12 passed · 0 failed | 2026-09-22T19:19Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 210 passed · 0 failed | 2026-09-22T19:20:14Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

## Not proven here
- No type check, end-to-end or build command exists in this project (`AGENTS.local.md`), so none ran.
- Global mode (`install --global` / `remove --global`) is not exercised by the new tests; the change sits after the `mode = global` early return and does not reach it.
- `docs/installation.md:173` still describes remove as only dropping the `@AGENTS.md` line; it is outside this story's `Owns` and left for a later story.

Verification status: complete
