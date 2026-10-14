# Review — s134-everything-to-handle-is-an-issue

[Story](../stories.md) · [Plan](../plans/s134-everything-to-handle-is-an-issue.md) · [Verification](../verif/s134-everything-to-handle-is-an-issue.md)

Diff reviewed: `git diff main...story/s134-everything-to-handle-is-an-issue`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: e3d8b653628b06760425aeec42b217697bd79de0

## When blocked
- Not blocked.

## Ownership
I listed the diff with `git diff --name-status main...story/s134-everything-to-handle-is-an-issue` (11 paths) and held each path against `Owns`.
- [x] Every path is inside `Owns`. The six method, settings and test files match `Owns` exactly. `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md` is added (status `A`), matches `docs/decisions/ADR-0090-*` and is named by plan task 5. Research, plan and verif are this story's own pipeline evidence.
- [ ] Outside `Owns`: none.
- [ ] Inside another running story's `Owns`: none.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s134-everything-to-handle-is-an-issue` exits 0, so I reused the record (`Verification mode: record`). The record shows the unit suite `bash tests/run.sh` exiting 0, on code outside `docs/` identical to `Tree: dd55319…`. The earlier exit-1 row came before the lead's rebase onto 875acee, and "Not proven here" explains it. Type check, E2E and build are `—`: the project has none. I read "Not proven here": no real filing was exercised, and the installed `.claude/`, `.polype/` and root `AGENTS.md` are not refreshed yet.
- [x] `po-gate qa-current`: not required. With `QA stage: —`, the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present. I found no change the plan did not ask for.
- [x] I checked each run interdict:
  - The root `AGENTS.md`, `.claude/`, `.polype/`, `docs/stories.md`, `method/skills/`, po-orchestrator, po-flow, the parity matrix and all existing tests are untouched.
  - In po-setup, the Step 2 heading, "Nothing else is asked", the five questions and `Reads settings: none` are unchanged.
  - In po-ship, "Cleanup, only after proof", "already prints `MERGED`, go straight to cleanup" and the forge's review rule are unchanged. The new text adds no `curl` and no `env -u GH_TOKEN`.
  - Only one ADR was added: 0090.
  - Per the lead's instruction, no `gh issue`, `gh api` or `task add` was run here.

## References
- [x] I opened every reference and it exists:
  - po-ship `:18` (the block rule) and `:22` (straight to cleanup).
  - po-ship `## The forge's review rule` (github.com recognition, ADR-0083).
  - po-drive `:31` (meaning of "shipped") and `:148`.
  - po-setup Step 1 (it reads `origin`).
  - ADR-0077, 0080, 0081 and 0083 under `docs/decisions/`.
  - `settings_read_by` in `tests/lib.sh`, through the existing tests.
- [x] The CLI forms used are valid: `gh issue list --search … --json title`, `gh issue create --repo HOST/OWNER/REPO`, `gh auth status --hostname`, `task rc.verbose=new-uuid add`, `task <uuid> annotate`.
- [ ] Some values look right but nothing confirms them: the accepted shape of a finding line, and the quoting of the shell commands. See Findings.

## Rules
- [x] The `AGENTS.md` conventions hold: method text in English, ADR in French, a `Reads settings:` line for every reader.
- [x] No accepted ADR is contradicted.
  - **Requested check: the `/po-drive` re-ship against ADR-0080/0081.** The new paragraph re-runs `/po-ship` only for a lane that is already shipped (a `<id>:` commit on Target branch) and whose pull request prints `MERGED`. `/po-ship` then passes Step 0 again: `story/<id>` is never rewritten (`:71`), so `Reviewed tree:` still matches. Step 3.1 proves the merge again before filing or removing anything. Cleanup still happens only after a proven merge, and nothing pushes `Target branch`.
  - **Requested check: step 3.2 against Step 0.** Step 3.2 reads "the block that ends with its last `Ship allowed:` line, as Step 0 reads it". That is the same block Step 0 bounds (between the previous verdict line and the last one), which is how fix-loop reviews are appended (s125, s131).
  - **Requested check: ADR-0090 against the method.** ADR-0090 matches what the method now says: the title format, no duplicates, `gh` only toward github.com, `+issue`, the `—` consequence, the setup rule, the security hold, and the re-ship without a `Parallel` slot. Two of its sentences are inaccurate; see the minor findings.

