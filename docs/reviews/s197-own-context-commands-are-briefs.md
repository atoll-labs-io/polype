# Review — s197-own-context-commands-are-briefs

[Story](../stories.md) · [Plan](../plans/s197-own-context-commands-are-briefs.md) · [Verification](../verif/s197-own-context-commands-are-briefs.md)

Method version: 0.11.0
Recorded: 2026-11-21T00:19:16+01:00

Diff reviewed: `git diff main...story/s197-own-context-commands-are-briefs`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 91cc2318a22253eebe1ac6bfa7d5c2afd5baee64

## Ownership
Diff listed with `git diff --name-only main...story/s197-own-context-commands-are-briefs`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. That covers the four commands and the eleven test files, including the oracle. The research, plan and verification files under `docs/` are pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` → exit 0, so the record is reused. It shows `bash tests/run.sh` exit 0 at Tree 20d44ca…. The project has no type check (`Typecheck: —`). I did not rerun the full suite: memory is tight and the gate passes. Per the record's "Not proven here", nobody ran a `## By hand` paragraph by hand.
- [x] `po-gate qa-current` → not required, because `QA stage: —`.

## Plan
- [x] Tasks 1–6 are all present. I compared each removed sentence with rows R1–R14, P1–P15, D1–D15 and V1, and opened each "lives in" reference:
  - **Holds in `po next`:** `lane.rs:53-119`, `wave.rs:57-74`, `mod.rs:79-96`, `context/start.rs:15-31`, the `lanes.rs` orphan warning (a lane needs path = `<Worktree root><id>` and branch `story/<id>`), and the `lanes.rs:323` root-cause stop.
  - **Holds in tests:** `held-says-what-collides.oracle.test.sh:87-99` and `a-wave.cases`.
  - **Holds in templates:** `templates/research.md:8-30`, `templates/plan.md:13-46`, `templates/design-screen.md:3,18,30-33`.
  - **Holds elsewhere:** the `design-doctrine` sections, and `po-drive.md:62-63`.
  - **The other direction:** I read the three commands as on main. Every sentence that went has a row: the "If it exists: confirm…" line is R7, the merged Step 2 bullets are D10, and Run interdicts, The pivot and Reuse are P11–P13. No unlisted cut.
  - **H rows kept word for word:**
    - in `/po-research`: the `.env*` stop;
    - in `/po-plan`: the ADR draft, the technical-choice settlement, and the `human` and `autonomous` lines;
    - in `/po-design`: the "ask once" question, its approval and the `Design skill` `—` stop.
  - **Cut but not kept whole:** D5's "write it … themselves. Do not set it for them" (finding below). P7, the go-ahead question on a story with no research, is cut on purpose. It now closes towards a stop, which is stricter, and the plan argues for it. No finding.
- [x] Run interdicts, one by one:
  - Empty diff on `po/`, `bin/`, `.claude/`, `.polype/`, `method/AGENTS.md`, `planner.md`, `designer.md`, templates, skills and the other commands: yes.
  - `po-drive.md` changes only its line 53: yes.
  - Oracle sum intact (`oracle-intact` exit 0): yes.
  - No new phrase test: yes.
  - The ADR-0036 sentence verbatim in all three commands: yes.
  - No version bump: yes.

## References
- [x] The actions and reasons the `## By hand` paragraphs name all exist in `lane.rs`/`mod.rs`: `ready`, `no research`, `research, no plan`, `plan-validated refuses`, `validate-plan`, `design`, and `ask` "Technical choice: waiting for a human". `po next` exits 2 (`output::UNREADABLE`) only when the repository has neither `AGENTS.local.md` nor `.polype/version`.
- [x] `planner.md:35` and `designer.md:28` point to whole files, not to a heading, and the files still exist. The planner's checks (`planner.md:17-25`) and the designer's (`designer.md:15-25`) cover what the commands' old checks gave them.
- [ ] Values that only look right: the no-`Surface` branch of `/po-design` does not hold (finding 1).

## Rules
- [x] `worktree_is_prepared_in_one_place`: `git worktree add -b` now appears in `po-research.md` alone, and `po-drive.md:53` points to `## The worktree`.
  - `method/AGENTS.md:103` (Law 4) summarises in one sentence what `/po-research` does (fetch, `.env*`, `Install`). It states the rule, gives no steps and agrees with them, so in my judgement it does not break the criterion.
  - It names only `/po-research`, though `/po-drive` now prepares worktrees by the same steps. Any future rewording has to keep the two consistent.
