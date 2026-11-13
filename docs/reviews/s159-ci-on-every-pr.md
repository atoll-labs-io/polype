# Review — s159-ci-on-every-pr

[Story](../stories.md) · [Plan](../plans/s159-ci-on-every-pr.md) · [Verification](../verif/s159-ci-on-every-pr.md)

Diff reviewed: `git diff main...story/s159-ci-on-every-pr`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 50714eb6186f35d0167867bb153db4d433b6f1f6

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s159-ci-on-every-pr`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `.github/workflows/ci.yml` falls under `.github/workflows/`. `AGENTS.local.md`, `bin/po-ci`, `docs/ci.md`, `method/commands/po-ship.md`, `method/templates/agents-local.md`, `tests/ci-on-every-pr.oracle.test.sh` and `tests/ci-on-every-pr.test.sh` are file entries. The research, plan and verif files are the story's own evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other story lane is s160 (`.worktrees/s160-intake-title-bounded`, not merged into `main`). It owns `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `docs/harnais.md` and its own tests, so the two lanes share no path.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s159-ci-on-every-pr` exits 0, so the record is reused. Its `bash tests/run.sh` run exited 0 on the code of `Tree: 7d724b26…`. The project has no type check (`Typecheck: —`). I read the record's "Not proven here": the GitHub runner run, the three criteria the reviewer judges by reading, and the ruleset that only a person sets.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, and nothing lies outside the plan.
- [x] Each run interdict checked:
  - Word counts: `agents-local.md` goes from 1089 to 1087 words, `po-ship.md` from 3306 to 3302.
  - The diff leaves these empty: `po-setup.md`, `po-gate.sh`, `bin/polype`, the root `AGENTS.md`, `.claude/`, `.polype/`, `docs/parite-killer-saas.md`.
  - No test file outside `Owns` changed. The oracle cksum is still `724301784 5040`, and `oracle-intact` exits 0.
  - `grep` finds no `po-eval|claude|GITHUB_|GITLAB_|GITEA_|FORGEJO_` in `bin/po-ci` or the workflow.
  - No branch protection is set and nothing is pushed.
  - `po-gate ship-allowed` and `--match-head-commit <sha>` are still in place before the merge (`po-ship.md:82`).

## References
- [x] Every reference opened and confirmed:
  - The `sed` in `bin/po-ci` matches `local_setting` (`bin/polype:514-517`).
  - `template_settings` is at `tests/lib.sh:32`.
  - `missing_settings` (`bin/polype:540`) will name a missing `Forge checks` line in `install`/`check` for existing projects, as the template row says ("is named").
  - The `gh pr checks --json` fields `name,bucket,link` exist in gh 2.103.3, and the bucket values `pass/fail/pending/skipping/cancel` are gh's own.
  - `gh pr view --json headRefOid` exists.
- [x] Values: the 30 s poll and 30 min limit come from the plan, as the story asks ("the delay the command states"). Exit 2 on a missing `Test` matches the plan.

## Rules
- [x] `AGENTS.md` conventions respected:
  - `Reads settings:` of `po-ship.md` gains `Forge checks`, and the template declares it.
  - Method files are in English and `docs/ci.md` is in French.
  - The M20 word rule is met in both method files.
- [x] No accepted ADR is contradicted:
  - ADR-0105: GitHub-hosted runners, a forge-neutral `bin/po-ci`, never `po-eval`, and branch protection left to the person.
  - ADR-0089: a missing line is named and changes nothing.

## Tests
- [x] Floor: `po-gate floor-guard s159-ci-on-every-pr main` exits 0, so nothing was lowered.
- [x] The assertions pin down criteria 1 to 3, and none of the six empty test shapes appears. The oracle runs a real copy of `po-ci` in a scratch repository with a `po-eval` stub, and checks that forge variables are neutralised. Criteria 4 to 6 are case 3 and were judged by reading:
  - `ship_waits_for_green_checks`: met at `po-ship.md:83`. The wait runs under `automatic` with `pr`. It checks `headRefOid == <sha>` and decides on the JSON. It fails closed on `fail`/`cancel`, on a timeout, or on an unreadable forge, and the PR stays open with no fix run.
  - `missing_setting_changes_nothing`: met at `po-ship.md:20` and `:83`. The text of the `—`/missing path matches `main`.
  - `docs_say_how_to_require_the_check`: met in `docs/ci.md`. It says what the check runs, where, and the person's gesture for the `suite` check.
- [x] Test budget: 4 of 25.
- [x] Bite:
  - Removing the `"$test_cmd" = "—"` guard in `bin/po-ci` makes 1 test fail (`ci_entry_refuses_a_missing_test_command`, exit 127). Undone, and `git diff --exit-code bin/po-ci` is clean.
  - Removing `cd "$root" &&` in `bin/po-ci` makes 1 test fail (`ci_entry_runs_the_suite`, "did not run from the root"). Undone, and `git diff --exit-code bin/po-ci` is clean.
- [x] No existing test is made useless by the story.

## Neighbours
- [x] I read the other readers of the changed files and found nothing broken:
  - `bin/polype` `missing_settings`/`check` reports the new template line as information only; `check` does not exit non-zero for it.
  - The freezing tests (`ship*.test.sh`, `structure.test.sh`, `installer.test.sh`, …) are covered by the passing full-suite run in the record.

## Lenses
Lenses run: none. No changed path or content matches the security, migration, dependencies or performance triggers. The workflow sets token permissions but contains no authorization check, URL input, upload, webhook or LLM call.
- [x] No lens finding.

## Findings
- minor — .github/workflows/ci.yml:16 — `run: sudo apt-get update && sudo apt-get install -y jq` relies on `sudo`, which the default Forgejo runner images (Debian `node:*`, run as root) probably lack.
  - `docs/ci.md:11` and ADR-0105 both promise that moving to Forgejo Actions is only a matter of moving the file. With `sudo`, that move would likely turn the first step red.
  - Not verified on a Forgejo runner. A step that skips `sudo` when it is absent, or a note in `docs/ci.md`, would keep the promise.
- minor — .github/workflows/ci.yml:15 — `actions/checkout@v4` is pinned to a moving tag, not a commit SHA. The token is read-only and the trigger is `pull_request`, not `pull_request_target`, so exposure is small. Pinning to a SHA is the usual hardening for a public repository.

## Not verified
- That `.github/workflows/ci.yml` runs green on a GitHub-hosted runner. No run of the `suite` check exists yet, and the suite may depend on tools or git state that `ubuntu-latest` lacks. A person should watch the first `suite` run on this story's pull request. A red run goes to the person; tests are not edited to make it pass.
- The `/po-ship` wait (`po-ship.md:83`) was judged only by reading. No ship ran against a red check, a missing check or a timeout. These are `po-eval` candidates (#208), as the plan says.
- Whether `gh pr checks` lists a second workflow that registers late, before every check has appeared. If it does not, a set read as complete could still miss a check. Not tested against the forge.
- The Forgejo portability of the workflow (first finding), because no Forgejo runner is available here.
- The ruleset that makes `suite` required on `main` is a person's gesture, done outside this story (`docs/ci.md`, "Le geste de la personne").

Max severity: minor
Ship allowed: yes

Diff reviewed: `git diff main...story/s159-ci-on-every-pr`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 80e1743ce8be9bd81b962b0dd073b0fe7c20cd97

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s159-ci-on-every-pr` and held each path against the story's `Owns`.
- [x] Every path is inside `Owns`:
  - `.github/workflows/ci.yml` falls under `.github/workflows/`.
  - `AGENTS.local.md`, `bin/po-ci`, `docs/ci.md`, `method/commands/po-ship.md`, `method/templates/agents-local.md`, `tests/ci-on-every-pr.oracle.test.sh` and `tests/ci-on-every-pr.test.sh` are file entries.
  - The research, plan, verif and review files are the story's own evidence.
  - The fix commit `46a98fb` touches only `.github/workflows/ci.yml`, `docs/ci.md` and the record.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none.
  - `story/s161-installer-leftovers` has no commits yet. Its `Owns` (`bin/polype`, `docs/installation.md`, `method/AGENTS.md`, its tests) shares no path with this story.
  - `framing/decisions-d1-d4` is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s159-ci-on-every-pr` exits 0, so I reused the record:
  - `Tree: db1b7530…`, with the last `bash tests/run.sh` run exiting 0 on that code.
  - `Typecheck: —`, so the project has no type check.
- [x] I read the record's "Not proven here". It covers the green GitHub run, the jq step on a Forgejo root runner, the three criteria judged by reading, and the ruleset.
- [x] `po-gate qa-current` is not required: with `QA stage: —` the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are present.
- [x] The fix commit has a reason: the forge failure on PR #220 and the two minor findings of loop 0. It changes three things:
  - It checks out the PR head as a local branch (`repository:`/`ref:` on checkout).
  - It pins `actions/checkout` to a commit.
  - It installs jq only when jq is missing, without `sudo` when running as root.
- [x] The workflow's `run:` steps keep the plan's shape: one jq step and one step that calls only `bin/po-ci`.
- [x] Run interdicts hold:
  - Word counts: `po-ship.md` goes from 3306 to 3302 words, `agents-local.md` from 1089 to 1087.
  - No change to `po-setup.md`, `po-gate.sh`, `bin/polype`, the root `AGENTS.md`, `.claude/`, `.polype/` or `docs/parite-killer-saas.md`.
  - The oracle cksum is still `724301784 5040`.
  - No forge variable or `po-eval` appears in `bin/po-ci` or in the workflow. `github.*` expressions appear only in the checkout `with:`, which is the forge-neutral form of the workflow file itself. No `GITHUB_` env var is read.
  - `po-gate ship-allowed` and `--match-head-commit <sha>` are still in place.

## References
- [x] Pin: `git ls-remote https://github.com/actions/checkout` shows that `11d5960a326750d5838078e36cf38b85af677262` is `refs/tags/v4.4.0`, as the comment says.
- [x] Checkout behaviour at that pin: I read `src/ref-helper.ts` (fetched at that commit).
  - An unqualified `ref` naming a branch that exists on origin gives `ref = <branch>` and `startPoint = refs/remotes/origin/<branch>`. That is a local branch, not a detached HEAD.
  - On `push`, `head_ref` is empty and the default `github.ref`/`github.sha` path stays.
