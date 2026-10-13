# Research — s111-tech-choice-backstop

## Structuring facts
- Root cause 1 (s104 major 1): `method/commands/po-flow.md:74`. When the Approval clause finds an ADR-worthy choice, it sends the story to `/po-research <id>`. It leaves `docs/plans/<id>.md` on disk with no marker (the `MARKER` string of `tests/escalation-contract.test.sh:14`) and no drafted ADR. `/po-plan` then sees "A plan file already present? Skip to Approval" (`po-plan.md:30`). Its marker paragraph (`po-plan.md:50`) only fires on the marker, so under `autonomous` the bullet at `:53` validates the plan.
- Root cause 2 (s104 major 2): `tests/escalation-contract.test.sh:47-50` checks the marker and `status: proposed` with `contains` on the whole of `po-plan.md`. The bullet at `po-plan.md:45` satisfies both checks, and `:46` also finds `whatever \`Plan validation\` says` there. So deleting the Approval paragraph at `:50` fails nothing.
- Root cause 3 (s101 major): `tests/conversational-framing.test.sh:53-64` (`test_stories_review_surfaces_criticals_only`) quotes neither rule. One is "never changed: a verdict is the subagent's" (`po-stories-review.md:49`). The other is "has already started" (`po-stories.md:53`).
- No story assumption is false. The criterion "/po-plan finds the line and asks with those options" already holds once the marker is in the plan (`po-plan.md:30`, `:50`), so `po-plan.md` needs no edit.
- `po-flow.md` does not read `ADR directory` (`po-flow.md:15`). Drafting an ADR there requires adding it, because the lint checks the `Reads settings:` names (`bin/po-lint:98-112`).

## Diagnostic
Reproduction. Each mutation was made on a scratch copy of `method/`, `tests/` and `bin/` in `mktemp -d`, never in the worktree:
- Deleted the `po-plan.md:50` paragraph, then ran `bash tests/run.sh escalation-contract.test.sh plan.test.sh`: **12 passed, 0 failed**. Defect 2 reproduced.
- Deleted the "`Max severity:` … never changed: a verdict is the subagent's, not the owner's." sentence from `po-stories-review.md:49`, then ran `conversational-framing`, `stories-review` and `stories`: **0 failed**.
- Deleted only the refusal clause of `po-stories.md:53`, keeping "Each story keeps its id.", then ran the same three files: **18 passed, 0 failed**. Defect 3 reproduced.
  - Deleting the whole line 53 does fail one test, but only through "keeps its id", which shares that line.
- `grep -n 'Technical choice' method/commands/po-flow.md` finds nothing. Defect 1 confirmed by reading: no path in `po-flow.md` writes the marker.

Hypotheses for defect 1:
1. *`/po-research` clears or rewrites an existing plan.* It would be refuted if po-research said nothing about plans. `po-research.md:17` says its output is "a worktree and one file, `docs/research/<id>.md`", and plans are named nowhere. **Discarded.**
2. *`/po-plan` Approval looks for a tech choice even without the marker.* It would be refuted if the Approval check were conditional on the marker. `po-plan.md:50` opens with "A plan holding the line …", and the autonomous bullet `:53` only checks the plan against the criteria. **Discarded.**
3. *`/po-orchestrator` stage 4 catches it.* It would be refuted if stage 4 also depended on the marker. `po-orchestrator.md:54` says "A plan holding the line … first has its choice put to the person", otherwise autonomous validation. **Discarded.**

The flow clause leaving an unmarked plan is the cause (kept: `po-flow.md:74` is the only writer on that path, and it writes nothing).

## Story
A short-track plan sent back over a technical choice keeps the marker line and the ranked options, so `/po-plan` always asks, even under `Plan validation: autonomous`. The story has three criteria:
- `flow_plan_sent_back_keeps_the_marker`: the flow Approval clause does three things before pointing to `/po-research`:
  - writes the marker into the plan already on disk;
  - leaves `validated: no`;
  - drafts the ADR with `status: proposed`, its options ranked by the owner's criteria.

  `/po-plan` then skips to Approval, finds the line and asks with those options.
- `approval_test_bites_in_its_section`: `test_plan_with_a_tech_choice_waits_for_a_human` checks the line and its rule inside the Approval section of `po-plan.md`.
- `stories_review_rules_bite`: `test_stories_review_surfaces_criticals_only` fails if either rule disappears.

