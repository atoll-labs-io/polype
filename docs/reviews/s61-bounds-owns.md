# Review — s61-bounds-owns

[Story](../stories.md) · [Plan](../plans/s61-bounds-owns.md) · [Verification](../verif/s61-bounds-owns.md)

Diff reviewed: `git diff main...story/s61-bounds-owns`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 5d230b1eceb89ec0ca431538bce11382c07b88a9

The tree was taken again just before this answer and was still `5d230b1e…`. The worktree was clean.

## Ownership
I listed the changed files with `git diff --name-only main...story/s61-bounds-owns`. There are 9 paths.
- [x] All five code and test paths are inside `Owns`:
  - `method/hooks/po-bounds.sh`
  - `tests/bounds.test.sh`
  - `method/templates/stories.md`
  - `method/skills/agentic-stories/SKILL.md`
  - `tests/stories.test.sh`
- [x] The story's own evidence (research, plan, verif) is in scope by construction.
- [x] `docs/decisions/ADR-0038-po-bounds-lit-les-owns-au-point-de-depart-de-la-story.md` is outside `Owns`. A written rule requires it: Law 6 says "Structural decisions are ADRs", and the story's own notes ask for "une ADR qui la remplace". This is a gap in `Owns`, not a breach by the implementer. Graded minor below.
- [x] No overlap with another running story. Only `story/s60-gate-parsing` has a worktree, and its `Owns` (`po-gate.sh`, `floor-guard`, `gate`, `run-ledger`, `qa-gate` tests) shares nothing with this diff.

## Evidence reused
- [x] `po-gate verif-current s61-bounds-owns` exits 0. `git diff --quiet 83ae5cd… HEAD -- . ':(exclude)docs'` is clean.
  - The record says complete, and the unit suite (`bash tests/run.sh`) exited 0. I relied on it (`Verification mode: record`) and did not rerun the full suite.
  - The project has no type check, end-to-end or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
  - I read the record's "Not proven here" section.
- [x] `po-gate qa-current` is not required: no screen, `QA stage: —`.

## Plan
- [x] Tasks 1–6 are all present and nothing was done outside the plan.
  - The plan's `<b>@{upstream}` became `for-each-ref --format='%(upstream)'`. It does the same thing, and a code comment explains why.
- [x] Run interdicts, checked one by one:
  - `check_bash`, `check_write_qa`, `join_dir`, `QA_GIT_VERBS`, `resolve_path`, `story_of_dir` and the dispatch are untouched; no diff hunk falls in them.
  - None of the listed forbidden paths appear in the diff.
  - No existing assertion in `bounds.test.sh` or `stories.test.sh` changed. `lane()` is unchanged.
  - The script still exits only 0 or 2 and never reads `AGENTS.local.md`.
  - No new tool: only builtins, `git`, `awk` and `jq`.
  - Tests use scratch repositories only.

## References
- [x] Everything the diff calls exists and is used as the code expects:
  - Functions: `deny`, `story_of_dir`, `TOP`, `STORY`, `OWNS_LINE`.
  - Test helpers: `write_status`, `bounds_stderr`, `hook_input`, `expect`, `section_of`, `$SKILL`, `$METHOD`.
  - Git commands: `worktree list --porcelain` (main worktree first), `merge-base` with several refs, `show <rev>:path`.
- [x] Checked by hand against this real lane with the new script:
  - `method/hooks/po-bounds.sh` and `method/skills/agentic-stories/x.md` are allowed (0). `docs/x.md` is allowed (0).
  - `bin/polype` is refused (2) with "read at 9dbe221 (where story/s61-bounds-owns started from main)". That is the true fork point, even though `main` has since moved to `3fc8ccc`.
- [x] I ran the new parser over all 68 `Owns` lines in Polype's `docs/stories.md`. It refuses only line 129, a shipped M1 story with prose, as the research predicted. No ready story (s60–s68) is refused.

## Rules
- [x] `AGENTS.md` conventions are respected: method text is in English, tests are bash, and each test is named after its criterion.
- [x] ADR-0024's "read at `HEAD`" point is replaced by ADR-0038, as the story requires. One minor problem with the ADR's frontmatter is listed under Findings.

## Tests
- [x] Floor: `po-gate floor-guard s61-bounds-owns main` exits 0, so nothing was lowered.
- [x] The assertions pin the four criteria, and none of the six empty test shapes appear:
  - The tests run against real git repositories, not mocks.
  - The upstream case uses a real bare origin with a lagging local `main`.
  - The glob case includes near-misses (`cfg/runXsh`, `crates/a/b/Cargo.toml`).
- [x] 4 tests, within `Test budget` 25.
- [x] Bite. I made each change below, ran only `tests/bounds.test.sh`, then restored the file and checked it with `git diff --exit-code`; it was clean every time.

