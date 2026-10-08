# Stories review: Polype, milestone "M8 bis — Les restes de M8" (s93–s98)

This is a one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). It was done in a context that did not write the stories, on 2026-10-08, against `/home/lecrabe/dev/atoll/polype/docs/stories.md` lines 1408–1499.

- **Scope source:** the findings named on each story's `Corrige` line, in `/home/lecrabe/dev/atoll/polype/docs/reviews/s76…s92-*.md`.
- **Platform:** `cli` (`AGENTS.local.md:19`).
- **Shape:** follows `/home/lecrabe/dev/atoll/polype/docs/reviews/stories-m8.md`.
- **Severity:** findings are rated critical, major or minor.

Review status: complete

## Coverage
Every major finding left by the M8 reviews (s76–s92):

| Scope item (major finding) | Source | Covered by | Covered |
| --- | --- | --- | --- |
| `QA stage: surfaces` was offered while nothing acted on it, and `agents-local.md` said "`/po-qa` … stops on `—`" | s78, finding 1 (all three loops) | none needed: s79 and s80 shipped it. `method/templates/agents-local.md:54` and `method/AGENTS.md:41` now route `surfaces`, and the "stops on `—`" phrase is gone from `method/` | yes (already closed) |
| No stop when no driver row matches the surface and platform, or when `Platform` is missing or `—` | s79 #1 | s93 `no_driver_row_blocks` | yes |
| The scenarios driver blocks on its own transcripts (no `docs/qa/<id>/` exception) | s81 major 1 | s93 `own_evidence_never_blocks` | yes |
| The lib scratch script must be written through Bash | s81 major 2 | s93 `own_evidence_never_blocks` | yes |
| Three scenario rules can be deleted with no test failing | s81 major 3 | s93 `scenario_rules_bite` | yes |
| The iOS `Test` command exits 0 on red tests | s85 F1 | s95 `test_commands_fail_on_red` | yes (ADR gap, see findings) |
| The scene driver and the plan template disagree on the fields of a viewpoint | s87 major | s94 `viewpoint_lines_match_the_plan` | yes |
| Simulation processes are never reliably stopped, and the leftover check cannot see them | s88 major | s94 `simulation_leaves_nothing_running` | yes |
| `/po-retro` matches milestones by prefix only | s89 major | s97 `retro_prefers_an_exact_milestone` | yes |
| `diagnostic` runs only on the fleet planner's path | s90 major 1 | s96 `every_path_runs_the_diagnostic` | yes |
| "No root cause found" research is re-planned or re-dispatched | s90 major 2 | s96 `no_root_cause_goes_to_a_human` | yes for `/po-drive`; partly elsewhere (minor below) |
| `docs/defauts.md` was changed outside s92's Owns | s92 major | s97 `stories_review_checks_owned_records`, a preventive check | yes, as a process fix: s92 itself is already shipped |

s76, s77, s80, s82, s83, s84, s86 and s91 have no major finding. **No major finding of the M8 reviews is left without a story.**

One criterion traces to no named finding: s96 `implementer_model_follows_the_rescore`. It is not in s90's majors, not in s80's minor, and I found no "Light up to" or rescore finding in any s7x–s9x review (see findings).

Minors that no story delivers, even though some are claimed on a `Corrige` line:
- s77 m2: header line wrap in `po-bounds.sh`.
- s81: the `--ignored` listing collapses already-ignored directories.
- s86 #2: `head`/`tokens` style in `cli-api-profiles.test.sh`.
- s90 #4: the planner's `Fixes` clause is unpinned.
- s90 #5: "the planner writes only research and plan".
- s92 minors 1 and 2. s97's `Corrige` claims these, but no criterion delivers them and neither `method/templates/review.md` nor `tests/review-tree-gate.test.sh` is in its Owns.

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| none named: the caller gave no kept-out list, and the review files exclude nothing | — | — | — |

