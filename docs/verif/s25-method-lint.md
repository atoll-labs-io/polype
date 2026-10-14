# Verification — s25-method-lint

[Story](../stories.md) · [Plan](../plans/s25-method-lint.md)

Tree: 33b0def2fc8bfaab714f3e805c00cefbb66012f8

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 140 passed · 0 failed | 2026-09-21T17:38:12Z |
| Method lint | `bash bin/po-lint` and `bash bin/po-lint method` | exit 0 each · no breach reported | 2026-09-21T17:10:30Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E stage: —`) | — |
| Build | — | no such command in this project (`Build stage: —`) | — |

Focused runs during the story, all exit 0: `bash tests/run.sh lint.test.sh` (4 passed), `design.test.sh` (5), `design-system.test.sh` (4), `flow.test.sh` (4), `design-handoff.test.sh` (5).

## Not proven here
- That the lint's rules are the right ones for a method tree Polype has not seen: they are calibrated on this repository's `method/` only (35 absence-triggered rules inside gate sections, 0 counter-examples at the time of writing). A method tree written differently could hit a false positive; nothing here proves otherwise.
- That an agent *obeys* the rules the lint and the hardened tests check. These are structural checks on the prompts; behaviour is only proven by the end-to-end passes recorded under `docs/validation/`.
- Lint and formatting of the shell sources: this project declares no linter or formatter beyond `bin/po-lint` itself.
- The `Reads settings:` duplication between `bin/po-lint` and `tests/structure.test.sh:31-44` is deliberate (the research's open question); nothing here decides which one should survive.

Verification status: complete