## Tests
- [x] Floor: `po-gate floor-guard s134-everything-to-handle-is-an-issue main` exits 0, so nothing was lowered.
- [x] The assertions quote the clause each acceptance criterion rests on. None of the six empty test shapes appears; no test runs `gh` or `task`.
- [x] Seven tests, within `Test budget: 25`.
- [x] Bite, three times, each run limited to `bash tests/run.sh everything-in-issues.test.sh`:
  - I removed the "Security stays with the person" bullet from po-ship: 1 test failed (`security_goes_to_the_person`). Undone; `git diff --exit-code` is clean.
  - I moved the worktree-removal step ahead of filing: 1 test failed (`ship_files_open_findings`, ordering). Undone; clean.
  - I removed the "That later proof is yours to make" paragraph from po-drive: 1 test failed (`ship_files_open_findings`). Undone; clean.
  - At the end, `git status --porcelain` is empty.
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read the other callers. po-flow `:91` and po-orchestrator `:81` apply `/po-ship` as written, so they inherit the filing. po-setup `:74` refers to Step 3 as a whole, not to a step number, so the renumbering breaks nothing. `agentic-stories/SKILL.md:53` keeps the "turns one into a story" wording, which is still true. The full suite is green on this code, per the record.

## Lenses
Lenses run: security. It was triggered by content: forge calls that carry a token (`gh issue create`/`list` toward a repository derived from `origin`), and shell commands built from review text, which is input.
- [x] I graded the security finding below on the review scale and listed it under Findings.

## Findings
- major — `method/commands/po-ship.md` Step 3.2 (github and taskwarrior bullets) — The finding text is inserted literally into single-quoted shell arguments: `--title '<title>' --body '<body>'`, `--search '<title> in:title'`, `-- '<title>'`, `annotate '<body>'`. Real findings contain single quotes; `docs/reviews/s121…` quotes "`'Pull request ready: <url>.'`". Followed literally, such a finding breaks the command. Text a reviewer quoted from an untrusted diff could also break out of the quotes and run under the lead's shell. The method already has a quoting rule for `po-run` (`'\''`, testing-doctrine) but says nothing here. Ask for `--body-file`/stdin, or an explicit escaping rule.
- major — `method/commands/po-ship.md` Step 3.2 "Which findings" — Step 3.2 picks up only lines whose severity is `major` or `minor`, with a leading `- ` or `* `. Real reviews also write `1. **minor**:` (s124, s130), `- **major** —` (s128) and multi-line findings with sub-bullets (s121, s131). A literal reading files none of these and does not list them in the finish either, so they are silently lost — the opposite of the story's aim. "The full finding line" also drops the sub-bullets. Either widen the recognised shapes, or make an unparsed line under `## Findings` go to the person.
- minor — `method/commands/po-ship.md` Step 3.2 lead-in, and ADR-0090 Decision Outcome ("car la revue part avec le worktree") — The stated reason does not hold. Step 1 (`:51`) commits the review on `story/<id>`, and Law 6 (`method/AGENTS.md:116`) says it lands with the story's commit. The review does not disappear with the worktree. The placement before removal is still right (the worktree copy is what gets read); only the reason is wrong.
- minor — ADR-0090 option D — The ADR turns option D down because a public tracker would publish the flaw. Yet the same review, security findings included, is already public in the pull request and on Target branch through the story's commit. Holding security findings back from the tracker therefore protects less than the ADR implies; worth stating.
- minor — `method/AGENTS.md:71` against the new Law 7 paragraph — `## What goes to the person` says "three motives, and only these". Law 7 now sends every item to the person under `Issue tracker: —`, and every security item under any value. That is a fourth reason, not reconciled with "only these".
- minor — `method/commands/po-setup.md:44` — "takes no question either" follows the `Project CLAUDE file` paragraph, which does ask a question, so "either" points at nothing nearby. Also, the setup's finish line (`:62`) does not carry the promised mention of the `Issue tracker` value.
- minor — `method/commands/po-ship.md` Step 3.2 "No duplicate" — The dedupe goes through `gh issue list --search`, which reads GitHub's search index. A just-created issue can be missing from that index for a short time, so a quick rerun may file it twice. `gh issue list --state open --json title --limit N` without `--search`, compared exactly, avoids the index.
- minor — `method/commands/po-drive.md:150` — "`status` … only lists such lanes", but neither the `## Report` list nor the `status` answer (`:170`) names the category of a merged lane waiting for cleanup.

