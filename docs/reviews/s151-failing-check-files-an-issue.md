# Review — s151-failing-check-files-an-issue

[Story](../stories.md) · [Plan](../plans/s151-failing-check-files-an-issue.md) · [Verification](../verif/s151-failing-check-files-an-issue.md)

Diff reviewed: `git diff main...story/s151-failing-check-files-an-issue`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 6d853628283bb04e482eeddbc4b73e1806696348

## Ownership
I listed the diff with `git diff --name-only main...story/s151-failing-check-files-an-issue` and checked each path against the `Owns` line of s151 (`docs/stories.md:2402`).
- [x] Every path is inside `Owns`. The six code and document paths are `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `method/AGENTS.md`, `method/skills/testing-doctrine/SKILL.md`, `docs/harnais.md` and the two `tests/failing-check-files-an-issue*.test.sh` files. The rest is the story's own research, plan and verif, which are in scope by construction.
- [x] No path is inside another running story's `Owns`. s152 shares `method/AGENTS.md` and `docs/harnais.md`, but it has no worktree: `git worktree list` shows only main, the merged `worktree-qa-report-and-bounds` and this story.

## Evidence reused
- [x] `po-gate verif-current s151-failing-check-files-an-issue` exits 0, so I reused the record. The unit suite `bash tests/run.sh` exited 0 on tree bd7544f…, which has the same code outside `docs/`. The project has no type check (`Typecheck: —`), so none was run. I read the record's "Not proven here" section and carried its items to `## Not verified`.
- [x] `po-gate qa-current` is not required because `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–6 are all present, and nothing lies outside the plan. The matcher is factored into `SECRET_MATCHER` and loaded by both `secret_scan` and `redact`. `redact)` is added to the dispatcher. `po-intake.sh` covers passthrough, `--sensitive`, scrub, fingerprint, github and taskwarrior. The Law 7 sentence, the `## Installed files` sentence, the doctrine row and `docs/harnais.md` are present. There are 5 own tests.
- [x] I checked each run interdict:
  - `.polype/`, `.claude/`, root `AGENTS.md`, `bin/polype`, `README.md`, `method/commands/`, `method/templates/` and `docs/parite-killer-saas.md` are untouched.
  - Only the two s151 test files changed.
  - `SECRET_PATTERNS` rows are byte-identical.
  - The scan's message is unchanged.
  - `po-intake.sh` holds no secret pattern, no `curl`, `wget`, `gh api` or `eval`. Output text reaches arguments only as `"$(cat file)"`.
  - `gh` and `task` are stubs in every test.
  - No literal PEM header or token appears in the diff.
- [x] The oracle is intact: `po-gate oracle-intact` exits 0, and its cksum `2234325478 11863` matches the plan.

## References
- [x] I opened every reference:
  - `po-ship.md:93-97` for filing and dedup. The `--limit 1000` refusal and the taskwarrior project-name rule match it, and the switch from `_unique description` to `_uuids`/`_get` is what the plan fixed.
  - `tests/run.sh:12,15,24` prints `  FAIL  `, which matches the fingerprint form.
  - The `sed` that reads the setting is the same as in `po-gate.sh`.
  - Install: `method/hooks/` is laid down whole, so `bin/polype` is unchanged as the story note says.
- [ ] Not every value is confirmed: nothing bounds the title length (finding 1).

## Rules
- [x] `AGENTS.md` conventions are respected: English method files, a bash test per story, a French doc under `docs/`.
- [x] No accepted ADR is contradicted. The Law 7 / ADR-0090 sensitive-to-person rule is kept.

