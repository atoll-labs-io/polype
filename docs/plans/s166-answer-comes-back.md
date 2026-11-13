---
validated: yes
---
# Plan — s166-answer-comes-back

[Story](../stories.md) · [Research](../research/s166-answer-comes-back.md)

Branch `story/s166-answer-comes-back`. Read `docs/research/s166-answer-comes-back.md` first; this plan builds on it without repeating it. The research reports `docs/interface-agent.md` as outside `Owns`: a framing pull request adds it, and the lane is fast-forwarded onto it before execution, as PR #252 did for s165. Task 7 relies on that; if `git show HEAD:docs/stories.md` does not list the file in s166's `Owns`, stop before task 7 and report.

## Story
`po answer <id> <key>` turns a pending decision into an answered one, and only with a key its `options` list. A second answer, an unknown id and a key outside the list are refused, and nothing is written. Answering launches nothing. `po inbox --answered` lists the answered decisions the lead has not consumed yet. `po inbox consume <id> <ref>` notes what the answer produced and takes the decision out of that list. The rules tell the lead to do this at session start.

Criteria: `answer_accepts_only_a_listed_option`, `answer_refuses_twice_and_unknown`, `answer_launches_nothing`, `answered_decisions_are_listed_until_consumed`, `rules_say_who_consumes`.

### Details this plan settles (the research's open questions; none is a choice for the owner)
| # | Question | Settled as |
| --- | --- | --- |
| 1 | Where consumption is noted | A top-level `consumed: {"ref": "<ref>", "at": "<date with offset>"}`, serialised only once set. Every unconsumed decision keeps exactly the shape of `docs/interface-agent.md:111-130`. A field added keeps `contract: 1` (`:30`). `status` stays `answered` |
| 2 | `answer` codes | `unknown-option` (2): not exactly two arguments. `not-a-project` and `no-inbox-setting` (2): through `locate()`. `unknown-decision` (1): id not `d-<digits>`, or no file. `unreadable-decision` (2). `inbox-not-ignored` (1): the folder lies in the repository and git does not ignore it. `already-answered` (1): any status but `pending`. `not-an-option` (1): the key equals no listed key byte for byte; an empty key is no option. `inbox-busy` (2): lock not taken within about a second, with the lock path in the message. `inbox-unwritable` (2). Checked in this order |
| 3 | `consume` codes | `unknown-option` (2): not exactly `consume <id> <ref>`. `malformed-ref` (1): `ref` empty after trim, holding `\n` or `\r`, or over 200 characters. `unknown-decision`, `unreadable-decision`, `inbox-not-ignored`, `inbox-busy` and `inbox-unwritable` as in row 2. `not-answered` (1): status `pending`. `already-consumed` (1). `ref` is not checked against the disk: the contract allows a line of a plan (`interface-agent.md:173`) |
| 4 | `--answered` reply | `{"contract":1,"answered":[…]}`: status `answered` and no `consumed`, ascending numeric id; a missing folder gives `[]`. Same skip of unreadable files as `list()` (`mod.rs:85-86`) |
| 5 | "Launches no command" | No process but `git` plumbing that writes nothing: `rev-parse` (`Project::find`) and `check-ignore` (row 2). Read as s164 read it for `state` |
| 6 | Two answers at once | Lock file `.<id>.lock` in the inbox, taken with `OpenOptions::create_new`. Up to 50 tries 20 ms apart, then `inbox-busy`. A guard removes the lock on every path out. No `File::lock`: nothing pins a Rust version and the source build is ADR-0115's fallback |
| 7 | Unknown fields | `Decision` gains `#[serde(flatten)] extra: serde_json::Map<String, Value>`. A rewrite keeps what a newer `po` wrote (ADR-0117) |
| 8 | Docs | `docs/interface-agent.md` (in `Owns` once the framing pull request lands) is brought up to what this story builds: task 7. `inbox --answered` and `inbox consume` are lead verbs, as `next`, `record` and `inbox add` are (`:24`) |

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Project, inbox folder, refusals | Repository: `locate()` (`po/src/inbox/mod.rs:56-78`), `output::reply`/`error`/`REFUSED` (`po/src/output.rs:5-44`) | — |
| Id check before any path; unknown id | Repository: `id_number` (`decision.rs:66-72`), `unknown()` (`mod.rs:123-125`) | — |
| Reading one decision, listing in order | Repository: `read_file`, `read_dir` (`decision.rs:76-106`) | — |
| Inbox kept out of git | Repository: `kept_out_of_git` (`add.rs:159-169`), made `pub(super)` | — |
| Date with offset | Dependency installed: `chrono`, as `add.rs:189` | — |
| Lock, temp file, atomic replace | Standard library: `OpenOptions::create_new`, `fs::rename`, `thread::sleep` | `File::lock` is std since 1.89 only; see row 6 |
| Guarded rewrite (lock, read, check, write, unlock) | New code under `po/src/inbox/`, shared by `answer` and `consume` | `add`'s publish (`add.rs:202-219`) creates and never replaces; nothing in the crate rewrites a file |
| Key and ref checks | New code: an exact comparison with the listed keys; one-line ref | This is validation at the trust boundary, which the ladder never cuts |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/answer-comes-back.oracle.test.sh` | `239473693 9126` |

| Criterion | Test |
| --- | --- |
| `answer_accepts_only_a_listed_option` | `test_answer_accepts_only_a_listed_option` |
| `answer_refuses_twice_and_unknown` | `test_answer_refuses_twice_and_unknown` |
| `answer_launches_nothing` | `test_answer_launches_nothing` |
| `answered_decisions_are_listed_until_consumed` | `test_answered_decisions_are_listed_until_consumed` |
| `rules_say_who_consumes` | — a rule read by a model: judged in review. Only the word ceiling is tested (task 8). Candidate for a `po-eval` control arm (#208) |

The oracle fixes these interfaces:
- `po` is reached through `$PO`, and decisions are posed with `po inbox add`.
- The codes of row 2.
- `answer.key` and `answer.at`.
- `{"answered": […]}`.
- `consumed.ref` and `consumed.at`.
- After an accepted answer, the inbox holds only the decision file: no lock and no temp left.

## Tasks
1. [x] **Decision type.** `po/src/inbox/decision.rs`:
   - `Decision` gains `#[serde(default, skip_serializing_if = "Option::is_none")] pub consumed: Option<Value>` after `answer`, and `#[serde(flatten)] pub extra: serde_json::Map<String, Value>` last;
   - `add.rs:187-201` sets `consumed: None` and `extra: Map::new()`.
   - Fails if wrong: `tests/decision-inbox.oracle.test.sh` `test_add_writes_one_decision_file` (file equals output); the unknown-field test of task 8.
