---
validated: yes
---
# Plan — s134-everything-to-handle-is-an-issue

[Story](../stories.md) · [Research](../research/s134-everything-to-handle-is-an-issue.md)

Branch `story/s134-everything-to-handle-is-an-issue`. Read `docs/research/s134-everything-to-handle-is-an-issue.md` first; this plan builds on it without repeating it.

## Story
Everything to handle — an idea for a change, a feature, a defect, a finding a shipped review leaves open — becomes an issue in `Issue tracker`, filed by the lead or by `/po-ship`; security goes to the person instead. Criteria: `law_files_everything_to_handle`, `ship_files_open_findings`, `security_goes_to_the_person`, `setup_proposes_the_forge`, `adr_records_the_rule` (text in `docs/stories.md`, M12).

Three corrections the research found, applied here rather than worked around:
- `/po-drive` has no step that proves a person's merge later (`method/commands/po-drive.md:34,148`): task 3 adds it.
- "only a person turns a finding into a story" is written new; today's sentence is "only a person turns one into an issue or a story" (`method/AGENTS.md:125`).
- `/po-setup` writes `Issue tracker` from the forge reading with no question: a new follow-up would rename the Step 2 heading `tests/framing-commands-cleanup.test.sh:27` quotes.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Forge recognition and token rule for filing | already here: `method/commands/po-ship.md:27,29` (host of `origin`, `gh` pinned to github.com, ADR-0083) — cited, not restated | — |
| Which review block is "the last review" | already here: the last `Ship allowed:` block rule of `method/commands/po-ship.md:18` | — |
| Filing commands | the platform: `gh issue list/create --repo github.com/<owner>/<repo>`, `task add … -- <title>` | nothing in the repository files an issue (research, structuring facts) |
| Test file | already here: `tests/lib.sh` helpers; `section_of` copied from `tests/any-harness-docs.test.sh:13` | lib.sh has no section helper; adding one would touch a file outside `Owns` |

No script, no new setting, no new value: the filing lives in command prose, as every other forge call of `/po-ship` does.

## Tasks
1. [x] **Law 7 and the second motive** — `method/AGENTS.md`.
   - `:125`: keep the first two sentences; end the third with "only a person turns a finding into a story." (the "issue" half goes). Add a paragraph under the same heading: anything to handle — an idea for a change, a feature or a defect — whoever raised it (the person, a review, a subagent, the lead) and wherever it was noted (a conversation, `docs/decisions-log.md`, a review), is filed at once in `Issue tracker` by the lead, with its context (where it came from, why it matters); the findings a shipped review leaves open are filed by `/po-ship`. With `Issue tracker: —`, the lead brings it to the person instead. A security finding or a security idea is never filed on its own: it goes to the person, who decides where it goes (ADR-0077, ADR-0090).
   - `:71`: after "a new idea outside the approved scope, whoever brought it up" add that the lead also files it in `Issue tracker`, as Law 7 says. Heading `## Law 7 — Defects are not stories` unchanged.
   - Fails if wrong: `test_law_files_everything_to_handle`, `test_security_goes_to_the_person`.
2. [x] **Filing at ship** — `method/commands/po-ship.md`.
   - `:11`: add `Issue tracker` to `Reads settings:`.
   - Step 3: insert a new step 2 between the proof (`:84`) and the worktree removal (renumber 2→3, 3→4; keep "Cleanup, only after proof" and every existing phrase). Content:
     - Source: the findings under `## Findings` of the last review in the worktree's `docs/reviews/<id>.md` — the block that ends with its last `Ship allowed:` line (`:18`) — whose severity is `major` or `minor` (leading `- ` or `* `), less any the block itself marks fixed.
     - Title `<id>: <severity> — <start of the finding>`, the start being the finding's text after its severity, cut to its first 80 characters. Findings of one review sharing a title make one issue holding both. Body: the story id, the review path `docs/reviews/<id>.md` and its `Fix loop:`, the severity, the full finding line, and the pull request URL under `pr`.
     - No duplicate: an issue already open with exactly that title is not filed again, so a rerun after a stop at the worktree step files nothing twice.
     - `github`: only when `origin` is on `github.com` (as `## The forge's review rule` recognises it); `gh auth status --hostname github.com` passing; list with `gh issue list --repo github.com/<owner>/<repo> --state open --search '<title> in:title' --json title`, compare titles exactly, then `gh issue create --repo github.com/<owner>/<repo> --title … --body …`. The token goes only to the host that issued it (ADR-0083): no `curl`, no other host. `gh` missing or not logged in, or `origin` not on github.com → nothing filed, and the finish says so and lists the findings.
     - `taskwarrior`: `project:<repository name>` with the tag `+issue`; name = last path segment of `origin` without `.git`, else the folder of the main repository (`git rev-parse --path-format=absolute --git-common-dir`, its parent) — never the worktree folder. Duplicate check on pending tasks of that project and tag with the exact description; create with `task rc.verbose=new-uuid add project:<name> +issue -- '<title>'`, then `task <uuid> annotate` the body. `task` missing → nothing filed, reported.
     - `—`: nothing filed; the finish says so and lists the open findings for the person.
     - Security: a review whose `Lenses run:` line names the security lens (a line that starts with `none` does not) has none of its findings filed; a finding whose text bears on security (a secret or token, an authorization or tenant check, an injection) is not filed either. Each goes to the person in the finish, with "not filed: security (ADR-0077)".
   - `:88` finish: every finish after a proven merge names the issues filed (URL or task uuid), the ones skipped as already open, and the findings held for the person.
   - Fails if wrong: `test_ship_files_open_findings`, `test_ship_files_on_each_tracker_value`, `test_security_goes_to_the_person`, `test_readers_list_issue_tracker`.
