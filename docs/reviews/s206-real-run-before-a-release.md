# Review — s206-real-run-before-a-release

[Story](../stories.md) · [Plan](../plans/s206-real-run-before-a-release.md) · [Verification](../verif/s206-real-run-before-a-release.md)

Method version: 0.11.0
Recorded: 2026-11-23T14:14:48+01:00

Diff reviewed: `git diff main...story/s206-real-run-before-a-release`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 75a82bbbd11fc79b038139afd864beb2def451e1

## Ownership
Diff listed with `git diff --name-only main...story/s206-real-run-before-a-release`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. That covers `bin/po-eval`, `evals/` (arms, real/), `docs/evals/`, `docs/ci.md`, `docs/harnais.md` and the two test files. The two added ADRs (status `A`) are named by the plan, and `docs/decisions/` is also in `Owns`. No existing ADR was modified.
- [x] No other running story: the only other worktree is `framing-m22`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` passes (exit 0). The record is reused: `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`). I read the record's "Not proven here".
- [x] `po-gate qa-current`: not required, because `QA stage: —`.

## Plan
- [x] Tasks 1 to 8 are all present. I judged the nine declared departures. The `lane` base built from `journey` plus `real_lane` in each case's setup is faithful to task 8. `Private folder: ~/private/` resolves inside the run folder, since `HOME` is the run's home. Reading `tests/journey/answers/plain/` in place is the reuse that `## Reuse` asks for. The wider `gh` double, `ARM_CASES` applying only when no case is named on the command line, the new messages and the model-row wording are all harmless. The suite ran on a staged tree that is equal outside `docs/`, so the gate holds. None of these is a finding.
- [x] Run interdicts checked:
  - The diff under `po/`, `method/`, `tests/run.sh`, `tests/lib.sh`, `tests/journey/`, `.github/`, `.claude/` and `.polype/` is empty, and `bin/` changes only in `po-eval`.
  - No kept security test was touched.
  - No document names an installation.
  - Every launch in the suite goes through a double and a made-up key.

## References
- [x] Every `po state` and `po inbox` field the code reads exists with that serialisation in `po/src/` (`bounds`, `lanes[].story/stage/blocked_by`, `ready`, `waiting`, `shipped[].trust.fix_loops/track`, `framing.items[].item/state`, `pending[].id/story/blocks`). No other field is misread. `install --global` from an arm copy has no `po/`, so it builds nothing under the redirected `HOME`.
- [ ] No value that only looks right: see the `framing-not` finding.

## Rules
- [x] `AGENTS.md` conventions are respected.
- [x] Code against ADR-0133: the margin is 1 up to 5 runs per arm and 2 above, `lowered`/`raised`/`moved no rate` are listed, and nothing is retired.
- [x] Code against ADR-0134: the confirmation shows the count, model, budget and the login variable's name. Without a terminal it exits 2 with nothing run, and `--yes` or any unknown option exits 2. No `--fallback-model`. `HOME`, `TMPDIR` and `CLAUDE_CONFIG_DIR` sit in the run folder. `GH_TOKEN` and `GITHUB_TOKEN` are unset.
- [x] Both ADRs list the options turned down, with reasons, cite the decisions by id only, and name no installation.

## Tests
- Oracle: `po-gate oracle-intact s206-real-run-before-a-release` → exit 0
- [x] Floor: `po-gate floor-guard` exits 0. `po-gate oracle-intact` exits 0.
- [x] Assertions pin the criteria. The doubles record how they were launched, so they do not reproduce the conditions under test.
- [x] 11 tests, within `Test budget: 25`.
- [x] Bite, each change undone and `git diff --exit-code` clean afterwards:
  - Terminal refusal in `lib.sh` (`[ ! -t 0 ]` → `false`): 1 failing test (oracle).
  - Arm phrase occurring exactly once in `bin/po-eval` (`-eq 1` → `-ge 1`): 1 failing (`arm_phrase_found_once`).
  - Scrub of kept files skipped in `real_finish`: 1 failing (`suite_never_pays`).
