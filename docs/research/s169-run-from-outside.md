# Research — s169-run-from-outside

[Story](../stories.md)

## Structuring facts
- Root cause of #204's remaining part: `po run` and `po continue` are stubs that answer `not-built` (`po/src/run/mod.rs:23-29`), and `run::session` and `run::bounds` give `None` (`po/src/run/mod.rs:31-37`), so `po state` prints `"session": null, "bounds": null` (`po/src/state/mod.rs:79-80`). Reproduced below.
- Wrong as written, settled by reading (issue #241, m4): `run_refuses_when_nothing_to_do` names no framing condition, and a project in framing has no ready story. Criterion `run_starts_one_lead_session` makes `run` launch "the missing framing stage", so `nothing-to-do` can only hold once `framing.stage` is `done`. The plan reads it that way and the oracle checks it (`/po-brief` launched with nothing ready). No change to the story text is needed.
- The contract's `nothing-to-do` row (`docs/interface-agent.md:204`) omits "no lane in flight", which the story's criterion adds; the contract follows the story.
- s164's oracle pins what this story changes: `session` and `bounds` must be `null` (`tests/state-as-json.oracle.test.sh:136`), `run`/`continue` must say `not-built` (`:151-156`), and `po state` must call no `claude` at all (`:178-191`). The file is in `Owns`; lines 136 and 151-156 change, 178-191 stay and hold as long as `po state` asks Claude Code only when a session was recorded.
- Liveness has a reliable reader: `claude agents --json` prints every listed session as JSON, without a TTY, in about 0.15 s; an entry whose process is alive carries a `pid`, a stopped one does not (observed, see `## Verified interfaces`). A lock file alone cannot tell a stopped session from a running one, since `claude --bg` returns at once and its process is not `po`'s child.

## Diagnostic
Reproduction, on `po` built from `main` at `b979845` (the start point of this lane):
```
$ po run        → {"contract":1,"error":"not-built",...}  exit 2
$ po continue x → {"contract":1,"error":"not-built",...}  exit 2
$ po state      → "session":null,"bounds":null
```
| Hypothesis | Refuting observation | Verdict |
| --- | --- | --- |
| The verbs are dispatched but their folder is a stub | `main.rs:27-28` routes `run`/`continue` elsewhere than `run::main`/`run::resume` | kept: `po/src/main.rs:27-28` routes to `run::main`/`run::resume`, which return `output::not_built` (`po/src/run/mod.rs:24,28`) |

#204 is a missing capability, not a regression: no earlier code launched a session.

## Story
An external agent launches and relaunches the project lead with the same command that gives state and inbox. Criteria:
1. `run_starts_one_lead_session` — `po run` launches one lead session at the project root through a command the test replaces; the only instruction is the command `po state` announces (missing framing stage, else `/po-drive`); returns `session`, `started`, `command`.
2. `continue_resumes_after_an_answer` — with a session started by `run` then stopped and an answered unconsumed decision, `po continue` resumes it; without a known session it launches like `run`.
3. `run_refuses_a_second_session` — while a session started by `run` runs, `run`/`continue` give `already-running`; `po state` carries `session.running`, `session.id`.
4. `run_refuses_unproven_bounds` — subagents only in the repository's `.claude/agents/` → `"bounds": "unproven"`, `run` gives `bounds-unproven`; global installation → `"held"`.
5. `run_refuses_when_nothing_to_do` — no ready story, no lane, no answered decision to consume → `nothing-to-do` (and framing done, above).
6. `run_takes_no_free_text` — any argument that is not a documented option is refused.
7. `docs_show_the_agent_loop` — documentation, judged in review.

## Current code
- `po/src/main.rs:23-46` — dispatch; `run` → `run::main(&rest)`, `continue` → `run::resume(&rest)`. Not touched.
- `po/src/run/mod.rs` — `Session {running: bool, id: Option<String>}` (`:11-14`), `Bounds {Held, Unproven}` serialised lowercase (`:16-21`), the four stubs (`:23-37`). The whole file is this story's.
- `po/src/state/mod.rs:79-80` — `state` already calls `run::session(context)` and `run::bounds(context)`; filling them fills `po state`.
- `po/src/context/mod.rs:96-112` — `Context` holds `project`, `framing`, `lanes`, `inbox` (decisions with `status` and `consumed`), all `pub`. `Context::read` (`:116`) reads everything once.
- `po/src/context/framing.rs:46-90` — `framing.stage` ∈ setup/scope/stories/stories-review/architecture/design-system/done, `next` a fixed `/po-…` string or `None` at `done`; a project without `AGENTS.local.md` is `setup` (`context/mod.rs:135-141`).
- `po/src/next/mod.rs:92` — `pub fn ready(context) -> Option<Vec<String>>`, `None` when stories, lanes or `Parallel` cannot be read (`next/wave.rs:9-17`).
- `po/src/project.rs:38-47` — `Project::find` resolves the main checkout from any worktree through `--git-common-dir`; `project.root` is canonical. `project::git` runs git with `GIT_OPTIONAL_LOCKS=0`.
- `po/src/output.rs` — `reply`, `error`, `REFUSED = 1`, `UNREADABLE = 2`; one object per call, panic hook included.
- `po/src/inbox/rewrite.rs:94-108` — the lock pattern of the crate: `OpenOptions::create_new`, 50 tries of 20 ms, removed on `Drop`. Private to `inbox/`; `run/` writes its own few lines.
- `po/src/inbox/rewrite.rs:29-31` — the date format: `chrono::Local::now().to_rfc3339_opts(Secs, false)`; private, but `chrono` is a dependency (ADR-0118).

## Attachment points
- `po/src/run/mod.rs`: `main`, `resume`, `session`, `bounds`. New submodules under `po/src/run/` as needed.
- `docs/interface-agent.md` `## run et continue` (`:190-206`), line 5 (verbs still `not-built`), line 24 (the lead's verbs), line 29 (error codes).
- `docs/installation.md:154-158` (« Limite de confiance »), `## Les fichiers d'état` (`:314-327`).
- `README.md` — no line points to `interface-agent.md` today (grep).

## Verified interfaces
- `claude --help` (this machine): `--bg` "Start the session in the background and return immediately. Prints the id that `claude attach`, `logs`, `stop` and `rm` take"; "With --resume <session-id>, continues that session in the background under the same ID, or starts a copy and says so when the session is already running"; `--session-id <uuid>` "Use a specific session ID for the conversation (must be a valid UUID)".
- `claude agents --help`: `--json` "Print active sessions (interactive and background) as a JSON array and exit (for scripting; does not require a TTY)"; `--all` adds completed ones; `--cwd <path>` filters.
- `claude agents --json` output, observed: objects with `id` (8 hex, the prefix of `sessionId`), `sessionId` (UUID), `cwd`, `kind`, `startedAt`, `state` (`working`, `done`, `blocked`), and `pid` + `status` only on entries whose process runs. Three entries with `state: blocked` and no `pid` are listed. Runtime 0.15 s.
- Bounded subagents: `implementer`, `qa`, `reviewer` are the ones whose frontmatter calls `po-bounds` (`grep -l po-bounds method/agents/*.md`). Global ones live in `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents/` (`docs/installation.md:44-51`), a project install puts them in `.claude/agents/` (`docs/installation.md:228-232`). Claude Code prefers a project subagent over a user one of the same name (Claude Code's subagent documentation; not re-read in this session).
- `tests/run.sh:13-16` points `CLAUDE_CONFIG_DIR` at an empty temp dir for the whole suite, so no test sees the developer's `~/.claude`.

## Traps
- `tests/state-as-json.oracle.test.sh:136` and `:151-156` change (above). `tests/verbs-read-project-context.oracle.test.sh:20` deletes `.session` and `.bounds` before comparing: unaffected, and outside `Owns`.
- `test_state_reads_only_files_and_git` (`state-as-json.oracle.test.sh:164-201`) fails if `po state` runs `claude`: no session file in that fixture, so `run::session` must not call Claude Code when nothing is recorded.
- `test_state_prints_one_json_object` runs `po state` with no subagents anywhere: `bounds` becomes `"unproven"` there, which line 136 must accept.
- After this story no verb answers `not-built`; `output::not_built` (`po/src/output.rs:46`) becomes dead code and warns at build. `output.rs` is outside `Owns`: leave it, file the clean-up.
- Polype's own checkout has its subagents in `.claude/agents/` (project install, `.polype/mode` = `project`): `po state` on Polype will say `"bounds": "unproven"`, which is true.
- `po run` writes, so it must stay out of git: the session record goes under the git common dir, never in the work tree; worktrees share it.
- `claude --bg` stdout is meant for people; parsing it is avoided by passing our own `--session-id`.
- s170 also owns `docs/interface-agent.md` and runs after s169; s171 cleans the machine files this plan names.
- No migration.

## Open questions
- Does `claude --bg` honour `--session-id`? The help lists both, nothing says they combine. Nobody can check it without launching a real session; the first real `po run` by the owner confirms it (`claude agents --json` lists that `sessionId`).
- Does a session the owner stops with `claude stop` stay listed without a `pid`, or leave the list? Both read as "not running" under the plan's rule, so the rule holds either way.
- Should a lane whose next action is `wait` count as "in flight"? The story says "lane en cours"; the plan counts every lane on disk, which never refuses work the lead could do (a landed lane still needs its cleanup).

## Complexity
Story: 4 → after reading: 4. The verbs plug into a context that already holds framing, lanes, ready and inbox; the risk the story names (launching without anyone watching) is real, and two facts rest on observation of an external CLI rather than its documentation.

## Split
— (not at 5)
