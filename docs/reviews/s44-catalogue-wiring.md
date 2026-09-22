# Review — s44-catalogue-wiring

Diff reviewed: `git diff m4-catalogue...story/s44-catalogue-wiring` (one commit, a432e44), in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the diff with `git diff --name-only m4-catalogue...story/s44-catalogue-wiring` and checked each path against `Owns` (`method/commands/po-setup.md`, `method/commands/po-help.md`, `method/AGENTS.md`, `docs/parite-killer-saas.md`, `tests/catalogue-wiring.test.sh`).
- [x] Every path is inside `Owns`. The other two paths are the story's own evidence (`docs/plans/s44-catalogue-wiring.md`, `docs/verif/s44-catalogue-wiring.md`).
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows no other story worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s44-catalogue-wiring` exited 0. `git diff --quiet 11799f4… HEAD -- . ':(exclude)docs'` also exited 0.
- With `Verification mode: record`, I reused the record: focused tests exit 0 (39 passed), full suite `bash tests/run.sh` exit 0 (230 passed). The project has no type check, E2E or build command (`—`), so none ran. The record's "Not proven here" section says no real `/po-setup` run was made, and that the installed copies catch up at the next install.

## Plan
- [x] Tasks 1–5 are all present. Nothing was changed outside the plan.
- [x] Every run interdict holds:
  - `method/templates/agents-local.md`, `method/commands/po-architect.md`, `bin/`, `.claude/`, `.polype/` and the root `AGENTS.md` have an empty diff.
  - Step 2 still has exactly five numbered items, and "Nothing else is asked" stays.
  - The phrases guarded by the `structure` and `design-handoff` tests are untouched.
  - Only lines B03, C01 and C07 of the parity matrix changed.
  - No existing test was edited.
  - `overlap.test.sh` is green in the record.

## References
- [x] I opened each reference and confirmed it:
  - `boilerplates/next-forge/profile.md` exists, with a `## Commands` block and `Commit profiled:`.
  - `method/templates/profile.md` names the command block after the settings.
  - `po-architect.md` step 1 defines a base with the same wording that `po-setup.md:26` copies.
  - The `## Conventions` placeholder exists in `method/templates/agents-local.md:72-74`.
  - `docs/catalogue.md` already says setup takes the commands from the profile.
- [ ] One value only looks right: the profile's command block carries no `Package manager` (see minor finding 1).

## Rules
- [x] The `AGENTS.md` conventions are respected: method text in English, the help line in French, tests are bash using `lib.sh` helpers, parity status cells use `fait — <path>`.
- [x] No accepted ADR is contradicted. ADR-0008 (a profile catalogue that pre-fills commands) is what this story implements.

## Tests
- [x] There are 4 tests, one per criterion and named after it. None of the six empty test shapes applies: each test reads the real file under test.
- [x] 4 tests against a budget of 25.
- [x] Bite checks. After each change I ran only `catalogue-wiring.test.sh`, then restored the file and confirmed it with `git diff --exit-code`:
  - I flipped "When step 1 found no base" to "found a base" in `po-setup.md`: 1 test failed (`setup_offers_the_catalogue`). Restored.
  - I set C01 in the matrix back to `partiel — … ; boilerplate en M4`: 1 test failed (`parity_matrix_reflects_the_catalogue`). Restored.
  - I deleted the sentence that turns the chosen profile's command block into the suggestions for question 5: 1 test failed (`setup_offers_the_catalogue`). Restored.
  - The final `git diff --exit-code` and `git status --porcelain` were both clean.
- [x] The story makes no test useless.

## Neighbours
- [x] `po-architect.md` Step 4 still works with the line setup now writes. The placeholder is already gone, and "a convention written by hand is not this command's to delete" protects the line. Architect Step 1 already looks for the profile, so the claim in `method/AGENTS.md` ("starts its reading from that profile") holds.
- [x] The setup-modes, structure, design-handoff and pilot tests are green in the record.

## Findings
- minor — `method/commands/po-setup.md:39`: the profile's command block has no `Package manager` line. In a project that picks a profile but has no lockfile yet (for example next-forge on bun), setup suggests `Package manager: —`, which means "this project has none", and that is wrong. The person can correct it at question 5. The fix belongs in `method/templates/profile.md` or in a sentence in setup, and the template is outside this story's `Owns`.
- minor — `method/commands/po-setup.md:30` and `:2`: the Step 2 heading ("Five questions … plus one follow-up on design") and the frontmatter description ("five answers") do not mention the new catalogue offer. The body at line 41 does.
- minor — `method/commands/po-setup.md:45`: setup writes the profile line into `## Conventions` in place of the placeholder. `po-architect.md` Step 4 still describes a first run as one that "replaces the placeholder". The general "never rewritten from scratch" clause makes the behaviour correct, but the wording does not foresee this case. `po-architect.md` is off-limits to this story.

## Not verified
- I did not run `/po-setup` on an empty repository with Polype's catalogue available, so the actual flow is untested: the profile offer, the pre-filled question 5, the conventions line and the closing advice. A person should run `/po-setup` once in an empty scratch repository and pick next-forge, then run `/po-architect` after bringing the boilerplate in at `Commit profiled`. They should check that the conventions line survives and that the architect starts from the profile.
- I did not check the "catalogue cannot be reached" branch in practice: setup running in a project where Polype's repository is not reachable.
- The installed copies (`.claude/`, `.polype/`, the root `AGENTS.md`) are deliberately unchanged, and nothing proves they will pick up the new text at the next install. A person should run `bin/polype-dev-install .` after the ship and check the diff.
- The project has no type check, E2E or build command (`—` in `AGENTS.local.md`), so none of those ran.

Max severity: minor
Ship allowed: yes
