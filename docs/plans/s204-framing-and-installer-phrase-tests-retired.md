---
track: flow
validated: yes
---
# Plan (short track) — s204-framing-and-installer-phrase-tests-retired

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s204-framing-and-installer-phrase-tests-retired.md`. Line numbers are those of `3c11c33`. Validated under `Plan validation: autonomous`, applying the owner's standing answers d-0051 and d-0052: no human reviewed this plan.

## Verified facts
**Story assumption partly false.** "Only the phrases of `docs/installation.md` and `method/AGENTS.md` fall" in the installer tests. Some of those phrases are security rules (bounds refusals, reviewer mode, what the installer does with a person's files, no project `CLAUDE.md`). Under d-0052 they stay. Not a blocker. The ranges `readme-onboarding.test.sh:127-155` of the story are stale: the phrase functions are at `:62-69`, `:134-147` and `:149-161`.

- All 40 test files of `Owns` exist, `tests/flow.test.sh` included: the lead widened `Owns` to it through a framing pull request after this plan's first draft. Before: 171 files and 727 functions, counted as `tests/run.sh:33-36` loads them.
- `po` reads, of the framing: `Entry mode` (`po/src/context/framing.rs:61-69`); the `status:` frontmatter of `docs/brief.md` or `docs/prd.md`, `approved` or not (`:39-52,76-78`); the last `Stories ready:` of `docs/reviews/stories.md` (`:82-83`); `Story track`, `Flow threshold`, `Design source` (`po/src/next/lane.rs:20,39,90`); the `Owns` lines (`po/src/context/stories.rs:153`), compared by `po/src/next/overlap.rs`. No script reads `## Landing the framing` of `/po-setup`. No journey lands a framing.
- `bin/po-lint` reads:
  - the `Reads settings:` names, only that each exists in the template (`:98-123`);
  - the tools against the stated contract: AskUserQuestion, Agent with Edit, `cannot edit files or run a shell`, no Write for a skill `stories-review` (`:125-160`);
  - in `## Checks`, `## Preconditions`, `Step 0` and `## By hand`, an absence that triggers no stop (`:169-186`). It holds that the `` `—` → stop `` branches of `/po-brief`, `/po-prd` and `/po-stories` stay stops. It does not hold that they exist.
- `bin/polype` lists each template setting a project lacks (`:627`) and checks `Project CLAUDE file` is `absorbed` or `kept` (`:623-629`). `bin/po-link-artifacts:15` reads the link line under a template's title.
- Launch count (`tests/routing-phrase-tests-retired.oracle.test.sh:123-145`): on a copy with every edit applied, every count is unchanged (`po` 178, `po-gate.sh` 136, `po-bounds.sh` 48, `po-session.sh` 25, `polype` 143, `po-lint` 26, `pre-commit` 32, …). No `LOWERED_COUNTS` line is needed. See `## The pivot`.
- On that copy: the 20 edited files (before `flow` joined; its edit removes 4 assertion lines of one kept function and moves no count), the oracle and s201's oracle pass (103 tests). `po-gate floor-guard` gives exactly the 4 `test-file-deleted` flags of task 1. No remaining test, script or workflow names a removed file or function.
- After: 168 files (4 deleted, the oracle added) and 675 functions (53 removed, 1 added).

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — only `tests/` and `docs/harnais.md` change |
| New screen | absent — `Surface: command` | absent |
| Authorization or tenant scope | absent — story text | absent — no `po/`, no `method/` |
| API contract | absent — story text | absent — no script output changes |
| New dependency | absent — story text | absent — bash and s201's helpers |
| Technical choice that deserves an ADR | absent — story text | absent. Every case falls under d-0051 or d-0052 |
| Defect to fix (`Fixes`/`Corrige`) | absent — `docs/stories.md:3330-3336` | absent |

