# Verification — s54-untrusted-output

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: b2dbc44d37fc898e3bdf00295f45361f64848d30

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 276 passed · 0 failed · 0 skipped | 2026-10-08T07:43:00Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project (`E2E stage: —`) | — |
| Build | — | no such command in this project (`Build stage: —`) | — |

Focused run during the tasks: `bash tests/run.sh structure.test.sh distribution-wiring.test.sh qa.test.sh install.test.sh` — exit 0, 32 passed, 0 failed (includes the two new tests `rules_treat_tool_output_as_data` and `rules_list_every_installed_hook`).

## Not proven here
- That an agent actually reports rather than follows an instruction met in tool output: the rule is prose in `method/AGENTS.md`, no hook enforces it.
- The root `AGENTS.md`, `.claude/` and `.polype/` are not refreshed by this story (installed copies, refreshed on `main` after ship).
- Run interdicts checked by hand: `git diff --stat` touches only `method/AGENTS.md` and `tests/structure.test.sh` outside `docs/`; `grep -c po-run method/AGENTS.md` prints 0; no existing test changed.
- No screen in this story, so no visual check.

Verification status: complete
