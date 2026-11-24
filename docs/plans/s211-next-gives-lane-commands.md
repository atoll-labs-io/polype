---
validated: yes
---
# Plan — s211-next-gives-lane-commands

[Story](../stories.md) · [Research](../research/s211-next-gives-lane-commands.md)

Branch `story/s211-next-gives-lane-commands`. Read `docs/research/s211-next-gives-lane-commands.md` first; this plan builds on it without repeating it.

Track: full. `po next` gave `flow`; the story text carries an API contract signal (`po next`'s JSON and every verb's `--help`, written in `docs/interface-agent.md`), as s190 did. No migration, screen, authorization, new dependency or `Fixes` line. No ADR: the owner chose on 2026-11-24 that `po` gives the commands (recorded in the story); the field's shape is a contract detail written in `docs/interface-agent.md`, `contract` staying `1` (`:29`).

## Story
`po next` gives the lead the literal commands that open each lane, and every verb of `po` says how to call it, so a lead under the sandbox opens its lanes and can raise a decision (#508, #478). Criteria: `next_gives_lane_commands`, `drive_runs_them_as_given` (model-read), `every_verb_has_help`, `records_are_landed` (review-judged).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Lane path of a story | this repository: the prefix rule of `po/src/context/lanes.rs:208`, extracted into a `pub(crate)` function both use | — |
| Start point | this repository: `Context.start` / `StartPoint.reference` (`po/src/context/start.rs:9-27`) | — |
| Reading git and settings | this repository: `project::git` (`po/src/project.rs:20-33`), `Project::setting` (`:55-67`) | — |
| Usage of `record` and `ship` | this repository: the `USAGE` constants `po/src/record/mod.rs:71`, `po/src/ship/mod.rs:18-20`, made `pub(crate)` | — |
| The `input` form of `inbox add` | dependency installed: `serde_json::json!`, the shape of `NewDecision` (`po/src/inbox/decision.rs:22-48`) | nothing in the repository builds a sample decision |
| Shell quoting of a path | new code, a few lines in `po/src/next/open.rs` | no helper in `po/` (`grep quote po/src`), no shell-quoting in std or in `serde_json` |
| Usage of `state`, `next`, `inbox`, `answer`, `run`, `continue` | new constants in `po/src/help.rs` | these verbs carry no usage string today (`po/src/inbox/mod.rs:66` is a refusal message) |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/next-gives-lane-commands.oracle.test.sh` | `1147489417 6395` |

| Criterion | Test |
| --- | --- |
| `next_gives_lane_commands` | `test_next_gives_lane_commands` — runs every command `po next` gives, from `/`, one `bash -c` each, then checks the worktree, its start at `origin/main` as fetched by the commands, the `.env*` copies, `Install` run in the lane, and `po next` reading the lane back |
| `drive_runs_them_as_given` | no test: the rule speaks to a model and is judged in review; candidate for a `po-eval` control arm (#208). Its word half is held by `bin/po-lint` in the suite (`tests/word-budget-is-linted*.sh`, `tests/lint.test.sh`) |
| `every_verb_has_help` | `test_every_verb_has_help` — eight verbs, exit 0, one object `{contract, verb, usage}`, nothing written, no session launched; `inbox add --help` carries `input`, which `po inbox add` then accepts |
| `records_are_landed` | no test: no script reads the record; the reviewer compares `cksum < docs/evals/real-2026-11-24-v0.12.0-2.md` with `589271514 851` |

Both oracle tests fail on the code as it stands, for the right reasons (`unknown-option` on `--help`; no `commands` on the ready entry), observed by the planner.

## Tasks
1. [x] **Version.** `po` goes from 0.12.0 to 0.13.0 in `po/Cargo.toml:3`, `po/Cargo.lock:165` and `bin/polype:28` (ADR-0122). Test able to fail: `bin/po-version-check` in `bin/po-ci`; every fixture stamps the version from `bin/polype`, so a mismatch shows as a `method-version-mismatch` warning in `po next` tests.

2. [x] **Lane commands in `po next`.** New `po/src/next/open.rs`, called from `po/src/next/mod.rs:96` for each ready id whose `lane::plan` action is `plan`. `Entry` (`:49-56`) gains `commands`, serialised only on those entries (`skip_serializing_if` on the outer `Option`, inner `None` → `null`); `po state` is unchanged. The rules, in this order:
   - `Install` missing → `commands: null`.
   - An untracked `.env*` file at the root that git does not ignore (`git ls-files --others --exclude-standard -- '.env*'` non-empty) → the entry becomes `ask`, reason `env file not ignored`, no track, no commands (`po-research.md:30` today). The entry is built with `lane::act("ask", "env file not ignored")` in `po/src/next/mod.rs`, `act` (`po/src/next/lane.rs:13`) going from private to `pub(super)`: the literal `act("ask", "<reason>")` form is what `journey_ask_reasons` (`tests/journey/journey.sh:201-212`) reads, so the reason is seen by `reason_reader_reads_every_ask` and must be reached by a journey (task 7).
   - Otherwise, each a string, every path absolute and shell-quoted (left bare when every byte is in `[A-Za-z0-9_@%+=:,./-]`, else `'…'` with `'` written `'\''`):
     1. `git -C <root> fetch origin`, only when `git remote get-url origin` succeeds;
     2. `git -C <root> worktree add -b story/<id> <lane> <start>`, `<start>` being `StartPoint.reference`; when `refs/heads/story/<id>` already exists (a branch a sandboxed run left without its worktree), `git -C <root> worktree add <lane> story/<id>` instead;
     3. per file of `git ls-files --others --ignored --exclude-standard -z -- '.env*'` at the root, `cp <root>/<f> <lane>/<f>`, preceded by `mkdir -p <lane>/<dir>` for a path holding `/`;
     4. `Install` other than `—`: `(cd <lane> && <Install>)` — a subshell, so the lead's shell stays where it was (`po-drive.md:50`).
   `<lane>` comes from the prefix rule extracted from `po/src/context/lanes.rs:208`, so `lanes()` recognises the worktree the commands open. `po` itself still runs no fetch and writes nothing (`po/src/project.rs:18-19`).
   Tests able to fail: oracle `test_next_gives_lane_commands`; in `tests/next-gives-lane-commands.test.sh`: `test_no_remote_no_fetch` (no `origin` → no fetch command, start `main`), `test_existing_branch_is_checked_out` (a `story/<id>` with no worktree → the commands open the lane on it), `test_unignored_env_asks`, `test_missing_install_gives_null` (and `Install: —` gives no install command), `test_paths_with_a_space_run` (the project in a folder whose name holds a space; the commands run as given and open the lane).

3. [x] **`--help` on every verb.** New `po/src/help.rs`; `po/src/main.rs` calls it before dispatch when the verb is one of `state next inbox answer record run continue ship` and any argument is `--help`: it prints `{contract, verb, usage}` and exits 0, reading no project and stdin, writing nothing, launching nothing. `usage` is one line: the existing constants for `record` and `ship`; new ones for `state` (`--all`, `--remote`), `next` (`--remote`), `inbox` (the five forms of `po/src/inbox/mod.rs:58-67`, `add` reading one decision on stdin), `answer <id> <key>`, `run`, `continue`. The `inbox` reply also carries `input`: a decision `NewDecision` accepts as it stands (`motive`, `question`, two `options`, `recommended`, `why`, `reversible`, `blocks`). `po --help` and an unknown verb keep their errors. Test able to fail: oracle `test_every_verb_has_help`.

4. [x] **The contract.** `docs/interface-agent.md`: under `## La commande` (`:25-31`), one rule for `po <verbe> --help` (shape, exit 0, nothing read or written, `input` for `inbox`); in the `next` row (`:270`), `commands`: present on a `plan` action of reason `ready` only, its four commands and their order, `null` without `Install`, and the `ask` of reason `env file not ignored`. `contract` stays `1`. Check: reviewer, against tasks 2 and 3.

5. [x] **The method.** No file of `method/` gains a word (`method/word-budget`: `po-drive.md` 2266/2266, `po-research.md` 509/509 today); `method/word-budget` itself changes only if a ceiling goes down.
   - `method/commands/po-drive.md:34`: reason `ready` → open the lane first. `:52-53`, under a heading `### Opening the lanes`: you open each lane yourself before any subagent starts, running the `commands` of its `po next` entry one by one, each exactly as given — never joined, looped or rewritten; `planner` may not run `git worktree add`, so a lane you did not open cannot exist. `:18` "prepares worktrees" → "opens lanes". A missing `Install` is already a stop of `## Checks` (`:24`). Pay for the added words inside the same file.
   - `method/commands/po-research.md:20`: `po next` runs first (drop "After step 1 of `## The worktree`,"). `:22-33`: steps 1 to 4 and the `/po-drive` sentence give way to: on reason `ready`, the entry's `commands` open the lane (the fetch, `git worktree add`, the copy of the `.env*` files git ignores, `Install`), run one by one, each exactly as given, `null` → stop naming `Install`; on reason `no research` the worktree is already there; do not run the tests. Keep the report line. `Target branch` may leave its `Reads settings:` line.
   Test able to fail: `bin/po-lint` (word ceilings, and the s210 rule against `cd … && git` in `method/`) in `tests/lint.test.sh` and `tests/word-budget-is-linted.oracle.test.sh`.

6. [x] **The record.** `cp /home/lecrabe/.claude/jobs/c268121d/tmp/records/real-2026-11-24-v0.12.0-2.md docs/evals/real-2026-11-24-v0.12.0-2.md`, byte for byte; `cksum <` it gives `589271514 851`. Nothing from `/tmp/po-eval-results.S0Td4j/` enters the repository. Check: reviewer, by `cksum`.

7. [x] **A journey reaches the new ask.** s206's oracle `test_every_ask_reason_is_reached` (`tests/journey-reaches-every-stop.oracle.test.sh:170-184`) runs every `stop_*` of `tests/journey/stops.sh` and fails when an `act("ask", …)` reason under `po/src/next/` was reached by none. Add one function at the end of `tests/journey/stops.sh`, `stop_env_file_not_ignored`, in the shape of its neighbours (`stop_no_complexity`, `:31-37`): `journey_kind local`; `journey_story s01-stop 'Un arrêt'` (it commits `docs/stories.md` alone, `journey.sh:143-152`); `git -C "$R" config core.excludesFile /dev/null`, so a machine's global ignore cannot hide the file (this machine's ignores `.envrc`); then an untracked `$R/.env`, never added nor committed — the throwaway project has no `.gitignore` (`tests/journey/project/`), and `Install` reads `—` from the template (`method/templates/agents-local.md:83`), a value, so `open` reaches the env check (`po/src/next/open.rs:16-24`); `if journey_run; then return 1; fi`; `journey_stopped_on_ask`. `journey_run` logs the reason into `$J/asks` before stopping (`journey.sh:531`, `journey_ask` `:495-505`). Each `stop_*` runs in a subshell on a restored snapshot (`journey_kind`, `:83-103`), so the file reaches no other journey. No other line of `stops.sh` or of `tests/journey/` changes. `tests/journey/stops.sh` joins the story's `Owns` on `main` through framing PR #510; this worktree's `docs/stories.md` keeps the older line and is not edited. Test able to fail: `bash tests/run.sh journey-reaches-every-stop.oracle.test.sh` (`test_every_ask_reason_is_reached` and `test_reason_reader_reads_every_ask` green).

8. [x] **Full suite and record.** `po-run --story s211-next-gives-lane-commands --label suite -- 'bash tests/run.sh'` once every task is done.

## Scene viewpoints
—

## Run interdicts
- `.claude/`, `.polype/`, `evals/`, `AGENTS.md`, `method/agents/` and every test file but the two of this story and `tests/journey/stops.sh` end with an empty diff (`tests/driver-next-action*.sh` and the four other files that source its fixture included, `tests/journey/journey.sh`, `tests/journey/project/`, `tests/journey/answers/` and `tests/journey-reaches-every-stop.oracle.test.sh` too).
- `tests/journey/stops.sh` gains `stop_env_file_not_ignored` and nothing else: `git diff main -- tests/journey/stops.sh` shows only added lines.
- `docs/stories.md` ends with an empty diff in this worktree (the `Owns` line moves through PR #510, not here).
- `tests/next-gives-lane-commands.oracle.test.sh` keeps the sum above; a change goes through `## Oracle changes` of the record.
- No ceiling of `method/word-budget` rises; no file of `method/` holds more words than before (`LC_ALL=C awk '{n+=NF}'`).
- `po` runs no `fetch`, `worktree add`, `cp` or `Install` itself: those strings appear in `po/src/next/open.rs` only as text of the commands it returns.
- No file of `/tmp/po-eval-results.S0Td4j/` is copied into the repository; `docs/evals/real-2026-11-24-v0.12.0-2.md` is not edited.
- `contract` stays `1`; no existing field of `po next`, `po state` or any refusal changes name or meaning.

## The pivot
`po next` hands the lead **shell strings** that its Bash tool runs one per call, the git ones starting `git -C <root>` so Claude Code takes them out of the sandbox, and `Install` in a subshell. It could be wrong three ways:
- Claude Code may treat `(cd <lane> && <Install>)` as a compound command with a `cd` and ask for approval, which a run without a prompt refuses. Compare with the permission docs (« Compound commands ») and the next real run; the fallback is an `Install` the lead runs with the lane as working directory of a subagent, which this story does not build.
- A lead may still join the commands into a loop, as the fourth run did. Only a real run shows it: `drive_runs_them_as_given` is model-read, a candidate for a `po-eval` control arm.
- The branch-exists case reuses a `story/<id>` left by an earlier attempt, with whatever it holds; that is the existing lane's work, kept rather than overwritten, and `po-research`'s worktree check on later stages still applies. Compare with `ship clean`, which deletes a branch only once landed.

## Files touched
`po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `po/src/main.rs`, `po/src/help.rs` (new), `po/src/next/mod.rs`, `po/src/next/open.rs` (new), `po/src/context/lanes.rs`, `po/src/context/mod.rs` (re-export, if needed), `po/src/record/mod.rs`, `po/src/ship/mod.rs` (`pub(crate)` usage), `docs/interface-agent.md`, `method/commands/po-drive.md`, `method/commands/po-research.md`, `method/word-budget` (only to lower), `docs/evals/real-2026-11-24-v0.12.0-2.md` (new), `tests/next-gives-lane-commands.oracle.test.sh` (planner), `tests/next-gives-lane-commands.test.sh` (new), `tests/journey/stops.sh` (one added function), and the story's `docs/` evidence. `po/src/next/lane.rs` changes only the visibility of `act`.

## Test strategy
Automated, at the adapter layer, through the binary as the lead calls it (the rules live in `po`, and its JSON is the interface): 2 oracle tests and 5 task tests in `tests/next-gives-lane-commands.test.sh`, 7 in all, within `Test budget` 25. The `stop_` journey of task 7 adds no test function: it is a case s206's existing oracle runs, and the rule it holds is s206's (every ask reason is reached), which deleting the new ask's journey would turn red. Each task test opens real lanes in a throwaway repository with a real bare origin, no mock. The full suite runs once at the end through `po-run`; the version check runs in CI. No visual check.

## Done when
One commit on `story/s211-next-gives-lane-commands` with the code, the tests, the record and the story's evidence; suite green through `po-run`; `po` at 0.13.0 in its three places; a review with no open critical finding; landed through a pull request on `main`.
