# Verification — s36-installer

Tree: 173becfd21eea782c8d8ecef036d4aac5015f767

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Task tests — alias (tasks 1-3) | `bash tests/run.sh install.test.sh` | exit 0 · 11 passed · 0 skipped | 2026-09-22T14:10:12Z |
| Task tests — subcommands (tasks 4-7) | `bash tests/run.sh installer.test.sh` | exit 0 · 10 passed · 0 skipped | 2026-09-22T14:19:48Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 185 passed · 0 skipped | 2026-09-22T14:22:05Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`) | — |
| Build | — | no such command in this project (`Build: —`) | — |

Manual checks, all inside `mktemp -d` projects (the run interdict forbids installing into this repository):
- the four subcommands on one project in sequence, with `--hooks`: install, check (exit 0), drift then check (exit 1), update with a ghost and a project-added command, remove — `AGENTS.md` restored from the backup, `.polype/` gone, `core.hooksPath` unset, `.gitignore` and `docs/` untouched;
- drift detection on three kinds of edit — a line replaced in place, a line appended, a single byte flipped without changing the length: `cksum` reported all three.

## Not proven here
- No lint, type check, end-to-end or build exists in this project; nothing covers them at a later stage either.
- The installer was never run against this repository, so no evidence exists that installing over a tracked `.polype/` behaves as described; the `scratch_repo` projects are the only ground covered.
- The global install (`~/.claude`) and the `init` subcommand are s37's and are absent here.
- `docs/parite-killer-saas.md` (H01, H02) is not updated: `docs/stories.md` puts that file in s39's Owns.

Verification status: complete