- [x] `suite_never_pays` holds in substance: every launch unsets both login variables and sets a made-up one, with a `claude` double first on `PATH`. Its static scan is weak (see Findings).

## Neighbours
- [x] `--control` now reads `evals/arms/reuse-ladder.arm` and keeps its messages. `grade()` keeps its shape, as `review-tree-gate.test.sh:62` needs. The record shows the existing `po-eval` tests green.

## Lenses
Lenses run: security — `bin/po-eval real` and `evals/real/` launch an LLM agent with tools and handle a login (prompt from case files, transcripts kept)
- [x] Each lens finding is graded and listed under Findings.

## Findings
Security findings: 4 — decision d-0058
- major — evals/real/grade.sh:263 — A session that never ran is graded like a lead that obeyed. `real_launch` (lib.sh:172,187) ignores the session's outcome.
  - Probe: a `claude` that exits 1 with "Invalid API key" gives `pass` on `brief-in-replace`, `stories-without-mode` and `setup-headless` in both arms, then `moved no rate: reuse-ladder`.
  - So an expired login, a spent budget or a permission file Claude Code rejects turns every stop case into evidence for retiring a rule.
  - Fix: require a `result` event without error in the session's `.jsonl`, and mark the run invalid otherwise.
- major — evals/real/cases/setup-headless.sh:6 — The `framing` base already writes a full `AGENTS.local.md` (lib.sh:110-117).
  - `/po-setup` then only prints it and stops ("If `AGENTS.local.md` is already there, do not touch it", method/commands/po-setup.md:16), so the lead never meets the `Design source` question.
  - `no-setting 'Design source'` passes whatever the lead does, and s204-H7 is not exercised.
- major — evals/real/grade.sh:191 — `framing-not` reads `po state`'s framing, i.e. `git show main:<file>` on the root's local `main` (po/src/project.rs:93).
  - An approved brief or PRD, or a "Stories ready: yes" review, that sits on disk, on `framing/*`, or on `origin/main` with the root not fast-forwarded, escapes `brief-headless`, `prd-headless` and `stories-review-critical`.
  - s204-H4 ("writes nothing in `docs/prd.md` before validation") is never checked as absence of the file.
- minor — tests/real-run-before-a-release.oracle.test.sh:164 — The `/bin/claude"` scan is a heuristic.
  - The task file passes it only through its line 69, which checks the run's double, not a double of its own.
  - `eval-arms-same-environment.test.sh` launches `po-eval` through sourced helpers the grep does not see.
  - Not paying is actually held by the made-up key and `env -u`, which the scan does not check.

## Not verified
- Anything a real model does: no paid run was launched; every probe met a double with a made-up key. Specifically:
  - Whether Claude Code accepts the rules of `settings.json` (`Bash(git:*)`, `Read(//…/**)`, `Agent`, the deny list), and whether a malformed rule drops the rule or the whole file. With `--permission-prompts none` the likely outcome is closed (tools denied), which the second finding then grades as `pass` on the stop cases.
  - Whether `--permission-prompts none` and `--max-budget-usd` exist and behave as assumed on a subscription token. Only the implementer read `claude --help`; I did not run the real binary.
  - Whether `-p` loads the bounded subagents' hooks as `--bg` does.
  - Whether each case puts the lead in front of its rule. I judged ten cases by reading (`journey`, `refused-model`, `stop-and-carry-on`, `human-validation`, `stray-change`, `qa-no-browser`, `brief-headless`, `setup-headless`, `security-at-ship`, `intake-security-issue`). Stop cases pass when the lead does nothing at all, which is the second finding. The `model-row` lines marked `case journey` are exercised but no predicate measures them. A person should run the first real run at a terminal and read the `.err` files and permission refusals.
