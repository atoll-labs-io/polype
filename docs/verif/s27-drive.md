# Verification — s27-drive

Tree: 242227c76c82b478d2f0a2a196bfdf2cd41670b9

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 149 passed · 0 failed · 0 skipped | 2026-09-21T18:22:00Z |
| Method lint | `bash bin/po-lint` | exit 0 · no breach in method/ | 2026-09-21T18:22:18Z |
| Task tests — settings | `bash tests/run.sh structure.test.sh` | exit 0 · 9 passed · 0 failed | 2026-09-21T18:12Z |
| Task tests — help | `bash tests/run.sh pilot.test.sh` | exit 0 · 7 passed · 0 failed | 2026-09-21T18:17Z |
| Task tests — drive | `bash tests/run.sh drive.test.sh` | exit 0 · 5 passed · 0 failed | 2026-09-21T18:19Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

Baseline before the story, on the same branch: `bash tests/run.sh` → 144 passed, 0 failed. The five new tests of `tests/drive.test.sh` account for the difference, and no existing test was changed or relaxed.

`bash tests/run.sh pilot.test.sh` was red between task 2 and task 8 (`every_command_listed_in_help`: "missing from po-help: po-drive"), exactly as the plan predicted; task 8 closed it.

## Not proven here
- **That `/po-drive` actually drives a fleet.** Every check above reads markdown: the tests assert that the command file states the readiness clauses, the single-message dispatch, the verbatim recording, the `Max attempts` cap and the serial ships. Running a real wave of parallel lanes — several worktrees, several subagents, a squash merge — is outside this repository's test harness; only a live `/po-drive` run on a project proves the behaviour.
- **`Tracker: github`**: declared as a setting value and explicitly deferred by the command; no code path exists and none is tested.
- **Type check, end to end, build**: the project declares no such command; nothing is deferred to ship for them.
- **Formatting**: no formatter is configured in `AGENTS.local.md`.

Verification status: complete