## Checks
- [x] Exclusions: none to check.
- [x] No technical layer dressed as a story. These are method stories; each names a behaviour a bash test can quote.
- [ ] Every criterion can be checked by one test. s95 `profile_slips_are_fixed` names no phrase (minor).
- [x] Dependency order: all six say `aucune`.
- [x] Complexity: 2 or 3 throughout. No 4, no 5.
- [x] Ids: `s93`–`s98`, form `s<number>-<slug>`, unique, increasing after s92.
- [x] Surface: all `—`, which `cli` admits.
- [x] Owns: every story declares one. I compared every pair entry by entry, folders as `x/**`, and found **no overlap**:
  - The `qa-drivers/` files are split: s93 has `SKILL.md` and `scenarios.md`; s94 has `scene.md` and `simulation.md`.
  - Each `boilerplates/*` folder has one owner: s95 holds native-ios, native-android, expo and rust-cli; s94 holds `godot/profile.md`.
  - Each test file has one owner.
  - `tests/lib.sh` and `tests/run.sh` are held by s95 alone.
  - No `.worktrees/` lane is in flight.

  Several stories still need paths that sit in no Owns, or in another story's Owns (findings below). Adding those paths as written would create overlaps, which would be critical because none of these stories depends on another.

## Findings
- **major — s98, ADR file outside Owns.** The rule s98 lifts is written in ADR-0050, not ADR-0052. `docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md:39` says "en mode `implementer`, `switch`, `checkout`, `stash` … sont refusés", and ADR-0050 is `accepted` with `superseded-by: []`.
  - s98 owns ADR-0052 and ADR-0053 but not ADR-0050. Its new ADR must name ADR-0050 in `supersedes`, and ADR-0050's `superseded-by` must change (Law 6). po-bounds would refuse that edit.
  - Add ADR-0050 to the Owns. ADR-0053 looks unneeded unless the plan has a reason for it.
- **major — s98, texts that forbid what the hook will allow.** Three texts still forbid `checkout` outright:
  - `method/agents/implementer.md:23` ("never checkout, switch or stash");
  - the implementer prompt in `method/commands/po-execute.md:42` ("never checkout or stash");
  - `docs/installation.md:86` ("partout : `git switch`, `checkout` …").

  Without a qualifying clause, an implementer told "never checkout" will not use the new throwaway-clone allowance, so the criterion's goal ("l'exploration … ne soit plus bloquée") is not reached. s98 owns none of these files.
  - `implementer.md` and `docs/installation.md` can be added safely.
  - `po-execute.md` is owned by s96, so adding it to s98 is an overlap: make s98 depend on s96, or move the prompt clause into s96.
- **major — s95, accepted ADRs it reverses.**
  - `ADR-0064…md:31` decides "iOS garde `Test: bundle exec fastlane buildAndTest` … `failBuild: false`".
  - `ADR-0062…md:25` decides "avec `Test: npx jest`".

  `test_commands_fail_on_red` overturns both. That needs a new ADR that supersedes them (in part) and a `superseded-by` link in each old file. s95 owns neither ADR-0064 nor ADR-0062.
- **major — s95, grounding tests owned by s94.** `skipped_grounding_is_visible` covers "un test d'ancrage de profil". Seven test files print the same stderr skip note:
  - five owned by s95: next-forge, cli-api, expo, flutter, native;
  - two owned by s94: `tests/godot-scene-driver.test.sh:108` and `tests/ros-simulation-driver.test.sh:112`.

  A `skip` helper in `lib.sh` that every test must call would make s95 edit s94's files: refused by po-bounds, or an overlap if those files are added. Fix it one of two ways:
  - write in a note that `tests/run.sh` detects the existing `not reachable: grounding not checked` marker, so no test file has to change; or
  - make s95 depend on s94 and add the two files.
- **major — s96, `implementer_model_follows_the_rescore`.**
  - It traces to no finding named on s96's `Corrige` line.
  - It cannot be built inside the Owns. On the short track there is no research file, and `method/templates/plan-flow.md` has no place for a complexity score. `po-execute.md:34` falls back to `docs/stories.md`.
  - Writing the planner's score into the plan needs `method/templates/plan-flow.md`, which s94 owns (adding it is a critical overlap without a dependency), and `method/agents/planner.md`, which no story owns.

  Drop the criterion, or name its source, add `planner.md`, and make s96 depend on s94 for `plan-flow.md`.
- **minor — s96.** `no_root_cause_goes_to_a_human` closes the `/po-drive` path only:
  - `method/agents/planner.md:42` ("Research already on disk — read it, build the plan on it") and `method/commands/po-plan.md` will still build a plan on a no-root-cause research. Neither is owned.
  - How `/po-drive` recognises "no root cause" needs a fixed line, which the `diagnostic` skill (owned) can define. `templates/research.md` is not owned.
  - `ADR-0068…md:33` (Neutral) says `/po-research` does not preload the skill. After s96 that is false. Superseding it would need ADR-0068, which is not owned.
