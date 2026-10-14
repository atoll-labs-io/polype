# Verification — s32-fleet-consistency

[Story](../stories.md) · [Plan](../plans/s32-fleet-consistency.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 3af59eb712a9f3b8cd3acd0505e61536bc6d1643

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 164 passed · 0 failed | 2026-09-22T07:49Z |
| Method lint | `bash bin/po-lint` | exit 0 · `po-lint: no breach in 22 file(s) of method/` | 2026-09-22T07:49Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

Focused runs during the tasks, all exit 0 on their final state: `bash tests/run.sh lint.test.sh` (6 passed) after tasks 1–5, `bash tests/run.sh drive.test.sh` (6 passed) after tasks 6–8, `bash tests/run.sh fleet-wiring.test.sh` (4 passed) after task 9, and `bash tests/run.sh overlap.test.sh drive.test.sh structure.test.sh` (16 passed) after reordering the `Reads settings:` line.

An earlier full-suite run (163 passed, 1 failed) caught `overlap.test.sh`: putting `Design source` between `Plan validation` and `Merge mode` created an eight-word run shared with Killer SaaS (ADR-0006). `Design source` was moved after `Install` in the same line; the suite above is the run on the fixed state.

For a command that is `—` in `AGENTS.local.md`, write `—` and "no such command in this project". Record only runs that happened, with the command that was actually used.

## Bite, proven against the pre-story files
The three new tests were written after their code, then run once against the committed state of the file they cover, which was restored immediately (diff checked after each restore):
- `bin/po-lint` from `HEAD` → `lint_fails_when_it_reads_nothing` FAIL ("lint exited 0 having read no file"), `lint_reports_how_many_files_it_read` FAIL ("the summary does not say it read 22 file(s)"), the other four lint tests still ok.
- `method/commands/po-drive.md` from `HEAD` → `drive_lane_includes_design_when_the_story_has_a_screen` FAIL ("the wave section names no design stage"), the other five drive tests still ok.

## Not proven here
- **Deeper mutation.** Only the whole-file pre-story state was replayed; no single clause of the new prose was neutralised one at a time. Whether each phrase the drive test greps is the only match in `po-drive.md` was not measured — the reviewer's job, in a fresh context.
- **Runtime behaviour of the lane.** `method/commands/po-drive.md` is a prose contract: nothing here proves a driver reading it actually stops a lane at the design stage, or that the report names `/po-design <id>`. Only a real fleet run on a story with a screen would, and the fleet has no design subagent (defect 24).
- **`matrix_and_adr_index_agree_on_the_fleet`** has no automated test, as the plan's test strategy argues: `tests/fleet-wiring.test.sh` pins D17, which the four rewritten cells now align on, and it stayed green. The rest of that criterion is the diff of `docs/parite-killer-saas.md`, `docs/conception.md` and `docs/defauts.md`, for the review to read.
- **Installed copies.** `.claude/`, `.polype/` and the root `AGENTS.md` still hold the previous text: `bin/polype-dev-install .` was not run, as the plan's run interdicts require.
- **No screen.** This story produces no screen, so there was no browser check.
- **Formatting and secrets**: checked at commit time; `git status --porcelain` listed no environment file.

Verification status: complete