3. [x] **The later proof in the fleet** — `method/commands/po-drive.md`.
   - `:14`: add `Issue tracker` to `Reads settings:` (the `:23` stop then covers it).
   - After `:148`, one paragraph: at the start of a wave's ships, a story that is shipped while its worktree `<Worktree root><id>` still exists and `gh pr view story/<id> --json state --jq .state` prints `MERGED` gets `/po-ship <id>` once more, which goes straight to cleanup (`method/commands/po-ship.md:22`) and files the open findings of its review there; it takes no `Parallel` slot and does not count as a ship for the serial order. `status` runs none of it and only lists such lanes.
   - `## Report`: add the issues filed per shipped story, the findings not filed and why, and the security findings held for the person, raised at once as `## What goes to the person` says for a stop.
   - Fails if wrong: `test_ship_files_open_findings` (the drive clause), `test_readers_list_issue_tracker`.
4. [x] **Setup and template** — `method/commands/po-setup.md`, `method/templates/agents-local.md`.
   - po-setup Step 2, after the `Project CLAUDE file` paragraph (`:42`), one unnumbered paragraph: `Issue tracker`, with no question, from Step 1's reading of `origin`: `github` when the host is `github.com`, `taskwarrior` for any other host or no remote; written into `AGENTS.local.md`, and the last message names the value and says the person changes it by asking in conversation (`github` · `taskwarrior` · `—`).
   - `:50`: "every other setting keeps the template's value" gets "`Issue tracker` aside" (or equivalent); "Nothing else is asked" and the Step 2 heading stay verbatim; `Reads settings: none` stays (setup creates the file, it reads none).
   - Template row `:56`: "where ideas, features and defects to handle are filed, and the findings a shipped review leaves open: `github` · `taskwarrior` · `—`; `—` sends them to the person". Default line `:23` stays `github`.
   - Fails if wrong: `test_setup_proposes_the_forge`.
5. [x] **Polype's own setting and the ADR** — `AGENTS.local.md:21` → `Issue tracker:     github` (alignment as the other lines). `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md` from `templates/adr.md`, in French, `status: accepted`, `date: 2026-10-14`, `scope: story s134-everything-to-handle-is-an-issue`, `supersedes: []`: context (the owner's decision of 2026-10-14, Law 7 as it stood); options — **A** the lead and `/po-ship` file everything, security to the person (chosen, by the owner); **B** only the person files (turned down: things are lost, the constat of M12); **C** only defects filed (turned down: ideas and features stay in conversations); **D** security filed too (turned down: a public tracker such as `atoll-labs-io/polype` would publish it, ADR-0077 sends security to the person). Consequences, including `—`: nothing is filed, the lead brings each item to the person and `/po-ship` lists the open findings in its report; GitLab and Forgejo are not values yet.
   - Fails if wrong: `test_adr_records_the_rule`, `test_setup_proposes_the_forge` (the Polype line).
