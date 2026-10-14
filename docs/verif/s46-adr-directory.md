# Verification — s46-adr-directory

[Story](../stories.md) · [Plan](../plans/s46-adr-directory.md)

Tree: a28fdde0ac7a383e069fdc1c990d8e9c391980cb

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Task tests | `bash tests/run.sh adr-directory.test.sh architect.test.sh lint.test.sh` | exit 0 after one fix to the new test's cleanup trap · 16 passed · 0 skipped | 2026-09-22T21:50Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 234 passed · 0 failed · 0 skipped | 2026-09-22T21:53Z |
| Lint | `bash bin/po-lint method` | exit 0 · no breach in 23 files | 2026-09-22T21:53Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

The full suite was run twice back to back on the same tree: the first run's exit code was lost to a pipe, the second one captured exit 0. Both reported 234 passed, 0 failed.

## Not proven here
- That the installed copies (`.claude/`, `.polype/`, root `AGENTS.md`) pick up the new wording: they are refreshed by the installer after ship, not by this story.
- That an agent actually resolves `<ADR directory>` from `AGENTS.local.md` at run time: the tests check the method's text and the lint, not an agent's behaviour.
- Formatting: none configured.

Verification status: complete