- macOS: `lib.sh` uses `mapfile` (bash 4, as `bin/po-eval` already did), so the default bash 3.2 does not run it. The tests use util-linux `script -qec`, GNU `stat -c` and GNU `sed -i`; macOS `script` takes `script -q /dev/null cmd` with no `-e` or `-c`. CI tests run only on ubuntu, so this is not exercised.
- Counts: there are 168 `*.test.sh` files and 685 `^test_` lines by grep, against the 677 the runner loads; I did not reconcile the difference. I did not recount the `po`/`po-eval` launch counts. `bin/po-lint method` passes; `--base origin/main` was not rerun. `--build-all` time was taken from the oracle file's run (about 30 s for the whole file).
- `release_names_its_real_run`, judged by reading: `docs/ci.md` step 1 and `docs/evals/real-run.md` say how a release cites its dated record with model and per-arm rates. A same-day rerun overwrites the record file.
- No probe file is left in `/tmp`. The worktree is clean (`git diff --exit-code`) and the tree is unchanged.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-23T16:23:30+01:00

Diff reviewed: `git diff main...story/s206-real-run-before-a-release`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 916faa704acca777dc5be6893e81bece02e27a9e

## Ownership
Diff listed with `git diff --name-only main...story/s206-real-run-before-a-release`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `bin/po-eval`, `evals/`, `docs/evals/`, `docs/ci.md`, `docs/harnais.md`, the two story test files and `docs/decisions/`. ADR-0133 and ADR-0134 are added (status `A`) and named by the plan. The fix commit 7bfbf82 stays inside the same paths.
- [x] No other running story. The only other worktree is `framing-m22` on `fix/qa-deadline-wording`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` passes (exit 0). The last `bash tests/run.sh` row exited 0 on the fix tree, so I did not rerun the suite. The project has no type check (`Typecheck: —`). I read the record's "Not proven here".
- [x] `po-gate qa-current`: not required, because `QA stage: —`.

## Plan
- [x] The fix run addresses every loop-0 finding:
  - **Invalid runs.** `grade_fault` and `real_session_held` now apply, and `real_valid` excludes invalid runs. An arm with an invalid run goes under `not judged`. Closed.
  - **`setup-headless`.** `AGENTS.local.md` is removed from the base. I built the case: `po state` still says `bounds: held`. Closed.
  - **`framing-not`.** `grade_versions` now reads the disk, every local and remote-tracking branch of the root, and the bare origin. Closed.
  - **Removed case.** `intake-review-refused` is gone, and s202-H6 now has its `no case` line.
- [x] Run interdicts hold. The diff under `po/`, `method/`, `tests/journey/`, `tests/run.sh`, `tests/lib.sh`, `.claude/` and `.polype/` is empty.

## References
- [x] `po ship file` reaches the forge through `gh api POST repos/…/issues` and `--body-file -`, and both doubles handle these. `"subagent_type":"qa"` matches the compact `tostring` of an Agent input. Every case named in `rules.tsv` exists, and every `CASE_RULES` id has a row.
- [ ] Not every value is confirmed. See the findings on the config guard, the forge double and `gh`.

## Rules
- [x] `AGENTS.md` conventions are respected.
- [x] ADR-0133 and ADR-0134 hold. Both accept that an agent that tries to leave C1 can; the findings below concern only what the fix claims to detect or record.

## Tests
- Oracle: `po-gate oracle-intact s206-real-run-before-a-release` → exit 0
- [x] Floor: `po-gate floor-guard` exits 0. `po-gate oracle-intact` exits 0.
- [x] Oracle cksum is `500510894 13834`, unchanged.
- [x] Counts confirmed:
  - 34 cases.
  - 160 registry rows, 77 with a case.
  - 28 stop rules, 23 with a case.
  - 168 test files and 684 functions as the runner loads them.
  - 18 tests for this story (6 oracle, 12 task), within `Test budget: 25`.
  - `bin/po-lint method` and `bin/po-lint --base origin/main method` both pass.
- [x] Bite. Each change was undone and `git diff --exit-code` was clean afterwards:
  - `real_session_held` config check → `if false`: 1 failing (`a_session_cannot_widen_the_next`).
  - `pred_used` permission filter dropped: 1 failing (`setup_headless_meets_its_rule`).
  - `grade_versions` branch search emptied: 2 failing (`framing_predicates_look_everywhere`, `setup_headless…`).
  - `claude-print` keeps `PO_CLAUDE`: 1 failing (`lead_cannot_name_the_paid_claude`).
  - The forge double ignores `--body-file`/`-F`: 1 failing (`forge_double_keeps_every_text_sent`).
  - `bin/po-eval` `ARM_FILE` path check removed: 1 failing (`bad_arm_refused_before_any_call`).
  - HUP traps removed: 1 failing (`hangup_leaves_nothing`). HUP set to ignored: 0 failing (see the hang-up finding).
- [x] Static scan of `suite_never_pays` left as it is: acceptable. Not paying is actually held by `env -u` and the made-up key on every launch, which I re-read. It stays a minor, listed below.

## Neighbours
- [x] `--control` and `grade()` are unchanged in shape since loop 0. The record shows the existing `po-eval` tests green.

## Lenses
Lenses run: security — `evals/real/` launches an LLM agent with tools, handles a login and grades what reaches a forge double
- [x] Each lens finding is graded and listed under Findings.

## Findings
Security findings: 3 — decision d-0059
- major — evals/real/lib.sh:77 — `gh` is not on the ADR-0134 allowlist. The method has the lead call it directly (`po-intake.md:24,29,36,74`, `po-setup.md:75,89-93`, `po-drive.md:18`).
  - If a direct `gh` call is refused, four cases cannot pass for a lead that follows the method: `intake-security-issue` and `intake-listing-fails` (`gh-called`), and `intake-human-merge` and `framing-landing-human` (`pr-open`).
  - Such a case scores 0/n in both arms, and the summary then lists the arm under `moved no rate`, which is the input for retiring a rule.
  - Whether the commands' `allowed-tools: Bash` lifts the refusal during a slash command is unverified (see `## Not verified`).
  - Changing the allowlist is the owner's call through a new ADR.
