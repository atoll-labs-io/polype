# Review — s207-real-run-is-usable

[Story](../stories.md) · [Plan](../plans/s207-real-run-is-usable.md) · [Verification](../verif/s207-real-run-is-usable.md)

Method version: 0.11.0
Recorded: 2026-11-23T21:10:02+01:00

Diff reviewed: `git diff main...story/s207-real-run-is-usable`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 1e5228945f8cb3cb059e4594e45696c97db0037d

## When blocked
- Failure cause: none, the review completed
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s207-real-run-is-usable` and held each path against `Owns`: `evals/real/`, `bin/po-eval`, `docs/evals/`, `tests/real-run-is-usable.oracle.test.sh`, `tests/real-run-is-usable.test.sh`, `tests/real-run-before-a-release.*`.
- [x] Inside `Owns`: `evals/real/lib.sh`, `docs/evals/real-run.md`, `tests/real-run-is-usable.oracle.test.sh`, `tests/real-run-is-usable.test.sh`.
- [x] In scope by construction:
  - The story's own pipeline files: research, plan, verif.
  - `docs/decisions/ADR-0136-…md`. The diff adds it (status `A`) and the plan names it.
- [x] Outside `Owns`: `docs/decisions/ADR-0135-…md` was modified, and the ADR exception never covers a modified ADR. The change is only its `superseded-by` frontmatter line, which Law 6 of `AGENTS.md` names as the one part of an accepted ADR that ever changes. ADR-0134 got the same change when ADR-0135 was written. So this is a gap in `Owns`, graded minor (see Findings).
- [x] Inside another running story's `Owns`: none.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s207-real-run-is-usable` → exits 0, so I reused the record.
  - Record: `Verification mode: record`, status complete. The `bash tests/run.sh` row exited 0 on tree `1e40cb98…`, with code outside `docs/` equal to `Tree: 719cce93…`.
  - The project has no type check command (`Typecheck: —`), and I did not substitute one.
  - "Not proven here" is carried to `## Not verified`.
- [x] `po-gate qa-current`: not required. `QA stage` is `—`, so the story does not go to QA.

## Plan
- [x] All six tasks are present, and nothing in the diff falls outside the plan.
  - T1: the `.last-cleanup` prune, `evals/real/lib.sh:193`.
  - T2: the eleven allowlist entries, `:113-115`, with `deny` unchanged.
  - T3: `real_spent` at `:659-675`, wired into `real_record`.
  - T4: the task test.
  - T5: `docs/evals/real-run.md` at :15, :28 and :35, plus ADR-0135's frontmatter.
  - T6: the full suite, recorded through `po-run`.
- [x] Run interdicts, checked one by one:
  - `docs/evals/real-2026-11-23-v0.12.0.md` has `cksum` `1525621025 999`, unchanged. This also settles `first_record_is_kept`.
  - `po/`, `method/` and `bin/` have an empty diff. So do `evals/real/` files other than `lib.sh`, and `tests/real-run-before-a-release*`.
  - The allowlist holds exactly the eleven named entries. No `bypassPermissions` and no `defaultMode`.
  - ADR-0134 is unchanged. ADR-0135 changes on its `superseded-by` line only.
  - No paid run was made: the tests use `--build` only.
  - The oracle sample is synthetic.
  - Only `./.last-cleanup` was added to the prune list.

## References
- [x] Confirmed:
  - The session file glob `*.session[0-9]*.jsonl` matches what `evals/real/claude-print:26-29` writes (`$REAL_OUT.session$n.jsonl`).
  - The redirect is applied at `exec`, so every launched session leaves a file and is counted.
  - `real_record` is the only caller of the removed inline jq. It now calls `real_spent` inside `$(…)`.
  - `real_spent` handles a stream with no `result` (`last // {}` gives zeros).
  - An unreadable file still makes the redirect fail inside `$(…)`, so the line reads `cost: unreadable`.
- [x] Values: the `0.99` cost and the `74 / 20685` tokens come from the reduced copy of the 2026-11-23 stream. Its `modelUsage` sums match the cumulative `total_cost_usd`.

## Rules
- [x] `AGENTS.md` conventions are respected: comments in English, method untouched, tests in bash, oracle and task test files split.
- [x] No accepted ADR is contradicted. ADR-0136 supersedes ADR-0135 on the allowlist only, and ADR-0135 stays `accepted`, which Law 6 allows because the replacement is partial.

