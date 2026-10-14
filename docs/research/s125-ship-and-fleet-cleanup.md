# Research — s125-ship-and-fleet-cleanup

## Structuring facts
- No assumption of the story is false. Every HOLDS row of `docs/reviews/triage-2026-10-14.md` that points to an `Owns` file still holds on `story/s125-ship-and-fleet-cleanup` (rows `:90`, `:91`, `:118`, `:120`, `:126`, `:129`, `:154`, `:155`, `:156`, `:170`). This is a defect story (`Corrige`), and each row's root cause is a missing clause or an assertion that does not bite, shown below.
- Root cause, ship text: `method/commands/po-ship.md:74` puts the skip condition on `origin/story/<id>` without saying what happens when that ref is missing, and checks parent and tree but not the message `<id>: <story title>`. Reproduced: with no remote branch, `git push --force-with-lease=story/x origin <sha>:refs/heads/story/x` creates the branch and exits 0 (git 2.56, throwaway repo in `/tmp`).
- Root cause, ship order: `method/AGENTS.md:55` ("lands … in the order the reviews passed") and `method/commands/po-drive.md:144` ("ship one story, prove it, then ship the next, in the order their reviews passed") state a landing order that `AGENTS.md:57` and `po-drive.md:148` ("land in the order a person merges them") contradict under an effective `human` with `pr`. Neither file says that the review order only orders which pull request opens first.
- Root cause, hollow tests (reproduced with mutants in `/tmp`, see `## Diagnostic`): `tests/escalation-contract.test.sh:78` still passes when "Meanwhile the other lanes carry on." and the AskUserQuestion clause are removed from `po-drive.md:111`; `tests/short-subject-shipped.test.sh:139-140` still passes when `po-session.sh:156` stops recording short subjects; `tests/defect-and-routing-paths.test.sh` still passes when the planner stop of `po-drive.md:103` is removed.
- Missing marker: `method/commands/po-status.md` never mentions `Technical choice: waiting for a human` (`grep` finds no match), while `method/hooks/po-session.sh:212-214` reports it.

## Story
`/po-ship`, `/po-drive`, `/po-status` and `method/AGENTS.md` say exactly what they do, and their tests bite. Criteria:
- `ship_text_is_complete`: `/po-ship` says what happens when `origin/story/<id>` does not exist yet, and the reused head is also checked against `<id>: <story title>`. A test pins Step 2 to the effective `Ship confirmation`. The criterion `push_targets_only_the_story_ref` gets a test of its own name.
- `fleet_rules_agree`: the ship order (review order vs. human merge order) reads without contradiction in `/po-drive` and `method/AGENTS.md`; `Root cause: not found` is a whole line (`grep -x`, ADR-0070) in `/po-drive`; `/po-status` shows a plan waiting for a technical choice.
- `fleet_tests_bite`: the tests of `escalation-contract`, `short-subject-shipped` and `defect-and-routing-paths` that the triage calls hollow fail once their rule is removed.

## Diagnostic
Reproduction, on the code as it stands, with nothing written in the worktree (mutants copied to `mktemp -d`):
1. `sed -i 's/ Meanwhile the other lanes carry on\.//'` on a copy of `po-drive.md`, then also dropping ", and it is not asked through AskUserQuestion, which would hold every other lane until the answer came": `test_human_stops_do_not_halt_the_fleet` exits 0 both times. The phrase "the other lanes carry on" occurs 5 times in `po-drive.md` (`:25`, `:91`, `:111`, `:113`), so `:78` cannot tell s104's sentence from the older ones.
2. In a copy of `po-session.sh`, `SHORT_SHIPPED["${id%:}"]=1` replaced by `:` (the regex text left in place): `test_short_subject_counts_as_shipped` exits 0. Its po-session half (`:139-140`) only greps the text of `read_shipped`.
3. In a copy of `po-drive.md`, the sentence "A planner that answers with a research holding `Root cause: not found` … no plan is approved or dispatched for it." removed from `:103`: `test_no_root_cause_goes_to_a_human` exits 0. The resume row at `:52` is pinned (`defect-and-routing-paths.test.sh:39-46`), the dispatch stop is not.
4. `grep -n effective tests/*.sh`: only `tests/drive-guards.test.sh:39,47`, both about the `## Resuming` table of `po-drive.md`; nothing pins `po-ship.md:62,76,77,80`.
5. `grep -rn push_targets_only_the_story_ref tests/`: no match; the criterion (`docs/stories.md:1682`) is carried by `tests/ship-through-pr.test.sh:27` `test_no_agent_pushes_target_branch`, s105's criterion (`docs/stories.md:1629`).

Hypotheses, one per family:
- H1 "the finding was fixed between the triage (365f0c6) and this branch". Refuted if the cited line no longer reads as quoted. Discarded: every cited line reads as the triage quotes it (`po-ship.md:74`, `po-drive.md:52,103,144,148`, `AGENTS.md:55,57`, the test lines above).
- H2 "the review order and the merge order describe two different things already, so there is no contradiction". Refuted if a sentence ties the review order to opening the pull requests only. Discarded: no sentence of either file does; `AGENTS.md:55` says the next one *lands* after it, in review order.
- H3 (kept) "each finding is a missing clause or an assertion matching text the rule does not own". The mutants of steps 1-3 prove it for the tests; steps 4-5 and the reads of `## Structuring facts` prove it for the text.

