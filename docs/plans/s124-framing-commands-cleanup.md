---
validated: yes
---
# Plan — s124-framing-commands-cleanup

Branch `story/s124-framing-commands-cleanup`. Read `docs/research/s124-framing-commands-cleanup.md` first; this plan builds on it without repeating it. Full track: the story carries a `Corrige` line.

## Story
Close the eleven `HOLDS` rows of `docs/reviews/triage-2026-10-14.md` that point into this story's `Owns` (rows 112-115, 119, 141, 143, 160, 161, 164, 177), so the framing commands follow one path and their rules are held by tests. Criteria `stories_paths_agree`, `setup_landing_holds`, `framing_wording_is_clean`, as in `docs/stories.md:1931-1934`.

## Reuse
The only new code is one bash test file; the method edits are prose.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `tests/framing-commands-cleanup.test.sh` | already in this repository: `contains`, `fail`, `require_file` (`tests/lib.sh`) and the `section_of`/`holds`/`offset` idiom copied from `tests/framing-second-landing.test.sh:6-15` | — (first rung holds; each test file defines its own `section_of`, as all framing tests do) |
| order check in `test_root_realigns_after_a_merge` | already in this repository: its own `offset` helper (`tests/framing-second-landing.test.sh:15`) | — |

## Tasks
1. [x] **`/po-stories` fix path** (`method/commands/po-stories.md:51-56`).
   - After the "A rewritten story goes through…" bullet (`:54`), add a bullet: a story set aside leaves the file, and "Before writing" runs again on the stories that remain, since a dependency or an `Owns` overlap may now be broken; a remaining story that now fails is put to the user through the one-story question of step 5 with its fix, and written in place once approved — unless it has already started, in which case stop and say so, as above.
   - Adjust `:52` "those stories and no other" so it also admits the stories a removal breaks (the next bullet), and `:55` likewise.
   - Rewrite `:56` so the fix path commits as "Finish" says but ends with its own line: `"Stories fixed. Next: /po-stories-review"`, never the Finish line of `:62`.
   - Keep verbatim: "Each story keeps its id.", the sentence "A story with a `story/<id>` branch … it is not reopened here." (mutated by `tests/tech-choice-backstop.test.sh:57-74`), `sent back by \`/po-stories-review\``.
   - Test that fails if wrong: `test_stories_paths_agree` (task 7).
2. [x] **`/po-stories-review` Outcome** (`method/commands/po-stories-review.md:56-59`). Put the blocked bullet first and make it exclusive: a review whose `Review status:` is `blocked` → list what it says is missing, then "Run /po-stories-review again once that is fixed."; it also ends on `Stories ready: no`, and only this bullet applies to it. The two `Stories ready:` bullets then apply to a complete review only (say "a complete review"). Do not touch `## Critical findings` (`:42-51`): its "never changed: a verdict is the subagent's, not the owner's." sentence is a mutation anchor. Test: `test_stories_paths_agree`.
3. [x] **PRD template** (`method/templates/prd.md:9`). Replace the status sentence: `status` stays `draft` until every section has been approved on its own question; `/po-prd` then sets it to `approved` at its commit, and never asks for the document to be read again. The phrase "read the whole" must disappear. Test: `test_stories_paths_agree`.
4. [x] **`/po-setup` forge timing** (`method/commands/po-setup.md:27`, `:40`).
   - Step 1 bullet: Step 1 notes only which forge `origin` names; the rest — whether it could be read and, if not, why, and whether the repository is collaborative — is read exactly as `/po-ship` reads it (`## The forge's review rule` of `method/commands/po-ship.md`, keep this literal) once question 1 of Step 2 has given `Target branch`, since the `CODEOWNERS` and protection signals read that branch.
   - `:40`: "Then `Ship confirmation`, from that reading of the forge, made once `Target branch` is known." Keep "AskUserQuestion call for `Ship confirmation`" unnumbered and "`automatic (chosen)` (suggested) and `human (chosen)`" verbatim (`tests/ship-follows-forge.test.sh:20-25`). Do not move the Platform follow-up (`tests/platform-setting.test.sh:75-79`).
   - Test: `test_setup_landing_holds`.
5. [x] **`/po-setup` landing** (`method/commands/po-setup.md:56`, `:61`, `:71`, `:95`) and **`/po-architect`** (`method/commands/po-architect.md:72`).
   - `:95` `local`: keep `git merge --ff-only framing/<slug>`; a refusal → stop: `framing/<slug>` stays in place and is not deleted, nothing forces the merge (no stash, checkout, reset or rebase), and the report names the branch and git's reason, so a person brings it level with `Target branch` before the next landing. Only after a merge that went through: `git branch -d framing/<slug>`. "Nothing is pushed." stays. Do not write "commit … on `Target branch`" in one sentence (`tests/framing-through-pr.test.sh:41`).
   - `:71`: "→ stop: Ancestry is never the proof" → "→ stop: ancestry is never the proof".
   - `:56` and `po-architect.md:72`: "Never commit a `CLAUDE.md`." → "Never commit a `CLAUDE.md` (ADR-0086)." and delete the trailing " (ADR-0086)" after "go in `AGENTS.local.md`.". The sentence "The only `CLAUDE.md` is the user's global one: … go in `AGENTS.local.md`." stays byte for byte (`tests/no-claude-md.test.sh:106-110`).
   - `:61` is not edited: task 7 holds it.
   - Tests: `test_setup_landing_holds`, `test_framing_wording_is_clean`.