## Tests
- Oracle: `po-gate oracle-intact s207-real-run-is-usable` → exit 0
  tests/real-run-is-usable.oracle.test.sh: changed, logged in ## Oracle changes — one comment line added above `usable_build`, holding the text `"$RTMP/bin/claude"` — `test_suite_never_pays` (s206 oracle) scans every `tests/*.sh` that launches po-eval and requires the text `/bin/claude"` in it; the oracle as written made that s206 test fail. No assertion changed. New cksum `4199343886 4800`.
  po-gate: 1 logged oracle change(s) of s207-real-run-is-usable to judge
- [x] Floor: `po-gate floor-guard s207-real-run-is-usable main` → exit 0, nothing lowered.
- [x] Oracle: `po-gate oracle-intact` → exit 0, with one logged change to judge. One comment line naming `"$RTMP/bin/claude"` was added so the s206 `test_suite_never_pays` scan accepts the file. No assertion changed, and no criterion is weakened.
- [x] The assertions pin the criteria, and none of the six "tests that prove nothing" shapes appears.
  - `law4_commands_are_allowed` compares the whole sorted list for exact equality, so an extra entry also fails.
  - The housekeeping test also checks that a widened `settings.json` and a modified installed command are still seen.
- [x] Four tests, within `Test budget` 25.
- [x] Bites. Each change was undone, and `git diff --exit-code evals/real/lib.sh` was clean after each:
  - Removed `-o -path ./.last-cleanup` → 1 failing test (`housekeeping_does_not_invalidate`).
  - Multiplied the per-session cost by 5 (the old sum over five events) → 3 failing tests (`cost_is_counted_once`, `tokens_come_from_the_last_result`, `record_holds_no_transcript`).
  - Took the `first` result instead of the `last` → 1 failing test (`tokens_come_from_the_last_result`).
- [x] The story made no existing test useless. `record_holds_no_transcript` still passes unedited.

## Neighbours
- [x] Read `real_record`, its only caller (`evals/real/lib.sh:909`), and `real_session_held` / `real_session_fault`, which use the same naming of session streams. Nothing is broken.
- `docs/harnais.md:209` still cites only ADR-0135 for the allowlist. It is not in `Owns` and is still accurate, because it sends the reader to `docs/evals/real-run.md`. Not a finding.

## Lenses
Lenses run: none. The diff touches no auth, routes, migrations, lockfiles or dependency manifests, and no server-side query code.
- [x] There are no lens findings.

## Findings
- minor — docs/decisions/ADR-0135-gh-entre-dans-la-liste-de-permissions-d-un-passage-reel.md:8 — this path is outside the story's `Owns`. The only change is the `superseded-by: [ADR-0136]` line, which Law 6 of `AGENTS.md` names as the one part of an accepted ADR that ever changes ("only its frontmatter links, `supersedes` and `superseded-by`, ever change"), so this is a gap in `Owns` and not a breach by the implementer. Leave the code as it is; a story that writes a superseding ADR could list the superseded one in its `Owns`.
- minor — evals/real/lib.sh:670 — `read -r c i o` assigns `c`, `i` and `o` without declaring them `local`, while the function declares its other variables. Today the leak stays harmless, because every caller runs `real_spent` inside `$(…)`. Adding them to the `local` line would keep a future direct caller from picking them up.

## Not verified
- Whether Claude Code accepts `cd <worktree> && git …` when each part is allowed, and whether `Bash(sed -n:*)` lets `sed -n` through while refusing `sed -i`. Only a real, paid run shows this (ADR-0136, Neutral; the record's "Not proven here"). A person should check that the next real run's stream has no `permission_denied` on these commands.
- Whether `.last-cleanup` holds nothing Claude Code reads to govern a session, and whether it is the only housekeeping file Claude Code writes at start. I did not open a real `.last-cleanup`, because that needs a `claude` start. A person can look at it in the next built run after a session, or accept the bet the plan makes.
- The cost count on a real multi-session stream, or on a session stopped by `--max-budget-usd`. Only the synthetic reduced sample was exercised; the next real run's record shows the rest.
- Type check: the project has none (`Typecheck: —`).
- E2E and build: the project has neither (`E2E stage: —`, `Build stage: —`).

Max severity: minor
Ship allowed: yes
