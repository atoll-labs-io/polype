# Review — s209-git-runs-outside-the-sandbox

[Story](../stories.md) · [Plan](../plans/s209-git-runs-outside-the-sandbox.md) · [Verification](../verif/s209-git-runs-outside-the-sandbox.md)

Method version: 0.11.0
Recorded: 2026-11-24T10:44:47+01:00

Diff reviewed: `git diff main...story/s209-git-runs-outside-the-sandbox`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: c3a868bfd654a5adb31883cf77b4edb3b740667f

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s209-git-runs-outside-the-sandbox`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `evals/real/lib.sh` is under `evals/real/`. The two records and `docs/evals/real-run.md` are under `docs/evals/`. Both ADR files are under `docs/decisions/`; the ADR-0137 change touches only `superseded-by` in the frontmatter. The two s209 test files and `tests/real-run-in-the-sandbox.oracle.test.sh` are listed by name. research, plan and verif are pipeline evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. The only other open lane is s210-lanes-run-git-with-dash-c, which owns `method/…`, `bin/po-lint`, `tests/lanes-run-git-with-dash-c.*` and `tests/lint.test.sh`. This diff touches none of them.
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current s209-git-runs-outside-the-sandbox`: exit 0, so I reused the record. The unit suite `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check, E2E or build (`Typecheck: —`, `E2E: —`, `Build: —`). The record's "Not proven here" says no real run took place; that point is carried to Not verified.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, and there is nothing outside the plan.
  - Task 1: `excludedCommands: ["git"]` and `"Bash(git *)"` are in `real_permissions`, the comment cites ADR-0138, and the announce line is updated.
  - Task 2: `! -path ./.config/git/ignore` is added in `real_governing`.
  - Task 3: `real_governing_file`, `real_hold_governing`, the call in `real_one` with its `rm -rf`, and the write-once pair in `real_session_held`.
  - Task 4: the task test.
  - Task 5: s208's oracle, the doc lines 16/28/35 and the ADR-0137 frontmatter.
  - Task 6: the records. `cksum` gives `776923962 984` and `2639938192 1077`, the same as the sources in `~/.claude/jobs/c268121d/tmp/records/`. The 11-24 file also matches the untracked copy in the main checkout.
- [x] Run interdicts, checked one by one:
  - No path among `po/`, `method/`, `bin/`, `evals/real/claude-print`, `evals/real/grade.sh`, `evals/real/cases/`, `tests/journey/` or `docs/evals/real-2026-11-23-v0.12.0.md` is in the diff.
  - The ADR-0137 body is untouched.
  - The oracle is intact (gate exit 0).
  - `excludedCommands` holds only `git`, and `Bash(git *)` is the only Bash rule.
  - `deny` is unchanged.
  - None of `allowUnsandboxedCommands`, `ignoreViolations`, `network`, `bypassPermissions` or a dangerous-skip flag appears.
  - `real_env` still writes the masks, and there is no `core.excludesFile`.
  - Validity still rests on the in-memory `REAL_GOVERNING`; the content copy only explains.
  - No raw stream was copied.
  - I did not launch `po-eval real` with a real `claude`.
  - Pivot check: `evals/real/grade.sh` does not read `git status` (grep is empty).

## References
- [x] Every call target exists: `real_governing`, `real_sigs`, `real_parent_sigs`, `real_above_sigs`, `real_project_sigs`, `real_claude_json`, `real_scrub`, `real_finish`, `REAL_WORK` (`mktemp -d` under `REAL_TMP`, removed by `real_finish`), `REAL_OUT` and `ARMS_SUFFIX[a]` (`a` is local to `real_one`). I checked `real_governing_file` against every label family `real_governing` emits: `config/`, `config/projects/`, `config/.claude.json`, `home/`, `home/.claude.json`, `bin/`, `gh/`, `git-config`, `git-hooks/`, `origin-config`, `origin-hooks/`, `run/`, `worktrees/`, `above:`, `project/` and `worktree/`.
- [x] No value that only looks right. The sandbox keys are exactly the five the oracle pins. The deny list is the four from ADR-0137. `real_scrub` walks `find -type f` and so reaches `<case>.<n>.changed/`. `cp -P` keeps a symlink as a link, so it never copies what a session-planted link points to.

## Rules
- [x] `AGENTS.md` conventions respected. The code and comments are in English and the docs and ADR in French. The diff is one commit, and the oracle changes are recorded under `## Oracle changes`.
- [x] No accepted ADR contradicted. ADR-0138 is accepted on the owner's choice of 2026-11-24 and replaces ADR-0137 on one point. ADR-0137 gets `superseded-by: [ADR-0138]` and stays `accepted` because it is replaced only in part. ADR-0138 lists options B to E and why each was turned down.

