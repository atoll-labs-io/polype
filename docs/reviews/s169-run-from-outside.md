# Review — s169-run-from-outside

[Story](../stories.md) · [Plan](../plans/s169-run-from-outside.md) · [Verification](../verif/s169-run-from-outside.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s169-run-from-outside`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 2db51225d69bdc79a43f1c5fd279d94025b114d7

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s169-run-from-outside`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. These are `po/src/run/{mod,session,bounds}.rs`, `README.md`, `docs/installation.md`, `docs/interface-agent.md`, `tests/run-from-outside{.oracle,}.test.sh` and `tests/state-as-json.oracle.test.sh`, plus the story's own research, plan and verif files.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none. The only other worktree is `story/s173-drive-executes-next`. That branch is an ancestor of `main` and its `Owns` (`method/commands/…`, `tests/drive*…`) does not overlap this one. s172 also owns `docs/interface-agent.md` and `po/src/context/mod.rs`, but it has no worktree.
- [ ] No `Owns` line on this story → not applicable

## Evidence reused
- [x] `po-gate verif-current s169-run-from-outside` → exit 0, so the record is reused. The unit suite `bash tests/run.sh` passed with exit 0 on tree df01d7f…, and the gate confirms that its code outside `docs/` matches. The project has no type check command (`Typecheck: —`). The record says `cargo build --release --locked` in `tests/run.sh` type-checks the Rust. I read its "Not proven here" section, and it is carried into Not verified below.
- [x] `po-gate qa-current` → not required, because `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–7 are all present, and nothing lies outside the plan. One deviation, which is justified: the launched child's stdout and stderr go to `Stdio::null()` instead of being "captured". The code comment gives the reason: a background child holding an inherited pipe would keep `po` waiting.
- [x] Each run interdict checked:
  - The diff is empty outside `Owns`, and `context/mod.rs`, `main.rs`, `output.rs`, `state/`, `next/`, `inbox/`, `project.rs` and `method/` are untouched.
  - The diff of `Cargo.toml` and `Cargo.lock` is empty.
  - Every launch goes through `PO_CLAUDE`, and `tests/run.sh` pins `CLAUDE_CONFIG_DIR` to a temp dir.
  - There is no shell in `po/src/run/`: `Command::new` takes separate arguments, and no received argument is forwarded.
  - `po state` calls Claude Code only when a record exists (`session::current`).
  - Nothing is written to the work tree; `test_run_leaves_the_work_tree_clean` covers this.
  - The s164 oracle changes only as task 5 says.
  - `output::not_built` is left as planned.

## References
- [x] Every call was opened and confirmed: `output::{reply,error,OK,REFUSED,UNREADABLE}` (`po/src/output.rs:5-37`), `Project::{find,git,root}` (`po/src/project.rs:8-69`), `Context` fields `framing`, `lanes` and `inbox` (`po/src/context/mod.rs:96-111`), `Framing.next: Option<String>` (`po/src/context/framing.rs:14`), `next::ready -> Option<Vec<String>>` (`po/src/next/mod.rs:92`), and `Decision.status` / `consumed` (`po/src/inbox/decision.rs:61-66`). The callers `main.rs:27-28` and `state/mod.rs:79-80` match the signatures.
- [x] The values that only look right are confirmed:
  - The CLI flags `--bg`, `--session-id` and `--resume` are confirmed by the research's quote of `claude --help`.
  - Liveness ("pid present") is confirmed by the research's observed `agents --json` listing.
  - The UUID v4 bit masks are correct.
  - The command strings come only from the fixed strings in `framing.rs:78-90` or from `/po-drive`.

## Rules
- [x] The `AGENTS.md` conventions are respected. Tests are bash, the oracle sits in `tests/<slug>.oracle.test.sh`, and the documentation is in French.
- [x] No accepted ADR is contradicted. No crate was added (ADR-0118), unknown values are `null` and never guessed (ADR-0117), and the transport is unchanged (ADR-0107).

## Tests
- Oracle: `po-gate oracle-intact s169-run-from-outside` → exit 0
- [x] Oracle: `po-gate oracle-intact` → 0. The plan names no oracle changes, and the record's `## Oracle changes` is empty.
- [x] Floor: `po-gate floor-guard s169-run-from-outside main` → 0, nothing lowered.
- [x] The assertions pin down criteria 1–6. None of the six empty test shapes appears. The stand-in for Claude Code is a third-party CLI double that the plan's test strategy justifies.
- [x] Within `Test budget`: 9 new tests out of 25.
- [x] Bite 1: in `session.rs`, I removed the `pid` condition from `is_running`. 3 tests failed (`continue_resumes_after_an_answer`, `run_refuses_a_second_session`, `run_refuses_when_nothing_to_do`). I undid it, and `git diff --exit-code` was clean.
- [x] Bite 2: in `bounds.rs`, I removed the "no copy in `.claude/agents/` of the repository" condition. 1 test failed (`run_refuses_unproven_bounds`). I undid it, and `git diff --exit-code` was clean.
- [x] Bite 3: in `mod.rs:170`, I removed `&& d.consumed.is_none()`. 0 tests failed, so that clause is untested (see Findings). I undid it, and `git diff --exit-code` was clean.
- [x] The tests the story made useless (the `not-built` loop of the s164 oracle) were removed, as task 5 says.

## Neighbours
- [x] `state/mod.rs:79-80` now receives computed `session` and `bounds`. `test_state_reads_only_files_and_git` and `test_state_prints_one_json_object` pass (I ran `state-as-json.oracle.test.sh`: 6/6). `main.rs` dispatch is unchanged.

## Lenses
Lenses run: none. `po/src/run/` names no auth, routes or migrations. The diff has no lockfile or manifest change and no server-side query code.
- [x] Not applicable

## Findings
- major — po/src/run/mod.rs:45 — The launch lock leaks on any abnormal exit and then blocks `run` and `continue` forever. `Lock` is removed only by `Drop`. `output::install_panic_hook` (`po/src/output.rs:55-72`) ends a panic with `std::process::exit`, which runs no destructors, and a SIGKILL during `claude --bg` has the same effect. After that, `take` (`mod.rs:213`) hits `AlreadyExists` 50 times, and every later `po run` or `po continue` answers `already-running` ("another po is launching the lead"). `docs/interface-agent.md` tells an external agent that `already-running` means "the lead is still working: nothing to relaunch". The agent therefore stops quietly while `po state` says `running: false`, and nobody is told. Fix: detect a stale lock, for example with a pid written inside it or an age limit, or report it with its own code.
- major — po/src/run/bounds.rs:26 — `held` is decided only by whether files named `implementer.md`, `qa.md` and `reviewer.md` exist under `<config>/agents/`. Nothing checks that those files are Polype's subagents carrying the `po-bounds` hook (`method/agents/reviewer.md:16`), or that the project has `.polype/hooks/po-bounds.sh`, which that hook calls. A user's own `~/.claude/agents/reviewer.md` with the same common name would report `held` and let an unattended session start without the bounds. The story's risk line says `run` refuses when it cannot prove the bounds will hold, and file existence does not prove that. This matches the plan (task 2), so the gap belongs to the plan as much as the code. This is a security matter: under `AGENTS.md` Law 7 it goes to the person, not to the tracker.
- minor — po/src/run/mod.rs:170 — No test covers the `consumed.is_none()` clause of the work test (bite 3: 0 failing tests). The code is correct today, but a project whose only decisions are answered and already consumed is not tested to give `nothing-to-do`. A test with one answered and consumed decision would hold it.
- minor — docs/interface-agent.md:29 — The exit-code list still names `not-built` ("un verbe pas encore construit"), but since this story no verb returns it. It should leave together with `output::not_built`, whose removal the plan left to the lead.

## Not verified
- Whether the real `claude --bg` honours `--session-id`, and whether it lists that `sessionId` with a `pid` in `claude agents --json` while it runs. Every test goes through the `PO_CLAUDE` stand-in. The owner should run `po run` once for real, then `claude agents --json`, and check that the recorded UUID appears with a `pid`.
- Whether a session is already listed with a `pid` the moment `claude --bg` returns. If it is not, a `run` or `continue` arriving right after a launch could read "not running" and start a second session, or resume a session that is still starting. I could not observe this without a real session. The owner should run `po run` and then `po run` again immediately, and check that the second one answers `already-running`.
- Whether `claude attach <id>` and `claude logs <id>` accept the 8-character short id that `po` returns, as `docs/interface-agent.md` states. The research quotes the `--bg` help ("Prints the id that `claude attach`, `logs` … take"), but I did not run the commands. The owner should check this with the id returned by the first real `po run`.
- Whether Claude Code really prefers the repository's `.claude/agents/` copy over the global one, which `bounds` relies on. I found no documentation here. The owner should confirm it from Claude Code's documentation.
- The documentation criterion `docs_show_the_agent_loop`, judged by reading: the loop section, the refusal table with exit codes, the `session` and `bounds` definitions and the machine files in `installation.md` are present and match the code. No script tests it; it is a candidate for a `po-eval` control arm (#208).
- I did not rerun the full suite; I reused the record. The record's first run (exit 1) was on code that was not committed yet (issue 254). I did not investigate it, because the gate counts only the passing run on the committed code.
- Formatting and lint: the project has none.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s169-run-from-outside` (commits ad578cb and a1b4219), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: c2de6a23604250f851fb5dac09b278e501ba39f1

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-status main...story/s169-run-from-outside` and held each path against the story's `Owns`.
- [x] Every path is inside `Owns`: `po/src/run/{mod,session,bounds}.rs`, `README.md`, `docs/installation.md`, `docs/interface-agent.md`, `tests/run-from-outside{.oracle,}.test.sh` and `tests/state-as-json.oracle.test.sh`. The story's own research, plan, verif and review files are also in the diff.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none. The only other worktree is `story/s173-drive-executes-next`, and it is an ancestor of `main` (`merge-base --is-ancestor` exits 0).
- [ ] No `Owns` line → not applicable

## Evidence reused
- [x] `po-gate verif-current s169-run-from-outside` → exit 0. The unit suite `bash tests/run.sh` passed (exit 0) on tree cc934cb…, and the gate confirms that the committed code outside `docs/` matches it. The project has no type check (`Typecheck: —`); `tests/run.sh` builds the crate first with `cargo build --release --locked`. I read the record's "Not proven here" and carried it into Not verified below. Two of the record's runs failed (exit 1), and both are explained in the record: issue 254 and a doc table row over 100 characters. Each was followed by a passing run.
- [x] `po-gate qa-current` → not required (`QA stage: —`).

## Plan
- [x] Tasks 1–7 are still present. The fix commit addresses the three findings of loop 0, and the owner chose option a of d-0011 ("un passage de correction avant de livrer"):
  - The stale launch lock is now taken over when its pid is dead or the lock is older than ten minutes (`mod.rs:237-276`).
  - `held` now requires Polype's exact `po-bounds` hook block in each global subagent, plus an executable `.polype/hooks/po-bounds.sh` (`bounds.rs:26-62`).
  - A consumed answer is now tested.
- [x] The run interdicts still hold:
  - No change to `Cargo.toml` or `Cargo.lock`.
  - No shell is used. `kill` is called as `Command::new("kill")` with separate arguments, and none of them comes from the caller.
  - Nothing is written to the work tree.
  - `output.rs` is untouched.

## References
- [x] `carries_hook` matches the frontmatter of `method/agents/{implementer,qa,reviewer}.md` line for line. I diffed the globally installed copies in `~/.claude/agents/` against `method/agents/`, and their headers are identical. So a real global install reads `held` and is not locked out.
- [x] `state/mod.rs` still calls `run::session` and `run::bounds` with the same signatures. `bounds` only reads files, so `po state` still runs no process unless a session record exists.

## Rules
- [x] The `AGENTS.md` conventions are respected: tests are bash, docs are in French, comments are in English.
- [x] No accepted ADR is contradicted: no crate was added (ADR-0118), and an unreadable value is never guessed (ADR-0117).

## Tests
- Oracle: `po-gate oracle-intact s169-run-from-outside` → exit 0
  tests/run-from-outside.oracle.test.sh: changed, logged in ## Oracle changes — Fixture only, no assertion: `agents_in` copies Polype's own `method/agents/{implementer,qa,reviewer}.md` instead of writing name-only files, and `project` also lays an executable `.polype/hooks/po-bounds.sh` beside `po-gate.sh`. — Fix run, review finding major `po/src/run/bounds.rs:26` (owner decision d-0011): `held` now requires each global file to be Polype's subagent wiring the `po-bounds` hook and the project to hold the executable script. The old fixture laid exactly the name-only files the finding says prove nothing, so its "held" cases would read `unproven`; every assertion, including the three `bounds` cases of `test_run_refuses_unproven_bounds`, is unchanged.
  po-gate: 1 logged oracle change(s) of s169-run-from-outside to judge
- Oracle: `po-gate oracle-intact s169-run-from-outside` → exit 0
- [x] Oracle: exit 0, with one logged change to judge. That change is to the fixture only:
  - `agents_in` now copies Polype's real subagents, where it used to write files holding only a name.
  - `project` now lays down an executable `po-bounds.sh`.
  - Every assertion is unchanged, and the two `unproven` cases of `test_run_refuses_unproven_bounds` still exercise the repository-copy rule.
  - It does not weaken the criterion. It was needed because the old fixture laid exactly the files that the loop-0 finding said prove nothing.
- [x] Floor: `po-gate floor-guard s169-run-from-outside main` → 0.
- [x] None of the six shapes of test that prove nothing appears. The Claude Code stand-in is the third-party CLI double that the plan justifies.
- [x] Within `Test budget`: 12 new tests out of 25 (6 oracle tests and 6 task tests).
- [x] Bite 1: in `mod.rs` `stale`, I dropped the dead-pid condition and kept only the age check. 1 test failed (`stale_launch_lock_is_taken_over`). I undid it, and `git diff --exit-code` was clean.
- [x] Bite 2: in `bounds.rs` `carries_hook`, I made any non-empty file count as proof. 1 test failed (`bounds_are_proven_not_named`). I undid it, and `git diff --exit-code` was clean.
- [x] Bite 3: in `mod.rs:171`, I removed `&& d.consumed.is_none()`. 1 test failed (`consumed_answer_is_nothing_to_do`), so the loop-0 gap is closed. I undid it, `git diff --exit-code` was clean, and I rebuilt the binary from the committed code.

## Neighbours
- [x] `state/mod.rs` and `main.rs` are unchanged and their calls still match. The story's 12 tests pass on the committed code; I ran them before and after the bites.

## Lenses
Lenses run: Security — the path `po/src/run/session.rs` names a session, and `po/src/run/bounds.rs` holds a permission check (bounds) that gates an unattended LLM session.
- [x] The launched prompt is never assembled from input. It is either the fixed framing stage or `/po-drive`, and `run_takes_no_free_text` holds that. No URL, upload or webhook is involved. The residual limits of the bounds proof are listed under Not verified, as a security matter for the person.

## Findings
- minor — po/src/run/mod.rs:240 — `take_over` can lose a fresh lock when three `po` meet a stale lock at the same moment. A and B both judge it stale, and A moves it aside and creates its own lock. B then moves A's lock aside, sees that the content differs, and links it back. In the gap before B links it back, a third `po` C can create the lock. B's `hard_link` then fails, B deletes the aside copy, and both A and C believe they hold the lock, so two lead sessions can launch. A's `Drop` then removes C's lock. This needs a stale lock plus three simultaneous launchers, so the impact is contained. A fix is to compare and remove only when the inode matches, or to keep the aside file when the link back fails.
- minor — docs/interface-agent.md:211 — The doc overstates what the lock check proves:
  - It says the lock is "tenu par un `po` vivant" and that `already-running` "veut donc toujours dire qu'un lancement ou une session est réellement en cours".
  - `kill -0` only proves that some process holds that pid. A dead `po` whose pid was reused within ten minutes still gives `already-running` while nothing runs.
  - In the other direction, a `po` run by another user reads as dead, because `kill -0` returns EPERM.
  - The fix is to tone the wording down to "probably" and name the ten-minute limit as the worst case.
- minor — docs/interface-agent.md:29 — The exit-code list still names `not-built` ("un verbe pas encore construit"), although no verb returns it any more. This is carried over from loop 0: the lead chose to leave it, because `output::not_built` lives in `po/src/output.rs`, outside `Owns`. It goes when `not_built` is removed (cargo warns that it is unused).

## Not verified
- Whether the real `claude --bg` honours `--session-id`, and whether it lists that `sessionId` with a `pid` in `claude agents --json` while it runs. Every test goes through the `PO_CLAUDE` stand-in. The owner should run `po run` once for real, then `claude agents --json`, and check that the recorded UUID appears with a `pid` (the plan's pivot).
- Whether a session already has a `pid` in the listing the moment `claude --bg` returns. If it does not, a `run` arriving right after a launch could start a second session. The owner should run `po run` twice in quick succession and expect `already-running` the second time.
- Whether `claude attach <id>` and `claude logs <id>` accept the 8-character short id that `po` returns. I did not run them; the owner should try them with the first real id.
- Whether Claude Code really prefers the repository's `.claude/agents/` copy over the global one, which `bounds` relies on. I found no documentation of this here. The owner should confirm it from Claude Code's documentation.
- Security, for the person and not for the tracker:
  - `bounds` does not read Claude Code's settings, so `disableAllHooks` would still read `held`.
  - It checks that `.polype/hooks/po-bounds.sh` exists and is executable, not that it is Polype's script.
  - The record says both of these itself. The person should decide whether `held` must also cover them.
- The stale-lock behaviour when the system `kill` binary is missing; then only the age limit applies. This is not tested.
- The documentation criterion `docs_show_the_agent_loop`, judged by reading: the loop section, the refusal table, the `session` and `bounds` definitions and the machine files in `installation.md` are present and match the code, apart from the two doc minors above. No script tests it; it is a candidate for a `po-eval` control arm (#208).
- I did not rerun the full suite; I reused the record. Formatting and lint: the project has none.

Max severity: minor
Ship allowed: yes
