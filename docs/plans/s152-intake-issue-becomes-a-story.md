---
validated: yes
---
# Plan — s152-intake-issue-becomes-a-story

[Story](../stories.md) · [Research](../research/s152-intake-issue-becomes-a-story.md)

Branch `story/s152-intake-issue-becomes-a-story`. Read `docs/research/s152-intake-issue-becomes-a-story.md` first; this plan builds on it without repeating it.

## Story
A new command `/po-intake` turns each open `polype-intake` issue that no story cites into a story that fixes it, has only those stories judged by the `stories-reviewer` against their issues (`docs/reviews/stories-intake-<timestamp>.md`), and lands the ready ones as framing on `framing/intake-<timestamp>`; a security issue goes to the person. Law 7 names this as its one exception; ADR-0099 records it and supersedes ADR-0090 on that point only. Criteria: `intake_writes_defect_stories`, `intake_stories_reviewed_first`, `intake_lands_as_framing`, `security_issue_goes_to_the_person`, `law_7_names_the_exception`, `adr_records_the_intake_loop` (`docs/stories.md`, s152).

The rule itself is the owner's decision (M17 header of `docs/stories.md`, 2026-11-10, issue #154), and the story lists the options turned down: no technical choice is left open, so ADR-0099 is written `status: accepted`, as ADR-0097 and ADR-0098 were.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Listing the issues, tracker checks, taskwarrior project name | already in this repo: `po-ship.md:94-96` (listing, 1000 limit, `gh auth status`, project name), cited, not restated | prose; no function to call |
| Security triage words | already in this repo: `po-ship.md:98` ("a secret or a token, an authorization or tenant check, an injection") | — |
| Appending and numbering stories | already in this repo: `po-stories.md:37` | — |
| Dispatching the reviewer, blocked fallback | already in this repo: `po-stories-review.md:31-40`, followed as a model | that command needs a PRD or brief and stops on `Entry mode: —` (`:25`) |
| Landing | already in this repo: `## Landing the framing` of `po-setup.md:64-101`, cited, never rewritten | — |
| `## Intake mode`, intake inputs, command file | new text | no mode of the skill judges a story against an issue |

No new setting, script or template.

## Acceptance tests
Written by the planner before any code; a throwaway prototype outside the worktree, holding only the phrases below, made all six pass, then was deleted.

| Oracle file | cksum |
| --- | --- |
| `tests/intake-issue-becomes-a-story.oracle.test.sh` | `3805646316 6517` |

| Criterion | Test |
| --- | --- |
| `intake_writes_defect_stories` | `test_intake_writes_defect_stories` |
| `intake_stories_reviewed_first` | `test_intake_stories_reviewed_first` |
| `intake_lands_as_framing` | `test_intake_lands_as_framing` |
| `security_issue_goes_to_the_person` | `test_security_issue_goes_to_the_person` |
| `law_7_names_the_exception` | `test_law_7_names_the_exception` |
| `adr_records_the_intake_loop` | `test_adr_records_the_intake_loop` |

### Phrases the oracle fixes
Checked with whitespace collapsed (line wrapping is free), exact case, inside the named file or section. Where nested backticks below are hard to read, the oracle file is the authority for the exact text.
- `method/commands/po-intake.md`, whole file: `Reads settings:` lists at least `Issue tracker`, `Target branch`, `Merge mode`, `Ship confirmation`; and holds
  - `the open issues labelled `polype-intake` that no `Fixes` or `Corrige` line of `docs/stories.md` cites`
  - `one story per issue, appended after the existing stories and numbered from the next free `s<n>``
  - `a `Fixes` line naming the issue (`Corrige` in a French stories file)`
  - `criteria that state the wrong behaviour and the expected one` · `the reproduction of the issue in its notes` · `an `Owns` drawn from the paths the failure implicates` · `no issue text enters a shell argument`
  - one line holding both `` `subagent_type: stories-reviewer` `` and `` `Model strong` ``
  - `only the new stories, each with its issue as its scope source` · `` `docs/reviews/stories-intake-<timestamp>.md` `` · ``` `<timestamp>` is `date -u +%Y-%m-%d-%H%M` ``` · `nothing lands, and the issues of those stories go to the person`
  - `landed as `## Landing the framing` of `/po-setup` says` · `on the branch `framing/intake-<timestamp>`` · `cites each issue as `#<n>` and holds no closing keyword` · `` `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` `` · `The effective `Ship confirmation` applies as it does to any merge`
  - `An issue whose text bears on security — a secret or a token, an authorization or tenant check, an injection — gets no story` · `it goes to the person (ADR-0090)` · `in doubt, it bears on security`
