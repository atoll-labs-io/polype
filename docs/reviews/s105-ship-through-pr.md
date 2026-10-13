# Review — s105-ship-through-pr

Reviewed tree: edc4db3a33d1e441893ab0b4265c482157f1d567
Fix loop: 0
Lenses run: none (the diff has no auth, migration, lockfile, manifest or server-side path, and no triggering content)

## Summary
The story replaces the squash ship with a landing commit. `/po-ship` builds it next to `story/<id>` with `git merge-tree --write-tree` and `git commit-tree`, pushes it only to the story branch, and lands it with `gh pr merge --rebase --match-head-commit`. Local mode is now for a repository without a remote only, and uses `--ff-only`. The rules, drive, flow, orchestrator, help, implementer, setup, template and French docs are realigned. The core change is sound: the gate is untouched and is re-run before the automatic merge, and `story/<id>` keeps its reviewed tree. There are no critical findings. Two majors: an automatic-mode resume path that refuses its own merge, and a criterion test that does not bite.

## Scope (Owns)
- `git diff --name-only main...story/s105-ship-through-pr` gives 17 paths.
- Every code and doc path is inside s105's `Owns`.
- `docs/plans|research|verif/s105-*` are the story's own pipeline evidence.
- `docs/decisions/ADR-0081-…md` is added (status `A`) and named by the plan, so it is in scope.
- No ADR that already exists is modified. ADR-0015 was already `superseded` / `superseded-by: [ADR-0080]` on `main`.
- **Overlap with s102:** see finding m1.

## Step 1 — Proven work reused
- `po-gate verif-current s105-ship-through-pr` exits 0. The `Unit suite` (`bash tests/run.sh`) has an exit-0 `po-run` row on code identical outside `docs/`.
- I relied on that record and did not re-run the suite. `Typecheck`, `E2E` and `Build` are `—`: the project has none of them.
- The record's "Not proven here" section says:
  - The tests only check wording.
  - The equivalence between `merge-tree` and `merge --squash` was not re-checked. I checked it myself (see step 5).
- `QA stage: —`, so there is no QA to require.

## Step 2 — References
- `gh pr merge --help` confirms that both `--rebase` and `--match-head-commit SHA` exist.
- In the test file, `frontmatter`, `$ROOT` and `$METHOD` exist in `tests/lib.sh`.
- `git merge-tree --write-tree` exists in git 2.56 (≥ 2.38, as ADR-0081 requires).

## Step 3 — Plan
- Tasks 1–7 are all present, and every run interdict held:
  - `po-gate.sh`, `po-status.md`, `.claude/`, `.polype/`, README, ADR-0015 and ADR-0080 are untouched.
  - No s102 or s106 material, and no new setting.
- The test deleted from `ship.test.sh` is justified in both the plan and the commit message.
- The plan text is internally stale (see m3).

## Step 4 — Tests
- **Floor:** `po-gate floor-guard s105-ship-through-pr main` exits 0.
- **Count:** 5 new tests and 1 removed, against a budget of 25.
- **Bite 1, `no_agent_pushes_target_branch`:** I changed the refspec of `po-ship.md:46` to `<sha>:refs/heads/<Target branch>`. Running `ship-through-pr.test.sh` gave **0 failures**. File restored, `git diff --exit-code` clean. This is finding M2.
- **Bite 2, `ship_gate_unchanged`:** I removed "run `po-gate ship-allowed <id>` once more" from the automatic line. Running `ship-through-pr.test.sh` and `ship.test.sh` gave **1 failure** (`ship_gate_unchanged`). File restored, `git diff --exit-code` clean.

## Step 5 — Values
I checked these in a throwaway repo, `/tmp/tmp.4NMpozQJ8F` (base, two story commits, a moved target):
- `merge-tree --write-tree` gives the same tree as `git merge --squash` (`425b679…`).
- `commit-tree` with the same tree and parent but another committer date gives another SHA (`1965558…` against `b0e8f90…`). This is what M1 rests on.

## Step 6 — Neighbours
- `po-drive.md:31,63` and `po-status.md:31` detect a shipped story by an `<id>:` subject. GitHub's rebase merge keeps that subject.
- `po-gate.sh:17` still talks about squash (m4).
- `README.md:33` still says "un squash" (m5).

## Findings

**M1 — major — `method/commands/po-ship.md:46,49`: an automatic ship that resumes refuses its own merge.**
- When `origin/story/<id>` already holds a commit with parent `<base>` and tree `<tree>`, the push is skipped. Nothing then says that `<sha>` becomes that remote head.
- `commit-tree` stamps the current time, so a rerun's freshly built `<sha>` differs from the head already pushed (shown in step 5).
- `gh pr merge <url> --rebase --match-head-commit <sha>` is therefore refused.
- Under "One failure and the ship stops", the story then goes back to a fix run, spending a `Max attempts` unit for nothing.
- It fails safely, with no silent damage.
- **Fix:** when the push is skipped, take `<sha>` from `origin/story/<id>`, or build the commit with fixed author and committer dates.