- minor — tests/real-run-before-a-release.test.sh:239 — `hangup_leaves_nothing` still passes when HUP is ignored (`trap '' HUP`). The test checks the cleanup, not that the run stops when its terminal closes.
- minor — tests/real-run-before-a-release.oracle.test.sh:164 — The loop-0 static-scan minor stays open by choice; I judge that choice acceptable, as Tests says.

## Not verified
- Anything a real model or a real Claude Code does. Nothing paid was launched; every probe met a double, with the login variables unset. Open questions:
  - Whether a command's `allowed-tools: Bash` grants Bash under `-p` despite the settings allowlist. This decides the `gh` finding.
  - Whether `Bash(<abs>/po:*)` matches the method's literal `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"`. If neither this match nor the previous grant holds, every `po` call is refused.
  - Whether `cd … &&` and `mktemp` are allowed.
  - The text of a denied permission (`used` filters on "permission").
  - Whether an invalid `model` on the Agent tool reaches a tool result (`refused-model` needs `used no-such-model-s206`; a lead that stops before trying fails it).
  - Whether Claude Code reloads a project `.claude/settings.local.json` between `-p` sessions.
  - A person should run the first real run at a terminal and read the `.err` files and the refusals.
- Cases judged by reading, 17 of them, against both questions:
  - The five unchanged cases: `journey`, `drive-one-story`, `human-validation`, `stop-and-carry-on`, `security-at-ship`.
  - Changed cases: `refused-model`, `stray-change`, `qa-no-browser`, `qa-no-dev`, `qa-service-silent`, `design-no-skill`, `design-system-no-source`, `prd-headless`, `stories-review-critical`, `stories-started-sent-back`, `stories-without-mode`, `brief-in-replace`.
  - Each puts the lead in front of its rule, and each fails a session that did nothing.
  - `used AGENTS.local.md` is a weak sign of meeting the condition, since nearly every lead reads that file, but it does separate a session that did nothing.
  - `used` reads only `tool_use` inputs paired with a non-refused `tool_result`, so text written in a message never counts. A tool call that merely echoes the text would count.