- [x] Failure reproduced and fix replayed, both in a temp directory:
  - A shallow clone of the story branch, detached on a commit no branch holds, makes `readme-onboarding.test.sh` fail `quickstart_runs_as_written` (5 passed, 1 failed). That is the failure seen on PR #220.
  - Replaying the checkout steps (`fetch --depth=1` of the branch refspec, then `checkout --force -B <branch> refs/remotes/origin/<branch>`) makes it pass, 6 of 6, with the branch tracking `origin/<branch>`.
- [x] The jq line `command -v jq >/dev/null || if …; then …; else …; fi` is valid shell (`||` followed by a compound command).
- [x] Values: the 30 s poll and the 30 min limit come from the plan. Exit 2 on a missing `Test` comes from the plan.

## Rules
- [x] `AGENTS.md` conventions hold:
  - `Reads settings:` gains `Forge checks`, and the template declares it.
  - Method files are in English, `docs/ci.md` is in French.
  - The M20 word rule is met.
- [x] No accepted ADR is contradicted. ADR-0105 holds: hosted runners, the forge-neutral `bin/po-ci`, no `po-eval`, and the ruleset left to the person. ADR-0089 holds: a missing line is named and changes nothing.
- [x] The `pull_request` trigger with `repository: head.repo.full_name` still runs under the read-only token. It is not `pull_request_target`, so a fork's code never gets a write token.

