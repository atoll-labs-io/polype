# Review — s112-short-subject-shipped

[Story](../stories.md) · [Plan](../plans/s112-short-subject-shipped.md) · [Verification](../verif/s112-short-subject-shipped.md)

Diff reviewed: `git diff main...story/s112-short-subject-shipped` (one commit, 2e39495), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: c898531cf61cf7393db06f47c008db3996e01b30

The tree has not changed since I first took it: I checked again just before resending, and it is still `c898531cf61cf7393db06f47c008db3996e01b30`.

Lenses run: none. No path or content in the diff triggers the security, migration, dependency or performance lens: the change is a local, read-only bash hook and two markdown commands.

## Ownership
Owns: `method/hooks/po-session.sh`, `method/commands/po-status.md`, `method/commands/po-drive.md`, `tests/short-subject-shipped.test.sh`.
- [x] Every path is inside `Owns`. All four code paths match an entry exactly.
- `docs/plans/s112-short-subject-shipped.md` and `docs/verif/s112-short-subject-shipped.md` are this story's own pipeline evidence, so they are in scope by construction.
- This story came through the short track, so there is no research file; the plan's `## Verified facts` takes its place.
- [x] No path falls inside another running story's `Owns`. The only other worktree, s113-reuse-ladder, owns files that do not overlap with these.
- `.claude/` and `.polype/` are untouched.

## Evidence reused
- [x] `po-gate verif-current s112-short-subject-shipped` passes (exit 0), so I reused the record instead of rerunning the suite.
  - Under `Verification mode: record`, the record proves the full unit suite (`bash tests/run.sh`, exit 0) on this exact code. That includes `overlap.test.sh`, `project-lead.test.sh` and `resume.test.sh`.
  - The project has no Type check, E2E or Build command (`—`), so none was run.
- [x] `po-gate qa-current` is not required: with `QA stage: —`, this story does not go to QA.
- [x] `po-gate floor-guard s112-short-subject-shipped main` exits 0: nothing in the diff makes the checks easier to pass.

## Plan
- [x] Tasks 1 to 5 are all present, and nothing was changed outside the plan.
  - The shared sentence appears word for word in both `po-status.md:31` and `po-drive.md:31`.
  - In `po-drive.md:68`, only the left cell changed.
- [x] I checked each run interdict:
  - `.claude/` and `.polype/` have an empty diff.
  - The `po-session` output lines keep their exact text.
  - `read_shipped` still makes a single `git log` call and writes nothing.
  - `po-drive.md` changes only at lines 31 and 68, and `nothing — the story is done` is untouched.
  - `docs/stories.md` is not edited.
  - No existing test file is modified.

## References
- Every name the diff uses exists:
  - `is_shipped`, `SHORT_SHIPPED` and `subjects` are defined in `method/hooks/po-session.sh:128-145`.
  - All three places that read the shipped state (`:151`, `:154`, `:213`) now call `is_shipped`.
  - The test helpers `scratch_repo`, `fail` and `METHOD` are defined in `tests/lib.sh`.
- No other file in `method/` or `bin/` states the shipped rule (I grepped for `subject`).

## Tests
- 3 tests, within the budget of 25. Two run the real hook on a throwaway repository; the third checks the text.
- None of the six kinds of test that prove nothing applies. In the fixture, `Depends on: none` has no token shaped like an id, so it really means "no dependency".
- I disabled three rules, one at a time, and ran only `short-subject-shipped.test.sh` each time:

| Rule disabled | Tests failing |
| --- | --- |
| Short-subject fallback removed from `is_shipped` | 2 of 3 (`session_lists_no_short_shipped_story`, `short_subject_is_exact`) |
| Dependency reader reads `SHIPPED` directly | 1 of 3 (`session_lists_no_short_shipped_story`) |
| Short regex loosened to `^s[0-9]+`, without the colon | 2 of 3 (`short_subject_is_exact`, `short_subject_counts_as_shipped`) |

- After each one I ran `git checkout -- method/hooks/po-session.sh`, and `git diff --exit-code` confirmed the file was back to its committed state.

## Values
- `${1%%-*}` takes the digits exactly as the id writes them, so `s1` cannot match `s10-…`; the test shows this.
- `^s[0-9]+:` requires the colon right after the digits, so it does not match `s10-autre:` or `s01-x:`.
- An empty history is harmless: the hook runs with `set -u` and without `-e`.

## Neighbours
- I ran the story's hook against the main repository. It prints `Ready stories: none`, while the installed hook still lists s01 to s10 as ready. The defect is gone on real data.
- On `main`, `s92:` and `s92-review-tree-gate:` are both subjects for the same single story, so the fallback cannot misfire there.

## Findings
- **minor** — `method/commands/po-status.md:31`: the arrow `→ shipped`, which the plan kept, now follows the new sentence. The line reads "…is shipped when … as the id writes it → shipped", which says the same thing twice. This is wording only.
- **minor** — `tests/short-subject-shipped.test.sh`, `test_short_subject_counts_as_shipped`: the `po-session` half of this test is only a grep for the regex text inside `read_shipped`. It checks text, not behaviour. The two behavioural tests already cover the rule, so it adds nothing they do not, but it costs nothing either.

No critical or major findings.

## Not verified
- **The "pull request presumed waiting" line (`po-session.sh:213`):** no test covers it, and I did not exercise it, because it needs an `origin/story/<id>` ref plus `Ship confirmation: human` and `Merge mode: pr`. The plan justifies skipping it (it uses the same helper), and the record lists it under "Not proven here". To cover it, build a scratch repository with an `origin` remote holding `story/sNN-x` and a short `sNN:` commit on `origin/main`, then check that the line disappears.
- **Reading `origin/<Target branch>` in `read_shipped`:** no test has a remote, so this path was not exercised. The code there is unchanged, apart from now reading from a shared variable of subjects.
- **`/po-status` and `/po-drive` in action:** these are agent instructions. I checked their text but did not run either command to see the sentence applied.
- **Type check, E2E and build:** the project has none of these commands (`—`), so none was run.

Max severity: minor
Ship allowed: yes