## Tests
- Oracle: `po-gate oracle-intact s209-git-runs-outside-the-sandbox` → exit 0
- [x] Floor: `po-gate floor-guard s209-git-runs-outside-the-sandbox main` exit 0, nothing lowered. `po-gate oracle-intact` exit 0. The two declared changes to s208's oracle (allow equals `["Bash(git *)"]`; the ignore form replaced by a `.config/git/attributes` form that must still read as a change) follow ADR-0138 and do not weaken a criterion. The attributes form keeps the "rest of `.config/git/`" clause tested.
- [x] Assertions pin the criteria, and none of the six empty test shapes is present.
  - The oracle runs `po-eval real` end to end with a claude double.
  - The kept-pair test checks `before` and `after` by `cmp` against real files.
  - The scrub check uses the sentinel login.
- [x] Within `Test budget` (25): 3 new tests, 2 edited.
- [x] Bite 1: the `! -path ./.config/git/ignore` exclusion removed. 1 test fails (`mask_list_is_not_governing`, `invalid — … (home/.config/git/ignore)`). Undone; `git diff --exit-code evals/real/lib.sh` clean.
- [x] Bite 2: the write-once guard `[ ! -e "$REAL_OUT.changed" ]` forced to `true`. 1 test fails (`kept_pair_follows_the_first_change`). Undone; `git diff --exit-code` clean.
- [x] Bite 3: `config/*` dropped from `real_governing_file`. 1 test fails (`mask_list_is_not_governing`, the kept pair is missing). Undone; `git diff --exit-code` clean.
- [x] No test made useless.

## Neighbours
- [x] `real_session_held` is called only by `real_launch`, twice on a drive run, and the write-once rule covers the second call. Outside `lib.sh`, `real_hold_governing` and `real_governing_file` are used only by the new task test. No other test sets `REAL_GOVERNING` directly. `REAL_GOVERNING_COPY` is read as `${…:-}`, so a caller that never holds the copy still works.

## Lenses
Lenses run: security — content: the run's permission and sandbox policy (`real_permissions`: `excludedCommands`, a new `Bash(git *)` allow rule), and kept files that may carry a login.
- [x] Each lens finding graded and listed under Findings. Git can now run any program outside the sandbox through `!` aliases, `-c core.hooksPath`, `core.sshCommand` or `core.fsmonitor`, with the person's write and network reach. ADR-0138 states this, the owner chose it, and `docs/evals/real-run.md` says it in "La limite". It is a decided and documented limit, not a new finding. The login in the kept files is scrubbed (the oracle checks the sentinel). The account e-mail a `.claude.json` may hold is stated in the doc.

## Findings
- minor — evals/real/lib.sh:236 — `real_governing_file` maps a `worktree/<rel>/<f>` label to `$R/<rel>/<f>`, which is only right for a lane inside `$R`: `real_governing` builds the label from `${wt#"$R"/}`, so a worktree that `git worktree list` reports outside `$R` gives `worktree//abs/path/f`, mapped to `$R//abs/path/f`, and the kept pair of such an invalid run comes out empty. Validity is unaffected; only the explanation is lost. The same first-field cut (`awk '{print $1}'`, and the `sed` of `real_session_held`) also loses a governing path that contains a space.

## Not verified
- No real run, and none allowed here. Only the next real run under a watching person can show three things:
  - that Claude Code honours `sandbox.excludedCommands: ["git"]`;
  - that `Bash(git *)` matches `git -C <path> …`, `git -c …` and compound forms such as `cd <path> && git …`;
  - that the lead then opens its lanes.
  That run should check its stream for `permission_denied` on git.
- Who writes git's global ignore is not proven (research, Open questions). The pivot's first risk also stays open: a writer that rewrites the file rather than appending to it. Someone should read the `git status` lines in the kept results of the next real run.
- A session-planted entry in the global ignore can now hide a file from `git status` without invalidating the run, which ADR-0138 accepts. I only confirmed by grep that `grade.sh` reads no `git status`. I did not trace each predicate of `grade.sh`.
- I did not rerun the full suite: the record proves it on this code. Only the three files the bites touch were run.