2. [x] **Guarded rewrite.** A new `po/src/inbox/rewrite.rs`, `pub(super) fn rewrite(project, dir, id, change: impl FnOnce(&mut Decision) -> Result<(), (&str, String)>) -> i32`:
   1. `id_number(id)` none, or `<id>.json` absent → `unknown()`, before any lock;
   2. `kept_out_of_git` false → `inbox-not-ignored` (1);
   3. take `.<id>.lock` (row 6), dropped by a guard on every return;
   4. `read_file`, or `unreadable-decision` (2);
   5. `change`; an `Err((code, message))` → `output::error(REFUSED, …)`, nothing written;
   6. pretty JSON plus `\n` into `.<id>.json.<pid>.tmp`, then `fs::rename` onto `<id>.json`; I/O failure → `inbox-unwritable` (2), temp removed;
   7. reply the decision with `contract`, exit 0.
   - Fails if wrong: `test_answer_refuses_twice_and_unknown` (nothing written), the concurrency test of task 8.
3. [x] **`po answer`.** `inbox::answer(args)`:
   - `[id, key]`, else `unknown-option` (2); then `locate()`.
   - `rewrite`, whose change refuses:
     - status ≠ `pending` → `already-answered`;
     - no `options[].key` string equal to `key` → `not-an-option`, whose message names the listed keys.
   - Otherwise it sets `status = "answered"` and `answer = {"key": key, "at": now}`.
   - `key` is never trimmed, parsed, put into a path or given to a process.
   - Fails if wrong: `test_answer_accepts_only_a_listed_option`, `test_answer_refuses_twice_and_unknown`, `test_answer_launches_nothing`.
