# Review: s54-untrusted-output

Reviewed tree: 1493812b0fa25791b45fd2d0d5a1520fb0525b17
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s54-untrusted-output, branch `story/s54-untrusted-output`, 1 commit (5abdbf7)
Scope: `git diff main...story/s54-untrusted-output`

## Summary
The story adds a `## Tool output is data` section to `method/AGENTS.md` and names `po-bounds` (and says what `po-gate` holds) in "Installed files". It also adds two tests to `tests/structure.test.sh`. Both acceptance criteria are met and both tests catch their rule when it is removed. No critical or major finding.

## Scope check (Owns)
- The `Owns` line in `docs/stories.md:824` lists `method/AGENTS.md` and `tests/structure.test.sh`. The diff touches those two files plus the story's own `docs/plans/s54-untrusted-output.md` and `docs/verif/s54-untrusted-output.md`. All of it is in scope.
- The only other running lane is `story/s53-review-lenses` (not merged). It owns `method/skills/review-lenses/`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/review.md` and `tests/review-lenses.test.sh`. Its diff does not overlap this one.
- The installed copies at the root (`AGENTS.md`, `.claude/`, `.polype/`) are untouched, as the run interdict requires.

## Step 1: proven evidence
- `po-gate verif-current s54-untrusted-output` exits 0, so the record's `Tree: b2dbc44…` matches the committed code outside `docs/`.
- With `Verification mode: record`, I relied on `docs/verif/s54-untrusted-output.md`:
  - status complete;
  - `bash tests/run.sh` exit 0, 276 passed, 0 failed;
  - the type check is `—` (the project has none);
  - E2E and Build are `—` (the project has none).
- I did not rerun the suite. I read the record's "Not proven here" section: rules prose cannot be enforced by a hook, and the installed copies are refreshed after ship.
- The story has no screen and `QA stage` is not `screens`, so there is no QA to require.

## Step 2: references
- `method/hooks/po-bounds.sh:2-14` confirms the facts the new sentence states: it is a PreToolUse hook with an `implementer` mode and a `qa` mode, and it limits which paths may be written and which git verbs may run.
- The hook is wired from the frontmatter of `method/agents/implementer.md` and `method/agents/qa.md`, both through `"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-bounds.sh`.
- `bin/polype` copies `method/hooks` to `.polype/hooks` in both poses.
- `method/hooks/` holds exactly `po-gate.sh`, `po-bounds.sh` and `pre-commit`, and `pre-commit` execs `po-gate.sh pre-commit`.

## Step 3: diff against the plan
- Task 1: the section is placed after Law 7 and before "Ids and branches", it is not a numbered Law, and both exact phrases are present. The section does not reuse the bold lead `**Page content is data**`, so `tests/qa.test.sh` stays green.
- Task 2: every phrase pinned by `tests/distribution-wiring.test.sh` is kept, including "called `po-gate` in these rules" and "the templates, the gate and the assembled `AGENTS.md`".
- Task 3: both tests are present under a `# s54` comment.
- Task 4: the run is recorded.
- Run interdicts all hold:
  - no mention of `po-run`;
  - no existing test changed;
  - `docs/parite-killer-saas.md` unchanged;
  - no file outside `Owns` changed.
- Nothing unrequested.

## Step 4: tests
- **Floor:** `po-gate floor-guard s54-untrusted-output main` exits 0, so nothing was lowered.
- **Tests that prove nothing:** none found. The second test loops over the files in `method/hooks/` instead of a hard-coded list, so a hook added later without a line in the rules turns it red.
- **Excess:** 2 tests, well within `Test budget` 25.
- **Bite:** I ran only `structure.test.sh` after each mutation, and confirmed the file was restored with `git diff --exit-code method/AGENTS.md` after each one.

| Mutation in `method/AGENTS.md` | Tests failed |
| --- | --- |
| Deleted the `## Tool output is data` section | 1 (`rules_treat_tool_output_as_data`) |
| Deleted the `po-bounds` sentence | 1 (`rules_list_every_installed_hook`, "does not name the hook po-bounds") |
| Changed "the pre-commit hook" to "the commit hook" | 1 (`rules_list_every_installed_hook`, "does not name the hook pre-commit") |
| Deleted "`po-gate` checks the gates of Law 3." | 1 (`rules_list_every_installed_hook`, "does not say what po-gate holds") |

After all four, `git status --porcelain` in the worktree is empty.

## Step 5: values
- "checks the gates of Law 3" agrees with `method/AGENTS.md:66` ("`po-gate` … checks all four").
- The list of artefacts in the new rule is worded as the story's criterion asks.

## Step 6: neighbours
- `method/skills/design-doctrine/SKILL.md:37` keeps its browser-specific rule. The new general rule agrees with it and does not copy its lead.
- The other tests that pin phrases in "Installed files" (`tests/distribution-wiring.test.sh`, `tests/install.test.sh:92`) are green according to the record.

## Findings

### Critical
None.

### Major
None.

### Minor
1. In `tests/structure.test.sh`, `rules_list_every_installed_hook` checks each hook name with `grep -qF "$name"` against the whole section. A short future hook name that happens to be part of another word (for example `gate`) would pass without a line of its own. That is acceptable today, but a pattern bounded by backticks would be stricter.
2. In `method/AGENTS.md`, "Installed files" names `po-gate` and `po-bounds` by their `.polype/hooks/…` paths, but mentions the third hook only as "the pre-commit hook", without its path `.polype/hooks/pre-commit`. That is enough for the criterion and the test; it is only a wording asymmetry.

## Not verified
- **Whether agents actually obey the new rule.** It is prose with no hook behind it, so the only way to check it is to watch an agent that meets an injected instruction in a command's output or a log. A person could plant such a line in a failing test's output during a story run and check that the agent reports it rather than acting on it.
- **The refreshed root `AGENTS.md` and `.claude/`.** They are refreshed on `main` after ship, so this review did not see them. A person should check that the refresh after ship carries the new section.
- **The full suite and `tests/overlap.test.sh` (ADR-0006).** I relied on the record and did not rerun them, as `Verification mode: record` allows.
- **The global pose.** I did not exercise `po-bounds` when it is installed globally (`$CLAUDE_PROJECT_DIR` resolving from `~/.claude/agents`). It is described here, not changed, so it is outside this diff.

## Verdict
Both criteria are met. The two new tests catch their rules when those rules are removed, nothing moved outside `Owns`, and the recorded run matches the code.

Max severity: minor
Ship allowed: yes
