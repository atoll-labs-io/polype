# Verification — s206-real-run-before-a-release

[Story](../stories.md) · [Plan](../plans/s206-real-run-before-a-release.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: f1259eebdf50bb9e67211f41b19b60f04cb79795

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- What a real model does: no paid run was launched. Every launch of `po-eval real` in the suite meets a `claude` double, with the login variables unset or set to a value the test makes up. The first real run, `bin/po-eval real` at a terminal, is the owner's gesture after the story ships; it alone shows whether:
  - the permission rules of the C1 settings (`Bash(git:*)`, `Read(//<run folder>/**)`, `Edit(…)`, `Agent`, the deny list) have the syntax and the effect Claude Code gives them — only `claude --help` was read, which names `--permission-prompts none` and `--max-budget-usd` but not the rule syntax;
  - `--max-budget-usd` bounds a session on a subscription token as on an API key;
  - Claude Code under `-p` loads the bounded subagents' hooks as under `--bg` (`bounds: held` is checked by `po state` before any launch, not inside the session);
  - each case of `evals/real/cases/` reaches the rule it names (judged in review: the cases are built and their repositories checked with `po state` and `po next`, never run);
  - the transcript shapes the grade reads: a `result` event with `is_error` and `subtype` ending each session, `tool_use` and `tool_result` pairs for `used <text>`, and a refused permission's result naming the word "permission" (the tests write these shapes by hand);
  - whether `Bash(gh:*)`, added by ADR-0135, lets a direct `gh` call through as the test's lead double assumes (prefix rules, first word of the command);
  - whether a command's `allowed-tools: Bash` grants Bash under `-p` despite the settings allowlist;
  - whether `Bash(<absolute path>/po:*)` matches the method's literal `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"`; if not, and the previous grant does not hold either, every `po` call is refused;
  - whether `cd … &&` and `mktemp` are allowed, and the exact text of a denied permission (`used` filters on "permission");
  - whether an invalid `model` on the Agent tool reaches a tool result (`refused-model` needs `used no-such-model-s206`);
  - whether Claude Code reloads a project `.claude/settings.local.json`, or any other file `real_governing` watches, between `-p` sessions;
  - which files Claude Code itself writes under its config folder and `HOME` while it works: `real_governing` leaves out the ones known (transcripts, caches, `.claude.json` but for the keys that allow something); one it does not know makes each run invalid after its first session, naming the path, and must then be added to that list;
  - the cost estimate of ADR-0133.
- Fix run 1: a closed terminal is played by a double that hangs up its own process group under `script(1)`; a terminal a person closes may signal in another order.
- Fix run 2: the forge doubles record more than a call would send (any argument that names a file, standard input when it is a pipe or a file, read for five seconds at most); a text recorded that way can fail `no-text-in-forge` on a run that did not send it, never the reverse. The run's `PATH` keeps a folder holding the real `claude` when that folder also holds a tool the run needs; the real binary stays reachable by its full path in any case, as ADR-0134 accepts.
- Fix run 3: the run's settings turn auto memory off with `autoMemoryEnabled: false`, a name read in the settings schema of the installed Claude Code binary (its strings, not a session), which also reads `CLAUDE_CODE_DISABLE_AUTO_MEMORY`, set to `1` in the run's environment. Whether `-p` honours either is provable by a real run only; if Claude Code writes the memory anyway, `real_governing` sees it and the run is invalid, naming the path. Above the run folder only the instruction files Claude Code names (`CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `.claude/CLAUDE.md`, `.claude/AGENTS.md`) are watched, not a whole `.claude/`; a process outside the run that writes one of them during a run makes it invalid. `AGENTS.local.md` stays unwatched, as `docs/evals/real-run.md` now says.
- The minor on the static scan of `test_suite_never_pays` is left as it is: a sound check would follow sourced helpers and read what each launch sets in its environment, more than a small change to the planner's oracle.
- `release_names_its_real_run` (`docs/ci.md`, `docs/evals/real-run.md`, `docs/harnais.md`): read by a person, judged in review.
- `po-eval real` under the bash of macOS: written for it as far as `bin/po-eval` already is (`mapfile`, `exec -a`), run on Linux only.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 2a1fbde3361d499fa8612e4baf2f02f2c5cf583c | 2026-11-23T13:02:09Z (573s) |
| Unit suite | `bash tests/run.sh` | 0 | 5e422c0c213bef5e470c77919e741798afad59e4 | 2026-11-23T15:15:14Z (682s) |
| Unit suite | `bash tests/run.sh` | 0 | ff8038670bd7b145cc37a159ab75d55b65f463aa | 2026-11-23T15:59:58Z (985s) |
| Unit suite | `bash tests/run.sh` | 0 | 0d106d832d3af84dab0ad56b9f4b2d5775b64898 | 2026-11-23T16:45:09Z (735s) |
