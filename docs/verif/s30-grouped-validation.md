# Verification — s30-grouped-validation

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 4523f2c4607c06566eeacccc6750d25147b8a53d

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Task tests (3, 4, 5) | `bash tests/run.sh drive.test.sh resume.test.sh` | exit 0 · 8 passed · 0 failed | 2026-09-21 |
| Task tests (6) | `bash tests/run.sh grouped-validation.test.sh` | exit 0 · 3 passed · 0 failed | 2026-09-21 |
| Unit suite | `bash tests/run.sh` | exit 0 · 157 passed · 0 failed · 0 skipped | 2026-09-21 |
| Method lint | `bin/po-lint method` | exit 0 · no breach in method/ | 2026-09-21 |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

## Not proven here
- No type check exists here: `Typecheck` is `—` in `AGENTS.local.md`. The method files are markdown and the tests are bash, so the suite itself is what loads and executes every changed file.
- No end-to-end run and no production build: both commands are `—`, and their stage settings are `—`.
- That the three new tests bite — deleting the clause each names from `po-drive.md` or from the ADRs — is proven by the reviewer in a fresh context (ADR-0012), not here.
- Formatting and the pre-commit gate run at commit time.
- `docs/parite-killer-saas.md` line T4 keeps pointing at the now superseded ADR-0014: the plan leaves that file to s31-fleet-wiring, which owns it.

Verification status: complete
