# Review — s208-real-run-in-the-sandbox

[Story](../stories.md) · [Plan](../plans/s208-real-run-in-the-sandbox.md) · [Verification](../verif/s208-real-run-in-the-sandbox.md)

Method version: 0.11.0
Recorded: 2026-11-23T23:47:35+01:00

Diff reviewed: `git diff main...story/s208-real-run-in-the-sandbox`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: aa539405e8ec4b876e79f1a7b7b578f91568fadd

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s208-real-run-in-the-sandbox`. Each path was checked against the story's `Owns` with the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`, except one:
  - `evals/real/lib.sh`, `docs/evals/real-run.md`, `docs/decisions/ADR-0136-…md` (frontmatter only) and `docs/decisions/ADR-0137-…md` are inside `Owns`.
  - `tests/real-run-in-the-sandbox.oracle.test.sh`, `tests/real-run-is-usable.oracle.test.sh`, `tests/real-run-before-a-release.oracle.test.sh` and `tests/real-run-before-a-release.test.sh` are inside `Owns`.
  - The research, plan and verification record are pipeline evidence.
- [x] Outside `Owns` (major): `tests/routing-phrase-tests-retired.oracle.test.sh`. No entry of the s208 `Owns` line covers it; it is the oracle of s201.
- [x] Inside another running story's `Owns` (critical): none. `git worktree list` shows only `main` and this story. s201 has no worktree open.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s208-real-run-in-the-sandbox` exits 0, so the record is reused.
  - `Verification mode: record`. The last `Unit suite` run (`bash tests/run.sh`) exited 0 on code equal to `Tree: 4996cba…` outside `docs/`.
  - The project has no type check (`Typecheck: —`), so none was run. I did not rerun the suite.
  - The record's "Not proven here" section is carried into Not verified below.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–7 are all present in the diff.
  - Task 1: ADR-0136 frontmatter only, `superseded`, `superseded-by: [ADR-0137]`.
  - Task 2: the sandbox block, the Bash allow rules removed, and the announce line.
  - Task 3: the anchored git ignore in the run's `HOME`.
  - Task 4: `bwrap`/`socat` added to `real_path_spares`, the Linux-only refusal before the announce, and stubs in `$RTMP/sandbox-tools`.
  - Task 5: config and `HOME` selected by name.
  - Task 6: the free-name loop plus `set -C`.
  - Task 7: the two tests and the three doc lines.
  - Changes outside the plan: the `lead_double` change, and the routing-phrase oracle line (finding below). Both are declared under `## Oracle changes` of the record.
- [x] Each run interdict checked:
  - The diff is empty for `po/`, `method/`, `evals/real/claude-print`, `evals/real/grade.sh`, `docs/ci.md`, `docs/evals/real-2026-11-23-v0.12.0.md` and `tests/journey/project/`.
  - The ADR-0136 body is unchanged. The cksum of the story's oracle is intact (`po-gate oracle-intact` exits 0).
  - `permissions.allow` holds no `Bash(...)` rule. `deny` keeps `WebFetch`, `WebSearch`, `Bash(curl:*)` and `Bash(claude:*)`.
  - None of these appear: `bypassPermissions`, `--dangerously-skip-permissions`, `allowUnsandboxedCommands`, `ignoreViolations`, `sandbox.network`, `excludedCommands`.

## References
- [x] Every configuration key and call confirmed:
  - The keys `sandbox.enabled`, `autoAllowBashIfSandboxed`, `failIfUnavailable` and `sandbox.filesystem.allowWrite` are all named in the installed Claude Code 2.1.331 binary.
  - The binary states how sandbox filesystem paths resolve: "absolute, ~ expanded, or relative to the settings file root". So `allowWrite: [$run]`, an absolute path, is read as absolute.
  - The binary also says user settings, which is where the run's config sits, are honoured for sandbox grants.
  - `real_sigs` runs `find . <expr> -print0` from inside its folder, so `-path './rules/*'` selects at any depth.
  - git's default `core.excludesFile` is `$XDG_CONFIG_HOME/git/ignore`, and `real_env` points `XDG_CONFIG_HOME` at that folder.
- [x] No value that only looks right:
  - The mask list matches the protections the research lists for 2.1.331, plus `.zshenv`.
  - The refusal exits 2, the same code as the other refusals of `real_main`.

## Rules
- [x] `AGENTS.md` conventions respected: commit message in English, comments in English and sparse, tests in bash with the `tests/lib.sh` helpers. The three existing test changes are declared, as `AGENTS.local.md` requires.
- [x] No accepted ADR contradicted:
  - ADR-0137 lists the options it turned down (B, C) and why.
  - ADR-0137 keeps what still holds from ADR-0134 and ADR-0135, and does not open an unwatched run.
  - ADR-0136 was changed in its frontmatter only, as Law 6 allows.

