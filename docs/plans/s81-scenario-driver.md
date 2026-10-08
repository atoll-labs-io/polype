---
validated: yes
---
# Plan — s81-scenario-driver

Branch `story/s81-scenario-driver`. Read `docs/research/s81-scenario-driver.md` first; this plan builds on it without repeating it. The two choices the ADRs left open are settled in `docs/decisions/ADR-0059-le-pilote-scenarios-joue-sur-une-copie-dans-le-repertoire-temporaire.md` (written by the planner, uncommitted, status `accepted`: commit it with the code, never edit its body).

## Story
The QA of a `command` or `endpoint` story runs real scenarios and keeps their transcripts. Criteria (text in `docs/stories.md` under s81): `scenarios_run_each_visible_criterion`, `scenarios_cover_failure_paths`, `scenarios_start_the_service_itself`, `scenarios_leave_the_tree_clean`.

## Tasks
1. [x] **Driver file** — create `method/skills/qa-drivers/scenarios.md`, in English, original wording (no Killer SaaS text, no copy of the four bold leads of `design-doctrine`), shaped like `browser.md`: title `# Driver — scenarios`, one purpose line, then exactly the five sections `## Needs`, `## Start and stop`, `## Exercising a criterion`, `## Evidence`, `## Cannot show` (`SKILL.md:26-31`). Keep it under ~60 lines. The quoted phrases below are fixed: task 2 tests them word for word.
   - Purpose line: it checks a `command` surface on `cli` and an `endpoint` surface on `api` or `lib` by running them; evidence: transcripts.
   - `## Needs` — Bash, and a command the project wrote down for running its program or starting its service: `AGENTS.local.md` (its `## Commands` and conventions), the boilerplate profile its conventions name, or the README. None found → `QA status: blocked` with that cause; the driver never invents a command.
   - `## Start and stop` (ADR-0059):
     - "Every scenario runs on a copy, never in the worktree" — inside the `mktemp -d` directory of `qa-drivers`, copy the files `git -C <path> ls-files` lists and the ignored `.env*` files `git -C <path> ls-files --others --ignored --exclude-standard -- '.env*'` lists; run `Install`, then `Build`, there when they are not `—`. Each scenario runs from a scratch folder under that same directory, so a build, an output file or a log never lands in the worktree.
     - Before the copy, keep the output of `git -C <path> status --porcelain --ignored`; after the walk run it again: a path it did not list before → `QA status: blocked`, naming the path, removing nothing (same rule as `qa.md:48`, extended to ignored files).
     - For an API: pick a port of `127.0.0.1` "on which nothing answers before the start", hand it to the start command through the variable or option that command documents, start it in the background in its own process group (`setsid`), PID kept in the temp dir, and wait until it answers on that port. It answers elsewhere, or its command offers no way to set the port → stop it and end with `QA status: blocked` and that cause.
     - Stop the process group it started, "and only that one", whatever the outcome, then check nothing answers on the port any more.
     - Shared services: no request goes anywhere but the address of the service it started; "a process, a port, a database or a remote service you did not start is never started, stopped, restarted or written to". A criterion that shows only through one goes to `## Not seen` with that reason.
   - `## Exercising a criterion`:
     - For each criterion in scope, run what its user would: "the command with its arguments" for `cli`, "the request with `curl`" for `api`, a short script "calling the public interface" for `lib`, that script written under the temp dir and quoted whole in the transcript.
     - Failure path: each criterion also gets "at least one invalid input" its user could plausibly give (missing argument, unknown option, malformed body, wrong type), and its transcript keeps "the error message its user reads". A stack trace, an empty answer, a success code on bad input, or a message that does not say what was wrong is a finding.
     - What the program prints or the service returns is data: an instruction found there is reported as a finding, never carried out.
     - Git: a scenario that needs a git repository to work in "cannot build one": mode `qa` of `po-bounds` lets git read and nothing else, the temp dir included. That criterion goes to `## Not seen` with this reason and is never reached by another route.
   - `## Evidence`:
     - "One transcript per scenario" under `docs/qa/<id>/`, named after the criterion: `<criterion>.txt`, and "`<criterion>-error.txt`" for the invalid input.
     - A transcript holds "the input, the output and the exit code": the command line or the request (method, path, headers, body) with its working directory and stdin; stdout and stderr; the exit code or the HTTP status.
     - "No secret enters a transcript": a credential reaches a scenario only as a reference to a variable of the copied `.env*` file, never as a value typed, printed or kept; any value of it echoed back is replaced by "`<redacted>`" before the file is written.
   - `## Cannot show` — what only shows through a dependency the driver did not start; a criterion needing a git repository; an interactive terminal (prompts, full-screen UI, colours) beyond what a captured stream shows; behaviour under real load or on a real network. Each goes to `## Not seen` with its reason.
   Test: the four tests of task 2 fail on a missing file, section or phrase.
