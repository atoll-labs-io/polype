# Stories review — <product>

Stories reviewed: `docs/stories.md`, against `<docs/prd.md | docs/brief.md>`, in a context that did not write them. Findings rated critical, major or minor.

Review status: <complete | blocked>

## When blocked
- Failure cause: <what failed, quoting what was found>
- Missing: <file, section or setting>
- Required adaptation: <what must change before retrying>
- Next action: <command or human action>

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| <core-loop line, angle, wedge or premise> | <## Core loop \| ## Angle \| ## Wedge & non-goals \| ## Premises> | <story ids, or none> | <yes \| no> |

## Checks
- [ ] Graveyard: no story revives a buried feature, under any name (PRD only)
- [ ] No technical layer dressed as a story; contract stories meet their conditions
- [ ] Every criterion can be checked by one test
- [ ] Dependency order: no dependency on a later or unknown id
- [ ] Complexity: no 5 left unsplit, every 4 names its risk
- [ ] Ids: `s<number>-<slug>`, unique, numbered in file order
- [ ] Owns: every story declares one; no path shared by two stories with no dependency between them

## Findings
<one per line: severity — story id — the problem>

## Not verified
<what this review did not check, why, and what a person should do instead>

Max severity: <critical | major | minor | none>
Stories ready: <yes | no>
