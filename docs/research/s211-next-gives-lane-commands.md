# Research — s211-next-gives-lane-commands

[Story](../stories.md)

## Structuring facts
- **Track.** `po next` gave `flow` (complexity 3 = `Flow threshold` 3). The planner took the full track: the story text carries an escalation signal, an API contract — `po next`'s JSON, written in the versioned contract `docs/interface-agent.md`, gains a field, and every verb gains `--help`. s190 took the full track on the same signal (`docs/plans/s190-next-names-the-track.md:10`).
- **No false assumption.** The lane-opening steps are where the story says, `method/commands/po-research.md:22-33`; `po next` already knows the start point (`po/src/context/start.rs:15-27`) and the lane path rule (`po/src/context/lanes.rs:208`). Nothing gives commands today: a ready entry is `{story, action: plan, reason: ready, track}` (`po/src/next/mod.rs:49-62,96`).
- **Unsaid by the story: a missing `Install` cannot ask.** Every `po next` fixture (`tests/driver-next-action.oracle.test.sh:24-63`, sourced by five other test files) writes no `Install` line and expects ready stories at `[plan, ready]` (`:194-196`). Those files sit outside `Owns`, so a missing `Install` gives `commands: null` (the contract's rule for a value `po` cannot read, `docs/interface-agent.md:30`), never an `ask`.
- **Unsaid by the story: the word budget has no slack.** `po-drive.md` counts 2266 words for a ceiling of 2266, `po-research.md` 509 for 509 (`method/word-budget`, `LC_ALL=C awk '{n+=NF}'`). Every word the change adds is paid for in the same file.
- **`--help` today is refused by every verb**: `po state --help` → `unknown-option`, exit 2 (observed); `run`/`continue` refuse any argument before launching (`po/src/run/mod.rs:73-81`).

## Story
`po next` gives the lead the exact commands that open each lane, and every verb of `po` says how to call it, so a lead under the sandbox opens its lanes and can raise a decision (#508, #478; owner's choice of 2026-11-24, not reopened). Criteria:
- `next_gives_lane_commands` — literal commands for a lane to open; each git one a single call starting `git -C <absolute root>`, absolute paths, no variable, loop or substitution.
- `drive_runs_them_as_given` — `/po-drive` runs them one by one as given; no ceiling of `method/word-budget` rises. Model-read.
- `every_verb_has_help` — `po <verb> --help` gives the verb's usage, for `inbox add` the JSON form; exit 0, writes nothing.
- `records_are_landed` — `docs/evals/real-2026-11-24-v0.12.0-2.md` committed as the run wrote it. Review-judged.

## Current code
- `po/src/main.rs:12-38` — dispatch on the first argument; no `--help` anywhere. Verbs: `state next inbox answer record run continue ship`.
- `po/src/next/mod.rs:72-105` — `po next`: lane entries from `lane::next`, then one entry per ready id from `lane::plan(&context, id, "ready")` (`:95-97`). `Entry` (`:49-56`) serialises `story, action, reason, track?`.
- `po/src/next/lane.rs:181-208` — `plan()` gives `plan` with its track, or an `ask` (`setting unreadable: …`, `no complexity`).
- `po/src/next/wave.rs:9-78` — the ready set: a story is ready only when the start point holds it (`:70-74`); orphaned branches are skipped (`:37-49`).
- `po/src/context/start.rs:15-27` — start point `origin/<target>` when `refs/remotes/origin/<target>` exists, else `<target>`; read locally, no fetch.
- `po/src/context/lanes.rs:200-241` — a lane is a worktree whose canonical path is `prefix + id` on `story/<id>`, `prefix` being `Worktree root` if absolute, else `<root>/<Worktree root>` (`:208`).
- `po/src/project.rs:20-33` — read-only `git()` with `GIT_OPTIONAL_LOCKS=0`; `Project.root` is canonical (`:41`).
- `po/src/inbox/add.rs:17-34` — `inbox add` reads one JSON object on stdin; shape `NewDecision` (`po/src/inbox/decision.rs:22-48`, `deny_unknown_fields`): `motive`, `sensitive?`, `question`, `context?`, `options[{key,label,consequence}]`, `recommended`, `why`, `reversible`, `story?`, `blocks`.
- Usage strings already exist: `po/src/record/mod.rs:71`, `po/src/ship/mod.rs:18-20` (and per step in `land.rs:14`, `push.rs:21`, `file.rs:22`, `clean.rs:19`). `po state` options `--all`, `--remote` (`po/src/trust/mod.rs:39-49`); `po next` option `--remote` (`po/src/next/mod.rs:73`); `po inbox` forms (`po/src/inbox/mod.rs:58-67`); `po answer <id> <key>` (`:71-75`).
- `method/commands/po-research.md:20` — by hand, `po next` runs after step 1 (the fetch); `:22-33` — the four steps: fetch and start point, `git worktree add -b`, copy of the ignored `.env*` (stop on an `.env*` git does not ignore), `Install` (skip on `—`).
- `method/commands/po-drive.md:34` — `plan` row: "reason `ready` → prepare the worktree first"; `:50` — no `cd`, every git command `git -C <absolute path>`; `:52-53` — lanes prepared "by the steps of `## The worktree` in `/po-research`".
- `docs/interface-agent.md:25-31` — common rules (one JSON object, `contract: 1`, a field added keeps the number, unreadable → `null`); `:104` — `lanes[].next` and `plan`'s `track`; `:270` — the `next` row of the lead's verbs; `:169-186` — `inbox add`.
- Version 0.12.0 in `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:28`; `bin/po-version-check` refuses a `po/` diff without a bump of all three (`tests/po-change-needs-a-version.oracle.test.sh`), run in CI.

## Attachment points
- A new `po/src/next/open.rs`, called from `po/src/next/mod.rs:96` for each ready id whose action is `plan`; `Entry` gains `commands`.
- `po/src/context/lanes.rs:208` — the prefix computation, extracted so `open.rs` builds the very path `lanes()` recognises.
- A new `po/src/help.rs`, called from `po/src/main.rs` before dispatch.
- `method/commands/po-drive.md:34,52-53`, `method/commands/po-research.md:20-33`, `docs/interface-agent.md:25-31,270`.

## Verified interfaces
- `lane::plan(context: &Context, id: &str, reason: &str) -> NextAction` (`po/src/next/lane.rs:181`); `NextAction { action, reason, track }` (`po/src/next/mod.rs:24-29`), also carried by `po state` (`lanes[].next`), which has no ready entries: a field on `Entry` alone stays out of `po state`.
- `Context.start: Option<StartPoint>`, `StartPoint.reference: String` (`po/src/context/start.rs:9-12`).
- `Project::setting(name) -> Setting::{Missing, Value}` (`po/src/project.rs:55-67`).
- `output::reply(body, code)` adds `contract: 1` (`po/src/output.rs:31-34`).
- `PO_CLAUDE` names the launcher `po run` calls in tests (`tests/run-from-outside.oracle.test.sh:78`).

## Traps
- **The sandbox facts (lead, observed 2026-11-24).** A command that starts with `git -C <abs>` runs outside the sandbox and is allowed; one that starts with an assignment or a loop stays inside, where `.git` is protected, so `git worktree add` creates the branch and not the worktree. The fourth run left exactly that: branches `story/<id>` with no worktree. `git worktree add -b` then fails on the existing branch; without `-b`, it checks the branch out.
- **`cd` in the lead's shell persists** in Claude Code's main session, and `po-drive.md:50` forbids leaving the start directory: `Install` must run where the lane is without moving the lead — a subshell `(cd <lane> && <Install>)` does not move it. `bin/po-lint`'s s210 rule scans `method/` only, not `po`'s output.
- **Paths may hold spaces**: the commands need shell quoting of every path (`'…'`, `'` written `'\''`); no helper in `po/` does it today (`grep quote po/src`).
- **`.env*` pathspec**: `git ls-files --others --ignored --exclude-standard -- '.env*'` matches top-level names; a matched path holding `/` needs its folder in the lane. An untracked `.env*` git does not ignore would be committed: po-research stops on it today (`:30`).
- **`po next` is read-only** (`po/src/project.rs:18-19`): the fetch is a command for the lead, never run by `po`.
- Tests that touch this: `tests/driver-next-action*.sh`, `next-names-the-track.oracle`, `held-says-what-collides.oracle`, `next-waits-on-dependencies.oracle`, `ship-order-and-closed-pr*` (ready entries compared on `[action, reason]` only — a new field passes), `tests/decision-inbox.test.sh:43-45`, `tests/run-from-outside.oracle.test.sh:302-314` (arguments refused; `--help` is not among them), `tests/word-budget-is-linted*` and `tests/lint.test.sh` (ceilings).
- No migration. The record `docs/evals/real-2026-11-24-v0.12.0-2.md` is outside the repository (`/home/lecrabe/.claude/jobs/c268121d/tmp/records/`), cksum `589271514 851`, checked; the raw streams stay out.

## Open questions
- Missing `Install`: `commands: null` (chosen, see Structuring facts) — the lead then asks the person, naming the setting.
- `--help` shape: one object `{contract, verb, usage}`; `usage` reuses the existing one-line strings rather than a list. `inbox` also carries `input`.

## Complexity
3 → 4: two features of `po` (lane commands with their edge cases — remote, existing branch, quoting, unignored `.env*`; help for eight verbs), two method files at a zero word margin, the contract and the version.

## Split
—