Max severity: minor
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-24T12:04:19+01:00

Diff reviewed: `git diff main...story/s209-git-runs-outside-the-sandbox`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 9da7c9fef71281aa2fa8a06bf66e38ec5a301986

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s209-git-runs-outside-the-sandbox`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill. I used the `Owns` line on `main`, which is the same in both versions of the story.
- [x] Every path inside `Owns`.
  - `evals/real/lib.sh` is under `evals/real/`.
  - The two records and `docs/evals/real-run.md` are under `docs/evals/`.
  - `docs/decisions/ADR-0137-…` and `ADR-0138-…` are under `docs/decisions/`. The only change to ADR-0137 is `superseded-by: [ADR-0138]` in its frontmatter (Law 6).
  - `tests/git-runs-outside-the-sandbox.{oracle.,}test.sh` and `tests/real-run-in-the-sandbox.oracle.test.sh` are listed by name.
  - The research, plan, verification and review files are pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s210 owns `method/…`, `bin/po-lint` and `tests/lanes-run-git-with-dash-c.*`/`tests/lint.test.sh`, and this diff touches none of them.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s209-git-runs-outside-the-sandbox` exited 0, so I reused the record. The unit suite `bash tests/run.sh` has a row with exit 0 on code equal to `Tree:` outside `docs/`. The project has `Typecheck: —`, `E2E: —` and `Build: —`, so there is no type check, E2E or build to run. I read the record's "Not proven here" and carried its points to Not verified.
- [x] `po-gate qa-current`: not required. With `QA stage: —` the story does not go to QA.

## Plan
- [x] Tasks 1–8 are present and nothing is outside the plan. In detail:
  - Task 7: `deny` gains `Bash(git -c *)`, `Bash(git * -c *)` and `Bash(git --config-env*)`, in that order after the four entries ADR-0137 set (`evals/real/lib.sh:118-119`), and the comment is extended.
  - Task 8: ADR-0138's Decision Outcome, its Bad consequences (both the first and the new one) and its Considered Options line are rewritten as the plan says. `docs/evals/real-run.md` lines 28 and 35 are amended.
  - Tasks 1–6 are unchanged since `a1e2463`.
  - Records: `cksum` gives `776923962 984` and `2639938192 1077`. Those equal the sources in `~/.claude/jobs/c268121d/tmp/records/` and, for 11-24, the untracked copy in the main checkout.
- [x] Run interdicts, checked one by one:
  - None of these is in the diff: `po/`, `method/`, `bin/`, `evals/real/claude-print`, `grade.sh`, `cases/`, `tests/journey/`, `docs/evals/real-2026-11-23-v0.12.0.md`, `docs/stories.md`.
  - The ADR-0137 body is untouched.
  - The oracle cksum is `1969442039 4746`, as in the plan.
  - `excludedCommands` is `["git"]` only, and `Bash(git *)` is the only Bash allow rule.
  - The deny list is exactly the seven entries the plan names, in order.
  - None of `allowUnsandboxedCommands`, `ignoreViolations`, `network` or `bypassPermissions` appears.
  - `real_env` masks are untouched, and there is no `core.excludesFile`.
  - Validity still rests on the in-memory `REAL_GOVERNING`.
  - No raw stream is copied in.
  - I did not launch a real `claude`.

## References
- [x] Every call target exists: `real_governing`, `real_governing_file`, `real_hold_governing`, `real_session_held`, `REAL_WORK`, `REAL_OUT` and `ARMS_SUFFIX[a]`. The fix commit adds no new reference.
- [ ] One value only looks right. ADR-0138 and `docs/evals/real-run.md` say the three rules refuse `--config-env` "quoi qui le précède". The rule `Bash(git --config-env*)` only matches it in first position (see Findings).

## Rules
- [x] The `AGENTS.md` conventions are respected. Code and comments are in English, the ADR and doc in French. The fix run has one commit of its own, and the oracle change is announced by the amended plan with its new sum.
- [x] No accepted ADR is contradicted. ADR-0138 is written in this story, so its body may still change. It now matches the amended criterion on `main` (`git show main:docs/stories.md`, s209).

