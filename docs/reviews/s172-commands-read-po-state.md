# Review — s172-commands-read-po-state

[Story](../stories.md) · [Plan](../plans/s172-commands-read-po-state.md) · [Verification](../verif/s172-commands-read-po-state.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s172-commands-read-po-state`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: cbdff8276e511fb2122cbfe3ebef7f1abf63ce89

## Ownership
I listed the diff with `git diff --name-only main...story/s172-commands-read-po-state` and checked each path against the story's `Owns` line using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. That covers `README.md`, the three method files, `tests/run.sh` and the 15 test files. The `docs/research`, `docs/plans` and `docs/verif` files for this id are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s172-commands-read-po-state` exited 0, so I reused the record. It holds `Unit suite` `bash tests/run.sh` with exit 0. The project has no type check (`Typecheck: —`), so none was run. I read its "Not proven here" section: criterion 3 is judged by reading, and no real Claude Code session start was run.
- [x] `po-gate qa-current` is not required because `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All tasks 1–8 are present and match the plan.
  - Task 4 changes the test files exactly as listed, file by file.
  - Task 6 removes the assertions it lists, file by file.
  - `tests/lib.sh` is untouched: the `po_for_hook` exception was not needed.
  - Nothing was done outside the plan.
- [x] I checked each run interdict:
  - `po/`, `docs/interface-agent.md`, `bin/` and `.github/` have an empty diff, and the only `method/` changes are the three allowed files.
  - The oracle sum is intact (`oracle-intact` exit 0).
  - The hook calls only `po state`, with no `--all` or `--remote`. It no longer runs `git worktree list` or `git log`, and reads no story files.
  - The `CLAUDE.md` hint and the comment block above `local again=` are kept.
  - `README.md` changes only the `jq` bullet.
  - The eight test files the plan froze have an empty diff.
  - The research file is not rewritten.

## References
- [x] I opened and confirmed every reference:
  - The `po state` fields used: `framing.stage`, `framing.items`, `framing.next`, `lanes[].path` and `lanes[].stops` with `file`, `command`, `fix_loop`, `max_attempts` and `branch`, then `ready`, `held` with `ref` and the flattened collision, `shipped[].trust.fix_loops` and `max_severity`, and the warning codes.
  - `--all` is accepted (`po/src/trust/mod.rs:39-49`).
  - The setup stage comes back when `AGENTS.local.md` is missing but `.polype/version` exists (`po/src/context/mod.rs:144-149`).
  - The exit codes are OK=0, REFUSED=1 and UNREADABLE=2 (`po/src/output.rs`).
- [x] The values hold up. The 1101 and 977 word thresholds match `main`'s counts (1101 and 977). The new counts are 395 and 976, so `po-retro.md` is one word under its limit.

## Rules
- [x] The `AGENTS.md` conventions are respected: method files are in English, the commands keep `Reads settings:`, and no prose rule was added without removing more words.
- [x] No accepted ADR is contradicted. The hook stays bash and calls `po` (ADR-0116), and `jq` follows decision d-0018.

## Tests
- Oracle: `po-gate oracle-intact s172-commands-read-po-state` → exit 0
- [x] Floor: `po-gate floor-guard s172-commands-read-po-state main` exited 1 with one flag, `tests/ship-and-fleet-cleanup.test.sh:64: assertions-dropped`. Plan task 4 names this file and gives the reason, so it is graded minor (listed under Findings).
- [x] The assertions pin the criteria. The oracle uses a stub `po` whose JSON contradicts the files on disk, so a line the hook derived itself cannot pass. It checks the arguments and the working directory, every line, the exact count of waiting lines, and the absence of `Decision inbox` and `no-gate`. None of the six empty test shapes is present.
- [x] Budget: 4 new tests, within `Test budget` 25.
- [x] Bite:
  - I removed the `select(any($named[]; . == $s))` filter on setting warnings. 1 test failed (`session_hook_prints_from_po_state`). I undid it, and `git diff --exit-code` was clean.
  - I inverted `$parallel == "set"` in the ready line. 1 test failed (`session_hook_prints_from_po_state`). I undid it, and `git diff --exit-code` was clean.
- [x] Tests made useless by the story were removed: the assertions on `po-status` prose that leaves the file, the `SHORT_SHIPPED` mutation, and the `session_next` parity, which would now be a tautology. The short-subject rule is covered in `po` by `tests/state-as-json.test.sh`.

## Neighbours
- [x] I read the other callers:
  - `method/AGENTS.md` (`po-session` "prints where the project stands").
  - `method/templates/agents-local.md:73`: `po-session` still names a missing `Project CLAUDE file`, through the kept hint.
  - `method/commands/po-help.md`.
  - The finish lines of `po-flow` and `po-ship`.
  - `docs/parite-killer-saas.md` D17/G06.
  - Nothing is broken. No reference to `Owns not checked` or `SHORT_SHIPPED` is left in `method/`, `bin/`, `po/` or `tests/`.

## Lenses
Lenses run: none. No security, migration, dependency or performance trigger: the diff holds bash, markdown and tests, with no lockfile or manifest.
- [x] There were no lens findings.

## Findings
- minor — tests/ship-and-fleet-cleanup.test.sh:64 — `floor-guard` flags one dropped assertion: the mutation block on `SHORT_SHIPPED["${id%:}"]=1`. Plan task 4 justifies it: the line leaves the hook, and the rule is now held by `po` and `tests/state-as-json.test.sh`.
- minor — method/hooks/po-session.sh:22 — The header still says "state read from disk and git by po-session; nothing was run or changed". The state now comes from `po state`, which runs `po-gate` for each lane. The plan kept the line on purpose, so this is a wording mismatch, not a defect.
- minor — method/hooks/po-session.sh:25,29 — When `po` or `jq` is missing, the hook exits before `claude_md_hint`. The installation hint about `CLAUDE.md`, which criterion 1 keeps in the hook, is not shown until `po` is laid down. This follows plan step 2.1/2.2. The L1 line already points to `polype install`.
- minor — method/commands/po-status.md:28 — The "next step" rule covers a story with a lane, a story in `ready` or `held`, and a shipped story. It does not cover a story when `ready`/`held` are `null`, for example when `Parallel` is missing. That case falls back only to "the warnings, as they are".
- minor — method/commands/po-retro.md:29,37 — "Where each figure comes from" takes the last review's `Max severity:` of a shipped story from `po state`. The **severities per story** row still describes reading every review's `Max severity:` from the file, so the two sources overlap for the last review. Output item 1 also lost "the `Target branch` of the root".

## Not verified
- I read criterion 3 (`status_and_retro_read_po_state`) and found it consistent with the story's list of what stays in files. Its only test counts words. To cover its behaviour, a person should run `/po-status` and `/po-retro <milestone>` on this repository and compare their figures with `po state --all`. It is a candidate for a `po-eval` control arm (#208).
- No real Claude Code `SessionStart` was run. The hook was exercised by the oracle against a stub `po`, and by the recorded suite against the real `po`. To cover it, start a session in a Polype project with `po` installed, then again without `po` and without `jq`.
- Session start time with several lanes was not measured. `po state` runs `po-gate` for each lane (plan, pivot 4). A person should look at start-up latency on a project with several worktrees.
- Settings warnings for `Max attempts`, `Merge mode` and `Ship confirmation` now appear only when `po` reads the stories and landed commits (plan, pivot 3). Before, the old hook always warned. No test pins this, and I did not probe it beyond reading `po/src/context/mod.rs`.
- I did not rerun the full suite: I reused the record (`Verification mode: record`). I ran only the story's two test files, plus the two mutation runs.

Max severity: minor
Ship allowed: yes
