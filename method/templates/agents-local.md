# <project> — Polype settings

This file is the project's. Polype's installer never rewrites it; `/po-setup` writes it once and you edit it afterwards. Rules live in `AGENTS.md`, which the installer regenerates — do not edit that one.

Format: one `Name: value` per line inside the blocks below, with no comment after the value (anything after the colon is the value). After a change, rerun the installer so the conventions at the bottom reach `AGENTS.md`.

## Pipeline

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
QA stage:          —
Issue tracker:     github
Worktree root:     .worktrees/
ADR directory:     docs/decisions/
Entry mode:        —
Design source:     —
Design skill:      —
Design tool:       —
Story track:       auto
Flow threshold:    2
Parallel:          3
Max attempts:      2
Tracker:           none
```

| Setting | Values |
| --- | --- |
| Merge mode | `pr` — a pull request to the target branch · `local` — squash merge on this machine |
| Target branch | where finished stories land |
| Plan validation | `human` — you approve each plan · `autonomous` — the planner approves its own and says so |
| Ship confirmation | `human` — you approve each merge · `automatic` — the review gate is enough |
| Test budget | maximum tests per story before the plan must justify more |
| Verification mode | `record` — a review reuses a current verification record · `rerun` — a review repeats the checks |
| Full suite | where the complete unit suite runs: `execute-end` · `ship` · `both` |
| E2E stage | where end-to-end tests run: `ship` · `ci` · `—` |
| E2E scope | how much end-to-end runs; `nominal` means one happy path |
| E2E browsers | browsers used before ship, e.g. `chromium`; `—` leaves the project default. Ship always uses all of them |
| Build stage | where the production build runs: `ship-if-route` (only when routing or a manifest changed) · `ship` · `ci` · `—` |
| QA stage | `screens` — /po-qa walks the screens a story touches before its review · `—` — no QA stage |
| Issue tracker | where defects are filed: `github` · `taskwarrior` · `—` |
| Worktree root | folder that holds story worktrees, ending with `/`; kept out of git by `.gitignore` |
| ADR directory | where the project's ADRs live, with its own numbering; ends with `/` |
| Entry mode | where the project starts: `replace` — build an internal replacement of a paid SaaS · `adapt` — a competing product with its own angle · `new` — an idea from scratch · `—` not chosen yet |
| Design source | who draws the screens: `internal` — screens drawn in the repository by an agent skill · `external` — a tool outside the repository · `—` means design commands stop and ask |
| Design skill | skill that draws the screens when `Design source` is `internal`; `—` otherwise |
| Design tool | tool the screens come from when `Design source` is `external`; `—` otherwise |
| Story track | `full` — every story walks every stage · `flow` — every story takes the short track · `auto` — the short track up to `Flow threshold` |
| Flow threshold | highest story complexity allowed on the short track when `Story track` is `auto` |
| Parallel | how many story lanes the fleet driver runs at once |
| Max attempts | fix runs a story gets before the fleet driver hands it to a human |
| Tracker | where the fleet publishes story state: `none` · `github` when the repository has a remote |

## Commands

```
Package manager:   —
Install:           —
Test:              —
Typecheck:         —
E2E:               —
Build:             —
Dev:               —
```

Agents run these exactly as written. `—` means the project has no such command, and no agent will make one up. `Test` has to accept paths to test files, so a single task's tests can run alone. `Dev` starts the development server and prints the address it serves; `/po-qa` needs it and stops on `—`.

## Conventions

<< layout, stack, patterns, naming, commit style >>
