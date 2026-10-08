---
validated: no
---
# Plan — <id>

Branch `story/<id>`. Read `docs/research/<id>.md` first; this plan builds on it without repeating it.

## Story
<restatement and acceptance criteria>

## Tasks
1. [ ] <task — and the test able to fail for it, or for a purely visual task the visual check>
2. [ ] <task>

## Scene viewpoints
<Only for a story whose `Surface` is `scene`; write `—` for any other. One line per viewpoint to capture: where it looks from, what it must show, and its framing, scale and light. The QA captures these viewpoints and the review judges the scene against them.>

## Run interdicts
<One line each: files that must end with an empty diff, commands not to run, nearby work that is out of scope. Only write what a reviewer can verify.>

## The pivot
<The decision this plan rests on and the two or three ways it could be wrong, each with what to compare it against. It tells the reviewer where to start looking, not where to stop.>

## Files touched
<expected list>

## Test strategy
<Which test at which layer, following the testing-doctrine skill, within `Test budget`. Automated tests and visual checks in separate lists.>

## Done when
<the repository's definition of done, applied to this story>