## Tests
- [x] Floor: `po-gate floor-guard s159-ci-on-every-pr main` exits 0.
- [x] None of the six empty test shapes appears. The oracle runs a real copy of `po-ci` with a `po-eval` stub and with forge variables set.
- [x] Criteria 4 to 6 (case 3) were judged by reading:
  - `po-ship.md:20`: a missing line ships as before and is named.
  - `po-ship.md:78`: under `automatic`, the ship waits on the JSON once `headRefOid == <sha>`. It fails closed on `fail`/`cancel`, a timeout or an unreadable forge, and the PR stays open. With `—` or no line, the `ci` wait is unchanged.
  - `docs/ci.md` says what runs, where, and the person's gesture.
- [x] Test budget: 4 of 25.
- [x] Bite:
  - Removing `cd "$root" &&` in `bin/po-ci` makes 1 test fail (`ci_entry_runs_the_suite`). Undone; `git diff --exit-code bin/po-ci` is clean.
  - Removing the `repository:` and `ref:` lines of the workflow fails 0 tests (oracle 3 passed). Undone; `git diff --exit-code .github/workflows/ci.yml` is clean. See the second finding.

## Neighbours
- [x] I read the other readers of the changed files and found nothing broken:
  - `missing_settings`/`check` in `bin/polype` only reports the new template line.
  - The tests that freeze `po-ship.md`/`agents-local.md` are covered by the full-suite run in the record.
  - Nothing else reads `.github/workflows/ci.yml` apart from the oracle.

