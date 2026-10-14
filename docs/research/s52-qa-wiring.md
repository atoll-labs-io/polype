# Research — s52-qa-wiring

[Story](../stories.md)

## Structuring facts
- **False assumption, blocks planning: `/po-qa` cannot commit anything.** The story says "/po-qa committe `docs/qa/<id>/` … comme /po-ship committe la revue" (`docs/stories.md:798`). But s51 built `/po-qa` without Bash on purpose (`method/commands/po-qa.md:4-8`, description `:2` "cannot edit files or run a shell, by construction"), and `tests/qa.test.sh:49` holds that clause (`lacks_tool "$PO_QA" Bash`). `tests/qa.test.sh` is **not** in s52's `Owns` (`docs/stories.md:791`), so the implementer's po-bounds hook refuses to write it (`method/hooks/po-bounds.sh:5`, Owns check). Giving `/po-qa` Bash also trips `bin/po-lint:142-146` while the description keeps "cannot … run a shell".
- The qa subagent cannot commit either: mode `qa` allows reading git verbs only (`method/hooks/po-bounds.sh:142-150`), `tests/bounds.test.sh:167` checks that `git commit` is refused, and `method/agents/qa.md:52` says "No commit". `po-bounds.sh` and `tests/bounds.test.sh` are outside `Owns` too.
- Everything else fits in `Owns`: a `qa-current` gate next to `verif_current` (`method/hooks/po-gate.sh:51-62`, dispatcher `:319-326`), the Law 1 table (`method/AGENTS.md:30-38`), Law 6 (`:93`), the reviewer's step 1 (`method/skills/review-antihallu/SKILL.md:24`), the review template (`method/templates/review.md:22-23`), and the implementer's browser line (`method/agents/implementer.md:37`).
- The QA `Tree:` is `git rev-parse 'story/<id>^{tree}'` (`method/templates/qa.md:28`, ADR-0026), so `code_matches` (`po-gate.sh:36`) compares it exactly as it compares `Reviewed tree:`.

## Story
Bind the QA report to the code, commit it with the story and make the review require it, so a story with a screen cannot ship without proof that its screens work. Criteria: `rules_list_qa_in_the_story_cycle`, `po_gate_qa_current`, `po_qa_commits_its_evidence`, `review_requires_a_current_qa_report`, `implementer_hands_the_screen_to_qa`. A story without a screen sees no difference (`docs/stories.md:800`).

## Current code
- `method/hooks/po-gate.sh` (326 lines). Subcommands `plan-validated`, `ship-allowed`, `verif-current`, `pre-commit`, `floor-guard` (`:319-326`); header usage block `:4-13`. `verif_current` (`:51-62`) refuses when the file is missing, when there is no exact `Verification status: complete` line, when there is no 40-hex `Tree:` (`first_hash`, `:31`), when the tree object is missing (`tree_exists`, `:33`), or when the code outside `docs/` differs from HEAD (`code_matches`, `:36`). Messages go through `refuse` (`:19`) and the subcommand exits 1.
- `method/commands/po-qa.md` (36 lines): Read/Glob/Grep/Agent only, preconditions read from files (`:21-26`), delegates to `qa` (`:29-33`), relays the answer and never writes a report (`:36`). It does not read `QA stage`: s51 kept it independent of that setting so a person can run it by hand (`docs/research/s51-qa-agent.md:54`).
- `method/agents/qa.md`: writes `docs/qa/<id>/report.md` (`:48`), takes `Tree:` before the walk (`:40`), stops when code outside `docs/` is uncommitted (`:28`), and does not commit (`:52`).
- `method/templates/qa.md`: the two last lines are `Tree:` and `QA status: <complete | blocked>` (`:28-29`); `tests/qa.test.sh:16-18` holds that order.
- `method/agents/reviewer.md`: reads `Target branch`, `Verification mode`, `Test budget`, `ADR directory` (`:13`); for a story with a screen it already reads the design system and the design folder (`:18`, `:22-23`); it writes no file (`:26`); a missing prerequisite gives a blocked report (`:29-35`).
- `method/skills/review-antihallu/SKILL.md`: the scope check, then step 1 "Reuse what is already proven", with `po-gate verif-current <id>` (`:24-28`). The list of pipeline evidence that is in scope by construction (`:18`) does not include `docs/qa/<id>/`.
- `method/templates/review.md`: `## Evidence reused` holds one box for `verif-current` (`:22-23`); `tests/ownership.test.sh:73-76` requires `## Ownership` to come before that heading.
- `method/AGENTS.md`: the per-story table has no QA row (`:30-38`). Law 3 lists three gates (`:58-64`, "checks all three"). Law 4 lists the uncommitted `docs/` work that is allowed and leaves out `docs/qa/<id>/` (`:79`). Law 6 says "A story is committed once by the implementer…" (`:93`).
- `method/agents/implementer.md:37`: "**If a task produces a screen, open it in a browser before you finish**".
- `method/templates/agents-local.md:21,49`: `QA stage` (`screens` · `—`), default `—`; `:72,75` `Dev`.