6. [x] **Tests** — `tests/everything-in-issues.test.sh`, header `# s134 — everything to handle is an issue.`, seven `test_*` functions (nine after fix run 1, see Test strategy) quoting short exact phrases of the text tasks 1–5 write (implementer picks them from its own wording):
   - `test_law_files_everything_to_handle` — Law 7 section holds the filing paragraph (`Issue tracker`, `docs/decisions-log.md`, "with its context", the `—` clause) and "only a person turns a finding into a story"; the whole `method/AGENTS.md` no longer holds "into an issue or a story"; heading line present; `## What goes to the person` holds "a new idea outside the approved scope" and the filing clause.
   - `test_ship_files_open_findings` — Step 3 of `po-ship.md` holds the title format `<id>: <severity> — `, the no-duplicate clause, the body clause, and the filing step sits after the proof and before `git worktree remove`; `po-drive.md` holds the later-proof clause with `MERGED` and `/po-ship <id>`.
   - `test_ship_files_on_each_tracker_value` — the three values in Step 3: `gh issue create --repo github.com/`, `gh auth status --hostname github.com` with the nothing-filed clause; `+issue` with `project:`; the `—` clause.
   - `test_security_goes_to_the_person` — `po-ship.md` holds the security clause ("not filed: security") and the `Lenses run:` rule; Law 7 holds "never filed on its own".
   - `test_readers_list_issue_tracker` — `settings_read_by` of `po-ship.md` and `po-drive.md` holds `Issue tracker`; every `method/commands/*.md` and `method/agents/*.md` other than `po-setup.md` whose body mentions `` `Issue tracker` `` lists it.
   - `test_setup_proposes_the_forge` — po-setup Step 2 holds the `github`/`taskwarrior` rule; template row holds "ideas, features and defects"; `grep -qx 'Issue tracker:     github'` on `$ROOT/AGENTS.local.md`.
   - `test_adr_records_the_rule` — exactly one `docs/decisions/ADR-0090-*.md`, `adr: 0090`, `status: accepted`, the three turned-down options and the `—` consequence.
   - No test runs `gh` or `task`: nothing reaches a forge or a Taskwarrior data dir.
   - Run: `bash tests/run.sh everything-in-issues.test.sh`, then the full suite once through `po-run`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `AGENTS.md` (root), `.claude/`, `.polype/`, `docs/stories.md`, `method/skills/`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `docs/parite-killer-saas.md`, every existing `tests/*.test.sh`.
- `git diff main...story/s134-everything-to-handle-is-an-issue --name-only` lists only `Owns` paths plus `docs/research/`, `docs/plans/`, `docs/verif/`, `docs/reviews/` of this story.
- No `gh issue`, `gh api`, `task add` or any forge call run during implementation or tests.
- `method/commands/po-setup.md` Step 2 heading, "Nothing else is asked", the five numbered questions and `Reads settings: none` unchanged.
- In `method/commands/po-ship.md`: "Cleanup, only after proof", "already prints `MERGED`, go straight to cleanup", `## The forge's review rule` text unchanged; no `curl` for filing; no `env -u GH_TOKEN`.
- Only one new ADR file, numbered 0090.

## The pivot
Filing is placed in `/po-ship` Step 3, between the proof and the worktree removal, and `/po-drive` reaches person-merged lanes by rerunning `/po-ship`, so one text owns filing. Ways it could be wrong:
- `/po-ship <id>` on a person-merged lane might not reach Step 3: Step 0 gate first (`po-ship.md:18`) — compare: `story/<id>` is never rewritten (`:71`), so the `Reviewed tree:` still matches; check the review's own commit is on the branch (`:51`).
- "Security" by lens line plus text judgment could miss a security finding a reviewer wrote under a `none` lens line — compare with `method/skills/review-lenses/SKILL.md:15` triggers; the text clause is the backstop.
- Writing `Issue tracker` without a question may read as not "proposing" — compare with the criterion and the review answer in `docs/reviews/stories-m12.md` (the "le porteur répond" wording was dropped as untestable).

## Files touched
`method/AGENTS.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-setup.md`, `method/templates/agents-local.md`, `AGENTS.local.md`, `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md`, `tests/everything-in-issues.test.sh`; plus this plan, the research and `docs/verif/`.

## Test strategy
Nine automated tests, one file, documentation layer (the only layer of this repository's method files), within `Test budget: 25`. Seven quote the clause their criterion rests on, so deleting that clause turns them red; `test_readers_list_issue_tracker` also catches a future reader that forgets its `Reads settings:`. The two added by fix run 1 for the loop-0 majors, `test_finding_text_never_enters_a_command` and `test_every_finding_shape_is_read`, also execute commands: they extract the title and body commands of `/po-ship` Step 3 from `method/commands/po-ship.md` itself and run them with `bash -c` under `LC_ALL=C`, in a scratch folder, on a fixture review holding two reviews (`Fix loop: 1` then `Fix loop: 2`), quotes and `$(touch pwned)`, the numbered, bold, plain and star shapes, a sub-bullet and an accented finding longer than 80 characters. They check the title cut (by characters, trailing space trimmed), that the body names the last `Fix loop:`, and that nothing was run. They execute `sed`, `grep`, `tail`, `printf` only: no `gh`, no `task`, no forge stub. Existing tests listed in the research's traps run in the full suite and must stay green unchanged. No visual check.

## Done when
Nine new tests and the full suite green (`bash tests/run.sh`, through `po-run`); `bin/po-lint` clean; one commit on `story/s134-everything-to-handle-is-an-issue` carrying code, research, plan and record; a review with no open critical finding; shipped as `s134-everything-to-handle-is-an-issue: Polype dépose une issue pour tout ce qui est à traiter`.