- [x] `routing_is_said_once`: the only routing left in each command is its `## By hand` paragraph and its finish line.
- [ ] Human checkpoints: D5 is weakened (finding 2).
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s197-own-context-commands-are-briefs` → exit 0
- [x] Floor: `po-gate floor-guard` exit 1 with one flag: `tests/design.test.sh:20` assertions dropped. The plan justifies it under D4–D7, so it is minor.
- [x] The oracle pins `commands_still_lint` and `words_go_down`. Counts: the three commands total 1 789 words, cap 1 821. `po-drive.md` is at 2 413, `planner.md` and `designer.md` are unchanged.
- [x] 2 tests, within `Test budget` 25.
- [x] Bite:
  - 40 words appended to `po-design.md` → `words_go_down` fails (1). Undone; `git diff --exit-code` clean.
  - `Reads settings:` renamed in `po-plan.md` → `commands_still_lint` fails (1). Undone; `git diff --exit-code` clean.
  - The moved lint mutation on `agents/designer.md` passes inside `lint.test.sh`. That test asserts exactly one breach at the mutated line, so a mutation that did not apply would fail it.
- [x] Each deleted phrase test fell with a sentence the plan's table removes. The behaviour each guarded is held by a test of `po next`, of the state or of the session:
  - framing → `held-says-what-collides`;
  - root cause → `driver-next-action` and the `.cases` fixtures;
  - design system and Design source → `a-wave.cases`;
  - orphan worktree → `state-as-json`;
  - stories-review soft gate → the framing tests of `po state`.
- [ ] The helpers left behind in `tech-choice-backstop.test.sh` are now unused (finding 7).

## Neighbours
- [ ] `method/commands/po-stories-review.md:61` still describes the warning `/po-research` no longer gives (finding 3). `po-help.md` and `po-status.md` have nothing stale.

## Lenses
Lenses run: none
- [x] No lens trigger: the diff is method prose and bash tests only.

## Findings
- major — method/commands/po-design.md:14 — The no-`Surface` branch goes on for any `plan` entry, whatever its reason.
  - With reason `ready`, there is no worktree. D3 removed the check that `<Worktree root><id>` exists on `story/<id>`, so line 16 then reads and writes inside a path that is not a worktree. That breaks Law 4, and on main this case stopped and pointed to `/po-research`.
  - With reason `no research`, line 16 reads a research file that does not exist. D8's justification ("`design` comes only once a research or a plan exists") holds only for the `design` action, not for this branch.
  - Fix: limit the branch to `plan` with reason `research, no plan` or `plan-validated refuses`.
- major — method/commands/po-design.md:14 — Row D5 is marked **H**, but its human rule did not survive. Main said to "ask the person to choose `internal` or `external` and write it in `AGENTS.local.md` themselves. Do not set it for them." The `ask` "Design source unset" is now reported "as a question for the person", which invites the session to write the answer into the settings itself.
  - `designer.md:22` covers the subagent only.
  - `AGENTS.md` `## Reading settings` forbids guessing a value, not writing a value the person chose.
  - This is the same pattern the previous story showed: a rule about what stays with the person, cut to fit a word cap.
