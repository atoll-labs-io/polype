# Research — s191-drive-takes-one-story

[Story](../stories.md)

## Structuring facts
- **False assumption of the story**: `po-research.md:24` names neither command (it is the stories-review warning); `grep -ri 'orchestrator\|po-flow' method/` finds nothing in that file. `po-execute.md:36` only says "even when no orchestrator runs it", in prose.
- `po next` takes no id (`po/src/next/mod.rs:73-75`: any argument other than `--remote` is refused) and `po/` is out of `Owns`: `/po-drive <id>` filters the entries of the one `po next` output to the story (`story` field, `mod.rs:51-56`). A ready story beyond `Parallel` is `held` with reason `parallel` (`po/src/next/wave.rs:65-66`), so `/po-drive <id>` cannot open it while earlier stories take the slots.
- `polype update` already drops every file the old manifest lists and the new payload does not ship, keeping only a copy whose sum drifted (`bin/polype:1126-1129`, `drop_laid_file` at `:483-503`): no installer change is needed for `update_removes_them_from_a_project`.
- Every routing rule of the two commands is already computed by `po next` (`po/src/next/lane.rs:19-46` track, `:53-119` stages, `:155-203` review outcomes), except one sentence nobody else carries: the short-track note appended to the implementer's prompt (`po-flow.md:88`); `implementer.md:25` reads the research only.
- `method/` holds 72 702 words in 68 files (`LC_ALL=C wc -w`, summed per file); the two commands hold 1 907 + 1 569 = 3 476.