## Not verified
- No real filing ran: no `gh issue create`, no `gh issue list --search` against GitHub, no `task add`/`annotate`. The lead forbade it, and no test exercises it. A person should watch the first real ship of a story with open findings: check the title, the body, the dedupe on a rerun, and the "not filed" finish under `gh` logged out.
- The `/po-drive` re-ship of a lane a person merged was checked by reading the text only, never run. A person should check it on the first lane left for a human merge.
- The judgement "text bears on security" cannot be tested; no example was tried.
- `.claude/`, `.polype/` and the root `AGENTS.md` still hold the old method. This ship itself will use the old `/po-ship`, so this review's findings will not be filed automatically.
- I took the full suite from the record and did not re-run it.

Max severity: major
Ship allowed: yes

---

# Review — s134-everything-to-handle-is-an-issue

[Story](../stories.md) · [Plan](../plans/s134-everything-to-handle-is-an-issue.md) · [Verification](../verif/s134-everything-to-handle-is-an-issue.md)

Diff reviewed: `git diff main...story/s134-everything-to-handle-is-an-issue`. I did not write this code. This loop checks fix commit 868ab5e against the loop-0 findings. Findings are graded critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 768a9f67b1df91759eb50c3d2eca5605359070cb

## When blocked
- Not blocked. The tree was taken again just before answering and is unchanged. The worktree is clean.

## Ownership
I listed the diff with `git diff --name-status main...story/s134-everything-to-handle-is-an-issue` (12 paths) and held each one against `Owns`.
- [x] Every path is inside `Owns`.
  - The five method files, `AGENTS.local.md` and the test file match `Owns` exactly.
  - ADR-0090 was added (status `A`), matches `docs/decisions/ADR-0090-*` and is named by the plan.
  - Research, plan, verif and review are this story's own pipeline evidence.
- [ ] Outside `Owns`: none.
- [ ] Inside another running story's `Owns`: none.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] I reused the record (`Verification mode: record`).
  - `po-gate verif-current s134-everything-to-handle-is-an-issue` exits 0.
  - The record's `Tree: 43bd29f…` equals HEAD's code outside `docs/`: `git diff --quiet` exits 0.
  - The last `bash tests/run.sh` row exited 0.
- [x] I read "Not proven here". Fix run 1 executes the title and body commands on a fixture. Item splitting and the "shape not recognised" hand-over stay prose.
- [x] The project has no type check, E2E or build: all are `—`.
- [x] `po-gate qa-current` is not required: with `QA stage: —`, the story does not go to QA.

## Plan
Each loop-0 finding against 868ab5e:
- [x] Major, shell quoting: **fixed**.
  - Title and body are now cut from the review by line numbers into `$d/title` and `$d/body`.
  - They are filed through `--body-file` and `"$(cat "$d/title")"`.
  - Law 7 now carries the general rule.
- [x] Major, finding shapes: **fixed**.
  - Recognised shapes are now `- `, `* ` and `1. `, with the severity bare or in bold and the colon inside or outside the bold.
  - Items are taken whole, sub-bullets included.
  - Unrecognised lines that name a severity, and unfixed criticals, go to the person.
