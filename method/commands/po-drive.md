---
description: Drives the fleet — advances every ready story in parallel, one lane per story, and ships the finished ones one at a time
argument-hint: [status | <id>]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---
# /po-drive

Reads settings: `Target branch`, `Worktree root`, `Install`, `Plan validation`, `Max attempts`, `Merge mode`, `Ship confirmation`, `ADR directory`, `Tracker`, `Model strong`, `Model light`, `Light up to`, `Issue tracker`

Argument: $ARGUMENTS — `status` reports the fleet and changes nothing; empty runs a wave; anything else names one story.

You drive the fleet: `po next` says what each lane does next, and you do it. You have neither Write nor Edit, so you write no code and decide no verdict: each subagent works under its own file's contract (ADR-0016), and Bash only runs `po` and `gh pr view`, opens lanes, writes `validated: yes` and the decisions log, and records what a subagent handed you; it never edits a source file.

## Checks
- No `AGENTS.local.md` → stop and point to `/po-setup`.
- No Agent tool available → stop: without subagents there is no lane.
- `docs/stories.md` missing → stop and point to `/po-stories`; never invent a story to fill a lane.
- One of the settings above missing → stop and name it, never guessing.
- `po` missing, or `po next` exiting 2 → stop, name `polype install`, and route nothing yourself.
- An argument other than `status` is matched against `docs/stories.md` as `AGENTS.md` (`## Ids and branches`) says; zero or several matches → list them and stop.
- `Tracker: github` → say that publishing to GitHub is not handled yet, and carry on.

## The next action
Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next --remote`. It prints `actions`, `ready`, `held` and `warnings`. You do each entry of `actions` and choose no route of your own. Run it again once a stage's answers are recorded; the wave ends when every entry is `wait` or `ask`, those of `ready` included. With an id, keep only that story's entries: its `actions` entry, or its `held` reason and `ref`, reported with nothing launched; no entry at all (shipped, or absent from `po next`) → say so and stop.

| Action | What you do |
| --- | --- |
| `plan` | the planner, step 1; reason `ready` → open the lane first |
| `validate-plan` | `## Validating a wave's plans` |
| `design` | the designer, step 2 |
| `execute`, `fix` | the implementer, step 3 |
| `qa` | the qa subagent, step 4 |
| `review` | the reviewer, step 5 |
| `ship` | `/po-ship <id>`; reason `landed` → its cleanup only, taking no slot and no place in the serial order |
| `wait` | nothing; reported |
| `ask` | `po inbox add` first, options and recommendation included, then the person at once, with the reason |

One rule stays yours, since `po` cannot see it: a failed ship sends its story back to a fix run under the same `Max attempts` cap.

**A stage already recorded is resumed, never replayed.**

## A wave

You never leave the directory you were started in: no `cd`, at any stage of a wave. Each lane's worktree is resolved once, as the absolute path `<repository root>/<Worktree root><id>`; every git command you run against a lane is `git -C <absolute path>`, and every subagent prompt carries that same absolute path.

### Opening the lanes
Before any subagent starts, you open each lane, running its `po next` entry's `commands` one by one, exactly as given: never joined, looped or rewritten. `planner` may not run `git worktree add`, so a lane you did not open cannot exist.

A worktree `po` reports in an `orphan-worktree` warning is named in the report with the path and the branch actually found, drops that lane from the wave, and waits for a human: you run no `git worktree add --force`, `worktree remove`, `worktree prune`, `switch`, `checkout` or `stash` to make it fit.

ADR numbers are a shared resource no `Owns` line can divide, so you assign them before the wave leaves — read the highest `ADR-NNNN` on `Target branch`, then hand each lane of the wave its own number, the following ones in sequence, in the order of `docs/stories.md`. A lane that needs no ADR leaves its number unused and the gap stays a gap: a number is never handed to a second lane of the same wave.

### Dispatching
The lanes of a wave must **overlap in time**: every subagent of a stage is started before any of them is waited on. No dispatch shape is imposed: a subagent starts in the background and hands the call back at once, so counting messages proves nothing. Each lane's **activity window**, which `## Report` states, shows the overlap. Never two calls for the same story at once. This holds stage by stage: every planner, then every designer, then every implementer, then every qa, then every reviewer — a stage is started whole. A lane whose subagent leaves only once the previous lane has answered overlaps nothing, and `Parallel` buys nothing there.

1. `subagent_type: planner`, `model:` set to `Model strong` — the story id, the absolute worktree path and the action's `track`, under its own contract. The plans that come back are approved as `## Validating a wave's plans` settles it, before any implementer starts.
2. **The design stage**, for a story with a screen (`AGENTS.md`, Law 1): `subagent_type: designer`, `model:` set to `Model strong` — the story id and the absolute worktree path, under its own contract (`method/agents/designer.md`). Every designer of a wave leaves before any is waited on.
3. `subagent_type: implementer` — the prompt `/po-execute` fixes (`method/commands/po-execute.md`), its appended sentences and model included, word for word, for each lane whose `docs/plans/<id>.md` holds `validated: yes`. A plan without that line never reaches an implementer.
4. **The QA stage**: `subagent_type: qa` — the model and the prompt `/po-qa` fixes (`method/commands/po-qa.md`), word for word, from its `## Delegation` through `## The evidence commit` (ADR-0102). Every qa of a wave leaves before any is waited on.
5. `subagent_type: reviewer` — the model and the prompt `/po-review` fixes (`method/commands/po-review.md`), word for word, at the `Fix loop:` its `## Fix loop` computes.

A lane that stops stays stopped and is reported. A lane that goes to a human goes to the person at once, in a message of its own naming the story, the reason and what the person must decide; it is not asked through AskUserQuestion, which would hold every other lane until the answer came. Meanwhile the other lanes carry on.