6. [x] **Existing test edits** (`tests/framing-second-landing.test.sh`) — both change the clause they check, which the story asks for:
   - `:22-24` `test_framing_merge_is_proven_per_forge`: add 'Any other state, or no pull request from that branch, means not merged.' to the list, and lower-case 'ancestry is never the proof of a merge on GitHub'.
   - `:51-55` `test_root_realigns_after_a_merge`: compare the offset in the landing section of the root fast-forward of Base — 'In the root, `git merge --ff-only origin/<Target branch>`, whatever the slug' — with the offset of 'GIT_INDEX_FILE=<tmp> git read-tree <base>'; fail when the first is missing or not before the second. Drop the `**The commit, built beside the checkout**` comparison. This bites: moving the realignment bullet below the commit block makes it fail.
   - Run `bash tests/run.sh framing-second-landing.test.sh`.
7. [x] **New test file** `tests/framing-commands-cleanup.test.sh`, header comment `# s124 — …`, three functions named after the criteria:
   - `test_stories_paths_agree`: in `section_of po-stories.md 'A story sent back by the review'`, holds 'Next: /po-stories-review' and the set-aside rerun phrase written in task 1; the section does not hold 'Next: /po-research'. In `section_of po-stories-review.md 'Outcome'`, holds the exclusivity phrase of task 2 and 'a complete review'. `templates/prd.md` lacks 'read the whole' and holds the new phrase of task 3.
   - `test_setup_landing_holds`: Step 1 of `po-setup.md` holds 'once question 1 of Step 2 has given `Target branch`'; the landing section holds 'It never commits to `Target branch` directly and never pushes it.'; the `**`Merge mode: local`**` block (awk from that heading to `**Report.**`) holds the refusal sentence of task 5 and its "is not deleted" clause.
   - `test_framing_wording_is_clean`: `po-setup.md` holds '→ stop: ancestry is never the proof' and lacks 'stop: Ancestry'; `po-setup.md` and `po-architect.md` each hold 'Never commit a `CLAUDE.md` (ADR-0086).' and lack '`AGENTS.local.md`. (ADR-0086)'.
   - Quote short exact phrases (`contains` is case-sensitive). Run `bash tests/run.sh framing-commands-cleanup.test.sh`.
8. [x] **Full suite once**: `po-run --story s124-framing-commands-cleanup --label test -- 'bash tests/run.sh'`. The neighbours most likely to turn red: `no-claude-md`, `ship-follows-forge`, `platform-setting`, `framing-through-pr`, `framing-realign-and-orchestrator-log`, `conversational-framing`, `tech-choice-backstop`, `overlap`.

## Scene viewpoints
—

## Run interdicts
- `method/commands/po-setup.md:79` (the secret scan before `commit-tree`) ends unchanged: triage row 142 belongs to s127's `hooks_say_what_they_do`.
- `po-setup.md:68` (s121 realignment, accepted trade-off) and every line of `**Base.**` other than `:71` end unchanged.
- No file outside `Owns` plus `docs/research/`, `docs/plans/`, `docs/verif/` of this story changes: in particular `method/templates/brief.md`, `tests/no-claude-md.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/tech-choice-backstop.test.sh`, `docs/plans/s110-framing-second-landing.md`, `.claude/`, `.polype/` keep an empty diff.
- The sentence "The only `CLAUDE.md` is the user's global one: … go in `AGENTS.local.md`." is byte-identical in `po-setup.md` and `po-architect.md` before and after.
- The "Reads settings:" lines of the five method files are unchanged (no new setting read).
- `docs/parite-killer-saas.md` untouched: no parity line is implemented here.

## The pivot
The fix path of `/po-stories` now may rewrite a story that was not sent back, when a removal breaks it (task 1). Everything else is wording. Ways it could be wrong:
- It weakens "those stories and no other" (`po-stories.md:52`), a guard that keeps the fix path from reopening approved stories. Compare with `po-stories.md:36`, where the main sequence already reruns "Before writing" after Set aside: the new bullet must only touch stories the removal broke, through the user's one-story question, never silently.
- A broken story that has already started could be rewritten. The new bullet must keep the "has already started → stop" rule of `:53` for it.
- The local refusal (task 5) could leave the next landing stuck: `local` Base (`po-setup.md:75`) stacks on `framing/<slug>` when it is not an ancestor of `Target branch`, so the refusal repeats until a person acts. The report must say that, rather than the command rebasing on its own, which the "no switch, no checkout, no stash" rule of `:61` forbids.

## Files touched
- `method/commands/po-stories.md`
- `method/commands/po-stories-review.md`
- `method/templates/prd.md`
- `method/commands/po-setup.md`
- `method/commands/po-architect.md`
- `tests/framing-second-landing.test.sh`
- `tests/framing-commands-cleanup.test.sh` (new)

## Test strategy
Text-rule tests at the only layer this repository has (bash greps of method files), within `Test budget` (25): three new functions, two edited.
- `test_stories_paths_agree`, `test_setup_landing_holds`, `test_framing_wording_is_clean` — each assertion quotes the phrase that carries one rule, so deleting the rule removes the phrase and the test fails.
- `test_framing_merge_is_proven_per_forge` gains the "means not merged" clause; `test_root_realigns_after_a_merge` now compares two places that can move independently.
- No visual check: no screen.
Bite check left to the reviewer (ADR-0012): remove the set-aside bullet, the Outcome exclusivity, the local refusal sentence, line `:61` or `:71`'s clause, and see the matching test fail.

## Done when
Every acceptance criterion holds on the committed code; the eleven triage rows no longer reproduce; `bash tests/run.sh` green through `po-run`; `docs/verif/s124-framing-commands-cleanup.md` complete; one commit on `story/s124-framing-commands-cleanup`; a review with no open critical finding; shipped as `s124-framing-commands-cleanup: Les commandes de cadrage disent juste`.