## Current code
- `po-flow.md:69-76` `## Approval`: the `human` and `autonomous` bullets come at `:70-72`, followed by the tech-choice clause at `:74`, which comes *after* the bullets. It contains `whatever \`Plan validation\` says`, which `escalation-contract.test.sh:46` requires in `$FLOW`.
- `po-flow.md:46-48`: the second signal check fires first in normal runs ("write no plan"). The `:74` clause is only a backstop.
- `po-plan.md:30` (inside `## Checks first`) skips to Approval when a plan exists and names the marker. `:45` drafts the ADR (`templates/adr.md`, `status: proposed`, `## Ranking the options` of `capability-bricks`, ADR named in the plan). `:50` (inside `## Approval — per \`Plan validation\``) asks with the ADR's options in ranked order, accepts or rewrites the ADR, and removes the marker.
- `po-orchestrator.md:45`: when `/po-flow` escalates, the story continues at stage 2. Stage 4 (`:54`) writes the plan only "if it does not exist" and reads the marker. A marked flow plan is therefore handled there too, with no edit.

## Attachment points
- `method/commands/po-flow.md` `## Approval` (`:69-76`) and the `Reads settings:` line (`:15`).
- `tests/escalation-contract.test.sh` `test_plan_with_a_tech_choice_waits_for_a_human` (`:44-67`). Its `section_of` helper is at `:18` and `holds` at `:19`.
- `tests/conversational-framing.test.sh` `test_stories_review_surfaces_criticals_only` (`:53-64`).
- New `tests/tech-choice-backstop.test.sh`, the story's own test file under the convention (`AGENTS.local.md`).

## Verified interfaces
- Exact headings:
  - `## Approval` (`po-flow.md:69`)
  - `## Approval — per \`Plan validation\`` (`po-plan.md:49`)
  - `## Checks first` (`po-plan.md:22`)
  - `## Writing the plan` (`po-plan.md:37`)
- `section_of() { awk -v h="## $2" '$0 == h …' }` matches a heading exactly. `escalation-contract.test.sh:18` and `conversational-framing.test.sh:12` each define it locally.
- `tests/lib.sh`: `ROOT` comes from the lib's own location (`:5`), and `METHOD="$ROOT/method"` (`:6`). `contains` (`:43`), `require_file` (`:41`), `settings_read_by` (`:37`). Test files read `$METHOD` when they are sourced (`escalation-contract.test.sh:4-12`), so a test file sourced again in a subshell with `METHOD=<copy>` runs against a mutant. `tests/lint.test.sh:6-16` (`mutant()`, `mktemp -d` and `trap`) is the existing pattern for this.
- `tests/run.sh:17` runs each test with `set -eu` in its own `bash -c`.
- Exact phrases quoted later:
  - "never changed: a verdict is the subagent's" (`po-stories-review.md:49`)
  - "has already started" (`po-stories.md:53`, same line as "Each story keeps its id.")
- Numbering: `po-architect.md:48` and `po-brief.md:58` use "the next free number in `<ADR directory>`". `po-drive.md:97` reserves numbers for planner lanes, and `/po-drive` does not run `/po-flow` (`grep flow po-drive.md` finds nothing).

## Traps
- `escalation-contract.test.sh:46` needs `whatever \`Plan validation\` says` somewhere in `po-flow.md`. The rewritten clause must keep the phrase.
- `tests/overlap.test.sh` fails on 8+ consecutive words shared with Killer SaaS, so new prose must be written fresh.
- `adr-directory.test.sh:4-7` lists the ADR readers. `po-flow.md` is not in the list and the file is outside `Owns`, so the new test checks `po-flow` reads the setting. `po-flow.md` must never name `docs/decisions/`.
- `method/templates/plan-flow.md:13` says "Any signal present means this file should not exist". The backstop keeps the file on purpose. `plan-flow.md` is outside `Owns` (s113 owns it next), so the wording stays as it is and the new clause says the file is kept.
- The `plan-flow.md:15-22` signal table has no technical-choice row, though `po-flow.md:43` lists that signal. This gap is outside `Owns` and only noted here.
- The baseline is green: `escalation-contract`, `conversational-framing`, `flow`, `plan`, `adr-directory` and `lint` gave 30 passed, 0 failed on this worktree.
- No migration and no new dependency.

## Open questions
- If a person runs `/po-flow` by hand while `/po-drive` lanes hold reserved numbers, "next free number" can collide with a reserved one. This is rare, and `/po-plan` has the same exposure (`:45` names no number). It is not settled here.

## Complexity
2, the same as the story: one prose clause, two test edits, one new test file of three tests.

## Split
Not needed.
