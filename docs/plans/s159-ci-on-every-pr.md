---
validated: yes
---
# Plan — s159-ci-on-every-pr

[Story](../stories.md) · [Research](../research/s159-ci-on-every-pr.md)

Branch `story/s159-ci-on-every-pr`. Read `docs/research/s159-ci-on-every-pr.md` first; this plan builds on it without repeating it.

## Story
The full suite runs on every pull request and every push to `Target branch` through one forge-neutral entry, `bin/po-ci`, called by a GitHub workflow (ADR-0105). A new setting, `Forge checks`, makes `/po-ship` merge only once the forge's checks pass on the landing commit; `—` or a missing line keeps today's ship. Criteria: `ci_entry_runs_the_suite`, `workflow_only_calls_the_entry`, `setting_declares_forge_checks`, `ship_waits_for_green_checks`, `missing_setting_changes_nothing`, `docs_say_how_to_require_the_check` (restated in the research).

Root cause (research, `## Diagnostic`): no step runs the suite on the tree that lands, since the gates leave `docs/` out (`po-gate.sh:75`) and `/po-ship` commits the review after the last run (`po-ship.md:51-52`); and no CI exists. Tasks 1-4 target exactly that.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `bin/po-ci` reading `Test:` | already in this repository: the `sed` of `local_setting` (`bin/polype:513-516`), copied, not sourced | `bin/polype` is an installer whose functions run with its own globals (`$project`); sourcing it to read one line would drag its setup in |
| Waiting for checks in `/po-ship` | already in this repository: `gh pr checks`, named at `po-ship.md:55`, and `--match-head-commit <sha>` at `po-ship.md:77` | — (prose, no code) |
| `.github/workflows/ci.yml` | the platform: GitHub Actions, `actions/checkout`, `apt-get` | no workflow exists in the repository |

## Acceptance tests
The three cases of the owner's rule of 2026-11-13 (`docs/stories.md:2496`), criterion by criterion. Gate check done in the research: `po-gate oracle-intact` reads only the oracle-file table (`method/hooks/po-gate.sh:608-612`), so a criterion without a test is admitted.

| Oracle file | cksum |
| --- | --- |
| `tests/ci-on-every-pr.oracle.test.sh` | `724301784 5040` |

