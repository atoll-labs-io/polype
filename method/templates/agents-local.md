# <project> — Polype settings and conventions

**This file belongs to the project.** The installer never overwrites it and `/po-setup` is the only command that creates it. `AGENTS.md` belongs to the method and is rebuilt on every install: write nothing there.

Every value below is read by the pipeline. One setting per line, `Name: value`, nothing else on the line: the value is everything after the first colon, trimmed. Change any of them at any time; rerun the installer afterwards so the conventions reach `AGENTS.md`.

## Pipeline settings

```
Merge mode:        pr
Target branch:     main
Plan validation:   human
Ship confirmation: human
Test budget:       25
Verification mode: record
Full suite:        execute-end
E2E stage:         ship
E2E scope:         nominal
E2E browsers:      —
Build stage:       ship-if-route
Issue tracker:     github
Worktree root:     .worktrees/
```

| Setting | Accepted values |
| --- | --- |
| Merge mode | `pr` (pull request against the target branch) · `local` (squash merged locally, no review platform) |
| Target branch | the branch stories land on |
| Plan validation | `human` (a checkpoint waits for you) · `autonomous` (the agent validates its own plan and says so) |
| Ship confirmation | `human` (asked before every merge) · `automatic` |
| Test budget | tests per story; a plan asking for more says why |
| Verification mode | `record` (the review trusts a current verification record) · `rerun` (the review runs everything again) |
| Full suite | when the whole unit suite runs: `execute-end` · `ship` · `both` |
| E2E stage | when the end-to-end suite runs: `ship` · `ci` · `—` |
| E2E scope | how far it goes; `nominal` is one happy path |
| E2E browsers | browsers during the cycle, e.g. `chromium`; `—` means the project default. Ship runs them all |
| Build stage | when the production build runs: `ship-if-route` (only if a route or manifest moved) · `ship` · `ci` · `—` |
| Issue tracker | where defects go: `github` · `taskwarrior` · `—` |
| Worktree root | directory holding the story worktrees, with a trailing slash |

## Project commands

```
Package manager:   —
Install:           —
Test:              —
Typecheck:         —
E2E:               —
Build:             —
```

A command left at `—` does not exist in this project: agents say so and never invent one. `Test` must accept test file paths as arguments so a focused run is possible.

## Project conventions

<< structure, stack, patterns, naming, commit rules >>