- Intake, the framing landing and QA under a real lead are not exercised here.
- macOS: as in loop 0, not exercised.
- Probes ran in a `mktemp -d` directory, since removed. The worktree is clean and the tree is unchanged.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-23T17:20:24+01:00

Review status: complete
Fix loop: 2
Reviewed tree: 3f7d075d418ab6232dce26a39e05384096529ac2

## Ownership
I listed the diff with `git diff --name-only main...story/s206-real-run-before-a-release` and held each path against the story's `Owns`.
- [x] Every path is inside `Owns`. Fix commit 3a53d5f touches `evals/real/` (`lib.sh`, `grade.sh`, `claude-print`, `doubles/gh`, plus the new `doubles/capture.sh` and `doubles/unexpected`), `docs/evals/real-run.md`, `docs/harnais.md`, `docs/decisions/`, the task test file and the story's own docs. ADR-0135 is added (status `A`) and the plan names it.
- [x] No other running story writes these paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0. The last `bash tests/run.sh` row exited 0 on the fix tree, so I did not rerun the full suite. The project has no type check (`Typecheck: —`). I read "Not proven here".
- [x] `po-gate qa-current` is not required (`QA stage: —`).

## Plan
- [x] Loop-1 major (`gh` not on the allowlist): closed. `Bash(gh:*)` is in `real_permissions`. I drove the other three cases with a lead double that follows the method and calls `gh` through the same prefix-rule check as the test. `intake-security-issue`, `intake-human-merge` and `framing-landing-human` each scored `pass`, with no invalid run.
- [x] Loop-1 hang-up minor: closed. The test now fails when the run ignores HUP (see Bite).
- [x] Static-scan minor: still open, as loop 1 accepted.
- Decision d-0059:
  - First finding: partly lifted. See the security finding below.
  - Second finding: lifted. I probed eight spellings the test does not try: heredoc into `--input -`, `<<<` into `--body-file -`, a quoted `-Fbody=@f`, `xargs` into `--body`, `-b "$(< f)"`, `glab --description-file=`, and a pipe into a listing. Every text was seen, and a text never sent was not. Two misses are noted under Findings: curl's `f=<file` and `f=@file;type=…`. They are minor, because the `curl` double sends nothing and `curl` is denied.
  - Third finding: lifted. I probed six `PATH` shapes: a folder holding only `claude` (dropped), an empty entry, a duplicate entry, a relative entry, and a `claude` sharing its folder with `node` or with `git` (kept, as declared). The kept folders stay behind the run's double, and ADR-0134 accepts reach by full path.
- [x] Declared departures, judged:
  - `unexpected` now wraps the journey double instead of reusing it in place. This keeps `tests/journey/` untouched, so it is fine.
  - Recording standard input instead of rewriting `-` arguments is sound, because the inner double still gets the same input.
  - The new invalid reason names the first changed path, which is clearer. No stale reference to `real_config_sum` remains.
  - The `PATH` filtering is acceptable as described above.
- [x] ADR-0134 differs from af05407 only on `superseded-by: [ADR-0135]`. Its status stays `accepted`, which is right because the replacement is partial. ADR-0135 is in French, lists the options it turned down with reasons, and cites d-0060 by id.
- [x] Run interdicts hold: the diff under `po/`, `method/`, `tests/journey/`, `tests/run.sh`, `tests/lib.sh`, `.claude/` and `.polype/` is empty.

## References
- [x] `capture.sh` is sourced by both doubles through a resolved symlink path. `pred_no_text_in_forge` reads the call logs, the PR files and every origin object and ref. `po` writes its machine state under `.git/polype/`, which `real_governing` does not watch, so it cannot cause a false invalid. No method command writes git config.
- [ ] The values are not all confirmed: the set of places `real_governing` watches has gaps (see Findings).

