# Review — Story <id>

> Fresh-context review of `git diff <Target branch>...story/<id>`. Every finding classified critical, major or minor.

Review status: <complete | blocked>

## If blocked
- Failure cause: <command, tool or state that failed, with its error>
- Missing: <evidence, file, setting or access>
- Required adaptation: <what must be provided before rerunning>
- Next action: <command or human gesture>

## Verification record
- [ ] `po-gate verif-current <id>`: <current, taken as proof | stale or missing → suite and type check run here, results>

## Plan
- [ ] Every task present, nothing the plan did not ask for
- [ ] Every run interdict checked, by name

## References
- [ ] Every import, call, API and configuration key opened and verified
- [ ] No plausible-but-wrong value

## Rules
- [ ] Conventions of `AGENTS.md` followed
- [ ] No accepted ADR contradicted

## Tests
- [ ] Assertions pin the acceptance criteria; no test that names a rule without exercising it
- [ ] Volume within `Test budget`, or justified by the plan
- [ ] Bite: <invariant neutralized> → <N> tests red → restored, `git diff --exit-code` clean
- [ ] Tests the story made redundant are removed, or keeping them is justified

## Regressions
- [ ] Other callers of the touched code opened; no impact

## Findings
<one line each: severity — file:line — what is wrong>

## Not verified
<what this review could not check and why; the gestures a human should make instead>

Max severity: <critical | major | minor | none>
Ship allowed: <yes | no>