## Story
`/po-drive` alone moves work: empty for every ready story, `<id>` for one. `/po-orchestrator` and `/po-flow` go (ADR-0109, #210).
- `two_commands_are_gone` — both files gone, no file of `method/` nor `README.md` names them, `bin/po-lint` passes.
- `update_removes_them_from_a_project` — on a project installed with the previous version, `polype update` removes both without keeping them as the person's files when intact.
- `drive_takes_an_id` — `/po-drive <id>` advances that story only, by the same `po next` actions; a non-exact argument is matched against `docs/stories.md`, zero or several matches stop with a list. Model-read: judged in review.
- `nothing_only_they_said_is_lost` — the plan lists each rule only one of the two commands carried and where it lives now, or why it goes. Model-read.
- `words_go_down` — `method/` at least 3 000 words fewer; no file the story touches grows.

## Current code
- `method/commands/po-drive.md` (2 450 words): `argument-hint: [status]` (`:3`), argument line `:16`, Checks `:20-26`, actions table `:31-41`, lane preparation `:51-56`, dispatch `:58-69`, plan validation `:71-86`, decisions log `:102-107`, report `:109-118`.
- `po-orchestrator.md` (1 907 words): stages 0-8 and its own decisions log (`:23-97`). `po-flow.md` (1 569 words): track, signals, worktree, plan, approval, execute/review/ship (`:23-101`).
- Mentions outside them (all opened): `po-help.md:35,40,46`; `method/AGENTS.md:45,47`; `templates/plan-flow.md:9,15`; `po-status.md:28` (`/po-flow <id>` as next step); `skills/diagnostic/SKILL.md:3`; `po-execute.md:36`; `README.md:45`; `docs/migration.md:139`; `docs/parite-killer-saas.md:64-65` (D15, D16 status cells); `docs/direction.md:37`.
- `bin/`, `po/src/`, `method/hooks/`, `docs/interface-agent.md`: no mention.

## Attachment points
- `po-drive.md:3,16` (argument), `:20-26` (a check for the id), `:102-103` (decisions-log list).
- `po-execute.md:47-62` — the prompt `/po-drive` sends word for word (`po-drive.md:63`): the short-track sentence joins the other appended sentences.
- `bin/polype` `cmd_update` (`:1112-1172`) — unchanged, exercised by the oracle.

## Verified interfaces
- `po next` output: `actions[]` of `{story, action, reason, track?}`, `ready[]`, `held[]` of `{story, reason, ref, entry?, ref_entry?, path?}`, `warnings` (`po/src/next/mod.rs:23-70`).
- `AGENTS.md:137` already rules: "A command given something that is not an exact id matches it against `docs/stories.md`; zero or several matches → it lists the stories and stops."
- Technical-choice and root-cause stops: `po/src/context/lanes.rs:322-330` reads them from the plan and the research whatever the track; `lane.rs:76-79` turns them into `ask`.
- `planner.md:28-30` (worktree copy, after s190): takes `track` from `po next`, raises `flow` to `full` on the seven signals or more than about six tasks.
- `bin/po-lint` passes today (`no breach in 27 file(s)`); its fail-closed rule reads the arrows of `## Checks` sections (`bin/po-lint:163-180`).

## Rules only the two commands carry
O = `po-orchestrator.md`, F = `po-flow.md`. "Covered" cites where the rule already lives.

| # | Rule (source) | After the story |
| --- | --- | --- |
| 1 | Settings, stories file, id matched, model settings → stop (O:24, F:24-25, F:34) | covered: `po-drive.md:20-24`; id matching moves to `po-drive.md` |
| 2 | Scope approved per `Entry mode` before any story runs (O:26-29) | goes: `/po-stories` refuses an unapproved scope (`po-stories.md:21-24`), and `po state` reads it (`po/src/context/framing.rs:61-79`) |
| 3 | Stories review not passed → warn, never block (O:31) | covered: `po-research.md:24`, read by the planner (`planner.md:35`); `framing.rs:81-85` |
| 4 | A screen story needs `docs/design-system.md` and `Design source` before any worktree (O:33) | partly: `po next` asks for both at the design stage (`lane.rs:86-94`), after the research; the "before any worktree" part goes |
| 5 | Every human stop ends the single-story run (O:35) | covered: `po-drive.md:67`; with one lane, the run ends |
| 6 | Track from `Story track`/`Flow threshold`; no complexity → full (O:38-41, F:29-32) | covered: `lane.rs:19-46`; no complexity is now `ask "no complexity"` (`lane.rs:41-43`) |
| 7 | Screen or QA story → full track; `QA stage` missing stops only a QA story (O:43, F:34, F:52) | covered: `lane.rs:28-35` |
| 8 | Flow escalation continues on full reusing the worktree (O:45, F:48) | covered: `planner.md:30` raises the track itself, in the same lane |
| 9 | Escalation signals, checked on the story text and after reading the code (F:37-46, F:50) | covered: `planner.md:30`; "before any worktree exists" goes (the driver prepares every lane, `po-drive.md:52`) |
| 10 | Research created or reused; `Fixes`/`Corrige` → diagnostic; `Root cause: not found` ends with no plan (O:48) | covered: `planner.md:38,41`; `lane.rs:77` |
| 11 | Design stage only for a screen, reuses `design.md` (O:51) | covered: `lane.rs:86-94`, `po-drive.md:35,62` |
| 12 | Plan reads `design.md` with the research (O:54) | covered: `po-plan.md:45`, which the planner honours (`planner.md:35`) |
| 13 | Technical choice settled with the person first; then `Plan validation` (O:54-56, F:70-80) | covered: `lane.rs:78` `ask`, `po-plan.md` Approval, `po-drive.md:71-86`; F's "next free ADR number" goes, replaced by the reservation of `po-drive.md:56` and `planner.md:56` |
| 14 | Implementer model rule, fix runs, no fix run on a QA or shape block (O:59, F:87, F:90) | covered: `po-drive.md:36`, `po-execute.md:40-45`, `lane.rs:187-202` |
| 15 | Design and oracle sentences appended to the implementer prompt (O:61-65) | covered: `po-execute.md:56-62`, sent word for word (`po-drive.md:63`) |
| 16 | Short-track sentence appended to the implementer and reviewer prompts (F:88-89) | implementer: **moves to `po-execute.md`** (nothing else carries it); reviewer: covered by `reviewer.md:25` |
| 17 | QA after every execution, `Model strong`, blocked report committed then stop, current report re-recorded (O:68-70) | covered: `po-drive.md:37,64`, `lane.rs:107-115` |
| 18 | Review recorded by `/po-review`, failure recorded blocked (O:73, F:89) | covered: `po-drive.md:65,88-93` |
| 19 | QA return and QA-evidence return spend no fix run; two evidence commits → human (O:75-79, F:90) | covered: `lane.rs:187-192` |
| 20 | Findings-shape block → human, no fix run (O:81, F:90) | covered: `lane.rs:194-196` |
| 21 | Two fix runs then human; a verdict never softened (O:83, F:90) | covered: `lane.rs:197-202` (`Max attempts`), `po-drive.md:89` |
| 22 | Ship per `/po-ship`, effective confirmation, cleanup after proof (O:86, F:91) | covered: `po-drive.md:39,95-100` |
| 23 | Decisions log: plan approved alone, fix runs, details, answers; dated rows, landed as `decisions-log` (O:89-93) | covered: `po-drive.md:102-105` |
| 24 | Decisions log: the track chosen at Stage 1 and a flow escalation (O:89) | the track goes (computed by `po`, not a decision); a planner raising `flow` to `full` **joins the list of `po-drive.md:103`** |
| 25 | Log written once the run shipped or stopped; a `pr` ship writes at "Pull request ready" (O:93) | covered: `po-drive.md:96,103` ("after the wave's last ship"; a pull request left for a person ends a ship) |
| 26 | A run that decided nothing writes no row (O:95) | covered: one row per decision (`po-drive.md:103`) |
| 27 | Research, design and plan on the session model (ADR-0036) (O:21, F:21) | goes: no command writes them in its own context any more; the planner runs on `Model strong` (`po-drive.md:61`) |
| 28 | No Agent tool → stop (F:26) | covered: `po-drive.md:22` |
| 29 | Short-track plan content: `track: flow`, verified facts, signals, Reuse, oracle, six tasks, ~150 lines (F:65-67) | covered: `planner.md:40,43` |
| 30 | "Nothing is relaxed" list, three contexts (F:19, F:94-99) | goes: restates Law 3 and Law 2 of `AGENTS.md`; the context count is ADR-0109's |
| 31 | Finish lines (O:97, F:101) | covered: `po-drive.md:109-118` |

## Traps
- Eighteen test files read the two commands (`grep -c`); four more matches outside `Owns` are false positives (`WORKFLOW`, `PLAN_FLOW` variables). Each owned file is triaged in the plan.
- `tests/resume-shape-stop.test.sh` reads only the two commands: emptied, it must be deleted, since `tests/run.sh:37` fails a file with no `test_`.
- `tests/plan-and-defect-paths-cleanup.test.sh:80` mutates the exact sentence of `plan-flow.md:15` that names `/po-flow`: its phrase must follow the rewrite.
- `tests/fleet-wiring.test.sh:57-65` requires D16 to stay `fait — …`; `tests/pilot.test.sh:128-136` requires every command file to appear in `po-help.md`.
- 23 test files read `po-drive.md` (`grep -l`), many outside `Owns`: the words cut from it must be words no test reads. Word ceilings already bind it (≤ 2 481, `ship-files-the-other-findings.oracle.test.sh:9`; ≤ 2 500, `drive-executes-next.oracle.test.sh:13`) and `AGENTS.md` (≤ 3 739).
- `design-handoff.test.sh:23` reads the start of `po-execute.md:36` up to "**has a design**": only the tail may go.
- The installed copies under `.claude/` keep both commands until the next install: not this story's.
- No migration, no `po/` change, no version bump.

## Open questions
- `/po-drive <id>` on a story `held` for `parallel` while other stories are only ready: report and stop (the plan's choice), or open it anyway? Only `po next <id>` would settle it without a driver-chosen route; that is `po/` work for a later story.
- `docs/direction.md:37` says the commands disappear "Pas avant s168": the plan rewrites it as done, same word count; the owner may prefer to leave direction prose alone.

## Complexity
4 → 4. No code, but a wide, mechanical cut across 20 test files where a careless removal hides a lost rule.

## Split
—
