# Review — s31-fleet-wiring

Diff reviewed: `git diff m3-flotte...story/s31-fleet-wiring`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s31-fleet-wiring` → passes (exit 0). `git diff --quiet bbffcfc HEAD -- . ':(exclude)docs'` confirms it independently. `Verification mode: record`, so the record's `bash tests/run.sh` (exit 0 · 161 passed) and `bash bin/po-lint` (exit 0) are reused, not rerun. Type check, E2E and build are `—` in `AGENTS.local.md`: the project has none, and I substituted nothing.
- Its "Not proven here" section is accurate: no bite proof was attempted by the implementer (correct — ADR-0012), runtime behaviour of `/po-drive` and `/po-status` is unproven, and the installed copies under `.claude/`/`.polype/` were deliberately left stale.
- I did run `bash tests/run.sh` once at the end of my own mutation work, purely to prove my mutations were undone: 161 passed, 0 failed.

## Ownership
- [x] `git diff --name-only m3-flotte...story/s31-fleet-wiring` touches exactly `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`, `docs/parite-killer-saas.md`, `tests/fleet-wiring.test.sh` — all five on the story's `Owns` line (`docs/stories.md:460`) — plus `docs/plans/s31-fleet-wiring.md` and `docs/verif/s31-fleet-wiring.md`, this story's own pipeline evidence, in scope by construction. Nothing outside, nothing inside another running story's `Owns`.

## Plan
- [x] Task 1 (fleet subsection in Law 1) — present, `method/AGENTS.md:44-48`, three claims in the method's own words.
- [x] Task 2 (`/po-drive status` in the help) — present, `method/commands/po-help.md:32`, French, nested under the `/po-drive` entry the same way `/po-design` nests under `/po-research`.
- [x] Task 3 (fleet step in `/po-status`) — present: `Parallel` and `Max attempts` added to the `Reads settings:` line (`:11`), new step 4 (`:32-37`), steps renumbered 5 and 6. Both new names exist in `method/templates/agents-local.md:29-30` with their rows at `:55-56`, so `tests/structure.test.sh` and `bin/po-lint`'s `settings` rule are satisfied.
- [x] Task 4 (five status cells) — A02, D09, D16, D17 flipped to `fait — …`; D05 left as it already was; D17's Polype cell rewritten. No other row touched. See findings 1 and 2.
- [x] Task 5 (`tests/fleet-wiring.test.sh`) — present, header as specified, one `test_<criterion>` per criterion.
- Run interdicts, one by one: `.claude/`, `.polype/` and the root `AGENTS.md` — empty diff, confirmed. `docs/decisions/` — empty diff, confirmed. No existing test file edited (only `tests/fleet-wiring.test.sh` added); `pilot.test.sh` and `wiring.test.sh` green untouched. `docs/stories.md` and `docs/milestones.md` — empty diff. Parity rows other than A02/D05/D09/D16/D17 — empty diff (the matrix diff is exactly 4 changed rows). `git status --porcelain` lists no environment file.
- Nothing in the diff is outside the plan.

## References
- [x] `Parallel`, `Max attempts` → `method/templates/agents-local.md:29,30` and the values table `:55,56`. Confirmed.
- [x] "read the way `/po-drive` reads it (`method/commands/po-drive.md`)" → `po-drive.md:56` does define it (from `docs/reviews/<id>.md`'s `Fix loop:`, never from session memory), which in turn points at `po-review.md`. The chain resolves.
- [x] `git -C <path> rev-parse --abbrev-ref HEAD` prints `story/<id>` for a checked-out branch and `HEAD` when detached — the prescribed command does what the text claims. See finding 3 for what it does *not* do.
- [x] A02/D09's new citation `method/skills/review-antihallu/SKILL.md` → the ownership section really is there (`:9-20`, added by s28). D16's `method/commands/po-drive.md` → grouped validation really is there (`:79-94`). D17's `method/commands/po-status.md` → the new step 4.
- [x] `method/agents/reviewer.md:24` says "step 4 of the procedure" — that is the six-step skill, not `/po-status`'s numbered steps, so the renumbering breaks no cross-reference. `bin/po-lint`'s `fail-closed` rule only scans `## Checks|Preconditions|Step 0` sections (`bin/po-lint:160`), so `/po-status`'s steps are outside its scope regardless.
- [x] No value that only looks right: no number, status code, limit or default is introduced; `Parallel`/`Max attempts` are read, never fixed.

