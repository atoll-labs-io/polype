# Research — s182-po-change-needs-a-version

[Story](../stories.md)

## Structuring facts
- **Root cause (#296).** No check compares a diff with its base. `bin/po-ci:15` runs the `Test` command and nothing else, and no test or script reads a base for `po/` (no `merge-base`/`origin/` use concerns the version). The checkout `.github/workflows/ci.yml:15-21` is depth 1, on the pull request's head from the head repository, so no base would be there anyway. Input that reaches it: any pull request that changes `po/` and leaves `po/Cargo.toml:3` alone. Proof: s176's landing ceece03 changed 4 files of `po/` with no version change, and its `suite` check concluded `success` (`gh api …/commits/<ceece03>/check-runs`). The harm is at `bin/polype:897-906`, which picks the prebuilt binary by `POLYPE_VERSION` alone.
- **Partly false assumption**: the notes say `bin/po-release:10-15` compares the three places. It compares two, `po/Cargo.toml` and `bin/polype`, and never reads `po/Cargo.lock`. Only `test_version_goes_up` (`tests/record-review-loose-ends.oracle.test.sh:89-98`) reads all three. Reuse that test's reading, not po-release's.
- **The workflow can only bring the base through checkout's own inputs.** `test_workflow_only_calls_the_entry` allows `run:` steps for `jq` and `bin/po-ci` only (`tests/ci-on-every-pr.oracle.test.sh:73-86`) and no `uses:` other than `actions/checkout` (`:87-89`). A `git fetch` step is ruled out.
- **The `head_ref` workaround is obsolete.** `ci.yml:17-21` exists because the quickstart test ran `git pull` in a clone of a detached checkout (`docs/ci.md:11`). s181 fixed that (`tests/readme-onboarding.test.sh:105-108`: bare clone plus `update-ref refs/heads/main HEAD`). The only other test that touches the target branch already handles a detached merge checkout (`tests/driver-next-action.test.sh:86-93`).
- **A technical choice waits for the owner**: where the check lives and how it finds its base on any forge. It is drafted as ADR-0125 (`proposed`). The plan is written for its option A.

## Diagnostic
**Reproduction.** I created no file. History of `po/src` since s164 (`git log -- po/src`, compared against `git diff <c>^ <c> -- po/Cargo.toml`): ceece03 (s176), e9de336 (s170), 758c061 (s175), acae0a2 (s169), b979845 (s168), 39b59a3 (s174), 8c3c1aa (s166), 173ac1d (s167) and f5ba595 (s165) changed `po/src` without a version line. ceece03's `suite` check reads `success`. The defect reproduces: a `po/` change with no bump goes through CI green.

**Hypotheses.**
1. *A version check exists but is skipped in CI because of the depth-1 checkout.* Would be refuted by finding no such check. `grep -rln "merge-base\|origin/main\|base_ref" tests/*.sh bin/ .github/` returns only `driver-next-action`, `held-says-what-collides`, `bounds` and `framing-second-landing`, about stories and owns, never `po/` versions. **Discarded.**
2. *`bin/po-release` guards the bump.* Would be refuted if it never compares against a base. It runs only on a `v*` tag (`.github/workflows/release.yml:3-5`), and `bin/po-release:10-15` checks two places against each other, not against a previous version. **Discarded.**
3. *Nothing compares the versions of a diff's two ends, and the checkout leaves no base to compare against.* Would be refuted by a red `suite` on a no-bump `po/` change. ceece03 is green. **Kept.**

## Story
A pull request that changes `po/` without raising the version fails the `suite` check (ADR-0122). Criteria:
- `po_diff_without_bump_is_refused`: a commit changing `po/` without a version change fails, and the message names the version and the files to bump together.
- `bump_moves_the_three_places`: a version raised in one or two of `po/Cargo.toml`, `po/Cargo.lock`, `POLYPE_VERSION` is refused, and so is a version that goes back or stays equal.
- `other_diffs_pass`: a diff outside `po/` passes; a pure bump passes.
- `missing_base_fails`: the base is a git ref; when it is absent the check fails and names it.
- `workflow_brings_the_base`: on a pull request the checkout brings the base branch from the base repository, never a fork, as the ref the check receives.
- `ci_still_has_one_entry`: the `run:` steps are still only `bin/po-ci` and the `jq` install (ADR-0105).

Precision, not a false assumption: raising the version always touches `po/` (`po/Cargo.toml`, `po/Cargo.lock`). "Bumps without touching `po/`" reads as "a bump with no other change", which passes under any reading.

## Current code
- `.github/workflows/ci.yml:3-6`: runs on `pull_request` and on pushes to `main`. `:15-21`: one checkout pinned on v4.4.0, `repository:` = head repo or own, `ref: ${{ github.head_ref }}`, no `fetch-depth` (default 1). `:22`: jq install. `:23`: `bin/po-ci`.
- `bin/po-ci:6-15`: resolves the root from its own path, reads `Test:` from `AGENTS.local.md` with `sed`, and runs it with `exec bash -c` from the root. Reads no forge variable (ADR-0105).
- `tests/run.sh:4-28`: builds `po` once and runs every `test_*` function of the files it gets (all `*.test.sh` by default), each in its own process.
- `docs/ci.md:11`: explains the `head_ref` checkout. `:17-18`: "bump both versions" at release time, without `Cargo.lock` and without saying the bump belongs to the change.
- Version today: `0.3.1` at `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27`.
- `po/` holds only `Cargo.toml`, `Cargo.lock` and `src/` (28 files); `po/target/` is ignored.

## Attachment points
- New `bin/po-version-check`, shaped like `bin/po-ci`: root from `$0`, settings read with the same `sed`, no forge variable.
- One test in `tests/po-change-needs-a-version.test.sh` runs it on `$ROOT`; that is what makes `suite` refuse (option A of ADR-0125).
- `.github/workflows/ci.yml` checkout `with:` block.
- `docs/ci.md` sections "Où" and "Publier une version".

## Verified interfaces
- Version readers to reuse (`tests/record-review-loose-ends.oracle.test.sh:91-93`):
  `sed -n 's/^version = "\(.*\)"$/\1/p' po/Cargo.toml | head -n 1`;
  `awk '$0 == "name = \"po\"" {getline; print; exit}' po/Cargo.lock | sed -n 's/^version = "\(.*\)"$/\1/p'`;
  `sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' bin/polype | head -n 1`.
- Ordering: `sort -V`, already used at `:97` of the same test.
- Setting reader: `sed -n "s/^Target branch:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*\$/\1/p"` (same form as `bin/po-ci:9`).
- `story_base` (`method/hooks/po-bounds.sh:131-153`) takes `git merge-base HEAD <refs>`. The story's diff is `<Target>...story/<id>` (AGENTS.md, "Ids and branches"), so the check diffs `merge-base(HEAD, base)..HEAD`.
- `scratch_repo` (`tests/lib.sh:47-54`) inits `-b main` with a neutral git config.

## Traps
- **The oracle is sourced from s159's.** `test_ci_still_has_one_entry` sources `tests/ci-on-every-pr.oracle.test.sh` and calls `test_workflow_only_calls_the_entry`, so ADR-0105's rule stays tested in one place. That file must keep loading on its own.
- **This story's own pull request exercises the new checkout.** The suite now runs on the merge commit, detached, with full history. `test_workflow_brings_the_base` needs `origin/main` in the checkout. Only the forge proves it.
- **Local runs need `origin/main`.** The repository has it (`git for-each-ref refs/remotes`). A clone with no remote sees the live test fail and name the ref. That is wanted (`missing_base_fails`).
- **A push to `main`**: with full history, `origin/main` = `HEAD`, the diff is empty, and the check passes without checking anything. The pull request has already checked it.
- `bin/po-version-check` copies nothing into projects: `bin/polype` does not ship `bin/po-ci` either (no `po-ci` in `bin/polype`).
- No `po/` change here, so no version moves (story notes). `tests/run.sh` and `bin/po-ci` are in `Owns` but option A leaves them alone.
- Full suite ~436 s (`docs/reviews/s181-suite-keeps-the-working-po.md:27`).

## Open questions
1. Does `actions/checkout@v4.4.0` with `fetch-depth: 0` on a `pull_request` event leave `refs/remotes/origin/main` of the base repository? This comes from its documented behaviour (it fetches all branches, then `refs/pull/N/merge`), not from a run. This story's own `suite` check settles it.
2. Does any other test break on a detached merge commit? None reads `$ROOT`'s branch (`grep 'abbrev-ref HEAD\|symbolic-ref'` finds only scratch repositories), but only the forge run proves it.
3. The owner's choice in ADR-0125: A, B or C.

## Complexity
Story 3 → 3. One small script, one test, a workflow tweak and docs. The width comes from the forge (merge checkout, full history), which only CI can prove.

## Split
Not needed.