- [x] Minor, placement reason: fixed in po-ship and ADR-0090.
- [x] Minor, ADR option D: the nuance has been added.
- [x] Minor, "only these" in `## What goes to the person`: reconciled in both places.
- [x] Minor, po-setup "either" and the finish line: fixed.
- [x] Minor, dedupe through the search index: replaced by an exact compare against `--state open --limit 1000 --json title --jq '.[].title'`.
- [x] Minor, merged lanes in the po-drive report and status: both now name them.
- [x] Run interdicts still hold: root `AGENTS.md`, `.claude/`, `.polype/`, `docs/stories.md` and existing tests are untouched. Following the lead's note, I ran no `gh issue`/`gh api` write and no `task add` against the owner's forge or Taskwarrior.

## References
- [x] `gh issue create` has `-F/--body-file` and `-t/--title`; `gh issue list` has `-L/--limit` and `-q/--jq`. I checked this against the local `gh --help`.
- [x] Taskwarrior 3.5.0, run in a throwaway `TASKDATA` under the temp dir with `rc.hooks=0`:
  - `task rc.verbose=new-uuid add project:polype +issue -- "$(cat title)"` stores the title literally. That includes `'`, backticks, `$(touch pwned)`, `"q"`, `-rf`, `+tag`, `project:evil` and `due:tomorrow`; none of these were parsed as attributes.
  - `task <uuid> annotate -- "$(cat body)"` stores the multi-line body literally.
  - `task project:… +issue status:pending _unique description` accepts the filter. `grep -qxF -f title open` matched, so the dedupe hits.
  - Nothing was executed.

## Rules
- [x] The `AGENTS.md` conventions hold: method text in English, ADR in French.
- [x] No accepted ADR is contradicted.
- [x] ADR-0090's Decision Outcome now matches the new po-ship text: reason, exact dedupe, shapes, no shell argument.

## Tests
- [x] Floor: `po-gate floor-guard s134-everything-to-handle-is-an-issue main` exits 0, so nothing was lowered.
- [x] 9 tests (`bash tests/run.sh everything-in-issues.test.sh`: 9 passed), within `Test budget: 25`. The two new tests extract the commands from po-ship itself and run them on a fixture review. They do not restate the commands. I found none of the six "tests that prove nothing" shapes.
- [x] Bite, twice. Each run was limited to `bash tests/run.sh everything-in-issues.test.sh`:
  - I changed the title command to feed the review line through `eval "echo $(sed -n '<first>p' …)"`: 2 tests failed (`finding_text_never_enters_a_command`, `every_finding_shape_is_read`). Undone with `git checkout --`; `git diff --exit-code` is clean.
  - I removed the bold handling from the severity-stripping `sed` (`s/^(critical|major|minor) *[—:-]? *//`): 2 tests failed (same two). Undone; clean.
  - Afterwards, `git status --porcelain` is empty.

## Neighbours
- [x] po-flow and po-orchestrator call `/po-ship` as written. `po-review.md:26` confirms that fix-loop reviews are appended to the same file. That matters for the first finding below.

## Lenses
Lenses run: security. It was triggered by content: shell commands that carry review text, which is input, to `gh issue create`/`gh issue list` with a forge token, and to `task add`/`annotate`.
- [x] Shell word: no review text reaches a shell word. Only the story id, the severity word, the line numbers and the URL `gh` printed are substituted into `printf`. The review text goes file → `sed` → file. The test proves that `$(touch pwned)` never runs.
- [x] `-f` pattern file: `grep -qxF -f "$d/title"` reads one non-empty line (the `<id>: <severity> — ` prefix is always present). With `-F -x` it is a fixed, whole-line match, so no regex or empty-pattern trap.
- [x] `$(cat …)` splitting: it is always inside double quotes, so the shell passes one argument and does not split or glob it.
- [x] Option position: the title always starts with `<id>:`, so it can never start with `-`. The body goes through `--body-file`. Taskwarrior gets `--` before both title and body.
- [x] The token goes only to github.com through `gh`. No `curl` was added.

