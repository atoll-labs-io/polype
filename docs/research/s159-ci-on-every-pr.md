# Research — s159-ci-on-every-pr

[Story](../stories.md)

## Structuring facts
- **Root cause (#201).** Nothing runs the suite on the code that lands. The only proof `/po-ship` asks for under `Full suite: execute-end` is `po-gate verif-current` (`method/commands/po-ship.md:52`), and every tree comparison of the gates leaves `docs/` out (`method/hooks/po-gate.sh:75`); the review is committed by `/po-ship` itself, after the last suite run (`method/commands/po-ship.md:51`). No CI exists to catch the gap: `.github/` holds only `ISSUE_TEMPLATE/harness-support.md`. Input that reaches it: a review file the suite reads (`tests/artifact-links-backfill.test.sh:26-42` walks `docs/reviews/`). Proof: `f71ba00` (s147) added `docs/reviews/s147-strict-checks-by-default.md` in its landing commit and turned `main` red (#168); #187 repeated it for s156.
- **False assumption, partly.** "`/po-ship` nomme déjà les trois forges" holds for the forge's *review rule* (`po-ship.md:27-31`), but `/po-ship` merges through `gh` alone (`po-ship.md:77`); GitLab and Forgejo landing is left to a later story (`docs/decisions/ADR-0081-…md:53`). Waiting for checks can only be wired where the ship merges: GitHub. Elsewhere `required` must fail closed. The story is not contradicted; its risk note overstates the reach.
- **A vague wait already exists.** `po-ship.md:55` ("**`ci`** … wait for `gh pr checks` to be green") and `po-ship.md:77` ("wait for `ci` to be green when the project declares it") wait when `E2E stage` or `Build stage` is `ci` (`method/templates/agents-local.md:50,53`). Under `Forge checks: —` or missing, that behaviour must stay as it is ("rien ne change").
- **A missing setting stops the ship today**: `po-ship.md:20` "stop if the file or a setting is missing". `Forge checks` needs an explicit exception (decisions-log `docs/decisions-log.md:192`, same reading as `Project CLAUDE file`, ADR-0089).
- **The oracle gate admits a criterion without a test** (M20 check): `po-gate oracle-intact` reads only the `Oracle file` table (`method/hooks/po-gate.sh:608-612`); `templates/plan.md:20` asks one test "per acceptance criterion that a test can check". The lane may go on.

## Story
The full suite runs on every pull request and on every push to `Target branch`, through one forge-neutral script; `/po-ship`, when the project says so, merges only once the forge's checks pass on the landing commit. Criteria:
1. `ci_entry_runs_the_suite` — `bin/po-ci` runs the project's `Test` from the root, passes its output through, exits with its code; reads no forge variable, never runs `po-eval`.
2. `workflow_only_calls_the_entry` — triggers on every PR and every push to `Target branch`, installs `jq`, one check step calling `bin/po-ci`, no write right for the token.
3. `setting_declares_forge_checks` — template gains `Forge checks:` (`required` or `—`); this repo's `AGENTS.local.md` sets `required`.
4. `ship_waits_for_green_checks` — `required` + `Merge mode: pr`: wait for checks on the landing commit, merge only if all pass; red or none by the stated delay → stop, to the person, PR stays open; `—` changes nothing.
5. `missing_setting_changes_nothing` — no line → merge as before and name the setting in the report; `/po-setup` untouched.
6. `docs_say_how_to_require_the_check` — `docs/ci.md`: what runs, where, the person's gesture to require it on `Target branch`.

## Diagnostic
- **Reproduction** (read-only, no file created): `ls -la .github` → only `ISSUE_TEMPLATE`; `git log -- .github` → one commit (`1c3caa5`, issue template). `git show --stat f71ba00` lists `docs/reviews/s147-…md` and `docs/verif/s147-…md` in the landing commit; `docs/verif/s147-…md:11` `Tree:` names code outside `docs/` only (`docs/verif/s147-…md:9`). Issue #168 quotes the failing `artifact-links-backfill` tests on `main` after it.
- **H1 — the gates skip `docs/` by mistake.** Refuted: the exclusion is deliberate, commented at `po-gate.sh:74` ("the record, the ticked plan and the review are written after the code they judge"). Discarded.
- **H2 — `/po-ship` never reruns the suite on the landing tree.** Kept: `po-ship.md:52` reruns `<Test>` only when `verif-current` fails, and `verif-current` ignores `docs/`; no step runs it on the `merge-tree` result (`po-ship.md:69-70`). Would be refuted by a step that tests `<tree>`; none exists.
- **H3 — a CI exists but is not required.** Refuted: no workflow file at all.
- Root cause = H2 plus the absence of any CI; the story's fix (suite on the forge, ship waits for it) targets both.

## Current code
- `method/commands/po-ship.md` (102 lines, 3306 words). `Reads settings:` at :11. Step 1 checks :50-57; landing :59-77; `automatic` merge `gh pr merge <url> --rebase --match-head-commit <sha>` at :77; finish :102 names effective `Ship confirmation`.
- `method/templates/agents-local.md` (89 lines, 1089 words): Pipeline block :9-39, table :41-71, Commands block :75-83 (`Test:` :78).
- `AGENTS.local.md` (repo): `Target branch: main` :9, `Test: bash tests/run.sh` :44; no `Forge checks`.
- `bin/`: `ks-overlap po-eval po-link-artifacts po-lint polype polype-dev-install`; no `po-ci`. `.github/workflows/` absent; `docs/ci.md` absent.
- `tests/run.sh` runs every `tests/*.test.sh`, fails a file without `test_` (`tests/run.sh:15`). The suite calls `bin/po-eval` only with a fake `claude` (`tests/evals.test.sh:12-30`), and `tests/evals.test.sh:141` forbids `run.sh` naming the evals.

## Attachment points
- `bin/po-ci` (new): Polype's own entry; `bin/` is not installed into projects, so projects copy the pattern, not the file.
- `.github/workflows/ci.yml` (new).
- `po-ship.md`: `Reads settings:` :11; the "stop if a setting is missing" sentence :20; Step 1 `ci` bullet :55; `automatic` bullet :77; finish :102.
- `templates/agents-local.md`: Pipeline block (after `Project CLAUDE file`, :38) and table (:71).

## Verified interfaces
- `template_settings` (`tests/lib.sh:32-34`): names of every `Name:` line inside the template's fences.
- Installer `missing_settings` (`bin/polype:539-563`) reads the template's fenced lines and prints `missing setting: <Name>: <template value>` for each the project lacks, on `update` and `check`, writing nothing (ADR-0043). Adding the line makes `polype check` name `Forge checks` for every existing project, with the template's value.
- `local_setting` (`bin/polype:513-516`): `sed -n "s/^$1:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*\$/\1/p" … | head -n 1` — the way settings are read by script; `^Test:` does not match `Test budget:`.
- `gh pr checks` (gh 2.103.3): reads the PR's head; exit 8 = pending; with no check yet registered it errors, so a wait right after the push must poll. `gh api repos/{owner}/{repo}/commits/<sha>/check-runs` reads one exact commit.
- `po-ship.md:29`: GitHub read with `gh api` pinned `--hostname github.com` (ADR-0083).

## Traps
- **Word rule of M20** (`docs/stories.md:2496`): any word added to `po-ship.md` or `templates/agents-local.md` is paid by as many removed from the same file. Measure with `wc -w` against `git show main:<file>`.
- Tests freezing phrases of the two method files: `tests/ship.test.sh`, `tests/ship-through-pr.test.sh` (:21, :50 reads the `Merge mode` row), `tests/structure.test.sh` (:8-12 one value per fenced line, regex `^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$`; :23-30 every `Reads settings` name must be a template setting), `tests/installer.test.sh:154-171` (template minus two lines → exactly two missing settings: still true with one more line), `tests/ship-follows-forge.test.sh`, `tests/claude-md-setting.test.sh`.
- `/po-ship` of this very story runs from the installed copy (`.claude/commands/po-ship.md`), which predates the setting: s159's own ship does not wait; its PR is the first where the workflow runs (a `pull_request` workflow added by the PR runs on it).
- The suite has never run on a neutral machine: a test bound to the developer's machine may go red on the runner. That is the point of the story, not a reason to touch other tests; a red first run goes to the person.
- `actions/checkout` gives a shallow detached checkout: no local `main`. Tests use scratch repos (`tests/lib.sh:46-53`) and `$ROOT` files; none found running `git` on `$ROOT` history.
- `docs/parite-killer-saas.md:62,86` mention CI reading at ship; the file is outside `Owns`, left as is.

## Open questions
- Delay of the wait: the command must state one. 30 minutes, polled every 30 s, is proposed; the suite's duration on a runner is unknown until the first run.
- Template default: `—` keeps a new project that has no workflow from stopping each ship; this repo sets `required`. A plan decision, inside criterion 3.
- `ship_waits_for_green_checks` cannot become a small local script inside `Owns`: the only script path owned, `bin/po-ci`, is not installed into projects and must read no forge. Case 3; a `po-gate`-side helper would be a later story.

## Complexity
Story 4 → 4. Two small new files and one script are simple; the weight is `/po-ship`'s wait (three outcomes, a delay, fail closed off GitHub) under a zero-net-words rule, with the old `ci` wait to keep.

## Split
—