**M2 — major — `tests/ship-through-pr.test.sh` `test_no_agent_pushes_target_branch` does not bite.**
- The check works line by line ("every line holding `git push` also holds `story/<id>`").
- The push line of `po-ship.md` mentions `story/<id>` several times outside the refspec, so pushing to `Target branch` on that same line passes (bite 1: 0 failures).
- The test only catches a push added on a line of its own.
- **Fix:** assert on the refspec itself, for example the exact phrase `<sha>:refs/heads/story/<id>`, or check that no `git push` mentions `<Target branch>`.

**m1 — minor — an `Owns` overlap with the lane `s102-ship-follows-the-forge`.** I chose not to apply critical here; please read the reasoning and overrule it if you disagree.
- The facts:
  - s102's worktree exists at `.worktrees/s102-ship-follows-the-forge` and `story/s102-ship-follows-the-forge` is not an ancestor of `main` (exit 1).
  - Its `Owns` covers `method/AGENTS.md`, `po-setup.md`, `po-ship.md`, `po-drive.md`, `po-orchestrator.md`, `po-flow.md` and `templates/agents-local.md`, all of which this diff changes.
  - Read literally, the critical rule of `review-antihallu` matches.
- Why I did not grade it critical:
  - The rule's premise is "two lanes are writing the same file", and that is false here. `diff -rq` of s102's `method/` and `tests/` against `main` shows no s102 edit; the only differences are files `main` changed after s102 branched.
  - `docs/stories.md` declares s102 **Dépend de: s105**, so s102 is the lane that waits, as Law 1's "the second waits for the first to ship" requires.
  - A fix run of s105 could not resolve this.
- What remains:
  - The s102 worktree holds an uncommitted research, plan and ADR-0079.
  - `po-bounds` reports its branch started at `16009a9`, a commit where s102 is not yet in `docs/stories.md` (a stale or orphan base).
  - **Action for a person:** recreate or rebase that lane from `main` after s105 ships. Do not let it run on its current base.

**m2 — minor — the ADR-0081 frontmatter link is one-sided.**
- ADR-0081 declares `supersedes: [ADR-0080]` while its body says it supersedes ADR-0080 only in part.
- ADR-0080 keeps `superseded-by: []` (the plan forbade touching it).
- The body still reads "Recommandée" and "une fois la recommandation acceptée" while `status: accepted`.

**m3 — minor — the plan is stale against its own state.**
- `docs/plans/s105-ship-through-pr.md` still says "Until they do, the plan stays at `validated: no`", yet its frontmatter is `validated: yes`.
- Its run interdict says "ADR-0081 stays `status: proposed`", yet the ADR is `accepted` and states that the owner decided on 2026-10-13. I could not verify that acceptance (see Not verified).

**m4 — minor — the comment at `method/hooks/po-gate.sh:17` is stale.**
- It still says "Squash merges…" and advises running `ship-allowed` in CI "on a checkout of the story branch tip".
- The remote story tip is now the landing commit. Once the base has moved, its tree includes other stories' code, so a CI following that advice would fail the gate.
- The plan's interdict kept this file's diff empty. Fix it in a later story.

**m5 — minor — `README.md:33` still reads "un squash sur la branche cible".**
- That path is outside s105's `Owns`, so it needs its own change.

**m6 — minor — existing setups will stop at ship after the next install.**
- This repository has `Merge mode: local` with `origin` set to `git@github.com:atoll-io/polype.git`, so the new remote check will stop `/po-ship` here after the next install.
- Other projects with the same setup will stop the same way. The stop message is clear, but neither `docs/migration.md` nor `/po-setup` tells an existing project to switch to `pr`.
- Changing `AGENTS.local.md` is outside this story (s106 territory).

## Not verified
- **Real pushes.** `git push --force-with-lease=story/<id> origin <sha>:refs/heads/story/<id>`, both on a first push (no tracking ref) and on a re-push, was never run: `po-bounds` refuses `git push` to the reviewer everywhere, including the temp dir. A person should run one real pr-mode ship on a scratch GitHub repository.
- **GitHub merge flags.** That `gh pr merge --rebase --match-head-commit` really refuses a mismatched head, and that a rebase merge keeps the `<id>: <title>` subject, was checked only against `--help`. No PR was merged.
- **Forgejo and GitLab.** Their fast-forward styles are not wired in `/po-ship` and were not checked (ADR-0081 defers them).
- **Owner decisions.** That the owner really accepted ADR-0081 and validated the plan rests only on the ADR's own sentence. A person should confirm it.
- **The full unit suite** was not re-run. I relied on the record (exit 0, gate current). Running `tests/overlap.test.sh` (the Killer SaaS overlap check) is therefore covered by that record and nothing else.
- **QA.** None, since `QA stage: —`. There is no screen or scene.

Max severity: major
Ship allowed: yes
