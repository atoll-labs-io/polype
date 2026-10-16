# Review — s141-review-findings-shape

[Story](../stories.md) · [Plan](../plans/s141-review-findings-shape.md) · [Verification](../verif/s141-review-findings-shape.md)

Story: s141-review-findings-shape — Une revue se remplit sur un gabarit que /po-ship sait lire
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s141-review-findings-shape
Reviewed tree: 16cd6a4f242b111955c3e73370d7fe4a6f693b3c
Review status: complete
Fix loop: 0
Lenses run: none. The diff touches no auth, route, migration, lockfile or server-side path. `po-gate.sh` is a local shell gate, not a server.

## Scope (`Owns`)
`git diff --name-status main...story/s141-review-findings-shape` touches 11 paths:
- **Inside `Owns`:** the six method files, `tests/review-findings-shape.test.sh`, and ADR-0094.
- **ADR-0094:** it is listed in `Owns`. It is also an added file (status `A`) that the plan names, so it is in scope either way.
- **Pipeline evidence:** `docs/research/…`, `docs/plans/…` and `docs/verif/…` are in scope by construction.
- **Nothing outside `Owns`.**
- **Run interdicts:** all hold. Nothing changed under `.claude/` or `.polype/`, under `docs/reviews/`, in `po-orchestrator.md` or `po-flow.md`, or in any other test file. `ship_allowed`, `paired_value`, `pre_commit` and `floor_guard` are unchanged. The `- title:` and `- body:` lines of `po-ship.md` are identical to before.

## Evidence relied on
- **`po-gate verif-current`:** exit 0, so the record is current. Unit suite `bash tests/run.sh` exited 0 on the code tree. With `Verification mode: record`, I did not rerun the full suite.
- **Checks the project lacks:** no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`), so none was run.
- **QA:** `QA stage: —`, so the story does not go to QA.
- **`po-gate floor-guard … main`:** exit 0, nothing lowered.
- **Story tests:** I ran `bash tests/run.sh review-findings-shape.test.sh` and all 5 passed. That is within `Test budget: 25`.

## Plan against diff
- **Tasks 1 to 7:** all present.
  - The gate follows the plan's ERE, its line order and its message format.
  - The template line is right, and the phrase pinned by an existing test (`a finding never starts with \`Ship allowed:\``) is kept.
  - The reviewer agent has both new sentences.
  - `/po-review` has the narrowed `Bash(...)` line and no bare `Bash`.
  - `/po-drive` has its paragraph, and its new resume row sits above the fix-run row.
  - The `/po-ship` net only had a clause inserted.
  - ADR-0094 is accepted and records option 1.
- **Reuse:** the gate builds on `top()` and `refuse()` and on the verdict ERE `^([-*] )?Ship allowed:` that `ship_allowed` already uses.

## Bite proof
Each mutation was applied to `method/hooks/po-gate.sh`. I then ran only `tests/review-findings-shape.test.sh`, undid the change with `git checkout --`, and confirmed it with `git diff --exit-code`.

| Mutation | Tests failed |
| --- | --- |
| Heading rule off (`bad = 0` for `^#` lines) | 1 (gate_checks_findings_shape) |
| List items never refused | 1 |
| List items refused whenever they name a severity (opening check dropped) | 1 |
| No section end at the next `## ` | 1 |
| Whole file read instead of the last block | 1 |
| Rule for unindented lines outside a list off | 1 |

All six rules are tested. The worktree is clean, and the tree was re-taken just before this answer: it is unchanged.

## Findings
- major — method/commands/po-orchestrator.md:78 and method/commands/po-flow.md:91 (left unchanged), against method/commands/po-review.md:39 — The new stop is a blocked report whose `Next action:` names `po-gate findings-shape`. Only `/po-drive`'s resume table has a row for it. Under `/po-orchestrator` ("Any other blocked review → back to stage 5 as a fix run") or a rerun of `/po-flow` ("Any other `Ship allowed: no` → a fix run"), that report is read as a reason for a fix run. The fix run spends a loop with nothing to fix, and the person is never asked. Criterion `recording_runs_the_check` says the stop "survit à une reprise" and that both commands "en héritent sans changer". That holds only for `/po-drive`. There is a second gap: `/po-orchestrator` Stage 7 records "the way `/po-review` does" rather than "as `/po-review` says", so `po-review.md:39`'s sentence about inheritance may not bind it at all. ADR-0094 names the orchestrator half as something to follow in `Issue tracker`. The run interdicts prevented a fix here, so a later story has to do it.
- major — method/hooks/po-gate.sh:94 (`opens()`) — The gate accepts any list item that opens with a severity followed by *any* character that is not a letter, digit or underscore. For example `- major. a.sh:1 x`, `- major (a.sh:1) x` and `- MAJOR x` all pass. `+ major — x` and `1) major — x` also pass, because the gate does not treat them as list items. Probed in a scratch repo: all exit 0. `/po-ship` step 3.2 opens a finding only on the separators `—`, `:` or `-`, with the markers `- `, `* ` or `1. `. Its net catches only items that hold a severity *without* opening with it. So these lines pass the gate, are not filed, and are not reported to the person: the silent drop of #112 can still happen. The pivot of the plan says the gate must refuse exactly what step 3.2 cannot read. The code follows the criterion's wording, so the fix starts with narrowing that wording. A related cosmetic gap: `- Major — x` passes, but step 3.2's title `sed` matches the severity case-sensitively, so the issue title would read `<id>: major — Major — x`.
- minor — method/commands/po-review.md:39 and method/commands/po-drive.md:138 — Only exit 1 is handled. The gate exits 2 on an unknown subcommand, for example when the `.polype/hooks/po-gate.sh` in a worktree predates this story. The prose says nothing about that exit or any other non-zero one, so the recording context has no rule for it.

## Not verified
- **The narrowed permission in a live harness.** I did not check whether Claude Code accepts `cd <worktree> && .polype/hooks/po-gate.sh findings-shape <id>` under `Bash(.polype/hooks/po-gate.sh findings-shape:*)` without a prompt. The record flags this too. A person should run `/po-review` once on a real story and watch for a permission prompt.
- **The re-ask and blocked-report flows.** In `/po-review` and `/po-drive` these are prose, checked only by phrase tests. No run showed that the malformed block stays byte for byte when Write rewrites the file, or that the second failure produces the blocked report and the stop. A person should force a malformed answer once and inspect `docs/reviews/<id>.md`.
- **Other awk versions.** The gate's awk ran only on this machine's default awk. mawk or BSD awk were not tried, for example with `[[:space:]]` and `tolower`.
- **The full suite.** I did not rerun it. I relied on the `po-run` row in `docs/verif/s141-review-findings-shape.md` with exit 0.

Max severity: major
Ship allowed: yes