| Criterion | Test |
| --- | --- |
| `ci_entry_runs_the_suite` | Case 2: the rule becomes the script `bin/po-ci`. `test_ci_entry_runs_the_suite` runs a copy in a scratch repo from a subfolder, with and without forge variables, beside a `bin/po-eval` stub that leaves a marker: exit 3 passed through, stdout and stderr passed through, run from the root, same output both ways, no marker. |
| `workflow_only_calls_the_entry` | Case 1: the forge reads the workflow's fields. `test_workflow_only_calls_the_entry` reads `.github/workflows/ci.yml`: `on:` names `pull_request` without branch or path filter and `push` covering `Target branch` of `AGENTS.local.md`; top-level `permissions:` and no `write`; every `run:` on one line, exactly one calling `bin/po-ci` and nothing else, the others installing `jq`; every `uses:` is `actions/checkout`. |
| `setting_declares_forge_checks` | Case 1: `bin/polype` (`missing_settings`, `bin/polype:540-563`) and `template_settings` (`tests/lib.sh:32`) read the template's fenced lines. `test_setting_declares_forge_checks`: `Forge checks` is a template setting valued `required` or `—`; this repo's `AGENTS.local.md` reads `required`. |
| `ship_waits_for_green_checks` | Case 3: the rule speaks to the model running `/po-ship`. No oracle test, no phrase test; the reviewer judges `po-ship.md` by reading it. Candidate for a `po-eval` control arm (#208): a ship given a red check, then no check, must stop with the pull request open. It cannot become a local script inside `Owns`: `bin/po-ci` is not installed into projects and must read no forge (research, Open questions). |
| `missing_setting_changes_nothing` | Case 3, as above. The reviewer reads `po-ship.md`. `po-eval` candidate (#208): a project without the line ships as before and the finish names `Forge checks`. |
| `docs_say_how_to_require_the_check` | Case 3 for its form (no script reads `docs/ci.md`): the reviewer reads it. Not a `po-eval` candidate: it speaks to a person, no agent acts on it. |

Oracle proven passable before the plan, outside the worktree (a scratch copy with a minimal `po-ci`, workflow and settings: 3 passed), and red on the worktree as it stands (3 failed). Six mutations each turned one test red: a branch on `GITHUB_ACTIONS`, a call to `po-eval`, a run outside the root, `contents: write`, a `branches:` filter on `pull_request`, a second command on the check line.

## Tasks
1. [x] **`bin/po-ci`**, executable (`chmod +x`, committed with mode 100755). Root = the folder above the script (`$(cd "$(dirname "$0")/.." && pwd -P)`); read the first `Test:` line of `$root/AGENTS.local.md` with the `local_setting` sed (`^Test:` never matches `Test budget:`); empty, missing file or `—` → a message on stderr naming `Test` and exit 2, never a guessed command; else `cd "$root" && exec bash -c "<Test>"`. No forge variable, no `po-eval`, no output of its own on success. A few lines, one *why* comment at most. Test that fails if wrong: `test_ci_entry_runs_the_suite`; plus one test of your own in `tests/ci-on-every-pr.test.sh`, `test_ci_entry_refuses_a_missing_test_command` (`Test: —` → exit 2, nothing run).
2. [x] **`.github/workflows/ci.yml`**: `name: ci`; `on:` `pull_request:` (no filter) and `push:` `branches: [main]`; top-level `permissions: contents: read`; one job `suite`, `runs-on: ubuntu-latest`, steps `actions/checkout@v4`, `run: sudo apt-get update && sudo apt-get install -y jq`, `run: bin/po-ci`. Every `run:` on one line. Nothing forge-specific beyond the file itself (ADR-0105: Forgejo Actions reads this syntax). Test: `test_workflow_only_calls_the_entry`.
3. [x] **The setting.** `method/templates/agents-local.md`: add `Forge checks:      —` to the Pipeline block, after `Project CLAUDE file`, and one table row: `required` — `/po-ship` merges only once the forge's checks pass on the landing commit · `—` — it does not wait for them; a missing line ships as before and is named. Pay the words: remove at least as many words elsewhere in the same file, keeping every phrase a test freezes (`tests/structure.test.sh`, `tests/ship-through-pr.test.sh`, `tests/claude-md-setting.test.sh`, `tests/installer.test.sh`, `tests/platform-setting.test.sh`, `tests/model-routing.test.sh`, `tests/qa.test.sh`). `AGENTS.local.md` (this repo): `Forge checks:      required` in its Pipeline block, after `Project CLAUDE file`. Tests: `test_setting_declares_forge_checks`, then `bash tests/run.sh structure.test.sh installer.test.sh ship-through-pr.test.sh claude-md-setting.test.sh`.
4. [x] **`/po-ship`** (`method/commands/po-ship.md`), net words ≤ 0 for the file:
   - `Reads settings:` (:11) gains `Forge checks`.
   - :20 "stop if the file or a setting is missing" gains its one exception: a missing `Forge checks` line ships as before the setting existed, and the finish names the setting as missing (ADR-0089 reading, `docs/decisions-log.md:192`).
   - In the `automatic` bullet (:77), before the second `po-gate ship-allowed`: with `Forge checks: required`, wait for the forge's checks on `<sha>`. Read them with `gh pr view <url> --json headRefOid` (must equal `<sha>`) and `gh pr checks <url> --json name,bucket,link`, deciding on the JSON, not on the exit code; poll every 30 seconds for at most **30 minutes**. Merge when at least one check exists and every bucket is `pass` or `skipping`. A `fail` or `cancel` bucket, or no complete set within 30 minutes → stop: the pull request stays open, nothing is merged, no fix run starts, and the finish goes to the person naming each failed check with its link, or saying none arrived. A forge `gh` cannot read (not GitHub, `gh` missing or logged out) stops the same way: `required` fails closed. The token rule of `po-ship.md:29` applies unchanged.
   - `Forge checks: —` or no line → the wait stays exactly today's: `ci` as `po-ship.md:55` and :77 say. Fold the :77 clause into the new text rather than adding a second wait.
   - Under an effective `Ship confirmation: human`, nothing changes: the ship stops at "Pull request ready" and the person merges.
   - The finish (:102) names `Forge checks` when its line is missing, and the checks' outcome when it waited.
   - Pay the words in the same file, keeping every phrase `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`, `tests/ship-follows-forge.test.sh` and the other `tests/*.test.sh` that read `po-ship.md` freeze (`grep -l po-ship.md tests/*.sh`). Unable to pay them without breaking a frozen phrase → stop and report; do not touch a test outside `Owns`.
   Tests: `bash tests/run.sh $(cd tests && grep -l 'po-ship' *.test.sh)` and `structure.test.sh`; criteria 4 and 5 are judged by the reviewer (case 3).
5. [x] **`docs/ci.md`**, in French, short: what the check runs (`bin/po-ci` → the `Test` command of `AGENTS.local.md`, `bash tests/run.sh` here; never `po-eval`, whose runs are paid, ADR-0105); where (GitHub hosted runners, `.github/workflows/ci.yml`, on every pull request and every push to `main`; moving to Forgejo Actions is a matter of moving the file, #75); what `Forge checks: required` makes `/po-ship` do; and the person's gesture, which no agent does: on GitHub, Settings → Rules → Rulesets (or Branches → branch protection) for `main`, "Require status checks to pass", check `suite`. Reviewer reads it.
6. [x] **Full suite**, once, through `po-run --story s159-ci-on-every-pr --label test -- 'bash tests/run.sh'`. No type check exists (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `method/templates/agents-local.md` and `method/commands/po-ship.md` end with no more words than on `main`: `git show main:<file> | wc -w` ≥ `wc -w < <file>` (M20 word rule).
- Empty diff for `method/commands/po-setup.md` (criterion 5; it belongs to s162), `method/hooks/po-gate.sh`, `bin/polype`, the root `AGENTS.md` (regenerated by framing after the ship), `.claude/`, `.polype/`, `docs/parite-killer-saas.md`.
- No test file outside `Owns` changes; `tests/ci-on-every-pr.oracle.test.sh` keeps its cksum unless `## Oracle changes` of the record says why.
- `bin/po-ci` and the workflow never name `po-eval`, `claude`, `GITHUB_`, `GITLAB_`, `GITEA_`, `FORGEJO_` (`grep -nE` on both files).
- No agent sets a branch protection, ruleset or required check on the forge, and none pushes `main`.
- `/po-ship` still runs `po-gate ship-allowed <id>` before any merge, and still merges with `--match-head-commit <sha>`.

## The pivot
The wait reads the checks of the pull request whose head is the landing commit, through `gh pr checks`, and fails closed. Ways it could be wrong:
- **Head not yet updated** after the push: `gh pr checks` would report the previous head's checks. Guard: compare `headRefOid` with `<sha>` before trusting any bucket; `--match-head-commit <sha>` already refuses a merge on another head.
- **30 minutes too short** for the suite on a runner, or a check that never reports (workflow disabled, Actions off): both stop the ship with the PR open, which is the intended failure mode; compare with the duration of the first run of `ci` on this story's own PR.
- **Over-reach on `—`**: rewriting the `ci` wait at :55/:77 could change a project that has `E2E stage: ci`. Compare the `—`/missing path against `main`'s text: same command, same condition.

## Files touched
`bin/po-ci` (new) · `.github/workflows/ci.yml` (new) · `docs/ci.md` (new) · `method/commands/po-ship.md` · `method/templates/agents-local.md` · `AGENTS.local.md` · `tests/ci-on-every-pr.oracle.test.sh` (oracle, written) · `tests/ci-on-every-pr.test.sh` (new, one test) · `docs/research/s159-ci-on-every-pr.md` · `docs/plans/s159-ci-on-every-pr.md` · `docs/verif/s159-ci-on-every-pr.md`

## Test strategy
Automated, 4 of `Test budget` 25:
- Script behaviour (case 2): `test_ci_entry_runs_the_suite` (oracle), `test_ci_entry_refuses_a_missing_test_command` (implementer, `tests/ci-on-every-pr.test.sh`).
- Machine-read fields (case 1): `test_workflow_only_calls_the_entry`, `test_setting_declares_forge_checks` (oracle).
- Existing suites that freeze the two method files run with task 3 and task 4, then the full suite once (task 6).

Read by the reviewer, no test (case 3): `ship_waits_for_green_checks`, `missing_setting_changes_nothing` (both `po-eval` candidates, #208), `docs_say_how_to_require_the_check`. No phrase test is added for any of them.

Not provable in the story: that the workflow passes on a GitHub runner. The first proof is the `ci` check of this story's own pull request; a red run there goes to the person, other tests are not edited to make it pass.

## Done when
One commit `s159-ci-on-every-pr: La suite complète tourne sur chaque pull request` landed through a pull request; the suite green locally (task 6) and the `ci` check green on that pull request; a review with no open critical finding; `docs/ci.md` tells the person how to make `suite` required on `main`.
