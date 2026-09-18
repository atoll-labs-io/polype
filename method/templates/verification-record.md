# Verification — Story <id>

> Written by the implementer as its last act before the story commit, and committed with it. The review compares `Tree:` with the commit; when they match, it takes these results as proven instead of running them again. Every command is the project's own, quoted verbatim from `AGENTS.local.md`.

`Tree:` is produced in this order: `git add -A`, then `git write-tree`, copied below. It is therefore the exact code that was tested. This file and the ticked plan are written afterwards, under `docs/`, which the comparison ignores.

Tree: <40-hex output of git write-tree>

| Check | Command | Result | When (UTC) |
| --- | --- | --- | --- |
| Full suite | `<Test>` | exit 0 · <N> passed · <M> skipped | <ISO-8601> |
| Type check | `<Typecheck>` | exit 0 | <ISO-8601> |
| End to end | — | not run: runs at ship | — |
| Build | — | not run: runs at ship | — |

A command set to `—` in `AGENTS.local.md` does not exist in this project: write `—` and say so. Never record a command you did not run, or a substitute for one that is missing.

## Not proven here
<What this record does not cover and who covers it: typically the end-to-end suite and the build, which run once at ship; the linter and formatter, which run on staged files at commit. An empty section claims that everything was checked.>

Verification status: complete