## Tests
- [x] Floor: `po-gate floor-guard s151-failing-check-files-an-issue main` → 0, nothing lowered.
- [x] The assertions pin down all seven criteria and none of the six empty shapes applies. The stubs only log calls and replay fixed listings; they reproduce no rule of `po-intake`.
- [x] There are 12 tests, within the budget of 25.
- [x] Bite: I disabled four rules one at a time. For each I ran only `failing-check-files-an-issue.test.sh`, the oracle and, for the shared rule, `gate.test.sh`, then undid it and confirmed with `git diff --exit-code`:
  - The PEM block erasure in `redact` (`inkey = 1` replaced by `inkey = 0`) → 1 failing test (`secrets_are_scrubbed`) → undone, clean.
  - The github dedup title match (`if (0)`) → 1 failing test (`same_failure_not_filed_twice`) → undone, clean.
  - The env-name filter of the env scrub (every variable skipped) → 1 failing test (`secrets_are_scrubbed`) → undone, clean.
  - The shared word-boundary clause of `next_secret` → 2 failing tests (`secrets_are_scrubbed`, `pre_commit_refuses_obvious_keys`) → undone, clean.
- [x] The story makes no test useless.

## Neighbours
- [x] `secret_scan`, the pre-commit path, now calls `hit()` → `next_secret(s, i, 1)`, which is the same loop as the old `hit()`. `gate.test.sh` passes, and it bites on the shared rule. `po-run.sh` and `po-session.sh` are untouched.
- [x] I probed the `set -e` behaviour of the taskwarrior dedup loop (a pending task that does not match) in a throwaway shell: the loop does not abort the script.

## Lenses
Lenses run: none. No path or content in the diff matches a trigger: no auth, route, upload, webhook, migration, lockfile or server code. I still read the secret scrubbing and the outbound filing under step 5.
- [x] There are no lens findings.

## Findings
- major — method/hooks/po-intake.sh:111-139 — The issue title `<label>: <fingerprint>` has no length bound. The fingerprint is the rest of the first failing line, so a pytest summary line can make it arbitrarily long, for example `FAILED path::test - <assertion message>`.
  `/po-ship` cuts its titles at 80 characters for this reason (`po-ship.md:92`). GitHub rejects issue titles longer than 256 characters, so on such a line `gh issue create` fails. The code then takes `not_filed`, and the failure survives only in the scheduler's log, which is the outcome the story exists to prevent.
  The same pytest form also puts the assertion message into the fingerprint. A message that varies from run to run (values, addresses, seeds) then gives a new title each night and defeats `same_failure_not_filed_twice`. This follows the story's wording ("le texte qui suit `FAILED `"), so changing it needs the story's criterion revisited, not only the code.
  Fix: cut the fingerprint (character-safe, as `po-ship` does) and trim it, and consider cutting pytest's ` - …` suffix through the story.
- minor — method/hooks/po-gate.sh:289-293 — `redact` applies the boundary rule to the line it has already rewritten. A match placed right after an earlier `[redacted]` now sees `]` as the character before it, so `redact` can erase a string the pre-commit scan would not flag. This errs only towards over-redaction, never under. It is a small departure from "the same rule as the scan".

## Not verified
- No real tracker was reached, because `gh` and `task` are stubs everywhere. Not checked: a live `gh issue create`, `gh label create` (and the label permissions under `issues: write`), `task add` and `task annotate` with a multi-line body, and GitHub's real title limit and title normalisation, which the exact-title dedup relies on. A person should run `po-intake` once against a scratch GitHub repository and a scratch taskwarrior project with a failing check.
- Two taskwarrior paths have no test: the dedup with a pending task whose title does not match, and the annotate-failure paths. I only probed the loop's `set -e` behaviour.
- I did not run the GitHub Actions workflow, the systemd unit and timer, or the crontab line of `docs/harnais.md` on a scheduler. A person should enable one of them on a test project and watch one scheduled run.
- Interleaving of stdout and stderr in the combined capture is best effort (two `tee -a` on one file). When both streams are busy, the first failing line could be read out of order. I did not check this.
- Formatting has no check in this project.
- Type check, E2E and build: the project has none (`—`).

Max severity: major
Ship allowed: yes