## Rules
- [x] `AGENTS.md` conventions are respected.
- [ ] One claim does not hold yet. `docs/evals/real-run.md` says the command records everything that governs the next session ("tout ce qui gouverne la suivante"). The finding below shows places it does not record.

## Tests
- Oracle: `po-gate oracle-intact s206-real-run-before-a-release` → exit 0
- Oracle: `po-gate oracle-intact s206-real-run-before-a-release` → exit 0
- [x] `po-gate floor-guard` exits 0. The oracle cksum is still `500510894 13834`.
- [x] Counts confirmed:
  - 34 cases.
  - 160 registry rows, 77 with a case.
  - 28 stop rules, 23 with a case.
  - 168 test files and 685 functions as `tests/run.sh` loads them.
  - 19 tests for this story (6 oracle, 13 task), within `Test budget: 25`.
  - `bin/po-lint method` and `bin/po-lint --base origin/main method` both exit 0.
- [x] Bite. I ran only `real-run-before-a-release.test.sh` after each change, then undid it and confirmed `git diff --exit-code`:
  - Both HUP traps set to `trap '' HUP`: 1 failing (`hangup_leaves_nothing`).
  - Root project signatures dropped from `real_governing`: 1 failing (`a_session_cannot_widen_the_next`).
  - `branch.*` no longer excluded from the root git config: 1 failing (the "own work" half of the same test).
  - The `key=@file` loop of `capture.sh` disabled: 1 failing (`forge_double_keeps_every_text_sent`).
  - `REAL_RUN_PATH` set to the unfiltered `PATH`: 1 failing (`lead_cannot_name_the_paid_claude`).
  - `Bash(gh:*)` removed: 1 failing (`gh_is_allowed_for_a_lead_that_follows_the_method`).
- [x] No test of the six kinds that prove nothing. The `gh` lead double applies the run's own `settings.json`; it does not hardcode the answer.

## Neighbours
- [x] Only `real_launch` calls `real_session_held`, and the end-of-launch check now uses `REAL_GOVERNING`. `claude-print` is unchanged apart from its comment.

## Lenses
Lenses run: security — `evals/real/` launches an LLM agent with tools, watches what governs its next session, and records what reaches a forge double
- [x] Each lens finding is graded and listed under Findings.

## Findings
Security findings: 1 — decision d-0061
- minor — evals/real/doubles/capture.sh:34 — curl's `-F 'f=<file'` and `-F 'f=@file;type=…'` are not captured (probed). The `curl` double sends nothing and `curl` is denied, so no text reaches a forge.
- minor — tests/real-run-before-a-release.oracle.test.sh:164 — The loop-0 static-scan minor stays open by choice, as loop 1 accepted.

## Not verified
- Nothing paid was launched. Every probe met a `claude` double, with the login variables unset and a made-up key. What only a real run shows:
  - Whether Claude Code reads auto memory and parent `CLAUDE.md` files under `-p` with `CLAUDE_CONFIG_DIR` set. This is the basis of the security finding; I relied on documented interactive behaviour.
  - Which files Claude Code writes under its config at first start. A plugin marketplace clone under `plugins/`, for example, would make every run invalid after session 1. It would name the path, as declared.
  - Whether `shell-snapshots/` or `session-env/` carry over between sessions. Both are skipped, and a change to them goes unseen (probed).
  - Whether `Bash(gh:*)` matches a direct `gh` call as the lead double assumes.
  - The other open questions of the loop-1 block.
