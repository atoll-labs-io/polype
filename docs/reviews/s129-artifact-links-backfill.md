# Review — s129-artifact-links-backfill

[Story](../stories.md) · [Plan](../plans/s129-artifact-links-backfill.md) · [Verification](../verif/s129-artifact-links-backfill.md)

Diff reviewed: `git diff main...story/s129-artifact-links-backfill`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 047655dc69cc5775a6b427de4b597f87cfdd1de0

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s129-artifact-links-backfill` and checked each path against the story's `Owns` line using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The diff has 438 files: `bin/po-link-artifacts` (A), `tests/artifact-links-backfill.test.sh` (A), the story's own plan and record (A), and 434 modified files under `docs/research/` (85), `docs/plans/` (117), `docs/reviews/` (116) and `docs/verif/` (116). Every one of those folders is in `Owns`.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The plan says no other lane is in progress.
- [x] The story has an `Owns` line (`docs/stories.md`, s129).

## Evidence reused
- [x] `po-gate verif-current s129-artifact-links-backfill` exits 0, so I reused the record (`Verification mode: record`). The `Unit suite` run (`bash tests/run.sh`) exited 0 on tree `6087af0e…`. I checked that this tree differs from the committed tree only in `docs/verif/s129-artifact-links-backfill.md`, which means the full suite ran on the backfilled docs. The project has no type check (`Typecheck: —`), no E2E and no build.
- [x] `po-gate qa-current`: not required, because `QA stage: —` and `Surface: —`.

## Plan
- [x] Tasks 1–5 are all present. Nothing in the diff is outside the plan. The short track has no research file; the plan's `## Verified facts` stands in for it.
- [x] I checked each run interdict:
  - `method/` has an empty diff.
  - `docs/stories.md`, `docs/decisions-log.md`, `docs/reviews/stories*.md` and `docs/reviews/triage-*.md` have empty diffs.
  - Every modified artefact is exactly `+2 -0`: all 434 of 434 by `git diff --numstat`. The only exceptions are the four added files.
  - No hand edits. The added lines fall into exactly four kinds: 118 × `[Story](../stories.md)` (85 research + 33 flow plans), 84 × `… · [Research](…)`, 116 × `… · [Plan](…)` and 116 × `… · [Plan](…) · [Verification](…)`, each paired with one blank line. Every hunk lands right after the title (line 3, or 6/7 after a frontmatter).
  - No ADR was added.
  - `bin/polype`, `.claude/`, `.polype/` and `docs/installation.md` are untouched.
  - No file mode changed.

## References
- [x] I opened and confirmed every reference:
  - `method/templates/{research,plan,plan-flow,review,verification-record,qa}.md` hold the six link lines the script reads.
  - The `bin/polype:88-89` pairs `bin:polype/bin method:polype/method`, so `$(dirname "$0")/../method/templates` resolves in the global install.
  - The `tests/lib.sh` helpers (`scratch_repo`, `fail`) and `po-run.sh` / `po-gate.sh` are used with their real arguments.
- [x] Values that look right are confirmed: for every one of the 434 changed files, each link target exists relative to the file's own directory, and the `<id>` in each link equals the file's id. I checked this independently of the story's test.