- major — method/commands/po-stories-review.md:61 — It still says "`/po-research` warns when `docs/reviews/stories.md` is missing or says `Stories ready: no`, and carries on anyway". R4 removed that warning, and only `po state` and `po-session` "Framing next:" carry it now, so the soft gate the sentence describes no longer happens in `/po-research`. The file is outside this story's `Owns`, so fixing it means widening the scope or opening a follow-up.
- minor — method/commands/po-plan.md:45 — The finish lines (also `po-research.md:45` and `po-design.md:48`) sit outside `## By hand`. The planner and the designer read these files as their procedure, so the lines tell them to run `po next` and to put an `ask` "as a question for the person", which neither subagent may do.
  - Nothing tells a subagent to skip `## By hand` other than its heading.
  - A short-track planner that applied `po-plan.md:21` would stop on `no research`.
  - Candidate for the `po-eval` arm the plan names (#208).
- minor — method/commands/po-research.md:20 — `po` missing or exiting 2 now points only to `polype install`.
  - The `/po-setup` pointer (R2/P3) is gone, though po-drive keeps both.
  - The `/po-design-system` pointer (D4) is gone too.
  - The "no entry at all" case that `/po-drive <id>` spells out (`po-drive.md:30`) is left implicit.
  - The same holds for `po-plan.md:21` and `po-design.md:14`.
- minor — tests/design.test.sh:20 — floor-guard flag (assertions dropped). The plan justifies it under D4–D7.
- minor — tests/tech-choice-backstop.test.sh:2 — The header comment still says "a plan's checks stop on the marker", and `MARKER`, `section_of` and `holds` (lines 5, 9, 10) are no longer used by any test in the file.

## Not verified
- No hand run of `/po-research`, `/po-plan` or `/po-design` against a live `po next`. What a person meets is judged from the code only:
  - a held story is reported with its `held` reason and `ref`;
  - `/po-plan` on a story with no research reports `plan`/`no research` and ends;
  - `/po-research` while the fleet is at `Parallel` now stops on `parallel`, which it did not do on main.

  To cover it, a person runs each command in a fixture project on a held story, a story with no research and a story with no `Surface` line.
- No real planner or designer run on the new files. Whether a subagent takes `## By hand` for itself is a model-read question: watch the next wave, or build the #208 control arm.
- I did not rerun the full suite. I relied on the `po-run` row (exit 0) that `verif-current` accepts.
- I did not open the decision inbox or the private folder, as instructed.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-21T00:54:45+01:00

Diff reviewed: `git diff main...story/s197-own-context-commands-are-briefs`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 12a3848573e391830a2177c64275ecdf115905b1

## Ownership
Diff listed with `git diff --name-only main...story/s197-own-context-commands-are-briefs`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`:
  - the five commands, including `po-stories-review.md`, which framing commit 5b24c36 added and merge 981f8c9 brought in;
  - the eleven test files;
  - the oracle.
  - The research, plan, verification and review files are pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows no other `story/` worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` → exit 0, so the record is reused. Its last `bash tests/run.sh` row exits 0 at tree 39698219…. The project has no type check (`Typecheck: —`).
  - I did not rerun the full suite: memory is tight.
  - The record's "Not proven here" says the restored stops and the "A subagent skips this paragraph." lines are prose, checked only by reading.
- [x] `po-gate qa-current` → not required, because `QA stage: —`.

## Plan
- [x] Status of each Fix loop 0 finding:
  - **Major 1 (no-`Surface` branch), closed.** `po-design.md:14` now goes on only on `plan` with reason `research, no plan` or `plan-validated refuses`.
    - `po next` builds a lane only for a worktree at `<Worktree root><id>` on `story/<id>` (`po/src/context/lanes.rs:216-226`). Both reasons come from `lane::next` alone (`po/src/next/lane.rs:94-103`), never from the `ready` list (`mod.rs:93-94`). So this branch can no longer run where no story worktree exists.
    - `research, no plan` implies that the research exists (`lane.rs:71-74`). `plan-validated refuses` needs only a plan, and a short-track lane has no research. So « when present » (line 16) is needed and right.
  - **Major 2 (D5), closed.** The rule is restored. Against main `:20`, the only difference is the word « is »: main has « `Design source` is `—` → », the branch « `Design source` `—` → ». The rest is identical: « stop and ask the person to choose `internal` or `external` and write it in `AGENTS.local.md` themselves. Do not set it for them. » No change in force.
  - **Restored stop on a missing `docs/design-system.md`: needed.** On a `design` entry it repeats what `po next` already guarantees (`lane.rs:87-88`), which is harmless. On the no-`Surface` branch nothing else checks it, because `has_screen` reads only `Surface` (`po/src/context/stories.rs:25-27`). Same reasoning for the `Design source` stop. Small wording loss: see the minor finding below.
  - **Major 3 (`po-stories-review.md:61`), closed.** The new sentence holds against `po state`, which carries the `stories-review` item `none`/`no`/`yes` (`framing.rs:115-122`). The session prints that item on its `Framing:` line and `/po-stories-review` on `Framing next:` (`po-session.sh:59-60`). Nothing blocks on it: `wave.rs` never reads the review. One nuance: `Framing next:` names it only once the scope is approved and the stories exist (`framing.rs:98-103`), and with no `Framing` at all when `Entry mode` is unreadable. That is a wording nuance, not a finding. The word count is unchanged: 790 on the branch, 790 on main.
  - **Minor 4 (finish lines read by subagents), closed.** The `po next` call moved into `## By hand` (« At the end, report a new `po next` entry likewise »). The finish lines now hold only the message, and `/po-plan` has none.
  - **Minor 5 (pointers), closed.**
    - `/po-setup` is back in all three commands. It is needed: `Project::find` accepts `.polype/version` without `AGENTS.local.md` (`mod.rs:79-85`), so `po next` does not exit 2 in that case.
    - `/po-design-system` is back in `po-design.md:14`.
    - The no-entry case is still covered by « as `/po-drive <id>` does » (`po-drive.md:30`: « no entry at all … say so and stop »).
  - **Minor 6 (floor flag on `design.test.sh:20`): still there, still justified.** Carried over below.
  - **Minor 7 (unused helpers in `tech-choice-backstop.test.sh`), closed.** `MARKER`, `section_of` and `holds` are gone, and the header comment is reworded.
- [x] The two checkpoints the implementer did not restore, judged from `git diff main -- method/commands/`:
  - **Orphan worktree: unchanged in force.**
    - A worktree under the root on a wrong or detached branch, or a `story/<id>` branch at another path, raises `orphan-worktree` (`lanes.rs:228-236`).
    - A story whose branch is orphaned gets no entry (`wave.rs:52`).
    - « A warning naming the story … ends the command » covers both cases.
    - The « no `switch`, `checkout` or `stash` » rule lives in Law 4 of `AGENTS.md` (« any mismatch ends the stage — no `git switch`, `checkout` or `stash` »), which every session loads, and in `po-drive.md:55`.
    - Caveat, model-read: when only the path is orphaned (wrong branch at `<Worktree root><id>`), the story still shows as `ready`. The stop then rests on the model reading the warning's path as "naming the story". Listed under Not verified.
  - **Framing stop: unchanged in force.**
    - `/po-research` runs `po next` after step 1, the fetch.
    - `StartPoint` reads `origin/<Target branch>` when it exists (`start.rs:15-27`), so the story is `held` with reason `framing` and the start point as `ref` (`wave.rs:69-74`). That happens before step 2 creates any worktree.
    - Main's message « Merge it, then run /po-research again » is lost. The stop itself is not.
- [x] Subagents reading the commands as their procedure, now that `## By hand` opens with « A subagent skips this paragraph. »:
  - **Designer: no stop lost.** `designer.md` holds them all: branch at :18, root or detached at :19, design system at :21, `Design source` at :22, no screen at :23, `Design skill` at :39.
  - **Planner: no stop lost.** `planner.md` holds the branch check at :20-21, root cause at :38, technical choice at :49 and validation at :45-47. The old trap of a short-track planner stopping on `no research` is gone.
  - **The shared risk** is the scope of « this paragraph », covered by a minor finding below.
- [x] A person running a command by hand still meets every stop:
  - root cause and technical choice, as an `ask`;
  - framing, `parallel` and `owns`, as `held`;
  - an orphan worktree, as a warning;
  - no `AGENTS.local.md`, and `po` missing;
  - the `.env*` stop (`po-research.md:30`);
  - the `Design skill` stop (`po-design.md:31`);
  - the « ask once » question and the approval in `/po-design`;
  - the ADR draft, the technical-choice settlement and the `human` and `autonomous` lines in `/po-plan`.
- [x] The two further cuts in `po-design.md`. No rule a model needs is lost:
  - **Step 2:** `templates/design-screen.md` holds the reused pattern (`## Kind`, :9), « the note stops here » for a derived screen (:12) and every section for a new one. « No artefact for a derived screen » stays in Step 3 (« A new screen only »).
  - **Step 3:** « Its tokens and components are the ones the note lists » is covered by `design-doctrine` `## No invention`, `designer.md:31` and the template's `## Components and tokens` table.
- [x] Run interdicts:
  - `planner.md` and `designer.md` are untouched;
  - nothing changes in `po/`, `bin/`, `.claude/`, `.polype/`, `method/AGENTS.md`, the templates or the skills;
  - `po-drive.md` changes only line 53;
  - the oracle sum is intact;
  - the ADR-0036 sentence is verbatim in all three commands;
  - no version bump.

## References
- [x] Opened and confirmed:
  - `lane.rs:53-119`;
  - `mod.rs:72-102`;
  - `wave.rs:37-77`;
  - `start.rs:15-31`;
  - `lanes.rs:200-240`;
  - `framing.rs:60-126`;
  - `po-session.sh:50-62`;
  - `po-drive.md:25-35`.
- [x] Every action and reason the `## By hand` paragraphs name exists in that code.

## Rules
- [x] `routing_is_said_once`: the only routing left in each command is its `## By hand` paragraph.
- [x] `worktree_is_prepared_in_one_place`: as in Fix loop 0.
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s197-own-context-commands-are-briefs` → exit 0
- Floor: `po-gate floor-guard` → exit 1, one flag: `tests/design.test.sh:20` assertions-dropped. The plan justifies it (D4–D7), so it is minor.
- [x] `po-gate oracle-intact` → exit 0. The record has no oracle change.
- [x] 2 oracle tests, within `Test budget` 25. Word counts with `LC_ALL=C wc -w`:
  - `po-research.md` 509, `po-plan.md` 627, `po-design.md` 680: 1 816 together, for a cap of 1 821;
  - `po-drive.md` 2 413.
- [x] Bite: appended 10 words to `po-design.md` → `words_go_down` fails (1 test). Undone with `git checkout --`; `git diff --exit-code` clean.
- [x] `tech-choice-backstop.test.sh` still bites. I ran only that file and the oracle: 4 passed. Each remaining test mutates a method copy and fails if the guarded test still passes, so a passing run is itself the bite proof. Its temp directory is removed by its trap.

## Neighbours
- [x] `planner.md:35` and `designer.md:28` still point to whole files.

## Lenses
Lenses run: none
- [x] No lens trigger: the diff is method prose and bash tests only.

## Findings
- minor — tests/design.test.sh:20 — floor-guard flag (assertions dropped, 1 removed). The plan justifies it under D4–D7.
- minor — method/commands/po-plan.md:21 — « A subagent skips this paragraph. » names one paragraph, but the `## By hand` heading also holds paragraphs a subagent needs.
  - In `po-plan.md` that is :23 (« Everything below… inside `<Worktree root><id>` ») and :25 (« A plan file already present? Skip to "Approval" »). The planner is dispatched on `plan-validated refuses` with a plan already on disk, and `planner.md` does not say "don't rewrite it".
  - In `po-design.md` it is :16 (the read list, research « when present »).
  - A model that takes the heading as the scope of the skip loses these lines.
  - Fix: move those lines under their own heading. Candidate for the #208 arm.
- minor — method/commands/po-design.md:14 — « `docs/design-system.md` missing » no longer says where to look. Main :19 said « Inside the worktree ». The check sits before « Everything below reads and writes inside `<Worktree root><id>` », so a person may check the repository root instead.
  - It matters only on the no-`Surface` branch. On a `design` entry, `po next` checks it in the lane (`lane.rs:87`).
- minor — method/commands/po-design.md:14 — Taking `plan` with reason `plan-validated refuses` lets the design be written after the plan exists.
  - Nothing says the plan must then be redone to build on it (`po-plan.md:33`), which goes against the stage order of Law 1.
  - Main had no stage check at all, so this is not a regression. The new wording now permits it explicitly.

## Not verified
- No hand run of `/po-research`, `/po-plan` or `/po-design` against a live `po next`, and no real planner or designer run on the new files. Whether a model stops on a warning that names only the orphaned path, and whether a subagent skips just the one paragraph, are model-read questions. To cover them, a person runs each command in a fixture project on:
  - a held story;
  - a story with no research;
  - a worktree at `<Worktree root><id>` on the wrong branch;
  - a story with no `Surface` line.
- I did not rerun the full suite. I relied on the `po-run` row that `verif-current` accepts (exit 0).
- I did not open the decision inbox or the private folder, as instructed. Nothing was pushed, and the worktree is clean (`git status --porcelain` empty). The tree was taken again before answering and is unchanged.

Max severity: minor
Ship allowed: yes
