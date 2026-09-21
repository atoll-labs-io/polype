# Review — s24-architect-conventions

Diff reviewed: `git diff m3-flotte...story/s24-architect-conventions`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `bash .polype/hooks/po-gate.sh verif-current s24-architect-conventions` → exit 0; `git diff --quiet f9d5733 HEAD -- . ':(exclude)docs'` also exit 0. `Verification mode: record`, so I reused `docs/verif/s24-architect-conventions.md`: unit suite `bash tests/run.sh` exit 0, 135 passed, 0 skipped (includes `overlap.test.sh`, ADR-0006). Not rerun here.
- [x] `Typecheck`, `E2E`, `Build` are `—` in `AGENTS.local.md`: the project has none, so none was run and none is substituted.
- [x] Record's "Not proven here" read: it explicitly defers the mutation run to this review, which I performed below.

## Plan
- [x] Tasks 1–6 all present in the diff. Task 1–3 → `method/commands/po-architect.md:49,51,53`; task 4 → `:62`; task 5 → `tests/architect.test.sh:52-86`; task 6 → `docs/defauts.md:15-16`.
- [x] Run interdicts, one by one: `.claude/` and `.polype/` — empty diff, installer not run; `method/commands/po-setup.md`, `method/templates/agents-local.md`, `tests/structure.test.sh`, `tests/wiring.test.sh` — empty diff; `docs/parite-killer-saas.md` — empty diff; `docs/defauts.md` — only rows 7 and 8 changed; no new test file; `AGENTS.local.md` untouched.
- [ ] One file outside the declared scope: `tests/design-handoff.test.sh` is in the commit but in neither the plan's `Files touched` nor the story's `Owns` (finding 1).
- [x] One commit on `story/s24-architect-conventions`; `git status --porcelain` empty, no environment file.

## References
- [x] `section_of` is defined at `tests/architect.test.sh:8` (same file as the new tests, so in scope); `fail`, `require_file`, `contains` come from `tests/lib.sh:11,41,43`; `tests/run.sh` sources `lib.sh` then the test file, so all resolve.
- [x] The two headings the tests slice on exist verbatim: `## Step 4 — Conventions as rules` (`:48`, em dash) and `## Approval and commit` (`:60`). Each quoted phrase exists in the section it is greped from — proved by the mutations, none of which passed vacuously.
- [x] `docs/reviews/s16-architect.md:40,49` (the cited source of defects 7 and 8) and `docs/defauts.md:15-16` say what the plan's Verified facts claim.
- [x] No value only looks right: the change is prose and greps, no default, limit, format or status code.