- **minor — s96.** It rewrites `po-drive.md`, `po-flow.md`, `po-orchestrator.md` and `po-execute.md`, whose phrases are also pinned by tests it does not own:
  - `tests/surface-routing.test.sh:35` (s94) expects exactly 3 resume rows routed by "goes to QA";
  - `tests/qa-fleet.test.sh:153-162`;
  - `tests/resume.test.sh`, `tests/fleet-design.test.sh`, `tests/grouped-validation.test.sh`, `tests/owns-overlap.test.sh`.

  Changes must be additive. Say so in a note.
- **minor — s97.**
  - `po-help.md:31` is pinned by `tests/qa-fleet.test.sh:96-97`, which s97 does not own. Keep the pinned phrases.
  - `retro_prefers_an_exact_milestone` changes "open by the last review", a phrase that `ADR-0067…md:30` also states ("ouvert selon la dernière revue"). The ADR text becomes inexact.
- **minor — s97.** `stories_review_checks_owned_records` names `docs/defauts.md`, a path specific to Polype, inside a method skill. Word it as "the file its `Fixes` line names", so it holds for a project's own defect record.
- **minor — s97, `Corrige` overclaims.** It claims "mineurs de … `s92-review-tree-gate.md`" with no criterion and no owned file for them (see Coverage).
- **minor — s94.** `method/agents/reviewer.md:32` lists what a viewpoint carries ("what each must show, its framing, scale and light"). If the plan templates' fields change to scene, position, target and framing, the reviewer text may drift, and s94 does not own it. Keeping the existing fields and adding the new ones avoids this.
- **minor — s95.** The natural home of the new lint cases (`QA driver: —`, `mobile-web` with `Dev: —`) is `tests/qa-drivers.test.sh` (`profiles_declare_their_driver`), but s93 owns that file. The tests must go into `tests/profile.test.sh` or `tests/platform-setting.test.sh`. Say so in a note.
- **minor — s95.** `profile_slips_are_fixed` names no phrase. List the four slips so one test can pin them:
  - s85 F3: xcbeautify "latest"; the `customizer.sh` deletions; Android `ui/<feature>/` ownership;
  - s86 #1: `utils/Cargo.toml` target section.
- **minor — s93, s94, s95, s96, s98.** None owns a `tests/<story-slug>.test.sh`, the file the repository convention asks for (`AGENTS.local.md`, Conventions). s97 owns `tests/final-texts.test.sh`, which does not exist yet and is not its slug. A planner that follows the convention would be refused by po-bounds. Add the file, or write in a note which owned test file takes the new functions.
- **minor — milestone.** No M8 bis story has a "Notes pour l'agent" section. The pins and constraints above belong there.

## Not verified
- **Where s98's third `Corrige` source is recorded.** It cites "refus de `git checkout` relevés par les lanes de s84 et s85". No review, verif or research file of s84 or s85 records such a refusal; only `docs/plans/s85-native-profiles.md:52` plans a `checkout` in a temp clone. I could not hold the criterion against a written source.
- **Whether a test in the full suite enforces "every setting named in a file's body is listed in its `Reads settings:`".** It matters for s93's `Install`/`Build`. I read only `qa.test.sh:41` and `tests/lib.sh` by reference.
- **Whether `po-bounds` in implementer mode applies the verb ban regardless of `-C`.** I read only `po-bounds.sh:736-750` by search. This is the mechanism s98 changes.
- **The internals of `bin/po-lint` `check_profiles`, and how s78's three lint branches would be tested.** I relied on the s78 review's bite results.
- **The suite and `bin/po-lint` were not run.** I read tests only by search, except `tests/run.sh`.
- **M8 bis Owns against stories outside the milestone.** I compared them only with each other; no lane is in flight under `.worktrees/`.
- **Minor findings of the M8 reviews.** I traced them against the `Corrige` lines but checked them less closely than the majors, so the list of uncovered minors may not be complete.

Max severity: major
Stories ready: yes

> Answered at the next commit: s98 owns ADR-0050, `implementer.md` and `docs/installation.md`, and depends on s96, which now carries the `/po-execute` prompt clause; s95 owns ADR-0062 and ADR-0064 and relies on the existing skip marker in `tests/run.sh`; s96 drops `implementer_model_follows_the_rescore` and owns `planner.md`, `po-plan.md` and ADR-0068; s97 no longer claims s92's minors and words its check on the file a `Fixes` line names; each story owns a `tests/<slug>.test.sh`; notes carry the pins.
