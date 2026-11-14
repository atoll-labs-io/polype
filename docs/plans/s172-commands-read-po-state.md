---
validated: yes
---
# Plan — s172-commands-read-po-state

[Story](../stories.md) · [Research](../research/s172-commands-read-po-state.md)

Branch `story/s172-commands-read-po-state`. Read `docs/research/s172-commands-read-po-state.md` first. This plan builds on it, and the section below corrects it where s176 and the reworded story made it false.

## Research amendments (2026-11-14, after s176 and decisions d-0017, d-0018)
The research file is this lane's and is not rewritten (`/po-plan` contract). These corrections apply:
- **False assumption 1 is settled by s176.** `po state` now carries `framing.items` (`{item, state}`, in the hook's order), `lanes[].path` and `lanes[].stops` (each stop has a `code` and its own fields: `file`, `command`, `fix_loop`, `max_attempts`, `branch`), and `blocked_by` is the code of the first stop (`docs/interface-agent.md`, the `## state` bullets). This was checked on a `po` built from `ceece03`, on the fixtures of `project-lead`, `session-and-gate-checks` and the escalations case. Every line those tests pin is there. `ready` is still `null` without `Parallel`, which the reworded criterion accepts.
- **False assumptions 2 and 3 are settled by the story.** `Owns` now lists every test file of the research's table, plus `tests/lib.sh`, `tests/run.sh` and `README.md`. Criterion 3 now keeps file reading for whatever `po state` does not carry.
- **Open questions 1–4 are answered:**
  - (1) the split, option (c): s176 has shipped;
  - (2) the `CLAUDE.md` / install-mode hint stays in bash;
  - (3) the two commands read `po state` for what it carries and read files for the rest, naming which;
  - (4) the hook reads the JSON with `jq` (d-0018).
- **No `po/` change is needed.** The "attachment points" under `po/` no longer apply.
- **`tests/readme-onboarding.test.sh:30-34` does not break.** The rewritten hook keeps a `mapfile` after its bash guard (task 2).
- **Complexity is 4, as the story rates it.** The plan has 8 tasks, so no split is needed.

## Story
`po-session` takes framing, lanes, ready stories and human stops from `po state`, and reads that JSON with `jq`. Its output on the existing tests is unchanged, except the ready line, which now says what `po` computed. When `Parallel` is missing, that line names it.

Of the `po state` warnings, the hook shows only those it already showed: the version mismatch, an orphan worktree, and an unreadable setting. The `CLAUDE.md` / install-mode hint stays in bash. Without `po`, the hook prints a line naming the installer. Without `jq`, it prints a line naming `jq` and pointing to `po state`. In both cases it exits 0.

`/po-status` and `/po-retro` read `po state` for what it carries (`--all` for a retro outside the current milestone), name what they still read from files, and cite `po state` as the source of any figure taken from it.

Criteria:
- `session_hook_prints_from_po_state`
- `session_hook_survives_a_missing_po`
- `status_and_retro_read_po_state` (judged in review, plus a word-count test)

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Hook formatting of the `po state` JSON | dependency already installed: `jq`, required by `po-bounds.sh` (`method/hooks/po-bounds.sh:55,830`) and chosen by d-0018 | nothing in the repository turns this JSON into lines; bash alone cannot parse JSON |
| Locating `po` | already in this repository: `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"` (`method/commands/po-drive.md:29`) | — |
| PATH without `jq` in the oracle | already in this repository: the pattern of `path_without_cargo` (`tests/po-prebuilt-and-verified.oracle.test.sh:94-107`), copied because it is local to that file | — |
| Laying the suite's `po` | `tests/run.sh:22-26` already builds it; one `cp` added | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/commands-read-po-state.oracle.test.sh` | `3219234154 7518` |

| Criterion | Test |
| --- | --- |
| `session_hook_prints_from_po_state` | `test_session_hook_prints_from_po_state`: a stub `po` whose JSON contradicts the files on disk. It checks that the hook calls `po state` from the project root and prints each line from the JSON: framing, next, unreadable settings, ready, lanes with path, every stop with its values, orphans. It checks that `Decision inbox` and `no-gate` are not shown. It covers `ready: null` with and without `Parallel`. |
| `session_hook_survives_a_missing_po` | `test_session_hook_survives_a_missing_po`: no `po` → a line naming it and `polype install`, exit 0, no framing line. PATH without `jq` → a line naming `jq` and `<po path> state`, exit 0. A `method-version-mismatch` warning → printed as is. |
| `status_and_retro_read_po_state` | no oracle (a rule read by a model, judged in review). `test_status_and_retro_shrink` in `tests/commands-read-po-state.test.sh` checks only `wc -w < file` against 1101 and 977. This is a candidate for a `po-eval` control arm (#208). |

## Tasks
1. [x] **`tests/run.sh`: put the suite's `po` where the hook looks for it.** Inside the `if [ -f "$root/po/Cargo.toml" ]` block, after the build: `mkdir -p "$CLAUDE_CONFIG_DIR/polype" && cp "$CARGO_TARGET_DIR/release/po" "$CLAUDE_CONFIG_DIR/polype/po"`. Use a copy, not a symlink: an installer test that runs `lay_po` on this shared directory then replaces a file and never writes through a link. Test that fails if this is wrong: `tests/project-lead.test.sh` session tests, which run under the suite's config dir (task 4).

2. [x] **Rewrite `method/hooks/po-session.sh` (bash, ADR-0116).**
   - **Keep:** lines 1–17 unchanged (silence outside a project and in a story worktree; the bash ≥ 4.2 guard); the header line (:22); `setting()`; the `CLAUDE.md` hint, which is lines 241–256 with their comment block left just above `local again=` inside a function (`tests/update-keeps-mode.test.sh:166-178` reads that block).
   - **Remove:** everything that derives state. That is lines 33–39 except `Project CLAUDE file`, `on_target*`, `last_value`, `frontmatter_status`, `framing`, `read_worktrees`, `read_shipped`/`SHORT_SHIPPED`, `ready_stories`, `lanes_in_flight`, and the per-lane part of `waiting_for_a_human`.
   - **New flow:**
     1. `po="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"`. If it is not executable, print **L1** and exit 0.
     2. If `command -v jq` fails, print **L2** and exit 0.
     3. Capture `json="$(cd "$top" && "$po" state 2>/dev/null)"`. A non-zero exit, or `jq -e .contract` failing on it, prints **L3** and exits 0.
     4. Read the formatted lines with `mapfile -t … < <(jq -r … <<< "$json")`. This keeps a bash-4 construct after the guard for `tests/readme-onboarding.test.sh:30-34`.
   - **Printed lines, in this order:**
     1. The header.
     2. One line per warning with code `method-version-mismatch`: `po warning: <the warning object, jq -c>`.
     3. If `framing.stage` is `setup`: `Framing: setup missing → /po-setup`, then exit 0, as today.
     4. If `framing` is not null:
        - `Framing: ` followed by each item as `<item, with - as a space> <state>`, joined by ` · `;
        - `Framing next: <next>`, or `Framing next: none — framing done` when `next` is null.
     5. `Unreadable setting: <setting>` for each `missing-setting` or `unreadable-setting` warning whose setting is one of `Target branch`, `Entry mode`, `Worktree root`, `Max attempts`, `Merge mode`, `Ship confirmation` (the six this hook used to name).
     6. The ready line:
        - `Ready stories: a, b`;
        - `Ready stories: none` for `[]`;
        - for `null`, when the `Parallel` setting is missing or not all digits: `Ready stories: not computed — Parallel is missing or unreadable in AGENTS.local.md`;
        - any other `null`: `Ready stories: not read by po`.
     7. When `lanes` is not null: `Lanes in flight: <story> (<path>), …`, or `Lanes in flight: none`.
     8. `Waiting for a human:` followed by these items, or `Waiting for a human: nothing`:
        - per lane, in order, each stop:
          - `root-cause-not-found` → `- <id>: root cause not found (<file>)`;
          - `technical-choice` → `- <id>: technical choice waiting for a human (<file>) → <command>`;
          - `qa-blocked` → `- <id>: QA blocked (<file>)`;
          - `max-attempts` → `- <id>: Max attempts reached (Fix loop: <fix_loop>, Max attempts: <max_attempts>)`;
          - `merge-waiting` → `- <id>: pull request presumed waiting for a human merge (<branch> pushed; the forge was not asked)`;
        - then each `orphan-worktree` warning: `- <path>: orphan worktree (<branch, or detached HEAD when null>)`;
        - then the `CLAUDE.md` hint lines.
   - **L1:** `po-session: po not found at <po path>; project state not read → polype install lays it down`
   - **L2:** `po-session: jq not found; project state not shown → install jq, or run <po path> state for the JSON`
   - **L3:** `po-session: po state failed (exit <n>); project state not read → polype update . rebuilds po`
   - Update the comment at :2–4: the hook reads `po state` and changes nothing. Strip any comment that only narrates.
   - Tests that fail if this is wrong: the oracle; `tests/session-and-gate-checks.test.sh`; `tests/project-lead.test.sh`; `tests/no-claude-md.test.sh`; `tests/claude-md-setting.test.sh`; `tests/update-keeps-mode.test.sh`; `tests/readme-onboarding.test.sh`.

3. [x] **Create `tests/commands-read-po-state.test.sh` with `test_session_hook_reports_a_failing_po`.** A stub `po` that prints `{"contract":1,"error":"not-a-project","message":"x"}` and exits 2. The test expects a line holding `po state failed (exit 2)`, exit 0, and no `Framing` line. Copy the oracle's stub helpers into this file rather than sourcing the oracle. This test fails if L3 is missing or if the hook falls back to deriving.

4. [x] **Session tests outside the hook: change only what read the bash derivation.**
   - `tests/project-lead.test.sh`: add `'Parallel: 2'` to the `polype_repo` call of `test_session_hook_reports_state_read_only` (:61). Change :86 to `'Ready stories: s02-b'`. Nothing else changes.
   - `tests/short-subject-shipped.test.sh`:
     - add `Parallel: 3` to the settings printed in `project_with_stories` (:12);
     - change :31 and :48 to `'Ready stories: s02-y'`;
     - change :40 to `'Ready stories: s10-x, s100-y'`;
     - remove the `po-status` sentence loop (:26-28), because criterion 3 removes that rule from `po-status.md`. Keep `SENTENCE` only if another assertion still uses it.
   - `tests/ship-and-fleet-cleanup.test.sh`, in `test_fleet_tests_bite`: remove the mutation block on `SHORT_SHIPPED["${id%:}"]=1` (:80-92), because that line leaves the hook. The rule now lives in `po` (`po/src/context/lanes.rs:74-75`) and `tests/state-as-json.test.sh:100` covers it. Keep the `escalation-contract` `bites` line.
   - `tests/state-as-json.test.sh`: the parity with `po-session` becomes a tautology once the hook prints `po state`.
     - Remove `session_next` (:48-56).
     - Change `expect` to take the expected next as `$2` and compare it with `.framing.next // "null"`.
     - Write the calls of `test_framing_next_matches_po_session` (:72-89) as: `expect scope /po-brief`, `stories /po-stories`, `stories-review /po-stories-review`, `architecture /po-architect`, `design-system /po-design-system`, `done null` twice, `stories /po-stories`, `setup /po-setup`.
     - Rename the function to `test_framing_next_follows_the_stage`.
   - **Expected unchanged; run them and change none:** `tests/session-and-gate-checks.test.sh` (all three cases keep their assertions: the technical-choice line and the design-system items come from `po` with the same text), `tests/no-claude-md.test.sh`, `tests/claude-md-setting.test.sh`, `tests/update-keeps-mode.test.sh`, `tests/readme-onboarding.test.sh`.
     - If one of them fails only because its own `CLAUDE_CONFIG_DIR` has no `po`, add to `tests/lib.sh` a helper `po_for_hook` (`mkdir -p "$CLAUDE_CONFIG_DIR/polype"; [ -e … ] || cp "$PO" …`), call it in that test, and record the case in the verification record.
     - Issue 254: `tests/readme-onboarding.test.sh` rebuilds `po` from the committed HEAD into the suite's shared target folder. This story changes no Rust, so it should not bite. If it does, report it rather than editing around it.

   Test that fails if this is wrong: each file above, run on its own.

5. [x] **`README.md` line 59 (the `jq` bullet).** Add the session hook to what `jq` is required for (it reads `po state` there), and change nothing else. Test that fails if this is wrong: `tests/readme-onboarding.test.sh` `test_prerequisites_are_listed` still finds `jq` and `SessionStart`.

6. [x] **Rewrite `method/commands/po-status.md`.**
   - `Reads settings`: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`, `Story track`, `Flow threshold`, `ADR directory`.
   - Keep the read-only sentence, including `no commit, checkout, merge or file change`, and the `git fetch` allowance.
   - **Step 2:** run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" state --all` from the repository root. When `po` is missing or exits 2, say so, name `polype install`, and stop. The step reports from that JSON: framing items and next, milestone, lanes (path, stage, `next`, stops), `ready`, `held` (reason, ref, and for `owns` the two entries and the path), `shipped`, and warnings as they are. Each figure cites `po state`.
   - **Step 3, named as what `po state` does not carry, read from files:**
     - per story of `docs/stories.md`: its complexity;
     - its track: `track: flow` in the plan, `full` for a plan without it, or `(expected)` from `Story track` and `Flow threshold`;
     - whether the research, design, plan, record, QA report and review files are present, in the worktree while it exists, otherwise on `Target branch`;
     - the plan's ticked boxes over total;
     - the next step of a story without a lane:
       - a story in `ready`: `/po-flow <id>` when the expected track is flow, otherwise `/po-research <id>`;
       - a story in `held`: its reason;
       - a shipped story: nothing.
   - A story with a lane takes its next from `lanes[].next`.
   - Output: keep the table header `story (complexity) · track · research · design · plan · record · qa · review · shipped · next`. Keep step 6, the ADRs, which reads `ADR directory` and names no path. Finish with the `Next:` line.
   - **Remove** the framing rules, shipped rule, gate and QA routing, fleet derivation, overlap rule and next chain. This also removes the stale `Fix loop:` "the way `/po-drive` reads it" (s173 review finding, :35).
   - **Assertions that move with it, each because its clause leaves `po-status.md`:**
     - `tests/pilot.test.sh`: remove `test_status_detects_merged_pull_requests`. `test_status_derives_from_files` stays as it is.
     - `tests/fleet-wiring.test.sh`: remove `test_status_shows_lanes_and_attempts`.
     - `tests/final-leftovers.test.sh`, `test_overlap_wording_is_light`: remove the two `$s` lines (:23-24) and keep the skill lines.
     - `tests/ship-and-fleet-cleanup.test.sh`, `test_fleet_rules_agree`: remove the `step3`/`step4`/`step5` block (:47-58).
     - `tests/qa-fleet.test.sh`:
       - `test_status_reports_qa`: keep `'· record · qa · review ·'` and remove the other four assertions;
       - remove `test_status_agrees_with_the_fleet_on_a_blocked_report`;
       - the loop of :114-119 stays.
     - `tests/owns-overlap.test.sh`, `test_every_overlap_text_cites_the_rule`: drop `commands/po-status.md` from the first list (:51).
     - `tests/ship.test.sh`: remove :45-46.
     - `tests/surface-routing.test.sh`, `test_qa_follows_the_qa_stage`: remove :33. The `lacks` checks stay.
     - `tests/wiring.test.sh`, `test_status_reports_framing_and_track`: keep `Story track`, `Flow threshold`, `` `track: flow` ``, `` `/po-flow <id>` ``. Remove `Entry mode`, `docs/prd.md`, `docs/brief.md`, `Stories ready:`, `docs/architecture.md`, `docs/design-system.md`.
     - `tests/docs-and-eval-cleanup.test.sh`: remove `test_status_shipped_rule_reads_once` and `test_status_design_system_matches_session`, and remove `test_drive_resumes_a_review_the_gate_refuses` (:65-71, `po-status` only).
     - `tests/short-subject-shipped.test.sh`: see task 4.
     - `tests/adr-directory.test.sh`: unchanged.

   Test that fails if this is wrong: each file above, plus `test_status_and_retro_shrink` (task 7).

7. [x] **Rewrite `method/commands/po-retro.md`, and add `test_status_and_retro_shrink` to `tests/commands-read-po-state.test.sh`.**
   - The retro runs `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" state --all`, named in the Bash list of the opening paragraph. Without `po`, or on exit 2, it says so, names `polype install`, and stops.
   - For a shipped story, its fix loops and its last review's max severity come from `shipped[].trust.fix_loops` and `max_severity`, with `po state` as the cited source.
   - Read from files, and named as such: the `Max severity:` of each earlier review; finding counts per severity; a blocked review's cause; blocked QA walks; open majors; recorded runs; and every figure of a story still in flight.
   - Remove the clause "read the way `/po-drive` reads it" (:37, the s173 finding).
   - The Output rule becomes: "Every figure names the file and line it comes from, or `po state` for a figure taken from it".
   - Keep the Scope section word for word (`tests/commands-and-texts.test.sh`), the measure names, `open by the last review`, the `not blocked` majors row, `This command writes no file`, `Bash is used read-only`, `It counts no lines of code and no commits`, `an absent file is never a zero`. Never write `git log` or `--stat`.
   - `tests/po-retro.test.sh` and `tests/commands-and-texts.test.sh` are expected unchanged.
   - Test that fails if this is wrong: `tests/po-retro.test.sh`, `tests/commands-and-texts.test.sh`, and `test_status_and_retro_shrink`, which checks `[ "$(wc -w < "$METHOD/commands/po-status.md")" -lt 1101 ]` and `[ "$(wc -w < "$METHOD/commands/po-retro.md")" -lt 977 ]`.

8. [x] **Full suite, once.** Run `po-run --story s172-commands-read-po-state --label test -- 'bash tests/run.sh'`. There is no type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `po/`, `docs/interface-agent.md`, `bin/`, `.github/`, and every file of `method/` except `hooks/po-session.sh`, `commands/po-status.md` and `commands/po-retro.md` end with an empty diff.
- `tests/commands-read-po-state.oracle.test.sh` keeps the sum `3219234154 7518`, unless the change is recorded under `## Oracle changes` of the verification record.
- The hook calls only `po state`: no other verb, no `--all`, no `--remote`. It never runs `git worktree list`, `git log`, or reads `docs/stories.md`, a lane's files or `docs/reviews/stories.md`.
- The `CLAUDE.md` / install-mode hint keeps its behaviour, its lines, and the comment block above `local again=`.
- `README.md`: only the `jq` bullet changes.
- `tests/session-and-gate-checks.test.sh`, `tests/no-claude-md.test.sh`, `tests/claude-md-setting.test.sh`, `tests/update-keeps-mode.test.sh`, `tests/readme-onboarding.test.sh`, `tests/adr-directory.test.sh`, `tests/po-retro.test.sh` and `tests/commands-and-texts.test.sh` end with an empty diff. The `po_for_hook` exception of task 4 must be recorded if used.
- Issue #244 is not addressed here; it stays an issue (research, "Settled findings").
- `docs/research/s172-commands-read-po-state.md` is not rewritten.

## The pivot
**The decision:** `po state` is the hook's only source, and only the formatting stays in bash. Ways this could be wrong:
1. **A line `po` computes differently from the old bash on an existing fixture.** I compared outputs on the fixtures of `project-lead` (state, escalations, ordinary lanes), `session-and-gate-checks` (technical choice) and the setup case, and they match except the ready line, which task 4 updates. A fixture I did not run could still differ. Compare the hook's output with `po state` on the failing case before touching the test.
2. **A test runs the hook under its own config dir with no `po`.** Compare against the list in task 4 and the `po_for_hook` exception.
3. **Settings warnings.** `po` warns about `Max attempts`, `Merge mode` and `Ship confirmation` only when stories and landed commits are read (`po/src/context/mod.rs:155-167`), whereas the old hook always did. No existing test pins those lines. Check that none of the `Waiting for a human: nothing` assertions picks up a warning.
4. **Session start time.** `po state` runs each lane's `po-gate` (`po/src/context/lanes.rs:126-138`). This is acceptable for a read-only hook. If the suite slows sharply, report it instead of caching.

## Files touched
`method/hooks/po-session.sh`, `method/commands/po-status.md`, `method/commands/po-retro.md`, `README.md`, `tests/run.sh`, `tests/commands-read-po-state.test.sh` (new), `tests/commands-read-po-state.oracle.test.sh` (written by the planner), `tests/project-lead.test.sh`, `tests/short-subject-shipped.test.sh`, `tests/ship-and-fleet-cleanup.test.sh`, `tests/state-as-json.test.sh`, `tests/pilot.test.sh`, `tests/fleet-wiring.test.sh`, `tests/final-leftovers.test.sh`, `tests/qa-fleet.test.sh`, `tests/owns-overlap.test.sh`, `tests/ship.test.sh`, `tests/surface-routing.test.sh`, `tests/wiring.test.sh`, `tests/docs-and-eval-cleanup.test.sh`, and `tests/lib.sh` only under the task 4 exception. Plus `docs/research/`, `docs/plans/` and `docs/verif/` for this id.

## Test strategy
- **New tests: 4, within `Test budget` 25.** Two oracle tests at the hook's interface, with a stub `po` so that the bash cannot answer for `po`. One task test for a failing `po`. One word-count test, which is all criterion 3 gets by the owner's rule.
- **The `po` side is not retested here.** s164 and s176 cover it (`tests/state-carries-session-lines.oracle.test.sh`, `tests/state-as-json.test.sh`), and the session tests of `project-lead` and `short-subject-shipped` run the real `po` end to end.
- **Changed tests:** only assertions whose clause leaves a file, listed per file in tasks 4 and 6. Each removal is a clause this story deletes, so keeping it would make a test check a phrase no script reads.
- **Candidate for a `po-eval` control arm (#208):** `status_and_retro_read_po_state`.
- **Visual checks:** none.

## Done when
- The oracle and the task tests pass, and the full suite passes once through `po-run`.
- `po-status.md` and `po-retro.md` have fewer words than 1101 and 977.
- The review finds no open critical finding.
- One commit lands through a pull request.
