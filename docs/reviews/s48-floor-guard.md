# Review: s48-floor-guard

Diff reviewed: `git diff main...story/s48-floor-guard`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: b2fa4f1a705c18e469e1019f3a6640b80bf655df

## Ownership
Diff listed with `git diff --name-only main...story/s48-floor-guard`. Each path was checked against `Owns`: `method/hooks/po-gate.sh`, `method/templates/review.md`, `method/skills/review-antihallu/`, `tests/floor-guard.test.sh`.
- [x] `method/hooks/po-gate.sh`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md` and `tests/floor-guard.test.sh` are inside `Owns`.
- [x] `docs/research/`, `docs/plans/` and `docs/verif/s48-floor-guard.md` are this story's own evidence, so they are in scope.
- [x] One path is outside `Owns`: `docs/decisions/ADR-0025-garde-de-plancher-lit-le-diff.md`. A written rule requires it ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so it is a gap in `Owns` and rated minor, not an implementer breach.
- [x] No overlap with another running story. The only other worktree is `story/s51-qa-agent`. Its `Owns` and its diff (qa.md, po-qa.md, po-bounds.sh, agents-local.md, po-setup.md, po-help.md, design-doctrine, qa/bounds tests, ADR-0026) share no path with s48.

## Evidence reused
- [x] `po-gate verif-current s48-floor-guard` exits 0. The record's tree `d01ff1d1…` matches HEAD outside `docs/` (`git diff --quiet` exits 0), and the record is marked complete with every exit code at 0. I reused it for the unit suite (`bash tests/run.sh`, 252 passed). The type check is `—`: the project has no such command. Its "Not proven here" section says the guard was never run under macOS awk or mawk (only `gawk --posix`), and that user git configs were covered only as far as the tests set them.

## Plan
- [x] Tasks 1–6 are all present. The pattern table, the test paths, the empty-catch, strict-flag and threshold rules, the exit-code helper, the dispatch branch, the skill bullet and the template box match the plan almost verbatim. The diff adds nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - `method/agents/reviewer.md`, `po-review.md`, `method/AGENTS.md`, `bin/`, `.claude/` and `.polype/` are not in the diff.
  - `po-gate.sh` only adds lines (numstat `159 0`), so the existing function bodies are unchanged.
  - `gate.test.sh`, `review.test.sh` and `ownership.test.sh` are not in the diff.
  - The skill still has exactly 6 `**N. ` lines and keeps its heading.
  - Grepping for `\s`, `\b`, `\d`, `gensub` and `{n}` found nothing in `po-gate.sh`. The only hits were `${…}` expansions.
  - `docs/parite-killer-saas.md` and `docs/references/` are untouched.
  - `bin/po-lint` exits 0 (23 files).

## References
- [x] I opened `top`, `refuse`, the dispatch `case`, `scratch_repo`/`contains`/`require_file`/`fail` in `tests/lib.sh`, and the `run.sh` focused mode. All exist with the signatures used.
- [x] Values: the `-U0` hunk-header parsing (a missing `,count` means 1, `,0` means a pure deletion) is correct. `--find-renames` is pinned on both diffs, so `diff.renames=false` in the user config cannot turn a rename into a deletion, and the test exercises that. Exit 0 on an empty diff is legitimate: nothing was lowered.

## Rules
- [x] `AGENTS.md` and `AGENTS.local.md` conventions are respected: method text is in English, tests are bash and named after the criteria, the commit message is English with no trailer.
- [x] ADR-0025 (accepted: read the diff only, patterns kept inside `po-gate`, exit 2 blocks the review) is followed by both the code and the skill text.

## Tests
- [x] Floor: `bash method/hooks/po-gate.sh floor-guard s48-floor-guard main` → exit 0, nothing lowered. I ran the story's new version of the guard; the copy installed in this review context does not have it yet.
- [x] The assertions pin the five acceptance criteria with exact `path:line: rule` lines, plus negative cases: an untouched base line, a rewrite in place, a rename, a raised threshold, a catch with a body, and an exact count of six flags. None of the six empty test shapes appear. Each fixture is a real git diff in a scratch repo, and the scratch config enables `diff.noprefix`, `diff.renames=false` and `color.diff=always`.
- [x] 5 tests, within the budget of 25.
- [x] Bite: each mutation was run against `bash tests/run.sh floor-guard.test.sh` only, and each was undone and confirmed with `git diff --exit-code method/hooks/po-gate.sh` (clean every time):
  - Assertion comparison `arem > aadd` changed to `arem > aadd + 1` → 1 failing test.
  - Deletion filter `/^D\t/` changed to `/^X\t/` → 1 failing test.
  - Unreadable-diff rule `if (bad || (NR>0 && blocks==0 && headers==0)) exit 3` changed to `if (0) exit 3` → **0 failing tests**.
  - Both awk exit-status checks (`rc -ne 3`, `rc -eq 0` → unverifiable) neutralised → **0 failing tests**.
- [x] No existing test became useless.

## Neighbours
- [x] The only other caller of `po-gate.sh` is `method/hooks/pre-commit:4` (`pre-commit` subcommand), and it is unaffected. The new `floor-guard)` branch only adds a case. `reviewer.md:15`'s phrase "the scope check that comes first, then six steps" is still accurate, because the floor check went inside step 4.

## Findings
- **major** — `method/hooks/po-gate.sh:210, 224-225`. No test covers the "diff in a format the guard cannot read → exit 2" rule, which is the plan's own pivot ("A guard that cannot read the diff must say 2, never 0"). Turning off the `exit 3` condition, or both `rc` checks, leaves all 5 tests green. Exit 2 is tested only for argument and ref errors. If that path regressed, an unparseable diff would come out as a silent 0.
- **major** — `method/hooks/po-gate.sh:182` (deletion check) and `:150/162` (assertion counting gated on `is_test` of the new path). A test file renamed to a path outside the test tree is never flagged. In a scratch repo, `git mv tests/a.test.ts attic/a.ts` gave exit 0 with nothing printed: name-status reports `R100`, not `D`, and the new path is not a test path, so its assertions are not counted. A suffix rename that test runners skip but the path regexes still accept (`src/a.test.ts` → `src/a.test.ts.off`) also comes out clean. To a test runner either rename is the same as deleting the file (the criterion `floor_guard_flags_weakened_tests`), yet the guard reports 0, "nothing lowered". It is contained, because the review's own reading of the diff can still catch the `R` line.
- **minor** — `method/hooks/po-gate.sh:84-87, 93`. Some common skip/focus forms are not in the pattern table: Vitest `it.skipIf(...)` / `test.runIf`, modifier chains such as `describe.concurrent.only`, and Python `@skip(...)` after `from unittest import skip`. All three were confirmed unflagged in a scratch repo. The plan's list was followed as written, and the story asks for an extensible list, so this is minor.
- **minor** — `method/hooks/po-gate.sh:128`. `header_path` removes the surrounding quotes from a quoted path but does not unescape it (`\"`, `\\`, `\t` in file names). A flag on such a path would print a git-escaped name. This is cosmetic, and it is rare because `core.quotePath=false` is pinned.
- **minor** — `docs/stories.md` (s48 `Owns`). `docs/decisions/ADR-0025-garde-de-plancher-lit-le-diff.md` is outside `Owns`, but the ADR rule in `AGENTS.md` (Law 6) requires the file, so this is a gap in the story's `Owns`, not a breach.