## Rules
- [x] `AGENTS.md` conventions respected: method files in English, `Reads settings:` line lists every new setting in backticks, `templates/<name>.md` convention untouched, the story is one commit on `story/s31-fleet-wiring`.
- [x] The new AGENTS.md prose does not contradict `po-drive.md`: "ships stay serial … in the order the reviews passed" matches `po-drive.md:103`; "two stories sharing one of those paths never run at once — the second waits for the first to ship" matches `po-drive.md:37,108`.
- [ ] No accepted ADR contradicted — **not clean**: see findings 1 and 2. The D17 rewrite follows ADR-0016, which is `status: proposed`, while ADR-0003 is still `accepted` with `superseded-by: []`.

## Tests
- [x] Four tests, one per acceptance criterion, well inside `Test budget: 25`.
- [x] None of the six empty shapes. I checked the scoping helpers rather than only the assertions: `section_of` really stops at the next `## ` (`### The fleet` stays inside Law 1), and `step_of` really returns only the 6 lines of step 4 — so the `holds` assertions cannot be satisfied by text living elsewhere in the file. `contains`/`holds` are `grep -qF`, exact and literal, so a reworded clause turns red.
- [x] The parity assertion rejects `partiel`: the `case` matches `"fait — "*` only, and I confirmed by mutation.
- Bite, six mutations, each followed by `tests/run.sh fleet-wiring.test.sh` only:
  - delete the "Two limits keep the parallelism honest…" paragraph of `method/AGENTS.md` → **1 failing** (`rules_describe_the_fleet`: "Law 1 lacks: **Ships stay serial**")
  - delete step 4 of `method/commands/po-status.md` entirely → **1 failing** (`status_shows_lanes_and_attempts`: "po-status.md has no Fleet step")
  - revert D16's status cell to `partiel — …` → **1 failing** (`parity_matrix_reflects_the_fleet`: "D16 is not done: partiel — …")
  - delete the `/po-drive status` line from `po-help.md` → **1 failing** in `fleet-wiring.test.sh`; `pilot.test.sh` stayed fully green, which is exactly the gap the plan said this test had to cover
  - drop `Parallel` from the `Reads settings:` line → **1 failing** ("po-status.md does not read Parallel")
  - delete the "`Parallel` or `Max attempts` unreadable →" sentence → **1 failing** ("the fleet step lacks: print no fleet section")
  - All six undone; `git diff --exit-code` clean and `git status --porcelain` empty before this report was written; full suite re-run afterwards: 161 passed, 0 failed.
- [x] No test made useless by the story; no existing test removed or weakened.

## Neighbours
- [x] Every other reference to `/po-status` read: `po-drive.md:28`, `po-ship.md:50`, `po-flow.md:87`, `po-help.md:33`, `AGENTS.md:40`, `tests/drive.test.sh:18`. None depends on the step numbering, so renumbering 4→5 and 5→6 breaks nothing.
- [x] `tests/wiring.test.sh:19-35` slices Law 1 by `### Framing` / `### Per story` and then takes everything after `### Per story` as the per-story body — the new `### The fleet` subsection lands inside that slice but mentions none of `/po-research`, `/po-design`, `/po-plan`, so the ordering assertions are unaffected. Confirmed green.
- [x] `tests/pilot.test.sh:38` (`every_command_listed_in_help`) still green with the nested bullet.

