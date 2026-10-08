# Review — s56-evidence-runner

Reviewed tree: ddd54e0d936371db72a4d7e0666e54137068d1d3
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s56-evidence-runner (branch `story/s56-evidence-runner`, commit 1a9fb81)
Scope: `git diff main...story/s56-evidence-runner`, 14 files
Lenses run: none. No changed path or content matches the Security, Migration, Dependencies or Performance triggers: the diff is bash hooks, method prose, tests and the evals builder, with no lockfile, no manifest, no SQL and no server code.

## Scope check (`Owns`)
- Every code path is inside the story's `Owns`: `method/hooks/po-run.sh`, `method/hooks/po-gate.sh`, `method/templates/verification-record.md`, `method/agents/implementer.md`, `method/skills/testing-doctrine/`, `method/AGENTS.md`, `evals/` (for `evals/lib.sh`), `tests/run-ledger.test.sh`, `tests/gate.test.sh` and `tests/execute.test.sh`. The research, plan and verif files are the story's own evidence.
- `docs/decisions/ADR-0035-le-releve-tient-un-registre-ecrit-par-po-run.md` is not in `Owns`. AGENTS.md Law 6 requires it ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so this is a gap in `Owns`, not a breach. Finding m1.
- `git worktree list` shows only `main` and this story, so no other running story shares a path.
- The run interdicts hold: the diff is empty on `.claude/`, `.polype/`, `bin/`, `tests/evals.test.sh`, `tests/structure.test.sh`, `tests/lib.sh`, `docs/stories.md`, `method/commands/` and `method/skills/review-antihallu/`.

## Checks
- [x] `po-gate verif-current s56-evidence-runner` passes with the installed (old) gate. It also passes with the new `method/hooks/po-gate.sh`, which reads the new `## Runs` table.
- [x] Reused the record (`Verification mode: record`):
  - It says `Verification status: complete`, and its `Tree:` 132b7c2… equals HEAD outside `docs/`.
  - Its only declared check, `bash tests/run.sh`, has a run row with exit 0 on tree eab2800…. `git cat-file` shows that tree exists, and it equals HEAD outside `docs/`.
  - The run time (08:35:08Z) comes before the commit time (08:35:26Z), so the row is plausible.
  - The project has no type check (`Typecheck: —`), no E2E and no build, and I did not substitute any of my own.
  - I read the record's "Not proven here" section.
- [x] `po-gate floor-guard s56-evidence-runner main`: exit 0, nothing lowered.
- [x] A baseline run of `tests/run-ledger.test.sh` passes 6 of 6.
- [x] Bite tests. Each mutation was undone, and `git diff --exit-code` on the file confirmed it was back to its committed state:
  1. `po-gate.sh` without the run-tree filter (`tree_exists … && git diff --quiet "$run_tree" "$tree" …` replaced by `true`): run-ledger + gate + evals → 1 failure (`verif_current_requires_a_passing_run_per_check`).
  2. `po-gate.sh` without the last-exit check (`[ "$last" = 0 ]` replaced by `true`): run-ledger + gate → 1 failure (same test).
  3. `po-gate.sh` without command equality (`[ "$command_r" = "$command" ]` replaced by `true`): run-ledger → 1 failure (same test).
  4. `po-run.sh` without the branch check (line 38 replaced by `true`): run-ledger → 1 failure (`po_run_refuses_outside_a_story_worktree`).
- [x] Test budget: 6 new tests and 2 adjusted ones, within the budget of 25. None of the six "prove nothing" patterns found: the tests drive the real `po-run` and `po-gate` on throwaway repos, and the evals test builds a real case.
- [x] References: `tree_exists`, `top`, `refuse` and `code_matches` exist in `po-gate.sh`. `bin/polype` installs the whole `method/hooks/` directory as executable, so `.polype/hooks/po-run.sh` will exist after install. `po-bounds.sh implementer` does not block a `.polype/hooks/po-run.sh …` command.
- [x] Plan: tasks 1–9 are all present in the diff, and I found no unrequested change. The diff matches ADR-0035 and research answers Q1–Q5.

