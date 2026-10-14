# Verification — s34-method-consistency

[Story](../stories.md) · [Plan](../plans/s34-method-consistency.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 349307f4029225375a999c253af7c4c82d4c8d76

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 171 passed · 0 failed · 0 skipped | 2026-09-22T13:43:00Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project (`E2E stage` is `—`) | — |
| Build | — | no such command in this project (`Build stage` is `—`) | — |

Focused runs during the story, all exit 0: `bash tests/run.sh ownership.test.sh` (3 passed), `bash tests/run.sh drive.test.sh resume.test.sh` (14 passed), `bash tests/run.sh drive.test.sh` (11 passed), `bash tests/run.sh drive.test.sh planner.test.sh` (16 passed), `bash tests/run.sh design.test.sh` (5 passed).

Mutation proof of task 5, run and undone: `Design source` is `—` → rewritten from `stop` to `carry on` in `method/commands/po-design.md`, plus a decoy line elsewhere holding the trigger and the word `stop`. `bash tests/run.sh design.test.sh` → exit 1, `design_test_message_matches_its_assertion` failing on the duplicated trigger; the old assertion would have stayed green. File restored and `git diff --exit-code method/commands/po-design.md` clean before anything else was written.

## Not proven here
- **That any agent obeys these sentences.** Every check reads a method document: it proves the rule is written, not that a driver reads its resume table top to bottom, that a planner reuses the research it finds, or that a reviewer fills the new `## Ownership` boxes. Only a fleet run recorded in `docs/validation/` shows that; this is the recurring limit `docs/defauts.md:21` names.
- **That the commit-count discriminator holds on a real story.** The row for a lane stopped after a fix run compares `Fix loop:` with the implementer commits on `story/<id>`. No story with a migration commit exists to exercise the drift the paragraph warns about; the `Tree:` fallback it prescribes is untested prose.
- **Lint and formatting**: no such commands in this project; `bin/po-lint` was not run, the story changes no gate section.
- **End to end and production build**: `E2E stage` and `Build stage` are `—`.

Verification status: complete
