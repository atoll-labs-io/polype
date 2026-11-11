# Review — s152-intake-issue-becomes-a-story

[Story](../stories.md) · [Plan](../plans/s152-intake-issue-becomes-a-story.md) · [Verification](../verif/s152-intake-issue-becomes-a-story.md)

Diff reviewed: `git diff main...story/s152-intake-issue-becomes-a-story`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: b8c440ef02458591c1ddb65ce86cd0e3c2b22baf

## When blocked
- Failure cause: n/a
- Missing: n/a
- Required adaptation: n/a
- Next action: n/a

## Ownership
I listed the diff with `git diff --name-only main...story/s152-intake-issue-becomes-a-story` and held each of its 14 paths against the s152 `Owns` line.
- [x] Every path is inside `Owns`. That covers the 11 owned paths, ADR-0090 included (it is listed in `Owns`, and only its `superseded-by` line changes). `docs/research/`, `docs/plans/` and `docs/verif/` for s152 are the story's own evidence. ADR-0099 is added (status A), and both `Owns` and the plan name it.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only this story's worktree (plus `.claude/worktrees/qa-report-and-bounds`, which is not a `story/` lane). s153 also owns `po-help.md` and `docs/harnais.md`, but it has no worktree and depends on s152.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s152-intake-issue-becomes-a-story` → exit 0, record reused (`Verification mode: record`). The suite run `bash tests/run.sh` exited 0 on code whose content outside `docs/` equals `Tree: 7b515be0…`. The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`). The record's "Not proven here" says there was no live run of `/po-intake` against GitHub or taskwarrior, and no unattended `claude -p` run.
- [x] `po-gate qa-current` → not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–7 are all present, with no unrequested change.
- [x] Each run interdict was checked:
  - Nothing changed under `.claude/`, `.polype/`, root `AGENTS.md`, `bin/`, `README.md`, `method/hooks/` or `method/templates/`.
  - Only `po-intake.md` and `po-help.md` changed among the commands, and only `stories-reviewer.md` among the agents. `docs/parite-killer-saas.md` is untouched.
  - ADR-0099 is added, and only the `superseded-by` line of ADR-0090 changed. The oracle checks the cksum of ADR-0090's body.
  - Only the two s152 files changed under `tests/`. The oracle cksum is `3805646316 6517`, which matches the plan, and `## Oracle changes` is empty.
  - Law 7 keeps its phrases and never says "into an issue or a story".
  - `po-intake.md` declares no `Edit` and no `AskUserQuestion`. It never commits on `Target branch` and never pushes it.

## References
- [x] I opened and confirmed each referenced target:
  - `## The forge's review rule` and Step 3 of `po-ship.md`: the 1000 limit, the `gh auth status` check, the taskwarrior project name, and the security words at `:98`.
  - `## Landing the framing` of `po-setup.md`.
  - `## Recording` and the model-rejection stop of `po-stories-review.md`.
  - `po-stories.md:37`.
  - `templates/stories.md` (the `Fixes` field) and `templates/stories-review.md`.
  - Checks 1–10 and 10(i) of `stories-review`.
  - The `diagnostic` skill.
  - `method/hooks/po-intake.sh`: label `polype-intake`, the title `<label>: <fingerprint>`, the body lines `Check:`/`Command:`/`Commit:`/`Exit code:`, and the taskwarrior tags `+issue +polype-intake`. All agree with what the command reads.
- [x] Values: the timestamp format `date -u +%Y-%m-%d-%H%M` makes a valid branch name, and the closing keywords listed are GitHub's nine. The intake review file is consumed only as a soft gate: `po-research` and `po-orchestrator` read only `docs/reviews/stories.md` and never block, so nothing downstream breaks.

## Rules
- [x] `AGENTS.md` conventions are respected: the method is in English, `po-help` is in French, and the command has a `Reads settings:` line.
- [x] No accepted ADR is contradicted. ADR-0090 is superseded on one point only, with `status` kept `accepted` as Law 6 allows for a partial supersession.