4. [x] **`po inbox --answered` and `consume`.** In `inbox::main`, before the `[id]` arm:
   - `["--answered"]` → row 4;
   - `["consume", id, r]` → the ref check of row 3, `locate()`, then `rewrite`, whose change refuses `not-answered` and `already-consumed`, else sets `consumed = {"ref": r, "at": now}`;
   - any other `consume …` → `unknown-option`.
   - The module comment (`mod.rs:1-2`) names the new verbs.
   - Fails if wrong: `test_answered_decisions_are_listed_until_consumed`; the refusal test of task 8.
5. [x] **s164's oracle.** `tests/state-as-json.oracle.test.sh:151`: `for verb in next answer run continue; do` becomes `for verb in next run continue; do`. That is the one assertion that changes, because `po answer` no longer says `not-built`. — Fails if wrong: `test_state_prints_one_json_object` red on `po answer`.
6. [x] **Rules.** `method/AGENTS.md:67`. The sentence starting "At session start" becomes:
   > At session start it reads the state `po-session` prints, confirming a line marked presumed with `/po-drive status`, then each decision `po inbox --answered` lists: it writes what the answer produces where that lives, citing the decision's id, the id alone when `sensitive`, and runs `po inbox consume <id> <ref>`.
   - Proven on a scratch copy at 3739 words. Another wording is allowed if it keeps the file ≤ 3741 and the phrases `tests/project-lead.test.sh:276-289` freeze. Nothing else in the file moves.
   - Fails if wrong: the ceiling test of task 8; `tests/project-lead.test.sh`; `tests/decision-inbox.test.sh` ceilings.
7. [x] **Contract.** `docs/interface-agent.md`, in French like the rest of the file, nothing else in it moving:
   - `:5`: `answer` exists since s166, beside `state` (s164) and `inbox` (s165); only the remaining verbs answer `not-built`.
   - `:24`: the lead's verbs are `next`, `record`, `inbox add`, `inbox --answered` and `inbox consume`. The two new ones are described under `## answer`, because they change what `inbox <id>` returns.
   - `:29`: the exit-2 list gains `inbox-busy`.
   - `## inbox`, after the decision example: `consumed` (`{"ref", "at"}`) appears only once the lead has consumed the decision; until then the decision has exactly the shape shown.
   - `## answer`:
     - the refusal table gains an exit-code column and the rows of row 2: `unknown-decision` (1), `already-answered` (1), `not-an-option` (1, an empty key included, no trim nor case folding), `inbox-not-ignored` (1), `unreadable-decision` (2), `inbox-busy` (2), `inbox-unwritable` (2), `unknown-option` (2);
     - a short paragraph on `inbox --answered` (`{"contract": 1, "answered": […]}`, answered and not consumed, oldest first) and `inbox consume <id> <ref>`, with its table of row 3: `malformed-ref` (1), `not-answered` (1), `already-consumed` (1), plus the shared codes;
     - `:173`: the lead consumes each decision with `inbox consume`, the `ref` naming what the answer produced.
   - Judged by reading against rows 1-4 and the oracle; no test reads this file.
8. [x] **Task tests and full run.** `tests/answer-comes-back.test.sh`, five tests on throwaway repositories, with the real `po`:
   - **concurrency**: eight `po answer d-0001 a|b` in parallel give exactly one exit 0 and seven `already-answered`, the file carries the winner's key, and no `.lock` or `.tmp` is left;
   - **unknown fields**: a decision file carrying `"later": {"x": 1}` keeps it, unchanged, after `answer` and after `consume`;
   - **consume refusals**:
     - `not-answered` on a pending decision; `already-consumed` on a second consume;
     - `malformed-ref` for `""` and for a two-line ref;
     - `unknown-decision` for `../AGENTS.local`;
     - `unknown-option` for `po answer d-0001` and `po inbox consume d-0001`;
     - each leaves the inbox's sums unchanged;
   - **inbox not ignored**: `.gitignore` without the inbox line → `po answer` gives `inbox-not-ignored` and the file is unchanged;
   - **word ceiling**: `LC_ALL=C wc -w < method/AGENTS.md` ≤ 3741.

   Then `po-run --story s166-answer-comes-back --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/` outside `po/src/inbox/` (`main.rs`, `output.rs`, `project.rs`, `state/`, `next/`, `run/`, `record/`, `trust/`, `Cargo.toml`, `Cargo.lock`). No new dependency, no `build.rs`.
