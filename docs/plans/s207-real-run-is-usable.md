---
validated: yes
---
# Plan — s207-real-run-is-usable

[Story](../stories.md) · [Research](../research/s207-real-run-is-usable.md)

Branch `story/s207-real-run-is-usable`. Read the research first; this plan builds on it without repeating it.

## Story
A real run no longer invalidates itself over Claude Code's `.last-cleanup`, its agents may `cd` into their worktree and read with the usual tools, and its record counts each session's cost once (#476, #477). Criteria, sorted as `docs/direction.md` asks:
- read by a script, oracle test: `housekeeping_does_not_invalidate`, `law4_commands_are_allowed`, `cost_is_counted_once`;
- read by a person only: `first_record_is_kept`, judged in review (the file's sum stays `1525621025 999`).

## Decision of the owner (2026-11-23)
The allowlist widens by an explicit list, not by `bypassPermissions` (option a, written in the story). Recorded as [ADR-0136](../decisions/ADR-0136-cd-et-les-commandes-de-lecture-entrent-dans-la-liste-de-permissions-d-un-passage-reel.md), `accepted`, superseding ADR-0135 on the list only. No other command enters without him. No technical choice is left open here.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Prune of `.last-cleanup` | this repository: the prune list of `real_governing` (`evals/real/lib.sh:188-192`), one more `-o -path` | — |
| Allowlist entries | this repository: the `allow` array of `real_permissions` (`evals/real/lib.sh:111-113`) | — |
| Last `result` of a transcript | this repository: the jq of `real_session_fault` (`evals/real/grade.sh:26`), `[inputs \| fromjson? \| select(type == "object" and .type == "result")] \| last` | — |
| Two-decimal cost | the platform: awk `printf "%.2f"`, as `evals/real/lib.sh:837` already formats the budget | jq has no `printf` |
| `real_spent` | new code, about ten lines: the usage jq of `real_record` (`evals/real/lib.sh:660-663`) moved into a function, per session file | the inline jq reads all streams concatenated and cannot group per session; a function is what the oracle and `real_record` both call |

## Acceptance tests
Written before any code, run against `dcaeb91`: all three fail for the reason they name (`.last-cleanup` seen; allowlist of 11 entries; `real_spent` missing).

| Oracle file | cksum |
| --- | --- |
| `tests/real-run-is-usable.oracle.test.sh` | `1093610473 4714` |

| Criterion | Test |
| --- | --- |
| `housekeeping_does_not_invalidate` | `test_housekeeping_does_not_invalidate` — builds the journey case with `po-eval real --build`, writes `$J/config/.last-cleanup`, expects `real_governing` unchanged; then a widened `settings.json` and an appended line in an installed `commands/po-*.md` must each be seen |
| `law4_commands_are_allowed` | `test_law4_commands_are_allowed` — the built `config/settings.json` `permissions.allow`, sorted, equals exactly the 11 previous entries plus the 11 new ones; `deny` still holds `Bash(curl:*)` and `Bash(claude:*)` |
| `cost_is_counted_once` | `test_cost_is_counted_once` — a reduced copy of the 2026-11-23 stream (5 `result` events, cumulative `total_cost_usd` 0.9945…) in a results folder: `real_spent` prints `cost: 0.99 USD over 1 session…`; with a second, empty session stream and `.sessions` at 2, `cost: 0.99 USD over 2 sessions` |
| `first_record_is_kept` | — no script reads it: judged in review by `cksum < docs/evals/real-2026-11-23-v0.12.0.md` = `1525621025 999` |

## Tasks
1. [x] **Prune `.last-cleanup`.** In `real_governing` (`evals/real/lib.sh:188-192`), add `-o -path ./.last-cleanup` to the `real_sigs config` prune list, next to `./stats-cache.json`. Touch nothing else in the listing. Update the function's comment only if it names the pruned files (it names categories: leave it). Test able to fail: `test_housekeeping_does_not_invalidate`; `test_a_session_cannot_widen_the_next` (`tests/real-run-before-a-release.test.sh:272`) stays green.
2. [x] **Widen the allowlist.** In `real_permissions` (`evals/real/lib.sh:109-115`), append exactly `"Bash(cd:*)", "Bash(cat:*)", "Bash(ls:*)", "Bash(wc:*)", "Bash(cksum:*)", "Bash(sed -n:*)", "Bash(grep:*)", "Bash(head:*)", "Bash(tail:*)", "Bash(diff:*)", "Bash(mktemp:*)"` to `allow`; `deny` unchanged. Update the function's comment: "The C1 settings of ADR-0134, `gh` added by ADR-0135, `cd` and the reading commands by ADR-0136". Test able to fail: `test_law4_commands_are_allowed`; `test_build_holds_no_login` stays green.
3. [x] **Count each session once.** Add `real_spent <results folder>` to `evals/real/lib.sh`, next to `real_record`: for each `"$1"/*.session[0-9]*.jsonl` (one file per launched session, `evals/real/claude-print:25-27`), take the last `result` event as `real_session_fault` does; cost is its `total_cost_usd`; tokens are the sum over its `modelUsage` models of `inputTokens` / `outputTokens`, falling back to its `usage.input_tokens` / `output_tokens` when `modelUsage` is absent; a stream with no `result` adds 0 and still counts. Print one line `cost: <X.XX> USD over <N> sessions; tokens in <A>, out <B>`, cost formatted `%.2f`; on unreadable input print `cost: unreadable`. Replace `:660-663` with `usage="$(real_spent "$REAL_RESULTS")"`. Tests able to fail: `test_cost_is_counted_once`; task test `test_tokens_come_from_the_last_result` (below); `test_record_holds_no_transcript` (`tests/real-run-before-a-release.test.sh:113`, expects `cost: 0.01 USD over 1 sessions`) stays green unedited.
4. [x] **Task test.** Create `tests/real-run-is-usable.test.sh`, sourcing the oracle's preamble as `tests/real-run-before-a-release.test.sh:4` does, with one function `test_tokens_come_from_the_last_result`: on `first_run_stream`, `real_spent` says `tokens in 74, out 20685`; on a stream whose last `result` has only `usage` (the s206 double's shape plus `usage`), it takes that last `usage`, not the sum of all. Fails if tokens are summed over events (32/5598) or read from the first event.
5. [x] **Docs and ADR link.** `docs/evals/real-run.md`: `:15` — cost and usage are taken from the last `result` event of each session, and sessions are those launched; `:28` — the permission list adds `cd`, `cat`, `ls`, `wc`, `cksum`, `sed -n`, `grep`, `head`, `tail`, `diff`, `mktemp`, citing ADR-0136 beside ADR-0135; `:35` — add the housekeeping file Claude Code writes at start (`.last-cleanup`) to what the listing leaves out. In `docs/decisions/ADR-0135-…md`, set the frontmatter `superseded-by: [ADR-0136]` and nothing else (Law 6). Check: `grep -c 'ADR-0136' docs/evals/real-run.md` ≥ 1; `git diff docs/decisions/ADR-0135-*` shows only that frontmatter line.
6. [x] **Full suite**, once, through `po-run --story s207-real-run-is-usable --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `docs/evals/real-2026-11-23-v0.12.0.md` ends with an empty diff (`cksum` = `1525621025 999`).
- `po/`, `method/`, `bin/` and `evals/real/{claude-print,grade.sh,cases,doubles,rules.tsv,seeds,stories.md}` end with an empty diff: the change lives in `evals/real/lib.sh` alone.
- `tests/real-run-before-a-release.oracle.test.sh` and `tests/real-run-before-a-release.test.sh` end with an empty diff.
- No allowlist entry beyond the eleven named; `deny` unchanged; no `bypassPermissions`, no `defaultMode`.
- ADR-0134 unchanged; ADR-0135 changes in its `superseded-by` line only; ADR-0136 body unchanged.
- No paid run: never `bin/po-eval real` without `--build`, `--build-all`, `--list` or `--rules`; no `claude` call.
- Nothing from `/tmp/po-eval-results.*` enters the repository; the oracle's sample is synthetic and carries no transcript text.
- No other housekeeping path pruned than `./.last-cleanup` (a real run shows the next ones).

## The pivot
Everything hinges on **the last `result` event of a session stream being that session's whole spend**. Ways it could be wrong:
- A stream where a later `result` carries a *smaller* `total_cost_usd` (a reset, or a subagent's own result reported in the lead's stream). Compare: on `journey.1.session1.jsonl` all five carry 0.9945252999999996, `session_id` identical, and the `modelUsage` `costUSD` sum equals it (research, Verified interfaces).
- A session that hit `--max-budget-usd` or crashed ending with no `result`: its spend is then unseen (0), not over-counted; the record under-reports it. Accepted: the run is already invalid (`real_session_fault`), and the count of sessions still shows it.
- `modelUsage` keys changing shape: the fallback to `usage` keeps a number, possibly per-turn only. The cost line does not depend on it.

Second hinge: pruning `.last-cleanup` hides nothing that governs. Compare: its name says housekeeping and Claude Code writes it alone at start (#476), but what it holds and whether Claude Code reads anything from it was not opened here; the reviewer can check its content in a built run after a `claude` start, or accept the bet the story makes.

## Files touched
- `evals/real/lib.sh` (tasks 1-3)
- `tests/real-run-is-usable.test.sh` (task 4, new)
- `docs/evals/real-run.md`, `docs/decisions/ADR-0135-gh-entre-dans-la-liste-de-permissions-d-un-passage-reel.md` frontmatter (task 5)
- Already written by the planner, committed with the code: `tests/real-run-is-usable.oracle.test.sh`, `docs/research/s207-real-run-is-usable.md`, this plan, `docs/decisions/ADR-0136-cd-et-les-commandes-de-lecture-entrent-dans-la-liste-de-permissions-d-un-passage-reel.md`

## Test strategy
Four tests, within `Test budget` 25: three oracle tests at the layer that owns each rule — the built run's config and `real_governing` for the first two (through `po-eval real --build`, as the s206 tests do), `real_spent` for the cost — and one task test for the tokens, which the story does not name but the same rule governs. Each would fail if its rule were removed: drop the prune → `.last-cleanup` is seen; drop an entry or add one → the sorted list differs; sum all events → 4.97 over 5; sum tokens → 32/5598. The existing s206 tests guard the other side: 31 governing changes still seen, the deny list, the record's wiring. No mock of an owned service: the build is the real one, the stream a reduced copy of a real one. Not proven by any test: that Claude Code accepts `cd … && git …` under these rules — the next real run shows it (ADR-0136, Neutral). Each rule is read by a script; none goes to a `po-eval` control arm.

## Done when
- one commit on `story/s207-real-run-is-usable` holding the code, the tests, the research, the plan and ADR-0136, landed through a pull request as `s207-real-run-is-usable: Un passage réel va au bout et dit ce qu'il a coûté`;
- `bash tests/run.sh` green, recorded through `po-run`;
- a review with no open critical finding, `first_record_is_kept` checked by sum;
- the next real run is the lead's to propose to the owner, not this story's.