If the Agent tool rejects a model name, that lane stops, named in the report with the setting and its value; it is never redispatched with another model or with none, and the refusal is never recorded as a review or a QA report.

## Validating a wave's plans
The plans a wave produced are approved together, per `Plan validation`.

Under `autonomous`, nothing is asked: each plan comes back from its lane already holding `validated: yes`, checked against its own acceptance criteria by the planner that wrote it.

Under `human`, the whole wave goes into **one AskUserQuestion**, never one per story: a question per story would serialise the very lanes you started in parallel. The question shows, for each plan, the story id, its tasks and its test strategy, and the path `docs/plans/<id>.md`. Three answers:

| Answer | What it does |
| --- | --- |
| Approve every plan | every plan of the wave is approved, and each lane moves on to its implementer |
| Choose which ones | only the plans the answer names are approved; the others stay as they are |
| Stop the wave | nothing is approved, and no implementer is dispatched at all |

`validated: yes` is written through Bash, into the frontmatter of the plans the answer approved and of no other: you have neither Write nor Edit, and a plan nobody named is never approved on your own initiative.

A plan left unapproved keeps `validated: no`. No implementer is dispatched for it, its lane waits for the next wave, where the plan is offered again; the gate refusing it is the same `po-gate plan-validated <id>` as everywhere else, never your memory of the answer. On `Stop`, the plans stay on disk as the planners wrote them, and the next run resumes at the plan with nothing to redo.

## The verdict, and the fix runs
A reviewer's answer is recorded **verbatim** into `docs/reviews/<id>.md` in the lane's worktree, through `po record review <id>` as `## Recording` of `/po-review` says, its shape check, re-ask, stops and blocked report for a failed reviewer included. You transcribe it, you do not author it: no severity is yours to choose, no finding yours to soften or drop.

What a recorded verdict leads to, the next `po next` says.

## Ships, one at a time
Ships never overlap. `Merge mode: local` requires the repository root clean and on `Target branch`, and two merges would race; so you ship one story, prove it, then ship the next. Proving a ship means seeing it land or seeing it stop — a failure, a "Not now", a pull request left for a person — and the next one starts.

Each ship is `/po-ship` applied as written: `po-gate ship-allowed <id>` first — the **last** `Ship allowed:` line of `docs/reviews/<id>.md` must be `yes` **and** its `Reviewed tree:` must still match the code outside `docs/`, with both `Review status:` lines `complete`, or that ship stops. `Ship confirmation: human` means one AskUserQuestion per merge under `Merge mode: local`, and a pull request left for a person under `Merge mode: pr`; `automatic` lets the gate decide alone, unless the repository is collaborative.

Under an effective `human` with `Merge mode: pr`, opening the pull request ends that ship but is not the landing: you may open the next one at once. `po-gate ship-allowed <id>` is required before any merge, whatever the value of `Ship confirmation`.

## The decisions log
Once the ships are done, after the wave's last ship, record what the wave decided without the person (ADR-0077): append through Bash, to `docs/decisions-log.md` in the repository root, one row per decision — each story launched and each one held back, with why; each fix run started; each re-review of a late commit; each plan approved without a human; each track a planner raised to `full`; each lane handed to a human; each implementation detail you settled without the person; each answer you gave without asking. The file is created from `templates/decisions-log.md` when it is absent. Rows are dated `YYYY-MM-DD` and carry their reason, a security finding as its decision id, never its text; none already there is rewritten.

Land it as `## Landing the framing` of `/po-setup` says, slug `decisions-log`, path `docs/decisions-log.md`, message `docs: decisions log`. A stop of that landing ends the landing, never the wave's report; a log left uncommitted is landed by the next wave together with its own rows. Under `Merge mode: local` with an effective `human`, a "Not now" leaves `docs/decisions-log.md` staged in the root, so the next local ship stops on it until the log is landed.

`status` writes no row.

## Report
One table: story · stage reached · plan · verdict · shipped · models. It states, per lane and per stage, the model the subagent ran on — the value passed, or `session` when `—` passed none. Then, as `po next` gave them: each `wait` and `ask` with its reason; each held story with its `reason` and `ref`, plus `entry`, `ref_entry` and `path` for `owns`; the stories waiting for their framing pull request to merge, each with its start point; each orphan worktree as found. Then the lanes handed to a human; every pull request waiting for a human merge, with its URL; the merged lanes waiting for cleanup, each with its pull request URL and whether `/po-ship` cleaned it up; any `Ship confirmation` line a ship rewrote, with its draft URL; the decisions-log landing, or why it did not land; per shipped story, the issues filed in `Issue tracker`, the findings not filed and why (a security one never by its text), and each `Security findings:` line as written.

The plan column says who approved it. Under `Plan validation: autonomous`, the report states that the plans were approved without a human reading them and names the stories concerned; under `human`, it states which plans the wave approved and which ones are still waiting for the next wave. It also names every story whose design no human approved (ADR-0019).

The report states, per stage, the activity window of each lane — when its subagent started and when it answered — and whether those windows overlap. A stage whose windows do not overlap is reported as sequential. No line of the report claims that lanes ran at the same time unless their activity windows show it; the number of messages the dispatch took is not evidence of anything.

With `$ARGUMENTS` set to `status`, run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" state`, report what it returns, and launch or write nothing. Per lane in flight: the story, its next action and reason, its worktree path; a lane whose reason is `landed` is listed among them as a merged lane waiting for cleanup, with its pull request URL. Then what each held story waits for: its reason, or a pull request waiting for a human merge, with its URL.

Finish with the candidates of the next wave, or "Fleet idle: nothing is ready."