## Current code
- `method/commands/po-ship.md` Step 2 (`:59-81`): `:62` says "Below, `Ship confirmation` is always the effective value that section settled"; the bullets `:76`, `:77`, `:80` each say ", the effective value". `:74` holds the push, the skip condition and the rebinding of `<sha>` in one bullet.
- `method/commands/po-drive.md`: `## Resuming` row `:52` "research holding the line `Root cause: not found`"; `## Dispatching` step 1 `:103` "A planner that answers with a research holding `Root cause: not found` sends its lane to a human …"; `## A wave` `:111`, the at-once rule; `## Ships, one at a time` `:144` and `:148`.
- `method/AGENTS.md` `### The fleet` `:55` (**Ships stay serial**) and `:57` (effective human with pr).
- `method/commands/po-status.md`: step 3 plan bullet `:27` "plan: none · draft · approved"; step 4 blocked stories `:36`; step 5 "Next" `:39`. No technical-choice case anywhere.
- Tests: `tests/ship-through-pr.test.sh:27-41`, `tests/escalation-contract.test.sh:75-85`, `tests/short-subject-shipped.test.sh:20-30` (file `:134-141` above), `tests/defect-and-routing-paths.test.sh:28-50`.

## Attachment points
- `po-ship.md:74`: the skip bullet. It must keep `Skip the push` and `When the push is skipped, \`<sha>\` becomes that head` on one line, before `gh pr merge` (`tests/ship-resumes-cleanly.test.sh:13-20`), and keep `git rev-parse origin/story/<id>` in Step 2 (`:14`).
- `po-drive.md:52`, `:103` for the whole-line wording; `:144`, `:148` for the ship order.
- `AGENTS.md:55`, `:57`.
- `po-status.md:27`, `:36`, `:39`.
- New test file `tests/ship-and-fleet-cleanup.test.sh`, one function per criterion. Mutation helpers can be copied from `tests/tech-choice-backstop.test.sh:6-22` (`mutant`, `run_against`); sourcing that file would also load its `test_*` functions.

## Verified interfaces
- `run_against <method dir> <test file> <function>` sets `METHOD` before sourcing (`tech-choice-backstop.test.sh:20-22`). `DRIVE`, `ORCH`, `HOOK` are computed from `$METHOD` when the file is sourced (`escalation-contract.test.sh:5,8`, `short-subject-shipped.test.sh:4`, `defect-and-routing-paths.test.sh:9`), so a mutant tree reaches them.
- `po-session.sh:145` `is_shipped` reads `SHORT_SHIPPED[${1%%-*}]`, filled at `:155-157`. A story `s01-x` with a commit `s01: x` is shipped; `project_with_stories` and `session_in` (`short-subject-shipped.test.sh:8-23`) build that case.
- `section_of`/`holds` are defined per test file, not in `tests/lib.sh` (`lib.sh:1-53`).
- `git push --force-with-lease=<ref> origin <sha>:refs/heads/<ref>` with no remote-tracking ref: creates the branch, exit 0; a second identical run prints "Everything up-to-date", exit 0 (reproduced, git 2.56.0).

## Traps
Phrases that tests outside `Owns` pin, which the edits must keep word for word:
- `tests/fleet-wiring.test.sh:36-38` in Law 1 of `AGENTS.md`: `**Ships stay serial**`, `lands on \`Target branch\` alone`, `in the order the reviews passed`; `:41-42` the `Owns` sentences.
- `tests/drive.test.sh:78-84` in `## Ships, one at a time`: `Ships never overlap.`, `you ship one story, prove it, then ship the next`, `requires the repository root clean and on \`Target branch\``, the gate sentence, and `\`Ship confirmation: human\` means one AskUserQuestion per merge under \`Merge mode: local\`, and a pull request left for a person under \`Merge mode: pr\``.
- `tests/ship-follows-forge.test.sh:104-106`: `is not the landing` in the ships section, `opening the pull request is not the landing` in Law 1.
- `tests/qa-fleet.test.sh:167` pins `is \`blocked\` → "a human decides"` in `po-status.md`.
- `tests/ship-through-pr.test.sh:31-40`: every `git push` line of `po-ship.md` must name `story/<id>` and no ref but `refs/heads/story/<id>`, so the new missing-ref sentence must not introduce a `git push` naming anything else.
- `tests/defect-and-routing-paths.test.sh:39-46` and `tests/escalation-contract.test.sh:61-69` count the resuming rows holding each marker (exactly one) and read column 3; rewording `:52` must keep one row and keep `a human` at the start of its second cell.
- `tests/overlap.test.sh`: no new method line may share 8+ consecutive words with Killer SaaS.
- s126 (same milestone) owns `po-plan.md`, `planner.md`, `po-research.md`, `po-orchestrator.md`, and its criterion `defect_stops_agree` also counts the `po-drive.md:103` stop among "the three stops". s125 owns `po-drive.md` and `defect-and-routing-paths.test.sh`, so the stop is pinned here. If s126 pins it again from its own test file, the two tests overlap without conflicting.
- Installed copies (root `AGENTS.md`, `.claude/`, `.polype/`) are not edited; they are refreshed after the ship. No migration, no dependency, no ADR (ADR-0089 stays unused).

## Open questions
- Should the `po-drive.md:53` and `:120` mentions of `Technical choice: waiting for a human` also say "whole line"? The story asks it for `Root cause: not found` only; the plan leaves them unchanged.
- `po-status.md` has no `Root cause: not found` case either, which `po-session.sh:208-211` reports. No triage row asks for it; the lead decided after the wave to close it in this story (plan, task 6).

## Complexity
2 → 2. Prose edits in four method files and five test files, plus one new test file. Three mutation tests reuse an existing pattern. No executable code changes.

## Split
—
