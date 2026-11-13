# Review — s166-answer-comes-back

[Story](../stories.md) · [Plan](../plans/s166-answer-comes-back.md) · [Verification](../verif/s166-answer-comes-back.md)

Diff reviewed: `git diff main...story/s166-answer-comes-back`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 54cc0d03b081ca66be537b61a59c38178e8d3726

## When blocked
- Failure cause: none, the review is complete
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s166-answer-comes-back`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The story's `Owns` is `po/src/inbox/`, `method/AGENTS.md`, `tests/answer-comes-back.oracle.test.sh`, `tests/answer-comes-back.test.sh`, `tests/state-as-json.oracle.test.sh` and `docs/interface-agent.md`. Every changed code and doc path falls under one of these. `docs/research|plans|verif/s166-answer-comes-back.md` are pipeline evidence, so they count as in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane. s167, s168 and s169, which share `tests/state-as-json.oracle.test.sh` or `docs/interface-agent.md`, have no `story/` branch.
- [x] This story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s166-answer-comes-back` → exit 0, so the record is reused. It shows Unit suite `bash tests/run.sh` exit 0 on code equal to `Tree: b8fa79de…` outside `docs/`. The project has no type check (`Typecheck: —`), and the record says cargo compiles `po` before the suite runs. I read the record's "Not proven here" section and carried its items below.
- [x] `po-gate qa-current`: not required, because `QA stage: —` means the story does not go to QA.
- Oracle checksum confirmed: `cksum tests/answer-comes-back.oracle.test.sh` = `239473693 9126`, the same as in the plan.

## Plan
- [x] Tasks 1-8 are all present: the `Decision` gains `consumed` (only when set) and flatten `extra`, `rewrite.rs`, `po answer`, `inbox --answered` and `consume`, one line of s164's oracle, the rule sentence, the contract and the five task tests. I found nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - No change in `po/` outside `po/src/inbox/`, no change to `Cargo.toml`/`Cargo.lock`, no `build.rs`.
  - `method/` changes only at `AGENTS.md:67`. `docs/installation.md`, the root `AGENTS.md`, `.claude/` and `.polype/` are unchanged.
  - Existing tests change only at `state-as-json.oracle.test.sh:151`.
  - `answer` and `consume` start no process beyond the git plumbing in `Project::find` and `kept_out_of_git`. They write only through the lock, the temp file and the rename.
  - List and show write nothing.
  - Refusals return before the write, and the lock is dropped by a guard because it is bound as `_lock`, not `_`.
  - `NewDecision`/`Choice` keep `deny_unknown_fields`.
  - `run`/`continue` still return `not-built`. The `## run et continue`, `## state` and `## Ce que l'interface ne fait pas` sections of `docs/interface-agent.md` are unchanged, and `contract` stays 1.

## References
- [x] Every reference opened and confirmed: `locate()`, `unknown()`, `id_number`, `read_file`, `read_dir` (`po/src/inbox/decision.rs`, `mod.rs`), `kept_out_of_git` (now `pub(super)` in `add.rs:159`), `output::reply|error|REFUSED|UNREADABLE` (`po/src/output.rs`), the `answer` routing at `po/src/main.rs:24`, and `chrono` (already used at `add.rs:189`).
- [x] Values checked against the plan or contract:
  - `REF_MAX = 200` and the lock timing of 50 × 20 ms ≈ 1 s match plan rows 3 and 6.
  - The exit codes for `unknown-option`, `inbox-busy`, `inbox-unwritable` and `unreadable-decision` (2) and for `not-an-option`, `already-answered`, `unknown-decision`, `inbox-not-ignored`, `malformed-ref`, `not-answered` and `already-consumed` (1) match the plan rows and the new `## answer` tables in `docs/interface-agent.md`.
  - Dates use RFC 3339 with an offset, as in `add`.

## Rules
- [x] `AGENTS.md` conventions respected: commit message in English, tests in bash under `tests/`, code comments in English, contract in French.
- [x] No accepted ADR contradicted: ADR-0107 (transport, inbox kept out of git) and ADR-0117 (unknown fields kept, now done through `extra`). The `rules_say_who_consumes` rule, judged by reading, covers each clause of the criterion: session start, `po inbox --answered`, writing what each answer produces where it lives while citing the id, the id alone when `sensitive`, then `po inbox consume`. A missing `po` is already covered by `method/AGENTS.md:79`.

