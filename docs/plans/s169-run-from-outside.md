---
validated: yes
---
# Plan — s169-run-from-outside

[Story](../stories.md) · [Research](../research/s169-run-from-outside.md)

Branch `story/s169-run-from-outside`. Read `docs/research/s169-run-from-outside.md` first; this plan builds on it without repeating it.

## Story
An external agent launches and relaunches the project lead with `po run` and `po continue`, the command that already gives it the state and the inbox. Criteria, in short (full text in `docs/stories.md`):
1. `run_starts_one_lead_session` — one lead session at the project root, its only instruction the command `po state` announces; returns `session`, `started`, `command`.
2. `continue_resumes_after_an_answer` — resumes the stopped session `run` started; without one, launches like `run`.
3. `run_refuses_a_second_session` — `already-running` while it runs; `po state` carries `session.running` and `session.id`.
4. `run_refuses_unproven_bounds` — subagents only in `.claude/agents/` → `"bounds": "unproven"` and `bounds-unproven`; global installation → `"held"`.
5. `run_refuses_when_nothing_to_do` — framing done, no ready story, no lane, no answered decision to consume → `nothing-to-do`. Framing not done is never `nothing-to-do` (issue #241 m4, settled in the research).
6. `run_takes_no_free_text` — any argument is refused (`run` and `continue` document no option).
7. `docs_show_the_agent_loop` — documentation, judged in review.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Project, settings, framing, lanes, ready set, inbox | already in this repository: `Context::read` (`po/src/context/mod.rs:116`), `next::ready` (`po/src/next/mod.rs:92`), `Project::find` (`po/src/project.rs:38`) | — |
| One JSON object per reply, exit codes | already here: `output::reply`, `output::error` (`po/src/output.rs`) | — |
| Session record read and write, the launch lock | standard library (`OpenOptions::create_new`, rename), the pattern of `po/src/inbox/rewrite.rs:94-108` | `rewrite::take` is private to `inbox/`, outside `Owns`; about fifteen lines are copied rather than opening another story's folder |
| `started` with its offset | dependency already installed: `chrono` (ADR-0118), as `inbox/rewrite.rs:29-31` does | the helper is private to `inbox/` |
| Reading `claude agents --json` | dependency already installed: `serde_json::Value`, read tolerantly (ADR-0117) | — |
| A UUID for `--session-id` | standard library: 16 bytes of `/dev/urandom`, version 4 bits set | no crate in the lock file makes UUIDs, and none may be added (ADR-0118) |
| Launching Claude Code | standard library `std::process::Command`, program and arguments as separate values, never through a shell | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/run-from-outside.oracle.test.sh` | `1743346644 12735` |

| Criterion | Test |
| --- | --- |
| `run_starts_one_lead_session` | `test_run_starts_one_lead_session` |
| `continue_resumes_after_an_answer` | `test_continue_resumes_after_an_answer` |
| `run_refuses_a_second_session` | `test_run_refuses_a_second_session` |
| `run_refuses_unproven_bounds` | `test_run_refuses_unproven_bounds` |
| `run_refuses_when_nothing_to_do` | `test_run_refuses_when_nothing_to_do` (includes the framing case of m4: `/po-brief` launched with nothing ready) |
| `run_takes_no_free_text` | `test_run_takes_no_free_text` |
| `docs_show_the_agent_loop` | — documentation, judged in review; candidate for a `po-eval` control arm (#208) |

The oracle fixes these interfaces for the tasks: the program `po` launches is `$PO_CLAUDE` (default `claude`); a new session is `PO_CLAUDE --bg --session-id <uuid> <command>`, a resumed one `PO_CLAUDE --bg --resume <uuid> <command>`, launched with the project root as working directory; liveness is read from `PO_CLAUDE agents --json`; global subagents are read under `$CLAUDE_CONFIG_DIR/agents/`.

## Tasks
1. [x] **The session record and its liveness** — new `po/src/run/session.rs`. The record is `<git common dir>/polype/lead-session.json` (`{"session": <uuid>, "started", "command"}`), the common dir read with `project.git(["rev-parse", "--path-format=absolute", "--git-common-dir"])`, so worktrees share it and git never tracks it. `claude_program()` = `$PO_CLAUDE` when set and non-empty, else `claude`. Liveness: run `<program> agents --json` (stdin null, stderr dropped), parse a JSON array of `Value`; the recorded session runs iff one entry has `sessionId` equal to the recorded UUID **and** a non-null `pid`. `run::session(context)`: no record → `Some({running: false, id: null})` **without calling Claude Code**; a record → `Some({running, id: <first 8 characters of the uuid>})`; a record that does not parse, or a listing that cannot be run or parsed → `None`. Test: `test_run_refuses_a_second_session` (state's `session`), and `test_state_reads_only_files_and_git` of s164 (no `claude` call without a record).
2. [x] **Bounds** — new `po/src/run/bounds.rs`. Config dir = `$CLAUDE_CONFIG_DIR` when set and non-empty, else `$HOME/.claude`, else none. `held` iff `implementer.md`, `qa.md` and `reviewer.md` are all files under `<config>/agents/` **and** none of the three exists under `<root>/.claude/agents/` (Claude Code prefers the project's copy, whose hooks wait for the trust dialog); every other case `unproven`. `run::bounds` always returns `Some`. Test: `test_run_refuses_unproven_bounds`.
3. [x] **`po run` and `po continue`** — `po/src/run/mod.rs` (`main`, `resume`), plus a `launch.rs` if it reads better. In this order, each refusal printing one object and launching nothing:
   - any argument → exit 2 `unknown-option` (before reading the project);
   - not a project → exit 2 `not-a-project`, as `state` says it;
   - `Context::read`; take the lock `<git common dir>/polype/run.lock` (`create_new`, 50 tries of 20 ms, removed on `Drop`); still held → exit 1 `already-running`;
   - session `None` → exit 2 `session-unreadable`, naming the record or the listing; `running` → exit 1 `already-running`;
   - `bounds` `unproven` → exit 1 `bounds-unproven`;
   - the command: `framing` `None` → exit 2 `state-unreadable`; stage not `done` → `framing.next`; `done` → `/po-drive` when there is work: a lane on disk (`context.lanes` non-empty), a ready story (`next::ready` non-empty), or a decision `answered` with no `consumed`. No work and `lanes`, `ready` or `inbox` unreadable → exit 2 `state-unreadable`; otherwise exit 1 `nothing-to-do`;
   - launch with the project root as working directory, stdin null, stdout and stderr captured and never printed: `run`, and `continue` without a record → `--bg --session-id <new uuid> <command>`; `continue` with a stopped recorded session → `--bg --resume <uuid> <command>`. Spawn error or non-zero exit → exit 2 `launch-failed`, no record written;
   - write the record (temp file then rename), reply exit 0 `{"session": <8 chars>, "started", "command"}`.
   The command only ever comes from `framing.rs`'s fixed strings or `/po-drive`. Tests: the six oracle tests.
4. [x] **Task tests** — `tests/run-from-outside.test.sh`, same fixture shape as the oracle (copied, not sourced: sourcing would import its tests): `test_run_leaves_the_work_tree_clean` (after `po run`, `git status --porcelain` of the project is empty, nothing changed outside `.git`, and `.git/polype/lead-session.json` exists — the machine file s171 cleans); `test_launch_failure_records_nothing` (stand-in exits 1 → exit 2 `launch-failed`, then `po state` gives `{"running": false, "id": null}`); `test_unreadable_listing_is_never_guessed` (after a run, the stand-in's `agents --json` prints non-JSON → `po state` gives `"session": null`, `po run` exit 2 `session-unreadable`, no new launch).
5. [x] **s164's oracle follows** — `tests/state-as-json.oracle.test.sh`: line 136 checks only `shipped` as `null` (`session` and `bounds` are computed now); lines 151-156, the `run`/`continue` `not-built` loop, are removed, no verb being unbuilt any more. Lines 178-191 stay as they are. Test: the file itself, green.
6. [x] **The contract** — `docs/interface-agent.md`: line 5 no longer says verbs answer `not-built`; the lead's verbs (`next`, `record`, `inbox add`, `inbox --answered`, `inbox consume`) listed in a section of their own, outside the external agent's contract, pointing to where each shape is described; a section showing the loop of an external agent (`state` → `inbox` → `answer` → `continue`, and `run` to start); `## run et continue` gives the exit code of each refusal, the `nothing-to-do` condition of task 3 (framing done first), what `session` is (the short id `claude attach`, `claude logs` take), how `bounds` is decided; line 29 gains `session-unreadable`, `state-unreadable`, `launch-failed`. Judged in review.
7. [x] **Installation and README** — `docs/installation.md`: under « Limite de confiance », what `bounds` reports and on which files; in `## Les fichiers d'état`, the two machine files `po run` leaves (`<git common dir>/polype/lead-session.json`, `<git common dir>/polype/run.lock`, out of git, for s171 to clean); `PO_CLAUDE` named as the program `po` launches. `README.md`: one line pointing to `docs/interface-agent.md`. Judged in review.

## Scene viewpoints
—

## Run interdicts
- Empty diff outside `Owns`; inside it, `po/src/context/mod.rs`, `po/src/main.rs`, `po/src/output.rs`, `po/src/state/`, `po/src/next/`, `po/src/inbox/`, `po/src/project.rs`, `method/` stay untouched.
- `po/Cargo.toml` and `po/Cargo.lock`: empty diff (ADR-0118).
- No test launches the real `claude`: every call goes through `PO_CLAUDE`, and `tests/run.sh` keeps `CLAUDE_CONFIG_DIR` on a temp dir.
- `po/src/run/` never runs a shell (`sh`, `bash`, `-c`) and never puts an argument it received into the launched command.
- `po state` runs Claude Code only when a session record exists.
- `po run` writes nothing in the work tree: only under the git common dir.
- In `tests/state-as-json.oracle.test.sh`, only the assertions of task 5 change.
- `output::not_built` becomes unused and warns at build: leave it (`output.rs` is outside `Owns`); the lead files its removal.

## The pivot
`po` owns the session id (`--session-id <uuid>`) and reads liveness as "listed by `claude agents --json` with a `pid`". Ways it could be wrong:
- `claude --bg` ignores `--session-id` with `--bg`: the record names a session that does not exist, `po state` says not running, and `continue` resumes nothing. Compare: on the first real `po run`, `claude agents --json` must list the recorded `sessionId`. Nobody in this pipeline can run that check without launching a real session; the owner does it once.
- A session whose process runs but is not listed with a `pid` (or the reverse): `already-running` would miss it. Compare with the observed listing in the research and with Claude Code's documentation of `agents --json`.
- Claude Code preferring the user's subagent over the project's: then "both present" would hold, and the oracle's middle case would be stricter than needed, never weaker.

## Files touched
`po/src/run/mod.rs`, `po/src/run/session.rs`, `po/src/run/bounds.rs` (and possibly `po/src/run/launch.rs`), `tests/run-from-outside.oracle.test.sh` (written by the planner), `tests/run-from-outside.test.sh`, `tests/state-as-json.oracle.test.sh`, `docs/interface-agent.md`, `docs/installation.md`, `README.md`, plus `docs/research/`, `docs/plans/`, `docs/verif/` of the story.

## Test strategy
- Layer: the binary, end to end on a throwaway repository, as every `po` story does; Claude Code replaced by a stand-in through `PO_CLAUDE`, which is the only process boundary `po run` crosses. The stand-in is a hand-written double of a third-party CLI, shaped on its observed `agents --json` output: Claude Code cannot be started in a test without launching a model.
- Oracle: 6 tests. Task tests: 3 (task 4). Changed: `tests/state-as-json.oracle.test.sh` (task 5). Total new: 9, within `Test budget` 25.
- Not tested by a script: the documentation criterion (review); the real behaviour of `claude --bg --session-id` (the pivot, owner's first run).
- Full suite once at the end (`Full suite: execute-end`), through `po-run`.

## Done when
One commit on `story/s169-run-from-outside` with the code, its tests and these docs; `bash tests/run.sh` green; a review with no open critical finding; landed through a pull request.
