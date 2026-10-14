# Verification — s70-reviewer-bounds

[Story](../stories.md) · [Plan](../plans/s70-reviewer-bounds.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 868d79704f1d32d2553ddd2f558b52dab9e02823

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Not proven here
- Whether Claude Code honours the reviewer's frontmatter hook in a real `/po-review` dispatch and under `claude -p --agent reviewer` (`bin/po-eval`): only the script and its wiring line are tested. The first real review and the next `po-eval` run show it.
- Whether `${TMPDIR:-/tmp}` in a real reviewer session is where the reviewer puts its probes (a sandboxed session may set a per-session TMPDIR); a mismatch fails closed.
- Bash writes (redirections, `cp`, `sed -i`, scripts running git) are outside the hook, as accepted by ADR-0047.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 2461d897fde629f2991361b9d171ac4a624ae942 | 2026-10-08T11:49:33Z |
