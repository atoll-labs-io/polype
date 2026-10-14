# Verification — s33-real-parallelism

[Story](../stories.md) · [Plan](../plans/s33-real-parallelism.md)

Tree: 36068ddcd93e511ca451ec5282bd832848cb83ab

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 168 passed · 0 failed · 0 skipped | 2026-09-22T08:36Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

Focused runs and task checks, in plan order:

| Task | Check | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| 1, 8 | `grep -oE '^\| [0-9]+ \|' docs/defauts.md \| sort \| uniq -d` | empty output both times — no duplicated defect number | 2026-09-22T08:30Z, 2026-09-22T08:34Z |
| 2-7 | `bash tests/run.sh drive.test.sh` | exit 0 · 10 passed · 0 failed — the six existing tests plus the four of this story | 2026-09-22T08:33Z |
| 9 | `bin/po-lint` | exit 0 · `po-lint: no breach in 22 file(s) of method/` | 2026-09-22T08:36Z |

Before the method files were edited, each of the 17 phrases the four new tests assert was checked absent from `method/commands/po-drive.md` and `method/agents/planner.md` with `grep -qF`: every new assertion would have failed on the files as they stood. `test_drive_uses_absolute_paths_only` bites by construction — any backquoted `` `cd `` added to the driver turns it red.

Scope, checked with `git diff m3-flotte --stat`: `docs/defauts.md`, `method/agents/planner.md`, `method/commands/po-drive.md`, `tests/drive.test.sh` only. Nothing under `.claude/`, `.polype/` or `docs/decisions/`; `docs/stories.md`, `docs/parite-killer-saas.md`, `docs/conception.md`, `method/AGENTS.md` and `method/templates/agents-local.md` untouched. `git status --porcelain` lists no environment file.

## Not proven here
- **That an agent obeys these sentences.** Every check here reads a document: it proves the rule is written, not that a driver dispatches a whole stage in one message or keeps its working directory. Only a fleet run recorded in `docs/validation/` can show that; this is the recurring limit `docs/defauts.md:21` names.
- **The ADR allocation policy in practice** — reserving one number per lane leaves gaps in the sequence when a lane needs no ADR. The plan's pivot records the choice; no run has exercised it.
- End to end, production build, type check: this project declares none of these commands.
- Formatting and the pre-commit gate: at commit time.

Verification status: complete