- `AGENTS.local.md` is not watched. A session that edits `Plan validation` or `Ship confirmation` is not flagged. Watching it would mark `setup-headless` invalid, since `/po-setup` writes that file. I judged this a grading matter, not part of the finding.
- `/po-setup` step 3 reruns `polype init` "if available". Here `polype` shares `~/.local/bin` with `claude`, so the filtered `PATH` drops it. Where `polype` is reachable some other way, its `AGENTS.md` rewrite would mark `setup-headless` invalid.
- Over-capture can fail `no-text-in-forge` on a run that did not send the text. I saw this in a probe: a file named like an argument (`--title t` with a file `t` in the working folder) was recorded. It is declared.
- macOS: not exercised, as in loops 0 and 1.
- Probes ran in a `mktemp -d` folder, since removed; nothing is left in `/tmp`. The worktree is clean and the tree is unchanged.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-23T17:54:57+01:00

Diff reviewed: `git diff main...story/s206-real-run-before-a-release`, in a context that did not write it. Findings rated critical, major or minor. This review covers fix run 3 (commit 0185f61) and the loop-2 findings.

Review status: complete
Fix loop: 3
Reviewed tree: 0e41eace0e28decc9456b0ecc86764d32363c9cc

## Ownership
I listed the diff with `git diff --name-only main...story/s206-real-run-before-a-release` and held each path against the story's `Owns`.
- [x] Every path is inside `Owns`. Fix commit 0185f61 touches `evals/real/lib.sh`, `evals/real/doubles/capture.sh`, `docs/evals/real-run.md`, the task test file and the story's own docs.
- [x] No other running story writes these paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0. The last `bash tests/run.sh` row exited 0 on the fix tree, so I did not rerun the full suite. The project has no type check (`Typecheck: —`). I read "Not proven here", including the new fix-run-3 item.
- [x] `po-gate qa-current` is not required (`QA stage: —`).

## Plan
- [x] Decision d-0061 is lifted.
  - Auto memory: `autoMemoryEnabled: false` is in the run's settings (lib.sh:110). The variable is exported in `real_env` (lib.sh:68) and reaches the session, because `claude-print` strips only its own variables (`env -u`).
  - The memory folder of every project under the config is watched (lib.sh:193).
  - Watched as well: the instruction files and `.claude/` of the run folder and of `.worktrees/`, and the instruction files of every folder above (lib.sh:148-166, 204-206).
- [x] Curl minor from loop 2: closed. `k=<f` and `k=@f;type=…` are captured (capture.sh:33-36), and each has its own witness in the test.
- [x] The fix-run-3 line in the plan matches the diff. Test strategy ("fix run 3 two") is correct: two tests were widened and none added.
- [x] Run interdicts hold. The diff under `po/`, `method/`, `tests/journey/`, `tests/run.sh`, `tests/lib.sh`, `.claude/` and `.polype/` is empty.

## References
- [x] `real_one` resolves the run folder with `pwd -P` (lib.sh:487). The walk up from the run folder therefore follows the physical path Claude Code sees.
- [x] Only `real_one` and `real_session_held` call `real_governing`.