## Not verified
- **The guard under macOS/BSD awk and mawk.** Neither is installed here, and the record says the same. A person on macOS should run `bash tests/run.sh floor-guard.test.sh` there, and with `mawk` on Linux (for example by putting a `mawk` symlink named `awk` first on `PATH`).
- **The exit-2 "unreadable format" path in practice.** I could not produce a real git diff the parser rejects (the pinned options and a removed `--- ` line inside a hunk both parsed correctly), so this defensive path was only read, never seen working.
- **User git configs beyond those the tests set** (`diff.noprefix`, `diff.renames=false`, `color.diff=always`; the record also tried `diff.mnemonicPrefix` by hand). Other diff-affecting settings, such as `diff.algorithm`, `diff.relative` or `diff.dirstat`, were not tried. A person should run the guard once in a repository with their real global config.
- **The skill change in a real review.** The reviewer subagent installed for this review still carries the old skill. Only after an install refresh (`polype update`) will a real review run step 4's *Floor* bullet and grade flags the way the new text says.
- **The full suite and lint.** Both come from the verification record (current tree, exit 0). I did not rerun them; I only ran the focused `floor-guard.test.sh` for the mutations. `bin/po-lint` was rerun and is clean.

Relevant files:
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/method/hooks/po-gate.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/tests/floor-guard.test.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/method/skills/review-antihallu/SKILL.md
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/method/templates/review.md
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/docs/plans/s48-floor-guard.md
- /home/lecrabe/dev/atoll/polype/.worktrees/s48-floor-guard/docs/verif/s48-floor-guard.md

The working tree was left clean (`git status --porcelain` empty, every mutation undone and confirmed with `git diff --exit-code`).

Max severity: major
Ship allowed: yes
