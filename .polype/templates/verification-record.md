# Verification — <id>

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: <hash printed by git write-tree>

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `<Test>` | exit <code> · <passed> passed · <skipped> skipped | <ISO-8601> |
| Type check | `<Typecheck>` | exit <code> | <ISO-8601> |
| End to end | — | deferred to ship | — |
| Build | — | deferred to ship | — |

For a command that is `—` in `AGENTS.local.md`, write `—` and "no such command in this project". Record only runs that happened, with the command that was actually used.

## Not proven here
<What this record does not cover, and which stage covers it — usually end-to-end and build at ship, lint and formatting at commit. Leaving this empty means claiming everything was checked.>

Verification status: <complete | incomplete>