## Attachment points
- Gate: a new `qa_current` function placed after `verif_current`, a `qa-current)` line in the `case` (`po-gate.sh:319-326`), and a header line (`:4-13`). Report path: `docs/qa/<id>/report.md` (`qa.md:48`).
- Rules: a row between Execute and Review (`AGENTS.md:36-37`); possibly a Law 3 gate row (`:58-64`) and `docs/qa/<id>/` in Law 4 (`:79`) and Law 6 (`:90`, `:93`).
- Reviewer: `QA stage` added to its `Reads settings:` (`reviewer.md:13`); step 1 of the skill (`SKILL.md:24`); a box under `## Evidence reused` (`review.md:22-23`); `docs/qa/<id>/` added to the evidence list (`SKILL.md:18`).
- Implementer: the sentence at `implementer.md:37`, plus `docs/qa/<id>/` among the expected uncommitted files on a fix run (`:24`) if the evidence is not committed before then.
- Commit of the evidence: **no attachment point inside `Owns`** (see Structuring facts).

## Verified interfaces
- `first_hash <label> <file>` → the first `<label>: <40 hex>` (`po-gate.sh:31`); `tree_exists <hash>` (`:33`); `code_matches <tree>`, run as git diff `--quiet <tree> HEAD -- . ':(exclude)docs'` (`:36`); `top` (`:18`).
- Gate tests live in `tests/gate.test.sh`: `sandbox` (`:6-12`), `passes` (`:15`), `record` (`:84-88`). A `tests/qa-gate.test.sh` (in `Owns`) can follow the same shape, with `GATE="$METHOD/hooks/po-gate.sh"` as in `tests/gate.test.sh:4`.
- Helpers in `tests/lib.sh`: `contains` (exact, `:46`), `lacks_tool`/`needs_tool` (`:27-28`), `settings_read_by` (`:36-38`), `template_settings` (`:31-33`), `scratch_repo` (`:49-56`).
- `bin/po-lint:142-146`: a command whose frontmatter says "cannot edit files or run a shell" must not declare Write, Edit or Bash.

## Traps
- `tests/qa.test.sh:49` (`lacks_tool "$PO_QA" Bash`) and `:47` (the sentence "This command never writes a report") hold `/po-qa` as it stands. `tests/bounds.test.sh:167` holds the qa-mode commit refusal.
- `/po-review` has no Bash (`method/commands/po-review.md:4-9`, held by `tests/review.test.sh`): the gate has to run in the reviewer (`docs/stories.md:800`).
- `tests/ownership.test.sh:73-76`: a new box goes under `## Evidence reused`, never above `## Ownership`.
- `tests/fleet-wiring.test.sh:27-41`, `tests/structure.test.sh:48`, `tests/flow.test.sh:29`, `tests/resume.test.sh:22-23` and `tests/distribution-wiring.test.sh` quote Law 1, the flow section and the "Installed files" phrases: add text, do not reword those phrases.
- `QA stage: —` is the default (`agents-local.md:21`). If the reviewer required `qa-current` for every screen story whatever that setting says, every screen story of a project without QA would be blocked. The requirement has to depend on `QA stage: screens`.
- Committed evidence and `code_matches`: a docs-only commit after the walk leaves the gate green (`po-gate.sh:35-36`, like `tests/gate.test.sh:116`).
- Neighbouring lanes: s53 (reviewer, skill, review template), s54 (AGENTS.md), s56 (po-gate, implementer, AGENTS.md) and s57 all depend on s52 (`docs/stories.md:806,823,852,869`), so none can run at the same time as this lane.
- No migration. No new dependency. No API, screen or authorization change. The five full-track signals are absent; complexity alone picks the full track.

## Open questions
- **Who commits `docs/qa/<id>/`?** Settling this needs a change to the story, not a planner's choice. Options:
  1. Add `tests/qa.test.sh` to `Owns`. `/po-qa` gets Bash for one purpose only, the commit of `docs/qa/<id>/` alone after a `QA status:` report exists. Its description drops "run a shell" (because of `bin/po-lint:142`), and `tests/qa.test.sh:49` becomes `lacks_tool Write`/`Edit`. This keeps the story's wording ("comme /po-ship").
  2. Reword the criterion so that `/po-ship` commits `docs/qa/<id>/` together with the review (`method/commands/po-ship.md:25` already does this for the review). This needs `method/commands/po-ship.md` (and its test) in `Owns`. `/po-qa` stays without a shell, but the evidence stays uncommitted until ship, so `implementer.md:24` and Law 4 have to tolerate it on a fix run.
  3. A qa-mode exception for `git add/commit -- docs/qa/<id>` in po-bounds. Rejected here: it widens the hook ADR-0026 kept to a whitelist of reading verbs.
- Whether `qa-current` also needs a Law 3 row and should be counted in "checks all three" (`AGENTS.md:64`). It is not required by a criterion; the plan decides.

## Complexity
Story 3 → 3 once the owner of the commit is settled. The gate, the rules and the reviewer wiring are small, text-level changes; the commit is the one structural choice, and it calls for an ADR (ADR-0029 is reserved for this lane).

## Split
Not needed.
