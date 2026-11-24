---
track: flow
validated: yes
---
# Plan (short track) — s210-lanes-run-git-with-dash-c

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/<id>.md`.

## Verified facts
- No story assumption proved false. The story says twelve lines of `method/` write `cd <…> &&`: confirmed, outside `method/hooks/` (`grep -rnE '(^|[^a-zA-Z_-])cd[[:space:]]' method/ | grep -v hooks` → 12).
- Ten of the twelve put a `cd` before every command, git included, so they must change:
  `method/AGENTS.md:105` (Law 4), `method/agents/planner.md:18`, `designer.md:16`, `qa.md:25`, `implementer.md:22`, `reviewer.md:25` (last sentence), `method/commands/po-execute.md:29`, `po-qa.md:27`, `po-review.md:29` (the brief sentences "Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`."), and `po-ship.md:16` ("Run commands with `cd <path> &&` unless a step names the repository root.", the lead running git in the lane).
- Two stay as they are, since the `cd` comes before `po`, not git: `po-qa.md:34` and `po-review.md:34`.
- No line of `method/` writes `cd … && git` (or `;`/`||`) in the same code span today: the regex of task 2 matches nothing in `method/` (checked with `grep -rnE`). The hook comments `po-bounds.sh:36` and `:310` name `cd` and `git` with no separator and do not match.
- **No test pins any of the ten phrases**: `grep -rn "shell command\|cd <\|git -C <\|occupant" tests/ evals/` finds nothing. No test file outside `Owns` has to change.
- Word budget: every file to edit sits **exactly at its ceiling** (`AGENTS.md 3732`, `agents/planner.md 1336`, `designer.md 959`, `qa.md 1012`, `implementer.md 1141`, `reviewer.md 1120`, `po-execute.md 614`, `po-qa.md 552`, `po-review.md 886`, `po-ship.md 998`; total 50158 = sum, `method/word-budget`). So each new sentence must hold no more words than the one it replaces; the counts below were taken with `LC_ALL=C awk '{n+=NF}'`, as `bin/po-lint:372` counts.
- `bin/po-lint`: output `<file>:<line>: [<rule>] <message>` through `report()` (`bin/po-lint:34-37`); rules are `check_*` functions called in order at `:461-465`; `METHOD_FILES` (`:94`) lists only `commands/` and `agents/`, while `check_budget` walks the whole tree with `find` (`:390`). The summary counts `METHOD_FILE_COUNT` and `tests/lint.test.sh` (`test_lint_reports_how_many_files_it_read`) pins that number: the new rule must not change it. Header (`:5-7`): a rule must be decidable without reading prose.
- `tests/lint.test.sh` `mutant()` lifts every ceiling to 999999; the oracle copies that trick.
- `po-bounds.sh` parses `cd X && git …` (tests `bounds.test.sh:110-119`): out of scope, no change.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — only `.md` prose and `bin/po-lint` change |
| New screen | absent — `Surface: command` | absent — no UI |
| Authorization or tenant scope | absent — story text | absent — `po-bounds.sh` untouched |
| API contract | absent — story text | absent — `po-lint` keeps its output format, one more rule name |
| New dependency | absent — story text | absent — grep/awk already used by `bin/po-lint` |
| Technical choice that deserves an ADR | absent — the owner chose `git -C` (#487, 2026-11-24) | absent — a lint rule is a pattern of the existing script |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Corrige` line in the story | absent |

## Story
As the owner, the method has git run as `git -C <absolute path>`, never after a `cd`, so Claude Code stops asking approval before each git command of a lane. Criteria: `law4_names_git_dash_c`, `no_cd_before_git_in_method`, `method_does_not_grow`. Complexity scored after reading: 2.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `check_cd_git` in `bin/po-lint` | new code in this repository, on `report()` (`bin/po-lint:34`) and the `find` walk of `check_budget` (`:390`) | no existing rule reads every file of `method/` line by line for a pattern; grep -E (platform) does the matching |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/lanes-run-git-with-dash-c.oracle.test.sh` | `2191923571 3722` |

| Criterion | Test |
| --- | --- |
| `law4_names_git_dash_c` | — speaks to a model: judged in review by reading `method/AGENTS.md` Law 4; candidate for a `po-eval` control arm (#208) |
| `no_cd_before_git_in_method` | `test_no_cd_before_git_in_method`: real `method/` has no `[cd-git]` breach; a copy with a cd-before-git line in a command, a skill, a hook and a template gets exactly four `<file>:<line>: [cd-git]`, exit ≠ 0; `git -C`, `cd … && po`, and the new wording stay green |
| `method_does_not_grow` | `test_method_does_not_grow`: no line of `method/word-budget` above its value at the merge base with `origin/<Target branch>`, no new line, and no `[budget]` breach |

On the code as it stands (2026-11-24) the first fails (no rule), the second passes and guards the edits. The prose half of `no_cd_before_git_in_method` (an instruction putting `cd` before *every* command) is not decidable by lint: the reviewer checks the ten lines.

## Tasks

1. [x] **Law 4.** In `method/AGENTS.md:105`, replace the second sentence (32 words) with exactly (31 words):
   `Inside it, git runs as \`git -C <absolute worktree path>\`, never after a \`cd\`, and everything else starts with \`cd <absolute worktree path> &&\`, since a subagent's shell forgets its directory.`
   Test: `test_method_does_not_grow` (budget), `law4_names_git_dash_c` in review.
2. [x] **Lint rule.** In `bin/po-lint`, add `# --- rule: cd-git` and `check_cd_git`, called after `check_budget`: walk every regular file (and symlink to one) under `$METHOD` the way `check_budget` does, and `report "<path under method/>" <line> cd-git "a cd precedes git: run git as git -C <path>"` for each line matching
   `(^|[^[:alnum:]_.-])cd[[:space:]][^\`]*(&&|;|\|\|)[[:space:]]*git([[:space:]]|\`|$)` (a `cd` command word, then within the same code span a separator directly followed by `git`). Do not touch `METHOD_FILES` or the summary count. Test: `test_no_cd_before_git_in_method`; `tests/lint.test.sh` stays green.
3. [x] **Subagents.** Replace, word count equal:
   - `planner.md:18`, `designer.md:16`, `qa.md:25`: "so start every shell command with \`cd <that path> &&\` or use \`git -C <that path>\`." → "so run git as \`git -C <that path>\`, every other command after \`cd <that path> &&\`."
   - `implementer.md:22`: "Start every shell command with \`cd <that path> &&\` or use \`git -C <that path>\`:" → "Run git as \`git -C <that path>\`, every other command after \`cd <that path> &&\`:"
   - `reviewer.md:25`: "Start every shell command with \`cd <worktree> &&\` or use \`git -C <worktree>\`." → "Run git as \`git -C <worktree>\`, every other command after \`cd <worktree> &&\`."
   Test: `test_method_does_not_grow`; review reads the five lines.
4. [x] **Commands.** In the briefs of `po-execute.md:29`, `po-qa.md:27`, `po-review.md:29`: "Start every shell command with \`cd <absolute path> &&\` or use \`git -C <absolute path>\`." → "Run git as \`git -C <absolute path>\`, every other command after \`cd <absolute path> &&\`." In `po-ship.md:16`: "Run commands with \`cd <path> &&\` unless a step names the repository root." → "Run commands there by Law 4, unless a step names the repository root." (13 → 12 words). Leave `po-qa.md:34` and `po-review.md:34`. Test: `test_method_does_not_grow`.
5. [x] **Budget.** In `method/word-budget`, lower `AGENTS.md` and `commands/po-ship.md` (and any other file whose count fell) to their new counts and `total` by the same amount; raise nothing. Then the full suite once through `po-run`. Test: `test_method_does_not_grow`, `test_budget_starts_at_todays_counts` (already landed: tolerant to lower counts).

## Scene viewpoints
—

## Run interdicts
- `.claude/`, `.polype/`, `po/`, `evals/`, `docs/evals/`, `docs/decisions/` end with an empty diff (installed copies; s209's lane owns `evals/` and `docs/evals/`).
- `method/hooks/` ends with an empty diff, `po-bounds.sh` included.
- `method/commands/po-qa.md:34` and `po-review.md:34` keep their `cd <…> && … po record` text.
- No line of `method/word-budget` above its value on `origin/main`.
- `tests/lanes-run-git-with-dash-c.oracle.test.sh` keeps cksum `2191923571 3722`.
- No `tests/lanes-run-git-with-dash-c.test.sh` unless it holds a test (`tests/run.sh` fails an empty file).

## Files touched
`method/AGENTS.md`, `method/agents/{planner,designer,qa,implementer,reviewer}.md`, `method/commands/{po-execute,po-qa,po-review,po-ship}.md`, `method/word-budget`, `bin/po-lint`, `tests/lanes-run-git-with-dash-c.oracle.test.sh` (written).

## Test strategy
Two oracle tests, within `Test budget: 25`. The lint rule is tested by mutation, as `tests/lint.test.sh` does, with negative controls so the rule is shown narrow. The prose rewording speaks to a model: no phrase test (direction of 2026-11-13); the reviewer reads the ten lines, and Law 4 is a candidate for a `po-eval` control arm. No new test in `tests/lint.test.sh` is needed; it must stay green.

## Done when
One commit on `story/s210-lanes-run-git-with-dash-c`, `bash tests/run.sh` green through `po-run`, `bin/po-lint --base origin/main` clean, review with no open critical finding, landed through a pull request.
