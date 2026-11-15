# Research — s184-session-shows-what-waits

[Story](../stories.md)

## Structuring facts
- Root cause #315: the `jq` program of `method/hooks/po-session.sh:48-76` builds its `W` ("Waiting for a human") lines from `lanes[].stops` (`:74`) and `orphan-worktree` warnings (`:75`) only; it never reads `.waiting`, which `po state` fills from the inbox (`po/src/state/mod.rs:56-63`). Input: any pending decision. Proof: reproduction below, `po state` gives `waiting: ["d-0001","d-0002"]` and the hook prints `Waiting for a human: nothing` (`:108-109`).
- Root cause #244: `po/src/context/framing.rs:81-85` reads the review only from `docs/reviews/stories.md`, and `:86` the architecture only from `docs/architecture.md`. This repository holds neither: 22 per-milestone files `docs/reviews/stories-m*.md` (last: `stories-m22.md:79`, `Stories ready: yes`). Proof: `po state` on this repository → `stories-review: none`, `stage: stories-review`.
- Deeper cause of #244, not in the story: this repository runs `Entry mode: —` (`AGENTS.local.md:24`), which `/po-stories-review` refuses (`method/commands/po-stories-review.md:26`); the lead has held one-off reviews under free names since M13 (`docs/decisions-log.md:84`). `po` agrees with the method (`po-stories-review.md:38` writes the single file); the repository is the odd one out. A choice waits for the owner: ADR-0126 (proposed).
- No count of answered-not-consumed decisions exists in `po state`; it is computed as a boolean in `po/src/run/mod.rs:170-172` and again, out of `Owns`, in `po/src/inbox/mod.rs:179`.
- Even with both #244 options applied, this repository's framing does not reach `done`: `design-system` stays `missing` because 77 stories have no `Surface` line (`po/src/context/stories.rs:153-154`). Outside this story.

## Diagnostic
**Reproduction #315** (scratch repo under `/tmp`, removed after; installed `po` 0.3.1 and the worktree's `method/hooks/po-session.sh`): `AGENTS.local.md` with `Decision inbox: .polype/inbox/`, `d-0001` pending, `d-0002` pending sensitive, `d-0003` answered. `po state` → `"waiting":["d-0001","d-0002"]`; hook → `Waiting for a human: nothing`; `po inbox --answered` → `["d-0003"]`, of which the hook says nothing.
**Reproduction #244**: `po state` at the repository root → `framing.stage: stories-review`, items `scope by hand · stories present · stories review none · architecture missing · design system missing`; `po-session` prints the same and `Waiting for a human: nothing`.
The oracle (`tests/session-shows-what-waits.oracle.test.sh`), run against the installed `po` with nothing built in the worktree, fails on the three defect criteria and passes `single_file_projects_read_the_same`: it bites on the code as it stands.

**Hypotheses**
| # | Hypothesis | Observation that would refute it | Verdict |
| --- | --- | --- | --- |
| H1 | `po state` does not list pending decisions | `waiting` holds the pending ids | discarded: `["d-0001","d-0002"]` |
| H2 | The hook never reads `.waiting` | a `jq` path on `.waiting` in the hook | kept: none in `po-session.sh:48-76` (read) |
| H3 | `Decision inbox` unread makes `waiting` null, so the hook has nothing | `waiting` non-null in the repro | discarded: setting set, list returned |
| H4 | `po` reads per-milestone review files under another name | a read of `stories-*` in `po/src` | kept as cause: only `framing.rs:81` (grep) |
| H5 | The single file exists but its last `Stories ready:` is not `yes` | `git show main:docs/reviews/stories.md` | discarded: file absent on `main` |

