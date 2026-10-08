# Review — s81-scenario-driver

Diff reviewed: `git diff main...story/s81-scenario-driver`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 73b80ddd04913cc7c3e742a877b1864f5d678499

## Ownership
I listed the diff with `git diff --name-status main...story/s81-scenario-driver` (commit 65d560d).
- [x] Every path is inside `Owns`. `method/skills/qa-drivers/scenarios.md` and `tests/scenario-driver.test.sh` are the story's `Owns`. `docs/research|plans|verif/s81-scenario-driver.md` are pipeline evidence. `docs/decisions/ADR-0059-le-pilote-scenarios-joue-sur-une-copie-dans-le-repertoire-temporaire.md` has status `A` and the plan names it, so it is in scope by construction.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other live lane is `s80-surface-routing`, and its Owns and diff don't touch these paths. It uses ADR-0058, so there is no number clash.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s81-scenario-driver` exited 0, so I reused the record (`Verification mode: record`): Unit suite `bash tests/run.sh` exited 0. The project has no type check (`Typecheck: —`), no E2E and no build. Its "Not proven here" section says no real `/po-qa` run was made against a `command` or `endpoint` story. I also ran a focused `bash tests/run.sh scenario-driver.test.sh qa-drivers.test.sh overlap.test.sh`: 10 passed.
- [x] `po-gate qa-current` is not required: no screen (`Surface: —`).

## Plan
- [x] Tasks 1–3 are all present. The driver has the five sections and every phrase the plan fixes. Nothing falls outside the plan.
- [x] Run interdicts, one by one:
  - The diff is empty on `SKILL.md`, `browser.md`, `agents/qa.md`, `commands/po-qa.md`, `templates/qa.md`, `templates/agents-local.md`, `hooks/po-bounds.sh`, `bin/po-lint` and `tests/qa-drivers.test.sh`.
  - Nothing changes under `.claude/` or `.polype/`.
  - No ADR other than 0059 is touched.
  - No `design-doctrine` bold lead is repeated.
  - `docs/parite-killer-saas.md` is untouched.
  - `po-bounds` is not widened.

## References
- [x] Every reference was opened and confirmed:
  - `po-bounds.sh:310` `QA_GIT_VERBS` allows `status` and `ls-files`, and `check_git_read` passes `-C` and `--ignored`/`--others`.
  - `check_write_qa` (`po-bounds.sh:271-278`) refuses Write outside `docs/qa/<id>/`.
  - `qa-drivers/SKILL.md:14-15` routes to `scenarios.md`, and its five-item list (`:26-31`) is the section list the driver follows.
  - `## Not seen` exists in `templates/qa.md`.
  - `Install` and `Build` exist in `templates/agents-local.md:75,79`.
  - The `.env*` copy command matches `po-research.md:32`.
  - `po-lint:290` accepts `scenarios` once the file exists.
- [x] Values checked: `127.0.0.1`, the `setsid` process group and `status --porcelain --ignored` are all sound. Two gaps are under Findings: the missing `docs/qa/<id>/` exception and the missing "never answers" branch.

## Rules
- [ ] `AGENTS.md` conventions are respected except one gap: `qa.md` does not declare `Install` and `Build` (minor, below).
- [x] No accepted ADR is contradicted. ADR-0059 is followed, and ADR-0052 and ADR-0057 are respected.

## Tests
- [x] Floor: `po-gate floor-guard s81-scenario-driver main` exited 0, so nothing was lowered.
- [x] The assertions pin each criterion by phrase, and none of the six empty test shapes appears. Phrase checks are the only layer this repo has for method text.
- [x] 4 tests, within `Test budget` 25.
- [x] Bite proofs. After each one I ran `git checkout -- method/skills/qa-drivers/scenarios.md` and `git diff --exit-code` came back clean.
  - Removing "on which nothing answers before the start": 1 test fails (`scenarios_start_the_service_itself`).
  - Removing the sentence "After the walk, run it again: a path the first output did not list → `QA status: blocked`…": **0 tests fail**.
  - Removing the scratch-folder sentence and the sentence "A stack trace, an empty answer, a success code on bad input… is a finding": **0 tests fail**.
