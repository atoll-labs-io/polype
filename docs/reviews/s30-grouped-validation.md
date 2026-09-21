# Review — s30-grouped-validation

Diff reviewed: `git diff m3-flotte...story/s30-grouped-validation`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s30-grouped-validation` → passes (exit 0); `git diff --quiet 4523f2c HEAD -- . ':(exclude)docs'` also clean, so the record's `Tree:` names the committed code. `Verification mode: record`, so the unit suite (157 passed) and `bin/po-lint method` are taken from `/home/lecrabe/dev/atoll/polype/.claude/worktrees/m1-cycle/.worktrees/s30-grouped-validation/docs/verif/s30-grouped-validation.md` as proven. I re-ran both anyway because they cost seconds here (`bash tests/run.sh` → 157 passed / 0 failed; `bin/po-lint method` → no breach); results agree with the record.
- Its "Not proven here" section is honest: `Typecheck`, `E2E`, `Build` are all `—` in `AGENTS.local.md` — the project has none, and I substituted nothing.

## Plan
- [x] Task 1 — `docs/decisions/ADR-0017-validation-groupee.md` written in French, `status: accepted`, `date: 2026-09-21`, `supersedes: [ADR-0014]`, three options with the two rejected ones named. Present.
- [x] Task 2 — ADR-0014 frontmatter only: `status: superseded`, `superseded-by: [ADR-0017]`. The diff on that file is exactly 4 changed lines (2 removed, 2 added); the body is untouched, matching the ADR-0013 precedent.
- [x] Task 3 — `## Validating a wave's plans` sits at line 79, after `## A wave` (60) and before `## The verdict, and the fix runs` (96), and contains zero `subagent_type:` strings, so the `tests/drive.test.sh:45-47` trap the plan identified is respected.
- [x] Task 4 — dispatch step 1 keeps `subagent_type: planner` and now points at the new section.
- [x] Task 5 — `## Report` gained the autonomous / human approval sentence.
- [x] Task 6 — `tests/grouped-validation.test.sh`, three functions named exactly after the three acceptance criteria of `docs/stories.md:457-459`.
- [x] Nothing outside the plan: the diff is the six files the plan listed, no more.
- [x] Run interdicts, one by one, each checked with `git diff --quiet m3-flotte...story/s30-grouped-validation -- <path>`: `docs/parite-killer-saas.md`, `docs/stories.md`, `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `.claude/`, `.polype/`, `method/templates/agents-local.md`, `tests/drive.test.sh`, `tests/resume.test.sh` — all empty. ADR-0014's body: untouched. No worktree/switch/checkout/stash trace (`git worktree list` shows only the three expected entries).

## References
- [x] `po-gate plan-validated <id>` exists (`.polype/hooks/po-gate.sh:63`, `method/hooks/po-gate.sh:63`) and means what the new prose says.
- [x] The autonomous claim matches the contract it cites: `method/agents/planner.md` ("`autonomous` — check the plan yourself …, write `validated: yes` …, and say in your answer that no human reviewed it") and `method/commands/po-plan.md:47-48`.
- [x] `method/commands/po-execute.md`, `method/commands/po-review.md`, ADR-0015 and the `Plan validation` setting all exist; `AskUserQuestion` is declared in the frontmatter (`method/commands/po-drive.md:10`) and `Plan validation` in the `Reads settings:` line (line 14), which is why `bin/po-lint` stays silent.
- [x] `## Report`'s new sentence says "The plan column says who approved it" and that table does have a `plan` column.
- [x] ADR-0017 is the next free number (0016 is the last one on disk); its frontmatter uses `deciders`/`tags` like every other ADR here rather than the `scope:` of `templates/adr.md` — that is the repository's real convention, not a defect.

## Rules
- [x] `AGENTS.md` conventions: method prose in English, ADR in French, one test file per story, commit message in English with no trailer.
- [x] No accepted ADR contradicted — the story's whole point is ADR-0014, and ADR-0016 (driver with no Write/Edit) is honoured: `validated: yes` goes through Bash, as the section states explicitly.
- [x] ADR-0012 respected: the implementer did no red-first; the bite proof below is mine, in a fresh context.

## Tests
- [x] Three tests, one per acceptance criterion, well inside `Test budget: 25`. None of the six empty shapes applies: they read the committed files through `section_of`/`frontmatter` and assert exact phrases; no mock, no fixture, no swallowed error.
- [x] Bite — eight mutations, each followed by `bash tests/run.sh grouped-validation.test.sh` (only the file that exercises the rule), each undone and confirmed with `git diff --exit-code`:
    - `**one AskUserQuestion**, never one per story` → `one AskUserQuestion per story` → **1 failing test**
    - "`validated: yes` … of the plans the answer approved **and of no other**" weakened to "the wave's plans" → **1 failing**
    - `## Report` paragraph deleted → **1 failing**
    - dispatch pointer in `## A wave` deleted → **1 failing**
    - "A plan left unapproved keeps `validated: no`" reworded → **1 failing**
    - ADR-0014 `status: superseded` → `accepted` → **1 failing**
    - ADR-0017 `supersedes: [ADR-0014]` → `[]` → **1 failing**
    - "Le ship reste story par story" reworded → **1 failing**