## Rules
- [x] `AGENTS.md` conventions are respected: bash, `set -u`, usage comment, English, one test file per story.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s129-artifact-links-backfill main` exits 0, so nothing was lowered.
- [x] The assertions pin down the three criteria: fixture lines are checked against the template lines, `cmp` confirms nothing else changed, the second run is idempotent, the real repository's links resolve, the gate codes are compared, and a run on a copy of `docs/` is a no-op. None of the six empty test shapes is present. The gate fixture runs the real `po-run` and `po-gate`.
- [x] There are 3 tests, within `Test budget: 25`.
- [x] Bite:
  - Existence filter removed (`resolvable`): 1 test fails (`backfill_is_a_script`). Undone, `git diff --exit-code` clean.
  - Skip-when-linked removed: 2 tests fail. Undone, clean.
  - `is_flow` forced to false: 0 tests fail (this file and `artifact-link-templates.test.sh`). Undone, clean. See Findings.
  - `^s[0-9]+-` id filter removed: 0 tests fail. Undone, clean. See Findings.
  - The worktree was confirmed clean after every run.
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read the positional readers of these files. `po-gate.sh:29`, `po-lint`, `po-session.sh:48` and `po-eval` read the frontmatter at line 1, which the script leaves alone. The verdict, status and `Tree:` lines are read by pattern or `tail`, and none depends on lines 2–3.
- [x] I compared the gates directly. In a throwaway clone of `main` under `/tmp`, I ran `po-gate plan-validated`, `ship-allowed`, `verif-current` and `qa-current` for all 117 stories (468 runs) and captured their output. Then I copied in the backfilled artefacts, committed, and ran them again. Exit codes and messages were identical, with hashes masked.

## Lenses
Lenses run: none. The diff has no auth, migration, lockfile or server-side path, and no matching content.
- [x] There are no lens findings.

## Findings
- minor — `tests/artifact-links-backfill.test.sh:34` (rule at `bin/po-link-artifacts:41`). The flow-plan fixture `s02-b` has no research file. When `is_flow` is forced to false, the full-plan template line loses its Research link through the existence filter and gives the same `[Story](../stories.md)`, so 0 tests fail. Plan task 1 says the test fails when flow detection is removed, and it does not. No real artefact is affected, since no flow plan has a research file. A fixture of a flow plan next to a research file would make the rule bite.
- minor — `bin/po-link-artifacts:45`. The `[[ "$id" =~ ^s[0-9]+- ]]` filter adds nothing to the `s[0-9]*-*` globs at lines 33–35 for the fixtures and the real files. Removing it fails 0 tests: the non-artefacts are excluded by the glob, not by this guard. Either drop the guard, or add a fixture that only the regex excludes, such as `s1x-foo.md`.

## Not verified
- **QA reports.** `docs/qa/` does not exist in this repository, so the script's `docs/qa/<id>/report.md` branch only ran on test fixtures, never on a real report. A person should check the first real QA report after `/po-qa` runs.
- **Backfill in nautile and pecten.** I did not check the run in those projects, which belongs to their own stories, after the Polype reinstall from `~/.claude/polype/bin`. Run `po-link-artifacts` there on a branch and check the same `+2 -0` diff.
- **Link rendering.** I did not check how the links render on GitHub or in Obsidian. I only checked that each link resolves on the filesystem. Open one plan and one review on GitHub and in the vault.
- **Content of the 434 artefacts.** I did not read them one by one. They are covered by the mechanical checks above: line kinds, position, `+2 -0`, link resolution, id match and gate parity.
- **Inputs outside the current data.** I did not exercise `awk -v` on a link line with a backslash, a title line hidden inside a code fence, or permissions other than 644 being lost by `mv`. None of these occurs in the current templates or files.

Max severity: minor
Ship allowed: yes

---

# Review — s129-artifact-links-backfill

[Story](../stories.md) · [Plan](../plans/s129-artifact-links-backfill.md) · [Verification](../verif/s129-artifact-links-backfill.md)

Diff reviewed: `git diff main...story/s129-artifact-links-backfill`, by a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 905f64f2b6c31ac4b7029db7f0533502c2215e21

## Ownership
I listed the diff with `git diff --name-only main...story/s129-artifact-links-backfill` and held each path against `Owns` (`docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/`, `docs/qa/`, `bin/po-link-artifacts`, `tests/artifact-links-backfill.test.sh`).
- [x] Every path is inside `Owns`. There are 434 backfilled artefacts, the story's own plan, record and review, the script and the test.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only the root on `main` and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s129-artifact-links-backfill` exits 0, so the record is reused (`Verification mode: record`). The `Unit suite` (`bash tests/run.sh`) exited 0 on tree `a2cc58b1…`, which is the fix-run code outside `docs/`. The project has no type check command (`Typecheck: —`). The "Not proven here" section says the 434 artefacts rest on mechanical checks, and I acted on that (see Neighbours).
- [x] `po-gate qa-current` is not required. `Surface: —` and `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–5 are present. The fix commit `cf70f34` closes both loop-0 minors:
  - It adds a `docs/research/s02-b.md` fixture next to the flow plan, so flow detection now bites.
  - It removes the `[[ "$id" =~ ^s[0-9]+- ]]` guard.
- [x] I checked the run interdicts one by one:
  - `method/`, `.claude/`, `.polype/`, `bin/polype`, `docs/installation.md`, `docs/stories.md`, `docs/decisions-log.md`, `docs/reviews/stories*.md` and `docs/reviews/triage-*.md` all have an empty diff.
  - `git diff --numstat -- docs` shows every file at `+2 -0` except this story's own plan, record and review.
  - No ADR was added.
  - No hand edit: see the reproduction under Neighbours.

## References
- [x] `method/templates/{research,plan,plan-flow,review,verification-record,qa}.md` each carry the link line the script reads (`TPL=$(dirname "$0")/../method/templates`). The script calls only `awk`, `sed`, `grep` and `basename`, nothing local that is missing. The test calls `scratch_repo`, `fail`, `po-gate.sh` and `po-run.sh`, and all of them exist.
- [x] Values: the `track: flow` regex, the ` · ` separator and the `[Story](` skip prefix all match the s128 templates and the 33 real flow plans. The reproduction confirms this.

## Rules
- [x] The `AGENTS.md` conventions are respected: a bash test file per story, English in the code, no installed file edited.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s129-artifact-links-backfill main` exits 0, so nothing was lowered.
- [x] The assertions pin down the three criteria. The fixtures show none of the six empty test shapes. The gate parity in `test_links_resolve_everywhere` runs the real `po-gate` on committed fixtures.
- [x] There are 3 tests, within `Test budget: 25`.
- [x] Bite, with only `artifact-links-backfill.test.sh` run each time:
  - Flow detection forced off (`if false; then tpl=plan-flow`, `bin/po-link-artifacts:41`): 1 failing test (`backfill_is_a_script`, `plans/s02-b: wrong line`). Undone; `git diff --exit-code` is clean. Loop-0 minor 1 is closed.
  - Existence filter removed (`true && out=`, `:28`): 1 failing test (`plans/s03-c` keeps its Research link). Undone; clean.
  - Skip-when-linked removed (`:48` replaced by `:`): 2 failing tests. Undone; clean.
- [x] No test is made useless by the story.

## Neighbours
- [x] Readers of these files read the frontmatter on line 1, or their lines by pattern or `tail`. `po-gate` excludes `docs/` from tree comparisons, so a link line changes no gate result. The fixture parity in the test and the loop-0 run of 468 gates already showed this.
- [x] The lead noted that the backfilled artefacts were not re-run after the fix. I covered that here: in a throwaway clone of `main` (`/tmp/tmp.qh82luna5O/m`, HEAD `066b03d`), the **post-fix** script changed 434 files. `diff -r` against the branch's `docs/` shows no difference apart from this story's own three evidence files. Dropping the guard therefore changed nothing on real data, and the committed artefacts are exactly the script's output.

## Lenses
Lenses run: none. The diff has no auth, migration, lockfile or server-side path, and no content that triggers a lens.
- [x] There are no lens findings.

## Findings
- minor — `docs/plans/s129-artifact-links-backfill.md` (task 1) against `bin/po-link-artifacts:33-35`. The plan still says the script "keeps only names matching `^s[0-9]+-`", and its test line lists a "name filter" bite. Since the fix run, the only filter is the `s[0-9]*-*` glob, which also accepts names that are not ids, such as `s1x-foo.md`. Today no real file is affected (the reproduction is byte-identical). Loop-0 allowed this option, but the plan text no longer describes the code.

## Not verified
- **QA reports.** `docs/qa/` does not exist in this repository, so the `docs/qa/<id>/report.md` branch has only run on test fixtures. A person should check the first real report after a `/po-qa` run.
- **Backfill in nautile and pecten.** That belongs to their own stories, run from `~/.claude/polype/bin`. Run `po-link-artifacts` there on a branch and check for a uniform `+2 -0` diff.
- **Link rendering on GitHub or Obsidian.** I only checked that the links resolve on the filesystem. Open one plan and one review in each to confirm.
- **Content of the 434 artefacts.** I did not read them one by one. They are covered by the reproduction from `main`, the `+2 -0` numstat and the link-resolution test.
- **Inputs outside the current data.** I did not exercise three cases: an `awk -v` link value with a backslash, a `# ` title inside a code fence before the real title, and file mode across `mv`. None of them occurs in the current templates or files.
- **The installed templates.** The copies in `.polype/templates/` (e.g. `review.md`) still lack the s128 link line on `main`. The script reads `method/templates`, so this story is not affected. A reinstall (`bin/polype-dev-install .`) refreshes them, but it is outside this diff.

Max severity: minor
Ship allowed: yes
