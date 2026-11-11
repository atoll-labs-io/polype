# Review — s150-oracle-intact-gate

[Story](../stories.md) · [Plan](../plans/s150-oracle-intact-gate.md) · [Verification](../verif/s150-oracle-intact-gate.md)

Diff reviewed: `git diff main...story/s150-oracle-intact-gate`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: aa22df15d8c07d8d14d48b9bb6a8e8793b22ef35

## Ownership
I listed the changed paths with `git diff --name-only main...story/s150-oracle-intact-gate` and checked each one against the story's `Owns` line (`docs/stories.md:2386`).
- [x] Every path is inside `Owns`. `method/hooks/po-gate.sh`, `method/skills/review-antihallu/SKILL.md` and `tests/oracle-intact-gate.oracle.test.sh` are listed there. The research, the plan and the record are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] No path sits inside another running story's `Owns`. s151 and s155 also own `po-gate.sh` and `review-antihallu/SKILL.md`, but `git worktree list` shows no lane for them. The only other worktree is `worktree-qa-report-and-bounds`, which is not a story branch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s150-oracle-intact-gate` passes, so the record is reused. The last Unit suite run (`bash tests/run.sh`) exited 0 on code that matches `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`). I read the record's "Not proven here": two rows for one file, a row naming an intact or unlisted file, and the installed copy are not tested.
- [x] `po-gate qa-current` is not required (`QA stage: —`).

## Plan
- [x] Tasks 1 to 5 are all present. Nothing in the diff goes beyond the plan.
- [x] I checked the run interdicts one by one:
  - `.polype/`, `.claude/`, `method/templates/review.md`, `method/agents/reviewer.md`, `method/commands/po-review.md` and `method/AGENTS.md` all have an empty diff.
  - `po-gate.sh` removes no line (`grep '^-[^-]'` prints nothing).
  - In the SKILL, the *Bite.* line is the only line removed, and there are still exactly six `**N. ` steps.
  - The oracle's cksum on the branch is `1293718647 7539`, which matches the plan.
  - No new setting and no new `method/` file. No `tests/oracle-intact-gate.test.sh` was created.

## References
- [x] I opened every reference and it exists: `top()` (`po-gate.sh:36`), `set -euo pipefail` (`:31`), and the dispatch `case` with its unknown-subcommand fallback (`:632`). The `| Oracle file | cksum |` header is in `method/templates/plan.md:22` and `plan-flow.md:39`. The `| Oracle file | What changes | Why |` header is in `method/templates/verification-record.md:24`. ADR-0098 is in `docs/decisions/`.
- [x] I checked the values. The sum format `<crc> <size>` is the `cksum < file` output the plan template prescribes. The exit codes 0, 1 and 2 match the other `po-gate` checks. Under `pipefail`, `git cat-file blob … | cksum` fails through `oracle_unreadable`, not through a stray `set -e` exit.

## Rules
- [x] `AGENTS.md` conventions are respected: the method text is in English, the tests are bash with one oracle file, and there is no edit to the installed copies.
- [x] No accepted ADR is contradicted. The header states the ADR-0052 and ADR-0098 limit, as the criterion requires.

## Tests
- [x] Oracle: the installed `.polype` copy does not have this subcommand yet, as the plan's pivot says. I ran the story's own `method/hooks/po-gate.sh oracle-intact s150-oracle-intact-gate`: exit 0, the oracle is intact.
- [x] Floor: `po-gate floor-guard s150-oracle-intact-gate main` exits 0, so nothing was lowered.
- [x] The assertions pin down the acceptance criteria. The gate tests build throwaway repositories, run the real gate from `main` and check exit code, stdout and stderr. None of the six empty test shapes is present.
- [x] 4 tests, within `Test budget` (25).
- [x] Bite, run with only `oracle-intact-gate.oracle.test.sh`:
  - I replaced `[ "$have" = "$want" ] || bad+=(… changed)` with `true`. 2 tests failed (`gate_compares_oracle_sums`, `gate_without_oracle_says_so`). Undone, and `git diff --exit-code` is clean.
  - I replaced the logged-path match `[ "$cpath" = "$path" ] || continue` with `true`. 1 test failed (`gate_compares_oracle_sums`). Undone, and `git diff --exit-code` is clean.
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read the other callers. `tests/evals.test.sh` calls only `floor-guard`. No doc or command lists the gate subcommands in a way that would now be stale. The existing gates and helpers are untouched.

## Lenses
Lenses run: none. No changed path or content matches the security, migration, dependencies or performance triggers.
- [x] No lens findings.

## Findings
- minor — method/templates/review.md:41 — The review template still has only a `Floor:` checklist line, with no slot for the new `po-gate oracle-intact` result, so a review can leave out the Oracle step without the template noticing. The file is outside this story's `Owns`, and the research names it as a follow-up for the lead to file. No change is due in this diff.

## Not verified
- I did not run the installed `.polype/hooks/po-gate.sh oracle-intact`, because the installed method is refreshed only after ship. A person should run `po-gate oracle-intact <id>` on the next lane after the refresh.
- Untested cases in `po-gate.sh`, named in the record: two `## Oracle changes` rows for one file, and a row naming an intact or unlisted file. I read these paths in the code but did not run them.
- Untested markdown edge cases: a `## ` heading inside a fenced code block in the plan or the record would be read as a section boundary, and an escaped `\|` inside a cell would split it.
- Untested platform case: git filters such as `autocrlf` could make a blob's sum differ from `cksum < file` on a working copy. Checking would need a probe repo with filters configured.

Max severity: minor
Ship allowed: yes