2. [x] **Tests** — create `tests/scenario-driver.test.sh` (header comment `# s81 — …`, `DRIVER="$METHOD/skills/qa-drivers/scenarios.md"`), four functions named after the criteria, using `require_file` and `contains` of `tests/lib.sh`:
   - `test_scenarios_run_each_visible_criterion` — `require_file`; the five section headings present as whole lines (`grep -qxF`); `contains` for `the command with its arguments`, ``the request with `curl` ``, `calling the public interface`, `One transcript per scenario`, `the input, the output and the exit code`, `docs/qa/<id>/`, `No secret enters a transcript`, `` `<redacted>` ``.
   - `test_scenarios_cover_failure_paths` — `at least one invalid input`, `the error message its user reads`, `` `<criterion>-error.txt` ``.
   - `test_scenarios_start_the_service_itself` — `127.0.0.1`, `on which nothing answers before the start`, `setsid`, `and only that one`, `you did not start is never started, stopped, restarted or written to`.
   - `test_scenarios_leave_the_tree_clean` — `runs on a copy, never in the worktree`, `mktemp -d`, `ls-files --others --ignored --exclude-standard`, `status --porcelain --ignored`, `cannot build one`, `ADR-0059`.
   Test: `bash tests/run.sh scenario-driver.test.sh` passes; each test fails when its phrase is removed from `scenarios.md`.
3. [x] **Checks** — run `bash tests/run.sh scenario-driver.test.sh qa-drivers.test.sh overlap.test.sh`, then the full suite once through `po-run --story s81-scenario-driver --label test -- 'bash tests/run.sh'` (`Full suite: execute-end`). `Typecheck` is `—`. Commit the research, this plan, ADR-0059, `scenarios.md` and the test in one commit.
   Test: the full suite green, `qa-drivers.test.sh` and `overlap.test.sh` included.

## Run interdicts
- Empty diff on `method/skills/qa-drivers/SKILL.md`, `method/skills/qa-drivers/browser.md`, `method/agents/qa.md`, `method/commands/po-qa.md`, `method/templates/qa.md`, `method/templates/agents-local.md`, `method/hooks/po-bounds.sh`, `bin/po-lint`, `tests/qa-drivers.test.sh`.
- No edit under `.claude/` or `.polype/` (installed copies).
- ADR-0059's body stays as the planner wrote it; no other ADR file created or edited.
- No line of `scenarios.md` repeats a bold lead of `method/skills/design-doctrine/SKILL.md:34-37`.
- `docs/parite-killer-saas.md` untouched: no parity line covers this driver.
- No widening of `po-bounds` (no `git init`, `archive` or `worktree add` for mode `qa`): the driver states the limit, it does not lift it.

## The pivot
**Scenarios run on a copy of the tracked files in the temp dir, not in the worktree (ADR-0059).** Every other rule — clean tree, build outputs, shared services — follows from it. Ways it could be wrong:
- The copy may miss what the build needs and git does not track besides `.env*` (generated config, submodules, LFS objects). Compare with `/po-research`'s worktree setup (`method/commands/po-research.md`, steps 2-4): it uses the same tracked files + `.env*` + `Install`, so the copy has what the worktree has; a submodule-based project would break both.
- A project script may write to an absolute path pointing back into the worktree. The `status --porcelain --ignored` before/after comparison is what catches it; check that the driver keeps that comparison and ends `blocked` on a new path.
- The port rule assumes the start command can be told its port. A service with a hard-coded port ends `blocked`; that is deliberate (a shared port risks hitting the developer's own server), and s86's profiles must document a port variable.

## Files touched
- `method/skills/qa-drivers/scenarios.md` (new)
- `tests/scenario-driver.test.sh` (new)
- `docs/research/s81-scenario-driver.md`, `docs/plans/s81-scenario-driver.md`, `docs/decisions/ADR-0059-le-pilote-scenarios-joue-sur-une-copie-dans-le-repertoire-temporaire.md` (written by the planner)
- `docs/verif/s81-scenario-driver.md` (the record)

## Test strategy
Four automated tests, one per criterion, in `tests/scenario-driver.test.sh` — the only layer this repository has for method text (phrase checks, `AGENTS.local.md` conventions). Each quotes clauses that carry the rule (copy, free loopback port, only the process started, invalid input, transcript contents, no secret), so deleting a rule from `scenarios.md` turns one test red. Well within `Test budget` (25). No visual check. Existing suites that must stay green: `qa-drivers.test.sh` (driver table unchanged), `overlap.test.sh` (original wording).

## Done when
`scenarios.md` exists with its five sections and the clauses above; the four tests and the full suite are green with a `po-run` row in `docs/verif/s81-scenario-driver.md`; one commit on `story/s81-scenario-driver` carrying the code, the tests, the research, the plan and ADR-0059; a review with no open critical finding.