## Findings
- minor — `method/commands/po-ship.md:91` (body command) — `grep -m1 '^Fix loop:' docs/reviews/<id>.md` takes the **first** `Fix loop:` of the file. Fix-loop reviews are appended (`po-review.md:26`; ten existing review files hold 2–3 such lines). For a story that went through a fix run, the filed body therefore names `Fix loop: 0` instead of the loop of the last review that Step 3.2 reads. The fixture holds a single `Fix loop:` line, so the test cannot see this. Take the last occurrence instead, for example `grep '^Fix loop:' … | tail -n1`.
- minor — `method/commands/po-ship.md:90` (title command) — Two things depend on the environment:
  - The separator class `[—:-]` holds a multibyte em dash. Under a C/POSIX locale, `sed -E` matches it byte by byte. I probed it: it leaves `\x80\x94` at the head of the title, which is invalid UTF-8.
  - `cut -c1-80` counts characters only on recent coreutils (9.12 here). Older GNU coreutils cut bytes and can split an accented character.

  In both cases GitHub would store a different title from the local file, the exact compare would miss, and every rerun would file a duplicate. Pinning `LC_ALL=C.UTF-8` on the pipeline, or stating that the commands need a UTF-8 locale, closes it.
- minor — `method/commands/po-ship.md:94` — `--limit 1000` caps the dedupe list. A repository with more than 1000 open issues could get a duplicate. Also, if `gh issue list` fails, the step leaves an empty `$d/open`, and the finding is filed anyway with no duplicate check. Say that a failed listing means "nothing is filed".
- minor — `docs/plans/s134-everything-to-handle-is-an-issue.md:57,89` — The test strategy still says "seven `test_*` functions" and "no test executes a filing command". The fix run added two tests that execute the extraction commands. That is within budget and justified by the loop-0 findings, but the plan no longer describes the file.

## Not verified
- No real `gh issue create` or `gh issue list` was run: the lead forbade it. I have not seen these:
  - whether GitHub trims a title that ends in a space because the cut landed on a space; that would also make the exact dedupe miss;
  - the `--jq '.[].title'` output against a real repository;
  - the "not filed" finish when `gh` is logged out.

  A person should watch the first real ship that has open findings, rerun it once to confirm no duplicate, and check one title that holds accents.
- The prose parts were only read, never executed: splitting items (where `<last>` ends), "marks fixed", the "shape not recognised" hand-over, merging findings that share a title into one body, and the "text bears on security" judgement.
- The `/po-drive` re-ship of a lane a person merged was checked by reading only.
- Older coreutils, BSD `cut` and a C locale were reasoned about or probed in isolation, not run end to end.
- `.claude/`, `.polype/` and the root `AGENTS.md` still hold the old method. The worktree's root `AGENTS.md` still shows `Issue tracker: —` and the old Law 7. This ship will run the old `/po-ship`, so this review's findings will not be filed automatically.
- I took the full suite from the record and did not rerun it. I ran only the story's test file.

Max severity: minor
Ship allowed: yes

---

# Review — s134-everything-to-handle-is-an-issue

[Story](../stories.md) · [Plan](../plans/s134-everything-to-handle-is-an-issue.md) · [Verification](../verif/s134-everything-to-handle-is-an-issue.md)

Diff reviewed: `git diff main...story/s134-everything-to-handle-is-an-issue`. I did not write this code. This loop checks fix commit abed386 against the loop-1 findings. Findings are graded critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: 99df95ff7aa62e1694f77d385502ae298e809480

## When blocked
- Not blocked. I took the tree again just before answering and it has not changed. The worktree is clean (`git status --porcelain` is empty).