## Tests
- Oracle: `po-gate oracle-intact s209-git-runs-outside-the-sandbox` → exit 0
- [x] Floor: `po-gate floor-guard s209-git-runs-outside-the-sandbox main` exited 0, so nothing was lowered.
- [x] The oracle check, `po-gate oracle-intact`, exited 0. The fix commit's change to `test_git_runs_outside_the_sandbox`, which pins the exact seven-entry deny list, carries the planner's new sum, and it tightens the criterion rather than weakening it. The two changes to s208's oracle stay recorded under `## Oracle changes` and still follow ADR-0138.
- [x] The assertions pin the criteria, and none of the six empty test shapes is present. The oracle goes through `po-eval real --build` and runs with a claude double. The kept pair is compared with `cmp`, and the scrub is checked with the login sentinel.
- [x] Within `Test budget` (25): 3 new tests and 2 edited. The amendment adds none.
- [x] Bite 1: I removed `"Bash(git * -c *)"` from `deny`. 1 test failed (`git_runs_outside_the_sandbox`). I undid it, and `git diff --exit-code evals/real/lib.sh` is clean.
- [x] Bite 2: I removed `excludedCommands: ["git"]`. Across the s209 oracle and s208's oracle, 1 test failed (`git_runs_outside_the_sandbox`). I undid it, and `git diff --exit-code evals/real/lib.sh` is clean.
- [x] No test made useless. The fix-loop-0 bites on the ignore exclusion, the write-once guard and the `config/*` mapping cover code the fix did not touch.

## Neighbours
- [x] The plan says `tests/real-run-is-usable.oracle.test.sh` and `tests/real-run-before-a-release.test.sh` check deny by membership only. The recorded full suite on this code is green. The `git -c` uses in `method/hooks/po-gate.sh` and `evals/real/lib.sh:486-502` run inside scripts, not as Bash tool commands, so the new deny rules do not reach them. `method/` writes no `git switch -c` or `git … -c` command for an agent to type.

## Lenses
Lenses run: security — content: the run's permission policy (`real_permissions`: `excludedCommands: ["git"]`, `Bash(git *)` allow, three new git deny rules) and kept files that may hold a login.
- [x] Each lens finding is graded and listed under Findings. Git running outside the sandbox, the gaps for environment-passed and file-written config, and the over-refusal of a legitimate `-c` are decided by the owner and stated in ADR-0138, so they are not new findings. The overstated `--config-env` claim is a finding.

## Findings
Security findings: 1 — decision d-0062
- minor — docs/evals/real-run.md:35 — The inserted git sentence ends "la personne qui regarde fait le reste." It is immediately followed by the existing "La présence de la personne en est le complément.", whose "en" now refers to the git sentence instead of "Ce confinement". The two sentences now say the same thing twice.
- minor — evals/real/lib.sh:240 — Carried from fix loop 0 and still open. `real_governing_file` maps `worktree/<rel>` to `$R/<rel>`, which is only right for a lane inside `$R`. A worktree outside `$R` gives the label `worktree//abs/…`, and the kept pair comes out empty. The first-field cut (`awk '{print $1}'` at :168, and the `sed` in `real_session_held`) also loses a governing path that contains a space. Validity is unaffected; only the explanation of an invalid run is lost.

## Not verified
- No real run, and none is allowed here. Only the next real run under a watching person can show the following, so that person should look for `permission_denied` on `git` lines in the stream:
  - that Claude Code honours `sandbox.excludedCommands: ["git"]`;
  - that `Bash(git *)` matches `git -C <path> …`;
  - that the three deny rules match case-sensitively, so that `git -C` is not refused;
  - that the lead then opens its lanes.
- The case-sensitive matching and the refusals listed in ADR-0138's Neutral line rest on the lead's probe of 2026-11-24, not on anything I ran.
- Whether a leading `VAR=… git …` or an environment-passed config gets past the rules is not proven anywhere (the record says so too).
- Who writes git's global ignore, and whether it gets rewritten rather than appended to, is not proven. Someone should read the kept pairs and the `git status` lines of the next real run.
- An entry a session adds to the global ignore can now hide a file from `git status` without invalidating the run, which ADR-0138 accepts. Fix loop 0 checked only that `grade.sh` reads no `git status`; nobody traced each of its predicates.
- I did not rerun the full suite: the record proves it on this code. I ran only `git-runs-outside-the-sandbox.oracle.test.sh` and `real-run-in-the-sandbox.oracle.test.sh` for the bites.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-24T14:01:23+01:00

