# Research — s201-routing-phrase-tests-retired

[Story](../stories.md)

## Structuring facts
- **Root cause (story `Corrige` #136, #164, defects 5/7/9/10/11).** An assertion that pins prose or data that no script reads breaks when that text grows or is reworded, and stays green when the behaviour changes. Proof: `tests/drop-keeps-modified.test.sh:184` pins the `superseded-by:` line of ADR-0088 and was edited by s142 (`5a74dda`) and s188 (`d5424a8`) with no behaviour change, its message still naming only ADR-0092 (#136). `tests/strict-checks-by-default.test.sh:79` hard-codes nine profiles: run on a copy with a tenth profile it fails "expected nine profiles, found 10" while `bin/po-lint` passes (#164).
- **False assumption: "a mutation test of a `method/` file (`tech-choice-backstop`, `plan-and-defect-paths-cleanup`…) proves a script bites: it stays".** Both run a *phrase test* against a mutated copy of `method/`, never a script: `run_against` sources a `tests/*.test.sh` and calls one of its functions (`tests/tech-choice-backstop.test.sh:16-18`, `tests/plan-and-defect-paths-cleanup.test.sh:20-37`). They go with the phrase tests they target. A mutation test that runs a script stays, such as `strict-checks-by-default.test.sh:27-56`, which runs `po-lint` on mutated profiles.
- **Gap in `Owns`.** `tests/ship-and-fleet-cleanup.test.sh:49` (s202's `Owns`, not this story's) runs `escalation-contract.test.sh`'s `test_human_stops_do_not_halt_the_fleet` as its mutation target. That function pins only `po-drive.md` and `AGENTS.md` prose, so the story has to drop it. `test_fleet_tests_bite` would then fail "fails on the real tree" (`:35`). The story needs `tests/ship-and-fleet-cleanup.test.sh` in its `Owns`. Nothing else outside `Owns` reads a family file: a search of `tests/`, `bin/` and `evals/` for each family file name finds only this one.
- **Fresh count.** 193 `*.test.sh` files and 960 `test_` functions (map of 2026-11-15: 161 and 828). Of the 42 family files in `Owns`, `tests/resume-shape-stop.test.sh` is gone (s191, `00e5228`). That leaves 41 files and 226 functions. 92 functions stay whole or trimmed and 134 go; 13 files empty out and are deleted.
- **No script reads the wording the story retires.** `po` reads only fields: from `docs/stories.md` the `- **Owns**`, `- **Fixes**`/`- **Corrige**`, `- **Complexity**` and `- **Surface**` lines (`po/src/context/stories.rs:153-159`); from the plan `validated: yes`, `Technical choice: waiting for a human` and `track:`; from the research `Root cause: not found` (`po/src/context/lanes.rs:320-326`); from a review `Fix loop`, `Review status`, `Ship allowed` and a `- Next action:` holding `findings-shape`, `/po-qa` or `QA evidence` (`po/src/next/lane.rs:185-195`). `po record` reads the first two non-empty lines of `templates/review.md` (`po/src/record/compose.rs:7-15`). `po-gate` reads the verdict lines, `Tree:`, `## Checks`/`## Runs`, `## Acceptance tests` with `| Oracle file | cksum |`, and `## Oracle changes` (`method/hooks/po-gate.sh:145-191,579-667`). `po-lint` reads `Reads settings:`, the tool frontmatter and the profiles (`bin/po-lint:85-348`). The installer reads the template's setting names and default values (`bin/polype:607-631`) and the `Assembled by Polype` marker.

## Story
The routing, fleet, plan, execute and review tests keep only what a script reads. The first of four families of #207.

| Criterion | Kind |
| --- | --- |
| `kept_assertions_have_a_reader` | model-read: the reviewer samples the plan's table |
| `contract_tests_stay` | script-read: `po-lint` passes, kept contract tests still defined |
| `no_script_lost_its_tests` | script-read: per-script launch count does not drop against the base |
| `suite_still_runs_clean` | script-read: no test file without `test_`; the full suite through `po-run` |
| `journey_covers_what_left` | model-read: the plan's table names the journey test or s206 |

## Current code
- **Runner.** `tests/run.sh:32-48` sources `lib.sh` and each file in a fresh `bash -c` to list `test_` names, fails a file with none, then runs each function in its own process. `tests/lib.sh:44` `contains` is a plain `grep -qF`.
- **Phrase-test shape.** Most family files define `section_of`/`holds` and grep sentences of `method/commands/*.md`, `method/agents/*.md`, skills, templates, `method/AGENTS.md`, ADRs or `docs/`. Inside the family, scripts are launched only by `gate`, `floor-guard`, `review-tree-gate`, `review-findings-shape`, `oracle-intact-gate.oracle`, `project-lead`, `drop-keeps-modified`, `strict-checks-by-default`, `leftovers`, `docs-and-eval-cleanup` and `review-header-recorded.oracle`. The per-file list sits in the plan's table, checked by the launch reader below.
- **Journeys** (s199, s200): `tests/journey/journey.sh` walks `po next` through the real `plan-validated`, `verif-current` and `ship-allowed` gates, the pre-commit, `po-run`, `po record` and `po ship` (`docs/harnais.md:123-146`). Test functions: `journey-runs-to-a-landed-commit.oracle.test.sh` (`test_journey_follows_po_next`, `test_story_lands_on_the_full_track`, `test_story_lands_through_a_pull_request`, `test_two_lanes_ship_in_order`, `test_real_gates_are_crossed`, `test_journey_runs_in_the_suite`) and `journey-reaches-every-stop.oracle.test.sh` (`test_short_track_lands`, `test_screen_story_goes_through_design_and_qa`, `test_blocked_review_loops_then_asks`, `test_pending_decision_holds_the_lane`, `test_human_confirmation_waits_for_the_merge`, `test_every_ask_reason_is_reached`).
- **Routing fixtures** outside the family that prove the routing these phrases describe: `tests/driver-next-action.oracle.test.sh` (`test_ships_stay_serial_in_review_order`, `test_ready_and_held_say_why`, `test_fix_loops_stop_at_max_attempts`, `test_blocked_on_shape_asks_and_never_fixes`, `test_every_routing_case_is_a_fixture`) over `tests/fixtures/driver-cases/*.cases`. In them, Owns overlap is `ready-set.cases:38-47` and `QA stage: surfaces` is `resuming.cases:92-140`. `tests/next-names-the-track.oracle.test.sh` covers a `Fixes`/`Corrige` story forced to the full track. `tests/held-says-what-collides.oracle.test.sh` covers `test_owns_collision_names_the_path`. `tests/bounds-messages.test.sh:59-69` covers checkout only in a throwaway clone. `tests/bounds.test.sh:85-92` covers writes only inside `Owns`.

## Attachment points
- The 41 family files (edits and deletions), `tests/routing-phrase-tests-retired.oracle.test.sh` (written), `docs/harnais.md` (a paragraph on the count), `docs/defauts.md` (the recurrent-pattern line), and, once `Owns` allows it, `tests/ship-and-fleet-cleanup.test.sh:33-50`.
- The launch count lives in the oracle file, above its first `test_`, so s202–s204 source it with `source <(sed '/^test_/,$d' …)`, the pattern of `tests/docs-and-eval-cleanup.test.sh:4`.
- The base ref is `origin/<Target branch>`, as `bin/po-version-check:11-29` takes it. CI fetches the whole history (`.github/workflows/ci.yml`, `fetch-depth: 0`), and `tests/po-change-needs-a-version.oracle.test.sh:123-147` already holds that `origin/main` is present in a checkout.

## Verified interfaces
- **Launch reader** (oracle, written and run here). `script_launches <tests dir> <root>` sources each file as `run.sh` does, dumps `declare -p` (only variables the file sets) and `declare -f`, and has a Python reader (`python3 -I`, as `tech-choice-backstop.test.sh:36` already uses) print `<script>\t<file>:<test>`.
  - A launch is the script's path outside single quotes, after variable expansion, in the test or a helper it calls. A mention as a variable's value or as an argument of a text reader (`grep`, `awk`, `sed`, `contains`, `fail`…) does not count.
  - `hooksPath` counts for `pre-commit`.
  - `scripts_kept_their_tests <repo> <ref>` compares the merge base with the working tree. When HEAD is the merge base and `tests/` is clean, it compares nothing. It names the absent ref.
- **Counts on 2026-11-21 (`e322b00`)**: po 178, polype 143, po-gate.sh 135, po-run.sh 52, po-bounds.sh 48, pre-commit 31, po-session.sh 25, po-lint 24, po-eval 20, po-intake.sh 13, po-release 12, polype-dev-install 12, po-version-check 5, po-link-artifacts 4, po-ci 2, ks-overlap 1. Reading the whole suite takes about 3 s; the comparison takes about 7 s.
- **No planned removal launches a script.** The reader's per-function output was checked over the 41 files. Every function it marks as launching is kept: `gate` 22, `floor-guard` 6, `project-lead` 8, `drop-keeps-modified` 5, `review-tree-gate` 3, `review-findings-shape` 3, `oracle-intact-gate` 2, `strict-checks` 2, `leftovers` 1, `docs-and-eval-cleanup` 1, `review-header-recorded` 1.

## Traps
- **The reader is static.** An earlier draft that counted any mention marked `docs-and-eval-cleanup.test.sh:test_law3_row_states_both_status_checks` as a po-gate launch, though it only `awk`s the script's comments. A stricter draft that counted only command positions lost 7 real pre-commit launches in `gate.test.sh`, which lay the hook and commit. The rule in the oracle, text readers excluded, keeps both right; the bite in the oracle holds it.
- **A ratchet for every later pull request.** Once landed, `test_no_script_lost_its_tests` runs on every PR. A story that legitimately retires a script's test (a hook removed counts zero and is not listed; a test merged into another is not) has to keep the count or lighten this oracle, which only a shipped-oracle rule allows. The plan reports this rather than settling it.
- **Before the commit**, HEAD is the base. "Nothing compared" holds only when `tests/` is also clean, so the implementer's pre-commit suite run does compare.
- **`tech-choice-backstop.test.sh:32-63`** targets `conversational-framing.test.sh` (s204's family). Deleting the file drops that mutation now; s204 owns the phrase test it guarded and no longer has to edit a file outside its `Owns`.
- **Oracle files of shipped stories**: `review-header-recorded.oracle.test.sh` (s158) and `oracle-intact-gate.oracle.test.sh` (s150). `po-gate oracle-intact` reads only the oracle that `## Acceptance tests` of a running story's plan names (`po-gate.sh:606-667`). No story in flight names either: `git branch --list 'story/*'` shows only `story/s201-…`.
- **`KEPT_CONTRACTS` in the oracle pins function names.** s205 (word caps) may move `drive-executes-next.test.sh:test_execute_does_not_grow` and would then have to lighten this oracle.
- **The suite**: −134 functions and −13 files, +3 oracle functions and +1 file, ending at 181 files and 828 functions once `test_fleet_tests_bite` also goes. Measured: 73 family functions ran in 1.5 s, so about 3 s is saved; the oracle file adds about 10 s. Net about +7 s on 8–13 min. s202–s204, sourcing the count, add about 7 s each.

## Diagnostic
- **Reproduction.**
  - #164: a copy of `tests/{lib,run,strict-checks-by-default}.sh`, `method/`, `bin/po-lint` and `boilerplates/` plus a tenth profile, under `mktemp -d`, gives `FAIL every_profile_fills_strictness — expected nine profiles, found 10`.
  - #136: `git log -G` on `:184` shows two edits forced by new ADRs (s142, s188).
- **H1** "the two tests hold wrong values, fix the values": the values were right when written, and growth made them wrong (s142 and s188 had to edit `:184`). A new value fails again at the next ADR or profile. Discarded.
- **H2** "the assertions pin a text no script reads": no script reads ADR frontmatter (no hit for `superseded-by` in `po/src`, `bin`, `method/hooks`), and `po-lint` checks the profiles' lines but not their number (`bin/po-lint:266-344`). A tenth profile breaks the test while `po-lint` passes. Kept: the root cause above.

## Open questions
Settled by the lead after this research: `tests/ship-and-fleet-cleanup.test.sh` joined `Owns` (`8e2a5ad`); the count stays on every later PR, a story that rightly removes a script's test lightening the oracle and saying so; the three unguarded checks are #442.

## Complexity
3 → **4**. The deletions are mechanical, but the launch count has to read bash statically without lying. Two drafts of it were wrong in opposite directions.

## Split
—