## Ownership
I listed the diff with `git diff --name-status main...story/s134-everything-to-handle-is-an-issue` (12 paths) and checked each one against `Owns`.
- [x] Every path is inside `Owns`.
  - The five method files, `AGENTS.local.md` and `tests/everything-in-issues.test.sh` each match an `Owns` entry exactly.
  - ADR-0090 is added (status `A`), matches `docs/decisions/ADR-0090-*`, and the plan names it.
  - The research, plan, verif and review files are this story's own pipeline evidence.
- [ ] Outside `Owns`: none.
- [ ] Inside another running story's `Owns`: none. `git worktree list` shows only `main` and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] I reused the record (`Verification mode: record`).
  - `po-gate verif-current s134-everything-to-handle-is-an-issue` exits 0.
  - The record's `Tree: 777f62f…` equals HEAD's code outside `docs/`: `git diff --quiet` exits 0.
  - The last `bash tests/run.sh` row (13:50:34Z) exited 0.
- [x] I read "Not proven here". Fix run 2 states that these were not executed: BSD `sed`, a missing `C.UTF-8` locale, and the refusal after a failed or 1000-title listing.
- [x] The project has no type check, E2E or build: each is `—`.
- [x] `po-gate qa-current` is not needed: with `QA stage: —`, the story does not go to QA.

## Plan
Each loop-1 finding, checked against abed386:
- [x] Minor, first `Fix loop:` instead of the last: **fixed**. The command is now `grep '^Fix loop:' … | tail -n1`. The prose explains why, and the fixture now holds two reviews (`Fix loop: 1`, then `Fix loop: 2`).
- [x] Minor, locale-dependent cut: **fixed**.
  - `cut -c1-80` is replaced by `s/^(.{80}).*/\1/` inside the same `sed`, which now runs under `LC_ALL=C.UTF-8`.
  - A trailing space left by the cut is now trimmed (`s/ +$//`).
  - The test runs the command under an outer `LC_ALL=C` and checks an accented title of 79 `é` plus ` suite`.
- [x] Minor, `--limit 1000` cap and a failed listing: **fixed** in prose, in po-ship and in ADR-0090.
  - A listing that exits non-zero files nothing and quotes the error.
  - A `github` listing that returns exactly 1000 titles is refused, not paged.
- [x] Minor, stale plan test strategy: **fixed**. Task 6, Test strategy and Done-when now say nine tests and describe the two tests that execute commands.
- [x] Run interdicts still hold. Root `AGENTS.md`, `.claude/`, `.polype/`, `docs/stories.md` and the existing tests are untouched. As the lead asked, I ran no `gh issue`/`gh api` write and no `task add` against the owner's forge or Taskwarrior.

## References
- [x] `LC_ALL=C.UTF-8` resolves on this machine (`locale -a` lists `C.utf8`). The repository already relies on it in `tests/hooks-installer-docs-cleanup.test.sh:108`.
- [x] The new "a failed listing proves nothing" rule has to hold up when the list is empty. I probed it with Taskwarrior 3.5.0 in a throwaway `TASKRC`/`TASKDATA` under `/tmp/tmp.hjnsbb6k6K` (`hooks=0`):
  - `task project:polype +issue status:pending _unique description` exits **0**, with empty output, on an empty data dir.
  - It also exits 0 when only another project has tasks.
  - So a first filing is not mistaken for a failed listing, and `grep -qxF -f title` on the empty file exits 1, so the finding gets filed.
- [x] ADR-0090's Decision Outcome now carries the failed-listing and 1000-titles clause, consistent with po-ship.

## Rules
- [x] The `AGENTS.md` conventions hold: method text is in English and the ADR in French.
- [x] No accepted ADR is contradicted. The token still goes to github.com only, through `gh`, with no direct HTTP call (ADR-0083).

