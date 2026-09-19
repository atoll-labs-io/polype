# Verification — s20-wiring

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 88f946bcd188107bf9d969f3d2e3c783df9bccec

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused, fix run (findings 1–7) | `bash tests/run.sh wiring.test.sh pilot.test.sh structure.test.sh` | exit 0 · 22 passed · 0 failed | 2026-09-19 (fix run) |
| Focused, fix run | `bash tests/run.sh wiring.test.sh` | exit 0 · 6 passed · 0 failed | 2026-09-19 (fix run) |
| Unit suite, fix run | `bash tests/run.sh` | exit 0 · 123 passed · 0 failed | 2026-09-19 (fix run) |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

## Not proven here
- The tests are static phrase checks on method files: they prove the clauses exist, not that an agent following `/po-orchestrator` or `/po-status` behaves as written on a real project. A person should run `/po-status` and `/po-orchestrator` once on a project with framing files and an `auto` track to observe it.
- The installed copies under `.claude/` and `.polype/` of this repository are not updated by this story; they change on the next install.
- No visual check: the story produces no screen.
- Static phrase tests cannot tell a rule from its opposite unless they quote the exact rule. The track test now quotes the `auto` comparison verbatim ("is at most `Flow threshold`; above it, …"), so rewording it fails the test; a semantic inversion expressed in other words would still pass. The same limit holds for every test in `tests/wiring.test.sh`.
- The design hand-off (Law 4, orchestrator stages 4 and 5) is not yet in `method/agents/implementer.md` or `method/commands/po-plan.md`, which this story does not own: a screen story run through `/po-execute` or `/po-plan` directly, outside `/po-orchestrator`, still meets the older contracts.

Verification status: complete