## Tests
- [x] Floor: `po-gate floor-guard s166-answer-comes-back main` → exit 0, nothing lowered. The one change to an existing assertion, `answer` leaving the `not-built` loop, is justified by task 5.
- [x] Assertions pin the criteria with the real `po` on throwaway git repositories, and none of the six empty test shapes appears. The oracle's PATH stubs and logging `git` prove the "launches nothing" criterion.
- [x] Within `Test budget`: 9 tests against a budget of 25.
- [x] Bite 1: listed-key check disabled (`if false && !keys.contains(...)` in `po/src/inbox/mod.rs`) → 1 failing test (`answer_accepts_only_a_listed_option`) → undone, `git diff --exit-code po/src/inbox/mod.rs` clean.
- [x] Bite 2: exclusive lock disabled (`create_new(true)` → `create(true)` in `po/src/inbox/rewrite.rs`) → `parallel_answers_record_one` failed in 1 of 3 runs, the other 8 tests never failed → undone, `git diff --exit-code po/src/inbox/rewrite.rs` clean. On unchanged code the task tests passed in 4 of 4 runs.
- [x] The story makes no test useless.

## Neighbours
- [x] I read the other code that reads `Decision`: `pending_ids` (used by `po state`), `list`, `show`, and `add::write`, which now sets `consumed: None` and `extra`. The added fields are optional or flattened, so existing readers parse old files unchanged. The suite passes on the recorded tree.

## Lenses
Lenses run: security — content: an answer and a ref arriving from an outside agent become a record change (who may change a decision file; id turned into a path). The key is compared exactly to the listed keys and never reaches a shell or a path. The id passes `id_number` before any path is built (`consume ../AGENTS.local` → `unknown-decision`, tested). The ref is limited to one line of at most 200 characters. No lens finding.
- [x] Each lens finding graded and listed: none.

## Findings
- major — po/src/inbox/rewrite.rs:95 — The plan's pivot (the exclusive lock that lets a decision go from `pending` to `answered` exactly once) is tested only some of the time.
    With the lock made non-exclusive (`create_new` → `create`), `parallel_answers_record_one` (`tests/answer-comes-back.test.sh`) failed in 1 of 3 runs, and every other test passed. The lock code is correct as I read it, but a regression would usually get through the suite.
    A test that can make the race happen every time is needed, for example by holding `.<id>.lock` from the test and checking for `inbox-busy`, then releasing it and checking that the answer goes through.
- minor — method/AGENTS.md:67 — To stay under the word ceiling, the new sentence drops the description of what `po-session` prints ("the framing stage, the ready stories, the lanes in flight and what waits for a human").
    The installed-files paragraph (`:151`) now says only "prints where the project stands", so the rules no longer list those four items anywhere. The plan prescribed this wording, and it is noted only for whoever next edits the paragraph.
- minor — po/src/inbox/rewrite.rs:29 — `now()` repeats the `chrono::Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)` expression that `add.rs:189` still writes inline. `add` could call the new helper so both timestamps stay the same.

## Not verified
- The CI run on the pull request: it runs at ship, and the record says so.
- Bare `po answer` on this repository: its inbox has no decisions. Refusing an unlisted key is proven only on throwaway repositories, by the oracle and bite 1.
- A stale lock left by a `po` killed while holding it: by reading, it gives `inbox-busy` with a message naming the lock path to remove. I ran no test for it. A person can check by creating `.d-0001.lock` by hand and running `po answer`.
- An `inbox-unwritable` path (a read-only inbox) and an `unreadable-decision` under the lock: confirmed by reading only. Checking them means making a fixture inbox read-only and corrupting a decision file.
- `docs/interface-agent.md` and the `method/AGENTS.md:67` rule were judged by reading only, as the plan says. No test reads them except the word ceiling (≤ 3741). The rule is a `po-eval` candidate (#208).
- The behaviour of a model given the new rule: no session was run. Running a lead session on a fixture with one answered decision would show whether it cites the id and runs `po inbox consume`.

Max severity: major
Ship allowed: yes