## Tests
- Oracle: `po-gate oracle-intact s208-real-run-in-the-sandbox` → exit 0
- [x] Floor: `po-gate floor-guard s208-real-run-in-the-sandbox main` exits 0, nothing lowered. The `LOWERED_COUNTS` line it does not flag is reported under Findings.
- [x] Assertions pin the four criteria, and none of the six empty test shapes appears.
  - The refusal test builds a PATH farm with no `bwrap`, `socat` or `claude`, runs the real command through `script`, and asserts exit 2, both tool names, no `Continue?` and 0 calls.
  - The mask test runs git in the environment `real_env` sets.
  - The listing test plays housekeeping files, then nine governing changes, and restores between each.
  - The record test checks the first file byte for byte, two new names, and three files in total.
- [x] Within `Test budget` (25): four new tests, and two existing ones adjusted.
- [x] Bite, two rules disabled:
  - (1) The free-name loop of `real_record` replaced by `:`. Result: 1 failing test (`record_never_overwrites`); the output also shows that `set -C` refuses to overwrite. Undone, `git diff --exit-code evals/real/lib.sh` clean.
  - (2) The refusal `if [ -n "$missing" ]` turned into `if false`. Result: 1 failing test (`sandbox_governs_bash`). Undone, `git diff --exit-code evals/real/lib.sh` clean.
- [x] Tests the story made useless: the equality on the allow list in `test_law4_commands_are_allowed` was removed along with its clause. The deny check is kept.

## Neighbours
- [x] Callers of the changed code read:
  - `real_permissions` is called only by `real_config` (`evals/real/lib.sh:127`).
  - `real_record` is called only at `real_main` (`:928`) and by the new oracle.
  - `real_governing` is read by `real_session_held`. The existing `test_a_session_cannot_widen_the_next` and `test_housekeeping_does_not_invalidate` pass on the recorded tree.
  - `docs/ci.md:20` still holds for the first record of a day.

## Lenses
Lenses run: none. No changed path names auth, routes, migrations, lockfiles or server code, and the diff contains none of the content triggers. The diff does change how a real run is confined, so it was read in full against ADR-0137 and the run interdicts.
- [x] No lens findings.

## Findings
- major — tests/routing-phrase-tests-retired.oracle.test.sh:152 — The file is outside the s208 `Owns` line (`evals/real/`, `bin/po-eval`, `docs/evals/`, the three `real-run-*` test pairs, `docs/decisions/`). It is the oracle of s201. The plan's `## Files touched` does not name it either. The added line `po 184 183 s208-real-run-in-the-sandbox` allows a drop of one in the count of tests that launch `po`. The record's reason is plausible: the removed equality named `$J/config/polype/po`, and the launch counter read that as a launch of `po`. It is declared under `## Oracle changes` and expires once the story lands. Still, it is an unplanned change to another story's oracle, outside the story's scope. Either widen `Owns` on purpose, or have the plan name this mechanism.
- minor — evals/real/lib.sh:928 — `[ "$REAL_RECORD" != yes ] || real_record` ignores the new `return 2`. A record that cannot be written without overwriting prints its error, but `real_main` carries on to `results:` and `po-eval` exits 0. The free-name loop makes this path rare, but the refusal does not reach the exit code.
- minor — tests/real-run-before-a-release.test.sh:408 — `lead_double` now allows any command when the sandbox keys are on, which goes beyond the wording of plan task 7. The record declares and justifies it. It is a fair model of `autoAllowBashIfSandboxed`, but `test_gh_is_allowed_for_a_lead_that_follows_the_method` now proves only "gh not denied". Whether real Claude Code allows `gh` under the sandbox is left to the real run.

## Not verified
- **Claude Code under the sandbox.** No real `claude` session was run (forbidden by the run interdicts; paid). It is unverified that Claude Code 2.1.330+ honours the `sandbox` block from `CLAUDE_CONFIG_DIR/settings.json`, keeps `deny: Bash(curl:*)`/`Bash(claude:*)` under auto-allowed sandboxed Bash, and lets the lead write to `$J/origin.git`, `$J/prs` and `TMPDIR` through `allowWrite`. A person should run the next `po-eval real` and read the stream for `permission_denied` and sandbox violations.
- **Git ignore inside bwrap.** It is unverified that git, running inside bwrap, still reads the run's `XDG_CONFIG_HOME/git/ignore`, which is what hides the real masks. The test proves it only in the run's environment outside the sandbox; the research probe used `/usr/bin/bwrap` by hand. The next real run shows it.
- **Completeness of the governing lists.** It is unverified that they are complete against what a session can change: files such as `keybindings.json`, `plugins/data/`, and `HOME` files outside the list (`.ssh/`, `.config/` other than `git/`). It is also unverified that Claude Code does not rewrite a listed file (`plugins/installed_plugins.json`, `plugins/marketplaces/`) at start, which would invalidate a run again. The list is the owner's decision, and the plan names this as its pivot. Only a real run settles it.
- **macOS branch.** It has no `bwrap`/`socat` check and was not run.
- **CI behaviour.** I relied on the record's local suite run. The `$RTMP/sandbox-tools` stubs keep the launching tests passing on a runner without `bwrap`/`socat`, but I did not observe a GitHub Actions run of this tree. A person should check the PR's required checks.
- **Effects of a read-only `.git/config` in a lane.** `git config` and `git push -u` print errors there (research `## Traps`). This is out of the story's reach; the next real run shows it.

Max severity: major
Ship allowed: yes