## Story
The session start lists the decisions waiting for the owner, and stops saying a stories review is missing when one exists per milestone. Criteria: `session_lists_pending_decisions` (ids under `Waiting for a human`, `nothing` only when nothing waits, a sensitive one by its id only); `session_counts_answered_not_consumed` (a count and a pointer to `po inbox --answered`); `this_repository_reads_reviewed` (per the owner's option); `single_file_projects_read_the_same`; `version_goes_up` (minor, three places).

## Current code
- `method/hooks/po-session.sh`: reads `po state` (`:33`), tags lines `P` (printed), `W` (waiting), `S` (setup, ends the report) (`:47-76`). `W` lines = lane stops (`:74`), orphan worktrees (`:75`), then CLAUDE.md hints added in bash (`:87-106`). `nothing` when no `W` line (`:108-109`). At `setup` stage only the `S` line prints (`:58`, `:81`).
- `po/src/state/mod.rs`: `State` (`:19-34`) serialises fields in declaration order; `waiting` = ids of `pending` decisions, `None` when the inbox is unreadable (`:56-63`).
- `po/src/context/mod.rs`: `Inbox { dir, decisions, unreadable }` (`:85-91`), read by `read_inbox` (`:189-207`); `None` when `Decision inbox` is missing or `—` (`usable`, `:65-72`).
- `po/src/run/mod.rs:161-193` `command`: `answered` = any decision `answered` with no `consumed`; counts as work for `/po-drive`.
- `po/src/context/framing.rs:54-127`: framing items and stage; `scope` is `by hand` under `Entry mode: —` (`:65`, `:74`).
- `docs/interface-agent.md:93` documents `waiting`; `:96` the framing items; `:30` says an added field keeps `contract: 1`.

## Attachment points
- `Inbox` in `po/src/context/mod.rs`: one method for "answered, not consumed", used by `run::command` and `state::compose`.
- `State` in `po/src/state/mod.rs`: a new field after `waiting`.
- The `jq` program of `po-session.sh`: `W` lines from `.waiting`, a `P` line from the new field, inside the non-`setup` branch.
- `docs/reviews/stories.md` (option 1-B): new file on the story branch.

## Verified interfaces
- `Decision { id: String, sensitive: Option<bool>, status: String, consumed: Option<Value>, .. }` — `po/src/inbox/decision.rs:49-69`; decisions come sorted by id number (`:101-105`).
- `po inbox --answered` → `{"contract":1,"answered":[<decision>…]}` (`po/src/inbox/mod.rs:170-189`, `docs/interface-agent.md:201`).
- `Project::on_target(target, path)` = `git show <target>:<path>` (`po/src/project.rs:92-94`): `po state` reads framing files on `main`, never the working tree.
- Version: `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27`, all `0.3.2`; `bin/po-version-check` refuses a `po/` diff without a raise in the three (ADR-0125).
- Tests run the hook with the built `po` copied to `$CLAUDE_CONFIG_DIR/polype/po` (`tests/run.sh:23-27`).

## Traps
- `tests/commands-read-po-state.oracle.test.sh:95` counts exactly 7 `- ` lines on a stub state with `"waiting":[]` and no `answered` key, and `:96` refuses the text `Decision inbox`: the new `P` line must not start with `- ` nor name the setting.
- `tests/state-carries-session-lines.oracle.test.sh:151-172` rebuilds the session lines from `po state` (`SESSION_LINES`) and compares lines starting with `Framing`, `Lanes in flight:`, `Waiting for a human`, `- ` (`:178`): pending-decision lines start with `- ` and must enter `SESSION_LINES`; its fixtures set no `Decision inbox`, so today they hold no decision.
- `tests/verbs-read-project-context.oracle.test.sh:18-26` (`normalised`) compares the whole `po state` object: a new field must be dropped there or written into each expected object.
- `tests/project-lead.test.sh:105` pins the whole output at `setup` stage: nothing new may print there.
- `tests/artifact-links-backfill.test.sh:120-123` refuses a `[Story](` line under the title of any `docs/reviews/stories*.md`: `stories-m22.md` has none.
- `this_repository_reads_reviewed` cannot run `po state` on the worktree itself: `on_target` reads `main`, which lacks the file until the ship. The oracle copies the working tree's settings, stories and reviews into a scratch repository on `main`.
- `.polype/hooks/po-session.sh` (installed, 0.3.1) is not changed: this repository's own session shows the fix only after the copies are refreshed.
- `docs/reviews/stories.md` is a framing file (Law 6); here it travels on the story branch because the story `Owns` it.

## Open questions
- The owner's two choices of ADR-0126 (review file; `architecture` under `Entry mode: —`). The plan is written for 1-B and 2-A.
- Should the hook ever show a decision's question for a non-sensitive decision? The criterion asks for ids; the plan prints ids only, so the sensitive rule holds by construction.
- The design-system gap (77 stories without `Surface`) and `/po-stories-review` refusing `Entry mode: —` keep this repository's framing from `done`; to be filed, not fixed here.

## Complexity
3 → 3 under options 1-B and 2-A: two local code changes, one field, one documentation file, a version raise. Option 1-A or 1-C would raise it to 4 (a file-naming rule, and for 1-C method files out of `Owns`).

## Split
Not needed at 3.