## Tests
- [x] Floor: `po-gate floor-guard s134-everything-to-handle-is-an-issue main` exits 0, so nothing was lowered.
- [x] 9 tests (`bash tests/run.sh everything-in-issues.test.sh`: 9 passed), within `Test budget: 25`.
  - The new assertions run the command extracted from po-ship itself.
  - The `a && ! b || fail` check on the body fails if either part fails.
  - None of the six "tests that prove nothing" shapes appears.
- [x] Bite, three times. Each run was limited to `bash tests/run.sh everything-in-issues.test.sh`, and each change was undone with `git checkout --`, with `git diff --exit-code method/commands/po-ship.md` clean afterwards:
  - I removed `LC_ALL=C.UTF-8` from the title `sed`: 1 test failed (`every_finding_shape_is_read`).
  - I put back `grep -m1 '^Fix loop:'` without `tail -n1`: 1 test failed (same test).
  - I dropped the `s/ +$//` trim: 1 test failed (same test).
  - Afterwards, `git status --porcelain` is empty.

## Neighbours
- [x] No other file in `method/`, `tests/` or `docs/decisions/` still uses `cut -c1-80` or `grep -m1 '^Fix loop:'`. ADR-0090 was updated alongside po-ship. po-flow and po-orchestrator call `/po-ship` as written.

## Lenses
Lenses run: security. It was triggered by content: the changed po-ship Step 3.2 commands, which carry review text (input) to `gh issue list`/`gh issue create` with a forge token, and to `task add`/`annotate`.
- [x] Shell word: still no review text in a shell word. The fix added only constants to the `sed` script (`.{80}`, ` +$`) and a `tail -n1`. The review text still goes file → `sed` → file.
- [x] The locale pin applies only to the title `sed`. It changes how characters are counted, not what is quoted or expanded.
- [x] The refusal after a failed or capped listing reduces risk: no filing goes out blind.
- [x] No `curl`, no other host, no token handling added.

## Findings
- minor — `method/commands/po-ship.md:90,92` — The title `sed` relies on a `C.UTF-8` locale being installed. GNU `sed` falls back to the C locale silently when a locale is missing, and some systems may not ship `C.UTF-8` (older glibc, some macOS). On such a system the title command:
  - counts bytes again;
  - can leave a partial `—` byte or split an accented character;
  - so the exact dedupe can miss, and a rerun can file a duplicate.

  Nothing in the step detects this; the record lists it under "Not proven here". A one-line check (`locale -a | grep -qi '^c\.utf-\?8$'`, else hand the findings to the person) or a stated prerequisite would close it.
- minor — `method/commands/po-ship.md:90` — Under a UTF-8 locale, GNU `sed`'s `.` does not match an invalid byte. A first line holding one would then escape the 80-character cut and keep its full length. Review files are agent-written UTF-8, so this is theoretical; I name it for completeness.

## Not verified
- No real `gh issue list` or `gh issue create` was run, because the lead forbade it. These are therefore unseen:
  - the empty-repo `--json title --jq` output and its exit code;
  - GitHub's trimming of a title, beyond the trailing space;
  - the refusal at exactly 1000 titles;
  - the "not filed" finish when `gh` is logged out.

  A person should watch the first real ship that has open findings, rerun it once to confirm no duplicate, and check one title with accents.
- The title command was run only on GNU `sed` with `C.UTF-8` present. A missing locale and BSD `sed` were reasoned about, not executed.
- I probed Taskwarrior's empty-listing exit code in a throwaway data dir only, never against the owner's data. I did not run `task add` against the owner's Taskwarrior.
- These parts are prose that was read, never executed:
  - item splitting (where `<last>` ends) and "marks fixed";
  - the "shape not recognised" hand-over;
  - merging findings that share a title into one body;
  - the "text bears on security" judgement;
  - the `/po-drive` re-ship of a lane a person merged.
- `.claude/`, `.polype/` and the root `AGENTS.md` still hold the old method. This ship will run the old `/po-ship`, so this review's findings will not be filed automatically.
- I took the full suite from the record and did not rerun it. I ran only the story's test file.

Max severity: minor
Ship allowed: yes