## Story
The framing, installer and documentation tests keep only what a script reads (#207, last family), except the security tests the owner keeps. Criteria:
- `kept_assertions_have_a_reader` and `no_phrase_test_is_left`: read by a model, judged in review;
- `contract_tests_stay`, `no_script_lost_its_tests`, `suite_still_runs_clean`: read by a script.

## Reuse
The one piece of new code is the oracle's list of what must stay. It reuses `tests_defined` and the count of `tests/routing-phrase-tests-retired.oracle.test.sh:221-225,123-190`, sourced unchanged as `docs/harnais.md:154` says. Its shape is `tests/qa-and-design-phrase-tests-retired.oracle.test.sh`. Everything else is deletion.

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/framing-and-installer-phrase-tests-retired.oracle.test.sh` | `3879645666 32911` |

| Criterion | Test |
| --- | --- |
| `kept_assertions_have_a_reader` | — model-read (owner rule of 2026-11-13). The reviewer samples `## Classification` and opens each cited reader. The **S** rows have no reader: that is the exception the owner decided (d-0052). Candidate `po-eval` arm (#208). |
| `contract_tests_stay` | `test_contract_tests_stay`. It checks every function left in the 36 family files (`S204_KEPT`) and 233 lines (`S204_KEPT_LINES`). Those lines are every assertion of a kept function that reads prose: every **S** line, and the lines a script reads. It fails on the base until task 3 rewrites `hooks-installer-docs-cleanup.test.sh:51`. `po-lint` is run by s201's test of the same name. |
| `no_script_lost_its_tests` | s201's `test_no_script_lost_its_tests`, run against `origin/main` in every suite run. |
| `suite_still_runs_clean` | s201's `test_suite_still_runs_clean`, plus the full suite once through `po-run`. |
| `no_phrase_test_is_left` | — model-read: `## Outside the four families` and task 4. |

## Classification
**M** = read by a model only. **P** = read by a person only. **H** = a stop or checkpoint, removed and named for s206. **S** = security, kept (d-0052). **X** = reads a script's own file, kept (see `## The pivot`).

| File | Removed | Rule it pinned | Read by | Where it still lives |
| --- | --- | --- | --- | --- |
| `architect` | `:5`; `:13-16`; `test_…analyses_code_before_deciding`, `…records_structural_decisions_as_adrs`, `…never_rewrites_the_base` | base options; read code first; one ADR per choice; never propose a rewrite | model | `po-architect.md`, **M**. Kept: tool (Claude Code, `po-lint:125-160`), `:17` and both Step 4 functions **S** |
| `brief` | `:5`; `test_brief_runs_only_in_new_mode` | `Reads settings`; mode stops | model | **M** (#449); **H1** |
| `brief` | `test_interrogation_skill_…`, `…commits_approval_and_adr_together`; `:45-46` | interview skill; one commit; resume | model | **M** |
| `brief` | `test_brief_has_exit_criteria` | approved on criteria and agreement | model | **H3**. Kept: template `status:` (`framing.rs:39-52`); `…checks_before_writing_approved` **S** |
| `prd` | file (5) | mode stops; validation; template; probes; graveyard | model | **H1**, **H4**, **M**; `po` reads only `status:` |
| `stories` | file (7) | source by mode; approved source; slices; Owns; splits; Owns syntax | model | **H1**, **H2**, **M**; syntax → `overlap.rs`, `bounds:test_owns_accept_globs` |
| `stories-review` | `:4,6,9-11`; 5 functions | coverage; check 8; soft gate; non-goals; template | model | **M**; overlap at run time → `overlap.rs`. Kept: tools **S** (`po-lint:154`), preload (`po-lint` `skills_of`), `Stories ready:` (`framing.rs:82`) |
| `conversational-framing` | `:5-51`; `:56-59,61-63,65` | one item per question; criticals asked; started story | model | **H4**, **H5**, **H6**, **M**. Kept `:55` tool, `:60,64` **S** |
| `setup-modes` | `:5,10-12`; 2 functions | five questions; `Design source` not filled | model | **M**, **H7**; its `—` stop → `lane.rs:90`. Kept: names → `polype:627`, `po-lint:98`; values → `framing.rs:61`, `lane.rs:20,90` |
| `framing-commands-cleanup` | `test_stories_paths_agree`; `:25-28,38-39,43` | next lines; setup wording; ancestry stop | model | **M**, **H4**, **H8**. Kept **S** |
| `framing-realign…` | `:15-16,21-28,30-32,35-37` | realignment order | model | **M**. Kept `:29,34` **S** |
| `framing-through-pr` | `test_framing_pr_fast_forwards` | rebase merge; `MERGED`; human merge | model | **M**, **H8**, **H9**. Kept **S** |
| `adr-directory` | `:4-8,14-15`; 2 functions | `Reads settings` of ten files; no fixed path; table text | model, person | **M** (#449), **P**. Kept: name and default (`polype:627`, `po-lint:98`); mutation |
| `any-harness-docs` | file (3) | harness wording; issue template | person | **P** |
| `migration-doc` | file (4) | migration guide; its paths resolve | person | **P**; path check for #442 |
| `distribution-wiring` | `:5,7-13,16-34,38-138,147-168` (4 functions, and the rest of `test_rules_point_at_the_installer`) | install story; matrix; README paths | model, person | **M** (`method/AGENTS.md`, `po-help.md`), **P** (matrix, README), #442. Kept `test_readme_describes_the_pre_commit`, `test_rules_point_at_the_installer` **S** |
| `hooks-installer-docs-cleanup` | `:57`; README in `:51`; `:98-128` (3 functions) | template line; installation doc; ADR-0080; profile and doctrine | model, person | **M**, **P** (#442); `po-gate` behaviour stays in the same functions. Kept **X**; `test_hooks_say_what_they_do_scan_reads_the_base` **S** |
| `install` | `:106-109` | Law text on `.polype/templates/` | model | `install:test_install_copies_commands_agents_skills_templates` |
| `installer` | `:172-182` | upgrade section | person | **P**; `installer:test_update_lists_missing_settings`. Kept 2 doc functions **S** |
| `global-install` | `:118-129` | chezmoi path | person | **P** |
| `claude-md-setting` | `:41-46`; `:121-132` | setup asks; this repo's value; `Reads settings`; ADR-0089/0086 | model, person | **M** (#449), **P** (#442). Kept: block and values (`polype:623-629`); sentences **S** |
| `local-copy-checksums` | `:153-161` | state-files section | person | **P**; `test_local_sums_file_stays_out_of_git` |
| `update-keeps-mode` | `:6,99-100,113-121,156-165` | doc repair; setup step 3; wording; ADR-0091 | model, person | **M**, **P**; hints → `po-session` in the same functions. Kept **X** |
| `artifact-link-templates` | `:34` | record link line never edited | model | **M**; link lines → `po-link-artifacts:15` |
| `run-ledger` | `:156-157`, `agent` of `:155` | `-- '<Test>'` in the implementer | model | **M**; quoting → `po-gate`, `po-run` in the same function. Kept `:140-151` **S** |
| `readme-onboarding` | `:62-70` | prerequisites | person | **P**; bash guard → `test_old_bash_is_named`. Kept 2 **S** |
| `flow` | `:10-13` of `test_plan_flow_template_carries_verified_facts` | headings `## Verified facts`, `## Escalation signals`; words `path:line`, `150 lines` | model | `templates/plan-flow.md`, **M**. Kept `:8-9`: `track: flow` → `po` (`po/src/trust/signals.rs:89`), `po-link-artifacts` (`is_flow`); `validated: no` → `po-gate.sh:47`. Header `:2` stays true |

Unchanged: `lint` (mutations of `po-lint`), `installer-leftovers.oracle`, `defects-seen-on-products.oracle`, `commands-read-po-state`, `record-writes-reports` (scripts, word caps until s205), and the **S** files below.

## Rules the owner decides
**No new decision.** Every case falls under d-0051 or d-0052. A rule that is both a stop and a security rule is kept.
- **Removed, named for s206** (the rule itself):
  - **H1** `/po-brief` stops when `Entry mode` is `replace` or `adapt` and names `/po-prd`; `/po-prd` stops when it is `new` and names `/po-brief`; both, and `/po-stories`, stop when it is `—`.
  - **H2** `/po-stories` takes as its source only a PRD or a brief whose frontmatter says `status: approved`, and refuses one still at `status: interviewing` as if it were missing.
  - **H3** `/po-brief` writes `status: approved` only once every exit criterion holds, the person's agreement among them.
  - **H4** Each framing command puts its items to the person one per question (Approve / Change / Set aside) and writes an item only once it is approved; `/po-prd` writes nothing into `docs/prd.md` before the person validates it.
  - **H5** `/po-stories-review` puts each critical finding to the person, one per question (Fix / Accept the risk / Set the story aside); an accepted finding stays open in the report, and majors and minors are not asked.
  - **H6** A story sent back by the review that has already started (a `story/<id>` branch or a research file) stops `/po-stories`, which does not reopen it.
  - **H7** `/po-setup` never fills `Design source` on the person's behalf.
  - **H8** On GitHub, a framing branch counts as merged only when its pull request reads `MERGED`; with `gh` missing or logged out the landing stops, since ancestry is never the proof.
  - **H9** Under an effective `Ship confirmation: human`, a framing landing stops once its pull request is open and a person merges it; under `Merge mode: local` it asks Merge / Not now first.
- **Kept as they are**, by file and function:
  - `architect`: `test_architect_asks_for_the_base` (`:17`), `test_architect_merges_conventions_instead_of_replacing`, `test_architect_protects_the_settings_blocks`; `brief`: `test_brief_checks_before_writing_approved`; `stories-review`: `test_stories_reviewer_is_read_only_without_shell`; `conversational-framing`: `test_stories_review_surfaces_criticals_only` (`:60,64`).
  - `framing-commands-cleanup`: both functions; `framing-realign-and-orchestrator-log`: `test_every_landing_realigns_the_root` (`:29,34`); `framing-through-pr`: `test_framing_commits_on_a_branch`; `distribution-wiring`: `test_readme_describes_the_pre_commit`, `test_rules_point_at_the_installer`; `hooks-installer-docs-cleanup`: `test_hooks_say_what_they_do_scan_reads_the_base`.
  - `installer`: `test_installation_doc_lists_the_hook_refusals`, `test_installation_matches_the_hook`; `claude-md-setting`: `test_adr_records_the_choice` (`:133-140`); `run-ledger`: `test_implementer_runs_checks_through_po_run`, `test_fix_run_keeps_the_runs`; `readme-onboarding`: `test_existing_config_is_explained`, `test_install_doc_tells_the_truth`.
  - Whole files: `bounds`, `bounds-messages`, `install-collisions`, `no-claude-md`, `payload-kept-outside`, `payload-refuses-foreign-files`, `security-findings-stay-private`, `decision-inbox`, `answer-comes-back`.

## The pivot
Four kept tests read a script's own file, not prose a model follows:
- `hooks-installer-docs-cleanup`: `test_hooks_say_what_they_do_no_squash` (the text of `po-gate.sh`) and `test_hooks_say_what_they_do_env_word_forks_none` (the code of `po-bounds.sh`);
- `update-keeps-mode`: `test_session_comment_says_why` and `test_session_comment_reads_once` (the comments of `po-session.sh`).

They are classed **X**: a test of a script, changed with that script. The count sees each one as a launch, so removing them would lower `po-gate.sh` to 135, `po-bounds.sh` to 47 and `po-session.sh` to 23. That needs a `LOWERED_COUNTS` line outside `Owns`. **How it could be wrong**: if the reviewer holds that a script's comment is a phrase no script reads, the lead widens `Owns` to s201's oracle and these four go with one `LOWERED_COUNTS` line each. Nothing else depends on it.

## Outside the four families
Of the 171 files, 66 are in no family's `Owns` now that `flow` joined s204's. None holds a phrase test:
- **Launch a script and check what it does**: `answer-comes-back.oracle`, `artifact-links-backfill`, `ci-on-every-pr`(`.oracle`, also `ci.yml`, read by GitHub Actions), `commands-read-po-state.oracle`, `decision-inbox.oracle`, `driver-next-action`(`.oracle`), `eval-arms-same-environment`, `evals`, `failing-check-files-an-issue`, `first-release-holds`(`.oracle`), `held-says-what-collides.oracle`, `inbox-guards-bite`(`.oracle`), `intake-title-bounded.oracle`, the four `journey-*`, `next-names-the-track`(`.oracle`), `next-waits-on-dependencies.oracle`, `orphan-copy-survives`(`.oracle`), `po-change-needs-a-version`(`.oracle`), `po-prebuilt-and-verified`(`.oracle`), `rebuilt-helper-single-defect`, `record-review-loose-ends`(`.oracle`), `record-writes-reports.oracle`, `reuse-ladder-eval`, `run-from-outside`(`.oracle`), `session-shows-what-waits.oracle`, `ship-builds-the-landing-commit`(`.oracle`), `ship-cleans-the-lane`(`.oracle`), `ship-files-open-findings`(`.oracle`), `ship-lands-through-a-pull-request`(`.oracle`), `ship-order-and-closed-pr`(`.oracle`), `ship-reads-the-forge`(`.oracle`), `stale-decisions-are-flagged`(`.oracle`), `state-as-json`(`.oracle`), `state-carries-session-lines.oracle`, `suite-keeps-the-working-po.oracle`, `trust-signals`(`.oracle`), `verbs-read-project-context.oracle`.
- **Word caps until s205**, beside script tests: `delegating-commands-are-briefs.oracle`, `drive-executes-next.oracle`, `drive-takes-one-story.oracle`, `own-context-commands-are-briefs.oracle`, `security-findings-stay-private.oracle`, `ship-files-the-other-findings.oracle`, and the caps in `ship-cleans-the-lane.oracle`, `ship-files-open-findings`, `ship-lands-through-a-pull-request`. The first and fourth also check a `Reads settings:` line exists, which `po-lint:98-103` requires. `drive-takes-one-story.oracle` also checks that no file names a removed command: a name, not a rule's wording.
- `overlap`: ADR-0006, text that must not be copied.

## Tasks
1. [x] Delete `tests/prd.test.sh`, `stories.test.sh`, `any-harness-docs.test.sh` and `migration-doc.test.sh`. Test: s201's `test_suite_still_runs_clean`.
2. [x] Edit the framing files. In each file, first replace whole lines, then delete lines from the bottom up:
   - `architect.test.sh`: delete `:5,13-16,19-49`;
   - `brief.test.sh`: `:2` → `# s13 — brief command and template.`; delete `:5,11-42,45-46,50-58,72-84`;
   - `stories-review.test.sh`: `:2` → `` # s15 — stories review: the subagent's tools and the template's verdict lines. ``; delete `:4,6,9-11,21-36,44-81`;
   - `conversational-framing.test.sh`: `:2` → `# s101 — the stories review asks with its own tool and never edits the stories or a verdict (ADR-0074).`; `:54` → `  local review="$CMDS/po-stories-review.md"`; delete `:5-51,56-59,61-63,65`;
   - `setup-modes.test.sh`: `:2` → `# s11 — framing settings in the settings template.`; delete `:5,10-12,28-42`;
   - `framing-commands-cleanup.test.sh`: `:2` → `# s124 — the framing landing never commits to or pushes the target branch, and no framing command commits a CLAUDE.md.`; delete `:8-21,25-28,38-39,43`;
   - `framing-realign-and-orchestrator-log.test.sh`: `:2` → `# s121 — realigning the root forces nothing, and a merged framing branch is deleted only by its own next landing.`; delete `:15-16,21-28,30-32,35-37`;
   - `framing-through-pr.test.sh`: `:2` → `# s106 — a framing command commits only on its framing branch and pushes nothing else.`; delete `:46-56`;
   - `adr-directory.test.sh`: delete `:4-8,14-15,18-32`.
   - Test: those files, focused.
3. [x] Edit the installer and documentation files, the same way:
   - `distribution-wiring.test.sh`: `:2` → `# s39 — the rules point at the installer, and the README tells the pre-commit's refusals as po-gate holds them.`; delete `:5,7-13,16-34,38-138,147-168`;
   - `hooks-installer-docs-cleanup.test.sh`: `:2` → `# s127 — hooks and installer keep no trace of an older behaviour.`; `:51` → `  for f in "$GATE"; do`; delete `:57,98-128`;
   - delete `install.test.sh:106-109`, `installer.test.sh:172-182`, `global-install.test.sh:118-129`, `claude-md-setting.test.sh:41-46,121-132`, `local-copy-checksums.test.sh:153-161`, `update-keeps-mode.test.sh:6,99-100,113-121,156-165`, `artifact-link-templates.test.sh:34`, `readme-onboarding.test.sh:62-70`;
   - `run-ledger.test.sh`: `:155` → `  local err rest`; delete `:156-157`;
   - `flow.test.sh`: delete `:10-13`; lines `:1-9,14`, the header included, stay as they are.
   - Test: those files, focused, and the oracle.
4. [x] Append to `docs/harnais.md` the section `## Ce que la suite prouve depuis #207`, in French, with these paragraphs:
   - Opening: s201 to s204 removed from `tests/` every test that looked in `method/`, `docs/` or `README.md` for a phrase no script reads. What remains proves:
     - script behaviour on throwaway repositories (`po`, `po-gate`, `po-run`, `po-bounds`, `po-session`, `po-intake`, the pre-commit, `po-lint`, `po-link-artifacts`, `bin/polype`, `po-ci`, `po-eval`, `po-release`, `po-version-check`), watched by the launch count;
     - the replayed journey;
     - the contracts a script or the harness reads: template settings, tools and frontmatter, the fields `po` and `po-gate` read (`validated:`, `track:`, `Tree:`, `Ship allowed:`, `Stories ready:`, the `status:` of a brief or a PRD), template link lines, `.github/` workflows;
     - word caps until s205; `tests/overlap.test.sh` (ADR-0006);
     - four tests that read a script's own file (`## The pivot`);
     - no file of `tests/` looks any longer for a phrase no script reads, apart from the security exception below and those four.
   - **Exception du porteur (d-0052)**: the security phrase tests stay until s206's real run, which says for each whether a script or a case holds it. Name the nine whole files of `## Rules the owner decides` and say that the other kept functions are named in the plans of s202 to s204 and pinned by their oracles.
   - **Ce qu'elle ne prouve pas**:
     - that a model follows the prose: the checkpoint and stop rules removed are named in s206's criteria, and the rest is judged in review, a candidate for a `po-eval` arm (#208);
     - `README.md` and `docs/` are no longer read by any test, apart from what security keeps; their paths and the ADR registry wait for a check (#442);
   - **Ce que seul un produit prouve** (s203): `## What only a product proves` of `docs/plans/s203-qa-and-design-phrase-tests-retired.md`, translated, its ten bullets kept.
   - **Ce que seul un vrai passage prouve** (s204): no journey plays the framing, so only s206's real run tests the interview of `/po-brief` and `/po-prd`, approval one item per question, the stories review put to the person, and a framing landing through `framing/<slug>` and its pull request (`## Landing the framing` of `/po-setup`).
   - Test: none (a document); the reviewer reads it.
5. [x] Checks.
   - Run the oracle, `routing-phrase-tests-retired.oracle.test.sh` and the 21 edited files, focused.
   - Then run the full suite once through `po-run --story s204-framing-and-installer-phrase-tests-retired --label 'Unit suite' -- 'bash tests/run.sh'`, then `bin/po-lint method`.
   - Expect 171 → 168 files and 727 → 675 functions.
   - Expect `po-gate floor-guard s204-framing-and-installer-phrase-tests-retired origin/main` to give exactly the 4 `test-file-deleted` flags of task 1.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `method/`, `po/`, `bin/`, `boilerplates/`, `.github/`;
  - `docs/` except this plan, the record and `docs/harnais.md`;
  - `tests/lib.sh`, `tests/run.sh`, `tests/journey/`, `tests/routing-phrase-tests-retired.oracle.test.sh`, and every test file outside `Owns`.
- No assertion is added or reworded, apart from the two base lines fix run 1 restores word for word. The only rewritten lines are the headers, `conversational-framing:54`, `hooks-installer-docs-cleanup:51` and `run-ledger:155` of tasks 2 and 3. Every kept line keeps its text, the **S** lines included.
- The oracle keeps `3879645666 32911`. No `tests/framing-and-installer-phrase-tests-retired.test.sh` is created. No version bump. Nothing is left in `/tmp` or `${TMPDIR}`.

## Files touched
- Deleted (4): task 1.
- Edited (21): tasks 2 and 3, `flow.test.sh` included. Written: `docs/harnais.md`, the oracle, this plan.
- Unchanged in `Owns`: `install-collisions`, `installer-leftovers.oracle`, `no-claude-md`, `payload-*` (3), `lint`, `bounds`, `bounds-messages`, `defects-seen-on-products.oracle`, `commands-read-po-state`, `record-writes-reports`, `security-findings-stay-private`, `decision-inbox`, `answer-comes-back`.

## Test strategy
One oracle test, within `Test budget` 25. The other three criteria a script reads are held by s201's tests, on this tree. Everything else removes assertions.

## Done when
- The focused files and the oracle pass. The full suite passes once through `po-run`. `po-lint` is clean.
- The reviewer samples `## Classification`, checks that floor-guard gives only the 4 expected flags, judges `## The pivot` and accepts the d-0052 exception.
- The implementer makes one commit with this plan.
