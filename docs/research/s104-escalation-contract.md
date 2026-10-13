# Research — s104-escalation-contract

## Structuring facts
- **Gap in the story: nothing on disk tells a plan waiting for a technical choice from a plan merely unvalidated.** The resume table routes every `validated: no` plan to "the plan" (`method/commands/po-drive.md:53`), and under `Plan validation: human` to the grouped question (`po-drive.md:115`). The row the story asks for needs a marker line in the plan, read like `Root cause: not found` is read in the research (`po-drive.md:52`, ADR-0070).
- **Today the planner and `/po-plan` settle structural choices alone**: "A structural choice ... is decided here, in the plan, with an ADR" (`method/agents/planner.md:135`) and "A structural choice with alternatives (library, pattern, data model) gets an ADR" (`method/commands/po-plan.md:45`). Both contradict ADR-0077 and are the clauses to rewrite.
- **The lead writes through Bash only, and a dirty root stops a local ship.** `/po-drive` has no Write/Edit (`po-drive.md:4-10`, `:18`); `/po-ship` under `Merge mode: local` stops when the root holds a modified tracked file (`method/commands/po-ship.md:79`). The log must be appended at the end of a wave, after its last ship, then landed.
- **The framing path the log must take exists**: `## Landing the framing` of `/po-setup` (`method/commands/po-setup.md:60-90`) — branch `framing/<slug>`, commit built beside the checkout, PR stacked on an open one, `human` stops at "Framing pull request ready".
- **`bin/po-lint` flags any command or agent body naming `AskUserQuestion` without declaring it** (`bin/po-lint:131-133`); `planner.md` declares no such tool (`planner.md:4`), so its new text must not name it.

## Story
s104: a written contract of what goes to the person and what the lead settles alone, plus a log of the lead's own decisions (ADR-0077). Criteria:
- `rules_list_the_three_escalation_motives` — `method/AGENTS.md` names incoherence (code, accepted ADR, story contradicting each other), a new idea outside the approved scope, and a strategic decision (vision, scope, recurring cost, security, personal data, hard to undo).
- `tech_choices_are_never_settled_alone` — any technical choice worth an ADR is discussed first; an implementation detail inside a validated plan stays with the lead; in doubt, it asks.
- `plan_with_a_tech_choice_waits_for_a_human` — such a plan never validates itself whatever `Plan validation`; `po-plan.md`, `po-flow.md`, `planner.md` say so; the lane escalates the choice with its options ranked, other lanes carry on; the resume table holds "plan waiting for a technical choice → a human".
- `human_stops_do_not_halt_the_fleet` — `/po-drive` and `/po-orchestrator` raise each stop "to a human" at once, one by one; the fleet carries on.
- `lead_logs_what_it_decides_alone` — each lone decision adds a dated line with its reason to `docs/decisions-log.md` per `templates/decisions-log.md`; committed on a branch and proposed as a PR after each wave through the s106 path; Law 6 lists it among framing files.
- `options_ranked_by_owner_criteria` — `capability-bricks` and `/po-architect` rank options first by: open source or self-hostable, frugal in hardware, scalable, easy for an AI to handle.

## Current code
- `method/AGENTS.md` (144 lines): `## The project lead` (`:63-67`) says the lead leads framing then runs `/po-drive`, answers first; nothing on what it escalates or logs. Law 6 framing list (`:104`) says the framing files "are committed on `Target branch`" — stale since s106 (they land through a PR) and lacks the log. Law 3 says "a story gets two fix loops, then a human decides" (`:80`).
- `method/commands/po-drive.md` (156 lines): resume table `:49-67`, first-match-wins (`:47`); root-cause row `:52`, plan row `:53`; "A lane that stops stays stopped and is reported; the other lanes of the wave carry on." (`:106`); `## Validating a wave's plans` `:110-125` (autonomous `:113`, grouped AskUserQuestion `:115`); report and `status` reasons `:145-156` (human reasons listed `:154`). Nothing is logged anywhere.
- `method/commands/po-orchestrator.md` (81 lines): stage 4 validates per `Plan validation` (`:51-54`); stops for a human at `:46`, `:65`, `:74`, `:76`; "Where a human must decide, you call AskUserQuestion" (`:19`).
- `method/commands/po-plan.md` (55 lines): `**A plan file already present?** Skip to "Approval"` (`:30`); structural choice bullet `:45`; approval `:49-51`.
- `method/commands/po-flow.md` (92 lines): escalation signals `:36-51` (a new dependency already escalates, `:42`); approval `:68-73`.
- `method/agents/planner.md` (58 lines): signal list `:114`; validation `:127-131`; ADR limit `:134-135`.
- `method/commands/po-architect.md` (74 lines): step 3 reads `capability-bricks` and drafts one ADR per choice (`:40-48`); each ADR put to the person one question at a time with "the options turned down" (`:64-65`).
- `method/skills/capability-bricks/SKILL.md` (49 lines): "Each default is picked self-hostable first" (`:6`), sections `## Default bricks`, `## Two editions`, `## Contract tests`; no ranking rule.
- `method/templates/decisions-log.md`: absent. `docs/decisions-log.md`: absent in this repository.