## Rules
- [x] `docs/evals/real-run.md` now matches the code, apart from one overstatement (see Findings).
  - Memory "même coupée": matches.
  - `CLAUDE.local.md`: matches.
  - Parent folders: matches.
  - Folders above: matches.
  - The curl spellings: match.
  - `AGENTS.local.md` left out: matches, and the doc says it openly.
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s206-real-run-before-a-release` → exit 0
- [x] `po-gate oracle-intact` exits 0. Oracle cksum is `500510894 13834`, unchanged. `po-gate floor-guard` exits 0.
- [x] Counts confirmed:
  - 168 test files and 685 functions as `tests/run.sh` loads them.
  - 19 tests for this story (6 oracle, 13 task), within `Test budget: 25`.
  - `bin/po-lint method` and `bin/po-lint --base origin/main method` both exit 0.
- [x] Bite. After each change I ran only the affected test function, with no login and a fake `claude` first on `PATH`. Each change was undone and confirmed with `git diff --exit-code`:
  - Memory watch (lib.sh:193) dropped: 1 failing (`a_session_cannot_widen_the_next`, at the MEMORY.md form).
  - Both `real_parent_sigs` calls dropped: 1 failing (same test, at `$J/CLAUDE.md`).
  - `real_above_sigs` dropped: 1 failing (same test, at the parent `CLAUDE.md`).
  - `autoMemoryEnabled: false` removed: 1 failing (same test, settings check).
  - `${rest%%;*}` capture removed: 1 failing (`forge_double_keeps_every_text_sent`, witness-p).
  - `<` taken out of the split class: 1 failing (same test, witness-o).
- [x] No test of the six kinds that prove nothing. The parent-folder form writes into the test's own temporary folder, never into `/tmp` itself.

## Neighbours
- [x] Probes against `real_governing` on a built `security-at-ship` run.
  - Seen, as they should be: a nested memory file, a memory folder replaced by a symlink, `$J/.claude/settings.json`, `.worktrees/.mcp.json`, `.worktrees/CLAUDE.local.md`, and above the run folder `.claude/CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` and a symlinked `CLAUDE.md`, plus `agent-memory/` both under the config and under the project.
  - Not seen, as declared: `AGENTS.local.md`, in the project and in the run folder.
  - Not seen, and not covered by any rule: `.claude/rules/` and `.claude/settings.json` in a folder above the run folder.
  - The lead's ordinary work stayed valid: transcripts, `tool-results/`, `$J/tmp`, `$J/logs/AGENTS.md`, and a note in a lane. The one exception is below.

## Lenses
Lenses run: security — `evals/real/` launches an LLM agent with tools and watches what governs its next session
- [x] Each lens finding is graded and listed under Findings.

## Findings
- minor — evals/real/lib.sh:193 — `-path '*/memory' -o -path '*/memory/*'` matches anything named `memory` at any depth under `projects/`, not only `projects/<slug>/memory/`. Probed: a file `<slug>/<session>/tool-results/memory` makes the lead's ordinary work read as a widened session. That is a false invalid, though the name is unlikely. Anchoring the pattern to `./*/memory` and `./*/memory/*` would fix it.
- minor — docs/evals/real-run.md:35 — "ceux des dossiers qui les contiennent (le dossier du passage, `.worktrees/`)" refers back to a list that includes `.polype/`. But `real_parent_sigs` (lib.sh:150-153) does not watch `.polype/` in those two folders, so the doc says a little more than is recorded.
- minor — evals/real/lib.sh:68 — No test names `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`, so removing it would fail nothing. Only the settings key is pinned.
- minor — tests/real-run-before-a-release.oracle.test.sh:164 — The loop-0 static-scan minor stays open by choice, as loops 1 and 2 accepted.

## Not verified
- Nothing paid was launched. Every probe met a fake `claude`, with the login variables unset and a made-up key. What only a real run shows:
  - Whether `-p` honours `autoMemoryEnabled: false` or `CLAUDE_CODE_DISABLE_AUTO_MEMORY`. The names come from the implementer's reading of the binary's strings, which I did not repeat. If Claude Code writes memory anyway, the run is marked invalid and names the path.
  - Whether Claude Code creates an empty memory folder or file even when auto memory is off. That would be a false invalid on every run.
  - Whether Claude Code loads `.claude/rules/` from folders above the project. These are unwatched above the run folder (probed). With the default `TMPDIR`, that means `/tmp/.claude/rules/`, which only a `bash` write can reach. A person should check this on the first real run.
  - The open questions of the loop-2 block: files written under the config at first start, `shell-snapshots/` and `session-env/` carrying over, and whether `Bash(gh:*)` matches a direct call.
- `AGENTS.local.md` is not watched, as the doc now states. A session that edits it is not flagged.
- curl `-K <config>` names a file that itself names another file. The second file is not captured (probed). The curl double sends nothing and curl is denied.
- A process outside the run that writes an instruction file above the run folder during a run makes that run invalid. This is true, not false: the next session would load the file.
- macOS: not exercised, as in loops 0 to 2.
- Probes ran in a `mktemp -d` folder, since removed. Nothing of mine is left in `/tmp`, the worktree is clean, and the tree is unchanged.

Max severity: minor
Ship allowed: yes