- [x] Every rule the story depends on is covered. Final state: `git status --porcelain` empty, `git diff --exit-code` clean — no mutation left behind.
- [x] No existing test removed or weakened; `tests/drive.test.sh` and `tests/resume.test.sh` have an empty diff and stay green.

## Neighbours
- [x] Other readers of the changed prose: `## Resuming`, `## The ready set`, `## Ships, one at a time` in the same file — the new section does not contradict them (see the minor finding on re-offering a plan).
- [x] Other holders of the grouped-approval rule: `method/commands/po-plan.md:47`, `po-flow.md:65`, `po-orchestrator.md:51` are the single-story form and are untouched, as they should be.
- [x] Every file citing ADR-0014 was opened: `docs/parite-killer-saas.md:115` (deferred to s31 on purpose), `docs/conception.md:109` (finding below), `docs/decisions/ADR-0015-…:27`, plus historical evidence files (`docs/research/s16-architect.md`, `docs/reviews/s24-…`, `docs/validation/m1.md`) which record past states and must not be rewritten.
- [x] No other story branch is in flight (`git branch --no-merged m3-flotte` lists only this one), so no path in this diff belongs to a concurrently running lane.

## Findings
- **major** — `docs/decisions/ADR-0014-checkpoints-groupes.md` (frontmatter) — outside the story's `Owns`. `docs/stories.md:453` lists `method/commands/po-drive.md`, `docs/decisions/ADR-0017-validation-groupee.md`, `tests/grouped-validation.test.sh`, and nothing else; `method/skills/review-antihallu/SKILL.md:13` rates a path outside `Owns` major. The plan argues the case openly (`docs/plans/s30-grouped-validation.md:26`) and the alternative — two live, contradicting ADRs — is worse, so the right resolution is to widen the `Owns` line of s30 in `docs/stories.md` on purpose, not to revert the two frontmatter lines. No concurrent lane owns that path, so this is major and not critical.
- **major** — `docs/conception.md:109` — the project's ADR index still presents ADR-0014 as the live decision ("validation des plans groupée par vague en flotte (le volet « ship au milestone » tombe avec ADR-0015)") and never mentions ADR-0017. Line 108 of the same list shows the convention for a replaced ADR: `~~ADR-0013~~ — remplacée par ADR-0015.` This story exists to end exactly that kind of contradiction, and it leaves one standing in the design document. Worse, `docs/conception.md` appears in no story's `Owns` (s31 takes `AGENTS.md`, `po-help`, `po-status` and the parity matrix, not this file), so no later story will pick it up — unlike `docs/parite-killer-saas.md:115`, which s31 does own and the plan deferred knowingly. A person should strike the ADR-0014 line the way ADR-0013 was struck and add an ADR-0017 line, as a quick fix or as an extra `Owns` path on s31.
- **minor** — `method/commands/po-drive.md:88` — "Choose which ones — only the plans the answer names are approved" does not settle how the choice is collected inside a single `AskUserQuestion` (multi-select, or a free answer listing ids). The same looseness exists in `method/commands/po-architect.md:62`, so it matches the house style, but a driver reading this could ask a second question and quietly break "never one per story".
- **minor** — `method/commands/po-drive.md:92` — an unapproved plan "waits for the next wave, where the plan is offered again", and there is no `Change` answer (the single-story form has one: `po-plan.md:47`, `po-flow.md:65`). A human who wants a plan revised can only refuse it and be offered the identical plan next wave. Worth a clause, in a later story, on how a refusal reaches the planner.
- **minor** — `method/commands/po-drive.md:92` — the section says "the next run resumes at the plan with nothing to redo", while the `## Resuming` table (line 46) sends "plan absent or without `validated: yes`" back to "the same stage, at the plan", which is the row that dispatches `planner`. The rule "A stage already recorded is resumed, never replayed" (line 58) resolves it in favour of re-offering the existing plan, but the new section would be safer saying outright that no `planner` is dispatched for a lane whose plan already exists.

## Not verified
- **No behaviour was executed.** This diff is prose read by an agent plus two ADRs; there is no program to run, no screen to open, no third party involved. That a driver actually asks one grouped question, writes `validated: yes` into only the named plans and dispatches no implementer for the rest can only be seen by running `/po-drive` with `Plan validation: human` on a wave of at least two stories. A person should do that once, on a real wave, before trusting the human mode — this review proves the rule is written and pinned by a test, not that a model obeys it.
- **The test layer can only catch deletion or rewording of the phrases it quotes.** A contradicting sentence added elsewhere in `po-drive.md` — for instance one permitting a per-story question — would leave all three tests green. That is inherent to testing prose by quotation, the only layer this repository has; a reader, not the suite, is the guard there.
- **Type check, end-to-end run and production build did not happen**: `Typecheck`, `E2E`, `E2E stage`, `Build` and `Build stage` are all `—` in `AGENTS.local.md`. The project has none and I substituted nothing.
- **The ADR text was read, not validated by anyone with authority.** ADR-0017 declares `deciders: [lecrabe]`; that ADR-0014 is genuinely dead and that per-story shipping is what the user wants is a human call, and the accepted status here was written by an agent. If that is not the user's intent, the ADR needs a human `accepted` before s31 builds on it.

Max severity: major
Ship allowed: yes
