# Research — s207-real-run-is-usable

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. Its line numbers hold at `dcaeb91`: `real_governing` is `evals/real/lib.sh:186-215` (the story's `:186-198` covers its prune list), `real_session_held` `:298-307`, `real_permissions` `:109-115`, the cost `:660-663`.
- `.last-cleanup` invalidates because the prune list of `real_governing` (`evals/real/lib.sh:188-192`) names Claude Code's other housekeeping paths but not `./.last-cleanup`; `real_session_held` diffs the whole listing (`:301`) and names the first changed path (`:303`).
- The cost line sums `total_cost_usd` over every `result` event (`evals/real/lib.sh:660-661`), and counts sessions as result events (`:662`). On `journey.1.session1.jsonl` there are 5 `result` events, each carrying the same cumulative `total_cost_usd` 0.9945252999999996 and the same cumulative `modelUsage`, while `usage` is per turn: hence "4.97 USD over 5 sessions; tokens in 32, out 5598".
- Widening the allowlist changes the list that accepted ADR-0135 spells out, so it needs a new ADR (written: ADR-0136, the owner's option a), superseding ADR-0135 on that point as ADR-0135 superseded ADR-0134.
- Nothing in `po/` is touched: the launch path (`po run` → `claude-print` → `claude -p`) is unchanged.

## Story
A real run must not declare itself invalid over a file Claude Code writes alone, its agents must be able to `cd` into their worktree, and its record must say the true cost (#476, #477, owner's decision of 2026-11-23). Complexity 2. Owns `evals/real/`, `bin/po-eval`, `docs/evals/`, the two `real-run-is-usable` test files, the two `real-run-before-a-release` test files.

- `housekeeping_does_not_invalidate` — `.last-cleanup` no longer marks the run invalid; a change of `settings.json` or of an installed command still does.
- `law4_commands_are_allowed` — the allowlist admits `cd`, `cat`, `ls`, `wc`, `cksum`, `sed -n`, `grep`, `head`, `tail`, `diff`, `mktemp` on top of the previous entries, nothing else; `curl` and `claude` stay denied.
- `cost_is_counted_once` — the record takes the last `result` of each session and counts sessions launched: 0.99 USD over 1 session on the 2026-11-23 stream.
- `first_record_is_kept` — `docs/evals/real-2026-11-23-v0.12.0.md` stays as written (cksum `1525621025 999` at `dcaeb91`). Judged in review.

## Current code
- `evals/real/lib.sh:109-115` `real_permissions <run>`: prints the settings JSON (`autoMemoryEnabled: false`, `allow` of 11 entries, `deny` of `WebFetch`, `WebSearch`, `Bash(curl:*)`, `Bash(claude:*)`). `real_config` writes it to `$J/config/settings.json` (`:123`).
- `evals/real/lib.sh:186-215` `real_governing`: `real_sigs config "$J/config"` with a `-prune` list (`./projects`, `./todos`, `./statsig`, `./shell-snapshots`, `./session-env`, `./file-history`, `./debug`, `./ide`, `./plans`, `./telemetry`, `./paste-cache`, `./cache`, `./logs`, `./backups`, `./downloads`, `./history.jsonl`, `./stats-cache.json`, `./.credentials.json`, `./.claude.json*`), then home, bin, gh, git config and hooks, parents, project and worktrees.
- `evals/real/lib.sh:298-307` `real_session_held`: compares `REAL_GOVERNING` (taken before the first session) with a fresh `real_governing`; any difference writes `$REAL_OUT.invalid` and stops the run.
- `evals/real/lib.sh:655-686` `real_record`: builds the record; the usage line is the jq of `:660-663` over `cat "$REAL_RESULTS"/*.jsonl`, all sessions concatenated, so per-session grouping is lost.
- `evals/real/claude-print:20-22`: each launched session increments `$REAL_OUT.sessions`; `:25-27` its stream goes to `$REAL_OUT.session<n>.jsonl`, the file created by the redirect even if the session dies with no `result`. `REAL_OUT` is `$REAL_RESULTS/<case>.<run><arm suffix>` (`evals/real/lib.sh:489`).
- `evals/real/grade.sh:24-31` `real_session_fault`: already takes the **last** `result` of one transcript (`[inputs | fromjson? | select(type == "object" and .type == "result")] | last`).

## Attachment points
- Prune list of `real_governing`, `evals/real/lib.sh:188-192`: one more `-o -path ./.last-cleanup`.
- `allow` array of `real_permissions`, `evals/real/lib.sh:111-113`.
- Usage computation of `real_record`, `evals/real/lib.sh:660-663`: extracted into a function `real_spent <results folder>` that `real_record` calls; the oracle calls it directly.
- `docs/evals/real-run.md:15` (record: "coût et usage additionnés depuis les événements `result`"), `:28` (the permission list), `:35` (what the governing listing leaves out).
- `docs/decisions/ADR-0135-…md` frontmatter `superseded-by: []` → `[ADR-0136]` (the implementer may write under `docs/`, `method/hooks/po-bounds.sh:188`).

## Verified interfaces
- `po-eval real --build <case> <dir>` prints the project path on its last line; `$dir/config/settings.json` is the run's settings (`tests/real-run-before-a-release.test.sh:54-72`).
- After `POLYPE_ROOT=<root> source evals/real/lib.sh` with `J` and `R` set, `real_governing` runs by hand (`tests/real-run-before-a-release.test.sh:284-289`).
- The run's config holds installed commands under `$J/config/commands/po-*.md` (global install by `real_config`, `evals/real/lib.sh:119-122`; the s206 governing test edits `$J/config/agents/implementer.md`, `:297`).
- The stream's `result` events: `total_cost_usd` and `modelUsage.<model>.{inputTokens,outputTokens,costUSD}` cumulative over the session (sum of `costUSD` 0.3522889 + 0.6422364 = 0.9945253 = `total_cost_usd`); `usage.{input_tokens,output_tokens}` per turn (16/2004, 2/112, 8/1943, 2/170, 4/1369, summing to the record's 32/5598). Cumulative tokens: in 74, out 20685.
- The s206 claude double prints one result with `total_cost_usd` 0.01 and neither `usage` nor `modelUsage` (`tests/real-run-before-a-release.oracle.test.sh:57`).

## Traps
- `tests/real-run-before-a-release.test.sh:141` expects `cost: 0.01 USD over 1 sessions`: the new line must keep that substring (two decimals, the word `sessions`), or the s206 test is edited (in `Owns`) and the reviewer told why.
- `tests/real-run-before-a-release.test.sh:337-347` asserts the lead's own work does not read as governing; `:290-335` asserts 31 governing changes are still seen. Pruning `.last-cleanup` only must keep both green.
- `tests/real-run-before-a-release.test.sh:67` checks the deny list is still present; unchanged.
- Rounding: jq has no `printf`; `0.9945` must print `0.99`, and `4.9` should print `4.90`. awk `%.2f` (already used at `evals/real/lib.sh:837`) does it.
- `.sessions` files and `session<k>.jsonl` files agree on the count; a session with an empty stream still counts as launched. The oracle supplies both, so either source passes.
- The paid stream sits outside the repository (`/tmp/po-eval-results.QOuTAX/`); only a reduced, synthetic copy of its `result` shape enters the oracle, no transcript text.
- `docs/evals/real-2026-11-23-v0.12.0.md` must end with an empty diff, even though its cost line is now known to be wrong.

## Open questions
- Whether Claude Code writes other housekeeping files at first start besides `.last-cleanup`: only the next real run shows. The story limits the change to that file.
- Whether `Bash(cd:*)` lets `cd <path> && git …` through under `-p` and whether `Bash(sed -n:*)` refuses `sed -i`: only a real run shows (ADR-0136, Neutral).
- The tokens line: the story fixes cost and sessions only; taking the last result's `modelUsage` for tokens follows the same rule (#477 says tokens are "likely affected the same way"). The plan takes it, with a task test, not an oracle test.

## Complexity
2 → 2. Three local changes in one sourced shell library, one doc update, one ADR record; no `po/` change.

## Split
Not needed.