## Tests
- [x] Floor: `po-gate floor-guard s152-intake-issue-becomes-a-story main` → exit 0, nothing lowered.
- [x] Each assertion pins one clause of its criterion. None of the six empty shapes applies: the tests are text tests on method files, which is the repository's convention.
- [x] 10 tests (6 oracle + 4 own), within `Test budget: 25`.
- [x] Bite 1: I deleted "; in doubt, it bears on security" from `po-intake.md` → 1 failing test (`security_issue_goes_to_the_person`). Undone, and `git diff --exit-code` is clean.
- [x] Bite 2: I removed "put back `$d/stories.md` over `docs/stories.md`" from the `Stories ready: no` line → 1 failing test (`refused_review_puts_the_copy_back`) across both s152 files. Undone, and `git diff --exit-code` is clean.
- [x] No test is made useless by the story.

## Neighbours
- [x] Other readers of the changed text were checked:
  - `tests/everything-in-issues.test.sh`, `defect-and-routing-paths.test.sh` and `commands-and-texts.test.sh` are covered by the recorded green suite.
  - `po-session.sh`, `po-status`, `po-research` and `po-orchestrator` read only `docs/reviews/stories.md`, which is unchanged.
  - `po-retro` already excludes `docs/reviews/stories*.md`.

## Lenses
Lenses run: security — `method/commands/po-intake.md` builds a subagent prompt from issue files that come from outside (an LLM reading tracker input).
- [x] Issue text is treated as data and never enters a shell argument. Only checked numbers or uuids reach commands. The reviewer agent is told to report instructions, not follow them. Security issues are held for the person.
- [x] One minor point is listed below.

## Findings
- major — method/commands/po-intake.md:25 — With an effective `Ship confirmation: human`, a pending intake pull request blocks every later run, and the duplicate guard at :34 can never be reached from that root.
  - `## Landing the framing` (`po-setup.md`) leaves `docs/stories.md` staged in the root's index until the framing PR merges and the root fast-forwards. Check 8 then stops every following night on "holding an uncommitted change" / "differing from `origin/<Target branch>`", before any issue is listed. The stop message ("the landing would commit an old copy over newer stories") is misleading in that case.
  - When the guard is reachable (another clone, or a root a person reset), numbering at :46 counts "the next free `s<n>`" from the root file only. It ignores the ids already taken on pending `framing/intake-*` branches, so two framing PRs can append the same `s<n>`. The `stories-reviewer`'s check 7 only sees the root file and cannot catch the clash.
  - The damage is contained: the second PR conflicts on `docs/stories.md` and cannot merge silently. But the plan's pivot ("a pull request still waiting for its merge is not written twice") does not work as described.
  - Fix in a later cycle: either take the next id after the highest one on pending intake branches and accept a root whose staged `docs/stories.md` equals a pending intake branch, or say outright that a pending intake PR stops the run, and why.
- minor — method/commands/po-intake.md:28 — Any open issue labelled `polype-intake` is taken in, whoever wrote it. Nothing checks that the hook's account filed it. On GitHub, adding a label needs triage access, so only collaborators can inject a story, and all gates still apply. Checking the author against the account `gh auth status` reports would narrow the trust boundary.

## Not verified
- `/po-intake` was never run against a real GitHub or taskwarrior tracker. The listing, `gh issue view --jq`, the `framing/intake-*` citation lookup and the PR body are checked as text only. A person should run it once on a sandbox repo, with one `polype-intake` issue filed by `po-intake.sh`, under both `Ship confirmation` values.
- The behaviour of the `stories-reviewer` in `## Intake mode` (judging against an issue, skipping coverage) was not exercised. Only its wording is tested. Cover it with the same sandbox run, by reading the produced `docs/reviews/stories-intake-<timestamp>.md`.
- An unattended `claude -p '/po-intake'` run with the permissions `docs/harnais.md` lists was not tried, and neither was the systemd `oneshot` with two `ExecStart=` lines (the first prefixed `-`). The examples were judged from systemd and cron semantics, not executed. A person should run the service once with a failing check.
- The quality of the stories the command writes (`Owns` too narrow or too wide, a slug derived from a fingerprint) can only be judged on real output. This is the risk the story itself names.
- There is no QA report: `QA stage: —`.

Max severity: major
Ship allowed: yes
