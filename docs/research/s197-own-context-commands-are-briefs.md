# Research — s197-own-context-commands-are-briefs

[Story](../stories.md)

## Structuring facts
- The story's line numbers are stale: `po-plan.md` has 60 lines, so "`po-plan.md:108-114`" is its `## Approval` at `method/commands/po-plan.md:51-57`; the word total (2 521 = 764 + 871 + 886, `LC_ALL=C wc -w`) still holds on 2cd31f3.
- Cutting only what `po next` computes and the worktree redite frees about 350 words, half the 700 asked. The other half comes from sentences that restate `templates/research.md`, `templates/plan.md`, `templates/design-screen.md` and the `design-doctrine`/`testing-doctrine` skills, which the planner and the designer fill or preload anyway. Measured on a draft: 499 + 624 + 660 = 1 783 words (≤ 1 821), with every human checkpoint kept.
- `po next` computes every stop the three commands restate: `Root cause: not found` (`po/src/next/lane.rs:77`, `po/src/context/lanes.rs:323-324`), the technical choice (`lane.rs:78`, `lanes.rs:326-330`), no design system and `Design source` unset (`lane.rs:86-93`), the story missing from the start point (`po/src/next/wave.rs:70-73`, `po/src/context/start.rs:15-31`), a worktree on the wrong branch (`lanes.rs:226-236`, warning `orphan-worktree`), a non-project (`po/src/next/mod.rs:79-85`, exit 2).
- `po next` does not compute two things the commands still need: it never fetches (`start.rs:16-22` reads `origin/<target>` locally), and `has_screen` reads only the `Surface` line (`po/src/context/stories.rs:25-27`), not the "no `Surface` line, text shows a screen" case of Law 1 (`method/AGENTS.md`, `### Per story`).
- `planner.md:35` and `designer.md:28` read the commands as their procedure; nothing they need lives only in a sentence the plan removes (table of the plan).

## Story
Make `/po-research`, `/po-plan` and `/po-design` keep only the procedure of their stage. Criteria: `routing_is_said_once`, `worktree_is_prepared_in_one_place`, `subagents_keep_their_procedure` (model-read, judged in review); `commands_still_lint`, `words_go_down` (≥ 700 fewer words in the three, no touched `method/` file grows).

## Current code
- `method/commands/po-research.md` (764 words): `## Checks first` :21-24 (AGENTS.local.md, id match, soft `Stories ready:` warning), `## The worktree` :26-38 (fetch, start-point check on `docs/stories.md`, `worktree add`, `.env*` copy, `Install`, existing-worktree checks :36), `## The investigation` :40-48 (six steps), `## The report` :50-57 (cap, `Root cause` finish :55).
- `method/commands/po-plan.md` (871): `## Checks first` :22-26 (setup, id, worktree, `Root cause`), `## Inputs` :32-35 (no-research go-ahead :35), `## Writing the plan` :37-49, `## Approval` :51-57, finish :59.
- `method/commands/po-design.md` (886): `## Checks` :15-24 (six checks), `## Where the design lives` :28-31, Steps 1-4 :33-62, `## Approval` :64-65.
- `method/commands/po-drive.md:53` restates the worktree steps "as `/po-research` does"; `:30` reads `po next` and, for an id, its entry or held reason, "no entry → say so and stop".
- `method/agents/planner.md` (1 336) and `method/agents/designer.md` (959) carry their own checks (`planner.md:17-25`, `designer.md:15-25`) and read the commands as contracts.

## Attachment points
- One "by hand" paragraph per command, run before the procedure: `po next` read as `/po-drive <id>` reads it (`po-drive.md:30`), each command naming the actions it goes on:
  - `/po-research`: `plan` with reason `ready` or `no research` (`next/mod.rs:96`, `lane.rs:73-75`).
  - `/po-plan`: `plan` with reason `research, no plan` or `plan-validated refuses`, `validate-plan`, and the `ask` "Technical choice: waiting for a human" (`lane.rs:78,95-103`). `po state` sends the person to `/po-plan <id>` for that choice (`lanes.rs:326-330`, `tests/session-and-gate-checks.test.sh:54`).
  - `/po-design`: `design` (`lane.rs:92`).
- `po-drive.md:53` becomes a pointer to `## The worktree` of `po-research.md`.
- `tests/lint.test.sh:86-103` moves its fail-closed mutations from `po-design.md` to `agents/designer.md:22-23`, `## Drawing with the project's skill` (both checked on a draft copy: one breach on the mutant, none on the negative controls).

