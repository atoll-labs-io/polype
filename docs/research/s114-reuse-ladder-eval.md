# Research — s114-reuse-ladder-eval

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. Its one blind spot: a temporary `CLAUDE_CONFIG_DIR` holds no login. This machine logs in through `~/.claude/.credentials.json` (present), so a `claude -p` launched with an empty config dir has no credentials unless the environment carries a token. The plan has to settle this without copying a secret or touching `~/.claude/`.
- The sentence the control arm swaps sits alone on `method/skills/review-antihallu/SKILL.md:38`. ADR-0085 (Consequences, Neutral) keeps it on its own line so the swap can be exact.
- Two copies of the reviewer can win at run time. The throwaway repository gets a per-project install (`evals/lib.sh:149`, so `.claude/skills/` inside the repo), and the user-level copy may shadow it (`bin/po-eval:54`, ADR-0033 Consequences). A control arm that changes only the temp config dir leaves its result to whichever copy wins. Changing both copies removes that dependency.
- `bin/polype` honours `CLAUDE_CONFIG_DIR` (`bin/polype:30`), and a global install writes only under that root (`bin/polype:80-90`: `commands/`, `agents/`, `skills/`, `polype/`). A control install into a temp dir therefore never reaches `~/.claude/`.
- `tests/evals.test.sh:67-70` lists exactly four defect kinds and requires four. Adding `rebuilt-helper` changes that clause, which this story is allowed to do.

## Story
s114 delivers the tool that measures s113's reuse rule against a one-line YAGNI control. It does not deliver the rates: the person runs the paid calls after ship.
- `eval_plants_a_rebuilt_helper` — a case under `evals/cases/` whose diff rebuilds a helper `app/notes.py` already has. It sets `CASE_EXPECT_SEVERITY=major` and `CASE_EXPECT_SHIP=yes`, the built repository never names the flaw, and `tests/evals.test.sh` counts the new kind.
- `eval_has_a_yagni_control_arm` — `bin/po-eval --control` runs the same cases a second time with the step-3 sentence replaced by `Follow YAGNI.` alone, then prints both rates side by side. `tests/run.sh` still makes no paid call.
- `control_arm_never_touches_the_global_install` — the control arm installs into a temporary `CLAUDE_CONFIG_DIR` that is removed at the end, and `~/.claude/` is never modified. `drift_check` still compares the real install with `method/`.

