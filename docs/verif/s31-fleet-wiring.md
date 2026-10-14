# Verification — s31-fleet-wiring

[Story](../stories.md) · [Plan](../plans/s31-fleet-wiring.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: bbffcfcea1a1e0e062cd5c12538088cf43d2bcc0

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 161 passed · 0 failed | 2026-09-21T19:36Z |
| Method lint | `bash bin/po-lint` | exit 0 · no breach in method/ | 2026-09-21T19:38Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

Focused runs during the tasks, all exit 0: `bash tests/run.sh fleet-wiring.test.sh` after each task, plus `bash tests/run.sh fleet-wiring.test.sh wiring.test.sh pilot.test.sh` (16 passed) after the `/po-status` change, to prove the clauses those two files own stayed green.

For a command that is `—` in `AGENTS.local.md`, write `—` and "no such command in this project". Record only runs that happened, with the command that was actually used.

## Not proven here
- **Bite proof.** No clause was neutralised to watch a test go red: the doctrine leaves that to the reviewer, in a fresh context. What was checked instead, per assertion, is that each phrase the four tests grep occurs **exactly once** in the file under test (`grep -cF` = 1 for every phrase of `method/AGENTS.md` and `method/commands/po-status.md` listed in the tests), so removing the clause removes the only match. The status-cell assertion was exercised against a row still reading `partiel` (A07): the extracted cell is `partiel — …`, which the `case` rejects.
- **Behaviour of `/po-drive` and `/po-status` at runtime.** These files are prose contracts; nothing here proves an agent reading them counts lanes correctly. Only a real fleet run would.
- **Installed copies.** `.claude/`, `.polype/` and the root `AGENTS.md` still hold the previous text: `bin/polype-dev-install .` was not run, as the plan's run interdicts require. `tests/install.test.sh` covers the installer itself and stayed green.
- **Formatting and secrets**: checked at commit time; `git status --porcelain` listed no environment file.
- ADR-0016 is still `status: proposed` while `method/commands/po-drive.md` cites it as settled. `docs/decisions/` is outside this story's `Owns`, so it was left untouched — reported, not fixed.

Verification status: complete