## Lenses
Lenses run: none. No changed path or content matches the security, migration, dependency or performance triggers. The workflow pins an action, but a workflow `uses:` is not a manifest or a lockfile, and it holds no authorization check, URL input, upload, webhook or LLM call.
- [x] No lens finding.

## Findings
- minor — .github/workflows/ci.yml:21 — `ref: ${{ github.head_ref }}` checks out the branch tip as it stands when the job starts, not the event's `github.event.pull_request.head.sha`. If a push lands between the event and the checkout, GitHub attaches the check of the earlier SHA to a run of the later code.
  - `/po-ship` is safe from this: it waits for `headRefOid == <sha>`, and nothing pushes after the landing commit.
  - On any other pull request, a check can report on a commit it did not run.
  - A fix that keeps a local branch: after checkout, `git checkout -B "$GITHUB_HEAD_REF" "${{ github.event.pull_request.head.sha }}"`. But that adds a step the plan's one-check-step shape would have to admit. Otherwise, write the limit down in `docs/ci.md`.
- minor — .github/workflows/ci.yml:16-21 — No local test guards the rule that the fix loop depends on (a PR checkout on a local branch, not a detached merge commit). Removing `repository:` and `ref:` leaves `ci-on-every-pr.oracle.test.sh` at 3 passed. A later edit could bring back the PR #220 failure. The failure shows itself, because `suite` goes red on the next pull request, so this stays minor.
- The two minor findings of loop 0 (`sudo` and the unpinned `actions/checkout@v4`) are fixed by `46a98fb`.

