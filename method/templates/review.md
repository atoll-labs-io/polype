# Review — <id>

Diff reviewed: `git diff <Target branch>...story/<id>`, in a context that did not write it. Findings rated critical, major or minor.

Review status: <complete | blocked>
Fix loop: <0 for the first review, then 1, 2>
Reviewed tree: <40 hex — git rev-parse 'story/<id>^{tree}', taken before the review starts>

## When blocked
- Failure cause: <what failed, with the error>
- Missing: <evidence, file, setting or access>
- Required adaptation: <what must change before retrying>
- Next action: <command or human action>

## Ownership
Diff listed with `git diff --name-only <Target branch>...story/<id>`, each path held against the story's `Owns`.
- [ ] Every path inside `Owns`
- [ ] Outside `Owns` → major: <path — the `Owns` line it missed>
- [ ] Inside another running story's `Owns` → critical: <path — the story holding it and its worktree>
- [ ] No `Owns` line on this story → unverifiable scope, reported as such

## Evidence reused
- [ ] `po-gate verif-current <id>` → <passes, record reused | fails or missing → suite and type check run here, with results>

## Plan
- [ ] Each task present; nothing outside the plan
- [ ] Each run interdict checked, named one by one

## References
- [ ] Every import, call, API and configuration key opened and confirmed
- [ ] No value that only looks right

## Rules
- [ ] `AGENTS.md` conventions respected
- [ ] No accepted ADR contradicted

## Tests
- [ ] Assertions pin down the acceptance criteria; none of the six empty test shapes
- [ ] Within `Test budget`, or the excess is justified in the plan
- [ ] Bite: <rule disabled> → <N> failing tests → undone, `git diff --exit-code` clean
- [ ] Tests made useless by the story are removed, or keeping them is explained

## Neighbours
- [ ] Other callers of the changed code read; nothing broken

## Findings
<one per line: severity — file:line — the problem>

## Not verified
<what this review did not check, why, and what a person should do instead>

Max severity: <critical | major | minor | none>
Ship allowed: <yes | no>
