# Verification — s49-secret-scan

Tree: 561cc7dd55e3f08c256d5792577cb8ddc630c1cc

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused tests | `bash tests/run.sh gate.test.sh structure.test.sh` | exit 0 · 31 passed · 0 skipped | 2026-10-07T22:41:31Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 267 passed · 0 skipped | 2026-10-07T22:41:31Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

## Not proven here
- The scan was run with this machine's awk (gawk or mawk as installed) only; macOS awk is not exercised, the patterns only keep to POSIX ERE without `{n}`, `\s` or `\b`.
- The installed copy `.polype/hooks/po-gate.sh` is not refreshed by this story; the secret gate is live in this repository only after the next install.
- Formats outside the six table rows (other providers, generic high-entropy strings) are not detected, by design (ADR-0028).

Verification status: complete