## Rules
- [x] `AGENTS.md` conventions respected: method file in English, `Reads settings:` line unchanged, frontmatter unchanged (`AskUserQuestion` was already allowed), tests are bash `test_<name>` functions named exactly after the acceptance criteria, quoting short exact phrases. Straight double quotes around `"Approval and commit"` match the house style of `method/commands/*.md` (guillemets appear only twice across the directory).
- [x] The existing test `architect_analyses_code_before_deciding` still finds its phrase (`Write the conventions as rules in the `## Conventions` section of `AGENTS.local.md``) — the rewrite deliberately preserved that prefix.
- [x] No accepted ADR contradicted: ADR-0014 (grouped checkpoints) is honoured — the rerun difference is added to the single grouped question rather than becoming a second one; ADR-0012 (no red-first while implementing) is why the record has no mutation, correct; ADR-0006 covered by the suite.

## Tests
- [x] 2 new tests, budget 25. Assertions read the file under test; no mock, no fixture, no `catch`, no self-written query — none of the six empty shapes applies.
- [x] Bite, five mutations, each run on the affected test files only, each undone with `git diff --exit-code` clean afterwards:
  1. Step 4 reverted to its pre-story sentence (`Replace only that section's placeholder or body…`) → `architect.test.sh`: **2 failing** (`architect_merges_conventions_instead_of_replacing`, `architect_protects_the_settings_blocks`). This is exactly mutation 3 of `docs/reviews/s16-architect.md:40`, which used to fail 0 tests — defect 7 is now genuinely covered.
  2. Deleted only `Every settings block of `AGENTS.local.md` stays exactly as it is…` → `architect.test.sh` + `structure.test.sh` + `wiring.test.sh`: **1 failing** (`architect_protects_the_settings_blocks`).
  3. Deleted `On a rerun it also shows what the new conventions would remove or contradict…` from Approval point 2 → **1 failing** (`architect_merges_conventions_instead_of_replacing`).
  4. Moved the settings sentence out of step 4 into `## Never rewrite the base`, unchanged → **1 failing** (`architect_protects_the_settings_blocks`), so the guard is pinned to the step that writes the file, not to the file at large.
  5. `docs/defauts.md` row 7 back to `ouvert` → `design-handoff.test.sh`: **1 failing** (`defects_one_to_three_marked_fixed`).
- [x] Final state: `git status --porcelain` empty and `git diff --exit-code` clean — no mutation left behind.
- [x] No test made useless; the edit to `tests/design-handoff.test.sh` changes exactly the clause the story changes (rows 7 and 8) and its comment says so.

## Neighbours
- [x] `method/commands/po-setup.md:17` and `:41` ("`/po-architect`, which fills only its « Conventions » section", "Leave the conventions placeholder as it is") still agree with the new wording; `setup_never_overwrites_settings` passes under mutation 2.
- [x] `method/templates/architecture.md:52` points at the Conventions section of `AGENTS.local.md` without describing how it is written — unaffected.
- [x] `tests/wiring.test.sh:27` only lists `/po-architect` in the cheat sheet; no other test reads this command. The stale phrase `section's placeholder or body` now survives only in `docs/plans/`, `docs/verif/` and older reviews, where it is quoted history.
- [x] `method/commands/po-architect.md` Check 3 (`:21`, rerun = `docs/architecture.md` exists) now agrees with step 4 instead of contradicting it, which was the substance of defect 8.

## Findings
- minor — `docs/plans/s24-architect-conventions.md:59-63` and `docs/stories.md:364` — the commit changes `tests/design-handoff.test.sh`, listed in neither `Files touched` nor the story's `Owns`. The change is required (that test asserted rows 7 and 8 read `ouvert`, so task 6 would otherwise break the suite) and correct, and s23 did the same; the declaration, not the code, is what is wrong.
- minor — `method/commands/po-architect.md:49` — the no-delete protection is phrased on the rerun branch ("a rerun keeps every rule already written there"), while a rerun is defined at `:21` by the existence of `docs/architecture.md`, not by the state of the Conventions section. A *first* run in a repository where someone already wrote conventions by hand falls under "A first run replaces the placeholder of that section"; only the trailing general clause ("the section is never rewritten from scratch") saves those rules. Naming the placeholder's absence as the signal would close the case defect 8 describes.
- minor — `method/commands/po-architect.md:62` against `:49` — Approval point 2 offers to show "what the new conventions would **remove**", but step 4 now guarantees nothing is ever removed. Only the "contradict" half can happen; the "remove" half is vestigial wording that could suggest removal is still an option.

## Not verified
- **No live run of `/po-architect`**, with a base or on an empty repository. These tests prove the prompt states its rules, not that an agent obeys them — the recurring pattern recorded at `docs/defauts.md:21`. A person should run it twice on a scratch repository with hand-written conventions already in `## Conventions`, and check the diff of `AGENTS.local.md`: settings blocks byte-identical, earlier rules still present, new ones appended.
- **The contradiction path** (a rule the code now contradicts, a new rule contradicting an existing one) was never exercised: nothing shows the agent actually surfaces both in the grouped question rather than quietly picking one.
- **The installed copies** `.claude/commands/po-architect.md` and `.polype/` still carry the old "Replace only that section's placeholder or body" sentence; the run interdict rightly forbade running the installer, so the pipeline executing on this repository keeps the old rule until the next `bin/polype-dev-install .`. Someone should run the installer on `m3-flotte` after ship.
- **Full suite, `overlap.test.sh` and formatting** were taken from the current record, not rerun here; my own runs were the five scoped mutation runs only.
- **No screen**: this story has no design artefact, so no design-system conformity was assessed.
- The project defines no typecheck, E2E or build command, so none of those was run.

Max severity: minor
Ship allowed: yes