## Findings

**M1 — major — `verif-current` passes when a `## Checks` row has the wrong number of cells** (`method/hooks/po-gate.sh`, `record_rows`)
- A `## Checks` row only counts when it has 3 or more cells (`section == "## Checks" && n >= 3`). A shorter row is dropped without any message, so the check it declares never needs a run.
- Reproduced on a scratch repo: a record with `| Check | Command |` and `| Unit suite | \`bash tests/run.sh\` |`, an empty `## Runs`, status complete and a matching `Tree:` gets `po-gate verif-current` exit 0. The declared suite never ran.
- The same goes for a row whose label starts with `-` or `:-`: it matches the separator regex and is dropped.
- The template has 3 columns, so this needs a malformed record. But the story's purpose is that a check that never ran cannot pass, and here it does without any warning. A refusal on an unparseable `## Checks` row would close it.

**m1 — minor — the ADR is outside `Owns`**
- `docs/decisions/ADR-0035-…md` is required by AGENTS.md Law 6 ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`") but is not on the story's `Owns` line. This is a gap in the story's scope, not an implementer breach.

**m2 — minor — out-of-date sentence in a neighbouring file**
- `method/skills/review-antihallu/SKILL.md:24` still says that without the hook, `git diff --quiet <Tree> HEAD …` "does the same comparison". That is no longer true: the gate now also checks run rows.
- The file is outside `Owns` and on the plan's no-change list, and the research flagged it. It needs a later change.

**m3 — minor — the implementer text is ambiguous on a fix run** (`method/agents/implementer.md`, "After the last task")
- Step 1 says "Write `docs/verif/<id>.md` from `templates/verification-record.md`" and then "never rewrite the file, never touch a row under `## Runs`".
- On a fix run the record already exists, so the text does not say whether to keep the earlier rows or start from the template.
- The gate is not affected, because earlier rows are on earlier code. The run history is, if the implementer rewrites the file.

**m4 — minor — passing the command in double quotes can change it**
- The implementer text, `.polype/hooks/po-run.sh … -- "<Test>"`, and the gate's refusal hint, `-- "$command"`, both put the command inside double quotes.
- A `Test` setting that contains `"`, `$` or a backtick is then expanded by the caller's shell. The recorded command no longer equals the declared one, so the gate refuses.
- This fails closed, so it costs a confusing loop, not a wrong pass. Single quotes, or a note about it, would avoid it.

## Not verified
- **Agents using it for real.** No real implementer subagent ran with the new `implementer.md`, `po-bounds` and `po-run` inside Claude Code: the installed `.claude/` and `.polype/` are still the old method. A person should run one small story after the next `polype-dev-install` and check that the record's `## Runs` rows come from `po-run`, with the Checks table intact.
- **In-flight lanes at update time.** Records in the old format, with no `## Checks`, will now fail `verif-current`, and `/po-drive` will send those lanes back to the code stage. The research says this is intended, but I did not exercise it. Say it in the ship message, and check `/po-drive status` after updating.
- **Other platforms.** I did not run anything on macOS/BSD (BSD awk, `cp`, `mktemp -d`), nor on a repository with a split index, where copying only the `index` file may not give a valid temporary index. A person with a Mac, or a repository with `core.splitIndex=true`, should run `tests/run-ledger.test.sh`.
- **Command vs setting.** The gate does not check that a declared command equals the `Test`/`Typecheck` setting, and a hand-written row in `## Runs` cannot be detected (ADR-0035, Bad). In this story's own record I checked that the declared command matches `Test:` and that the run row's tree and time are plausible. Other stories need the reviewer to do the same by eye.
- **Type check, E2E, build.** The project has none (`Typecheck: —`, `E2E: —`, `Build: —`).

## Verdict
No critical finding. M1 is a real hole in the gate's parse, contained to records that do not follow the template; it is logged for a later cycle along with the four minors. After the review the worktree is clean and the tree is unchanged (ddd54e0d936371db72a4d7e0666e54137068d1d3).

Max severity: major
Ship allowed: yes
