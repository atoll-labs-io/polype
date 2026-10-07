# QA — <id>

Scope: the screens `git diff <Target branch>...story/<id>` touches and the story's acceptance criteria a person can see on a screen; nothing else was walked.
Browser tool: <the tool of the session that opened the pages and took the captures>
Origin: <the address `Dev` printed when it started, the only one visited>

## Coverage
| Screen or criterion | Reached | Result |
| --- | --- | --- |
| <route, page or criterion name> | <yes | no> | <as expected | finding N | not reached — reason> |

## Findings
Status rule: **verified** means the steps were replayed and reproduced the defect, and a capture file holds it; **probable** means it was seen once, or no capture file could be kept; **unverified** means it is suspected from what the page showed, not seen happening.

### Finding <N> — <short title>
Severity: <critical | major | minor>
Status: <verified | probable | unverified>
Steps to reproduce:
1. <first action, from the origin>
2. <next action>
Capture: <docs/qa/<id>/<file> | none — reason>
Expected: <what the story or the design says should happen>
Observed: <what the page did>

## Not seen
- <screen or criterion> — <why: behind a sign-in, no visible effect, the page could not reach that state, the walk stopped>

Tree: <40 hex — git rev-parse 'story/<id>^{tree}', taken before the walk>
QA status: <complete | blocked>