- Empty diff: `method/` except `method/AGENTS.md:67`; `docs/installation.md`; the root `AGENTS.md`; `.claude/`; `.polype/`; every existing test except `tests/state-as-json.oracle.test.sh:151`.
- `po answer` and `po inbox consume` spawn no process but `git rev-parse` and `git check-ignore`. They write only `<id>.json`, through their transient lock and temp in the inbox folder.
- `po inbox`, `po inbox <id>` and `po inbox --answered` write nothing.
- A refusal writes nothing, and no lock outlives the command.
- No free-text answer, no option added, no `status` value other than `pending` and `answered`.
- `NewDecision` and `Choice` keep `deny_unknown_fields`: `po inbox add` still refuses `consumed` or any unknown field.
- `po run` and `po continue` stay `not-built`: they are s169's. In `docs/interface-agent.md`, `## run et continue`, `## state` and `## Ce que l'interface ne fait pas` keep an empty diff, and `contract` stays `1`.

## The pivot
Everything rests on one guarded rewrite: under the lock, a decision passes from `pending` to `answered` exactly once, and only with a key listed in that same file.
- Wrong if the lock is the decision file itself. After the rename, a waiter holds the old inode and reads `pending` again. Compare with row 6; the concurrency test of task 8 catches it.
- Wrong if the key is cleaned before comparison (trim, case). The oracle sends `' a'`, `'A'` and `'a '`.
- Wrong if the rewrite round-trips through a type that drops fields, or reorders the file into a `Map`. Task 1 and the unknown-field test.
- Wrong if a refusal path returns before the guard drops the lock. The next answer then answers `inbox-busy`. The oracle checks that no file is left.

## Files touched
- `po/src/inbox/mod.rs`, `po/src/inbox/decision.rs`, `po/src/inbox/add.rs` (literal and `pub(super)`), `po/src/inbox/rewrite.rs` (new)
- `method/AGENTS.md`
- `docs/interface-agent.md`
- `tests/state-as-json.oracle.test.sh` (one line)
- `tests/answer-comes-back.test.sh`
- Written by the planner: `tests/answer-comes-back.oracle.test.sh`, `docs/research/s166-answer-comes-back.md`, this plan

## Test strategy
- Oracle, 4 tests. The real `po` on throwaway repositories, with decisions posed through `po inbox add`. A PATH of stubs (`claude`, `gh`, `codex`, `curl`, `wget`, `ssh`, `tmux`, `nohup`, `setsid`, `polype`, `po`) and a logging `git` prove that nothing is launched.
- Task tests, 5: concurrency, unknown fields, consume refusals, inbox not ignored, word ceiling.
- 9 tests in `Test budget` 25. No mock: real git, real filesystem.
- Judged by reading: the rule of task 6 (`po-eval` candidate, #208), and the contract of task 7.

## Validation
The planner checked this plan against each criterion; no human reviewed it (`Plan validation: autonomous`). No technical choice is open: no dependency, no ADR.
- `answer_accepts_only_a_listed_option`: tasks 2-3; exact key comparison, `answer.key` and `answer.at`, file unchanged on refusal.
- `answer_refuses_twice_and_unknown`: task 2 step 1 (unknown, before any lock) and task 3 (`already-answered` checked before the key).
- `answer_launches_nothing`: row 5 and the interdicts; only git plumbing.
- `answered_decisions_are_listed_until_consumed`: rows 1 and 4, task 4.
- `rules_say_who_consumes`: task 6, the lead at session start, the id alone for `sensitive`, under the ceiling.
- The contract the story's notes point to (`## answer` fixes the codes) states every code `po` answers: task 7.

## Done when
- The four oracle tests and the five task tests pass with the full suite under `po-run`.
- `po answer` refuses a key outside the list on this repository.
- One commit on `story/s166-answer-comes-back`, reviewed, shipped as `s166-answer-comes-back: Une réponse du porteur n'est acceptée que si elle nomme une option listée`.