## Attachment points
- `method/AGENTS.md`: a new section right after `## The project lead` (`:67`), and the Law 6 framing bullet (`:104`).
- `po-drive.md`: a resume row between `:52` and `:53`; the sentence at `:106`; `## Validating a wave's plans`; a log step closing a wave (new `### The decisions log` under `## A wave`, or after `## Ships, one at a time`); `## Report` and `status` reasons (`:146`, `:154`).
- `po-orchestrator.md`: stage 4 (`:51-54`) and a sentence on stops for a human.
- `po-plan.md`: `:30`, `:45`, `## Approval`.
- `po-flow.md`: `## Escalation signals` list and `## Approval`.
- `planner.md`: signal list `:114`, `## Validation`, `## Limits` `:135`.
- `po-architect.md`: step 3 (`:41`) and approval summary (`:65`).
- `capability-bricks/SKILL.md`: a new `## Ranking the options` section.
- New `method/templates/decisions-log.md` (installed to `.polype/templates/` with all templates, `bin/polype:98-101`).

## Verified interfaces
- Landing a framing commit: `<slug>`, `<paths>`, `<message>` named by the caller; `pr` pushes `framing/<slug>` with `--force-with-lease`, reuses an open PR; effective `human` → stops with "Framing pull request ready: <url>…"; `automatic` → merge `--rebase --match-head-commit`, proof `MERGED`, root `--ff-only`, branch deleted; `local` → `update-ref`, `human` asks Merge / Not now, then `--ff-only` (`po-setup.md:61-88`).
- `po-gate plan-validated` reads only the frontmatter `validated: yes` (Law 3, `AGENTS.md:73`): a marker in the body changes no gate.
- ADR template status values: `proposed | accepted | superseded` (`method/templates/adr.md:4`).
- `po-drive.md` already reads `Target branch`, `Merge mode`, `Ship confirmation` (`:14`), all the landing needs.
- Fleet ADR numbers: one reserved per lane (`po-drive.md:92`).

## Traps
- **Frozen phrases to keep** (additive changes only): `tests/plan.test.sh:22-23` (`Write \`validated: yes\` into the frontmatter on Approve and on nothing else.`, `state that no human reviewed it`); `tests/planner.test.sh` (`` `validated: no` ``, `the ADR that number names — and no other file. No source file, no test file, no commit`, the two `lines at most` caps); `tests/flow.test.sh` (signal list and ordering in `## Escalation signals`, `validated: yes` in `## Nothing is relaxed`); `tests/grouped-validation.test.sh:19-46` (the whole approval section wording); `tests/defect-and-routing-paths.test.sh:39-46` (exactly one resume row holding `Root cause: not found`, before the plan row); `tests/drive.test.sh:186-215` (every resume row names a stage; plan row keeps "the lane keeps that file and never writes it again"); `tests/ship-follows-forge.test.sh:94-102`; `tests/capability-bricks.test.sh` (tables parsed by `## ` section — a new section must not sit inside them); `tests/distribution-wiring.test.sh:34` (`committed on \`Target branch\`` — also present at `AGENTS.md:135`, so Law 6 may change).
- `bin/po-lint` fail-closed rule (`bin/po-lint:160-180`): inside `## Checks*` sections, an arrow after "no/not/missing" must say stop/ask/carry on.
- `bin/po-lint` settings rule: every `Reads settings:` name must exist in the template; no new setting is needed.
- `tests/overlap.test.sh`: new text in own words.
- `.claude/`, `.polype/` and the root `AGENTS.md` are installed copies: never edited by this story.
- A tech choice on the short track: `po-flow.md` writes only the worktree and the plan (`:19`), no ADR file; routing the choice to the full track keeps that true.
- `/po-drive status` writes nothing (`:146`): the log must not be written by it.
- No migration, no dependency, no screen.

## Open questions
- Exact marker text — the plan settles `Technical choice: waiting for a human`, alone on its line, by analogy with ADR-0070.
- After the person decides, who rewrites the plan and accepts the ADR? The plan settles: `/po-plan <id>` (it holds AskUserQuestion and Write) puts the choice, records it, removes the marker.
- Which lone decisions `/po-drive` logs: the plan settles a closed list (stories launched and held back, fix runs started, re-reviews, plans approved without a human, lanes handed to a human).
- `po-session.sh` (s103) lists pending escalations but not the new tech-choice wait; `method/hooks/` is outside this story's `Owns` — reported, not handled.

## Complexity
3 → 3. Eight method files and one template, all prose; the only real design is the marker and the moment the log is written.

## Split
—