| Change to `po-bounds.sh` | Failing test(s) |
| --- | --- |
| Read `Owns` at `HEAD:docs/stories.md` instead of `$BASE` | 1 (`owns_are_read_where_the_story_started`) |
| Drop the upstream ref | 1 (same test) |
| Leave `.` unescaped in the glob regex | 1 (`owns_accept_globs`) |
| `*` becomes `.*` (crosses `/`) | 1 (`owns_accept_globs`) |
| Skip the `check_entry` validation loop | 1 (`bounds_refuse_an_entry_they_cannot_read`) |
| Parser silently drops text where an entry should start | 1 (same test) |
| Parser silently drops trailing prose | 1 (same test) |

- [x] No existing test was made useless by this story.

## Neighbours
- [x] Read the other readers of `Owns`:
  - `method/commands/po-drive.md:31-36` (lanes must have disjoint `Owns` paths)
  - `method/skills/stories-review/SKILL.md:25` (overlap check, "directories included")
  - `method/templates/review.md`, `method/skills/review-antihallu/SKILL.md` (ownership check)
  - `docs/installation.md:84` ("l'`Owns` committé" is still true)
- [x] None of these know the new glob syntax. See the major finding below.

## Lenses
Lenses run: security — `method/hooks/po-bounds.sh` is the permission hook that decides what the implementer may write (a check on who may change a file).
- [x] The `Owns` line can no longer widen itself through a story commit: confirmed by the bite on fork-point reading.
- [x] Every error path fails closed:
  - detached or bare root
  - no merge base
  - story absent at the fork point
  - unreadable entry
- [x] The glob-to-regex conversion escapes every regex metacharacter that is not refused earlier. `?`, `[`, `]`, `{`, `}` and whitespace are refused at validation.
- [x] Residual: see the minor finding on `git branch -f main`.

## Findings
- **major** — `method/commands/po-drive.md:36`, `method/skills/stories-review/SKILL.md:25`, `method/templates/review.md` (ownership section) — the story makes `*`/`**` globs valid `Owns` entries and the stories template now invites them. But the checks that keep two lanes off the same paths still compare paths literally ("a directory owned by one story covers every path beneath it").
  - Example: `crates/*/Cargo.toml` against `crates/core/` gets no defined overlap rule, so two overlapping lanes could be judged disjoint and launched together.
  - The damage is contained (ships are serial and a collision shows as a merge conflict), and ADR-0038 and the verif record name the gap. It still needs a story that owns those files.
- **minor** — `docs/decisions/ADR-0038-po-bounds-lit-les-owns-au-point-de-depart-de-la-story.md` — this path is outside `Owns`, but Law 6 requires it ("Structural decisions are ADRs in `<ADR directory>`…") and so do the story's own notes. It is a gap in the story's `Owns`, not an implementer breach; the code is fine as is.
- **minor** — `docs/decisions/ADR-0038-…md:7` — the frontmatter says `supersedes: []`, while the body says "Ce point d'ADR-0024 est remplacé ici". The replacement is partial, but a reader following frontmatter links never finds ADR-0038 from ADR-0024. Consider stating the partial supersession in the frontmatter.
- **minor** (security lens) — `method/hooks/po-bounds.sh` (`story_base`) — the fork point is `merge-base HEAD main [upstream]`. `check_bash` lets through `git branch -f main HEAD` and `git update-ref refs/heads/main HEAD` (both checked: exit 0).
  - An implementer that ran one of these after a widening commit would move the base onto its own commit and widen its bounds again.
  - ADR-0038's "Neutral" consequence accepts this: the threat model is error, not hostility. Check_bash is s62's territory.

## Not verified
- **The installed hook in a real implementer session.** `.polype/hooks/po-bounds.sh` on `main` is still the old script. I did not drive a Claude Code session with the refreshed hook, only ran `method/hooks/po-bounds.sh` by hand against this lane. After ship and install, a person should launch one implementer and check that a write outside `Owns` is refused with the fork-point message.
- **Bash 3.2 compatibility.** The plan claims it, but I only ran bash 5 here. Someone on macOS's `/bin/bash` should run `bash tests/run.sh bounds.test.sh`.
- **Lanes forked from a remote that is not `main`'s upstream.** By design these are refused, not widened. There is no test for that refusal, and I did not run one.
- **The full suite.** I did not rerun it; I relied on the current record. I ran only `tests/bounds.test.sh`, for the baseline and the bite checks.
- **Hook latency.** Each `Write` now runs `worktree list`, `for-each-ref`, `merge-base` and `show`. I did not measure it.

Max severity: major
Ship allowed: yes