- [x] The story made no existing test useless.

## Neighbours
- [x] I read `qa.md` (walk steps 5–7, Limits), `SKILL.md`, `browser.md`, `po-lint:283-292` and `tests/qa-drivers.test.sh`. Nothing is broken, but `qa.md:48` and the driver disagree (first finding).

## Lenses
Lenses run: none. No path or content trigger: the diff is method prose and bash phrase tests, with no auth code, migration, lockfile or server code.

## Findings
- major — `method/skills/qa-drivers/scenarios.md:12` — The before/after `git status --porcelain --ignored` rule blocks on "a path the first output did not list" and has no exception for `docs/qa/<id>/`. The transcripts this same driver writes there (`:30`) are exactly such new untracked paths. Read literally, every `command`/`endpoint` QA ends `QA status: blocked`. `qa.md:48`, which the plan says this rule extends ("same rule as `qa.md:48`"), exempts `docs/qa/<id>/`, and the driver dropped that exemption. Fix: add "outside `docs/qa/<id>/`".
- major — `method/skills/qa-drivers/scenarios.md:21` — For `lib`, the driver says to "write a short script under the temporary directory" but does not say it must be written through Bash. In mode `qa`, `po-bounds` refuses the Write tool outside `docs/qa/<id>/`, and the temp dir is included (`po-bounds.sh:271-278`). `qa.md:56` makes a refusal a stop and forbids reaching the same result by another route. An agent that first reaches for Write is therefore stopped, and writing the same file through Bash afterwards is arguably forbidden. The research knew this ("scratch files are written through Bash only"), but the driver does not say it.
- major — `tests/scenario-driver.test.sh:47-54` — Untested rules. The blocking consequence of the clean-tree check (the plan's own pivot asks to "check that the driver keeps that comparison and ends `blocked` on a new path"), the scratch-folder rule and the "success code on bad input is a finding" rule can each be deleted with no test failing (bite results above). The tests pin `status --porcelain --ignored` and `runs on a copy`, both of which survive the deletion.
- minor — `method/skills/qa-drivers/scenarios.md:14` — The start has no failure branch for a service that never answers. "Wait until it answers on that port" has no bound and no `blocked` outcome when nothing answers, while `browser.md` has one ("nothing answers at that origin → … blocked"). How the agent would detect "answers on another port" is also left unsaid.
- minor — `method/agents/qa.md:18` (outside `Owns`) — The driver makes the `qa` agent read `Install` and `Build` (`scenarios.md:10`), but `qa.md`'s `Reads settings:` line lists only `Target branch`, `Platform`, `Dev`. The `AGENTS.local.md` convention requires every setting read to be listed. This is a gap in the story's `Owns`, not an implementer breach; the research and the record already note it as a follow-up.
- minor — `method/skills/qa-drivers/scenarios.md:12` — `status --porcelain --ignored` collapses an already-ignored directory into one line (for example `!! node_modules/`). A program writing inside a directory that was already ignored is not caught. This is a residual limit of the safety net; ADR-0059's copy rule is the real guard.

## Not verified
- **No real `/po-qa` run against a `command` or `endpoint` story.** Every rule here is model-followed prose, and the tests pin phrases, not behaviour. So I could not see whether an agent copies the tree correctly, picks a free port, stops only its own process group, redacts secrets, or (first finding) blocks on its own transcripts. A person should run `/po-qa` on a small CLI story and on an API story in a sample project, then inspect `docs/qa/<id>/`, the worktree status and the leftover processes and ports.
- **The secret-redaction path** was never exercised against the pre-commit secret scan of `/po-qa`'s evidence commit. Check it with a transcript that echoes a token.
- **Copying a project with submodules, LFS or generated config** that is not tracked was not checked. The plan accepts that this would break the copy.
- **`setsid` PID and process-group behaviour** across shells was not checked; I relied on reasoning only.

Max severity: major
Ship allowed: yes