## Current code
- `bin/po-eval` (174 lines) parses `--repeat`, `--model`, `--list` and `--build` (`bin/po-eval:106-117`). Without `--build` it loads every selected case (`:129`), runs `drift_check` (`:130`), announces `N cases × R repetitions = T runs of claude -p` (`:133`), reads one line of confirmation (`:134-141`) and creates a results dir (`:143`). Then, per case and per repetition, it builds the repository by calling **itself** as a separate process, `"$POLYPE_ROOT/bin/po-eval" --build` (`:156`), launches `claude -p "$prompt" --agent reviewer --allowedTools "Read Grep Glob Bash Edit" --no-session-persistence` inside the worktree with stdin closed (`:161-163`), deletes the repository (`:164`), grades the run (`:165`) and prints one line per case: `<case>: P/R passed (X%) — expected S/H; got …` (`:171`).
- `POLYPE_ROOT` is the parent of the script's directory (`bin/po-eval:15`), and every path follows from it: `evals/cases` (`:16`), `evals/lib.sh` (`:19`), `method/commands/po-review.md` for the launch line (`:81`), and `bin/polype` through `eval_base` (`evals/lib.sh:149`). A copy of `bin/`, `method/` and `evals/` is therefore a self-sufficient po-eval.
- `drift_check` (`bin/po-eval:55-77`) reads `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (`:56`). It compares `agents/reviewer.md` and every file of each skill the reviewer's frontmatter preloads, in both directions, and exits 2 on any difference (`:74-76`).
- `grade` (`bin/po-eval:96-104`) prints `blocked`, `<severity>/<ship>` or `no verdict`.
- `evals/lib.sh`: `eval_base` writes `app/notes.py`, with `NoteStore.add/get/list_for` (`evals/lib.sh:63-82`). `get` looks the note up and raises `Forbidden` unless the user owns it (`:71-75`). It also writes four tests (`:85-113`), settings and stories, then runs `polype install "$repo"` (`:149`). `eval_story` appends `story`, creates the worktree, writes the research, runs `plant`, writes the plan with `validated: yes`, commits, and records a real `po-run` (`:154-173`). `eval_research` cites `path:line` of the base code before `plant` runs (`:178-204`). `eval_archive_story` and `eval_archive_plan` are shared by three cases (`:250-294`).
- Cases are shell files declaring `CASE_KIND`, `CASE_DEFECT`, `CASE_EXPECT_SEVERITY`, `CASE_EXPECT_SHIP`, `CASE_PRESSURE` and `CASE_STORY_ID`, plus `story`, `plan` and `plant` (`evals/cases/untested-guard.sh:2-29`, checked at `bin/po-eval:45-51`). Pressure cases reuse a base through `CASE_BASE` (`evals/cases/pressure-urgency.sh:2`). The current plants already inline `get`'s lookup and owner check inside `archive` (`evals/cases/untested-guard.sh:16-19`).
- `method/skills/review-antihallu/SKILL.md:38` is the s113 sentence. It is the only line that starts with `New code that an existing helper you can cite by`.

## Attachment points
- `bin/po-eval`: a `--control` flag in the parser (`:106-117`), the run count (`:133`), the run loop (`:148-172`) and the usage text (`:6-8`, `:22-26`).
- `evals/cases/rebuilt-helper.sh`: a new case, in the shape of `evals/cases/untested-guard.sh`.
- `tests/evals.test.sh:67-70`: the list of kinds and its count. `:80`: the regex that forbids a built repository from naming its flaw.
- `tests/reuse-ladder-eval.test.sh`: a new file, one function per criterion (`AGENTS.local.md` conventions).

## Verified interfaces
- `bin/polype install --global` writes to `$CLAUDE_CONFIG_DIR` (`bin/polype:30,78-90`). Its payload is `bin/` plus `method/` from `$base` (`bin/polype:28-29`), and it refuses an incomplete payload (`bin/polype:124-132`).
- The test harness runs each `test_*` function in its own `bash -c` process with `set -eu` (`tests/run.sh:17`). `ROOT` and `fail` come from `tests/lib.sh:5,11`.
- `tests/evals.test.sh:12-31`: `fake_claude` stands in for `claude` through `PATH`, and `po_eval` pins `TMPDIR` and `CLAUDE_CONFIG_DIR` to the test's temp dir. These helpers are local to that file, and the new test file needs its own.
- `tests/review-tree-gate.test.sh:63` extracts `grade() {` … `}` from `bin/po-eval` with sed, so `grade` must stay a top-level function in that shape.
- `tests/run-ledger.test.sh:172` calls `po-eval --build foreign-resource`, so `--build` must keep its contract.

## Traps
- **Precedence.** User-level agents may lose to the project's copy while user-level skills win, or the reverse (ADR-0033). If the control arm's text sat in only one place, the arm could run on the s113 sentence without anyone noticing. A control build that uses the control payload puts `Follow YAGNI.` in both copies.
- **Login.** A fresh config dir has no `.credentials.json`. Copying it would put a secret in `/tmp`, and a symlink would let a token refresh write into `~/.claude/`. Only an environment token (`ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`) leaves both untouched.
- **Cleanup.** The po-eval script runs under `set -euo pipefail` (`bin/po-eval:13`) and exits 2 from several places (`:157`, `:82`). Only an `EXIT` trap removes the temp dirs on every path.
- **The drift check stays first.** It must still run on the real config before any temp dir exists. The control config differs from `method/` on purpose and is never drift-checked.
- **Output unchanged without `--control`.** `tests/evals.test.sh:122,146,153` grep `<case>: P/R passed` and `N cases × R repetitions = T runs`, so those lines must not change.
- The existing plants already re-inline `get` (`evals/cases/untested-guard.sh:16-19`). Under s113 a reviewer may flag that as major too, which leaves their expected verdicts unchanged (major or critical). The new case must still differ: a separate private method that copies `get`'s body, with the refusal tested, so the rebuilt helper is the only finding.
- `CASE_KIND` must match `[a-z-]+` (`tests/evals.test.sh:47`), and `major` requires ship `yes` (`:51-52`).
- The no-naming regex (`tests/evals.test.sh:80`) runs on `app tests docs/stories.md docs/plans docs/research`. A plan carrying a `## Reuse` heading rules out `reuse` as a forbidden word. `duplicat` and `rebuil` appear nowhere under `evals/` (checked with grep).
- No migration and no new dependency. Nothing under `method/` changes, so `tests/overlap.test.sh` is not concerned.

## Open questions
- Does `claude -p` start from an empty `CLAUDE_CONFIG_DIR` with only an environment token, without onboarding? It cannot be checked without a paid call. If it fails, the failure shows up as `claude exit N`, with the `.err` kept in the results dir.
- Which copy wins when the user-level and project-level skills differ? The plan avoids depending on the answer and puts the control text in both copies.

## Complexity
3 → 3. One flag and one loop in a 174-line script, one case and two test files. The care goes into isolation and cleanup, not into volume.

## Split
—