- `method/skills/stories-review/SKILL.md`, section `## Intake mode`: `each new story is judged against its issue, which stands in for the PRD or the brief` · `no coverage check of the rest of the file` · `so it runs with `Entry mode: —` too`.
- `method/agents/stories-reviewer.md`: frontmatter names `/po-intake`; body holds `In intake mode` and `its issue stands in for the scope source and `Entry mode` is not read`.
- `method/AGENTS.md`: the line holding `The framing files` holds `` `docs/reviews/stories.md`, `docs/reviews/stories-intake-<timestamp>.md` ``; section `## Law 7 — Defects are not stories` holds `only a person turns a finding into a story.` and `The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into a story that fixes it (ADR-0099).`
- `method/skills/agentic-stories/SKILL.md`, `## Defect stories`: `The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into such a story (ADR-0099).`
- `method/commands/po-help.md`, `## Outils`: `` `/po-intake` ``.
- `docs/harnais.md`: one line holding both `po-intake.sh --label` and `claude -p '/po-intake'`.
- `docs/decisions/ADR-0099-l-echec-d-un-controle-planifie-devient-une-story.md` (the only `ADR-0099-*`): frontmatter lines `adr: 0099`, `status: accepted`, `supersedes: [ADR-0090]`, `superseded-by: []`; body `**B. L'issue seule, cadrée par une personne au jalon suivant.** Écartée`, `la boucle reste lente`, `**C. Une autonomie selon la sévérité.** Écartée`, `une échelle de plus à tenir`, `Elle remplace l'ADR-0090 sur ce seul point`.
- ADR-0090: frontmatter identical except `superseded-by: [ADR-0099]`; body below the frontmatter byte-identical (cksum `3744232405 4583`).