Diff reviewed: `git diff main...story/s209-git-runs-outside-the-sandbox`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: d623b31e045151012ff16da42ac8ec629a619676

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s209-git-runs-outside-the-sandbox`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill. The `Owns` line is the same on `main` and in the worktree.
- [x] Every path is inside `Owns`:
  - `evals/real/lib.sh` falls under `evals/real/`.
  - `docs/evals/real-run.md` and the two records fall under `docs/evals/`.
  - ADR-0137 and ADR-0138 fall under `docs/decisions/`. The only change to ADR-0137 is `superseded-by: [ADR-0138]` in its frontmatter, which Law 6 allows.
  - The three test files are each named in `Owns`.
  - The research, plan, verif and review files are pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane, and `story/s209-…` is not an ancestor of `main` (`merge-base --is-ancestor` exit 1).
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s209-git-runs-outside-the-sandbox` exited 0, so I reused the record. The last unit-suite run (`bash tests/run.sh`) exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check, E2E or build (`Typecheck: —`, `E2E: —`, `Build: —`). I read the record's "Not proven here" and carried its points to Not verified.
- [x] `po-gate qa-current`: not required. With `QA stage: —` the story does not go to QA.

## Plan
- [x] All tasks 1–11 are present, and nothing in the diff is outside the plan.
  - Task 9: `Bash(git * --config-env*)` is last in `deny`, and the comment says "the four git deny rules".
  - Task 10: the ADR-0138 Considered Options line, Decision Outcome, first and second Bad, and Neutral are rewritten. The Neutral cites the lead's second probe rather than "only a real run shows", which is more precise. `real-run.md` line 28 names the four refusals. On line 35, the git sentence now sits before "Ce confinement…", which is again followed by "La présence de la personne en est le complément." The doubled closing clause is gone.
  - Task 11: a `worktree//*` branch in `real_governing_file`, plus its task test.
