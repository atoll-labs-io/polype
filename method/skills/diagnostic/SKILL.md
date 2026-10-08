---
name: diagnostic
description: How to research a story that fixes a defect — reproduce it, find and prove the root cause, and only then plan the fix. Applied to a story carrying a `Fixes` line by the planner, `/po-research` and `/po-orchestrator`.
---
# Diagnostic

A fix planned on a guess is a second defect. This skill orders the research of a defect story so that the plan starts from a cause that was shown, not from a symptom.

## When
A story carrying a `Fixes` line (`Corrige` in a French stories file). It always takes the full track, and this skill runs during the research, before any plan exists.

## Reproduce
Run the defect on the code as it stands, with the inputs the defect names: a command, an existing test, a request. Write down what was run and what it showed. Create no file in the worktree to do it, since the research stage writes nothing but its research, its plan and a reserved ADR; a reproduction that needs a new test becomes a task of the plan, and the research says the defect was not reproduced and why. A defect that does not reproduce is a finding to report, not a reason to fix blind.

## Hypotheses
Take them one at a time. For each, write the observation that would refute it, then record it as kept or discarded with the evidence. A hypothesis nobody tried to refute is not recorded as kept.

## Root cause
Write it first in `## Structuring facts` of the research: the `path:line` at fault, the input that reaches it, and the proof, meaning the output, trace or line read that ties the symptom to that place. A symptom is not a cause. A `## Diagnostic` section of the research carries the reproduction and the hypotheses.

## Only then, the plan
The fix task targets the cause. Another task adds the test that would have caught the defect: it fails on the code before the fix, which is proven by the reviewer's bite check (ADR-0012), not by running it red during implementation.

## Three hypotheses, then stop
**After three discarded hypotheses, stop.** Write the research with the three and what refuted each, write no plan, and report that no root cause was found. No guessed fix, no defensive patch around the symptom. The research then opens its `## Structuring facts` with this exact line, alone on its line: `Root cause: not found`. That line hands the story to a human: no command and no agent builds a plan on a research that carries it. Once someone finds the cause, they rewrite the research without the line, and the story resumes at its plan (ADR-0070).