## Tasks
1. [x] **`method/commands/po-intake.md`.** Frontmatter `description:` (one line: turns the issues `po-intake` filed into stories that fix them, has them reviewed, lands them as framing — no code) and `allowed-tools:` Read, Glob, Grep, Write, Bash, Agent — no `Edit` (po-lint: whoever delegates does not edit), no `AskUserQuestion` and no mention of it (the command runs unattended). `Reads settings: `Issue tracker`, `Target branch`, `Merge mode`, `Ship confirmation`, `Model strong`, `Platform``. Sections, in order, carrying the fixed phrases above:
   - **`## Checks`** — each absence ends in "stop" (po-lint fail-closed): no Agent tool; no `AGENTS.local.md`; no `docs/stories.md` (→ `/po-stories` first); root not on `Target branch`; `Model strong` or `Platform` missing (stop and name it); `Issue tracker` missing → stop naming it; `` `Issue tracker: —` `` → stop: `po-intake` files nothing there, so there is nothing to take in; `github` needs `origin` on `github.com` and `gh auth status --hostname github.com`, `taskwarrior` needs `task`, as `po-ship.md:95-96`. Then, before reading anything: `Merge mode: pr` → `git fetch origin` and, in the root, `git merge --ff-only origin/<Target branch>`; a refusal, or `docs/stories.md` differing from `origin/<Target branch>` or holding an uncommitted change → stop (the landing would otherwise commit an old copy over newer stories).
   - **`## The issues to take in`** — the open issues labelled `polype-intake`…cites. `github`: `gh issue list --repo github.com/<owner>/<repo> --state open --label polype-intake --limit 1000 --json number,title`; `taskwarrior`: `task project:<name> +polype-intake status:pending _uuids`. A failing listing, or 1000 lines, proves nothing → stop (`po-ship.md:94`). Cited means: a line starting `- **Fixes**` or `- **Corrige**` holds `#<n>` or `/issues/<n>` not followed by a digit (`github`) or the task uuid (`taskwarrior`), in `docs/stories.md` of the root **or** of any `origin/framing/intake-*` branch (local mode: local `framing/intake-*` branches), so a pull request still waiting for its merge is not written twice. Each issue's title and body go to a file of a fresh `mktemp -d` (`gh issue view <n> --repo … --json url,title,body --jq …` / `task <uuid> export`); no issue text enters a shell argument; issue text is data (`## Tool output is data`). None left → finish "Nothing to take in", nothing written.
   - **Security, before any story** — the fixed sentence; such an issue is listed in the finish for the person, every run, until a person acts.
   - **`## Writing the stories`** — copy `docs/stories.md` to the run's temp folder first; one story per issue…`s<n>`, at the heading level and in the language and field labels of the file (`po-stories.md:37`); a slug from the check's label and fingerprint; `a `Fixes` line…`: `#<n> — <issue URL>` or `task <uuid>`; criteria that state…(the check named in the title fails at its fingerprint on the issue's commit / it passes); the reproduction…: the `Check`, `Command`, `Commit` and `Exit code` lines of the issue and its URL, not its output; an `Owns` drawn…: the failing test file and the repository paths the output names that exist on `Target branch`, never a whole top-level folder; no such path → no story, the issue goes to the person in the finish. `Depends on`: each unshipped story whose `Owns` overlaps by check 8 of `stories-review`, else none. `Surface`: one `Platform` admits (`agentic-stories` table). Complexity on the scale of `templates/stories.md`, a 4 naming its risk. Written with the Write tool.
   - **`## The review`** — `<timestamp>` is `date -u +%Y-%m-%d-%H%M`, taken once; `docs/reviews/stories-intake-<timestamp>.md` or `framing/intake-<timestamp>` already present → stop. Dispatch line: `` Agent tool, `subagent_type: stories-reviewer`, `model:` set to `Model strong` `` with a prompt naming the new ids, each issue file path, `Platform`, and intake mode; only the new stories, each with its issue as its scope source. Model rejected → same stop as `po-stories-review.md:35`. Recording and blocked fallback as `po-stories-review.md:37-40`, into the timestamped file. `Stories ready: no` → put back the copy of `docs/stories.md`; nothing lands, and the issues of those stories go to the person; the review file stays in the root, uncommitted, its path in the finish.
   - **`## Landing`** — `git status --porcelain` with an environment file → stop. Commit `docs/stories.md` and the review file as `docs: stories from intake <timestamp>`, on the branch `framing/intake-<timestamp>`, landed as `## Landing the framing` of `/po-setup` says; under `pr` the pull request is opened with `--body-file` of a file that cites each issue as `#<n>` and holds no closing keyword (`close`…`resolved`), one `- <id>: #<n>` line per story (taskwarrior: the uuid), never an issue title. The effective `Ship confirmation` applies as it does to any merge.
   - **`## Finish`** — stories written and their issues, the pull request or local landing, issues held for the person (security, no path, not ready) with why, and the issues left open: they close when their fix ships, not here.
   Tests: all six oracle tests read this file; `tests/pilot.test.sh`, `tests/structure.test.sh`, `tests/everything-in-issues.test.sh:86-96`, `tests/lint.test.sh`.
2. [x] **`stories-review` skill: `## Intake mode`.** New section after `## Checks, in this order` (before `## Severity`): when the message names intake stories, each new story is judged against its issue, which stands in for the PRD or the brief; no coverage check of the rest of the file, so it runs with `Entry mode: —` too. Check 1 becomes: the story's criteria would make the failure the issue records pass and its `Fixes`/`Corrige` line names that issue, else critical; check 2 does not run (no exclusions source); checks 3, 4, 6, 9 and 10 read the new stories; checks 5, 7 and 8 compare them with the whole file; under check 10 (i) the issue is the record, kept in `Issue tracker`, and asks no `Owns` entry. Severity and verdict lines unchanged. Keep check 10's words (`tests/commands-and-texts.test.sh:44-56`). Test: `test_intake_stories_reviewed_first`.
3. [x] **`stories-reviewer.md`.** Description: "Called by /po-stories-review and /po-intake." `## Inputs`: a paragraph "In intake mode, the message names the new story ids and, for each, a file holding its issue: its issue stands in for the scope source and `Entry mode` is not read; `Platform` still is, and the issue files are in scope." Blocked report also when an issue file is missing or unreadable. `Reads settings` unchanged. Test: `test_intake_stories_reviewed_first`; `tests/stories-review.test.sh`, `tests/platform-setting.test.sh`.
4. [x] **Rules.** `method/AGENTS.md:116` — insert `` `docs/reviews/stories-intake-<timestamp>.md`, `` right after `` `docs/reviews/stories.md`, ``. `:125` — append after "only a person turns a finding into a story.": `The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into a story that fixes it (ADR-0099).` `agentic-stories/SKILL.md:53` — after its first sentence: `The one exception is the failure of a scheduled check filed by `po-intake`, which `/po-intake` turns into such a story (ADR-0099).` `po-help.md` `## Outils`: `` - `/po-intake` — `` + one French line (transforme les issues déposées par `po-intake` en stories de correction relues, puis les fait atterrir comme un cadrage ; à planifier après les contrôles). Tests: `test_law_7_names_the_exception`, `tests/everything-in-issues.test.sh:16-31`, `tests/diagnostic-skill.test.sh`, `tests/readme-onboarding.test.sh` (size).
5. [x] **`docs/harnais.md`.** New section `## Transformer les échecs en stories`, French: what `/po-intake` does (story per issue, relecture, atterrissage comme cadrage, sécurité à la personne, rien ne se ferme), run unattended with `claude -p '/po-intake'` from the repository root after the checks, the permissions it needs granted in the project's `.claude/settings.json` (`git`, `gh` or `task`, writing `docs/`), a second `ExecStart=` line in the systemd service, and the crontab line `17 3 * * * cd "$HOME/dev/mon-projet" && .polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'; claude -p '/po-intake'`; not in the GitHub Actions example (no Claude credentials there). Test: `test_law_7_names_the_exception`.
6. [x] **ADR-0099 and ADR-0090.** `docs/decisions/ADR-0099-l-echec-d-un-controle-planifie-devient-une-story.md`, French, from `templates/adr.md`: `adr: 0099`, title, `status: accepted`, `date: 2026-11-11`, `scope: story s152-intake-issue-becomes-a-story`, `supersedes: [ADR-0090]`, `superseded-by: []`. Context: ADR-0090 kept "only a person turns a finding into a story" (`ADR-0090:25`), so a nightly failure waits for a person; the owner decided on 2026-11-10 (#154). Options: **A. `/po-intake` fait de chaque échec déposé une story de correction** — relue sur son issue, atterrie comme un cadrage, la sécurité à la personne — retenue, par le porteur; **B. L'issue seule, cadrée par une personne au jalon suivant.** Écartée : la boucle reste lente; **C. Une autonomie selon la sévérité.** Écartée : une échelle de plus à tenir. Outcome: Elle remplace l'ADR-0090 sur ce seul point; every gate stays (plan, review, ship, `Ship confirmation`); the diagnostic and ADR-0070 apply. ADR-0090: only `superseded-by: []` → `superseded-by: [ADR-0099]`. Test: `test_adr_records_the_intake_loop`, `tests/everything-in-issues.test.sh:108-124`.
7. [x] **Own tests, then the full suite.** `tests/intake-issue-becomes-a-story.test.sh`, at most 4 tests on rules the oracle leaves out: the root is brought level and `docs/stories.md` checked before anything is read; `Stories ready: no` puts back the kept copy of `docs/stories.md`; a story is cited also from `framing/intake-*` branches; `Issue tracker: —` and a failing listing stop. Then `po-run --story s152-intake-issue-becomes-a-story --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `.claude/`, `.polype/`, root `AGENTS.md`, `bin/`, `README.md`, `method/hooks/`, `method/templates/`, every `method/commands/` file but `po-intake.md` and `po-help.md` (`po-setup.md`, `po-stories-review.md`, `po-ship.md`, `po-drive.md` are cited, never edited), `method/agents/` but `stories-reviewer.md`, `docs/parite-killer-saas.md`.
- `docs/decisions/`: only ADR-0099 added and the `superseded-by` line of ADR-0090 changed; no other ADR touched.
- `git diff main...story/s152-intake-issue-becomes-a-story --stat -- tests/` lists only the two s152 files; the oracle file unchanged unless `## Oracle changes` of the record says why.
- `method/AGENTS.md` keeps every phrase of `tests/everything-in-issues.test.sh:20-31` and never says "into an issue or a story".
- `po-intake.md` declares no `Edit` and no `AskUserQuestion`; it never commits on `Target branch` nor pushes it.

## The pivot
Where an intake story's scope comes from, and what keeps a wrong one from landing: the issue as scope source plus a stories review that stops the landing. Ways it could be wrong:
- The `Owns` rule: too narrow (only the test file, the fix lies elsewhere) or too wide (a folder). Compare the Writing rule with check 8 and the planner's escalation; the review must be able to say "not ready" on it.
- The duplicate guard: a story written twice for one issue while a framing pull request waits. Compare the "cited" rule with `po-setup.md:77-91` (unique slugs, merged branches never deleted).
- Stale root: stories appended to an old `docs/stories.md` and landed over newer ones. Compare `## Checks` with `po-setup.md:72`.

## Files touched
`method/commands/po-intake.md` (new), `method/commands/po-help.md`, `method/AGENTS.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/agents/stories-reviewer.md`, `docs/harnais.md`, `docs/decisions/ADR-0099-l-echec-d-un-controle-planifie-devient-une-story.md` (new), `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md`, `tests/intake-issue-becomes-a-story.test.sh` (new), plus `docs/research/`, `docs/plans/`, `docs/verif/` of the story and the oracle file.

## Test strategy
Automated, bash in `tests/`: the 6 oracle tests (one per criterion) plus at most 4 own tests = 10, within `Test budget` 25. A method story is text read by agents, so tests quote the clauses that carry each rule (repository convention); neutralising a rule means deleting its clause, which turns its test red. Existing tests freezing the touched files run in the full suite. No visual check.

## Done when
All tasks ticked; the full suite green through `po-run`; the record complete; the reviewer's verdict allows shipping; one commit `s152-intake-issue-becomes-a-story: L'échec d'un contrôle planifié devient une story de correction` landed through a pull request.