## Findings
- **major — `docs/parite-killer-saas.md:66` vs `:97` and `:114`** — the matrix now contradicts itself about where fleet state lives. D17's Polype cell was rewritten to "État dérivé des worktrees et de git (ADR-0016) … le tracker n'étant qu'une visibilité optionnelle", while G06 (`:97`) still reads "l'état de travail vit dans le tracker (ADR-0003) … état dans le tracker en M3" and T3 (`:114`) still records the trade-off as "Tracker pour l'état, fichiers pour les verdicts — ADR-0003". A person reading this ledger to plan M3 gets two opposite answers, and G06's "en M3" now points at work ADR-0016 removed. The plan's own interdict ("Touch no other row") is what produced this, so the defect is in the plan as much as in the diff. Fix: reconcile G06 and T3 in the same pass, or record explicitly why they stay.
- **minor — `docs/parite-killer-saas.md:66`** — D17 is flipped to `fait` on the authority of ADR-0016, which is `status: proposed`; ADR-0003, whose model it replaces, is still `accepted` with `supersedes: []` / `superseded-by: []`, and ADR-0016 never declares it supersedes anything. The reading itself is faithful (ADR-0016's Consequences do leave the tracker as optional visibility), and `po-drive.md:18,25` already relied on it before this story — the diff extends the reliance rather than creating it. `docs/decisions/` is outside this story's `Owns` and the implementer correctly reported it instead of editing it. Fix is a human decision: accept ADR-0016 and state its relationship to ADR-0003.
- **minor — `method/commands/po-status.md:33` vs `:35`** — the step prescribes one command for a lane (`git -C <Worktree root><id> rev-parse --abbrev-ref HEAD`), but `/po-drive` confirms a lane on **two** axes (`po-drive.md:65`: the branch *and* `git worktree list --porcelain` showing `story/<id>` at that path and no other). Classification stays correct — git refuses the same branch in two worktrees, so a branch checked out elsewhere makes the rev-parse at the expected path print something else — but the promise at `:35` to report "`story/<id>` checked out at another path … as it was found" cannot be kept, because nothing in the step names the command that says *where*. One clause adding `git worktree list --porcelain` closes it.
- **minor — `AGENTS.local.md` (this repository, outside `Owns`)** — `/po-status` now declares it reads `Parallel` and `Max attempts`, but this project's own settings file has neither (its Pipeline block stops at `Flow threshold`, and it still says `Issue tracker` where the template says `Tracker`). By the file's own fail-closed sentence at `:37`, the fleet section would print nothing when `/po-status` runs here. Pre-existing — `po-drive.md:14` reads the same three settings since s27 — and the fix belongs to the project's settings file, not to this story.
- **minor — `tests/fleet-wiring.test.sh:49`** — the assertion pins the whole pre-existing `/po-drive` help line verbatim, text this story did not write; it was already green on `m3-flotte`. The other three assertions of that test bite, so the coverage is real, but this one buys nothing and will break on any legitimate rewording of the entry.

## Not verified
- **Runtime behaviour of `/po-status` and `/po-drive`.** These files are prose contracts for an agent; nothing here proves an agent reading step 4 actually counts lanes, reads `Fix loop:` correctly, or refuses to print the section when a setting is missing. Only a real fleet run shows that. A person should run `/po-drive status` and `/po-status` in a repository with two or three live lanes — including one lane deliberately left on a wrong branch, and one story with `Fix loop: 2` in its review — and compare the two reports against each other and against `git worktree list`.
- **The stale installed copies.** `.claude/`, `.polype/` and the root `AGENTS.md` still hold the pre-s26 text, by the plan's interdict. The fleet rules, the help entry and the fleet step are therefore *not* active in this repository until someone runs `bin/polype-dev-install .` — and that includes the ownership section of `review-antihallu` that s28 added, which the installed skill this review was loaded with does not contain (I read `method/skills/review-antihallu/SKILL.md` directly instead). A person should run the installer and check the drift before the next fleet story.
- **`bin/po-lint`.** Taken from the record (exit 0), not rerun, per `Verification mode: record`. I read the `fail-closed` rule's implementation to confirm it does not even scan the section that changed, so a green lint there is expected rather than reassuring; the fail-closed quality of `:37` was judged by reading, not by a tool.
- **No screen.** This story has no interface, no `docs/designs/s31-fleet-wiring/`, so design conformity was not assessed — correctly, the escalation table of the plan says so and I confirmed nothing visual is in the diff.
- **Type check, E2E, production build.** `Typecheck`, `E2E`, `E2E stage`, `Build` and `Build stage` are all `—` in `AGENTS.local.md`: the project has none. I ran no substitute.
- **Concurrent-lane behaviour of the `Owns` rule the AGENTS.md text now states.** The prose claims two stories sharing a path never run at once; that invariant lives in `/po-drive`'s wave selection, which no automated test exercises against a real pair of worktrees. Worth a human trying it once with two stories whose `Owns` overlap.

Max severity: major
Ship allowed: yes