## Verified interfaces
- `po next` prints `actions` (`story`, `action`, `reason`, `track`), `ready`, `held` (`story`, `reason`, `ref`), `warnings` (`next/mod.rs:64-70`); exit 2 when no `AGENTS.local.md` nor `.polype/version` (`project.rs:38-45`, `output.rs:7`). `Project::find` uses `--git-common-dir`, so it runs from the root or a worktree (`project.rs:39-41`).
- A story is `ready` only within `Parallel` slots and with no `Owns` collision, dependency or decision (`wave.rs:57-74`); otherwise `held`.
- `bin/po-lint` fail-closed rule reads only `## Checks|Preconditions|Step 0` sections (`bin/po-lint:175`); a `## By hand` section is outside it.
- Tools: `po-research.md:4-9` Read Glob Grep Write Bash; `po-plan.md:4-10` the same plus AskUserQuestion; `po-design.md` declares none (ADR-0027, `tests/designer-browser.test.sh:20-22`). Running `po next` needs no new permission: both have Bash, `/po-design` has every tool, so ADR-0120 is not touched.
- Word caps on touched files outside `Owns`: `po-research.md` ≤ 764, `planner.md` ≤ 1 336, `po-drive.md` ≤ 2 450 (`tests/drive-takes-one-story.oracle.test.sh:9-12`), `po-drive.md` ≤ 2 449 (`tests/ship-cleans-the-lane.oracle.test.sh:221`), `designer.md` ≤ 967 (`tests/defects-seen-on-products.oracle.test.sh:9`).

## Traps
- Phrase tests read the cut sentences: `research.test.sh:9`, `design.test.sh:21-27,31-57,82,86`, `reuse-ladder.test.sh:59-62`, `plan-and-defect-paths-cleanup.test.sh:42-49,66`, `tech-choice-backstop.test.sh:24-26`, `defect-and-routing-paths.test.sh:29-30`, `framing-through-pr.test.sh:59-70`, `stories-review.test.sh:50-53`, `drive.test.sh:23`, `drive-guards.test.sh:17`, `lint.test.sh:88-100`. All in `Owns`; run on a draft tree, these and no others fail.
- Phrases that must stay: `model-routing.test.sh:87` (`which no command can choose (ADR-0036); start the session on \`Model strong\`` in all three), `planner.test.sh:9-30` (`200 lines at most`, `250 lines at most`), `escalation-contract.test.sh:46-53` and `tech-choice-backstop.test.sh:34` (the Approval marker paragraph), `design-handoff.test.sh:33-37`, `planner-writes-the-oracle.test.sh:60-62` (`no other test file`, `## Acceptance tests`), `designer-browser.test.sh:30-31`, `plan.test.sh:21-29`, `research.test.sh:6-34` but :9, `design.test.sh:59-88` but :82 and :86.
- The behaviour of the stops that move to `po next` is already tested: `tests/driver-next-action.oracle.test.sh:235,254` (root cause), `tests/fixtures/driver-cases/a-wave.cases:5-24` (no design system, `Design source` unset), `tests/held-says-what-collides.oracle.test.sh:87-99` (framing hold).
- `po-drive.md` sits at 2 441 words; the pointer takes it to 2 413 (measured).
- `method/AGENTS.md` Law 4 also says "`/po-research` creates the worktree … after a fetch …, copies the ignored `.env*` files …, and runs `Install`". It is outside `Owns`; it states who does it, the steps live in `po-research.md`.
- `tests/run.sh` builds `po` with cargo on every run: build once, then run the focused files.

## Open questions
- Does the reviewer accept Law 4's sentence as the rule rather than a second description of the steps? The plan keeps the steps in one place and does not touch `method/AGENTS.md`.
- `po next` misses the "no `Surface` line, text shows a screen" case (`stories.rs:25-27`); the plan keeps one clause for it in `/po-design`. The gap in `po` itself is an item for `Issue tracker`, not this story.
- By hand, a story beyond `Parallel` now reads `held: parallel` and `/po-research` stops; this is `po next`'s answer, the same as `/po-drive <id>`.

## Complexity
4 → 3: no code and no `po` change; the risk the story names (two subagent contracts) is handled by the sentence-by-sentence table, and the test changes are removals of phrase assertions plus one mutation moved.

## Split
—