## Not verified
- That `suite` runs green on a GitHub-hosted runner with the fixed checkout. I only replayed the checkout's git steps locally, read from its source at the pinned commit. The next `suite` run on PR #220 is the proof, and a person should watch it.
- The checkout of a pull request from a fork (`repository: head.repo.full_name`). No fork PR exists to try it on.
- The jq step on a Forgejo runner image (root, no `sudo`), because no Forgejo runner is available here.
- The `/po-ship` wait (`po-ship.md:78`) was judged by reading only. No ship ran against a red check, a missing check or a timeout. These are `po-eval` candidates (#208).
- Whether `gh pr checks` already lists a workflow that registers late, so that a set read as complete is really complete. Not tested against the forge.
- The ruleset that makes `suite` required on `main` is a person's gesture (`docs/ci.md`, "Le geste de la personne").

Max severity: minor
Ship allowed: yes

Diff reviewed: `git diff main...story/s159-ci-on-every-pr`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 80e1743ce8be9bd81b962b0dd073b0fe7c20cd97

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
I listed the diff with `git diff --name-only main...story/s159-ci-on-every-pr` and checked each path against the story's `Owns`.
- [x] Every path is inside `Owns`. `.github/workflows/ci.yml` is under `.github/workflows/`. `AGENTS.local.md`, `bin/po-ci`, `docs/ci.md`, `method/commands/po-ship.md`, `method/templates/agents-local.md`, `tests/ci-on-every-pr.oracle.test.sh` and `tests/ci-on-every-pr.test.sh` are file entries. The research, plan, verif and review files are the story's own evidence. Fix commit `46a98fb` touches only `.github/workflows/ci.yml`, `docs/ci.md` and the record.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `story/s161-installer-leftovers` sits at `main` with no commits, and its `Owns` shares no path with this story. `framing/decisions-d1-d4` is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s159-ci-on-every-pr` exits 0, so I reused the record: its last `bash tests/run.sh` run exited 0 on the current code. The project has no type check (`Typecheck: —`).
- [x] I read the record's "Not proven here". It lists the green GitHub run, the jq step on a Forgejo root runner, the three criteria judged by reading, and the ruleset.
- [x] `po-gate qa-current` is not required: with `QA stage: —` the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are present.
- [x] The fix commit has a reason: the failure on PR #220 and the two minor findings of loop 0. It changes three things:
  - It checks out the PR head as a local branch, with `repository:` and `ref:` on the checkout step.
  - It pins `actions/checkout` to a commit.
  - It installs jq only when jq is missing, and skips `sudo` when running as root.
- [x] The workflow keeps the plan's shape: one jq step and one step that only calls `bin/po-ci`.
- [x] Run interdicts hold:
  - The word counts went down: `po-ship.md` from 3306 to 3302, `agents-local.md` from 1089 to 1087.
  - Nothing changed in `po-setup.md`, `po-gate.sh`, `bin/polype`, the root `AGENTS.md`, `.claude/`, `.polype/` or `docs/parite-killer-saas.md`.
  - Neither `bin/po-ci` nor the workflow mentions `po-eval` or reads a forge env var.
  - `po-gate ship-allowed` and `--match-head-commit <sha>` are still in place.

## References
- [x] Every reference opened and confirmed:
  - The pin `11d5960a326750d5838078e36cf38b85af677262` is `refs/tags/v4.4.0` of `actions/checkout`, as the comment says.
  - At that pin, an unqualified `ref` naming a branch checks out a local branch, not a detached HEAD. On `push`, `head_ref` is empty and the default path applies.
  - Locally, a detached clone reproduces the `quickstart_runs_as_written` failure seen on PR #220. Replaying the checkout's branch steps makes it pass.
  - The jq line is valid shell.
- [x] Values: the 30 s poll, the 30 min limit and exit 2 on a missing `Test` all come from the plan.

## Rules
- [x] `AGENTS.md` conventions hold: `Reads settings:` gains `Forge checks` and the template declares it; method files are in English and `docs/ci.md` is in French; the M20 word rule is met.
- [x] No accepted ADR is contradicted. ADR-0105 holds: hosted runners, a forge-neutral `bin/po-ci`, no `po-eval`, and the ruleset left to the person. ADR-0089 holds: a missing line is named and changes nothing.
- [x] The trigger stays `pull_request` with a read-only token, not `pull_request_target`.

## Tests
- [x] Floor: `po-gate floor-guard s159-ci-on-every-pr main` exits 0.
- [x] None of the six empty test shapes appears. The oracle runs a real copy of `po-ci` with a `po-eval` stub and with forge variables set. Criteria 4 to 6 (case 3) were judged by reading `po-ship.md:20`, `po-ship.md:78` and `docs/ci.md`.
- [x] Test budget: 4 of 25.
- [x] Bite:
  - Removing `cd "$root" &&` in `bin/po-ci` fails 1 test (oracle: 2 passed, 1 failed). Undone, and `git diff --exit-code bin/po-ci` is clean.
  - Removing the `repository:` and `ref:` lines (`ci.yml:20-21`) fails 0 tests (4 passed). Undone, and `git diff --exit-code .github/workflows/ci.yml` is clean. See the second finding.

## Neighbours
- [x] I read the other readers of the changed code and nothing is broken:
  - In `bin/polype`, `missing_settings` and `check` only report the new template line.
  - The tests that freeze `po-ship.md` and `agents-local.md` are covered by the recorded full-suite run.
  - Only the oracle reads `ci.yml`.

## Lenses
Lenses run: none. No changed path or content matches the security, migration, dependency or performance triggers. A workflow `uses:` is not a manifest or a lockfile, and the diff has no authorization check, URL input, upload, webhook or LLM call.
- [x] No lens finding.

## Findings
- minor — .github/workflows/ci.yml:21 — `ref: ${{ github.head_ref }}` checks out the branch tip at the moment the job starts, not the event's `github.event.pull_request.head.sha`. If a push lands between the event and the checkout, the check for the earlier SHA reports on later code.
  - `/po-ship` is safe from this, because it waits for `headRefOid == <sha>` and nothing pushes after the landing commit.
  - Any other pull request can get a check on a commit it did not run.
  - Two ways out: re-point the local branch at the event SHA after checkout, or write the limit down in `docs/ci.md`.
- minor — .github/workflows/ci.yml:20 — No local test guards the rule this fix loop depends on: a PR checkout on a local branch, not a detached merge commit. Removing `repository:` and `ref:` leaves the story's tests at 4 passed, so a later edit could bring back the PR #220 failure. It stays minor because `suite` would go red on the next pull request.

## Not verified
- That `suite` runs green on a GitHub-hosted runner with the fixed checkout. I only replayed the checkout's git steps locally. A person should watch the next `suite` run on PR #220.
- The checkout of a pull request from a fork (`repository: head.repo.full_name`). No fork PR exists to try it on.
- The jq step on a Forgejo runner image (root, no `sudo`). No Forgejo runner is available here.
- The `/po-ship` wait (`po-ship.md:78`), judged by reading only. No ship ran against a red check, a missing check or a timeout. These are `po-eval` candidates (#208).
- Whether `gh pr checks` lists a workflow that registers late, so that a set read as complete really is complete. Not tested against the forge.
- The ruleset that makes `suite` required on `main`. It is a person's gesture (`docs/ci.md`, "Le geste de la personne").

Max severity: minor
Ship allowed: yes