- The story is judged against the criterion on `main` (PR #501 wording): the deny list holds ADR-0137's four, then `Bash(git -c *)`, `Bash(git * -c *)`, `Bash(git --config-env*)` and `Bash(git * --config-env*)`, and nothing else. This matches.
- [x] Run interdicts, checked one by one:
  - None of these is in the diff: `po/`, `method/`, `bin/`, `evals/real/claude-print`, `grade.sh`, `cases/`, `tests/journey/`, `docs/evals/real-2026-11-23-v0.12.0.md`, `docs/stories.md`.
  - The ADR-0137 body is untouched.
  - The oracle is intact (gate exit 0).
  - `excludedCommands` is exactly `["git"]`.
  - `Bash(git *)` is the only Bash allow rule.
  - The deny list has the eight entries in order.
  - None of these appears: `allowUnsandboxedCommands`, `ignoreViolations`, `network`, `bypassPermissions`.
  - `real_env` still writes the masks, and there is no `core.excludesFile`.
  - Validity still rests on the in-memory `REAL_GOVERNING`.
  - No raw stream was copied.
  - I launched no real `claude`.
- [x] Records:
  - `cksum` gives `776923962 984` (11-24) and `2639938192 1077` (11-23 `-2`), identical to the sources in `~/.claude/jobs/c268121d/tmp/records/`.
  - The 11-24 file is byte-identical (`cmp`) to the untracked copy in the main checkout.
  - `records_are_landed` is met.

## References
- [x] Every call target exists:
  - `real_governing`, `real_sigs`, `real_parent_sigs`, `real_project_sigs`, `real_above_sigs`;
  - `real_governing_file`, `real_hold_governing`, `real_session_held`, `real_scrub` / `real_finish`;
  - `REAL_WORK`, `REAL_OUT`, `ARMS_SUFFIX[a]`.

  The fix commit 03180eb adds no new reference.
- [x] No value that only looks right in the code. The four deny patterns are the ones on `main`'s criterion and in d-0062. One documentation claim does not hold (see Findings).

## Rules
- [x] The `AGENTS.md` conventions are respected. Code and comments are in English, the ADR and doc in French. The fix run has one commit of its own.
- [x] No accepted ADR is contradicted. ADR-0138 is written in this story, so its body may still change. ADR-0137 stays `accepted` because it is only partly replaced, and points to ADR-0138.

## Tests
- Oracle: `po-gate oracle-intact s209-git-runs-outside-the-sandbox` → exit 0
- [x] Floor: `po-gate floor-guard s209-git-runs-outside-the-sandbox main` exited 0, so nothing was lowered. `po-gate oracle-intact` exited 0. The two changes to s208's oracle stay declared under `## Oracle changes` and follow ADR-0138. Neither weakens a criterion.
- [x] The assertions pin the criteria, and none of the six empty test shapes is present:
  - The oracle runs `po-eval real` through `--build` and a claude double.
  - The kept pair is checked with `cmp`.
  - The scrub is checked with the login sentinel.
- [x] Within `Test budget` (25): 4 new tests and 2 edited.
- [x] Bite 1: removed `"Bash(git * --config-env*)"` from `deny` → 1 failing test (`git_runs_outside_the_sandbox`) → undone, `git diff --exit-code evals/real/lib.sh` clean.
- [x] Bite 2: removed the `worktree//*` branch of `real_governing_file` → 1 failing test (`lane_outside_the_root_maps_to_its_path`) → undone, `git diff --exit-code` clean, `git status --porcelain` empty.
- [x] No test made useless. The bites of fix loops 0 and 1 (the ignore exclusion, the write-once guard, the `config/*` mapping, `excludedCommands`, `git * -c *`) cover code the last fix did not touch.

## Neighbours
- [x] `real_session_held` is called only from `real_launch`, and its write-once rule covers the second call.
- [x] Outside `lib.sh`, `real_governing_file` and `real_hold_governing` are used only by the task tests.
- [x] `main`'s `method/` (s210 landed) writes no `git … -c` or `git -c` for an agent to type. A grep outside `hooks/` is empty, so the `-c` rules refuse no command the method prescribes.
- [x] `real-run-is-usable` and `real-run-before-a-release` check deny by membership only. The recorded suite is green.

## Lenses
Lenses run: security — content: the run's permission and sandbox policy (`real_permissions`: `excludedCommands: ["git"]`, the `Bash(git *)` allow rule, four git deny rules), and the kept governing files, which may carry a login.
- [x] Each lens finding is graded and listed under Findings.
  - The following are decided by the owner and stated in ADR-0138, so they are not new findings: git outside the sandbox, the environment-passed config gap, and the over-refusal of a legitimate `-c`.
  - Previous security finding: lifted, decision d-0062. The rule it asked for is in `deny` at `evals/real/lib.sh:120`. The oracle pins it, and bite 1 proves the oracle catches its removal. ADR-0138 and `real-run.md` line 28 name it.

## Findings
Security findings: 1 — decision d-0063
- minor — evals/real/lib.sh:168 — Carried from fix loops 0 and 1. The plan leaves it on purpose for the lead to file. The first-field cut (`awk '{print $1}'` here, and the `sed` of `real_session_held` at :347) drops a governing path that contains a space, so the kept pair of such an invalid run comes out empty. Validity is unaffected.

## Not verified
- No real run took place, and none is allowed here. Only the next real run under a watching person shows that Claude Code honours `sandbox.excludedCommands: ["git"]`, that `Bash(git *)` matches `git -C <path> …`, and that the lead then opens its lanes. That person should look for `permission_denied` on `git` lines in the stream.
- The case-sensitive matching of the four deny rules is not something I ran. Neither are the refusals of `git -C <path> --config-env=…` and `git --no-pager --config-env=…` or the pass of `git -C <path> log`. They rest on the lead's two probes of 2026-11-24, cited in ADR-0138's Neutral.
- Whether a leading `VAR=… git …` or an environment-passed config gets past the rules is proven nowhere. The record says so too.
- The route in the major finding was found by reading `real_governing`, not by running it under Claude Code. Whether Claude Code's Edit tool or sandbox refuses part of it (for instance writing under a fresh `.git/`) was not tried. A probe in a throwaway run would settle it.
- Who writes git's global ignore, and whether it is appended to or rewritten, is not proven. Someone should read the kept pairs and the `git status` lines of the next real run.
- An entry a session adds to the global ignore can hide a file from `git status` without invalidating the run, which ADR-0138 accepts. Earlier loops confirmed only by grep that `grade.sh` reads no `git status`; nobody traced each of its predicates.
- I did not rerun the full suite, because the record proves it on this code. I ran only `git-runs-outside-the-sandbox.oracle.test.sh` and `git-runs-outside-the-sandbox.test.sh` for the bites.

Max severity: major
Ship allowed: yes
