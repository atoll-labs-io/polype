---
track: flow
validated: no
---
# Plan (short track) — <id>

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/<id>.md`. Keep it to about 150 lines at most.

## Verified facts
<What the code actually does around this story, each fact opened in the code and given with its `path:line`. Any assumption of the story that proved wrong comes first. The implementer and the reviewer read this section in place of a research file.>

## Escalation signals
<Each of the five, marked `absent`, with where it was checked — once on the story text before reading the code, once after reading it. Any signal present means this file should not exist: the story belongs to the full track.>

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — <where checked> | absent — <where checked> |
| New screen | absent — <where checked> | absent — <where checked> |
| Authorization or tenant scope | absent — <where checked> | absent — <where checked> |
| API contract | absent — <where checked> | absent — <where checked> |
| New dependency | absent — <where checked> | absent — <where checked> |

## Story
<restatement and acceptance criteria>

## Tasks
<Six at most; more means the story leaves the short track.>

1. [ ] <task — and the test able to fail for it>
2. [ ] <task>

## Run interdicts
<One line each: files that must end with an empty diff, commands not to run, nearby work out of scope. Only what a reviewer can verify.>

## Files touched
<expected list>

## Test strategy
<Which test at which layer, following the testing-doctrine skill, within `Test budget`.>

## Done when
<the repository's definition of done, applied to this story>
